import random
import numpy as np
import math
import os
from abc import ABC, abstractmethod
from scipy.interpolate import splrep, splev
from typing import List, Iterator, Union 
from scipy.stats import poisson
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageQt
from scipy.ndimage import convolve, gaussian_filter
import json
import sys
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
from PyQt5.QtCore import *
DIST_SEARCH_STEP = 4

class MiscUtility:

    @staticmethod
    def new_gbc():
        """Returns a new GridBagConstraints-like dictionary with default values for gridx and gridy set to zero."""
        return {'gridx': 0, 'gridy': 0}

    @staticmethod
    def gui_name(param):
        """Returns the GUI 'display name' for the input parameter (first letter capitalized with colon added)."""
        name = param.name()
        if not name:
            return ":"
        uppercase = name[0].toUpperCase() + name[1:]
        return f"{uppercase}:"

    @staticmethod
    def show_error(message):
        """Displays an error dialog with the specified message."""
        QMessageBox.showerror("Error", message)

    @staticmethod
    def sq(val):
        """Returns the square of the input value."""
        return val * val

    @staticmethod
    def to_deltas(points):
        """Converts a list of 2D points to a list of offsets."""
        deltas = [points[i + 1] - points[i] for i in range(len(points) - 1)]
        return deltas

    @staticmethod
    def from_deltas(deltas, start):
        """Reverses the output of `to_deltas`."""
        points = [start]
        for delta in deltas:
            points.append(points[-1] + delta)
        return points

class RngUtility:
    rng = random.Random()

    @staticmethod
    def next_point(x_min, x_max, y_min, y_max):
        x = RngUtility.next_double(x_min, x_max)
        y = RngUtility.next_double(y_min, y_max)
        return Vector(x, y)

    @staticmethod
    def next_int(min_val, max_val):
        if min_val > max_val:
            raise ValueError("Random bounds are inverted")
        elif min_val == max_val:
            raise ValueError("Random range must have nonzero size")
        return RngUtility.rng.randint(min_val, max_val)

    @staticmethod
    def next_double(min_val, max_val):
        if min_val > max_val:
            raise ValueError("Random bounds are inverted")
        return RngUtility.rng.uniform(min_val, max_val)

    @staticmethod
    def random_chain(start, end, n_steps, step_size):
        if n_steps <= 0:
            raise ValueError("Must have at least one step")
        if step_size <= 0.0:
            raise ValueError("Step size must be positive")
        points = [None] * (n_steps + 1)
        points[0] = start
        points[n_steps] = end
        RngUtility.random_chain_recursive(points, 0, n_steps, step_size)
        return points

    @staticmethod
    def random_chain_recursive(points, i_start, i_end, step_size):
        if i_end - i_start <= 1:
            return

        i_bridge = (i_start + i_end) // 2
        circle1 = Circle(points[i_start], step_size * (i_bridge - i_start))
        circle2 = Circle(points[i_end], step_size * (i_end - i_bridge))
        bridge = None
        if i_bridge > i_start + 1 and i_bridge < i_end - 1:
            bridge = Circle.disk_disk_intersect(circle1, circle2)
        elif i_bridge == i_start + 1 and i_bridge == i_end - 1:
            intersects = Circle.circle_circle_intersect(circle1, circle2)
            bridge = RngUtility.rng.choice(intersects)
        elif i_bridge == i_start + 1:
            bridge = Circle.disk_circle_intersect(circle2, circle1)
        else:
            bridge = Circle.disk_circle_intersect(circle1, circle2)
        points[i_bridge] = bridge

        RngUtility.random_chain_recursive(points, i_start, i_bridge, step_size)
        RngUtility.random_chain_recursive(points, i_bridge, i_end, step_size)

class Vector:
    def __init__(self, x=0.0, y=0.0):
        self.x = x
        self.y = y

    def normalize(self):
        norm = np.linalg.norm([self.x, self.y])
        if norm == 0:
            raise ValueError("Cannot normalize a zero vector")
        return Vector(self.x / norm, self.y / norm)

    def scalar_multiply(self, scalar):
        return Vector(self.x * scalar, self.y * scalar)

    def add(self, other):
        return Vector(self.x + other.x, self.y + other.y)

    def subtract(self, other):
        return Vector(self.x - other.x, self.y - other.y)

    def theta(self):
        return np.arctan2(self.y, self.x)

    def angle_with(self, other):
        if self.is_zero() or other.is_zero():
            raise ValueError("Cannot compute angle with zero vector")
        cos_theta = self.normalize().dot_product(other.normalize())
        cos_theta = np.clip(cos_theta, -1, 1)
        return np.arccos(cos_theta)

    def un_rotate(self, old_x_axis):
        if old_x_axis.is_zero():
            raise ValueError("New x-axis must be nonzero")
        old_x_axis = old_x_axis.normalize()
        new_y_axis = Vector(-old_x_axis.y, old_x_axis.x)
        x_rotated = old_x_axis.scalar_multiply(self.x)
        y_rotated = new_y_axis.scalar_multiply(self.y)
        return x_rotated.add(y_rotated)

    def dot_product(self, other):
        return self.x * other.x + self.y * other.y

    def is_zero(self):
        return self.x == 0 and self.y == 0

    def to_array(self):
        return np.array([self.x, self.y])

    def __repr__(self):
        return f"Vector({self.x}, {self.y})"
    
class Param:
    def __init__(self, name="", hint="", value=None):
        self.value = value
        self.name = name
        self.hint = hint
        
    def get_value(self):
        return self.value

    def get_string(self):
        return "" if self.value is None else str(self.value)

    def set_name(self, name):
        self.name = name

    def get_name(self):
        return "" if self.name is None else self.name

    def set_hint(self, hint):
        self.hint = hint

    def get_hint(self):
        return "" if self.hint is None else self.hint

    def parse(self, string, parser):
        if not string.strip():
            raise ValueError(f"Value of \"{self.get_name()}\" must be non-empty")
        try:
            self.value = parser(string)
        except Exception as e:
            raise ValueError(f"Unable to parse value \"{string}\" for parameter \"{self.get_name()}\"")

    def verify(self, bound, verifier):
        try:
            verifier(self.value, bound)
        except ValueError as e:
            raise ValueError(f"Value of \"{self.get_name()}\" {str(e)} {bound}")

    @staticmethod
    def less(value, max_value):
        if value >= max_value:
            raise ValueError("must be less than")

    @staticmethod
    def greater(value, min_value):
        if value <= min_value:
            raise ValueError("must be greater than")

    @staticmethod
    def less_eq(value, max_value):
        if value > max_value:
            raise ValueError("must be less than or equal to")

    @staticmethod
    def greater_eq(value, min_value):
        if value < min_value:
            raise ValueError("must be greater than or equal to")
        
    @staticmethod
    def from_dict(param_dict):
        return Param(
            value=param_dict["value"],
            name=param_dict.get("name", ""),
            hint=param_dict.get("hint", "")
        )

    def to_dict(self):
        return {
            "value": self.value,
            "name": self.name,
            "hint": self.hint
        }

class Optional(Param):
    def __init__(self, name="", hint="", value=None, use=False):
        super().__init__(name, hint, value)
        self.use = use

    def parse(self, use, string, parser):
        self.use = use
        if self.use:
            super().parse(string, parser)

    def verify(self, bound, verifier):
        if self.use:
            super().verify(bound, verifier)
            
    @staticmethod
    def from_dict(optional_dict):
        return Optional(
            value=optional_dict["value"],
            name=optional_dict.get("name", ""),
            hint=optional_dict.get("hint", ""),
            use=optional_dict["use"]
        )

    def to_dict(self):
        return {
            "value": self.value,
            "name": self.name,
            "hint": self.hint,
            "use": self.use
        }

class Distribution(ABC):
    def __init__(self, lower_bound, upper_bound):
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    @abstractmethod
    def clone(self):
        pass

    def set_bounds(self, lower_bound, upper_bound):
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    @abstractmethod
    def get_type(self):
        pass

    @abstractmethod
    def get_string(self):
        pass

    @abstractmethod
    def sample(self):
        pass

    @abstractmethod
    def set_names(self):
        pass

    @abstractmethod
    def set_hints(self):
        pass

    @abstractmethod
    def verify(self):
        pass

class DistributionDialog(QDialog):
    def __init__(self, distribution):
        super().__init__()
        self.original = distribution.clone()
        self.distribution = distribution
        self.init_ui()
        self.display_distribution()
        self.setWindowTitle("Distribution Dialog")
        self.setModal(True)
        self.show()

    def init_ui(self):
        layout = QVBoxLayout()

        self.comboBox = QComboBox()
        self.comboBox.addItems([Gaussian.typename, Uniform.typename, PiecewiseLinear.typename])
        layout.addWidget(self.comboBox)

        self.lower_bound_label = QLabel("Lower bound:")
        self.lower_bound_field = QLineEdit(str(self.distribution.lower_bound))
        self.lower_bound_field.setReadOnly(True)
        layout.addWidget(self.lower_bound_label)
        layout.addWidget(self.lower_bound_field)

        self.upper_bound_label = QLabel("Upper bound:")
        self.upper_bound_field = QLineEdit(str(self.distribution.upper_bound))
        self.upper_bound_field.setReadOnly(True)
        layout.addWidget(self.upper_bound_label)
        layout.addWidget(self.upper_bound_field)

        self.label1 = QLabel()
        self.field1 = QLineEdit()
        layout.addWidget(self.label1)
        layout.addWidget(self.field1)

        self.label2 = QLabel()
        self.field2 = QLineEdit()
        layout.addWidget(self.label2)
        layout.addWidget(self.field2)

        button_layout = QHBoxLayout()
        self.okay_button = QPushButton("Okay")
        self.cancel_button = QPushButton("Cancel")
        button_layout.addWidget(self.okay_button)
        button_layout.addWidget(self.cancel_button)
        layout.addLayout(button_layout)

        self.setLayout(layout)

        self.comboBox.currentIndexChanged.connect(self.selection_changed)
        self.okay_button.clicked.connect(self.okay_pressed)
        self.cancel_button.clicked.connect(self.cancel_pressed)

    def display_distribution(self):
        self.comboBox.setCurrentText(self.distribution.get_type())
        if isinstance(self.distribution, Gaussian):
            gaussian = self.distribution
            self.label1.setText("Mean:")
            self.label1.setToolTip(gaussian.mean.get_hint())
            self.field1.setText(gaussian.mean.get_string())
            self.label2.setText("Sigma:")
            self.label2.setToolTip(gaussian.sigma.get_hint())
            self.field2.setText(gaussian.sigma.get_string())
        elif isinstance(self.distribution, Uniform):
            uniform = self.distribution
            self.label1.setText("Min:")
            self.label1.setToolTip(uniform.min.get_hint())
            self.field1.setText(uniform.min.get_string())
            self.label2.setText("Max:")
            self.label2.setToolTip(uniform.max.get_hint())
            self.field2.setText(uniform.max.get_string())
        elif isinstance(self.distribution, PiecewiseLinear):
            piecewise_linear = self.distribution
            self.label1.setText("X values:")
            self.label1.setToolTip("X values of points in the piecewise linear distribution")
            self.field1.setText(piecewise_linear.get_x_string())
            self.label2.setText("Y values:")
            self.label2.setToolTip("Y values of points in the piecewise linear distribution")
            self.field2.setText(piecewise_linear.get_y_string())

    def selection_changed(self):
        selection = self.comboBox.currentText()
        if selection != self.distribution.get_type():
            if selection == Gaussian.typename:
                self.distribution = Gaussian(self.distribution.lower_bound, self.distribution.upper_bound)
            elif selection == Uniform.typename:
                self.distribution = Uniform(self.distribution.lower_bound, self.distribution.upper_bound)
            elif selection == PiecewiseLinear.typename:
                self.distribution = PiecewiseLinear(self.distribution.lower_bound, self.distribution.upper_bound)
            self.display_distribution()

    def okay_pressed(self):
        selection = self.comboBox.currentText()
        try:
            if selection == Gaussian.typename:
                gaussian = self.distribution
                gaussian.mean.parse(self.field1.text(), float)
                gaussian.sigma.parse(self.field2.text(), float)
            elif selection == Uniform.typename:
                uniform = self.distribution
                uniform.min.parse(self.field1.text(), float)
                uniform.max.parse(self.field2.text(), float)
            elif selection == PiecewiseLinear.typename:
                piecewise_linear = self.distribution
                piecewise_linear.parse_xy_values(self.field1.text(), self.field2.text())
            self.distribution.verify()
            self.accept()
        except ValueError as e:
            QMessageBox.critical(self, "Error", str(e))

    def cancel_pressed(self):
        self.distribution = self.original
        self.reject()

class Gaussian(Distribution):
    typename = "Gaussian"

    def __init__(self, lower_bound, upper_bound):
        super().__init__(lower_bound, upper_bound)
        self.mean = Param()
        self.sigma = Param()
        self.set_names()
        self.set_hints()

    def clone(self):
        clone = Gaussian(self.lower_bound, self.upper_bound)
        clone.mean.parse(self.mean.get_string(), float)
        clone.sigma.parse(self.sigma.get_string(), float)
        return clone

    def get_type(self):
        return self.typename

    def get_string(self):
        return f"{self.get_type()}: μ={self.mean.get_string()}, σ={self.sigma.get_string()}"

    def sample(self):
        val = None
        while val is None or val < self.lower_bound or val > self.upper_bound:
            val = np.random.normal(self.mean.get_value(), self.sigma.get_value())
        return val

    def set_names(self):
        self.mean.set_name("mean")
        self.sigma.set_name("sigma")

    def set_hints(self):
        self.mean.set_hint("Mean of the Gaussian")
        self.sigma.set_hint("Standard deviation of the Gaussian")

    def verify(self):
        if self.sigma.get_value() <= 0:
            raise ValueError(f"Standard deviation {self.sigma} is not positive")

    @staticmethod
    def from_dict(gaussian_dict):
        lower_bound = gaussian_dict.get("lower_bound", 0.0)
        upper_bound = gaussian_dict.get("upper_bound", float('inf'))
        gaussian = Gaussian(lower_bound, upper_bound)
        gaussian.mean = Param.from_dict(gaussian_dict["mean"])
        gaussian.sigma = Param.from_dict(gaussian_dict["sigma"])
        return gaussian

    def to_dict(self):
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "mean": self.mean.to_dict(),
            "sigma": self.sigma.to_dict()
        }

class Uniform(Distribution):
    typename = "Uniform"

    def __init__(self, lower_bound, upper_bound):
        super().__init__(lower_bound, upper_bound)
        self.min = Param()
        self.max = Param()
        self.set_names()
        self.set_hints()

    def clone(self):
        clone = Uniform(self.lower_bound, self.upper_bound)
        clone.min.parse(self.min.get_string(), float)
        clone.max.parse(self.max.get_string(), float)
        return clone

    def get_type(self):
        return self.typename

    def get_string(self):
        return f"{self.get_type()}: {self.min.get_string()}-{self.max.get_string()}"

    def sample(self):
        trim_min = max(self.lower_bound, self.min.get_value())
        trim_max = min(self.upper_bound, self.max.get_value())
        return np.random.uniform(trim_min, trim_max)

    def set_names(self):
        self.min.set_name("minimum")
        self.max.set_name("maximum")

    def set_hints(self):
        self.min.set_hint("Minimum of the uniform distribution (inclusive)")
        self.max.set_hint("Maximum of the uniform distribution (inclusive)")

    def verify(self):
        if self.min.get_value() > self.max.get_value():
            raise ValueError(f"Uniform distribution minimum {self.min.get_value()} exceeds maximum {self.max.get_value()}")
        if self.min.get_value() > self.upper_bound:
            raise ValueError(f"Uniform distribution minimum {self.min.get_value()} exceeds upper bound {self.upper_bound}")
        if self.max.get_value() < self.lower_bound:
            raise ValueError(f"Uniform distribution maximum {self.max.get_value()} is less than lower bound {self.lower_bound}")

    @staticmethod
    def from_dict(uniform_dict):
        lower_bound = uniform_dict.get("lower_bound", 0.0)
        upper_bound = uniform_dict.get("upper_bound", float('inf'))
        uniform = Uniform(lower_bound, upper_bound)
        uniform.min = Param.from_dict(uniform_dict["min"])
        uniform.max = Param.from_dict(uniform_dict["max"])
        return uniform

    def to_dict(self):
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "min": self.min.to_dict(),
            "max": self.max.to_dict()
        }

class PiecewiseLinear(Distribution):
    typename = "Piecewise Linear"

    def __init__(self, lower_bound, upper_bound):
        super().__init__(lower_bound, upper_bound)
        self.distribution = []
        self.set_names()
        self.set_hints()

    def clone(self):
        clone = PiecewiseLinear(self.lower_bound, self.upper_bound)
        clone.distribution = list(self.distribution)
        return clone

    def get_type(self):
        return self.typename

    def get_string(self):
        return "Piecewise linear"

    def sample(self):
        integral = 0.0
        for i in range(len(self.distribution) - 1):
            p1 = self.distribution[i]
            p2 = self.distribution[i + 1]
            integral += 0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0])
        normalized = [[p[0], p[1] / integral] for p in self.distribution]

        i = 0
        cdf = 0.0
        rand = np.random.uniform()
        cdf_prev = 0.0
        while i < len(normalized) - 1 and cdf < rand:
            cdf_prev = cdf
            p1 = normalized[i]
            p2 = normalized[i + 1]
            cdf += 0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0])
            i += 1

        cdf_remain = rand - cdf_prev

        if i == 0:
            return normalized[0][0]
        if i == len(normalized):
            return normalized[-1][0]

        p1 = normalized[i - 1]
        p2 = normalized[i]
        x1, y1 = p1
        x2, y2 = p2

        m = (y2 - y1) / (x2 - x1)
        a = 0.5 * m
        b = y1 - m * x1
        c = 0.5 * m * x1 ** 2 - y1 * x1 - cdf_remain

        b4ac = b ** 2 - 4 * a * c
        if b4ac < 0:
            raise ArithmeticError("Sampling failure (no real quadratic roots)")
        else:
            root0 = (-b + np.sqrt(b4ac)) / (2 * a)
            root1 = (-b - np.sqrt(b4ac)) / (2 * a)
            if x1 <= root0 <= x2:
                return root0
            else:
                return root1

    def set_names(self):
        pass

    def set_hints(self):
        pass

    def verify(self):
        last_x = float('-inf')
        for point in self.distribution:
            if point[0] < last_x:
                raise ValueError(f"Piecewise linear x-coordinates out of order ({last_x}, {point[0]})")
            last_x = point[0]
            if point[1] < 0:
                raise ValueError(f"Negative piecewise linear probability {point[1]}")
        if self.distribution[0][0] < self.lower_bound:
            raise ValueError(f"Piecewise linear distribution extends below lower bound of {self.lower_bound}")
        if self.distribution[-1][0] > self.upper_bound:
            raise ValueError(f"Piecewise linear distribution extends above upper bound of {self.upper_bound}")

    def get_x_string(self):
        return ",".join(str(point[0]) for point in self.distribution)

    def get_y_string(self):
        return ",".join(str(point[1]) for point in self.distribution)

    def parse_xy_values(self, x_string, y_string):
        x_tokens = x_string.split(",")
        y_tokens = y_string.split(",")
        if len(x_tokens) != len(y_tokens):
            raise ValueError("Number of x points and y points must be equal")
        if len(x_tokens) == 0:
            raise ValueError("Must have a nonzero number of points in distribution")
        self.distribution = []
        for x, y in zip(x_tokens, y_tokens):
            try:
                x_val = float(x)
            except ValueError:
                raise ValueError(f"Invalid x-coordinate \"{x}\"")
            try:
                y_val = float(y)
            except ValueError:
                raise ValueError(f"Invalid y-coordinate \"{y}\"")
            self.distribution.append([x_val, y_val])
            
class Circle:
    BUFF = 1e-10

    def __init__(self, center, radius):
        self.center = np.array([center.x, center.y])
        self.radius = radius

    def center(self):
        return self.center

    def radius(self):
        return self.radius

    def contains(self, point):
        return np.linalg.norm(self.center - np.array([point.x, point.y])) <= self.radius + self.BUFF

    def __eq__(self, other):
        if not isinstance(other, Circle):
            return False
        return np.array_equal(self.center, other.center) and (self.radius == other.radius)

    def choose_point(self, min_theta, max_theta):
        theta = RngUtility.next_double(min_theta, max_theta)
        dir = np.array([math.cos(theta), math.sin(theta)])
        return Vector(self.center[0] + dir[0] * self.radius, self.center[1] + dir[1] * self.radius)

    @staticmethod
    def circle_circle_intersect(circle1, circle2):
        d = np.linalg.norm(circle1.center - circle2.center)
        space = d - circle1.radius - circle2.radius
        if space > 0:
            circle1 = Circle(Vector(circle1.center[0], circle1.center[1]), circle1.radius + Circle.BUFF)
            circle2 = Circle(Vector(circle2.center[0], circle2.center[1]), circle2.radius + Circle.BUFF)
            space -= 2 * Circle.BUFF

        nested = d < abs(circle1.radius - circle2.radius)
        if circle1 == circle2 or nested or space > 0:
            raise ArithmeticError("Circles do not intersect")

        a = (circle1.radius ** 2 - circle2.radius ** 2 + d ** 2) / (2 * d)
        h = math.sqrt(circle1.radius ** 2 - a ** 2)

        axis = (circle2.center - circle1.center) / np.linalg.norm(circle2.center - circle1.center)
        points = [
            Vector(circle1.center[0] + a * axis[0] - h * axis[1], circle1.center[1] + a * axis[1] + h * axis[0]),
            Vector(circle1.center[0] + a * axis[0] + h * axis[1], circle1.center[1] + a * axis[1] - h * axis[0])
        ]
        return points

    @staticmethod
    def disk_circle_intersect(disk, circle):
        d = np.linalg.norm(disk.center - circle.center)
        if d < disk.radius - circle.radius:
            return circle.choose_point(-math.pi, math.pi)

        axis = (disk.center - circle.center) / np.linalg.norm(disk.center - circle.center)
        points = Circle.circle_circle_intersect(disk, circle)
        delta = np.arccos(np.clip(np.dot(axis, (points[0].subtract(circle.center).to_array())), -1.0, 1.0))

        return circle.choose_point(axis[0] - delta, axis[0] + delta)

    @staticmethod
    def disk_disk_intersect(disk1, disk2):
        d = np.linalg.norm(disk1.center - disk2.center)
        if d < abs(disk1.radius - disk2.radius):
            inner = disk1 if disk1.radius < disk2.radius else disk2
            x_min = inner.center[0] - inner.radius
            x_max = inner.center[0] + inner.radius
            y_min = inner.center[1] - inner.radius
            y_max = inner.center[1] + inner.radius

            while True:
                result = Vector(RngUtility.next_double(x_min, x_max), RngUtility.next_double(y_min, y_max))
                if inner.contains(result):
                    return result

        points = Circle.circle_circle_intersect(disk1, disk2)
        box_height = np.linalg.norm(points[0].subtract(points[1]).to_array())
        box_left = min(d - disk2.radius, disk1.radius)
        box_right = max(d - disk2.radius, disk1.radius)

        axis = (disk2.center - disk1.center) / np.linalg.norm(disk2.center - disk1.center)
        while True:
            delta = Vector(RngUtility.next_double(box_left, box_right), RngUtility.next_double(-box_height, box_height))
            result = Vector(*(disk1.center + delta.un_rotate(axis)))
            if disk1.contains(result) and disk2.contains(result):
                return result

class Fiber:
    class Params:
        def __init__(self, segment_length, width_change, n_segments, start_width, straightness, start, end):
            self.segment_length = segment_length
            self.width_change = width_change
            self.n_segments = n_segments
            self.start_width = start_width
            self.straightness = straightness
            self.start = start
            self.end = end
        
        @staticmethod
        def from_dict(params_dict):
            return Fiber.Params(
                segment_length=params_dict.get("segment_length", 0),
                width_change=params_dict.get("width_change", 0),
                n_segments=params_dict.get("n_segments", 0),
                start_width=params_dict.get("start_width", 0),
                straightness=params_dict.get("straightness", 0),
                start=Vector(params_dict["start"]["x"], params_dict["start"]["y"]),
                end=Vector(params_dict["end"]["x"], params_dict["end"]["y"])
            )

        def to_dict(self):
            return {
                "segment_length": self.segment_length,
                "width_change": self.width_change,
                "n_segments": self.n_segments,
                "start_width": self.start_width,
                "straightness": self.straightness,
                "start": {"x": self.start.x, "y": self.start.y},
                "end": {"x": self.end.x, "y": self.end.y}
            }

    class Segment:
        def __init__(self, start, end, width):
            self.start = start
            self.end = end
            self.width = width

    class SegmentIterator:
        def __init__(self, points, widths):
            self.curr = 0
            self.points = points
            self.widths = widths

        def __iter__(self):
            return self

        def __next__(self):
            if self.curr < len(self.points) - 1:
                segment = Fiber.Segment(self.points[self.curr], self.points[self.curr + 1], self.widths[self.curr])
                self.curr += 1
                return segment
            else:
                raise StopIteration

    def __init__(self, params):
        self.params = params
        self.points = []
        self.widths = []

    def __iter__(self) -> Iterator[Segment]:
        return self.SegmentIterator(self.points, self.widths)

    def get_points(self) -> List:
        return list(self.points)

    def get_direction(self):
        return (self.params.end.subtract(self.params.start)).normalize()

    def generate(self):
        self.points = RngUtility.random_chain(self.params.start, self.params.end, self.params.n_segments, self.params.segment_length)
        width = self.params.start_width
        for i in range(self.params.n_segments):
            self.widths.append(width)
            variability = min(abs(width), self.params.width_change)
            width += RngUtility.next_double(-variability, variability)

    def bubble_smooth(self, passes):
        deltas = MiscUtility.to_deltas(self.points)
        for _ in range(passes):
            for j in range(len(deltas) - 1):
                self.try_swap(deltas, j, j + 1)
        self.points = MiscUtility.from_deltas(deltas, self.points[0])

    def swap_smooth(self, ratio):
        deltas = MiscUtility.to_deltas(self.points)
        for _ in range(ratio * len(deltas)):
            u = RngUtility.rng.randint(0, len(deltas) - 1)
            v = RngUtility.rng.randint(0, len(deltas) - 1)
            self.try_swap(deltas, u, v)
        self.points = MiscUtility.from_deltas(deltas, self.points[0])

    def spline_smooth(self, spline_ratio):
        if self.params.n_segments <= 1:
            return

        t_points = np.arange(len(self.points))
        x_points = np.array([p.x for p in self.points])
        y_points = np.array([p.y for p in self.points])
        tck_x = splrep(t_points, x_points)
        tck_y = splrep(t_points, y_points)

        new_points = []
        new_widths = []
        for i in range((len(self.points) - 1) * spline_ratio + 1):
            if i % spline_ratio == 0:
                new_points.append(self.points[i // spline_ratio])
            else:
                t = i / spline_ratio
                new_points.append(Vector(splev(t, tck_x), splev(t, tck_y)))
            if i < (len(self.points) - 1) * spline_ratio:
                new_widths.append(self.widths[i // spline_ratio])
        self.points = new_points
        self.widths = new_widths

    @staticmethod
    def try_swap(deltas, u, v):
        old_diff = Fiber.local_diff_sum(deltas, u, v)
        deltas[u], deltas[v] = deltas[v], deltas[u]
        new_diff = Fiber.local_diff_sum(deltas, u, v)
        if new_diff > old_diff:
            deltas[u], deltas[v] = deltas[v], deltas[u]

    @staticmethod
    def local_diff_sum(deltas, u, v):
        i1 = min(u, v)
        i2 = max(u, v)
        if i1 < 0 or i2 >= len(deltas):
            raise IndexError("u and v must be within the array")

        sum_diff = 0.0
        if i1 > 0:
            sum_diff += deltas[i1 - 1].angle_with(deltas[i1])
        if i1 < i2:
            sum_diff += deltas[i1].angle_with(deltas[i1 + 1])
        if i1 < i2 - 1:
            sum_diff += deltas[i2 - 1].angle_with(deltas[i2])
        if i2 < len(deltas) - 1:
            sum_diff += deltas[i2].angle_with(deltas[i2 + 1])
        return sum_diff

class FiberImage:
    class Params:
        def __init__(self):
            self.nFibers = Param(int)
            self.segmentLength = Param(float)
            self.alignment = Param(float)
            self.meanAngle = Param(float)
            self.widthChange = Param(float)
            self.imageWidth = Param(int)
            self.imageHeight = Param(int)
            self.imageBuffer = Param(int)

            self.length = Uniform(0.0, float('inf'))
            self.width = Uniform(0.0, float('inf'))
            self.straightness = Uniform(0.0, 1.0)

            self.scale = Optional(float)
            self.downSample = Optional(float)
            self.blur = Optional(float)
            self.noise = Optional(float)
            self.distance = Optional(float)
            self.cap = Optional(int)
            self.normalize = Optional(int)
            self.bubble = Optional(int)
            self.swap = Optional(int)
            self.spline = Optional(int)

#Adjust logic to handle error              
        @staticmethod
        def from_dict(params_dict):
            params = FiberImage.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            params.alignment = Param.from_dict(params_dict["alignment"])
            params.meanAngle = Param.from_dict(params_dict["meanAngle"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            params.length = Uniform.from_dict(params_dict["length"])
            params.width = Gaussian.from_dict(params_dict["width"])
            params.straightness = Uniform.from_dict(params_dict["straightness"])
            params.scale = Optional.from_dict(params_dict["scale"])
            params.downSample = Optional.from_dict(params_dict["downSample"])
            params.blur = Optional.from_dict(params_dict["blur"])
            params.noise = Optional.from_dict(params_dict["noise"])
            params.distance = Optional.from_dict(params_dict["distance"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            return params

        def to_dict(self):
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "alignment": self.alignment.to_dict(),
                "meanAngle": self.meanAngle.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "scale": self.scale.to_dict(),
                "downSample": self.downSample.to_dict(),
                "blur": self.blur.to_dict(),
                "noise": self.noise.to_dict(),
                "distance": self.distance.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict()
            }

        def set_names(self):
            self.nFibers.set_name("number of fibers")
            self.segmentLength.set_name("segment length")
            self.alignment.set_name("alignment")
            self.meanAngle.set_name("mean angle")
            self.widthChange.set_name("width change")
            self.imageWidth.set_name("image width")
            self.imageHeight.set_name("image height")
            self.imageBuffer.set_name("edge buffer")

            self.length.set_names()
            self.straightness.set_names()
            self.width.set_names()

            self.scale.set_name("scale")
            self.downSample.set_name("down sample")
            self.blur.set_name("blur")
            self.noise.set_name("noise")
            self.distance.set_name("distance")
            self.cap.set_name("cap")
            self.normalize.set_name("normalize")
            self.bubble.set_name("bubble")
            self.swap.set_name("swap")
            self.spline.set_name("spline")

        def set_hints(self):
            self.nFibers.set_hint("The number of fibers per image to generate")
            self.segmentLength.set_hint("The length in pixels of fiber segments")
            self.alignment.set_hint("A value between 0 and 1 indicating how close fibers are to the mean angle on average")
            self.meanAngle.set_hint("The average fiber angle in degrees")
            self.widthChange.set_hint("The maximum segment-to-segment width change of a fiber in pixels")
            self.imageWidth.set_hint("The width of the saved image in pixels")
            self.imageHeight.set_hint("The height of the saved image in pixels")
            self.imageBuffer.set_hint("The size in pixels of the empty border around the edge of the image")

            self.length.set_hints()
            self.straightness.set_hints()
            self.width.set_hints()

            self.scale.set_hint("Check to draw a scale bar on the image; value is the number of pixels per micron")
            self.downSample.set_hint("Check to enable down sampling; value is the ratio of final size to original size")
            self.blur.set_hint("Check to enable Gaussian blurring; value is the radius of the blur in pixels")
            self.noise.set_hint("Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)")
            self.distance.set_hint("Check to apply a distance filter; value controls the sharpness of the intensity falloff")
            self.cap.set_hint("Check to cap the intensity; value is the inclusive maximum on a scale of 0-255")
            self.normalize.set_hint("Check to normalize the intensity; value is the inclusive maximum on a scale of 0-255")
            self.bubble.set_hint("Check to apply \"bubble smoothing\"; value is the number of passes")
            self.swap.set_hint("Check to apply \"swap smoothing\"; number of swaps is this value times number of segments")
            self.spline.set_hint("Check to enable spline smoothing; value is the number of interpolated points per segment")

        def verify(self):
            self.nFibers.verify(0, Param.greater)
            self.segmentLength.verify(0.0, Param.greater)
            self.widthChange.verify(0.0, Param.greater_eq)
            self.alignment.verify(0.0, Param.greater_eq)
            self.alignment.verify(1.0, Param.less_eq)
            self.meanAngle.verify(0.0, Param.greater_eq)
            self.meanAngle.verify(180.0, Param.less_eq)

            self.imageWidth.verify(0, Param.greater)
            self.imageHeight.verify(0, Param.greater)
            self.imageBuffer.verify(0, Param.greater)

            self.length.verify()
            self.straightness.verify()
            self.width.verify()

            self.scale.verify(0.0, Param.greater)
            self.downSample.verify(0.0, Param.greater)
            self.blur.verify(0.0, Param.greater)
            self.noise.verify(0.0, Param.greater)
            self.distance.verify(0.0, Param.greater)
            self.cap.verify(0, Param.greater_eq)
            self.cap.verify(255, Param.less_eq)
            self.normalize.verify(0, Param.greater_eq)
            self.normalize.verify(255, Param.less_eq)
            self.bubble.verify(0, Param.greater)
            self.swap.verify(0, Param.greater)
            self.spline.verify(0, Param.greater)

    TARGET_SCALE_SIZE = 0.2
    CAP_RATIO = 0.01
    BUFF_RATIO = 0.015

    def __init__(self, params):
        self.params = params
        self.fibers = []
        self.image = Image.new('L', (params.imageWidth.value(), params.imageHeight.value()), 0)

    def __iter__(self):
        return iter(self.fibers)

    def generate_fibers(self):
        directions = self.generate_directions()

        for direction in directions:
            fiber_params = Fiber.Params()

            fiber_params.segment_length = self.params.segmentLength.value()
            fiber_params.width_change = self.params.widthChange.value()

            fiber_params.n_segments = max(1, round(self.params.length.sample() / self.params.segmentLength.value()))
            fiber_params.straightness = self.params.straightness.sample()
            fiber_params.start_width = self.params.width.sample()

            end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
            fiber_params.start = self.find_fiber_start(end_distance, direction)
            fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

            fiber = Fiber(fiber_params)
            fiber.generate()
            self.fibers.append(fiber)

    def smooth(self):
        for fiber in self.fibers:
            if self.params.bubble.use:
                fiber.bubble_smooth(self.params.bubble.value())
            if self.params.swap.use:
                fiber.swap_smooth(self.params.swap.value())
            if self.params.spline.use:
                fiber.spline_smooth(self.params.spline.value())

    def draw_fibers(self):
        draw = ImageDraw.Draw(self.image)
        for fiber in self.fibers:
            for segment in fiber:
                draw.line(
                    [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                    fill=255,
                    width=int(segment.width)
                )

    def apply_effects(self):
        if self.params.distance.use:
            self.image = ImageUtility.distance_function(self.image, self.params.distance.value())
        if self.params.noise.use:
            self.add_noise()
        if self.params.blur.use:
            self.image = ImageUtility.gaussian_blur(self.image, self.params.blur.value())
        if self.params.scale.use:
            self.draw_scale_bar()
        if self.params.downSample.use:
            self.image = self.image.resize(
                (int(self.image.width * self.params.downSample.value()), int(self.image.height * self.params.downSample.value())),
                Image.BILINEAR
            )
        if self.params.cap.use:
            self.image = ImageUtility.cap(self.image, self.params.cap.value())
        if self.params.normalize.use:
            self.image = ImageUtility.normalize(self.image, self.params.normalize.value())

    def get_image(self):
        return self.image.copy()

    def generate_directions(self):
        sum_angle = -np.radians(self.params.meanAngle.value())
        sum_direction = Vector(np.cos(sum_angle * 2.0), np.sin(sum_angle * 2.0))
        sum_vector = sum_direction.scalar_multiply(self.params.alignment.value() * self.params.nFibers.value())

        chain = RngUtility.random_chain(Vector(), sum_vector, self.params.nFibers.value(), 1.0)
        directions = MiscUtility.to_deltas(chain)

        output = []
        for direction in directions:
            angle = direction.theta() / 2.0
            output.append(Vector(np.cos(angle), np.sin(angle)))
        return output

    def find_fiber_start(self, length, direction):
        x_length = direction.normalize().x * length
        y_length = direction.normalize().y * length
        x = self.find_start(x_length, self.params.imageWidth.value(), self.params.imageBuffer.value())
        y = self.find_start(y_length, self.params.imageHeight.value(), self.params.imageBuffer.value())
        return Vector(x, y)

    @staticmethod
    def find_start(length, dimension, buffer):
        buffer = max(length / 2, buffer)
        if abs(length) > dimension:
            min_val = min(dimension - length, dimension)
            max_val = max(0, -length)
            return RngUtility.next_double(min_val, max_val)
        if abs(length) > dimension - 2 * buffer:
            buffer = 0
        min_val = max(buffer, buffer - length)
        max_val = min(dimension - buffer - length, dimension - buffer)
        return RngUtility.next_double(min_val, max_val)

    def draw_scale_bar(self):
        target_size = self.TARGET_SCALE_SIZE * self.image.width / self.params.scale.value()
        floor_pow = np.floor(np.log10(target_size))
        options = [10**floor_pow, 5 * 10**floor_pow, 10**(floor_pow + 1)]
        best_size = min(options, key=lambda x: abs(target_size - x))

        if abs(np.floor(np.log10(best_size))) <= 2:
            label = f"{best_size:.2f} µ"
        else:
            label = f"{best_size:.1e} µ"

        cap_size = int(self.CAP_RATIO * self.image.height)
        x_buff = int(self.BUFF_RATIO * self.image.width)
        y_buff = int(self.BUFF_RATIO * self.image.height)
        scale_height = self.image.height - y_buff - cap_size
        scale_right = x_buff + int(best_size * self.params.scale.value())

        draw = ImageDraw.Draw(self.image)
        draw.line((x_buff, scale_height, scale_right, scale_height), fill=255)
        draw.line((x_buff, scale_height + cap_size, x_buff, scale_height - cap_size), fill=255)
        draw.line((scale_right, scale_height + cap_size, scale_right, scale_height - cap_size), fill=255)
        draw.text((x_buff, scale_height - cap_size - y_buff), label, fill=255)

    def add_noise(self):
        mean = self.params.noise.value()
        noise = poisson(mean).rvs(self.image.size).reshape(self.image.size[::-1])
        np_image = np.array(self.image)
        np_image = np.clip(np_image + noise, 0, 255).astype(np.uint8)
        self.image = Image.fromarray(np_image, 'L')

class ImageCollection:
    class Params(FiberImage.Params):
        def __init__(self):
            super().__init__()
            self.nImages = Param()
            self.seed = Optional()

        def set_names(self):
            super().set_names()
            self.nImages.set_name("number of images")
            self.seed.set_name("seed")

        def set_hints(self):
            super().set_hints()
            self.nImages.set_hint("The number of images to generate")
            self.seed.set_hint("Check to fix the random seed; value is the seed")

        def verify(self):
            super().verify()
            self.nImages.verify(0, Param.greater)

    def __init__(self, params):
        params.verify()
        self.params = params
        self.image_stack: List[FiberImage] = []

    def generate_images(self):
        if self.params.seed.use:
            random.seed(self.params.seed.value())
        
        self.image_stack.clear()
        for _ in range(self.params.nImages.value()):
            image = FiberImage(self.params)
            image.generate_fibers()
            image.smooth()
            image.draw_fibers()
            image.apply_effects()
            self.image_stack.append(image)

    def is_empty(self):
        return not self.image_stack

    def get(self, i):
        return self.image_stack[i]

    def get_image(self, i):
        return self.get(i).get_image()

    def size(self):
        return len(self.image_stack)

class ImageUtility:

    @staticmethod
    def distance_function(image, falloff):
        if image.mode != 'L':
            raise ValueError("Image must be in 'L' mode (8-bit pixels, black and white)")

        input_array = np.array(image)
        output_array = np.zeros_like(input_array)

        for y in range(output_array.shape[0]):
            for x in range(output_array.shape[1]):
                if input_array[y, x] == 0:
                    output_array[y, x] = 0
                else:
                    min_dist = ImageUtility.background_dist(input_array, x, y)
                    output_array[y, x] = min(255, int(min_dist * falloff) if min_dist > 0 else 255)

        return Image.fromarray(output_array)

    @staticmethod
    def gaussian_blur(image, radius):
        input_array = np.array(image)
        output_array = gaussian_filter(input_array, sigma=radius / 3.0)
        return Image.fromarray(output_array)

    @staticmethod
    def scale(image, ratio, interpolation=Image.BILINEAR):
        new_size = (int(image.width * ratio), int(image.height * ratio))
        return image.resize(new_size, resample=interpolation)

    @staticmethod
    def cap(image, max_value):
        if image.mode != 'L':
            raise ValueError("Image must be in 'L' mode (8-bit pixels, black and white)")

        input_array = np.array(image)
        output_array = np.clip(input_array, 0, max_value)
        return Image.fromarray(output_array)

    @staticmethod
    def normalize(image, max_value):
        if image.mode != 'L':
            raise ValueError("Image must be in 'L' mode (8-bit pixels, black and white)")

        input_array = np.array(image)
        current_max = input_array.max()
        output_array = (input_array * max_value / current_max).astype(np.uint8)
        return Image.fromarray(output_array)

    @staticmethod
    def background_dist(image_array, x, y):
        r_max = int(np.sqrt(image_array.shape[0]**2 + image_array.shape[1]**2)) + 1
        found = False
        min_dist = np.inf
        for r in range(DIST_SEARCH_STEP, r_max, DIST_SEARCH_STEP):
            if found:
                break
            x_min, x_max = max(0, x - r), min(image_array.shape[1], x + r)
            y_min, y_max = max(0, y - r), min(image_array.shape[0], y + r)
            for y_in in range(y_min, y_max):
                for x_in in range(x_min, x_max):
                    if image_array[y_in, x_in] > 0:
                        continue
                    dist = np.sqrt((x_in - x) ** 2 + (y_in - y) ** 2)
                    if dist <= r and dist < min_dist:
                        found = True
                        min_dist = dist
        return min_dist

    @staticmethod
    def zero_pad(image, pad):
        return ImageOps.expand(image, border=pad, fill=0)

class IOManager:
    DATA_PREFIX = "data"
    IMAGE_PREFIX = "image"
    IMAGE_EXT = "png"

    def __init__(self):
        self.serializer = json.JSONEncoder(indent=4)
        self.deserializer = json.JSONDecoder()

    def read_params_file(self, filename: str):
        with open(filename, 'r') as file:
            try:
                params_dict = self.deserializer.decode(file.read())
                params = ImageCollection.Params.from_dict(params_dict)
            except FileNotFoundError:
                raise IOError(f"File \"{filename}\" not found")
            except IOError:
                raise IOError(f"Error when reading \"{filename}\"")
            except json.JSONDecodeError:
                raise IOError(f"Malformed parameters file \"{filename}\"")

        if "length" not in params_dict:
            raise KeyError(f"'length' key not found in params file {filename}")
        if "straightness" not in params_dict:
            raise KeyError(f"'straightness' key not found in params file {filename}")
        if "width" not in params_dict:
            raise KeyError(f"'width' key not found in params file {filename}")

        params.length.set_bounds(0, float('inf'))
        params.straightness.set_bounds(0, 1)
        params.width.set_bounds(0, float('inf'))
        params.set_names()
        params.set_hints()
        return params

    def write_results(self, params, collection, out_folder: str):
        if not os.path.exists(out_folder):
            os.makedirs(out_folder)
        
        self.write_string_file(os.path.join(out_folder, "params.json"), json.dumps(params.to_dict(), indent=4))
        
        for i in range(collection.size()):
            image_prefix = os.path.join(out_folder, f"{self.IMAGE_PREFIX}{i}")
            self.write_image_file(image_prefix, collection.get_image(i))
            data_filename = os.path.join(out_folder, f"{self.DATA_PREFIX}{i}.json")
            self.write_string_file(data_filename, json.dumps(collection.get(i).to_dict(), indent=4))

    def write_string_file(self, filename: str, contents: str):
        with open(filename, 'w') as file:
            try:
                file.write(contents)
            except IOError:
                raise IOError(f"Error while writing \"{filename}\"")

    def write_image_file(self, prefix: str, image: Image.Image):
        filename = f"{prefix}.{self.IMAGE_EXT}"
        try:
            image.save(filename, format=self.IMAGE_EXT.upper())
        except IOError:
            raise IOError(f"Error while writing \"{filename}\"")

class OptionPanel(QWidget):
    FIELD_W = 5
    INNER_BUFF = 5

    def __init__(self, parent=None, border_text=None):
        super().__init__(parent)
        layout = QVBoxLayout()
        self.setLayout(layout)
        self.y = 0
        self.components = []

        if border_text:
            self.setTitle(border_text)

    def add_button_line(self, label_text, hint_text, button_text):
        self.add_label(label_text, hint_text)
        return self.add_button(button_text)

    def add_field_line(self, param):
        self.add_label(MiscUtility.gui_name(param), param.hint())
        return self.add_field()

    def add_read_only_field(self):
        field = self.add_field()
        field.setReadOnly(True)
        return field

    def add_display_field(self):
        field = QLineEdit()
        field.setReadOnly(True)
        field.setFrame(False)
        layout = self.layout()
        layout.addWidget(field)
        self.y += 1
        return field

    def add_field(self):
        field = QLineEdit()
        field.setFixedWidth(self.FIELD_W * 10)
        layout = self.layout()
        layout.addWidget(field)
        self.y += 1
        return field

    def add_label(self, label_text, hint_text):
        label = QLabel(label_text)
        layout = self.layout()
        layout.addWidget(label)
        if hint_text:
            label.setToolTip(hint_text)
        return label

    def add_check_box(self, option):
        check_box = QCheckBox(MiscUtility.gui_name(option))
        check_box.setChecked(option.use)
        layout = self.layout()
        layout.addWidget(check_box)
        if option.hint():
            check_box.setToolTip(option.hint())
        self.y += 1
        return check_box

    def add_button(self, label_text):
        button = QPushButton(label_text)
        layout = self.layout()
        layout.addWidget(button)
        self.y += 1
        return button

    def show_hint(self, hint_text):
        QMessageBox.information(self, "Hint", hint_text)

    def hide_hint(self):
        pass

class MainWindow(QMainWindow):
    IMAGE_DISPLAY_SIZE = 512
    DEFAULTS_FILE = "defaults.json"

    def __init__(self):
        super().__init__()

        self.setWindowTitle("Fiber Generator")
        self.out_folder = os.path.join("output", "")
        self.io_manager = IOManager()

        try:
            self.params = self.io_manager.read_params_file(self.DEFAULTS_FILE)
        except Exception as e:
            self.show_error(str(e))

        self.collection = None
        self.display_index = 0

        self.init_gui()
        #self.display_params()
        
    def init_gui(self):
        self.setGeometry(100, 100, 800, 600)
        self.setFixedSize(1000, 618)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)

        main_layout = QGridLayout(central_widget)

        # Create display frame
        display_frame = QFrame(self)
        display_layout = QVBoxLayout(display_frame)
        main_layout.addWidget(display_frame, 0, 0, 4, 1)

        tab_widget = QTabWidget()
        main_layout.addWidget(tab_widget, 0, 1)

        generation_tab = QWidget()
        structure_tab = QWidget()
        appearance_tab = QWidget()

        tab_widget.addTab(generation_tab, "Generation")
        tab_widget.addTab(structure_tab, "Structure")
        tab_widget.addTab(appearance_tab, "Appearance")

        self.generate_button = QPushButton("Generate...", self)
        main_layout.addWidget(self.generate_button, 1, 1)

        # Display frame components
        self.image_display = self.create_image_display(display_frame)
        display_layout.addWidget(self.image_display)

        buttons_layout = QHBoxLayout()
        display_layout.addLayout(buttons_layout)

        self.prev_button = QPushButton("Previous", display_frame)
        buttons_layout.addWidget(self.prev_button)

        self.next_button = QPushButton("Next", display_frame)
        buttons_layout.addWidget(self.next_button)

        # Generation tab components
        generation_layout = QVBoxLayout(generation_tab)
        generation_tab.setLayout(generation_layout)

        session_frame = QGroupBox("Session", generation_tab)
        session_layout = QGridLayout(session_frame)
        generation_layout.addWidget(session_frame)

        session_layout.addWidget(QLabel("Parameters:"), 0, 0)
        self.load_button = QPushButton("Open...", session_frame)
        session_layout.addWidget(self.load_button, 0, 1)

        session_layout.addWidget(QLabel("Output location:" + " \noutput/"), 1, 0)
        self.save_button = QPushButton("Open...", session_frame)
        session_layout.addWidget(self.save_button, 1, 1)

        session_layout.addWidget(QLabel("Number of images:"), 2, 0)
        self.n_images_field = QLineEdit(session_frame)
        session_layout.addWidget(self.n_images_field, 2, 1)

        self.seed_check = QCheckBox("Seed:", session_frame)
        session_layout.addWidget(self.seed_check, 3, 0)
        self.seed_field = QLineEdit(session_frame)
        session_layout.addWidget(self.seed_field, 3, 1)

        # Structure tab components
        structure_layout = QVBoxLayout(structure_tab)
        structure_tab.setLayout(structure_layout)

        distribution_frame = QGroupBox("Distributions", structure_tab)
        distribution_layout = QGridLayout(distribution_frame)
        structure_layout.addWidget(distribution_frame)

        distribution_layout.addWidget(QLabel("Length distribution:"), 0, 0)
        self.length_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.length_button, 0, 1)
        self.length_display = QLineEdit(distribution_frame)
        distribution_layout.addWidget(self.length_display, 0, 2)

        distribution_layout.addWidget(QLabel("Width distribution:"), 1, 0)
        self.width_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.width_button, 1, 1)
        self.width_display = QLineEdit(distribution_frame)
        distribution_layout.addWidget(self.width_display, 1, 2)

        distribution_layout.addWidget(QLabel("Straightness distribution:"), 2, 0)
        self.straight_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.straight_button, 2, 1)
        self.straight_display = QLineEdit(distribution_frame)
        distribution_layout.addWidget(self.straight_display, 2, 2)

        values_frame = QGroupBox("Values", structure_tab)
        values_layout = QGridLayout(values_frame)
        structure_layout.addWidget(values_frame)

        values_layout.addWidget(QLabel("Number of fibers:"), 0, 0)
        self.n_fibers_field = QLineEdit(values_frame)
        values_layout.addWidget(self.n_fibers_field, 0, 1)

        values_layout.addWidget(QLabel("Segment length:"), 1, 0)
        self.segment_field = QLineEdit(values_frame)
        values_layout.addWidget(self.segment_field, 1, 1)

        values_layout.addWidget(QLabel("Width change:"), 2, 0)
        self.width_change_field = QLineEdit(values_frame)
        values_layout.addWidget(self.width_change_field, 2, 1)

        values_layout.addWidget(QLabel("Alignment:"), 3, 0)
        self.alignment_field = QLineEdit(values_frame)
        values_layout.addWidget(self.alignment_field, 3, 1)

        values_layout.addWidget(QLabel("Mean angle:"), 4, 0)
        self.mean_angle_field = QLineEdit(values_frame)
        values_layout.addWidget(self.mean_angle_field, 4, 1)

        # Appearance tab components
        appearance_layout = QVBoxLayout(appearance_tab)
        appearance_tab.setLayout(appearance_layout)

        required_frame = QGroupBox("Required", appearance_tab)
        required_layout = QGridLayout(required_frame)
        appearance_layout.addWidget(required_frame)

        required_layout.addWidget(QLabel("Image width:"), 0, 0)
        self.image_width_field = QLineEdit(required_frame)
        required_layout.addWidget(self.image_width_field, 0, 1)

        required_layout.addWidget(QLabel("Image height:"), 1, 0)
        self.image_height_field = QLineEdit(required_frame)
        required_layout.addWidget(self.image_height_field, 1, 1)

        required_layout.addWidget(QLabel("Image buffer:"), 2, 0)
        self.image_buffer_field = QLineEdit(required_frame)
        required_layout.addWidget(self.image_buffer_field, 2, 1)

        optional_frame = QGroupBox("Optional", appearance_tab)
        optional_layout = QGridLayout(optional_frame)
        appearance_layout.addWidget(optional_frame)

        optional_layout.addWidget(QLabel("Scale:"), 0, 0)
        self.scale_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.scale_check, 0, 1)
        self.scale_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.scale_field, 0, 2)

        optional_layout.addWidget(QLabel("Down sample:"), 1, 0)
        self.sample_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.sample_check, 1, 1)
        self.sample_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.sample_field, 1, 2)

        optional_layout.addWidget(QLabel("Blur:"), 2, 0)
        self.blur_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.blur_check, 2, 1)
        self.blur_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.blur_field, 2, 2)

        optional_layout.addWidget(QLabel("Noise:"), 3, 0)
        self.noise_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.noise_check, 3, 1)
        self.noise_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.noise_field, 3, 2)

        optional_layout.addWidget(QLabel("Distance:"), 4, 0)
        self.distance_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.distance_check, 4, 1)
        self.distance_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.distance_field, 4, 2)

        optional_layout.addWidget(QLabel("Cap:"), 5, 0)
        self.cap_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.cap_check, 5, 1)
        self.cap_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.cap_field, 5, 2)

        optional_layout.addWidget(QLabel("Normalize:"), 6, 0)
        self.normalize_check = QCheckBox("", optional_frame)
        optional_layout.addWidget(self.normalize_check, 6, 1)
        self.normalize_field = QLineEdit(optional_frame)
        optional_layout.addWidget(self.normalize_field, 6, 2)

        smoothing_frame = QGroupBox("Smoothing", appearance_tab)
        smoothing_layout = QGridLayout(smoothing_frame)
        appearance_layout.addWidget(smoothing_frame)

        smoothing_layout.addWidget(QLabel("Bubble:"), 0, 0)
        self.bubble_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.bubble_check, 0, 1)
        self.bubble_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.bubble_field, 0, 2)

        smoothing_layout.addWidget(QLabel("Swap:"), 1, 0)
        self.swap_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.swap_check, 1, 1)
        self.swap_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.swap_field, 1, 2)

        smoothing_layout.addWidget(QLabel("Spline:"), 2, 0)
        self.spline_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.spline_check, 2, 1)
        self.spline_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.spline_field, 2, 2)

        self.generate_button.clicked.connect(self.generate_pressed)
        self.prev_button.clicked.connect(self.prev_pressed)
        self.next_button.clicked.connect(self.next_pressed)
        self.load_button.clicked.connect(self.load_pressed)
        self.save_button.clicked.connect(self.save_pressed)
        self.length_button.clicked.connect(self.length_pressed)
        self.width_button.clicked.connect(self.width_pressed)
        self.straight_button.clicked.connect(self.straight_pressed)

    def display_params(self):
        self.path_display.setText(self.out_folder)

        self.n_images_field.setText(self.params.nImages.get_string())
        self.seed_check.setChecked(self.params.seed.use)
        self.seed_field.setText(self.params.seed.get_string())

        self.length_display.setText(self.params.length.get_string())
        self.width_display.setText(self.params.width.get_string())
        self.straight_display.setText(self.params.straightness.get_string())

        self.n_fibers_field.setText(self.params.nFibers.get_string())
        self.segment_field.setText(self.params.segmentLength.get_string())
        self.width_change_field.setText(self.params.widthChange.get_string())
        self.alignment_field.setText(self.params.alignment.get_string())
        self.mean_angle_field.setText(self.params.meanAngle.get_string())

        self.image_width_field.setText(self.params.imageWidth.get_string())
        self.image_height_field.setText(self.params.imageHeight.get_string())
        self.image_buffer_field.setText(self.params.imageBuffer.get_string())

        self.scale_check.setChecked(self.params.scale.use)
        self.scale_field.setText(self.params.scale.get_string())
        self.sample_check.setChecked(self.params.downSample.use)
        self.sample_field.setText(self.params.downSample.get_string())
        self.blur_check.setChecked(self.params.blur.use)
        self.blur_field.setText(self.params.blur.get_string())
        self.noise_check.setChecked(self.params.noise.use)
        self.noise_field.setText(self.params.noise.get_string())
        self.distance_check.setChecked(self.params.distance.use)
        self.distance_field.setText(self.params.distance.get_string())
        self.cap_check.setChecked(self.params.cap.use)
        self.cap_field.setText(self.params.cap.get_string())
        self.normalize_check.setChecked(self.params.normalize.use)
        self.normalize_field.setText(self.params.normalize.get_string())
        self.bubble_check.setChecked(self.params.bubble.use)
        self.bubble_field.setText(self.params.bubble.get_string())
        self.swap_check.setChecked(self.params.swap.use)
        self.swap_field.setText(self.params.swap.get_string())
        self.spline_check.setChecked(self.params.spline.use)
        self.spline_field.setText(self.params.spline.get_string())

    def parse_params(self):
        self.params.nImages.parse(self.n_images_field.text(), int)
        self.params.seed.parse(self.seed_check.isChecked(), self.seed_field.text(), int)

        self.params.nFibers.parse(self.n_fibers_field.text(), int)
        self.params.segmentLength.parse(self.segment_field.text(), float)
        self.params.widthChange.parse(self.width_change_field.text(), float)
        self.params.alignment.parse(self.alignment_field.text(), float)
        self.params.meanAngle.parse(self.mean_angle_field.text(), float)

        self.params.imageWidth.parse(self.image_width_field.text(), int)
        self.params.imageHeight.parse(self.image_height_field.text(), int)
        self.params.imageBuffer.parse(self.image_buffer_field.text(), int)

        self.params.scale.parse(self.scale_check.isChecked(), self.scale_field.text(), float)
        self.params.downSample.parse(self.sample_check.isChecked(), self.sample_field.text(), float)
        self.params.blur.parse(self.blur_check.isChecked(), self.blur_field.text(), float)
        self.params.noise.parse(self.noise_check.isChecked(), self.noise_field.text(), float)
        self.params.distance.parse(self.distance_check.isChecked(), self.distance_field.text(), float)
        self.params.cap.parse(self.cap_check.isChecked(), self.cap_field.text(), int)
        self.params.normalize.parse(self.normalize_check.isChecked(), self.normalize_field.text(), int)

        self.params.bubble.parse(self.bubble_check.isChecked(), self.bubble_field.text(), int)
        self.params.swap.parse(self.swap_check.isChecked(), self.swap_field.text(), int)
        self.params.spline.parse(self.spline_check.isChecked(), self.spline_field.text(), int)

    def display_image(self, image):
        x_scale = self.IMAGE_DISPLAY_SIZE / image.width
        y_scale = self.IMAGE_DISPLAY_SIZE / image.height
        scale = min(x_scale, y_scale)
        image = image.resize((int(image.width * scale), int(image.height * scale)), Image.NEAREST)

        qt_image = ImageQt(image)
        pixmap = QPixmap.fromImage(qt_image)
        self.image_display.setPixmap(pixmap)

    def generate_pressed(self):
        try:
            self.parse_params()
            self.collection = ImageCollection(self.params)
            self.collection.generate_images()
            self.io_manager.write_results(self.params, self.collection, self.out_folder)
        except Exception as e:
            self.show_error(str(e))
            return

        self.display_index = 0
        self.display_image(self.collection.get_image(self.display_index))

    def prev_pressed(self):
        if self.collection and self.display_index > 0:
            self.display_index -= 1
            self.display_image(self.collection.get_image(self.display_index))

    def next_pressed(self):
        if self.collection and self.display_index < self.collection.size() - 1:
            self.display_index += 1
            self.display_image(self.collection.get_image(self.display_index))

    def load_pressed(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Open File", "", "JSON files (*.json)")
        if filename:
            try:
                self.params = self.io_manager.read_params_file(filename)
            except Exception as e:
                self.show_error(str(e))
            self.display_params()

    def save_pressed(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Directory")
        if directory:
            self.out_folder = os.path.join(directory, "")
            self.display_params()

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

    def create_image_display(self, parent):
        label = QLabel(parent)
        label.setText("Press \"Generate\" to view images")
        label.setAlignment(Qt.AlignCenter)
        label.setStyleSheet("background-color: black; color: white;")
        label.setFixedSize(512, 512)
        return label

    def show_error(self, message):
        QMessageBox.critical(self, "Error", message)

class EntryPoint:
    @staticmethod
    def main(args):
        if len(args) > 1:
            io_manager = IOManager()
            try:
                params = io_manager.read_params_file(args[1])
                collection = ImageCollection(params)
                collection.generate_images()
                output_folder = os.path.join("output", os.sep)
                io_manager.write_results(params, collection, output_folder)
            except Exception as e:
                print(f"Error: {e}")
        else:
            app = QApplication(sys.argv)
            window = MainWindow()
            window.show()
            sys.exit(app.exec_())
            
if __name__ == "__main__":
    EntryPoint.main(sys.argv)