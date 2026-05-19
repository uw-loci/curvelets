from __future__ import annotations

SCHEMA_VERSION = "2.0.0"
COORDINATE_CONVENTION = "Exported tables use x,y,z columns in pixel and physical units; 2D exports use z=0. Internal array order may remain z,y,x."
DIMENSION_ORDER_2D = "YX"
DIMENSION_ORDER_3D = "ZYX"
PHYSICAL_UNIT = "micron"

DEFAULT_BACKGROUND_ANNULUS_NEAR = 3.0
DEFAULT_BACKGROUND_ANNULUS_FAR = 6.0
DEFAULT_BACKGROUND_SECTOR_COUNT = 16
DEFAULT_LOCAL_ALIGNMENT_RADIUS = 24.0

EXPORT_DETAIL_CONCISE = "concise"
EXPORT_DETAIL_FULL = "full"

IMAGE_FILE_NAMES = {
    "centerline_mask": "centerline_mask.ome.tiff",
    "centerline_instance_labels": "centerline_instance_labels.ome.tiff",
    "junction_mask": "junction_mask.ome.tiff",
    "endpoint_mask": "endpoint_mask.ome.tiff",
    "fiber_image": "fiber_image.ome.tiff",
    "enhanced_image": "enhanced_image.ome.tiff",
}

CSV_COLUMNS = {
    "fiber_geometry_metrics": [
        "image_id", "fiber_id", "component_id", "source_algorithm", "source_type",
        "contour_length_px", "contour_length_um", "end_to_end_distance_px", "end_to_end_distance_um",
        "straightness", "orientation_mean_xy_deg", "orientation_mean_yz_deg", "orientation_mean_xz_deg",
        "curvature_mean_px_inv", "curvature_std_px_inv", "curvature_max_px_inv",
        "curvature_mean_um_inv", "curvature_std_um_inv", "curvature_max_um_inv",
        "radius_mean_px", "radius_std_px", "radius_min_px", "radius_max_px",
        "radius_mean_um", "radius_std_um", "radius_min_um", "radius_max_um",
        "free_endpoint_count", "junction_endpoint_count", "junction_count", "is_closed",
        "touches_image_boundary", "is_truncated",
    ],
    "fiber_image_metrics": [
        "image_id", "fiber_id", "source_algorithm", "source_type",
        "centerline_intensity_mean", "centerline_intensity_std",
        "local_background_mean", "local_background_std",
        "contrast", "snr",
        "image_domain_width_mean_px", "image_domain_width_std_px",
        "psf_applied", "noise_model", "blur_applied", "normalization_applied",
    ],
    "network_metrics": [
        "image_id", "source_algorithm", "num_fibers", "num_components", "num_junctions", "num_endpoints",
        "fiber_density", "length_density", "mean_alignment",
        "mean_curvature_px_inv", "mean_curvature_um_inv",
        "mean_radius_px", "mean_radius_um",
        "mean_nn_distance_px", "mean_nn_distance_um",
        "mean_local_alignment", "size_x_px", "size_y_px", "size_z_px",
        "pixel_size_x_um", "pixel_size_y_um", "voxel_size_z_um",
        "topology_link_count", "geometric_contact_edge_count", "raster_centerline_components",
        "fiber_voxel_count", "centerline_voxel_count", "fiber_centerline_voxel_ratio",
    ],
    "junctions": [
        "image_id", "junction_id", "x_px", "y_px", "z_px", "x_um", "y_um", "z_um",
        "degree", "component_id", "source_algorithm", "source_type",
    ],
    "endpoints": [
        "image_id", "endpoint_id", "fiber_id", "point_index", "x_px", "y_px", "z_px",
        "x_um", "y_um", "z_um", "orientation_xy_deg", "orientation_yz_deg", "orientation_xz_deg",
        "endpoint_class", "component_id", "touches_image_boundary",
    ],
    "fiber_junction_edges": [
        "image_id", "fiber_id", "junction_id", "edge_type", "component_id", "source_algorithm",
    ],
    "roi_metrics": [
        "image_id", "roi_id", "roi_name", "fiber_count", "length_density", "mean_alignment",
        "mean_distance_to_boundary_um", "notes",
    ],
    "fiber_roi_relationships": [
        "image_id", "fiber_id", "roi_id", "distance_to_boundary_um", "orientation_relative_to_boundary_deg",
        "local_density", "local_alignment",
    ],
    "components": [
        "image_id", "component_id", "num_fibers", "num_junctions", "num_endpoints", "total_length_px", "total_length_um",
    ],
    "fiber_points": [
        "image_id", "fiber_id", "point_index", "x_px", "y_px", "z_px", "x_um", "y_um", "z_um",
        "s_px", "s_um", "curvature_px_inv", "curvature_um_inv", "radius_px", "radius_um",
        "intensity", "background", "component_id", "source_type",
    ],
    "fiber_segments": [
        "image_id", "fiber_id", "segment_index", "start_point_index", "end_point_index",
        "segment_length_px", "segment_length_um",
        "start_x_px", "start_y_px", "start_z_px", "end_x_px", "end_y_px", "end_z_px",
        "tangent_xy_deg", "tangent_yz_deg", "tangent_xz_deg", "segment_radius_px", "segment_radius_um", "source_type",
    ],
    "curvature_profile": ["image_id", "fiber_id", "point_index", "s_px", "s_um", "curvature_px_inv", "curvature_um_inv", "source_type"],
    "radius_profile": ["image_id", "fiber_id", "point_index", "s_px", "s_um", "radius_px", "radius_um", "source_type"],
    "intensity_profile": ["image_id", "fiber_id", "point_index", "s_px", "s_um", "intensity", "background", "contrast", "source_type"],
    "local_alignment": ["image_id", "fiber_id", "point_index", "s_px", "s_um", "local_alignment", "nn_distance_px", "nn_distance_um", "nn_orientation_diff_deg", "source_type"],
    "dataset_manifest": [
        "sample_id", "image_id", "mode", "source_algorithm", "has_centerline_mask", "has_fiber_image",
        "has_enhanced_image", "sample_path",
    ],
}

DEFAULT_WORKBOOK_SHEETS = [
    "Overview",
    "Fiber Geometry Metrics",
    "Fiber Image Metrics",
    "Network Metrics",
    "Junctions",
    "Endpoints",
    "Generation Recipe",
    "Definitions",
]
