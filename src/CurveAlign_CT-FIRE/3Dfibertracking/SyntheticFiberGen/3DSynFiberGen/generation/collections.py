
from __future__ import annotations

from copy import deepcopy
import time

import numpy as np

from core.abort import _raise_if_aborted
from core.distributions import distribution_from_dict
from core.params import Optional, Param
from core.rng import RngUtility
from generation.batch_parallel import generate_parallel_batch, should_use_parallel_batch
from generation.sample_2d import FiberImage
from generation.sample_3d import FiberImage3D

class ImageCollection:
    class Params(FiberImage.Params):
        def __init__(self):
            super().__init__()
            self.nImages = Param(value=1, name="number of images", hint="The number of images to generate")
            self.seed = Optional(value=1, name="seed", hint="Check to fix the random seed; value is the seed", use=True)

        @staticmethod
        def from_dict(params_dict):
            params = ImageCollection.Params()
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
            params.alignment = Param.from_dict(params_dict["alignment"])
            params.meanAngle = Param.from_dict(params_dict["meanAngle"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
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
            params.scale = Optional.from_dict(params_dict["scale"])
            params.downSample = Optional.from_dict(params_dict["downSample"])
            params.blur = Optional.from_dict(params_dict["blur"])
            params.noise = Optional.from_dict(params_dict["noise"])
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            params.distance = Optional.from_dict(params_dict["distance"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
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
            params.nImages = Param.from_dict(params_dict["nImages"])
            params.seed = Optional.from_dict(params_dict["seed"])
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
                "alignment": self.alignment.to_dict(),
                "meanAngle": self.meanAngle.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "intensity": self.intensity.to_dict(),
                "scale": self.scale.to_dict(),
                "downSample": self.downSample.to_dict(),
                "blur": self.blur.to_dict(),
                "noise": self.noise.to_dict(),
                "noiseModel": self.noiseModel.to_dict(),
                "noiseStdDev": self.noiseStdDev.to_dict(),
                "saltPepperProb": self.saltPepperProb.to_dict(),
                "distance": self.distance.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict(),
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
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict(),
                "nImages": self.nImages.to_dict(),
                "seed": self.seed.to_dict()
            }

        def set_names(self):
            super().set_names()
            self.nImages.set_name("number of images")
            self.seed.set_name("seed")

        def set_hints(self):
            super().set_hints()
            self.nImages.set_hint("The number of images to generate")
            self.seed.set_hint("Check to fix the random seed; value is the seed")

        def verify(self):
            super().verify()
            self.nImages.verify(0, Param.greater)

    def __init__(self, params):
        params.verify()
        self.params = params
        self.image_stack: List[FiberImage] = []
        self.generation_timings = {}

    def _finalize_generation_timing(self, total_elapsed, stage_totals):
        summary = {"total_seconds": float(total_elapsed)}
        summary.update({key: float(value) for key, value in stage_totals.items()})
        self.generation_timings = summary

    def generate_images(self, abort_check=None):
        total_images = int(self.params.nImages.get_value())
        if should_use_parallel_batch(total_images):
            samples, timing_summary = generate_parallel_batch(self.params, is_3d_mode=False, abort_check=abort_check)
            self.image_stack = samples
            self.generation_timings = timing_summary
            return

        total_start = time.perf_counter()
        if self.params.seed.use:
            RngUtility.rng.seed(self.params.seed.value)
            np.random.seed(self.params.seed.value)

        self.image_stack.clear()
        stage_totals = {
            "generation_seconds": 0.0,
            "joint_count_seconds": 0.0,
            "smoothing_seconds": 0.0,
        }
        for i in range(total_images):
            _raise_if_aborted(abort_check)
            image = FiberImage(self.params)
            image.generate_fibers(abort_check=abort_check)
            stage_totals["generation_seconds"] += float(image.performance_timings.get("generate_fibers_2d_seconds", 0.0))
            image.smooth(abort_check=abort_check)
            stage_totals["smoothing_seconds"] += float(image.performance_timings.get("smooth_2d_seconds", 0.0))
            stage_totals["joint_count_seconds"] += float(image.performance_timings.get("joint_count_2d_seconds", 0.0))
            self.image_stack.append(image)
        self._finalize_generation_timing(time.perf_counter() - total_start, stage_totals)

    def is_empty(self):
        return not self.image_stack

    def get(self, i):
        return self.image_stack[i]

    def get_image(self, i):
        return self.get(i).get_image()

    def size(self):
        return len(self.image_stack)


class ImageCollection3D(ImageCollection):
    class Params(FiberImage3D.Params):
        def __init__(self):
            super().__init__()
            self.nImages = Param(value=1, name="number of images", hint="The number of images to generate")
            self.seed = Optional(value=1, name="seed", hint="Check to fix the random seed; value is the seed", use=True)
            self.minAngleChange = Param(value=15.0, name="min angle change", hint="Minimum angle change in degrees")
            self.maxAngleChange = Param(value=45.0, name="max angle change", hint="Maximum angle change in degrees")
            self.min_angle_change = self.minAngleChange
            self.max_angle_change = self.maxAngleChange

        @staticmethod
        def from_dict(params_dict):
            params = ImageCollection3D.Params()
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
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            params.distanceFalloff = Optional.from_dict(params_dict["distanceFalloff"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            params.nImages = Param.from_dict(params_dict["nImages"])
            params.seed = Optional.from_dict(params_dict["seed"])
            params.minAngleChange = Param.from_dict(params_dict["minAngleChange"])
            params.maxAngleChange = Param.from_dict(params_dict["maxAngleChange"])
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
                "nImages": self.nImages.to_dict(),
                "seed": self.seed.to_dict(),
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
            self.nImages.set_name("number of images")
            self.seed.set_name("seed")

        def set_hints(self):
            super().set_hints()
            self.nImages.set_hint("The number of images to generate")
            self.seed.set_hint("Check to fix the random seed; value is the seed")

        def verify(self):
            super().verify()
            self.nImages.verify(0, Param.greater)

    def __init__(self, params):
        params.verify()
        self.params = params
        self.image_stack: List[FiberImage3D] = []
        self.generation_timings = {}

    def generate_images_3d(self, abort_check=None):
        total_images = int(self.params.nImages.get_value())
        if should_use_parallel_batch(total_images):
            samples, timing_summary = generate_parallel_batch(self.params, is_3d_mode=True, abort_check=abort_check)
            self.image_stack = samples
            self.generation_timings = timing_summary
            return

        total_start = time.perf_counter()
        if self.params.seed.use:
            RngUtility.rng.seed(self.params.seed.value)
            np.random.seed(self.params.seed.value)

        self.image_stack.clear()
        stage_totals = {
            "generation_seconds": 0.0,
            "smoothing_seconds": 0.0,
        }
        for i in range(total_images):
            _raise_if_aborted(abort_check)
            image = FiberImage3D(self.params)
            image.generate_fibers_3d(abort_check=abort_check)
            stage_totals["generation_seconds"] += float(image.performance_timings.get("generate_fibers_3d_seconds", 0.0))
            image.smooth_3d(abort_check=abort_check)
            stage_totals["smoothing_seconds"] += float(image.performance_timings.get("smooth_3d_seconds", 0.0))
            self.image_stack.append(image)
        summary = {"total_seconds": float(time.perf_counter() - total_start)}
        summary.update({key: float(value) for key, value in stage_totals.items()})
        self.generation_timings = summary

    def is_empty(self):
        return not self.image_stack

    def get(self, i):
        return self.image_stack[i]

    def get_image(self, i):
        return self.get(i).get_image()

    def size(self):
        return len(self.image_stack)
