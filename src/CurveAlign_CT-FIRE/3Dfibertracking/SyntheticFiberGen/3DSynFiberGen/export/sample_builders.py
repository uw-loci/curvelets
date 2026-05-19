from __future__ import annotations

from collections import defaultdict
from copy import deepcopy
from datetime import datetime
from typing import Any

import numpy as np

try:
    from scipy.spatial import cKDTree
except ImportError:  # pragma: no cover
    cKDTree = None

from ._builder_utils import (
    _as_array,
    _curvature_three_points,
    _distance_transform_for_image,
    _infer_units,
    _orientation_degrees,
    _param_use,
    _param_value,
    _safe_int,
    _sample_annulus,
    _segment_point_distance,
    _to_um,
    _touches_boundary,
    _UnionFind,
)
from .model import (
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
from .schema import (
    COORDINATE_CONVENTION,
    DEFAULT_BACKGROUND_ANNULUS_FAR,
    DEFAULT_BACKGROUND_ANNULUS_NEAR,
    DEFAULT_BACKGROUND_SECTOR_COUNT,
    DEFAULT_LOCAL_ALIGNMENT_RADIUS,
    DIMENSION_ORDER_2D,
    DIMENSION_ORDER_3D,
    PHYSICAL_UNIT,
    SCHEMA_VERSION,
)


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
            radius_px = float(width_value) / 2.0 if not np.isnan(width_value) else np.nan
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
                radius_um=_to_um(radius_px, pixel_size_x_um) if not np.isnan(radius_px) else None,
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
                segment_radius_um=_to_um(radius_px, pixel_size_x_um) if not np.isnan(radius_px) else None,
                source_type="centerline_geometry",
            ))
            segment_midpoints.append((start + end) / 2.0)
            segment_orientations.append(seg_vec / max(seg_len, 1e-8))
            segment_fiber_ids.append(fiber_id)

        contour_length_px = float(cumulative_s[-1])
        chord_px = float(np.linalg.norm(point_arrays[-1] - point_arrays[0]))
        radius_array_px = np.asarray([v for v in radius_values_px if not np.isnan(v)], dtype=float)
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
        for _junction_id, edges in edges_by_junction.items():
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
                background_mean, _background_std = _sample_annulus(
                    fiber_image_arr,
                    binary_fiber_region,
                    coord,
                    DEFAULT_BACKGROUND_ANNULUS_NEAR,
                    DEFAULT_BACKGROUND_ANNULUS_FAR,
                )
                point.intensity = intensity
                point.background = background_mean
                point_intensities.append(intensity)
                if not np.isnan(background_mean):
                    point_backgrounds.append(background_mean)
                    point_contrasts.append(intensity - background_mean)
                if image_dt is not None:
                    if is_3d:
                        zyx = np.clip(np.round(np.asarray([point.z_px, point.y_px, point.x_px])).astype(int), 0, np.array(image_dt.shape) - 1)
                        image_domain_widths.append(float(image_dt[tuple(zyx)]) * 2.0)
                    else:
                        yx = np.clip(np.round(np.asarray([point.y_px, point.x_px])).astype(int), 0, np.array(image_dt.shape) - 1)
                        image_domain_widths.append(float(image_dt[tuple(yx)]) * 2.0)
                point_rows.append((
                    fiber.fiber_id,
                    point.point_index,
                    point.s_um,
                    intensity,
                    background_mean,
                    (intensity - background_mean) if not np.isnan(background_mean) else np.nan,
                ))
            fiber.metrics["centerline_intensity_mean"] = float(np.mean(point_intensities)) if point_intensities else np.nan
            fiber.metrics["centerline_intensity_std"] = float(np.std(point_intensities)) if point_intensities else np.nan
            fiber.metrics["local_background_mean"] = float(np.mean(point_backgrounds)) if point_backgrounds else np.nan
            fiber.metrics["local_background_std"] = float(np.std(point_backgrounds)) if point_backgrounds else np.nan
            fiber.metrics["contrast"] = float(np.mean(point_contrasts)) if point_contrasts else np.nan
            bg_std = fiber.metrics["local_background_std"]
            fiber.metrics["snr"] = float(fiber.metrics["contrast"] / bg_std) if not np.isnan(bg_std) and abs(bg_std) > 1e-8 else np.nan
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
                for dist, candidate in zip(distances, indices, strict=False):
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
