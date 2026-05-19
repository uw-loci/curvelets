from __future__ import annotations

from PyQt6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QVBoxLayout,
    QWidget,
)


def build_outputs_tab(window, outputs_tab):
    outputs_layout = QVBoxLayout(outputs_tab)
    outputs_tab.setLayout(outputs_layout)

    image_config_frame = QGroupBox("Image Dimensions", outputs_tab)
    image_config_layout = QGridLayout(image_config_frame)
    outputs_layout.addWidget(image_config_frame)

    image_config_layout.addWidget(QLabel("Image width:"), 0, 0)
    window.image_width_field = QLineEdit(image_config_frame)
    image_config_layout.addWidget(window.image_width_field, 0, 1)

    image_config_layout.addWidget(QLabel("Image height:"), 1, 0)
    window.image_height_field = QLineEdit(image_config_frame)
    image_config_layout.addWidget(window.image_height_field, 1, 1)

    window.image_depth_label = QLabel("Image depth:")
    window.image_depth_field = QLineEdit(image_config_frame)
    image_config_layout.addWidget(window.image_depth_label, 2, 0)
    image_config_layout.addWidget(window.image_depth_field, 2, 1)

    image_config_layout.addWidget(QLabel("Image buffer:"), 3, 0)
    window.image_buffer_field = QLineEdit(image_config_frame)
    image_config_layout.addWidget(window.image_buffer_field, 3, 1)

    output_products_frame = QGroupBox("Derived Outputs", outputs_tab)
    render_grid = QGridLayout(output_products_frame)
    outputs_layout.addWidget(output_products_frame)

    window.generate_centerline_checkbox = QCheckBox(
        "Generate centerline mask", output_products_frame
    )
    render_grid.addWidget(window.generate_centerline_checkbox, 0, 0, 1, 2)

    window.generate_fiber_checkbox = QCheckBox("Generate fiber image", output_products_frame)
    fiber_output_row = QWidget(output_products_frame)
    fiber_output_row_layout = QHBoxLayout(fiber_output_row)
    fiber_output_row_layout.setContentsMargins(0, 0, 0, 0)
    fiber_output_row_layout.setSpacing(4)
    fiber_output_row_layout.addWidget(window.generate_fiber_checkbox)
    window.output_relationship_info_button = window.create_info_button(
        "Fiber Image only: blur, downsampling, normalize/cap/scale, distance or distance "
        "falloff, noise, scale bar, and PSF. Centerline Mask remains structural."
    )
    fiber_output_row_layout.addWidget(window.output_relationship_info_button)
    fiber_output_row_layout.addStretch(1)
    render_grid.addWidget(fiber_output_row, 1, 0, 1, 3)

    window.centerline_mask_width_label = QLabel("Centerline Mask Render Width (px):")
    window.centerline_mask_width_label.setToolTip(
        "Controls the rendered/exported centerline mask width. "
        "The realism model always uses a 1-pixel structural centerline input."
    )
    window.centerline_mask_width_field = QLineEdit(output_products_frame)
    window.centerline_mask_width_field.setToolTip(
        "Controls the rendered/exported centerline mask width. "
        "The realism model always uses a 1-pixel structural centerline input."
    )
    render_grid.addWidget(window.centerline_mask_width_label, 2, 0)
    render_grid.addWidget(window.centerline_mask_width_field, 2, 1)
    outputs_layout.addStretch(1)


def build_distributions_tab(window, distributions_tab):
    distributions_layout = QVBoxLayout(distributions_tab)
    distributions_tab.setLayout(distributions_layout)

    distribution_frame = QGroupBox("Structure Distributions", distributions_tab)
    distribution_layout = QGridLayout(distribution_frame)
    distributions_layout.addWidget(distribution_frame)

    distribution_layout.addWidget(QLabel("Length distribution:"), 0, 0)
    window.length_button = QPushButton("Modify...", distribution_frame)
    distribution_layout.addWidget(window.length_button, 0, 1)
    window.length_display = QLineEdit(distribution_frame)
    window.length_display.setReadOnly(True)
    window.length_display.setMinimumSize(200, 20)
    distribution_layout.addWidget(window.length_display, 0, 2, 1, 15)

    distribution_layout.addWidget(QLabel("Width distribution:"), 1, 0)
    window.width_button = QPushButton("Modify...", distribution_frame)
    distribution_layout.addWidget(window.width_button, 1, 1)
    window.width_display = QLineEdit(distribution_frame)
    window.width_display.setReadOnly(True)
    window.width_display.setMinimumSize(200, 20)
    distribution_layout.addWidget(window.width_display, 1, 2, 1, 15)

    distribution_layout.addWidget(QLabel("Straightness distribution:"), 2, 0)
    window.straight_button = QPushButton("Modify...", distribution_frame)
    distribution_layout.addWidget(window.straight_button, 2, 1)
    window.straight_display = QLineEdit(distribution_frame)
    window.straight_display.setReadOnly(True)
    window.straight_display.setMinimumSize(200, 20)
    distribution_layout.addWidget(window.straight_display, 2, 2, 1, 15)

    distribution_layout.addWidget(QLabel("Intensity distribution:"), 3, 0)
    window.intensity_button = QPushButton("Modify...", distribution_frame)
    distribution_layout.addWidget(window.intensity_button, 3, 1)
    window.intensity_display = QLineEdit(distribution_frame)
    window.intensity_display.setReadOnly(True)
    window.intensity_display.setMinimumSize(200, 20)
    distribution_layout.addWidget(window.intensity_display, 3, 2, 1, 15)

    distribution_layout.setColumnStretch(0, 1)
    distribution_layout.setColumnStretch(1, 1)
    distribution_layout.setColumnStretch(2, 15)


def build_structure_tab(window, structure_tab):
    fiber_layout = QVBoxLayout(structure_tab)
    structure_tab.setLayout(fiber_layout)

    values_frame = QGroupBox("Values", structure_tab)
    values_layout = QGridLayout(values_frame)
    fiber_layout.addWidget(values_frame)

    values_layout.addWidget(QLabel("Number of fibers:"), 0, 0)
    window.n_fibers_field = QLineEdit(values_frame)
    values_layout.addWidget(window.n_fibers_field, 0, 1)

    values_layout.addWidget(QLabel("Segment length:"), 1, 0)
    window.segment_field = QLineEdit(values_frame)
    values_layout.addWidget(window.segment_field, 1, 1)

    values_layout.addWidget(QLabel("Width change:"), 2, 0)
    window.width_change_field = QLineEdit(values_frame)
    values_layout.addWidget(window.width_change_field, 2, 1)

    window.alignment_label = QLabel("Alignment:")
    window.alignment_field = QLineEdit(values_frame)
    values_layout.addWidget(window.alignment_label, 3, 0)
    values_layout.addWidget(window.alignment_field, 3, 1)

    window.joint_points_label = QLabel("Joint points:")
    window.joint_points_field = QLineEdit(values_frame)
    values_layout.addWidget(window.joint_points_label, 5, 0)
    values_layout.addWidget(window.joint_points_field, 5, 1)

    window.use_joints_checkbox = QCheckBox("Use joints", values_frame)
    values_layout.addWidget(window.use_joints_checkbox, 5, 2)

    window.alignment3D_label = QLabel("Alignment 3D:")
    window.alignment3D_field = QLineEdit(values_frame)
    values_layout.addWidget(window.alignment3D_label, 3, 0)
    values_layout.addWidget(window.alignment3D_field, 3, 1)

    window.mean_angle_label = QLabel("Mean angle:")
    window.mean_angle_field = QLineEdit(values_frame)
    values_layout.addWidget(window.mean_angle_label, 4, 0)
    values_layout.addWidget(window.mean_angle_field, 4, 1)

    window.mean_direction_label = QLabel("Mean direction:")
    window.mean_direction_field = QLineEdit(values_frame)
    values_layout.addWidget(window.mean_direction_label, 4, 0)
    values_layout.addWidget(window.mean_direction_field, 4, 1)

    window.min_angle_change_label = QLabel("Min angle change (degrees):")
    window.min_angle_change_field = QLineEdit(values_frame)
    values_layout.addWidget(window.min_angle_change_label, 6, 0)
    values_layout.addWidget(window.min_angle_change_field, 6, 1)

    window.max_angle_change_label = QLabel("Max angle change (degrees):")
    window.max_angle_change_field = QLineEdit(values_frame)
    values_layout.addWidget(window.max_angle_change_label, 7, 0)
    values_layout.addWidget(window.max_angle_change_field, 7, 1)

    window.curvature_label = QLabel("Curvature:")
    window.curvature_field = QLineEdit(values_frame)
    values_layout.addWidget(window.curvature_label, 8, 0)
    values_layout.addWidget(window.curvature_field, 8, 1)

    window.branching_probability_label = QLabel("Branching Probability:")
    window.branching_probability_field = QLineEdit(values_frame)
    values_layout.addWidget(window.branching_probability_label, 9, 0)
    values_layout.addWidget(window.branching_probability_field, 9, 1)

    values_layout.setColumnStretch(0, 1)
    values_layout.setColumnStretch(1, 3)
    values_layout.setColumnStretch(2, 1)
    values_layout.setColumnStretch(3, 2)

    smoothing_frame = QGroupBox("Smoothing", structure_tab)
    smoothing_layout = QGridLayout(smoothing_frame)
    fiber_layout.addWidget(smoothing_frame)

    smoothing_layout.addWidget(QLabel("Bubble:"), 0, 0)
    window.bubble_check = QCheckBox("", smoothing_frame)
    smoothing_layout.addWidget(window.bubble_check, 0, 1)
    window.bubble_field = QLineEdit(smoothing_frame)
    smoothing_layout.addWidget(window.bubble_field, 0, 2)

    smoothing_layout.addWidget(QLabel("Swap:"), 1, 0)
    window.swap_check = QCheckBox("", smoothing_frame)
    smoothing_layout.addWidget(window.swap_check, 1, 1)
    window.swap_field = QLineEdit(smoothing_frame)
    smoothing_layout.addWidget(window.swap_field, 1, 2)

    smoothing_layout.addWidget(QLabel("Spline:"), 2, 0)
    window.spline_check = QCheckBox("", smoothing_frame)
    smoothing_layout.addWidget(window.spline_check, 2, 1)
    window.spline_field = QLineEdit(smoothing_frame)
    smoothing_layout.addWidget(window.spline_field, 2, 2)


def build_fiber_render_tab(window, fiber_render_tab):
    effects_layout = QVBoxLayout(fiber_render_tab)
    fiber_render_tab.setLayout(effects_layout)

    noise_frame = QGroupBox("Noise", fiber_render_tab)
    noise_layout = QGridLayout(noise_frame)
    effects_layout.addWidget(noise_frame)

    window.noise_model_label = QLabel("Noise Model:")
    window.noise_model_combo = QComboBox(noise_frame)
    window.noise_model_combo.addItems(
        [
            "No Noise",
            "Poisson",
            "Gaussian",
            "Salt-and-Pepper",
            "Speckle",
            "Poisson+Gaussian",
        ]
    )
    noise_layout.addWidget(window.noise_model_label, 0, 0)
    noise_layout.addWidget(window.noise_model_combo, 0, 2)

    window.noise_label = QLabel("Poisson Noise Mean:")
    window.noise_check = QCheckBox("", noise_frame)
    window.noise_field = QLineEdit(noise_frame)
    noise_layout.addWidget(window.noise_label, 1, 0)
    noise_layout.addWidget(window.noise_check, 1, 1)
    noise_layout.addWidget(window.noise_field, 1, 2)

    window.noise_mean_label = QLabel("Poisson Noise Mean:")
    window.noise_mean_check = QCheckBox("", noise_frame)
    window.noise_mean_field = QLineEdit(noise_frame)
    noise_layout.addWidget(window.noise_mean_label, 2, 0)
    noise_layout.addWidget(window.noise_mean_check, 2, 1)
    noise_layout.addWidget(window.noise_mean_field, 2, 2)

    window.noise_std_label = QLabel("Gaussian Std Dev:")
    window.noise_std_check = QCheckBox("", noise_frame)
    window.noise_std_field = QLineEdit(noise_frame)
    noise_layout.addWidget(window.noise_std_label, 3, 0)
    noise_layout.addWidget(window.noise_std_check, 3, 1)
    noise_layout.addWidget(window.noise_std_field, 3, 2)

    window.saltpepper_label = QLabel("Salt-Pepper Prob:")
    window.saltpepper_check = QCheckBox("", noise_frame)
    window.saltpepper_field = QLineEdit(noise_frame)
    noise_layout.addWidget(window.saltpepper_label, 4, 0)
    noise_layout.addWidget(window.saltpepper_check, 4, 1)
    noise_layout.addWidget(window.saltpepper_field, 4, 2)

    blur_frame = QGroupBox("Blur & Downsampling", fiber_render_tab)
    blur_layout = QGridLayout(blur_frame)
    effects_layout.addWidget(blur_frame)

    window.blur_label = QLabel("Blur:")
    window.blur_check = QCheckBox("", blur_frame)
    window.blur_field = QLineEdit(blur_frame)
    blur_layout.addWidget(window.blur_label, 0, 0)
    blur_layout.addWidget(window.blur_check, 0, 1)
    blur_layout.addWidget(window.blur_field, 0, 2)

    window.blur_radius_label = QLabel("Blur Radius:")
    window.blur_radius_check = QCheckBox("", blur_frame)
    window.blur_radius_field = QLineEdit(blur_frame)
    blur_layout.addWidget(window.blur_radius_label, 1, 0)
    blur_layout.addWidget(window.blur_radius_check, 1, 1)
    blur_layout.addWidget(window.blur_radius_field, 1, 2)

    blur_layout.addWidget(QLabel("Down sample:"), 2, 0)
    window.sample_check = QCheckBox("", blur_frame)
    blur_layout.addWidget(window.sample_check, 2, 1)
    window.sample_field = QLineEdit(blur_frame)
    blur_layout.addWidget(window.sample_field, 2, 2)

    intensity_frame = QGroupBox("Intensity & Scaling", fiber_render_tab)
    intensity_layout = QGridLayout(intensity_frame)
    effects_layout.addWidget(intensity_frame)

    window.scale_label = QLabel("Scale:")
    window.scale_check = QCheckBox("", intensity_frame)
    window.scale_field = QLineEdit(intensity_frame)
    intensity_layout.addWidget(window.scale_label, 0, 0)
    intensity_layout.addWidget(window.scale_check, 0, 1)
    intensity_layout.addWidget(window.scale_field, 0, 2)

    intensity_layout.addWidget(QLabel("Normalize:"), 1, 0)
    window.normalize_check = QCheckBox("", intensity_frame)
    intensity_layout.addWidget(window.normalize_check, 1, 1)
    window.normalize_field = QLineEdit(intensity_frame)
    intensity_layout.addWidget(window.normalize_field, 1, 2)

    intensity_layout.addWidget(QLabel("Cap:"), 2, 0)
    window.cap_check = QCheckBox("", intensity_frame)
    intensity_layout.addWidget(window.cap_check, 2, 1)
    window.cap_field = QLineEdit(intensity_frame)
    intensity_layout.addWidget(window.cap_field, 2, 2)

    window.distance_label = QLabel("Distance:")
    window.distance_check = QCheckBox("", intensity_frame)
    window.distance_field = QLineEdit(intensity_frame)
    intensity_layout.addWidget(window.distance_label, 3, 0)
    intensity_layout.addWidget(window.distance_check, 3, 1)
    intensity_layout.addWidget(window.distance_field, 3, 2)

    window.distance_falloff_label = QLabel("Distance Falloff:")
    window.distance_falloff_check = QCheckBox("", intensity_frame)
    window.distance_falloff_field = QLineEdit(intensity_frame)
    intensity_layout.addWidget(window.distance_falloff_label, 4, 0)
    intensity_layout.addWidget(window.distance_falloff_check, 4, 1)
    intensity_layout.addWidget(window.distance_falloff_field, 4, 2)

    effects_layout.addStretch(1)


def build_advanced_post_tab(window, advanced_post_tab):
    advanced_post_layout = QVBoxLayout(advanced_post_tab)
    advanced_post_tab.setLayout(advanced_post_layout)

    psf_group = QGroupBox("Point Spread Function", advanced_post_tab)
    psf_layout = QVBoxLayout(psf_group)
    advanced_post_layout.addWidget(psf_group)

    psf_header_layout = QHBoxLayout()
    window.apply_psf_checkbox = QCheckBox("Apply PSF Convolution", psf_group)
    window.psf_type_combo = QComboBox(psf_group)
    window.psf_type_combo.addItems(["None", "3D Gaussian", "Vectorial (SHG)"])
    psf_header_layout.addWidget(window.apply_psf_checkbox)
    psf_header_layout.addStretch(1)
    psf_header_layout.addWidget(QLabel("PSF Type:", psf_group))
    psf_header_layout.addWidget(window.psf_type_combo)
    psf_layout.addLayout(psf_header_layout)

    window.psf_gaussian_group = QGroupBox("Gaussian PSF Parameters", psf_group)
    gaussian_layout = QGridLayout(window.psf_gaussian_group)
    psf_layout.addWidget(window.psf_gaussian_group)

    window.psf_gaussian_na_field = QLineEdit(window.psf_gaussian_group)
    window.psf_gaussian_wavelength_field = QLineEdit(window.psf_gaussian_group)
    window.psf_voxel_z_field = QLineEdit(window.psf_gaussian_group)
    window.psf_voxel_y_field = QLineEdit(window.psf_gaussian_group)
    window.psf_voxel_x_field = QLineEdit(window.psf_gaussian_group)

    gaussian_layout.addWidget(QLabel("NA:"), 0, 0)
    gaussian_layout.addWidget(window.psf_gaussian_na_field, 0, 1)
    gaussian_layout.addWidget(QLabel("Wavelength (µm):"), 1, 0)
    gaussian_layout.addWidget(window.psf_gaussian_wavelength_field, 1, 1)
    gaussian_layout.addWidget(QLabel("Voxel size Z (µm):"), 2, 0)
    gaussian_layout.addWidget(window.psf_voxel_z_field, 2, 1)
    gaussian_layout.addWidget(QLabel("Voxel size Y (µm):"), 3, 0)
    gaussian_layout.addWidget(window.psf_voxel_y_field, 3, 1)
    gaussian_layout.addWidget(QLabel("Voxel size X (µm):"), 4, 0)
    gaussian_layout.addWidget(window.psf_voxel_x_field, 4, 1)

    window.psf_vectorial_group = QGroupBox("Vectorial (SHG) Parameters", psf_group)
    vectorial_layout = QGridLayout(window.psf_vectorial_group)
    psf_layout.addWidget(window.psf_vectorial_group)

    window.psf_vectorial_na_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_medium_ri_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_sample_ri_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_wavelength_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_polarization_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_volume_z_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_volume_y_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_volume_x_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_shape_z_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_shape_y_field = QLineEdit(window.psf_vectorial_group)
    window.psf_vectorial_shape_x_field = QLineEdit(window.psf_vectorial_group)

    labels = [
        ("NA:", window.psf_vectorial_na_field),
        ("Medium RI:", window.psf_vectorial_medium_ri_field),
        ("Sample RI:", window.psf_vectorial_sample_ri_field),
        ("Excitation λ (µm):", window.psf_vectorial_wavelength_field),
        ("Polarization (°):", window.psf_vectorial_polarization_field),
        ("Volume Z (µm):", window.psf_vectorial_volume_z_field),
        ("Volume Y (µm):", window.psf_vectorial_volume_y_field),
        ("Volume X (µm):", window.psf_vectorial_volume_x_field),
        ("Shape Z (px):", window.psf_vectorial_shape_z_field),
        ("Shape Y (px):", window.psf_vectorial_shape_y_field),
        ("Shape X (px):", window.psf_vectorial_shape_x_field),
    ]
    for row_index, (label_text, field) in enumerate(labels):
        vectorial_layout.addWidget(QLabel(label_text), row_index, 0)
        vectorial_layout.addWidget(field, row_index, 1)

    psf_layout.addStretch(1)
    window.preview_psf_button = QPushButton("Preview PSF (Plot)", psf_group)
    psf_layout.addWidget(window.preview_psf_button)
    advanced_post_layout.addStretch(1)
