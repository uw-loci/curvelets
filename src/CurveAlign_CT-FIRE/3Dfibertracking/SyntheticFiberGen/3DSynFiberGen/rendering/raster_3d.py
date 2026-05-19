from __future__ import annotations

import math

import numpy as np

from core.abort import _raise_if_aborted


def get_rendered_tube_diameter_3d(width_value, min_diameter=1):
    try:
        diameter = float(width_value)
    except (TypeError, ValueError):
        diameter = float(min_diameter)
    return max(min_diameter, diameter)


def get_rendered_tube_radius_3d(width_value, min_diameter=1):
    diameter = get_rendered_tube_diameter_3d(width_value, min_diameter=min_diameter)
    if diameter <= 1:
        return 0.0
    return max(0.0, (float(diameter) - 1.0) / 2.0)


def _downsample_supersampled_mask(mask, factor):
    z_size, y_size, x_size = mask.shape
    reshaped = mask.reshape(
        z_size // factor, factor,
        y_size // factor, factor,
        x_size // factor, factor,
    )
    return reshaped.max(axis=(1, 3, 5))


def _rasterize_segment_supersampled_3d(volume, start, end, radius, value, binary=False, factor=4):
    z_dim, y_dim, x_dim = volume.shape
    x0, y0, z0 = start
    x1, y1, z1 = end
    radius = max(0.0, float(radius))
    effective_radius = max(radius, 0.45)

    min_x = max(0, int(math.floor(min(x0, x1) - effective_radius - 1)))
    max_x = min(x_dim - 1, int(math.ceil(max(x0, x1) + effective_radius + 1)))
    min_y = max(0, int(math.floor(min(y0, y1) - effective_radius - 1)))
    max_y = min(y_dim - 1, int(math.ceil(max(y0, y1) + effective_radius + 1)))
    min_z = max(0, int(math.floor(min(z0, z1) - effective_radius - 1)))
    max_z = min(z_dim - 1, int(math.ceil(max(z0, z1) + effective_radius + 1)))
    if min_x > max_x or min_y > max_y or min_z > max_z:
        return

    coarse_z = max_z - min_z + 1
    coarse_y = max_y - min_y + 1
    coarse_x = max_x - min_x + 1
    fine_z = coarse_z * factor
    fine_y = coarse_y * factor
    fine_x = coarse_x * factor

    fine_z_coords, fine_y_coords, fine_x_coords = np.indices((fine_z, fine_y, fine_x), dtype=np.float32)
    fine_x_coords = min_x - 0.5 + (fine_x_coords + 0.5) / factor
    fine_y_coords = min_y - 0.5 + (fine_y_coords + 0.5) / factor
    fine_z_coords = min_z - 0.5 + (fine_z_coords + 0.5) / factor

    seg = np.array([x1 - x0, y1 - y0, z1 - z0], dtype=np.float32)
    seg_len_sq = float(np.dot(seg, seg))
    if seg_len_sq <= 1e-8:
        t = np.zeros_like(fine_x_coords, dtype=np.float32)
    else:
        t = (
            (fine_x_coords - x0) * seg[0]
            + (fine_y_coords - y0) * seg[1]
            + (fine_z_coords - z0) * seg[2]
        ) / seg_len_sq
        t = np.clip(t, 0.0, 1.0)

    closest_x = x0 + t * seg[0]
    closest_y = y0 + t * seg[1]
    closest_z = z0 + t * seg[2]
    dist_sq = (
        (fine_x_coords - closest_x) ** 2
        + (fine_y_coords - closest_y) ** 2
        + (fine_z_coords - closest_z) ** 2
    )
    fine_mask = dist_sq <= (effective_radius ** 2)
    if not np.any(fine_mask):
        return

    coarse_mask = _downsample_supersampled_mask(fine_mask, factor)
    if not np.any(coarse_mask):
        return

    region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
    if binary:
        region[coarse_mask] = 255.0
    else:
        region[coarse_mask] += value


def _rasterize_segment_3d(volume, start, end, radius, value, binary=False):
    z_dim, y_dim, x_dim = volume.shape
    x0, y0, z0 = start
    x1, y1, z1 = end
    radius = max(0.0, float(radius))

    if radius < 0.75:
        _rasterize_segment_supersampled_3d(volume, start, end, radius, value, binary=binary, factor=4)
        return

    min_x = max(0, int(math.floor(min(x0, x1) - radius - 1)))
    max_x = min(x_dim - 1, int(math.ceil(max(x0, x1) + radius + 1)))
    min_y = max(0, int(math.floor(min(y0, y1) - radius - 1)))
    max_y = min(y_dim - 1, int(math.ceil(max(y0, y1) + radius + 1)))
    min_z = max(0, int(math.floor(min(z0, z1) - radius - 1)))
    max_z = min(z_dim - 1, int(math.ceil(max(z0, z1) + radius + 1)))
    if min_x > max_x or min_y > max_y or min_z > max_z:
        return

    z_coords, y_coords, x_coords = np.indices((max_z - min_z + 1, max_y - min_y + 1, max_x - min_x + 1), dtype=np.float32)
    x_coords += min_x
    y_coords += min_y
    z_coords += min_z

    seg = np.array([x1 - x0, y1 - y0, z1 - z0], dtype=np.float32)
    seg_len_sq = float(np.dot(seg, seg))
    if seg_len_sq <= 1e-8:
        t = np.zeros_like(x_coords, dtype=np.float32)
    else:
        t = ((x_coords - x0) * seg[0] + (y_coords - y0) * seg[1] + (z_coords - z0) * seg[2]) / seg_len_sq
        t = np.clip(t, 0.0, 1.0)

    closest_x = x0 + t * seg[0]
    closest_y = y0 + t * seg[1]
    closest_z = z0 + t * seg[2]
    dist_sq = (x_coords - closest_x) ** 2 + (y_coords - closest_y) ** 2 + (z_coords - closest_z) ** 2
    mask = dist_sq <= (radius ** 2)
    if not np.any(mask):
        return

    region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
    if binary:
        region[mask] = 255.0
    else:
        region[mask] += value


def render_fibers_to_volume(
    fibers,
    shape,
    default_intensity=255.0,
    binary=False,
    centerline_only=False,
    line_width_override=None,
    abort_check=None,
):
    volume = np.zeros(shape, dtype=np.float32)
    for fiber_index, fiber in enumerate(fibers):
        if fiber_index % 4 == 0:
            _raise_if_aborted(abort_check)
        intensity = 255.0 if binary else getattr(fiber, "intensity", default_intensity)
        if intensity is None:
            intensity = default_intensity
        try:
            intensity = float(intensity)
        except (TypeError, ValueError):
            intensity = default_intensity
        if intensity <= 0:
            continue
        intensity = max(0.0, min(255.0, intensity))
        for segment_index, segment in enumerate(fiber):
            if segment_index % 32 == 0:
                _raise_if_aborted(abort_check)
            start = np.array([segment.start.x, segment.start.y, segment.start.z], dtype=np.float32)
            end = np.array([segment.end.x, segment.end.y, segment.end.z], dtype=np.float32)
            if line_width_override is not None:
                radius = get_rendered_tube_radius_3d(line_width_override, min_diameter=1)
            else:
                radius = 0.0 if centerline_only else get_rendered_tube_radius_3d(segment.width, min_diameter=1)
            _rasterize_segment_3d(volume, start, end, radius, intensity, binary=binary)
    return np.clip(volume, 0, 255).astype(np.uint8)


def draw_scale_bar_on_volume(volume, params, microns=10.0):
    if not params.scale.use:
        return volume
    pixels_per_micron = float(params.scale.get_value())
    if pixels_per_micron <= 0:
        return volume
    output = np.array(volume, copy=True)
    length_px = max(1, int(round(microns * pixels_per_micron)))
    z = max(0, output.shape[0] - 2)
    y = max(1, output.shape[1] - 8)
    x_start = 4
    x_end = min(output.shape[2] - 1, x_start + length_px)
    output[z, y:y + 2, x_start:x_end] = 255
    return output


__all__ = [
    'draw_scale_bar_on_volume',
    'get_rendered_tube_diameter_3d',
    'get_rendered_tube_radius_3d',
    'render_fibers_to_volume',
]
