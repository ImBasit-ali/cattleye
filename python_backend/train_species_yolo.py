#!/usr/bin/env python3
"""
Train 2-class cow/buffalo YOLO (fn1 from kaggle.ipynb).

Dataset: raghavdharwal/cows-and-buffalo-computer-vision-dataset
Optional volume: sadhliroomyprime/cattle-weight-detection-model-dataset-12k (cow only)

Usage (local or Kaggle):
  python train_species_yolo.py \\
    --data-dir /kaggle/input/datasets/raghavdharwal/cows-and-buffalo-computer-vision-dataset \\
    --output models/species_detector.pt

On Kaggle, add both fn1 datasets, then run from python_backend/.
"""
from __future__ import annotations

import argparse
import json
import random
import shutil
from pathlib import Path

import yaml
from ultralytics import YOLO

SPECIES_CLASSES = ["cow", "buffalo"]
COW_ALIASES = ("cow", "cows", "cattle", "holstein", "dairy", "bull")
BUFFALO_ALIASES = ("buffalo", "buffaloes", "buff", "murrah", "bison")


def classify_species(path: Path) -> str | None:
    lower = str(path).lower().replace("\\", "/")
    for alias in BUFFALO_ALIASES:
        if alias in lower:
            return "buffalo"
    for alias in COW_ALIASES:
        if alias in lower:
            return "cow"
    return None


def collect_labeled_images(root: Path) -> list[tuple[Path, int]]:
    items: list[tuple[Path, int]] = []
    if not root.is_dir():
        return items

    for pattern in ("*.jpg", "*.jpeg", "*.png", "*.JPG", "*.PNG"):
        for img_path in root.rglob(pattern):
            species = classify_species(img_path)
            if species is None:
                species = classify_species(img_path.parent)
            if species is None:
                continue
            class_id = SPECIES_CLASSES.index(species)
            items.append((img_path, class_id))

    return items


def build_yolo_dataset(
    *,
    primary_root: Path,
    volume_root: Path | None,
    work_dir: Path,
    max_per_class: int,
    val_ratio: float,
    seed: int,
) -> tuple[Path, int]:
    random.seed(seed)
    work_dir.mkdir(parents=True, exist_ok=True)

    for split in ("train", "val"):
        (work_dir / "images" / split).mkdir(parents=True, exist_ok=True)
        (work_dir / "labels" / split).mkdir(parents=True, exist_ok=True)

    by_class: dict[int, list[Path]] = {0: [], 1: []}
    for img_path, class_id in collect_labeled_images(primary_root):
        by_class[class_id].append(img_path)

    if volume_root and volume_root.is_dir():
        vol_imgs = (
            list(volume_root.rglob("*.jpg"))
            + list(volume_root.rglob("*.jpeg"))
            + list(volume_root.rglob("*.png"))
        )
        random.shuffle(vol_imgs)
        by_class[0].extend(vol_imgs[: max_per_class])

    total = 0
    for class_id, paths in by_class.items():
        random.shuffle(paths)
        capped = paths[:max_per_class]
        n_val = max(1, int(len(capped) * val_ratio)) if capped else 0
        val_paths = capped[:n_val]
        train_paths = capped[n_val:]

        for split, split_paths in (("train", train_paths), ("val", val_paths)):
            for img_path in split_paths:
                dst_img = work_dir / "images" / split / f"{class_id}_{img_path.stem}{img_path.suffix.lower()}"
                if dst_img.exists():
                    dst_img = work_dir / "images" / split / f"{class_id}_{total}_{img_path.name}"
                shutil.copy(img_path, dst_img)
                label_path = work_dir / "labels" / split / f"{dst_img.stem}.txt"
                label_path.write_text(f"{class_id} 0.5 0.5 1.0 1.0\n", encoding="utf-8")
                total += 1

    if total == 0:
        raise SystemExit(
            f"No labeled images found under {primary_root}.\n"
            "Expected folder or path names containing 'cow' or 'buffalo' "
            "(e.g. Cow/, Buffalo/ subfolders)."
        )

    yaml_path = work_dir / "data.yaml"
    yaml_path.write_text(
        yaml.dump(
            {
                "path": str(work_dir.resolve()),
                "train": "images/train",
                "val": "images/val",
                "nc": 2,
                "names": SPECIES_CLASSES,
            }
        ),
        encoding="utf-8",
    )
    print(f"  Dataset: {total} images (cow={len(by_class[0][:max_per_class])}, "
          f"buffalo={len(by_class[1][:max_per_class])})")
    return yaml_path, total


def main() -> None:
    parser = argparse.ArgumentParser(description="Train cow/buffalo species YOLO")
    parser.add_argument(
        "--data-dir",
        required=True,
        help="Path to cows-and-buffalo-computer-vision-dataset root",
    )
    parser.add_argument(
        "--volume-dir",
        default="",
        help="Optional cattle-weight-detection-12k root (treated as cow)",
    )
    parser.add_argument(
        "--output",
        default="models/species_detector.pt",
        help="Output .pt path (default: models/species_detector.pt)",
    )
    parser.add_argument("--work-dir", default="working/species_yolo")
    parser.add_argument("--epochs", type=int, default=60)
    parser.add_argument("--imgsz", type=int, default=416)
    parser.add_argument("--batch", type=int, default=32)
    parser.add_argument("--max-per-class", type=int, default=8000)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    backend_root = Path(__file__).resolve().parent
    primary = Path(args.data_dir)
    volume = Path(args.volume_dir) if args.volume_dir else None
    work_dir = Path(args.work_dir)
    if not work_dir.is_absolute():
        work_dir = backend_root / work_dir

    output = Path(args.output)
    if not output.is_absolute():
        output = backend_root / output
    output.parent.mkdir(parents=True, exist_ok=True)

    print("Building YOLO dataset from fn1 structure…")
    yaml_path, total = build_yolo_dataset(
        primary_root=primary,
        volume_root=volume,
        work_dir=work_dir,
        max_per_class=args.max_per_class,
        val_ratio=0.2,
        seed=args.seed,
    )

    print(f"Training YOLOv8n on {total} images…")
    model = YOLO("yolov8n.pt")
    results = model.train(
        data=str(yaml_path),
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch,
        lr0=0.01,
        project=str(work_dir),
        name="species_run",
        exist_ok=True,
        patience=15,
        verbose=True,
    )

    best = work_dir / "species_run" / "weights" / "best.pt"
    if not best.is_file():
        raise SystemExit("Training finished but best.pt was not found.")

    shutil.copy(best, output)
    metrics = results.results_dict if hasattr(results, "results_dict") else {}
    map50 = float(metrics.get("metrics/mAP50(B)", 0.0))

    meta = {
        "function": "species_classification",
        "model": "YOLOv8n",
        "pytorch_model": str(output.name),
        "datasets_used": [
            "raghavdharwal/cows-and-buffalo-computer-vision-dataset",
            "sadhliroomyprime/cattle-weight-detection-model-dataset-12k",
        ],
        "input_size": args.imgsz,
        "classes": SPECIES_CLASSES,
        "conf_threshold": 0.35,
        "mAP50": round(map50, 4),
        "inference_note": "Detect cow vs buffalo; full-image pseudo labels during training",
    }
    meta_path = output.parent / "species_meta.json"
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"Saved {output}")
    print(f"Saved {meta_path}")
    print(f"mAP50: {map50:.4f}")


if __name__ == "__main__":
    main()
