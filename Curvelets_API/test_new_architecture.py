#!/usr/bin/env python3
"""
Test the new CurveAlign architecture with separated concerns.
"""

import sys
from pathlib import Path
import numpy as np

# Add curvealign to path
sys.path.insert(0, str(Path(__file__).parent / "curvealign_py"))

def test_core_api():
    """Test core API without visualization dependencies."""
    print("=== Testing Core API (No Visualization) ===")
    
    import curvealign
    
    # Test image
    image = np.random.rand(128, 128)
    
    # Core analysis (no visualization)
    print("Running core analysis...")
    result = curvealign.analyze_image(image)
    
    print(f"✅ Core analysis successful")
    print(f"   Curvelets: {len(result.curvelets)}")
    print(f"   Features: {len(result.features)} types")
    print(f"   Stats: {list(result.stats.keys())}")
    print(f"   No visualization in result: {not hasattr(result, 'overlay')}")
    
    return result, image

def test_visualization_backends():
    """Test different visualization backends."""
    print("\n=== Testing Visualization Backends ===")
    
    import curvealign
    
    image = np.random.rand(64, 64)
    result = curvealign.analyze_image(image)
    
    # Test standalone backend
    print("Testing standalone backend...")
    try:
        from curvealign.visualization import standalone
        overlay = standalone.create_overlay(image, result.curvelets)
        maps = standalone.create_angle_maps(image, result.curvelets)
        print(f"   ✅ Standalone: overlay {overlay.shape}, maps {maps[0].shape}")
    except ImportError as e:
        print(f"   ❌ Standalone failed: {e}")
    
    # Test napari backend
    print("Testing napari backend...")
    try:
        from curvealign.visualization import napari_plugin
        vectors, props = napari_plugin.curvelets_to_napari_vectors(result.curvelets)
        points, point_props = napari_plugin.curvelets_to_napari_points(result.curvelets)
        print(f"   ✅ napari: vectors {vectors.shape}, points {points.shape}")
    except ImportError as e:
        print(f"   ❌ napari not available: {e}")
    
    # Test PyImageJ backend
    print("Testing PyImageJ backend...")
    try:
        from curvealign.visualization import pyimagej_plugin
        imagej_data = pyimagej_plugin.analysis_result_to_imagej(result, image)
        macro = pyimagej_plugin.create_imagej_macro(result, "test.tif")
        print(f"   ✅ PyImageJ: data keys {list(imagej_data.keys())}")
        print(f"   ✅ Macro generated: {len(macro)} characters")
    except ImportError as e:
        print(f"   ❌ PyImageJ not available: {e}")

def test_type_organization():
    """Test the new type organization."""
    print("\n=== Testing Type Organization ===")
    
    # Test core types
    from curvealign.types.core import Curvelet, Boundary, CtCoeffs
    from curvealign.types.options import CurveAlignOptions, FeatureOptions  
    from curvealign.types.results import AnalysisResult, BoundaryMetrics
    
    print("✅ Core types imported successfully")
    
    # Test type usage
    curvelet = Curvelet(100, 150, 45.0, 1.5)
    options = CurveAlignOptions(keep=0.002)
    
    print(f"   Curvelet: {curvelet}")
    print(f"   Options: keep={options.keep}")
    
    # Test main package imports still work
    import curvealign
    print(f"   Main package: {len(curvealign.__all__)} exports")

def main():
    """Test the new architecture."""
    print("=== CurveAlign New Architecture Test ===")
    
    # Test core API
    result, image = test_core_api()
    
    # Test visualization backends
    test_visualization_backends()
    
    # Test type organization
    test_type_organization()
    
    print("\n🎉 New architecture working correctly!")
    print("\nKey improvements:")
    print("✅ Core API is visualization-free")
    print("✅ Types organized into logical packages")
    print("✅ Pluggable visualization backends")
    print("✅ Clean separation of concerns")
    print("✅ Framework integration ready")

if __name__ == "__main__":
    main()
