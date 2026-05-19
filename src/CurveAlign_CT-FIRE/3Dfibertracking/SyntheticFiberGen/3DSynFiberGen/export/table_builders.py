from __future__ import annotations

import numpy as np
import pandas as pd

from ._builder_utils import _fill_columns, _global_alignment_score, _safe_nanmean
from .model import CanonicalSample
from .schema import CSV_COLUMNS


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
