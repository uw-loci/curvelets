"""
Result structures for CurveAlign analysis.

This module defines all result and output data structures returned
by CurveAlign analysis functions.
"""

from typing import NamedTuple, List, Dict, Optional, Tuple, Any
import numpy as np

from .core import Curvelet


# Feature table - structured array or DataFrame-like structure
FeatureTable = Dict[str, np.ndarray]


class BoundaryMetrics(NamedTuple):
    """
    Results from boundary analysis.
    
    Attributes
    ----------
    relative_angles : np.ndarray
        Relative angles between curvelets and boundary
    distances : np.ndarray
        Distances from curvelets to boundary
    inside_mask : np.ndarray
        Boolean array indicating curvelets inside boundary
    alignment_stats : Dict[str, float]
        Summary statistics for boundary alignment
    """
    relative_angles: np.ndarray
    distances: np.ndarray
    inside_mask: np.ndarray
    alignment_stats: Dict[str, float]


class AnalysisResult(NamedTuple):
    """
    Complete results from single image analysis.
    
    Attributes
    ----------
    curvelets : List[Curvelet]
        Extracted curvelets
    features : FeatureTable
        Computed features for each curvelet
    boundary_metrics : BoundaryMetrics, optional
        Boundary analysis results if boundary provided
    stats : Dict[str, float]
        Summary statistics
    """
    curvelets: List[Curvelet]
    features: FeatureTable
    boundary_metrics: Optional[BoundaryMetrics]
    stats: Dict[str, float]


class ROIResult(NamedTuple):
    """
    Results from ROI analysis.
    
    Attributes
    ----------
    roi_results : List[AnalysisResult]
        Results for each individual ROI
    comparison_stats : Dict[str, Any]
        Statistics comparing ROIs
    """
    roi_results: List[AnalysisResult]
    comparison_stats: Dict[str, Any]
