# CurveAlign Python API - Architecture

## Design Philosophy

The CurveAlign Python API follows a **separation of concerns** architecture that keeps the core analysis functionality independent from visualization frameworks. This allows users to choose their preferred visualization tools while maintaining a clean, focused core API.

## Package Structure

```
curvealign/
├── __init__.py                    # Main API exports
├── api.py                         # High-level user-facing functions
├── types/                         # Type definitions (organized by function)
│   ├── __init__.py               # Type exports
│   ├── core.py                   # Core data structures (Curvelet, Boundary, CtCoeffs)
│   ├── options.py                # Configuration classes (CurveAlignOptions, FeatureOptions)
│   └── results.py                # Result structures (AnalysisResult, BoundaryMetrics)
├── core/                         # Core analysis algorithms (visualization-free)
│   ├── __init__.py
│   ├── curvelets.py              # FDCT and curvelet extraction
│   ├── features.py               # Feature computation
│   └── boundary.py               # Boundary analysis
└── visualization/                # Pluggable visualization backends
    ├── __init__.py               # Visualization backend detection
    ├── standalone.py             # Matplotlib-based visualization (default)
    ├── napari_plugin.py          # napari integration
    └── pyimagej_plugin.py        # ImageJ/FIJI integration
```

## Core API (Visualization-Free)

The core API focuses purely on analysis and data structures:

```python
import curvealign

# Core analysis (no visualization dependencies)
result = curvealign.analyze_image(image)
curvelets, coeffs = curvealign.get_curvelets(image)
features = curvealign.compute_features(curvelets)
boundary_metrics = curvealign.measure_boundary(curvelets, boundary)

# Result contains only data, no visualizations
print(result.stats)
print(len(result.curvelets))
# result.overlay and result.maps are removed
```

## Visualization Backends

### Standalone (Default - Matplotlib)

```python
from curvealign.visualization import standalone

# Create visualizations
overlay = standalone.create_overlay(image, result.curvelets)
raw_map, processed_map = standalone.create_angle_maps(image, result.curvelets)

# Or use convenience function
overlay = curvealign.overlay(image, result.curvelets, backend="standalone")
```

### napari Integration

```python
from curvealign.visualization import napari_plugin

# Convert to napari format
vector_data, vector_props = napari_plugin.curvelets_to_napari_vectors(result.curvelets)
point_data, point_props = napari_plugin.curvelets_to_napari_points(result.curvelets)

# Launch napari viewer
viewer = napari_plugin.launch_napari_viewer(result, image)

# Or get all layers for manual setup
layers = napari_plugin.analysis_result_to_napari_layers(result, image)
```

### PyImageJ Integration

```python
from curvealign.visualization import pyimagej_plugin

# Convert to ImageJ format
imagej_data = pyimagej_plugin.analysis_result_to_imagej(result, image)

# Launch ImageJ
ij = pyimagej_plugin.launch_imagej_with_results(result, image)

# Generate ImageJ macro
macro = pyimagej_plugin.create_imagej_macro(result, "image.tif")
```

## Type System Organization

### Core Types (`types/core.py`)
- `Curvelet`: Individual curvelet representation
- `Boundary`: Boundary definitions
- `CtCoeffs`: Curvelet coefficient structures

### Configuration (`types/options.py`)
- `CurveAlignOptions`: Main analysis configuration
- `FeatureOptions`: Feature computation parameters

### Results (`types/results.py`)
- `AnalysisResult`: Complete analysis output
- `BoundaryMetrics`: Boundary analysis results
- `ROIResult`: ROI analysis results
- `FeatureTable`: Feature computation results

## Benefits of This Architecture

### 1. **Separation of Concerns**
- Core analysis is independent of visualization
- Users can choose their preferred visualization framework
- Easy to add new visualization backends

### 2. **Framework Integration**
- **napari**: Interactive 3D visualization, layer management
- **ImageJ/FIJI**: Integration with existing ImageJ workflows
- **Standalone**: No external dependencies, matplotlib-based

### 3. **Extensibility**
- Easy to add new visualization backends
- Core API remains stable while visualization evolves
- Framework-specific optimizations possible

### 4. **Clean Dependencies**
- Core API has minimal dependencies (numpy, scipy)
- Visualization backends are optional
- Users only install what they need

## Usage Patterns

### Basic Analysis (No Visualization)
```python
import curvealign

result = curvealign.analyze_image(image)
# Pure data analysis, no visualization dependencies
```

### With Standalone Visualization
```python
import curvealign
from curvealign.visualization import standalone

result = curvealign.analyze_image(image)
overlay = standalone.create_overlay(image, result.curvelets)
```

### With napari
```python
import curvealign
from curvealign.visualization import napari_plugin

result = curvealign.analyze_image(image)
viewer = napari_plugin.launch_napari_viewer(result, image)
```

### With ImageJ
```python
import curvealign
from curvealign.visualization import pyimagej_plugin

result = curvealign.analyze_image(image)
ij = pyimagej_plugin.launch_imagej_with_results(result, image)
```

## Migration from Previous Version

### Old Architecture (Monolithic)
```python
# Old: Visualization baked into core
result = curvealign.analyze_image(image)
overlay = result.overlay  # Always created, matplotlib dependency
maps = result.maps        # Always created
```

### New Architecture (Pluggable)
```python
# New: Visualization is optional and pluggable
result = curvealign.analyze_image(image)  # No visualization dependencies

# Choose your visualization backend
from curvealign.visualization import standalone
overlay = standalone.create_overlay(image, result.curvelets)

# Or use napari
from curvealign.visualization import napari_plugin
viewer = napari_plugin.launch_napari_viewer(result, image)
```

## Adding New Visualization Backends

To add a new visualization backend:

1. Create `curvealign/visualization/your_backend.py`
2. Implement conversion functions for your framework's data structures
3. Add import handling in `curvealign/visualization/__init__.py`
4. Follow the established patterns for data conversion

Example structure:
```python
# curvealign/visualization/your_backend.py

def curvelets_to_your_format(curvelets):
    """Convert curvelets to your framework's format."""
    pass

def launch_your_viewer(result, image):
    """Launch your visualization framework."""
    pass
```

This architecture ensures that CurveAlign remains a focused analysis tool while providing flexible visualization options for different scientific workflows.
