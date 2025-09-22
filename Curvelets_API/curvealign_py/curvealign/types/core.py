"""
Core data structures for CurveAlign.

This module defines the fundamental data types used throughout the API:
- Curvelet: Individual curvelet representation
- Boundary: Boundary definitions for analysis
- CtCoeffs: Curvelet coefficient structures
"""

from typing import NamedTuple, Literal, Union, List, Optional, Tuple, Any
import numpy as np


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


# Curvelet coefficient structure - list of scales, each containing wedges
CtCoeffs = List[List[np.ndarray]]
