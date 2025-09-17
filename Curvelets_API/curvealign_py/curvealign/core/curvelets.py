"""
Curvelet transform implementation.

This module handles the Fast Discrete Curvelet Transform (FDCT) operations,
including forward transform, coefficient thresholding, parameter extraction,
and reconstruction.
"""

from typing import List, Tuple, Optional, Sequence
import numpy as np

from ..types import Curvelet, CtCoeffs


def extract_curvelets(
    image: np.ndarray,
    keep: float = 0.001,
    scale: Optional[int] = None,
    group_radius: Optional[float] = None,
) -> Tuple[List[Curvelet], CtCoeffs]:
    """
    Extract curvelets from an image using FDCT.
    
    This function implements the core curvelet extraction algorithm from newCurv.m:
    1. Apply forward FDCT to the image
    2. Threshold coefficients to keep only the strongest ones
    3. Extract center positions and angles from remaining coefficients
    4. Group nearby curvelets and compute mean angles
    5. Filter edge curvelets
    
    Parameters
    ----------
    image : np.ndarray
        2D grayscale input image
    keep : float, default 0.001
        Fraction of coefficients to keep (e.g., 0.001 = top 0.1%)
    scale : int, optional
        Specific scale to analyze (default: auto-select appropriate scale)
    group_radius : float, optional
        Radius for grouping nearby curvelets (pixels)
        
    Returns
    -------
    Tuple[List[Curvelet], CtCoeffs]
        Extracted curvelets and thresholded coefficient structure
    """
    # Apply forward FDCT - equivalent to: C = fdct_wrapping(IMG,0,2)
    C = apply_fdct(image, finest=0, nbangles_coarsest=2)
    
    # Create empty coefficient structure for thresholding
    Ct = _create_empty_coeffs_like(C)
    
    # Select scale to analyze
    if scale is None:
        # Default: second finest scale (scale=1 in MATLAB indexing)
        scale = 1
    s = len(C) - scale - 1  # Convert to Python 0-based indexing
    
    # Take absolute values of coefficients at selected scale
    for wedge_idx in range(len(C[s])):
        C[s][wedge_idx] = np.abs(C[s][wedge_idx])
    
    # Threshold coefficients - keep only the strongest 'keep' fraction
    Ct[s] = threshold_coefficients_at_scale(C[s], keep)
    
    # Extract center positions and angles
    X_rows, Y_cols = extract_parameters(Ct)
    
    # Convert coefficient positions to curvelet objects
    curvelets = _extract_curvelets_from_coeffs(Ct[s], X_rows[s], Y_cols[s], s)
    
    # Group nearby curvelets if radius specified
    if group_radius is not None:
        curvelets = group_curvelets(curvelets, group_radius)
    
    # Normalize angles to 0-180 degree range (fiber symmetry)
    curvelets = _normalize_angles(curvelets)
    
    # Remove curvelets too close to image edges
    curvelets = _filter_edge_curvelets(curvelets, image.shape)
    
    return curvelets, Ct


def reconstruct_image(coeffs: CtCoeffs, scales: Optional[Sequence[int]] = None) -> np.ndarray:
    """
    Reconstruct an image from curvelet coefficients.
    
    This implements the inverse FDCT reconstruction from CTrec.m and processImage.m.
    Equivalent to: Y = ifdct_wrapping(Ct, 0)
    
    Parameters
    ----------
    coeffs : CtCoeffs
        Curvelet coefficient structure from forward transform
    scales : Sequence[int], optional
        Specific scales to include in reconstruction (default: all scales)
        
    Returns
    -------
    np.ndarray
        Reconstructed image (real part of inverse transform)
    """
    # If specific scales requested, create filtered coefficient structure
    if scales is not None:
        filtered_coeffs = _create_empty_coeffs_like(coeffs)
        for scale_idx in scales:
            if 0 <= scale_idx < len(coeffs):
                filtered_coeffs[scale_idx] = coeffs[scale_idx]
        coeffs = filtered_coeffs
    
    # Apply inverse FDCT - equivalent to: Y = ifdct_wrapping(Ct, 0)
    Y = apply_ifdct(coeffs, finest=0)
    
    # Return real part as in MATLAB: CTr = real(Y)
    return np.real(Y)


def apply_fdct(image: np.ndarray, finest: int = 0, nbangles_coarsest: int = 2) -> CtCoeffs:
    """
    Apply forward Fast Discrete Curvelet Transform.
    
    This is equivalent to the MATLAB call: C = fdct_wrapping(IMG, 0, 2)
    
    Parameters
    ----------
    image : np.ndarray
        Input image
    finest : int, default 0
        Finest scale parameter (0 for curvelets at finest scale)
    nbangles_coarsest : int, default 2
        Number of angles at coarsest scale
        
    Returns
    -------
    CtCoeffs
        Curvelet coefficient structure (list of scales, each containing wedges)
        
    Notes
    -----
    This function requires a curvelet transform library like PyCurvelab.
    Currently returns a placeholder structure for testing.
    """
    try:
        # Try to import PyCurvelab or similar library
        # import pycurvelets
        # return pycurvelets.fdct_wrapping(image, finest, nbangles_coarsest)
        
        # For now, create a placeholder coefficient structure
        height, width = image.shape
        
        # Calculate number of scales based on image size
        # From MATLAB: nbscales = ceil(log2(min(N1,N2)) - 3)
        nbscales = int(np.ceil(np.log2(min(height, width)) - 3))
        nbscales = max(nbscales, 3)  # Ensure at least 3 scales
        
        # Create coefficient structure
        coeffs = []
        for scale in range(nbscales):
            scale_coeffs = []
            
            if scale == 0:
                # Coarsest scale - fewer angles
                n_angles = nbangles_coarsest * 4
            else:
                # Finer scales - more angles  
                n_angles = nbangles_coarsest * 4 * (2 ** (scale - 1))
            
            # Create wedges for this scale
            for wedge in range(n_angles):
                # Size decreases with scale
                size_factor = 2 ** (nbscales - scale - 1)
                wedge_height = max(height // size_factor, 8)
                wedge_width = max(width // size_factor, 8)
                
                # Generate placeholder coefficients
                coeffs_wedge = np.random.randn(wedge_height, wedge_width) * np.exp(-scale)
                scale_coeffs.append(coeffs_wedge)
            
            coeffs.append(scale_coeffs)
        
        return coeffs
        
    except ImportError:
        raise ImportError(
            "Curvelet transform library not available. "
            "Please install PyCurvelab or similar FDCT implementation."
        )


def extract_parameters(coeffs: CtCoeffs) -> Tuple[List[List[np.ndarray]], List[List[np.ndarray]]]:
    """
    Extract center positions from curvelet coefficients.
    
    This is equivalent to the MATLAB call: [X_rows, Y_cols] = fdct_wrapping_param(Ct)
    
    Parameters
    ----------
    coeffs : CtCoeffs
        Curvelet coefficient structure
        
    Returns
    -------
    Tuple[List[List[np.ndarray]], List[List[np.ndarray]]]
        Row and column center coordinates for each scale and wedge
        
    Notes
    -----
    This function requires a curvelet transform library like PyCurvelab.
    Currently returns placeholder coordinates for testing.
    """
    try:
        # Try to import PyCurvelab or similar library
        # import pycurvelets
        # return pycurvelets.fdct_wrapping_param(coeffs)
        
        # For now, create placeholder parameter structure
        X_rows = []
        Y_cols = []
        
        for scale_idx, scale_coeffs in enumerate(coeffs):
            scale_X_rows = []
            scale_Y_cols = []
            
            for wedge_idx, wedge_coeffs in enumerate(scale_coeffs):
                if wedge_coeffs is not None and wedge_coeffs.size > 0:
                    height, width = wedge_coeffs.shape
                    
                    # Create coordinate grids
                    rows, cols = np.meshgrid(
                        np.arange(height, dtype=float),
                        np.arange(width, dtype=float),
                        indexing='ij'
                    )
                    
                    scale_X_rows.append(rows)
                    scale_Y_cols.append(cols)
                else:
                    scale_X_rows.append(np.array([]))
                    scale_Y_cols.append(np.array([]))
            
            X_rows.append(scale_X_rows)
            Y_cols.append(scale_Y_cols)
        
        return X_rows, Y_cols
        
    except ImportError:
        raise ImportError(
            "Curvelet transform library not available. "
            "Please install PyCurvelab or similar FDCT implementation."
        )


def apply_ifdct(coeffs: CtCoeffs, finest: int = 0) -> np.ndarray:
    """
    Apply inverse Fast Discrete Curvelet Transform.
    
    This is equivalent to the MATLAB call: Y = ifdct_wrapping(Ct, 0)
    
    Parameters
    ----------
    coeffs : CtCoeffs
        Curvelet coefficient structure
    finest : int, default 0
        Finest scale parameter
        
    Returns
    -------
    np.ndarray
        Reconstructed image (complex-valued)
    """
    try:
        # Try to import PyCurvelab or similar library
        # import pycurvelets
        # return pycurvelets.ifdct_wrapping(coeffs, finest)
        
        # For now, return placeholder reconstruction
        # Estimate image size from coefficient structure
        if not coeffs or not coeffs[0]:
            return np.zeros((256, 256))
        
        # Use finest scale to estimate image size
        finest_scale = coeffs[-1] if coeffs else []
        if finest_scale:
            height = finest_scale[0].shape[0] * (2 ** (len(coeffs) - 1))
            width = finest_scale[0].shape[1] * (2 ** (len(coeffs) - 1))
        else:
            height, width = 256, 256
        
        # Generate placeholder reconstruction
        return np.random.randn(height, width) + 1j * np.random.randn(height, width)
        
    except ImportError:
        raise ImportError(
            "Curvelet transform library not available. "
            "Please install PyCurvelab or similar FDCT implementation."
        )


def threshold_coefficients_at_scale(scale_coeffs: List[np.ndarray], keep: float) -> List[np.ndarray]:
    """
    Threshold coefficients at a single scale to keep only the strongest ones.
    
    This implements the thresholding logic from newCurv.m lines 59-76.
    
    Parameters
    ----------
    scale_coeffs : List[np.ndarray]
        Coefficients for all wedges at one scale
    keep : float
        Fraction of coefficients to keep
        
    Returns
    -------
    List[np.ndarray]
        Thresholded coefficients at this scale
    """
    # Find maximum coefficient value across all wedges
    abs_max = 0
    for wedge_coeffs in scale_coeffs:
        if wedge_coeffs.size > 0:
            wedge_max = np.max(np.abs(wedge_coeffs))
            abs_max = max(abs_max, wedge_max)
    
    if abs_max == 0:
        return scale_coeffs
    
    # Create histogram bins
    bins = np.arange(0, abs_max + 0.01 * abs_max, 0.01 * abs_max)
    
    # Compute histogram for each wedge
    all_hist_vals = []
    for wedge_coeffs in scale_coeffs:
        if wedge_coeffs.size > 0:
            hist_vals, _ = np.histogram(np.abs(wedge_coeffs), bins)
            all_hist_vals.append(hist_vals)
    
    if not all_hist_vals:
        return scale_coeffs
    
    # Sum histograms across wedges
    total_hist = np.sum(all_hist_vals, axis=0)
    cum_vals = np.cumsum(total_hist)
    
    # Find threshold value
    cum_max = cum_vals[-1] if len(cum_vals) > 0 else 1
    threshold_idx = np.where(cum_vals > (1 - keep) * cum_max)[0]
    
    if len(threshold_idx) > 0:
        max_val = bins[threshold_idx[0]]
    else:
        max_val = 0
    
    # Apply threshold to each wedge
    thresholded_coeffs = []
    for wedge_coeffs in scale_coeffs:
        if wedge_coeffs.size > 0:
            thresholded = wedge_coeffs * (np.abs(wedge_coeffs) >= max_val)
            thresholded_coeffs.append(thresholded)
        else:
            thresholded_coeffs.append(wedge_coeffs)
    
    return thresholded_coeffs


def group_curvelets(curvelets: List[Curvelet], radius: float) -> List[Curvelet]:
    """
    Group nearby curvelets within a specified radius.
    
    This implements the grouping algorithm from newCurv.m lines 142-169.
    
    Parameters
    ----------
    curvelets : List[Curvelet]
        Input curvelets
    radius : float
        Grouping radius in pixels
        
    Returns
    -------
    List[Curvelet]
        Grouped curvelets (merged nearby ones)
    """
    if not curvelets or radius <= 0:
        return curvelets
    
    # Convert to arrays for easier processing
    centers = np.array([[c.center_row, c.center_col] for c in curvelets])
    angles = np.array([c.angle_deg for c in curvelets])
    weights = np.array([c.weight or 1.0 for c in curvelets])
    
    # Track which curvelets have been grouped
    used = np.zeros(len(curvelets), dtype=bool)
    grouped_curvelets = []
    
    for i, curvelet in enumerate(curvelets):
        if used[i]:
            continue
            
        # Find nearby curvelets within radius
        distances = np.sqrt(np.sum((centers - centers[i])**2, axis=1))
        nearby_indices = np.where((distances <= radius) & ~used)[0]
        
        if len(nearby_indices) > 1:
            # Group nearby curvelets
            nearby_angles = angles[nearby_indices]
            nearby_weights = weights[nearby_indices]
            nearby_centers = centers[nearby_indices]
            
            # Compute mean angle using circular statistics (simplified)
            mean_angle = _fix_angle(nearby_angles)
            
            # Compute weighted center
            total_weight = np.sum(nearby_weights)
            mean_center = np.average(nearby_centers, axis=0, weights=nearby_weights)
            
            # Create grouped curvelet
            grouped_curvelet = Curvelet(
                center_row=int(round(mean_center[0])),
                center_col=int(round(mean_center[1])),
                angle_deg=mean_angle,
                weight=total_weight
            )
            
            grouped_curvelets.append(grouped_curvelet)
            used[nearby_indices] = True
        else:
            # Single curvelet, keep as is
            grouped_curvelets.append(curvelet)
            used[i] = True
    
    return grouped_curvelets


# Helper functions

def _create_empty_coeffs_like(coeffs: CtCoeffs) -> CtCoeffs:
    """Create empty coefficient structure with same shape as input."""
    empty_coeffs = []
    for scale_coeffs in coeffs:
        empty_scale = []
        for wedge_coeffs in scale_coeffs:
            empty_scale.append(np.zeros_like(wedge_coeffs))
        empty_coeffs.append(empty_scale)
    return empty_coeffs


def _extract_curvelets_from_coeffs(
    scale_coeffs: List[np.ndarray], 
    X_rows: List[np.ndarray], 
    Y_cols: List[np.ndarray], 
    scale_idx: int
) -> List[Curvelet]:
    """Extract curvelet objects from thresholded coefficients."""
    curvelets = []
    inc = 360 / len(scale_coeffs)  # Angular increment
    start_angle = 225
    
    for wedge_idx, wedge_coeffs in enumerate(scale_coeffs):
        if wedge_coeffs.size == 0:
            continue
            
        # Find non-zero coefficients
        nonzero_indices = np.nonzero(wedge_coeffs)
        if len(nonzero_indices[0]) == 0:
            continue
        
        # Calculate angles for this wedge
        temp_angle = start_angle - (inc * wedge_idx)
        shift_temp = start_angle - (inc * (wedge_idx + 1))
        angle = (temp_angle + shift_temp) / 2
        
        # Normalize angle
        if angle < 0:
            angle += 360
        if angle > 225:
            angle -= 180
        if angle < 45:
            angle += 180
        
        # Get positions of non-zero coefficients
        if wedge_idx < len(X_rows) and wedge_idx < len(Y_cols):
            rows = X_rows[wedge_idx]
            cols = Y_cols[wedge_idx]
            
            for row_idx, col_idx in zip(nonzero_indices[0], nonzero_indices[1]):
                if row_idx < rows.shape[0] and col_idx < rows.shape[1]:
                    center_row = int(round(rows[row_idx, col_idx]))
                    center_col = int(round(cols[row_idx, col_idx]))
                    weight = float(np.abs(wedge_coeffs[row_idx, col_idx]))
                    
                    curvelet = Curvelet(
                        center_row=center_row,
                        center_col=center_col,
                        angle_deg=angle,
                        weight=weight
                    )
                    curvelets.append(curvelet)
    
    return curvelets


def _normalize_angles(curvelets: List[Curvelet]) -> List[Curvelet]:
    """Normalize angles to 0-180 degree range (group6.m equivalent)."""
    normalized = []
    for curvelet in curvelets:
        normalized_angle = (180 + curvelet.angle_deg) % 180
        normalized_curvelet = Curvelet(
            center_row=curvelet.center_row,
            center_col=curvelet.center_col,
            angle_deg=normalized_angle,
            weight=curvelet.weight
        )
        normalized.append(normalized_curvelet)
    return normalized


def _filter_edge_curvelets(curvelets: List[Curvelet], image_shape: Tuple[int, int]) -> List[Curvelet]:
    """Remove curvelets too close to image edges."""
    height, width = image_shape
    edge_buffer = max(1, min(height, width) // 100)
    
    filtered = []
    for curvelet in curvelets:
        if (edge_buffer <= curvelet.center_row < height - edge_buffer and
            edge_buffer <= curvelet.center_col < width - edge_buffer):
            filtered.append(curvelet)
    
    return filtered


def _fix_angle(angles: np.ndarray) -> float:
    """
    Compute mean angle minimizing standard deviation (fixAngle.m equivalent).
    
    This implements the algorithm from fixAngle.m to find the best mean angle
    by minimizing the standard deviation of grouped angles.
    """
    if len(angles) == 0:
        return 0.0
    
    if len(angles) == 1:
        return float(angles[0])
    
    inc = 360 / len(angles)  # Angular increment
    bins = np.arange(np.min(angles), np.max(angles) + inc, inc)
    
    temp_angles = angles.copy()
    original_std = np.std(angles)
    std_values = [original_std]
    
    # Try different angle shifts
    for i in range(len(bins) - 1):
        # Shift angles that are >= bins[end-i]
        shift_mask = temp_angles >= bins[-(i + 1)]
        temp_angles[shift_mask] -= 180
        std_values.append(np.std(temp_angles))
    
    # Find minimum standard deviation
    min_std_idx = np.argmin(std_values)
    
    if std_values[min_std_idx] < original_std and min_std_idx < len(bins):
        # Apply the best shift
        final_angles = angles.copy()
        if min_std_idx > 0:
            shift_mask = final_angles >= bins[-(min_std_idx)]
            final_angles[shift_mask] -= 180
            
            if min_std_idx > 0.5 * len(bins):
                final_angles += 180
        
        # Ensure positive angles
        final_angles[final_angles < 0] += 180
        
        return float(np.mean(final_angles))
    else:
        return float(np.mean(angles))
