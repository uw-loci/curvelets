
from __future__ import annotations

import time
from copy import deepcopy

import numpy as np
import pandas as pd
from scipy.ndimage import label

from core.abort import _raise_if_aborted
from core.distributions import distribution_from_dict
from core.geometry import Vector
from core.params import Optional, Param
from core.rng import RngUtility3D
from generation.fiber import Fiber
from generation.sample_2d import FiberImage
from generation.topology_3d import (
    apply_topology_3d,
    build_geometric_contact_edges_3d,
    closest_point_on_segment_3d,
    count_graph_components,
    segment_segment_distance_3d,
)
from postprocess.pipeline_3d import ImageUtility3D
from postprocess.psf import PSFManager
from rendering.raster_3d import draw_scale_bar_on_volume, render_fibers_to_volume


class FiberImage3D(FiberImage):
    class Params(FiberImage.Params):
        def __init__(self):
            super().__init__()
            self.segmentLength.value = 6.0
            self.width.mean.value = 3.0
            self.width.sigma.value = 0.75
            self.straightness.min.value = 0.94
            self.straightness.max.value = 0.99
            self.imageDepth = Param(value=512, name="image depth", hint="The depth of the saved volume in pixels")
            self.curvature = Param(value=0.8, name="curvature", hint="The curvature of fibers in 3D")
            self.branchingProbability = Param(value=0.1, name="branching probability", hint="The probability of fibers branching")
            self.meanDirection = Param(value=[0.0, 0.0, 1.0], name="mean direction", hint="The average fiber direction as a 3D vector")
            self.blurRadius = Optional(value=5.0, name="blur radius", hint="Check to enable Gaussian blurring; value is the radius of the blur in pixels", use=False)
            self.noiseMean = Optional(value=10.0, name="noise mean", hint="Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)", use=False)
            self.distanceFalloff = Optional(value=64.0, name="distance falloff", hint="Check to apply a distance filter; value controls the sharpness of the intensity falloff", use=False)
            self.alignment3D = Param(value=0.65, name="alignment", hint="A value between 0 and 1 indicating how close fibers are to the mean direction on average")
            self.minAngleChange = Param(value=0.0, name="min angle change", hint="Minimum angle change in degrees")
            self.maxAngleChange = Param(value=20.0, name="max angle change", hint="Maximum angle change in degrees")
            self.blur = self.blurRadius
            self.noise = self.noiseMean
            self.distance = self.distanceFalloff
            self.min_angle_change = self.minAngleChange
            self.max_angle_change = self.maxAngleChange

        @staticmethod
        def from_dict(params_dict):
            params = FiberImage3D.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            if "generateCenterlineLabel" in params_dict:
                params.generateCenterlineLabel = Param.from_dict(params_dict["generateCenterlineLabel"])
            if "generateFiberImage" in params_dict:
                params.generateFiberImage = Param.from_dict(params_dict["generateFiberImage"])
            if "centerlineOutputType" in params_dict:
                params.centerlineOutputType = Param.from_dict(params_dict["centerlineOutputType"])
            if "renderMode" in params_dict:
                params.renderMode = Param.from_dict(params_dict["renderMode"])
            if "centerlineMaskWidthPx" in params_dict:
                params.centerlineMaskWidthPx = Param.from_dict(params_dict["centerlineMaskWidthPx"])
            elif "maskType" in params_dict:
                params.centerlineMaskWidthPx.value = 1
            if "maskOutputMode" in params_dict:
                params.maskOutputMode = Param.from_dict(params_dict["maskOutputMode"])
            elif "maskBinary" in params_dict:
                Param.from_dict(params_dict["maskBinary"])
                params.maskOutputMode.value = "Binary"
            if "generateCenterlineLabel" not in params_dict and "generateFiberImage" not in params_dict:
                legacy_render_mode = str(params.renderMode.get_value()).strip().lower()
                params.generateCenterlineLabel.value = legacy_render_mode == "mask mode"
                params.generateFiberImage.value = legacy_render_mode != "mask mode"
            params.centerlineOutputType.value = "Binary"
            params.maskOutputMode.value = "Binary"
            params.alignment3D = Param.from_dict(params_dict["alignment3D"])
            params.meanDirection = Param.from_dict(params_dict["meanDirection"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageDepth = Param.from_dict(params_dict["imageDepth"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            if "showCenterlineOverlay" in params_dict:
                params.showCenterlineOverlay = Optional.from_dict(params_dict["showCenterlineOverlay"])
            if "centerlineOverlayColor" in params_dict:
                params.centerlineOverlayColor = Param.from_dict(params_dict["centerlineOverlayColor"])
            if "centerlineOverlayBrightness" in params_dict:
                params.centerlineOverlayBrightness = Param.from_dict(params_dict["centerlineOverlayBrightness"])
            params.length = distribution_from_dict(params_dict.get("length"), params.length)
            params.width = distribution_from_dict(params_dict.get("width"), params.width)
            params.straightness = distribution_from_dict(params_dict.get("straightness"), params.straightness)
            if "intensity" in params_dict:
                params.intensity = distribution_from_dict(params_dict.get("intensity"), params.intensity)
            params.curvature = Param.from_dict(params_dict["curvature"])
            params.branchingProbability = Param.from_dict(params_dict["branchingProbability"])
            params.scale = Optional.from_dict(params_dict["scale"])
            params.downSample = Optional.from_dict(params_dict["downSample"])
            params.blurRadius = Optional.from_dict(params_dict["blurRadius"])
            params.noiseMean = Optional.from_dict(params_dict["noiseMean"])
            params.distanceFalloff = Optional.from_dict(params_dict["distanceFalloff"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            params.minAngleChange = Param.from_dict(params_dict["minAngleChange"])
            params.maxAngleChange = Param.from_dict(params_dict["maxAngleChange"])
            # Noise model additions
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            if "psfEnabled" in params_dict:
                params.psfEnabled = Optional.from_dict(params_dict["psfEnabled"])
            if "psfType" in params_dict:
                params.psfType = Param.from_dict(params_dict["psfType"])
            if "psfGaussianNA" in params_dict:
                params.psfGaussianNA = Param.from_dict(params_dict["psfGaussianNA"])
            if "psfGaussianWavelength" in params_dict:
                params.psfGaussianWavelength = Param.from_dict(params_dict["psfGaussianWavelength"])
            if "psfPixelSizeZ" in params_dict:
                params.psfPixelSizeZ = Param.from_dict(params_dict["psfPixelSizeZ"])
            if "psfPixelSizeY" in params_dict:
                params.psfPixelSizeY = Param.from_dict(params_dict["psfPixelSizeY"])
            if "psfPixelSizeX" in params_dict:
                params.psfPixelSizeX = Param.from_dict(params_dict["psfPixelSizeX"])
            if "psfVectorialNA" in params_dict:
                params.psfVectorialNA = Param.from_dict(params_dict["psfVectorialNA"])
            if "psfVectorialMediumRI" in params_dict:
                params.psfVectorialMediumRI = Param.from_dict(params_dict["psfVectorialMediumRI"])
            if "psfVectorialSampleRI" in params_dict:
                params.psfVectorialSampleRI = Param.from_dict(params_dict["psfVectorialSampleRI"])
            if "psfVectorialWavelength" in params_dict:
                params.psfVectorialWavelength = Param.from_dict(params_dict["psfVectorialWavelength"])
            if "psfVectorialPolarization" in params_dict:
                params.psfVectorialPolarization = Param.from_dict(params_dict["psfVectorialPolarization"])
            if "psfVectorialVolumeZ" in params_dict:
                params.psfVectorialVolumeZ = Param.from_dict(params_dict["psfVectorialVolumeZ"])
            if "psfVectorialVolumeY" in params_dict:
                params.psfVectorialVolumeY = Param.from_dict(params_dict["psfVectorialVolumeY"])
            if "psfVectorialVolumeX" in params_dict:
                params.psfVectorialVolumeX = Param.from_dict(params_dict["psfVectorialVolumeX"])
            if "psfVectorialShapeZ" in params_dict:
                params.psfVectorialShapeZ = Param.from_dict(params_dict["psfVectorialShapeZ"])
            if "psfVectorialShapeY" in params_dict:
                params.psfVectorialShapeY = Param.from_dict(params_dict["psfVectorialShapeY"])
            if "psfVectorialShapeX" in params_dict:
                params.psfVectorialShapeX = Param.from_dict(params_dict["psfVectorialShapeX"])
            params.blur = params.blurRadius
            params.noise = params.noiseMean
            params.distance = params.distanceFalloff
            params.min_angle_change = params.minAngleChange
            params.max_angle_change = params.maxAngleChange
            return params

        def to_dict(self):
            self.sync_legacy_output_fields()
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "generateCenterlineLabel": self.generateCenterlineLabel.to_dict(),
                "generateFiberImage": self.generateFiberImage.to_dict(),
                "centerlineOutputType": self.centerlineOutputType.to_dict(),
                "renderMode": self.renderMode.to_dict(),
                "centerlineMaskWidthPx": self.centerlineMaskWidthPx.to_dict(),
                "maskOutputMode": self.maskOutputMode.to_dict(),
                "alignment3D": self.alignment3D.to_dict(),
                "meanDirection": self.meanDirection.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageDepth": self.imageDepth.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "intensity": self.intensity.to_dict(),
                "curvature": self.curvature.to_dict(),
                "branchingProbability": self.branchingProbability.to_dict(),
                "scale": self.scale.to_dict(),
                "downSample": self.downSample.to_dict(),
                "blurRadius": self.blurRadius.to_dict(),
                "noiseMean": self.noiseMean.to_dict(),
                "noiseModel": self.noiseModel.to_dict(),
                "noiseStdDev": self.noiseStdDev.to_dict(),
                "saltPepperProb": self.saltPepperProb.to_dict(),
                "distanceFalloff": self.distanceFalloff.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict(),
                "minAngleChange": self.minAngleChange.to_dict(),
                "maxAngleChange": self.maxAngleChange.to_dict(),
                "psfEnabled": self.psfEnabled.to_dict(),
                "psfType": self.psfType.to_dict(),
                "psfGaussianNA": self.psfGaussianNA.to_dict(),
                "psfGaussianWavelength": self.psfGaussianWavelength.to_dict(),
                "psfPixelSizeZ": self.psfPixelSizeZ.to_dict(),
                "psfPixelSizeY": self.psfPixelSizeY.to_dict(),
                "psfPixelSizeX": self.psfPixelSizeX.to_dict(),
                "psfVectorialNA": self.psfVectorialNA.to_dict(),
                "psfVectorialMediumRI": self.psfVectorialMediumRI.to_dict(),
                "psfVectorialSampleRI": self.psfVectorialSampleRI.to_dict(),
                "psfVectorialWavelength": self.psfVectorialWavelength.to_dict(),
                "psfVectorialPolarization": self.psfVectorialPolarization.to_dict(),
                "psfVectorialVolumeZ": self.psfVectorialVolumeZ.to_dict(),
                "psfVectorialVolumeY": self.psfVectorialVolumeY.to_dict(),
                "psfVectorialVolumeX": self.psfVectorialVolumeX.to_dict(),
                "psfVectorialShapeZ": self.psfVectorialShapeZ.to_dict(),
                "psfVectorialShapeY": self.psfVectorialShapeY.to_dict(),
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict()
            }

        def set_names(self):
            super().set_names()
            self.imageDepth.set_name("image depth")
            self.curvature.set_name("curvature")
            self.branchingProbability.set_name("branching probability")
            self.meanDirection.set_name("mean direction")
            self.blurRadius.set_name("blur radius")
            self.noiseMean.set_name("noise mean")
            self.distanceFalloff.set_name("distance falloff")
            self.alignment3D.set_name("alignment")
            self.minAngleChange.set_name("min angle change")
            self.maxAngleChange.set_name("max angle change")

        def set_hints(self):
            super().set_hints()
            self.imageDepth.set_hint("The depth of the saved volume in pixels")
            self.curvature.set_hint("The curvature of fibers in 3D")
            self.branchingProbability.set_hint("The probability of fibers branching")
            self.meanDirection.set_hint("The average fiber direction as a 3D vector")
            self.blurRadius.set_hint("Check to enable Gaussian blurring; value is the radius of the blur in pixels")
            self.noiseMean.set_hint("Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)")
            self.distanceFalloff.set_hint("Check to apply a distance filter; value controls the sharpness of the intensity falloff")
            self.alignment3D.set_hint("A value between 0 and 1 indicating how close fibers are to the mean direction on average")
            self.minAngleChange.set_hint("Minimum angle change between segments in degrees")
            self.maxAngleChange.set_hint("Maximum angle change between segments in degrees")

        def verify(self):
            super().verify()
            self.imageDepth.verify(0, Param.greater)
            self.curvature.verify(0.0, Param.greater_eq)
            self.branchingProbability.verify(0.0, Param.greater_eq)
            self.branchingProbability.verify(1.0, Param.less_eq)
            self.meanDirection.verify(0.0, Param.greater_eq)
            self.meanDirection.verify(1.0, Param.less_eq)
            self.blurRadius.verify(0.0, Param.greater_eq)
            self.noiseMean.verify(0.0, Param.greater_eq)
            self.distanceFalloff.verify(0.0, Param.greater_eq)
            self.minAngleChange.verify(0.0, Param.greater_eq)
            self.minAngleChange.verify(180.0, Param.less_eq)
            self.maxAngleChange.verify(0.0, Param.greater_eq)
            self.maxAngleChange.verify(180.0, Param.less_eq)

    def __init__(self, params):
        super().__init__(params)
        self.image = np.zeros((params.imageDepth.get_value(), params.imageHeight.get_value(), params.imageWidth.get_value()), dtype=np.uint8)
        self.topology_links = []
        self.validation_metrics = {}
        self._cached_fiber_volume_3d = None
        self._cached_centerline_volume_3d = None
        self._cached_final_output_3d = None
        self._has_full_validation_metrics = False
        self.validation_metrics = {}

    def to_dict(self):
        return {
            "params": self.params.to_dict(),
            "fibers": [fiber.to_dict() for fiber in self.fibers],
            "joint_points": [{"x": point.x, "y": point.y, "z": point.z} for point in self.joint_points],
            "topology_links": self.topology_links,
            "validation_metrics": self.validation_metrics,
            "performance_timings": dict(self.performance_timings),
            "generation_metadata": dict(self.generation_metadata),
        }

    @staticmethod
    def from_dict(fiber_image_dict):
        params = FiberImage3D.Params.from_dict(fiber_image_dict["params"])
        fiber_image = FiberImage3D(params)
        fiber_image.fibers = [Fiber.from_dict(fiber_dict) for fiber_dict in fiber_image_dict["fibers"]]
        fiber_image.joint_points = [
            Vector(point.get("x", 0.0), point.get("y", 0.0), point.get("z", 0.0))
            for point in fiber_image_dict.get("joint_points", [])
        ]
        fiber_image.topology_links = list(fiber_image_dict.get("topology_links", []))
        fiber_image.validation_metrics = dict(fiber_image_dict.get("validation_metrics", {}))
        fiber_image.performance_timings = dict(fiber_image_dict.get("performance_timings", {}))
        fiber_image.generation_metadata = dict(fiber_image_dict.get("generation_metadata", {}))
        fiber_image.joints_dirty = False
        fiber_image.validation_dirty = not bool(fiber_image.validation_metrics)
        fiber_image._has_full_validation_metrics = bool(fiber_image.validation_metrics)
        return fiber_image

    def invalidate_render_cache(self):
        super().invalidate_render_cache()
        self._cached_fiber_volume_3d = None
        self._cached_centerline_volume_3d = None
        self._cached_final_output_3d = None
        self._has_full_validation_metrics = False

    @staticmethod
    def _closest_point_on_segment_3d(point, start, end):
        return closest_point_on_segment_3d(point, start, end)

    @staticmethod
    def _segment_segment_distance_3d(p0, p1, q0, q1):
        return segment_segment_distance_3d(p0, p1, q0, q1)

    def _add_joint_point_unique_3d(self, point):
        # Kept as a compatibility no-op wrapper; topology logic now owns uniqueness.
        if point not in self.joint_points:
            self.joint_points.append(point)

    def _attach_endpoint_to_segment_3d(self, fiber, endpoint_index, joint_point, segment_start, segment_end):
        # Topology attachment lives in generation.topology_3d.apply_topology_3d().
        raise NotImplementedError("Endpoint attachment is handled by generation.topology_3d")

    def apply_topology_3d(self, abort_check=None):
        apply_topology_3d(self, abort_check=abort_check)

    def count_joints(self, abort_check=None):
        if self.topology_links:
            return list(self.joint_points)
        return []

    @staticmethod
    def _count_graph_components(node_count, edge_pairs):
        return count_graph_components(node_count, edge_pairs)

    def build_geometric_contact_edges_3d(self, contact_radius=None, abort_check=None):
        return build_geometric_contact_edges_3d(self, contact_radius=contact_radius, abort_check=abort_check)

    def calculate_validation_metrics_3d(
        self,
        fiber_volume=None,
        centerline_volume=None,
        abort_check=None,
        include_raster_metrics=True,
        include_contact_metrics=True,
    ):
        start_time = time.perf_counter()
        if (
            include_raster_metrics
            and include_contact_metrics
            and not self.validation_dirty
            and self._has_full_validation_metrics
            and self.validation_metrics
        ):
            return self.validation_metrics
        path_lengths = []
        straightness_values = []
        widths = []
        turn_angles = []
        segment_dirs = []

        for fiber_index, fiber in enumerate(self.fibers):
            if fiber_index % 4 == 0:
                _raise_if_aborted(abort_check)
            if len(fiber.points) < 2:
                continue
            path_len = 0.0
            local_dirs = []
            for seg_idx in range(len(fiber.points) - 1):
                if seg_idx % 32 == 0:
                    _raise_if_aborted(abort_check)
                delta = fiber.points[seg_idx + 1].subtract(fiber.points[seg_idx])
                seg_len = delta.length()
                if seg_len <= 1e-8:
                    continue
                path_len += seg_len
                local_dirs.append(delta.normalize())
                segment_dirs.append(delta.normalize())
                if seg_idx < len(fiber.widths):
                    widths.append(fiber.widths[seg_idx])
            chord = fiber.points[-1].subtract(fiber.points[0]).length()
            if path_len > 0:
                path_lengths.append(path_len)
                straightness_values.append(chord / path_len)
            for seg_a, seg_b in zip(local_dirs, local_dirs[1:], strict=False):
                dot = float(np.clip(seg_a.dot_product(seg_b), -1.0, 1.0))
                turn_angles.append(float(np.degrees(np.arccos(dot))))

        mean_direction = Vector(*self.params.meanDirection.get_value())
        if mean_direction.is_zero():
            mean_direction = Vector(0.0, 0.0, 1.0)
        mean_direction = mean_direction.normalize()
        alignment_scores = [abs(seg.dot_product(mean_direction)) for seg in segment_dirs] if segment_dirs else []

        fiber_voxels = np.nan
        centerline_voxels = np.nan
        centerline_components = np.nan
        if include_raster_metrics:
            if fiber_volume is None:
                fiber_volume = self.render_fiber_volume_3d(abort_check=abort_check)
            if centerline_volume is None:
                centerline_volume = self.render_centerline_volume_3d(abort_check=abort_check)

            _raise_if_aborted(abort_check)
            fiber_voxels = int((fiber_volume > 0).sum())
            centerline_voxels = int((centerline_volume > 0).sum())
            _, centerline_components = label(centerline_volume > 0)
        topology_edge_pairs = [
            (int(link["fiber_id"]), int(link["connected_fiber_id"]))
            for link in self.topology_links
            if "fiber_id" in link and "connected_fiber_id" in link
        ]
        geometric_contact_edges = (
            self.build_geometric_contact_edges_3d(abort_check=abort_check)
            if include_contact_metrics
            else []
        )

        metrics = {
            "fiber_count": int(len(self.fibers)),
            "topology_link_count": int(len(self.topology_links)),
            "topology_graph_component_count": int(self._count_graph_components(len(self.fibers), topology_edge_pairs)),
            "geometric_contact_edge_count": int(len(geometric_contact_edges)) if include_contact_metrics else np.nan,
            "geometric_contact_component_count": int(self._count_graph_components(len(self.fibers), geometric_contact_edges)) if include_contact_metrics else np.nan,
            "joint_count_3d": int(len(self.joint_points)),
            "raster_centerline_component_count": int(centerline_components) if include_raster_metrics else np.nan,
            "fiber_voxel_count": fiber_voxels,
            "centerline_voxel_count": centerline_voxels,
            "fiber_to_centerline_voxel_ratio": float(fiber_voxels / max(centerline_voxels, 1)) if include_raster_metrics else np.nan,
            "mean_path_length": float(np.mean(path_lengths)) if path_lengths else 0.0,
            "std_path_length": float(np.std(path_lengths)) if path_lengths else 0.0,
            "mean_straightness": float(np.mean(straightness_values)) if straightness_values else 0.0,
            "std_straightness": float(np.std(straightness_values)) if straightness_values else 0.0,
            "mean_segment_width": float(np.mean(widths)) if widths else 0.0,
            "std_segment_width": float(np.std(widths)) if widths else 0.0,
            "mean_turn_angle_deg": float(np.mean(turn_angles)) if turn_angles else 0.0,
            "std_turn_angle_deg": float(np.std(turn_angles)) if turn_angles else 0.0,
            "realized_alignment_to_mean_direction": float(np.mean(alignment_scores)) if alignment_scores else 0.0,
        }
        if include_raster_metrics and include_contact_metrics:
            self.validation_metrics = metrics
            self.validation_dirty = False
            self._has_full_validation_metrics = True
            self.record_timing("validation_3d_seconds", time.perf_counter() - start_time)
        return metrics

    def bresenham_3d(x1, y1, z1, x2, y2, z2):
        raise NotImplementedError("Legacy voxel traversal helper removed; use rendering.raster_3d")

    @staticmethod
    def _line_voxels_3d(start, end):
        raise NotImplementedError("Legacy voxel traversal helper removed; use rendering.raster_3d")

    @staticmethod
    def get_rendered_tube_diameter_3d(width_value, min_diameter=1):
        from rendering.raster_3d import get_rendered_tube_diameter_3d
        return get_rendered_tube_diameter_3d(width_value, min_diameter=min_diameter)

    @staticmethod
    def get_rendered_tube_radius_3d(width_value, min_diameter=1):
        from rendering.raster_3d import get_rendered_tube_radius_3d
        return get_rendered_tube_radius_3d(width_value, min_diameter=min_diameter)

    @staticmethod
    def _sample_segment_points_3d(start, end, spacing=0.35):
        raise NotImplementedError("Legacy 3D sampling helper removed; use rendering.raster_3d")

    @staticmethod
    def _stamp_ball_3d(volume, point, radius, value, binary=False):
        raise NotImplementedError("Legacy 3D stamping helper removed; use rendering.raster_3d")

    @staticmethod
    def _downsample_supersampled_mask(mask, factor):
        raise NotImplementedError("Legacy 3D raster helper removed; use rendering.raster_3d")

    @staticmethod
    def _rasterize_segment_supersampled_3d(volume, start, end, radius, value, binary=False, factor=4):
        raise NotImplementedError("Legacy 3D raster helper removed; use rendering.raster_3d")

    @staticmethod
    def _rasterize_segment_3d(volume, start, end, radius, value, binary=False):
        raise NotImplementedError("Legacy 3D raster helper removed; use rendering.raster_3d")

    @staticmethod
    def render_fibers_to_volume(
        fibers,
        shape,
        default_intensity=255.0,
        binary=False,
        centerline_only=False,
        line_width_override=None,
        abort_check=None,
    ):
        return render_fibers_to_volume(
            fibers,
            shape,
            default_intensity=default_intensity,
            binary=binary,
            centerline_only=centerline_only,
            line_width_override=line_width_override,
            abort_check=abort_check,
        )

    def render_fiber_volume_3d(self, abort_check=None):
        if abort_check is None and self._cached_fiber_volume_3d is not None and not self.render_dirty:
            return self._cached_fiber_volume_3d.copy()
        shape = (
            self.params.imageDepth.get_value(),
            self.params.imageHeight.get_value(),
            self.params.imageWidth.get_value()
        )
        output = self.render_fibers_to_volume(self.fibers, shape, abort_check=abort_check)
        if abort_check is None:
            self._cached_fiber_volume_3d = output.copy()
            self.render_dirty = False
        return output

    def render_centerline_volume_3d(self, abort_check=None):
        if abort_check is None and self._cached_centerline_volume_3d is not None and not self.centerline_render_dirty:
            return self._cached_centerline_volume_3d.copy()
        shape = (
            self.params.imageDepth.get_value(),
            self.params.imageHeight.get_value(),
            self.params.imageWidth.get_value()
        )
        output = self.render_fibers_to_volume(
            self.fibers,
            shape,
            default_intensity=255.0,
            binary=True,
            centerline_only=True,
            line_width_override=self.get_mask_line_width(self.params),
            abort_check=abort_check,
        ).astype(np.float32)
        output = (output > 127).astype(np.uint8) * 255
        if abort_check is None:
            self._cached_centerline_volume_3d = output.copy()
            self.centerline_render_dirty = False
        return output

    def render_base_volume_3d(self, abort_check=None):
        return self.render_fiber_volume_3d(abort_check=abort_check)

    @staticmethod
    def find_start_3d(length, dimension, buffer):
        return FiberImage.find_start(length, dimension, buffer)

    def find_fiber_start_3d(self, length, direction):
        x_length = direction.normalize().x * length
        y_length = direction.normalize().y * length
        z_length = direction.normalize().z * length
        x = self.find_start_3d(x_length, self.params.imageWidth.get_value(), self.params.imageBuffer.get_value())
        y = self.find_start_3d(y_length, self.params.imageHeight.get_value(), self.params.imageBuffer.get_value())
        z = self.find_start_3d(z_length, self.params.imageDepth.get_value(), self.params.imageBuffer.get_value())
        return Vector(x, y, z)

    def generate_directions_3d(self):
        mean_direction = Vector(*self.params.meanDirection.get_value())
        alignment = self.params.alignment3D.get_value()
        return [
            RngUtility3D.sample_oriented_direction(mean_direction, alignment).normalize()
            for _ in range(self.params.nFibers.get_value())
        ]

    def generate_fibers_3d(self, abort_check=None):
        start_time = time.perf_counter()
        directions = self.generate_directions_3d()

        for direction_index, direction in enumerate(directions):
            if direction_index % 4 == 0:
                _raise_if_aborted(abort_check)
            fiber_params = Fiber.Params()

            fiber_params.segment_length = self.params.segmentLength.get_value()
            fiber_params.width_change = self.params.widthChange.get_value()
            fiber_params.min_angle_change = self.params.minAngleChange.get_value()
            fiber_params.max_angle_change = self.params.maxAngleChange.get_value()
            fiber_params.curvature_scale = self.params.curvature.get_value()

            fiber_params.n_segments = max(1, round(self.params.length.sample() / self.params.segmentLength.get_value()))
            fiber_params.straightness = self.params.straightness.sample()
            fiber_params.start_width = self.params.width.sample()

            end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
            fiber_params.start = self.find_fiber_start_3d(end_distance, direction)
            fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

            fiber = Fiber(fiber_params)
            fiber.generate_3d(abort_check=abort_check)
            if hasattr(self.params, "intensity"):
                fiber.intensity = self.params.intensity.sample()
            self.fibers.append(fiber)
        self.mark_geometry_dirty()
        self.validation_metrics = {}
        self.record_timing("generate_fibers_3d_seconds", time.perf_counter() - start_time)

    def smooth_3d(self, abort_check=None):
        start_time = time.perf_counter()
        for fiber_index, fiber in enumerate(self.fibers):
            if fiber_index % 4 == 0:
                _raise_if_aborted(abort_check)
            if self.params.bubble.use:
                fiber.bubble_smooth_3d(self.params.bubble.get_value(), abort_check=abort_check)
            if self.params.swap.use:
                fiber.swap_smooth_3d(self.params.swap.get_value(), abort_check=abort_check)
            if self.params.spline.use:
                fiber.spline_smooth(self.params.spline.get_value(), abort_check=abort_check)
        self.apply_topology_3d(abort_check=abort_check)
        for fiber in self.fibers:
            fiber.calculate_orientations()
        self.joints_dirty = False
        self.validation_dirty = True
        self.invalidate_render_cache()
        self.validation_metrics = {}
        self.record_timing("smooth_3d_seconds", time.perf_counter() - start_time)

    def add_noise_3d(self):
        model = str(self.params.noiseModel.get_value()).lower()
        if model == "no noise":
            return
        noise_params = deepcopy(self.params)
        noise_params.noise = noise_params.noiseMean
        self.image = self.add_noise_to_array(self.image.astype(np.float32), noise_params)

    def draw_scale_bar_3d(self):
        self.image = draw_scale_bar_on_volume(self.image, self.params)

    @classmethod
    def apply_postprocessing_3d(cls, volume, params, abort_check=None):
        output = np.asarray(volume, dtype=np.float32).copy()
        mask_mode = cls.is_mask_mode(params)
        binary_mask = mask_mode and cls.is_binary_mask_output(params)

        if binary_mask:
            return (output > 127).astype(np.uint8) * 255

        if params.distanceFalloff.use:
            output = ImageUtility3D.distance_function_3d(
                output.astype(np.uint8),
                params.distanceFalloff.get_value(),
                abort_check=abort_check,
            ).astype(np.float32)

        if not mask_mode and getattr(params, "psfEnabled", None) and params.psfEnabled.use:
            manager = PSFManager(params)
            psf_result = manager.apply(output, volume=True, abort_check=abort_check)
            if psf_result is not None:
                output = psf_result.astype(np.float32)

        if (not mask_mode or not binary_mask) and cls.should_apply_noise(params, is_3d=True):
            noise_params = deepcopy(params)
            noise_params.noise = noise_params.noiseMean
            output = cls.add_noise_to_array(output, noise_params).astype(np.float32)

        if params.blurRadius.use:
            _raise_if_aborted(abort_check)
            output = ImageUtility3D.gaussian_blur_3d(output, params.blurRadius.get_value()).astype(np.float32)

        if params.cap.use:
            output = ImageUtility3D.cap_3d(output, params.cap.get_value()).astype(np.float32)

        if params.normalize.use:
            max_value = np.max(output)
            if max_value > 0:
                output = output / max_value * float(params.normalize.get_value())

        output = np.clip(output, 0, 255).astype(np.uint8)

        if not mask_mode and params.scale.use:
            temp = FiberImage3D(params)
            temp.image = output.copy()
            temp.draw_scale_bar_3d()
            output = temp.image

        if params.downSample.use:
            step = max(1, int(round(1 / params.downSample.get_value())))
            output = output[::step, ::step, ::step]

        return output

    def apply_effects_3d(self, abort_check=None):
        self.image = self.apply_postprocessing_3d(self.image, self.params, abort_check=abort_check)
        self._cached_final_output_3d = np.array(self.image, copy=True)
        self.render_dirty = False

    def get_image(self):
        if self._cached_final_output_3d is None or self.render_dirty:
            start_time = time.perf_counter()
            base_volume = self.render_base_volume_3d()
            self._cached_final_output_3d = self.apply_postprocessing_3d(base_volume, self.params)
            self.image = np.array(self._cached_final_output_3d, copy=True)
            self.render_dirty = False
            self.record_timing("render_postprocess_3d_seconds", time.perf_counter() - start_time)
        return self.image

    # 3D-specific CSV export: extend parent with depth/volume metrics
    def to_csv_data(self):
        network_df, summary_df, segments_df, points_df, joints_df, params_df = super().to_csv_data()
        joints_df = pd.DataFrame([
            {
                "Joint ID": idx,
                "X": joint.x,
                "Y": joint.y,
                "Z": joint.z,
            }
            for idx, joint in enumerate(self.joint_points)
        ])
        try:
            depth = int(self.params.imageDepth.get_value()) if hasattr(self.params, 'imageDepth') else 0
        except Exception:
            depth = 0
        if not network_df.empty:
            try:
                network_df.loc[0, 'Image Depth (px)'] = depth
                width = float(network_df.loc[0, 'Image Width (px)']) if 'Image Width (px)' in network_df.columns else 0.0
                height = float(network_df.loc[0, 'Image Height (px)']) if 'Image Height (px)' in network_df.columns else 0.0
                volume = width * height * depth
                network_df.loc[0, 'Image Volume (px^3)'] = volume
                total_len = float(network_df.loc[0, 'Total Fiber Length (px)']) if 'Total Fiber Length (px)' in network_df.columns else 0.0
                network_df.loc[0, 'Length Density (px/px^3)'] = (total_len / volume) if volume > 0 else 0.0
                metrics = self.calculate_validation_metrics_3d() if self.validation_dirty or not self.validation_metrics else self.validation_metrics
                network_df.loc[0, 'Topology Link Count'] = metrics.get('topology_link_count', 0)
                network_df.loc[0, 'Topology Graph Components'] = metrics.get('topology_graph_component_count', 0)
                network_df.loc[0, 'Geometric Contact Edge Count'] = metrics.get('geometric_contact_edge_count', 0)
                network_df.loc[0, 'Geometric Contact Components'] = metrics.get('geometric_contact_component_count', 0)
                network_df.loc[0, '3D Joint Count'] = metrics.get('joint_count_3d', 0)
                network_df.loc[0, 'Raster Centerline Components'] = metrics.get('raster_centerline_component_count', 0)
                network_df.loc[0, 'Fiber Voxel Count'] = metrics.get('fiber_voxel_count', 0)
                network_df.loc[0, 'Centerline Voxel Count'] = metrics.get('centerline_voxel_count', 0)
                network_df.loc[0, 'Fiber/Centerline Voxel Ratio'] = metrics.get('fiber_to_centerline_voxel_ratio', 0.0)
                network_df.loc[0, 'Mean Turn Angle (deg)'] = metrics.get('mean_turn_angle_deg', 0.0)
                network_df.loc[0, 'Std Turn Angle (deg)'] = metrics.get('std_turn_angle_deg', 0.0)
                network_df.loc[0, 'Realized Alignment To Mean Dir'] = metrics.get('realized_alignment_to_mean_direction', 0.0)
            except Exception:
                pass
        return network_df, summary_df, segments_df, points_df, joints_df, params_df
