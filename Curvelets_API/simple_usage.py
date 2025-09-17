# Simple CurveAlign Usage Example
import sys
from pathlib import Path
import numpy as np

# Add curvealign to path
sys.path.insert(0, str(Path(__file__).parent / "curvealign_py"))
import curvealign

# Create or load your image
image = np.random.rand(256, 256)  # Replace with: io.imread('your_image.tif')

# Analyze
result = curvealign.analyze_image(image)

# Get results
print(f"Found {len(result.curvelets)} fiber segments")
print(f"Mean angle: {result.stats['mean_angle']:.1f}°")
print(f"Alignment: {result.stats['alignment']:.3f}")
