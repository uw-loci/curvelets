from __future__ import annotations

import math

from PyQt6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QScrollArea,
    QVBoxLayout,
    QWidget,
)

# Params stored as cosine values internally but displayed/edited in degrees.
_ANGLE_PARAMS = {"thresh_ext", "thresh_dang_aextend", "thresh_linka"}

# Params shown in the default (common) view, in display order.
_COMMON_PARAMS = [
    "thresh_im2",
    "s_xlinkbox",
    "thresh_LMP",
    "thresh_LMPdist",
    "thresh_ext",
    "thresh_dang_aextend",
    "thresh_linka",
    "coefficient_percentile",
    "num_scales",
    "min_fiber_length",
]

# Human-readable labels and tooltips for each fire_2d_angle parameter.
# Order controls Advanced section display order.
_PARAM_META: dict[str, tuple[str, str]] = {
    "sigma_im":               ("σ image (pre-smooth)",               "px; 0 = off"),
    "sigma_d":                ("σ distance smooth",                  ""),
    "thresh_im2":             ("Image threshold (absolute)",         "intensity; background pixels below this are removed before distance transform"),
    "thresh_Dxlink":          ("Cross-link dist threshold",          "distance transform units"),
    "s_xlinkbox":             ("Cross-link search box",              "px"),
    "thresh_LMP":             ("LMP threshold",                      "local max pruning threshold"),
    "thresh_LMPdist":         ("LMP distance threshold",             "px; raise to 10–15 to prevent memory errors on large images"),
    "thresh_ext":             ("Extension threshold",                "degrees (0–180); cosine stored internally"),
    "lam_dirdecay":           ("Direction decay λ",                  ""),
    "s_minstep":              ("Min step size",                      "px"),
    "s_maxstep":              ("Max step size",                      "px"),
    "thresh_dang_aextend":    ("Angle extend threshold",             "degrees (0–180); cosine stored internally"),
    "thresh_dang_L":          ("Angle direction length",             "px"),
    "thresh_short_L":         ("Short-fiber prune length",           "px"),
    "s_fiberdir":             ("Fiber direction window",             "px"),
    "thresh_linkd":           ("Link distance threshold",            "px"),
    "thresh_linka":           ("Link angle threshold",               "degrees (0–180); cosine stored internally"),
    "thresh_flen":            ("Min fiber length (FIRE)",            "px; prunes short segments during FIRE tracing"),
    "min_fiber_length":       ("Min fiber length (CurveAlign filter)", "px; post-filter applied to traced fibers after FIRE"),
    "thresh_numv":            ("Min vertices per fiber",             ""),
    "s_boundthick":           ("Boundary thickness",                 "px"),
    "blist":                  ("Boundary list flag",                 "0/1"),
    "s_maxspace":             ("Max spacing",                        "px"),
    "lambda":                 ("Regularisation λ",                   ""),
    "ang_interval":           ("Angle interval",                     "deg"),
    # CT-FIRE curvelet preprocessing (only used when 'Use curvelet reconstruction' is checked)
    "coefficient_percentile": ("Curvelet coeff. percentile",         "0–1; fraction of curvelet coefficients kept (higher = more detail)"),
    "num_scales":             ("Curvelet finest scales",             "integer, e.g. 4"),
}


class CTFireParamsDialog(QDialog):
    """Popup dialog for editing CT-FIRE / fire_2d_angle parameters."""

    def __init__(self, current_params: dict, parent=None):
        super().__init__(parent)
        self.setWindowTitle("CT-FIRE Parameters")
        self.setModal(True)
        self.resize(460, 480)

        self._fields: dict[str, QLineEdit] = {}

        scroll_area = QScrollArea(self)
        scroll_area.setWidgetResizable(True)
        scroll_widget = QWidget()
        scroll_layout = QVBoxLayout(scroll_widget)
        scroll_layout.setContentsMargins(8, 8, 8, 8)
        scroll_layout.setSpacing(4)

        # Common parameters (always visible)
        common_form = QFormLayout()
        for key in _COMMON_PARAMS:
            if key in _PARAM_META:
                self._add_field(common_form, key, current_params)
        scroll_layout.addLayout(common_form)

        # Advanced toggle button
        self._adv_btn = QPushButton("▶  Show Advanced Parameters")
        self._adv_btn.setFlat(True)
        self._adv_btn.clicked.connect(self._toggle_advanced)
        scroll_layout.addWidget(self._adv_btn)

        # Advanced parameters section (hidden by default)
        self._adv_widget = QWidget()
        adv_form = QFormLayout(self._adv_widget)
        common_set = set(_COMMON_PARAMS)
        for key in _PARAM_META:
            if key not in common_set:
                self._add_field(adv_form, key, current_params)
        self._adv_widget.setVisible(False)
        scroll_layout.addWidget(self._adv_widget)
        scroll_layout.addStretch()

        scroll_area.setWidget(scroll_widget)

        buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        buttons.accepted.connect(self._on_accept)
        buttons.rejected.connect(self.reject)

        layout = QVBoxLayout(self)
        layout.addWidget(scroll_area)
        layout.addWidget(buttons)

    def _add_field(self, form: QFormLayout, key: str, current_params: dict) -> None:
        label_text, hint = _PARAM_META[key]
        raw = current_params.get(key, "")
        if key in _ANGLE_PARAMS:
            try:
                display_val = round(math.degrees(math.acos(float(raw))))
            except (ValueError, TypeError):
                display_val = raw
        else:
            display_val = raw
        field = QLineEdit(str(display_val))
        lbl = QLabel(f"{key} — {label_text}:")
        if hint:
            lbl.setToolTip(hint)
            field.setToolTip(hint)
        form.addRow(lbl, field)
        self._fields[key] = field

    def _toggle_advanced(self) -> None:
        visible = not self._adv_widget.isVisible()
        self._adv_widget.setVisible(visible)
        self._adv_btn.setText(
            "▼  Hide Advanced Parameters" if visible else "▶  Show Advanced Parameters"
        )

    def _on_accept(self):
        errors = []
        for key, field in self._fields.items():
            text = field.text().strip()
            try:
                v = float(text)
            except ValueError:
                errors.append(f"'{key}': cannot parse '{text}' as a number")
                continue
            if key in _ANGLE_PARAMS and not (0.0 <= v <= 180.0):
                errors.append(f"'{key}': angle must be 0–180°, got {v}")
        if errors:
            QMessageBox.warning(self, "Invalid input", "\n".join(errors))
            return
        self.accept()

    def get_params(self, base_params: dict) -> dict:
        """Return updated params dict — starts from base_params and overlays edited values."""
        result = dict(base_params)
        for key, field in self._fields.items():
            text = field.text().strip()
            try:
                if key in _ANGLE_PARAMS:
                    result[key] = math.cos(math.radians(float(text)))
                else:
                    original = base_params.get(key, 0)
                    if isinstance(original, int):
                        result[key] = int(float(text))
                    else:
                        result[key] = float(text)
            except (ValueError, TypeError):
                pass
        return result
