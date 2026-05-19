import json
import os
import sys
from functools import lru_cache

import numpy as np

DEFAULT_STAGE2_PIPELINE_NAME = "Stage 2 cGAN (Centerline -> SHG)"

_STAGE2_DIST_ROOT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..",
    "vendor",
    "centerline2shg_stage2",
    "collagen_stage2_inference",
)
_STAGE2_DIST_ROOT = os.path.abspath(_STAGE2_DIST_ROOT)
_STAGE2_DEFAULT_MODEL_DIR = os.path.join(_STAGE2_DIST_ROOT, "model")
_STAGE2_DEFAULT_PARAM_PATH = os.path.join(_STAGE2_DIST_ROOT, "parameters", "params_stage2.json")


def get_default_stage2_model_dir():
    return _STAGE2_DEFAULT_MODEL_DIR


def _resolve_device(requested):
    requested = str(requested or "auto").strip().lower()
    import torch

    if requested in ("cpu",):
        return "cpu"
    if requested in ("cuda", "cuda:0"):
        if not torch.cuda.is_available():
            raise RuntimeError("CUDA was requested for Stage 2 cGAN, but CUDA is not available.")
        return "cuda:0"
    if requested in ("mps",):
        if getattr(torch.backends, "mps", None) is None or not torch.backends.mps.is_available():
            raise RuntimeError("MPS was requested for Stage 2 cGAN, but MPS is not available.")
        return "mps"
    if requested in ("auto", ""):
        if torch.cuda.is_available():
            return "cuda:0"
        if getattr(torch.backends, "mps", None) is not None and torch.backends.mps.is_available():
            return "mps"
        return "cpu"
    raise ValueError(f"Unsupported Stage 2 cGAN device option: {requested}")


@lru_cache(maxsize=1)
def _load_stage2_modules():
    if not os.path.isdir(_STAGE2_DIST_ROOT):
        raise FileNotFoundError(f"Stage 2 cGAN distribution not found: {_STAGE2_DIST_ROOT}")

    if _STAGE2_DIST_ROOT not in sys.path:
        sys.path.insert(0, _STAGE2_DIST_ROOT)

    import torch
    from modules.models import cGAN
    from modules.utils.util_model import load_model

    return torch, cGAN, load_model


@lru_cache(maxsize=4)
def _load_stage2_model_cached(model_dir, resolved_device):
    torch, cGAN, load_model = _load_stage2_modules()

    if not model_dir:
        model_dir = _STAGE2_DEFAULT_MODEL_DIR
    model_dir = os.path.abspath(model_dir)
    if os.path.isfile(model_dir):
        model_dir = os.path.dirname(model_dir)
    if not os.path.isdir(model_dir):
        raise FileNotFoundError(f"Stage 2 cGAN model directory not found: {model_dir}")
    generator_path = os.path.join(model_dir, "G.pt")
    if not os.path.isfile(generator_path):
        raise FileNotFoundError(f"Stage 2 cGAN generator weights not found: {generator_path}")
    if not os.path.isfile(_STAGE2_DEFAULT_PARAM_PATH):
        raise FileNotFoundError(f"Stage 2 cGAN parameter file not found: {_STAGE2_DEFAULT_PARAM_PATH}")

    with open(_STAGE2_DEFAULT_PARAM_PATH, "r", encoding="utf-8") as handle:
        params = json.load(handle)

    model = cGAN(params=params, is_train=False, device=resolved_device)
    load_model(model, model_dir, world_size=1, logger=None)
    model = model.to(resolved_device)
    model.eval()
    return model


def is_stage2_cgan_available(model_dir=None):
    try:
        import torch  # noqa: F401
        import torchvision  # noqa: F401
    except Exception as exc:
        return False, f"PyTorch dependencies are unavailable: {exc}"

    try:
        _load_stage2_modules()
    except Exception as exc:
        return False, f"Stage 2 cGAN package could not be imported: {exc}"

    candidate_model_dir = os.path.abspath(model_dir or _STAGE2_DEFAULT_MODEL_DIR)
    if os.path.isfile(candidate_model_dir):
        candidate_model_dir = os.path.dirname(candidate_model_dir)
    generator_path = os.path.join(candidate_model_dir, "G.pt")
    if not os.path.isfile(generator_path):
        return False, f"Generator weights not found: {generator_path}"
    if not os.path.isfile(_STAGE2_DEFAULT_PARAM_PATH):
        return False, f"Parameter file not found: {_STAGE2_DEFAULT_PARAM_PATH}"

    return True, f"Ready ({candidate_model_dir})"


def load_stage2_cgan(model_dir=None, device="auto"):
    resolved_device = _resolve_device(device)
    model_dir = os.path.abspath(model_dir or _STAGE2_DEFAULT_MODEL_DIR)
    if os.path.isfile(model_dir):
        model_dir = os.path.dirname(model_dir)
    return _load_stage2_model_cached(model_dir, resolved_device)


def _prepare_centerline_input(centerline_np):
    arr = np.asarray(centerline_np)
    if arr.ndim != 2:
        raise ValueError(f"Stage 2 cGAN expects a 2D centerline image, got shape {arr.shape}")
    arr = arr.astype(np.float32)
    if arr.max() > 1.0 or arr.min() < 0.0:
        arr = np.clip(arr, 0.0, 255.0) / 255.0
    else:
        arr = np.clip(arr, 0.0, 1.0)
    return arr


def run_stage2_cgan(centerline_np, model_dir=None, device="auto"):
    torch, _, _ = _load_stage2_modules()
    resolved_device = _resolve_device(device)
    model = load_stage2_cgan(model_dir=model_dir, device=resolved_device)

    centerline_arr = _prepare_centerline_input(centerline_np)
    centerline_t = torch.from_numpy(centerline_arr).unsqueeze(0).unsqueeze(0).to(resolved_device)

    _, _, height, width = centerline_t.shape
    pad_h = (64 - height % 64) % 64
    pad_w = (64 - width % 64) % 64
    if pad_h > 0 or pad_w > 0:
        centerline_t = torch.nn.functional.pad(centerline_t, (0, pad_w, 0, pad_h), mode="reflect")

    with torch.no_grad():
        generated_t = model.forward(centerline_t)

    if pad_h > 0 or pad_w > 0:
        generated_t = generated_t[:, :, :height, :width]

    generated_np = (generated_t.detach().cpu().numpy().squeeze() + 1.0) / 2.0
    generated_np = np.clip(generated_np, 0.0, 1.0).astype(np.float32)
    return (generated_np * 255.0).astype(np.uint8)


def build_stage2_enhancement_recipe(model_dir=None, device="auto"):
    resolved_device = _resolve_device(device)
    resolved_model_dir = os.path.abspath(model_dir or _STAGE2_DEFAULT_MODEL_DIR)
    if os.path.isfile(resolved_model_dir):
        resolved_model_dir = os.path.dirname(resolved_model_dir)
    return {
        "pipeline_name": DEFAULT_STAGE2_PIPELINE_NAME,
        "pipeline_key": "stage2_cgan_centerline_to_shg",
        "mode": "2D",
        "input_type": "centerline_mask",
        "modality": "SHG",
        "model_dir": resolved_model_dir,
        "generator_weights": os.path.join(resolved_model_dir, "G.pt"),
        "parameter_file": _STAGE2_DEFAULT_PARAM_PATH,
        "device": resolved_device,
    }
