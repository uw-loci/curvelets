"""
PyImageJ integration for CurveAlign.

This module provides functions to convert CurveAlign data structures
to ImageJ/FIJI-compatible formats and launch ImageJ with results.
"""

from typing import Sequence, Optional, Any, Dict
import numpy as np

from ..types import Curvelet, AnalysisResult


def curvelets_to_imagej_overlay(
    curvelets: Sequence[Curvelet],
    image_shape: tuple,
    line_length: float = 15.0
) -> Dict[str, Any]:
    """
    Convert curvelets to ImageJ overlay format.
    
    Parameters
    ----------
    curvelets : Sequence[Curvelet]
        List of curvelets to convert
    image_shape : tuple
        Shape of the original image (height, width)
    line_length : float, default 15.0
        Length of overlay lines
        
    Returns
    -------
    Dict[str, Any]
        ImageJ-compatible overlay data
    """
    if not curvelets:
        return {}
    
    # Convert to ImageJ ROI format
    rois = []
    
    for i, curvelet in enumerate(curvelets):
        # Calculate line endpoints
        angle_rad = np.deg2rad(curvelet.angle_deg)
        center_row, center_col = curvelet.center_row, curvelet.center_col
        
        dx = line_length * np.cos(angle_rad) / 2
        dy = line_length * np.sin(angle_rad) / 2
        
        x1, y1 = center_col - dx, center_row - dy
        x2, y2 = center_col + dx, center_row + dy
        
        # Create line ROI
        roi_data = {
            'type': 'line',
            'x1': x1, 'y1': y1,
            'x2': x2, 'y2': y2,
            'angle': curvelet.angle_deg,
            'weight': curvelet.weight or 1.0,
            'name': f'Curvelet_{i}',
            'stroke_width': 2,
            'stroke_color': _angle_to_imagej_color(curvelet.angle_deg)
        }
        rois.append(roi_data)
    
    return {
        'rois': rois,
        'image_shape': image_shape,
        'n_curvelets': len(curvelets)
    }


def analysis_result_to_imagej(
    result: AnalysisResult,
    image: np.ndarray,
    title: str = "CurveAlign_Analysis"
) -> Dict[str, Any]:
    """
    Convert analysis result to ImageJ-compatible format.
    
    Parameters
    ----------
    result : AnalysisResult
        CurveAlign analysis result
    image : np.ndarray
        Original image
    title : str, default "CurveAlign_Analysis"
        Title for ImageJ window
        
    Returns
    -------
    Dict[str, Any]
        ImageJ-compatible data package
    """
    # Convert image to ImageJ format
    if image.dtype != np.uint8:
        if image.max() <= 1:
            imagej_image = (image * 255).astype(np.uint8)
        else:
            imagej_image = image.astype(np.uint8)
    else:
        imagej_image = image
    
    # Convert curvelets to overlay
    overlay_data = curvelets_to_imagej_overlay(result.curvelets, image.shape)
    
    # Prepare results table
    results_table = {
        'headers': ['Curvelet_ID', 'Center_Row', 'Center_Col', 'Angle_Deg', 'Weight'],
        'data': []
    }
    
    for i, curvelet in enumerate(result.curvelets):
        results_table['data'].append([
            i,
            curvelet.center_row,
            curvelet.center_col,
            curvelet.angle_deg,
            curvelet.weight or 1.0
        ])
    
    # Summary statistics
    summary_stats = {
        'Image_Shape': f"{image.shape[0]}x{image.shape[1]}",
        'Total_Curvelets': len(result.curvelets),
        'Mean_Angle_Deg': result.stats['mean_angle'],
        'Std_Angle_Deg': result.stats['std_angle'],
        'Alignment_Index': result.stats['alignment'],
        'Fiber_Density': result.stats['density']
    }
    
    return {
        'image': imagej_image,
        'title': title,
        'overlay': overlay_data,
        'results_table': results_table,
        'summary_stats': summary_stats,
        'metadata': {
            'analysis_type': 'CurveAlign',
            'n_curvelets': len(result.curvelets),
            'image_shape': image.shape
        }
    }


def launch_imagej_with_results(
    result: AnalysisResult,
    image: np.ndarray,
    title: str = "CurveAlign_Analysis"
) -> Any:
    """
    Launch ImageJ with CurveAlign results.
    
    Parameters
    ----------
    result : AnalysisResult
        Analysis results to visualize
    image : np.ndarray
        Original image
    title : str, default "CurveAlign_Analysis"
        Window title
        
    Returns
    -------
    imagej.ImageJ
        PyImageJ instance
    """
    try:
        import imagej
    except ImportError:
        raise ImportError("PyImageJ not available. Install with: pip install pyimagej")
    
    # Initialize ImageJ
    ij = imagej.init()
    
    # Convert data
    imagej_data = analysis_result_to_imagej(result, image, title)
    
    # Display image
    ij.ui().show(title, imagej_data['image'])
    
    # Add overlay ROIs
    # Note: This would require more detailed ImageJ scripting
    # For now, provide the data structure for manual implementation
    
    print(f"ImageJ launched with {len(result.curvelets)} curvelets")
    print("Overlay data available in imagej_data['overlay']")
    print("Results table available in imagej_data['results_table']")
    
    return ij


def _angle_to_imagej_color(angle_deg: float) -> str:
    """Convert angle to ImageJ color string."""
    # Map angles to ImageJ color names
    normalized = (angle_deg % 180) / 180
    
    if normalized < 0.125:
        return "red"
    elif normalized < 0.375:
        return "orange"
    elif normalized < 0.625:
        return "yellow"
    elif normalized < 0.875:
        return "green"
    else:
        return "blue"


def create_imagej_macro(
    result: AnalysisResult,
    image_path: str,
    output_path: str = "curvealign_macro.ijm"
) -> str:
    """
    Generate ImageJ macro for reproducing CurveAlign analysis.
    
    Parameters
    ----------
    result : AnalysisResult
        Analysis results
    image_path : str
        Path to original image
    output_path : str, default "curvealign_macro.ijm"
        Path for output macro file
        
    Returns
    -------
    str
        Generated macro content
    """
    macro_content = f"""// CurveAlign Analysis Results Macro
// Generated automatically from Python API

// Open image
open("{image_path}");

// Analysis summary
print("CurveAlign Analysis Results:");
print("Curvelets detected: {len(result.curvelets)}");
print("Mean angle: {result.stats['mean_angle']:.1f} degrees");
print("Alignment index: {result.stats['alignment']:.3f}");

// Add curvelet overlays
"""
    
    for i, curvelet in enumerate(result.curvelets[:100]):  # Limit for macro size
        angle_rad = np.deg2rad(curvelet.angle_deg)
        center_row, center_col = curvelet.center_row, curvelet.center_col
        
        dx = 15 * np.cos(angle_rad) / 2
        dy = 15 * np.sin(angle_rad) / 2
        
        x1, y1 = center_col - dx, center_row - dy
        x2, y2 = center_col + dx, center_row + dy
        
        color = _angle_to_imagej_color(curvelet.angle_deg)
        
        macro_content += f"""
makeLine({x1:.1f}, {y1:.1f}, {x2:.1f}, {y2:.1f});
setForegroundColor("{color}");
run("Draw", "slice");
"""
    
    macro_content += """
// Save results
saveAs("PNG", "curvealign_imagej_overlay.png");
"""
    
    # Save macro file
    with open(output_path, 'w') as f:
        f.write(macro_content)
    
    return macro_content
