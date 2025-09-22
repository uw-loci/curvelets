# Simple CurveAlign Usage Example - New Architecture
import sys
from pathlib import Path
import numpy as np

# Add curvealign to path
sys.path.insert(0, str(Path(__file__).parent / "curvealign_py"))
import curvealign

def main():
    print("=== CurveAlign Simple Usage Example ===")
    
    # Create or load your image
    image = np.random.rand(256, 256)  # Replace with: io.imread('your_image.tif')
    print(f"Image shape: {image.shape}")
    
    # Core analysis (no visualization dependencies)
    print("Running core analysis...")
    result = curvealign.analyze_image(image)
    
    # Get results
    print(f"\n=== Analysis Results ===")
    print(f"Found {len(result.curvelets)} fiber segments")
    print(f"Mean angle: {result.stats['mean_angle']:.1f}°")
    print(f"Alignment: {result.stats['alignment']:.3f}")
    print(f"Density: {result.stats['density']:.6f} curvelets/pixel")
    
    # Optional: Create visualization (if matplotlib available)
    try:
        from curvealign.visualization import standalone
        print("\nCreating visualization...")
        overlay = standalone.create_overlay(image, result.curvelets)
        print(f"✅ Overlay created: {overlay.shape}")
        
        # Could save with: 
        # from skimage import io
        # io.imsave('fiber_overlay.png', overlay)
        
    except ImportError:
        print("Matplotlib not available - skipping visualization")
    
    # Optional: Launch napari viewer (if napari available)
    try:
        from curvealign.visualization import napari_plugin
        print("Launching napari viewer...")
        viewer = napari_plugin.launch_napari_viewer(result, image)
        print("✅ napari viewer launched")
        
    except ImportError:
        print("napari not available - skipping interactive visualization")
    
    print("\n🎉 Analysis complete!")
    print("\nTo use with your own images:")
    print("  from skimage import io")
    print("  image = io.imread('your_image.tif')")
    print("  result = curvealign.analyze_image(image)")

if __name__ == "__main__":
    main()
