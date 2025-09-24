### fdct/ifdct usage map

Function calls to CurveLab’s MATLAB API discovered in the repository.

| File | Line | Call | Purpose |
|---|---:|---|---|
| `src/CurveAlign_CT-FIRE/newCurv.m` | 36 | `fdct_wrapping(IMG,0,2)` | Forward curvelet transform (wrapping); 0 = finest, 2 = nbangles_coarsest? variant used here |
| `src/CurveAlign_CT-FIRE/newCurv.m` | 80 | `fdct_wrapping_param(Ct)` | Retrieve center row/col indices per scale/wedge for nonzero coeffs |
| `src/CurveAlign_CT-FIRE/TumorTrace/newCurv.m` | 24 | `fdct_wrapping(IMG,0,2)` | Forward curvelet transform; older variant with `pixel_indent` |
| `src/CurveAlign_CT-FIRE/TumorTrace/newCurv.m` | 61 | `fdct_wrapping_param(Ct)` | Centers/angles indexing parameters |
| `src/CurveAlign_CT-FIRE/CTrec.m` | 41 | `fdct_wrapping(double(IS),0)` | Forward transform for reconstruction demo |
| `src/CurveAlign_CT-FIRE/CTrec.m` | 81 | `ifdct_wrapping(Ct,0)` | Inverse transform to reconstruct |
| `src/CurveAlign_CT-FIRE/ctFIRE/CTrec_1.m` | 28 | `fdct_wrapping(double(IS),0)` | Forward transform (ctFIRE reconstruction helper) |
| `src/CurveAlign_CT-FIRE/ctFIRE/CTrec_1.m` | 67 | `ifdct_wrapping(Ct,0)` | Inverse transform |
| `src/CurveAlign_CT-FIRE/ctFIRE/CTrec_1ck.m` | 29 | `fdct_wrapping(double(IS),0)` | Forward transform (CK variant) |
| `src/CurveAlign_CT-FIRE/ctFIRE/CTrec_1ck.m` | 68 | `ifdct_wrapping(Ct,0)` | Inverse transform |
| `src/CurveAlign_CT-FIRE/processROI.m` | 326 | `ifdct_wrapping(Ct,0)` | Optional reconstruction when in curvelets mode |
| `src/CurveAlign_CT-FIRE/processImage.m` | 478 | `ifdct_wrapping(Ct,0)` | Optional reconstruction when in curvelets mode |
| `src/CurveAlign_CT-FIRE/processImageCK.m` | 304 | `ifdct_wrapping(Ct,0)` | Optional reconstruction when in curvelets mode |
| `src/CurveAlign_CT-FIRE/processImage_p.m` | 371 | `ifdct_wrapping(Ct,0)` | Optional reconstruction in parallel pipeline |

Notes
- All forward transforms use `fdct_wrapping` (wrapping variant). No `fdct_usfft_*` calls are present in this repo.
- Parameter extraction for center positions uses `fdct_wrapping_param` in `newCurv.m` variants to map coefficient indices to pixel space for angle/center calculations.
- The inverse always uses `ifdct_wrapping(Ct, 0)` to reconstruct from selected scales/wedges.


