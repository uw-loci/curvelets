from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Optional

import numpy as np
import pandas as pd
import tifffile as tiff
from openpyxl.utils import get_column_letter

from .builders import (
    build_components_table,
    build_curvature_profile,
    build_endpoint_table,
    build_fiber_geometry_metrics,
    build_fiber_image_metrics,
    build_fiber_junction_edge_table,
    build_fiber_points_table,
    build_fiber_segments_table,
    build_intensity_profile,
    build_junction_table,
    build_local_alignment_profile,
    build_manifest,
    build_network_metrics,
    build_radius_profile,
)
from .schema import (
    CSV_COLUMNS,
    DEFAULT_WORKBOOK_SHEETS,
    EXPORT_DETAIL_CONCISE,
    EXPORT_DETAIL_FULL,
    IMAGE_FILE_NAMES,
    SCHEMA_VERSION,
)


def _ensure_dir(path: str | Path) -> Path:
    path = Path(path)
    path.mkdir(parents=True, exist_ok=True)
    return path


def _normalize_value(value: Any):
    if isinstance(value, np.generic):
        return value.item()
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, dict):
        return {str(k): _normalize_value(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_normalize_value(v) for v in value]
    return value


def _write_json(path: str | Path, payload: Any):
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(_normalize_value(payload), handle, indent=2)


def _write_csv(path: str | Path, frame: pd.DataFrame, columns: Optional[list[str]] = None):
    if frame is None:
        frame = pd.DataFrame(columns=columns or [])
    if columns is not None:
        for column in columns:
            if column not in frame.columns:
                frame[column] = np.nan
        frame = frame[columns]
    frame.to_csv(path, index=False)


def _prepare_image_array(array: Any) -> np.ndarray:
    if array is None:
        raise ValueError("Image artifact is missing")
    if hasattr(array, "convert"):
        array = np.asarray(array)
    else:
        array = np.asarray(array)
    if array.dtype == np.bool_:
        array = array.astype(np.uint8)
    return array


def _infer_axes(array: np.ndarray, is_3d: bool) -> Optional[str]:
    if array.ndim == 2:
        return "YX"
    if array.ndim == 3:
        if not is_3d and array.shape[-1] in (3, 4):
            return "YXS"
        return "ZYX" if is_3d else "CYX"
    if array.ndim == 4 and is_3d and array.shape[-1] in (3, 4):
        return "ZYXS"
    return None


def _write_ome_tiff(path: str | Path, array: Any, is_3d: bool):
    image = _prepare_image_array(array)
    axes = _infer_axes(image, is_3d)
    try:
        metadata = {"axes": axes} if axes else None
        tiff.imwrite(path, image, ome=True, metadata=metadata)
    except Exception:
        tiff.imwrite(path, image)


SHEET_DESCRIPTIONS = {
    "Overview": "High-level export metadata and sample counts.",
    "Fiber Geometry Metrics": "Per-fiber geometry and topology metrics derived from the canonical centerline geometry.",
    "Fiber Image Metrics": "Per-fiber image-domain metrics sampled from the rendered fiber image output.",
    "Network Metrics": "One-row sample/network summary covering counts, densities, alignment, and validation metrics.",
    "Junctions": "Junction locations and degrees in the canonical topology graph.",
    "Endpoints": "Endpoint coordinates, classes, orientations, and boundary-touch flags.",
    "Generation Recipe": "Synthetic generator input parameters used to produce this sample.",
    "Definitions": "Documentation for the workbook sheets and exported columns.",
}

FIELD_DESCRIPTIONS = {
    "image_id": "Stable sample image identifier.",
    "fiber_id": "Canonical fiber identifier shared across geometry and image-domain outputs.",
    "component_id": "Connected-component identifier in the canonical fiber graph.",
    "contour_length_px": "Fiber contour length in pixels along the ordered centerline.",
    "contour_length_um": "Fiber contour length in physical units.",
    "end_to_end_distance_px": "Distance between the first and last centerline point in pixels.",
    "end_to_end_distance_um": "Distance between the first and last centerline point in physical units.",
    "straightness": "End-to-end distance divided by contour length.",
    "curvature_mean_um_inv": "Mean per-point curvature in inverse physical units.",
    "curvature_std_um_inv": "Standard deviation of per-point curvature in inverse physical units.",
    "curvature_max_um_inv": "Maximum per-point curvature in inverse physical units.",
    "radius_mean_um": "Mean centerline-to-edge radius in physical units.",
    "radius_std_um": "Standard deviation of centerline-to-edge radius in physical units.",
    "radius_min_um": "Minimum centerline-to-edge radius in physical units.",
    "radius_max_um": "Maximum centerline-to-edge radius in physical units.",
    "junction_count": "Number of junction relationships touching this fiber.",
    "free_endpoint_count": "Number of free endpoints on this fiber.",
    "junction_endpoint_count": "Number of endpoints classified as junction-connected.",
    "centerline_intensity_mean": "Mean rendered fiber-image intensity sampled along the centerline.",
    "local_background_mean": "Mean local background sampled in an annulus or shell around the centerline.",
    "contrast": "Centerline intensity minus local background using the configured definition.",
    "snr": "Signal-to-noise ratio using the provenance-defined SNR definition.",
    "image_domain_width_mean_px": "Mean width estimated from the rendered fiber image in pixels.",
    "num_fibers": "Number of canonical fibers in the sample.",
    "num_components": "Number of connected components in the canonical fiber graph.",
    "num_junctions": "Number of junction nodes in the canonical fiber graph.",
    "num_endpoints": "Number of endpoints across all fibers.",
    "fiber_density": "Fiber count normalized by image area or volume.",
    "length_density": "Total contour length normalized by image area or volume.",
    "mean_alignment": "Mean local alignment score across fibers.",
    "mean_radius_um": "Mean per-fiber radius summary in physical units.",
    "mean_nn_distance_um": "Mean nearest-neighbor spacing between fibers in physical units.",
    "x_px": "X coordinate in pixel units.",
    "y_px": "Y coordinate in pixel units.",
    "z_px": "Z coordinate in voxel units; 0 for 2D exports.",
    "x_um": "X coordinate in physical units.",
    "y_um": "Y coordinate in physical units.",
    "z_um": "Z coordinate in physical units; 0 for 2D exports.",
    "degree": "Node degree in the canonical topology graph.",
    "edge_type": "Relationship between a fiber and a junction node.",
    "touches_image_boundary": "True when the endpoint or fiber touches the image boundary.",
}

THREE_D_ONLY_COLUMNS = {
    "orientation_mean_yz_deg",
    "orientation_mean_xz_deg",
    "orientation_yz_deg",
    "orientation_xz_deg",
    "tangent_yz_deg",
    "tangent_xz_deg",
    "size_z_px",
    "voxel_size_z_um",
    "z_px",
    "z_um",
    "topology_link_count",
    "geometric_contact_edge_count",
    "raster_centerline_components",
    "fiber_voxel_count",
    "centerline_voxel_count",
    "fiber_centerline_voxel_ratio",
}


def _is_missing_scalar(value: Any) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        return value == ""
    try:
        return bool(pd.isna(value))
    except Exception:
        return False


def _has_physical_units(sample) -> bool:
    return sample.pixel_size_x_um is not None or sample.pixel_size_y_um is not None or sample.voxel_size_z_um is not None


def _prune_frame_for_sample(frame: pd.DataFrame, sample, table_name: str) -> pd.DataFrame:
    if frame is None or frame.empty:
        return frame
    pruned = frame.copy()
    if table_name == "Overview":
        if "Value" in pruned.columns:
            pruned = pruned[~pruned["Value"].map(_is_missing_scalar)]
        return pruned.reset_index(drop=True)

    if not sample.is_3d:
        pruned = pruned.drop(columns=[column for column in THREE_D_ONLY_COLUMNS if column in pruned.columns], errors="ignore")

    if not _has_physical_units(sample):
        physical_columns = [
            column
            for column in pruned.columns
            if column.endswith("_um") or column.endswith("_um_inv") or column.startswith("pixel_size_") or column.startswith("voxel_size_")
        ]
        pruned = pruned.drop(columns=physical_columns, errors="ignore")

    empty_columns = [
        column for column in pruned.columns
        if all(_is_missing_scalar(value) for value in pruned[column].tolist())
    ]
    pruned = pruned.drop(columns=empty_columns, errors="ignore")
    return pruned


def _build_overview_frame(sample, export_detail: str) -> pd.DataFrame:
    rows = [
        {"Field": "Schema Version", "Value": SCHEMA_VERSION},
        {"Field": "Sample ID", "Value": sample.sample_id},
        {"Field": "Image ID", "Value": sample.image_id},
        {"Field": "Mode", "Value": "3D" if sample.is_3d else "2D"},
        {"Field": "Export Detail", "Value": export_detail},
        {"Field": "Source Algorithm", "Value": sample.source_algorithm},
        {"Field": "Fiber Count", "Value": len(sample.fibers)},
        {"Field": "Junction Count", "Value": len(sample.junctions)},
        {"Field": "Endpoint Count", "Value": len(sample.endpoints)},
        {"Field": "Component Count", "Value": len(sample.components)},
        {"Field": "Has Centerline Mask", "Value": sample.images.centerline_mask is not None},
        {"Field": "Has Fiber Image", "Value": sample.images.fiber_image is not None},
        {"Field": "Has Enhanced Image", "Value": sample.images.enhanced_image is not None},
        {"Field": "Pixel Size X (um)", "Value": sample.pixel_size_x_um},
        {"Field": "Pixel Size Y (um)", "Value": sample.pixel_size_y_um},
        {"Field": "Voxel Size Z (um)", "Value": sample.voxel_size_z_um},
    ]
    return pd.DataFrame(rows)


def _build_generation_recipe_frame(sample) -> pd.DataFrame:
    recipe = sample.generation_recipe or {}
    rows = [{"Parameter": key, "Value": value} for key, value in recipe.items()]
    return pd.DataFrame(rows, columns=["Parameter", "Value"])


def _build_definitions_frame(frames: dict[str, pd.DataFrame]) -> pd.DataFrame:
    rows = []
    for sheet_name, frame in frames.items():
        rows.append({
            "Sheet": sheet_name,
            "Field": "(sheet)",
            "Description": SHEET_DESCRIPTIONS.get(sheet_name, "Exported workbook sheet."),
        })
        for column in frame.columns:
            rows.append({
                "Sheet": sheet_name,
                "Field": column,
                "Description": FIELD_DESCRIPTIONS.get(column, "Exported field."),
            })
    return pd.DataFrame(rows, columns=["Sheet", "Field", "Description"])


def _write_excel_summary(sample_dir: Path, sample, export_detail: str):
    workbook_path = sample_dir / f"{sample.sample_id}_summary.xlsx"
    frames = {
        "Overview": _prune_frame_for_sample(_build_overview_frame(sample, export_detail), sample, "Overview"),
        "Fiber Geometry Metrics": _prune_frame_for_sample(build_fiber_geometry_metrics(sample), sample, "fiber_geometry_metrics"),
        "Fiber Image Metrics": _prune_frame_for_sample(
            build_fiber_image_metrics(sample) if sample.images.fiber_image is not None else pd.DataFrame(columns=CSV_COLUMNS["fiber_image_metrics"]),
            sample,
            "fiber_image_metrics",
        ),
        "Network Metrics": _prune_frame_for_sample(build_network_metrics(sample), sample, "network_metrics"),
        "Junctions": _prune_frame_for_sample(build_junction_table(sample), sample, "junctions"),
        "Endpoints": _prune_frame_for_sample(build_endpoint_table(sample), sample, "endpoints"),
        "Generation Recipe": _build_generation_recipe_frame(sample),
    }
    frames["Definitions"] = _build_definitions_frame(frames)
    with pd.ExcelWriter(workbook_path, engine="openpyxl") as writer:
        for sheet_name in DEFAULT_WORKBOOK_SHEETS:
            frame = frames.get(sheet_name, pd.DataFrame())
            frame.to_excel(writer, sheet_name=sheet_name, index=False)
            worksheet = writer.sheets[sheet_name]
            worksheet.freeze_panes = worksheet["A2"]
            for idx, col in enumerate(frame.columns, start=1):
                max_length = max([len(str(col))] + [len(str(value)) for value in frame[col].tolist()]) + 2 if not frame.empty else len(str(col)) + 2
                worksheet.column_dimensions[get_column_letter(idx)].width = min(max_length, 60)



def export_session_restore(out_dir: str | Path, app_state: dict[str, Any]) -> Path:
    metadata_dir = _ensure_dir(Path(out_dir) / "metadata")
    path = metadata_dir / "session_params.json"
    _write_json(path, app_state)
    manifest_path = Path(out_dir) / "manifest.json"
    if manifest_path.exists():
        with open(manifest_path, "r", encoding="utf-8") as handle:
            manifest = json.load(handle)
        files_present = manifest.setdefault("files_present", {})
        metadata_files = files_present.setdefault("metadata", [])
        if "session_params.json" not in metadata_files:
            metadata_files.append("session_params.json")
        _write_json(manifest_path, manifest)
    return path


def _write_default_files(sample_dir: Path, sample, export_detail: str, include_excel: bool):
    images_dir = _ensure_dir(sample_dir / "images")
    metrics_dir = _ensure_dir(sample_dir / "metrics")
    metadata_dir = _ensure_dir(sample_dir / "metadata")
    geometry_dir = _ensure_dir(sample_dir / "geometry")

    files_present: dict[str, list[str]] = {
        "images": [],
        "metrics": [],
        "metadata": [],
        "geometry": [],
        "profiles": [],
    }

    image_artifacts = {
        "centerline_mask": sample.images.centerline_mask,
        "centerline_instance_labels": sample.images.centerline_instance_labels,
        "junction_mask": sample.images.junction_mask,
        "endpoint_mask": sample.images.endpoint_mask,
        "fiber_image": sample.images.fiber_image,
        "enhanced_image": sample.images.enhanced_image,
    }
    for key, artifact in image_artifacts.items():
        if artifact is None:
            continue
        path = images_dir / IMAGE_FILE_NAMES[key]
        _write_ome_tiff(path, artifact, sample.is_3d)
        files_present["images"].append(path.name)

    metric_frames = {
        "fiber_geometry_metrics.csv": build_fiber_geometry_metrics(sample),
        "network_metrics.csv": build_network_metrics(sample),
        "junctions.csv": build_junction_table(sample),
        "endpoints.csv": build_endpoint_table(sample),
        "fiber_junction_edges.csv": build_fiber_junction_edge_table(sample),
    }
    if sample.images.fiber_image is not None:
        metric_frames["fiber_image_metrics.csv"] = build_fiber_image_metrics(sample)
    for filename, frame in metric_frames.items():
        key = filename.replace(".csv", "")
        frame = _prune_frame_for_sample(frame, sample, key)
        columns = list(frame.columns)
        path = metrics_dir / filename
        _write_csv(path, frame, columns)
        files_present["metrics"].append(path.name)

    centerlines_path = geometry_dir / "centerlines.json"
    _write_json(centerlines_path, sample.to_centerlines_json())
    files_present["geometry"].append(centerlines_path.name)

    _write_json(metadata_dir / "provenance.json", sample.provenance)
    files_present["metadata"].append("provenance.json")
    if sample.generation_recipe:
        _write_json(metadata_dir / "generation_recipe.json", sample.generation_recipe)
        files_present["metadata"].append("generation_recipe.json")
    if sample.extractor_recipe:
        _write_json(metadata_dir / "extractor_recipe.json", sample.extractor_recipe)
        files_present["metadata"].append("extractor_recipe.json")
    if sample.enhancement_recipe:
        _write_json(metadata_dir / "enhancement_recipe.json", sample.enhancement_recipe)
        files_present["metadata"].append("enhancement_recipe.json")

    manifest = build_manifest(sample, files_present, export_detail)
    _write_json(sample_dir / "manifest.json", manifest)

    if include_excel:
        _write_excel_summary(sample_dir, sample, export_detail)
        files_present["metadata"].append(f"{sample.sample_id}_summary.xlsx")
        _write_json(sample_dir / "manifest.json", build_manifest(sample, files_present, export_detail))

    return files_present



def export_canonical_research_package(out_dir: str | Path, sample, include_excel: bool = True) -> dict[str, list[str]]:
    sample_dir = _ensure_dir(out_dir)
    return _write_default_files(sample_dir, sample, EXPORT_DETAIL_CONCISE, include_excel)



def export_full_raw_geometry(out_dir: str | Path, sample, include_excel: bool = True) -> dict[str, list[str]]:
    sample_dir = _ensure_dir(out_dir)
    files_present = _write_default_files(sample_dir, sample, EXPORT_DETAIL_FULL, include_excel)

    geometry_dir = _ensure_dir(sample_dir / "geometry")
    profiles_dir = _ensure_dir(sample_dir / "profiles")

    geometry_frames = {
        "fiber_points.csv": (build_fiber_points_table(sample), CSV_COLUMNS["fiber_points"]),
        "fiber_segments.csv": (build_fiber_segments_table(sample), CSV_COLUMNS["fiber_segments"]),
        "components.csv": (build_components_table(sample), CSV_COLUMNS["components"]),
    }
    for filename, (frame, columns) in geometry_frames.items():
        frame = _prune_frame_for_sample(frame, sample, filename.replace(".csv", ""))
        _write_csv(geometry_dir / filename, frame, list(frame.columns))
        files_present["geometry"].append(filename)

    profile_frames = {
        "curvature_profile.csv": (build_curvature_profile(sample), CSV_COLUMNS["curvature_profile"]),
        "radius_profile.csv": (build_radius_profile(sample), CSV_COLUMNS["radius_profile"]),
        "intensity_profile.csv": (build_intensity_profile(sample), CSV_COLUMNS["intensity_profile"]),
        "local_alignment.csv": (build_local_alignment_profile(sample), CSV_COLUMNS["local_alignment"]),
    }
    for filename, (frame, columns) in profile_frames.items():
        frame = _prune_frame_for_sample(frame, sample, filename.replace(".csv", ""))
        _write_csv(profiles_dir / filename, frame, list(frame.columns))
        files_present["profiles"].append(filename)

    _write_json(sample_dir / "manifest.json", build_manifest(sample, files_present, EXPORT_DETAIL_FULL))
    return files_present



def export_excel_summary(out_dir: str | Path, sample, export_detail: str = EXPORT_DETAIL_CONCISE) -> Path:
    sample_dir = _ensure_dir(out_dir)
    _write_excel_summary(sample_dir, sample, export_detail)
    return sample_dir / f"{sample.sample_id}_summary.xlsx"



def write_dataset_manifest(parent_dir: str | Path, rows: list[dict[str, Any]]) -> Path:
    parent_dir = _ensure_dir(parent_dir)
    frame = pd.DataFrame(rows)
    _write_csv(parent_dir / "dataset_manifest.csv", frame, CSV_COLUMNS["dataset_manifest"])
    return parent_dir / "dataset_manifest.csv"
