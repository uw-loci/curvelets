from __future__ import annotations

from collections import defaultdict
from copy import deepcopy
from datetime import datetime
from math import atan2, degrees
from typing import Any, Optional

import numpy as np
import pandas as pd
from scipy.ndimage import distance_transform_edt, label

try:
    from scipy.spatial import cKDTree
except Exception:  # pragma: no cover
    cKDTree = None

from export_model import (
    CanonicalComponent,
    CanonicalEdge,
    CanonicalEndpoint,
    CanonicalFiber,
    CanonicalImageArtifacts,
    CanonicalJunction,
    CanonicalPoint,
    CanonicalSample,
    CanonicalSegment,
)
from export_schema import (
    COORDINATE_CONVENTION,
    CSV_COLUMNS,
    DEFAULT_BACKGROUND_ANNULUS_FAR,
    DEFAULT_BACKGROUND_ANNULUS_NEAR,
    DEFAULT_BACKGROUND_SECTOR_COUNT,
    DEFAULT_LOCAL_ALIGNMENT_RADIUS,
    DIMENSION_ORDER_2D,
    DIMENSION_ORDER_3D,
    PHYSICAL_UNIT,
    SCHEMA_VERSION,
)


def _param_value(param, default=None):
    if param is None:
        return default
    if hasattr(param, "get_value"):
        try:
            return param.get_value()
        except Exception:
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
    except Exception:
        return default


def _safe_int(value, default=0):
    try:
        return int(round(float(value)))
    except Exception:
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


def _to_um(value_px: Optional[float], scale_um: Optional[float]):
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


def build_generation_recipe(source_fiber_image) -> dict[str, Any]:
    params = source_fiber_image.params
    params_dict = deepcopy(params.to_dict())
    recipe = {}
    for key, raw_value in params_dict.items():
        if hasattr(source_fiber_image, "should_export_generation_param") and not source_fiber_image.should_export_generation_param(key, raw_value):
            continue
        if key in {"showJoints", "showCenterlineOverlay", "centerlineOverlayColor", "centerlineOverlayBrightness", "renderMode", "centerlineOutputType", "maskOutputMode"}:
            continue
        recipe[key] = raw_value.get("value") if isinstance(raw_value, dict) and "value" in raw_value else raw_value
    return recipe


def build_provenance(source_fiber_image, sample_id: str, image_id: str, is_3d: bool, has_enhanced: bool = False) -> dict[str, Any]:
    params = source_fiber_image.params
    pixel_size_x_um, pixel_size_y_um, voxel_size_z_um = _infer_units(params, is_3d)
    return {
        "schema_version": SCHEMA_VERSION,
        "sample_id": sample_id,
        "image_id": image_id,
        "source_algorithm": "synthetic_generator",
        "source_algorithm_version": None,
        "generator_version": None,
        "extractor_version": None,
        "enhancement_model_name": None,
        "enhancement_model_version": None,
        "pipeline_stage": "synthetic_generator",
        "synthetic_flag": True,
        "extracted_flag": False,
        "enhanced_flag": bool(has_enhanced),
        "pixel_size_x_um": pixel_size_x_um,
        "pixel_size_y_um": pixel_size_y_um,
        "voxel_size_z_um": voxel_size_z_um,
        "physical_unit": PHYSICAL_UNIT,
        "coordinate_convention": COORDINATE_CONVENTION,
        "dimension_order": DIMENSION_ORDER_3D if is_3d else DIMENSION_ORDER_2D,
        "width_source": "synthetic_model_input",
        "position_source": "synthetic_geometry",
        "corrected_position_flag": False,
        "overlap_resolution_mode": None,
        "background_annulus_near": DEFAULT_BACKGROUND_ANNULUS_NEAR,
        "background_annulus_far": DEFAULT_BACKGROUND_ANNULUS_FAR,
        "background_sector_count": DEFAULT_BACKGROUND_SECTOR_COUNT,
        "minimum_foreground": None,
        "snr_definition": "(centerline_intensity_mean - local_background_mean) / local_background_std",
        "psf_applied": bool(_param_use(getattr(params, "psfEnabled", None))),
        "psf_model": _param_value(getattr(params, "psfType", None), None),
        "noise_model": _param_value(getattr(params, "noiseModel", None), None),
        "blur_applied": bool(_param_use(getattr(params, "blur", None)) or _param_use(getattr(params, "blurRadius", None))),
        "normalize_applied": bool(_param_use(getattr(params, "normalize", None))),
        "downsample_applied": bool(_param_use(getattr(params, "downSample", None))),
        "timestamp": datetime.now().isoformat(),
        "input_image_path": None,
    }


def build_canonical_sample(source_fiber_image, image_id: str, sample_id: str, centerline_mask=None, fiber_image_array=None, enhanced_image=None) -> CanonicalSample:
    is_3d = hasattr(source_fiber_image.params, "imageDepth")
    dims_xyz = (
        _safe_int(_param_value(getattr(source_fiber_image.params, "imageWidth", None)), 0),
        _safe_int(_param_value(getattr(source_fiber_image.params, "imageHeight", None)), 0),
        _safe_int(_param_value(getattr(source_fiber_image.params, "imageDepth", None)), 1 if not is_3d else 0),
    )
    if not is_3d:
        dims_xyz = (dims_xyz[0], dims_xyz[1], 1)
    pixel_size_x_um, pixel_size_y_um, voxel_size_z_um = _infer_units(source_fiber_image.params, is_3d)

    sample = CanonicalSample(
        sample_id=sample_id,
        image_id=image_id,
        is_3d=is_3d,
        dims_px=dims_xyz,
        pixel_size_x_um=pixel_size_x_um,
        pixel_size_y_um=pixel_size_y_um,
        voxel_size_z_um=voxel_size_z_um,
        source_algorithm="synthetic_generator",
        source_type="centerline_geometry",
        images=CanonicalImageArtifacts(
            centerline_mask=centerline_mask,
            fiber_image=fiber_image_array,
            enhanced_image=enhanced_image,
        ),
        provenance=build_provenance(source_fiber_image, sample_id, image_id, is_3d, enhanced_image is not None),
        generation_recipe=build_generation_recipe(source_fiber_image),
        validation_metrics=deepcopy(getattr(source_fiber_image, "validation_metrics", {}) or {}),
    )

    endpoint_records = []
    segment_midpoints = []
    segment_orientations = []
    segment_fiber_ids = []

    for fiber in getattr(source_fiber_image, "fibers", []):
        points = getattr(fiber, "points", [])
        widths = list(getattr(fiber, "widths", []) or [])
        if len(points) < 2:
            continue
        fiber_id = len(sample.fibers)

        point_arrays = [_as_array(point) for point in points]
        cumulative_s = [0.0]
        for i in range(1, len(point_arrays)):
            cumulative_s.append(cumulative_s[-1] + float(np.linalg.norm(point_arrays[i] - point_arrays[i - 1])))

        fiber_points = []
        fiber_segments = []
        curvature_values = []
        radius_values_px = []
        seg_orient_xy = []
        seg_orient_yz = []
        seg_orient_xz = []

        for point_index, point_array in enumerate(point_arrays):
            width_value = widths[min(point_index, len(widths) - 1)] if widths else np.nan
            radius_px = float(width_value) / 2.0 if width_value == width_value else np.nan
            curvature_px_inv = None
            if 0 < point_index < len(point_arrays) - 1:
                curvature_px_inv = _curvature_three_points(point_arrays[point_index - 1], point_array, point_arrays[point_index + 1])
                curvature_values.append(curvature_px_inv)
            radius_values_px.append(radius_px)
            fiber_points.append(CanonicalPoint(
                point_index=point_index,
                x_px=float(point_array[0]),
                y_px=float(point_array[1]),
                z_px=float(point_array[2]) if is_3d else 0.0,
                s_px=float(cumulative_s[point_index]),
                x_um=_to_um(float(point_array[0]), pixel_size_x_um),
                y_um=_to_um(float(point_array[1]), pixel_size_y_um),
                z_um=_to_um(float(point_array[2]), voxel_size_z_um) if is_3d else 0.0,
                s_um=_to_um(float(cumulative_s[point_index]), pixel_size_x_um),
                curvature_px_inv=curvature_px_inv,
                curvature_um_inv=(curvature_px_inv / pixel_size_x_um) if curvature_px_inv is not None and pixel_size_x_um else None,
                radius_px=radius_px,
                radius_um=_to_um(radius_px, pixel_size_x_um) if radius_px == radius_px else None,
                source_type="centerline_geometry",
            ))

        for segment_index in range(len(point_arrays) - 1):
            start = point_arrays[segment_index]
            end = point_arrays[segment_index + 1]
            seg_vec = end - start
            seg_len = float(np.linalg.norm(seg_vec))
            orient_xy, orient_yz, orient_xz = _orientation_degrees(seg_vec)
            seg_orient_xy.append(orient_xy)
            seg_orient_yz.append(orient_yz)
            seg_orient_xz.append(orient_xz)
            radius_px = float(widths[min(segment_index, len(widths) - 1)]) / 2.0 if widths else np.nan
            fiber_segments.append(CanonicalSegment(
                segment_index=segment_index,
                start_point_index=segment_index,
                end_point_index=segment_index + 1,
                start_x_px=float(start[0]),
                start_y_px=float(start[1]),
                start_z_px=float(start[2]) if is_3d else 0.0,
                end_x_px=float(end[0]),
                end_y_px=float(end[1]),
                end_z_px=float(end[2]) if is_3d else 0.0,
                segment_length_px=seg_len,
                segment_length_um=_to_um(seg_len, pixel_size_x_um),
                tangent_xy_deg=orient_xy,
                tangent_yz_deg=orient_yz if is_3d else None,
                tangent_xz_deg=orient_xz if is_3d else None,
                segment_radius_px=radius_px,
                segment_radius_um=_to_um(radius_px, pixel_size_x_um) if radius_px == radius_px else None,
                source_type="centerline_geometry",
            ))
            segment_midpoints.append((start + end) / 2.0)
            segment_orientations.append(seg_vec / max(seg_len, 1e-8))
            segment_fiber_ids.append(fiber_id)

        contour_length_px = float(cumulative_s[-1])
        chord_px = float(np.linalg.norm(point_arrays[-1] - point_arrays[0]))
        radius_array_px = np.asarray([v for v in radius_values_px if v == v], dtype=float)
        curvature_array = np.asarray(curvature_values, dtype=float) if curvature_values else np.asarray([], dtype=float)
        orientation_mean_xy = float(np.mean(seg_orient_xy)) if seg_orient_xy else np.nan
        orientation_mean_yz = float(np.mean(seg_orient_yz)) if seg_orient_yz else np.nan
        orientation_mean_xz = float(np.mean(seg_orient_xz)) if seg_orient_xz else np.nan
        touches_boundary = any(_touches_boundary(point, dims_xyz, is_3d=is_3d) for point in point_arrays)
        is_closed = bool(np.linalg.norm(point_arrays[-1] - point_arrays[0]) <= max(1.0, np.nanmean(radius_array_px) if radius_array_px.size else 1.0))

        canonical_fiber = CanonicalFiber(
            fiber_id=fiber_id,
            points=fiber_points,
            segments=fiber_segments,
            metrics={
                "contour_length_px": contour_length_px,
                "contour_length_um": _to_um(contour_length_px, pixel_size_x_um),
                "end_to_end_distance_px": chord_px,
                "end_to_end_distance_um": _to_um(chord_px, pixel_size_x_um),
                "straightness": (chord_px / contour_length_px) if contour_length_px > 0 else np.nan,
                "orientation_mean_xy_deg": orientation_mean_xy,
                "orientation_mean_yz_deg": orientation_mean_yz if is_3d else np.nan,
                "orientation_mean_xz_deg": orientation_mean_xz if is_3d else np.nan,
                "curvature_mean_px_inv": float(np.mean(curvature_array)) if curvature_array.size else np.nan,
                "curvature_std_px_inv": float(np.std(curvature_array)) if curvature_array.size else np.nan,
                "curvature_max_px_inv": float(np.max(curvature_array)) if curvature_array.size else np.nan,
                "curvature_mean_um_inv": float(np.mean(curvature_array) / pixel_size_x_um) if curvature_array.size and pixel_size_x_um else np.nan,
                "curvature_std_um_inv": float(np.std(curvature_array) / pixel_size_x_um) if curvature_array.size and pixel_size_x_um else np.nan,
                "curvature_max_um_inv": float(np.max(curvature_array) / pixel_size_x_um) if curvature_array.size and pixel_size_x_um else np.nan,
                "radius_mean_px": float(np.mean(radius_array_px)) if radius_array_px.size else np.nan,
                "radius_std_px": float(np.std(radius_array_px)) if radius_array_px.size else np.nan,
                "radius_min_px": float(np.min(radius_array_px)) if radius_array_px.size else np.nan,
                "radius_max_px": float(np.max(radius_array_px)) if radius_array_px.size else np.nan,
                "radius_mean_um": float(np.mean(radius_array_px) * pixel_size_x_um) if radius_array_px.size and pixel_size_x_um else np.nan,
                "radius_std_um": float(np.std(radius_array_px) * pixel_size_x_um) if radius_array_px.size and pixel_size_x_um else np.nan,
                "radius_min_um": float(np.min(radius_array_px) * pixel_size_x_um) if radius_array_px.size and pixel_size_x_um else np.nan,
                "radius_max_um": float(np.max(radius_array_px) * pixel_size_x_um) if radius_array_px.size and pixel_size_x_um else np.nan,
                "free_endpoint_count": 0,
                "junction_endpoint_count": 0,
                "junction_count": 0,
                "is_closed": is_closed,
                "touches_image_boundary": touches_boundary,
                "is_truncated": touches_boundary,
            },
        )
        sample.fibers.append(canonical_fiber)
        endpoint_records.append((fiber_id, 0, point_arrays[0]))
        endpoint_records.append((fiber_id, len(point_arrays) - 1, point_arrays[-1]))

    # Build junctions and fiber-junction edges.
    junction_points = getattr(source_fiber_image, "joint_points", []) or []
    tolerance = 1.5
    edges_by_junction = defaultdict(list)
    endpoint_classes = {}

    for junction_id, joint in enumerate(junction_points):
        joint_array = _as_array(joint)
        junction = CanonicalJunction(
            junction_id=junction_id,
            x_px=float(joint_array[0]),
            y_px=float(joint_array[1]),
            z_px=float(joint_array[2]) if is_3d else 0.0,
            x_um=_to_um(float(joint_array[0]), pixel_size_x_um),
            y_um=_to_um(float(joint_array[1]), pixel_size_y_um),
            z_um=_to_um(float(joint_array[2]), voxel_size_z_um) if is_3d else 0.0,
        )
        sample.junctions.append(junction)
        for fiber in sample.fibers:
            points = [np.asarray([p.x_px, p.y_px, p.z_px], dtype=float) for p in fiber.points]
            if len(points) < 2:
                continue
            edge_type = None
            if np.linalg.norm(joint_array - points[0]) <= tolerance:
                edge_type = "start"
                endpoint_classes[(fiber.fiber_id, 0)] = "junction_connected"
            elif np.linalg.norm(joint_array - points[-1]) <= tolerance:
                edge_type = "end"
                endpoint_classes[(fiber.fiber_id, len(points) - 1)] = "junction_connected"
            else:
                for seg_idx in range(len(points) - 1):
                    if _segment_point_distance(joint_array, points[seg_idx], points[seg_idx + 1]) <= tolerance:
                        edge_type = "pass_through"
                        break
            if edge_type is not None:
                edge = CanonicalEdge(fiber_id=fiber.fiber_id, junction_id=junction_id, edge_type=edge_type)
                sample.edges.append(edge)
                edges_by_junction[junction_id].append(edge)

    # Components via fiber graph.
    if sample.fibers:
        union = _UnionFind(len(sample.fibers))
        for junction_id, edges in edges_by_junction.items():
            fiber_ids = [edge.fiber_id for edge in edges]
            for idx in range(1, len(fiber_ids)):
                union.union(fiber_ids[0], fiber_ids[idx])
        component_map = {}
        next_component_id = 0
        for fiber in sample.fibers:
            root = union.find(fiber.fiber_id)
            if root not in component_map:
                component_map[root] = next_component_id
                next_component_id += 1
            fiber.component_id = component_map[root]
            fiber.metrics["component_id"] = fiber.component_id
        for edge in sample.edges:
            edge.component_id = sample.fibers[edge.fiber_id].component_id
        for junction_id, edges in edges_by_junction.items():
            component_id = sample.fibers[edges[0].fiber_id].component_id if edges else next_component_id + junction_id
            sample.junctions[junction_id].component_id = component_id
            sample.junctions[junction_id].degree = len(edges)
        for fiber in sample.fibers:
            fiber.metrics["junction_count"] = sum(1 for edge in sample.edges if edge.fiber_id == fiber.fiber_id)

        endpoint_id = 0
        for fiber_id, point_index, point_array in endpoint_records:
            fiber = sample.fibers[fiber_id]
            if point_index == 0:
                neighbor = np.asarray([fiber.points[1].x_px, fiber.points[1].y_px, fiber.points[1].z_px], dtype=float)
                tangent = neighbor - point_array
            else:
                neighbor = np.asarray([fiber.points[-2].x_px, fiber.points[-2].y_px, fiber.points[-2].z_px], dtype=float)
                tangent = point_array - neighbor
            orientation_xy, orientation_yz, orientation_xz = _orientation_degrees(tangent)
            endpoint_class = endpoint_classes.get((fiber_id, point_index), "free_end")
            endpoint = CanonicalEndpoint(
                endpoint_id=endpoint_id,
                fiber_id=fiber_id,
                point_index=point_index,
                x_px=float(point_array[0]),
                y_px=float(point_array[1]),
                z_px=float(point_array[2]) if is_3d else 0.0,
                x_um=_to_um(float(point_array[0]), pixel_size_x_um),
                y_um=_to_um(float(point_array[1]), pixel_size_y_um),
                z_um=_to_um(float(point_array[2]), voxel_size_z_um) if is_3d else 0.0,
                orientation_xy_deg=orientation_xy,
                orientation_yz_deg=orientation_yz if is_3d else np.nan,
                orientation_xz_deg=orientation_xz if is_3d else np.nan,
                endpoint_class=endpoint_class,
                component_id=fiber.component_id,
                touches_image_boundary=_touches_boundary(point_array, dims_xyz, is_3d=is_3d),
            )
            sample.endpoints.append(endpoint)
            endpoint_id += 1
            if endpoint_class == "junction_connected":
                fiber.metrics["junction_endpoint_count"] += 1
            else:
                fiber.metrics["free_endpoint_count"] += 1

        component_lookup = defaultdict(lambda: CanonicalComponent(component_id=-1))
        for fiber in sample.fibers:
            comp = component_lookup[fiber.component_id]
            if comp.component_id == -1:
                comp.component_id = fiber.component_id
            comp.fiber_ids.append(fiber.fiber_id)
            comp.total_length_px += float(fiber.metrics.get("contour_length_px") or 0.0)
        for junction in sample.junctions:
            comp = component_lookup[junction.component_id]
            if comp.component_id == -1:
                comp.component_id = junction.component_id
            comp.junction_ids.append(junction.junction_id)
        for endpoint in sample.endpoints:
            comp = component_lookup[endpoint.component_id]
            if comp.component_id == -1:
                comp.component_id = endpoint.component_id
            comp.endpoint_ids.append(endpoint.endpoint_id)
        sample.components = []
        for component_id in sorted(component_lookup):
            comp = component_lookup[component_id]
            comp.total_length_um = _to_um(comp.total_length_px, pixel_size_x_um)
            sample.components.append(comp)

    # Image-derived measurements.
    fiber_image_arr = None if fiber_image_array is None else np.asarray(fiber_image_array)
    centerline_mask_arr = None if centerline_mask is None else np.asarray(centerline_mask)
    if fiber_image_arr is not None:
        if fiber_image_arr.ndim == 3 and not is_3d and fiber_image_arr.shape[-1] in (3, 4):
            fiber_image_arr = fiber_image_arr[..., 0]
        if fiber_image_arr.ndim == 4:
            fiber_image_arr = fiber_image_arr[..., 0]
        intensity_threshold = max(1.0, 0.25 * float(np.max(fiber_image_arr))) if fiber_image_arr.size else 1.0
        binary_fiber_region = fiber_image_arr >= intensity_threshold
        image_dt = _distance_transform_for_image(binary_fiber_region) if np.any(binary_fiber_region) else None
        point_rows = []
        for fiber in sample.fibers:
            point_intensities = []
            point_backgrounds = []
            point_contrasts = []
            image_domain_widths = []
            for point in fiber.points:
                if is_3d:
                    coord = np.asarray([point.x_px, point.y_px, point.z_px], dtype=float)
                    zyx = np.clip(np.round(coord[::-1]).astype(int), 0, np.array(fiber_image_arr.shape) - 1)
                    intensity = float(fiber_image_arr[tuple(zyx)])
                else:
                    coord = np.asarray([point.x_px, point.y_px], dtype=float)
                    yx = np.clip(np.round(coord[::-1]).astype(int), 0, np.array(fiber_image_arr.shape) - 1)
                    intensity = float(fiber_image_arr[tuple(yx)])
                background_mean, background_std = _sample_annulus(
                    fiber_image_arr,
                    binary_fiber_region,
                    coord,
                    DEFAULT_BACKGROUND_ANNULUS_NEAR,
                    DEFAULT_BACKGROUND_ANNULUS_FAR,
                )
                point.intensity = intensity
                point.background = background_mean
                point_intensities.append(intensity)
                if background_mean == background_mean:
                    point_backgrounds.append(background_mean)
                    point_contrasts.append(intensity - background_mean)
                if image_dt is not None:
                    if is_3d:
                        zyx = np.clip(np.round(np.asarray([point.z_px, point.y_px, point.x_px])).astype(int), 0, np.array(image_dt.shape) - 1)
                        image_domain_widths.append(float(image_dt[tuple(zyx)]) * 2.0)
                    else:
                        yx = np.clip(np.round(np.asarray([point.y_px, point.x_px])).astype(int), 0, np.array(image_dt.shape) - 1)
                        image_domain_widths.append(float(image_dt[tuple(yx)]) * 2.0)
                point_rows.append((fiber.fiber_id, point.point_index, point.s_um, intensity, background_mean, (intensity - background_mean) if background_mean == background_mean else np.nan))
            fiber.metrics["centerline_intensity_mean"] = float(np.mean(point_intensities)) if point_intensities else np.nan
            fiber.metrics["centerline_intensity_std"] = float(np.std(point_intensities)) if point_intensities else np.nan
            fiber.metrics["local_background_mean"] = float(np.mean(point_backgrounds)) if point_backgrounds else np.nan
            fiber.metrics["local_background_std"] = float(np.std(point_backgrounds)) if point_backgrounds else np.nan
            fiber.metrics["contrast"] = float(np.mean(point_contrasts)) if point_contrasts else np.nan
            bg_std = fiber.metrics["local_background_std"]
            fiber.metrics["snr"] = float(fiber.metrics["contrast"] / bg_std) if bg_std == bg_std and abs(bg_std) > 1e-8 else np.nan
            widths_arr = np.asarray(image_domain_widths, dtype=float) if image_domain_widths else np.asarray([], dtype=float)
            fiber.metrics["image_domain_width_mean_px"] = float(np.mean(widths_arr)) if widths_arr.size else np.nan
            fiber.metrics["image_domain_width_std_px"] = float(np.std(widths_arr)) if widths_arr.size else np.nan

    # Neighborhood metrics using segment midpoints.
    if segment_midpoints:
        midpoint_arr = np.asarray(segment_midpoints, dtype=float)
        tangent_arr = np.asarray(segment_orientations, dtype=float)
        fiber_id_arr = np.asarray(segment_fiber_ids, dtype=int)
        local_scores = defaultdict(list)
        nn_diffs = defaultdict(list)
        nn_distances = defaultdict(list)
        if cKDTree is not None and len(midpoint_arr) > 1:
            tree = cKDTree(midpoint_arr)
            for idx, midpoint in enumerate(midpoint_arr):
                neighbor_indices = tree.query_ball_point(midpoint, DEFAULT_LOCAL_ALIGNMENT_RADIUS)
                neighbor_indices = [j for j in neighbor_indices if fiber_id_arr[j] != fiber_id_arr[idx]]
                if neighbor_indices:
                    dots = [abs(float(np.dot(tangent_arr[idx], tangent_arr[j]))) for j in neighbor_indices]
                    local_scores[int(fiber_id_arr[idx])].append(float(np.mean(dots)))
                distances, indices = tree.query(midpoint, k=min(len(midpoint_arr), 8))
                if np.isscalar(indices):
                    indices = [int(indices)]
                    distances = [float(distances)]
                best_index = None
                best_distance = None
                for dist, candidate in zip(distances, indices):
                    candidate = int(candidate)
                    if candidate == idx or fiber_id_arr[candidate] == fiber_id_arr[idx]:
                        continue
                    best_index = candidate
                    best_distance = float(dist)
                    break
                if best_index is not None:
                    nn_distances[int(fiber_id_arr[idx])].append(best_distance)
                    angle = np.degrees(np.arccos(np.clip(abs(np.dot(tangent_arr[idx], tangent_arr[best_index])), -1.0, 1.0)))
                    nn_diffs[int(fiber_id_arr[idx])].append(float(angle))
        for fiber in sample.fibers:
            fid = fiber.fiber_id
            fiber.metrics["mean_nn_distance_px"] = float(np.mean(nn_distances[fid])) if nn_distances[fid] else np.nan
            fiber.metrics["mean_nn_distance_um"] = _to_um(fiber.metrics["mean_nn_distance_px"], pixel_size_x_um) if nn_distances[fid] else np.nan
            fiber.metrics["local_alignment"] = float(np.mean(local_scores[fid])) if local_scores[fid] else np.nan
            fiber.metrics["nn_orientation_diff_mean_deg"] = float(np.mean(nn_diffs[fid])) if nn_diffs[fid] else np.nan

    return sample


def build_fiber_geometry_metrics(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        row = {
            "image_id": sample.image_id,
            "fiber_id": fiber.fiber_id,
            "component_id": fiber.component_id,
            "source_algorithm": fiber.source_algorithm,
            "source_type": fiber.source_type,
        }
        row.update({key: fiber.metrics.get(key, np.nan) for key in CSV_COLUMNS["fiber_geometry_metrics"] if key not in row})
        rows.append(row)
    return _fill_columns(pd.DataFrame(rows), "fiber_geometry_metrics")


def build_fiber_image_metrics(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        rows.append({
            "image_id": sample.image_id,
            "fiber_id": fiber.fiber_id,
            "source_algorithm": sample.source_algorithm,
            "source_type": "fiber_image",
            "centerline_intensity_mean": fiber.metrics.get("centerline_intensity_mean", np.nan),
            "centerline_intensity_std": fiber.metrics.get("centerline_intensity_std", np.nan),
            "local_background_mean": fiber.metrics.get("local_background_mean", np.nan),
            "local_background_std": fiber.metrics.get("local_background_std", np.nan),
            "contrast": fiber.metrics.get("contrast", np.nan),
            "snr": fiber.metrics.get("snr", np.nan),
            "image_domain_width_mean_px": fiber.metrics.get("image_domain_width_mean_px", np.nan),
            "image_domain_width_std_px": fiber.metrics.get("image_domain_width_std_px", np.nan),
            "psf_applied": sample.provenance.get("psf_applied", False),
            "noise_model": sample.provenance.get("noise_model"),
            "blur_applied": sample.provenance.get("blur_applied", False),
            "normalization_applied": sample.provenance.get("normalize_applied", False),
        })
    return _fill_columns(pd.DataFrame(rows), "fiber_image_metrics")


def build_junction_table(sample: CanonicalSample) -> pd.DataFrame:
    return _fill_columns(pd.DataFrame([
        {
            "image_id": sample.image_id,
            "junction_id": junction.junction_id,
            "x_px": junction.x_px,
            "y_px": junction.y_px,
            "z_px": junction.z_px,
            "x_um": junction.x_um,
            "y_um": junction.y_um,
            "z_um": junction.z_um,
            "degree": junction.degree,
            "component_id": junction.component_id,
            "source_algorithm": junction.source_algorithm,
            "source_type": junction.source_type,
        }
        for junction in sample.junctions
    ]), "junctions")


def build_endpoint_table(sample: CanonicalSample) -> pd.DataFrame:
    return _fill_columns(pd.DataFrame([
        {
            "image_id": sample.image_id,
            "endpoint_id": endpoint.endpoint_id,
            "fiber_id": endpoint.fiber_id,
            "point_index": endpoint.point_index,
            "x_px": endpoint.x_px,
            "y_px": endpoint.y_px,
            "z_px": endpoint.z_px,
            "x_um": endpoint.x_um,
            "y_um": endpoint.y_um,
            "z_um": endpoint.z_um,
            "orientation_xy_deg": endpoint.orientation_xy_deg,
            "orientation_yz_deg": endpoint.orientation_yz_deg,
            "orientation_xz_deg": endpoint.orientation_xz_deg,
            "endpoint_class": endpoint.endpoint_class,
            "component_id": endpoint.component_id,
            "touches_image_boundary": endpoint.touches_image_boundary,
        }
        for endpoint in sample.endpoints
    ]), "endpoints")


def build_fiber_junction_edge_table(sample: CanonicalSample) -> pd.DataFrame:
    return _fill_columns(pd.DataFrame([
        {
            "image_id": sample.image_id,
            "fiber_id": edge.fiber_id,
            "junction_id": edge.junction_id,
            "edge_type": edge.edge_type,
            "component_id": edge.component_id,
            "source_algorithm": edge.source_algorithm,
        }
        for edge in sample.edges
    ]), "fiber_junction_edges")


def build_components_table(sample: CanonicalSample) -> pd.DataFrame:
    return _fill_columns(pd.DataFrame([
        {
            "image_id": sample.image_id,
            "component_id": component.component_id,
            "num_fibers": len(component.fiber_ids),
            "num_junctions": len(component.junction_ids),
            "num_endpoints": len(component.endpoint_ids),
            "total_length_px": component.total_length_px,
            "total_length_um": component.total_length_um,
        }
        for component in sample.components
    ]), "components")


def build_fiber_points_table(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        for point in fiber.points:
            rows.append({
                "image_id": sample.image_id,
                "fiber_id": fiber.fiber_id,
                "point_index": point.point_index,
                "x_px": point.x_px,
                "y_px": point.y_px,
                "z_px": point.z_px,
                "x_um": point.x_um,
                "y_um": point.y_um,
                "z_um": point.z_um,
                "s_px": point.s_px,
                "s_um": point.s_um,
                "curvature_px_inv": point.curvature_px_inv,
                "curvature_um_inv": point.curvature_um_inv,
                "radius_px": point.radius_px,
                "radius_um": point.radius_um,
                "intensity": point.intensity,
                "background": point.background,
                "component_id": fiber.component_id,
                "source_type": point.source_type,
            })
    return _fill_columns(pd.DataFrame(rows), "fiber_points")


def build_fiber_segments_table(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        for segment in fiber.segments:
            rows.append({
                "image_id": sample.image_id,
                "fiber_id": fiber.fiber_id,
                "segment_index": segment.segment_index,
                "start_point_index": segment.start_point_index,
                "end_point_index": segment.end_point_index,
                "segment_length_px": segment.segment_length_px,
                "segment_length_um": segment.segment_length_um,
                "start_x_px": segment.start_x_px,
                "start_y_px": segment.start_y_px,
                "start_z_px": segment.start_z_px,
                "end_x_px": segment.end_x_px,
                "end_y_px": segment.end_y_px,
                "end_z_px": segment.end_z_px,
                "tangent_xy_deg": segment.tangent_xy_deg,
                "tangent_yz_deg": segment.tangent_yz_deg,
                "tangent_xz_deg": segment.tangent_xz_deg,
                "segment_radius_px": segment.segment_radius_px,
                "segment_radius_um": segment.segment_radius_um,
                "source_type": segment.source_type,
            })
    return _fill_columns(pd.DataFrame(rows), "fiber_segments")


def build_curvature_profile(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        for point in fiber.points:
            rows.append({
                "image_id": sample.image_id,
                "fiber_id": fiber.fiber_id,
                "point_index": point.point_index,
                "s_px": point.s_px,
                "s_um": point.s_um,
                "curvature_px_inv": point.curvature_px_inv,
                "curvature_um_inv": point.curvature_um_inv,
                "source_type": point.source_type,
            })
    return _fill_columns(pd.DataFrame(rows), "curvature_profile")


def build_radius_profile(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        for point in fiber.points:
            rows.append({
                "image_id": sample.image_id,
                "fiber_id": fiber.fiber_id,
                "point_index": point.point_index,
                "s_px": point.s_px,
                "s_um": point.s_um,
                "radius_px": point.radius_px,
                "radius_um": point.radius_um,
                "source_type": point.source_type,
            })
    return _fill_columns(pd.DataFrame(rows), "radius_profile")


def build_intensity_profile(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        for point in fiber.points:
            contrast = (point.intensity - point.background) if point.intensity is not None and point.background is not None and point.background == point.background else np.nan
            rows.append({
                "image_id": sample.image_id,
                "fiber_id": fiber.fiber_id,
                "point_index": point.point_index,
                "s_px": point.s_px,
                "s_um": point.s_um,
                "intensity": point.intensity,
                "background": point.background,
                "contrast": contrast,
                "source_type": "fiber_image",
            })
    return _fill_columns(pd.DataFrame(rows), "intensity_profile")


def build_local_alignment_profile(sample: CanonicalSample) -> pd.DataFrame:
    rows = []
    for fiber in sample.fibers:
        local_alignment = fiber.metrics.get("local_alignment", np.nan)
        nn_distance_px = fiber.metrics.get("mean_nn_distance_px", np.nan)
        nn_distance_um = fiber.metrics.get("mean_nn_distance_um", np.nan)
        nn_orientation_diff_deg = fiber.metrics.get("nn_orientation_diff_mean_deg", np.nan)
        for point in fiber.points:
            rows.append({
                "image_id": sample.image_id,
                "fiber_id": fiber.fiber_id,
                "point_index": point.point_index,
                "s_px": point.s_px,
                "s_um": point.s_um,
                "local_alignment": local_alignment,
                "nn_distance_px": nn_distance_px,
                "nn_distance_um": nn_distance_um,
                "nn_orientation_diff_deg": nn_orientation_diff_deg,
                "source_type": point.source_type,
            })
    return _fill_columns(pd.DataFrame(rows), "local_alignment")


def build_network_metrics(sample: CanonicalSample) -> pd.DataFrame:
    fiber_count = len(sample.fibers)
    junction_count = len(sample.junctions)
    endpoint_count = len(sample.endpoints)
    component_count = len(sample.components)
    width_px, height_px, depth_px = sample.dims_px
    volume_or_area = float(width_px * height_px * max(depth_px, 1)) if sample.is_3d else float(width_px * height_px)
    total_length_px = sum(float(fiber.metrics.get("contour_length_px") or 0.0) for fiber in sample.fibers)
    mean_alignment = _global_alignment_score(sample) if sample.fibers else np.nan
    mean_curvature_px_inv = _safe_nanmean([fiber.metrics.get("curvature_mean_px_inv", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    mean_curvature_um_inv = _safe_nanmean([fiber.metrics.get("curvature_mean_um_inv", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    mean_radius_px = _safe_nanmean([fiber.metrics.get("radius_mean_px", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    mean_radius_um = _safe_nanmean([fiber.metrics.get("radius_mean_um", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    mean_nn_distance_px = _safe_nanmean([fiber.metrics.get("mean_nn_distance_px", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    mean_nn_distance_um = _safe_nanmean([fiber.metrics.get("mean_nn_distance_um", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    mean_local_alignment = _safe_nanmean([fiber.metrics.get("local_alignment", np.nan) for fiber in sample.fibers]) if sample.fibers else np.nan
    row = {
        "image_id": sample.image_id,
        "source_algorithm": sample.source_algorithm,
        "num_fibers": fiber_count,
        "num_components": component_count,
        "num_junctions": junction_count,
        "num_endpoints": endpoint_count,
        "fiber_density": (fiber_count / volume_or_area) if volume_or_area > 0 else np.nan,
        "length_density": (total_length_px / volume_or_area) if volume_or_area > 0 else np.nan,
        "mean_alignment": mean_alignment,
        "mean_curvature_px_inv": mean_curvature_px_inv,
        "mean_curvature_um_inv": mean_curvature_um_inv,
        "mean_radius_px": mean_radius_px,
        "mean_radius_um": mean_radius_um,
        "mean_nn_distance_px": mean_nn_distance_px,
        "mean_nn_distance_um": mean_nn_distance_um,
        "mean_local_alignment": mean_local_alignment,
        "size_x_px": width_px,
        "size_y_px": height_px,
        "size_z_px": depth_px,
        "pixel_size_x_um": sample.pixel_size_x_um,
        "pixel_size_y_um": sample.pixel_size_y_um,
        "voxel_size_z_um": sample.voxel_size_z_um,
        "topology_link_count": sample.validation_metrics.get("topology_link_count", len(sample.edges)),
        "geometric_contact_edge_count": sample.validation_metrics.get("geometric_contact_edge_count", np.nan),
        "raster_centerline_components": sample.validation_metrics.get("raster_centerline_component_count", np.nan),
        "fiber_voxel_count": sample.validation_metrics.get("fiber_voxel_count", np.nan),
        "centerline_voxel_count": sample.validation_metrics.get("centerline_voxel_count", np.nan),
        "fiber_centerline_voxel_ratio": sample.validation_metrics.get("fiber_to_centerline_voxel_ratio", np.nan),
    }
    return _fill_columns(pd.DataFrame([row]), "network_metrics")


def build_manifest(sample: CanonicalSample, files_present: dict[str, list[str]], export_detail: str) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "sample_id": sample.sample_id,
        "image_id": sample.image_id,
        "mode": "3D" if sample.is_3d else "2D",
        "dimension_order": DIMENSION_ORDER_3D if sample.is_3d else DIMENSION_ORDER_2D,
        "coordinate_convention": COORDINATE_CONVENTION,
        "units": PHYSICAL_UNIT,
        "export_detail": export_detail,
        "source_algorithm": sample.source_algorithm,
        "outputs_present": {
            "centerline_mask": sample.images.centerline_mask is not None,
            "fiber_image": sample.images.fiber_image is not None,
            "enhanced_image": sample.images.enhanced_image is not None,
        },
        "files_present": files_present,
    }


def build_dataset_manifest_rows(sample: CanonicalSample, sample_path: str) -> dict[str, Any]:
    return {
        "sample_id": sample.sample_id,
        "image_id": sample.image_id,
        "mode": "3D" if sample.is_3d else "2D",
        "source_algorithm": sample.source_algorithm,
        "has_centerline_mask": sample.images.centerline_mask is not None,
        "has_fiber_image": sample.images.fiber_image is not None,
        "has_enhanced_image": sample.images.enhanced_image is not None,
        "sample_path": sample_path,
    }
