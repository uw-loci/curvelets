from __future__ import annotations

from PyQt6.QtWidgets import (
    QCheckBox,
    QGridLayout,
    QGroupBox,
    QLabel,
    QLineEdit,
    QPushButton,
    QSizePolicy,
    QTabWidget,
    QVBoxLayout,
    QWidget,
)


def build_session_header(window, main_layout):
    right_panel = QWidget(window)
    right_layout = QVBoxLayout(right_panel)
    right_layout.setContentsMargins(0, 0, 0, 0)
    right_panel.setSizePolicy(QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Expanding)
    main_layout.addWidget(right_panel, 0, 1, 5, 1)

    session_header_frame = QGroupBox("Session", right_panel)
    session_header_layout = QGridLayout(session_header_frame)
    right_layout.addWidget(session_header_frame)

    session_header_layout.addWidget(QLabel("Parameters:"), 0, 0)
    window.load_button = QPushButton("Open...", session_header_frame)
    session_header_layout.addWidget(window.load_button, 0, 1)

    session_header_layout.addWidget(QLabel("Number of images:"), 1, 0)
    window.n_images_field = QLineEdit(session_header_frame)
    session_header_layout.addWidget(window.n_images_field, 1, 1)

    window.seed_check = QCheckBox("Seed:", session_header_frame)
    session_header_layout.addWidget(window.seed_check, 2, 0)
    window.seed_field = QLineEdit(session_header_frame)
    session_header_layout.addWidget(window.seed_field, 2, 1)

    window.mode_toggle_button = QPushButton("Switch to 3D Mode", session_header_frame)
    session_header_layout.addWidget(window.mode_toggle_button, 0, 2)
    window.reset_button = QPushButton("Reset", session_header_frame)
    session_header_layout.addWidget(window.reset_button, 1, 2)
    window.generate_button = QPushButton("Generate...", session_header_frame)
    session_header_layout.addWidget(window.generate_button, 2, 2)
    window.abort_button = QPushButton("Abort", session_header_frame)
    window.abort_button.setEnabled(False)
    session_header_layout.addWidget(window.abort_button, 3, 2)
    return right_panel, right_layout


def build_tab_containers(window, right_layout, right_panel):
    window.tab_widget = QTabWidget(right_panel)
    right_layout.addWidget(window.tab_widget, 1)

    create_structure_tab = QWidget()
    match_real_data_tab = QWidget()
    enhance_realism_tab = QWidget()
    preview_export_tab = QWidget()

    window.create_structure_tab_index = window.tab_widget.addTab(
        create_structure_tab, "Create Structure"
    )
    window.match_real_data_tab_index = window.tab_widget.addTab(
        match_real_data_tab, "Match Real Data"
    )
    window.enhance_realism_tab_index = window.tab_widget.addTab(
        enhance_realism_tab, "Enhance Realism"
    )
    window.preview_export_tab_index = window.tab_widget.addTab(
        preview_export_tab, "Preview & Export"
    )

    create_structure_layout = QVBoxLayout(create_structure_tab)
    window.create_structure_tabs = QTabWidget(create_structure_tab)
    create_structure_layout.addWidget(window.create_structure_tabs)

    structure_tab = QWidget()
    distributions_tab = QWidget()
    outputs_tab = QWidget()
    fiber_render_tab = QWidget()
    advanced_post_tab = QWidget()

    window.structure_subtab_index = window.create_structure_tabs.addTab(
        structure_tab, "Structure"
    )
    window.distributions_subtab_index = window.create_structure_tabs.addTab(
        distributions_tab, "Distributions"
    )
    window.outputs_subtab_index = window.create_structure_tabs.addTab(outputs_tab, "Outputs")
    window.fiber_render_subtab_index = window.create_structure_tabs.addTab(
        fiber_render_tab, "Fiber Render"
    )
    window.advanced_subtab_index = window.create_structure_tabs.addTab(
        advanced_post_tab, "Advanced"
    )

    return {
        "structure_tab": structure_tab,
        "distributions_tab": distributions_tab,
        "outputs_tab": outputs_tab,
        "fiber_render_tab": fiber_render_tab,
        "advanced_post_tab": advanced_post_tab,
        "match_real_data_tab": match_real_data_tab,
        "enhance_realism_tab": enhance_realism_tab,
        "preview_export_tab": preview_export_tab,
    }
