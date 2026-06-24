"""Run all five cattle vision models from original .pth / .pt weights."""
from __future__ import annotations

import hashlib
import io
import math
import secrets
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import torch
import torch.nn.functional as F
import torchvision.transforms as T
from PIL import Image
from ultralytics import YOLO

try:
    from config import (
        BCS_PTH,
        BEHAVIOR_PTH,
        EARTAG_PT,
        ENABLE_EARTAG_OCR,
        LAMENESS_PTH,
        MODELS_DIR,
        MUZZLE_PTH,
        POSE_PT,
        TROCR_MODEL,
        load_meta,
    )
    from services.ear_tag_ocr import EarTagOcrService
    from services.model_architectures import (
        BcsScorer,
        BehaviorClassifier,
        LamenessBiLSTM,
        MuzzleEmbedder,
        load_split_checkpoint,
    )
except ImportError:
    from python_backend.config import (
        BCS_PTH,
        BEHAVIOR_PTH,
        EARTAG_PT,
        ENABLE_EARTAG_OCR,
        LAMENESS_PTH,
        MODELS_DIR,
        MUZZLE_PTH,
        POSE_PT,
        TROCR_MODEL,
        load_meta,
    )
    from python_backend.services.ear_tag_ocr import EarTagOcrService
    from python_backend.services.model_architectures import (
        BcsScorer,
        BehaviorClassifier,
        LamenessBiLSTM,
        MuzzleEmbedder,
        load_split_checkpoint,
    )


@dataclass
class CattleRegion:
    crop: Image.Image
    tag_conf: float
    tag_box: tuple[float, float, float, float] | None
    body_box: tuple[int, int, int, int]
    species: str = "cow"
    species_conf: float = 0.5


@dataclass
class _PartialAnalysis:
    cattle_id: str
    ear_tag: dict[str, Any]
    muzzle: dict[str, Any]
    bcs: dict[str, Any]
    lameness: dict[str, Any]
    feeding: dict[str, Any]


class LocalModelService:
    """Detect cattle first, then run ear-tag, muzzle, BCS, behavior, and lameness models."""

    MIN_CATTLE_AREA = 80 * 80
    PERSON_AREA_RATIO = 0.08
    MIN_TAG_TEXTURE_STD = 12.0
    # YOLO fn1 was trained with pseudo full-image boxes (0 0.5 0.5 1.0 1.0).
    BODY_BOX_AREA_RATIO = 0.12
    BODY_BOX_DIM_RATIO = 0.45
    DETECT_CONF = 0.25

    def __init__(self) -> None:
        self._ready = False
        self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        self._eartag_yolo: YOLO | None = None
        self._pose_yolo: YOLO | None = None
        self._behavior: BehaviorClassifier | None = None
        self._bcs: BcsScorer | None = None
        self._muzzle: MuzzleEmbedder | None = None
        self._lameness: LamenessBiLSTM | None = None
        self._ear_tag_ocr = EarTagOcrService(
            model_name=TROCR_MODEL,
            device=self._device,
            enabled=ENABLE_EARTAG_OCR,
        )

        self._eartag_meta = load_meta("eartag")
        self._behavior_meta = load_meta("behavior")
        self._bcs_meta = load_meta("bcs")
        self._muzzle_meta = load_meta("muzzle")
        self._lameness_meta = load_meta("lameness")

    @property
    def is_ready(self) -> bool:
        return self._ready

    @property
    def models_dir(self) -> str:
        return str(MODELS_DIR)

    @property
    def has_eartag_ocr(self) -> bool:
        return self._ear_tag_ocr.is_ready

    def initialize(self) -> None:
        if self._ready:
            return

        weights = {
            "eartag_detector.pt": EARTAG_PT,
            "yolov8n-pose.pt": POSE_PT,
            "behavior_classifier.pth": BEHAVIOR_PTH,
            "bcs_scorer.pth": BCS_PTH,
            "muzzle_embedder.pth": MUZZLE_PTH,
            "lameness_detector.pth": LAMENESS_PTH,
        }
        missing = [name for name, path in weights.items() if not path.is_file()]
        if missing:
            raise FileNotFoundError(
                f"Missing PyTorch weights in {MODELS_DIR}: {', '.join(missing)}"
            )

        self._eartag_yolo = YOLO(str(EARTAG_PT))
        self._pose_yolo = YOLO(str(POSE_PT))

        if self._ear_tag_ocr.is_enabled:
            try:
                self._ear_tag_ocr.initialize()
                print(f"[models] TrOCR ready ({TROCR_MODEL})")
            except RuntimeError as exc:
                print(f"[models] TrOCR disabled: {exc}")

        behavior = BehaviorClassifier(num_classes=len(self._behavior_meta["classes"]))
        self._load_torch_module(behavior, BEHAVIOR_PTH)
        self._behavior = behavior.to(self._device).eval()

        bcs = BcsScorer(num_bins=len(self._bcs_meta["bcs_bins"]) - 1)
        self._load_torch_module(bcs, BCS_PTH)
        self._bcs = bcs.to(self._device).eval()

        muzzle = MuzzleEmbedder(embed_dim=self._muzzle_meta["embed_dim"])
        load_split_checkpoint(
            muzzle,
            str(MUZZLE_PTH),
            prefixes={"bb.": "bb", "head.": "head"},
        )
        self._muzzle = muzzle.to(self._device).eval()

        lameness = LamenessBiLSTM(
            feat_dim=self._lameness_meta["feat_dim"],
            hidden=128,
            num_layers=2,
            num_classes=len(self._lameness_meta["classes"]),
        )
        self._load_torch_module(lameness, LAMENESS_PTH)
        self._lameness = lameness.to(self._device).eval()

        self._ready = True

    @staticmethod
    def hash_bytes(data: bytes) -> str:
        sample = data[:102400]
        return hashlib.md5(sample).hexdigest()

    def count_cattle(self, image_bytes: bytes) -> int:
        self._ensure_ready()
        image = self._decode_image(image_bytes)
        return len(self._detect_cattle_regions(image))

    def analyze_image(self, image_bytes: bytes) -> dict[str, Any]:
        self._ensure_ready()
        image = self._decode_image(image_bytes)
        regions = self._detect_cattle_regions(image)
        if not regions:
            raise ValueError("No cattle found in this image")

        best = max(regions, key=lambda r: r.tag_conf)
        partial = self._analyze_cattle_region(best, index=0)
        return self._merge_partials([partial], self.hash_bytes(image_bytes))

    def analyze_video_preview(self, preview_bytes: bytes, video_file_name: str) -> dict[str, Any]:
        return self.analyze_video_frames([preview_bytes], video_file_name)

    def analyze_video_frames(
        self,
        frame_bytes_list: list[bytes],
        video_file_name: str,
    ) -> dict[str, Any]:
        """Analyze video using one or more JPEG frames (up to 20 for lameness LSTM)."""
        self._ensure_ready()
        if not frame_bytes_list:
            raise ValueError("No video frames provided")

        frames = [self._decode_image(data) for data in frame_bytes_list if data]
        if not frames:
            raise ValueError("No valid video frames")

        best_regions: list[CattleRegion] = []
        for frame in frames:
            regions = self._detect_cattle_regions(frame)
            if len(regions) > len(best_regions):
                best_regions = regions

        if not best_regions:
            raise ValueError("No cattle found in this video")

        keypoint_sequence = self._build_keypoint_sequence(frames)
        cow_count = 0
        buffalo_count = 0
        animals: list[dict[str, Any]] = []

        for i, region in enumerate(best_regions):
            partial = self._analyze_cattle_region(
                region,
                index=i,
                keypoint_sequence=keypoint_sequence,
            )
            if region.species == "buffalo":
                buffalo_count += 1
            else:
                cow_count += 1

            milking = self._infer_milking_status(
                partial.bcs,
                partial.feeding,
                partial.lameness,
            )
            conf = max(partial.bcs["confidence"], partial.lameness["confidence"]) / 100.0
            overall = self._build_overall_health(
                partial.ear_tag,
                partial.bcs,
                partial.lameness,
                partial.feeding,
            )
            animals.append(
                {
                    "cattle_id": partial.cattle_id,
                    "species": region.species,
                    "milking_status": milking,
                    "bcs_score": partial.bcs["score"],
                    "lameness_score": float(partial.lameness["locomotion_score"]),
                    "is_lame": partial.lameness["detected"],
                    "confidence": conf,
                    "feeding_alert": partial.feeding["current_behavior"]
                    not in ("feeding", "drinking"),
                    "health_status": overall["status"],
                }
            )

        return {
            "cattle_count": cow_count or len(animals),
            "buffalo_count": buffalo_count,
            "video_file_name": video_file_name,
            "animals": animals,
        }

    def _load_torch_module(self, model: torch.nn.Module, path: Path) -> None:
        ckpt = torch.load(path, map_location="cpu", weights_only=False)
        if isinstance(ckpt, torch.nn.Module):
            return

        state = ckpt
        if isinstance(ckpt, dict):
            state = ckpt.get("state_dict") or ckpt.get("model_state_dict") or ckpt

        if not isinstance(state, dict):
            raise ValueError(f"Unsupported checkpoint format: {path}")

        model.load_state_dict(state, strict=True)

    def _decode_image(self, data: bytes) -> Image.Image:
        return Image.open(io.BytesIO(data)).convert("RGB")

    def _imagenet_tensor(
        self,
        image: Image.Image,
        *,
        size: int,
        mean: list[float],
        std: list[float],
    ) -> torch.Tensor:
        transform = T.Compose(
            [
                T.Resize((size, size)),
                T.ToTensor(),
                T.Normalize(mean=mean, std=std),
            ]
        )
        return transform(image).unsqueeze(0).to(self._device)

    def _detect_eartag_boxes(
        self,
        image: Image.Image,
        *,
        conf_override: float | None = None,
    ) -> list[tuple[float, float, float, float, float]]:
        assert self._eartag_yolo is not None
        conf_thr = conf_override if conf_override is not None else float(
            self._eartag_meta["conf_threshold"]
        )
        results = self._eartag_yolo.predict(
            source=image,
            imgsz=int(self._eartag_meta["input_size"]),
            conf=conf_thr,
            verbose=False,
        )
        boxes: list[tuple[float, float, float, float, float]] = []
        if not results or results[0].boxes is None:
            return boxes

        xyxy = results[0].boxes.xyxy.cpu().numpy()
        confs = results[0].boxes.conf.cpu().numpy()
        for box, conf in zip(xyxy, confs, strict=False):
            x1, y1, x2, y2 = box.tolist()
            boxes.append((x1, y1, x2, y2, float(conf)))
        boxes.sort(key=lambda b: b[4], reverse=True)
        return boxes

    def _expand_tag_to_cattle_crop(
        self,
        image: Image.Image,
        x1: float,
        y1: float,
        x2: float,
        y2: float,
    ) -> tuple[Image.Image, tuple[int, int, int, int]]:
        """Expand an ear-tag box to approximate the full cattle body region."""
        w, h = image.size
        tag_w = max(x2 - x1, 8.0)
        tag_h = max(y2 - y1, 8.0)
        cx = (x1 + x2) / 2.0

        body_w = max(tag_w * 7.0, 160.0)
        body_h = max(tag_h * 12.0, 220.0)

        x1b = max(0, int(cx - body_w / 2))
        x2b = min(w, int(cx + body_w / 2))
        y1b = max(0, int(y1 - tag_h * 2.5))
        y2b = min(h, int(y2 + body_h))

        if x2b <= x1b or y2b <= y1b:
            return image, (0, 0, w, h)
        return image.crop((x1b, y1b, x2b, y2b)), (x1b, y1b, x2b, y2b)

    def _is_person_dominant(self, image: Image.Image) -> bool:
        """Reject human-only frames (yolov8n-pose.pt is COCO person class)."""
        assert self._pose_yolo is not None
        w, h = image.size
        frame_area = w * h
        if frame_area <= 0:
            return False

        results = self._pose_yolo.predict(source=image, imgsz=640, conf=0.35, verbose=False)
        if not results or results[0].boxes is None:
            return False

        names = results[0].names or {}
        person_area = 0.0
        for idx, cls_id in enumerate(results[0].boxes.cls.cpu().numpy()):
            label = names.get(int(cls_id), "")
            if label != "person":
                continue
            x1, y1, x2, y2 = results[0].boxes.xyxy[idx].cpu().numpy()
            person_area += max(0.0, (x2 - x1) * (y2 - y1))

        return person_area / frame_area >= self.PERSON_AREA_RATIO

    def _is_valid_ear_tag(
        self,
        image: Image.Image,
        x1: float,
        y1: float,
        x2: float,
        y2: float,
        conf: float,
    ) -> bool:
        w, h = image.size
        tag_w = x2 - x1
        tag_h = y2 - y1
        if tag_w < 10 or tag_h < 10:
            return False
        if tag_w > w * 0.35 or tag_h > h * 0.35:
            return False
        if conf < float(self._eartag_meta["conf_threshold"]):
            return False

        x1i = max(0, int(x1))
        y1i = max(0, int(y1))
        x2i = min(w, int(x2))
        y2i = min(h, int(y2))
        if x2i <= x1i or y2i <= y1i:
            return False

        patch = np.array(image.crop((x1i, y1i, x2i, y2i)))
        if patch.size == 0 or float(patch.std()) < self.MIN_TAG_TEXTURE_STD:
            return False
        return True

    def _detect_cattle_regions(self, image: Image.Image) -> list[CattleRegion]:
        """Locate cattle via YOLO (full-body pseudo labels or small ear-tag boxes)."""
        w, h = image.size
        frame_area = max(w * h, 1)
        tags = self._detect_eartag_boxes(image, conf_override=self.DETECT_CONF)
        regions: list[CattleRegion] = []

        for x1, y1, x2, y2, conf in tags:
            box_w = x2 - x1
            box_h = y2 - y1
            area_ratio = (box_w * box_h) / frame_area

            # Pseudo-label training produces large full-body boxes — use directly.
            if (
                area_ratio >= self.BODY_BOX_AREA_RATIO
                or box_w >= w * self.BODY_BOX_DIM_RATIO
                or box_h >= h * self.BODY_BOX_DIM_RATIO
            ):
                x1i, y1i, x2i, y2i = int(x1), int(y1), int(x2), int(y2)
                if x2i > x1i and y2i > y1i and (x2i - x1i) * (y2i - y1i) >= self.MIN_CATTLE_AREA:
                    crop = image.crop((x1i, y1i, x2i, y2i))
                    species, species_conf = self._estimate_species(crop)
                    regions.append(
                        CattleRegion(
                            crop=crop,
                            tag_conf=conf,
                            tag_box=(x1, y1, x2, y2),
                            body_box=(x1i, y1i, x2i, y2i),
                            species=species,
                            species_conf=species_conf,
                        )
                    )
                continue

            if not self._is_valid_ear_tag(image, x1, y1, x2, y2, conf):
                continue
            crop, body_box = self._expand_tag_to_cattle_crop(image, x1, y1, x2, y2)
            if crop.width * crop.height < self.MIN_CATTLE_AREA:
                continue
            species, species_conf = self._estimate_species(crop)
            regions.append(
                CattleRegion(
                    crop=crop,
                    tag_conf=conf,
                    tag_box=(x1, y1, x2, y2),
                    body_box=body_box,
                    species=species,
                    species_conf=species_conf,
                )
            )

        if regions:
            return self._merge_overlapping_regions(regions)

        if self._is_person_dominant(image):
            return []

        if w * h >= self.MIN_CATTLE_AREA:
            species, species_conf = self._estimate_species(image)
            return [
                CattleRegion(
                    crop=image,
                    tag_conf=0.0,
                    tag_box=None,
                    body_box=(0, 0, w, h),
                    species=species,
                    species_conf=species_conf,
                )
            ]
        return []

    @staticmethod
    def _estimate_species(crop: Image.Image) -> tuple[str, float]:
        """Heuristic cow vs buffalo (fn1: cows-and-buffalo-computer-vision-dataset)."""
        sample = crop.resize((128, 128))
        arr = np.array(sample, dtype=np.float32)
        brightness = float(arr.mean())
        aspect = crop.width / max(crop.height, 1)

        buffalo_score = 0.0
        if brightness < 95:
            buffalo_score += 0.45
        if aspect > 1.15:
            buffalo_score += 0.25
        if crop.height > crop.width * 0.85:
            buffalo_score += 0.15

        if buffalo_score >= 0.55:
            return "buffalo", min(0.85, 0.5 + buffalo_score * 0.3)
        return "cow", min(0.85, 0.55 + (1.0 - buffalo_score) * 0.25)

    @staticmethod
    def _head_crop(body: Image.Image) -> Image.Image:
        """Upper body / head region for muzzle_embedder (ResNet50 + ArcFace)."""
        w, h = body.size
        head_h = max(int(h * 0.42), 64)
        return body.crop((0, 0, w, min(head_h, h)))

    @staticmethod
    def _bcs_crop(body: Image.Image) -> Image.Image:
        """Central torso for BCS (EfficientNet-B3, fn3 body-parts / mmcows)."""
        w, h = body.size
        margin_x = int(w * 0.08)
        margin_y = int(h * 0.12)
        return body.crop((margin_x, margin_y, w - margin_x, h - margin_y))

    def _build_keypoint_sequence(self, frames: list[Image.Image]) -> list[list[float]]:
        """Build [seq_len, 51] keypoints from video frames (notebook: SEQ_LEN=20)."""
        seq_len = int(self._lameness_meta["seq_len"])
        sequence: list[list[float]] = []

        for frame in frames[:seq_len]:
            regions = self._detect_cattle_regions(frame)
            crop = regions[0].crop if regions else frame
            sequence.append(self._best_keypoints(crop))

        if not sequence:
            sequence.append([0.0] * int(self._lameness_meta["feat_dim"]))

        while len(sequence) < seq_len:
            sequence.append(list(sequence[-1]))

        return sequence[:seq_len]

    @staticmethod
    def _infer_milking_status(
        bcs: dict[str, Any],
        feeding: dict[str, Any],
        lameness: dict[str, Any],
    ) -> str:
        """Heuristic milking status (no dedicated model in kaggle.ipynb)."""
        behavior = feeding.get("current_behavior", "unknown")
        score = float(bcs.get("score", 3.0))
        lame = bool(lameness.get("detected"))

        if behavior in ("feeding", "drinking") and 2.0 <= score <= 4.25 and not lame:
            return "lactating"
        if behavior in ("resting", "standing") and score >= 3.5 and not lame:
            return "dry"
        if score >= 2.5 and behavior == "feeding":
            return "lactating"
        return "unknown"

    def _merge_overlapping_regions(self, regions: list[CattleRegion]) -> list[CattleRegion]:
        if len(regions) <= 1:
            return regions

        merged: list[CattleRegion] = []
        used = [False] * len(regions)

        for i, region in enumerate(regions):
            if used[i]:
                continue
            group = [region]
            used[i] = True
            for j in range(i + 1, len(regions)):
                if used[j]:
                    continue
                if self._box_iou(region.body_box, regions[j].body_box) > 0.35:
                    group.append(regions[j])
                    used[j] = True
            best = max(group, key=lambda r: r.tag_conf)
            merged.append(best)
        return merged

    @staticmethod
    def _box_iou(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> float:
        ax1, ay1, ax2, ay2 = a
        bx1, by1, bx2, by2 = b
        ix1 = max(ax1, bx1)
        iy1 = max(ay1, by1)
        ix2 = min(ax2, bx2)
        iy2 = min(ay2, by2)
        inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
        if inter == 0:
            return 0.0
        area_a = max(1, (ax2 - ax1) * (ay2 - ay1))
        area_b = max(1, (bx2 - bx1) * (by2 - by1))
        return inter / (area_a + area_b - inter)

    def _analyze_cattle_region(
        self,
        region: CattleRegion,
        *,
        index: int,
        keypoint_sequence: list[list[float]] | None = None,
    ) -> _PartialAnalysis:
        body = region.crop
        bcs_crop = self._bcs_crop(body)
        head_crop = self._head_crop(body)

        ear_tag = self._predict_eartag(body)
        cattle_id = self._assign_cattle_id(ear_tag, index)
        if not ear_tag.get("tag_number"):
            ear_tag = dict(ear_tag)
            ear_tag["tag_number"] = cattle_id
            if not ear_tag.get("detected"):
                ear_tag["notes"] = (
                    f"No ear tag visible — assigned random ID {cattle_id}."
                )
            elif self._ear_tag_ocr.is_ready:
                ear_tag["notes"] = (
                    f"Ear tag visible — TrOCR could not read ID; assigned {cattle_id}."
                )
            else:
                ear_tag["notes"] = (
                    f"Ear tag detected — assigned ID {cattle_id} "
                    "(TrOCR disabled)."
                )
        muzzle = self._predict_muzzle(head_crop)
        bcs = self._predict_bcs(bcs_crop)
        feeding = self._predict_behavior(body)
        lameness = self._predict_lameness(body, keypoint_sequence=keypoint_sequence)

        return _PartialAnalysis(
            cattle_id=cattle_id,
            ear_tag=ear_tag,
            muzzle=muzzle,
            bcs=bcs,
            lameness=lameness,
            feeding=feeding,
        )

    @staticmethod
    def _assign_cattle_id(ear_tag: dict[str, Any], index: int) -> str:
        """Use OCR tag number when available; else stable id if tag visible; else random ET id."""
        tag_number = ear_tag.get("tag_number")
        if tag_number and str(tag_number).strip():
            return str(tag_number).strip()
        if ear_tag.get("detected"):
            return f"ET-{index + 1:04d}"
        return f"ET-{secrets.randbelow(900000) + 100000}"

    def _select_tag_box(
        self,
        image: Image.Image,
        boxes: list[tuple[float, float, float, float, float]],
    ) -> tuple[float, float, float, float, float] | None:
        if not boxes:
            return None
        w, h = image.size
        frame_area = max(w * h, 1)
        small = [
            box
            for box in boxes
            if ((box[2] - box[0]) * (box[3] - box[1])) / frame_area
            < self.BODY_BOX_AREA_RATIO
        ]
        candidates = small or boxes
        return max(candidates, key=lambda b: b[4])

    @staticmethod
    def _crop_tag_patch(
        image: Image.Image,
        x1: float,
        y1: float,
        x2: float,
        y2: float,
        *,
        padding: float = 0.15,
    ) -> Image.Image:
        w, h = image.size
        box_w = max(x2 - x1, 8.0)
        box_h = max(y2 - y1, 8.0)
        pad_x = box_w * padding
        pad_y = box_h * padding
        left = max(0, int(x1 - pad_x))
        top = max(0, int(y1 - pad_y))
        right = min(w, int(x2 + pad_x))
        bottom = min(h, int(y2 + pad_y))
        if right <= left or bottom <= top:
            return image
        return image.crop((left, top, right, bottom))

    def _predict_eartag(self, crop: Image.Image) -> dict[str, Any]:
        w, _ = crop.size
        boxes = self._detect_eartag_boxes(crop)
        tag_box = self._select_tag_box(crop, boxes)
        if tag_box is None:
            return {
                "detected": False,
                "tag_number": None,
                "tag_color": None,
                "tag_position": "not visible",
                "ocr_confidence": 0,
                "notes": "No ear tag visible on this animal",
            }

        x1, y1, x2, y2, conf = tag_box
        cx = (x1 + x2) / 2
        if cx < w * 0.45:
            position = "left ear"
        elif cx > w * 0.55:
            position = "right ear"
        else:
            position = "both"

        tag_number: str | None = None
        ocr_confidence = int(min(99, max(0, round(conf * 100))))
        notes = "Ear tag detected — OCR not available, using generated ID."

        if self._ear_tag_ocr.is_ready:
            patch = self._crop_tag_patch(crop, x1, y1, x2, y2)
            tag_number, ocr_confidence = self._ear_tag_ocr.read_tag(patch)
            if tag_number:
                notes = f"Ear tag read via TrOCR: {tag_number}."
            else:
                notes = "Ear tag detected — TrOCR could not read a valid ID."

        return {
            "detected": True,
            "tag_number": tag_number,
            "tag_color": None,
            "tag_position": position,
            "ocr_confidence": ocr_confidence,
            "notes": notes,
        }

    def _predict_muzzle(self, crop: Image.Image) -> dict[str, Any]:
        assert self._muzzle is not None
        size = int(self._muzzle_meta["input_size"])
        tensor = self._imagenet_tensor(
            crop,
            size=size,
            mean=self._muzzle_meta["normalize_mean"],
            std=self._muzzle_meta["normalize_std"],
        )
        with torch.no_grad():
            emb = self._muzzle(tensor)
            emb = F.normalize(emb, p=2, dim=1)
            values = emb.squeeze(0).cpu().tolist()

        norm = math.sqrt(sum(v * v for v in values))
        detected = norm > 0.1
        distinctiveness = "high" if norm > 0.85 else "medium" if norm > 0.5 else "low"

        return {
            "detected": detected,
            "pattern_description": (
                "Muzzle biometric embedding extracted (muzzle_embedder.pth)."
                if detected
                else "Could not extract muzzle embedding."
            ),
            "breed_estimate": "Unknown",
            "distinctiveness": distinctiveness,
            "biometric_features": [
                f"embedding_dim_{len(values)}",
                f"L2_norm_{norm:.3f}",
            ],
            "notes": (
                "Compare embedding with gallery for ID match."
                if detected
                else "Muzzle not clear enough."
            ),
        }

    def _predict_bcs(self, crop: Image.Image) -> dict[str, Any]:
        assert self._bcs is not None
        size = int(self._bcs_meta["input_size"])
        tensor = self._imagenet_tensor(
            crop,
            size=size,
            mean=self._bcs_meta["normalize_mean"],
            std=self._bcs_meta["normalize_std"],
        )
        with torch.no_grad():
            logits = self._bcs(tensor).squeeze(0).cpu().tolist()

        probs = [1 / (1 + math.exp(-x)) for x in logits]
        idx = sum(1 for p in probs if p > 0.5)
        bins = self._bcs_meta["bcs_bins"]
        score = float(bins[min(idx, len(bins) - 1)])
        confidence = int(min(99, max(50, round((max(probs) if probs else 0.5) * 100))))

        return {
            "score": score,
            "category": self._bcs_category(score),
            "visible_ribs": score <= 2.5,
            "spine_visible": score <= 2.0,
            "hip_bones": "prominent" if score <= 2.0 else "covered" if score >= 4.0 else "normal",
            "recommendation": self._bcs_recommendation(score),
            "confidence": confidence,
        }

    def _predict_behavior(self, crop: Image.Image) -> dict[str, Any]:
        assert self._behavior is not None
        size = int(self._behavior_meta["input_size"])
        tensor = self._imagenet_tensor(
            crop,
            size=size,
            mean=self._behavior_meta["normalize_mean"],
            std=self._behavior_meta["normalize_std"],
        )
        with torch.no_grad():
            logits = self._behavior(tensor).squeeze(0).cpu().tolist()

        max_idx = max(range(len(logits)), key=logits.__getitem__)
        max_val = logits[max_idx]
        classes = self._behavior_meta["classes"]
        behavior = classes[min(max_idx, len(classes) - 1)]
        exp_sum = sum(math.exp(x - max_val) for x in logits)
        conf = math.exp(logits[max_idx] - max_val) / exp_sum if exp_sum else 0.0
        engagement = int(round(conf * 100))

        return {
            "current_behavior": behavior,
            "head_position": "down (feeding)" if behavior == "feeding" else "level",
            "location_zone": (
                "feeding area"
                if behavior in ("feeding", "drinking")
                else "resting area"
            ),
            "estimated_feeding_engagement": engagement,
            "notes": f"Behavior: {behavior} ({engagement}% confidence).",
        }

    def _predict_lameness(
        self,
        cattle_crop: Image.Image,
        *,
        keypoint_sequence: list[list[float]] | None = None,
    ) -> dict[str, Any]:
        assert self._pose_yolo is not None
        assert self._lameness is not None

        seq_len = int(self._lameness_meta["seq_len"])
        feat_dim = int(self._lameness_meta["feat_dim"])

        if keypoint_sequence:
            seq = keypoint_sequence[:seq_len]
            while len(seq) < seq_len:
                seq.append(list(seq[-1]))
        else:
            kpts = self._best_keypoints(cattle_crop)
            seq = [kpts] * seq_len

        tensor = torch.tensor(seq, dtype=torch.float32, device=self._device).view(
            1, seq_len, feat_dim
        )
        with torch.no_grad():
            logits = self._lameness(tensor).squeeze(0).cpu().tolist()

        probs = self._softmax(logits)
        lame_prob = probs[1] if len(probs) > 1 else 0.0
        detected = lame_prob >= 0.5
        locomotion = (
            4 if lame_prob > 0.8 else 3 if lame_prob > 0.65 else 2 if detected else 1
        )

        return {
            "detected": detected,
            "locomotion_score": locomotion,
            "posture": (
                "severely arched"
                if locomotion >= 4
                else "arched"
                if locomotion >= 3
                else "slightly arched"
                if locomotion >= 2
                else "normal"
            ),
            "weight_distribution": "uneven" if detected else "even",
            "affected_limb": "cannot determine" if detected else "none",
            "urgency": (
                "urgent"
                if locomotion >= 4
                else "veterinary attention"
                if locomotion >= 3
                else "monitor"
                if detected
                else "none"
            ),
            "confidence": int(round(lame_prob * 100 if detected else (1 - lame_prob) * 100)),
        }

    def _best_keypoints(self, crop: Image.Image) -> list[float]:
        """Extract 17×3 pose keypoints (yolov8n-pose.pt → lameness BiLSTM)."""
        assert self._pose_yolo is not None
        results = self._pose_yolo.predict(source=crop, imgsz=640, conf=0.2, verbose=False)
        kpts = [0.0] * 51
        if not results or results[0].keypoints is None or results[0].boxes is None:
            return kpts

        data = results[0].keypoints.data
        confs = results[0].boxes.conf.cpu().numpy()

        best_conf = 0.0
        best_kpts: list[float] | None = None
        for det_idx, row in enumerate(data):
            conf = float(confs[det_idx]) if det_idx < len(confs) else 0.0
            if conf < 0.2 or conf <= best_conf:
                continue
            flat = row.cpu().numpy().reshape(-1).tolist()
            if len(flat) >= 51:
                best_conf = conf
                best_kpts = [float(v) for v in flat[:51]]

        return best_kpts if best_kpts is not None else kpts

    def _merge_partials(self, partials: list[_PartialAnalysis], image_hash: str) -> dict[str, Any]:
        partial = partials[0]
        overall = self._build_overall_health(
            partial.ear_tag,
            partial.bcs,
            partial.lameness,
            partial.feeding,
        )
        return {
            "image_hash": image_hash,
            "cattle_id": partial.cattle_id,
            "eartag": partial.ear_tag,
            "muzzle": partial.muzzle,
            "bcs": partial.bcs,
            "lameness": partial.lameness,
            "feeding": partial.feeding,
            "overall_health": overall,
        }

    def _build_overall_health(
        self,
        ear_tag: dict[str, Any],
        bcs: dict[str, Any],
        lameness: dict[str, Any],
        feeding: dict[str, Any],
    ) -> dict[str, Any]:
        alerts: list[str] = []
        status = "Healthy"

        if lameness["urgency"] in ("urgent", "veterinary attention"):
            status = "Requires Attention"
            alerts.append("Lameness requires veterinary review")
        elif lameness["detected"]:
            status = "Needs Monitoring"
            alerts.append("Possible lameness — monitor gait")

        if bcs["score"] <= 2.0 or bcs["score"] >= 4.5:
            if status == "Healthy":
                status = "Requires Attention"
            alerts.append(f"BCS {bcs['score']} outside optimal range")

        if lameness["urgency"] == "urgent":
            status = "Critical"

        summary = " ".join(
            [
                "Ear tag visible." if ear_tag["detected"] else "Ear tag not detected.",
                f"BCS {bcs['score']} ({bcs['category']}).",
                f"Behavior: {feeding['current_behavior']}.",
                (
                    "Lameness indicators present."
                    if lameness["detected"]
                    else "No lameness indicators."
                ),
            ]
        )

        return {
            "status": status,
            "priority_alert": alerts[0] if alerts else None,
            "summary": summary,
        }

    @staticmethod
    def _softmax(logits: list[float]) -> list[float]:
        if not logits:
            return []
        max_l = max(logits)
        exps = [math.exp(x - max_l) for x in logits]
        total = sum(exps)
        return [e / total for e in exps]

    @staticmethod
    def _bcs_category(score: float) -> str:
        if score <= 1.5:
            return "Emaciated"
        if score <= 2.5:
            return "Thin"
        if score <= 3.5:
            return "Optimal"
        if score <= 4.5:
            return "Fat"
        return "Obese"

    @staticmethod
    def _bcs_recommendation(score: float) -> str:
        if score <= 2.0:
            return "Increase energy intake and monitor weight weekly."
        if score >= 4.0:
            return "Review ration to avoid excess body condition."
        return "Maintain current feeding plan."

    def _ensure_ready(self) -> None:
        if not self._ready:
            raise RuntimeError("LocalModelService not initialized — call initialize() first.")
