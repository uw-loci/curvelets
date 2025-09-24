### Curvelets repository: API outline and roles

This document maps the Curvelets repo functionality, grouped by exposure level and role, to guide MATLAB→Python translation. Paths are relative to `curvelets/src/CurveAlign_CT-FIRE/` unless noted.

## High-level (user-facing entry points)

- **CurveAlign GUIs (App Designer / GUIDE)**
  - `CurveAlignVisualization.mlapp`: visualization frontend for results and overlays
  - `ROIbasedDensityCalculation.mlapp`: ROI-driven density/align analysis
  - `Cellanalysis/*.mlapp`: cell analysis tooling integrated with CurveAlign outputs
  - `ctFIRE/intersectionGUI.mlapp`, `ctFIRE/intersectionProperties.mlapp`: CT-FIRE intersection/props explorers

- **CurveAlign main scripts (GUI/CLI)**
  - `CurveAlign.m`: main entry (GUI-backed processing and setup)
  - `CAroi.m`: ROI-focused analysis (GUI context), pairs with `processROI.m`
  - `CurveAlign_CommandLine.m`: command-line variant
  - Cluster wrappers: `CurveAlign_cluster.m`, `CurveAlignFE_cluster.m`, `LOCIca_cluster.m`, `CAroi_cluster.m`
  - Test/demo scripts: `testCurveAlign_CommandLine.m`, `goCAK.m`

- **CT-FIRE module (individual fiber extraction)**
  - `ctFIRE/ctFIRE.m`: main CT-FIRE entry point
  - `ctFIRE/ctFIRE_cluster.m`: cluster processing version
  - `ctFIRE/roi_gui_v3.m`: ROI-based CT-FIRE analysis
  - `ctFIRE/goCTFK.m`: CT-FIRE orchestration
  - `ctFIRE/intersectionGUI.mlapp`: fiber intersection analysis GUI
  - `ctFIRE/intersectionProperties.mlapp`: intersection properties analysis

- **Cell analysis module**
  - `Cellanalysis/*.mlapp`: cell analysis tooling integrated with fiber outputs
  - Cell segmentation and cell-fiber interaction analysis
  - `Cellanalysis/TumorRegionAnnotationGUI.mlapp`: tumor annotation and measurements

- **ROI management module**
  - ROI definition tools (manual/automatic ROI creation)
  - ROI analysis and management utilities
  - Integration with ROI-based density calculation
  - Support for multiple ROI formats and geometric shapes

- **Preprocessing modules**
  - `preprocessing/bioFormatsMatlabGUI.m`: multi-series/channel loader and exporter via Bio-Formats
  - `preprocessing/autoThreshGUI.m`: image thresholding and preview tooling
  - `preprocessing/preprocmodule.m`: main preprocessing module entry point
  - `preprocessing/pmBioFormats.m`, `preprocessing/pmBioFormats_v2.m`: Bio-Formats integration helpers
  - `preprocessing/pmAutoThresh.m`, `preprocessing/autoThresh.m`: auto-thresholding utilities
  - `preprocessing/pmConv8Bit.m`: 8-bit conversion utilities
  - `preprocessing/pmManImgReg.m`: manual image registration
  - Thresholding algorithms: `preprocessing/sauvola.m`, `preprocessing/adaptivethreshold.m`, `preprocessing/Kapur.m`, `preprocessing/kittlerMinErrThresh.m`

## Mid-level orchestration (analysis pipelines)

- **Image/ROI analysis coordinators**
  - `processImage.m`: central analysis pipeline (single image). Supports modes:
    - Curvelets-only (FDCT), or CT-FIRE-backed features
    - Optional boundary analysis (CSV or TIFF mask)
    - Optional map/overlay and stats generation
  - `processROI.m`: like `processImage.m` but ROI-oriented (structural outputs tailored to ROI workflows)
  - `processImageCK.m`: variant used in certain integration contexts (CK)
  - `processImage_p.m`: parallel-friendly batch pipeline (path-based I/O)
  - Support utilities: `checkCAoutput.m`, `checkCTFireFiles.m`, `postprocess_CHTCoutput.m`

- **Feature extraction (mid→low bridge)**
  - `getCT.m`, `getCTroi.m`: calls curvelet extraction (`newCurv`) and computes per-"fiber" features (density/alignment via kNN and box windows), returns `object` (centers, angles, weights), fiber keys, and `Ct` (coeffs)
  - `getFIRE.m`: loads CT-FIRE output of individual fibers and converts to CurveAlign-compatible format

- **CT-FIRE processing pipelines**
  - `ctFIRE/ctFIRE_1.m`: core CT-FIRE processing pipeline for single images
  - `ctFIRE/ctFIRE_1p.m`: parallel CT-FIRE processing for batch operations
  - `ctFIRE/ctFeatures.m`: CT-FIRE feature extraction using FDCT enhancement
  - `ctFIRE/checkCTFireFiles.m`: CT-FIRE output validation and verification

- **Boundary measurement and visualization**
  - `getBoundary.m`: compute distances and relative angles to boundaries (CSV/polygon coordinates)
  - `getTifBoundary.m`: compute boundary measurements from TIFF mask files
  - `TumorTrace/getBoundary.m`: variant for tumor trace analysis
  - `checkBndryFiles.m`: boundary file validation
  - `drawMap.m`: builds raw and processed angle maps (uses filtering params)
  - `drawCurvs.m`: draw curvelet/fiber glyphs on images
  - `makeStatsO.m`, `makeStatsOROI.m`: summary statistics and CSV outputs
  - `draw_CAoverlay.m`, `draw_CAmap.m`: overlay and map drawing utilities

## Low-level algorithms (compute kernels)

- **Curvelet transform and coefficient handling**
  - `newCurv.m`: forward FDCT via CurveLab, magnitude thresholding by scale, coefficient selection, center/angle extraction with `fdct_wrapping_param`, optional grouping, returns `object` and `Ct`
  - Reconstruction helpers: `CTrec.m`, `ctFIRE/CTrec_1.m`, `ctFIRE/CTrec_1ck.m` (compute FDCT, threshold, partial inverse with `ifdct_wrapping`)

- **FIRE algorithm integration**
  - FIRE algorithm: individual fiber extraction from curvelet-enhanced images
  - Integration: CT-FIRE generates fiber lists that CurveAlign consumes via `getFIRE.m`

## I/O and preprocessing

- **Image I/O**
  - `bfmatlab/*.m`: Bio-Formats MATLAB toolbox (`bfopen`, `bfGetReader`, `bfGetPlane`, `bfsave`, etc.)
  - `preprocessing/pmBioFormats.m`, `pmBioFormats_v2.m`, `pmTest.m`, `BFinMatlabFigureSlider.m`: helpers and demos around Bio-Formats and GUI slider visualization

- **Output writing**
  - CSV/text via `csvwrite`, `fopen`/`fprintf` (e.g., `writeAllHistData.m`, parts of `process*` functions)
  - XLSX summaries via `writecell`, `writematrix`
  - TIFF outputs (`imwrite`) for overlays and reconstructed images

## External dependencies

- CurveLab 2.1.2 MATLAB (`fdct_wrapping_matlab`): `fdct_wrapping`, `ifdct_wrapping`, `fdct_wrapping_param`
- Circular statistics: `CircStat2012a`
- CT-FIRE (fiber extraction), FIRE toolkit
- Bio-Formats Java (OME) for image I/O

## Notes on exposure levels

- **High-level API**: Main entry points including:
  - CurveAlign: `CurveAlign.m`, `CurveAlign_CommandLine.m`, `CAroi.m`, and MLAPP UIs
  - CT-FIRE: `ctFIRE/ctFIRE.m`, `ctFIRE/ctFIRE_cluster.m`, `ctFIRE/roi_gui_v3.m`, intersection analysis, orchestration
  - Cell analysis: `Cellanalysis/*.mlapp`, cell segmentation, tumor annotation
  - ROI management: ROI definition, analysis tools, density calculation
  - Preprocessing: `preprocessing/bioFormatsMatlabGUI.m`, `preprocessing/autoThreshGUI.m`, main preprocessing module
- **Mid-level API**: Processing pipelines and feature extraction:
  - Image processing: `processImage*.m`, `processROI.m`
  - Feature extraction: `getCT*.m`, `getFIRE.m`
  - CT-FIRE processing: `ctFIRE/ctFIRE_1.m`, `ctFIRE/ctFIRE_1p.m`, `ctFIRE/ctFeatures.m`, validation
  - Visualization/stats: boundary analysis, drawing utilities, statistics
- **Low-level API**: Core algorithms:
  - Curvelet transforms: `newCurv.m`, `CTrec*.m`
  - External libraries: FDCT (CurveLab), FIRE algorithm integration

## Deprecated/Legacy components

- `batch_curveAlign.m`: legacy batch processing (replaced by newer batch methods)
- `CurvePrep.m`: legacy preparation utilities (functionality integrated elsewhere)
- `TumorTrace/newCurv.m`: legacy tumor trace variant (functionality integrated into main pipeline)

## fdct usage summary (details in `fdct_calls.md`)

- Forward: `fdct_wrapping` in `newCurv.m`, `TumorTrace/newCurv.m`, `CTrec*.m`, `ctFIRE/ctFeatures.m`
- Params/centers: `fdct_wrapping_param` in `newCurv.m` variants
- Inverse: `ifdct_wrapping` in reconstruction helpers and when producing optional reconstructions in `process*`

## Implemented Python API

### High-level Functions
- `curvealign.analyze_image(image: np.ndarray, boundary: Optional[Boundary]=None, mode: Literal["curvelets","ctfire"]="curvelets", options: CurveAlignOptions=None) -> AnalysisResult`
- `curvealign.analyze_roi(image: np.ndarray, rois: List[Boundary], options: CurveAlignOptions=None) -> ROIResult`
- `curvealign.batch_analyze(inputs: Iterable[Path|np.ndarray], boundaries: Optional[Iterable[Boundary]]=None, options: CurveAlignOptions=None) -> List[AnalysisResult]`

### Mid-level Functions
- `curvealign.get_curvelets(image: np.ndarray, keep: float=0.001, scale: Optional[int]=None, group_radius: Optional[float]=None) -> Tuple[List[Curvelet], CtCoeffs]`
- `curvealign.reconstruct(coeffs: CtCoeffs, scales: Optional[List[int]]=None) -> np.ndarray`
- `curvealign.compute_features(curvelets: List[Curvelet], options: FeatureOptions=None) -> FeatureTable`
- `curvealign.measure_boundary(curvelets: List[Curvelet], boundary: Boundary, dist_thresh: float, min_dist: Optional[float]=None, exclude_inside_mask: bool=False) -> BoundaryMetrics`

### Visualization Functions (Pluggable Backends)
- `standalone.create_overlay(image: np.ndarray, curvelets: List[Curvelet], mask: Optional[np.ndarray]=None) -> np.ndarray`
- `standalone.create_angle_maps(image: np.ndarray, curvelets: List[Curvelet]) -> Tuple[np.ndarray,np.ndarray]`
- `napari_plugin.launch_napari_viewer(result: AnalysisResult, image: np.ndarray) -> napari.Viewer`
- `pyimagej_plugin.launch_imagej_with_results(result: AnalysisResult, image: np.ndarray) -> imagej.ImageJ`

### Core Types (Organized in Packages)
- `types.core.Curvelet(center_row: int, center_col: int, angle_deg: float, weight: Optional[float])`
- `types.core.CtCoeffs`: structured coeff container (scales × wedges)
- `types.core.Boundary`: polygon(s) or binary mask with spacing/scale metadata
- `types.results.AnalysisResult`: curvelets, features, boundary metrics, stats (no visualization)
- `types.options.CurveAlignOptions`: analysis configuration parameters

### Implementation Architecture
- **Core API**: Visualization-free analysis algorithms
- **Types Package**: Organized by function (core, options, results)
- **Visualization Package**: Pluggable backends (standalone, napari, ImageJ)
- **Framework Integration**: Ready for napari, ImageJ, and other scientific tools

Implementation notes
- Back the transform with PyCurvelab bindings or PyCurvelab-compatible NumPy/C++ (fdct_usfft / wrapping). 
- Visualization is separated from core API for framework neutrality and minimal dependencies
- I/O: default to `tifffile` and `imageio`; optional `pyimagej` integration for complex formats.
- Deterministic tests: seed any randomized steps; provide fixtures mirroring MATLAB tests in `tests/test_results`.


