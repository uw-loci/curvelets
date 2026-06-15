# Match Real Data — Extractor Integration Rules & Notes

This file governs all work on the **Match Real Data** tab and the CT-FIRE extractor
pipeline in `3DSynFiberGen`.  Read it before touching any file listed below.

---

## Environment

| Requirement | Detail |
|---|---|
| Python | **3.14** from MSYS2 UCRT64 (`C:\msys64\ucrt64\bin\python3`) |
| venv | `.venv/` at the 3DSynFiberGen root, created by `setup_ucrt64_env.sh` |
| Windows PATH | `C:\msys64\ucrt64\bin` must be on **System PATH** (for fiber_backend DLLs) |
| ctfire_py | Sibling package at `H:\GitHub.06.2022\tme-quant\src\ctfire_py\` — made importable via `.pth` file, **not** pip-installed |
| VS Code terminal | Use **MSYS2 UCRT64** profile for environment work; PowerShell for git |

Run `bash setup_ucrt64_env.sh` once from the UCRT64 terminal to set up the venv.

### Known issue: matplotlib DLL version mismatch on MSYS2 UCRT64

`ctfire_py/ct_fire.py` has top-level `import matplotlib.pyplot / .cm / .colors`.
On MSYS2 UCRT64, `matplotlib._path` (a C extension) can fail with:
```
ImportError: DLL load failed while importing _path: The specified procedure could not be found.
```
This is a Python 3.14 ABI incompatibility in MSYS2's matplotlib build.

**Fix (applied in `run_ctfire_subprocess.py` and `setup_ucrt64_env.sh`):**
Before importing ctfire_py, try importing `matplotlib.pyplot`.  If it raises
`ImportError` or `OSError`, stub out all matplotlib submodules in `sys.modules`
with empty `types.ModuleType` objects.  This is safe because with `plotflag=0`
ctfire_py never calls any matplotlib code paths.

Do **not** modify ctfire_py to make its matplotlib imports lazy — that package
is off-limits (see Rule 0 below).

`pacman -Syu` may fix the root cause if MSYS2 releases an updated matplotlib
built for Python 3.14, but the stub workaround makes extraction work regardless.

---

## Key files

```
extractors/
  base.py              ExtractorAdapter ABC; parse() → CanonicalSample
  ct_fire.py           CTFireAdapter (implemented); Ridge Detection + SOAX still scaffolded

core/
  metrics.py           smooth_mask(), soft_iou(), rasterize_fiber_result()

app/controllers/
  extraction.py        ExtractionWorkflowMixin — choose input, run, save, soft-IOU
  export.py            _render_output_for_index — handles "ctfire_centerlines" target

app/workers/
  extraction_worker.py ExtractionWorker QThread

app/ui_sections/
  workflows.py         build_match_real_data_tab() — input button, extractor combo,
                       extraction status, soft-IOU group (enable checkbox + σ spinbox)
  display.py           preview_target_combo includes "CT-FIRE Centerlines" (index 3);
                       soft_iou_result_label below the preview group

app/main_window.py     ExtractionWorkflowMixin in base classes;
                       extracted_sample, match_input_path, extraction_worker state;
                       signal wiring for extraction buttons + soft-IOU triggers

export/model.py        CanonicalSample, CanonicalFiber, CanonicalPoint,
                       CanonicalImageArtifacts — the canonical data model

docs/
  extractor_session_summary.md  Running log of work sessions (append, never overwrite)
```

---

## CT-FIRE pipeline

```
User picks image
  → CTFireAdapter.parse({"image_path": ..., "params": None})
    → load_ctfire_params()           default FIRE params from ctfire_py
    → fire_2d_angle(p, im, plotflag=0)   C++ extension via fiber_backend
    → _build_canonical_fibers()     Xf/Ff → CanonicalFiber list  (row→y, col→x)
    → _build_centerline_mask()      rasterize_fiber_result() → uint8 skeleton
  → ExtractionWorker emits extraction_finished(CanonicalSample)
  → on_extraction_finished()
    → saves output_ctfire/<stem>_centerlines.tif  (uint8 × 255)
    → saves output_ctfire/<stem>_fibers.json      (CanonicalSample.to_centerlines_json())
    → sync_preview_target_choices()   enables "CT-FIRE Centerlines" in combo
```

### fire_2d_angle output keys used

| Key | Meaning |
|---|---|
| `Xf` | CurveAlign-filtered vertex matrix `[row, col, ...]` (preferred) |
| `Ff` | Filtered fiber list — each entry is a dict with `'v'` (vertex indices) |
| `Xa`, `Fa` | Network-level fallback if `Xf`/`Ff` are empty |
| `X`, `F`  | Raw fallback of last resort |

Always prefer `Xf`/`Ff` (fibers ≥ 30 px, matching what tme-quant validation uses).

---

## Soft-IOU metric

- **What it compares:** extracted centerline skeleton (CT-FIRE `Xf/Ff`) vs. generated
  centerline mask (`fiber_image.render_centerline_label_2d()`).
- **Trigger:** "CT-FIRE Centerlines" is the active preview target **AND**
  "Show centerline overlay" is checked **AND** "Compute soft-IOU" is enabled.
- **Formula:** `(m1·m2).sum() / (m1²+m2²−m1·m2).sum()`  on Gaussian-smoothed masks.
- **σ default:** 5 px (≈ 10 px FWHM — fiber scale tolerance).
  Expose in the soft-IOU σ spinbox (range 1–20 px, step 0.5).
- **Score display:** `soft_iou_result_label` in the display panel below the preview
  controls group.
- **Shape mismatch:** if generated and extracted images differ in size, the extracted
  mask is resized to match generated (PIL NEAREST interpolation).
- **Reference threshold:** ≥ 0.50 is a passing score (from tme-quant validation,
  Python vs. MATLAB comparison with >30 px filter).

---

## Preview target routing

| Combo item | Internal key | Enabled when |
|---|---|---|
| Fiber Image | `fiber_image` | `generate_fiber_checkbox` checked |
| Centerline Mask | `centerline_mask` | `generate_centerline_checkbox` checked |
| Enhanced Image | `enhanced` | enhanced output cached |
| CT-FIRE Centerlines | `ctfire_centerlines` | `extracted_sample is not None` |
| Reference (Planned) | `reference` | always disabled |
| Compare (Planned) | `compare` | always disabled |

Combo indices: 0 Fiber, 1 Centerline, 2 Enhanced, **3 CT-FIRE**, 4 Reference, 5 Compare.
`sync_preview_target_choices()` and `get_active_preview_target()` in `main_window.py`
both enumerate these; keep them in sync when adding new targets.

`restore_current_mode_preview()` in `session_state.py` skips the collection-present
check when the active target is `ctfire_centerlines` (extraction does not need a
generated collection).

---

## What is still scaffolded

| Item | File | Status |
|---|---|---|
| Ridge Detection adapter | `extractors/ridge_detection.py` | scaffold — `NotImplementedError` |
| SOAX adapter | `extractors/soax.py` | scaffold — `NotImplementedError` |
| `match_input_combo` (Reference source) | `workflows.py` | UI only — "Raw images" path not wired |
| Auto-update generator params | `app/controllers/param_suggestions.py` | done — "Suggest Generator Params" button in Match Real Data tab |
| 3D CT-FIRE extraction | `ctfire_py` | raises `NotImplementedError` until C++ 3D build |

---

## Rules for future work on this tab

0. **Do not modify any files under `H:\GitHub.06.2022\tme-quant\src\ctfire_py\`.**
   That package is maintained separately and its files are tested as-is.
   Work around any ctfire_py behaviour in our own code (subprocess script, adapters, etc.).

1. **Do not change the soft-IOU formula** in `core/metrics.py` without updating the
   reference threshold note above and the session summary.
2. **Xf/Ff first, always.** When consuming `fire_2d_angle` output, prefer filtered
   results over raw `X/F`.  If you change the fallback chain, note the reason.
3. **`CanonicalSample` is the canonical exchange format.** Any new extractor must
   return a fully populated `CanonicalSample` including `images.centerline_mask`.
4. **Keep `_build_render_fiber_image` calls guarded.** It raises if `collection` is
   None.  The ctfire_centerlines path in `_render_output_for_index` already guards
   this — do not remove that guard.
5. **Output folder is `output_ctfire/`.** Do not redirect to `output_2d/` or `output_3d/`;
   those are for generated images only.
6. **Append to `extractor_session_summary.md` after each session.** Include date,
   what was done, what is pending, and any gotchas discovered.
