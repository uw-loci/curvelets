#!/usr/bin/env python3
"""Standalone CT-FIRE extraction script — run inside the UCRT64 venv.

Called by CTFireAdapter._parse_via_subprocess() in the main app.

Usage:
    python run_ctfire_subprocess.py <image_path> <output_dir>

Writes:
    <output_dir>/<stem>_centerlines.tif   uint8 centerline mask (values 0/1)
    <output_dir>/<stem>_fibers.json       to_centerlines_json() format

Prints a single JSON line to stdout:
    {"tif": "<abs_path>", "json": "<abs_path>", "n_fibers": N, "stem": "<stem>"}

Exit codes:
    0 — success
    1 — bad arguments
    2 — fiber_backend unavailable
    3 — extraction error
"""
from __future__ import annotations

import json
import sys
import types
from pathlib import Path

# Ensure the project root (parent of extractors/) is on sys.path so that
# core, export, extractors are importable without an editable install.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

# ctfire_py/ct_fire.py has top-level `import matplotlib.pyplot / .cm / .colors`.
# On MSYS2 UCRT64, matplotlib's C extension (_path) can fail with a DLL version
# mismatch even when C:\msys64\ucrt64\bin is on PATH.  Stub matplotlib out before
# ctfire_py is imported; the stub is safe because ct_fire only calls matplotlib
# inside plotting helpers that are never reached when plotflag=0.
def _try_import_matplotlib() -> bool:
    """Return True if matplotlib loaded cleanly, False if a DLL error occurred."""
    try:
        import matplotlib          # noqa: F401
        import matplotlib.pyplot   # noqa: F401
        import matplotlib.cm       # noqa: F401
        import matplotlib.colors   # noqa: F401
        return True
    except (ImportError, OSError):
        return False

if not _try_import_matplotlib():
    for _mod_name in [
        "matplotlib",
        "matplotlib.pyplot",
        "matplotlib.cm",
        "matplotlib.colors",
        "matplotlib.figure",
        "matplotlib.transforms",
        "matplotlib.backends",
        "matplotlib.backends.backend_agg",
    ]:
        sys.modules[_mod_name] = types.ModuleType(_mod_name)


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: run_ctfire_subprocess.py <image_path> <output_dir> [params_json]", file=sys.stderr)
        return 1

    image_path = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)

    params: dict | None = None
    use_ct = False
    if len(sys.argv) >= 4:
        try:
            params = json.loads(sys.argv[3])
            # Extract reserved mode flag before passing params to fire_2d_angle
            if params:
                use_ct = bool(params.pop("_use_ct_reconstruction", False))
        except (json.JSONDecodeError, ValueError):
            pass

    try:
        from ctfire_py import HAS_FIBER_BACKEND
    except ImportError:
        HAS_FIBER_BACKEND = False

    if not HAS_FIBER_BACKEND:
        print(
            "ERROR: fiber_backend not available in this Python interpreter.\n"
            "Make sure you are running inside the UCRT64 venv (.venv/bin/python3)\n"
            "and that C:\\msys64\\ucrt64\\bin is on the Windows System PATH.",
            file=sys.stderr,
        )
        return 2

    # Route fire_2d_angle progress prints to stderr (visible in terminal)
    # so only the final JSON result goes to stdout (captured by the main app).
    _real_stdout = sys.stdout
    sys.stdout = sys.stderr
    try:
        from extractors.ct_fire import CTFireAdapter

        sample = CTFireAdapter().parse({
            "image_path": image_path,
            "params": params,
            "use_ct_reconstruction": use_ct,
        })
    except Exception as exc:
        sys.stdout = _real_stdout
        print(f"ERROR: extraction failed: {exc}", file=sys.stderr)
        return 3
    finally:
        sys.stdout = _real_stdout

    stem = sample.sample_id
    tif_path = output_dir / f"{stem}_centerlines.tif"
    json_path = output_dir / f"{stem}_fibers.json"

    import numpy as np
    import tifffile

    if sample.images.centerline_mask is not None:
        mask = sample.images.centerline_mask
        if mask.max() <= 1:
            mask = (mask.astype(np.uint8)) * 255
        tifffile.imwrite(str(tif_path), mask.astype(np.uint8))
    else:
        tifffile.imwrite(str(tif_path), np.zeros((1, 1), dtype=np.uint8))

    with open(json_path, "w") as fh:
        json.dump(sample.to_centerlines_json(), fh, indent=2)

    result = {
        "tif": str(tif_path.resolve()),
        "json": str(json_path.resolve()),
        "n_fibers": len(sample.fibers),
        "stem": stem,
    }

    if sample.images.overlay_image is not None:
        overlay_path = output_dir / f"{stem}_overlay.tif"
        tifffile.imwrite(str(overlay_path), sample.images.overlay_image)
        result["overlay_tif"] = str(overlay_path.resolve())

    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
