from __future__ import annotations

import json
from pathlib import Path

from generation.collections import ImageCollection, ImageCollection3D

ROOT = Path(__file__).resolve().parent.parent
DEFAULTS_DIR = ROOT / "config" / "defaults"
DEFAULT_2D_PATH = DEFAULTS_DIR / "2d.json"
DEFAULT_3D_PATH = DEFAULTS_DIR / "3d.json"
DEFAULT_BASE_PATH = DEFAULTS_DIR / "base.json"


def resolve_default_params_path(is_3d: bool) -> Path:
    return DEFAULT_3D_PATH if is_3d else DEFAULT_2D_PATH


def read_json(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path, payload):
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)


def _read_params_dict(filename: str) -> dict:
    try:
        with open(filename, encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError as exc:
        raise OSError(f'File "{filename}" not found') from exc
    except OSError as exc:
        raise OSError(f'Error when reading "{filename}"') from exc
    except json.JSONDecodeError as exc:
        raise OSError(f'Malformed parameters file "{filename}"') from exc


def _finalize_loaded_params(params, params_dict: dict, filename: str):
    if "length" not in params_dict:
        raise KeyError(f"'length' key not found in params file {filename}")
    if "straightness" not in params_dict:
        raise KeyError(f"'straightness' key not found in params file {filename}")
    if "width" not in params_dict:
        raise KeyError(f"'width' key not found in params file {filename}")

    params.length.set_bounds(0, float("inf"))
    params.straightness.set_bounds(0, 1)
    params.width.set_bounds(0, float("inf"))
    if "intensity" in params_dict:
        params.intensity.set_bounds(0, 255)
    params.set_names()
    params.set_hints()
    return params


def load_params_2d_file(filename: str):
    params_dict = _read_params_dict(filename)
    params = ImageCollection.Params.from_dict(params_dict)
    return _finalize_loaded_params(params, params_dict, filename)


def load_params_3d_file(filename: str):
    params_dict = _read_params_dict(filename)
    params = ImageCollection3D.Params.from_dict(params_dict)
    return _finalize_loaded_params(params, params_dict, filename)


def load_params_file_auto(filename: str):
    params_dict = _read_params_dict(filename)
    if "imageDepth" in params_dict:
        params = ImageCollection3D.Params.from_dict(params_dict)
        return _finalize_loaded_params(params, params_dict, filename), True
    params = ImageCollection.Params.from_dict(params_dict)
    return _finalize_loaded_params(params, params_dict, filename), False


class ParamsLoader2D:
    def read_params_file(self, filename: str):
        return load_params_2d_file(filename)


class ParamsLoader3D:
    def read_params_file(self, filename: str):
        return load_params_3d_file(filename)
