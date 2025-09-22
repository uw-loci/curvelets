"""
Visualization package for CurveAlign results.

This package provides pluggable visualization backends for different frameworks:
- standalone: Matplotlib-based visualization (default)
- napari: napari plugin integration
- pyimagej: ImageJ/FIJI integration

The core API remains visualization-agnostic and only provides data structures.
Visualization is handled by separate, optional modules.
"""

# Import standalone visualization by default
try:
    from .standalone import create_overlay, create_angle_maps
    _has_standalone = True
except ImportError:
    _has_standalone = False

# Optional napari integration
try:
    from . import napari_plugin
    _has_napari = True
except ImportError:
    _has_napari = False

# Optional PyImageJ integration  
try:
    from . import pyimagej_plugin
    _has_pyimagej = True
except ImportError:
    _has_pyimagej = False


def get_available_backends():
    """Get list of available visualization backends."""
    backends = []
    if _has_standalone:
        backends.append("standalone")
    if _has_napari:
        backends.append("napari")
    if _has_pyimagej:
        backends.append("pyimagej")
    return backends


# Export default visualization functions if available
__all__ = []
if _has_standalone:
    __all__.extend(["create_overlay", "create_angle_maps"])

__all__.extend(["get_available_backends"])
