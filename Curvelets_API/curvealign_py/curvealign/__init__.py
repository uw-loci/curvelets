"""
CurveAlign Python API for collagen fiber analysis.

This package provides a Python interface for analyzing collagen fiber organization
in microscopy images using curvelet transforms and related techniques.

Main Functions
--------------
analyze_image : Analyze a single image for fiber organization
analyze_roi : Analyze multiple regions of interest  
batch_analyze : Analyze multiple images in batch mode
get_curvelets : Extract curvelets using FDCT
reconstruct : Reconstruct image from curvelet coefficients
compute_features : Compute fiber features from curvelets
measure_boundary : Measure alignment relative to boundaries
overlay : Create visualization overlays
angle_map : Create spatial angle maps

Examples
--------
>>> import curvealign
>>> import numpy as np
>>> image = np.random.rand(512, 512)
>>> result = curvealign.analyze_image(image)
>>> print(f"Found {len(result.curvelets)} curvelets")
"""

from .api import (
    analyze_image,
    analyze_roi,
    batch_analyze,
    get_curvelets,
    reconstruct,
    compute_features,
    measure_boundary,
    overlay,
    angle_map,
)

from .types import (
    Curvelet,
    Boundary,
    CurveAlignOptions,
    FeatureOptions,
    AnalysisResult,
    ROIResult,
    BoundaryMetrics,
    FeatureTable,
)

__version__ = "0.1.0"

__all__ = [
    # Main API functions
    "analyze_image", "analyze_roi", "batch_analyze", "get_curvelets", "reconstruct",
    "compute_features", "measure_boundary", "overlay", "angle_map",
    # Types and data structures
    "Curvelet", "Boundary", "CurveAlignOptions", "FeatureOptions",
    "AnalysisResult", "ROIResult", "BoundaryMetrics", "FeatureTable",
]
