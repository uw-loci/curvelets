"""
Visualization utilities for CurveAlign results.

This module implements visualization functions for creating overlays,
angle maps, and other graphical representations of curvelet analysis results.
"""

from typing import Sequence, Optional, Tuple
import numpy as np
from scipy import ndimage

from ..types import Curvelet, OverlayOptions, MapOptions


def create_overlay(
    image: np.ndarray,
    curvelets: Sequence[Curvelet],
    mask: Optional[np.ndarray] = None,
    options: Optional[OverlayOptions] = None,
) -> np.ndarray:
    """
    Create an overlay image showing curvelets ONLY on detected fiber regions.
    
    This implements proper overlay generation that only highlights actual
    detected fiber structures, not the entire image.
    
    Parameters
    ----------
    image : np.ndarray
        Original grayscale image
    curvelets : Sequence[Curvelet]
        List of curvelets to overlay
    mask : np.ndarray, optional
        Optional mask to apply to the overlay
    options : OverlayOptions, optional
        Visualization parameters
        
    Returns
    -------
    np.ndarray
        RGB overlay image with curvelets drawn ONLY where fibers are detected
    """
    if options is None:
        options = OverlayOptions()
    
    height, width = image.shape
    
    # Start with original grayscale image as RGB background
    if image.dtype != np.float32 and image.dtype != np.float64:
        image_normalized = image.astype(np.float32) / 255.0 if image.max() > 1 else image.astype(np.float32)
    else:
        image_normalized = image.astype(np.float32)
        if image_normalized.max() > 1:
            image_normalized = image_normalized / image_normalized.max()
    
    # Create RGB background
    background_rgb = np.stack([image_normalized, image_normalized, image_normalized], axis=2)
    
    if not curvelets:
        return (background_rgb * 255).astype(np.uint8)
    
    # Create fiber overlay that ONLY covers detected fiber regions
    fiber_overlay = np.zeros((height, width, 3), dtype=np.float32)
    
    for curvelet in curvelets:
        # Draw thick colored line only where fiber is detected
        _draw_thick_curvelet_line(
            fiber_overlay,
            curvelet,
            line_width=int(options.line_width * 2),  # Thicker for better visibility
            colormap=options.colormap
        )
    
    # Apply mask if provided
    if mask is not None:
        mask_3d = np.stack([mask, mask, mask], axis=2).astype(bool)
        fiber_overlay = fiber_overlay * mask_3d
    
    # Create final overlay: show original image with colored fibers ONLY where detected
    fiber_mask = np.any(fiber_overlay > 0, axis=2)
    
    final_overlay = background_rgb.copy()
    # Only blend where we have detected fibers
    alpha = options.alpha
    final_overlay[fiber_mask] = (1 - alpha) * background_rgb[fiber_mask] + alpha * fiber_overlay[fiber_mask]
    
    return (np.clip(final_overlay, 0, 1) * 255).astype(np.uint8)


def create_angle_maps(
    image: np.ndarray,
    curvelets: Sequence[Curvelet],
    options: Optional[MapOptions] = None,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Create raw and processed angle maps showing spatial fiber orientation.
    
    This implements the angle map generation from drawMap.m and draw_CAmap.m,
    creating both raw angle assignments and filtered/processed maps.
    
    Parameters
    ----------
    image : np.ndarray
        Original image
    curvelets : Sequence[Curvelet]
        List of curvelets
    options : MapOptions, optional
        Map generation parameters
        
    Returns
    -------
    Tuple[np.ndarray, np.ndarray]
        Raw angle map and processed angle map
    """
    if options is None:
        options = MapOptions()
    
    height, width = image.shape
    
    # Create raw angle map
    raw_map = np.full((height, width), np.nan)
    
    for curvelet in curvelets:
        row, col = int(curvelet.center_row), int(curvelet.center_col)
        if 0 <= row < height and 0 <= col < width:
            raw_map[row, col] = curvelet.angle_deg
    
    # Create processed map with spatial filtering
    processed_map = _process_angle_map(raw_map, options)
    
    return raw_map, processed_map


def _draw_thick_curvelet_line(
    overlay: np.ndarray,
    curvelet: Curvelet,
    line_width: int,
    colormap: str,
) -> None:
    """
    Draw a thick curvelet line on the overlay image.
    
    Parameters
    ----------
    overlay : np.ndarray
        RGB overlay image to draw on (modified in place)
    curvelet : Curvelet
        Curvelet to draw
    line_width : int
        Width of the line
    colormap : str
        Colormap name for angle-based coloring
    """
    height, width = overlay.shape[:2]
    
    # Get curvelet properties
    center_row, center_col = curvelet.center_row, curvelet.center_col
    angle_deg = curvelet.angle_deg
    
    # Convert angle to color
    color = _angle_to_color(angle_deg, colormap)
    color_normalized = np.array(color) / 255.0  # Normalize to 0-1
    
    # Calculate line endpoints
    line_length = 15  # pixels
    angle_rad = np.deg2rad(angle_deg)
    
    dx = line_length * np.cos(angle_rad) / 2
    dy = line_length * np.sin(angle_rad) / 2
    
    x1 = int(center_col - dx)
    y1 = int(center_row - dy)
    x2 = int(center_col + dx)
    y2 = int(center_row + dy)
    
    # Draw thick line
    line_points = _get_thick_line_points(x1, y1, x2, y2, line_width)
    
    for x, y in line_points:
        if 0 <= y < height and 0 <= x < width:
            overlay[y, x] = color_normalized


def _draw_curvelet_line(
    overlay: np.ndarray,
    curvelet: Curvelet,
    line_width: float,
    colormap: str,
) -> None:
    """
    Draw a single curvelet as a colored line on the overlay image.
    
    Parameters
    ----------
    overlay : np.ndarray
        RGB overlay image to draw on (modified in place)
    curvelet : Curvelet
        Curvelet to draw
    line_width : float
        Width of the line
    colormap : str
        Colormap name for angle-based coloring
    """
    height, width = overlay.shape[:2]
    
    # Get curvelet properties
    center_row, center_col = curvelet.center_row, curvelet.center_col
    angle_deg = curvelet.angle_deg
    
    # Convert angle to color
    color = _angle_to_color(angle_deg, colormap)
    
    # Calculate line endpoints
    line_length = 10  # pixels
    angle_rad = np.deg2rad(angle_deg)
    
    dx = line_length * np.cos(angle_rad) / 2
    dy = line_length * np.sin(angle_rad) / 2
    
    x1 = int(center_col - dx)
    y1 = int(center_row - dy)
    x2 = int(center_col + dx)
    y2 = int(center_row + dy)
    
    # Draw line using Bresenham's algorithm
    points = _bresenham_line(x1, y1, x2, y2)
    
    for x, y in points:
        if 0 <= y < height and 0 <= x < width:
            overlay[y, x] = color


def _angle_to_color(angle_deg: float, colormap: str) -> Tuple[int, int, int]:
    """
    Convert an angle to RGB color based on colormap.
    
    Parameters
    ----------
    angle_deg : float
        Angle in degrees (0-180)
    colormap : str
        Colormap name
        
    Returns
    -------
    Tuple[int, int, int]
        RGB color values (0-255)
    """
    # Normalize angle to 0-1 range
    normalized = (angle_deg % 180) / 180
    
    if colormap == "hsv":
        # HSV colormap: map angle to hue
        import colorsys
        rgb = colorsys.hsv_to_rgb(normalized, 1.0, 1.0)
        return tuple(int(c * 255) for c in rgb)
    elif colormap == "jet":
        # Simple jet-like colormap
        if normalized < 0.25:
            r, g, b = 0, int(normalized * 4 * 255), 255
        elif normalized < 0.5:
            r, g, b = 0, 255, int((0.5 - normalized) * 4 * 255)
        elif normalized < 0.75:
            r, g, b = int((normalized - 0.5) * 4 * 255), 255, 0
        else:
            r, g, b = 255, int((1.0 - normalized) * 4 * 255), 0
        return r, g, b
    else:
        # Default: grayscale
        gray = int(normalized * 255)
        return gray, gray, gray


def _get_thick_line_points(x1: int, y1: int, x2: int, y2: int, thickness: int) -> list:
    """
    Generate points for a thick line.
    
    Parameters
    ----------
    x1, y1 : int
        Starting point
    x2, y2 : int
        Ending point
    thickness : int
        Line thickness
        
    Returns
    -------
    List[Tuple[int, int]]
        Points for the thick line
    """
    points = []
    
    # Get base line points
    line_points = _bresenham_line(x1, y1, x2, y2)
    
    # Add thickness around each point
    for x, y in line_points:
        for dx in range(-thickness//2, thickness//2 + 1):
            for dy in range(-thickness//2, thickness//2 + 1):
                if dx*dx + dy*dy <= (thickness//2)**2:  # Circular thickness
                    points.append((x + dx, y + dy))
    
    return list(set(points))  # Remove duplicates


def _bresenham_line(x0: int, y0: int, x1: int, y1: int) -> list:
    """
    Generate points along a line using Bresenham's algorithm.
    
    Parameters
    ----------
    x0, y0 : int
        Starting point
    x1, y1 : int
        Ending point
        
    Returns
    -------
    List[Tuple[int, int]]
        Points along the line
    """
    points = []
    
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    
    x, y = x0, y0
    
    while True:
        points.append((x, y))
        
        if x == x1 and y == y1:
            break
            
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy
    
    return points


def _process_angle_map(raw_map: np.ndarray, options: MapOptions) -> np.ndarray:
    """
    Apply spatial filtering to create processed angle map.
    
    This implements the filtering pipeline from drawMap.m including
    standard deviation filtering, square maximum filtering, and Gaussian smoothing.
    
    Parameters
    ----------
    raw_map : np.ndarray
        Raw angle map with NaN for empty pixels
    options : MapOptions
        Processing parameters
        
    Returns
    -------
    np.ndarray
        Processed angle map
    """
    # Start with raw map
    processed = raw_map.copy()
    
    # Fill NaN values with interpolation or leave as NaN
    # For now, just leave NaN values as is
    
    # Apply standard deviation filter
    if options.std_window > 0:
        processed = _apply_std_filter(processed, options.std_window)
    
    # Apply square maximum filter
    if options.square_window > 0:
        processed = _apply_square_max_filter(processed, options.square_window)
    
    # Apply Gaussian smoothing
    if options.gaussian_sigma > 0:
        processed = _apply_gaussian_filter(processed, options.gaussian_sigma)
    
    return processed


def _apply_std_filter(image: np.ndarray, window_size: int) -> np.ndarray:
    """Apply standard deviation filter to angle map."""
    # TODO: Implement proper standard deviation filtering
    # For now, just return the input
    return image


def _apply_square_max_filter(image: np.ndarray, window_size: int) -> np.ndarray:
    """Apply square maximum filter to angle map."""
    # Use scipy's maximum filter
    return ndimage.maximum_filter(image, size=window_size)


def _apply_gaussian_filter(image: np.ndarray, sigma: float) -> np.ndarray:
    """Apply Gaussian filter to angle map."""
    # Handle NaN values
    mask = ~np.isnan(image)
    if not np.any(mask):
        return image
    
    # Apply Gaussian filter only to valid pixels
    filtered = image.copy()
    valid_data = np.where(mask, image, 0)
    
    # Apply filter
    filtered_data = ndimage.gaussian_filter(valid_data, sigma=sigma)
    filtered_mask = ndimage.gaussian_filter(mask.astype(float), sigma=sigma)
    
    # Normalize by the filtered mask to handle NaN regions properly
    with np.errstate(divide='ignore', invalid='ignore'):
        filtered = np.where(filtered_mask > 0, filtered_data / filtered_mask, np.nan)
    
    return filtered
