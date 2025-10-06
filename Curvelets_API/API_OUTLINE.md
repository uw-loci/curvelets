### Curvelets repository: API outline and roles

This document maps the Curvelets repo functionality, grouped by exposure level and role, to guide MATLAB→Python translation. Paths are relative to `curvelets/src/CurveAlign_CT-FIRE/` unless noted.

## High-level (user-facing entry points)

- **CurveAlign GUIs (App Designer / GUIDE)**
  - `CurveAlignVisualization.mlapp`: visualization frontend for results and overlays
  - `ROIbasedDensityCalculation.mlapp`: ROI-driven density/align analysis
  - `Cellanalysis/*.mlapp`: cell analysis tooling integrated with CurveAlign outputs
  - `ctFIRE/intersectionGUI.mlapp`: CT-FIRE intersection analysis GUI

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

- **Cell analysis module**
  - `Cellanalysis/*.mlapp`: cell analysis tooling integrated with fiber outputs
  - Cell segmentation and cell-fiber interaction analysis

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
  - Support utilities: `checkCAoutput.m`, `checkCTFireFiles.m`, `checkBndryFiles.m`, `postprocess_CHTCoutput.m`

- **Feature extraction (mid→low bridge)**
  - `getCT.m`, `getCTroi.m`: calls curvelet extraction (`newCurv`) and computes per-"fiber" features (density/alignment via kNN and box windows), returns `object` (centers, angles, weights), fiber keys, and `Ct` (coeffs)
  - `getFIRE.m`: loads CT-FIRE output of individual fibers and converts to CurveAlign-compatible format

- **CT-FIRE processing pipelines**
  - `ctFIRE/ctFIRE_1.m`: core CT-FIRE processing pipeline for single images
  - `ctFIRE/ctFIRE_1p.m`: parallel CT-FIRE processing for batch operations
  - `ctFIRE/checkCTFireFiles.m`: CT-FIRE output validation and verification

- **Boundary measurement and visualization**
  - `getBoundary.m`: compute distances and relative angles to boundaries (CSV/polygon coordinates)
  - `getTifBoundary.m`: compute boundary measurements from TIFF mask files
  - `checkBndryFiles.m`: boundary file validation
  - `drawMap.m`: builds raw and processed angle maps (uses filtering params)
  - `drawCurvs.m`: draw curvelet/fiber glyphs on images
  - `makeStatsO.m`, `makeStatsOROI.m`: summary statistics and CSV outputs (uses CircStat functions: `circ_mean`, `circ_median`, `circ_var`, `circ_std`, `circ_r`, `circ_skewness`, `circ_kurtosis`, `circ_otest`)
  - `draw_CAoverlay.m`, `draw_CAmap.m`: overlay and map drawing utilities
  - `getRelativeangles.m`: calculates relative angles between fibers and boundaries

## Low-level algorithms (compute kernels)

- **Curvelet transform and coefficient handling**
  - `newCurv.m`: forward FDCT via CurveLab, magnitude thresholding by scale, coefficient selection, center/angle extraction with `fdct_wrapping_param`, optional grouping, returns `object` and `Ct`
  - `fixAngle.m`: minimizes standard deviation between grouped curvelet angles for accurate mean calculation (called by `newCurv.m`)
  - Reconstruction helpers: `CTrec.m`, `ctFIRE/CTrec_1.m`, `ctFIRE/CTrec_1ck.m` (compute FDCT, threshold, partial inverse with `ifdct_wrapping`)

- **FIRE algorithm integration**
  - FIRE entry points: `fire_2D_ang1.m` and `fire_2D_ang1CPP.m` (C++ optimized) for individual fiber extraction from curvelet-enhanced images
  - Integration: CT-FIRE (`ctFIRE_1*.m` variants) calls FIRE entry points, generates fiber lists that CurveAlign consumes via `getFIRE.m`

- **Utility functions**
  - `formatFeatureName.m`: formats feature names with dynamic parameters for visualization and export
  - `group6.m`: normalizes fiber angles to 0-180 degree range

## I/O and preprocessing

- **Image I/O**
  - `bfmatlab/*.m`: Bio-Formats MATLAB toolbox (`bfopen`, `bfGetReader`, `bfGetPlane`, `bfsave`, etc.)
  - `preprocessing/pmBioFormats.m`, `pmBioFormats_v2.m`, `pmTest.m`, `BFinMatlabFigureSlider.m`: helpers and demos around Bio-Formats and GUI slider visualization

- **Output writing**
  - CSV/text via `csvwrite`, `fopen`/`fprintf` (e.g., `writeAllHistData.m`, parts of `process*` functions)
  - XLSX summaries via `writecell`, `writematrix`
  - TIFF outputs (`imwrite`) for overlays and reconstructed images

## External dependencies

- **CurveLab 2.1.2 MATLAB** (`fdct_wrapping_matlab`): `fdct_wrapping`, `ifdct_wrapping`, `fdct_wrapping_param`
- **Circular statistics** (`CircStat2012a`): Used for angular statistics in `makeStatsO.m`, `makeStatsOROI.m`, `getCT.m`, `getFIRE.m`
  - `circ_mean`: circular mean for angular data
  - `circ_median`: circular median
  - `circ_var`: circular variance
  - `circ_std`: circular standard deviation
  - `circ_r`: mean resultant vector length (alignment metric)
  - `circ_skewness`: measure of angular distribution symmetry
  - `circ_kurtosis`: measure of angular distribution peakedness
  - `circ_otest`: omnibus test for uniformity
- **FIRE toolkit**: Individual fiber extraction algorithm
  - Entry points: `fire_2D_ang1.m`, `fire_2D_ang1CPP.m` (C++ optimized)
  - Called by CT-FIRE processing pipeline
- **Bio-Formats Java (OME)**: Multi-format biological image I/O

## Notes on exposure levels

- **High-level API**: Main entry points including:
  - CurveAlign: `CurveAlign.m`, `CurveAlign_CommandLine.m`, `CAroi.m`, and MLAPP UIs
  - CT-FIRE: `ctFIRE/ctFIRE.m`, `ctFIRE/ctFIRE_cluster.m`, `ctFIRE/roi_gui_v3.m`, intersection analysis, orchestration
  - Cell analysis: `Cellanalysis/*.mlapp`, cell segmentation
  - ROI management: ROI definition, analysis tools, density calculation
  - Preprocessing: `preprocessing/bioFormatsMatlabGUI.m`, `preprocessing/autoThreshGUI.m`, main preprocessing module
- **Mid-level API**: Processing pipelines and feature extraction:
  - Image processing: `processImage*.m`, `processROI.m`
  - Feature extraction: `getCT*.m`, `getFIRE.m`
  - CT-FIRE processing: `ctFIRE/ctFIRE_1.m`, `ctFIRE/ctFIRE_1p.m`, validation
  - Visualization/stats: boundary analysis, drawing utilities, statistics
- **Low-level API**: Core algorithms:
  - Curvelet transforms: `newCurv.m`, `CTrec*.m`
  - External libraries: FDCT (CurveLab), FIRE algorithm integration
- **Low-level utilities from unlisted files** (e.g., `addCurvelabAddressFn`, `network_statK`) are abstracted behind core nodes and not explicitly graphed to maintain high-level focus.

## Deprecated/Legacy components

- **TumorTrace module** (`TumorTrace/` directory): Deprecated tumor boundary tracing analysis module including `TumorRegionAnnotationGUI.mlapp`
  - Contains legacy variants: `newCurv.m`, `fixAngle.m`, `getBoundary.m`, etc.
  - Functionality has been integrated into main CurveAlign pipeline
  - Note: Despite being deprecated, `tumorTraceCalculations` is still called from `CAroi.m`.
- `batch_curveAlign.m`: legacy batch processing (replaced by `CurveAlign_cluster.m` and parallel processing methods)
- `CurvePrep.m`: legacy preparation utilities (functionality integrated elsewhere)
- `ctFIRE/ctFeatures.m`: redundant CT-FIRE feature extraction (functionality integrated elsewhere)
- `ctFIRE/intersectionProperties.mlapp`: redundant intersection properties analysis (no longer used in workflow)

## fdct usage summary (details in `fdct_calls.md`)

- Forward: `fdct_wrapping` in `newCurv.m`, `CTrec*.m`
- Params/centers: `fdct_wrapping_param` in `newCurv.m`
- Inverse: `ifdct_wrapping` in reconstruction helpers (`CTrec*.m`) and when producing optional reconstructions in `process*` functions



