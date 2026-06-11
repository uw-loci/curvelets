# Extractor Session Summaries

Append a new section after each working session.
Format: `## YYYY-MM-DD HH:MM — <one-line topic>`

---

## 2026-06-10 — MSYS2 UCRT64 setup + CT-FIRE extractor integration (initial)

### What was done

**Environment & tooling**
- Added MSYS2 UCRT64 terminal profile to root `.vscode/settings.json`
  (`h:\GitHub.06.2022\curvelets\.vscode\settings.json`).
- Added matching profile to the 3DSynFiberGen-level
  `.vscode/settings.json` (for when the subfolder is opened directly).
- Created `setup_ucrt64_env.sh` — one-shot bash script that creates `.venv`
  from UCRT64 Python 3.14, runs `pip install -e ".[gui]"`, and writes the
  `ctfire_src.pth` file so `ctfire_py` is importable.

**New files**
| File | Purpose |
|---|---|
| `core/metrics.py` | `smooth_mask`, `soft_iou`, `rasterize_fiber_result` (ported from tme-quant test) |
| `app/workers/extraction_worker.py` | `ExtractionWorker(QThread)` — runs CTFireAdapter in background |
| `app/controllers/extraction.py` | `ExtractionWorkflowMixin` — choose input, run, save results, compute soft-IOU |
| `CLAUDE_EXTRACTOR.md` | Rules & reference notes for extractor work |
| `docs/extractor_session_summary.md` | This file |

**Modified files**
| File | Change |
|---|---|
| `extractors/ct_fire.py` | Full `CTFireAdapter.parse()` using `fire_2d_angle`; `_build_canonical_fibers`, `_build_centerline_mask` |
| `app/ui_sections/workflows.py` | Match Real Data tab: active "Choose input…" button, path label, status label, soft-IOU group (enable checkbox + σ spinbox) |
| `app/ui_sections/display.py` | Added "CT-FIRE Centerlines" to preview combo (index 3); `soft_iou_result_label` below preview group |
| `app/controllers/export.py` | `_render_output_for_index` handles `ctfire_centerlines` before building render_image |
| `app/controllers/session_state.py` | `restore_current_mode_preview` bypasses collection check for `ctfire_centerlines` target |
| `app/main_window.py` | `ExtractionWorkflowMixin` in base classes; state init; signal wiring; preview routing updated |
| `app/controllers/__init__.py` | Exports `ExtractionWorkflowMixin` |

### Soft-IOU design decision
Reused the existing "Show centerline overlay" checkbox as the trigger (rather than
adding a new one). When "CT-FIRE Centerlines" is the active target AND the overlay
is checked AND "Compute soft-IOU" is enabled: generated centerlines are overlaid on
the CT-FIRE mask in napari, and the score appears in `soft_iou_result_label` below
the preview panel. σ spinbox updates the score live.

### Gotchas / notes
- **VS Code terminal profile location:** must be in the *workspace root*
  `.vscode/settings.json` (`curvelets/`), not the nested subfolder one.
  The nested file is only used when that subfolder is opened as its own workspace.
- **fiber_backend binary is Python 3.14-specific.**
  `fiber_backend.cp314-mingw_x86_64_ucrt_gnu.pyd` will not load in any other Python
  version.  If `HAS_FIBER_BACKEND` is False, check Python version first.
- **ctfire_py is not pip-installable directly** due to the two-level `src/` layout in
  tme-quant.  The `.pth` file approach is the correct solution (see setup script).
- **Combo index shift:** adding "CT-FIRE Centerlines" at index 3 shifted "Reference
  (Planned)" to 4 and "Compare (Planned)" to 5.  `sync_preview_target_choices` uses
  hard-coded indices — keep them consistent with `display.py` item order.
- **render_image can be None** for CT-FIRE target when no collection exists.
  `populate_2d_viewer` in napari_bridge handles `fiber_image=None` gracefully
  (skips overlay); no additional guard needed in display path.

### Pending / next steps
- [ ] Run `setup_ucrt64_env.sh` and verify `fire_2d_angle` import in the UCRT64 venv
- [ ] End-to-end test: choose TIFF → Run Extraction → verify centerline TIFF + JSON
      written to `output_ctfire/`
- [ ] Verify "CT-FIRE Centerlines" shows in preview dropdown after extraction
- [ ] Verify soft-IOU score updates when "Show centerline overlay" is checked
- [ ] Implement Ridge Detection adapter (`extractors/ridge_detection.py`)
- [ ] Implement SOAX adapter (`extractors/soax.py`)
- [ ] Wire "Raw images" path in `match_input_combo` (currently UI-only)
- [ ] Consider auto-populating generator params from extracted fiber statistics
