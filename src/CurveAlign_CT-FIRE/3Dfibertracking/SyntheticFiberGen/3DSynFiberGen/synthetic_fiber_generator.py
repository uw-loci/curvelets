import random
import numpy as np
import math
import os
import json
import sys
from abc import ABC, abstractmethod
from scipy.interpolate import splrep, splev
from typing import List, Iterator 
from scipy.stats import poisson
from scipy.ndimage import gaussian_filter
from scipy.signal import fftconvolve
import matplotlib.pyplot as plt
import tifffile as tiff
from PIL import Image, ImageDraw, ImageOps, ImageQt
import napari
import pandas as pd
import numpy as np
from psf_model import generate_psf_gaussian, generate_psf_vectorial
from PyQt6.QtWidgets import *
from PyQt6.QtGui import *
from PyQt6.QtCore import *
from copy import deepcopy
from datetime import datetime
DIST_SEARCH_STEP = 4
LAST_PSF_STATS = None

class MiscUtility:
    """Utility class containing miscellaneous helper functions for geometry and UI interactions."""

    @staticmethod
    def new_gbc() -> dict:
        """Creates a GridBagConstraints-like dictionary with default values."""
        return {'gridx': 0, 'gridy': 0}

    @staticmethod
    def gui_name(param) -> str:
        """Formats a parameter name for GUI display."""
        name = param.name()
        return f"{name[0].upper() + name[1:] if name else ''}:"

    @staticmethod
    def show_error(message: str, parent=None) -> None:
        """Displays an error message using a QMessageBox."""
        QMessageBox.critical(parent, "Error", message)

    @staticmethod
    def sq(val: float) -> float:
        """Returns the square of a given value."""
        return val * val

    @staticmethod
    def to_deltas(points: list) -> list:
        """
        Converts a list of 2D points into a list of vector offsets.
        The difference between consecutive points is computed, 
        effectively converting absolute positions into relative movements.
        """
        return [points[i + 1] - points[i] for i in range(len(points) - 1)]

    @staticmethod
    def from_deltas(deltas: list, start) -> list:
        """
        Reconstructs a sequence of absolute positions from a list of vector offsets.
        :param deltas: List of movement vectors.
        :param start: Initial position as a Vector.
        :return: List of absolute positions.
        """
        points = [start]
        for delta in deltas:
            points.append(points[-1] + delta)
        return points

    @staticmethod
    def calculate_intersection(p1, p2, q1, q2):
        """
        Computes the intersection point of two line segments, if any.
        Uses the determinant method to solve for intersection:
        - If the determinant is near zero, the lines are parallel or coincident.
        - Otherwise, the intersection point is computed.
        :return: Intersection point as a Vector, or None if no intersection exists.
        """
        # Line equations in the form: ax + by = c
        a1, b1, c1 = p2.y - p1.y, p1.x - p2.x, (p2.y - p1.y) * p1.x + (p1.x - p2.x) * p1.y
        a2, b2, c2 = q2.y - q1.y, q1.x - q2.x, (q2.y - q1.y) * q1.x + (q1.x - q2.x) * q1.y
        
        # Compute determinant
        det = a1 * b2 - a2 * b1
        if abs(det) < 1e-7:  # Lines are parallel or coincident
            return None

        # Solve for intersection point
        x, y = (b2 * c1 - b1 * c2) / det, (a1 * c2 - a2 * c1) / det

        # Ensure the intersection point lies within both segments
        if (min(p1.x, p2.x) <= x <= max(p1.x, p2.x) and min(p1.y, p2.y) <= y <= max(p1.y, p2.y) and
            min(q1.x, q2.x) <= x <= max(q1.x, q2.x) and min(q1.y, q2.y) <= y <= max(q1.y, q2.y)):
            return Vector(x, y)
        return None  # Intersection exists but is outside segment bounds

    @staticmethod
    def get_intersection_point(p1, p2, q1, q2):
        """
        Determines the intersection point of two line segments if they intersect.
        Uses the counter-clockwise (CCW) method to check if the two segments actually cross.
        If they do, the exact intersection is computed using `calculate_intersection`.
        :return: Vector of intersection if it exists, otherwise None.
        """
        def ccw(a, b, c):
            """Returns True if points a, b, and c are counter-clockwise ordered."""
            return (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)

        if ccw(p1, q1, q2) != ccw(p2, q1, q2) and ccw(p1, p2, q1) != ccw(p1, p2, q2):
            return MiscUtility.calculate_intersection(p1, p2, q1, q2)
        return None  # No valid intersection

    @staticmethod
    def point_on_segment(p, a, b) -> bool:
        """
        Checks if point `p` lies on the line segment between `a` and `b`.
        First, it verifies if `p` is collinear with `a` and `b` using the cross-product method.
        Then, it ensures that `p` is within the segment bounds.
        :return: True if `p` lies on the segment, False otherwise.
        """
        # Check collinearity using cross-product
        cross_product = (p.y - a.y) * (b.x - a.x) - (p.x - a.x) * (b.y - a.y)
        if abs(cross_product) > 1e-5:
            return False  # Not on the same line

        # Ensure `p` is within segment bounds
        return min(a.x, b.x) <= p.x <= max(a.x, b.x) and min(a.y, b.y) <= p.y <= max(a.y, b.y)

class MiscUtility3D(MiscUtility):
    """Utility class for 3D-specific operations, extending MiscUtility."""

    @staticmethod
    def to_deltas_3d(points: list) -> list:
        """
        Converts a list of 3D points into a list of offset vectors.
        Each offset represents the difference between consecutive points, 
        converting absolute positions into relative movements.
        :return: A list of 3D Vector offsets (deltas).
        """
        if len(points) < 2:
            return []  # No valid deltas if less than two points
        return [points[i + 1] - points[i] for i in range(len(points) - 1)]

    @staticmethod
    def from_deltas_3d(deltas: list, start) -> list:
        """
        Reconstructs a sequence of absolute 3D positions from a list of offset vectors.
        The process iteratively applies each delta to the previous point, 
        effectively converting relative movements back into absolute positions.
        :return: A list of absolute 3D Vector positions.
        """
        if not deltas:
            return [start]  # If no deltas, return only the starting position
        
        points = [start]
        for delta in deltas:
            points.append(points[-1] + delta)  # Compute next position
        return points

class RngUtility:
    """Utility class for generating random numbers and randomized point distributions."""
    
    rng = random.Random()

    @staticmethod
    def next_point(x_min: float, x_max: float, y_min: float, y_max: float):
        """
        Generates a random 2D point within the specified bounds.
        :return: A Vector representing the random point.
        """
        return Vector(RngUtility.next_double(x_min, x_max), RngUtility.next_double(y_min, y_max))

    @staticmethod
    def next_int(min_val: int, max_val: int) -> int:
        """
        Returns a random integer within the given range.\
        :raises ValueError: If min_val is greater than max_val or the range has zero size.
        """
        if min_val > max_val:
            raise ValueError("Random bounds are inverted")
        if min_val == max_val:
            raise ValueError("Random range must have nonzero size")
        return RngUtility.rng.randint(min_val, max_val)

    @staticmethod
    def next_double(min_val: float, max_val: float) -> float:
        """
        Returns a random floating-point number in the given range.
        :raises ValueError: If min_val is greater than max_val.
        """
        if min_val > max_val:
            raise ValueError("Random bounds are inverted")
        return RngUtility.rng.uniform(min_val, max_val)

    @staticmethod
    def random_chain(start, end, n_steps: int, step_size: float) -> list:
        """
        Generates a randomized sequence of points forming a chain between two endpoints.
        Uses midpoint displacement to create a jagged, non-linear path.
        :raises ValueError: If n_steps is <= 0 or step_size is <= 0.
        :return: A list of Vector points forming the random chain.
        """
        if n_steps <= 0:
            raise ValueError("Must have at least one step")
        if step_size <= 0.0:
            raise ValueError("Step size must be positive")

        points = [None] * (n_steps + 1)
        points[0], points[n_steps] = start, end  # Fix endpoints

        RngUtility.random_chain_recursive(points, 0, n_steps, step_size)
        return points

    @staticmethod
    def random_chain_recursive(points: list, i_start: int, i_end: int, step_size: float):
        """
        Recursively generates a random chain of points using midpoint displacement.
        Each midpoint is displaced within an area defined by two intersecting circles 
        (one centered at each neighboring endpoint).
        :param points: List of Vector points (modified in place).
        """
        if i_end - i_start <= 1:
            return  # No further division needed

        i_bridge = (i_start + i_end) // 2  # Midpoint index
        circle1 = Circle(points[i_start], step_size * (i_bridge - i_start))
        circle2 = Circle(points[i_end], step_size * (i_end - i_bridge))

        # Determine midpoint displacement based on different intersection cases
        if i_bridge > i_start + 1 and i_bridge < i_end - 1:
            bridge = Circle.disk_disk_intersect(circle1, circle2)
        elif i_bridge == i_start + 1 and i_bridge == i_end - 1:
            bridge_candidates = Circle.circle_circle_intersect(circle1, circle2)
            bridge = RngUtility.rng.choice(bridge_candidates) if bridge_candidates else None
        else:
            bridge = Circle.disk_circle_intersect(circle2, circle1) if i_bridge == i_start + 1 else Circle.disk_circle_intersect(circle1, circle2)

        # Ensure bridge is a valid Vector
        if not isinstance(bridge, Vector):
            raise TypeError(f"Expected bridge to be a Vector, got {type(bridge)}")

        points[i_bridge] = bridge  # Set midpoint

        # Recursively apply the process to both halves
        RngUtility.random_chain_recursive(points, i_start, i_bridge, step_size)
        RngUtility.random_chain_recursive(points, i_bridge, i_end, step_size)

class RngUtility3D(RngUtility):
    """Utility class for generating random 3D point chains with directional constraints."""

    @staticmethod
    def random_chain_3d(start, end, n_segments: int, segment_length: float, min_angle_change: float, max_angle_change: float):
        """
        Generates a random 3D chain of vectors with angle constraints between segments.
        :return: A list of Vector points forming the random 3D chain.
        """
        points = [start]
        direction = (end - start).normalize()

        # Convert angle limits from degrees to radians
        min_angle_change_rad = math.radians(min_angle_change)
        max_angle_change_rad = math.radians(max_angle_change)

        for _ in range(n_segments):
            random_dir = RngUtility3D.random_vector_3d()

            # Ensure the new direction respects the angle constraints
            angle = math.acos(direction.dot_product(random_dir))
            if angle < min_angle_change_rad or angle > max_angle_change_rad:
                random_dir = RngUtility3D.constrain_angle(random_dir, direction, min_angle_change_rad, max_angle_change_rad)

            new_point = points[-1] + random_dir.scalar_multiply(segment_length)
            points.append(new_point)
            direction = random_dir  # Update direction for the next segment

        return points

    @staticmethod
    def random_vector_3d():
        """
        Generates a random 3D unit vector.
        Uses uniform spherical distribution for isotropic sampling.
        """
        theta = np.random.uniform(0, 2 * np.pi)  # Azimuthal angle
        z = np.random.uniform(-1, 1)  # Uniform sampling along Z-axis
        r = math.sqrt(1 - z**2)  # Radius in XY-plane
        return Vector(r * math.cos(theta), r * math.sin(theta), z)

    @staticmethod
    def constrain_angle(random_dir, current_dir, min_angle: float, max_angle: float):
        """
        Constrains a randomly generated vector to fall within a specified angle range.
        If the generated direction is outside the allowed range, it is adjusted accordingly.
        """
        angle = math.acos(current_dir.dot_product(random_dir))

        # Adjust the angle if it is outside the allowed range
        if angle < min_angle:
            return RngUtility3D.adjust_angle(random_dir, current_dir, min_angle)
        if angle > max_angle:
            return RngUtility3D.adjust_angle(random_dir, current_dir, max_angle)
        
        return random_dir

    @staticmethod
    def adjust_angle(random_dir, current_dir, target_angle: float):
        """
        Adjusts a direction vector to match a specified angle relative to the current direction.
        Uses a rotation matrix to rotate the vector around the current direction axis.
        """
        rotation_matrix = RngUtility3D.rotation_matrix(current_dir, target_angle)
        adjusted_dir = np.dot(rotation_matrix, random_dir.to_array())
        return Vector(adjusted_dir[0], adjusted_dir[1], adjusted_dir[2])

    @staticmethod
    def rotation_matrix(axis, angle: float):
        """
        Generates a 3D rotation matrix for rotating a vector by a given angle around an axis.
        Uses Rodrigues' rotation formula.
        """
        axis = axis.normalize().to_array()  # Ensure the axis is a unit vector
        cos_angle = np.cos(angle)
        sin_angle = np.sin(angle)
        one_minus_cos = 1 - cos_angle
        x, y, z = axis

        # Construct the 3D rotation matrix using Rodrigues' formula
        return np.array([
            [cos_angle + x * x * one_minus_cos,
             x * y * one_minus_cos - z * sin_angle,
             x * z * one_minus_cos + y * sin_angle],
            [y * x * one_minus_cos + z * sin_angle,
             cos_angle + y * y * one_minus_cos,
             y * z * one_minus_cos - x * sin_angle],
            [z * x * one_minus_cos - y * sin_angle,
             z * y * one_minus_cos + x * sin_angle,
             cos_angle + z * z * one_minus_cos]
        ])

class Vector:
    """A 3D vector class for mathematical operations in synthetic fiber generation."""

    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        """Initializes a 3D vector with default values of zero."""
        self.x = x
        self.y = y
        self.z = z

    def normalize(self):
        """
        Returns a normalized (unit) vector.
        :raises ValueError: If the vector is zero and cannot be normalized.
        """
        norm = np.linalg.norm([self.x, self.y, self.z])
        if norm == 0:
            raise ValueError("Cannot normalize a zero vector")
        return Vector(self.x / norm, self.y / norm, self.z / norm)

    def scalar_multiply(self, scalar: float):
        """Returns a new vector scaled by a given scalar."""
        return Vector(self.x * scalar, self.y * scalar, self.z * scalar)
    
    def length(self) -> float:
        """Computes and returns the magnitude (length) of the vector."""
        return (self.x ** 2 + self.y ** 2 + self.z ** 2) ** 0.5

    def add(self, other):
        """Returns the sum of this vector and another vector."""
        return Vector(self.x + other.x, self.y + other.y, self.z + other.z)

    def subtract(self, other):
        """Returns the difference between this vector and another vector."""
        return Vector(self.x - other.x, self.y - other.y, self.z - other.z)

    def __add__(self, other):
        """Overloads the + operator for vector addition."""
        return self.add(other)

    def __sub__(self, other):
        """Overloads the - operator for vector subtraction."""
        return self.subtract(other)

    def dot_product(self, other) -> float:
        """Computes and returns the dot product of this vector with another."""
        return self.x * other.x + self.y * other.y + self.z * other.z

    def angle_with(self, other) -> float:
        """
        Computes the angle (in radians) between this vector and another.
        :raises ValueError: If either vector is zero.
        """
        if self.is_zero() or other.is_zero():
            raise ValueError("Cannot compute angle with zero vector")
        cos_theta = np.clip(self.normalize().dot_product(other.normalize()), -1, 1)
        return np.arccos(cos_theta)

    def theta(self) -> float:
        """Computes the angle (in radians) of the vector in the XY plane."""
        return np.arctan2(self.y, self.x)

    def un_rotate(self, old_x_axis):
        """
        Rotates the vector back to align with the original x-axis.
        :raises ValueError: If the provided x-axis is a zero vector.
        """
        if old_x_axis.is_zero():
            raise ValueError("New x-axis must be nonzero")
        old_x_axis = old_x_axis.normalize()
        new_y_axis = Vector(-old_x_axis.y, old_x_axis.x)  # Perpendicular in XY plane
        return old_x_axis.scalar_multiply(self.x).add(new_y_axis.scalar_multiply(self.y))

    def is_zero(self) -> bool:
        """Checks if the vector is a zero vector (all components are zero)."""
        return self.x == 0 and self.y == 0 and self.z == 0

    def to_array(self):
        """Returns the vector as a NumPy array."""
        return np.array([self.x, self.y, self.z])

    def __getitem__(self, index: int) -> float:
        """Allows indexing into the vector as if it were a list or tuple."""
        if index == 0:
            return self.x
        elif index == 1:
            return self.y
        elif index == 2:
            return self.z
        raise IndexError("Index out of range for Vector")

    def __repr__(self) -> str:
        """Returns a string representation of the vector."""
        return f"Vector({self.x}, {self.y}, {self.z})"
    
class Param:
    """A class for handling parameter values with optional bounds, parsing, and validation."""

    def __init__(self, value=None, name="", hint="", lower_bound=None, upper_bound=None):
        """Initializes a parameter with optional constraints."""
        self.value = value
        self.name = name
        self.hint = hint
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    def get_value(self):
        """Returns the current value of the parameter."""
        return self.value

    def get_string(self) -> str:
        """Returns the string representation of the parameter value."""
        return str(self.value) if self.value is not None else ""

    def set_name(self, name: str):
        """Sets the name of the parameter."""
        self.name = name

    def get_name(self) -> str:
        """Returns the name of the parameter."""
        return self.name if self.name else ""

    def set_hint(self, hint: str):
        """Sets the hint (description) for the parameter."""
        self.hint = hint

    def get_hint(self) -> str:
        """Returns the hint (description) for the parameter."""
        return self.hint if self.hint else ""

    def set_bounds(self, lower_bound, upper_bound):
        """Sets the lower and upper bounds for the parameter."""
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    def get_lower_bound(self):
        """Returns the lower bound of the parameter."""
        return self.lower_bound

    def get_upper_bound(self):
        """Returns the upper bound of the parameter."""
        return self.upper_bound

    def parse(self, string: str, parser):
        """
        Parses a string input and converts it into the expected data type.
        :param string: The input string to parse.
        :param parser: A function that converts the string into the desired type.
        :raises ValueError: If parsing fails or the input is empty.
        """
        if not string.strip():
            raise ValueError(f"Value of \"{self.get_name()}\" must be non-empty")
        try:
            if string.startswith("[") and string.endswith("]"):
                self.value = [parser(x.strip()) for x in string[1:-1].split(",")]
            else:
                self.value = parser(string)
        except Exception as e:
            raise ValueError(f"Unable to parse value \"{string}\" for parameter \"{self.get_name()}\": {e}")

    def verify(self, bound, verifier):
        """
        Verifies if the parameter's value meets the given condition.
        :param bound: The reference value for verification.
        :param verifier: A function that validates the value against the bound.
        :raises ValueError: If verification fails.
        """
        try:
            if isinstance(self.value, list):
                for val in self.value:
                    verifier(val, bound)
            else:
                verifier(self.value, bound)
        except ValueError as e:
            raise ValueError(f"Value of \"{self.get_name()}\" {e} {bound}")

    @staticmethod
    def less(value, max_value):
        """Ensures the value is less than the specified maximum."""
        if value >= max_value:
            raise ValueError("must be less than")

    @staticmethod
    def greater(value, min_value):
        """Ensures the value is greater than the specified minimum."""
        if value <= min_value:
            raise ValueError("must be greater than")

    @staticmethod
    def less_eq(value, max_value):
        """Ensures the value is less than or equal to the specified maximum."""
        if value > max_value:
            raise ValueError("must be less than or equal to")

    @staticmethod
    def greater_eq(value, min_value):
        """Ensures the value is greater than or equal to the specified minimum."""
        if value < min_value:
            raise ValueError("must be greater than or equal to")

    @staticmethod
    def from_dict(param_dict):
        """
        Creates a Param instance from a dictionary.
        :param param_dict: Dictionary containing parameter attributes.
        :return: A Param instance with the parsed values.
        """
        value = param_dict.get("value")
        if isinstance(value, list):
            value = [float(v) for v in value]
        return Param(
            value=value,
            name=param_dict.get("name", ""),
            hint=param_dict.get("hint", "")
        )

    def to_dict(self) -> dict:
        """Converts the Param instance into a dictionary representation."""
        return {
            "value": self.value,
            "name": self.name,
            "hint": self.hint
        }

class Optional(Param):
    """A subclass of Param that includes an option to enable or disable its usage."""

    def __init__(self, value=None, name="", hint="", use=False, lower_bound=None, upper_bound=None):
        """Initializes an optional parameter with an additional 'use' flag."""
        super().__init__(value, name, hint, lower_bound, upper_bound)
        self.use = use  # Indicates if this parameter should be used.

    def parse(self, use: bool, string: str, parser):
        """Parses the input string into the appropriate data type if 'use' is True."""
        self.use = use
        if self.use:
            super().parse(string, parser)

    def verify(self, bound, verifier):
        """Verifies the parameter's value against a specified constraint if 'use' is True."""
        if self.use:
            super().verify(bound, verifier)

    @staticmethod
    def from_dict(optional_dict: dict):
        """Creates an Optional instance from a dictionary."""
        return Optional(
            value=optional_dict.get("value"),
            name=optional_dict.get("name", ""),
            hint=optional_dict.get("hint", ""),
            use=optional_dict.get("use", False)
        )

    def to_dict(self) -> dict:
        """Converts the Optional instance into a dictionary representation."""
        return {
            "value": self.value,
            "name": self.name,
            "hint": self.hint,
            "use": self.use
        }

class PSFManager:
    """Encapsulates PSF parameter handling, kernel caching, and convolution helpers."""

    MAX_PSF_SIZE = 129

    def __init__(self, params):
        self.params = params
        self._cache = getattr(self.params, "_psf_cache", {})

    def apply(self, data: np.ndarray, volume: bool):
        """
        Convolve data with the configured PSF.

        Args:
            data: Numpy array representing either a 2D image (H, W) or 3D volume (Z, Y, X).
            volume: True for 3D data, False for 2D.

        Returns:
            uint8 array with the same shape as the input, or None if PSF is disabled.
        """
        kernel = self.get_kernel()
        if kernel is None:
            return None

        np_data = np.asarray(data, dtype=np.float32)
        np_data -= np_data.min()
        max_val = np_data.max()
        if max_val > 0:
            np_data /= max_val

        if volume:
            psf = kernel
        else:
            psf = kernel[kernel.shape[0] // 2]
            psf_sum = psf.sum()
            if psf_sum <= 0:
                return None
            psf = psf / psf_sum

        convolved = fftconvolve(np_data, psf, mode="same")
        convolved = np.clip(convolved, 0.0, None)
        convolved -= convolved.min()
        conv_max = convolved.max()
        if conv_max > 0:
            convolved /= conv_max
        return (convolved * 255.0).astype(np.uint8)

    # ------------------------------------------------------------------
    # Internal helpers

    def get_kernel(self):
        if not self._psf_is_enabled():
            return None

        psf_mode = self._normalized_psf_type()

        if psf_mode == "gaussian":
            shape, voxel_size = self._gaussian_psf_parameters()
            key = (
                "gaussian",
                tuple(shape),
                tuple(round(v, 6) for v in voxel_size),
                round(float(self.params.psfGaussianNA.get_value()), 6),
                round(float(self.params.psfGaussianWavelength.get_value()), 6),
            )
            kernel = self._cache.get(key)
            if kernel is None:
                kernel = generate_psf_gaussian(
                    shape,
                    voxel_size,
                    float(self.params.psfGaussianNA.get_value()),
                    float(self.params.psfGaussianWavelength.get_value()),
                )
                self._cache[key] = kernel
        elif psf_mode == "vectorial":
            dims_um, shape_pix = self._vectorial_psf_parameters()
            key = (
                "vectorial",
                tuple(round(v, 4) for v in dims_um),
                tuple(shape_pix),
                round(float(self.params.psfVectorialNA.get_value()), 6),
                round(float(self.params.psfVectorialMediumRI.get_value()), 6),
                round(float(self.params.psfVectorialSampleRI.get_value()), 6),
                round(float(self.params.psfVectorialWavelength.get_value()), 6),
                round(float(self.params.psfVectorialPolarization.get_value()), 6),
            )
            kernel = self._cache.get(key)
            if kernel is None:
                kernel = generate_psf_vectorial(
                    {
                        "NA": float(self.params.psfVectorialNA.get_value()),
                        "n_medium": float(self.params.psfVectorialMediumRI.get_value()),
                        "n_sample": float(self.params.psfVectorialSampleRI.get_value()),
                        "wavelength_um": float(self.params.psfVectorialWavelength.get_value()),
                        "polarization_angle_deg": float(self.params.psfVectorialPolarization.get_value()),
                        "dims_um": dims_um,
                        "shape_pix": shape_pix,
                    }
                )
                self._cache[key] = kernel
        else:
            kernel = None

        self.params._psf_cache = self._cache
        return kernel

    def _psf_is_enabled(self) -> bool:
        return (
            hasattr(self.params, "psfEnabled")
            and getattr(self.params.psfEnabled, "use", False)
            and self._normalized_psf_type() != "none"
        )

    def _normalized_psf_type(self) -> str:
        if not hasattr(self.params, "psfType"):
            return "none"
        value = str(self.params.psfType.get_value() or "").strip().lower()
        if "gaussian" in value:
            return "gaussian"
        if "vectorial" in value:
            return "vectorial"
        return "none"

    def _gaussian_psf_parameters(self):
        voxel_size = (
            float(self.params.psfPixelSizeZ.get_value()),
            float(self.params.psfPixelSizeY.get_value()),
            float(self.params.psfPixelSizeX.get_value()),
        )
        shape = self._auto_gaussian_shape(voxel_size)
        return shape, voxel_size

    def _auto_gaussian_shape(self, voxel_size):
        na = max(float(self.params.psfGaussianNA.get_value()), 1e-6)
        wavelength = max(float(self.params.psfGaussianWavelength.get_value()), 1e-6)
        dz, dy, dx = [max(v, 1e-6) for v in voxel_size]
        sigma_to_fwhm = 2.0 * np.sqrt(2.0 * np.log(2.0))
        fwhm_xy = 0.51 * wavelength / na
        fwhm_z = 0.88 * wavelength / (na * na)
        sigma_xy_um = max(fwhm_xy / sigma_to_fwhm, 1e-6)
        sigma_z_um = max(fwhm_z / sigma_to_fwhm, 1e-6)

        def radius(sigma_um, spacing_um):
            return max(1, int(np.ceil(3.0 * sigma_um / spacing_um)))

        rz = min(self.MAX_PSF_SIZE // 2, radius(sigma_z_um, dz))
        ry = min(self.MAX_PSF_SIZE // 2, radius(sigma_xy_um, dy))
        rx = min(self.MAX_PSF_SIZE // 2, radius(sigma_xy_um, dx))

        def to_odd(length):
            length = max(1, length * 2 + 1)
            if length % 2 == 0:
                length += 1
            return min(self.MAX_PSF_SIZE | 1, length)

        return (to_odd(rz), to_odd(ry), to_odd(rx))

    def _vectorial_psf_parameters(self):
        dims = (
            max(float(self.params.psfVectorialVolumeZ.get_value()), 1e-3),
            max(float(self.params.psfVectorialVolumeY.get_value()), 1e-3),
            max(float(self.params.psfVectorialVolumeX.get_value()), 1e-3),
        )

        def clamp_size(value):
            value = max(3, int(value))
            if value % 2 == 0:
                value += 1
            return min(self.MAX_PSF_SIZE | 1, value)

        shape = (
            clamp_size(self.params.psfVectorialShapeZ.get_value()),
            clamp_size(self.params.psfVectorialShapeY.get_value()),
            clamp_size(self.params.psfVectorialShapeX.get_value()),
        )
        return dims, shape

class Distribution(ABC):
    """Abstract base class for probability distributions with bounded values."""

    def __init__(self, lower_bound: float, upper_bound: float):
        """Initializes a distribution with lower and upper bounds."""
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    @abstractmethod
    def clone(self):
        """Creates and returns a copy of the current distribution instance."""
        pass

    def set_bounds(self, lower_bound: float, upper_bound: float):
        """Updates the lower and upper bounds of the distribution."""
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    @abstractmethod
    def get_type(self) -> str:
        """Returns the type of the distribution as a string."""
        pass

    @abstractmethod
    def get_string(self) -> str:
        """Returns a string representation of the distribution."""
        pass

    @abstractmethod
    def sample(self):
        """Generates a random sample from the distribution."""
        pass

    @abstractmethod
    def set_names(self):
        """Assigns human-readable names to the distribution parameters (if applicable)."""
        pass

    @abstractmethod
    def set_hints(self):
        """Provides user hints for distribution parameters (if applicable)."""
        pass

    @abstractmethod
    def verify(self):
        """Validates that the distribution parameters are correctly set."""
        pass
    
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

class Gaussian(Distribution):
    """Represents a Gaussian (Normal) distribution with configurable mean and standard deviation."""
    
    typename = "Gaussian"

    def __init__(self, lower_bound: float, upper_bound: float, mean_value: float = None, sigma_value: float = None):
        """Initializes a Gaussian distribution with given bounds, mean, and standard deviation."""
        super().__init__(lower_bound, upper_bound)
        self.mean = Param(mean_value)
        self.sigma = Param(sigma_value)
        self.set_names()
        self.set_hints()

    def clone(self) -> "Gaussian":
        """Creates a deep copy of this Gaussian distribution."""
        return Gaussian(self.lower_bound, self.upper_bound, self.mean.get_value(), self.sigma.get_value())

    def get_type(self) -> str:
        """Returns the type name of the distribution."""
        return self.typename

    def get_string(self) -> str:
        """Returns a formatted string representation of the Gaussian distribution."""
        return f"{self.get_type()}: μ={self.mean.get_string()}, σ={self.sigma.get_string()}"

    def sample(self) -> float:
        """Generates a random sample from the Gaussian distribution, ensuring it falls within the bounds."""
        val = None
        while val is None or val < self.lower_bound or val > self.upper_bound:
            val = np.random.normal(self.mean.get_value(), self.sigma.get_value())
        return val

    def set_names(self):
        """Sets the names for the distribution parameters."""
        self.mean.set_name("mean")
        self.sigma.set_name("sigma")

    def set_hints(self):
        """Sets tooltips (hints) for GUI-based representation."""
        self.mean.set_hint("Mean (μ) of the Gaussian distribution")
        self.sigma.set_hint("Standard deviation (σ) of the Gaussian distribution")

    def verify(self):
        """Ensures the Gaussian distribution parameters are valid."""
        if self.sigma.get_value() <= 0:
            raise ValueError(f"Standard deviation {self.sigma.get_value()} must be positive.")
        if self.mean.get_value() < self.lower_bound or self.mean.get_value() > self.upper_bound:
            raise ValueError(f"Mean {self.mean.get_value()} must be within bounds [{self.lower_bound}, {self.upper_bound}].")

    @staticmethod
    def from_dict(gaussian_dict: dict) -> "Gaussian":
        """Creates a Gaussian distribution instance from a dictionary."""
        return Gaussian(
            gaussian_dict.get("lower_bound", 0.0),
            gaussian_dict.get("upper_bound", float('inf')),
            gaussian_dict["mean"]["value"],
            gaussian_dict["sigma"]["value"]
        )

    def to_dict(self) -> dict:
        """Converts the Gaussian distribution to a dictionary format."""
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "mean": self.mean.to_dict(),
            "sigma": self.sigma.to_dict(),
            "type": self.typename,
        }

class Uniform(Distribution):
    """Represents a uniform distribution with configurable minimum and maximum values."""

    typename = "Uniform"

    def __init__(self, lower_bound: float, upper_bound: float, min_value: float = None, max_value: float = None):
        """Initializes a uniform distribution within the given bounds."""
        super().__init__(lower_bound, upper_bound)
        self.min = Param(min_value)
        self.max = Param(max_value)
        self.set_names()
        self.set_hints()

    def clone(self) -> "Uniform":
        """Creates a deep copy of this uniform distribution."""
        return Uniform(self.lower_bound, self.upper_bound, self.min.get_value(), self.max.get_value())

    def get_type(self) -> str:
        """Returns the type name of the distribution."""
        return self.typename

    def get_string(self) -> str:
        """Returns a formatted string representation of the uniform distribution."""
        return f"{self.get_type()}: {self.min.get_string()}-{self.max.get_string()}"

    def sample(self) -> float:
        """Generates a random sample from the uniform distribution, ensuring it falls within the bounds."""
        trim_min = max(self.lower_bound, self.min.get_value())
        trim_max = min(self.upper_bound, self.max.get_value())
        return np.random.uniform(trim_min, trim_max)

    def set_names(self):
        """Sets the names for the distribution parameters."""
        self.min.set_name("minimum")
        self.max.set_name("maximum")

    def set_hints(self):
        """Sets hints for GUI-based representation."""
        self.min.set_hint("Minimum of the uniform distribution (inclusive)")
        self.max.set_hint("Maximum of the uniform distribution (inclusive)")

    def verify(self):
        """Ensures that the uniform distribution parameters are valid."""
        if self.min.get_value() > self.max.get_value():
            raise ValueError(f"Minimum {self.min.get_value()} cannot exceed maximum {self.max.get_value()}.")
        if self.min.get_value() < self.lower_bound:
            raise ValueError(f"Minimum {self.min.get_value()} is below lower bound {self.lower_bound}.")
        if self.max.get_value() > self.upper_bound:
            raise ValueError(f"Maximum {self.max.get_value()} exceeds upper bound {self.upper_bound}.")

    @staticmethod
    def from_dict(uniform_dict: dict) -> "Uniform":
        """Creates a uniform distribution instance from a dictionary."""
        return Uniform(
            uniform_dict.get("lower_bound", 0.0),
            uniform_dict.get("upper_bound", float('inf')),
            uniform_dict["min"]["value"],
            uniform_dict["max"]["value"]
        )

    def to_dict(self) -> dict:
        """Converts the uniform distribution to a dictionary format."""
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "min": self.min.to_dict(),
            "max": self.max.to_dict(),
            "type": self.typename,
        }

class PiecewiseLinear(Distribution):
    """Represents a piecewise linear probability distribution."""

    typename = "Piecewise Linear"

    def __init__(self, lower_bound: float, upper_bound: float, distribution: list = None):
        """Initializes a piecewise linear distribution."""
        super().__init__(lower_bound, upper_bound)
        self.distribution = distribution if distribution else []
        self.set_names()
        self.set_hints()

    def clone(self) -> "PiecewiseLinear":
        """Creates a deep copy of this piecewise linear distribution."""
        return PiecewiseLinear(self.lower_bound, self.upper_bound, list(self.distribution))

    def get_type(self) -> str:
        """Returns the type name of the distribution."""
        return self.typename

    def get_string(self) -> str:
        """Returns a string representation of the distribution."""
        return "Piecewise linear"

    def sample(self) -> float:
        """Samples a random value from the piecewise linear distribution within the bounds."""
        if not self.distribution:
            raise ValueError("Piecewise linear distribution is empty.")

        # Compute total area under the piecewise linear curve (integral)
        integral = sum(0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0])
                       for p1, p2 in zip(self.distribution, self.distribution[1:]))

        # Normalize the distribution
        normalized = [[p[0], p[1] / integral] for p in self.distribution]

        # Generate a random sample from the cumulative distribution function (CDF)
        i, cdf, rand, cdf_prev = 0, 0.0, np.random.uniform(), 0.0
        while i < len(normalized) - 1 and cdf < rand:
            cdf_prev = cdf
            p1, p2 = normalized[i], normalized[i + 1]
            cdf += 0.5 * (p1[1] + p2[1]) * (p2[0] - p1[0])
            i += 1

        cdf_remain = rand - cdf_prev

        if i == 0:
            return normalized[0][0]
        if i == len(normalized):
            return normalized[-1][0]

        # Solve for the sample x value
        p1, p2 = normalized[i - 1], normalized[i]
        x1, y1, x2, y2 = p1[0], p1[1], p2[0], p2[1]

        m = (y2 - y1) / (x2 - x1)  # Slope
        a = 0.5 * m
        b = y1 - m * x1
        c = 0.5 * m * x1 ** 2 - y1 * x1 - cdf_remain

        discriminant = b ** 2 - 4 * a * c
        if discriminant < 0:
            raise ArithmeticError("Sampling failure (no real quadratic roots)")

        # Compute the valid root within the segment bounds
        root0 = (-b + np.sqrt(discriminant)) / (2 * a)
        root1 = (-b - np.sqrt(discriminant)) / (2 * a)
        return root0 if x1 <= root0 <= x2 else root1

    def set_names(self):
        """Sets parameter names (not used in this class)."""
        pass

    def set_hints(self):
        """Sets tooltips for GUI representation (not used in this class)."""
        pass

    def verify(self):
        """Ensures that the piecewise linear distribution is valid."""
        last_x = float('-inf')
        for x, y in self.distribution:
            if x < self.lower_bound or x > self.upper_bound:
                raise ValueError(f"X-values must be within bounds [{self.lower_bound}, {self.upper_bound}]")
            if x < last_x:
                raise ValueError(f"Piecewise linear x-coordinates out of order ({last_x}, {x})")
            if y < 0:
                raise ValueError(f"Negative piecewise linear probability {y}")
            last_x = x

        if not self.distribution:
            raise ValueError("Piecewise linear distribution cannot be empty.")
        if self.distribution[0][0] < self.lower_bound:
            raise ValueError(f"Distribution extends below lower bound {self.lower_bound}")
        if self.distribution[-1][0] > self.upper_bound:
            raise ValueError(f"Distribution extends above upper bound {self.upper_bound}")

    def get_x_string(self) -> str:
        """Returns a comma-separated string of x-values."""
        return ",".join(str(point[0]) for point in self.distribution)

    def get_y_string(self) -> str:
        """Returns a comma-separated string of y-values."""
        return ",".join(str(point[1]) for point in self.distribution)

    def parse_xy_values(self, x_string: str, y_string: str):
        """Parses x and y values from comma-separated strings and updates the distribution."""
        x_tokens, y_tokens = x_string.split(","), y_string.split(",")

        if len(x_tokens) != len(y_tokens):
            raise ValueError("Number of x and y points must be equal")
        if not x_tokens:
            raise ValueError("Must have at least one point in the distribution")

        self.distribution = []
        for x, y in zip(x_tokens, y_tokens):
            try:
                x_val = float(x)
                y_val = float(y)
                if x_val < self.lower_bound or x_val > self.upper_bound:
                    raise ValueError(f"X-value {x_val} is out of bounds [{self.lower_bound}, {self.upper_bound}]")
                if y_val < 0:
                    raise ValueError(f"Negative probability {y_val} is not allowed")
                self.distribution.append([x_val, y_val])
            except ValueError:
                raise ValueError(f"Invalid coordinate values: {x}, {y}")

    @staticmethod
    def from_dict(piecewise_linear_dict: dict) -> "PiecewiseLinear":
        """Creates a piecewise linear distribution instance from a dictionary."""
        lower_bound = piecewise_linear_dict.get("lower_bound", 0.0)
        upper_bound = piecewise_linear_dict.get("upper_bound", float('inf'))
        x_values = piecewise_linear_dict.get("x_values", [])
        y_values = piecewise_linear_dict.get("y_values", [])

        if len(x_values) != len(y_values):
            raise ValueError("Mismatch between x_values and y_values length in dictionary")

        distribution = list(zip(x_values, y_values))
        return PiecewiseLinear(lower_bound, upper_bound, distribution)

    def to_dict(self) -> dict:
        """Converts the piecewise linear distribution to a dictionary format."""
        return {
            "lower_bound": self.lower_bound,
            "upper_bound": self.upper_bound,
            "x_values": [p[0] for p in self.distribution],
            "y_values": [p[1] for p in self.distribution],
            "type": self.typename
        }
                
class Circle:
    """Represents a circle with a center and radius, supporting intersection calculations."""

    BUFF = 1e-10  # Small buffer to avoid precision issues

    def __init__(self, center, radius):
        """Initializes a circle with a given center and radius."""
        self._center = center
        self._radius = radius

    def center(self):
        """Returns the center of the circle."""
        return self._center

    def radius(self):
        """Returns the radius of the circle."""
        return self._radius

    def contains(self, point):
        """
        Checks whether a given point lies inside or on the boundary of the circle.
        :param point: The point to check.
        :return: True if the point is inside or on the circle, False otherwise.
        """
        return np.linalg.norm(self.center().to_array() - point.to_array()) <= self.radius() + self.BUFF

    def __eq__(self, other):
        """Checks if two circles are equal (same center and radius)."""
        return isinstance(other, Circle) and np.array_equal(self.center().to_array(), other.center().to_array()) and self.radius() == other.radius()

    def choose_point(self, min_theta, max_theta):
        """
        Chooses a random point on the circle's circumference within the given angle range.
        :param min_theta: Minimum angle (in radians).
        :param max_theta: Maximum angle (in radians).
        :return: A random point on the circle.
        """
        theta = RngUtility.next_double(min_theta, max_theta)
        direction = np.array([math.cos(theta), math.sin(theta)])
        return Vector(self.center().x + direction[0] * self.radius(), self.center().y + direction[1] * self.radius())

    @staticmethod
    def circle_circle_intersect(circle1, circle2):
        """
        Finds the intersection points of two circles.
        :return: A list of intersection points or an empty list if no intersection exists.
        """
        d = np.linalg.norm(circle1.center().to_array() - circle2.center().to_array())
        space = d - circle1.radius() - circle2.radius()

        # Adjust if circles are too far apart
        if space > 0:
            circle1 = Circle(circle1.center(), circle1.radius() + Circle.BUFF)
            circle2 = Circle(circle2.center(), circle2.radius() + Circle.BUFF)
            space -= 2 * Circle.BUFF

        nested = d < abs(circle1.radius() - circle2.radius())

        # Ensure circles intersect
        while circle1 == circle2 or nested or space > 0:
            if nested:
                # Adjust smaller circle's radius
                if circle1.radius() < circle2.radius():
                    circle1 = Circle(circle1.center(), circle2.radius() - d + circle2.radius() + Circle.BUFF)
                else:
                    circle2 = Circle(circle2.center(), circle1.radius() - d + circle1.radius() + Circle.BUFF)
            elif space > 0:
                # Adjust centers to bring them closer
                direction = (circle2.center() - circle1.center()).normalize()
                new_center1 = circle1.center() + direction.scalar_multiply(space / 2)
                new_center2 = circle2.center() - direction.scalar_multiply(space / 2)
                circle1 = Circle(new_center1, circle1.radius())
                circle2 = Circle(new_center2, circle2.radius())

            d = np.linalg.norm(circle1.center().to_array() - circle2.center().to_array())
            space = d - circle1.radius() - circle2.radius()
            nested = d < abs(circle1.radius() - circle2.radius())

        # Compute intersection points
        a = (circle1.radius()**2 - circle2.radius()**2 + d**2) / (2 * d)
        h = math.sqrt(circle1.radius()**2 - a**2)
        axis = (circle2.center() - circle1.center()).normalize()
        perp = Vector(-axis.y, axis.x)

        return [
            circle1.center() + axis.scalar_multiply(a) + perp.scalar_multiply(h),
            circle1.center() + axis.scalar_multiply(a) - perp.scalar_multiply(h)
        ]

    @staticmethod
    def disk_circle_intersect(disk, circle, max_iterations=10000):
        """
        Finds a valid intersection point between a disk and a circle.
        :return: A point within both the disk and the circle.
        """
        d = np.linalg.norm(disk.center().to_array() - circle.center().to_array())

        # If the circle is inside the disk, pick a random point
        if d < disk.radius() - circle.radius():
            return circle.choose_point(-math.pi, math.pi)

        axis = (disk.center() - circle.center()).normalize()
        points = Circle.circle_circle_intersect(disk, circle)
        delta = np.arccos(np.clip(np.dot(axis.to_array(), (points[0] - circle.center()).normalize().to_array()), -1.0, 1.0))

        for _ in range(max_iterations):
            point = circle.choose_point(-delta, delta)
            if disk.contains(point):
                return point

        # Fallback: broaden search range
        for _ in range(max_iterations):
            point = circle.choose_point(-math.pi, math.pi)
            if disk.contains(point):
                return point
        raise RuntimeError("Failed to find a valid intersection in disk_circle_intersect")

    @staticmethod
    def disk_disk_intersect(disk1, disk2, max_iterations=10000):
        """
        Finds a valid intersection point between two disks.
        :return: A point that lies within both disks.
        """
        d = np.linalg.norm(disk1.center().to_array() - disk2.center().to_array())

        if d < abs(disk1.radius() - disk2.radius()):
            # One disk is inside the other, pick a point in the smaller disk
            inner = disk1 if disk1.radius() < disk2.radius() else disk2
            for _ in range(max_iterations):
                point = Vector(RngUtility.next_double(inner.center().x - inner.radius(), inner.center().x + inner.radius()),
                               RngUtility.next_double(inner.center().y - inner.radius(), inner.center().y + inner.radius()))
                if inner.contains(point):
                    return point
            raise RuntimeError("Failed to find a valid intersection in disk_disk_intersect")

        # Compute intersection points of the two disks
        points = Circle.circle_circle_intersect(disk1, disk2)
        box_height = np.linalg.norm((points[0] - points[1]).to_array())
        box_left = min(d - disk2.radius(), disk1.radius())
        box_right = max(d - disk2.radius(), disk1.radius())

        axis = (disk2.center() - disk1.center()).normalize()
        for _ in range(max_iterations):
            delta = Vector(RngUtility.next_double(box_left, box_right), RngUtility.next_double(-box_height, box_height))
            result = disk1.center() + delta.un_rotate(axis)
            if disk1.contains(result) and disk2.contains(result):
                return result
        raise RuntimeError("Failed to find a valid intersection in disk_disk_intersect")
    
class Fiber:
    class Params:
        def __init__(self, segment_length=10.0, width_change=0.0, n_segments=15, start_width=1.0, straightness=1.0, start=None, end=None, min_angle_change=15, max_angle_change=45):
            self.segment_length = segment_length
            self.width_change = width_change
            self.n_segments = n_segments
            self.start_width = start_width
            self.straightness = straightness
            self.start = start if start else Vector()
            self.end = end if end else Vector()
            self.min_angle_change = min_angle_change
            self.max_angle_change = max_angle_change

        @staticmethod
        def from_dict(params_dict):
            return Fiber.Params(
                segment_length=params_dict.get("segment_length", 10.0),
                width_change=params_dict.get("width_change", 0.0),
                n_segments=params_dict.get("n_segments", 15),
                start_width=params_dict.get("start_width", 1.0),
                straightness=params_dict.get("straightness", 1.0),
                start=Vector(params_dict["start"]["x"], params_dict["start"]["y"], params_dict["start"]["z"]),
                end=Vector(params_dict["end"]["x"], params_dict["end"]["y"], params_dict["end"]["z"]),
                min_angle_change=params_dict("minAngleChange", 15),  # New parameter
                max_angle_change=params_dict("maxAngleChange", 45)   # New parameter
            )

        def to_dict(self):
            return {
                "segment_length": self.segment_length,
                "width_change": self.width_change,
                "n_segments": self.n_segments,
                "start_width": self.start_width,
                "straightness": self.straightness,
                "start": {"x": self.start.x, "y": self.start.y, "z": self.start.z},
                "end": {"x": self.end.x, "y": self.end.y, "z": self.end.z},
                "minAngleChange": self.min_angle_change,  # New parameter
                "maxAngleChange": self.max_angle_change  # New parameter
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
        self.abort_flag = False
        self.has_joint = False

    def __iter__(self):
        return self.SegmentIterator(self.points, self.widths)

    def get_points(self):
        return list(self.points)

    def get_direction(self):
        return (self.params.end.subtract(self.params.start)).normalize()
    
    #basic methodolgy could be refined for more percision 
    def calculate_orientations(self):
        # Initialize arrays to store orientations for each plane
        self.orientations_xy = []
        self.orientations_yz = []
        self.orientations_xz = []

        # Loop through each consecutive point pair in the fiber
        for i in range(len(self.points) - 1):
            # Get the start and end points of the segment
            start_point = self.points[i]
            end_point = self.points[i + 1]

            # Calculate direction vector of the segment
            direction = end_point.subtract(start_point)
            
            # Calculate orientations in each plane and convert to degrees
            angle_xy = np.degrees(np.arctan2(direction.y, direction.x))
            angle_yz = np.degrees(np.arctan2(direction.z, direction.y))
            angle_xz = np.degrees(np.arctan2(direction.z, direction.x))
            
            # Append the computed angles to their respective lists
            self.orientations_xy.append(angle_xy)
            self.orientations_yz.append(angle_yz)
            self.orientations_xz.append(angle_xz)

    def generate(self):
        self.points = RngUtility.random_chain(self.params.start, self.params.end, self.params.n_segments, self.params.segment_length)
        width = self.params.start_width
        for i in range(self.params.n_segments):
            self.widths.append(width)
            variability = min(abs(width), self.params.width_change)
            width += RngUtility.next_double(-variability, variability)
            self.calculate_orientations()  # Calculate orientations after generating points
    
    def generate_3d(self):
        # Reset abort flag at the start of 3D generation
        self.abort_flag = False

        self.points = RngUtility3D.random_chain_3d(
            self.params.start,
            self.params.end,
            self.params.n_segments,
            self.params.segment_length,
            self.params.min_angle_change,  # Min angle change parameter
            self.params.max_angle_change   # Max angle change parameter
        )
        width = self.params.start_width
        self.widths = []

        # Loop to assign widths and calculate orientations
        for i in range(self.params.n_segments):
            if self.abort_flag:
                print("Aborting 3D generation during width assignment...")
                return  # Exit early if abort is requested
            self.widths.append(width)
            variability = min(abs(width), self.params.width_change)
            width += RngUtility.next_double(-variability, variability)
            self.calculate_orientations()
            QCoreApplication.processEvents()  # Process pending UI events

        # Straightness adjustment if required
        if self.params.straightness < 1.0:
            for i in range(1, len(self.points)):
                if self.abort_flag:
                    print("Aborting 3D generation during straightness adjustment...")
                    return
                QCoreApplication.processEvents()
                segment_length = self.points[i].subtract(self.points[i-1]).length()
                straightness_factor = self.params.straightness * segment_length
                direction = self.points[i].subtract(self.points[i-1]).normalize()
                offset = direction.scalar_multiply(straightness_factor)
                self.points[i] = self.points[i-1].add(offset)

    # 3. Add the following method to the Fiber class:
    def abort(self):
        """Sets the abort flag to True, causing generate_3d to stop processing."""
        print("DEBUG: Fiber.abort() called, setting abort_flag to True")
        self.abort_flag = True
        print("Abort flag set for 3D generation.")
        
    def bubble_smooth(self, passes):
        deltas = MiscUtility.to_deltas(self.points)
        for _ in range(passes):
            for j in range(len(deltas) - 1):
                self.try_swap(deltas, j, j + 1)
        self.points = MiscUtility.from_deltas(deltas, self.points[0])
        
    def bubble_smooth_3d(self, passes):
        deltas = MiscUtility3D.to_deltas_3d(self.points)
        for _ in range(passes):
            for j in range(len(deltas) - 1):
                self.try_swap(deltas, j, j + 1)
        self.points = MiscUtility3D.from_deltas_3d(deltas, self.points[0])

    def swap_smooth(self, ratio):
        deltas = MiscUtility.to_deltas(self.points)
        for _ in range(ratio * len(deltas)):
            u = RngUtility.rng.randint(0, len(deltas) - 1)
            v = RngUtility.rng.randint(0, len(deltas) - 1)
            self.try_swap(deltas, u, v)
        self.points = MiscUtility.from_deltas(deltas, self.points[0])
        
    def swap_smooth_3d(self, ratio):
        deltas = MiscUtility3D.to_deltas_3d(self.points)
        for _ in range(ratio * len(deltas)):
            u = RngUtility.rng.randint(0, len(deltas) - 1)
            v = RngUtility.rng.randint(0, len(deltas) - 1)
            self.try_swap(deltas, u, v)
        self.points = MiscUtility3D.from_deltas_3d(deltas, self.points[0])

    def spline_smooth(self, spline_ratio):
        if self.params.n_segments <= 1:
            return

        t_points = np.arange(len(self.points))
        x_points = np.array([p.x for p in self.points])
        y_points = np.array([p.y for p in self.points])
        z_points = np.array([p.z for p in self.points])

        # Check if there are enough points for the default spline degree
        k = 3  # Default degree for cubic splines
        if len(self.points) <= k:
            k = len(self.points) - 1  # Adjust k to be less than the number of points

        # Perform spline interpolation
        tck_x = splrep(t_points, x_points, k=k)
        tck_y = splrep(t_points, y_points, k=k)
        tck_z = splrep(t_points, z_points, k=k)

        new_points = []
        new_widths = []

        for i in range((len(self.points) - 1) * spline_ratio + 1):
            if i % spline_ratio == 0:
                new_points.append(self.points[i // spline_ratio])
            else:
                t = i / spline_ratio
                new_x = float(splev(t, tck_x))
                new_y = float(splev(t, tck_y))
                new_z = float(splev(t, tck_z))
                new_points.append(Vector(new_x, new_y, new_z))

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

    def to_dict(self):
        return {
            "params": self.params.to_dict(),
            "points": [{"x": p.x, "y": p.y, "z": p.z} for p in self.points],
            "widths": self.widths,
            "orientations_xy": self.orientations_xy,
            "orientations_yz": self.orientations_yz,
            "orientations_xz": self.orientations_xz
        }

    @staticmethod
    def from_dict(fiber_dict):
        params = Fiber.Params.from_dict(fiber_dict["params"])
        points = [Vector(p["x"], p["y"], p["z"]) for p in fiber_dict["points"]]
        widths = fiber_dict["widths"]
        fiber = Fiber(params)
        fiber.points = points
        fiber.widths = widths
        return fiber

class FiberImage:
    class Params:
        def __init__(self):
            self.nFibers = Param(value=15, name="number of fibers", hint="The number of fibers per image to generate")
            self.segmentLength = Param(value=10.0, name="segment length", hint="The length in pixels of fiber segments")
            self.alignment = Param(value=0.5, name="alignment", hint="A value between 0 and 1 indicating how close fibers are to the mean angle on average")
            self.meanAngle = Param(value=90.0, name="mean angle", hint="The average fiber angle in degrees")
            self.widthChange = Param(value=0.0, name="width change", hint="The maximum segment-to-segment width change of a fiber in pixels")
            self.imageWidth = Param(value=512, name="image width", hint="The width of the saved image in pixels")
            self.imageHeight = Param(value=512, name="image height", hint="The height of the saved image in pixels")
            self.imageBuffer = Param(value=5, name="edge buffer", hint="The size in pixels of the empty border around the edge of the image")
            self.jointPoints = Param(value=3, name="joint points", hint="The number of joint points to generate")
            self.showJoints = Optional(value=None, name="Show joints", hint="Check to display joint points on the image", use=False)
            self.useJoints = Optional(value=True, name="Use joints", hint="Toggle to use joint point constraints during generation", use=True)


            self.length = Uniform(0.0, float('inf'), 15.0, 200.0)
            self.width = Gaussian(0.0, float('inf'), 5.0, 0.5)
            self.straightness = Uniform(0.0, 1.0, 0.9, 1.0)

            self.scale = Optional(value=5.0, name="scale", hint="Check to draw a scale bar on the image; value is the number of pixels per micron", use=False)
            self.downSample = Optional(value=0.5, name="down sample", hint="Check to enable down sampling; value is the ratio of final size to original size", use=False)
            self.blur = Optional(value=5.0, name="blur", hint="Check to enable Gaussian blurring; value is the radius of the blur in pixels", use=False)
            self.noise = Optional(value=10.0, name="noise", hint="Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)", use=False)
            # New noise configuration
            self.noiseModel = Param(value="No Noise", name="noise model", hint="Noise model to apply (No Noise, Poisson, Gaussian, Salt-and-Pepper, Speckle, Poisson+Gaussian)")
            self.noiseStdDev = Optional(value=10.0, name="noise std dev", hint="Standard deviation for Gaussian noise; used only for Gaussian or Poisson+Gaussian", use=False)
            self.saltPepperProb = Optional(value=0.01, name="salt-and-pepper probability", hint="Probability for Salt-and-Pepper noise; used only for Salt-and-Pepper", use=False)
            self.distance = Optional(value=64.0, name="distance", hint="Check to apply a distance filter; value controls the sharpness of the intensity falloff", use=False)
            self.cap = Optional(value=255, name="cap", hint="Check to cap the intensity; value is the inclusive maximum on a scale of 0-255", use=False)
            self.normalize = Optional(value=255, name="normalize", hint="Check to normalize the intensity; value is the inclusive maximum on a scale of 0-255", use=False)
            self.bubble = Optional(value=10, name="bubble", hint="Check to apply \"bubble smoothing\"; value is the number of passes", use=False)
            self.swap = Optional(value=100, name="swap", hint="Check to apply \"swap smoothing\"; number of swaps is this value times number of segments", use=False)
            self.spline = Optional(value=4, name="spline", hint="Check to enable spline smoothing; value is the number of interpolated points per segment", use=False)
            self.psfEnabled = Optional(value=1.0, name="apply psf", hint="Toggle to convolve the generated image with an optical PSF", use=False)
            self.psfType = Param(value="None", name="psf type", hint="PSF kernel to apply (None, 3D Gaussian, Vectorial (SHG))")
            self.psfGaussianNA = Param(value=1.2, name="gaussian psf NA", hint="Numerical aperture used for the Gaussian PSF approximation")
            self.psfGaussianWavelength = Param(value=0.8, name="gaussian psf wavelength", hint="Excitation wavelength (microns) for Gaussian PSF estimation")
            self.psfPixelSizeZ = Param(value=0.3, name="psf voxel size z", hint="Voxel spacing along Z in microns")
            self.psfPixelSizeY = Param(value=0.2, name="psf voxel size y", hint="Voxel spacing along Y in microns")
            self.psfPixelSizeX = Param(value=0.2, name="psf voxel size x", hint="Voxel spacing along X in microns")
            self.psfVectorialNA = Param(value=1.2, name="vectorial psf NA", hint="Numerical aperture for the vectorial PSF model")
            self.psfVectorialMediumRI = Param(value=1.33, name="medium refractive index", hint="Immersion medium refractive index")
            self.psfVectorialSampleRI = Param(value=1.37, name="sample refractive index", hint="Sample refractive index")
            self.psfVectorialWavelength = Param(value=0.8, name="vectorial psf wavelength", hint="Excitation wavelength (microns) for vectorial PSF")
            self.psfVectorialPolarization = Param(value=0.0, name="polarization angle", hint="Input polarization angle in degrees")
            self.psfVectorialVolumeZ = Param(value=6.0, name="volume size z", hint="Physical PSF extent along Z (microns)")
            self.psfVectorialVolumeY = Param(value=12.0, name="volume size y", hint="Physical PSF extent along Y (microns)")
            self.psfVectorialVolumeX = Param(value=12.0, name="volume size x", hint="Physical PSF extent along X (microns)")
            self.psfVectorialShapeZ = Param(value=33, name="psf samples z", hint="Number of samples along Z for the PSF volume")
            self.psfVectorialShapeY = Param(value=65, name="psf samples y", hint="Number of samples along Y for the PSF volume")
            self.psfVectorialShapeX = Param(value=65, name="psf samples x", hint="Number of samples along X for the PSF volume")

        @staticmethod
        def from_dict(params_dict):
            params = FiberImage.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            params.jointPoints = Param.from_dict(params_dict["jointPoints"])
            params.showJoints = Optional.from_dict(params_dict["showJoints"])
            params.useJoints = Optional.from_dict(params_dict["useJoints"])          
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
            # New noise config
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            params.distance = Optional.from_dict(params_dict["distance"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            if "psfEnabled" in params_dict:
                params.psfEnabled = Optional.from_dict(params_dict["psfEnabled"])
            if "psfType" in params_dict:
                params.psfType = Param.from_dict(params_dict["psfType"])
            if "psfGaussianNA" in params_dict:
                params.psfGaussianNA = Param.from_dict(params_dict["psfGaussianNA"])
            if "psfGaussianWavelength" in params_dict:
                params.psfGaussianWavelength = Param.from_dict(params_dict["psfGaussianWavelength"])
            if "psfPixelSizeZ" in params_dict:
                params.psfPixelSizeZ = Param.from_dict(params_dict["psfPixelSizeZ"])
            if "psfPixelSizeY" in params_dict:
                params.psfPixelSizeY = Param.from_dict(params_dict["psfPixelSizeY"])
            if "psfPixelSizeX" in params_dict:
                params.psfPixelSizeX = Param.from_dict(params_dict["psfPixelSizeX"])
            if "psfVectorialNA" in params_dict:
                params.psfVectorialNA = Param.from_dict(params_dict["psfVectorialNA"])
            if "psfVectorialMediumRI" in params_dict:
                params.psfVectorialMediumRI = Param.from_dict(params_dict["psfVectorialMediumRI"])
            if "psfVectorialSampleRI" in params_dict:
                params.psfVectorialSampleRI = Param.from_dict(params_dict["psfVectorialSampleRI"])
            if "psfVectorialWavelength" in params_dict:
                params.psfVectorialWavelength = Param.from_dict(params_dict["psfVectorialWavelength"])
            if "psfVectorialPolarization" in params_dict:
                params.psfVectorialPolarization = Param.from_dict(params_dict["psfVectorialPolarization"])
            if "psfVectorialVolumeZ" in params_dict:
                params.psfVectorialVolumeZ = Param.from_dict(params_dict["psfVectorialVolumeZ"])
            if "psfVectorialVolumeY" in params_dict:
                params.psfVectorialVolumeY = Param.from_dict(params_dict["psfVectorialVolumeY"])
            if "psfVectorialVolumeX" in params_dict:
                params.psfVectorialVolumeX = Param.from_dict(params_dict["psfVectorialVolumeX"])
            if "psfVectorialShapeZ" in params_dict:
                params.psfVectorialShapeZ = Param.from_dict(params_dict["psfVectorialShapeZ"])
            if "psfVectorialShapeY" in params_dict:
                params.psfVectorialShapeY = Param.from_dict(params_dict["psfVectorialShapeY"])
            if "psfVectorialShapeX" in params_dict:
                params.psfVectorialShapeX = Param.from_dict(params_dict["psfVectorialShapeX"])
            return params

        def to_dict(self):
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "jointPoints": self.jointPoints.to_dict(),
                "showJoints": self.showJoints.to_dict(),
                "useJoints": self.useJoints.to_dict(),
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
                "noiseModel": self.noiseModel.to_dict(),
                "noiseStdDev": self.noiseStdDev.to_dict(),
                "saltPepperProb": self.saltPepperProb.to_dict(),
                "distance": self.distance.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict(),
                "psfEnabled": self.psfEnabled.to_dict(),
                "psfType": self.psfType.to_dict(),
                "psfGaussianNA": self.psfGaussianNA.to_dict(),
                "psfGaussianWavelength": self.psfGaussianWavelength.to_dict(),
                "psfPixelSizeZ": self.psfPixelSizeZ.to_dict(),
                "psfPixelSizeY": self.psfPixelSizeY.to_dict(),
                "psfPixelSizeX": self.psfPixelSizeX.to_dict(),
                "psfVectorialNA": self.psfVectorialNA.to_dict(),
                "psfVectorialMediumRI": self.psfVectorialMediumRI.to_dict(),
                "psfVectorialSampleRI": self.psfVectorialSampleRI.to_dict(),
                "psfVectorialWavelength": self.psfVectorialWavelength.to_dict(),
                "psfVectorialPolarization": self.psfVectorialPolarization.to_dict(),
                "psfVectorialVolumeZ": self.psfVectorialVolumeZ.to_dict(),
                "psfVectorialVolumeY": self.psfVectorialVolumeY.to_dict(),
                "psfVectorialVolumeX": self.psfVectorialVolumeX.to_dict(),
                "psfVectorialShapeZ": self.psfVectorialShapeZ.to_dict(),
                "psfVectorialShapeY": self.psfVectorialShapeY.to_dict(),
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict()
            }

        def set_names(self):
            self.nFibers.set_name("number of fibers")
            self.segmentLength.set_name("segment length")
            self.jointPoints.set_name("joint points")
            self.useJoints.set_name("Use joints")
            self.showJoints.set_name("Show Joints")   
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
            self.noiseModel.set_name("noise model")
            self.noiseStdDev.set_name("noise std dev")
            self.saltPepperProb.set_name("salt-and-pepper probability")
            self.distance.set_name("distance")
            self.cap.set_name("cap")
            self.normalize.set_name("normalize")
            self.bubble.set_name("bubble")
            self.swap.set_name("swap")
            self.spline.set_name("spline")

        def set_hints(self):
            self.nFibers.set_hint("The number of fibers per image to generate")
            self.segmentLength.set_hint("The length in pixels of fiber segments")
            self.jointPoints.set_hint("The number of joint points in the fiber network")
            self.useJoints.set_hint("Toggle to use joint point constraints during generation")
            self.showJoints.set_hint("Check to display joint points on the image")
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
            self.noiseModel.set_hint("Noise model to apply (No Noise, Poisson, Gaussian, Salt-and-Pepper, Speckle, Poisson+Gaussian)")
            self.noiseStdDev.set_hint("Standard deviation for Gaussian noise; used only for Gaussian or Poisson+Gaussian")
            self.saltPepperProb.set_hint("Probability for Salt-and-Pepper noise; used only for Salt-and-Pepper")
            self.distance.set_hint("Check to apply a distance filter; value controls the sharpness of the intensity falloff")
            self.cap.set_hint("Check to cap the intensity; value is the inclusive maximum on a scale of 0-255")
            self.normalize.set_hint("Check to normalize the intensity; value is the inclusive maximum on a scale of 0-255")
            self.bubble.set_hint("Check to apply \"bubble smoothing\"; value is the number of passes")
            self.swap.set_hint("Check to apply \"swap smoothing\"; number of swaps is this value times number of segments")
            self.spline.set_hint("Check to enable spline smoothing; value is the number of interpolated points per segment")
            self.psfEnabled.set_hint("Check to apply an optical PSF prior to adding noise")
            self.psfType.set_hint("PSF kernel to apply (None, 3D Gaussian, Vectorial (SHG))")
            self.psfGaussianNA.set_hint("Numerical aperture for the Gaussian PSF approximation")
            self.psfGaussianWavelength.set_hint("Excitation wavelength (microns) for Gaussian PSF estimation")
            self.psfPixelSizeZ.set_hint("Voxel spacing along Z in microns")
            self.psfPixelSizeY.set_hint("Voxel spacing along Y in microns")
            self.psfPixelSizeX.set_hint("Voxel spacing along X in microns")
            self.psfVectorialNA.set_hint("Numerical aperture for the vectorial PSF model")
            self.psfVectorialMediumRI.set_hint("Immersion medium refractive index")
            self.psfVectorialSampleRI.set_hint("Sample refractive index")
            self.psfVectorialWavelength.set_hint("Excitation wavelength (microns) for the vectorial PSF")
            self.psfVectorialPolarization.set_hint("Linear polarization angle in degrees")
            self.psfVectorialVolumeZ.set_hint("Physical PSF extent along Z (microns)")
            self.psfVectorialVolumeY.set_hint("Physical PSF extent along Y (microns)")
            self.psfVectorialVolumeX.set_hint("Physical PSF extent along X (microns)")
            self.psfVectorialShapeZ.set_hint("Number of samples along Z in the PSF volume")
            self.psfVectorialShapeY.set_hint("Number of samples along Y in the PSF volume")
            self.psfVectorialShapeX.set_hint("Number of samples along X in the PSF volume")

        def verify(self):
            self.nFibers.verify(0, Param.greater)
            self.segmentLength.verify(0.0, Param.greater)
            if self.useJoints.use:
                self.jointPoints.verify(0, Param.greater_eq)
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
            # Validate noise model and related params
            allowed_models = {"no noise", "poisson", "gaussian", "salt-and-pepper", "speckle", "poisson+gaussian"}
            model = str(self.noiseModel.get_value()).lower()
            if model not in allowed_models:
                raise ValueError(f"Value of \"noise model\" must be one of {sorted(list(allowed_models))}")
            if model in {"gaussian", "poisson+gaussian"}:
                if float(self.noiseStdDev.get_value()) <= 0:
                    raise ValueError("Value of \"noise std dev\" must be greater than 0.0")
            if model == "salt-and-pepper":
                p = float(self.saltPepperProb.get_value())
                if p < 0.0 or p > 1.0:
                    raise ValueError("Value of \"salt-and-pepper probability\" must be between 0.0 and 1.0")
            self.distance.verify(0.0, Param.greater)
            self.cap.verify(0, Param.greater_eq)
            self.cap.verify(255, Param.less_eq)
            self.normalize.verify(0, Param.greater_eq)
            self.normalize.verify(255, Param.less_eq)
            self.bubble.verify(0, Param.greater)
            self.swap.verify(0, Param.greater)
            self.spline.verify(0, Param.greater)
            psf_type_value = str(self.psfType.get_value()).strip().lower()
            allowed_psf_types = {"none", "3d gaussian", "vectorial (shg)"}
            if psf_type_value not in allowed_psf_types:
                raise ValueError(f"Value of \"psf type\" must be one of {sorted(list(allowed_psf_types))}")
            self.psfGaussianNA.verify(0.0, Param.greater)
            self.psfGaussianWavelength.verify(0.0, Param.greater)
            self.psfPixelSizeZ.verify(0.0, Param.greater)
            self.psfPixelSizeY.verify(0.0, Param.greater)
            self.psfPixelSizeX.verify(0.0, Param.greater)
            self.psfVectorialNA.verify(0.0, Param.greater)
            self.psfVectorialMediumRI.verify(0.0, Param.greater)
            self.psfVectorialSampleRI.verify(0.0, Param.greater)
            self.psfVectorialWavelength.verify(0.0, Param.greater)
            self.psfVectorialVolumeZ.verify(0.0, Param.greater)
            self.psfVectorialVolumeY.verify(0.0, Param.greater)
            self.psfVectorialVolumeX.verify(0.0, Param.greater)
            self.psfVectorialShapeZ.verify(0, Param.greater)
            self.psfVectorialShapeY.verify(0, Param.greater)
            self.psfVectorialShapeX.verify(0, Param.greater)

    TARGET_SCALE_SIZE = 0.2
    CAP_RATIO = 0.01
    BUFF_RATIO = 0.015

    def __init__(self, params):
        self.params = params
        self.fibers = []
        self.joint_points = []
        self.image = Image.new('L', (params.imageWidth.get_value(), params.imageHeight.get_value()), 0)

    def __iter__(self):
        return iter(self.fibers)
    
    def to_dict(self):
        return {
            "params": self.params.to_dict(),
            "fibers": [fiber.to_dict() for fiber in self.fibers],
            "joint_points": [{"x": point.x, "y": point.y} for point in self.joint_points],
        }
    
    def to_csv_data(self):
        summary_data, segments_data, points_data = [], [], []
        joints_data = [{"Joint ID": idx, "X": jp.x, "Y": jp.y} for idx, jp in enumerate(self.joint_points)]

        # Accumulators for network-level metrics
        all_orient_xy = []  # degrees
        per_fiber_alignment = []
        per_fiber_straightness = []  # morphological straightness
        total_length = 0.0
        all_segment_widths = []

        for idx, fiber in enumerate(self.fibers):
            start = fiber.points[0]
            end = fiber.points[-1]
            mean_width = sum(fiber.widths) / len(fiber.widths) if fiber.widths else 0
            mean_angle = sum(fiber.orientations_xy) / len(fiber.orientations_xy) if fiber.orientations_xy else 0
            std_angle = np.std(fiber.orientations_xy) if fiber.orientations_xy else 0

            # Compute per-fiber path length and morphological straightness
            path_len = 0.0
            for seg_idx in range(len(fiber.points) - 1):
                p0 = fiber.points[seg_idx]
                p1 = fiber.points[seg_idx + 1]
                path_len += p1.subtract(p0).length()
            chord = end.subtract(start).length() if len(fiber.points) >= 2 else 0.0
            straightness_morph = (chord / path_len) if path_len > 0 else 0.0
            per_fiber_straightness.append(straightness_morph)
            total_length += path_len

            # Per-fiber alignment from segment orientations (nematic order parameter)
            if getattr(fiber, 'orientations_xy', None):
                angs = np.deg2rad(np.array(fiber.orientations_xy, dtype=float))
                if angs.size > 0:
                    cmean = np.mean(np.exp(1j * 2.0 * angs))
                    per_fiber_alignment.append(float(np.abs(cmean)))
                    # Accumulate for network
                    all_orient_xy.extend(list(np.array(fiber.orientations_xy, dtype=float)))
            else:
                per_fiber_alignment.append(0.0)

            summary_data.append({
                "Fiber ID": idx,
                "Start X": start.x,
                "Start Y": start.y,
                "End X": end.x,
                "End Y": end.y,
                "Segment Count": fiber.params.n_segments,
                "Segment Length": fiber.params.segment_length,
                "Straightness Param": fiber.params.straightness,
                "Path Length": path_len,
                "Straightness Morph": straightness_morph,
                "Start Width": fiber.params.start_width,
                "Mean Width": mean_width,
                "Mean Angle XY": mean_angle,
                "Std Angle XY": std_angle,
                "Fiber Alignment": (per_fiber_alignment[-1] if per_fiber_alignment else 0.0),
                "Has Joint Point": fiber.has_joint
            })

            for seg_idx in range(len(fiber.points) - 1):
                p0 = fiber.points[seg_idx]
                p1 = fiber.points[seg_idx + 1]
                segments_data.append({
                    "Fiber ID": idx,
                    "Segment Index": seg_idx,
                    "Start X": p0.x,
                    "Start Y": p0.y,
                    "Start Z": p0.z,
                    "End X": p1.x,
                    "End Y": p1.y,
                    "End Z": p1.z,
                    "Width": fiber.widths[seg_idx] if seg_idx < len(fiber.widths) else "",
                    "Orientation XY": fiber.orientations_xy[seg_idx] if seg_idx < len(fiber.orientations_xy) else "",
                    "Orientation YZ": fiber.orientations_yz[seg_idx] if seg_idx < len(fiber.orientations_yz) else "",
                    "Orientation XZ": fiber.orientations_xz[seg_idx] if seg_idx < len(fiber.orientations_xz) else ""
                })
                if seg_idx < len(fiber.widths):
                    all_segment_widths.append(fiber.widths[seg_idx])

            for pt_idx, point in enumerate(fiber.points):
                points_data.append({
                    "Fiber ID": idx,
                    "Point Index": pt_idx,
                    "X": point.x,
                    "Y": point.y,
                    "Z": point.z,
                    "Width": fiber.widths[pt_idx] if pt_idx < len(fiber.widths) else "",
                    "Orientation XY": fiber.orientations_xy[pt_idx] if pt_idx < len(fiber.orientations_xy) else "",
                    "Orientation YZ": fiber.orientations_yz[pt_idx] if pt_idx < len(fiber.orientations_yz) else "",
                    "Orientation XZ": fiber.orientations_xz[pt_idx] if pt_idx < len(fiber.orientations_xz) else ""
                })

        # Compute network-level alignment and mean direction from all segment orientations (if any)
        if len(all_orient_xy) > 0:
            thetas = np.deg2rad(np.array(all_orient_xy, dtype=float))
            cmean = np.mean(np.exp(1j * 2.0 * thetas))
            network_alignment = float(np.abs(cmean))
            mean_dir_rad = 0.5 * float(np.arctan2(cmean.imag, cmean.real))
            network_mean_angle = (np.degrees(mean_dir_rad) + 360.0) % 180.0
        else:
            network_alignment = 0.0
            network_mean_angle = 0.0

        # Alignment score per segment relative to network mean (0..1)
        if len(segments_data) > 0:
            seg_align_scores = []
            for fiber in self.fibers:
                for seg_idx in range(len(fiber.points) - 1):
                    theta_deg = fiber.orientations_xy[seg_idx] if seg_idx < len(fiber.orientations_xy) else None
                    if theta_deg is None:
                        seg_align_scores.append("")
                    else:
                        delta = np.deg2rad(theta_deg - network_mean_angle)
                        score = 0.5 * (1.0 + np.cos(2.0 * delta))
                        seg_align_scores.append(float(score))
            for row, score in zip(segments_data, seg_align_scores):
                row["Alignment Score (0-1)"] = score

        # Compute network-level aggregate metrics
        fiber_count = len(self.fibers)
        segment_count = sum(max(0, len(f.points) - 1) for f in self.fibers)
        img_w = int(self.params.imageWidth.get_value()) if hasattr(self.params, 'imageWidth') else 0
        img_h = int(self.params.imageHeight.get_value()) if hasattr(self.params, 'imageHeight') else 0
        area = float(img_w * img_h) if img_w and img_h else 0.0
        length_density = (total_length / area) if area > 0 else 0.0
        joint_count = len(self.joint_points)
        joint_density = (joint_count / area) if area > 0 else 0.0
        avg_fiber_align = float(np.mean(per_fiber_alignment)) if per_fiber_alignment else 0.0
        std_fiber_align = float(np.std(per_fiber_alignment)) if per_fiber_alignment else 0.0
        avg_straight = float(np.mean(per_fiber_straightness)) if per_fiber_straightness else 0.0
        std_straight = float(np.std(per_fiber_straightness)) if per_fiber_straightness else 0.0
        if all_segment_widths:
            widths_arr = np.array(all_segment_widths, dtype=float)
            avg_width = float(np.mean(widths_arr))
            std_width = float(np.std(widths_arr))
            min_width = float(np.min(widths_arr))
            max_width = float(np.max(widths_arr))
        else:
            avg_width = std_width = min_width = max_width = 0.0
        mean_seg_len = (total_length / segment_count) if segment_count > 0 else 0.0

        network_summary = [{
            "Fiber Count": fiber_count,
            "Segment Count": segment_count,
            "Network Alignment": network_alignment,
            "Network Mean Angle (deg)": network_mean_angle,
            "Avg Fiber Alignment": avg_fiber_align,
            "Std Fiber Alignment": std_fiber_align,
            "Avg Straightness (morph)": avg_straight,
            "Std Straightness (morph)": std_straight,
            "Total Fiber Length (px)": total_length,
            "Image Width (px)": img_w,
            "Image Height (px)": img_h,
            "Image Area (px^2)": area,
            "Length Density (px/px^2)": length_density,
            "Joint Count": joint_count,
            "Joint Density (#/px^2)": joint_density,
            "Avg Segment Width": avg_width,
            "Std Segment Width": std_width,
            "Min Segment Width": min_width,
            "Max Segment Width": max_width,
            "Mean Segment Length (px)": mean_seg_len
        }]

        # Only include parameters that are applied:
        # - Always include non-optional Params (no 'use' flag)
        # - For Optional params, include only when use == True
        # Special handling: include noise model with its parameter values (mean/std/p as appropriate)
        params_dict = self.params.to_dict()
        params_data = []

        # Precompute a descriptive noise model string with values
        noise_model_value = None
        try:
            model_name = str(self.params.noiseModel.get_value()).lower() if hasattr(self.params, 'noiseModel') else 'no noise'
            if model_name == 'poisson':
                if hasattr(self.params, 'noiseMean'):
                    noise_mean = self.params.noiseMean.get_string()
                elif hasattr(self.params, 'noise'):
                    noise_mean = self.params.noise.get_string()
                else:
                    noise_mean = None
                noise_model_value = f"Poisson{f' (mean={noise_mean})' if noise_mean is not None else ''}"
            elif model_name == 'gaussian':
                std = self.params.noiseStdDev.get_string() if hasattr(self.params, 'noiseStdDev') else None
                noise_model_value = f"Gaussian{f' (std={std})' if std is not None else ''}"
            elif model_name == 'salt-and-pepper':
                p = self.params.saltPepperProb.get_string() if hasattr(self.params, 'saltPepperProb') else None
                noise_model_value = f"Salt-and-Pepper{f' (p={p})' if p is not None else ''}"
            elif model_name == 'speckle':
                noise_model_value = 'Speckle'
            elif model_name == 'poisson+gaussian':
                if hasattr(self.params, 'noiseMean'):
                    mean_str = self.params.noiseMean.get_string()
                elif hasattr(self.params, 'noise'):
                    mean_str = self.params.noise.get_string()
                else:
                    mean_str = None
                std_str = self.params.noiseStdDev.get_string() if hasattr(self.params, 'noiseStdDev') else None
                details = []
                if mean_str is not None:
                    details.append(f"mean={mean_str}")
                if std_str is not None:
                    details.append(f"std={std_str}")
                details_str = f" ({', '.join(details)})" if details else ""
                noise_model_value = f"Poisson+Gaussian{details_str}"
            else:
                noise_model_value = 'No Noise'
        except Exception:
            noise_model_value = None

        for k, v in params_dict.items():
            # Special-case noise model: include formatted value with parameters
            if k == 'noiseModel' and noise_model_value is not None:
                params_data.append({"Parameter": k, "Value": noise_model_value})
                continue

            if isinstance(v, dict):
                # Optional param: include only if 'use' is True
                if "use" in v and not v.get("use", False):
                    continue
                # Prefer to show the concrete value if present
                value = v.get("value", v)
            else:
                value = v
            params_data.append({"Parameter": k, "Value": value})

        return (
            pd.DataFrame(network_summary),
            pd.DataFrame(summary_data),
            pd.DataFrame(segments_data),
            pd.DataFrame(points_data),
            pd.DataFrame(joints_data),
            pd.DataFrame(params_data)
        )

    @staticmethod
    def from_dict(fiber_image_dict):
        params = FiberImage.Params.from_dict(fiber_image_dict["params"])
        fiber_image = FiberImage(params)
        fiber_image.fibers = [Fiber.from_dict(fiber_dict) for fiber_dict in fiber_image_dict["fibers"]]
        return fiber_image

    def generate_fibers(self):
        max_iterations = 10000  # Cap to prevent infinite loops

        for _ in range(max_iterations):
            self.fibers = []  # Clear previous fibers
            self.joint_points = []  # Clear previous joint points
            directions = self.generate_directions()

            for direction in directions:
                fiber_params = Fiber.Params()
                fiber_params.segment_length = self.params.segmentLength.get_value()
                fiber_params.width_change = self.params.widthChange.get_value()
                fiber_params.n_segments = max(1, round(self.params.length.sample() / self.params.segmentLength.get_value()))
                fiber_params.straightness = self.params.straightness.sample()
                fiber_params.start_width = self.params.width.sample()

                end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
                fiber_params.start = self.find_fiber_start(end_distance, direction)
                fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

                fiber = Fiber(fiber_params)
                fiber.generate()
                self.fibers.append(fiber)

            # Count and store joints
            joint_points = self.count_joints()
            self.joint_points.extend(joint_points)
            joint_count = len(joint_points)

            if self.params.useJoints.use:
                if joint_count == self.params.jointPoints.get_value():
                    break
            else:
                break  # No joint constraints, exit immediately
        else:
            raise Exception("Failed to generate the desired number of joints.")
        
    def count_joints(self):
        joints = set()  # Use a set to store unique joint points
        for i, fiber1 in enumerate(self.fibers):
            for fiber2 in self.fibers[i + 1:]:
                for seg1 in fiber1:
                    for seg2 in fiber2:
                        # Check if the segments intersect
                        intersection_point = MiscUtility.get_intersection_point(seg1.start, seg1.end, seg2.start, seg2.end)
                        if intersection_point:
                            joints.add(intersection_point)
                            fiber1.has_joint = True
                            fiber2.has_joint = True

                        # Check if the end of seg1 is on seg2, even if not an intersection
                        if MiscUtility.point_on_segment(seg1.end, seg2.start, seg2.end):
                            joints.add(seg1.end)
                            fiber1.has_joint = True
                            fiber2.has_joint = True
                        if MiscUtility.point_on_segment(seg2.end, seg1.start, seg1.end):
                            joints.add(seg2.end)
                            fiber1.has_joint = True
                            fiber2.has_joint = True

        self.joints = joints  # Save the joint points for rendering
        return list(joints)

    def smooth(self):
        for fiber in self.fibers:
            if self.params.bubble.use:
                fiber.bubble_smooth(self.params.bubble.get_value())
            if self.params.swap.use:
                fiber.swap_smooth(self.params.swap.get_value())
            if self.params.spline.use:
                fiber.spline_smooth(self.params.spline.get_value())
            # Refresh orientations after any geometry change
            fiber.calculate_orientations()
        # Recompute joint points after smoothing to reflect updated geometry
        try:
            self.joint_points = self.count_joints()
        except Exception:
            # If recomputation fails, keep previous joints to avoid breaking pipeline
            pass

    def draw_fibers(self):
        draw = ImageDraw.Draw(self.image)
        for fiber in self.fibers:
            for segment in fiber:
                draw.line(
                    [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                    fill=255,
                    width=int(segment.width)
                )
                
        # If show_joints is enabled, draw joint points
        if self.params.showJoints.use:
            for joint in self.joint_points:
                radius = 3  # Adjust the size of the joint point marker
                x, y = joint.x, joint.y
                draw.ellipse([x - radius, y - radius, x + radius, y + radius], outline=255, fill=255)        

    def apply_effects(self):
        if self.params.distance.use:
            self.image = ImageUtility.distance_function(self.image, self.params.distance.get_value())
        self._apply_psf(volume=False)
        # Apply noise based on selected model and its own enable flag(s)
        model = str(self.params.noiseModel.get_value()).lower()
        apply_noise = False
        if model == "poisson":
            apply_noise = self.params.noise.use
        elif model == "gaussian":
            apply_noise = self.params.noiseStdDev.use
        elif model == "salt-and-pepper":
            apply_noise = self.params.saltPepperProb.use
        elif model == "speckle":
            apply_noise = True
        elif model == "poisson+gaussian":
            apply_noise = self.params.noise.use or self.params.noiseStdDev.use
        # "No Noise" or unknown → no noise
        if apply_noise:
            self.add_noise()
        if self.params.blur.use:
            self.image = ImageUtility.gaussian_blur(self.image, self.params.blur.get_value())
        if self.params.scale.use:
            self.draw_scale_bar()
        if self.params.downSample.use:
            self.image = self.image.resize(
                (int(self.image.width * self.params.downSample.get_value()), int(self.image.height * self.params.downSample.get_value())),
                Image.BILINEAR
            )
        if self.params.cap.use:
            self.image = ImageUtility.cap(self.image, self.params.cap.get_value())
        if self.params.normalize.use:
            self.image = ImageUtility.normalize(self.image, self.params.normalize.get_value())

    def get_image(self):
        return self.image.copy()

    def generate_directions(self):
        mean_angle_radians = np.radians(self.params.meanAngle.get_value())        
        mean_direction = Vector(np.cos(mean_angle_radians), np.sin(mean_angle_radians))
        alignment_factor = self.params.alignment.get_value() * self.params.nFibers.get_value()
        sum_vector = mean_direction.scalar_multiply(alignment_factor)
        
        # Generate a random chain of vectors
        chain = RngUtility.random_chain(Vector(), sum_vector, self.params.nFibers.get_value(), 1.0)
        
        # Convert the chain into deltas
        directions = MiscUtility.to_deltas(chain)
        
        # Normalize the directions and add them to output
        output = []
        for direction in directions:
            normalized_direction = direction.normalize()
            output.append(normalized_direction)
        return output

    def find_fiber_start(self, length, direction):
        x_length = direction.normalize().x * length
        y_length = direction.normalize().y * length
        x = self.find_start(x_length, self.params.imageWidth.get_value(), self.params.imageBuffer.get_value())
        y = self.find_start(y_length, self.params.imageHeight.get_value(), self.params.imageBuffer.get_value())
        return Vector(x, y)

    @staticmethod
    def find_start(length, dimension, buffer):
        buffer = max(length / 2, buffer)
        if abs(length) > dimension:
            min_val = max(0, -length)
            max_val = min(dimension, dimension - length)
            return RngUtility.next_double(min_val, max_val)
        if abs(length) > dimension - 2 * buffer:
            buffer = 0
        min_val = max(buffer, buffer - length)
        max_val = min(dimension - buffer - length, dimension - buffer)
        return RngUtility.next_double(min_val, max_val)

    def draw_scale_bar(self):
        target_size = self.TARGET_SCALE_SIZE * self.image.width / self.params.scale.get_value()  
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
        scale_right = x_buff + int(best_size * self.params.scale.get_value())  

        draw = ImageDraw.Draw(self.image)
        draw.line((x_buff, scale_height, scale_right, scale_height), fill=255)
        draw.line((x_buff, scale_height + cap_size, x_buff, scale_height - cap_size), fill=255)
        draw.line((scale_right, scale_height + cap_size, scale_right, scale_height - cap_size), fill=255)
        draw.text((x_buff, scale_height - cap_size - y_buff), label, fill=255)

    def add_noise(self):
        model = str(self.params.noiseModel.get_value()).lower()
        if model == "no noise":
            return
        np_image = np.array(self.image, dtype=np.float32)
        h, w = np_image.shape
        if model == "poisson":
            mean = float(self.params.noise.get_value())
            noise = poisson(mean).rvs(np_image.size).reshape(h, w)
            np_image = np_image + noise
        elif model == "gaussian":
            std = float(self.params.noiseStdDev.get_value())
            noise = np.random.normal(0.0, std, size=(h, w))
            np_image = np_image + noise
        elif model == "salt-and-pepper":
            p = float(self.params.saltPepperProb.get_value())
            rnd = np.random.rand(h, w)
            np_image[rnd < (p / 2.0)] = 0.0
            np_image[rnd > 1.0 - (p / 2.0)] = 255.0
        elif model == "speckle":
            speckle = np.random.normal(1.0, 0.2, size=(h, w))
            np_image = np_image * speckle
        elif model == "poisson+gaussian":
            mean = float(self.params.noise.get_value())
            p_noise = poisson(mean).rvs(np_image.size).reshape(h, w)
            g_std = float(self.params.noiseStdDev.get_value())
            g_noise = np.random.normal(0.0, g_std, size=(h, w))
            np_image = np_image + p_noise + g_noise
        else:
            # Fallback to Poisson if unknown model
            mean = float(self.params.noise.get_value())
            noise = poisson(mean).rvs(np_image.size).reshape(h, w)
            np_image = np_image + noise
        np_image = np.clip(np_image, 0, 255).astype(np.uint8)
        self.image = Image.fromarray(np_image, 'L')

    def _apply_psf(self, volume: bool):
        if not hasattr(self.params, "psfEnabled"):
            return
        manager = PSFManager(self.params)
        if volume:
            data = self.image.astype(np.float32)
        else:
            data = np.array(self.image, dtype=np.float32)
        before_mean = float(data.mean())
        before_std = float(data.std())
        result = manager.apply(data, volume=volume)
        if result is None:
            return
        after_mean = float(result.mean())
        after_std = float(result.std())
        global LAST_PSF_STATS
        LAST_PSF_STATS = {
            "volume": volume,
            "before_mean": before_mean,
            "after_mean": after_mean,
            "before_std": before_std,
            "after_std": after_std,
        }
        if volume:
            self.image = result
        else:
            self.image = Image.fromarray(result, 'L')

class FiberImage3D(FiberImage):
    class Params(FiberImage.Params):
        def __init__(self):
            super().__init__()
            self.imageDepth = Param(value=512, name="image depth", hint="The depth of the saved volume in pixels")
            self.curvature = Param(value=1.0, name="curvature", hint="The curvature of fibers in 3D")
            self.branchingProbability = Param(value=0.1, name="branching probability", hint="The probability of fibers branching")
            self.meanDirection = Param(value=[0.0, 0.0, 1.0], name="mean direction", hint="The average fiber direction as a 3D vector")
            self.blurRadius = Optional(value=5.0, name="blur radius", hint="Check to enable Gaussian blurring; value is the radius of the blur in pixels", use=False)
            self.noiseMean = Optional(value=10.0, name="noise mean", hint="Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)", use=False)
            self.distanceFalloff = Optional(value=64.0, name="distance falloff", hint="Check to apply a distance filter; value controls the sharpness of the intensity falloff", use=False)
            self.alignment3D = Param(value=0.5, name="alignment", hint="A value between 0 and 1 indicating how close fibers are to the mean direction on average")
            self.min_angle_change = Param(value=15.0, name="min angle change", hint="Minimum angle change in degrees")
            self.max_angle_change = Param(value=45.0, name="max angle change", hint="Maximum angle change in degrees")
            
        @staticmethod
        def from_dict(params_dict):
            params = FiberImage3D.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            params.alignment3D = Param.from_dict(params_dict["alignment3D"])
            params.meanDirection = Param.from_dict(params_dict["meanDirection"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageDepth = Param.from_dict(params_dict["imageDepth"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            params.length = Uniform.from_dict(params_dict["length"])
            params.width = Gaussian.from_dict(params_dict["width"])
            params.straightness = Uniform.from_dict(params_dict["straightness"])
            params.curvature = Param.from_dict(params_dict["curvature"])
            params.branchingProbability = Param.from_dict(params_dict["branchingProbability"])
            params.scale = Optional.from_dict(params_dict["scale"])
            params.downSample = Optional.from_dict(params_dict["downSample"])
            params.blurRadius = Optional.from_dict(params_dict["blurRadius"])
            params.noiseMean = Optional.from_dict(params_dict["noiseMean"])
            params.distanceFalloff = Optional.from_dict(params_dict["distanceFalloff"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            params.min_angle_change = Param.from_dict(params_dict["minAngleChange"])
            params.max_angle_change = Param.from_dict(params_dict["maxAngleChange"])
            # Noise model additions
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            if "psfEnabled" in params_dict:
                params.psfEnabled = Optional.from_dict(params_dict["psfEnabled"])
            if "psfType" in params_dict:
                params.psfType = Param.from_dict(params_dict["psfType"])
            if "psfGaussianNA" in params_dict:
                params.psfGaussianNA = Param.from_dict(params_dict["psfGaussianNA"])
            if "psfGaussianWavelength" in params_dict:
                params.psfGaussianWavelength = Param.from_dict(params_dict["psfGaussianWavelength"])
            if "psfPixelSizeZ" in params_dict:
                params.psfPixelSizeZ = Param.from_dict(params_dict["psfPixelSizeZ"])
            if "psfPixelSizeY" in params_dict:
                params.psfPixelSizeY = Param.from_dict(params_dict["psfPixelSizeY"])
            if "psfPixelSizeX" in params_dict:
                params.psfPixelSizeX = Param.from_dict(params_dict["psfPixelSizeX"])
            if "psfVectorialNA" in params_dict:
                params.psfVectorialNA = Param.from_dict(params_dict["psfVectorialNA"])
            if "psfVectorialMediumRI" in params_dict:
                params.psfVectorialMediumRI = Param.from_dict(params_dict["psfVectorialMediumRI"])
            if "psfVectorialSampleRI" in params_dict:
                params.psfVectorialSampleRI = Param.from_dict(params_dict["psfVectorialSampleRI"])
            if "psfVectorialWavelength" in params_dict:
                params.psfVectorialWavelength = Param.from_dict(params_dict["psfVectorialWavelength"])
            if "psfVectorialPolarization" in params_dict:
                params.psfVectorialPolarization = Param.from_dict(params_dict["psfVectorialPolarization"])
            if "psfVectorialVolumeZ" in params_dict:
                params.psfVectorialVolumeZ = Param.from_dict(params_dict["psfVectorialVolumeZ"])
            if "psfVectorialVolumeY" in params_dict:
                params.psfVectorialVolumeY = Param.from_dict(params_dict["psfVectorialVolumeY"])
            if "psfVectorialVolumeX" in params_dict:
                params.psfVectorialVolumeX = Param.from_dict(params_dict["psfVectorialVolumeX"])
            if "psfVectorialShapeZ" in params_dict:
                params.psfVectorialShapeZ = Param.from_dict(params_dict["psfVectorialShapeZ"])
            if "psfVectorialShapeY" in params_dict:
                params.psfVectorialShapeY = Param.from_dict(params_dict["psfVectorialShapeY"])
            if "psfVectorialShapeX" in params_dict:
                params.psfVectorialShapeX = Param.from_dict(params_dict["psfVectorialShapeX"])
            return params

        def to_dict(self):
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "alignment3D": self.alignment3D.to_dict(),
                "meanDirection": self.meanDirection.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageDepth": self.imageDepth.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "curvature": self.curvature.to_dict(),
                "branchingProbability": self.branchingProbability.to_dict(),
                "scale": self.scale.to_dict(),
                "downSample": self.downSample.to_dict(),
                "blurRadius": self.blurRadius.to_dict(),
                "noiseMean": self.noiseMean.to_dict(),
                "noiseModel": self.noiseModel.to_dict(),
                "noiseStdDev": self.noiseStdDev.to_dict(),
                "saltPepperProb": self.saltPepperProb.to_dict(),
                "distanceFalloff": self.distanceFalloff.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict(),
                "psfEnabled": self.psfEnabled.to_dict(),
                "psfType": self.psfType.to_dict(),
                "psfGaussianNA": self.psfGaussianNA.to_dict(),
                "psfGaussianWavelength": self.psfGaussianWavelength.to_dict(),
                "psfPixelSizeZ": self.psfPixelSizeZ.to_dict(),
                "psfPixelSizeY": self.psfPixelSizeY.to_dict(),
                "psfPixelSizeX": self.psfPixelSizeX.to_dict(),
                "psfVectorialNA": self.psfVectorialNA.to_dict(),
                "psfVectorialMediumRI": self.psfVectorialMediumRI.to_dict(),
                "psfVectorialSampleRI": self.psfVectorialSampleRI.to_dict(),
                "psfVectorialWavelength": self.psfVectorialWavelength.to_dict(),
                "psfVectorialPolarization": self.psfVectorialPolarization.to_dict(),
                "psfVectorialVolumeZ": self.psfVectorialVolumeZ.to_dict(),
                "psfVectorialVolumeY": self.psfVectorialVolumeY.to_dict(),
                "psfVectorialVolumeX": self.psfVectorialVolumeX.to_dict(),
                "psfVectorialShapeZ": self.psfVectorialShapeZ.to_dict(),
                "psfVectorialShapeY": self.psfVectorialShapeY.to_dict(),
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict()
            }

        def set_names(self):
            super().set_names()
            self.imageDepth.set_name("image depth")
            self.curvature.set_name("curvature")
            self.branchingProbability.set_name("branching probability")
            self.meanDirection.set_name("mean direction")
            self.blurRadius.set_name("blur radius")
            self.noiseMean.set_name("noise mean")
            self.distanceFalloff.set_name("distance falloff")
            self.alignment3D.set_name("alignment")
            self.min_angle_change.set_name("min angle change")  # New
            self.max_angle_change.set_name("max angle change")  # New

        def set_hints(self):
            super().set_hints()
            self.imageDepth.set_hint("The depth of the saved volume in pixels")
            self.curvature.set_hint("The curvature of fibers in 3D")
            self.branchingProbability.set_hint("The probability of fibers branching")
            self.meanDirection.set_hint("The average fiber direction as a 3D vector")
            self.blurRadius.set_hint("Check to enable Gaussian blurring; value is the radius of the blur in pixels")
            self.noiseMean.set_hint("Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)")
            self.distanceFalloff.set_hint("Check to apply a distance filter; value controls the sharpness of the intensity falloff")
            self.alignment3D.set_hint("A value between 0 and 1 indicating how close fibers are to the mean direction on average")
            self.min_angle_change.set_hint("Minimum angle change between segments in degrees")  # New
            self.max_angle_change.set_hint("Maximum angle change between segments in degrees")  # New

        def verify(self):
            super().verify()
            self.imageDepth.verify(0, Param.greater)
            self.curvature.verify(0.0, Param.greater_eq)
            self.branchingProbability.verify(0.0, Param.greater_eq)
            self.branchingProbability.verify(1.0, Param.less_eq)
            self.meanDirection.verify(0.0, Param.greater_eq)
            self.meanDirection.verify(1.0, Param.less_eq)
            self.blurRadius.verify(0.0, Param.greater_eq)
            self.noiseMean.verify(0.0, Param.greater_eq)
            self.distanceFalloff.verify(0.0, Param.greater_eq)
            self.min_angle_change.verify(0.0, Param.greater_eq)
            self.min_angle_change.verify(180.0, Param.less_eq)
            self.max_angle_change.verify(0.0, Param.greater_eq)
            self.max_angle_change.verify(180.0, Param.less_eq)

    def __init__(self, params):
        super().__init__(params)
        self.image = np.zeros((params.imageDepth.get_value(), params.imageHeight.get_value(), params.imageWidth.get_value()), dtype=np.uint8)
        
    def bresenham_3d(x1, y1, z1, x2, y2, z2):
        points = []
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        dz = abs(z2 - z1)
        xs = 1 if x2 > x1 else -1
        ys = 1 if y2 > y1 else -1
        zs = 1 if z2 > z1 else -1

        # Driving axis is X-axis
        if dx >= dy and dx >= dz:
            p1 = 2 * dy - dx
            p2 = 2 * dz - dx
            while x1 != x2:
                x1 += xs
                if p1 >= 0:
                    y1 += ys
                    p1 -= 2 * dx
                if p2 >= 0:
                    z1 += zs
                    p2 -= 2 * dx
                p1 += 2 * dy
                p2 += 2 * dz
                points.append((x1, y1, z1))

        # Driving axis is Y-axis
        elif dy >= dx and dy >= dz:
            p1 = 2 * dx - dy
            p2 = 2 * dz - dy
            while y1 != y2:
                y1 += ys
                if p1 >= 0:
                    x1 += xs
                    p1 -= 2 * dy
                if p2 >= 0:
                    z1 += zs
                    p2 -= 2 * dy
                p1 += 2 * dx
                p2 += 2 * dz
                points.append((x1, y1, z1))

        # Driving axis is Z-axis
        else:
            p1 = 2 * dy - dz
            p2 = 2 * dx - dz
            while z1 != z2:
                z1 += zs
                if p1 >= 0:
                    y1 += ys
                    p1 -= 2 * dz
                if p2 >= 0:
                    x1 += xs
                    p2 -= 2 * dz
                p1 += 2 * dy
                p2 += 2 * dx
                points.append((x1, y1, z1))

        return points
        
    @staticmethod
    def find_start_3d(length, dimension, buffer):
        buffer = max(length / 2, buffer)
        if abs(length) > dimension:
            min_val = max(0, -length)
            max_val = min(dimension, dimension - length)
            return RngUtility.next_double(min_val, max_val)
        if abs(length) > dimension - 2 * buffer:
            buffer = 0
        min_val = max(buffer, buffer - length)
        max_val = min(dimension - buffer - length, dimension - buffer)
        return RngUtility.next_double(min_val, max_val)
    
    def find_fiber_start_3d(self, length, direction):
        x_length = direction.normalize().x * length
        y_length = direction.normalize().y * length
        z_length = direction.normalize().z * length
        x = self.find_start_3d(x_length, self.params.imageWidth.get_value(), self.params.imageBuffer.get_value())
        y = self.find_start_3d(y_length, self.params.imageHeight.get_value(), self.params.imageBuffer.get_value())
        z = self.find_start_3d(z_length, self.params.imageDepth.get_value(), self.params.imageBuffer.get_value())
        return Vector(x, y, z)
    
    def generate_directions_3d(self):
        mean_direction = Vector(*self.params.meanDirection.get_value())
        alignment_factor = self.params.alignment3D.get_value() * self.params.nFibers.get_value()
        sum_vector = mean_direction.scalar_multiply(alignment_factor)

        # Generate a random chain of vectors
        chain = RngUtility3D.random_chain_3d(Vector(), sum_vector, self.params.nFibers.get_value(), 1.0, self.params.min_angle_change.get_value(), self.params.max_angle_change.get_value())

        # Convert the chain into deltas
        directions = MiscUtility3D.to_deltas_3d(chain)

        # Normalize the directions and add them to output
        output = []
        for direction in directions:
            normalized_direction = direction.normalize()
            output.append(normalized_direction)
        return output
    
    def generate_fibers_3d(self, abort_check=None):
        directions = self.generate_directions_3d()

        for direction in directions:
            fiber_params = Fiber.Params()

            fiber_params.segment_length = self.params.segmentLength.get_value()
            fiber_params.width_change = self.params.widthChange.get_value()

            fiber_params.n_segments = max(1, round(self.params.length.sample() / self.params.segmentLength.get_value()))
            fiber_params.straightness = self.params.straightness.sample()
            fiber_params.start_width = self.params.width.sample()

            end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
            fiber_params.start = self.find_fiber_start_3d(end_distance, direction)
            fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

            fiber = Fiber(fiber_params)
            fiber.generate_3d()
            self.fibers.append(fiber)
    
    def smooth_3d(self):
        for fiber in self.fibers:
            if self.params.bubble.use:
                fiber.bubble_smooth_3d(self.params.bubble.get_value())
            if self.params.swap.use:
                fiber.swap_smooth_3d(self.params.swap.get_value())
            if self.params.spline.use:
                fiber.spline_smooth(self.params.spline.get_value())
            # Refresh orientations after any geometry change
            fiber.calculate_orientations()
        # Recompute joint points after smoothing to reflect updated geometry
        try:
            self.joint_points = self.count_joints()
        except Exception:
            pass
                
    def add_noise_3d(self):
        model = str(self.params.noiseModel.get_value()).lower()
        if model == "no noise":
            return
        img = self.image.astype(np.float32)
        if model == "poisson":
            mean = float(self.params.noiseMean.get_value())
            noise = poisson(mean).rvs(img.size).reshape(img.shape)
            img = img + noise
        elif model == "gaussian":
            std = float(self.params.noiseStdDev.get_value())
            noise = np.random.normal(0.0, std, size=img.shape)
            img = img + noise
        elif model == "salt-and-pepper":
            p = float(self.params.saltPepperProb.get_value())
            rnd = np.random.rand(*img.shape)
            img[rnd < (p / 2.0)] = 0.0
            img[rnd > 1.0 - (p / 2.0)] = 255.0
        elif model == "speckle":
            speckle = np.random.normal(1.0, 0.2, size=img.shape)
            img = img * speckle
        elif model == "poisson+gaussian":
            mean = float(self.params.noiseMean.get_value())
            p_noise = poisson(mean).rvs(img.size).reshape(img.shape)
            g_std = float(self.params.noiseStdDev.get_value())
            g_noise = np.random.normal(0.0, g_std, size=img.shape)
            img = img + p_noise + g_noise
        else:
            mean = float(self.params.noiseMean.get_value())
            noise = poisson(mean).rvs(img.size).reshape(img.shape)
            img = img + noise
        self.image = np.clip(img, 0, 255).astype(np.uint8)

    def apply_effects_3d(self):
        if self.params.distance.use:
            self.image = ImageUtility3D.distance_function_3d(self.image, self.params.distance.get_value())
        self._apply_psf(volume=True)
        # Apply noise based on selected model and its own enable flag(s)
        model = str(self.params.noiseModel.get_value()).lower()
        apply_noise = False
        if model == "poisson":
            apply_noise = self.params.noiseMean.use
        elif model == "gaussian":
            apply_noise = self.params.noiseStdDev.use
        elif model == "salt-and-pepper":
            apply_noise = self.params.saltPepperProb.use
        elif model == "speckle":
            apply_noise = True
        elif model == "poisson+gaussian":
            apply_noise = self.params.noiseMean.use or self.params.noiseStdDev.use
        if apply_noise:
            self.add_noise_3d()
        if self.params.blur.use:
            self.image = ImageUtility3D.gaussian_blur_3d(self.image, self.params.blur.get_value())
        if self.params.scale.use:
            self.draw_scale_bar_3d()
        if self.params.downSample.use:
            self.image = self.image[::int(1/self.params.downSample.get_value()), ::int(1/self.params.downSample.get_value()), ::int(1/self.params.downSample.get_value())]
        if self.params.cap.use:
            self.image = ImageUtility3D.cap_3d(self.image, self.params.cap.get_value())
        if self.params.normalize.use:
            self.image = ImageUtility3D.normalize_3d(self.image, self.params.normalize.get_value())

    def get_image(self):
        return self.image

    # 3D-specific CSV export: extend parent with depth/volume metrics
    def to_csv_data(self):
        network_df, summary_df, segments_df, points_df, joints_df, params_df = super().to_csv_data()
        try:
            depth = int(self.params.imageDepth.get_value()) if hasattr(self.params, 'imageDepth') else 0
        except Exception:
            depth = 0
        if not network_df.empty:
            try:
                network_df.loc[0, 'Image Depth (px)'] = depth
                width = float(network_df.loc[0, 'Image Width (px)']) if 'Image Width (px)' in network_df.columns else 0.0
                height = float(network_df.loc[0, 'Image Height (px)']) if 'Image Height (px)' in network_df.columns else 0.0
                volume = width * height * depth
                network_df.loc[0, 'Image Volume (px^3)'] = volume
                total_len = float(network_df.loc[0, 'Total Fiber Length (px)']) if 'Total Fiber Length (px)' in network_df.columns else 0.0
                network_df.loc[0, 'Length Density (px/px^3)'] = (total_len / volume) if volume > 0 else 0.0
            except Exception:
                pass
        return network_df, summary_df, segments_df, points_df, joints_df, params_df

class ImageCollection:
    class Params(FiberImage.Params):
        def __init__(self):
            super().__init__()
            self.nImages = Param(value=1, name="number of images", hint="The number of images to generate")
            self.seed = Optional(value=1, name="seed", hint="Check to fix the random seed; value is the seed", use=True)

        @staticmethod
        def from_dict(params_dict):
            params = ImageCollection.Params()
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
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            params.distance = Optional.from_dict(params_dict["distance"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            if "psfEnabled" in params_dict:
                params.psfEnabled = Optional.from_dict(params_dict["psfEnabled"])
            if "psfType" in params_dict:
                params.psfType = Param.from_dict(params_dict["psfType"])
            if "psfGaussianNA" in params_dict:
                params.psfGaussianNA = Param.from_dict(params_dict["psfGaussianNA"])
            if "psfGaussianWavelength" in params_dict:
                params.psfGaussianWavelength = Param.from_dict(params_dict["psfGaussianWavelength"])
            if "psfPixelSizeZ" in params_dict:
                params.psfPixelSizeZ = Param.from_dict(params_dict["psfPixelSizeZ"])
            if "psfPixelSizeY" in params_dict:
                params.psfPixelSizeY = Param.from_dict(params_dict["psfPixelSizeY"])
            if "psfPixelSizeX" in params_dict:
                params.psfPixelSizeX = Param.from_dict(params_dict["psfPixelSizeX"])
            if "psfVectorialNA" in params_dict:
                params.psfVectorialNA = Param.from_dict(params_dict["psfVectorialNA"])
            if "psfVectorialMediumRI" in params_dict:
                params.psfVectorialMediumRI = Param.from_dict(params_dict["psfVectorialMediumRI"])
            if "psfVectorialSampleRI" in params_dict:
                params.psfVectorialSampleRI = Param.from_dict(params_dict["psfVectorialSampleRI"])
            if "psfVectorialWavelength" in params_dict:
                params.psfVectorialWavelength = Param.from_dict(params_dict["psfVectorialWavelength"])
            if "psfVectorialPolarization" in params_dict:
                params.psfVectorialPolarization = Param.from_dict(params_dict["psfVectorialPolarization"])
            if "psfVectorialVolumeZ" in params_dict:
                params.psfVectorialVolumeZ = Param.from_dict(params_dict["psfVectorialVolumeZ"])
            if "psfVectorialVolumeY" in params_dict:
                params.psfVectorialVolumeY = Param.from_dict(params_dict["psfVectorialVolumeY"])
            if "psfVectorialVolumeX" in params_dict:
                params.psfVectorialVolumeX = Param.from_dict(params_dict["psfVectorialVolumeX"])
            if "psfVectorialShapeZ" in params_dict:
                params.psfVectorialShapeZ = Param.from_dict(params_dict["psfVectorialShapeZ"])
            if "psfVectorialShapeY" in params_dict:
                params.psfVectorialShapeY = Param.from_dict(params_dict["psfVectorialShapeY"])
            if "psfVectorialShapeX" in params_dict:
                params.psfVectorialShapeX = Param.from_dict(params_dict["psfVectorialShapeX"])
            params.nImages = Param.from_dict(params_dict["nImages"])
            params.seed = Optional.from_dict(params_dict["seed"])
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
                "noiseModel": self.noiseModel.to_dict(),
                "noiseStdDev": self.noiseStdDev.to_dict(),
                "saltPepperProb": self.saltPepperProb.to_dict(),
                "distance": self.distance.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict(),
                "psfEnabled": self.psfEnabled.to_dict(),
                "psfType": self.psfType.to_dict(),
                "psfGaussianNA": self.psfGaussianNA.to_dict(),
                "psfGaussianWavelength": self.psfGaussianWavelength.to_dict(),
                "psfPixelSizeZ": self.psfPixelSizeZ.to_dict(),
                "psfPixelSizeY": self.psfPixelSizeY.to_dict(),
                "psfPixelSizeX": self.psfPixelSizeX.to_dict(),
                "psfVectorialNA": self.psfVectorialNA.to_dict(),
                "psfVectorialMediumRI": self.psfVectorialMediumRI.to_dict(),
                "psfVectorialSampleRI": self.psfVectorialSampleRI.to_dict(),
                "psfVectorialWavelength": self.psfVectorialWavelength.to_dict(),
                "psfVectorialPolarization": self.psfVectorialPolarization.to_dict(),
                "psfVectorialVolumeZ": self.psfVectorialVolumeZ.to_dict(),
                "psfVectorialVolumeY": self.psfVectorialVolumeY.to_dict(),
                "psfVectorialVolumeX": self.psfVectorialVolumeX.to_dict(),
                "psfVectorialShapeZ": self.psfVectorialShapeZ.to_dict(),
                "psfVectorialShapeY": self.psfVectorialShapeY.to_dict(),
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict(),
                "nImages": self.nImages.to_dict(),
                "seed": self.seed.to_dict()
            }

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

    def generate_images(self, abort_check=None):
        if self.params.seed.use:
            RngUtility.rng.seed(self.params.seed.value)
            np.random.seed(self.params.seed.value)

        self.image_stack.clear()
        for i in range(self.params.nImages.get_value()):
            if abort_check and abort_check():
                break
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

class ImageCollection3D(ImageCollection):
    class Params(FiberImage3D.Params):
        def __init__(self):
            super().__init__()
            self.nImages = Param(value=1, name="number of images", hint="The number of images to generate")
            self.seed = Optional(value=1, name="seed", hint="Check to fix the random seed; value is the seed", use=True)
            self.minAngleChange = Param(value=15.0, name="min angle change", hint="Minimum angle change in degrees")
            self.maxAngleChange = Param(value=45.0, name="max angle change", hint="Maximum angle change in degrees")

        @staticmethod
        def from_dict(params_dict):
            params = ImageCollection3D.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            params.alignment3D = Param.from_dict(params_dict["alignment3D"])
            params.meanDirection = Param.from_dict(params_dict["meanDirection"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageDepth = Param.from_dict(params_dict["imageDepth"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            params.length = Uniform.from_dict(params_dict["length"])
            params.width = Gaussian.from_dict(params_dict["width"])
            params.straightness = Uniform.from_dict(params_dict["straightness"])
            params.curvature = Param.from_dict(params_dict["curvature"])
            params.branchingProbability = Param.from_dict(params_dict["branchingProbability"])
            params.scale = Optional.from_dict(params_dict["scale"])
            params.downSample = Optional.from_dict(params_dict["downSample"])
            params.blurRadius = Optional.from_dict(params_dict["blurRadius"])
            params.noiseMean = Optional.from_dict(params_dict["noiseMean"])
            params.noiseModel = Param.from_dict(params_dict["noiseModel"]) if "noiseModel" in params_dict else Param("No Noise")
            params.noiseStdDev = Optional.from_dict(params_dict["noiseStdDev"]) if "noiseStdDev" in params_dict else Optional(10.0, use=False)
            params.saltPepperProb = Optional.from_dict(params_dict["saltPepperProb"]) if "saltPepperProb" in params_dict else Optional(0.01, use=False)
            params.distanceFalloff = Optional.from_dict(params_dict["distanceFalloff"])
            params.cap = Optional.from_dict(params_dict["cap"])
            params.normalize = Optional.from_dict(params_dict["normalize"])
            params.bubble = Optional.from_dict(params_dict["bubble"])
            params.swap = Optional.from_dict(params_dict["swap"])
            params.spline = Optional.from_dict(params_dict["spline"])
            params.nImages = Param.from_dict(params_dict["nImages"])
            params.seed = Optional.from_dict(params_dict["seed"])
            params.minAngleChange = Param.from_dict(params_dict["minAngleChange"])
            params.maxAngleChange = Param.from_dict(params_dict["maxAngleChange"])
            if "psfEnabled" in params_dict:
                params.psfEnabled = Optional.from_dict(params_dict["psfEnabled"])
            if "psfType" in params_dict:
                params.psfType = Param.from_dict(params_dict["psfType"])
            if "psfGaussianNA" in params_dict:
                params.psfGaussianNA = Param.from_dict(params_dict["psfGaussianNA"])
            if "psfGaussianWavelength" in params_dict:
                params.psfGaussianWavelength = Param.from_dict(params_dict["psfGaussianWavelength"])
            if "psfPixelSizeZ" in params_dict:
                params.psfPixelSizeZ = Param.from_dict(params_dict["psfPixelSizeZ"])
            if "psfPixelSizeY" in params_dict:
                params.psfPixelSizeY = Param.from_dict(params_dict["psfPixelSizeY"])
            if "psfPixelSizeX" in params_dict:
                params.psfPixelSizeX = Param.from_dict(params_dict["psfPixelSizeX"])
            if "psfVectorialNA" in params_dict:
                params.psfVectorialNA = Param.from_dict(params_dict["psfVectorialNA"])
            if "psfVectorialMediumRI" in params_dict:
                params.psfVectorialMediumRI = Param.from_dict(params_dict["psfVectorialMediumRI"])
            if "psfVectorialSampleRI" in params_dict:
                params.psfVectorialSampleRI = Param.from_dict(params_dict["psfVectorialSampleRI"])
            if "psfVectorialWavelength" in params_dict:
                params.psfVectorialWavelength = Param.from_dict(params_dict["psfVectorialWavelength"])
            if "psfVectorialPolarization" in params_dict:
                params.psfVectorialPolarization = Param.from_dict(params_dict["psfVectorialPolarization"])
            if "psfVectorialVolumeZ" in params_dict:
                params.psfVectorialVolumeZ = Param.from_dict(params_dict["psfVectorialVolumeZ"])
            if "psfVectorialVolumeY" in params_dict:
                params.psfVectorialVolumeY = Param.from_dict(params_dict["psfVectorialVolumeY"])
            if "psfVectorialVolumeX" in params_dict:
                params.psfVectorialVolumeX = Param.from_dict(params_dict["psfVectorialVolumeX"])
            if "psfVectorialShapeZ" in params_dict:
                params.psfVectorialShapeZ = Param.from_dict(params_dict["psfVectorialShapeZ"])
            if "psfVectorialShapeY" in params_dict:
                params.psfVectorialShapeY = Param.from_dict(params_dict["psfVectorialShapeY"])
            if "psfVectorialShapeX" in params_dict:
                params.psfVectorialShapeX = Param.from_dict(params_dict["psfVectorialShapeX"])
            return params

        def to_dict(self):
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "alignment3D": self.alignment3D.to_dict(),
                "meanDirection": self.meanDirection.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageDepth": self.imageDepth.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "curvature": self.curvature.to_dict(),
                "branchingProbability": self.branchingProbability.to_dict(),
                "scale": self.scale.to_dict(),
                "downSample": self.downSample.to_dict(),
                "blurRadius": self.blurRadius.to_dict(),
                "noiseMean": self.noiseMean.to_dict(),
                "noiseModel": self.noiseModel.to_dict(),
                "noiseStdDev": self.noiseStdDev.to_dict(),
                "saltPepperProb": self.saltPepperProb.to_dict(),
                "distanceFalloff": self.distanceFalloff.to_dict(),
                "cap": self.cap.to_dict(),
                "normalize": self.normalize.to_dict(),
                "bubble": self.bubble.to_dict(),
                "swap": self.swap.to_dict(),
                "spline": self.spline.to_dict(),
                "nImages": self.nImages.to_dict(),
                "seed": self.seed.to_dict(),
                "minAngleChange": self.minAngleChange.to_dict(),
                "maxAngleChange": self.maxAngleChange.to_dict(),
                "psfEnabled": self.psfEnabled.to_dict(),
                "psfType": self.psfType.to_dict(),
                "psfGaussianNA": self.psfGaussianNA.to_dict(),
                "psfGaussianWavelength": self.psfGaussianWavelength.to_dict(),
                "psfPixelSizeZ": self.psfPixelSizeZ.to_dict(),
                "psfPixelSizeY": self.psfPixelSizeY.to_dict(),
                "psfPixelSizeX": self.psfPixelSizeX.to_dict(),
                "psfVectorialNA": self.psfVectorialNA.to_dict(),
                "psfVectorialMediumRI": self.psfVectorialMediumRI.to_dict(),
                "psfVectorialSampleRI": self.psfVectorialSampleRI.to_dict(),
                "psfVectorialWavelength": self.psfVectorialWavelength.to_dict(),
                "psfVectorialPolarization": self.psfVectorialPolarization.to_dict(),
                "psfVectorialVolumeZ": self.psfVectorialVolumeZ.to_dict(),
                "psfVectorialVolumeY": self.psfVectorialVolumeY.to_dict(),
                "psfVectorialVolumeX": self.psfVectorialVolumeX.to_dict(),
                "psfVectorialShapeZ": self.psfVectorialShapeZ.to_dict(),
                "psfVectorialShapeY": self.psfVectorialShapeY.to_dict(),
                "psfVectorialShapeX": self.psfVectorialShapeX.to_dict()
            }

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
        self.image_stack: List[FiberImage3D] = []

    def generate_images_3d(self, abort_check=None):
        if self.params.seed.use:
            RngUtility.rng.seed(self.params.seed.value)
            np.random.seed(self.params.seed.value)

        self.image_stack.clear()
        for i in range(self.params.nImages.get_value()):
            if abort_check and abort_check():
                break
            image = FiberImage3D(self.params)
            image.generate_fibers_3d(abort_check=abort_check)
            image.smooth_3d()
            image.apply_effects_3d()
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
        np_image = np.array(image).astype(np.float32)
        np_image = np_image / np_image.max() * max_value
        return Image.fromarray(np.clip(np_image, 0, max_value).astype(np.uint8))

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

class ImageUtility3D(ImageUtility):

    @staticmethod
    def distance_function_3d(image, falloff):
        input_array = np.array(image)
        output_array = np.zeros_like(input_array)

        for z in range(output_array.shape[0]):
            for y in range(output_array.shape[1]):
                for x in range(output_array.shape[2]):
                    if input_array[z, y, x] == 0:
                        output_array[z, y, x] = 0
                    else:
                        min_dist = ImageUtility3D.background_dist_3d(input_array, x, y, z)
                        output_array[z, y, x] = min(255, int(min_dist * falloff) if min_dist > 0 else 255)

        return output_array

    @staticmethod
    def gaussian_blur_3d(image, radius):
        input_array = np.array(image)
        output_array = gaussian_filter(input_array, sigma=radius / 3.0)
        return output_array

    @staticmethod
    def background_dist_3d(image_array, x, y, z):
        r_max = int(np.sqrt(image_array.shape[0]**2 + image_array.shape[1]**2 + image_array.shape[2]**2)) + 1
        found = False
        min_dist = np.inf
        for r in range(DIST_SEARCH_STEP, r_max, DIST_SEARCH_STEP):
            if found:
                break
            x_min, x_max = max(0, x - r), min(image_array.shape[2], x + r)
            y_min, y_max = max(0, y - r), min(image_array.shape[1], y + r)
            z_min, z_max = max(0, z - r), min(image_array.shape[0], z + r)
            for z_in in range(z_min, z_max):
                for y_in in range(y_min, y_max):
                    for x_in in range(x_min, x_max):
                        if image_array[z_in, y_in, x_in] > 0:
                            continue
                        dist = np.sqrt((x_in - x) ** 2 + (y_in - y) ** 2 + (z_in - z) ** 2)
                        if dist <= r and dist < min_dist:
                            found = True
                            min_dist = dist
        return min_dist

    @staticmethod
    def normalize_3d(image, max_value):
        np_image = np.array(image).astype(np.float32)
        np_image = np_image / np_image.max() * max_value
        return np.clip(np_image, 0, max_value).astype(np.uint8)

    @staticmethod
    def cap_3d(image, max_value):
        input_array = np.array(image)
        output_array = np.clip(input_array, 0, max_value)
        return output_array

    @staticmethod
    def zero_pad_3d(image, pad):
        return np.pad(image, pad, mode='constant', constant_values=0)

class IOManager:
    DATA_PREFIX = "2d_data_"
    IMAGE_PREFIX = "2d_image_"
    IMAGE_EXT = "tiff"

    def __init__(self):
        self.serializer = json.JSONEncoder(indent=4)
        self.deserializer = json.JSONDecoder()
        
    @staticmethod
    def save_csv(fiber_image, base_filename):
        import openpyxl

        network_df, summary_df, segments_df, points_df, joints_df, params_df = fiber_image.to_csv_data()

        # Build a Definitions sheet describing sheets and columns
        def_rows = []
        def add(sheet, field, desc):
            def_rows.append({"Sheet": sheet, "Field": field, "Description": desc})

        # Sheet-level descriptions
        add("Network Summary", "(sheet)", "Global network metrics: alignment, straightness, densities, size.")
        add("Fiber Summary", "(sheet)", "Per-fiber properties including path length, straightness, alignment.")
        add("Fiber Segments", "(sheet)", "Per-segment endpoints, widths, orientations, alignment score.")
        add("Fiber Points", "(sheet)", "Per-point coordinates and per-point orientation/width where available.")
        add("Joint Points", "(sheet)", "Detected joint/intersection coordinates in pixels.")
        add("Generation Parameters", "(sheet)", "Parameters applied to generate/post-process this image.")

        # Network Summary fields
        add("Network Summary", "Fiber Count", "Total number of fibers in the image.")
        add("Network Summary", "Segment Count", "Total number of segments across all fibers.")
        add("Network Summary", "Network Alignment", "Nematic order parameter |mean exp(i·2θ)| over all segments (0–1).")
        add("Network Summary", "Network Mean Angle (deg)", "Dominant network orientation in degrees, range [0, 180).")
        add("Network Summary", "Avg Fiber Alignment", "Average of per-fiber alignment scores (nematic, 0–1).")
        add("Network Summary", "Std Fiber Alignment", "Standard deviation of per-fiber alignment.")
        add("Network Summary", "Avg Straightness (morph)", "Mean chord/path straightness across fibers (0–1).")
        add("Network Summary", "Std Straightness (morph)", "Standard deviation of morphological straightness.")
        add("Network Summary", "Total Fiber Length (px)", "Sum of all segment lengths in pixels.")
        add("Network Summary", "Image Width (px)", "Image width in pixels.")
        add("Network Summary", "Image Height (px)", "Image height in pixels.")
        add("Network Summary", "Image Area (px^2)", "Image area = width × height (pixels squared).")
        add("Network Summary", "Length Density (px/px^2)", "Total fiber length divided by image area.")
        add("Network Summary", "Joint Count", "Number of detected joints (segment intersections or shared endpoints).")
        add("Network Summary", "Joint Density (#/px^2)", "Joint count divided by image area.")
        add("Network Summary", "Avg Segment Width", "Mean of segment widths.")
        add("Network Summary", "Std Segment Width", "Standard deviation of segment widths.")
        add("Network Summary", "Min Segment Width", "Minimum segment width.")
        add("Network Summary", "Max Segment Width", "Maximum segment width.")
        add("Network Summary", "Mean Segment Length (px)", "Average length of segments in pixels.")

        # Fiber Summary fields
        add("Fiber Summary", "Fiber ID", "Zero-based index of the fiber.")
        add("Fiber Summary", "Start X", "X coordinate of the first point (px).")
        add("Fiber Summary", "Start Y", "Y coordinate of the first point (px).")
        add("Fiber Summary", "End X", "X coordinate of the last point (px).")
        add("Fiber Summary", "End Y", "Y coordinate of the last point (px).")
        add("Fiber Summary", "Segment Count", "Number of segments in the fiber.")
        add("Fiber Summary", "Segment Length", "Nominal segment length used during generation (px).")
        add("Fiber Summary", "Straightness Param", "Generator straightness parameter sampled for the fiber (input).")
        add("Fiber Summary", "Path Length", "Sum of segment lengths along the fiber (px).")
        add("Fiber Summary", "Straightness Morph", "Chord length divided by path length (0–1).")
        add("Fiber Summary", "Start Width", "Starting width parameter for the fiber (px).")
        add("Fiber Summary", "Mean Width", "Average segment width within the fiber (px).")
        add("Fiber Summary", "Mean Angle XY", "Mean segment orientation in the XY plane (deg).")
        add("Fiber Summary", "Std Angle XY", "Standard deviation of XY orientations (deg).")
        add("Fiber Summary", "Fiber Alignment", "|mean exp(i·2θ)| computed over this fiber’s segments (0–1).")
        add("Fiber Summary", "Has Joint Point", "True if any segment participates in a joint.")

        # Fiber Segments fields
        add("Fiber Segments", "Fiber ID", "Zero-based index of the fiber containing this segment.")
        add("Fiber Segments", "Segment Index", "Zero-based index of the segment within the fiber.")
        add("Fiber Segments", "Start X", "X coordinate of segment start (px).")
        add("Fiber Segments", "Start Y", "Y coordinate of segment start (px).")
        add("Fiber Segments", "Start Z", "Z coordinate (0 in 2D; slice index in 3D).")
        add("Fiber Segments", "End X", "X coordinate of segment end (px).")
        add("Fiber Segments", "End Y", "Y coordinate of segment end (px).")
        add("Fiber Segments", "End Z", "Z coordinate (0 in 2D; slice index in 3D).")
        add("Fiber Segments", "Width", "Segment width (px).")
        add("Fiber Segments", "Orientation XY", "Orientation in XY plane (deg).")
        add("Fiber Segments", "Orientation YZ", "Orientation in YZ plane (deg; 3D only).")
        add("Fiber Segments", "Orientation XZ", "Orientation in XZ plane (deg; 3D only).")
        add("Fiber Segments", "Alignment Score (0-1)", "Segment alignment vs network mean: 0.5·(1+cos(2·Δθ)).")

        # Fiber Points fields
        add("Fiber Points", "Fiber ID", "Zero-based index of the fiber containing this point.")
        add("Fiber Points", "Point Index", "Zero-based index of the point within the fiber.")
        add("Fiber Points", "X", "X coordinate (px).")
        add("Fiber Points", "Y", "Y coordinate (px).")
        add("Fiber Points", "Z", "Z coordinate (0 in 2D; slice index in 3D).")
        add("Fiber Points", "Width", "Width value at this point, if available (px).")
        add("Fiber Points", "Orientation XY", "Orientation at this point in XY plane (deg).")
        add("Fiber Points", "Orientation YZ", "Orientation at this point in YZ plane (deg; 3D only).")
        add("Fiber Points", "Orientation XZ", "Orientation at this point in XZ plane (deg; 3D only).")

        # Joint Points fields
        add("Joint Points", "Joint ID", "Zero-based index of the joint.")
        add("Joint Points", "X", "X coordinate of the joint (px).")
        add("Joint Points", "Y", "Y coordinate of the joint (px).")

        # Generation Parameters fields
        add("Generation Parameters", "Parameter", "Name of applied parameter; optionals included only when enabled.")
        add("Generation Parameters", "Value", "Parameter value; noise model row includes its mean/std/prob as applicable.")
        add("Generation Parameters", "psfEnabled", "Boolean flag; True when PSF convolution is applied to the generated image.")
        add("Generation Parameters", "psfType", "String selecting the PSF model: None, 3D Gaussian, or Vectorial (SHG).")
        add("Generation Parameters", "psfGaussianNA", "Numerical aperture used for the approximate Gaussian PSF kernel.")
        add("Generation Parameters", "psfGaussianWavelength", "Excitation wavelength in microns for Gaussian PSF estimation.")
        add("Generation Parameters", "psfPixelSizeZ", "Voxel spacing along Z (microns) for Gaussian PSF sampling.")
        add("Generation Parameters", "psfPixelSizeY", "Voxel spacing along Y (microns) for Gaussian PSF sampling.")
        add("Generation Parameters", "psfPixelSizeX", "Voxel spacing along X (microns) for Gaussian PSF sampling.")
        add("Generation Parameters", "psfVectorialNA", "Numerical aperture used when generating the vectorial PSF kernel.")
        add("Generation Parameters", "psfVectorialMediumRI", "Immersion medium refractive index for the vectorial PSF model.")
        add("Generation Parameters", "psfVectorialSampleRI", "Sample refractive index assumed by the vectorial PSF model.")
        add("Generation Parameters", "psfVectorialWavelength", "Excitation wavelength in microns for the vectorial PSF model.")
        add("Generation Parameters", "psfVectorialPolarization", "Linear polarization angle in degrees used by the vectorial PSF.")
        add("Generation Parameters", "psfVectorialVolumeZ", "Physical PSF extent along Z (microns) for vectorial simulations.")
        add("Generation Parameters", "psfVectorialVolumeY", "Physical PSF extent along Y (microns) for vectorial simulations.")
        add("Generation Parameters", "psfVectorialVolumeX", "Physical PSF extent along X (microns) for vectorial simulations.")
        add("Generation Parameters", "psfVectorialShapeZ", "Number of samples along Z in the vectorial PSF volume.")
        add("Generation Parameters", "psfVectorialShapeY", "Number of samples along Y in the vectorial PSF volume.")
        add("Generation Parameters", "psfVectorialShapeX", "Number of samples along X in the vectorial PSF volume.")

        definitions_df = pd.DataFrame(def_rows)

        with pd.ExcelWriter(f"{base_filename}.xlsx", engine='openpyxl') as writer:
            # Order matters: write Network Summary first (Definitions added last)
            network_df.to_excel(writer, sheet_name="Network Summary", index=False)
            summary_df.to_excel(writer, sheet_name="Fiber Summary", index=False)
            segments_df.to_excel(writer, sheet_name="Fiber Segments", index=False)
            points_df.to_excel(writer, sheet_name="Fiber Points", index=False)
            joints_df.to_excel(writer, sheet_name="Joint Points", index=False)
            params_df.to_excel(writer, sheet_name="Generation Parameters", index=False)
            definitions_df.to_excel(writer, sheet_name="Definitions", index=False)

            sheets_map = {
                "Network Summary": network_df,
                "Fiber Summary": summary_df,
                "Fiber Segments": segments_df,
                "Fiber Points": points_df,
                "Joint Points": joints_df,
                "Generation Parameters": params_df,
                "Definitions": definitions_df
            }

            for sheet_name, df in sheets_map.items():
                worksheet = writer.sheets[sheet_name]
                # Freeze top row
                worksheet.freeze_panes = worksheet['A2']
                # Adjust column widths
                for idx, col in enumerate(df.columns, 1):  # 1-based indexing
                    max_length = max(
                        df[col].astype(str).map(len).max() if not df.empty else 0,
                        len(col)
                    ) + 2  # Add a little extra padding
                    worksheet.column_dimensions[openpyxl.utils.get_column_letter(idx)].width = max_length

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
             # Also save as Excel (.xlsx)
            xlsx_prefix = os.path.join(out_folder, f"{self.DATA_PREFIX}{i}")
            self.save_csv(collection.get(i), xlsx_prefix)

    def write_string_file(self, filename: str, contents: str):
        with open(filename, 'w') as file:
            try:
                file.write(contents)
            except IOError:
                raise IOError(f"Error while writing \"{filename}\"")

    def write_image_file(self, prefix: str, image):
        filename = f"{prefix}.{self.IMAGE_EXT}"
        try:
            tiff.imwrite(filename, image)
        except IOError:
            raise IOError(f"Error while writing \"{filename}\"")

class IOManager3D(IOManager):
    DATA_PREFIX = "3d_data_"

    def read_params_file(self, filename: str):
        with open(filename, 'r') as file:
            try:
                params_dict = self.deserializer.decode(file.read())
                params = ImageCollection3D.Params.from_dict(params_dict)
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
        out_folder = os.path.join(out_folder)
        if not os.path.exists(out_folder):
            os.makedirs(out_folder)
        
        self.write_string_file(os.path.join(out_folder, "params.json"), json.dumps(params.to_dict(), indent=4))
        
        for i in range(collection.size()):
            data_filename = os.path.join(out_folder, f"{self.DATA_PREFIX}{i}.json")
            self.write_string_file(data_filename, json.dumps(collection.get(i).to_dict(), indent=4))

    def save_napari_3d_image(self, viewer, prefix, base_shape=None):
        # Ensure the viewer is in 3D mode
        viewer.dims.ndisplay = 3

        # Establish base 3D array shape (Z, Y, X)
        base = None
        if '3D Image' in viewer.layers:
            image_layer = viewer.layers['3D Image']
            image_data = image_layer.data
            if isinstance(image_data, np.ndarray):
                base = image_data
            else:
                base = np.asarray(image_data)
            if base.ndim == 2:
                base = base[np.newaxis, ...]
            if base.ndim != 3:
                base = None
        if base is None:
            if base_shape is not None:
                base = np.zeros(tuple(base_shape), dtype=np.uint8)
            else:
                # Fallback: infer from shapes extents
                max_x = max_y = max_z = 0
                for layer in viewer.layers:
                    if getattr(layer, 'name', '') in ('Fibers',) or getattr(layer, 'name', '').startswith('Fiber'):
                        for fiber in list(layer.data):
                            coords = np.asarray(fiber)
                            if coords.ndim == 2 and coords.shape[1] == 3:
                                max_x = max(max_x, int(np.ceil(coords[:, 0].max())))
                                max_y = max(max_y, int(np.ceil(coords[:, 1].max())))
                                max_z = max(max_z, int(np.ceil(coords[:, 2].max())))
                if max_x <= 0 or max_y <= 0 or max_z <= 0:
                    return  # nothing to save
                base = np.zeros((max_z + 1, max_y + 1, max_x + 1), dtype=np.uint8)

        # Create an empty 3D array for the composite image and add base intensity
        composite_image = np.zeros(base.shape, dtype=np.uint8)
        composite_image += np.clip(base, 0, 255).astype(np.uint8)

        # Add the fiber data to the composite image
        for layer in viewer.layers:
            if not hasattr(layer, 'data'):
                continue
            if layer.name == 'Fibers' or layer.name.startswith('Fiber'):
                fiber_data = layer.data
                # fiber_data can be a list or ndarray of shape (N, 2, 3)
                for fiber in list(fiber_data):
                    coords = np.asarray(fiber).astype(int)
                    if coords.ndim != 2 or coords.shape[1] != 3:
                        continue
                    for i in range(len(coords) - 1):
                        x1, y1, z1 = coords[i]
                        x2, y2, z2 = coords[i + 1]
                        line_points = FiberImage3D.bresenham_3d(x1, y1, z1, x2, y2, z2)
                        for x, y, z in line_points:
                            if 0 <= x < composite_image.shape[2] and 0 <= y < composite_image.shape[1] and 0 <= z < composite_image.shape[0]:
                                composite_image[z, y, x] = 255

        # Save the composite image as a multi-page TIFF file
        tiff_file = f"{prefix}.tiff"
        tiff.imwrite(tiff_file, composite_image, imagej=True)

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

class GenerationWorker(QThread):
    generation_finished = pyqtSignal(object, object)
    generation_failed = pyqtSignal(str)

    def __init__(self, is_3d_mode, params, io_manager, out_folder):
        super().__init__()
        self.is_3d_mode = is_3d_mode
        self.params = params
        self.io_manager = io_manager
        self.out_folder = out_folder
        self.abort_requested = False

    def run(self):
        try:
            if self.is_3d_mode:
                collection = ImageCollection3D(self.params)
                collection.generate_images_3d(abort_check=self.abort_requested_check)
            else:
                collection = ImageCollection(self.params)
                collection.generate_images(abort_check=self.abort_requested_check)

            if not self.abort_requested:
                # Manual save: do not auto-write results here. Emit collection for UI.
                self.generation_finished.emit(collection, None)
            else:
                self.generation_finished.emit(None, "Generation aborted.")

        except Exception as e:
            self.generation_failed.emit(str(e))

    def abort(self):
        self.abort_requested = True
        
    def abort_requested_check(self):
        QApplication.processEvents()
        return self.abort_requested
    
class MainWindow(QMainWindow):
    IMAGE_DISPLAY_SIZE = 512
    DEFAULTS_FILE_2D = "defaults_2d.json"
    DEFAULTS_FILE_3D = "defaults_3d.json"

    def __init__(self):
        super().__init__()

        # Path setup
        script_dir = os.path.dirname(os.path.abspath(__file__))
        self.DEFAULTS_FILE_2D = os.path.join(script_dir, self.DEFAULTS_FILE_2D)
        self.DEFAULTS_FILE_3D = os.path.join(script_dir, self.DEFAULTS_FILE_3D)
        self.out_folder_2d = os.path.join(script_dir, "output_2d")
        self.out_folder_3d = os.path.join(script_dir, "output_3d")

        self.setWindowTitle("Fiber Generator")
        self.io_manager_2d = IOManager()
        self.io_manager_3d = IOManager3D()

        self.out_folder = self.out_folder_2d
        self.is_3d_mode = False
        self.abort_requested = False  # <--- New flag

        try:
            self.params_2d = self.io_manager_2d.read_params_file(self.DEFAULTS_FILE_2D)
            self.params_3d = self.io_manager_3d.read_params_file(self.DEFAULTS_FILE_3D)
            self.params = self.params_2d
        except Exception as e:
            self.show_error(str(e))
            self.params_2d = ImageCollection.Params()
            self.params_3d = ImageCollection3D.Params()
            self.params = self.params_2d

        self.collection = None
        self.display_index = 0
        self.scene = None

        # Guard flag to suppress redraws during UI mode switches
        self._suspend_redraw = False

        self.init_gui()
        self.display_params()

    def init_gui(self):
        self.setGeometry(100, 100, 800, 600)
        self.setFixedSize(1200, 700)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)

        main_layout = QGridLayout(central_widget)

        # Create display frame
        display_frame = QFrame(self)
        display_layout = QVBoxLayout(display_frame)

        # Add the display frame to the main layout
        main_layout.addWidget(display_frame, 0, 0, 4, 1)

        # Create horizontal layout to center the display stack left to right in left panel
        horizontal_layout = QHBoxLayout()
        left_spacer = QSpacerItem(400, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
        right_spacer = QSpacerItem(400, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
        horizontal_layout.addSpacerItem(left_spacer)

        # Create a QStackedWidget to hold both 2D and 3D displays
        self.display_stack = QStackedWidget(self)
        self.image_display_2d = self.create_image_display_2d(display_frame)
        self.image_display_3d = self.create_image_display_3d(display_frame)
        self.display_stack.addWidget(self.image_display_2d)
        self.display_stack.addWidget(self.image_display_3d)

        # Add the display stack to the horizontal layout
        horizontal_layout.addWidget(self.display_stack)
        horizontal_layout.addSpacerItem(right_spacer)

        # Add the horizontal layout to the vertical display layout
        display_layout.addLayout(horizontal_layout)

        # Add vertical spacers to center the display vertically
        top_spacer = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
        bottom_spacer = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
        display_layout.insertSpacerItem(0, top_spacer)
        display_layout.addSpacerItem(bottom_spacer)
        # Create and add tabs
        tab_widget = QTabWidget()
        main_layout.addWidget(tab_widget, 0, 1)

        session_tab = QWidget()
        fiber_tab = QWidget()
        post_processing_tab = QWidget()
        advanced_post_tab = QWidget()

        tab_widget.addTab(session_tab, "Session")
        tab_widget.addTab(fiber_tab, "Fiber Network")
        tab_widget.addTab(post_processing_tab, "Post-Processing")
        tab_widget.addTab(advanced_post_tab, "Advanced Post-Processing")

        # Create buttons below the display area
        self.generate_button = QPushButton("Generate...", self)
        self.mode_toggle_button = QPushButton("Switch to 3D Mode", self)
        self.reset_button = QPushButton("Reset", self)
        main_layout.addWidget(self.mode_toggle_button, 1, 1)
        main_layout.addWidget(self.reset_button, 2, 1)
        main_layout.addWidget(self.generate_button, 3, 1)
        
        self.abort_button = QPushButton("Abort", self) 
        self.abort_button.setEnabled(False)
        main_layout.addWidget(self.abort_button, 4, 1)

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

        # Manual save button under Previous/Next row on the left panel
        self.save_results_button = QPushButton("Save...", self)
        self.save_results_button.setEnabled(False)
        self.save_results_button.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        display_layout.addWidget(self.save_results_button)

        # Session tab components
        session_layout = QVBoxLayout(session_tab)
        session_tab.setLayout(session_layout)

        image_config_frame = QGroupBox("Image Configuration", session_tab)
        image_config_layout = QGridLayout(image_config_frame)
        session_layout.addWidget(image_config_frame)

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

        session_controls_frame = QGroupBox("Session Controls", session_tab)
        session_controls_layout = QGridLayout(session_controls_frame)
        session_layout.addWidget(session_controls_frame)

        session_controls_layout.addWidget(QLabel("Parameters:"), 0, 0)
        self.load_button = QPushButton("Open...", session_controls_frame)
        session_controls_layout.addWidget(self.load_button, 0, 1)

        self.output_location_label = QLabel("Output location:")
        session_controls_layout.addWidget(self.output_location_label, 1, 0, 1, 2)
        self.save_button = QPushButton("Open...", session_controls_frame)
        session_controls_layout.addWidget(self.save_button, 1, 1)

        session_controls_layout.addWidget(QLabel("Number of images:"), 2, 0)
        self.n_images_field = QLineEdit(session_controls_frame)
        session_controls_layout.addWidget(self.n_images_field, 2, 1)

        self.seed_check = QCheckBox("Seed:", session_controls_frame)
        session_controls_layout.addWidget(self.seed_check, 3, 0)
        self.seed_field = QLineEdit(session_controls_frame)
        session_controls_layout.addWidget(self.seed_field, 3, 1)


        # Fiber network tab components
        fiber_layout = QVBoxLayout(fiber_tab)
        fiber_tab.setLayout(fiber_layout)

        distribution_frame = QGroupBox("Distributions", fiber_tab)
        distribution_layout = QGridLayout(distribution_frame)
        fiber_layout.addWidget(distribution_frame)

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
        
        # Checkbox for toggling joint points markers
        self.show_joints_checkbox = QCheckBox("Show joint points", values_frame)
        values_layout.addWidget(self.show_joints_checkbox, 5, 2)
        self.show_joints_checkbox.stateChanged.connect(self.redraw_image)
        # Checkbox for "Use joints"
        self.use_joints_checkbox = QCheckBox("Use joints", values_frame)
        values_layout.addWidget(self.use_joints_checkbox, 5, 3)
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

        # Post-processing tab components
        post_processing_layout = QVBoxLayout(post_processing_tab)
        post_processing_tab.setLayout(post_processing_layout)

        noise_frame = QGroupBox("Noise", post_processing_tab)
        noise_layout = QGridLayout(noise_frame)
        post_processing_layout.addWidget(noise_frame)

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
        self.noise_check.stateChanged.connect(self.redraw_image)

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

        blur_frame = QGroupBox("Blur & Downsampling", post_processing_tab)
        blur_layout = QGridLayout(blur_frame)
        post_processing_layout.addWidget(blur_frame)

        self.blur_label = QLabel("Blur:")
        self.blur_check = QCheckBox("", blur_frame)
        self.blur_field = QLineEdit(blur_frame)
        blur_layout.addWidget(self.blur_label, 0, 0)
        blur_layout.addWidget(self.blur_check, 0, 1)
        blur_layout.addWidget(self.blur_field, 0, 2)
        self.blur_check.stateChanged.connect(self.redraw_image)

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
        self.sample_check.stateChanged.connect(self.redraw_image)

        intensity_frame = QGroupBox("Intensity & Scaling", post_processing_tab)
        intensity_layout = QGridLayout(intensity_frame)
        post_processing_layout.addWidget(intensity_frame)

        self.scale_label = QLabel("Scale:")
        self.scale_check = QCheckBox("", intensity_frame)
        self.scale_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.scale_label, 0, 0)
        intensity_layout.addWidget(self.scale_check, 0, 1)
        intensity_layout.addWidget(self.scale_field, 0, 2)
        self.scale_check.stateChanged.connect(self.redraw_image)

        intensity_layout.addWidget(QLabel("Normalize:"), 1, 0)
        self.normalize_check = QCheckBox("", intensity_frame)
        intensity_layout.addWidget(self.normalize_check, 1, 1)
        self.normalize_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.normalize_field, 1, 2)
        self.normalize_check.stateChanged.connect(self.redraw_image)

        intensity_layout.addWidget(QLabel("Cap:"), 2, 0)
        self.cap_check = QCheckBox("", intensity_frame)
        intensity_layout.addWidget(self.cap_check, 2, 1)
        self.cap_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.cap_field, 2, 2)
        self.cap_check.stateChanged.connect(self.redraw_image)

        self.distance_label = QLabel("Distance:")
        self.distance_check = QCheckBox("", intensity_frame)
        self.distance_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.distance_label, 3, 0)
        intensity_layout.addWidget(self.distance_check, 3, 1)
        intensity_layout.addWidget(self.distance_field, 3, 2)
        self.distance_check.stateChanged.connect(self.redraw_image)

        self.distance_falloff_label = QLabel("Distance Falloff:")
        self.distance_falloff_check = QCheckBox("", intensity_frame)
        self.distance_falloff_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.distance_falloff_label, 4, 0)
        intensity_layout.addWidget(self.distance_falloff_check, 4, 1)
        intensity_layout.addWidget(self.distance_falloff_field, 4, 2)

        smoothing_frame = QGroupBox("Smoothing", post_processing_tab)
        smoothing_layout = QGridLayout(smoothing_frame)
        post_processing_layout.addWidget(smoothing_frame)

        smoothing_layout.addWidget(QLabel("Bubble:"), 0, 0)
        self.bubble_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.bubble_check, 0, 1)
        self.bubble_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.bubble_field, 0, 2)
        self.bubble_check.stateChanged.connect(self.redraw_image)

        smoothing_layout.addWidget(QLabel("Swap:"), 1, 0)
        self.swap_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.swap_check, 1, 1)
        self.swap_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.swap_field, 1, 2)
        self.swap_check.stateChanged.connect(self.redraw_image)

        smoothing_layout.addWidget(QLabel("Spline:"), 2, 0)
        self.spline_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.spline_check, 2, 1)
        self.spline_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.spline_field, 2, 2)
        self.spline_check.stateChanged.connect(self.redraw_image)

        self.mode_toggle_button.clicked.connect(self.toggle_mode)
        self.generate_button.clicked.connect(self.generate_pressed)
        self.abort_button.clicked.connect(self.abort_pressed)
        self.reset_button.clicked.connect(self.reset_pressed)
        self.prev_button.clicked.connect(self.prev_pressed)
        self.next_button.clicked.connect(self.next_pressed)
        self.load_button.clicked.connect(self.load_pressed)
        self.save_button.clicked.connect(self.save_pressed)
        self.save_results_button.clicked.connect(self.save_results_pressed)
        self.length_button.clicked.connect(self.length_pressed)
        self.width_button.clicked.connect(self.width_pressed)
        self.straight_button.clicked.connect(self.straight_pressed)
        self.noise_model_combo.currentIndexChanged.connect(self.on_noise_model_changed)
        self.noise_std_check.stateChanged.connect(self.redraw_image)
        self.saltpepper_check.stateChanged.connect(self.redraw_image)

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

        self.apply_psf_checkbox.stateChanged.connect(self.update_psf_controls_visibility)
        self.psf_type_combo.currentIndexChanged.connect(self.update_psf_controls_visibility)
        self.preview_psf_button.clicked.connect(self.preview_psf_kernel)
        self.update_psf_controls_visibility()

        self.update_ui_mode()

    def update_image_counter(self):
        """Update the image counter label (e.g., 1/10)."""
        if self.collection is not None and self.collection.size() > 0:
            self.image_counter_label.setText(f"{self.display_index + 1}/{self.collection.size()}")
        else:
            self.image_counter_label.setText("0/0")

    def toggle_mode(self):
        # Prevent auto-redraw while switching and updating controls
        self._suspend_redraw = True

        self.is_3d_mode = not self.is_3d_mode
        if self.is_3d_mode:
            self.params = self.params_3d
            self.out_folder = self.out_folder_3d
            self.mode_toggle_button.setText("Switch to 2D Mode")
            self.display_stack.setCurrentWidget(self.image_display_3d)
            self.viewer.window._qt_window.show()
        else:
            self.params = self.params_2d
            self.out_folder = self.out_folder_2d
            self.mode_toggle_button.setText("Switch to 3D Mode")
            self.display_stack.setCurrentWidget(self.image_display_2d)
            self.viewer.window._qt_window.hide()

        # Update UI for the new mode
        self.update_ui_mode()
        self.display_params()
        self.update_image_counter()

        # Clear both viewers so switching modes shows an empty canvas
        self.clear_mode_views()

        # Re-enable redraw for future changes
        self._suspend_redraw = False

    def clear_mode_views(self):
        """Clear both the 2D and 3D viewers when switching modes."""
        # Clear napari layers (3D)
        try:
            if hasattr(self, 'viewer') and self.viewer is not None:
                self.viewer.layers.clear()
        except Exception:
            pass

        # Reset the 2D display to the help text
        if hasattr(self, 'image_display_2d') and self.image_display_2d is not None:
            try:
                self.image_display_2d.clear()
                self.image_display_2d.setText("Press \"Generate\" to view 2D images")
            except Exception:
                pass

    def create_image_display_2d(self, parent):
        label = QLabel(parent)
        label.setText("Press \"Generate\" to view 2D images")
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        label.setStyleSheet("background-color: black; color: white;")
        label.setFixedSize(512, 512)
        return label

    def create_image_display_3d(self, parent):
        # Initialize the napari viewer
        self.viewer = napari.Viewer(ndisplay=3)
        
        self.viewer.window._toggle_menubar_visible()
        
        # Create a container widget to hold the napari viewer
        container = QWidget(parent)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)

        # Embed the viewer's QWidget into the container
        layout.addWidget(self.viewer.window._qt_window.centralWidget())

        # Set the container size
        container.setMinimumSize(QSize(512, 512))
        container.setMaximumSize(QSize(512, 512))

        return container

    # [Removed] Save 3D View button handler

    def update_ui_mode(self):
        if self.is_3d_mode:
            self.mean_angle_field.hide()
            self.mean_angle_label.hide()
            self.alignment_field.hide()
            self.alignment_label.hide()
            self.noise_label.hide()
            self.noise_check.hide()
            self.noise_field.hide()
            self.distance_label.hide()
            self.distance_check.hide()
            self.distance_field.hide()
            self.blur_label.hide()
            self.blur_check.hide()
            self.blur_field.hide()
            self.scale_label.hide()
            self.scale_field.hide()
            self.scale_check.hide()
            self.joint_points_field.hide()
            self.joint_points_label.hide()
            self.show_joints_checkbox.hide()
            self.use_joints_checkbox.hide()

            self.mean_direction_field.show()
            self.mean_direction_label.show()
            self.max_angle_change_field.show()
            self.max_angle_change_label.show()
            self.min_angle_change_label.show()
            self.min_angle_change_field.show()
            self.alignment3D_field.show()
            self.alignment3D_label.show()
            self.noise_mean_label.show()
            self.noise_mean_check.show()
            self.noise_mean_field.show()
            self.distance_falloff_label.show()
            self.distance_falloff_check.show()
            self.distance_falloff_field.show()
            self.blur_radius_label.show()
            self.blur_radius_check.show()
            self.blur_radius_field.show()

            self.image_depth_label.show()
            self.image_depth_field.show()
            self.curvature_label.show()
            self.curvature_field.show()
            self.branching_probability_label.show()
            self.branching_probability_field.show()
        else:
            self.viewer.window._qt_window.hide()
            self.mean_direction_field.hide()
            self.mean_direction_label.hide()
            self.alignment3D_field.hide()
            self.alignment3D_label.hide()
            self.noise_mean_label.hide()
            self.noise_mean_check.hide()
            self.noise_mean_field.hide()
            self.distance_falloff_label.hide()
            self.distance_falloff_check.hide()
            self.distance_falloff_field.hide()
            self.blur_radius_label.hide()
            self.blur_radius_check.hide()
            self.blur_radius_field.hide()

            self.image_depth_label.hide()
            self.image_depth_field.hide()
            self.curvature_label.hide()
            self.curvature_field.hide()
            self.branching_probability_label.hide()
            self.branching_probability_field.hide()
            
            self.max_angle_change_field.hide()
            self.max_angle_change_label.hide()
            self.min_angle_change_label.hide()
            self.min_angle_change_field.hide()
            self.joint_points_label.show()
            self.joint_points_field.show()
            self.show_joints_checkbox.show()
            self.use_joints_checkbox.show()
            
            self.mean_angle_field.show()
            self.mean_angle_label.show()
            self.alignment_field.show()
            self.alignment_label.show()
            self.noise_label.show()
            self.noise_check.show()
            self.noise_field.show()
            self.distance_label.show()
            self.distance_check.show()
            self.distance_field.show()
            self.blur_label.show()
            self.blur_check.show()
            self.blur_field.show()
            self.scale_label.show()
            self.scale_field.show()
            self.scale_check.show()
        # Always ensure noise model controls are visible
        self.noise_model_label.show()
        self.noise_model_combo.show()
        # Update conditional visibility for related inputs
        self.update_noise_controls_visibility()

    def parse_params(self):
        self.params.nImages.parse(self.n_images_field.text(), int)
        self.params.seed.parse(self.seed_check.isChecked(), self.seed_field.text(), int)
        self.params.nFibers.parse(self.n_fibers_field.text(), int)
        self.params.segmentLength.parse(self.segment_field.text(), float)
        self.params.widthChange.parse(self.width_change_field.text(), float)

        if self.is_3d_mode:
            self.params.imageDepth.parse(self.image_depth_field.text(), int)
            self.params.curvature.parse(self.curvature_field.text(), float)
            self.params.branchingProbability.parse(self.branching_probability_field.text(), float)
            self.params.meanDirection.parse(self.mean_direction_field.text(), float)
            self.params.alignment3D.parse(self.alignment3D_field.text(), float)
            self.params.noiseMean.parse(self.noise_mean_check.isChecked(), self.noise_mean_field.text(), float)
            # Keep global noise.use in sync in 3D
            self.params.noise.use = self.noise_mean_check.isChecked()
            self.params.distanceFalloff.parse(self.distance_falloff_check.isChecked(), self.distance_falloff_field.text(), float)
            self.params.blurRadius.parse(self.blur_radius_check.isChecked(), self.blur_radius_field.text(), float)
            self.params.minAngleChange.parse(self.min_angle_change_field.text(), float)  # New
            self.params.maxAngleChange.parse(self.max_angle_change_field.text(), float)  # New
        else:
            self.params.meanAngle.parse(self.mean_angle_field.text(), float)
            self.params.alignment.parse(self.alignment_field.text(), float)
            self.params.noise.parse(self.noise_check.isChecked(), self.noise_field.text(), float)
            self.params.distance.parse(self.distance_check.isChecked(), self.distance_field.text(), float)
            self.params.blur.parse(self.blur_check.isChecked(), self.blur_field.text(), float)
            self.params.showJoints.use = self.show_joints_checkbox.isChecked()
            self.params.useJoints.use = self.use_joints_checkbox.isChecked()

            if self.use_joints_checkbox.isChecked():
                self.params.jointPoints.parse(self.joint_points_field.text(), int)

        # Noise model and related optionals
        self.params.noiseModel.parse(self.noise_model_combo.currentText(), str)
        self.params.noiseStdDev.parse(self.noise_std_check.isChecked(), self.noise_std_field.text(), float)
        self.params.saltPepperProb.parse(self.saltpepper_check.isChecked(), self.saltpepper_field.text(), float)

        self.params.imageWidth.parse(self.image_width_field.text(), int)
        self.params.imageHeight.parse(self.image_height_field.text(), int)
        self.params.imageBuffer.parse(self.image_buffer_field.text(), int)
        self.params.scale.parse(self.scale_check.isChecked(), self.scale_field.text(), float)
        self.params.downSample.parse(self.sample_check.isChecked(), self.sample_field.text(), float)
        self.params.cap.parse(self.cap_check.isChecked(), self.cap_field.text(), int)
        self.params.normalize.parse(self.normalize_check.isChecked(), self.normalize_field.text(), int)
        self.params.bubble.parse(self.bubble_check.isChecked(), self.bubble_field.text(), int)
        self.params.swap.parse(self.swap_check.isChecked(), self.swap_field.text(), int)
        self.params.spline.parse(self.spline_check.isChecked(), self.spline_field.text(), int)
        self.params.psfEnabled.use = self.apply_psf_checkbox.isChecked()
        self.params.psfType.parse(self.psf_type_combo.currentText(), str)
        self.params.psfGaussianNA.parse(self.psf_gaussian_na_field.text(), float)
        self.params.psfGaussianWavelength.parse(self.psf_gaussian_wavelength_field.text(), float)
        self.params.psfPixelSizeZ.parse(self.psf_voxel_z_field.text(), float)
        self.params.psfPixelSizeY.parse(self.psf_voxel_y_field.text(), float)
        self.params.psfPixelSizeX.parse(self.psf_voxel_x_field.text(), float)
        self.params.psfVectorialNA.parse(self.psf_vectorial_na_field.text(), float)
        self.params.psfVectorialMediumRI.parse(self.psf_vectorial_medium_ri_field.text(), float)
        self.params.psfVectorialSampleRI.parse(self.psf_vectorial_sample_ri_field.text(), float)
        self.params.psfVectorialWavelength.parse(self.psf_vectorial_wavelength_field.text(), float)
        self.params.psfVectorialPolarization.parse(self.psf_vectorial_polarization_field.text(), float)
        self.params.psfVectorialVolumeZ.parse(self.psf_vectorial_volume_z_field.text(), float)
        self.params.psfVectorialVolumeY.parse(self.psf_vectorial_volume_y_field.text(), float)
        self.params.psfVectorialVolumeX.parse(self.psf_vectorial_volume_x_field.text(), float)
        self.params.psfVectorialShapeZ.parse(self.psf_vectorial_shape_z_field.text(), int)
        self.params.psfVectorialShapeY.parse(self.psf_vectorial_shape_y_field.text(), int)
        self.params.psfVectorialShapeX.parse(self.psf_vectorial_shape_x_field.text(), int)

    def display_params(self):
        self.output_location_label.setText(f"Output location:\noutput/")

        self.n_images_field.setText(self.params.nImages.get_string())
        self.seed_check.setChecked(self.params.seed.use)
        self.seed_field.setText(self.params.seed.get_string())

        self.length_display.setText(self.params.length.get_string())
        self.width_display.setText(self.params.width.get_string())
        self.straight_display.setText(self.params.straightness.get_string())

        self.n_fibers_field.setText(self.params.nFibers.get_string())
        self.segment_field.setText(self.params.segmentLength.get_string())
        self.width_change_field.setText(self.params.widthChange.get_string())

        if self.is_3d_mode:
            self.image_depth_field.setText(self.params.imageDepth.get_string())
            self.curvature_field.setText(self.params.curvature.get_string())
            self.branching_probability_field.setText(self.params.branchingProbability.get_string())
            self.mean_direction_field.setText(self.params.meanDirection.get_string())
            self.alignment3D_field.setText(self.params.alignment3D.get_string())
            self.noise_mean_field.setText(self.params.noiseMean.get_string())
            # Reflect global noise.use in 3D checkbox
            self.noise_mean_check.setChecked(self.params.noise.use or self.params.noiseMean.use)
            self.distance_falloff_field.setText(self.params.distanceFalloff.get_string())
            self.blur_radius_field.setText(self.params.blurRadius.get_string())
            self.min_angle_change_field.setText(self.params.minAngleChange.get_string())  # New
            self.max_angle_change_field.setText(self.params.maxAngleChange.get_string())  # New
        else:
            self.mean_angle_field.setText(self.params.meanAngle.get_string())
            self.alignment_field.setText(self.params.alignment.get_string())
            self.noise_field.setText(self.params.noise.get_string())
            self.noise_check.setChecked(self.params.noise.use)
            self.distance_field.setText(self.params.distance.get_string())
            self.distance_check.setChecked(self.params.distance.use)
            self.blur_field.setText(self.params.blur.get_string())
            self.blur_check.setChecked(self.params.blur.use)
            self.show_joints_checkbox.setChecked(self.params.showJoints.use)
            self.use_joints_checkbox.setChecked(self.params.useJoints.use)
            if self.params.useJoints.use:
                self.joint_points_field.setText(str(self.params.jointPoints.get_value()))
                self.joint_points_field.setReadOnly(False)
            else:
                self.joint_points_field.clear()
                self.joint_points_field.setReadOnly(True)

        # Noise model and related optionals
        # Set noise model combo selection
        current_model = str(self.params.noiseModel.get_value()) if self.params.noiseModel.get_value() is not None else "No Noise"
        idx = self.noise_model_combo.findText(current_model)
        if idx >= 0:
            self.noise_model_combo.setCurrentIndex(idx)
        else:
            # Fallback to first option
            self.noise_model_combo.setCurrentIndex(0)

        # Std dev optional
        self.noise_std_field.setText(self.params.noiseStdDev.get_string())
        self.noise_std_check.setChecked(self.params.noiseStdDev.use)
        # Salt-pepper optional
        self.saltpepper_field.setText(self.params.saltPepperProb.get_string())
        self.saltpepper_check.setChecked(self.params.saltPepperProb.use)
        # Update conditional visibility
        self.update_noise_controls_visibility()

        self.image_width_field.setText(self.params.imageWidth.get_string())
        self.image_height_field.setText(self.params.imageHeight.get_string())
        self.image_buffer_field.setText(self.params.imageBuffer.get_string())

        self.scale_check.setChecked(self.params.scale.use)
        self.scale_field.setText(self.params.scale.get_string())
        self.sample_check.setChecked(self.params.downSample.use)
        self.sample_field.setText(self.params.downSample.get_string())
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
        self.apply_psf_checkbox.setChecked(self.params.psfEnabled.use)
        current_psf_type = str(self.params.psfType.get_value()) if self.params.psfType.get_value() is not None else "None"
        idx = self.psf_type_combo.findText(current_psf_type)
        if idx >= 0:
            self.psf_type_combo.setCurrentIndex(idx)
        self.psf_gaussian_na_field.setText(self.params.psfGaussianNA.get_string())
        self.psf_gaussian_wavelength_field.setText(self.params.psfGaussianWavelength.get_string())
        self.psf_voxel_z_field.setText(self.params.psfPixelSizeZ.get_string())
        self.psf_voxel_y_field.setText(self.params.psfPixelSizeY.get_string())
        self.psf_voxel_x_field.setText(self.params.psfPixelSizeX.get_string())
        self.psf_vectorial_na_field.setText(self.params.psfVectorialNA.get_string())
        self.psf_vectorial_medium_ri_field.setText(self.params.psfVectorialMediumRI.get_string())
        self.psf_vectorial_sample_ri_field.setText(self.params.psfVectorialSampleRI.get_string())
        self.psf_vectorial_wavelength_field.setText(self.params.psfVectorialWavelength.get_string())
        self.psf_vectorial_polarization_field.setText(self.params.psfVectorialPolarization.get_string())
        self.psf_vectorial_volume_z_field.setText(self.params.psfVectorialVolumeZ.get_string())
        self.psf_vectorial_volume_y_field.setText(self.params.psfVectorialVolumeY.get_string())
        self.psf_vectorial_volume_x_field.setText(self.params.psfVectorialVolumeX.get_string())
        self.psf_vectorial_shape_z_field.setText(self.params.psfVectorialShapeZ.get_string())
        self.psf_vectorial_shape_y_field.setText(self.params.psfVectorialShapeY.get_string())
        self.psf_vectorial_shape_x_field.setText(self.params.psfVectorialShapeX.get_string())
        self.update_psf_controls_visibility()
        
    def update_joint_points_field(self):
        if not self.use_joints_checkbox.isChecked():
            self.joint_points_field.setReadOnly(True)
            self.joint_points_field.setText("")  # Clear when unselecting
        else:
            self.joint_points_field.setReadOnly(False)
            self.joint_points_field.setText("3")  # Restore default when re-enabling use joints
        
    def generate_pressed(self):
        try:
            self.parse_params()

            if not self.use_joints_checkbox.isChecked():
                self.joint_points_field.clear()

            self.abort_requested = False
            self.abort_button.setEnabled(True)
            self.generate_button.setEnabled(False)
            self.reset_button.setEnabled(False)

            io_manager = self.io_manager_3d if self.is_3d_mode else self.io_manager_2d
            out_folder = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d

            self.worker = GenerationWorker(
                is_3d_mode=self.is_3d_mode,
                params=self.params,
                io_manager=io_manager,
                out_folder=out_folder
            )
            self.worker.generation_finished.connect(self.on_generation_finished)
            self.worker.generation_failed.connect(self.on_generation_failed)
            self.worker.start()

        except Exception as e:
            self.show_error(str(e))
            self.abort_button.setEnabled(False)
            self.generate_button.setEnabled(True)
            self.reset_button.setEnabled(True)

    def abort_pressed(self):
        if hasattr(self, 'worker') and self.worker.isRunning():
            self.worker.abort()
            self.abort_button.setEnabled(False)

    def on_generation_finished(self, collection, message):
        self.abort_button.setEnabled(False)
        self.generate_button.setEnabled(True)
        self.reset_button.setEnabled(True)

        if collection is not None:
            self.collection = collection
            self.display_index = 0

            # Save a deepcopy of the original unsmoothed fibers for all images
            from copy import deepcopy
            self.original_fibers_by_index = [deepcopy(self.collection.get(i).fibers) for i in range(self.collection.size())]
            # Convenience for current index
            fiber_image = self.collection.get(self.display_index)
            self.original_fibers = deepcopy(self.original_fibers_by_index[self.display_index])

            # Redraw the image properly (re-smooth if smoothing enabled, rebuild, post-process, display)
            self.redraw_image()

            # Update image counter
            self.update_image_counter()

            # Update joint points field if needed
            if not self.use_joints_checkbox.isChecked():
                self.joint_points_field.setText(str(len(fiber_image.joint_points)))

            # Enable manual save now that content exists
            self.save_results_button.setEnabled(True)
        elif message:
            self.show_error(message)

    def on_generation_failed(self, error):
        self.abort_button.setEnabled(False)
        self.generate_button.setEnabled(True)
        self.reset_button.setEnabled(True)
        self.show_error(error)


    def reset_pressed(self):
        try:
            if self.is_3d_mode:
                self.params = self.io_manager_3d.read_params_file(self.DEFAULTS_FILE_3D)
            else:
                self.params = self.io_manager_2d.read_params_file(self.DEFAULTS_FILE_2D)
            self.display_params()
        except Exception as e:
            self.show_error(str(e))
    
    def prev_pressed(self):
        if self.collection and self.display_index > 0:
            self.display_index -= 1
            self.display_image(self.collection.get_image(self.display_index))
            self.update_image_counter()

    def next_pressed(self):
        if self.collection and self.display_index < self.collection.size() - 1:
            self.display_index += 1
            self.display_image(self.collection.get_image(self.display_index))
            self.update_image_counter()

    def load_pressed(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Open File", "", "JSON files (*.json)")
        if filename:
            try:
                if self.is_3d_mode:
                    self.params = self.io_manager_3d.read_params_file(filename)
                else:
                    self.params = self.io_manager_2d.read_params_file(filename)
            except Exception as e:
                self.show_error(str(e))
            self.display_params()

    def save_pressed(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Directory")
        if directory:
            if self.is_3d_mode:
                self.out_folder_3d = os.path.join(directory, "")
                self.out_folder = self.out_folder_3d
            else:
                self.out_folder_2d = os.path.join(directory, "")
                self.out_folder = self.out_folder_2d
            self.display_params()

    def _update_fiber_params_from_ui(self, fiber_params):
        """Update a FiberImage/FiberImage3D params object from current UI state for saving."""
        try:
            # Common smoothing options
            fiber_params.bubble.use = bool(self.bubble_check.isChecked())
            fiber_params.bubble.value = int(self.bubble_field.text() or fiber_params.bubble.value)
            fiber_params.swap.use = bool(self.swap_check.isChecked())
            fiber_params.swap.value = int(self.swap_field.text() or fiber_params.swap.value)
            fiber_params.spline.use = bool(self.spline_check.isChecked())
            fiber_params.spline.value = int(self.spline_field.text() or fiber_params.spline.value)

            # Post-processing options (2D names)
            if hasattr(fiber_params, 'distance'):
                fiber_params.distance.use = bool(self.distance_check.isChecked())
                fiber_params.distance.value = float(self.distance_field.text() or fiber_params.distance.value)
            if hasattr(fiber_params, 'cap'):
                fiber_params.cap.use = bool(self.cap_check.isChecked())
                fiber_params.cap.value = int(self.cap_field.text() or fiber_params.cap.value)
            if hasattr(fiber_params, 'normalize'):
                fiber_params.normalize.use = bool(self.normalize_check.isChecked())
                fiber_params.normalize.value = int(self.normalize_field.text() or fiber_params.normalize.value)
            if hasattr(fiber_params, 'downSample'):
                fiber_params.downSample.use = bool(self.sample_check.isChecked())
                fiber_params.downSample.value = float(self.sample_field.text() or fiber_params.downSample.value)
            if hasattr(fiber_params, 'blur'):
                fiber_params.blur.use = bool(self.blur_check.isChecked())
                fiber_params.blur.value = float(self.blur_field.text() or fiber_params.blur.value)

            # Noise model handling (2D: noise/noiseStdDev/saltPepperProb; 3D: noiseMean/noiseStdDev/saltPepperProb)
            model = self.noise_model_combo.currentText().lower()
            if hasattr(fiber_params, 'noiseModel'):
                fiber_params.noiseModel.value = model.title() if model != 'no noise' else 'No Noise'
            # 2D Poisson mean
            if hasattr(fiber_params, 'noise'):
                fiber_params.noise.use = (model == 'poisson') and self.noise_check.isChecked()
                if self.noise_field.text():
                    fiber_params.noise.value = float(self.noise_field.text())
            # 3D Poisson mean
            if hasattr(fiber_params, 'noiseMean'):
                fiber_params.noiseMean.use = (model in ('poisson', 'poisson+gaussian')) and self.noise_mean_check.isChecked()
                if hasattr(self, 'noise_mean_field') and self.noise_mean_field.text():
                    fiber_params.noiseMean.value = float(self.noise_mean_field.text())
            if hasattr(fiber_params, 'noiseStdDev'):
                fiber_params.noiseStdDev.use = (model in ('gaussian', 'poisson+gaussian')) and self.noise_std_check.isChecked()
                if self.noise_std_field.text():
                    fiber_params.noiseStdDev.value = float(self.noise_std_field.text())
            if hasattr(fiber_params, 'saltPepperProb'):
                fiber_params.saltPepperProb.use = (model == 'salt-and-pepper') and self.saltpepper_check.isChecked()
                if self.saltpepper_field.text():
                    fiber_params.saltPepperProb.value = float(self.saltpepper_field.text())
        except Exception:
            # If any UI field fails parsing, keep original params values
            pass

    def save_results_pressed(self):
        """Prompt to choose saving the selected image or all images, with optional custom naming/location."""
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to save. Click Generate first.")
                return

            # Ask user which scope to save
            box = QMessageBox(self)
            box.setWindowTitle("Save")
            box.setText("Save current image or all generated images?")
            save_selected_btn = box.addButton("Save Selected", QMessageBox.ButtonRole.AcceptRole)
            save_all_btn = box.addButton("Save All", QMessageBox.ButtonRole.AcceptRole)
            box.addButton(QMessageBox.StandardButton.Cancel)
            custom_check = QCheckBox("Choose name and location")
            box.setCheckBox(custom_check)
            box.exec()

            custom = custom_check.isChecked()
            clicked = box.clickedButton()
            if clicked is save_all_btn:
                self._save_all_results(custom=custom)
            elif clicked is save_selected_btn:
                self._save_selected_result(custom=custom)
        except Exception as e:
            self.show_error(str(e))

    def _save_selected_result(self, custom: bool = False):
        """Save only the currently displayed image and its data with post-processing applied."""
        try:
            base_out = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
            if custom:
                # Pick an explicit filename and path for the image
                default_name = f"{'3d' if self.is_3d_mode else '2d'}_image_{self.display_index}.tiff"
                dest_file, _ = QFileDialog.getSaveFileName(self, "Save Image As", os.path.join(base_out, default_name), "TIFF (*.tiff)")
                if not dest_file:
                    return
                # Normalize to .tiff extension
                if not dest_file.lower().endswith(".tiff"):
                    dest_file = f"{os.path.splitext(dest_file)[0]}.tiff"
                out_folder = os.path.dirname(dest_file)
                base = os.path.splitext(dest_file)[0]
            else:
                # Create a unique session subfolder to avoid overwrites
                out_folder = self._make_unique_save_dir(base_out)
                base = os.path.join(out_folder, f"{'3d' if self.is_3d_mode else '2d'}_image_{self.display_index}")

            i = self.display_index
            fiber_image = self.collection.get(i)
            # Sync params with UI
            self._update_fiber_params_from_ui(fiber_image.params)

            if self.is_3d_mode:
                # Save 3D data JSON (aligned to base)
                self.io_manager_3d.write_string_file(f"{base}_data.json", json.dumps(fiber_image.to_dict(), indent=4))
                # Save 3D image using viewer composite to match base
                base_img = fiber_image.get_image()
                base_shape = base_img.shape if isinstance(base_img, np.ndarray) else None
                self.io_manager_3d.save_napari_3d_image(self.viewer, base, base_shape=base_shape)
                # Params snapshot alongside (per-image params reflecting current UI)
                self.io_manager_3d.write_string_file(
                    f"{base}_params.json", json.dumps(fiber_image.params.to_dict(), indent=4)
                )
                # Excel summary for 3D
                IOManager.save_csv(fiber_image, f"{base}_data")
            else:
                # Rebuild from (re-)smoothed fibers and apply post-processing
                self.re_smooth_fibers()
                base_image = self.rebuild_image_from_fibers()
                final_image = self.apply_postprocessing(base_image)
                # Save image as TIFF at chosen base
                tiff.imwrite(f"{base}.tiff", np.array(final_image))
                # Save data JSON and Excel summary next to it
                self.io_manager_2d.write_string_file(f"{base}_data.json", json.dumps(fiber_image.to_dict(), indent=4))
                IOManager.save_csv(fiber_image, f"{base}_data")
                # Params snapshot alongside (per-image params reflecting current UI)
                self.io_manager_2d.write_string_file(
                    f"{base}_params.json", json.dumps(fiber_image.params.to_dict(), indent=4)
                )

            QMessageBox.information(self, "Saved", f"Saved current {('3D' if self.is_3d_mode else '2D')} image and data to:\n{out_folder}")
        except Exception as e:
            self.show_error(str(e))

    def _rebuild_2d_image_from_fiber_list(self, fiber_image, fibers_list):
        """Rebuild a 2D PIL image from a provided list of fibers using the given fiber_image params."""
        base = Image.new('L', (fiber_image.params.imageWidth.get_value(), fiber_image.params.imageHeight.get_value()), 0)
        draw = ImageDraw.Draw(base)
        for fiber in fibers_list:
            for segment in fiber:
                draw.line(
                    [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                    fill=255,
                    width=int(segment.width)
                )
        return base

    def _save_all_results(self, custom: bool = False):
        """Save all generated images and their data reflecting current post-processing and smoothing settings."""
        try:
            base_out = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
            if custom:
                # Choose directory and a base prefix
                out_folder = QFileDialog.getExistingDirectory(self, "Select Save Directory", base_out)
                if not out_folder:
                    return
                default_prefix = "3d_image_" if self.is_3d_mode else "2d_image_"
                prefix, ok = QInputDialog.getText(self, "File Prefix", "Base filename prefix:", text=default_prefix)
                if not ok or not prefix:
                    prefix = default_prefix
            else:
                # Create a unique session subfolder to avoid overwrites
                out_folder = self._make_unique_save_dir(base_out)
                prefix = "3d_image_" if self.is_3d_mode else "2d_image_"

            # Write params snapshot (namespaced when custom)
            io_mgr = self.io_manager_3d if self.is_3d_mode else self.io_manager_2d
            params_name = f"{prefix}params.json" if custom else "params.json"
            io_mgr.write_string_file(os.path.join(out_folder, params_name), json.dumps(self.params.to_dict(), indent=4))

            if self.is_3d_mode:
                # Save all 3D images from collection and data JSON
                for i in range(self.collection.size()):
                    fiber_image = self.collection.get(i)
                    # Sync params with current UI so saved data reflects save-time settings
                    self._update_fiber_params_from_ui(fiber_image.params)
                    base = os.path.join(out_folder, f"{prefix}{i}")
                    # Data JSON
                    self.io_manager_3d.write_string_file(f"{base}_data.json", json.dumps(fiber_image.to_dict(), indent=4))
                    # Save the generated 3D volume directly
                    image_3d = self.collection.get_image(i)
                    tiff.imwrite(f"{base}.tiff", image_3d, imagej=True)
                    # Excel summary for 3D
                    IOManager.save_csv(fiber_image, f"{base}_data")
                QMessageBox.information(self, "Saved", f"Saved all 3D images and data to:\n{out_folder}")
                return

            # 2D mode: apply smoothing to each image from original fibers, rebuild, post-process and save
            for i in range(self.collection.size()):
                fiber_image = self.collection.get(i)
                # Update fiber-level params from UI
                self._update_fiber_params_from_ui(fiber_image.params)

                # Use the stored original fibers for this index if available
                try:
                    fibers_copy = deepcopy(self.original_fibers_by_index[i])
                except Exception:
                    fibers_copy = deepcopy(fiber_image.fibers)

                # Apply smoothing options to the copy
                if self.bubble_check.isChecked():
                    passes = int(self.bubble_field.text())
                    for f in fibers_copy:
                        f.bubble_smooth(passes)
                if self.swap_check.isChecked():
                    ratio = int(self.swap_field.text())
                    for f in fibers_copy:
                        f.swap_smooth(ratio)
                if self.spline_check.isChecked():
                    spline_ratio = int(self.spline_field.text())
                    for f in fibers_copy:
                        f.spline_smooth(spline_ratio)

                # Refresh orientations after smoothing
                for f in fibers_copy:
                    f.calculate_orientations()

                # Rebuild and apply post-processing
                base_img = self._rebuild_2d_image_from_fiber_list(fiber_image, fibers_copy)
                final_img = self.apply_postprocessing(base_img)

                # Save image and data using prefix
                base = os.path.join(out_folder, f"{prefix}{i}")
                tiff.imwrite(f"{base}.tiff", np.array(final_img))
                # Data JSON and Excel reflecting smoothed fibers
                temp = FiberImage(fiber_image.params)
                temp.fibers = fibers_copy
                # Recompute joints for the smoothed copy
                try:
                    temp.joint_points = temp.count_joints()
                except Exception:
                    temp.joint_points = list(getattr(fiber_image, 'joint_points', []))
                self.io_manager_2d.write_string_file(f"{base}_data.json", json.dumps(temp.to_dict(), indent=4))
                IOManager.save_csv(temp, f"{base}_data")

            QMessageBox.information(self, "Saved", f"Saved all 2D images and data to:\n{out_folder}")
        except Exception as e:
            self.show_error(str(e))

    def _make_unique_save_dir(self, base_folder: str) -> str:
        """Create and return a unique subfolder under base_folder to prevent overwriting previous saves."""
        try:
            os.makedirs(base_folder, exist_ok=True)
        except Exception:
            pass
        # Use a human-friendly, filesystem-safe timestamp: YYYY-MM-DD_HH-MM-SS
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        root = os.path.join(base_folder, f"save_{timestamp}")
        candidate = root
        counter = 1
        while os.path.exists(candidate):
            candidate = f"{root}_{counter:02d}"
            counter += 1
        os.makedirs(candidate, exist_ok=True)
        return candidate

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
      
    def display_image(self, image):
        if self.is_3d_mode:
            self.display_image_3d(image)
        else:
            self.display_image_2d(image)
            
    def redraw_image(self):
        # Skip redraws while we are in the middle of switching modes
        if getattr(self, '_suspend_redraw', False):
            return
        if self.collection is not None:
            if self.is_3d_mode:
                # In 3D mode, use the generated 3D volume directly
                image_3d = self.collection.get_image(self.display_index)
                self.display_image_3d(image_3d)
            else:
                # In 2D mode, rebuild from fibers and apply post-processing
                self.re_smooth_fibers()
                base_image = self.rebuild_image_from_fibers()
                final_image = self.apply_postprocessing(base_image)
                self.display_image(final_image)
    
    def re_smooth_fibers(self):
        if not hasattr(self, 'collection') or self.collection is None:
            return

        fiber_image = self.collection.get(self.display_index)

        # Restore original fibers if smoothing is disabled
        if not (self.bubble_check.isChecked() or self.swap_check.isChecked() or self.spline_check.isChecked()):
            try:
                fiber_image.fibers = deepcopy(self.original_fibers_by_index[self.display_index])
            except Exception:
                # Fallback to existing stored original if available
                fiber_image.fibers = deepcopy(getattr(self, 'original_fibers', fiber_image.fibers))
            return

        # Else apply smoothing
        try:
            fiber_image.fibers = deepcopy(self.original_fibers_by_index[self.display_index])
        except Exception:
            fiber_image.fibers = deepcopy(getattr(self, 'original_fibers', fiber_image.fibers))

        for fiber in fiber_image:
            if self.bubble_check.isChecked():
                passes = int(self.bubble_field.text())
                fiber.bubble_smooth(passes)

            if self.swap_check.isChecked():
                ratio = int(self.swap_field.text())
                fiber.swap_smooth(ratio)

            if self.spline_check.isChecked():
                spline_ratio = int(self.spline_field.text())
                fiber.spline_smooth(spline_ratio)
            # Refresh orientations to match updated geometry
            fiber.calculate_orientations()
        
        # After smoothing, recompute joints to reflect updated geometry
        try:
            fiber_image.joint_points = fiber_image.count_joints()
        except Exception:
            pass
                    
    def rebuild_image_from_fibers(self):
        fiber_image = self.collection.get(self.display_index)

        # Create a new blank grayscale image
        base_image = Image.new('L', (fiber_image.params.imageWidth.get_value(), fiber_image.params.imageHeight.get_value()), 0)
        draw = ImageDraw.Draw(base_image)

        # Draw each fiber
        for fiber in fiber_image:
            for segment in fiber:
                draw.line(
                    [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                    fill=255,
                    width=int(segment.width)
                )

        return base_image
    
    def apply_postprocessing(self, image):
        np_image = np.array(image)

        if self.distance_check.isChecked():
            distance_factor = float(self.distance_field.text())
            np_image = self._apply_distance_function(np_image, distance_factor)

        # Apply selected noise model for preview based on model and enable flags
        model = self.noise_model_combo.currentText().lower() if hasattr(self, 'noise_model_combo') else 'no noise'
        apply_preview = False
        if model == 'poisson':
            apply_preview = self.noise_check.isChecked()
        elif model == 'gaussian':
            apply_preview = self.noise_std_check.isChecked()
        elif model == 'salt-and-pepper':
            apply_preview = self.saltpepper_check.isChecked()
        elif model == 'speckle':
            apply_preview = True
        elif model == 'poisson+gaussian':
            apply_preview = self.noise_check.isChecked() or self.noise_std_check.isChecked()

        if apply_preview:
            if model == 'poisson':
                mean_noise = float(self.noise_field.text() or 10.0)
                noise = np.random.poisson(mean_noise, np_image.shape)
                np_image = np_image + noise
            elif model == 'gaussian':
                std = float(self.noise_std_field.text() or 10.0)
                noise = np.random.normal(0.0, std, size=np_image.shape)
                np_image = np_image + noise
            elif model == 'salt-and-pepper':
                p = float(self.saltpepper_field.text() or 0.01)
                rnd = np.random.rand(*np_image.shape)
                np_image[rnd < (p / 2.0)] = 0
                np_image[rnd > 1.0 - (p / 2.0)] = 255
            elif model == 'speckle':
                speckle = np.random.normal(1.0, 0.2, size=np_image.shape)
                np_image = np_image * speckle
            elif model == 'poisson+gaussian':
                mean_noise = float(self.noise_field.text() or 10.0)
                p_noise = np.random.poisson(mean_noise, np_image.shape)
                std = float(self.noise_std_field.text() or 10.0)
                g_noise = np.random.normal(0.0, std, size=np_image.shape)
                np_image = np_image + p_noise + g_noise
            np_image = np.clip(np_image, 0, 255).astype(np.uint8)

        if self.blur_check.isChecked():
            blur_radius = float(self.blur_field.text())
            np_image = gaussian_filter(np_image, sigma=blur_radius)

        if self.cap_check.isChecked():
            cap_value = int(self.cap_field.text())
            np_image = np.clip(np_image, 0, cap_value)

        if self.normalize_check.isChecked():
            max_value = np.max(np_image)
            if max_value > 0:
                np_image = (np_image * 255.0 / max_value).astype(np.uint8)

        if self.sample_check.isChecked():
            down_ratio = float(self.sample_field.text())
            new_size = (int(np_image.shape[1] * down_ratio), int(np_image.shape[0] * down_ratio))
            image = Image.fromarray(np_image, mode='L').resize(new_size, Image.NEAREST)
        else:
            image = Image.fromarray(np_image, mode='L')

        return image
    
    def _apply_distance_function(self, np_image, distance_factor):

        height, width = np_image.shape
        y_indices, x_indices = np.indices((height, width))
        center_x = width // 2
        center_y = height // 2

        distances = np.sqrt((x_indices - center_x) ** 2 + (y_indices - center_y) ** 2)
        distances = distances / distances.max()

        falloff = 1 - distances ** distance_factor
        falloff = np.clip(falloff, 0, 1)

        return (np_image * falloff).astype(np.uint8)
    
    def draw_scale_bar(self, draw, scale, image_width, image_height):
        try:
            # Get the physical scale from user input
            pixels_per_micron = float(self.scale_field.text())
        except ValueError:
            pixels_per_micron = 5.0  # default safe fallback

        # How many pixels to represent 10 microns?
        microns = 10
        pixel_length = int(microns * pixels_per_micron * scale)

        # Position: bottom left corner
        margin = 10
        x_start = margin
        y_start = image_height - margin

        # Draw scale line
        draw.line(
            [(x_start, y_start), (x_start + pixel_length, y_start)],
            fill='white',
            width=2
        )

        # Draw scale label
        font = None  # (optional: load a better font if desired)
        draw.text((x_start, y_start - 15), f"{microns} μm", fill='white', font=font)

    def display_image_2d(self, image):
        # Scale the image to fit the display window
        x_scale = self.IMAGE_DISPLAY_SIZE / image.width
        y_scale = self.IMAGE_DISPLAY_SIZE / image.height
        scale = min(x_scale, y_scale)
        image = image.resize((int(image.width * scale), int(image.height * scale)), Image.NEAREST)

        # Convert to RGBA for overlaying elements
        base_image = image.convert('RGBA')

        # Create transparent overlay
        overlay = Image.new('RGBA', base_image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        fiber_image = self.collection.get(self.display_index)

        # Draw joint points if checked
        if self.show_joints_checkbox.isChecked():
            for joint in fiber_image.joint_points:
                scaled_joint = (int(joint.x * scale), int(joint.y * scale))
                draw.ellipse(
                    (scaled_joint[0] - 3, scaled_joint[1] - 3, scaled_joint[0] + 3, scaled_joint[1] + 3),
                    outline='red',
                    fill='red'
                )

        # Draw scale bar if checked
        if self.scale_check.isChecked():
            self.draw_scale_bar(draw, scale, base_image.width, base_image.height)

        # Merge base image with overlay
        combined = Image.alpha_composite(base_image, overlay)

        # Display final combined image
        qt_image = ImageQt.ImageQt(combined)
        pixmap = QPixmap.fromImage(qt_image)
        self.image_display_2d.setPixmap(pixmap)

    def display_image_3d(self, image):
        # Clear existing layers in napari viewer
        self.viewer.layers.clear()

        # Ensure 3D numpy array (Z, Y, X)
        if isinstance(image, np.ndarray):
            image_data = image
        else:
            # Fallback if a PIL or other 2D image slips through
            try:
                image_data = np.array(image)
            except Exception:
                image_data = None

        # If not 3D, try getting 3D volume from collection directly
        if image_data is None or image_data.ndim != 3:
            image_data = self.collection.get_image(self.display_index)
        # If still not 3D, expand dims to avoid downstream errors
        if image_data.ndim == 2:
            image_data = image_data[np.newaxis, ...]

        # Put viewer into 3D mode. Skip adding a blank volume layer.
        self.viewer.dims.ndisplay = 3

        # Consolidate all fiber segments into a single Shapes layer
        fibers = self.collection.get(self.display_index).fibers
        all_lines = []
        all_widths = []
        for fiber in fibers:
            for segment in fiber:
                coords = np.array([segment.start.to_array(), segment.end.to_array()])
                all_lines.append(coords)
                all_widths.append(float(segment.width))

        if all_lines:
            # Create one shapes layer with per-shape widths
            self.viewer.add_shapes(
                data=all_lines,
                shape_type='line',
                edge_color='white',
                edge_width=np.asarray(all_widths),
                name='Fibers'
            )

        # Do not auto-save during redraw; use the "Save 3D View..." button instead

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
        self.noise_std_check.setVisible(show_std)
        self.noise_std_field.setVisible(show_std)
        # Salt-Pepper prob widgets
        self.saltpepper_label.setVisible(show_sp)
        self.saltpepper_check.setVisible(show_sp)
        self.saltpepper_field.setVisible(show_sp)
        # Poisson mean widgets depend on mode
        if self.is_3d_mode:
            self.noise_mean_label.setVisible(show_poisson_mean)
            self.noise_mean_check.setVisible(show_poisson_mean)
            self.noise_mean_field.setVisible(show_poisson_mean)
            # Hide 2D Poisson mean controls
            self.noise_label.setVisible(False)
            self.noise_check.setVisible(False)
            self.noise_field.setVisible(False)
        else:
            self.noise_label.setVisible(show_poisson_mean)
            self.noise_check.setVisible(show_poisson_mean)
            self.noise_field.setVisible(show_poisson_mean)
            # Hide 3D Poisson mean controls
            self.noise_mean_label.setVisible(False)
            self.noise_mean_check.setVisible(False)
            self.noise_mean_field.setVisible(False)

    def update_psf_controls_visibility(self):
        enabled = self.apply_psf_checkbox.isChecked()
        self.psf_type_combo.setEnabled(enabled)
        mode = self.psf_type_combo.currentText().lower()
        show_gaussian = enabled and "gaussian" in mode
        show_vectorial = enabled and "vectorial" in mode
        self.psf_gaussian_group.setVisible(show_gaussian)
        self.psf_vectorial_group.setVisible(show_vectorial)
        self.preview_psf_button.setEnabled(enabled)

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
        global LAST_PSF_STATS
        if LAST_PSF_STATS is not None:
            stats_text = (
                f"Last PSF apply (volume={LAST_PSF_STATS['volume']}): "
                f"mean {LAST_PSF_STATS['before_mean']:.4f}→{LAST_PSF_STATS['after_mean']:.4f}, "
                f"std {LAST_PSF_STATS['before_std']:.4f}→{LAST_PSF_STATS['after_std']:.4f}"
            )
        fig.text(0.5, 0.02, stats_text, ha='center', va='bottom')
        fig.suptitle('PSF Preview')
        fig.tight_layout()
        plt.show(block=False)
        plt.pause(0.1)

class EntryPoint:
    @staticmethod
    def main(args):
        if len(args) > 1:
            io_manager_2d = IOManager()
            io_manager_3d = IOManager3D()
            try:
                params = io_manager_2d.read_params_file(args[1])
                if "imageDepth" in params.to_dict():
                    collection = ImageCollection3D(params)
                    output_folder = os.path.join("output_3d", os.sep)
                    collection.generate_images_3d()
                    io_manager_3d.write_results(params, collection, output_folder)
                else:
                    collection = ImageCollection(params)
                    output_folder = os.path.join("output_2d", os.sep)
                    collection.generate_images()
                    io_manager_2d.write_results(params, collection, output_folder)
                    # Save .xlsx summary for each image
                    for i in range(collection.size()):
                        output_prefix = os.path.join(output_folder, f"2d_data_{i}")
                        IOManager.save_csv(collection.get(i), output_prefix)
            except Exception as e:
                print(f"Error: {e}")
        else:
            app = QApplication(sys.argv)
            window = MainWindow()
            window.show()
            sys.exit(app.exec())

if __name__ == "__main__":
    EntryPoint.main(sys.argv)
