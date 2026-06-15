from __future__ import annotations

import os
from copy import deepcopy
from datetime import datetime

import numpy as np
from PIL import Image
from PyQt6.QtWidgets import QCheckBox, QFileDialog, QInputDialog, QMessageBox

from export.builders import build_canonical_sample, build_dataset_manifest_rows
from export.schema import EXPORT_DETAIL_CONCISE, EXPORT_DETAIL_FULL
from export.writers import (
    export_canonical_research_package,
    export_full_raw_geometry,
    export_session_restore,
    write_dataset_manifest,
)
from generation.sample_2d import FiberImage
from generation.sample_3d import FiberImage3D


class ExportWorkflowMixin:
    def get_export_detail_level(self):
        if not hasattr(self, "export_detail_combo"):
            return EXPORT_DETAIL_CONCISE
        return EXPORT_DETAIL_FULL if self.export_detail_combo.currentText() == "Full geometry package" else EXPORT_DETAIL_CONCISE

    def _update_fiber_params_from_ui(self, fiber_params):
        try:
            if hasattr(fiber_params, 'generateCenterlineLabel'):
                fiber_params.generateCenterlineLabel.value = bool(self.generate_centerline_checkbox.isChecked())
            if hasattr(fiber_params, 'generateFiberImage'):
                fiber_params.generateFiberImage.value = bool(self.generate_fiber_checkbox.isChecked())
            if hasattr(fiber_params, 'centerlineOutputType'):
                fiber_params.centerlineOutputType.value = "Binary"
            if hasattr(fiber_params, 'centerlineMaskWidthPx'):
                fiber_params.centerlineMaskWidthPx.value = int(self.centerline_mask_width_field.text() or fiber_params.centerlineMaskWidthPx.value)
            if hasattr(fiber_params, 'maskOutputMode'):
                fiber_params.maskOutputMode.value = "Binary"
            if hasattr(fiber_params, 'sync_legacy_output_fields'):
                fiber_params.sync_legacy_output_fields()
            if hasattr(fiber_params, 'showCenterlineOverlay'):
                fiber_params.showCenterlineOverlay.use = bool(self.show_centerline_checkbox.isChecked())
            if hasattr(fiber_params, 'centerlineOverlayColor'):
                fiber_params.centerlineOverlayColor.value = self.centerline_color_combo.currentText()
            if hasattr(fiber_params, 'centerlineOverlayBrightness'):
                fiber_params.centerlineOverlayBrightness.value = 1.2

            fiber_params.bubble.use = bool(self.bubble_check.isChecked())
            fiber_params.bubble.value = int(self.bubble_field.text() or fiber_params.bubble.value)
            fiber_params.swap.use = bool(self.swap_check.isChecked())
            fiber_params.swap.value = int(self.swap_field.text() or fiber_params.swap.value)
            fiber_params.spline.use = bool(self.spline_check.isChecked())
            fiber_params.spline.value = int(self.spline_field.text() or fiber_params.spline.value)

            if hasattr(fiber_params, 'distance'):
                if self.is_3d_mode and hasattr(self, 'distance_falloff_check'):
                    fiber_params.distance.use = bool(self.distance_falloff_check.isChecked())
                    fiber_params.distance.value = float(self.distance_falloff_field.text() or fiber_params.distance.value)
                else:
                    fiber_params.distance.use = bool(self.distance_check.isChecked())
                    fiber_params.distance.value = float(self.distance_field.text() or fiber_params.distance.value)
            if hasattr(fiber_params, 'distanceFalloff'):
                fiber_params.distanceFalloff.use = bool(self.distance_falloff_check.isChecked())
                fiber_params.distanceFalloff.value = float(self.distance_falloff_field.text() or fiber_params.distanceFalloff.value)
            if hasattr(fiber_params, 'cap'):
                fiber_params.cap.use = bool(self.cap_check.isChecked())
                fiber_params.cap.value = int(self.cap_field.text() or fiber_params.cap.value)
            if hasattr(fiber_params, 'normalize'):
                fiber_params.normalize.use = bool(self.normalize_check.isChecked())
                fiber_params.normalize.value = int(self.normalize_field.text() or fiber_params.normalize.value)
            if hasattr(fiber_params, 'downSample'):
                fiber_params.downSample.use = bool(self.sample_check.isChecked())
                fiber_params.downSample.value = float(self.sample_field.text() or fiber_params.downSample.value)
            if hasattr(fiber_params, 'blur'):
                if self.is_3d_mode and hasattr(self, 'blur_radius_check'):
                    fiber_params.blur.use = bool(self.blur_radius_check.isChecked())
                    fiber_params.blur.value = float(self.blur_radius_field.text() or fiber_params.blur.value)
                else:
                    fiber_params.blur.use = bool(self.blur_check.isChecked())
                    fiber_params.blur.value = float(self.blur_field.text() or fiber_params.blur.value)
            if hasattr(fiber_params, 'blurRadius'):
                fiber_params.blurRadius.use = bool(self.blur_radius_check.isChecked())
                fiber_params.blurRadius.value = float(self.blur_radius_field.text() or fiber_params.blurRadius.value)
            if hasattr(fiber_params, 'scale'):
                fiber_params.scale.use = bool(self.scale_check.isChecked())
                fiber_params.scale.value = float(self.scale_field.text() or fiber_params.scale.value)

            model = self.noise_model_combo.currentText().lower()
            if hasattr(fiber_params, 'noiseModel'):
                fiber_params.noiseModel.value = model.title() if model != 'no noise' else 'No Noise'
            if hasattr(fiber_params, 'noise'):
                noise_enabled = self.noise_mean_check.isChecked() if self.is_3d_mode else self.noise_check.isChecked()
                noise_text = self.noise_mean_field.text() if self.is_3d_mode else self.noise_field.text()
                fiber_params.noise.use = (model in ('poisson', 'poisson+gaussian')) and noise_enabled
                if noise_text:
                    fiber_params.noise.value = float(noise_text)
            if hasattr(fiber_params, 'noiseMean'):
                fiber_params.noiseMean.use = (model in ('poisson', 'poisson+gaussian')) and self.noise_mean_check.isChecked()
                if hasattr(self, 'noise_mean_field') and self.noise_mean_field.text():
                    fiber_params.noiseMean.value = float(self.noise_mean_field.text())
            if hasattr(fiber_params, 'noiseStdDev'):
                fiber_params.noiseStdDev.use = (model in ('gaussian', 'poisson+gaussian')) and self.noise_std_check.isChecked()
                if self.noise_std_field.text():
                    fiber_params.noiseStdDev.value = float(self.noise_std_field.text())
            if hasattr(fiber_params, 'saltPepperProb'):
                fiber_params.saltPepperProb.use = (model == 'salt-and-pepper') and self.saltpepper_check.isChecked()
                if self.saltpepper_field.text():
                    fiber_params.saltPepperProb.value = float(self.saltpepper_field.text())
        except Exception:
            pass

    def _apply_ui_smoothing_to_fiber_image(self, fiber_image):
        is_volume = isinstance(fiber_image, FiberImage3D)
        for fiber in fiber_image.fibers:
            if fiber_image.params.bubble.use:
                if is_volume:
                    fiber.bubble_smooth_3d(fiber_image.params.bubble.get_value())
                else:
                    fiber.bubble_smooth(fiber_image.params.bubble.get_value())
            if fiber_image.params.swap.use:
                if is_volume:
                    fiber.swap_smooth_3d(fiber_image.params.swap.get_value())
                else:
                    fiber.swap_smooth(fiber_image.params.swap.get_value())
            if fiber_image.params.spline.use:
                fiber.spline_smooth(fiber_image.params.spline.get_value())
        for fiber in fiber_image.fibers:
            fiber.calculate_orientations()

    def _build_render_fiber_image(self, index):
        source_image = self.collection.get(index)
        render_params = deepcopy(source_image.params)
        self._update_fiber_params_from_ui(render_params)
        render_image = FiberImage3D(render_params) if self.is_3d_mode else FiberImage(render_params)

        try:
            render_image.fibers = deepcopy(self.original_fibers_by_index[index])
        except Exception:
            render_image.fibers = deepcopy(source_image.fibers)

        self._apply_ui_smoothing_to_fiber_image(render_image)
        if self.is_3d_mode:
            render_image.apply_topology_3d()
            for fiber in render_image.fibers:
                fiber.calculate_orientations()
            render_image.joints_dirty = False
        else:
            try:
                render_image.ensure_joints()
            except Exception:
                render_image.joint_points = deepcopy(getattr(source_image, 'joint_points', []))
                render_image.joints_dirty = False

        return render_image

    def build_session_restore_state(self):
        return {
            "current_mode": "3D" if self.is_3d_mode else "2D",
            "params_2d": self.params_2d.to_dict() if hasattr(self, "params_2d") else None,
            "params_3d": self.params_3d.to_dict() if hasattr(self, "params_3d") else None,
            "display_index_2d": getattr(self, "display_index_2d", 0),
            "display_index_3d": getattr(self, "display_index_3d", 0),
            "active_preview_target": self.get_active_preview_target(),
            "preview_target_label": self.preview_target_combo.currentText(),
            "preview_3d_view": self.get_3d_view_mode(),
            "show_joints": bool(self.show_joints_checkbox.isChecked()),
            "show_centerline_overlay": bool(self.show_centerline_checkbox.isChecked()),
            "centerline_overlay_color": self.centerline_color_combo.currentText(),
            "generate_centerline_mask": bool(self.generate_centerline_checkbox.isChecked()),
            "generate_fiber_image": bool(self.generate_fiber_checkbox.isChecked()),
            "enhancement_pipeline": self.enhancement_pipeline_combo.currentText(),
            "enhancement_modality": self.enhancement_modality_combo.currentText(),
            "enhancement_model_dir": self.get_current_enhancement_model_dir(),
            "enhancement_device": self.get_current_enhancement_device(),
            "enhancement_preview_mode": self.get_enhancement_preview_mode(),
            "export_detail": self.get_export_detail_level(),
            "out_folder_2d": getattr(self, "out_folder_2d", None),
            "out_folder_3d": getattr(self, "out_folder_3d", None),
        }

    def _default_sample_name(self, index):
        return f"{'3d' if self.is_3d_mode else '2d'}_sample_{index:03d}"

    def _build_export_sample_for_index(self, index, sample_name=None):
        render_image = self._build_render_fiber_image(index)
        centerline_mask = None
        fiber_output = None
        enhanced_output = self.get_cached_enhanced_output(index) if not self.is_3d_mode else None
        base_fiber_output = None

        if self.generate_centerline_checkbox.isChecked():
            if self.is_3d_mode:
                centerline_mask = render_image.render_centerline_volume_3d()
            else:
                centerline_mask = render_image.render_centerline_label_2d()

        if self.generate_fiber_checkbox.isChecked():
            if self.is_3d_mode:
                base_fiber_output = render_image.render_fiber_volume_3d()
                fiber_output = FiberImage3D.apply_postprocessing_3d(base_fiber_output, render_image.params)
            else:
                base_fiber_output = render_image.render_fiber_image_2d()
                fiber_output = FiberImage.apply_postprocessing_2d(base_fiber_output, render_image.params)

        if self.is_3d_mode:
            render_image.calculate_validation_metrics_3d(
                fiber_volume=base_fiber_output,
                centerline_volume=centerline_mask,
            )

        sample_name = sample_name or self._default_sample_name(index)
        sample = build_canonical_sample(
            render_image,
            image_id=sample_name,
            sample_id=sample_name,
            centerline_mask=centerline_mask,
            fiber_image_array=fiber_output,
            enhanced_image=enhanced_output,
        )
        if enhanced_output is not None:
            sample.enhancement_recipe = deepcopy(self.get_cached_enhancement_recipe(index))
        return sample

    def _export_sample_to_directory(self, index, sample_dir, export_detail, include_session_restore):
        sample_name = os.path.basename(sample_dir)
        sample = self._build_export_sample_for_index(index, sample_name=sample_name)
        if export_detail == EXPORT_DETAIL_FULL:
            export_full_raw_geometry(sample_dir, sample, include_excel=True)
        else:
            export_canonical_research_package(sample_dir, sample, include_excel=True)
        if include_session_restore:
            export_session_restore(sample_dir, self.build_session_restore_state())
        return build_dataset_manifest_rows(sample, sample_dir)

    def _render_output_for_index(self, index, output_target=None):
        preview_target = output_target or self.get_active_preview_target()
        if preview_target is None:
            raise ValueError("Enable at least one derived output before previewing or saving.")

        # Input image: display the loaded real image; no generated collection needed
        if preview_target == "input_image":
            path = getattr(self, "match_input_path", None)
            if not path:
                raise ValueError("No input image loaded. Use 'Load input image…' first.")
            final_output = Image.open(path).convert("RGB")
            return None, final_output

        # CT-FIRE overlay: show per-fiber colored overlay image (fallback to centerline mask)
        if preview_target == "ctfire_centerlines":
            extracted = getattr(self, "extracted_sample", None)
            if extracted is None:
                raise ValueError("No CT-FIRE results available. Run extraction first.")
            if extracted.images.overlay_image is not None:
                final_output = Image.fromarray(extracted.images.overlay_image).convert("RGB")
            elif extracted.images.centerline_mask is not None:
                mask = np.asarray(extracted.images.centerline_mask, dtype=np.uint8)
                if mask.max() <= 1:
                    mask = mask * 255
                final_output = Image.fromarray(mask).convert("RGB")
            else:
                raise ValueError("No CT-FIRE image available. Run extraction first.")
            render_image = None
            if self.collection is not None and self.collection.size() > 0:
                try:
                    render_image = self._build_render_fiber_image(index)
                except Exception:
                    pass
            return render_image, final_output

        render_image = self._build_render_fiber_image(index)
        if preview_target == "enhanced":
            raw_output = self.get_cached_enhanced_output(index)
            final_output = self.prepare_enhanced_preview_output(
                raw_output,
                self.get_enhancement_preview_mode(),
            ) if raw_output is not None else None
            if final_output is None:
                raise ValueError("No enhanced image is cached for the selected sample.")
        elif preview_target == "centerline_mask":
            if self.is_3d_mode:
                final_output = render_image.render_centerline_volume_3d()
            else:
                final_output = render_image.render_centerline_label_2d()
        else:
            if self.is_3d_mode:
                base_output = render_image.render_fiber_volume_3d()
                final_output = FiberImage3D.apply_postprocessing_3d(base_output, render_image.params)
            else:
                base_output = render_image.render_fiber_image_2d()
                final_output = FiberImage.apply_postprocessing_2d(base_output, render_image.params)
        return render_image, final_output

    def save_current_preview_pressed(self):
        self._save_selected_result(custom=self.export_custom_checkbox.isChecked())

    def save_all_preview_pressed(self):
        self._save_all_results(custom=self.export_custom_checkbox.isChecked())

    def save_results_pressed(self):
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to export. Click Generate first.")
                return

            box = QMessageBox(self)
            box.setWindowTitle("Export")
            box.setText("Export the current sample or all generated samples?")
            save_selected_btn = box.addButton("Export Current", QMessageBox.ButtonRole.AcceptRole)
            save_all_btn = box.addButton("Export All", QMessageBox.ButtonRole.AcceptRole)
            box.addButton(QMessageBox.StandardButton.Cancel)
            custom_check = QCheckBox("Choose name and location")
            box.setCheckBox(custom_check)
            box.exec()

            custom = custom_check.isChecked()
            clicked = box.clickedButton()
            if clicked is save_all_btn:
                self._save_all_results(custom=custom)
            elif clicked is save_selected_btn:
                self._save_selected_result(custom=custom)
        except Exception as exc:
            self.show_error(str(exc))

    def _save_selected_result(self, custom: bool = False):
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to export. Click Generate first.")
                return

            base_out = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
            export_detail = self.get_export_detail_level()
            include_session_restore = self.export_session_checkbox.isChecked()
            sample_name = self._default_sample_name(self.display_index)

            if custom:
                parent_dir = QFileDialog.getExistingDirectory(self, "Select Export Directory", base_out)
                if not parent_dir:
                    return
                sample_name_input, ok = QInputDialog.getText(
                    self,
                    "Sample Folder Name",
                    "Sample folder name:",
                    text=sample_name,
                )
                if not ok:
                    return
                sample_name = sample_name_input.strip() or sample_name
                parent_dir = os.path.abspath(parent_dir)
            else:
                parent_dir = self._make_unique_save_dir(base_out)

            sample_dir = self._make_unique_named_dir(parent_dir, sample_name)
            manifest_row = self._export_sample_to_directory(
                self.display_index,
                sample_dir,
                export_detail=export_detail,
                include_session_restore=include_session_restore,
            )
            write_dataset_manifest(parent_dir, [manifest_row])

            QMessageBox.information(self, "Exported", f"Exported current sample package to:\n{sample_dir}")
        except Exception as exc:
            self.show_error(str(exc))

    def _save_all_results(self, custom: bool = False):
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to export. Click Generate first.")
                return
            base_out = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
            export_detail = self.get_export_detail_level()
            include_session_restore = self.export_session_checkbox.isChecked()
            if custom:
                parent_dir = QFileDialog.getExistingDirectory(self, "Select Export Directory", base_out)
                if not parent_dir:
                    return
                default_prefix = f"{'3d' if self.is_3d_mode else '2d'}_sample_"
                prefix, ok = QInputDialog.getText(self, "Sample Prefix", "Sample folder prefix:", text=default_prefix)
                if not ok:
                    return
                prefix = prefix.strip() or default_prefix
            else:
                parent_dir = self._make_unique_save_dir(base_out)
                prefix = f"{'3d' if self.is_3d_mode else '2d'}_sample_"

            dataset_rows = []
            for i in range(self.collection.size()):
                sample_dir = self._make_unique_named_dir(parent_dir, f"{prefix}{i:03d}")
                dataset_rows.append(
                    self._export_sample_to_directory(
                        i,
                        sample_dir,
                        export_detail=export_detail,
                        include_session_restore=include_session_restore,
                    )
                )

            write_dataset_manifest(parent_dir, dataset_rows)
            QMessageBox.information(self, "Exported", f"Exported {self.collection.size()} sample packages to:\n{parent_dir}")
        except Exception as exc:
            self.show_error(str(exc))

    def _make_unique_save_dir(self, base_folder: str) -> str:
        try:
            os.makedirs(base_folder, exist_ok=True)
        except Exception:
            pass
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        root = os.path.join(base_folder, f"save_{timestamp}")
        candidate = root
        counter = 1
        while os.path.exists(candidate):
            candidate = f"{root}_{counter:02d}"
            counter += 1
        os.makedirs(candidate, exist_ok=True)
        return candidate

    def _make_unique_named_dir(self, parent_folder: str, base_name: str) -> str:
        os.makedirs(parent_folder, exist_ok=True)
        candidate = os.path.join(parent_folder, base_name)
        counter = 1
        while os.path.exists(candidate):
            candidate = os.path.join(parent_folder, f"{base_name}_{counter:02d}")
            counter += 1
        os.makedirs(candidate, exist_ok=True)
        return candidate
