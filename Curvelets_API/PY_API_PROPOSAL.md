### Proposed stable Python API for CurveAlign (first pass)

Goals
- Separate high-level analysis from mid/low-level transform, to allow fdct backends to evolve.
- Keep APIs pure-Python and NumPy-friendly; optional plugins for Bio-Formats/PyImageJ.

#### High-level analysis

```python
def analyze_image(
    image: np.ndarray,
    boundary: Optional[Boundary] = None,
    mode: Literal["curvelets", "ctfire"] = "curvelets",
    options: Optional[CurveAlignOptions] = None,
) -> AnalysisResult:
    ...

def analyze_roi(
    image: np.ndarray,
    rois: Sequence[Polygon],
    options: Optional[CurveAlignOptions] = None,
) -> ROIResult:
    ...

def batch_analyze(
    inputs: Iterable[Path | np.ndarray],
    boundaries: Optional[Iterable[Boundary]] = None,
    options: Optional[CurveAlignOptions] = None,
) -> list[AnalysisResult]:
    ...
```

#### Mid-level transform and features

```python
def get_curvelets(
    image: np.ndarray,
    keep: float = 0.001,
    scale: int | None = None,
    group_radius: float | None = None,
) -> tuple[list[Curvelet], CtCoeffs]:
    ...

def reconstruct(coeffs: CtCoeffs, scales: Sequence[int] | None = None) -> np.ndarray:
    ...

def compute_features(
    curvelets: Sequence[Curvelet],
    options: Optional[FeatureOptions] = None,
) -> FeatureTable:
    ...

def measure_boundary(
    curvelets: Sequence[Curvelet],
    boundary: Boundary,
    dist_thresh: float,
    min_dist: float | None = None,
    exclude_inside_mask: bool = False,
) -> BoundaryMetrics:
    ...

def overlay(
    image: np.ndarray,
    curvelets: Sequence[Curvelet],
    mask: np.ndarray | None = None,
    options: Optional[OverlayOptions] = None,
) -> np.ndarray:
    ...

def angle_map(
    image: np.ndarray,
    curvelets: Sequence[Curvelet],
    options: Optional[MapOptions] = None,
) -> tuple[np.ndarray, np.ndarray]:  # (raw, processed)
    ...
```

#### Types (dataclasses/TypedDicts)

```python
class Curvelet(NamedTuple):
    center_row: int
    center_col: int
    angle_deg: float
    weight: float | None

CtCoeffs = Any  # structured container: list[list[np.ndarray]] (scales × wedges)

class Boundary(NamedTuple):
    kind: Literal["mask", "polygon", "polygons"]
    data: np.ndarray | Polygon | list[Polygon]
    spacing_xy: tuple[float, float] | None

class AnalysisResult(NamedTuple):
    curvelets: list[Curvelet]
    features: FeatureTable
    boundary_metrics: BoundaryMetrics | None
    stats: dict[str, float]
    overlay: np.ndarray | None
    maps: tuple[np.ndarray, np.ndarray] | None
```

#### Options

```python
@dataclass
class CurveAlignOptions:
    keep: float = 0.001
    scale: int | None = None
    group_radius: float | None = None
    dist_thresh: float = 100.0
    min_dist: float | None = None
    exclude_inside_mask: bool = False
    map_std_window: int = 24
    map_square_window: int = 12
    map_gaussian_sigma: float = 4.0
```

Backend notes
- Prefer a pluggable FDCT layer (e.g., `curvelab_py` or pybind11 wrapper to CurveLab). Prototype with `pycurvelets` if available.
- I/O: default to `tifffile` and `imageio`; optional `pyimagej` integration for complex formats.
- Deterministic tests: seed any randomized steps; provide fixtures mirroring MATLAB tests in `tests/test_results`.


