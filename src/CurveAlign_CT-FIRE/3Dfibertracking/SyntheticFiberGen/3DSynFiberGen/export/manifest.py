from __future__ import annotations

from typing import Any

from .model import CanonicalSample
from .schema import (
    COORDINATE_CONVENTION,
    DIMENSION_ORDER_2D,
    DIMENSION_ORDER_3D,
    PHYSICAL_UNIT,
    SCHEMA_VERSION,
)


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
