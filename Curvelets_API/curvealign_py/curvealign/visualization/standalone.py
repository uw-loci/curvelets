"""
Standalone matplotlib-based visualization for CurveAlign results.

This module provides basic visualization capabilities using matplotlib,
serving as the default visualization backend when other frameworks
(napari, ImageJ) are not available.
"""

from typing import Sequence, Optional, Tuple
import numpy as np
from scipy import ndimage

from ..types import Curvelet


def create_overlay(
    image: np.ndarray,
    curvelets: Sequence[Curvelet],
    mask: Optional[np.ndarray] = None,
    colormap: str = "hsv",
    line_width: float = 2.0,
    alpha: float = 0.7,
) -> np.ndarray:
    """
    Create an overlay image showing curvelets on detected fiber regions.
    
    Parameters
    ----------
    image : np.ndarray
        Original grayscale image
    curvelets : Sequence[Curvelet]
        List of curvelets to overlay
    mask : np.ndarray, optional
        Optional mask to apply to the overlay
    colormap : str, default "hsv"
        Colormap for angle visualization
    line_width : float, default 2.0
        Width of curvelet lines
    alpha : float, default 0.7
        Transparency of overlay
        
    Returns
    -------
    np.ndarray
        RGB overlay image with curvelets drawn only where fibers are detected
    """
    height, width = image.shape
    
    # Normalize image
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
    
    # Create fiber overlay
    fiber_overlay = np.zeros((height, width, 3), dtype=np.float32)
    
    for curvelet in curvelets:
        _draw_thick_curvelet_line(
            fiber_overlay,
            curvelet,
            line_width=int(line_width),
            colormap=colormap
        )
    
    # Apply mask if provided
    if mask is not None:
        mask_3d = np.stack([mask, mask, mask], axis=2).astype(bool)
        fiber_overlay = fiber_overlay * mask_3d
    
    # Blend only where fibers are detected
    fiber_mask = np.any(fiber_overlay > 0, axis=2)
    final_overlay = background_rgb.copy()
    final_overlay[fiber_mask] = (1 - alpha) * background_rgb[fiber_mask] + alpha * fiber_overlay[fiber_mask]
    
    return (np.clip(final_overlay, 0, 1) * 255).astype(np.uint8)


def create_angle_maps(
    image: np.ndarray,
    curvelets: Sequence[Curvelet],
    std_window: int = 24,
    square_window: int = 12,
    gaussian_sigma: float = 4.0,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Create raw and processed angle maps.
    
    Parameters
    ----------
    image : np.ndarray
        Original image
    curvelets : Sequence[Curvelet]
        List of curvelets
    std_window : int, default 24
        Window size for standard deviation filter
    square_window : int, default 12
        Window size for square maximum filter
    gaussian_sigma : float, default 4.0
        Sigma for Gaussian disc filter
        
    Returns
    -------
    Tuple[np.ndarray, np.ndarray]
        Raw and processed angle maps
    """
    height, width = image.shape
    
    # Create raw angle map
    raw_map = np.full((height, width), np.nan)
    
    for curvelet in curvelets:
        row, col = int(curvelet.center_row), int(curvelet.center_col)
        if 0 <= row < height and 0 <= col < width:
            raw_map[row, col] = curvelet.angle_deg
    
    # Create processed map with spatial filtering
    processed_map = _process_angle_map(raw_map, std_window, square_window, gaussian_sigma)
    
    return raw_map, processed_map


# Helper functions (moved from core/visualize.py)

def _draw_thick_curvelet_line(
    overlay: np.ndarray,
    curvelet: Curvelet,
    line_width: int,
    colormap: str,
) -> None:
    """Draw a thick curvelet line on the overlay image."""
    height, width = overlay.shape[:2]
    
    center_row, center_col = curvelet.center_row, curvelet.center_col
    angle_deg = curvelet.angle_deg
    
    # Convert angle to color
    color = _angle_to_color(angle_deg, colormap)
    color_normalized = np.array(color) / 255.0
    
    # Calculate line endpoints
    line_length = 15
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


def _angle_to_color(angle_deg: float, colormap: str) -> Tuple[int, int, int]:
    """Convert an angle to RGB color based on colormap."""
    normalized = (angle_deg % 180) / 180
    
    if colormap == "hsv":
        import colorsys
        rgb = colorsys.hsv_to_rgb(normalized, 1.0, 1.0)
        return tuple(int(c * 255) for c in rgb)
    elif colormap == "jet":
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
        gray = int(normalized * 255)
        return gray, gray, gray


def _get_thick_line_points(x1: int, y1: int, x2: int, y2: int, thickness: int) -> list:
    """Generate points for a thick line."""
    points = []
    line_points = _bresenham_line(x1, y1, x2, y2)
    
    for x, y in line_points:
        for dx in range(-thickness//2, thickness//2 + 1):
            for dy in range(-thickness//2, thickness//2 + 1):
                if dx*dx + dy*dy <= (thickness//2)**2:
                    points.append((x + dx, y + dy))
    
    return list(set(points))


def _bresenham_line(x0: int, y0: int, x1: int, y1: int) -> list:
    """Generate points along a line using Bresenham's algorithm."""
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


def _process_angle_map(raw_map: np.ndarray, std_window: int, square_window: int, gaussian_sigma: float) -> np.ndarray:
    """Apply spatial filtering to create processed angle map."""
    processed = raw_map.copy()
    
    # Apply square maximum filter
    if square_window > 0:
        processed = ndimage.maximum_filter(processed, size=square_window)
    
    # Apply Gaussian smoothing
    if gaussian_sigma > 0:
        mask = ~np.isnan(processed)
        if np.any(mask):
            valid_data = np.where(mask, processed, 0)
            filtered_data = ndimage.gaussian_filter(valid_data, sigma=gaussian_sigma)
            filtered_mask = ndimage.gaussian_filter(mask.astype(float), sigma=gaussian_sigma)
            
            with np.errstate(divide='ignore', invalid='ignore'):
                processed = np.where(filtered_mask > 0, filtered_data / filtered_mask, np.nan)
    
    return processed
