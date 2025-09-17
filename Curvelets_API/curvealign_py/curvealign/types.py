"""
Type definitions for the CurveAlign Python API.

This module defines the core data structures and types used throughout
the CurveAlign API for type safety and documentation.
"""

from typing import NamedTuple, Literal, Union, List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import numpy as np
from pathlib import Path


class Curvelet(NamedTuple):
    """
    Represents a single curvelet with position, orientation, and strength.
    
    Attributes
    ----------
    center_row : int
        Row coordinate of curvelet center
    center_col : int  
        Column coordinate of curvelet center
    angle_deg : float
        Orientation angle in degrees (0-180)
    weight : float, optional
        Curvelet coefficient magnitude/strength
    """
    center_row: int
    center_col: int
    angle_deg: float
    weight: Optional[float] = None


# Curvelet coefficient structure - list of scales, each containing wedges
CtCoeffs = List[List[np.ndarray]]


class Boundary(NamedTuple):
    """
    Boundary definition for relative angle measurements.
    
    Attributes
    ----------
    kind : {"mask", "polygon", "polygons"}
        Type of boundary representation
    data : np.ndarray | Polygon | List[Polygon]
        Boundary data (binary mask, single polygon, or list of polygons)
    spacing_xy : Tuple[float, float], optional
        Physical spacing between pixels (x, y) in micrometers
    """
    kind: Literal["mask", "polygon", "polygons"]
    data: Union[np.ndarray, Any, List[Any]]  # TODO: Define Polygon type
    spacing_xy: Optional[Tuple[float, float]] = None


@dataclass
class CurveAlignOptions:
    """
    Configuration options for CurveAlign analysis.
    
    Parameters
    ----------
    keep : float, default 0.001
        Fraction of curvelet coefficients to keep
    scale : int, optional
        Specific curvelet scale to analyze
    group_radius : float, optional
        Radius for grouping nearby curvelets
    dist_thresh : float, default 100.0
        Distance threshold for boundary analysis (pixels)
    min_dist : float, optional
        Minimum distance from boundary (pixels)
    exclude_inside_mask : bool, default False
        Exclude curvelets inside boundary mask
    map_std_window : int, default 24
        Window size for angle map standard deviation filter
    map_square_window : int, default 12
        Window size for angle map square maximum filter
    map_gaussian_sigma : float, default 4.0
        Sigma for Gaussian disc filter in angle maps
    minimum_nearest_fibers : int, default 4
        Minimum number of nearest neighbors for density/alignment features
    minimum_box_size : int, default 16
        Minimum box size for local feature computation
    """
    keep: float = 0.001
    scale: Optional[int] = None
    group_radius: Optional[float] = None
    dist_thresh: float = 100.0
    min_dist: Optional[float] = None
    exclude_inside_mask: bool = False
    map_std_window: int = 24
    map_square_window: int = 12
    map_gaussian_sigma: float = 4.0
    minimum_nearest_fibers: int = 4
    minimum_box_size: int = 16
    
    def to_feature_options(self) -> 'FeatureOptions':
        """Convert to FeatureOptions."""
        return FeatureOptions(
            minimum_nearest_fibers=self.minimum_nearest_fibers,
            minimum_box_size=self.minimum_box_size
        )
    
    def to_overlay_options(self) -> 'OverlayOptions':
        """Convert to OverlayOptions."""
        return OverlayOptions()
    
    def to_map_options(self) -> 'MapOptions':
        """Convert to MapOptions."""
        return MapOptions(
            std_window=self.map_std_window,
            square_window=self.map_square_window,
            gaussian_sigma=self.map_gaussian_sigma
        )


@dataclass 
class FeatureOptions:
    """
    Options for feature computation.
    
    Parameters
    ----------
    minimum_nearest_fibers : int, default 4
        Minimum number of nearest neighbors for density/alignment
    minimum_box_size : int, default 16
        Minimum box size for local computations
    """
    minimum_nearest_fibers: int = 4
    minimum_box_size: int = 16


@dataclass
class OverlayOptions:
    """
    Options for overlay visualization.
    
    Parameters
    ----------
    colormap : str, default "hsv"
        Colormap for angle visualization
    line_width : float, default 1.0
        Width of curvelet lines
    alpha : float, default 0.7
        Transparency of overlay
    """
    colormap: str = "hsv"
    line_width: float = 1.0
    alpha: float = 0.7


@dataclass
class MapOptions:
    """
    Options for angle map generation.
    
    Parameters
    ----------
    std_window : int, default 24
        Window size for standard deviation filter
    square_window : int, default 12
        Window size for square maximum filter  
    gaussian_sigma : float, default 4.0
        Sigma for Gaussian disc filter
    """
    std_window: int = 24
    square_window: int = 12
    gaussian_sigma: float = 4.0


# Feature table - structured array or DataFrame-like structure
FeatureTable = Dict[str, np.ndarray]


@dataclass
class BoundaryMetrics:
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
    overlay : np.ndarray, optional
        Overlay visualization
    maps : Tuple[np.ndarray, np.ndarray], optional
        Raw and processed angle maps
    """
    curvelets: List[Curvelet]
    features: FeatureTable
    boundary_metrics: Optional[BoundaryMetrics]
    stats: Dict[str, float]
    overlay: Optional[np.ndarray]
    maps: Optional[Tuple[np.ndarray, np.ndarray]]


@dataclass
class ROIResult:
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
