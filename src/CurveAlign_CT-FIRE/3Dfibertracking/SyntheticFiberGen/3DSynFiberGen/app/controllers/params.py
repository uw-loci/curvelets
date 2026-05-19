from __future__ import annotations

from PyQt6.QtWidgets import QFileDialog

from generation.collections import ImageCollection, ImageCollection3D
from generation.sample_2d import FiberImage


class ParameterWorkflowMixin:
    def parse_params(self):
        self.params.nImages.parse(self.n_images_field.text(), int)
        self.params.seed.parse(self.seed_check.isChecked(), self.seed_field.text(), int)
        self.params.nFibers.parse(self.n_fibers_field.text(), int)
        self.params.segmentLength.parse(self.segment_field.text(), float)
        self.params.widthChange.parse(self.width_change_field.text(), float)
        self.params.generateCenterlineLabel.value = self.generate_centerline_checkbox.isChecked()
        self.params.generateFiberImage.value = self.generate_fiber_checkbox.isChecked()
        self.params.centerlineOutputType.value = "Binary"
        self.params.centerlineMaskWidthPx.parse(self.centerline_mask_width_field.text(), int)
        self.params.maskOutputMode.value = "Binary"
        if hasattr(self.params, "sync_legacy_output_fields"):
            self.params.sync_legacy_output_fields()

        if self.is_3d_mode:
            self.params.imageDepth.parse(self.image_depth_field.text(), int)
            self.params.curvature.parse(self.curvature_field.text(), float)
            self.params.branchingProbability.parse(self.branching_probability_field.text(), float)
            self.params.meanDirection.parse(self.mean_direction_field.text(), float)
            self.params.alignment3D.parse(self.alignment3D_field.text(), float)
            self.params.noiseMean.parse(self.noise_mean_check.isChecked(), self.noise_mean_field.text(), float)
            self.params.noise.use = self.noise_mean_check.isChecked()
            self.params.distanceFalloff.parse(self.distance_falloff_check.isChecked(), self.distance_falloff_field.text(), float)
            self.params.blurRadius.parse(self.blur_radius_check.isChecked(), self.blur_radius_field.text(), float)
            self.params.minAngleChange.parse(self.min_angle_change_field.text(), float)
            self.params.maxAngleChange.parse(self.max_angle_change_field.text(), float)
        else:
            self.params.meanAngle.parse(self.mean_angle_field.text(), float)
            self.params.alignment.parse(self.alignment_field.text(), float)
            self.params.noise.parse(self.noise_check.isChecked(), self.noise_field.text(), float)
            self.params.distance.parse(self.distance_check.isChecked(), self.distance_field.text(), float)
            self.params.blur.parse(self.blur_check.isChecked(), self.blur_field.text(), float)
            self.params.showJoints.use = self.show_joints_checkbox.isChecked()
            self.params.useJoints.use = self.use_joints_checkbox.isChecked()

            if self.use_joints_checkbox.isChecked():
                self.params.jointPoints.parse(self.joint_points_field.text(), int)

        self.params.showCenterlineOverlay.use = self.show_centerline_checkbox.isChecked()
        self.params.centerlineOverlayColor.parse(self.centerline_color_combo.currentText(), str)
        self.params.centerlineOverlayBrightness.parse("1.2", float)

        self.params.noiseModel.parse(self.noise_model_combo.currentText(), str)
        self.params.noiseStdDev.parse(self.noise_std_check.isChecked(), self.noise_std_field.text(), float)
        self.params.saltPepperProb.parse(self.saltpepper_check.isChecked(), self.saltpepper_field.text(), float)

        self.params.imageWidth.parse(self.image_width_field.text(), int)
        self.params.imageHeight.parse(self.image_height_field.text(), int)
        self.params.imageBuffer.parse(self.image_buffer_field.text(), int)
        self.params.scale.parse(self.scale_check.isChecked(), self.scale_field.text(), float)
        self.params.downSample.parse(self.sample_check.isChecked(), self.sample_field.text(), float)
        self.params.cap.parse(self.cap_check.isChecked(), self.cap_field.text(), int)
        self.params.normalize.parse(self.normalize_check.isChecked(), self.normalize_field.text(), int)
        self.params.bubble.parse(self.bubble_check.isChecked(), self.bubble_field.text(), int)
        self.params.swap.parse(self.swap_check.isChecked(), self.swap_field.text(), int)
        self.params.spline.parse(self.spline_check.isChecked(), self.spline_field.text(), int)
        self.params.psfEnabled.use = self.apply_psf_checkbox.isChecked()
        self.params.psfType.parse(self.psf_type_combo.currentText(), str)
        self.params.psfGaussianNA.parse(self.psf_gaussian_na_field.text(), float)
        self.params.psfGaussianWavelength.parse(self.psf_gaussian_wavelength_field.text(), float)
        self.params.psfPixelSizeZ.parse(self.psf_voxel_z_field.text(), float)
        self.params.psfPixelSizeY.parse(self.psf_voxel_y_field.text(), float)
        self.params.psfPixelSizeX.parse(self.psf_voxel_x_field.text(), float)
        self.params.psfVectorialNA.parse(self.psf_vectorial_na_field.text(), float)
        self.params.psfVectorialMediumRI.parse(self.psf_vectorial_medium_ri_field.text(), float)
        self.params.psfVectorialSampleRI.parse(self.psf_vectorial_sample_ri_field.text(), float)
        self.params.psfVectorialWavelength.parse(self.psf_vectorial_wavelength_field.text(), float)
        self.params.psfVectorialPolarization.parse(self.psf_vectorial_polarization_field.text(), float)
        self.params.psfVectorialVolumeZ.parse(self.psf_vectorial_volume_z_field.text(), float)
        self.params.psfVectorialVolumeY.parse(self.psf_vectorial_volume_y_field.text(), float)
        self.params.psfVectorialVolumeX.parse(self.psf_vectorial_volume_x_field.text(), float)
        self.params.psfVectorialShapeZ.parse(self.psf_vectorial_shape_z_field.text(), int)
        self.params.psfVectorialShapeY.parse(self.psf_vectorial_shape_y_field.text(), int)
        self.params.psfVectorialShapeX.parse(self.psf_vectorial_shape_x_field.text(), int)

    def display_params(self):
        self.n_images_field.setText(self.params.nImages.get_string())
        self.seed_check.setChecked(self.params.seed.use)
        self.seed_field.setText(self.params.seed.get_string())

        self.length_display.setText(self.params.length.get_string())
        self.width_display.setText(self.params.width.get_string())
        self.straight_display.setText(self.params.straightness.get_string())
        self.intensity_display.setText(self.params.intensity.get_string())

        self.n_fibers_field.setText(self.params.nFibers.get_string())
        self.segment_field.setText(self.params.segmentLength.get_string())
        self.width_change_field.setText(self.params.widthChange.get_string())
        self.generate_centerline_checkbox.setChecked(FiberImage.should_generate_centerline_label(self.params))
        self.generate_fiber_checkbox.setChecked(FiberImage.should_generate_fiber_image(self.params))
        self.centerline_mask_width_field.setText(self.params.centerlineMaskWidthPx.get_string())

        if self.is_3d_mode:
            self.image_depth_field.setText(self.params.imageDepth.get_string())
            self.curvature_field.setText(self.params.curvature.get_string())
            self.branching_probability_field.setText(self.params.branchingProbability.get_string())
            self.mean_direction_field.setText(self.params.meanDirection.get_string())
            self.alignment3D_field.setText(self.params.alignment3D.get_string())
            self.noise_mean_field.setText(self.params.noiseMean.get_string())
            self.noise_mean_check.setChecked(self.params.noise.use or self.params.noiseMean.use)
            self.distance_falloff_field.setText(self.params.distanceFalloff.get_string())
            self.distance_falloff_check.setChecked(self.params.distanceFalloff.use)
            self.blur_radius_field.setText(self.params.blurRadius.get_string())
            self.blur_radius_check.setChecked(self.params.blurRadius.use)
            self.min_angle_change_field.setText(self.params.minAngleChange.get_string())
            self.max_angle_change_field.setText(self.params.maxAngleChange.get_string())
        else:
            self.mean_angle_field.setText(self.params.meanAngle.get_string())
            self.alignment_field.setText(self.params.alignment.get_string())
            self.noise_field.setText(self.params.noise.get_string())
            self.noise_check.setChecked(self.params.noise.use)
            self.distance_field.setText(self.params.distance.get_string())
            self.distance_check.setChecked(self.params.distance.use)
            self.blur_field.setText(self.params.blur.get_string())
            self.blur_check.setChecked(self.params.blur.use)
            self.show_joints_checkbox.setChecked(self.params.showJoints.use)
            self.use_joints_checkbox.setChecked(self.params.useJoints.use)
            if self.params.useJoints.use:
                self.joint_points_field.setText(str(self.params.jointPoints.get_value()))
                self.joint_points_field.setReadOnly(False)
            else:
                self.joint_points_field.clear()
                self.joint_points_field.setReadOnly(True)

        self.show_centerline_checkbox.setChecked(self.params.showCenterlineOverlay.use)
        current_centerline_color = str(self.params.centerlineOverlayColor.get_value()) if self.params.centerlineOverlayColor.get_value() is not None else "Neon Green"
        idx = self.centerline_color_combo.findText(current_centerline_color)
        if idx >= 0:
            self.centerline_color_combo.setCurrentIndex(idx)
        else:
            self.centerline_color_combo.setCurrentIndex(0)

        current_model = str(self.params.noiseModel.get_value()) if self.params.noiseModel.get_value() is not None else "No Noise"
        idx = self.noise_model_combo.findText(current_model)
        if idx >= 0:
            self.noise_model_combo.setCurrentIndex(idx)
        else:
            self.noise_model_combo.setCurrentIndex(0)

        self.noise_std_field.setText(self.params.noiseStdDev.get_string())
        self.noise_std_check.setChecked(self.params.noiseStdDev.use)
        self.saltpepper_field.setText(self.params.saltPepperProb.get_string())
        self.saltpepper_check.setChecked(self.params.saltPepperProb.use)
        self.update_noise_controls_visibility()

        self.image_width_field.setText(self.params.imageWidth.get_string())
        self.image_height_field.setText(self.params.imageHeight.get_string())
        self.image_buffer_field.setText(self.params.imageBuffer.get_string())

        self.scale_check.setChecked(self.params.scale.use)
        self.scale_field.setText(self.params.scale.get_string())
        self.sample_check.setChecked(self.params.downSample.use)
        self.sample_field.setText(self.params.downSample.get_string())
        self.cap_check.setChecked(self.params.cap.use)
        self.cap_field.setText(self.params.cap.get_string())
        self.normalize_check.setChecked(self.params.normalize.use)
        self.normalize_field.setText(self.params.normalize.get_string())
        self.bubble_check.setChecked(self.params.bubble.use)
        self.bubble_field.setText(self.params.bubble.get_string())
        self.swap_check.setChecked(self.params.swap.use)
        self.swap_field.setText(self.params.swap.get_string())
        self.spline_check.setChecked(self.params.spline.use)
        self.spline_field.setText(self.params.spline.get_string())
        self.apply_psf_checkbox.setChecked(self.params.psfEnabled.use)
        current_psf_type = str(self.params.psfType.get_value()) if self.params.psfType.get_value() is not None else "None"
        idx = self.psf_type_combo.findText(current_psf_type)
        if idx >= 0:
            self.psf_type_combo.setCurrentIndex(idx)
        self.psf_gaussian_na_field.setText(self.params.psfGaussianNA.get_string())
        self.psf_gaussian_wavelength_field.setText(self.params.psfGaussianWavelength.get_string())
        self.psf_voxel_z_field.setText(self.params.psfPixelSizeZ.get_string())
        self.psf_voxel_y_field.setText(self.params.psfPixelSizeY.get_string())
        self.psf_voxel_x_field.setText(self.params.psfPixelSizeX.get_string())
        self.psf_vectorial_na_field.setText(self.params.psfVectorialNA.get_string())
        self.psf_vectorial_medium_ri_field.setText(self.params.psfVectorialMediumRI.get_string())
        self.psf_vectorial_sample_ri_field.setText(self.params.psfVectorialSampleRI.get_string())
        self.psf_vectorial_wavelength_field.setText(self.params.psfVectorialWavelength.get_string())
        self.psf_vectorial_polarization_field.setText(self.params.psfVectorialPolarization.get_string())
        self.psf_vectorial_volume_z_field.setText(self.params.psfVectorialVolumeZ.get_string())
        self.psf_vectorial_volume_y_field.setText(self.params.psfVectorialVolumeY.get_string())
        self.psf_vectorial_volume_x_field.setText(self.params.psfVectorialVolumeX.get_string())
        self.psf_vectorial_shape_z_field.setText(self.params.psfVectorialShapeZ.get_string())
        self.psf_vectorial_shape_y_field.setText(self.params.psfVectorialShapeY.get_string())
        self.psf_vectorial_shape_x_field.setText(self.params.psfVectorialShapeX.get_string())
        self.refresh_ui_state()

    def update_joint_points_field(self):
        if not self.use_joints_checkbox.isChecked():
            self.joint_points_field.setText("")
        else:
            if not self.joint_points_field.text():
                self.joint_points_field.setText(self.params.jointPoints.get_string())
        self.refresh_ui_state()

    def reset_pressed(self):
        try:
            if self.enhancement_worker is not None and self.enhancement_worker.isRunning():
                self.show_error("Wait for realism enhancement to finish before resetting the current mode.")
                return
            if self.is_3d_mode:
                self.params = self.params_loader_3d.read_params_file(self.DEFAULTS_FILE_3D)
            else:
                self.params = self.params_loader_2d.read_params_file(self.DEFAULTS_FILE_2D)
            self.clear_current_mode_runtime_state()
            self.sync_mode_runtime_state()
            self.display_params()
            self.update_image_counter()
            self.show_placeholder_for_current_mode()
        except Exception as exc:
            self.show_error(str(exc))

    def load_pressed(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Open File", "", "JSON files (*.json)")
        if filename:
            try:
                if self.is_3d_mode:
                    self.params = self.params_loader_3d.read_params_file(filename)
                else:
                    self.params = self.params_loader_2d.read_params_file(filename)
            except Exception as exc:
                self.show_error(str(exc))
            self.display_params()
