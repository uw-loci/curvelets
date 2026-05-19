
from __future__ import annotations

import os

import matplotlib.pyplot as plt
import napari
from PyQt6.QtCore import QPoint, QSize, Qt, QTimer
from PyQt6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QFrame,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QSizePolicy,
    QStackedWidget,
    QTabWidget,
    QToolButton,
    QToolTip,
    QVBoxLayout,
    QWidget,
)

from app.controllers import (
    EnhancementWorkflowMixin,
    ExportWorkflowMixin,
    GenerationWorkflowMixin,
    ParameterWorkflowMixin,
    SessionStateMixin,
)
from app.dialogs.distribution_dialog import DistributionDialog
from app.preview import NapariPreviewMixin, OverlayMixin
from fileio.params_io import ParamsLoader2D, ParamsLoader3D
from generation.collections import ImageCollection, ImageCollection3D
from postprocess.psf import PSFManager, get_last_psf_stats
from realism import (
    DEFAULT_STAGE2_PIPELINE_NAME,
    get_default_stage2_model_dir,
)

class MainWindow(SessionStateMixin, GenerationWorkflowMixin, ParameterWorkflowMixin, ExportWorkflowMixin, EnhancementWorkflowMixin, OverlayMixin, NapariPreviewMixin, QMainWindow):
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

        # Create display frame
        display_frame = QFrame(self)
        display_layout = QVBoxLayout(display_frame)
        display_frame.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)

        # Add the display frame to the main layout
        main_layout.addWidget(display_frame, 0, 0, 4, 1)

        # Create a QStackedWidget to hold both 2D and 3D displays
        self.display_stack = QStackedWidget(self)
        self.display_stack.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.display_stack.setMinimumSize(QSize(320, 320))
        self.image_display_2d = self.create_image_display_2d(display_frame)
        self.image_display_3d = self.create_image_display_3d(display_frame)
        self.display_stack.addWidget(self.image_display_2d)
        self.display_stack.addWidget(self.image_display_3d)

        display_layout.addWidget(self.display_stack, 1)
        right_panel = QWidget(self)
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_panel.setSizePolicy(QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Expanding)
        main_layout.addWidget(right_panel, 0, 1, 5, 1)

        session_header_frame = QGroupBox("Session", right_panel)
        session_header_layout = QGridLayout(session_header_frame)
        right_layout.addWidget(session_header_frame)

        session_header_layout.addWidget(QLabel("Parameters:"), 0, 0)
        self.load_button = QPushButton("Open...", session_header_frame)
        session_header_layout.addWidget(self.load_button, 0, 1)

        session_header_layout.addWidget(QLabel("Number of images:"), 1, 0)
        self.n_images_field = QLineEdit(session_header_frame)
        session_header_layout.addWidget(self.n_images_field, 1, 1)

        self.seed_check = QCheckBox("Seed:", session_header_frame)
        session_header_layout.addWidget(self.seed_check, 2, 0)
        self.seed_field = QLineEdit(session_header_frame)
        session_header_layout.addWidget(self.seed_field, 2, 1)

        self.mode_toggle_button = QPushButton("Switch to 3D Mode", session_header_frame)
        session_header_layout.addWidget(self.mode_toggle_button, 0, 2)
        self.reset_button = QPushButton("Reset", session_header_frame)
        session_header_layout.addWidget(self.reset_button, 1, 2)
        self.generate_button = QPushButton("Generate...", session_header_frame)
        session_header_layout.addWidget(self.generate_button, 2, 2)
        self.abort_button = QPushButton("Abort", session_header_frame)
        self.abort_button.setEnabled(False)
        session_header_layout.addWidget(self.abort_button, 3, 2)

        self.tab_widget = QTabWidget(right_panel)
        right_layout.addWidget(self.tab_widget, 1)

        create_structure_tab = QWidget()
        match_real_data_tab = QWidget()
        enhance_realism_tab = QWidget()
        preview_export_tab = QWidget()

        self.create_structure_tab_index = self.tab_widget.addTab(create_structure_tab, "Create Structure")
        self.match_real_data_tab_index = self.tab_widget.addTab(match_real_data_tab, "Match Real Data")
        self.enhance_realism_tab_index = self.tab_widget.addTab(enhance_realism_tab, "Enhance Realism")
        self.preview_export_tab_index = self.tab_widget.addTab(preview_export_tab, "Preview & Export")

        create_structure_layout = QVBoxLayout(create_structure_tab)
        self.create_structure_tabs = QTabWidget(create_structure_tab)
        create_structure_layout.addWidget(self.create_structure_tabs)

        structure_tab = QWidget()
        distributions_tab = QWidget()
        outputs_tab = QWidget()
        fiber_render_tab = QWidget()
        advanced_post_tab = QWidget()

        self.structure_subtab_index = self.create_structure_tabs.addTab(structure_tab, "Structure")
        self.distributions_subtab_index = self.create_structure_tabs.addTab(distributions_tab, "Distributions")
        self.outputs_subtab_index = self.create_structure_tabs.addTab(outputs_tab, "Outputs")
        self.fiber_render_subtab_index = self.create_structure_tabs.addTab(fiber_render_tab, "Fiber Render")
        self.advanced_subtab_index = self.create_structure_tabs.addTab(advanced_post_tab, "Advanced")

        fiber_tab = structure_tab
        render_tab = outputs_tab
        effects_tab = fiber_render_tab

        self.prev_button = QPushButton("Previous", self)
        self.next_button = QPushButton("Next", self)

        # Create buttons layout below the display stack
        self.buttons_layout = QHBoxLayout()
        self.buttons_layout.addWidget(self.prev_button)
        # Image counter label (e.g., 1/10)
        self.image_counter_label = QLabel("0/0", self)
        self.image_counter_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_counter_label.setMinimumWidth(60)
        self.buttons_layout.addWidget(self.image_counter_label)
        self.buttons_layout.addWidget(self.next_button)
        display_layout.addLayout(self.buttons_layout)

        preview_controls_frame = QGroupBox("Preview", display_frame)
        preview_controls_layout = QGridLayout(preview_controls_frame)
        display_layout.addWidget(preview_controls_frame)

        preview_controls_layout.addWidget(QLabel("Preview target:"), 0, 0)
        self.preview_target_combo = QComboBox(preview_controls_frame)
        self.preview_target_combo.addItems([
            "Fiber Image",
            "Centerline Mask",
            "Enhanced Image",
            "Reference (Planned)",
            "Compare (Planned)",
        ])
        preview_controls_layout.addWidget(self.preview_target_combo, 0, 1)
        self.open_napari_button = QPushButton("Open in napari", preview_controls_frame)
        preview_controls_layout.addWidget(self.open_napari_button, 0, 2)

        self.preview_3d_view_label = QLabel("3D view:", preview_controls_frame)
        preview_controls_layout.addWidget(self.preview_3d_view_label, 1, 0)
        self.preview_3d_view_combo = QComboBox(preview_controls_frame)
        self.preview_3d_view_combo.addItems([
            "Projection",
            "Attenuated Projection",
            "Isosurface",
        ])
        preview_controls_layout.addWidget(self.preview_3d_view_combo, 1, 1)

        self.show_joints_checkbox = QCheckBox("Show joint points", preview_controls_frame)
        preview_controls_layout.addWidget(self.show_joints_checkbox, 2, 0, 1, 2)

        self.show_centerline_checkbox = QCheckBox("Show centerline overlay", preview_controls_frame)
        preview_controls_layout.addWidget(self.show_centerline_checkbox, 3, 0, 1, 2)

        self.centerline_color_widget = QWidget(preview_controls_frame)
        centerline_color_layout = QHBoxLayout(self.centerline_color_widget)
        centerline_color_layout.setContentsMargins(0, 0, 0, 0)
        centerline_color_layout.setSpacing(6)
        self.centerline_color_label = QLabel("Color:", self.centerline_color_widget)
        self.centerline_color_combo = QComboBox(self.centerline_color_widget)
        self.centerline_color_combo.addItems(["Neon Green", "Cyan", "Magenta", "Yellow"])
        centerline_color_layout.addWidget(self.centerline_color_label)
        centerline_color_layout.addWidget(self.centerline_color_combo)
        centerline_color_layout.addStretch(1)
        preview_controls_layout.addWidget(self.centerline_color_widget, 4, 0, 1, 2)

        # Outputs tab components
        outputs_layout = QVBoxLayout(outputs_tab)
        outputs_tab.setLayout(outputs_layout)

        image_config_frame = QGroupBox("Image Dimensions", outputs_tab)
        image_config_layout = QGridLayout(image_config_frame)
        outputs_layout.addWidget(image_config_frame)

        image_config_layout.addWidget(QLabel("Image width:"), 0, 0)
        self.image_width_field = QLineEdit(image_config_frame)
        image_config_layout.addWidget(self.image_width_field, 0, 1)

        image_config_layout.addWidget(QLabel("Image height:"), 1, 0)
        self.image_height_field = QLineEdit(image_config_frame)
        image_config_layout.addWidget(self.image_height_field, 1, 1)

        self.image_depth_label = QLabel("Image depth:")
        self.image_depth_field = QLineEdit(image_config_frame)
        image_config_layout.addWidget(self.image_depth_label, 2, 0)
        image_config_layout.addWidget(self.image_depth_field, 2, 1)

        image_config_layout.addWidget(QLabel("Image buffer:"), 3, 0)
        self.image_buffer_field = QLineEdit(image_config_frame)
        image_config_layout.addWidget(self.image_buffer_field, 3, 1)

        output_products_frame = QGroupBox("Derived Outputs", outputs_tab)
        render_grid = QGridLayout(output_products_frame)
        outputs_layout.addWidget(output_products_frame)

        self.generate_centerline_checkbox = QCheckBox("Generate centerline mask", output_products_frame)
        render_grid.addWidget(self.generate_centerline_checkbox, 0, 0, 1, 2)

        self.generate_fiber_checkbox = QCheckBox("Generate fiber image", output_products_frame)
        fiber_output_row = QWidget(output_products_frame)
        fiber_output_row_layout = QHBoxLayout(fiber_output_row)
        fiber_output_row_layout.setContentsMargins(0, 0, 0, 0)
        fiber_output_row_layout.setSpacing(4)
        fiber_output_row_layout.addWidget(self.generate_fiber_checkbox)
        self.output_relationship_info_button = self.create_info_button(
            "Fiber Image only: blur, downsampling, normalize/cap/scale, distance or distance falloff, "
            "noise, scale bar, and PSF. Centerline Mask remains structural."
        )
        fiber_output_row_layout.addWidget(self.output_relationship_info_button)
        fiber_output_row_layout.addStretch(1)
        render_grid.addWidget(fiber_output_row, 1, 0, 1, 3)

        self.centerline_mask_width_label = QLabel("Centerline Mask Render Width (px):")
        self.centerline_mask_width_label.setToolTip(
            "Controls the rendered/exported centerline mask width. "
            "The realism model always uses a 1-pixel structural centerline input."
        )
        self.centerline_mask_width_field = QLineEdit(output_products_frame)
        self.centerline_mask_width_field.setToolTip(
            "Controls the rendered/exported centerline mask width. "
            "The realism model always uses a 1-pixel structural centerline input."
        )
        render_grid.addWidget(self.centerline_mask_width_label, 2, 0)
        render_grid.addWidget(self.centerline_mask_width_field, 2, 1)

        outputs_layout.addStretch(1)

        # Structure tab components
        fiber_layout = QVBoxLayout(fiber_tab)
        fiber_tab.setLayout(fiber_layout)

        # Distributions tab components
        distributions_layout = QVBoxLayout(distributions_tab)
        distributions_tab.setLayout(distributions_layout)

        distribution_frame = QGroupBox("Structure Distributions", distributions_tab)
        distribution_layout = QGridLayout(distribution_frame)
        distributions_layout.addWidget(distribution_frame)

        # Length distribution
        distribution_layout.addWidget(QLabel("Length distribution:"), 0, 0)
        self.length_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.length_button, 0, 1)
        self.length_display = QLineEdit(distribution_frame)
        self.length_display.setReadOnly(True)
        self.length_display.setMinimumSize(200, 20)  # Set a reasonable minimum size as it will also be used to scale all of the tabs 
        distribution_layout.addWidget(self.length_display, 0, 2, 1, 15)

        # Width distribution
        distribution_layout.addWidget(QLabel("Width distribution:"), 1, 0)
        self.width_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.width_button, 1, 1)
        self.width_display = QLineEdit(distribution_frame)
        self.width_display.setReadOnly(True)
        self.width_display.setMinimumSize(200, 20)  
        distribution_layout.addWidget(self.width_display, 1, 2, 1, 15)

        # Straightness distribution
        distribution_layout.addWidget(QLabel("Straightness distribution:"), 2, 0)
        self.straight_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.straight_button, 2, 1)
        self.straight_display = QLineEdit(distribution_frame)
        self.straight_display.setReadOnly(True)
        self.straight_display.setMinimumSize(200, 20)
        distribution_layout.addWidget(self.straight_display, 2, 2, 1, 15)

        distribution_layout.addWidget(QLabel("Intensity distribution:"), 3, 0)
        self.intensity_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.intensity_button, 3, 1)
        self.intensity_display = QLineEdit(distribution_frame)
        self.intensity_display.setReadOnly(True)
        self.intensity_display.setMinimumSize(200, 20)
        distribution_layout.addWidget(self.intensity_display, 3, 2, 1, 15)

        # Set stretch factors for columns
        distribution_layout.setColumnStretch(0, 1)
        distribution_layout.setColumnStretch(1, 1)
        distribution_layout.setColumnStretch(2, 15)

        values_frame = QGroupBox("Values", fiber_tab)
        values_layout = QGridLayout(values_frame)
        fiber_layout.addWidget(values_frame)

        values_layout.addWidget(QLabel("Number of fibers:"), 0, 0)
        self.n_fibers_field = QLineEdit(values_frame)
        values_layout.addWidget(self.n_fibers_field, 0, 1)

        values_layout.addWidget(QLabel("Segment length:"), 1, 0)
        self.segment_field = QLineEdit(values_frame)
        values_layout.addWidget(self.segment_field, 1, 1)

        values_layout.addWidget(QLabel("Width change:"), 2, 0)
        self.width_change_field = QLineEdit(values_frame)
        values_layout.addWidget(self.width_change_field, 2, 1)

        self.alignment_label = QLabel("Alignment:")
        self.alignment_field = QLineEdit(values_frame)
        values_layout.addWidget(self.alignment_label, 3, 0)
        values_layout.addWidget(self.alignment_field, 3, 1)

        # section for Joint Points
        self.joint_points_label = QLabel("Joint points:")
        self.joint_points_field = QLineEdit(values_frame)
        values_layout.addWidget(self.joint_points_label, 5, 0)
        values_layout.addWidget(self.joint_points_field, 5, 1)

        # Checkbox for "Use joints"
        self.use_joints_checkbox = QCheckBox("Use joints", values_frame)
        values_layout.addWidget(self.use_joints_checkbox, 5, 2)
        self.use_joints_checkbox.stateChanged.connect(self.update_joint_points_field)

        self.alignment3D_label = QLabel("Alignment 3D:")
        self.alignment3D_field = QLineEdit(values_frame)
        values_layout.addWidget(self.alignment3D_label, 3, 0)
        values_layout.addWidget(self.alignment3D_field, 3, 1)

        self.mean_angle_label = QLabel("Mean angle:")
        self.mean_angle_field = QLineEdit(values_frame)
        values_layout.addWidget(self.mean_angle_label, 4, 0)
        values_layout.addWidget(self.mean_angle_field, 4, 1)

        self.mean_direction_label = QLabel("Mean direction:")
        self.mean_direction_field = QLineEdit(values_frame)
        values_layout.addWidget(self.mean_direction_label, 4, 0)
        values_layout.addWidget(self.mean_direction_field, 4, 1)

        # Min angle change
        self.min_angle_change_label = QLabel("Min angle change (degrees):")
        self.min_angle_change_field = QLineEdit(values_frame)
        values_layout.addWidget(self.min_angle_change_label, 6, 0)
        values_layout.addWidget(self.min_angle_change_field, 6, 1)

        # Max angle change
        self.max_angle_change_label = QLabel("Max angle change (degrees):")
        self.max_angle_change_field = QLineEdit(values_frame)
        values_layout.addWidget(self.max_angle_change_label, 7, 0)
        values_layout.addWidget(self.max_angle_change_field, 7, 1)

        self.curvature_label = QLabel("Curvature:")
        self.curvature_field = QLineEdit(values_frame)
        values_layout.addWidget(self.curvature_label, 8, 0)
        values_layout.addWidget(self.curvature_field, 8, 1)

        self.branching_probability_label = QLabel("Branching Probability:")
        self.branching_probability_field = QLineEdit(values_frame)
        values_layout.addWidget(self.branching_probability_label, 9, 0)
        values_layout.addWidget(self.branching_probability_field, 9, 1)

        # Adjust layout column stretching for the newly added fields
        values_layout.setColumnStretch(0, 1)
        values_layout.setColumnStretch(1, 3)
        values_layout.setColumnStretch(2, 1)
        values_layout.setColumnStretch(3, 2)

        smoothing_frame = QGroupBox("Smoothing", fiber_tab)
        smoothing_layout = QGridLayout(smoothing_frame)
        fiber_layout.addWidget(smoothing_frame)

        smoothing_layout.addWidget(QLabel("Bubble:"), 0, 0)
        self.bubble_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.bubble_check, 0, 1)
        self.bubble_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.bubble_field, 0, 2)
        self.bubble_check.stateChanged.connect(self.on_optional_effect_changed)

        smoothing_layout.addWidget(QLabel("Swap:"), 1, 0)
        self.swap_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.swap_check, 1, 1)
        self.swap_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.swap_field, 1, 2)
        self.swap_check.stateChanged.connect(self.on_optional_effect_changed)

        smoothing_layout.addWidget(QLabel("Spline:"), 2, 0)
        self.spline_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.spline_check, 2, 1)
        self.spline_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.spline_field, 2, 2)
        self.spline_check.stateChanged.connect(self.on_optional_effect_changed)

        # Effects tab components
        effects_layout = QVBoxLayout(effects_tab)
        effects_tab.setLayout(effects_layout)

        noise_frame = QGroupBox("Noise", effects_tab)
        noise_layout = QGridLayout(noise_frame)
        effects_layout.addWidget(noise_frame)

        self.noise_model_label = QLabel("Noise Model:")
        self.noise_model_combo = QComboBox(noise_frame)
        self.noise_model_combo.addItems([
            "No Noise",
            "Poisson",
            "Gaussian",
            "Salt-and-Pepper",
            "Speckle",
            "Poisson+Gaussian",
        ])
        noise_layout.addWidget(self.noise_model_label, 0, 0)
        noise_layout.addWidget(self.noise_model_combo, 0, 2)

        self.noise_label = QLabel("Poisson Noise Mean:")
        self.noise_check = QCheckBox("", noise_frame)
        self.noise_field = QLineEdit(noise_frame)
        noise_layout.addWidget(self.noise_label, 1, 0)
        noise_layout.addWidget(self.noise_check, 1, 1)
        noise_layout.addWidget(self.noise_field, 1, 2)
        self.noise_check.stateChanged.connect(self.on_optional_effect_changed)

        self.noise_mean_label = QLabel("Poisson Noise Mean:")
        self.noise_mean_check = QCheckBox("", noise_frame)
        self.noise_mean_field = QLineEdit(noise_frame)
        noise_layout.addWidget(self.noise_mean_label, 2, 0)
        noise_layout.addWidget(self.noise_mean_check, 2, 1)
        noise_layout.addWidget(self.noise_mean_field, 2, 2)

        self.noise_std_label = QLabel("Gaussian Std Dev:")
        self.noise_std_check = QCheckBox("", noise_frame)
        self.noise_std_field = QLineEdit(noise_frame)
        noise_layout.addWidget(self.noise_std_label, 3, 0)
        noise_layout.addWidget(self.noise_std_check, 3, 1)
        noise_layout.addWidget(self.noise_std_field, 3, 2)

        self.saltpepper_label = QLabel("Salt-Pepper Prob:")
        self.saltpepper_check = QCheckBox("", noise_frame)
        self.saltpepper_field = QLineEdit(noise_frame)
        noise_layout.addWidget(self.saltpepper_label, 4, 0)
        noise_layout.addWidget(self.saltpepper_check, 4, 1)
        noise_layout.addWidget(self.saltpepper_field, 4, 2)

        blur_frame = QGroupBox("Blur & Downsampling", effects_tab)
        blur_layout = QGridLayout(blur_frame)
        effects_layout.addWidget(blur_frame)

        self.blur_label = QLabel("Blur:")
        self.blur_check = QCheckBox("", blur_frame)
        self.blur_field = QLineEdit(blur_frame)
        blur_layout.addWidget(self.blur_label, 0, 0)
        blur_layout.addWidget(self.blur_check, 0, 1)
        blur_layout.addWidget(self.blur_field, 0, 2)
        self.blur_check.stateChanged.connect(self.on_optional_effect_changed)

        self.blur_radius_label = QLabel("Blur Radius:")
        self.blur_radius_check = QCheckBox("", blur_frame)
        self.blur_radius_field = QLineEdit(blur_frame)
        blur_layout.addWidget(self.blur_radius_label, 1, 0)
        blur_layout.addWidget(self.blur_radius_check, 1, 1)
        blur_layout.addWidget(self.blur_radius_field, 1, 2)

        blur_layout.addWidget(QLabel("Down sample:"), 2, 0)
        self.sample_check = QCheckBox("", blur_frame)
        blur_layout.addWidget(self.sample_check, 2, 1)
        self.sample_field = QLineEdit(blur_frame)
        blur_layout.addWidget(self.sample_field, 2, 2)
        self.sample_check.stateChanged.connect(self.on_optional_effect_changed)

        intensity_frame = QGroupBox("Intensity & Scaling", effects_tab)
        intensity_layout = QGridLayout(intensity_frame)
        effects_layout.addWidget(intensity_frame)

        self.scale_label = QLabel("Scale:")
        self.scale_check = QCheckBox("", intensity_frame)
        self.scale_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.scale_label, 0, 0)
        intensity_layout.addWidget(self.scale_check, 0, 1)
        intensity_layout.addWidget(self.scale_field, 0, 2)
        self.scale_check.stateChanged.connect(self.on_optional_effect_changed)
        self.scale_field.editingFinished.connect(self.redraw_image)

        intensity_layout.addWidget(QLabel("Normalize:"), 1, 0)
        self.normalize_check = QCheckBox("", intensity_frame)
        intensity_layout.addWidget(self.normalize_check, 1, 1)
        self.normalize_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.normalize_field, 1, 2)
        self.normalize_check.stateChanged.connect(self.on_optional_effect_changed)

        intensity_layout.addWidget(QLabel("Cap:"), 2, 0)
        self.cap_check = QCheckBox("", intensity_frame)
        intensity_layout.addWidget(self.cap_check, 2, 1)
        self.cap_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.cap_field, 2, 2)
        self.cap_check.stateChanged.connect(self.on_optional_effect_changed)

        self.distance_label = QLabel("Distance:")
        self.distance_check = QCheckBox("", intensity_frame)
        self.distance_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.distance_label, 3, 0)
        intensity_layout.addWidget(self.distance_check, 3, 1)
        intensity_layout.addWidget(self.distance_field, 3, 2)
        self.distance_check.stateChanged.connect(self.on_optional_effect_changed)

        self.distance_falloff_label = QLabel("Distance Falloff:")
        self.distance_falloff_check = QCheckBox("", intensity_frame)
        self.distance_falloff_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.distance_falloff_label, 4, 0)
        intensity_layout.addWidget(self.distance_falloff_check, 4, 1)
        intensity_layout.addWidget(self.distance_falloff_field, 4, 2)

        effects_layout.addStretch(1)

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

        # Advanced post-processing tab (PSF)
        advanced_post_layout = QVBoxLayout(advanced_post_tab)
        advanced_post_tab.setLayout(advanced_post_layout)

        psf_group = QGroupBox("Point Spread Function", advanced_post_tab)
        psf_layout = QVBoxLayout(psf_group)
        advanced_post_layout.addWidget(psf_group)

        psf_header_layout = QHBoxLayout()
        self.apply_psf_checkbox = QCheckBox("Apply PSF Convolution", psf_group)
        self.psf_type_combo = QComboBox(psf_group)
        self.psf_type_combo.addItems(["None", "3D Gaussian", "Vectorial (SHG)"])
        psf_header_layout.addWidget(self.apply_psf_checkbox)
        psf_header_layout.addStretch(1)
        psf_header_layout.addWidget(QLabel("PSF Type:", psf_group))
        psf_header_layout.addWidget(self.psf_type_combo)
        psf_layout.addLayout(psf_header_layout)

        self.psf_gaussian_group = QGroupBox("Gaussian PSF Parameters", psf_group)
        gaussian_layout = QGridLayout(self.psf_gaussian_group)
        psf_layout.addWidget(self.psf_gaussian_group)

        self.psf_gaussian_na_field = QLineEdit(self.psf_gaussian_group)
        self.psf_gaussian_wavelength_field = QLineEdit(self.psf_gaussian_group)
        self.psf_voxel_z_field = QLineEdit(self.psf_gaussian_group)
        self.psf_voxel_y_field = QLineEdit(self.psf_gaussian_group)
        self.psf_voxel_x_field = QLineEdit(self.psf_gaussian_group)

        gaussian_layout.addWidget(QLabel("NA:"), 0, 0)
        gaussian_layout.addWidget(self.psf_gaussian_na_field, 0, 1)
        gaussian_layout.addWidget(QLabel("Wavelength (µm):"), 1, 0)
        gaussian_layout.addWidget(self.psf_gaussian_wavelength_field, 1, 1)
        gaussian_layout.addWidget(QLabel("Voxel size Z (µm):"), 2, 0)
        gaussian_layout.addWidget(self.psf_voxel_z_field, 2, 1)
        gaussian_layout.addWidget(QLabel("Voxel size Y (µm):"), 3, 0)
        gaussian_layout.addWidget(self.psf_voxel_y_field, 3, 1)
        gaussian_layout.addWidget(QLabel("Voxel size X (µm):"), 4, 0)
        gaussian_layout.addWidget(self.psf_voxel_x_field, 4, 1)

        self.psf_vectorial_group = QGroupBox("Vectorial (SHG) Parameters", psf_group)
        vectorial_layout = QGridLayout(self.psf_vectorial_group)
        psf_layout.addWidget(self.psf_vectorial_group)

        self.psf_vectorial_na_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_medium_ri_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_sample_ri_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_wavelength_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_polarization_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_volume_z_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_volume_y_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_volume_x_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_shape_z_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_shape_y_field = QLineEdit(self.psf_vectorial_group)
        self.psf_vectorial_shape_x_field = QLineEdit(self.psf_vectorial_group)

        vectorial_layout.addWidget(QLabel("NA:"), 0, 0)
        vectorial_layout.addWidget(self.psf_vectorial_na_field, 0, 1)
        vectorial_layout.addWidget(QLabel("Medium RI:"), 1, 0)
        vectorial_layout.addWidget(self.psf_vectorial_medium_ri_field, 1, 1)
        vectorial_layout.addWidget(QLabel("Sample RI:"), 2, 0)
        vectorial_layout.addWidget(self.psf_vectorial_sample_ri_field, 2, 1)
        vectorial_layout.addWidget(QLabel("Excitation λ (µm):"), 3, 0)
        vectorial_layout.addWidget(self.psf_vectorial_wavelength_field, 3, 1)
        vectorial_layout.addWidget(QLabel("Polarization (°):"), 4, 0)
        vectorial_layout.addWidget(self.psf_vectorial_polarization_field, 4, 1)
        vectorial_layout.addWidget(QLabel("Volume Z (µm):"), 5, 0)
        vectorial_layout.addWidget(self.psf_vectorial_volume_z_field, 5, 1)
        vectorial_layout.addWidget(QLabel("Volume Y (µm):"), 6, 0)
        vectorial_layout.addWidget(self.psf_vectorial_volume_y_field, 6, 1)
        vectorial_layout.addWidget(QLabel("Volume X (µm):"), 7, 0)
        vectorial_layout.addWidget(self.psf_vectorial_volume_x_field, 7, 1)
        vectorial_layout.addWidget(QLabel("Shape Z (px):"), 8, 0)
        vectorial_layout.addWidget(self.psf_vectorial_shape_z_field, 8, 1)
        vectorial_layout.addWidget(QLabel("Shape Y (px):"), 9, 0)
        vectorial_layout.addWidget(self.psf_vectorial_shape_y_field, 9, 1)
        vectorial_layout.addWidget(QLabel("Shape X (px):"), 10, 0)
        vectorial_layout.addWidget(self.psf_vectorial_shape_x_field, 10, 1)

        psf_layout.addStretch(1)
        self.preview_psf_button = QPushButton("Preview PSF (Plot)", psf_group)
        psf_layout.addWidget(self.preview_psf_button)
        advanced_post_layout.addStretch(1)

        match_real_data_layout = QVBoxLayout(match_real_data_tab)
        match_real_data_tab.setLayout(match_real_data_layout)

        input_group = QGroupBox("Input Data", match_real_data_tab)
        input_layout = QGridLayout(input_group)
        match_real_data_layout.addWidget(input_group)
        input_layout.addWidget(QLabel("Reference source:"), 0, 0)
        self.match_input_combo = QComboBox(input_group)
        self.match_input_combo.addItems(["Extracted centerlines (planned)", "Raw images (planned)"])
        input_layout.addWidget(self.match_input_combo, 0, 1)
        self.match_input_button = QPushButton("Choose input...", input_group)
        self.match_input_button.setEnabled(False)
        input_layout.addWidget(self.match_input_button, 1, 0, 1, 2)

        extraction_group = QGroupBox("Extract Structure", match_real_data_tab)
        extraction_layout = QGridLayout(extraction_group)
        match_real_data_layout.addWidget(extraction_group)
        extraction_layout.addWidget(QLabel("Extractor:"), 0, 0)
        self.extractor_combo = QComboBox(extraction_group)
        self.extractor_combo.addItems(["CT-FIRE", "Ridge Detection", "SOAX"])
        extraction_layout.addWidget(self.extractor_combo, 0, 1)
        self.run_extraction_button = QPushButton("Run Extraction", extraction_group)
        self.run_extraction_button.setEnabled(False)
        extraction_layout.addWidget(self.run_extraction_button, 1, 0, 1, 2)

        self.match_real_data_note = QLabel(
            "This workflow is scaffolded. The UI is now centered on structure-first generation, "
            "and extractor integration is the next backend step.",
            match_real_data_tab
        )
        self.match_real_data_note.setWordWrap(True)
        match_real_data_layout.addWidget(self.match_real_data_note)
        match_real_data_layout.addStretch(1)

        enhance_realism_layout = QVBoxLayout(enhance_realism_tab)
        enhance_realism_tab.setLayout(enhance_realism_layout)

        model_group = QGroupBox("Model Selection", enhance_realism_tab)
        model_layout = QGridLayout(model_group)
        enhance_realism_layout.addWidget(model_group)
        model_layout.addWidget(QLabel("Pipeline:"), 0, 0)
        self.enhancement_pipeline_combo = QComboBox(model_group)
        self.enhancement_pipeline_combo.addItems([DEFAULT_STAGE2_PIPELINE_NAME, "Custom model (planned)"])
        model_layout.addWidget(self.enhancement_pipeline_combo, 0, 1)
        model_layout.addWidget(QLabel("Modality:"), 1, 0)
        self.enhancement_modality_combo = QComboBox(model_group)
        self.enhancement_modality_combo.addItems(["SHG", "Polarized (planned)", "Other (planned)"])
        model_layout.addWidget(self.enhancement_modality_combo, 1, 1)
        model_layout.addWidget(QLabel("Model path:"), 2, 0)
        self.enhancement_model_path_field = QLineEdit(model_group)
        self.enhancement_model_path_field.setText(get_default_stage2_model_dir())
        model_layout.addWidget(self.enhancement_model_path_field, 2, 1)
        self.enhancement_model_browse_button = QPushButton("Browse...", model_group)
        model_layout.addWidget(self.enhancement_model_browse_button, 2, 2)
        model_layout.addWidget(QLabel("Device:"), 3, 0)
        self.enhancement_device_combo = QComboBox(model_group)
        self.enhancement_device_combo.addItems(["Auto", "CPU", "CUDA", "MPS"])
        model_layout.addWidget(self.enhancement_device_combo, 3, 1)
        self.enhancement_backend_status = QLabel("", model_group)
        self.enhancement_backend_status.setWordWrap(True)
        model_layout.addWidget(self.enhancement_backend_status, 4, 0, 1, 3)

        inference_group = QGroupBox("Inference", enhance_realism_tab)
        inference_layout = QVBoxLayout(inference_group)
        enhance_realism_layout.addWidget(inference_group)
        self.enhance_current_button = QPushButton("Enhance Current", inference_group)
        self.enhance_current_button.setEnabled(False)
        self.enhance_batch_button = QPushButton("Enhance Batch", inference_group)
        self.enhance_batch_button.setEnabled(False)
        inference_layout.addWidget(self.enhance_current_button)
        inference_layout.addWidget(self.enhance_batch_button)
        enhancement_preview_row = QHBoxLayout()
        enhancement_preview_row.addWidget(QLabel("Preview display:", inference_group))
        self.enhancement_preview_combo = QComboBox(inference_group)
        self.enhancement_preview_combo.addItems(["Raw", "Normalized", "Normalized + contrast"])
        self.enhancement_preview_combo.setCurrentText("Normalized")
        enhancement_preview_row.addWidget(self.enhancement_preview_combo)
        enhancement_preview_row.addStretch(1)
        inference_layout.addLayout(enhancement_preview_row)

        self.enhance_realism_note = QLabel("", enhance_realism_tab)
        self.enhance_realism_note.setWordWrap(True)
        self.enhance_realism_note.hide()
        enhance_realism_layout.addWidget(self.enhance_realism_note)
        enhance_realism_layout.addStretch(1)

        preview_export_layout = QVBoxLayout(preview_export_tab)
        preview_export_tab.setLayout(preview_export_layout)

        export_group = QGroupBox("Export", preview_export_tab)
        export_layout = QGridLayout(export_group)
        preview_export_layout.addWidget(export_group)
        self.export_current_button = QPushButton("Export Current Sample", export_group)
        export_layout.addWidget(self.export_current_button, 0, 0)
        self.export_all_button = QPushButton("Export All Samples", export_group)
        export_layout.addWidget(self.export_all_button, 0, 1)
        export_layout.addWidget(QLabel("Export detail:"), 1, 0)
        self.export_detail_combo = QComboBox(export_group)
        self.export_detail_combo.addItems([
            "Concise package",
            "Full geometry package",
        ])
        export_layout.addWidget(self.export_detail_combo, 1, 1)
        self.export_session_checkbox = QCheckBox("Include session restore", export_group)
        export_layout.addWidget(self.export_session_checkbox, 2, 0, 1, 2)
        self.export_custom_checkbox = QCheckBox("Choose name and location", export_group)
        export_layout.addWidget(self.export_custom_checkbox, 3, 0, 1, 2)

        summary_group = QGroupBox("Preview Summary", preview_export_tab)
        summary_layout = QVBoxLayout(summary_group)
        preview_export_layout.addWidget(summary_group)
        self.preview_export_summary = QLabel(summary_group)
        self.preview_export_summary.setWordWrap(True)
        self.preview_export_summary.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        summary_layout.addWidget(self.preview_export_summary)
        preview_export_layout.addStretch(1)

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
        self.centerline_color_combo.currentIndexChanged.connect(self.refresh_centerline_overlay)
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
            "reference": "Reference (Planned)",
            "compare": "Compare (Planned)",
            None: "None",
        }
        return labels.get(preview_target, "Fiber Image")

    def sync_preview_target_choices(self):
        fiber_enabled = self.generate_fiber_checkbox.isChecked()
        centerline_enabled = self.generate_centerline_checkbox.isChecked()
        enhanced_enabled = self.get_cached_enhanced_output(self.display_index) is not None
        enabled_states = {
            0: fiber_enabled,
            1: centerline_enabled,
            2: enhanced_enabled,
            3: False,
            4: False,
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
