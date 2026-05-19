
from __future__ import annotations

from PyQt6.QtWidgets import QComboBox, QDialog, QHBoxLayout, QLabel, QLineEdit, QMessageBox, QPushButton, QVBoxLayout

from core.distributions import Gaussian, PiecewiseLinear, Uniform

class DistributionDialog(QDialog):
    """Dialog for selecting and configuring probability distributions."""

    def __init__(self, distribution):
        """Initializes the dialog with a given distribution."""
        super().__init__()
        self.original = distribution.clone()  # Store original for cancel action
        self.distribution = distribution
        self.init_ui()
        self.display_distribution()
        self.setWindowTitle("Distribution Dialog")
        self.setModal(True)
        self.show()

    def init_ui(self):
        """Initializes the user interface components."""
        layout = QVBoxLayout()

        # Dropdown for selecting distribution type
        self.comboBox = QComboBox()
        self.comboBox.addItems([Gaussian.typename, Uniform.typename, PiecewiseLinear.typename])
        layout.addWidget(self.comboBox)

        # Editable fields for distribution bounds
        self.lower_bound_label = QLabel("Lower Bound:")
        self.lower_bound_field = QLineEdit(str(self.distribution.lower_bound))

        self.upper_bound_label = QLabel("Upper Bound:")
        self.upper_bound_field = QLineEdit(str(self.distribution.upper_bound))

        layout.addWidget(self.lower_bound_label)
        layout.addWidget(self.lower_bound_field)
        layout.addWidget(self.upper_bound_label)
        layout.addWidget(self.upper_bound_field)

        # Input fields for distribution-specific parameters
        self.label1 = QLabel()
        self.field1 = QLineEdit()
        self.label2 = QLabel()
        self.field2 = QLineEdit()

        layout.addWidget(self.label1)
        layout.addWidget(self.field1)
        layout.addWidget(self.label2)
        layout.addWidget(self.field2)

        # Buttons
        button_layout = QHBoxLayout()
        self.okay_button = QPushButton("OK")
        self.cancel_button = QPushButton("Cancel")
        button_layout.addWidget(self.okay_button)
        button_layout.addWidget(self.cancel_button)
        layout.addLayout(button_layout)

        self.setLayout(layout)

        # Event connections
        self.comboBox.currentIndexChanged.connect(self.selection_changed)
        self.okay_button.clicked.connect(self.okay_pressed)
        self.cancel_button.clicked.connect(self.cancel_pressed)

    def display_distribution(self):
        """Displays the currently selected distribution and its parameters."""
        self.comboBox.setCurrentText(self.distribution.get_type())
        self.lower_bound_field.setText(str(self.distribution.lower_bound))
        self.upper_bound_field.setText(str(self.distribution.upper_bound))

        # Adjust input fields based on distribution type
        if isinstance(self.distribution, Gaussian):
            self.label1.setText("Mean:")
            self.label1.setToolTip(self.distribution.mean.get_hint())
            self.field1.setText(self.distribution.mean.get_string())

            self.label2.setText("Sigma:")
            self.label2.setToolTip(self.distribution.sigma.get_hint())
            self.field2.setText(self.distribution.sigma.get_string())

        elif isinstance(self.distribution, Uniform):
            self.label1.setText("Min:")
            self.label1.setToolTip(self.distribution.min.get_hint())
            self.field1.setText(self.distribution.min.get_string())

            self.label2.setText("Max:")
            self.label2.setToolTip(self.distribution.max.get_hint())
            self.field2.setText(self.distribution.max.get_string())

        elif isinstance(self.distribution, PiecewiseLinear):
            self.label1.setText("X values:")
            self.label1.setToolTip("X values of points in the piecewise linear distribution")
            self.field1.setText(self.distribution.get_x_string())

            self.label2.setText("Y values:")
            self.label2.setToolTip("Y values of points in the piecewise linear distribution")
            self.field2.setText(self.distribution.get_y_string())

    def selection_changed(self):
        """Handles changes in distribution type selection."""
        selection = self.comboBox.currentText()
        if selection != self.distribution.get_type():
            lower_bound = self.get_lower_bound()
            upper_bound = self.get_upper_bound()
            if selection == Gaussian.typename:
                self.distribution = Gaussian(lower_bound, upper_bound)
            elif selection == Uniform.typename:
                self.distribution = Uniform(lower_bound, upper_bound)
            elif selection == PiecewiseLinear.typename:
                self.distribution = PiecewiseLinear(lower_bound, upper_bound)
            self.display_distribution()  # Refresh UI

    def okay_pressed(self):
        """Applies the changes and validates the new distribution parameters."""
        try:
            # Parse and validate the lower and upper bounds
            lower_bound = float(self.lower_bound_field.text())
            upper_bound = float(self.upper_bound_field.text())

            if lower_bound >= upper_bound:
                raise ValueError("Lower bound must be less than upper bound.")

            self.distribution.set_bounds(lower_bound, upper_bound)

            selection = self.comboBox.currentText()

            # Parse values based on the selected distribution type
            if selection == Gaussian.typename:
                self.distribution.mean.parse(self.field1.text(), float)
                self.distribution.sigma.parse(self.field2.text(), float)

            elif selection == Uniform.typename:
                min_val = float(self.field1.text())
                max_val = float(self.field2.text())

                # Ensure min/max are within bounds
                if min_val < lower_bound or max_val > upper_bound:
                    raise ValueError(f"Min/Max must be within [{lower_bound}, {upper_bound}].")

                self.distribution.min.parse(self.field1.text(), float)
                self.distribution.max.parse(self.field2.text(), float)

            elif selection == PiecewiseLinear.typename:
                self.distribution.parse_xy_values(self.field1.text(), self.field2.text())

            self.distribution.verify()  # Ensure parameters are valid
            self.accept()  # Close dialog with success
        except ValueError as e:
            QMessageBox.critical(self, "Error", str(e))

    def cancel_pressed(self):
        """Restores the original distribution and closes the dialog."""
        self.distribution = self.original  # Revert changes
        self.reject()

    def get_lower_bound(self) -> float:
        """Retrieves and validates the lower bound input."""
        try:
            return float(self.lower_bound_field.text())
        except ValueError:
            return self.distribution.lower_bound  # Default to original value if invalid

    def get_upper_bound(self) -> float:
        """Retrieves and validates the upper bound input."""
        try:
            return float(self.upper_bound_field.text())
        except ValueError:
            return self.distribution.upper_bound  # Default to original value if invalid
