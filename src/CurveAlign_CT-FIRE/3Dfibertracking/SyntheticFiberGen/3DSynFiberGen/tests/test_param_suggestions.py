"""Level 1 & 2 tests for the Suggest Generator Params feature.

Run from 3DSynFiberGen root:
    .venv/bin/python tests/test_param_suggestions.py
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Force UTF-8 output so Unicode chars (mu, arrows, checkmarks) work on Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

import importlib.util

import numpy as np

# app/__init__.py does "from .main_window import MainWindow" which pulls in
# matplotlib and napari — both may fail on UCRT64 outside the GUI process.
# Load param_suggestions directly by file path to avoid that chain.
def _load_param_suggestions():
    root = Path(__file__).resolve().parent.parent
    spec = importlib.util.spec_from_file_location(
        "param_suggestions",
        root / "app" / "controllers" / "param_suggestions.py",
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

# ---------------------------------------------------------------------------
# Level 1: param_suggestions.py — pure logic, no CT-FIRE, no Qt
# ---------------------------------------------------------------------------

def test_level1_suggestions():
    print("=" * 60)
    print("LEVEL 1: param_suggestions.py")
    print("=" * 60)

    from export.model import (
        CanonicalFiber, CanonicalImageArtifacts, CanonicalPoint, CanonicalSample,
    )
    ps = _load_param_suggestions()
    suggest_params_from_sample = ps.suggest_params_from_sample
    format_suggestions_summary  = ps.format_suggestions_summary
    apply_suggestions_to_params = ps.apply_suggestions_to_params

    # Build 5 diagonal fibers with known geometry and radius_px
    fibers = []
    for i in range(5):
        pts = [
            CanonicalPoint(
                point_index=j,
                x_px=float(j * 10 + i * 5),
                y_px=float(j * 8),
                radius_px=2.5 + i * 0.2,   # half-width 2.5–3.3 px → width 5–6.6 px
            )
            for j in range(10)
        ]
        fibers.append(CanonicalFiber(fiber_id=i, points=pts))

    sample = CanonicalSample(
        sample_id="test", image_id="test.tif", is_3d=False,
        dims_px=(1, 512, 768), fibers=fibers,
        images=CanonicalImageArtifacts(),
    )

    suggestions = suggest_params_from_sample(sample)

    print("\nsuggestions dict:")
    for k, v in suggestions.items():
        print(f"  {k}: {v!r}")

    print("\nformatted summary:")
    print(format_suggestions_summary(suggestions))

    # Assertions
    assert suggestions["n_fibers"] == 5, f"Expected 5 fibers, got {suggestions['n_fibers']}"
    assert suggestions["image_width"] == 768, f"Expected W=768, got {suggestions['image_width']}"
    assert suggestions["image_height"] == 512, f"Expected H=512, got {suggestions['image_height']}"
    assert suggestions["length_mean"] is not None and suggestions["length_mean"] > 0, "length_mean should be positive"
    assert suggestions["straightness_mean"] is not None, "straightness_mean should be set"
    assert 0.0 <= suggestions["straightness_mean"] <= 1.0, f"straightness out of range: {suggestions['straightness_mean']}"
    assert suggestions["mean_angle_deg"] is not None, "mean_angle_deg should be set"
    assert 0.0 <= suggestions["alignment"] <= 1.0, f"alignment out of range: {suggestions['alignment']}"
    assert suggestions["width_mean"] is not None, "width_mean should be set (radius_px was populated)"
    expected_width = 2.0 * np.mean([2.5 + i * 0.2 for i in range(5)])
    assert abs(suggestions["width_mean"] - expected_width) < 0.5, \
        f"width_mean={suggestions['width_mean']:.2f}, expected ~{expected_width:.2f}"
    print(f"\n  width_mean={suggestions['width_mean']:.2f} px (expected ~{expected_width:.2f} px) ✓")

    # Test apply_suggestions_to_params with a lightweight mock params object.
    # Avoids importing generation.collections which pulls in scipy (DLL issue on UCRT64).
    from core.params import Param
    from core.distributions import Gaussian, Uniform

    class _MockParams:
        def __init__(self):
            self.nFibers     = Param(value=15)
            self.length      = Uniform(0.0, float("inf"), 15.0, 200.0)
            self.width       = Gaussian(0.0, float("inf"), 5.0, 0.5)
            self.straightness = Uniform(0.0, 1.0, 0.9, 1.0)
            self.meanAngle   = Param(value=90.0)
            self.alignment   = Param(value=0.5)
            self.imageWidth  = Param(value=512)
            self.imageHeight = Param(value=512)

    params = _MockParams()
    apply_suggestions_to_params(params, suggestions)

    assert isinstance(params.length, Gaussian), "params.length should be Gaussian after apply"
    assert isinstance(params.width, Gaussian), "params.width should be Gaussian after apply"
    assert isinstance(params.straightness, Gaussian), "params.straightness should be Gaussian after apply"
    assert params.nFibers.value == 5, f"nFibers should be 5, got {params.nFibers.value}"
    assert params.imageWidth.value == 768
    assert params.imageHeight.value == 512
    print(f"  params.length       -> {params.length.get_string()} OK")
    print(f"  params.width        -> {params.width.get_string()} OK")
    print(f"  params.straightness -> {params.straightness.get_string()} OK")
    print(f"  params.meanAngle    -> {params.meanAngle.value} deg OK")
    print(f"  params.alignment    -> {params.alignment.value} OK")
    print(f"  params.imageWidth   -> {params.imageWidth.value} px OK")
    print(f"  params.imageHeight  -> {params.imageHeight.value} px OK")

    # Test with no radius_px (all None) — width should be None, other stats still work
    fibers_nowidth = []
    for i in range(3):
        pts = [
            CanonicalPoint(point_index=j, x_px=float(j * 10), y_px=float(j * 5))
            for j in range(8)
        ]
        fibers_nowidth.append(CanonicalFiber(fiber_id=i, points=pts))
    sample_nowidth = CanonicalSample(
        sample_id="nw", image_id="nw.tif", is_3d=False,
        dims_px=(1, 256, 256), fibers=fibers_nowidth,
        images=CanonicalImageArtifacts(),
    )
    s2 = suggest_params_from_sample(sample_nowidth)
    assert s2["width_mean"] is None, "width_mean should be None when no radius_px"
    print("  No-radius case: width_mean=None OK")

    # Test apply skips width when None
    params2 = _MockParams()
    orig_width_str = params2.width.get_string()
    apply_suggestions_to_params(params2, s2)
    assert params2.width.get_string() == orig_width_str, "width should not change when suggestion is None"
    print("  apply_suggestions skips width when None OK")

    print("\nLEVEL 1: ALL ASSERTIONS PASSED ✓\n")


# ---------------------------------------------------------------------------
# Level 2: _build_canonical_fibers() radius lookup
# ---------------------------------------------------------------------------

def test_level2_radius_lookup():
    print("=" * 60)
    print("LEVEL 2: _build_canonical_fibers() radius_px lookup")
    print("=" * 60)

    from extractors.ct_fire import _build_canonical_fibers

    # Xa has 5 vertices; Ra has matching half-widths
    Xa = np.array([
        [0.0,  0.0],
        [10.0, 0.0],
        [20.0, 0.0],
        [0.0,  10.0],
        [10.0, 10.0],
    ])
    Ra = np.array([3.0, 4.0, 3.5, 2.0, 5.0])

    # Xf is rows 0,1,2 of Xa (as if trimxfv selected them)
    Xf = Xa[[0, 1, 2], :]
    Ff = [{"v": [0, 1, 2]}]  # one fiber

    result = {"Xf": Xf, "Ff": Ff, "Xa": Xa, "Ra": Ra}
    fibers = _build_canonical_fibers(result)

    assert len(fibers) == 1, f"Expected 1 fiber, got {len(fibers)}"
    pts = fibers[0].points
    assert len(pts) == 3, f"Expected 3 points, got {len(pts)}"

    expected_radii = [3.0, 4.0, 3.5]
    for i, (pt, expected) in enumerate(zip(pts, expected_radii)):
        assert pt.radius_px is not None, f"Point {i}: radius_px should not be None"
        assert abs(pt.radius_px - expected) < 1e-9, \
            f"Point {i}: radius_px={pt.radius_px}, expected {expected}"
        print(f"  pt[{i}]: (x={pt.x_px}, y={pt.y_px}) → radius_px={pt.radius_px} ✓")

    # Verify x/y coordinate mapping (row→y, col→x)
    assert pts[0].x_px == 0.0 and pts[0].y_px == 0.0
    assert pts[1].x_px == 0.0 and pts[1].y_px == 10.0  # Xf[1] = [10, 0] → y=10, x=0
    assert pts[2].x_px == 0.0 and pts[2].y_px == 20.0  # Xf[2] = [20, 0] → y=20, x=0
    print("  x/y coordinate mapping (row→y, col→x) ✓")

    # Test fallback: missing Ra → all radius_px None
    result_nora = {"Xf": Xf, "Ff": Ff}
    fibers2 = _build_canonical_fibers(result_nora)
    assert all(p.radius_px is None for p in fibers2[0].points), \
        "radius_px should be None when Ra is absent"
    print("  Missing Ra: all radius_px=None ✓")

    # Test fallback chain: no Xf → uses Xa/Fa
    Fa = [{"v": [0, 1, 2, 3]}]
    result_noxf = {"Xa": Xa, "Fa": Fa, "Ra": Ra}
    fibers3 = _build_canonical_fibers(result_noxf)
    assert len(fibers3) == 1
    assert fibers3[0].points[0].radius_px == 3.0  # Xa[0] → Ra[0]
    assert fibers3[0].points[3].radius_px == 2.0  # Xa[3] → Ra[3]
    print("  Fallback to Xa/Fa: radius lookup still works ✓")

    print("\nLEVEL 2: ALL ASSERTIONS PASSED ✓\n")


if __name__ == "__main__":
    passed = 0
    failed = 0
    for name, fn in [("Level 1", test_level1_suggestions), ("Level 2", test_level2_radius_lookup)]:
        try:
            fn()
            passed += 1
        except Exception as exc:
            print(f"\n{name}: FAILED — {exc}\n")
            import traceback; traceback.print_exc()
            failed += 1

    print("=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)
    sys.exit(failed)
