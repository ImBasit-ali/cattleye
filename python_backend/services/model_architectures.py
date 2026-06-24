"""Neural network definitions matching assets/models/*_meta.json checkpoints."""
from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F
import timm
from torchvision import models


class BehaviorClassifier(nn.Module):
    """MobileNetV3-Small — 5 behavior classes."""

    def __init__(self, num_classes: int = 5):
        super().__init__()
        base = models.mobilenet_v3_small(weights=None)
        in_features = base.classifier[0].in_features
        base.classifier = nn.Sequential(
            nn.Linear(in_features, 1024),
            nn.Hardswish(),
            nn.Dropout(0.2),
            nn.Sequential(nn.Identity(), nn.Linear(1024, num_classes)),
        )
        self.net = base

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


class BcsScorer(nn.Module):
    """EfficientNet-B3 backbone + ordinal head (8 logits)."""

    def __init__(self, num_bins: int = 8):
        super().__init__()
        self.bb = timm.create_model("efficientnet_b3", pretrained=False, num_classes=0)
        self.head = nn.Sequential(
            nn.Dropout(0.3),
            nn.Linear(1536, 512),
            nn.ReLU(),
            nn.Identity(),
            nn.Linear(512, num_bins),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.head(self.bb(x))


class MuzzleEmbedder(nn.Module):
    """ResNet50 backbone → 256-d embedding (L2-normalised in service)."""

    def __init__(self, embed_dim: int = 256):
        super().__init__()
        backbone = models.resnet50(weights=None)
        backbone.fc = nn.Identity()
        self.bb = backbone
        self.head = nn.Sequential(
            nn.Linear(2048, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, embed_dim),
            nn.BatchNorm1d(embed_dim),
        )
        self.embed_dim = embed_dim

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.head(self.bb(x))


class LamenessBiLSTM(nn.Module):
    """LayerNorm → proj → BiLSTM → attention → classifier."""

    def __init__(
        self,
        feat_dim: int = 51,
        hidden: int = 128,
        num_layers: int = 2,
        num_classes: int = 2,
    ):
        super().__init__()
        self.norm = nn.LayerNorm(feat_dim)
        self.proj = nn.Linear(feat_dim, hidden)
        self.lstm = nn.LSTM(
            hidden,
            hidden,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
        )
        self.attn = nn.Linear(hidden * 2, 1)
        self.cls = nn.Sequential(
            nn.ReLU(),
            nn.Linear(hidden * 2, 64),
            nn.ReLU(),
            nn.Linear(64, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.norm(x)
        x = self.proj(x)
        out, _ = self.lstm(x)
        weights = torch.softmax(self.attn(out).squeeze(-1), dim=1)
        context = torch.sum(out * weights.unsqueeze(-1), dim=1)
        return self.cls(context)


def load_split_checkpoint(
    model: nn.Module,
    path: str,
    *,
    prefixes: dict[str, str] | None = None,
) -> nn.Module:
    """Load a flat state dict into a model, optionally splitting by submodule prefix."""
    ckpt = torch.load(path, map_location="cpu", weights_only=False)
    if isinstance(ckpt, torch.nn.Module):
        return ckpt

    state = ckpt
    if isinstance(ckpt, dict):
        state = ckpt.get("state_dict") or ckpt.get("model_state_dict") or ckpt

    if not isinstance(state, dict):
        raise ValueError(f"Unsupported checkpoint format: {path}")

    if prefixes:
        for prefix, attr in prefixes.items():
            submodule = getattr(model, attr)
            sub_state = {k[len(prefix) :]: v for k, v in state.items() if k.startswith(prefix)}
            submodule.load_state_dict(sub_state, strict=True)
        return model

    model.load_state_dict(state, strict=True)
    return model
