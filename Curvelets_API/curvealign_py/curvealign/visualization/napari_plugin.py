"""
napari plugin integration for CurveAlign.

This module provides functions to convert CurveAlign data structures
to napari-compatible formats for interactive visualization.
"""

from typing import Sequence, Optional, Tuple, List, Any
import numpy as np

from ..types import Curvelet, AnalysisResult


def curvelets_to_napari_vectors(
    curvelets: Sequence[Curvelet],
    line_length: float = 15.0
) -> Tuple[np.ndarray, dict]:
    """
    Convert curvelets to napari vectors layer format.
    
    Parameters
    ----------
    curvelets : Sequence[Curvelet]
        List of curvelets to convert
    line_length : float, default 15.0
        Length of vector lines in pixels
        
    Returns
    -------
    Tuple[np.ndarray, dict]
        Vector data and properties for napari
    """
    if not curvelets:
        return np.empty((0, 2, 2)), {}
    
    vectors = []
    colors = []
    
    for curvelet in curvelets:
        # Calculate vector endpoints
        angle_rad = np.deg2rad(curvelet.angle_deg)
        center_row, center_col = curvelet.center_row, curvelet.center_col
        
        dx = line_length * np.cos(angle_rad) / 2
        dy = line_length * np.sin(angle_rad) / 2
        
        start = [center_row - dy, center_col - dx]
        end = [center_row + dy, center_col + dx]
        
        vectors.append([start, end])
        
        # Color based on angle
        color_val = (curvelet.angle_deg % 180) / 180
        colors.append([color_val, 1.0, 1.0])  # HSV values
    
    vector_data = np.array(vectors)
    properties = {
        'colors': colors,
        'edge_width': 2,
        'length': line_length,
    }
    
    return vector_data, properties


def curvelets_to_napari_points(curvelets: Sequence[Curvelet]) -> Tuple[np.ndarray, dict]:
    """
    Convert curvelets to napari points layer format.
    
    Parameters
    ----------
    curvelets : Sequence[Curvelet]
        List of curvelets to convert
        
    Returns
    -------
    Tuple[np.ndarray, dict]
        Point data and properties for napari
    """
    if not curvelets:
        return np.empty((0, 2)), {}
    
    points = np.array([[c.center_row, c.center_col] for c in curvelets])
    
    # Create properties
    angles = np.array([c.angle_deg for c in curvelets])
    weights = np.array([c.weight or 1.0 for c in curvelets])
    
    properties = {
        'angle': angles,
        'weight': weights,
        'face_color': angles,  # Color by angle
        'size': np.clip(weights * 5, 3, 15),  # Size by weight
    }
    
    return points, properties


def analysis_result_to_napari_layers(
    result: AnalysisResult,
    image: np.ndarray,
    show_vectors: bool = True,
    show_points: bool = False,
) -> List[Tuple[Any, dict, str]]:
    """
    Convert complete analysis result to napari layer specifications.
    
    Parameters
    ----------
    result : AnalysisResult
        CurveAlign analysis result
    image : np.ndarray
        Original image
    show_vectors : bool, default True
        Whether to include vector layer
    show_points : bool, default False
        Whether to include points layer
        
    Returns
    -------
    List[Tuple[Any, dict, str]]
        List of (data, kwargs, layer_type) tuples for napari
    """
    layers = []
    
    # Original image layer
    layers.append((image, {'name': 'Original Image', 'colormap': 'gray'}, 'image'))
    
    # Curvelet vectors
    if show_vectors and result.curvelets:
        vector_data, vector_props = curvelets_to_napari_vectors(result.curvelets)
        layers.append((
            vector_data, 
            {
                'name': f'Fiber Vectors ({len(result.curvelets)})',
                'edge_color': 'angle',
                'edge_colormap': 'hsv',
                **vector_props
            }, 
            'vectors'
        ))
    
    # Curvelet points
    if show_points and result.curvelets:
        point_data, point_props = curvelets_to_napari_points(result.curvelets)
        layers.append((
            point_data,
            {
                'name': f'Curvelet Centers ({len(result.curvelets)})',
                'face_colormap': 'hsv',
                **point_props
            },
            'points'
        ))
    
    return layers


def launch_napari_viewer(
    result: AnalysisResult,
    image: np.ndarray,
    title: str = "CurveAlign Analysis"
) -> Any:
    """
    Launch napari viewer with CurveAlign results.
    
    Parameters
    ----------
    result : AnalysisResult
        Analysis results to visualize
    image : np.ndarray
        Original image
    title : str, default "CurveAlign Analysis"
        Viewer window title
        
    Returns
    -------
    napari.Viewer
        napari viewer instance
    """
    try:
        import napari
    except ImportError:
        raise ImportError("napari not available. Install with: pip install napari[all]")
    
    # Create viewer
    viewer = napari.Viewer(title=title)
    
    # Add layers
    layers = analysis_result_to_napari_layers(result, image)
    
    for data, kwargs, layer_type in layers:
        if layer_type == 'image':
            viewer.add_image(data, **kwargs)
        elif layer_type == 'vectors':
            viewer.add_vectors(data, **kwargs)
        elif layer_type == 'points':
            viewer.add_points(data, **kwargs)
    
    # Add analysis stats as text
    stats_text = f"""CurveAlign Analysis Results:
Curvelets detected: {len(result.curvelets)}
Mean angle: {result.stats['mean_angle']:.1f}°
Alignment index: {result.stats['alignment']:.3f}
Density: {result.stats['density']:.6f}"""
    
    # Add as dock widget (if napari supports it)
    try:
        from qtpy.QtWidgets import QLabel
        stats_widget = QLabel(stats_text)
        viewer.window.add_dock_widget(stats_widget, name="Analysis Results")
    except:
        print(stats_text)  # Fallback to console
    
    return viewer
