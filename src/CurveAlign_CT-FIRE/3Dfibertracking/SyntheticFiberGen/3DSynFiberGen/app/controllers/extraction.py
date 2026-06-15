from __future__ import annotations

import json
import os
import tempfile

import numpy as np
from PyQt6.QtWidgets import QFileDialog

from app.dialogs.ctfire_params_dialog import CTFireParamsDialog
from app.workers.extraction_worker import ExtractionWorker
from core.metrics import smooth_mask, soft_iou
from extractors.ct_fire import default_fire_params


class ExtractionWorkflowMixin:

    # ------------------------------------------------------------------
    # Input image loading
    # ------------------------------------------------------------------

    def choose_input_pressed(self):
        path, _ = QFileDialog.getOpenFileName(
            self,
            "Load input image",
            "",
            "Images (*.tif *.tiff *.png *.jpg *.jpeg);;All files (*)",
        )
        if not path:
            return
        self.match_input_path = path
        self.match_input_path_label.setText(os.path.basename(path))
        # Enable "Input Image" in the preview combo and switch to it
        self.sync_preview_target_choices()
        self.preview_target_combo.setCurrentText("Input Image")
        self.restore_current_mode_preview()

    # ------------------------------------------------------------------
    # CT-FIRE parameters dialog
    # ------------------------------------------------------------------

    def ctfire_params_pressed(self):
        current = getattr(self, "ctfire_params", None) or default_fire_params()
        dlg = CTFireParamsDialog(current, parent=self)
        if dlg.exec():
            self.ctfire_params = dlg.get_params(current)

    # ------------------------------------------------------------------
    # Extraction
    # ------------------------------------------------------------------

    def run_extraction_pressed(self):
        if hasattr(self, "suggest_params_button"):
            self.suggest_params_button.setEnabled(False)
        source_target = self.get_active_preview_target()
        image_path, has_ground_truth = self._get_extraction_image(source_target)
        if image_path is None:
            self.show_error(
                "Select a Fiber Image, Enhanced Image, or Input Image in the preview first."
            )
            return
        self._extraction_has_ground_truth = has_ground_truth
        self.run_extraction_button.setEnabled(False)
        self.extraction_status_label.setText("Running…")
        if hasattr(self, "soft_iou_enabled_checkbox"):
            self.soft_iou_enabled_checkbox.setEnabled(False)
        if hasattr(self, "show_ctfire_overlay_checkbox"):
            self.show_ctfire_overlay_checkbox.setEnabled(False)
        params = getattr(self, "ctfire_params", None) or default_fire_params()
        use_ct = (
            hasattr(self, "use_ct_reconstruction_checkbox")
            and self.use_ct_reconstruction_checkbox.isChecked()
            and self.use_ct_reconstruction_checkbox.isEnabled()
        )
        self.extraction_worker = ExtractionWorker({
            "image_path": image_path,
            "params": params,
            "use_ct_reconstruction": use_ct,
        })
        self.extraction_worker.extraction_finished.connect(self.on_extraction_finished)
        self.extraction_worker.extraction_failed.connect(self.on_extraction_failed)
        self.extraction_worker.start()

    def _get_extraction_image(self, target: str | None):
        """Return (image_path, has_ground_truth) for the given preview target.

        Saves a temp TIFF for generated targets; returns the raw path for
        input_image.  Returns (None, False) for non-extractable targets.
        """
        if target == "input_image":
            return self.match_input_path, False

        if target in ("fiber_image", "enhanced"):
            if self.collection is None or self.collection.size() == 0:
                return None, False
            try:
                from PIL import Image as PILImage

                if target == "fiber_image":
                    from generation.sample_2d import FiberImage
                    render_image = self._build_render_fiber_image(self.display_index)
                    base = render_image.render_fiber_image_2d()
                    pil_img = FiberImage.apply_postprocessing_2d(base, render_image.params)
                else:
                    pil_img = self.get_cached_enhanced_output(self.display_index)
                    if pil_img is None:
                        return None, False

                if not isinstance(pil_img, PILImage.Image):
                    pil_img = PILImage.fromarray(np.asarray(pil_img))

                pil_gray = pil_img.convert("L")
                tmp = tempfile.NamedTemporaryFile(suffix=".tif", delete=False)
                tmp.close()
                pil_gray.save(tmp.name)
                return tmp.name, True
            except Exception as exc:
                self.show_error(f"Could not render image for extraction:\n{exc}")
                return None, False

        return None, False

    def on_extraction_finished(self, sample):
        self.extracted_sample = sample
        n = len(sample.fibers)
        self.extraction_status_label.setText(f"Done — {n} fiber{'s' if n != 1 else ''} extracted")
        self._save_extraction_results(sample)
        self._on_extraction_complete()
        self.run_extraction_button.setEnabled(True)
        if hasattr(self, "soft_iou_enabled_checkbox"):
            self.soft_iou_enabled_checkbox.setEnabled(
                getattr(self, "_extraction_has_ground_truth", False)
            )
        if hasattr(self, "show_ctfire_overlay_checkbox"):
            self.show_ctfire_overlay_checkbox.setEnabled(True)
        if hasattr(self, "suggest_params_button"):
            self.suggest_params_button.setEnabled(True)

    def on_extraction_failed(self, msg: str):
        self.extraction_status_label.setText("Error — see message below")
        self.run_extraction_button.setEnabled(True)
        if hasattr(self, "soft_iou_enabled_checkbox"):
            self.soft_iou_enabled_checkbox.setEnabled(False)
        if hasattr(self, "show_ctfire_overlay_checkbox"):
            self.show_ctfire_overlay_checkbox.setEnabled(False)
        if hasattr(self, "suggest_params_button"):
            self.suggest_params_button.setEnabled(False)
        self.show_error(f"CT-FIRE extraction failed:\n{msg}")

    # ------------------------------------------------------------------
    # Persistence
    # ------------------------------------------------------------------

    def _save_extraction_results(self, sample):
        try:
            import tifffile

            project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            out_dir = os.path.join(project_dir, "output_ctfire")
            os.makedirs(out_dir, exist_ok=True)

            if sample.images.centerline_mask is not None:
                tif_path = os.path.join(out_dir, f"{sample.sample_id}_centerlines.tif")
                tifffile.imwrite(
                    tif_path, (sample.images.centerline_mask.astype(np.uint8) * 255)
                )

            json_path = os.path.join(out_dir, f"{sample.sample_id}_fibers.json")
            with open(json_path, "w") as fh:
                json.dump(sample.to_centerlines_json(), fh, indent=2)
        except Exception as exc:
            print(f"Warning: could not save CT-FIRE results: {exc}")

    # ------------------------------------------------------------------
    # Post-extraction UI sync
    # ------------------------------------------------------------------

    def _on_extraction_complete(self):
        self.sync_preview_target_choices()
        # Auto-check "Show centerline overlay" when soft-IOU is enabled with ground truth
        if (
            getattr(self, "_extraction_has_ground_truth", False)
            and getattr(self, "soft_iou_enabled_checkbox", None) is not None
            and self.soft_iou_enabled_checkbox.isChecked()
            and hasattr(self, "show_centerline_checkbox")
        ):
            self.show_centerline_checkbox.setChecked(True)
        # Switch to CT-FIRE Overlay; combo signal fires redraw + soft-IOU update
        self.preview_target_combo.setCurrentText("CT-FIRE Overlay")

    # ------------------------------------------------------------------
    # Soft-IOU
    # ------------------------------------------------------------------

    def _update_soft_iou_if_active(self, *_args):
        """Recompute and display soft-IOU when conditions are met.

        Conditions: CT-FIRE Overlay is the active preview target,
        'Compute soft-IOU' is checked, and extraction was run on a generated image.
        """
        if not hasattr(self, "soft_iou_result_label"):
            return
        if not getattr(self, "soft_iou_enabled_checkbox", None) or \
                not self.soft_iou_enabled_checkbox.isChecked():
            self.soft_iou_result_label.setText("Soft-IOU: —")
            return
        if self.get_active_preview_target() != "ctfire_centerlines":
            self.soft_iou_result_label.setText("Soft-IOU: —")
            return
        if not getattr(self, "_extraction_has_ground_truth", False):
            self.soft_iou_result_label.setText("Soft-IOU: n/a (no ground truth)")
            return
        self._compute_and_display_soft_iou()

    # ------------------------------------------------------------------
    # Suggest generator parameters from extracted fibers
    # ------------------------------------------------------------------

    def populate_generator_params_pressed(self):
        if getattr(self, "is_3d_mode", False):
            return
        sample = getattr(self, "extracted_sample", None)
        if sample is None:
            return
        from app.controllers.param_suggestions import (
            apply_suggestions_to_params,
            format_suggestions_summary,
            suggest_params_from_sample,
        )
        from PyQt6.QtWidgets import QMessageBox

        suggestions = suggest_params_from_sample(sample)
        reply = QMessageBox.question(
            self,
            "Apply Suggested Parameters?",
            format_suggestions_summary(suggestions),
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No,
        )
        if reply == QMessageBox.StandardButton.Yes:
            apply_suggestions_to_params(self.params, suggestions)
            self.display_params()

    def _compute_and_display_soft_iou(self):
        extracted = getattr(self, "extracted_sample", None)
        if extracted is None or extracted.images.centerline_mask is None:
            self.soft_iou_result_label.setText("Soft-IOU: n/a (no extraction)")
            return
        if self.collection is None or self.collection.size() == 0:
            self.soft_iou_result_label.setText("Soft-IOU: n/a (no generated image)")
            return
        try:
            from PIL import Image as PILImage

            fiber_image = self._build_render_fiber_image(self.display_index)
            gen_mask_pil = fiber_image.render_centerline_label_2d()
            gen_mask = (np.array(gen_mask_pil.convert("L")) > 127).astype(np.float32)

            ext_mask = extracted.images.centerline_mask.astype(np.float32)
            if ext_mask.max() > 1.0:
                ext_mask = (ext_mask > 127).astype(np.float32)

            if gen_mask.shape != ext_mask.shape:
                ext_pil = PILImage.fromarray((ext_mask * 255).astype(np.uint8))
                ext_pil = ext_pil.resize(
                    (gen_mask.shape[1], gen_mask.shape[0]), PILImage.NEAREST
                )
                ext_mask = (np.array(ext_pil) > 127).astype(np.float32)

            sigma = self.soft_iou_sigma_spinbox.value()
            score = soft_iou(smooth_mask(gen_mask, sigma), smooth_mask(ext_mask, sigma))
            self.soft_iou_result_label.setText(f"Soft-IOU: {score:.4f}")
        except Exception as exc:
            self.soft_iou_result_label.setText("Soft-IOU: error")
            print(f"Soft-IOU computation error: {exc}")
