from __future__ import annotations

from PyQt6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QScrollArea,
    QVBoxLayout,
    QWidget,
)

# Human-readable labels and unit hints for the numeric params.
# Order here controls form order. Key is the actual fire_2d_angle parameter name.
_PARAM_META: dict[str, tuple[str, str]] = {
    "sigma_im":            ("σ image (pre-smooth)",          "px, 0 = off"),
    "sigma_d":             ("σ distance smooth",             ""),
    "thresh_im2":          ("Image threshold (absolute)",    "intensity; background pixels below this are removed"),
    "thresh_Dxlink":       ("Cross-link dist threshold",     "distance transform units"),
    "s_xlinkbox":          ("Cross-link search box",         "px"),
    "thresh_LMP":          ("LMP threshold",                 ""),
    "thresh_LMPdist":      ("LMP distance threshold",        "px; raise to 10-15 to prevent memory errors on large images"),
    "thresh_ext":          ("Extension threshold",           "cos angle"),
    "lam_dirdecay":        ("Direction decay λ",             ""),
    "s_minstep":           ("Min step size",                 "px"),
    "s_maxstep":           ("Max step size",                 "px"),
    "thresh_dang_aextend": ("Angle extend threshold",        "cos"),
    "thresh_dang_L":       ("Angle direction length",        "px"),
    "thresh_short_L":      ("Short-fiber prune length",      "px"),
    "s_fiberdir":          ("Fiber direction window",        "px"),
    "thresh_linkd":        ("Link distance threshold",       "px"),
    "thresh_linka":        ("Link angle threshold",          "cos"),
    "thresh_flen":         ("Min fiber length (FIRE)",        "px"),
    "min_fiber_length":   ("Min fiber length (CurveAlign filter)", "px; post-filter after FIRE tracing"),
    "thresh_numv":         ("Min vertices per fiber",        ""),
    "s_boundthick":        ("Boundary thickness",            "px"),
    "blist":               ("Boundary list flag",            "0/1"),
    "s_maxspace":          ("Max spacing",                   "px"),
    "lambda":              ("Regularisation λ",              ""),
    "ang_interval":        ("Angle interval",                "deg"),
    # CT-FIRE curvelet preprocessing (only used when 'Use curvelet reconstruction' is checked)
    "coefficient_percentile": ("Curvelet coeff. percentile", "0–1, higher = more detail"),
    "num_scales":             ("Curvelet finest scales",      "integer, e.g. 4"),
}


class CTFireParamsDialog(QDialog):
    """Popup dialog for editing CT-FIRE / fire_2d_angle parameters."""

    def __init__(self, current_params: dict, parent=None):
        super().__init__(parent)
        self.setWindowTitle("CT-FIRE Parameters")
        self.setModal(True)
        self.resize(480, 560)

        self._fields: dict[str, QLineEdit] = {}

        scroll_area = QScrollArea(self)
        scroll_area.setWidgetResizable(True)
        form_widget = QWidget()
        form = QFormLayout(form_widget)
        form.setLabelAlignment(form.labelAlignment())

        for key, (label, hint) in _PARAM_META.items():
            value = current_params.get(key, "")
            field = QLineEdit(str(value))
            if hint:
                field.setToolTip(hint)
                display_label = f"{key} — {label} ({hint}):"
            else:
                display_label = f"{key} — {label}:"
            form.addRow(QLabel(display_label), field)
            self._fields[key] = field

        scroll_area.setWidget(form_widget)

        buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        buttons.accepted.connect(self._on_accept)
        buttons.rejected.connect(self.reject)

        layout = QVBoxLayout(self)
        layout.addWidget(scroll_area)
        layout.addWidget(buttons)

    def _on_accept(self):
        errors = []
        for key, field in self._fields.items():
            text = field.text().strip()
            try:
                float(text)
            except ValueError:
                errors.append(f"'{key}': cannot parse '{text}' as a number")
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
                original = base_params.get(key, 0)
                if isinstance(original, int):
                    result[key] = int(float(text))
                else:
                    result[key] = float(text)
            except (ValueError, TypeError):
                pass
        return result
