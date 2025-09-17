# CurveAlign Python API

A Python interface for analyzing collagen fiber organization in microscopy images using curvelet transforms.

## Overview

CurveAlign is a quantitative tool for interpreting the regional interaction between collagen and tumors by assessment of fiber features including angle, alignment, and density. This Python API provides a modern, type-safe interface to the CurveAlign functionality.

## Features

- **High-level Analysis**: Single function calls for complete image analysis
- **Flexible Input**: Support for NumPy arrays and various image formats  
- **Boundary Analysis**: Measure fiber alignment relative to boundaries
- **ROI Processing**: Analyze multiple regions of interest
- **Batch Processing**: Efficient analysis of multiple images
- **Rich Visualizations**: Create overlays and angle maps
- **Type Safety**: Full type annotations for better development experience

## Installation

```bash
pip install -e .
```

For development:
```bash
pip install -e ".[dev]"
```

## Quick Start

```python
import curvealign
import numpy as np

# Load your image (example with random data)
image = np.random.rand(512, 512)

# Analyze the image
result = curvealign.analyze_image(image)

# Access results
print(f"Found {len(result.curvelets)} curvelets")
print(f"Mean fiber angle: {result.stats['mean_angle']:.1f} degrees")
print(f"Alignment index: {result.stats['alignment']:.3f}")

# Create visualizations
overlay = curvealign.overlay(image, result.curvelets)
raw_map, processed_map = curvealign.angle_map(image, result.curvelets)
```

## API Structure

### High-Level Functions
- `analyze_image()`: Complete analysis of a single image
- `analyze_roi()`: Analysis of multiple regions of interest
- `batch_analyze()`: Batch processing of multiple images

### Mid-Level Functions  
- `get_curvelets()`: Extract curvelets using FDCT
- `compute_features()`: Compute fiber features
- `measure_boundary()`: Boundary alignment analysis
- `reconstruct()`: Reconstruct image from coefficients

### Visualization
- `overlay()`: Create curvelet overlay on original image
- `angle_map()`: Generate spatial angle maps

## Configuration

Analysis behavior can be customized using `CurveAlignOptions`:

```python
options = curvealign.CurveAlignOptions(
    keep=0.001,           # Fraction of coefficients to keep
    dist_thresh=100.0,    # Distance threshold for boundary analysis
    map_std_window=24,    # Window size for angle map filtering
)

result = curvealign.analyze_image(image, options=options)
```

## Development Status

This is an alpha release. The API is stable but the underlying curvelet transform implementation is still being developed. Currently uses placeholder algorithms - full FDCT integration coming soon.

## License

Licensed under the 2-Clause BSD license. See LICENSE for details.

## References

1. Bredfeldt, J.S., Liu, Y., Conklin, M.W., Keely, P.J., Mackie, T.R., and Eliceiri, K.W. (2014). Automated quantification of aligned collagen for human breast carcinoma prognosis. J Pathol Inform 5.

2. Liu, Y., Keikhosravi, A., Mehta, G.S., Drifka, C.R., and Eliceiri, K.W. Methods for quantifying fibrillar collagen alignment. In Fibrosis: Methods and Protocols.
