from __future__ import annotations

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import (
    QCheckBox,
    QComboBox,
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

    input_group = QGroupBox("Input Data", match_real_data_tab)
    input_layout = QGridLayout(input_group)
    match_real_data_layout.addWidget(input_group)
    input_layout.addWidget(QLabel("Reference source:"), 0, 0)
    window.match_input_combo = QComboBox(input_group)
    window.match_input_combo.addItems(["Extracted centerlines (planned)", "Raw images (planned)"])
    input_layout.addWidget(window.match_input_combo, 0, 1)
    window.match_input_button = QPushButton("Choose input...", input_group)
    window.match_input_button.setEnabled(False)
    input_layout.addWidget(window.match_input_button, 1, 0, 1, 2)

    extraction_group = QGroupBox("Extract Structure", match_real_data_tab)
    extraction_layout = QGridLayout(extraction_group)
    match_real_data_layout.addWidget(extraction_group)
    extraction_layout.addWidget(QLabel("Extractor:"), 0, 0)
    window.extractor_combo = QComboBox(extraction_group)
    window.extractor_combo.addItems(["CT-FIRE", "Ridge Detection", "SOAX"])
    extraction_layout.addWidget(window.extractor_combo, 0, 1)
    window.run_extraction_button = QPushButton("Run Extraction", extraction_group)
    window.run_extraction_button.setEnabled(False)
    extraction_layout.addWidget(window.run_extraction_button, 1, 0, 1, 2)

    window.match_real_data_note = QLabel(
        "This workflow is scaffolded. The UI is now centered on structure-first generation, "
        "and extractor integration is the next backend step.",
        match_real_data_tab,
    )
    window.match_real_data_note.setWordWrap(True)
    match_real_data_layout.addWidget(window.match_real_data_note)
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
