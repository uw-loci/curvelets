### Curvelets repository: API outline and roles

This document maps the Curvelets repo functionality, grouped by exposure level and role, to guide MATLAB→Python translation. Paths are relative to `curvelets/src/CurveAlign_CT-FIRE/` unless noted.

## High-level (user-facing entry points)

- **CurveAlign GUIs (App Designer / GUIDE)**
  - `CurveAlignVisualization.mlapp`: visualization frontend for results and overlays
  - `ROIbasedDensityCalculation.mlapp`: ROI-driven density/align analysis
  - `Cellanalysis/*.mlapp`: cell analysis tooling integrated with CurveAlign outputs
  - `ctFIRE/intersectionGUI.mlapp`, `ctFIRE/intersectionProperties.mlapp`: CT-FIRE intersection/props explorers

- **CurveAlign main scripts (GUI/CLI/Batch)**
  - `CurveAlign.m`: main entry (GUI-backed processing and setup)
  - `CAroi.m`: ROI-focused analysis (GUI context), pairs with `processROI.m`
  - `CurveAlign_CommandLine.m`: command-line variant
  - `batch_curveAlign.m`: batch runner
  - `CurvePrep.m`: preparation and setup utilities
  - Cluster wrappers: `CurveAlign_cluster.m`, `CurveAlignFE_cluster.m`, `LOCIca_cluster.m`, `CAroi_cluster.m`
  - Test/demo scripts: `testCurveAlign_CommandLine.m`, `goCAK.m`

- **CT-FIRE high level**
  - `ctFIRE/ctFIRE.m`, `ctFIRE/ctFIRE_cluster.m`, `ctFIRE/roi_gui_v3.m`, `ctFIRE/goCTFK.m`: CT-FIRE orchestration

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

- **Curvelet feature extraction (mid→low bridge)**
  - `getCT.m`, `getCTroi.m`: calls curvelet extraction (`newCurv`) and computes per-“fiber” features (density/alignment via kNN and box windows), returns `object` (centers, angles, weights), fiber keys, and `Ct` (coeffs)

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
  - `TumorTrace/newCurv.m`: earlier variant including `pixel_indent` step; same FDCT logic
  - Reconstruction helpers: `CTrec.m`, `ctFIRE/CTrec_1.m`, `ctFIRE/CTrec_1ck.m`, `ctFIRE/ctFeatures.m` (compute FDCT, threshold, partial inverse with `ifdct_wrapping`)

- **CT-FIRE integration (separate FIRE repo code is under `src/FIRE/`)**
  - CT-FIRE pipelines generate fiber lists that CurveAlign can consume via `getFIRE.m` (not detailed here) as an alternative to curvelet-derived “fibers”

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

- High-level API: `CurveAlign.m`, `CurveAlign_CommandLine.m`, `CAroi.m`, batch/cluster scripts, and MLAPP UIs
- Mid-level API: `processImage*.m`, `processROI.m`, `getCT*.m`, boundary/visualization/stats utilities
- Low-level API: `newCurv.m`, `CTrec*.m`, `ctFIRE/ctFeatures.m` (transform/reconstruct), plus helpers used by these (e.g., angle grouping, kNN feature calc)

## fdct usage summary (details in `fdct_calls.md`)

- Forward: `fdct_wrapping` in `newCurv.m`, `TumorTrace/newCurv.m`, `CTrec*.m`, `ctFIRE/ctFeatures.m`
- Params/centers: `fdct_wrapping_param` in `newCurv.m` variants
- Inverse: `ifdct_wrapping` in reconstruction helpers and when producing optional reconstructions in `process*`

## Proposed stable Python API (initial)

High-level
- `curvealign.analyze_image(image: np.ndarray, boundary: Optional[Boundary]=None, mode: Literal["curvelets","ctfire"]="curvelets", options: CurveAlignOptions=None) -> AnalysisResult`
- `curvealign.analyze_roi(image: np.ndarray, rois: List[Polygon], options: CurveAlignOptions=None) -> ROIResult`
- `curvealign.batch_analyze(inputs: Iterable[Path|np.ndarray], boundaries: Optional[Iterable[Boundary]]=None, options: CurveAlignOptions=None) -> List[AnalysisResult]`

Mid-level
- `curvealign.get_curvelets(image: np.ndarray, keep: float=0.001, scale: Optional[int]=None, group_radius: Optional[float]=None) -> Tuple[List[Curvelet], CtCoeffs]`
- `curvealign.reconstruct(coeffs: CtCoeffs, scales: Optional[List[int]]=None) -> np.ndarray`
- `features.compute(image: np.ndarray, curvelets: List[Curvelet], options: FeatureOptions=None) -> FeatureTable`
- `boundary.measure(curvelets: List[Curvelet], boundary: Boundary, dist_thresh: float, min_dist: Optional[float]=None, exclude_inside_mask: bool=False) -> BoundaryMetrics`
- `visualize.overlay(image: np.ndarray, curvelets: List[Curvelet], mask: Optional[np.ndarray]=None, options: OverlayOptions=None) -> np.ndarray`
- `visualize.map(image: np.ndarray, curvelets: List[Curvelet], options: MapOptions=None) -> Tuple[np.ndarray,np.ndarray]  # raw, processed`

Core types
- `Curvelet(center: tuple[int,int], angle_deg: float, weight: Optional[float])`
- `CtCoeffs`: structured coeff container (scales × wedges)
- `Boundary`: polygon(s) or binary mask with spacing/scale metadata
- `AnalysisResult`: angles, features, boundary metrics, stats, overlays/heatmaps

Implementation notes
- Back the transform with PyCurvelab bindings or PyCurvelab-compatible NumPy/C++ (fdct_usfft / wrapping). For I/O, prefer `tifffile` + optional PyImageJ for complex formats. Keep API pure-Python with optional plugins.


