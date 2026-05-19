from __future__ import annotations

from math import atan2, degrees

import numpy as np
import pandas as pd
from scipy.ndimage import distance_transform_edt

from .model import CanonicalSample
from .schema import CSV_COLUMNS


def _param_value(param, default=None):
    if param is None:
        return default
    if hasattr(param, "get_value"):
        try:
            return param.get_value()
        except (AttributeError, TypeError, ValueError):
            return default
    if hasattr(param, "value"):
        return param.value
    return param


def _param_use(param) -> bool:
    if param is None:
        return False
    if hasattr(param, "use"):
        return bool(param.use)
    return bool(_param_value(param))


def _safe_float(value, default=None):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _safe_int(value, default=0):
    try:
        return int(round(float(value)))
    except (TypeError, ValueError):
        return default


def _as_array(point) -> np.ndarray:
    return np.asarray([float(point.x), float(point.y), float(getattr(point, "z", 0.0))], dtype=float)


def _orientation_degrees(vec: np.ndarray):
    x, y, z = vec.tolist()
    return (
        float(degrees(atan2(y, x))),
        float(degrees(atan2(z, y))) if abs(y) > 1e-12 or abs(z) > 1e-12 else 0.0,
        float(degrees(atan2(z, x))) if abs(x) > 1e-12 or abs(z) > 1e-12 else 0.0,
    )


def _curvature_three_points(prev_point: np.ndarray, point: np.ndarray, next_point: np.ndarray) -> float:
    a = point - prev_point
    b = next_point - point
    c = next_point - prev_point
    a_len = np.linalg.norm(a)
    b_len = np.linalg.norm(b)
    c_len = np.linalg.norm(c)
    if a_len <= 1e-8 or b_len <= 1e-8 or c_len <= 1e-8:
        return 0.0
    cross = np.linalg.norm(np.cross(a, b))
    denom = a_len * b_len * c_len
    if denom <= 1e-8:
        return 0.0
    return float(2.0 * cross / denom)


def _segment_point_distance(point: np.ndarray, start: np.ndarray, end: np.ndarray) -> float:
    seg = end - start
    seg_len_sq = float(np.dot(seg, seg))
    if seg_len_sq <= 1e-8:
        return float(np.linalg.norm(point - start))
    t = float(np.dot(point - start, seg) / seg_len_sq)
    t = min(1.0, max(0.0, t))
    closest = start + t * seg
    return float(np.linalg.norm(point - closest))


def _sample_distance_transform(binary_mask: np.ndarray, coords_xyz: np.ndarray) -> float:
    if binary_mask.size == 0 or not np.any(binary_mask):
        return np.nan
    dt = distance_transform_edt(binary_mask)
    zyx = np.round(coords_xyz[::-1]).astype(int)
    zyx = np.clip(zyx, 0, np.array(binary_mask.shape) - 1)
    return float(dt[tuple(zyx)])


def _distance_transform_for_image(binary_mask: np.ndarray) -> np.ndarray:
    if binary_mask.ndim == 2:
        return distance_transform_edt(binary_mask)
    return distance_transform_edt(binary_mask)


def _sample_annulus(image: np.ndarray, fiber_mask: np.ndarray, point_xyz: np.ndarray, near_radius: float, far_radius: float):
    if image.ndim == 2:
        x0, y0 = point_xyz[:2]
        min_x = max(0, int(np.floor(x0 - far_radius)))
        max_x = min(image.shape[1] - 1, int(np.ceil(x0 + far_radius)))
        min_y = max(0, int(np.floor(y0 - far_radius)))
        max_y = min(image.shape[0] - 1, int(np.ceil(y0 + far_radius)))
        yy, xx = np.indices((max_y - min_y + 1, max_x - min_x + 1), dtype=float)
        xx += min_x
        yy += min_y
        dist = np.sqrt((xx - x0) ** 2 + (yy - y0) ** 2)
        annulus = (dist >= near_radius) & (dist <= far_radius)
        if fiber_mask is not None:
            local_mask = fiber_mask[min_y:max_y + 1, min_x:max_x + 1] > 0
            annulus &= ~local_mask
        values = image[min_y:max_y + 1, min_x:max_x + 1][annulus]
    else:
        x0, y0, z0 = point_xyz
        min_x = max(0, int(np.floor(x0 - far_radius)))
        max_x = min(image.shape[2] - 1, int(np.ceil(x0 + far_radius)))
        min_y = max(0, int(np.floor(y0 - far_radius)))
        max_y = min(image.shape[1] - 1, int(np.ceil(y0 + far_radius)))
        min_z = max(0, int(np.floor(z0 - far_radius)))
        max_z = min(image.shape[0] - 1, int(np.ceil(z0 + far_radius)))
        zz, yy, xx = np.indices((max_z - min_z + 1, max_y - min_y + 1, max_x - min_x + 1), dtype=float)
        xx += min_x
        yy += min_y
        zz += min_z
        dist = np.sqrt((xx - x0) ** 2 + (yy - y0) ** 2 + (zz - z0) ** 2)
        annulus = (dist >= near_radius) & (dist <= far_radius)
        if fiber_mask is not None:
            local_mask = fiber_mask[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1] > 0
            annulus &= ~local_mask
        values = image[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1][annulus]
    if values.size == 0:
        return np.nan, np.nan
    return float(np.mean(values)), float(np.std(values))


def _infer_units(params, is_3d: bool):
    scale_param = getattr(params, "scale", None)
    scale_value = _safe_float(_param_value(scale_param), None) if _param_use(scale_param) else None
    pixel_size_xy = (1.0 / scale_value) if scale_value and scale_value > 0 else None

    if is_3d:
        px_x = _safe_float(_param_value(getattr(params, "psfPixelSizeX", None)), pixel_size_xy)
        px_y = _safe_float(_param_value(getattr(params, "psfPixelSizeY", None)), pixel_size_xy)
        px_z = _safe_float(_param_value(getattr(params, "psfPixelSizeZ", None)), pixel_size_xy)
        return px_x, px_y, px_z
    return pixel_size_xy, pixel_size_xy, None


def _to_um(value_px: float | None, scale_um: float | None):
    if value_px is None or scale_um is None:
        return None
    return float(value_px) * float(scale_um)


def _touches_boundary(point_xyz: np.ndarray, dims_xyz: tuple[int, int, int], tol: float = 1.0, is_3d: bool = True) -> bool:
    x, y, z = point_xyz.tolist()
    max_x, max_y, max_z = dims_xyz
    touches_xy = (
        x <= tol or y <= tol or
        x >= max_x - 1 - tol or y >= max_y - 1 - tol
    )
    if not is_3d:
        return touches_xy
    return touches_xy or z <= tol or z >= max_z - 1 - tol


def _fill_columns(frame: pd.DataFrame, key: str) -> pd.DataFrame:
    columns = CSV_COLUMNS[key]
    for column in columns:
        if column not in frame.columns:
            frame[column] = np.nan
    return frame[columns]


def _safe_nanmean(values):
    cleaned = []
    for value in values:
        if value is None:
            cleaned.append(np.nan)
        else:
            cleaned.append(value)
    if not cleaned:
        return np.nan
    arr = np.asarray(cleaned, dtype=float)
    if arr.size == 0 or np.all(np.isnan(arr)):
        return np.nan
    return float(np.nanmean(arr))


def _global_alignment_score(sample: CanonicalSample):
    directions = []
    for fiber in sample.fibers:
        for segment in fiber.segments:
            start = np.asarray([segment.start_x_px, segment.start_y_px, segment.start_z_px], dtype=float)
            end = np.asarray([segment.end_x_px, segment.end_y_px, segment.end_z_px], dtype=float)
            vec = end - start
            length = np.linalg.norm(vec)
            if length <= 1e-8:
                continue
            directions.append(vec / length)
    if not directions:
        return np.nan
    direction_array = np.asarray(directions, dtype=float)
    mean_vec = np.mean(direction_array, axis=0)
    mean_norm = np.linalg.norm(mean_vec)
    if mean_norm <= 1e-8:
        return 0.0
    mean_vec = mean_vec / mean_norm
    scores = np.abs(direction_array @ mean_vec)
    return float(np.mean(scores))


class _UnionFind:
    def __init__(self, size: int):
        self.parent = list(range(size))

    def find(self, item: int) -> int:
        while self.parent[item] != item:
            self.parent[item] = self.parent[self.parent[item]]
            item = self.parent[item]
        return item

    def union(self, a: int, b: int):
        ra = self.find(a)
        rb = self.find(b)
        if ra != rb:
            self.parent[rb] = ra
