"""Compute generator parameter suggestions from a CT-FIRE CanonicalSample.

No Qt imports — pure numpy logic. Intended for use from ExtractionWorkflowMixin
via a lazy import inside populate_generator_params_pressed().
"""
from __future__ import annotations

from typing import Any

import numpy as np


def suggest_params_from_sample(sample) -> dict[str, Any]:
    """Compute generator parameter suggestions from extracted fiber data.

    Returns a dict with keys:
        n_fibers, length_mean, length_std,
        straightness_mean, straightness_std,
        mean_angle_deg, alignment,
        width_mean, width_std,
        image_width, image_height

    Stat fields are None when no valid fibers exist or no radius data is available.
    image_width/image_height are always populated from sample.dims_px.
    """
    # dims_px is (1, H, W) for 2D images produced by CTFireAdapter
    _, H, W = sample.dims_px

    path_lengths: list[float] = []
    straightnesses: list[float] = []
    fiber_angles: list[float] = []     # one per fiber
    fiber_angle_weights: list[float] = []  # total path length per fiber
    fiber_widths: list[float] = []     # mean diameter per fiber

    for fiber in sample.fibers:
        pts = fiber.points
        if len(pts) < 2:
            continue

        xs = np.array([p.x_px for p in pts], dtype=np.float64)
        ys = np.array([p.y_px for p in pts], dtype=np.float64)
        dx = np.diff(xs)
        dy = np.diff(ys)
        seg_lens = np.hypot(dx, dy)
        path_len = float(np.sum(seg_lens))
        if path_len == 0.0:
            continue

        # Length
        path_lengths.append(path_len)

        # Straightness
        chord = float(np.hypot(xs[-1] - xs[0], ys[-1] - ys[0]))
        straightnesses.append(min(1.0, chord / path_len))

        # Per-fiber mean angle using segment-length-weighted double-angle trick
        # arctan2(dy, dx) gives angle in (-π, π]; 180° periodicity via 2θ
        seg_angles = np.arctan2(dy, dx)
        cos2 = np.average(np.cos(2 * seg_angles), weights=seg_lens)
        sin2 = np.average(np.sin(2 * seg_angles), weights=seg_lens)
        fiber_angles.append(float(np.arctan2(sin2, cos2) / 2.0))  # radians
        fiber_angle_weights.append(path_len)

        # Width from radius_px (half-width = distance to background)
        radii = [p.radius_px for p in pts if p.radius_px is not None]
        if radii:
            fiber_widths.append(2.0 * float(np.mean(radii)))

    if not path_lengths:
        return {
            "n_fibers": len(sample.fibers),
            "length_mean": None,
            "length_std": None,
            "straightness_mean": None,
            "straightness_std": None,
            "mean_angle_deg": None,
            "alignment": None,
            "width_mean": None,
            "width_std": None,
            "image_width": int(W),
            "image_height": int(H),
        }

    # Network-level circular mean angle (double-angle, path-length weighted)
    weights = np.array(fiber_angle_weights, dtype=np.float64)
    angles = np.array(fiber_angles, dtype=np.float64)
    C = float(np.average(np.cos(2 * angles), weights=weights))
    S = float(np.average(np.sin(2 * angles), weights=weights))
    mean_angle_rad = np.arctan2(S, C) / 2.0
    mean_angle_deg = float(np.degrees(mean_angle_rad)) % 180.0
    alignment = float(np.hypot(C, S))  # resultant length R ∈ [0, 1]

    return {
        "n_fibers": len(sample.fibers),
        "length_mean": float(np.mean(path_lengths)),
        "length_std": float(np.std(path_lengths)),
        "straightness_mean": float(np.mean(straightnesses)),
        "straightness_std": float(np.std(straightnesses)),
        "mean_angle_deg": mean_angle_deg,
        "alignment": alignment,
        "width_mean": float(np.mean(fiber_widths)) if fiber_widths else None,
        "width_std": float(np.std(fiber_widths)) if fiber_widths else None,
        "image_width": int(W),
        "image_height": int(H),
    }


def format_suggestions_summary(suggestions: dict[str, Any]) -> str:
    """Return a human-readable summary of suggestions for a QMessageBox."""

    def _fmt_dist(mean_key: str, std_key: str, unit: str = "px") -> str:
        m = suggestions.get(mean_key)
        s = suggestions.get(std_key)
        if m is None:
            return "n/a"
        return f"μ={m:.1f} {unit}, σ={s:.1f} {unit}" if s is not None else f"μ={m:.1f} {unit}"

    n = suggestions.get("n_fibers", "n/a")
    angle = suggestions.get("mean_angle_deg")
    alignment = suggestions.get("alignment")
    W = suggestions.get("image_width")
    H = suggestions.get("image_height")

    lines = [
        f"Fibers:        {n}",
        f"Length:        {_fmt_dist('length_mean', 'length_std')}",
        f"Width:         {_fmt_dist('width_mean', 'width_std')}",
        f"Straightness:  {_fmt_dist('straightness_mean', 'straightness_std', '')}".rstrip(),
        f"Mean angle:    {angle:.1f}°" if angle is not None else "Mean angle:    n/a",
        f"Alignment:     {alignment:.2f}" if alignment is not None else "Alignment:     n/a",
        f"Image size:    {W} × {H} px" if W and H else "Image size:    n/a",
        "",
        "Apply these values to the generator parameters?",
    ]
    return "\n".join(lines)


def apply_suggestions_to_params(params, suggestions: dict[str, Any]) -> None:
    """Mutate params in place with suggested values. Skips fields where value is None."""
    from core.distributions import Gaussian

    n = suggestions.get("n_fibers")
    if n is not None:
        params.nFibers.value = int(n)

    length_mean = suggestions.get("length_mean")
    if length_mean is not None:
        length_std = max(float(suggestions.get("length_std") or 0.0), 1.0)
        lb = getattr(params.length, "lower_bound", 0.0)
        ub = getattr(params.length, "upper_bound", float("inf"))
        params.length = Gaussian(lb, ub, round(length_mean, 1), round(length_std, 1))

    width_mean = suggestions.get("width_mean")
    if width_mean is not None:
        width_std = max(float(suggestions.get("width_std") or 0.0), 0.1)
        params.width = Gaussian(0.0, float("inf"), round(width_mean, 2), round(width_std, 2))

    straight_mean = suggestions.get("straightness_mean")
    if straight_mean is not None:
        straight_std = max(float(suggestions.get("straightness_std") or 0.0), 0.001)
        straight_mean_clamped = float(np.clip(straight_mean, 0.0, 1.0))
        params.straightness = Gaussian(0.0, 1.0, round(straight_mean_clamped, 4), round(straight_std, 4))

    mean_angle = suggestions.get("mean_angle_deg")
    if mean_angle is not None:
        params.meanAngle.value = round(float(mean_angle), 1)

    alignment = suggestions.get("alignment")
    if alignment is not None:
        params.alignment.value = round(float(alignment), 3)

    iw = suggestions.get("image_width")
    if iw:
        params.imageWidth.value = int(iw)

    ih = suggestions.get("image_height")
    if ih:
        params.imageHeight.value = int(ih)
