### Curvelets repository: API outline and roles

This document maps the Curvelets repo functionality, grouped by exposure level and role, to guide MATLAB→Python translation. Paths are relative to `curvelets/src/CurveAlign_CT-FIRE/` unless noted.

**Organization**: This outline is organized into layers mirroring the API graph (`api_graph.dot`, `api_graph_new.png`):
1. **High-level**: User-facing GUIs and main entry points
2. **Mid-level**: Batch/cluster orchestration and processing pipelines
3. **Low-level**: Core algorithms and external library integrations

For a visual representation of the call graph and dependencies, see `api_graph_new.png`. For detailed fdct usage patterns, see `fdct_calls.md`.

## Major processing workflows

The Curvelets codebase supports several major processing workflows:

1. **CurveAlign workflow**: GUI/CLI → orchestration → processImage → getCT/getFIRE → newCurv/FDCT → boundary/stats/visualization
2. **CT-FIRE workflow**: GUI/CLI → ctFIRE_1 → FIRE algorithm → fiber extraction → intersection detection
3. **ROI workflow**: GUI → processROI/CA_ROIanalysis_p → getCTroi → ROI-specific stats and visualization
4. **Cell analysis workflow**: GUI → imageCard/imgCardWholeCell → Python segmentation models → cell properties → fiber-cell interaction
5. **Batch processing**: LOCIca_cluster → parallel pipelines → CHTC post-processing → combined outputs
6. **Preprocessing**: Bio-Formats import → thresholding/registration → image preparation for analysis

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
  - Segmentation interfaces: `imageCard.mlapp` (HE/Nuclei), `imgCardWholeCell.mlapp` (Cytoplasm)
  - Cell properties: `cellCard.mlapp`, `cellCardInd.mlapp`, `wholeCellCard.mlapp`, `CellObjectMeasurement.mlapp`
  - `cellDensity.m`: cell density calculation
  - `VampireCaller.m`: VAMPIRE shape classification caller
  - `ROIcellanalysis.m`: ROI-based cell analysis
  - Python integration: `stardistLink.m`, `wholeCellLink.m` → `stardist/StarDistPrediction.py`, `cellpose/cellpose_seg.py`, `deepcell/deepcell_seg.py`
  - Shape classification: `vampire/mainbody.py`

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
  - Image registration: `preprocessing/BDcreation_reg.m` (HE-SHG registration), `preprocessing/BDcreation_reg2.m` (HSV registration)

## Mid-level orchestration (analysis pipelines)

- **Batch & cluster processing orchestration**
  - `batch_curveAlign.m`: legacy batch processing (deprecated, replaced by parallel methods)
  - `LOCIca_cluster.m`: LOCI cluster orchestrator (calls CurveAlign, CT-FIRE, ROI processing, and post-processing)
  - `CurveAlign_cluster.m`: CurveAlign cluster processing wrapper
  - `ctFIRE_cluster.m`: CT-FIRE cluster processing wrapper
  - `CAroi_cluster.m`: ROI-focused cluster processing
  - `goCTFK.m`: CT-FIRE orchestration entry point
  - `goCAK.m`: CurveAlign orchestration entry point

- **Image/ROI analysis coordinators**
  - `processImage.m`: central analysis pipeline (single image). Supports modes:
    - Curvelets-only (FDCT), or CT-FIRE-backed features
    - Optional boundary analysis (CSV or TIFF mask)
    - Optional map/overlay and stats generation
  - `processROI.m`: like `processImage.m` but ROI-oriented (structural outputs tailored to ROI workflows)
  - `processImageCK.m`: variant used in certain integration contexts (CK)
  - `processImage_p.m`: parallel-friendly batch pipeline (path-based I/O)
  - `CA_ROIanalysis_p.m`: parallel ROI analysis pipeline
  - Support utilities: `checkCAoutput.m`, `checkCTFireFiles.m`, `checkBndryFiles.m`, `postprocess_CHTCoutput.m`

- **Feature extraction (mid→low bridge)**
  - `getCT.m`, `getCTroi.m`: calls curvelet extraction (`newCurv`) and computes per-"fiber" features (density/alignment via kNN and box windows), returns `object` (centers, angles, weights), fiber keys, and `Ct` (coeffs)
  - `getFIRE.m`: loads CT-FIRE output of individual fibers and converts to CurveAlign-compatible format
  - `getRelativeangles.m`: calculates relative angles between fibers and boundaries
  - `getAlignment2ROI.m`: computes fiber alignment relative to ROI boundaries

- **CT-FIRE processing pipelines**
  - `ctFIRE/ctFIRE_1.m`: core CT-FIRE processing pipeline for single images
  - `ctFIRE/ctFIRE_1p.m`: parallel CT-FIRE processing for batch operations
  - `ctFIRE/ctFIRE_1ck.m`: CT-FIRE processing variant for CK integration
  - `ctFIRE/CTFroi.m`: ROI-based CT-FIRE post-processing
  - `ctFIRE/selectedOUT.m`: advanced CT-FIRE output selection and filtering
  - `ctFIRE/checkCTFireFiles.m`: CT-FIRE output validation and verification
  - `ctFIRE/checkCTFoutput.m`: CT-FIRE output verification

- **Intersection detection (fiber crossings)**
  - `ctFIRE/lineIntersection.m`: line intersection detection
  - `ctFIRE/lineSegmentIntersection.m`: line segment intersection calculation
  - `ctFIRE/ipCombineRegions.m`: intersection point region combination
  - `ctFIRE/intersectionCombine.m`: intersection data combination and analysis

- **Boundary measurement and visualization**
  - `getBoundary.m`: compute distances and relative angles to boundaries (CSV/polygon coordinates)
  - `getTifBoundary.m`: compute boundary measurements from TIFF mask files
  - `checkBndryFiles.m`: boundary file validation
  - `drawMap.m`: builds raw and processed angle maps (uses filtering params)
  - `drawCurvs.m`: draw curvelet/fiber glyphs on images
  - `makeStatsO.m`, `makeStatsOROI.m`: summary statistics and CSV outputs (uses CircStat functions: `circ_mean`, `circ_median`, `circ_var`, `circ_std`, `circ_r`, `circ_skewness`, `circ_kurtosis`, `circ_otest`)
  - `draw_CAoverlay.m`, `draw_CAmap.m`: overlay and map drawing utilities
  - `writeAllHistData.m`: writes histogram data to CSV files

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

## I/O and data handling

- **Image I/O**
  - `bfmatlab/*.m`: Bio-Formats MATLAB toolbox (`bfopen`, `bfGetReader`, `bfGetPlane`, `bfsave`, etc.)
  - `preprocessing/pmBioFormats.m`, `pmBioFormats_v2.m`: Bio-Formats integration for multi-series/channel loading
  - `preprocessing/pmTest.m`, `BFinMatlabFigureSlider.m`: Bio-Formats testing and GUI slider visualization helpers

- **Output writing**
  - CSV/text: `writeAllHistData.m` for histogram data, `fopen`/`fprintf` in `makeStatsO*.m` and `process*` functions
  - XLSX summaries via `writecell`, `writematrix` in statistics generation
  - TIFF outputs (`imwrite`) for overlays, maps, and reconstructed images
  - MAT files for intermediate results and cached data

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
  - CurveAlign: `CurveAlign.m`, `CurveAlign_CommandLine.m`, `CAroi.m`, `CurveAlignVisualization.mlapp`, `ROIbasedDensityCalculation.mlapp`
  - CT-FIRE: `ctFIRE/ctFIRE.m`, `ctFIRE/ctFIRE_cluster.m`, `ctFIRE/roi_gui_v3.m`, `ctFIRE/intersectionGUI.mlapp`
  - Cell analysis: `Cellanalysis/*.mlapp` (imageCard, imgCardWholeCell, cellCard, CellObjectMeasurement, etc.)
  - ROI management: ROI definition, analysis tools, density calculation
  - Preprocessing: `preprocessing/bioFormatsMatlabGUI.m`, `preprocessing/autoThreshGUI.m`, `preprocessing/preprocmodule.m`
- **Mid-level API**: Processing pipelines and feature extraction:
  - Batch/cluster orchestration: `LOCIca_cluster.m`, `*_cluster.m`, `goCAK.m`, `goCTFK.m`
  - Image processing: `processImage.m`, `processImage_p.m`, `processImageCK.m`, `processROI.m`, `CA_ROIanalysis_p.m`
  - Feature extraction: `getCT.m`, `getCTroi.m`, `getFIRE.m`, `getRelativeangles.m`, `getAlignment2ROI.m`
  - CT-FIRE processing: `ctFIRE/ctFIRE_1*.m`, `ctFIRE/CTFroi.m`, `ctFIRE/selectedOUT.m`, validation utilities
  - Intersection detection: `lineIntersection.m`, `lineSegmentIntersection.m`, combination utilities
  - Visualization/stats: boundary analysis, drawing utilities, statistics (makeStatsO*, draw_CA*)
- **Low-level API**: Core algorithms:
  - Curvelet transforms: `newCurv.m`, `CTrec.m`, `CTrec_1.m`, `CTrec_1ck.m`
  - External libraries: CurveLab FDCT (`fdct_wrapping`, `ifdct_wrapping`, `fdct_wrapping_param`), FIRE algorithm integration (`fire_2D_ang1.m`, `fire_2D_ang1CPP.m`), CircStat (`circ_*` functions), Bio-Formats
  - Python integrations: cellpose, deepcell, stardist, vampire
- **Low-level utilities from unlisted files** (e.g., `addCurvelabAddressFn`, `network_statK`) are abstracted behind core nodes and not explicitly graphed to maintain high-level focus.

## Python integration points

- **Cell segmentation models**
  - `stardist/StarDistPrediction.py`: StarDist nucleus segmentation model (called via `stardistLink.m`)
  - `cellpose/cellpose_seg.py`: Cellpose whole-cell segmentation (called via `wholeCellLink.m`)
  - `deepcell/deepcell_seg.py`: DeepCell segmentation model (called via `wholeCellLink.m`)
  - `vampire/mainbody.py`: VAMPIRE cell shape classification (called via `VampireCaller.m`)

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



