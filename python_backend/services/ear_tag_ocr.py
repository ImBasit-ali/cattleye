"""TrOCR-based ear tag number reading (microsoft/trocr-small-printed)."""
from __future__ import annotations

import os
import re
from typing import TYPE_CHECKING

import torch
from PIL import Image, ImageEnhance, ImageOps

if TYPE_CHECKING:
    from transformers import TrOCRProcessor, VisionEncoderDecoderModel


def _truthy(value: str | None, *, default: bool = True) -> bool:
    if value is None:
        return default
    return value.strip().lower() in ("1", "true", "yes", "on")


def normalize_tag_text(raw: str) -> str | None:
    """Extract a plausible ear-tag ID from TrOCR output."""
    text = raw.strip().upper()
    if not text:
        return None

    cleaned = re.sub(r"[^A-Z0-9]", "", text)
    if len(cleaned) >= 2:
        return cleaned

    digits = re.sub(r"\D", "", text)
    if len(digits) >= 3:
        return digits

    return None


class EarTagOcrService:
    """Lazy-loaded TrOCR reader for cropped ear-tag patches."""

    def __init__(
        self,
        *,
        model_name: str | None = None,
        device: torch.device | None = None,
        enabled: bool | None = None,
    ) -> None:
        self._model_name = model_name or os.getenv(
            "TROCR_MODEL", "microsoft/trocr-small-printed"
        )
        self._device = device or torch.device(
            "cuda" if torch.cuda.is_available() else "cpu"
        )
        self._enabled = (
            enabled
            if enabled is not None
            else _truthy(os.getenv("ENABLE_EARTAG_OCR"), default=True)
        )
        self._ready = False
        self._processor: TrOCRProcessor | None = None
        self._model: VisionEncoderDecoderModel | None = None
        self._load_error: str | None = None

    @property
    def is_enabled(self) -> bool:
        return self._enabled

    @property
    def is_ready(self) -> bool:
        return self._ready

    @property
    def load_error(self) -> str | None:
        return self._load_error

    def initialize(self) -> None:
        if not self._enabled or self._ready:
            return

        try:
            from transformers import TrOCRProcessor, VisionEncoderDecoderModel
        except ImportError as exc:
            self._load_error = (
                "transformers not installed — pip install transformers"
            )
            self._enabled = False
            raise RuntimeError(self._load_error) from exc

        self._processor = TrOCRProcessor.from_pretrained(self._model_name)
        self._model = VisionEncoderDecoderModel.from_pretrained(self._model_name)
        self._model.to(self._device)
        self._model.eval()
        self._ready = True

    def _prepare_patch(self, patch: Image.Image) -> Image.Image:
        img = ImageOps.exif_transpose(patch.convert("RGB"))
        w, h = img.size
        if max(w, h) < 96:
            scale = 96 / max(w, h)
            img = img.resize(
                (max(32, int(w * scale)), max(32, int(h * scale))),
                Image.Resampling.LANCZOS,
            )
        img = ImageEnhance.Contrast(img).enhance(1.35)
        img = ImageEnhance.Sharpness(img).enhance(1.2)
        return img

    def read_tag(self, patch: Image.Image) -> tuple[str | None, int]:
        """Return (tag_number, ocr_confidence 0-100)."""
        if not self._enabled:
            return None, 0

        if not self._ready:
            try:
                self.initialize()
            except RuntimeError:
                return None, 0

        assert self._processor is not None
        assert self._model is not None

        img = self._prepare_patch(patch)
        pixel_values = self._processor(
            images=img,
            return_tensors="pt",
        ).pixel_values.to(self._device)

        with torch.no_grad():
            generated = self._model.generate(
                pixel_values,
                max_new_tokens=16,
                num_beams=4,
            )

        raw = self._processor.batch_decode(generated, skip_special_tokens=True)[0]
        tag = normalize_tag_text(raw)

        if not tag:
            return None, 0

        # TrOCR has no token-level confidence — score from output length match.
        conf = min(99, max(45, 50 + len(tag) * 8))
        return tag, conf
