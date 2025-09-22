"""
Core implementation modules for CurveAlign functionality.

This package contains the low-level implementation of curvelet transforms,
feature computation, and boundary analysis. Visualization is handled
separately in the visualization package to maintain separation of concerns.
"""

from . import curvelets
from . import features  
from . import boundary

__all__ = ["curvelets", "features", "boundary"]
