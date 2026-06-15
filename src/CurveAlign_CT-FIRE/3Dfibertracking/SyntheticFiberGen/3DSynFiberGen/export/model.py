from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any, Optional


@dataclass
class CanonicalPoint:
    point_index: int
    x_px: float
    y_px: float
    z_px: float = 0.0
    s_px: float = 0.0
    x_um: Optional[float] = None
    y_um: Optional[float] = None
    z_um: Optional[float] = None
    s_um: Optional[float] = None
    curvature_px_inv: Optional[float] = None
    curvature_um_inv: Optional[float] = None
    radius_px: Optional[float] = None
    radius_um: Optional[float] = None
    intensity: Optional[float] = None
    background: Optional[float] = None
    component_id: Optional[int] = None
    source_type: str = "centerline_geometry"


@dataclass
class CanonicalSegment:
    segment_index: int
    start_point_index: int
    end_point_index: int
    start_x_px: float
    start_y_px: float
    start_z_px: float
    end_x_px: float
    end_y_px: float
    end_z_px: float
    segment_length_px: float
    segment_length_um: Optional[float] = None
    tangent_xy_deg: Optional[float] = None
    tangent_yz_deg: Optional[float] = None
    tangent_xz_deg: Optional[float] = None
    segment_radius_px: Optional[float] = None
    segment_radius_um: Optional[float] = None
    source_type: str = "centerline_geometry"


@dataclass
class CanonicalFiber:
    fiber_id: int
    component_id: Optional[int] = None
    points: list[CanonicalPoint] = field(default_factory=list)
    segments: list[CanonicalSegment] = field(default_factory=list)
    metrics: dict[str, Any] = field(default_factory=dict)
    source_algorithm: str = "synthetic_generator"
    source_type: str = "centerline_geometry"


@dataclass
class CanonicalJunction:
    junction_id: int
    x_px: float
    y_px: float
    z_px: float = 0.0
    x_um: Optional[float] = None
    y_um: Optional[float] = None
    z_um: Optional[float] = None
    degree: int = 0
    component_id: Optional[int] = None
    source_algorithm: str = "synthetic_generator"
    source_type: str = "centerline_geometry"


@dataclass
class CanonicalEndpoint:
    endpoint_id: int
    fiber_id: int
    point_index: int
    x_px: float
    y_px: float
    z_px: float = 0.0
    x_um: Optional[float] = None
    y_um: Optional[float] = None
    z_um: Optional[float] = None
    orientation_xy_deg: Optional[float] = None
    orientation_yz_deg: Optional[float] = None
    orientation_xz_deg: Optional[float] = None
    endpoint_class: str = "free_end"
    component_id: Optional[int] = None
    touches_image_boundary: bool = False


@dataclass
class CanonicalEdge:
    fiber_id: int
    junction_id: int
    edge_type: str
    component_id: Optional[int] = None
    source_algorithm: str = "synthetic_generator"


@dataclass
class CanonicalComponent:
    component_id: int
    fiber_ids: list[int] = field(default_factory=list)
    junction_ids: list[int] = field(default_factory=list)
    endpoint_ids: list[int] = field(default_factory=list)
    total_length_px: float = 0.0
    total_length_um: Optional[float] = None


@dataclass
class CanonicalImageArtifacts:
    centerline_mask: Any = None
    centerline_instance_labels: Any = None
    junction_mask: Any = None
    endpoint_mask: Any = None
    fiber_image: Any = None
    enhanced_image: Any = None
    overlay_image: Any = None  # RGB uint8: per-fiber unique colors on grayscale background


@dataclass
class CanonicalSample:
    sample_id: str
    image_id: str
    is_3d: bool
    dims_px: tuple[int, int, int]
    pixel_size_x_um: Optional[float] = None
    pixel_size_y_um: Optional[float] = None
    voxel_size_z_um: Optional[float] = None
    source_algorithm: str = "synthetic_generator"
    source_type: str = "centerline_geometry"
    fibers: list[CanonicalFiber] = field(default_factory=list)
    junctions: list[CanonicalJunction] = field(default_factory=list)
    endpoints: list[CanonicalEndpoint] = field(default_factory=list)
    edges: list[CanonicalEdge] = field(default_factory=list)
    components: list[CanonicalComponent] = field(default_factory=list)
    images: CanonicalImageArtifacts = field(default_factory=CanonicalImageArtifacts)
    provenance: dict[str, Any] = field(default_factory=dict)
    generation_recipe: dict[str, Any] = field(default_factory=dict)
    extractor_recipe: Optional[dict[str, Any]] = None
    enhancement_recipe: Optional[dict[str, Any]] = None
    validation_metrics: dict[str, Any] = field(default_factory=dict)

    def to_centerlines_json(self) -> dict[str, Any]:
        return {
            "sample_id": self.sample_id,
            "image_id": self.image_id,
            "is_3d": self.is_3d,
            "dims_px": {
                "x": self.dims_px[0],
                "y": self.dims_px[1],
                "z": self.dims_px[2],
            },
            "pixel_size_x_um": self.pixel_size_x_um,
            "pixel_size_y_um": self.pixel_size_y_um,
            "voxel_size_z_um": self.voxel_size_z_um,
            "source_algorithm": self.source_algorithm,
            "source_type": self.source_type,
            "fibers": [
                {
                    "fiber_id": fiber.fiber_id,
                    "component_id": fiber.component_id,
                    "source_algorithm": fiber.source_algorithm,
                    "source_type": fiber.source_type,
                    "metrics": fiber.metrics,
                    "points": [asdict(point) for point in fiber.points],
                    "segments": [asdict(segment) for segment in fiber.segments],
                }
                for fiber in self.fibers
            ],
            "junctions": [asdict(junction) for junction in self.junctions],
            "endpoints": [asdict(endpoint) for endpoint in self.endpoints],
            "edges": [asdict(edge) for edge in self.edges],
            "components": [asdict(component) for component in self.components],
        }
