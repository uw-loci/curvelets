"""
Type definitions for the CurveAlign Python API.

This package contains all type definitions organized by functional area:
- Core data structures (curvelets, boundaries, coefficients)
- Configuration options (analysis parameters)
- Result structures (analysis outputs)
"""

from .core import Curvelet, CtCoeffs, Boundary
from .options import CurveAlignOptions, FeatureOptions
from .results import AnalysisResult, ROIResult, BoundaryMetrics, FeatureTable

__all__ = [
    # Core data structures
    "Curvelet", "CtCoeffs", "Boundary",
    # Configuration options
    "CurveAlignOptions", "FeatureOptions", 
    # Result structures
    "AnalysisResult", "ROIResult", "BoundaryMetrics", "FeatureTable",
]
