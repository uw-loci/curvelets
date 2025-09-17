"""
Core implementation modules for CurveAlign functionality.

This package contains the low-level implementation of curvelet transforms,
feature computation, boundary analysis, and visualization.
"""

from . import curvelets
from . import features  
from . import boundary
from . import visualize

__all__ = ["curvelets", "features", "boundary", "visualize"]
