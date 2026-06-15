
from __future__ import annotations

import os

from app.runtime_env import configure_runtime_environment

configure_runtime_environment()

import matplotlib.pyplot as plt
import napari
from PyQt6.QtCore import QPoint, QSize, Qt, QTimer
from PyQt6.QtWidgets import (
    QGridLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QSizePolicy,
    QStackedWidget,
    QToolButton,
    QToolTip,
    QVBoxLayout,
    QWidget,
)

from app.controllers import (
    EnhancementWorkflowMixin,
    ExportWorkflowMixin,
    ExtractionWorkflowMixin,
    GenerationWorkflowMixin,
    ParameterWorkflowMixin,
    SessionStateMixin,
)
from app.dialogs.distribution_dialog import DistributionDialog
from app.preview import NapariPreviewMixin, OverlayMixin
from app.ui_sections import (
    build_advanced_post_tab,
    build_display_panel,
    build_distributions_tab,
    build_enhance_realism_tab,
    build_fiber_render_tab,
    build_match_real_data_tab,
    build_navigation_controls,
    build_outputs_tab,
    build_preview_controls,
    build_preview_export_tab,
    build_session_header,
    build_structure_tab,
    build_tab_containers,
)
from fileio.params_io import ParamsLoader2D, ParamsLoader3D
from generation.collections import ImageCollection, ImageCollection3D
from postprocess.psf import PSFManager, get_last_psf_stats


class MainWindow(SessionStateMixin, GenerationWorkflowMixin, ParameterWorkflowMixin, ExportWorkflowMixin, EnhancementWorkflowMixin, ExtractionWorkflowMixin, OverlayMixin, NapariPreviewMixin, QMainWindow):
    IMAGE_DISPLAY_SIZE = 512
    DEFAULTS_FILE_2D = os.path.join("config", "defaults", "2d.json")
    DEFAULTS_FILE_3D = os.path.join("config", "defaults", "3d.json")

    def __init__(self):
        super().__init__()

        # Path setup
        project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.DEFAULTS_FILE_2D = os.path.join(project_dir, "config", "defaults", "2d.json")
        self.DEFAULTS_FILE_3D = os.path.join(project_dir, "config", "defaults", "3d.json")
        self.out_folder_2d = os.path.join(project_dir, "output_2d")
        self.out_folder_3d = os.path.join(project_dir, "output_3d")

        self.setWindowTitle("Fiber Generator")
        self.params_loader_2d = ParamsLoader2D()
        self.params_loader_3d = ParamsLoader3D()

        self.out_folder = self.out_folder_2d
        self.is_3d_mode = False
        self.abort_requested = False  # <--- New flag

        try:
            self.params_2d = self.params_loader_2d.read_params_file(self.DEFAULTS_FILE_2D)
            self.params_3d = self.params_loader_3d.read_params_file(self.DEFAULTS_FILE_3D)
            self.params = self.params_2d
        except Exception as e:
            self.show_error(str(e))
            self.params_2d = ImageCollection.Params()
            self.params_3d = ImageCollection3D.Params()
            self.params = self.params_2d

        self.collection = None
        self.collection_2d = None
        self.collection_3d = None
        self.extracted_sample = None
        self.match_input_path = None
        self.extraction_worker = None
        self.display_index = 0
        self.display_index_2d = 0
        self.display_index_3d = 0
        self.scene = None
        self.original_fibers_by_index = []
        self.original_fibers_by_index_2d = []
        self.original_fibers_by_index_3d = []
        self.enhanced_outputs_2d = {}
        self.enhanced_outputs_3d = {}
        self.enhancement_recipes_2d = {}
        self.enhancement_recipes_3d = {}
        self.enhancement_worker = None
        self.worker = None

        # Guard flag to suppress redraws during UI mode switches
        self._suspend_redraw = False

        self._resize_redraw_timer = QTimer(self)
        self._resize_redraw_timer.setSingleShot(True)
        self._resize_redraw_timer.timeout.connect(self.handle_resize_redraw)

        self.init_gui()
        self.display_params()

    def init_gui(self):
        self.resize(1280, 820)
        self.setMinimumSize(1100, 700)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)

        main_layout = QGridLayout(central_widget)
        main_layout.setColumnStretch(0, 3)
        main_layout.setColumnStretch(1, 2)
        main_layout.setRowStretch(0, 1)

        self.display_stack = QStackedWidget(self)
        display_frame, display_layout = build_display_panel(self, main_layout)
        build_navigation_controls(self, display_layout)
        build_preview_controls(self, display_frame, display_layout)
        right_panel, right_layout = build_session_header(self, main_layout)
        tabs = build_tab_containers(self, right_layout, right_panel)
        build_outputs_tab(self, tabs["outputs_tab"])
        build_structure_tab(self, tabs["structure_tab"])
        build_distributions_tab(self, tabs["distributions_tab"])
        build_fiber_render_tab(self, tabs["fiber_render_tab"])
        build_advanced_post_tab(self, tabs["advanced_post_tab"])
        self.mode_toggle_button.clicked.connect(self.toggle_mode)
        self.generate_button.clicked.connect(self.generate_pressed)
        self.abort_button.clicked.connect(self.abort_pressed)
        self.reset_button.clicked.connect(self.reset_pressed)
        self.prev_button.clicked.connect(self.prev_pressed)
        self.next_button.clicked.connect(self.next_pressed)
        self.load_button.clicked.connect(self.load_pressed)
        self.length_button.clicked.connect(self.length_pressed)
        self.width_button.clicked.connect(self.width_pressed)
        self.straight_button.clicked.connect(self.straight_pressed)
        self.intensity_button.clicked.connect(self.intensity_pressed)
        self.centerline_mask_width_field.editingFinished.connect(self.redraw_image)
        self.noise_model_combo.currentIndexChanged.connect(self.on_noise_model_changed)
        self.noise_mean_check.stateChanged.connect(self.on_optional_effect_changed)
        self.noise_std_check.stateChanged.connect(self.on_optional_effect_changed)
        self.saltpepper_check.stateChanged.connect(self.on_optional_effect_changed)
        self.blur_radius_check.stateChanged.connect(self.on_optional_effect_changed)
        self.distance_falloff_check.stateChanged.connect(self.on_optional_effect_changed)
        build_match_real_data_tab(self, tabs["match_real_data_tab"])
        self.match_input_button.clicked.connect(self.choose_input_pressed)
        self.run_extraction_button.clicked.connect(self.run_extraction_pressed)
        self.ctfire_params_button.clicked.connect(self.ctfire_params_pressed)
        self.extractor_combo.currentIndexChanged.connect(self._on_extractor_changed)
        self._on_extractor_changed()
        # Disable curvelet checkbox if curvelops is not installed
        try:
            from ctfire_py import HAS_CURVELOPS as _has_curvelops
        except ImportError:
            _has_curvelops = False
        if not _has_curvelops:
            self.use_ct_reconstruction_checkbox.setEnabled(False)
            self.use_ct_reconstruction_checkbox.setToolTip(
                "curvelops is not installed — running FIRE-only mode."
            )
        self.soft_iou_enabled_checkbox.stateChanged.connect(self._update_soft_iou_if_active)
        self.soft_iou_sigma_spinbox.valueChanged.connect(self._update_soft_iou_if_active)
        self.suggest_params_button.clicked.connect(self.populate_generator_params_pressed)
        self.preview_target_combo.currentIndexChanged.connect(self._update_run_extraction_button_state)
        build_enhance_realism_tab(self, tabs["enhance_realism_tab"])
        build_preview_export_tab(self, tabs["preview_export_tab"])

        self.use_joints_checkbox.stateChanged.connect(self.update_joint_points_field)
        self.bubble_check.stateChanged.connect(self.on_optional_effect_changed)
        self.swap_check.stateChanged.connect(self.on_optional_effect_changed)
        self.spline_check.stateChanged.connect(self.on_optional_effect_changed)
        self.noise_check.stateChanged.connect(self.on_optional_effect_changed)
        self.blur_check.stateChanged.connect(self.on_optional_effect_changed)
        self.sample_check.stateChanged.connect(self.on_optional_effect_changed)
        self.scale_check.stateChanged.connect(self.on_optional_effect_changed)
        self.scale_field.editingFinished.connect(self.redraw_image)
        self.normalize_check.stateChanged.connect(self.on_optional_effect_changed)
        self.cap_check.stateChanged.connect(self.on_optional_effect_changed)
        self.distance_check.stateChanged.connect(self.on_optional_effect_changed)
        self.apply_psf_checkbox.stateChanged.connect(self.on_psf_configuration_changed)
        self.psf_type_combo.currentIndexChanged.connect(self.on_psf_configuration_changed)
        self.preview_psf_button.clicked.connect(self.preview_psf_kernel)
        self.preview_target_combo.currentIndexChanged.connect(self.redraw_image)
        self.preview_target_combo.currentIndexChanged.connect(self.refresh_preview_export_summary)
        self.export_detail_combo.currentIndexChanged.connect(self.refresh_preview_export_summary)
        self.export_session_checkbox.stateChanged.connect(self.refresh_preview_export_summary)
        self.preview_3d_view_combo.currentIndexChanged.connect(self.redraw_image)
        self.preview_3d_view_combo.currentIndexChanged.connect(self.refresh_centerline_overlay)
        self.open_napari_button.clicked.connect(self.open_current_preview_in_napari)
        self.show_joints_checkbox.stateChanged.connect(self.redraw_image)
        self.show_centerline_checkbox.stateChanged.connect(self.refresh_centerline_overlay)
        self.show_centerline_checkbox.stateChanged.connect(self._update_soft_iou_if_active)
        self.show_ctfire_overlay_checkbox.stateChanged.connect(self.redraw_image)
        self.centerline_color_combo.currentIndexChanged.connect(self.refresh_centerline_overlay)
        self.preview_target_combo.currentIndexChanged.connect(self._update_soft_iou_if_active)
        self.enhancement_pipeline_combo.currentIndexChanged.connect(self.update_enhancement_ui_state)
        self.enhancement_modality_combo.currentIndexChanged.connect(self.update_enhancement_ui_state)
        self.enhancement_model_path_field.editingFinished.connect(self.update_enhancement_ui_state)
        self.enhancement_model_browse_button.clicked.connect(self.choose_enhancement_model_path)
        self.enhancement_device_combo.currentIndexChanged.connect(self.update_enhancement_ui_state)
        self.enhancement_preview_combo.currentIndexChanged.connect(self.redraw_image)
        self.enhancement_preview_combo.currentIndexChanged.connect(self.refresh_preview_export_summary)
        self.enhance_current_button.clicked.connect(self.enhance_current_pressed)
        self.enhance_batch_button.clicked.connect(self.enhance_batch_pressed)
        self.generate_centerline_checkbox.stateChanged.connect(self.on_output_configuration_changed)
        self.generate_fiber_checkbox.stateChanged.connect(self.on_output_configuration_changed)
        self.export_current_button.clicked.connect(self.save_current_preview_pressed)
        self.export_all_button.clicked.connect(self.save_all_preview_pressed)
        self.refresh_ui_state()

    def refresh_centerline_overlay(self):
        self.refresh_ui_state()
        if getattr(self, '_suspend_redraw', False) or self.collection is None:
            return
        if self.is_3d_mode:
            if '3D Image' not in self.viewer.layers:
                self.redraw_image()
            else:
                self.update_3d_centerline_layer()
        else:
            self.redraw_image()

    def on_output_configuration_changed(self, *_args):
        self.refresh_ui_state()
        self.redraw_image()

    def on_optional_effect_changed(self, *_args):
        self.refresh_ui_state()
        self.redraw_image()

    def on_psf_configuration_changed(self, *_args):
        self.refresh_ui_state()
        self.redraw_image()

    @staticmethod
    def set_line_edit_active(field, active):
        field.setEnabled(active)
        field.setReadOnly(not active)

    def set_optional_row_editable(self, check_box, field, visible=True):
        check_box.setVisible(visible)
        field.setVisible(visible)
        check_box.setEnabled(visible)
        field.setEnabled(visible)
        field.setReadOnly(not visible)

    @staticmethod
    def set_combo_item_enabled(combo_box, index, enabled):
        model = combo_box.model()
        item = model.item(index) if hasattr(model, "item") else None
        if item is not None:
            item.setEnabled(enabled)
    def get_requested_preview_target(self):
        preview_map = {
            "Fiber Image": "fiber_image",
            "Centerline Mask": "centerline_mask",
            "Enhanced Image": "enhanced",
            "Input Image": "input_image",
            "CT-FIRE Overlay": "ctfire_centerlines",
            "Reference (Planned)": "reference",
            "Compare (Planned)": "compare",
        }
        return preview_map.get(self.preview_target_combo.currentText(), "fiber_image")

    def get_3d_view_mode(self):
        if not hasattr(self, "preview_3d_view_combo"):
            return "projection"
        mode_map = {
            "Projection": "projection",
            "Attenuated Projection": "attenuated",
            "Isosurface": "isosurface",
        }
        return mode_map.get(self.preview_3d_view_combo.currentText(), "projection")

    def create_info_button(self, text):
        button = QToolButton(self)
        button.setText("i")
        button.setCursor(Qt.CursorShape.PointingHandCursor)
        button.setAutoRaise(True)
        button.setStyleSheet(
            "QToolButton { color: #d4a017; font-weight: 700; border: none; padding: 0px 2px; }"
            "QToolButton:hover { color: #f2c94c; }"
        )
        button.setToolTip(text)
        button.setToolTipDuration(0)
        button.clicked.connect(lambda _checked=False, b=button, t=text: QToolTip.showText(b.mapToGlobal(QPoint(b.width() // 2, b.height())), t, b))
        return button

    def get_active_preview_target(self):
        requested = self.get_requested_preview_target()
        available = []
        if self.generate_fiber_checkbox.isChecked():
            available.append("fiber_image")
        if self.generate_centerline_checkbox.isChecked():
            available.append("centerline_mask")
        if self.get_cached_enhanced_output(self.display_index) is not None:
            available.append("enhanced")
        if getattr(self, "match_input_path", None) is not None:
            available.append("input_image")
        if getattr(self, "extracted_sample", None) is not None:
            available.append("ctfire_centerlines")
        if requested in available:
            return requested
        if available:
            return available[0]
        return None

    @staticmethod
    def preview_target_to_label(preview_target):
        labels = {
            "fiber_image": "Fiber Image",
            "centerline_mask": "Centerline Mask",
            "enhanced": "Enhanced Image",
            "input_image": "Input Image",
            "ctfire_centerlines": "CT-FIRE Overlay",
            "reference": "Reference (Planned)",
            "compare": "Compare (Planned)",
            None: "None",
        }
        return labels.get(preview_target, "Fiber Image")

    def sync_preview_target_choices(self):
        fiber_enabled = self.generate_fiber_checkbox.isChecked()
        centerline_enabled = self.generate_centerline_checkbox.isChecked()
        enhanced_enabled = self.get_cached_enhanced_output(self.display_index) is not None
        input_enabled = getattr(self, "match_input_path", None) is not None
        ctfire_enabled = getattr(self, "extracted_sample", None) is not None
        enabled_states = {
            0: fiber_enabled,
            1: centerline_enabled,
            2: enhanced_enabled,
            3: input_enabled,       # Input Image
            4: ctfire_enabled,      # CT-FIRE Centerlines
            5: False,               # Reference (Planned)
            6: False,               # Compare (Planned)
        }
        for index, enabled in enabled_states.items():
            self.set_combo_item_enabled(self.preview_target_combo, index, enabled)

        active_target = self.get_active_preview_target()
        active_label = self.preview_target_to_label(active_target)
        current_label = self.preview_target_combo.currentText()
        if active_target is not None and current_label != active_label:
            block = self.preview_target_combo.blockSignals(True)
            self.preview_target_combo.setCurrentText(active_label)
            self.preview_target_combo.blockSignals(block)

        self._update_run_extraction_button_state()

    def _update_run_extraction_button_state(self):
        if not hasattr(self, "run_extraction_button"):
            return
        extractable = {"fiber_image", "enhanced", "input_image"}
        target_ok = self.get_active_preview_target() in extractable
        extractor_ok = self.extractor_combo.currentText() == "CT-FIRE"
        self.run_extraction_button.setEnabled(target_ok and extractor_ok)

    def _on_extractor_changed(self, *_):
        extractor = self.extractor_combo.currentText()
        is_ctfire = extractor == "CT-FIRE"
        self.use_ct_reconstruction_checkbox.setVisible(is_ctfire)
        _labels = {
            "CT-FIRE":         "CT-FIRE Params…",
            "Ridge Detection": "RD Params…",
            "SOAX":            "SOAX Params…",
        }
        self.ctfire_params_button.setText(_labels.get(extractor, "Params…"))
        self.ctfire_params_button.setEnabled(is_ctfire)
        if not is_ctfire:
            self.ctfire_params_button.setToolTip(f"{extractor} is not yet implemented")
        else:
            self.ctfire_params_button.setToolTip("")
        self._update_run_extraction_button_state()

    def refresh_preview_export_summary(self):
        mode_label = "3D" if self.is_3d_mode else "2D"
        preview_label = self.preview_target_to_label(self.get_active_preview_target())
        enabled_outputs = []
        if self.generate_centerline_checkbox.isChecked():
            enabled_outputs.append("Centerline Mask")
        if self.generate_fiber_checkbox.isChecked():
            enabled_outputs.append("Fiber Image")
        if self.get_cached_enhanced_output(self.display_index) is not None:
            enabled_outputs.append("Enhanced Image")
        if not enabled_outputs:
            enabled_outputs.append("None")
        collection_size = self.collection.size() if self.collection is not None else 0
        output_folder = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
        summary_lines = [
            f"Mode: {mode_label}",
            f"Available outputs: {', '.join(enabled_outputs)}",
            f"Active preview: {preview_label}",
            f"Export detail: {self.export_detail_combo.currentText()}",
        ]
        joint_summary = self._build_joint_result_summary()
        if joint_summary:
            summary_lines.append(joint_summary)
        if self.get_active_preview_target() == "enhanced":
            summary_lines.append(f"Enhanced preview display: {self.enhancement_preview_combo.currentText()}")
        if self.is_3d_mode:
            summary_lines.append(f"3D view: {self.preview_3d_view_combo.currentText()}")
        summary_lines.extend([
            f"Generated images: {collection_size}",
            f"Default output folder: {output_folder}",
        ])
        if self.export_session_checkbox.isChecked():
            summary_lines.append("Session restore: included")
        self.preview_export_summary.setText("\n".join(summary_lines))

    def _build_joint_result_summary(self):
        if self.is_3d_mode or self.collection is None:
            return None
        try:
            current_sample = self.collection.get(self.display_index)
        except Exception:
            return None
        metadata = getattr(current_sample, "generation_metadata", {}) or {}
        target = metadata.get("joint_match_target")
        if target is None:
            return None
        realized = metadata.get("joint_match_realized")
        tolerance = metadata.get("joint_match_tolerance")
        attempts = metadata.get("joint_match_attempts")
        if realized is None:
            return f"Joint result: requested {target}, result unavailable"
        try:
            delta = abs(int(realized) - int(target))
        except Exception:
            delta = None
        if delta is not None and tolerance is not None and delta <= int(tolerance):
            return f"Joint result: requested {target}, realized {realized} (within tolerance +/-{tolerance})"
        attempts_suffix = f" after {attempts} attempt{'s' if int(attempts) != 1 else ''}" if attempts is not None else ""
        return f"Joint result: requested {target}, realized {realized}{attempts_suffix}"

    def refresh_ui_state(self):
        self.centerline_mask_width_label.setEnabled(True)
        self.set_line_edit_active(self.centerline_mask_width_field, True)
        self.intensity_button.setEnabled(True)
        self.intensity_display.setEnabled(True)

        self.mean_angle_label.setVisible(not self.is_3d_mode)
        self.mean_angle_field.setVisible(not self.is_3d_mode)
        self.alignment_label.setVisible(not self.is_3d_mode)
        self.alignment_field.setVisible(not self.is_3d_mode)
        self.joint_points_label.setVisible(not self.is_3d_mode)
        self.joint_points_field.setVisible(not self.is_3d_mode)
        self.use_joints_checkbox.setVisible(not self.is_3d_mode)

        self.mean_direction_label.setVisible(self.is_3d_mode)
        self.mean_direction_field.setVisible(self.is_3d_mode)
        self.alignment3D_label.setVisible(self.is_3d_mode)
        self.alignment3D_field.setVisible(self.is_3d_mode)
        self.min_angle_change_label.setVisible(self.is_3d_mode)
        self.min_angle_change_field.setVisible(self.is_3d_mode)
        self.max_angle_change_label.setVisible(self.is_3d_mode)
        self.max_angle_change_field.setVisible(self.is_3d_mode)
        self.image_depth_label.setVisible(self.is_3d_mode)
        self.image_depth_field.setVisible(self.is_3d_mode)
        self.curvature_label.setVisible(self.is_3d_mode)
        self.curvature_field.setVisible(self.is_3d_mode)
        self.branching_probability_label.setVisible(self.is_3d_mode)
        self.branching_probability_field.setVisible(self.is_3d_mode)

        self.show_joints_checkbox.setVisible(not self.is_3d_mode)
        self.show_centerline_checkbox.setVisible(True)
        self.show_ctfire_overlay_checkbox.setVisible(True)
        self.centerline_color_widget.setVisible(self.show_centerline_checkbox.isChecked())
        self.preview_3d_view_label.setVisible(self.is_3d_mode)
        self.preview_3d_view_combo.setVisible(self.is_3d_mode)
        has_preview_data = self.collection is not None and self.collection.size() > 0
        self.preview_3d_view_combo.setEnabled(self.is_3d_mode and has_preview_data)
        self.open_napari_button.setVisible(True)
        self.open_napari_button.setEnabled(has_preview_data)
        self.export_current_button.setEnabled(has_preview_data)
        self.export_all_button.setEnabled(has_preview_data)
        self.export_detail_combo.setEnabled(True)
        self.export_session_checkbox.setEnabled(True)
        self.export_custom_checkbox.setEnabled(True)

        self.set_optional_row_editable(self.bubble_check, self.bubble_field, True)
        self.set_optional_row_editable(self.swap_check, self.swap_field, True)
        self.set_optional_row_editable(self.spline_check, self.spline_field, True)
        self.set_optional_row_editable(self.sample_check, self.sample_field, True)
        self.set_optional_row_editable(self.cap_check, self.cap_field, True)
        self.set_optional_row_editable(self.normalize_check, self.normalize_field, True)
        self.set_optional_row_editable(self.scale_check, self.scale_field, True)
        self.set_optional_row_editable(self.blur_check, self.blur_field, not self.is_3d_mode)
        self.set_optional_row_editable(self.blur_radius_check, self.blur_radius_field, self.is_3d_mode)
        self.set_optional_row_editable(self.distance_check, self.distance_field, not self.is_3d_mode)
        self.set_optional_row_editable(self.distance_falloff_check, self.distance_falloff_field, self.is_3d_mode)

        self.scale_label.setVisible(True)
        self.scale_check.setVisible(True)
        self.scale_field.setVisible(True)
        self.blur_label.setVisible(not self.is_3d_mode)
        self.blur_check.setVisible(not self.is_3d_mode)
        self.blur_field.setVisible(not self.is_3d_mode)
        self.blur_radius_label.setVisible(self.is_3d_mode)
        self.blur_radius_check.setVisible(self.is_3d_mode)
        self.blur_radius_field.setVisible(self.is_3d_mode)
        self.distance_label.setVisible(not self.is_3d_mode)
        self.distance_check.setVisible(not self.is_3d_mode)
        self.distance_field.setVisible(not self.is_3d_mode)
        self.distance_falloff_label.setVisible(self.is_3d_mode)
        self.distance_falloff_check.setVisible(self.is_3d_mode)
        self.distance_falloff_field.setVisible(self.is_3d_mode)

        self.set_line_edit_active(self.joint_points_field, not self.is_3d_mode)

        self.create_structure_tabs.setTabEnabled(self.fiber_render_subtab_index, True)
        self.create_structure_tabs.setTabEnabled(self.advanced_subtab_index, True)

        self.noise_model_label.setEnabled(True)
        self.noise_model_combo.setEnabled(True)
        self.apply_psf_checkbox.setEnabled(True)
        self.psf_type_combo.setEnabled(True)
        self.preview_psf_button.setEnabled(self.apply_psf_checkbox.isChecked() and self.psf_type_combo.currentText() != "None")
        self.sync_preview_target_choices()
        self.update_enhancement_ui_state()

        self.update_noise_controls_visibility()
        self.update_psf_controls_visibility()
        self.refresh_preview_export_summary()

    def create_image_display_2d_placeholder(self, parent):
        placeholder = QLabel(parent)
        placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        placeholder.setWordWrap(True)
        placeholder.setStyleSheet("background-color: black; color: white;")
        placeholder.setText("No 2D preview yet.\nClick \"Generate\" to create a 2D image.")
        placeholder.setMinimumSize(320, 320)
        placeholder.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        return placeholder

    def create_image_display_3d_placeholder(self, parent):
        placeholder = QLabel(parent)
        placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        placeholder.setWordWrap(True)
        placeholder.setStyleSheet("background-color: black; color: white;")
        placeholder.setText("No 3D preview yet.\nClick \"Generate\" to create a 3D volume.")
        placeholder.setMinimumSize(320, 320)
        placeholder.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        return placeholder

    def create_image_display_2d(self, parent):
        try:
            self.viewer_2d = napari.Viewer(ndisplay=2, show=False)
        except TypeError:
            self.viewer_2d = napari.Viewer(ndisplay=2)

        container = QWidget(parent)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        self.image_display_2d_stack = QStackedWidget(container)
        self.image_display_2d_placeholder = self.create_image_display_2d_placeholder(container)
        viewer_widget = getattr(self.viewer_2d.window, "_qt_viewer", None)
        if viewer_widget is None:
            viewer_widget = self.viewer_2d.window._qt_window
        self.image_display_2d_viewer_widget = viewer_widget
        try:
            self.image_display_2d_viewer_widget.setParent(container)
        except Exception:
            pass
        self.image_display_2d_viewer_widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.image_display_2d_viewer_widget.hide()
        self.image_display_2d_stack.addWidget(self.image_display_2d_placeholder)
        self.image_display_2d_stack.addWidget(self.image_display_2d_viewer_widget)
        self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_placeholder)
        layout.addWidget(self.image_display_2d_stack)

        container.setMinimumSize(QSize(320, 320))
        container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        return container

    def create_image_display_3d(self, parent):
        # Initialize the napari viewer without using a standalone top-level window.
        try:
            self.viewer = napari.Viewer(ndisplay=3, show=False)
        except TypeError:
            self.viewer = napari.Viewer(ndisplay=3)

        container = QWidget(parent)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        self.image_display_3d_stack = QStackedWidget(container)
        self.image_display_3d_placeholder = self.create_image_display_3d_placeholder(container)
        self.advanced_viewer = None
        viewer_widget = getattr(self.viewer.window, "_qt_viewer", None)
        if viewer_widget is None:
            viewer_widget = self.viewer.window._qt_window
        self.image_display_3d_viewer_widget = viewer_widget
        try:
            self.image_display_3d_viewer_widget.setParent(container)
        except Exception:
            pass
        self.image_display_3d_viewer_widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.image_display_3d_viewer_widget.hide()
        self.image_display_3d_stack.addWidget(self.image_display_3d_placeholder)
        self.image_display_3d_stack.addWidget(self.image_display_3d_viewer_widget)
        self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_placeholder)
        layout.addWidget(self.image_display_3d_stack)

        container.setMinimumSize(QSize(320, 320))
        container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)

        return container

    def resizeEvent(self, event):
        super().resizeEvent(event)
        if hasattr(self, "_resize_redraw_timer"):
            self._resize_redraw_timer.start(50)

    def handle_resize_redraw(self):
        if getattr(self, "_suspend_redraw", False):
            return
        if self.is_3d_mode or self.collection is None:
            return
        if self.get_active_preview_target() is None:
            return
        self.redraw_image()

    # [Removed] Save 3D View button handler

    def update_render_mode_visibility(self):
        self.refresh_ui_state()

    def update_ui_mode(self):
        self.refresh_ui_state()

    def length_pressed(self):
        dialog = DistributionDialog(self.params.length)
        dialog.exec()
        self.params.length = dialog.distribution
        self.display_params()

    def width_pressed(self):
        dialog = DistributionDialog(self.params.width)
        dialog.exec()
        self.params.width = dialog.distribution
        self.display_params()

    def straight_pressed(self):
        dialog = DistributionDialog(self.params.straightness)
        dialog.exec()
        self.params.straightness = dialog.distribution
        self.display_params()  

    def intensity_pressed(self):
        dialog = DistributionDialog(self.params.intensity)
        dialog.exec()
        self.params.intensity = dialog.distribution
        self.display_params()

    def display_image(self, image, fiber_image=None):
        if self.is_3d_mode:
            self.display_image_3d(image, fiber_image=fiber_image)
        else:
            self.display_image_2d(image, fiber_image=fiber_image)

    def redraw_image(self):
        # Skip redraws while we are in the middle of switching modes
        if getattr(self, '_suspend_redraw', False):
            return
        self.restore_current_mode_preview()

    def show_error(self, message):
        QMessageBox.critical(self, "Error", message)

    def on_noise_model_changed(self):
        # Auto-enable appropriate controls when model changes
        model = self.noise_model_combo.currentText().lower()
        # Reset all
        self.noise_check.setChecked(False)
        self.noise_mean_check.setChecked(False)
        self.noise_std_check.setChecked(False)
        self.saltpepper_check.setChecked(False)
        if model == 'poisson':
            if self.is_3d_mode:
                self.noise_mean_check.setChecked(True)
            else:
                self.noise_check.setChecked(True)
        elif model == 'gaussian':
            self.noise_std_check.setChecked(True)
        elif model == 'salt-and-pepper':
            self.saltpepper_check.setChecked(True)
        elif model == 'poisson+gaussian':
            if self.is_3d_mode:
                self.noise_mean_check.setChecked(True)
            else:
                self.noise_check.setChecked(True)
            self.noise_std_check.setChecked(True)
        # Speckle and No Noise: nothing to check
        self.update_noise_controls_visibility()
        self.redraw_image()

    def update_noise_controls_visibility(self):
        """Toggle visibility of noise-related inputs based on selected model and mode."""
        model = self.noise_model_combo.currentText().lower()
        show_std = model in ("gaussian", "poisson+gaussian")
        show_sp = model == "salt-and-pepper"
        show_poisson_mean = model in ("poisson", "poisson+gaussian")

        # Gaussian std dev widgets
        self.noise_std_label.setVisible(show_std)
        self.set_optional_row_editable(self.noise_std_check, self.noise_std_field, show_std)

        # Salt-Pepper prob widgets
        self.saltpepper_label.setVisible(show_sp)
        self.set_optional_row_editable(self.saltpepper_check, self.saltpepper_field, show_sp)

        # Poisson mean widgets depend on mode
        if self.is_3d_mode:
            self.noise_mean_label.setVisible(show_poisson_mean)
            self.set_optional_row_editable(self.noise_mean_check, self.noise_mean_field, show_poisson_mean)
            # Hide 2D Poisson mean controls
            self.noise_label.setVisible(False)
            self.set_optional_row_editable(self.noise_check, self.noise_field, False)
        else:
            self.noise_label.setVisible(show_poisson_mean)
            self.set_optional_row_editable(self.noise_check, self.noise_field, show_poisson_mean)
            # Hide 3D Poisson mean controls
            self.noise_mean_label.setVisible(False)
            self.set_optional_row_editable(self.noise_mean_check, self.noise_mean_field, False)

    def update_psf_controls_visibility(self):
        enabled = self.apply_psf_checkbox.isChecked()
        mode = self.psf_type_combo.currentText().lower()
        show_gaussian = "gaussian" in mode
        show_vectorial = "vectorial" in mode
        self.psf_gaussian_group.setVisible(show_gaussian)
        self.psf_vectorial_group.setVisible(show_vectorial)
        self.preview_psf_button.setEnabled(enabled and self.psf_type_combo.currentText() != "None")
        for field in self.psf_gaussian_group.findChildren(QLineEdit):
            self.set_line_edit_active(field, show_gaussian)
        for field in self.psf_vectorial_group.findChildren(QLineEdit):
            self.set_line_edit_active(field, show_vectorial)

    def preview_psf_kernel(self):
        manager = PSFManager(self.params)
        kernel = manager.get_kernel()
        if kernel is None:
            self.show_error("Enable PSF convolution and provide valid parameters before previewing.")
            return
        center_z = kernel.shape[0] // 2
        center_slice = kernel[center_z]
        axial_profile = kernel[:, kernel.shape[1] // 2, kernel.shape[2] // 2]
        fig, axes = plt.subplots(1, 2, figsize=(10, 4))
        im = axes[0].imshow(center_slice, cmap='inferno')
        axes[0].set_title('Center XY slice')
        axes[0].set_axis_off()
        fig.colorbar(im, ax=axes[0], fraction=0.046, pad=0.04)
        axes[1].plot(axial_profile)
        axes[1].set_title('Axial profile (Z center column)')
        axes[1].set_xlabel('Z index')
        axes[1].set_ylabel('Normalized intensity')
        stats_text = "No PSF applications yet."
        last_psf_stats = get_last_psf_stats()
        if last_psf_stats is not None:
            stats_text = (
                f"Last PSF apply (volume={last_psf_stats['volume']}): "
                f"mean {last_psf_stats['before_mean']:.4f}→{last_psf_stats['after_mean']:.4f}, "
                f"std {last_psf_stats['before_std']:.4f}→{last_psf_stats['after_std']:.4f}"
            )
        fig.text(0.5, 0.02, stats_text, ha='center', va='bottom')
        fig.suptitle('PSF Preview')
        fig.tight_layout()
        plt.show(block=False)
        plt.pause(0.1)
