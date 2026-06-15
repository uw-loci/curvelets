from __future__ import annotations

import json as _json
import subprocess
from pathlib import Path
from typing import Any

import numpy as np

from export.model import (
    CanonicalFiber,
    CanonicalImageArtifacts,
    CanonicalPoint,
    CanonicalSample,
)
from extractors.base import ExtractorAdapter

try:
    from ctfire_py import HAS_FIBER_BACKEND
    from ctfire_py import fire_2d_angle as _fire_2d_angle
except ImportError:
    HAS_FIBER_BACKEND = False
    _fire_2d_angle = None

try:
    from ctfire_py import HAS_CURVELOPS
    if HAS_CURVELOPS:
        from ctfire_py import ct_reconstruction as _ct_reconstruction
    else:
        _ct_reconstruction = None
except ImportError:
    HAS_CURVELOPS = False
    _ct_reconstruction = None


def default_fire_params() -> dict:
    """Default parameter dict for fire_2d_angle (matches ctfire_py test defaults)."""
    return {
        "sigma_im": 0,
        "sigma_d": 0.3,
        "dtype": "cityblock",
        "thresh_im": [],
        "thresh_im2": 150,
        "thresh_Dxlink": 1.5,
        "s_xlinkbox": 8,
        "thresh_LMP": 0.2,
        "thresh_LMPdist": 12,
        "thresh_ext": 0.342,
        "lam_dirdecay": 0.5,
        "s_minstep": 2,
        "s_maxstep": 6,
        "thresh_dang_aextend": 0.9848,
        "thresh_dang_L": 15,
        "thresh_short_L": 15,
        "s_fiberdir": 4,
        "thresh_linkd": 15,
        "thresh_linka": -0.866,
        "thresh_flen": 15,
        "min_fiber_length": 30,
        "thresh_numv": 3,
        "scale": [1.0, 1.0, 1.0],
        "s_boundthick": 10,
        "blist": 1,
        "s_maxspace": 5,
        "lambda": 0.01,
        "ang_interval": 3,
        # CT-FIRE curvelet preprocessing params (ignored in FIRE-only mode)
        "coefficient_percentile": 0.2,
        "num_scales": 4,
    }

from core.metrics import rasterize_fiber_result

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_SUBPROCESS_SCRIPT = Path(__file__).resolve().parent / "run_ctfire_subprocess.py"


def _ucrt64_python() -> Path:
    """Return the path to the UCRT64 venv Python, or raise if not found."""
    candidates = [
        # MSYS2 venv on Windows — bin/ directory, exe may or may not have extension
        _PROJECT_ROOT / ".venv" / "bin" / "python3.exe",
        _PROJECT_ROOT / ".venv" / "bin" / "python.exe",
        _PROJECT_ROOT / ".venv" / "bin" / "python3",
        _PROJECT_ROOT / ".venv" / "bin" / "python",
        # Standard Windows venv
        _PROJECT_ROOT / ".venv" / "Scripts" / "python.exe",
    ]
    for p in candidates:
        if p.exists():
            return p
    raise RuntimeError(
        "UCRT64 venv not found at .venv/.\n"
        "Run setup_ucrt64_env.sh in the MSYS2 UCRT64 terminal first.\n"
        f"(looked for python in: {_PROJECT_ROOT / '.venv' / 'bin'} and {_PROJECT_ROOT / '.venv' / 'Scripts'})"
    )


class CTFireAdapter(ExtractorAdapter):
    name = "ct_fire"
    version = "fire_2d_angle"

    def parse(self, inputs: dict[str, Any]) -> CanonicalSample:
        """Run fiber extraction on an image file.

        inputs: {"image_path": str | Path, "params": dict | None,
                 "use_ct_reconstruction": bool}

        When called from the main app (standard Python, no fiber_backend), this
        delegates to the UCRT64 venv via subprocess.  When called from inside the
        UCRT64 venv (fiber_backend available), it runs directly.
        """
        if HAS_FIBER_BACKEND and _fire_2d_angle is not None:
            use_ct = inputs.get("use_ct_reconstruction", False) and HAS_CURVELOPS
            if use_ct:
                return self._parse_with_ct_reconstruction(inputs)
            return self._parse_direct(inputs)
        return self._parse_via_subprocess(inputs)

    def extractor_params(self) -> dict[str, Any]:
        return default_fire_params()

    # ------------------------------------------------------------------
    # Direct path — FIRE-only (no curvelet preprocessing)
    # ------------------------------------------------------------------

    def _parse_direct(self, inputs: dict[str, Any]) -> CanonicalSample:
        from PIL import Image

        image_path = Path(inputs["image_path"])
        im = np.array(Image.open(image_path).convert("L"), dtype=np.float64)
        return self._parse_direct_from_array(im, inputs, image_path)

    # ------------------------------------------------------------------
    # CT-FIRE path — curvelet reconstruction → FIRE (requires curvelops)
    # ------------------------------------------------------------------

    def _parse_with_ct_reconstruction(self, inputs: dict[str, Any]) -> CanonicalSample:
        from PIL import Image

        image_path = Path(inputs["image_path"])
        im = np.array(Image.open(image_path).convert("L"), dtype=np.float64)
        p = inputs.get("params") or default_fire_params()
        enhanced = _ct_reconstruction(
            im,
            str(image_path),
            p.get("coefficient_percentile", 0.2),
            int(p.get("num_scales", 4)),
            plot_flag=False,
        )
        return self._parse_direct_from_array(enhanced, inputs, image_path)

    # ------------------------------------------------------------------
    # Shared fire_2d_angle call + CanonicalSample construction
    # ------------------------------------------------------------------

    def _parse_direct_from_array(
        self, im: "np.ndarray", inputs: dict[str, Any], image_path: Path
    ) -> CanonicalSample:
        import sys as _sys
        p = inputs.get("params") or default_fire_params()
        # Strip internal control keys before passing to fire_2d_angle
        fire_p = {k: v for k, v in p.items() if not k.startswith("_")}
        # Diagnostic: print exact params and image stats to terminal for troubleshooting
        print("=== fire_2d_angle params ===", file=_sys.stderr)
        for k, v in sorted(fire_p.items()):
            print(f"  {k}: {v!r}", file=_sys.stderr)
        print(
            f"  image shape: {im.shape}  dtype: {im.dtype}"
            f"  min: {float(im.min()):.1f}  max: {float(im.max()):.1f}",
            file=_sys.stderr,
        )
        print("===========================", file=_sys.stderr)
        result = _fire_2d_angle(fire_p, im, plotflag=0)

        fibers = _build_canonical_fibers(result)
        centerline_mask = _build_centerline_mask(result, im.shape)
        overlay = _build_overlay_image(im, result)

        return CanonicalSample(
            sample_id=image_path.stem,
            image_id=image_path.name,
            is_3d=False,
            dims_px=(1, int(im.shape[0]), int(im.shape[1])),
            source_algorithm=self.name,
            source_type="extracted_centerlines",
            fibers=fibers,
            images=CanonicalImageArtifacts(centerline_mask=centerline_mask, overlay_image=overlay),
            extractor_recipe={"params": fire_p},
        )

    # ------------------------------------------------------------------
    # Subprocess path — main app delegates to UCRT64 venv
    # ------------------------------------------------------------------

    def _parse_via_subprocess(self, inputs: dict[str, Any]) -> CanonicalSample:
        import os

        image_path = Path(inputs["image_path"])
        output_dir = _PROJECT_ROOT / "output_ctfire"
        output_dir.mkdir(parents=True, exist_ok=True)

        python = _ucrt64_python()

        # MSYS2 DLLs (numpy, scipy, matplotlib C extensions) live in ucrt64/bin.
        # The subprocess inherits the main app's PATH which won't include MSYS2,
        # so inject it explicitly to prevent DLL load failures.
        ucrt64_bin = r"C:\msys64\ucrt64\bin"
        env = os.environ.copy()
        path_parts = env.get("PATH", "").split(os.pathsep)
        if ucrt64_bin not in path_parts:
            env["PATH"] = ucrt64_bin + os.pathsep + env["PATH"]

        p = dict(inputs.get("params") or default_fire_params())
        # Embed mode flag in params JSON rather than adding a separate CLI arg
        p["_use_ct_reconstruction"] = bool(inputs.get("use_ct_reconstruction", False))
        params_json = _json.dumps(p)
        proc = subprocess.run(
            [str(python), str(_SUBPROCESS_SCRIPT), str(image_path), str(output_dir), params_json],
            stdout=subprocess.PIPE,
            stderr=None,   # inherit — progress and errors stream to the user's terminal
            text=True,
            timeout=300,
            env=env,
        )
        if proc.returncode != 0:
            raise RuntimeError(
                f"CT-FIRE subprocess failed (exit {proc.returncode}). See terminal for details."
            )

        # Take the last non-empty stdout line — fiber_backend C prints may also land on stdout
        stdout_lines = [l.strip() for l in proc.stdout.splitlines() if l.strip()]
        if not stdout_lines:
            raise RuntimeError(
                f"CT-FIRE subprocess produced no output (exit {proc.returncode})."
            )
        info = _json.loads(stdout_lines[-1])
        return _load_sample_from_files(
            tif_path=Path(info["tif"]),
            json_path=Path(info["json"]),
            image_path=image_path,
            stem=info["stem"],
            overlay_tif=info.get("overlay_tif"),
        )


# ---------------------------------------------------------------------------
# Helpers shared by direct path and result reconstruction
# ---------------------------------------------------------------------------

def _first_nonempty(result: dict, *keys):
    """Return the first value from result[keys] that is non-None and non-empty.

    Safe for numpy arrays: avoids the ambiguous truth-value error by checking
    .size instead of bool(arr).
    """
    for key in keys:
        val = result.get(key)
        if val is None:
            continue
        try:
            if np.asarray(val).size > 0:
                return val
        except (TypeError, ValueError):
            if val:
                return val
    return None


def _build_canonical_fibers(result: dict) -> list[CanonicalFiber]:
    """Convert fire_2d_angle output to CanonicalFiber list.

    Prefer CurveAlign-filtered output (Xf/Ff, fibers ≥30 px); fall back to
    network-level (Xa/Fa) then raw (X/F).
    X arrays are [row, col, ...].  Map: x_px = col, y_px = row.

    radius_px (half-width = distance to background) is read from result["Ra"],
    which is indexed by result["Xa"] vertices.  After fiberbreak/curvealign_filter
    the vertex array is re-indexed by trimxfv, but coordinate values are preserved,
    so we match each Xf vertex back to Xa by (row, col) to look up Ra.
    """
    X = _first_nonempty(result, "Xf", "Xa", "X")
    F = _first_nonempty(result, "Ff", "Fa", "F")
    if X is None or F is None or len(X) == 0 or len(F) == 0:
        return []

    # Build coordinate → radius lookup from Xa/Ra (Ra corresponds to Xa vertex indices).
    # Xf vertices are a re-indexed subset of Xa with the same coordinate values.
    radius_lookup: dict[tuple[int, int], float] = {}
    try:
        _xa_raw = result.get("Xa")
        _ra_raw = result.get("Ra")
        _Xa = np.asarray(_xa_raw if _xa_raw is not None else [])
        _Ra = np.asarray(_ra_raw if _ra_raw is not None else [])
        if _Xa.ndim == 2 and _Xa.shape[0] > 0 and len(_Ra) == len(_Xa):
            for _i in range(len(_Xa)):
                _key = (round(float(_Xa[_i, 0])), round(float(_Xa[_i, 1])))
                radius_lookup[_key] = float(_Ra[_i])
    except Exception:
        pass  # width will be None for all points if lookup fails

    X_arr = np.asarray(X)
    fibers: list[CanonicalFiber] = []
    for fiber_id, fiber in enumerate(F):
        v_list = fiber["v"] if isinstance(fiber, dict) else list(fiber)
        points: list[CanonicalPoint] = []
        for pt_idx, v in enumerate(v_list):
            if v >= len(X_arr):
                continue
            row = float(X_arr[v, 0])
            col = float(X_arr[v, 1])
            radius_px = radius_lookup.get((round(row), round(col)))
            points.append(
                CanonicalPoint(
                    point_index=pt_idx,
                    x_px=col,
                    y_px=row,
                    radius_px=radius_px,
                    source_type="extracted_centerlines",
                )
            )
        if len(points) >= 2:
            fibers.append(
                CanonicalFiber(
                    fiber_id=fiber_id,
                    points=points,
                    source_algorithm="ct_fire",
                    source_type="extracted_centerlines",
                )
            )
    return fibers


def _build_centerline_mask(result: dict, image_shape: tuple) -> np.ndarray:
    """Rasterize extracted fiber centerlines to a uint8 binary skeleton image."""
    X = _first_nonempty(result, "Xf", "Xa", "X")
    F = _first_nonempty(result, "Ff", "Fa", "F")
    if X is None or F is None or len(X) == 0 or len(F) == 0:
        return np.zeros(image_shape[:2], dtype=np.uint8)
    return rasterize_fiber_result(X, F, image_shape)


def _build_overlay_image(im: np.ndarray, result: dict) -> np.ndarray:
    """RGB uint8 array: each fiber drawn in a unique HSV color on a grayscale background.

    Colors cycle by fiber index (hue = i / n_fibers) — not angle-based.
    """
    import colorsys

    from skimage.draw import line as draw_line

    img_u8 = np.clip(im, 0, 255).astype(np.uint8)
    rgb = np.stack([img_u8, img_u8, img_u8], axis=-1)

    X = _first_nonempty(result, "Xf", "X")
    F = _first_nonempty(result, "Ff", "F")
    if X is None or F is None or len(X) == 0 or len(F) == 0:
        return rgb

    X_arr = np.asarray(X)
    H, W = im.shape[:2]
    n = max(len(F), 1)

    for i, fiber in enumerate(F):
        hue = (i / n) % 1.0
        r_f, g_f, b_f = colorsys.hsv_to_rgb(hue, 1.0, 1.0)
        color = (int(r_f * 255), int(g_f * 255), int(b_f * 255))
        v_list = fiber["v"] if isinstance(fiber, dict) else list(fiber)
        for seg in range(len(v_list) - 1):
            v0, v1 = v_list[seg], v_list[seg + 1]
            if v0 >= len(X_arr) or v1 >= len(X_arr):
                continue
            r0 = int(np.clip(round(float(X_arr[v0, 0])), 0, H - 1))
            c0 = int(np.clip(round(float(X_arr[v0, 1])), 0, W - 1))
            r1 = int(np.clip(round(float(X_arr[v1, 0])), 0, H - 1))
            c1 = int(np.clip(round(float(X_arr[v1, 1])), 0, W - 1))
            rr, cc = draw_line(r0, c0, r1, c1)
            rgb[rr, cc] = color

    return rgb


def _load_sample_from_files(
    tif_path: Path, json_path: Path, image_path: Path, stem: str,
    overlay_tif: str | None = None,
) -> CanonicalSample:
    """Reconstruct a CanonicalSample from subprocess output files."""
    import tifffile

    centerline_mask = tifffile.imread(str(tif_path))

    overlay = None
    if overlay_tif:
        p = Path(overlay_tif)
        if p.exists():
            overlay = tifffile.imread(str(p))

    with open(json_path) as fh:
        data = _json.load(fh)

    fibers: list[CanonicalFiber] = []
    for f in data.get("fibers", []):
        points = [
            CanonicalPoint(
                point_index=p["point_index"],
                x_px=p["x_px"],
                y_px=p["y_px"],
                z_px=p.get("z_px", 0.0),
                radius_px=p.get("radius_px"),
                source_type=p.get("source_type", "extracted_centerlines"),
            )
            for p in f.get("points", [])
        ]
        fibers.append(
            CanonicalFiber(
                fiber_id=f["fiber_id"],
                points=points,
                source_algorithm=f.get("source_algorithm", "ct_fire"),
                source_type=f.get("source_type", "extracted_centerlines"),
            )
        )

    dims = data.get("dims_px", {"x": 1, "y": centerline_mask.shape[0], "z": centerline_mask.shape[1]})

    return CanonicalSample(
        sample_id=stem,
        image_id=image_path.name,
        is_3d=data.get("is_3d", False),
        dims_px=(dims["x"], dims["y"], dims["z"]),
        source_algorithm=data.get("source_algorithm", "ct_fire"),
        source_type=data.get("source_type", "extracted_centerlines"),
        fibers=fibers,
        images=CanonicalImageArtifacts(centerline_mask=centerline_mask, overlay_image=overlay),
        extractor_recipe={},
    )
