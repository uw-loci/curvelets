from __future__ import annotations

from PyQt6.QtCore import QSize, Qt
from PyQt6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QFrame,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)


def build_display_panel(window, main_layout):
    display_frame = QFrame(window)
    display_layout = QVBoxLayout(display_frame)
    display_frame.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
    main_layout.addWidget(display_frame, 0, 0, 4, 1)

    window.display_stack.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
    window.display_stack.setMinimumSize(QSize(320, 320))
    window.image_display_2d = window.create_image_display_2d(display_frame)
    window.image_display_3d = window.create_image_display_3d(display_frame)
    window.display_stack.addWidget(window.image_display_2d)
    window.display_stack.addWidget(window.image_display_3d)
    display_layout.addWidget(window.display_stack, 1)
    return display_frame, display_layout


def build_navigation_controls(window, display_layout):
    window.prev_button = QPushButton("Previous", window)
    window.next_button = QPushButton("Next", window)

    window.buttons_layout = QHBoxLayout()
    window.buttons_layout.addWidget(window.prev_button)
    window.image_counter_label = QLabel("0/0", window)
    window.image_counter_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
    window.image_counter_label.setMinimumWidth(60)
    window.buttons_layout.addWidget(window.image_counter_label)
    window.buttons_layout.addWidget(window.next_button)
    display_layout.addLayout(window.buttons_layout)


def build_preview_controls(window, display_frame, display_layout):
    preview_controls_frame = QGroupBox("Preview", display_frame)
    preview_controls_layout = QGridLayout(preview_controls_frame)
    display_layout.addWidget(preview_controls_frame)

    preview_controls_layout.addWidget(QLabel("Preview target:"), 0, 0)
    window.preview_target_combo = QComboBox(preview_controls_frame)
    window.preview_target_combo.addItems(
        [
            "Fiber Image",
            "Centerline Mask",
            "Enhanced Image",
            "Input Image",
            "CT-FIRE Centerlines",
            "Reference (Planned)",
            "Compare (Planned)",
        ]
    )
    preview_controls_layout.addWidget(window.preview_target_combo, 0, 1)

    window.open_napari_button = QPushButton("Open in napari", preview_controls_frame)
    preview_controls_layout.addWidget(window.open_napari_button, 0, 2)

    window.preview_3d_view_label = QLabel("3D view:", preview_controls_frame)
    preview_controls_layout.addWidget(window.preview_3d_view_label, 1, 0)
    window.preview_3d_view_combo = QComboBox(preview_controls_frame)
    window.preview_3d_view_combo.addItems(
        [
            "Projection",
            "Attenuated Projection",
            "Isosurface",
        ]
    )
    preview_controls_layout.addWidget(window.preview_3d_view_combo, 1, 1)

    window.show_joints_checkbox = QCheckBox("Show joint points", preview_controls_frame)
    preview_controls_layout.addWidget(window.show_joints_checkbox, 2, 0, 1, 2)

    window.show_centerline_checkbox = QCheckBox(
        "Show centerline overlay", preview_controls_frame
    )
    preview_controls_layout.addWidget(window.show_centerline_checkbox, 3, 0, 1, 2)

    window.centerline_color_widget = QWidget(preview_controls_frame)
    centerline_color_layout = QHBoxLayout(window.centerline_color_widget)
    centerline_color_layout.setContentsMargins(0, 0, 0, 0)
    centerline_color_layout.setSpacing(6)
    window.centerline_color_label = QLabel("Color:", window.centerline_color_widget)
    window.centerline_color_combo = QComboBox(window.centerline_color_widget)
    window.centerline_color_combo.addItems(["Neon Green", "Cyan", "Magenta", "Yellow"])
    centerline_color_layout.addWidget(window.centerline_color_label)
    centerline_color_layout.addWidget(window.centerline_color_combo)
    centerline_color_layout.addStretch(1)
    preview_controls_layout.addWidget(window.centerline_color_widget, 4, 0, 1, 2)

    # Soft-IOU result label — updated by ExtractionWorkflowMixin when overlay is active
    window.soft_iou_result_label = QLabel("Soft-IOU: —", display_frame)
    window.soft_iou_result_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
    display_layout.addWidget(window.soft_iou_result_label)
