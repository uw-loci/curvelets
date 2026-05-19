from __future__ import annotations

import numpy as np
from PIL import Image, ImageEnhance, ImageOps
from PyQt6.QtWidgets import QFileDialog

from app.workers import EnhancementWorker
from realism import (
    DEFAULT_STAGE2_PIPELINE_NAME,
    build_stage2_enhancement_recipe,
    get_default_stage2_model_dir,
    is_stage2_cgan_available,
)


class EnhancementWorkflowMixin:
    def get_current_enhancement_backend(self):
        pipeline = self.enhancement_pipeline_combo.currentText() if hasattr(self, "enhancement_pipeline_combo") else ""
        if pipeline == DEFAULT_STAGE2_PIPELINE_NAME:
            return "stage2_cgan"
        return None

    def get_current_enhancement_model_dir(self):
        if not hasattr(self, "enhancement_model_path_field"):
            return get_default_stage2_model_dir()
        model_dir = self.enhancement_model_path_field.text().strip()
        return model_dir or get_default_stage2_model_dir()

    def get_current_enhancement_device(self):
        if not hasattr(self, "enhancement_device_combo"):
            return "Auto"
        return self.enhancement_device_combo.currentText().strip() or "Auto"

    @staticmethod
    def enhancement_cuda_available():
        try:
            import torch
            return bool(torch.cuda.is_available())
        except Exception:
            return False

    @staticmethod
    def enhancement_mps_available():
        try:
            import torch
            return getattr(torch.backends, "mps", None) is not None and bool(torch.backends.mps.is_available())
        except Exception:
            return False

    def get_enhancement_preview_mode(self):
        if not hasattr(self, "enhancement_preview_combo"):
            return "normalized"
        preview_map = {
            "Raw": "raw",
            "Normalized": "normalized",
            "Normalized + contrast": "normalized_contrast",
        }
        return preview_map.get(self.enhancement_preview_combo.currentText(), "normalized")

    def get_current_mode_enhanced_outputs(self):
        return self.enhanced_outputs_3d if self.is_3d_mode else self.enhanced_outputs_2d

    def get_current_mode_enhancement_recipes(self):
        return self.enhancement_recipes_3d if self.is_3d_mode else self.enhancement_recipes_2d

    def get_cached_enhanced_output(self, index):
        return self.get_current_mode_enhanced_outputs().get(index)

    def get_cached_enhancement_recipe(self, index):
        return self.get_current_mode_enhancement_recipes().get(index)

    def clear_current_mode_enhanced_outputs(self):
        self.get_current_mode_enhanced_outputs().clear()
        self.get_current_mode_enhancement_recipes().clear()

    def choose_enhancement_model_path(self):
        start_dir = self.get_current_enhancement_model_dir()
        selected_dir = QFileDialog.getExistingDirectory(self, "Select Stage 2 Model Directory", start_dir)
        if selected_dir:
            self.enhancement_model_path_field.setText(selected_dir)
            self.update_enhancement_ui_state()

    def build_structural_centerline_input_2d(self, index):
        if self.collection is None or index < 0 or index >= self.collection.size():
            raise ValueError("No generated 2D sample is available for enhancement.")
        render_image = self._build_render_fiber_image(index)
        render_image.params.centerlineMaskWidthPx.value = 1
        centerline_mask = render_image.render_centerline_label_2d()
        return np.asarray(centerline_mask, dtype=np.uint8)

    @staticmethod
    def _normalize_enhanced_preview_array(image_np, low=2, high=98):
        image_arr = np.asarray(image_np, dtype=np.float32)
        p_low = np.percentile(image_arr, low)
        p_high = np.percentile(image_arr, high)
        if not np.isfinite(p_low) or not np.isfinite(p_high) or p_high <= p_low:
            return np.clip(image_arr, 0, 255).astype(np.uint8)
        normalized = np.clip((image_arr - p_low) / (p_high - p_low), 0.0, 1.0)
        return (normalized * 255.0).astype(np.uint8)

    @classmethod
    def prepare_enhanced_preview_output(cls, image_np, preview_mode):
        image_arr = np.asarray(image_np, dtype=np.uint8)
        if preview_mode == "raw":
            return image_arr
        normalized = cls._normalize_enhanced_preview_array(image_arr)
        if preview_mode == "normalized_contrast":
            contrast_image = Image.fromarray(normalized, mode='L')
            contrast_image = ImageOps.equalize(contrast_image)
            contrast_image = ImageOps.autocontrast(contrast_image, cutoff=1)
            contrast_image = ImageEnhance.Contrast(contrast_image).enhance(1.8)
            contrast_image = ImageEnhance.Sharpness(contrast_image).enhance(1.2)
            return np.asarray(contrast_image, dtype=np.uint8)
        return normalized

    def update_enhancement_ui_state(self):
        if not hasattr(self, "enhancement_backend_status"):
            return

        backend_key = self.get_current_enhancement_backend()
        model_dir = self.get_current_enhancement_model_dir()
        is_backend_busy = self.enhancement_worker is not None and self.enhancement_worker.isRunning()
        has_generated_samples = self.collection is not None and self.collection.size() > 0
        cuda_available = self.enhancement_cuda_available()
        mps_available = self.enhancement_mps_available()

        controls_enabled = backend_key == "stage2_cgan"
        self.enhancement_model_path_field.setEnabled(controls_enabled)
        self.enhancement_model_browse_button.setEnabled(controls_enabled)
        self.enhancement_device_combo.setEnabled(controls_enabled)
        self.enhancement_modality_combo.setEnabled(False)
        self.enhancement_modality_combo.setCurrentText("SHG")
        self.set_combo_item_enabled(self.enhancement_device_combo, 2, cuda_available)
        self.set_combo_item_enabled(self.enhancement_device_combo, 3, mps_available)
        if not cuda_available and self.enhancement_device_combo.currentText() == "CUDA":
            block = self.enhancement_device_combo.blockSignals(True)
            self.enhancement_device_combo.setCurrentText("Auto")
            self.enhancement_device_combo.blockSignals(block)
        if not mps_available and self.enhancement_device_combo.currentText() == "MPS":
            block = self.enhancement_device_combo.blockSignals(True)
            self.enhancement_device_combo.setCurrentText("Auto")
            self.enhancement_device_combo.blockSignals(block)

        if self.is_3d_mode:
            status_text = "2D only. The bundled model does not support 3D enhancement."
            can_run = False
        elif backend_key != "stage2_cgan":
            status_text = "Custom-model integration is not implemented yet."
            can_run = False
        else:
            try:
                build_stage2_enhancement_recipe(
                    model_dir=model_dir,
                    device=self.get_current_enhancement_device(),
                )
            except Exception as exc:
                status_text = f"Stage 2 cGAN unavailable. {exc}"
                can_run = False
                self.enhancement_backend_status.setText(status_text)
                self.enhance_current_button.setEnabled(False)
                self.enhance_batch_button.setEnabled(False)
                return
            available, status_message = is_stage2_cgan_available(model_dir)
            if not available:
                if "CUDA was requested" in status_message:
                    status_text = "CUDA is not available on this machine. Use Auto or CPU."
                elif "MPS was requested" in status_message:
                    status_text = "MPS is not available in this Python runtime. Use Auto or CPU."
                else:
                    status_text = f"Stage 2 cGAN unavailable. {status_message}"
                can_run = False
            elif not has_generated_samples:
                status_text = "Ready. Generate a 2D sample to enable inference."
                can_run = False
            else:
                status_text = "Ready. Uses a 2D 1-pixel centerline mask as input."
                can_run = True

        if is_backend_busy:
            status_text = "Running realism enhancement..."
            can_run = False

        self.enhancement_backend_status.setText(status_text)
        self.enhance_current_button.setEnabled(can_run)
        self.enhance_batch_button.setEnabled(can_run and self.collection is not None and self.collection.size() > 1)

    def _start_enhancement_worker(self, sample_inputs, recipe, completion_message):
        self.enhancement_worker = EnhancementWorker(
            sample_inputs=sample_inputs,
            model_dir=recipe["model_dir"],
            device=recipe["device"],
            recipe=recipe,
        )
        self.enhancement_worker.enhancement_finished.connect(
            lambda results, recipe_dict, message=completion_message: self.on_enhancement_finished(results, recipe_dict, message)
        )
        self.enhancement_worker.enhancement_failed.connect(self.on_enhancement_failed)
        self.statusBar().showMessage("Running realism enhancement...")
        self.refresh_ui_state()
        self.enhancement_worker.start()

    def enhance_current_pressed(self):
        try:
            if self.is_3d_mode:
                self.show_error("The bundled realism backend currently supports 2D centerline inputs only.")
                return
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated 2D sample is available for enhancement. Click Generate first.")
                return
            if self.enhancement_worker is not None and self.enhancement_worker.isRunning():
                self.show_error("Enhancement is already running.")
                return

            recipe = build_stage2_enhancement_recipe(
                model_dir=self.get_current_enhancement_model_dir(),
                device=self.get_current_enhancement_device(),
            )
            centerline_input = self.build_structural_centerline_input_2d(self.display_index)
            self._start_enhancement_worker(
                sample_inputs=[(self.display_index, centerline_input)],
                recipe=recipe,
                completion_message="Enhanced current 2D sample.",
            )
        except Exception as exc:
            self.show_error(str(exc))

    def enhance_batch_pressed(self):
        try:
            if self.is_3d_mode:
                self.show_error("The bundled realism backend currently supports 2D centerline inputs only.")
                return
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated 2D samples are available for enhancement. Click Generate first.")
                return
            if self.enhancement_worker is not None and self.enhancement_worker.isRunning():
                self.show_error("Enhancement is already running.")
                return

            recipe = build_stage2_enhancement_recipe(
                model_dir=self.get_current_enhancement_model_dir(),
                device=self.get_current_enhancement_device(),
            )
            sample_inputs = []
            for index in range(self.collection.size()):
                sample_inputs.append((index, self.build_structural_centerline_input_2d(index)))
            self._start_enhancement_worker(
                sample_inputs=sample_inputs,
                recipe=recipe,
                completion_message=f"Enhanced {len(sample_inputs)} 2D sample(s).",
            )
        except Exception as exc:
            self.show_error(str(exc))

    def on_enhancement_finished(self, results, recipe, completion_message):
        output_cache = self.get_current_mode_enhanced_outputs()
        recipe_cache = self.get_current_mode_enhancement_recipes()
        for index, enhanced_output in results.items():
            output_cache[index] = enhanced_output
            recipe_cache[index] = dict(recipe)
        worker = self.enhancement_worker
        self.enhancement_worker = None
        if worker is not None:
            worker.deleteLater()
        self._set_preview_target_if_available("Enhanced Image")
        self.statusBar().showMessage(completion_message, 4000)
        self.refresh_ui_state()
        self.redraw_image()

    def on_enhancement_failed(self, error):
        worker = self.enhancement_worker
        self.enhancement_worker = None
        if worker is not None:
            worker.deleteLater()
        self.refresh_ui_state()
        self.show_error(error)
