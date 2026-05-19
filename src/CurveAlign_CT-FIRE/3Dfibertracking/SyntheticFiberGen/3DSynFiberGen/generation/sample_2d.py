
from __future__ import annotations

import math
import random
import time
from copy import deepcopy

import numpy as np
import pandas as pd
import tifffile as tiff
from PIL import Image, ImageDraw
from scipy.interpolate import splrep, splev
from scipy.ndimage import gaussian_filter, label
from scipy.stats import poisson

from core.abort import GenerationAborted, _raise_if_aborted
from core.distributions import Gaussian, PiecewiseLinear, Uniform, distribution_from_dict
from core.geometry import Circle, MiscUtility, MiscUtility3D, Vector
from core.params import Optional, Param
from core.rng import RngUtility, RngUtility3D
from generation.fiber import Fiber
from postprocess.pipeline_2d import ImageUtility
from postprocess.psf import PSFManager, set_last_psf_stats

JOINT_MATCH_MAX_ATTEMPTS = 16
JOINT_MATCH_TOLERANCE_RATIO = 0.1

class FiberImage:
    class Params:
        def __init__(self):
            self.nFibers = Param(value=15, name="number of fibers", hint="The number of fibers per image to generate")
            self.segmentLength = Param(value=10.0, name="segment length", hint="The length in pixels of fiber segments")
            self.alignment = Param(value=0.5, name="alignment", hint="A value between 0 and 1 indicating how close fibers are to the mean angle on average")
            self.meanAngle = Param(value=90.0, name="mean angle", hint="The average fiber angle in degrees")
            self.widthChange = Param(value=0.0, name="width change", hint="The maximum segment-to-segment width change of a fiber in pixels")
            self.generateCenterlineLabel = Param(value=True, name="generate centerline mask", hint="Generate a binary centerline mask derived from the fiber structure.")
            self.generateFiberImage = Param(value=True, name="generate fiber image", hint="Generate a fiber image derived from the fiber structure.")
            self.centerlineOutputType = Param(value="Binary", name="centerline mask output", hint="Binary centerline mask output format.")
            self.renderMode = Param(value="Fiber Mode", name="render mode", hint="Controls whether output is a realistic fiber image or a segmentation-style mask.")
            self.centerlineMaskWidthPx = Param(value=1, name="centerline mask width", hint="The rendered width in pixels of the centerline mask.")
            self.maskOutputMode = Param(value="Binary", name="mask output", hint="Legacy binary centerline mask output format.")
            self.imageWidth = Param(value=512, name="image width", hint="The width of the saved image in pixels")
            self.imageHeight = Param(value=512, name="image height", hint="The height of the saved image in pixels")
            self.imageBuffer = Param(value=5, name="edge buffer", hint="The size in pixels of the empty border around the edge of the image")
            self.jointPoints = Param(value=3, name="joint points", hint="The number of joint points to generate")
            self.showJoints = Optional(value=None, name="Show joints", hint="Check to display joint points on the image", use=False)
            self.showCenterlineOverlay = Optional(value=None, name="Show centerline overlay", hint="Overlay a centerline trace over the rendered fiber image", use=False)
            self.centerlineOverlayColor = Param(value="Neon Green", name="centerline overlay color", hint="Display color for the centerline overlay")
            self.centerlineOverlayBrightness = Param(value=1.2, name="centerline overlay brightness", hint="Brightness multiplier for the centerline overlay")
            self.useJoints = Optional(value=False, name="Use joints", hint="Toggle to use joint point constraints during generation", use=False)


            self.length = Uniform(0.0, float('inf'), 15.0, 200.0)
            self.width = Gaussian(0.0, float('inf'), 5.0, 0.5)
            self.straightness = Uniform(0.0, 1.0, 0.9, 1.0)
            self.intensity = Gaussian(0.0, 255.0, 200.0, 30.0)

            self.scale = Optional(value=5.0, name="scale", hint="Check to draw a scale bar on the image; value is the number of pixels per micron", use=False)
            self.downSample = Optional(value=0.5, name="down sample", hint="Check to enable down sampling; value is the ratio of final size to original size", use=False)
            self.blur = Optional(value=5.0, name="blur", hint="Check to enable Gaussian blurring; value is the radius of the blur in pixels", use=False)
            self.noise = Optional(value=10.0, name="noise", hint="Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)", use=False)
            # New noise configuration
            self.noiseModel = Param(value="No Noise", name="noise model", hint="Noise model to apply (No Noise, Poisson, Gaussian, Salt-and-Pepper, Speckle, Poisson+Gaussian)")
            self.noiseStdDev = Optional(value=10.0, name="noise std dev", hint="Standard deviation for Gaussian noise; used only for Gaussian or Poisson+Gaussian", use=False)
            self.saltPepperProb = Optional(value=0.01, name="salt-and-pepper probability", hint="Probability for Salt-and-Pepper noise; used only for Salt-and-Pepper", use=False)
            self.distance = Optional(value=64.0, name="distance", hint="Check to apply a distance filter; value controls the sharpness of the intensity falloff", use=False)
            self.cap = Optional(value=255, name="cap", hint="Check to cap the intensity; value is the inclusive maximum on a scale of 0-255", use=False)
            self.normalize = Optional(value=255, name="normalize", hint="Check to normalize the intensity; value is the inclusive maximum on a scale of 0-255", use=False)
            self.bubble = Optional(value=10, name="bubble", hint="Check to apply \"bubble smoothing\"; value is the number of passes", use=False)
            self.swap = Optional(value=100, name="swap", hint="Check to apply \"swap smoothing\"; number of swaps is this value times number of segments", use=False)
            self.spline = Optional(value=4, name="spline", hint="Check to enable spline smoothing; value is the number of interpolated points per segment", use=False)
            self.psfEnabled = Optional(value=1.0, name="apply psf", hint="Toggle to convolve the generated image with an optical PSF", use=False)
            self.psfType = Param(value="None", name="psf type", hint="PSF kernel to apply (None, 3D Gaussian, Vectorial (SHG))")
            self.psfGaussianNA = Param(value=1.2, name="gaussian psf NA", hint="Numerical aperture used for the Gaussian PSF approximation")
            self.psfGaussianWavelength = Param(value=0.8, name="gaussian psf wavelength", hint="Excitation wavelength (microns) for Gaussian PSF estimation")
            self.psfPixelSizeZ = Param(value=0.3, name="psf voxel size z", hint="Voxel spacing along Z in microns")
            self.psfPixelSizeY = Param(value=0.2, name="psf voxel size y", hint="Voxel spacing along Y in microns")
            self.psfPixelSizeX = Param(value=0.2, name="psf voxel size x", hint="Voxel spacing along X in microns")
            self.psfVectorialNA = Param(value=1.2, name="vectorial psf NA", hint="Numerical aperture for the vectorial PSF model")
            self.psfVectorialMediumRI = Param(value=1.33, name="medium refractive index", hint="Immersion medium refractive index")
            self.psfVectorialSampleRI = Param(value=1.37, name="sample refractive index", hint="Sample refractive index")
            self.psfVectorialWavelength = Param(value=0.8, name="vectorial psf wavelength", hint="Excitation wavelength (microns) for vectorial PSF")
            self.psfVectorialPolarization = Param(value=0.0, name="polarization angle", hint="Input polarization angle in degrees")
            self.psfVectorialVolumeZ = Param(value=6.0, name="volume size z", hint="Physical PSF extent along Z (microns)")
            self.psfVectorialVolumeY = Param(value=12.0, name="volume size y", hint="Physical PSF extent along Y (microns)")
            self.psfVectorialVolumeX = Param(value=12.0, name="volume size x", hint="Physical PSF extent along X (microns)")
            self.psfVectorialShapeZ = Param(value=33, name="psf samples z", hint="Number of samples along Z for the PSF volume")
            self.psfVectorialShapeY = Param(value=65, name="psf samples y", hint="Number of samples along Y for the PSF volume")
            self.psfVectorialShapeX = Param(value=65, name="psf samples x", hint="Number of samples along X for the PSF volume")

        @staticmethod
        def from_dict(params_dict):
            params = FiberImage.Params()
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
            params.jointPoints = Param.from_dict(params_dict["jointPoints"])
            params.showJoints = Optional.from_dict(params_dict["showJoints"])
            if "showCenterlineOverlay" in params_dict:
                params.showCenterlineOverlay = Optional.from_dict(params_dict["showCenterlineOverlay"])
            if "centerlineOverlayColor" in params_dict:
                params.centerlineOverlayColor = Param.from_dict(params_dict["centerlineOverlayColor"])
            if "centerlineOverlayBrightness" in params_dict:
                params.centerlineOverlayBrightness = Param.from_dict(params_dict["centerlineOverlayBrightness"])
            params.useJoints = Optional.from_dict(params_dict["useJoints"])          
            params.alignment = Param.from_dict(params_dict["alignment"])
            params.meanAngle = Param.from_dict(params_dict["meanAngle"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            params.length = distribution_from_dict(params_dict.get("length"), params.length)
            params.width = distribution_from_dict(params_dict.get("width"), params.width)
            params.straightness = distribution_from_dict(params_dict.get("straightness"), params.straightness)
            if "intensity" in params_dict:
                params.intensity = distribution_from_dict(params_dict.get("intensity"), params.intensity)
            params.scale = Optional.from_dict(params_dict["scale"])
            params.downSample = Optional.from_dict(params_dict["downSample"])
            params.blur = Optional.from_dict(params_dict["blur"])
            params.noise = Optional.from_dict(params_dict["noise"])
            # New noise config
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
            return params

        def sync_legacy_output_fields(self):
            generate_centerline = bool(self.generateCenterlineLabel.get_value())
            generate_fiber = bool(self.generateFiberImage.get_value())
            self.centerlineOutputType.value = "Binary"
            self.maskOutputMode.value = "Binary"
            self.renderMode.value = "Mask Mode" if generate_centerline and not generate_fiber else "Fiber Mode"

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
                "jointPoints": self.jointPoints.to_dict(),
                "showJoints": self.showJoints.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
                "useJoints": self.useJoints.to_dict(),
                "alignment": self.alignment.to_dict(),
                "meanAngle": self.meanAngle.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
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
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict()
            }

        def set_names(self):
            self.nFibers.set_name("number of fibers")
            self.segmentLength.set_name("segment length")
            self.generateCenterlineLabel.set_name("generate centerline mask")
            self.generateFiberImage.set_name("generate fiber image")
            self.centerlineOutputType.set_name("centerline mask output")
            self.renderMode.set_name("render mode")
            self.centerlineMaskWidthPx.set_name("centerline mask width")
            self.maskOutputMode.set_name("mask output")
            self.jointPoints.set_name("joint points")
            self.useJoints.set_name("Use joints")
            self.showJoints.set_name("Show Joints")   
            self.showCenterlineOverlay.set_name("Show centerline overlay")
            self.centerlineOverlayColor.set_name("centerline overlay color")
            self.centerlineOverlayBrightness.set_name("centerline overlay brightness")
            self.alignment.set_name("alignment")
            self.meanAngle.set_name("mean angle")
            self.widthChange.set_name("width change")
            self.imageWidth.set_name("image width")
            self.imageHeight.set_name("image height")
            self.imageBuffer.set_name("edge buffer")

            self.length.set_names()
            self.straightness.set_names()
            self.width.set_names()
            self.intensity.set_names()

            self.scale.set_name("scale")
            self.downSample.set_name("down sample")
            self.blur.set_name("blur")
            self.noise.set_name("noise")
            self.noiseModel.set_name("noise model")
            self.noiseStdDev.set_name("noise std dev")
            self.saltPepperProb.set_name("salt-and-pepper probability")
            self.distance.set_name("distance")
            self.cap.set_name("cap")
            self.normalize.set_name("normalize")
            self.bubble.set_name("bubble")
            self.swap.set_name("swap")
            self.spline.set_name("spline")

        def set_hints(self):
            self.nFibers.set_hint("The number of fibers per image to generate")
            self.segmentLength.set_hint("The length in pixels of fiber segments")
            self.generateCenterlineLabel.set_hint("Generate a binary centerline mask derived from the fiber structure.")
            self.generateFiberImage.set_hint("Generate a fiber image derived from the fiber structure.")
            self.centerlineOutputType.set_hint("Binary centerline mask output format.")
            self.renderMode.set_hint("Controls whether output is a realistic fiber image or a segmentation-style mask.")
            self.centerlineMaskWidthPx.set_hint("The rendered width in pixels of the centerline mask.")
            self.maskOutputMode.set_hint("Legacy binary centerline mask output format.")
            self.jointPoints.set_hint("The number of joint points in the fiber network")
            self.useJoints.set_hint("Toggle to use joint point constraints during generation")
            self.showJoints.set_hint("Check to display joint points on the image")
            self.showCenterlineOverlay.set_hint("Overlay a centerline trace over the rendered fiber image")
            self.centerlineOverlayColor.set_hint("Display color for the centerline overlay")
            self.centerlineOverlayBrightness.set_hint("Brightness multiplier for the centerline overlay")
            self.alignment.set_hint("A value between 0 and 1 indicating how close fibers are to the mean angle on average")
            self.meanAngle.set_hint("The average fiber angle in degrees")
            self.widthChange.set_hint("The maximum segment-to-segment width change of a fiber in pixels")
            self.imageWidth.set_hint("The width of the saved image in pixels")
            self.imageHeight.set_hint("The height of the saved image in pixels")
            self.imageBuffer.set_hint("The size in pixels of the empty border around the edge of the image")

            self.length.set_hints()
            self.straightness.set_hints()
            self.width.set_hints()
            self.intensity.set_hints()

            self.scale.set_hint("Check to draw a scale bar on the image; value is the number of pixels per micron")
            self.downSample.set_hint("Check to enable down sampling; value is the ratio of final size to original size")
            self.blur.set_hint("Check to enable Gaussian blurring; value is the radius of the blur in pixels")
            self.noise.set_hint("Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)")
            self.noiseModel.set_hint("Noise model to apply (No Noise, Poisson, Gaussian, Salt-and-Pepper, Speckle, Poisson+Gaussian)")
            self.noiseStdDev.set_hint("Standard deviation for Gaussian noise; used only for Gaussian or Poisson+Gaussian")
            self.saltPepperProb.set_hint("Probability for Salt-and-Pepper noise; used only for Salt-and-Pepper")
            self.distance.set_hint("Check to apply a distance filter; value controls the sharpness of the intensity falloff")
            self.cap.set_hint("Check to cap the intensity; value is the inclusive maximum on a scale of 0-255")
            self.normalize.set_hint("Check to normalize the intensity; value is the inclusive maximum on a scale of 0-255")
            self.bubble.set_hint("Check to apply \"bubble smoothing\"; value is the number of passes")
            self.swap.set_hint("Check to apply \"swap smoothing\"; number of swaps is this value times number of segments")
            self.spline.set_hint("Check to enable spline smoothing; value is the number of interpolated points per segment")
            self.psfEnabled.set_hint("Check to apply an optical PSF prior to adding noise")
            self.psfType.set_hint("PSF kernel to apply (None, 3D Gaussian, Vectorial (SHG))")
            self.psfGaussianNA.set_hint("Numerical aperture for the Gaussian PSF approximation")
            self.psfGaussianWavelength.set_hint("Excitation wavelength (microns) for Gaussian PSF estimation")
            self.psfPixelSizeZ.set_hint("Voxel spacing along Z in microns")
            self.psfPixelSizeY.set_hint("Voxel spacing along Y in microns")
            self.psfPixelSizeX.set_hint("Voxel spacing along X in microns")
            self.psfVectorialNA.set_hint("Numerical aperture for the vectorial PSF model")
            self.psfVectorialMediumRI.set_hint("Immersion medium refractive index")
            self.psfVectorialSampleRI.set_hint("Sample refractive index")
            self.psfVectorialWavelength.set_hint("Excitation wavelength (microns) for the vectorial PSF")
            self.psfVectorialPolarization.set_hint("Linear polarization angle in degrees")
            self.psfVectorialVolumeZ.set_hint("Physical PSF extent along Z (microns)")
            self.psfVectorialVolumeY.set_hint("Physical PSF extent along Y (microns)")
            self.psfVectorialVolumeX.set_hint("Physical PSF extent along X (microns)")
            self.psfVectorialShapeZ.set_hint("Number of samples along Z in the PSF volume")
            self.psfVectorialShapeY.set_hint("Number of samples along Y in the PSF volume")
            self.psfVectorialShapeX.set_hint("Number of samples along X in the PSF volume")

        def verify(self):
            self.sync_legacy_output_fields()
            self.nFibers.verify(0, Param.greater)
            self.segmentLength.verify(0.0, Param.greater)
            if self.useJoints.use:
                self.jointPoints.verify(0, Param.greater_eq)
            self.widthChange.verify(0.0, Param.greater_eq)
            if not bool(self.generateCenterlineLabel.get_value()) and not bool(self.generateFiberImage.get_value()):
                raise ValueError("At least one derived output must be enabled")
            if str(self.centerlineOutputType.get_value()).strip().lower() != "binary":
                raise ValueError("Value of \"centerline mask output\" must be 'binary'")
            allowed_render_modes = {"fiber mode", "mask mode"}
            render_mode = str(self.renderMode.get_value()).strip().lower()
            if render_mode not in allowed_render_modes:
                raise ValueError(f"Value of \"render mode\" must be one of {sorted(list(allowed_render_modes))}")
            self.centerlineMaskWidthPx.verify(0, Param.greater)
            mask_output_mode = str(self.maskOutputMode.get_value()).strip().lower()
            if mask_output_mode != "binary":
                raise ValueError("Value of \"mask output\" must be 'binary'")
            self.alignment.verify(0.0, Param.greater_eq)
            self.alignment.verify(1.0, Param.less_eq)
            self.meanAngle.verify(0.0, Param.greater_eq)
            self.meanAngle.verify(180.0, Param.less_eq)

            self.imageWidth.verify(0, Param.greater)
            self.imageHeight.verify(0, Param.greater)
            self.imageBuffer.verify(0, Param.greater)
            self.centerlineOverlayBrightness.verify(0.0, Param.greater)

            allowed_centerline_colors = {"green", "neon green", "cyan", "magenta", "yellow"}
            centerline_color = str(self.centerlineOverlayColor.get_value()).strip().lower()
            if centerline_color not in allowed_centerline_colors:
                raise ValueError(f"Value of \"centerline overlay color\" must be one of {sorted(list(allowed_centerline_colors))}")

            self.length.verify()
            self.straightness.verify()
            self.width.verify()
            self.intensity.verify()

            self.scale.verify(0.0, Param.greater)
            self.downSample.verify(0.0, Param.greater)
            self.blur.verify(0.0, Param.greater)
            self.noise.verify(0.0, Param.greater)
            # Validate noise model and related params
            allowed_models = {"no noise", "poisson", "gaussian", "salt-and-pepper", "speckle", "poisson+gaussian"}
            model = str(self.noiseModel.get_value()).lower()
            if model not in allowed_models:
                raise ValueError(f"Value of \"noise model\" must be one of {sorted(list(allowed_models))}")
            if model in {"gaussian", "poisson+gaussian"}:
                if float(self.noiseStdDev.get_value()) <= 0:
                    raise ValueError("Value of \"noise std dev\" must be greater than 0.0")
            if model == "salt-and-pepper":
                p = float(self.saltPepperProb.get_value())
                if p < 0.0 or p > 1.0:
                    raise ValueError("Value of \"salt-and-pepper probability\" must be between 0.0 and 1.0")
            self.distance.verify(0.0, Param.greater)
            self.cap.verify(0, Param.greater_eq)
            self.cap.verify(255, Param.less_eq)
            self.normalize.verify(0, Param.greater_eq)
            self.normalize.verify(255, Param.less_eq)
            self.bubble.verify(0, Param.greater)
            self.swap.verify(0, Param.greater)
            self.spline.verify(0, Param.greater)
            psf_type_value = str(self.psfType.get_value()).strip().lower()
            allowed_psf_types = {"none", "3d gaussian", "vectorial (shg)"}
            if psf_type_value not in allowed_psf_types:
                raise ValueError(f"Value of \"psf type\" must be one of {sorted(list(allowed_psf_types))}")
            self.psfGaussianNA.verify(0.0, Param.greater)
            self.psfGaussianWavelength.verify(0.0, Param.greater)
            self.psfPixelSizeZ.verify(0.0, Param.greater)
            self.psfPixelSizeY.verify(0.0, Param.greater)
            self.psfPixelSizeX.verify(0.0, Param.greater)
            self.psfVectorialNA.verify(0.0, Param.greater)
            self.psfVectorialMediumRI.verify(0.0, Param.greater)
            self.psfVectorialSampleRI.verify(0.0, Param.greater)
            self.psfVectorialWavelength.verify(0.0, Param.greater)
            self.psfVectorialVolumeZ.verify(0.0, Param.greater)
            self.psfVectorialVolumeY.verify(0.0, Param.greater)
            self.psfVectorialVolumeX.verify(0.0, Param.greater)
            self.psfVectorialShapeZ.verify(0, Param.greater)
            self.psfVectorialShapeY.verify(0, Param.greater)
            self.psfVectorialShapeX.verify(0, Param.greater)

    TARGET_SCALE_SIZE = 0.2
    CAP_RATIO = 0.01
    BUFF_RATIO = 0.015

    def __init__(self, params):
        self.params = params
        self.fibers = []
        self.joint_points = []
        self.image = Image.new('L', (params.imageWidth.get_value(), params.imageHeight.get_value()), 0)
        self.performance_timings = {}
        self.generation_metadata = {}
        self.joints_dirty = True
        self.render_dirty = True
        self.centerline_render_dirty = True
        self.validation_dirty = True
        self._cached_fiber_render_2d = None
        self._cached_centerline_render_2d = None
        self._cached_final_output_2d = None

    def record_timing(self, key, elapsed_seconds):
        self.performance_timings[key] = float(elapsed_seconds)

    def invalidate_render_cache(self):
        self.render_dirty = True
        self.centerline_render_dirty = True
        self._cached_fiber_render_2d = None
        self._cached_centerline_render_2d = None
        self._cached_final_output_2d = None

    def mark_geometry_dirty(self):
        self.joints_dirty = True
        self.validation_dirty = True
        self.invalidate_render_cache()

    def ensure_joints(self, abort_check=None, force=False):
        if force or self.joints_dirty:
            self.joint_points = self.count_joints(abort_check=abort_check)
            self.joints_dirty = False
        return self.joint_points

    def __iter__(self):
        return iter(self.fibers)

    @staticmethod
    def should_generate_centerline_label(params):
        if hasattr(params, "generateCenterlineLabel"):
            return bool(getattr(params.generateCenterlineLabel, "value", True))
        return str(getattr(params.renderMode, "value", "Fiber Mode")).strip().lower() == "mask mode"

    @staticmethod
    def should_generate_fiber_image(params):
        if hasattr(params, "generateFiberImage"):
            return bool(getattr(params.generateFiberImage, "value", True))
        return str(getattr(params.renderMode, "value", "Fiber Mode")).strip().lower() != "mask mode"

    @staticmethod
    def get_centerline_output_mode(params):
        return "binary"

    @staticmethod
    def is_binary_centerline_output(params):
        return True

    @staticmethod
    def is_mask_mode(params):
        return FiberImage.should_generate_centerline_label(params) and not FiberImage.should_generate_fiber_image(params)

    @staticmethod
    def get_mask_output_mode(params):
        return FiberImage.get_centerline_output_mode(params)

    @staticmethod
    def is_binary_mask_output(params):
        return FiberImage.is_binary_centerline_output(params)

    @staticmethod
    def _preview_only_export_param_keys():
        return {
            "showJoints",
            "showCenterlineOverlay",
            "centerlineOverlayColor",
            "centerlineOverlayBrightness",
        }

    @staticmethod
    def _deprecated_export_param_keys():
        return {
            "centerlineOutputType",
            "renderMode",
            "maskOutputMode",
        }

    @staticmethod
    def _gaussian_psf_export_param_keys():
        return {
            "psfGaussianNA",
            "psfGaussianWavelength",
            "psfPixelSizeZ",
            "psfPixelSizeY",
            "psfPixelSizeX",
        }

    @staticmethod
    def _vectorial_psf_export_param_keys():
        return {
            "psfVectorialNA",
            "psfVectorialMediumRI",
            "psfVectorialSampleRI",
            "psfVectorialWavelength",
            "psfVectorialPolarization",
            "psfVectorialVolumeZ",
            "psfVectorialVolumeY",
            "psfVectorialVolumeX",
            "psfVectorialShapeZ",
            "psfVectorialShapeY",
            "psfVectorialShapeX",
        }

    @staticmethod
    def _fiber_only_export_param_keys():
        return {
            "intensity",
            "scale",
            "downSample",
            "blur",
            "blurRadius",
            "noise",
            "noiseMean",
            "noiseModel",
            "noiseStdDev",
            "saltPepperProb",
            "distance",
            "distanceFalloff",
            "cap",
            "normalize",
            "psfEnabled",
            "psfType",
            *FiberImage._gaussian_psf_export_param_keys(),
            *FiberImage._vectorial_psf_export_param_keys(),
        }

    def should_export_generation_param(self, key, raw_value):
        params = self.params
        generate_centerline = FiberImage.should_generate_centerline_label(params)
        generate_fiber = FiberImage.should_generate_fiber_image(params)
        noise_model = str(params.noiseModel.get_value()).strip().lower() if hasattr(params, "noiseModel") else "no noise"
        noise_enabled = FiberImage.should_apply_noise(params, is_3d=hasattr(params, "imageDepth"))
        psf_type = str(params.psfType.get_value()).strip().lower() if hasattr(params, "psfType") else "none"
        psf_enabled = bool(getattr(getattr(params, "psfEnabled", None), "use", False)) and psf_type != "none"

        if key in FiberImage._preview_only_export_param_keys() or key in FiberImage._deprecated_export_param_keys():
            return False
        if key == "generateCenterlineLabel":
            return generate_centerline
        if key == "generateFiberImage":
            return generate_fiber
        if key == "centerlineMaskWidthPx":
            return generate_centerline
        if key in FiberImage._fiber_only_export_param_keys() and not generate_fiber:
            return False
        if key == "noiseModel":
            return generate_fiber and noise_enabled and noise_model != "no noise"
        if key in {"noise", "noiseMean"}:
            return generate_fiber and noise_model in {"poisson", "poisson+gaussian"}
        if key == "noiseStdDev":
            return generate_fiber and noise_model in {"gaussian", "poisson+gaussian"}
        if key == "saltPepperProb":
            return generate_fiber and noise_model == "salt-and-pepper"
        if key == "psfEnabled":
            return generate_fiber and psf_enabled
        if key == "psfType":
            return generate_fiber and psf_enabled
        if key in FiberImage._gaussian_psf_export_param_keys():
            return generate_fiber and psf_enabled and psf_type == "3d gaussian"
        if key in FiberImage._vectorial_psf_export_param_keys():
            return generate_fiber and psf_enabled and psf_type == "vectorial (shg)"
        if isinstance(raw_value, dict) and "use" in raw_value and not raw_value.get("use", False):
            return False
        return True

    def get_generation_parameter_description(self, key):
        descriptions = {
            "length": "Distribution used to sample fiber lengths.",
            "width": "Distribution used to sample fiber widths.",
            "straightness": "Distribution used to sample fiber straightness.",
            "intensity": "Distribution used to sample Fiber Image intensities.",
        }
        if key in descriptions:
            return descriptions[key]
        attr = getattr(self.params, key, None)
        if hasattr(attr, "get_hint"):
            return attr.get_hint()
        return "Applied parameter value."

    @staticmethod
    def get_mask_line_width(params):
        try:
            width_value = int(round(float(getattr(params.centerlineMaskWidthPx, "value", 1))))
        except (TypeError, ValueError):
            width_value = 1
        return max(1, width_value)

    @staticmethod
    def render_fibers_to_image(
        fibers,
        size,
        default_intensity=255.0,
        binary=False,
        line_width_override=None,
        abort_check=None,
    ):
        """Render fibers into a grayscale image for either realistic output or label masks."""
        width, height = size
        base = np.zeros((height, width), dtype=np.float32)
        for fiber_index, fiber in enumerate(fibers):
            if fiber_index % 8 == 0:
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
            overlay = Image.new('L', (width, height), 0)
            draw = ImageDraw.Draw(overlay)
            for segment_index, segment in enumerate(fiber):
                if segment_index % 32 == 0:
                    _raise_if_aborted(abort_check)
                if line_width_override is not None:
                    line_width = max(1, int(round(float(line_width_override))))
                else:
                    line_width = max(1, int(round(float(segment.width))))
                draw.line(
                    [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                    fill=int(round(intensity)),
                    width=line_width
                )
            overlay_np = np.array(overlay, dtype=np.float32)
            if binary:
                base = np.maximum(base, overlay_np)
            else:
                base += overlay_np
        base = np.clip(base, 0, 255).astype(np.uint8)
        return Image.fromarray(base, 'L')

    def render_fiber_image_2d(self, abort_check=None):
        if abort_check is None and self._cached_fiber_render_2d is not None and not self.render_dirty:
            return self._cached_fiber_render_2d.copy()
        output = self.render_fibers_to_image(
            self.fibers,
            (self.params.imageWidth.get_value(), self.params.imageHeight.get_value()),
            abort_check=abort_check,
        )
        if abort_check is None:
            self._cached_fiber_render_2d = output.copy()
            self.render_dirty = False
        return output

    def render_centerline_label_2d(self, abort_check=None):
        if abort_check is None and self._cached_centerline_render_2d is not None and not self.centerline_render_dirty:
            return self._cached_centerline_render_2d.copy()
        base_image = self.render_fibers_to_image(
            self.fibers,
            (self.params.imageWidth.get_value(), self.params.imageHeight.get_value()),
            default_intensity=255.0,
            binary=True,
            line_width_override=self.get_mask_line_width(self.params),
            abort_check=abort_check,
        )
        np_image = np.array(base_image, dtype=np.float32)
        np_image = (np_image > 127).astype(np.uint8) * 255
        output = Image.fromarray(np.clip(np_image, 0, 255).astype(np.uint8), 'L')
        if abort_check is None:
            self._cached_centerline_render_2d = output.copy()
            self.centerline_render_dirty = False
        return output

    def render_base_image_2d(self, abort_check=None):
        return self.render_fiber_image_2d(abort_check=abort_check)

    @staticmethod
    def add_noise_to_array(np_image, params):
        model = str(params.noiseModel.get_value()).lower()
        output = np.asarray(np_image, dtype=np.float32).copy()
        if model == "poisson":
            mean = float(params.noise.get_value())
            noise = poisson(mean).rvs(output.size).reshape(output.shape)
            output = output + noise
        elif model == "gaussian":
            std = float(params.noiseStdDev.get_value())
            noise = np.random.normal(0.0, std, size=output.shape)
            output = output + noise
        elif model == "salt-and-pepper":
            p = float(params.saltPepperProb.get_value())
            rnd = np.random.rand(*output.shape)
            output[rnd < (p / 2.0)] = 0.0
            output[rnd > 1.0 - (p / 2.0)] = 255.0
        elif model == "speckle":
            speckle = np.random.normal(1.0, 0.2, size=output.shape)
            output = output * speckle
        elif model == "poisson+gaussian":
            mean = float(params.noise.get_value())
            p_noise = poisson(mean).rvs(output.size).reshape(output.shape)
            g_std = float(params.noiseStdDev.get_value())
            g_noise = np.random.normal(0.0, g_std, size=output.shape)
            output = output + p_noise + g_noise
        return np.clip(output, 0, 255).astype(np.uint8)

    @staticmethod
    def should_apply_noise(params, is_3d=False):
        model = str(params.noiseModel.get_value()).lower()
        if model == "poisson":
            noise_param = params.noiseMean if is_3d and hasattr(params, "noiseMean") else params.noise
            return noise_param.use
        if model == "gaussian":
            return params.noiseStdDev.use
        if model == "salt-and-pepper":
            return params.saltPepperProb.use
        if model == "speckle":
            return True
        if model == "poisson+gaussian":
            noise_param = params.noiseMean if is_3d and hasattr(params, "noiseMean") else params.noise
            return noise_param.use or params.noiseStdDev.use
        return False

    @staticmethod
    def _format_scale_bar_label(length_um):
        if np.isclose(length_um, round(length_um)):
            return f"{int(round(length_um))} um"
        if 1e-2 <= abs(length_um) < 1e3:
            compact = f"{length_um:.2f}".rstrip("0").rstrip(".")
            return f"{compact} um"
        return f"{length_um:.1e} um"

    @classmethod
    def compute_scale_bar_spec(cls, image_width, image_height, pixels_per_micron):
        if pixels_per_micron <= 0:
            raise ValueError("Scale must be greater than zero.")

        target_size_um = cls.TARGET_SCALE_SIZE * image_width / pixels_per_micron
        floor_pow = np.floor(np.log10(target_size_um))
        options = [10**floor_pow, 5 * 10**floor_pow, 10**(floor_pow + 1)]
        best_size_um = float(min(options, key=lambda x: abs(target_size_um - x)))

        cap_size = int(cls.CAP_RATIO * image_height)
        x_buff = int(cls.BUFF_RATIO * image_width)
        y_buff = int(cls.BUFF_RATIO * image_height)
        scale_height = image_height - y_buff - cap_size
        scale_right = x_buff + int(best_size_um * pixels_per_micron)
        return {
            "label": cls._format_scale_bar_label(best_size_um),
            "left": x_buff,
            "right": scale_right,
            "height": scale_height,
            "cap_size": cap_size,
            "text_x": x_buff,
            "text_y": scale_height - cap_size - y_buff,
            "physical_length_um": best_size_um,
        }

    @classmethod
    def draw_scale_bar_on_image(cls, image, params):
        if not hasattr(params, "scale") or not params.scale.use:
            return image
        output = image.copy()
        spec = cls.compute_scale_bar_spec(
            output.width,
            output.height,
            float(params.scale.get_value()),
        )

        draw = ImageDraw.Draw(output)
        draw.line((spec["left"], spec["height"], spec["right"], spec["height"]), fill=255)
        draw.line((spec["left"], spec["height"] + spec["cap_size"], spec["left"], spec["height"] - spec["cap_size"]), fill=255)
        draw.line((spec["right"], spec["height"] + spec["cap_size"], spec["right"], spec["height"] - spec["cap_size"]), fill=255)
        draw.text((spec["text_x"], spec["text_y"]), spec["label"], fill=255)
        return output

    @classmethod
    def apply_postprocessing_2d(cls, image, params, abort_check=None):
        np_image = np.array(image, dtype=np.float32)
        mask_mode = cls.is_mask_mode(params)
        binary_mask = mask_mode and cls.is_binary_mask_output(params)

        if binary_mask:
            thresholded = (np_image > 127).astype(np.uint8) * 255
            return Image.fromarray(thresholded, 'L')

        if params.distance.use:
            np_image = ImageUtility.distance_function(
                Image.fromarray(np.clip(np_image, 0, 255).astype(np.uint8), 'L'),
                params.distance.get_value(),
                abort_check=abort_check,
            )
            np_image = np.array(np_image, dtype=np.float32)

        if not mask_mode and getattr(params, "psfEnabled", None) and params.psfEnabled.use:
            manager = PSFManager(params)
            psf_result = manager.apply(np_image, volume=False, abort_check=abort_check)
            if psf_result is not None:
                np_image = psf_result.astype(np.float32)

        if (not mask_mode or not binary_mask) and cls.should_apply_noise(params, is_3d=False):
            np_image = cls.add_noise_to_array(np_image, params).astype(np.float32)

        if params.blur.use:
            _raise_if_aborted(abort_check)
            np_image = gaussian_filter(np_image, sigma=params.blur.get_value())

        if params.cap.use:
            np_image = np.clip(np_image, 0, params.cap.get_value())

        if params.normalize.use:
            max_value = np.max(np_image)
            if max_value > 0:
                np_image = np_image * float(params.normalize.get_value()) / max_value

        np_image = np.clip(np_image, 0, 255)
        mode = 'L'
        output = Image.fromarray(np_image.astype(np.uint8), mode)

        if not mask_mode and params.scale.use:
            output = cls.draw_scale_bar_on_image(output, params)

        if params.downSample.use:
            new_size = (
                int(output.width * params.downSample.get_value()),
                int(output.height * params.downSample.get_value())
            )
            resize_mode = Image.NEAREST if mask_mode else Image.BILINEAR
            output = output.resize(new_size, resize_mode)

        return output

    def to_dict(self):
        self.ensure_joints()
        return {
            "params": self.params.to_dict(),
            "fibers": [fiber.to_dict() for fiber in self.fibers],
            "joint_points": [{"x": point.x, "y": point.y} for point in self.joint_points],
            "performance_timings": dict(self.performance_timings),
            "generation_metadata": dict(self.generation_metadata),
        }

    def to_csv_data(self):
        self.ensure_joints()
        summary_data, segments_data, points_data = [], [], []
        joints_data = [{"Joint ID": idx, "X": jp.x, "Y": jp.y} for idx, jp in enumerate(self.joint_points)]

        # Accumulators for network-level metrics
        all_orient_xy = []  # degrees
        per_fiber_alignment = []
        per_fiber_straightness = []  # morphological straightness
        total_length = 0.0
        all_segment_widths = []

        for idx, fiber in enumerate(self.fibers):
            start = fiber.points[0]
            end = fiber.points[-1]
            mean_width = sum(fiber.widths) / len(fiber.widths) if fiber.widths else 0
            mean_angle = sum(fiber.orientations_xy) / len(fiber.orientations_xy) if fiber.orientations_xy else 0
            std_angle = np.std(fiber.orientations_xy) if fiber.orientations_xy else 0

            # Compute per-fiber path length and morphological straightness
            path_len = 0.0
            for seg_idx in range(len(fiber.points) - 1):
                p0 = fiber.points[seg_idx]
                p1 = fiber.points[seg_idx + 1]
                path_len += p1.subtract(p0).length()
            chord = end.subtract(start).length() if len(fiber.points) >= 2 else 0.0
            straightness_morph = (chord / path_len) if path_len > 0 else 0.0
            per_fiber_straightness.append(straightness_morph)
            total_length += path_len

            # Per-fiber alignment from segment orientations (nematic order parameter)
            if getattr(fiber, 'orientations_xy', None):
                angs = np.deg2rad(np.array(fiber.orientations_xy, dtype=float))
                if angs.size > 0:
                    cmean = np.mean(np.exp(1j * 2.0 * angs))
                    per_fiber_alignment.append(float(np.abs(cmean)))
                    # Accumulate for network
                    all_orient_xy.extend(list(np.array(fiber.orientations_xy, dtype=float)))
            else:
                per_fiber_alignment.append(0.0)

            summary_data.append({
                "Fiber ID": idx,
                "Start X": start.x,
                "Start Y": start.y,
                "End X": end.x,
                "End Y": end.y,
                "Segment Count": fiber.params.n_segments,
                "Segment Length": fiber.params.segment_length,
                "Straightness Param": fiber.params.straightness,
                "Path Length": path_len,
                "Straightness Morph": straightness_morph,
                "Start Width": fiber.params.start_width,
                "Mean Width": mean_width,
                "Mean Angle XY": mean_angle,
                "Std Angle XY": std_angle,
                "Fiber Alignment": (per_fiber_alignment[-1] if per_fiber_alignment else 0.0),
                "Has Joint Point": fiber.has_joint
            })

            for seg_idx in range(len(fiber.points) - 1):
                p0 = fiber.points[seg_idx]
                p1 = fiber.points[seg_idx + 1]
                segments_data.append({
                    "Fiber ID": idx,
                    "Segment Index": seg_idx,
                    "Start X": p0.x,
                    "Start Y": p0.y,
                    "Start Z": p0.z,
                    "End X": p1.x,
                    "End Y": p1.y,
                    "End Z": p1.z,
                    "Width": fiber.widths[seg_idx] if seg_idx < len(fiber.widths) else "",
                    "Orientation XY": fiber.orientations_xy[seg_idx] if seg_idx < len(fiber.orientations_xy) else "",
                    "Orientation YZ": fiber.orientations_yz[seg_idx] if seg_idx < len(fiber.orientations_yz) else "",
                    "Orientation XZ": fiber.orientations_xz[seg_idx] if seg_idx < len(fiber.orientations_xz) else ""
                })
                if seg_idx < len(fiber.widths):
                    all_segment_widths.append(fiber.widths[seg_idx])

            for pt_idx, point in enumerate(fiber.points):
                points_data.append({
                    "Fiber ID": idx,
                    "Point Index": pt_idx,
                    "X": point.x,
                    "Y": point.y,
                    "Z": point.z,
                    "Width": fiber.widths[pt_idx] if pt_idx < len(fiber.widths) else "",
                    "Orientation XY": fiber.orientations_xy[pt_idx] if pt_idx < len(fiber.orientations_xy) else "",
                    "Orientation YZ": fiber.orientations_yz[pt_idx] if pt_idx < len(fiber.orientations_yz) else "",
                    "Orientation XZ": fiber.orientations_xz[pt_idx] if pt_idx < len(fiber.orientations_xz) else ""
                })

        # Compute network-level alignment and mean direction from all segment orientations (if any)
        if len(all_orient_xy) > 0:
            thetas = np.deg2rad(np.array(all_orient_xy, dtype=float))
            cmean = np.mean(np.exp(1j * 2.0 * thetas))
            network_alignment = float(np.abs(cmean))
            mean_dir_rad = 0.5 * float(np.arctan2(cmean.imag, cmean.real))
            network_mean_angle = (np.degrees(mean_dir_rad) + 360.0) % 180.0
        else:
            network_alignment = 0.0
            network_mean_angle = 0.0

        # Alignment score per segment relative to network mean (0..1)
        if len(segments_data) > 0:
            seg_align_scores = []
            for fiber in self.fibers:
                for seg_idx in range(len(fiber.points) - 1):
                    theta_deg = fiber.orientations_xy[seg_idx] if seg_idx < len(fiber.orientations_xy) else None
                    if theta_deg is None:
                        seg_align_scores.append("")
                    else:
                        delta = np.deg2rad(theta_deg - network_mean_angle)
                        score = 0.5 * (1.0 + np.cos(2.0 * delta))
                        seg_align_scores.append(float(score))
            for row, score in zip(segments_data, seg_align_scores):
                row["Alignment Score (0-1)"] = score

        # Compute network-level aggregate metrics
        fiber_count = len(self.fibers)
        segment_count = sum(max(0, len(f.points) - 1) for f in self.fibers)
        img_w = int(self.params.imageWidth.get_value()) if hasattr(self.params, 'imageWidth') else 0
        img_h = int(self.params.imageHeight.get_value()) if hasattr(self.params, 'imageHeight') else 0
        area = float(img_w * img_h) if img_w and img_h else 0.0
        length_density = (total_length / area) if area > 0 else 0.0
        joint_count = len(self.joint_points)
        joint_density = (joint_count / area) if area > 0 else 0.0
        avg_fiber_align = float(np.mean(per_fiber_alignment)) if per_fiber_alignment else 0.0
        std_fiber_align = float(np.std(per_fiber_alignment)) if per_fiber_alignment else 0.0
        avg_straight = float(np.mean(per_fiber_straightness)) if per_fiber_straightness else 0.0
        std_straight = float(np.std(per_fiber_straightness)) if per_fiber_straightness else 0.0
        if all_segment_widths:
            widths_arr = np.array(all_segment_widths, dtype=float)
            avg_width = float(np.mean(widths_arr))
            std_width = float(np.std(widths_arr))
            min_width = float(np.min(widths_arr))
            max_width = float(np.max(widths_arr))
        else:
            avg_width = std_width = min_width = max_width = 0.0
        mean_seg_len = (total_length / segment_count) if segment_count > 0 else 0.0

        network_summary = [{
            "Fiber Count": fiber_count,
            "Segment Count": segment_count,
            "Network Alignment": network_alignment,
            "Network Mean Angle (deg)": network_mean_angle,
            "Avg Fiber Alignment": avg_fiber_align,
            "Std Fiber Alignment": std_fiber_align,
            "Avg Straightness (morph)": avg_straight,
            "Std Straightness (morph)": std_straight,
            "Total Fiber Length (px)": total_length,
            "Image Width (px)": img_w,
            "Image Height (px)": img_h,
            "Image Area (px^2)": area,
            "Length Density (px/px^2)": length_density,
            "Joint Count": joint_count,
            "Joint Density (#/px^2)": joint_density,
            "Avg Segment Width": avg_width,
            "Std Segment Width": std_width,
            "Min Segment Width": min_width,
            "Max Segment Width": max_width,
            "Mean Segment Length (px)": mean_seg_len
        }]

        # Only include parameters that are applied:
        # - Always include non-optional Params (no 'use' flag)
        # - For Optional params, include only when use == True
        # Special handling: include noise model with its parameter values (mean/std/p as appropriate)
        params_dict = self.params.to_dict()
        params_data = []

        # Precompute a descriptive noise model string with values
        noise_model_value = None
        try:
            model_name = str(self.params.noiseModel.get_value()).lower() if hasattr(self.params, 'noiseModel') else 'no noise'
            if model_name == 'poisson':
                if hasattr(self.params, 'noiseMean'):
                    noise_mean = self.params.noiseMean.get_string()
                elif hasattr(self.params, 'noise'):
                    noise_mean = self.params.noise.get_string()
                else:
                    noise_mean = None
                noise_model_value = f"Poisson{f' (mean={noise_mean})' if noise_mean is not None else ''}"
            elif model_name == 'gaussian':
                std = self.params.noiseStdDev.get_string() if hasattr(self.params, 'noiseStdDev') else None
                noise_model_value = f"Gaussian{f' (std={std})' if std is not None else ''}"
            elif model_name == 'salt-and-pepper':
                p = self.params.saltPepperProb.get_string() if hasattr(self.params, 'saltPepperProb') else None
                noise_model_value = f"Salt-and-Pepper{f' (p={p})' if p is not None else ''}"
            elif model_name == 'speckle':
                noise_model_value = 'Speckle'
            elif model_name == 'poisson+gaussian':
                if hasattr(self.params, 'noiseMean'):
                    mean_str = self.params.noiseMean.get_string()
                elif hasattr(self.params, 'noise'):
                    mean_str = self.params.noise.get_string()
                else:
                    mean_str = None
                std_str = self.params.noiseStdDev.get_string() if hasattr(self.params, 'noiseStdDev') else None
                details = []
                if mean_str is not None:
                    details.append(f"mean={mean_str}")
                if std_str is not None:
                    details.append(f"std={std_str}")
                details_str = f" ({', '.join(details)})" if details else ""
                noise_model_value = f"Poisson+Gaussian{details_str}"
            else:
                noise_model_value = 'No Noise'
        except Exception:
            noise_model_value = None

        for k, v in params_dict.items():
            if not self.should_export_generation_param(k, v):
                continue

            # Special-case noise model: include formatted value with parameters
            if k == 'noiseModel' and noise_model_value is not None:
                params_data.append({"Parameter": k, "Value": noise_model_value})
                continue

            if isinstance(v, dict):
                value = v.get("value", v)
            else:
                value = v
            params_data.append({"Parameter": k, "Value": value})

        return (
            pd.DataFrame(network_summary),
            pd.DataFrame(summary_data),
            pd.DataFrame(segments_data),
            pd.DataFrame(points_data),
            pd.DataFrame(joints_data),
            pd.DataFrame(params_data)
        )

    @staticmethod
    def from_dict(fiber_image_dict):
        params = FiberImage.Params.from_dict(fiber_image_dict["params"])
        fiber_image = FiberImage(params)
        fiber_image.fibers = [Fiber.from_dict(fiber_dict) for fiber_dict in fiber_image_dict["fibers"]]
        fiber_image.joint_points = [
            Vector(point.get("x", 0.0), point.get("y", 0.0))
            for point in fiber_image_dict.get("joint_points", [])
        ]
        fiber_image.performance_timings = dict(fiber_image_dict.get("performance_timings", {}))
        fiber_image.generation_metadata = dict(fiber_image_dict.get("generation_metadata", {}))
        fiber_image.joints_dirty = False
        fiber_image.validation_dirty = True
        return fiber_image

    def generate_fibers(self, abort_check=None):
        start_time = time.perf_counter()
        target_joint_count = int(self.params.jointPoints.get_value()) if self.params.useJoints.use else None
        joint_tolerance = 0 if not self.params.useJoints.use or target_joint_count <= 0 else max(
            1,
            int(round(target_joint_count * JOINT_MATCH_TOLERANCE_RATIO)),
        )
        max_iterations = JOINT_MATCH_MAX_ATTEMPTS if self.params.useJoints.use else 1
        best_candidate = None
        accepted_iteration = None

        for iteration in range(max_iterations):
            if iteration % 8 == 0:
                _raise_if_aborted(abort_check)
            self.fibers = []  # Clear previous fibers
            self.joint_points = []  # Clear previous joint points
            directions = self.generate_directions()

            for direction_index, direction in enumerate(directions):
                if direction_index % 8 == 0:
                    _raise_if_aborted(abort_check)
                fiber_params = Fiber.Params()
                fiber_params.segment_length = self.params.segmentLength.get_value()
                fiber_params.width_change = self.params.widthChange.get_value()
                fiber_params.n_segments = max(1, round(self.params.length.sample() / self.params.segmentLength.get_value()))
                fiber_params.straightness = self.params.straightness.sample()
                fiber_params.start_width = self.params.width.sample()

                end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
                fiber_params.start = self.find_fiber_start(end_distance, direction)
                fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

                fiber = Fiber(fiber_params)
                fiber.generate(abort_check=abort_check)
                if hasattr(self.params, "intensity"):
                    fiber.intensity = self.params.intensity.sample()
                self.fibers.append(fiber)

            if self.params.useJoints.use:
                joint_points = self.count_joints(abort_check=abort_check)
                joint_count = len(joint_points)
                joint_delta = abs(joint_count - target_joint_count)
                if best_candidate is None or joint_delta < best_candidate["joint_delta"]:
                    best_candidate = {
                        "fibers": deepcopy(self.fibers),
                        "joint_points": deepcopy(joint_points),
                        "joint_delta": joint_delta,
                        "joint_count": joint_count,
                        "attempt_index": iteration + 1,
                    }
                if joint_delta <= joint_tolerance:
                    self.joint_points = joint_points
                    accepted_iteration = iteration + 1
                    break
            else:
                self.joint_points = []
                accepted_iteration = iteration + 1
                break  # No joint constraints, exit immediately
        else:
            if best_candidate is None:
                raise Exception("Failed to generate the desired number of joints.")
            self.fibers = best_candidate["fibers"]
            self.joint_points = best_candidate["joint_points"]
            accepted_iteration = best_candidate["attempt_index"]

        self.joints_dirty = not self.params.useJoints.use
        self.invalidate_render_cache()
        self.generation_metadata["joint_match_target"] = target_joint_count
        self.generation_metadata["joint_match_tolerance"] = joint_tolerance
        self.generation_metadata["joint_match_attempts"] = int(accepted_iteration or 1)
        self.generation_metadata["joint_match_realized"] = int(len(self.joint_points)) if self.params.useJoints.use else None
        self.record_timing("generate_fibers_2d_seconds", time.perf_counter() - start_time)

    def count_joints(self, abort_check=None):
        start_time = time.perf_counter()
        for fiber in self.fibers:
            fiber.has_joint = False
        joints = set()  # Use a set to store unique joint points
        for i, fiber1 in enumerate(self.fibers):
            if i % 4 == 0:
                _raise_if_aborted(abort_check)
            for fiber2 in self.fibers[i + 1:]:
                _raise_if_aborted(abort_check)
                for seg1_index, seg1 in enumerate(fiber1):
                    if seg1_index % 32 == 0:
                        _raise_if_aborted(abort_check)
                    for seg2_index, seg2 in enumerate(fiber2):
                        if seg2_index % 32 == 0:
                            _raise_if_aborted(abort_check)
                        # Check if the segments intersect
                        intersection_point = MiscUtility.get_intersection_point(seg1.start, seg1.end, seg2.start, seg2.end)
                        if intersection_point:
                            joints.add(intersection_point)
                            fiber1.has_joint = True
                            fiber2.has_joint = True

                        # Check if the end of seg1 is on seg2, even if not an intersection
                        if MiscUtility.point_on_segment(seg1.end, seg2.start, seg2.end):
                            joints.add(seg1.end)
                            fiber1.has_joint = True
                            fiber2.has_joint = True
                        if MiscUtility.point_on_segment(seg2.end, seg1.start, seg1.end):
                            joints.add(seg2.end)
                            fiber1.has_joint = True
                            fiber2.has_joint = True

        self.joints = joints  # Save the joint points for rendering
        self.record_timing("joint_count_2d_seconds", time.perf_counter() - start_time)
        return list(joints)

    def smooth(self, abort_check=None):
        start_time = time.perf_counter()
        for fiber_index, fiber in enumerate(self.fibers):
            if fiber_index % 4 == 0:
                _raise_if_aborted(abort_check)
            if self.params.bubble.use:
                fiber.bubble_smooth(self.params.bubble.get_value(), abort_check=abort_check)
            if self.params.swap.use:
                fiber.swap_smooth(self.params.swap.get_value(), abort_check=abort_check)
            if self.params.spline.use:
                fiber.spline_smooth(self.params.spline.get_value(), abort_check=abort_check)
            # Refresh orientations after any geometry change
            fiber.calculate_orientations()
        self.mark_geometry_dirty()
        self.record_timing("smooth_2d_seconds", time.perf_counter() - start_time)

    def draw_fibers(self, abort_check=None):
        self.image = self.render_base_image_2d(abort_check=abort_check)
        self._cached_final_output_2d = None

    def apply_effects(self, abort_check=None):
        self.image = self.apply_postprocessing_2d(self.image, self.params, abort_check=abort_check)
        self._cached_final_output_2d = self.image.copy()
        self.render_dirty = False

    def get_image(self):
        if self._cached_final_output_2d is None or self.render_dirty:
            start_time = time.perf_counter()
            base_image = self.render_base_image_2d()
            self._cached_final_output_2d = self.apply_postprocessing_2d(base_image, self.params)
            self.image = self._cached_final_output_2d.copy()
            self.render_dirty = False
            self.record_timing("render_postprocess_2d_seconds", time.perf_counter() - start_time)
        return self.image.copy()

    def generate_directions(self):
        mean_angle_radians = np.radians(self.params.meanAngle.get_value())        
        mean_direction = Vector(np.cos(mean_angle_radians), np.sin(mean_angle_radians))
        alignment_factor = self.params.alignment.get_value() * self.params.nFibers.get_value()
        sum_vector = mean_direction.scalar_multiply(alignment_factor)

        # Generate a random chain of vectors
        chain = RngUtility.random_chain(Vector(), sum_vector, self.params.nFibers.get_value(), 1.0)

        # Convert the chain into deltas
        directions = MiscUtility.to_deltas(chain)

        # Normalize the directions and add them to output
        output = []
        for direction in directions:
            normalized_direction = direction.normalize()
            output.append(normalized_direction)
        return output

    def find_fiber_start(self, length, direction):
        x_length = direction.normalize().x * length
        y_length = direction.normalize().y * length
        x = self.find_start(x_length, self.params.imageWidth.get_value(), self.params.imageBuffer.get_value())
        y = self.find_start(y_length, self.params.imageHeight.get_value(), self.params.imageBuffer.get_value())
        return Vector(x, y)

    @staticmethod
    def find_start(length, dimension, buffer):
        dimension = float(dimension)
        length = float(length)
        buffer = max(0.0, float(buffer))

        # Preferred case: keep the projected fiber fully inside the image while
        # respecting the requested edge buffer when possible.
        min_val = max(buffer, buffer - length)
        max_val = min(dimension - buffer - length, dimension - buffer)
        if min_val <= max_val:
            return RngUtility.next_double(min_val, max_val)

        # If the buffer makes placement impossible, relax it before giving up.
        min_val = max(0.0, -length)
        max_val = min(dimension - length, dimension)
        if min_val <= max_val:
            return RngUtility.next_double(min_val, max_val)

        # Final fallback: the projected span is larger than the image dimension.
        # Center it on the axis so the fiber is truncated symmetrically instead
        # of throwing a raw inverted-bounds error.
        return 0.5 * (dimension - length)

    def draw_scale_bar(self):
        self.image = self.draw_scale_bar_on_image(self.image, self.params)

    def add_noise(self):
        model = str(self.params.noiseModel.get_value()).lower()
        if model == "no noise":
            return
        np_image = self.add_noise_to_array(np.array(self.image, dtype=np.float32), self.params)
        self.image = Image.fromarray(np_image, 'L')

    def _apply_psf(self, volume: bool):
        if not hasattr(self.params, "psfEnabled"):
            return
        manager = PSFManager(self.params)
        if volume:
            data = self.image.astype(np.float32)
        else:
            data = np.array(self.image, dtype=np.float32)
        before_mean = float(data.mean())
        before_std = float(data.std())
        result = manager.apply(data, volume=volume)
        if result is None:
            return
        after_mean = float(result.mean())
        after_std = float(result.std())
        set_last_psf_stats({
            "volume": volume,
            "before_mean": before_mean,
            "after_mean": after_mean,
            "before_std": before_std,
            "after_std": after_std,
        })
        if volume:
            self.image = result
        else:
            self.image = Image.fromarray(result, 'L')
