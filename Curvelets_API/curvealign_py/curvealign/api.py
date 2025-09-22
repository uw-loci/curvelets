"""
CurveAlign Python API - High-level interface for collagen fiber analysis.

This module provides the main user-facing API for CurveAlign functionality,
including image analysis, ROI processing, and batch operations.
"""

from typing import Optional, Sequence, Iterable, Tuple, List, Union, Literal
from pathlib import Path
import numpy as np

from .types import (
    Curvelet, CtCoeffs, Boundary, AnalysisResult, ROIResult, 
    CurveAlignOptions, FeatureOptions, FeatureTable, BoundaryMetrics
)
from .core import curvelets, features, boundary


def analyze_image(
    image: np.ndarray,
    boundary: Optional[Boundary] = None,
    mode: Literal["curvelets", "ctfire"] = "curvelets",
    options: Optional[CurveAlignOptions] = None,
) -> AnalysisResult:
    """
    Analyze a single image for collagen fiber organization.
    
    This is the main high-level function for single image analysis, supporting
    both curvelet-based and CT-FIRE based fiber extraction methods.
    
    Parameters
    ----------
    image : np.ndarray
        2D grayscale image to analyze
    boundary : Boundary, optional
        Boundary definition for relative angle measurements
    mode : {"curvelets", "ctfire"}, default "curvelets"
        Fiber extraction method to use
    options : CurveAlignOptions, optional
        Analysis parameters and options
        
    Returns
    -------
    AnalysisResult
        Complete analysis results including curvelets, features, stats, and visualizations
        
    Examples
    --------
    >>> import numpy as np
    >>> import curvealign
    >>> image = np.random.rand(512, 512)  # Example image
    >>> result = curvealign.analyze_image(image)
    >>> print(f"Found {len(result.curvelets)} curvelets")
    """
    if options is None:
        options = CurveAlignOptions()
    
    # Extract curvelets or use CT-FIRE
    if mode == "curvelets":
        curvelets_list, coeffs = get_curvelets(
            image, 
            keep=options.keep,
            scale=options.scale,
            group_radius=options.group_radius
        )
    elif mode == "ctfire":
        # TODO: Implement CT-FIRE integration
        raise NotImplementedError("CT-FIRE mode not yet implemented")
    else:
        raise ValueError(f"Unknown mode: {mode}")
    
    # Compute features
    features_result = compute_features(curvelets_list, options.to_feature_options())
    
    # Boundary analysis if provided
    boundary_metrics = None
    if boundary is not None:
        boundary_metrics = measure_boundary(
            curvelets_list, boundary, options.dist_thresh,
            min_dist=options.min_dist,
            exclude_inside_mask=options.exclude_inside_mask
        )
    
    # Compute summary statistics
    angles = np.array([c.angle_deg for c in curvelets_list])
    stats = {
        'mean_angle': float(np.mean(angles)),
        'std_angle': float(np.std(angles)),
        'alignment': float(np.mean(np.cos(2 * np.deg2rad(angles)))),
        'density': len(curvelets_list) / (image.shape[0] * image.shape[1]),
        'total_curvelets': len(curvelets_list)
    }
    
    return AnalysisResult(
        curvelets=curvelets_list,
        features=features_result,
        boundary_metrics=boundary_metrics,
        stats=stats
    )


def analyze_roi(
    image: np.ndarray,
    rois: Sequence[Boundary],
    options: Optional[CurveAlignOptions] = None,
) -> ROIResult:
    """
    Analyze multiple regions of interest within an image.
    
    Parameters
    ----------
    image : np.ndarray
        2D grayscale image to analyze
    rois : Sequence[Boundary]
        List of ROI definitions (polygons or masks)
    options : CurveAlignOptions, optional
        Analysis parameters and options
        
    Returns
    -------
    ROIResult
        Results for each ROI including per-ROI statistics and comparisons
    """
    if options is None:
        options = CurveAlignOptions()
    
    roi_results = []
    for i, roi in enumerate(rois):
        # Extract ROI region from image
        # TODO: Implement ROI extraction logic
        roi_image = image  # Placeholder
        
        # Analyze this ROI
        result = analyze_image(roi_image, boundary=roi, options=options)
        roi_results.append(result)
    
    # TODO: Implement ROI comparison statistics
    comparison_stats = {}
    
    return ROIResult(
        roi_results=roi_results,
        comparison_stats=comparison_stats
    )


def batch_analyze(
    inputs: Iterable[Union[Path, np.ndarray]],
    boundaries: Optional[Iterable[Optional[Boundary]]] = None,
    options: Optional[CurveAlignOptions] = None,
) -> List[AnalysisResult]:
    """
    Analyze multiple images in batch mode.
    
    Parameters
    ----------
    inputs : Iterable[Path | np.ndarray]
        Images to analyze (file paths or arrays)
    boundaries : Iterable[Boundary], optional
        Boundary definitions for each image (None for no boundary)
    options : CurveAlignOptions, optional
        Analysis parameters and options
        
    Returns
    -------
    List[AnalysisResult]
        Analysis results for each input image
    """
    if options is None:
        options = CurveAlignOptions()
    
    results = []
    boundary_iter = iter(boundaries) if boundaries else iter([None] * len(list(inputs)))
    
    for input_item in inputs:
        # Load image if path provided
        if isinstance(input_item, (str, Path)):
            # TODO: Implement image loading
            image = np.random.rand(512, 512)  # Placeholder
        else:
            image = input_item
            
        # Get corresponding boundary
        boundary = next(boundary_iter, None)
        
        # Analyze image
        result = analyze_image(image, boundary=boundary, options=options)
        results.append(result)
    
    return results


def get_curvelets(
    image: np.ndarray,
    keep: float = 0.001,
    scale: Optional[int] = None,
    group_radius: Optional[float] = None,
) -> Tuple[List[Curvelet], CtCoeffs]:
    """
    Extract curvelets from an image using the Fast Discrete Curvelet Transform.
    
    Parameters
    ----------
    image : np.ndarray
        2D grayscale image
    keep : float, default 0.001
        Fraction of curvelet coefficients to keep (threshold)
    scale : int, optional
        Specific scale to analyze (default: auto-select)
    group_radius : float, optional
        Radius for grouping nearby curvelets
        
    Returns
    -------
    Tuple[List[Curvelet], CtCoeffs]
        Extracted curvelets and coefficient structure
    """
    return curvelets.extract_curvelets(image, keep, scale, group_radius)


def reconstruct(coeffs: CtCoeffs, scales: Optional[Sequence[int]] = None) -> np.ndarray:
    """
    Reconstruct an image from curvelet coefficients.
    
    Parameters
    ----------
    coeffs : CtCoeffs
        Curvelet coefficient structure
    scales : Sequence[int], optional
        Specific scales to include in reconstruction
        
    Returns
    -------
    np.ndarray
        Reconstructed image
    """
    return curvelets.reconstruct_image(coeffs, scales)


def compute_features(
    curvelets_list: Sequence[Curvelet],
    options: Optional[FeatureOptions] = None,
) -> FeatureTable:
    """
    Compute fiber features from curvelets.
    
    Parameters
    ----------
    curvelets_list : Sequence[Curvelet]
        List of extracted curvelets
    options : FeatureOptions, optional
        Feature computation parameters
        
    Returns
    -------
    FeatureTable
        Computed features for each curvelet
    """
    return features.compute_features(curvelets_list, options)


def measure_boundary(
    curvelets_list: Sequence[Curvelet],
    boundary: Boundary,
    dist_thresh: float,
    min_dist: Optional[float] = None,
    exclude_inside_mask: bool = False,
) -> BoundaryMetrics:
    """
    Measure curvelet alignment relative to a boundary.
    
    Parameters
    ----------
    curvelets_list : Sequence[Curvelet]
        List of extracted curvelets
    boundary : Boundary
        Boundary definition (polygon or mask)
    dist_thresh : float
        Distance threshold for boundary analysis
    min_dist : float, optional
        Minimum distance from boundary
    exclude_inside_mask : bool, default False
        Whether to exclude curvelets inside boundary mask
        
    Returns
    -------
    BoundaryMetrics
        Boundary analysis results
    """
    return boundary.measure_boundary_alignment(
        curvelets_list, boundary, dist_thresh, min_dist, exclude_inside_mask
    )


def overlay(
    image: np.ndarray,
    curvelets_list: Sequence[Curvelet],
    mask: Optional[np.ndarray] = None,
    backend: str = "standalone",
    **kwargs
) -> np.ndarray:
    """
    Create an overlay image showing curvelets on the original image.
    
    Parameters
    ----------
    image : np.ndarray
        Original image
    curvelets_list : Sequence[Curvelet]
        List of curvelets to overlay
    mask : np.ndarray, optional
        Optional mask to apply
    backend : str, default "standalone"
        Visualization backend ("standalone", "napari", "pyimagej")
    **kwargs
        Additional parameters for the visualization backend
        
    Returns
    -------
    np.ndarray
        Overlay image (backend-dependent format)
        
    Notes
    -----
    This is a convenience function. For more control, use visualization
    package directly: from curvealign.visualization import standalone
    """
    if backend == "standalone":
        try:
            from .visualization.standalone import create_overlay
            return create_overlay(image, curvelets_list, mask, **kwargs)
        except ImportError:
            raise ImportError("Matplotlib not available for standalone visualization")
    else:
        raise ValueError(f"Backend '{backend}' not supported by overlay function. "
                        f"Use visualization package directly for {backend}.")


def angle_map(
    image: np.ndarray,
    curvelets_list: Sequence[Curvelet],
    backend: str = "standalone",
    **kwargs
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Create angle maps showing spatial distribution of fiber orientations.
    
    Parameters
    ----------
    image : np.ndarray
        Original image
    curvelets_list : Sequence[Curvelet]
        List of curvelets
    backend : str, default "standalone"
        Visualization backend
    **kwargs
        Additional parameters for the visualization backend
        
    Returns
    -------
    Tuple[np.ndarray, np.ndarray]
        Raw and processed angle maps
        
    Notes
    -----
    This is a convenience function. For more control, use visualization
    package directly: from curvealign.visualization import standalone
    """
    if backend == "standalone":
        try:
            from .visualization.standalone import create_angle_maps
            return create_angle_maps(image, curvelets_list, **kwargs)
        except ImportError:
            raise ImportError("Matplotlib not available for standalone visualization")
    else:
        raise ValueError(f"Backend '{backend}' not supported by angle_map function.")
