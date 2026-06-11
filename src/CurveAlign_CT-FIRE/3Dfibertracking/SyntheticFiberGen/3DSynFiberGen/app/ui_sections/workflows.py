from __future__ import annotations

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QDoubleSpinBox,
    QGridLayout,
    QGroupBox,
    QLabel,
    QLineEdit,
    QPushButton,
    QVBoxLayout,
)

from realism import DEFAULT_STAGE2_PIPELINE_NAME, get_default_stage2_model_dir


def build_match_real_data_tab(window, match_real_data_tab):
    match_real_data_layout = QVBoxLayout(match_real_data_tab)
    match_real_data_tab.setLayout(match_real_data_layout)

    # --- Input image ---
    input_group = QGroupBox("Input Data", match_real_data_tab)
    input_layout = QGridLayout(input_group)
    match_real_data_layout.addWidget(input_group)
    window.match_input_button = QPushButton("Load input image…", input_group)
    input_layout.addWidget(window.match_input_button, 0, 0)
    window.match_input_path_label = QLabel("No image loaded", input_group)
    window.match_input_path_label.setWordWrap(True)
    input_layout.addWidget(window.match_input_path_label, 0, 1)

    # --- Extractor selection and run ---
    extraction_group = QGroupBox("Extract Structure", match_real_data_tab)
    extraction_layout = QGridLayout(extraction_group)
    match_real_data_layout.addWidget(extraction_group)
    extraction_layout.addWidget(QLabel("Extractor:"), 0, 0)
    window.extractor_combo = QComboBox(extraction_group)
    window.extractor_combo.addItems(["CT-FIRE", "Ridge Detection", "SOAX"])
    extraction_layout.addWidget(window.extractor_combo, 0, 1)
    window.use_ct_reconstruction_checkbox = QCheckBox(
        "Use curvelet reconstruction (CT-FIRE)", extraction_group
    )
    window.use_ct_reconstruction_checkbox.setChecked(False)
    extraction_layout.addWidget(window.use_ct_reconstruction_checkbox, 1, 0, 1, 2)
    window.run_extraction_button = QPushButton("Run Extraction", extraction_group)
    window.run_extraction_button.setEnabled(False)
    extraction_layout.addWidget(window.run_extraction_button, 2, 0)
    window.ctfire_params_button = QPushButton("CT-FIRE Params…", extraction_group)
    extraction_layout.addWidget(window.ctfire_params_button, 2, 1)
    window.extraction_status_label = QLabel("Idle", extraction_group)
    window.extraction_status_label.setWordWrap(True)
    extraction_layout.addWidget(window.extraction_status_label, 3, 0, 1, 2)

    # --- Soft-IOU parameters ---
    soft_iou_group = QGroupBox("Soft-IOU Comparison", match_real_data_tab)
    soft_iou_layout = QGridLayout(soft_iou_group)
    match_real_data_layout.addWidget(soft_iou_group)

    window.soft_iou_enabled_checkbox = QCheckBox("Compute soft-IOU", soft_iou_group)
    window.soft_iou_enabled_checkbox.setChecked(True)
    soft_iou_layout.addWidget(window.soft_iou_enabled_checkbox, 0, 0, 1, 2)

    soft_iou_layout.addWidget(QLabel("Smoothing σ (px):"), 1, 0)
    window.soft_iou_sigma_spinbox = QDoubleSpinBox(soft_iou_group)
    window.soft_iou_sigma_spinbox.setRange(1.0, 20.0)
    window.soft_iou_sigma_spinbox.setSingleStep(0.5)
    window.soft_iou_sigma_spinbox.setValue(5.0)
    soft_iou_layout.addWidget(window.soft_iou_sigma_spinbox, 1, 1)

    match_real_data_layout.addStretch(1)


def build_enhance_realism_tab(window, enhance_realism_tab):
    enhance_realism_layout = QVBoxLayout(enhance_realism_tab)
    enhance_realism_tab.setLayout(enhance_realism_layout)

    model_group = QGroupBox("Model Selection", enhance_realism_tab)
    model_layout = QGridLayout(model_group)
    enhance_realism_layout.addWidget(model_group)
    model_layout.addWidget(QLabel("Pipeline:"), 0, 0)
    window.enhancement_pipeline_combo = QComboBox(model_group)
    window.enhancement_pipeline_combo.addItems(
        [DEFAULT_STAGE2_PIPELINE_NAME, "Custom model (planned)"]
    )
    model_layout.addWidget(window.enhancement_pipeline_combo, 0, 1)
    model_layout.addWidget(QLabel("Modality:"), 1, 0)
    window.enhancement_modality_combo = QComboBox(model_group)
    window.enhancement_modality_combo.addItems(["SHG", "Polarized (planned)", "Other (planned)"])
    model_layout.addWidget(window.enhancement_modality_combo, 1, 1)
    model_layout.addWidget(QLabel("Model path:"), 2, 0)
    window.enhancement_model_path_field = QLineEdit(model_group)
    window.enhancement_model_path_field.setText(get_default_stage2_model_dir())
    model_layout.addWidget(window.enhancement_model_path_field, 2, 1)
    window.enhancement_model_browse_button = QPushButton("Browse...", model_group)
    model_layout.addWidget(window.enhancement_model_browse_button, 2, 2)
    model_layout.addWidget(QLabel("Device:"), 3, 0)
    window.enhancement_device_combo = QComboBox(model_group)
    window.enhancement_device_combo.addItems(["Auto", "CPU", "CUDA", "MPS"])
    model_layout.addWidget(window.enhancement_device_combo, 3, 1)
    window.enhancement_backend_status = QLabel("", model_group)
    window.enhancement_backend_status.setWordWrap(True)
    model_layout.addWidget(window.enhancement_backend_status, 4, 0, 1, 3)

    inference_group = QGroupBox("Inference", enhance_realism_tab)
    inference_layout = QVBoxLayout(inference_group)
    enhance_realism_layout.addWidget(inference_group)
    window.enhance_current_button = QPushButton("Enhance Current", inference_group)
    window.enhance_current_button.setEnabled(False)
    window.enhance_batch_button = QPushButton("Enhance Batch", inference_group)
    window.enhance_batch_button.setEnabled(False)
    inference_layout.addWidget(window.enhance_current_button)
    inference_layout.addWidget(window.enhance_batch_button)

    enhancement_preview_row = QGridLayout()
    enhancement_preview_row.addWidget(QLabel("Preview display:", inference_group), 0, 0)
    window.enhancement_preview_combo = QComboBox(inference_group)
    window.enhancement_preview_combo.addItems(["Raw", "Normalized", "Normalized + contrast"])
    window.enhancement_preview_combo.setCurrentText("Normalized")
    enhancement_preview_row.addWidget(window.enhancement_preview_combo, 0, 1)
    inference_layout.addLayout(enhancement_preview_row)

    window.enhance_realism_note = QLabel("", enhance_realism_tab)
    window.enhance_realism_note.setWordWrap(True)
    window.enhance_realism_note.hide()
    enhance_realism_layout.addWidget(window.enhance_realism_note)
    enhance_realism_layout.addStretch(1)


def build_preview_export_tab(window, preview_export_tab):
    preview_export_layout = QVBoxLayout(preview_export_tab)
    preview_export_tab.setLayout(preview_export_layout)

    export_group = QGroupBox("Export", preview_export_tab)
    export_layout = QGridLayout(export_group)
    preview_export_layout.addWidget(export_group)
    window.export_current_button = QPushButton("Export Current Sample", export_group)
    export_layout.addWidget(window.export_current_button, 0, 0)
    window.export_all_button = QPushButton("Export All Samples", export_group)
    export_layout.addWidget(window.export_all_button, 0, 1)
    export_layout.addWidget(QLabel("Export detail:"), 1, 0)
    window.export_detail_combo = QComboBox(export_group)
    window.export_detail_combo.addItems(["Concise package", "Full geometry package"])
    export_layout.addWidget(window.export_detail_combo, 1, 1)
    window.export_session_checkbox = QCheckBox("Include session restore", export_group)
    export_layout.addWidget(window.export_session_checkbox, 2, 0, 1, 2)
    window.export_custom_checkbox = QCheckBox("Choose name and location", export_group)
    export_layout.addWidget(window.export_custom_checkbox, 3, 0, 1, 2)

    summary_group = QGroupBox("Preview Summary", preview_export_tab)
    summary_layout = QVBoxLayout(summary_group)
    preview_export_layout.addWidget(summary_group)
    window.preview_export_summary = QLabel(summary_group)
    window.preview_export_summary.setWordWrap(True)
    window.preview_export_summary.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
    summary_layout.addWidget(window.preview_export_summary)
    preview_export_layout.addStretch(1)
