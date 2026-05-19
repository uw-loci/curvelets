
from __future__ import annotations

import math
import time
from copy import deepcopy

import numpy as np
import pandas as pd
from PIL import Image
from scipy.interpolate import splrep, splev
from scipy.ndimage import label

from core.abort import GenerationAborted, _raise_if_aborted
from core.distributions import Gaussian, PiecewiseLinear, Uniform, distribution_from_dict
from core.geometry import Circle, MiscUtility, MiscUtility3D, Vector
from core.params import Optional, Param
from core.rng import RngUtility, RngUtility3D
from generation.fiber import Fiber
from generation.sample_2d import FiberImage
from postprocess.pipeline_3d import ImageUtility3D
from postprocess.psf import PSFManager

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
                legacy_mask_binary = Param.from_dict(params_dict["maskBinary"])
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
        point_arr = point.to_array().astype(float)
        start_arr = start.to_array().astype(float)
        end_arr = end.to_array().astype(float)
        seg = end_arr - start_arr
        seg_len_sq = float(np.dot(seg, seg))
        if seg_len_sq <= 1e-8:
            closest = start_arr
            t = 0.0
        else:
            t = float(np.clip(np.dot(point_arr - start_arr, seg) / seg_len_sq, 0.0, 1.0))
            closest = start_arr + t * seg
        distance = float(np.linalg.norm(point_arr - closest))
        return Vector(*closest), t, distance

    @staticmethod
    def _segment_segment_distance_3d(p0, p1, q0, q1):
        p0 = p0.to_array().astype(float)
        p1 = p1.to_array().astype(float)
        q0 = q0.to_array().astype(float)
        q1 = q1.to_array().astype(float)

        u = p1 - p0
        v = q1 - q0
        w0 = p0 - q0
        a = float(np.dot(u, u))
        b = float(np.dot(u, v))
        c = float(np.dot(v, v))
        d = float(np.dot(u, w0))
        e = float(np.dot(v, w0))
        denom = a * c - b * b
        eps = 1e-8

        if a <= eps and c <= eps:
            return float(np.linalg.norm(p0 - q0))
        if a <= eps:
            s = 0.0
            t = float(np.clip(e / c if c > eps else 0.0, 0.0, 1.0))
        elif c <= eps:
            t = 0.0
            s = float(np.clip(-d / a if a > eps else 0.0, 0.0, 1.0))
        else:
            if denom <= eps:
                s = 0.0
            else:
                s = float(np.clip((b * e - c * d) / denom, 0.0, 1.0))
            t = (b * s + e) / c
            if t < 0.0:
                t = 0.0
                s = float(np.clip(-d / a, 0.0, 1.0))
            elif t > 1.0:
                t = 1.0
                s = float(np.clip((b - d) / a, 0.0, 1.0))

        closest_p = p0 + s * u
        closest_q = q0 + t * v
        return float(np.linalg.norm(closest_p - closest_q))

    def _add_joint_point_unique_3d(self, point):
        key = tuple(int(round(coord * 4.0)) for coord in (point.x, point.y, point.z))
        if not hasattr(self, "_joint_point_keys_3d"):
            self._joint_point_keys_3d = set()
        if key not in self._joint_point_keys_3d:
            self._joint_point_keys_3d.add(key)
            self.joint_points.append(point)

    def _attach_endpoint_to_segment_3d(self, fiber, endpoint_index, joint_point, segment_start, segment_end):
        if len(fiber.points) < 2:
            return

        tangent = segment_end.subtract(segment_start)
        if tangent.is_zero():
            return
        tangent = tangent.normalize()

        if endpoint_index == 0:
            neighbor_index = 1
            old_direction = fiber.points[neighbor_index].subtract(fiber.points[0])
        else:
            neighbor_index = len(fiber.points) - 2
            old_direction = fiber.points[-1].subtract(fiber.points[neighbor_index])

        if old_direction.is_zero():
            old_direction = tangent
        else:
            old_direction = old_direction.normalize()

        if tangent.dot_product(old_direction) < 0:
            tangent = tangent.scalar_multiply(-1.0)

        blended_direction = tangent.scalar_multiply(0.6).add(old_direction.scalar_multiply(0.4))
        if blended_direction.is_zero():
            blended_direction = tangent
        else:
            blended_direction = blended_direction.normalize()

        segment_length = fiber.points[neighbor_index].subtract(fiber.points[endpoint_index]).length()
        segment_length = max(0.5, segment_length)

        fiber.points[endpoint_index] = Vector(joint_point.x, joint_point.y, joint_point.z)
        if endpoint_index == 0:
            fiber.points[neighbor_index] = joint_point.add(blended_direction.scalar_multiply(segment_length))
        else:
            fiber.points[neighbor_index] = joint_point.subtract(blended_direction.scalar_multiply(segment_length))

    def apply_topology_3d(self, abort_check=None):
        self.topology_links = []
        self.joint_points = []
        self._joint_point_keys_3d = set()

        branch_probability = float(np.clip(self.params.branchingProbability.get_value(), 0.0, 1.0))
        if branch_probability <= 0.0 or len(self.fibers) < 2:
            return

        mean_width = float(self.params.width.mean.get_value()) if hasattr(self.params.width, "mean") else 0.0
        capture_radius = max(
            2.5,
            1.25 * float(self.params.segmentLength.get_value()),
            1.25 * mean_width,
        )
        target_links = max(0, int(round(branch_probability * len(self.fibers))))
        used_endpoints = set()
        linked_pairs = set()

        for _ in range(target_links):
            _raise_if_aborted(abort_check)
            best_global_candidate = None

            for fiber_idx, fiber in enumerate(self.fibers):
                if fiber_idx % 4 == 0:
                    _raise_if_aborted(abort_check)
                if len(fiber.points) < 2:
                    continue
                for endpoint_index in (0, len(fiber.points) - 1):
                    endpoint_key = (fiber_idx, 0 if endpoint_index == 0 else 1)
                    if endpoint_key in used_endpoints:
                        continue

                    endpoint = fiber.points[endpoint_index]
                    for other_idx, other_fiber in enumerate(self.fibers):
                        if other_idx % 4 == 0:
                            _raise_if_aborted(abort_check)
                        if other_idx == fiber_idx or len(other_fiber.points) < 2:
                            continue
                        pair_key = tuple(sorted((fiber_idx, other_idx)))
                        if pair_key in linked_pairs:
                            continue

                        for seg_idx in range(len(other_fiber.points) - 1):
                            if seg_idx % 32 == 0:
                                _raise_if_aborted(abort_check)
                            seg_start = other_fiber.points[seg_idx]
                            seg_end = other_fiber.points[seg_idx + 1]
                            joint_point, t_value, distance = self._closest_point_on_segment_3d(endpoint, seg_start, seg_end)
                            if distance > capture_radius:
                                continue

                            interior_bonus = 0.35 if 0.1 < t_value < 0.9 else 0.0
                            endpoint_bonus = 0.1 if endpoint_index in (0, len(fiber.points) - 1) else 0.0
                            score = distance - interior_bonus - endpoint_bonus
                            if best_global_candidate is None or score < best_global_candidate[0]:
                                best_global_candidate = (
                                    score,
                                    fiber_idx,
                                    endpoint_index,
                                    other_idx,
                                    seg_idx,
                                    joint_point,
                                    seg_start,
                                    seg_end,
                                )

            if best_global_candidate is None:
                break

            _, fiber_idx, endpoint_index, other_idx, seg_idx, joint_point, seg_start, seg_end = best_global_candidate
            fiber = self.fibers[fiber_idx]
            self._attach_endpoint_to_segment_3d(fiber, endpoint_index, joint_point, seg_start, seg_end)
            fiber.has_joint = True
            self.fibers[other_idx].has_joint = True
            self._add_joint_point_unique_3d(joint_point)
            self.topology_links.append({
                "fiber_id": fiber_idx,
                "connected_fiber_id": other_idx,
                "segment_index": seg_idx,
                "x": joint_point.x,
                "y": joint_point.y,
                "z": joint_point.z,
            })
            used_endpoints.add((fiber_idx, 0 if endpoint_index == 0 else 1))
            linked_pairs.add(tuple(sorted((fiber_idx, other_idx))))

    def count_joints(self, abort_check=None):
        if self.topology_links:
            return list(self.joint_points)
        return []

    @staticmethod
    def _count_graph_components(node_count, edge_pairs):
        if node_count <= 0:
            return 0
        adjacency = {i: set() for i in range(node_count)}
        for left, right in edge_pairs:
            adjacency[left].add(right)
            adjacency[right].add(left)
        visited = set()
        components = 0
        for node in range(node_count):
            if node in visited:
                continue
            components += 1
            stack = [node]
            visited.add(node)
            while stack:
                current = stack.pop()
                for neighbor in adjacency[current]:
                    if neighbor not in visited:
                        visited.add(neighbor)
                        stack.append(neighbor)
        return components

    def build_geometric_contact_edges_3d(self, contact_radius=None, abort_check=None):
        if contact_radius is None:
            contact_radius = max(
                1.0,
                0.5 * float(self.params.centerlineMaskWidthPx.get_value()) + 0.75,
                0.2 * float(self.params.segmentLength.get_value()),
            )

        edge_pairs = set()
        for left_idx, left_fiber in enumerate(self.fibers):
            if left_idx % 4 == 0:
                _raise_if_aborted(abort_check)
            if len(left_fiber.points) < 2:
                continue
            for right_idx in range(left_idx + 1, len(self.fibers)):
                if right_idx % 4 == 0:
                    _raise_if_aborted(abort_check)
                right_fiber = self.fibers[right_idx]
                if len(right_fiber.points) < 2:
                    continue

                close_enough = False
                for left_seg_idx in range(len(left_fiber.points) - 1):
                    if left_seg_idx % 32 == 0:
                        _raise_if_aborted(abort_check)
                    p0 = left_fiber.points[left_seg_idx]
                    p1 = left_fiber.points[left_seg_idx + 1]
                    for right_seg_idx in range(len(right_fiber.points) - 1):
                        if right_seg_idx % 32 == 0:
                            _raise_if_aborted(abort_check)
                        q0 = right_fiber.points[right_seg_idx]
                        q1 = right_fiber.points[right_seg_idx + 1]
                        if self._segment_segment_distance_3d(p0, p1, q0, q1) <= contact_radius:
                            edge_pairs.add((left_idx, right_idx))
                            close_enough = True
                            break
                    if close_enough:
                        break
        return sorted(edge_pairs)

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
            for seg_a, seg_b in zip(local_dirs, local_dirs[1:]):
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
        points = []
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        dz = abs(z2 - z1)
        xs = 1 if x2 > x1 else -1
        ys = 1 if y2 > y1 else -1
        zs = 1 if z2 > z1 else -1

        # Driving axis is X-axis
        if dx >= dy and dx >= dz:
            p1 = 2 * dy - dx
            p2 = 2 * dz - dx
            while x1 != x2:
                x1 += xs
                if p1 >= 0:
                    y1 += ys
                    p1 -= 2 * dx
                if p2 >= 0:
                    z1 += zs
                    p2 -= 2 * dx
                p1 += 2 * dy
                p2 += 2 * dz
                points.append((x1, y1, z1))

        # Driving axis is Y-axis
        elif dy >= dx and dy >= dz:
            p1 = 2 * dx - dy
            p2 = 2 * dz - dy
            while y1 != y2:
                y1 += ys
                if p1 >= 0:
                    x1 += xs
                    p1 -= 2 * dy
                if p2 >= 0:
                    z1 += zs
                    p2 -= 2 * dy
                p1 += 2 * dx
                p2 += 2 * dz
                points.append((x1, y1, z1))

        # Driving axis is Z-axis
        else:
            p1 = 2 * dy - dz
            p2 = 2 * dx - dz
            while z1 != z2:
                z1 += zs
                if p1 >= 0:
                    y1 += ys
                    p1 -= 2 * dz
                if p2 >= 0:
                    x1 += xs
                    p2 -= 2 * dz
                p1 += 2 * dy
                p2 += 2 * dx
                points.append((x1, y1, z1))

        return points

    @staticmethod
    def _line_voxels_3d(start, end):
        x1, y1, z1 = [int(round(v)) for v in start]
        x2, y2, z2 = [int(round(v)) for v in end]
        points = [(x1, y1, z1)]
        points.extend(FiberImage3D.bresenham_3d(x1, y1, z1, x2, y2, z2))
        return points

    @staticmethod
    def get_rendered_tube_diameter_3d(width_value, min_diameter=1):
        try:
            diameter = float(width_value)
        except (TypeError, ValueError):
            diameter = float(min_diameter)
        return max(min_diameter, diameter)

    @staticmethod
    def get_rendered_tube_radius_3d(width_value, min_diameter=1):
        diameter = FiberImage3D.get_rendered_tube_diameter_3d(width_value, min_diameter=min_diameter)
        if diameter <= 1:
            return 0.0
        return max(0.0, (float(diameter) - 1.0) / 2.0)

    @staticmethod
    def _sample_segment_points_3d(start, end, spacing=0.35):
        start = np.asarray(start, dtype=np.float32)
        end = np.asarray(end, dtype=np.float32)
        seg = end - start
        seg_length = float(np.linalg.norm(seg))
        if seg_length <= 1e-8:
            return start[np.newaxis, :]
        n_steps = max(1, int(math.ceil(seg_length / max(spacing, 1e-3))))
        t = np.linspace(0.0, 1.0, n_steps + 1, dtype=np.float32)
        return start[np.newaxis, :] + t[:, np.newaxis] * seg[np.newaxis, :]

    @staticmethod
    def _stamp_ball_3d(volume, point, radius, value, binary=False):
        z_dim, y_dim, x_dim = volume.shape
        x0, y0, z0 = point
        radius = max(0.0, float(radius))

        min_x = max(0, int(math.floor(x0 - radius - 1)))
        max_x = min(x_dim - 1, int(math.ceil(x0 + radius + 1)))
        min_y = max(0, int(math.floor(y0 - radius - 1)))
        max_y = min(y_dim - 1, int(math.ceil(y0 + radius + 1)))
        min_z = max(0, int(math.floor(z0 - radius - 1)))
        max_z = min(z_dim - 1, int(math.ceil(z0 + radius + 1)))
        if min_x > max_x or min_y > max_y or min_z > max_z:
            return

        z_coords, y_coords, x_coords = np.indices(
            (max_z - min_z + 1, max_y - min_y + 1, max_x - min_x + 1),
            dtype=np.float32
        )
        x_coords += min_x
        y_coords += min_y
        z_coords += min_z

        dist_sq = (x_coords - x0) ** 2 + (y_coords - y0) ** 2 + (z_coords - z0) ** 2
        mask = dist_sq <= (radius ** 2)
        if not np.any(mask):
            return

        region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
        if binary:
            region[mask] = 255.0
        else:
            region[mask] += value

    @staticmethod
    def _downsample_supersampled_mask(mask, factor):
        z_size, y_size, x_size = mask.shape
        reshaped = mask.reshape(
            z_size // factor, factor,
            y_size // factor, factor,
            x_size // factor, factor,
        )
        return reshaped.max(axis=(1, 3, 5))

    @staticmethod
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

        fine_z_coords, fine_y_coords, fine_x_coords = np.indices(
            (fine_z, fine_y, fine_x),
            dtype=np.float32,
        )
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

        coarse_mask = FiberImage3D._downsample_supersampled_mask(fine_mask, factor)
        if not np.any(coarse_mask):
            return

        region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
        if binary:
            region[coarse_mask] = 255.0
        else:
            region[coarse_mask] += value

    @staticmethod
    def _rasterize_segment_3d(volume, start, end, radius, value, binary=False):
        z_dim, y_dim, x_dim = volume.shape
        x0, y0, z0 = start
        x1, y1, z1 = end
        radius = max(0.0, float(radius))

        # Thin 3D structures need dense subvoxel sampling; pure center-distance
        # rasterization under-resolves oblique segments and creates dotted output.
        if radius < 0.75:
            FiberImage3D._rasterize_segment_supersampled_3d(
                volume,
                start,
                end,
                radius,
                value,
                binary=binary,
                factor=4,
            )
            return

        min_x = max(0, int(math.floor(min(x0, x1) - radius - 1)))
        max_x = min(x_dim - 1, int(math.ceil(max(x0, x1) + radius + 1)))
        min_y = max(0, int(math.floor(min(y0, y1) - radius - 1)))
        max_y = min(y_dim - 1, int(math.ceil(max(y0, y1) + radius + 1)))
        min_z = max(0, int(math.floor(min(z0, z1) - radius - 1)))
        max_z = min(z_dim - 1, int(math.ceil(max(z0, z1) + radius + 1)))
        if min_x > max_x or min_y > max_y or min_z > max_z:
            return

        z_coords, y_coords, x_coords = np.indices(
            (max_z - min_z + 1, max_y - min_y + 1, max_x - min_x + 1),
            dtype=np.float32
        )
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
                    radius = FiberImage3D.get_rendered_tube_radius_3d(line_width_override, min_diameter=1)
                else:
                    radius = 0.0 if centerline_only else FiberImage3D.get_rendered_tube_radius_3d(segment.width, min_diameter=1)
                FiberImage3D._rasterize_segment_3d(volume, start, end, radius, intensity, binary=binary)
        return np.clip(volume, 0, 255).astype(np.uint8)

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
        if not self.params.scale.use:
            return
        pixels_per_micron = float(self.params.scale.get_value())
        if pixels_per_micron <= 0:
            return
        microns = 10.0
        length_px = max(1, int(round(microns * pixels_per_micron)))
        z = max(0, self.image.shape[0] - 2)
        y = max(1, self.image.shape[1] - 8)
        x_start = 4
        x_end = min(self.image.shape[2] - 1, x_start + length_px)
        self.image[z, y:y + 2, x_start:x_end] = 255

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
