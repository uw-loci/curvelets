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
from scipy.ndimage import gaussian_filter, label
from scipy.signal import fftconvolve
import matplotlib.pyplot as plt
import tifffile as tiff
from PIL import Image, ImageDraw, ImageOps
import napari
import pandas as pd
import numpy as np
from psf_model import generate_psf_gaussian, generate_psf_vectorial
from export_builders import build_canonical_sample, build_dataset_manifest_rows
from export_schema import EXPORT_DETAIL_CONCISE, EXPORT_DETAIL_FULL
from export_writers import (
    export_canonical_research_package,
    export_full_raw_geometry,
    export_session_restore,
    write_dataset_manifest,
)
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
    def orthonormal_basis(direction):
        direction_array = direction.normalize().to_array()
        reference = np.array([0.0, 0.0, 1.0], dtype=float)
        if abs(np.dot(direction_array, reference)) > 0.9:
            reference = np.array([0.0, 1.0, 0.0], dtype=float)
        basis_u = np.cross(direction_array, reference)
        basis_u_norm = np.linalg.norm(basis_u)
        if basis_u_norm <= 1e-8:
            reference = np.array([1.0, 0.0, 0.0], dtype=float)
            basis_u = np.cross(direction_array, reference)
            basis_u_norm = np.linalg.norm(basis_u)
        basis_u /= basis_u_norm
        basis_v = np.cross(direction_array, basis_u)
        basis_v /= np.linalg.norm(basis_v)
        return Vector(*basis_u), Vector(*basis_v)

    @staticmethod
    def polyline_length(points):
        if len(points) < 2:
            return 0.0
        diffs = np.diff(points, axis=0)
        return float(np.linalg.norm(diffs, axis=1).sum())

    @staticmethod
    def resample_polyline(points, n_segments):
        if len(points) <= 1:
            return points
        if n_segments <= 0:
            return points[[0, -1], :]

        diffs = np.diff(points, axis=0)
        segment_lengths = np.linalg.norm(diffs, axis=1)
        cumulative = np.concatenate(([0.0], np.cumsum(segment_lengths)))
        total_length = cumulative[-1]
        if total_length <= 1e-8:
            return np.repeat(points[:1], n_segments + 1, axis=0)

        targets = np.linspace(0.0, total_length, n_segments + 1)
        output = np.zeros((n_segments + 1, points.shape[1]), dtype=float)
        for axis in range(points.shape[1]):
            output[:, axis] = np.interp(targets, cumulative, points[:, axis])
        return output

    @staticmethod
    def sample_oriented_direction(mean_direction, alignment):
        if mean_direction.is_zero():
            return RngUtility3D.random_vector_3d()

        alignment = float(np.clip(alignment, 0.0, 1.0))
        mean_array = mean_direction.normalize().to_array()
        # Fiber orientation is axial, not directional, so sample both signs.
        if RngUtility.rng.random() < 0.5:
            mean_array = -mean_array
        random_array = RngUtility3D.random_vector_3d().to_array()
        mean_weight = 0.25 + 3.75 * alignment
        random_weight = max(0.05, 1.0 - alignment)
        blended = mean_weight * mean_array + random_weight * random_array
        norm = np.linalg.norm(blended)
        if norm <= 1e-8:
            return Vector(*mean_array)
        return Vector(*(blended / norm))

    @staticmethod
    def generate_endpoint_constrained_curve_3d(
        start,
        end,
        n_segments: int,
        segment_length: float,
        straightness: float,
        max_angle_change: float,
        curvature_scale: float = 1.0,
    ):
        if n_segments <= 0:
            return [start, end]

        start_arr = start.to_array().astype(float)
        end_arr = end.to_array().astype(float)
        chord = end_arr - start_arr
        chord_length = float(np.linalg.norm(chord))
        if chord_length <= 1e-8:
            line = np.repeat(start_arr[np.newaxis, :], n_segments + 1, axis=0)
            return [Vector(*point) for point in line]

        target_length = max(chord_length, float(n_segments) * float(segment_length))
        straightness = float(np.clip(straightness, 0.0, 1.0))
        if n_segments == 1 or straightness >= 0.999:
            line = np.linspace(start_arr, end_arr, n_segments + 1)
            return [Vector(*point) for point in line]

        main_direction = Vector(*chord).normalize()
        basis_u, basis_v = RngUtility3D.orthonormal_basis(main_direction)
        basis_u = basis_u.to_array()
        basis_v = basis_v.to_array()

        sample_count = max(16, n_segments * 4)
        t_values = np.linspace(0.0, 1.0, sample_count + 1)
        line = start_arr[np.newaxis, :] + t_values[:, np.newaxis] * chord[np.newaxis, :]

        waviness_factor = max(0.0, 1.0 - straightness)
        turn_factor = float(np.clip(max_angle_change / 45.0, 0.25, 2.0))
        curvature_factor = max(0.1, float(curvature_scale))
        base_amplitude = chord_length * 0.18 * waviness_factor * turn_factor * curvature_factor
        if base_amplitude <= 1e-8:
            resampled_line = RngUtility3D.resample_polyline(line, n_segments)
            resampled_line[0] = start_arr
            resampled_line[-1] = end_arr
            return [Vector(*point) for point in resampled_line]

        offset_u = np.zeros_like(t_values)
        offset_v = np.zeros_like(t_values)
        for mode in (1, 2, 3):
            decay = 1.0 / (mode * mode)
            offset_u += np.random.normal(0.0, base_amplitude * decay) * np.sin(np.pi * mode * t_values)
            offset_v += np.random.normal(0.0, base_amplitude * decay) * np.sin(np.pi * mode * t_values)

        offset_field = offset_u[:, np.newaxis] * basis_u[np.newaxis, :] + offset_v[:, np.newaxis] * basis_v[np.newaxis, :]

        if target_length > chord_length + 1e-6:
            low_scale = 0.0
            high_scale = 4.0
            for _ in range(14):
                mid_scale = (low_scale + high_scale) / 2.0
                candidate = line + mid_scale * offset_field
                candidate_length = RngUtility3D.polyline_length(candidate)
                if candidate_length < target_length:
                    low_scale = mid_scale
                else:
                    high_scale = mid_scale
            curve = line + low_scale * offset_field
        else:
            curve = line

        resampled_curve = RngUtility3D.resample_polyline(curve, n_segments)
        resampled_curve[0] = start_arr
        resampled_curve[-1] = end_arr
        return [Vector(*point) for point in resampled_curve]

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

def distribution_from_dict(dist_dict, fallback):
    """Create a Distribution from a dict, falling back to the provided instance."""
    if dist_dict is None:
        return fallback
    dist_type = dist_dict.get("type", getattr(fallback, "typename", None))
    if dist_type == Gaussian.typename:
        return Gaussian.from_dict(dist_dict)
    if dist_type == Uniform.typename:
        return Uniform.from_dict(dist_dict)
    if dist_type == PiecewiseLinear.typename:
        return PiecewiseLinear.from_dict(dist_dict)
    return fallback
                
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
        def __init__(
            self,
            segment_length=10.0,
            width_change=0.0,
            n_segments=15,
            start_width=1.0,
            straightness=1.0,
            start=None,
            end=None,
            min_angle_change=15,
            max_angle_change=45,
            curvature_scale=1.0,
        ):
            self.segment_length = segment_length
            self.width_change = width_change
            self.n_segments = n_segments
            self.start_width = start_width
            self.straightness = straightness
            self.start = start if start else Vector()
            self.end = end if end else Vector()
            self.min_angle_change = min_angle_change
            self.max_angle_change = max_angle_change
            self.curvature_scale = curvature_scale

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
                min_angle_change=params_dict.get("minAngleChange", 15),
                max_angle_change=params_dict.get("maxAngleChange", 45),
                curvature_scale=params_dict.get("curvatureScale", 1.0),
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
                "minAngleChange": self.min_angle_change,
                "maxAngleChange": self.max_angle_change,
                "curvatureScale": self.curvature_scale,
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
        self.intensity = None

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
        self.abort_flag = False

        self.points = RngUtility3D.generate_endpoint_constrained_curve_3d(
            self.params.start,
            self.params.end,
            self.params.n_segments,
            self.params.segment_length,
            self.params.straightness,
            self.params.max_angle_change,
            getattr(self.params, "curvature_scale", 1.0),
        )
        width = self.params.start_width
        self.widths = []

        for i in range(self.params.n_segments):
            if self.abort_flag:
                return
            self.widths.append(width)
            variability = min(abs(width), self.params.width_change)
            width += RngUtility.next_double(-variability, variability)
            QCoreApplication.processEvents()

        self.calculate_orientations()

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
            "orientations_xz": self.orientations_xz,
            "intensity": self.intensity
        }

    @staticmethod
    def from_dict(fiber_dict):
        params = Fiber.Params.from_dict(fiber_dict["params"])
        points = [Vector(p["x"], p["y"], p["z"]) for p in fiber_dict["points"]]
        widths = fiber_dict["widths"]
        fiber = Fiber(params)
        fiber.points = points
        fiber.widths = widths
        fiber.intensity = fiber_dict.get("intensity", None)
        return fiber

class FiberImage:
    class Params:
        def __init__(self):
            self.nFibers = Param(value=15, name="number of fibers", hint="The number of fibers per image to generate")
            self.segmentLength = Param(value=10.0, name="segment length", hint="The length in pixels of fiber segments")
            self.alignment = Param(value=0.5, name="alignment", hint="A value between 0 and 1 indicating how close fibers are to the mean angle on average")
            self.meanAngle = Param(value=90.0, name="mean angle", hint="The average fiber angle in degrees")
            self.widthChange = Param(value=0.0, name="width change", hint="The maximum segment-to-segment width change of a fiber in pixels")
            self.generateCenterlineLabel = Param(value=True, name="generate centerline mask", hint="Generate a binary centerline mask derived from the fiber structure.")
            self.generateFiberImage = Param(value=True, name="generate fiber image", hint="Generate a fiber image derived from the fiber structure.")
            self.centerlineOutputType = Param(value="Binary", name="centerline mask output", hint="Binary centerline mask output format.")
            self.renderMode = Param(value="Fiber Mode", name="render mode", hint="Controls whether output is a realistic fiber image or a segmentation-style mask.")
            self.centerlineMaskWidthPx = Param(value=1, name="centerline mask width", hint="The rendered width in pixels of the centerline mask.")
            self.maskOutputMode = Param(value="Binary", name="mask output", hint="Legacy binary centerline mask output format.")
            self.imageWidth = Param(value=512, name="image width", hint="The width of the saved image in pixels")
            self.imageHeight = Param(value=512, name="image height", hint="The height of the saved image in pixels")
            self.imageBuffer = Param(value=5, name="edge buffer", hint="The size in pixels of the empty border around the edge of the image")
            self.jointPoints = Param(value=3, name="joint points", hint="The number of joint points to generate")
            self.showJoints = Optional(value=None, name="Show joints", hint="Check to display joint points on the image", use=False)
            self.showCenterlineOverlay = Optional(value=None, name="Show centerline overlay", hint="Overlay a centerline trace over the rendered fiber image", use=False)
            self.centerlineOverlayColor = Param(value="Neon Green", name="centerline overlay color", hint="Display color for the centerline overlay")
            self.centerlineOverlayBrightness = Param(value=1.2, name="centerline overlay brightness", hint="Brightness multiplier for the centerline overlay")
            self.useJoints = Optional(value=True, name="Use joints", hint="Toggle to use joint point constraints during generation", use=True)


            self.length = Uniform(0.0, float('inf'), 15.0, 200.0)
            self.width = Gaussian(0.0, float('inf'), 5.0, 0.5)
            self.straightness = Uniform(0.0, 1.0, 0.9, 1.0)
            self.intensity = Gaussian(0.0, 255.0, 200.0, 30.0)

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
            if "generateCenterlineLabel" in params_dict:
                params.generateCenterlineLabel = Param.from_dict(params_dict["generateCenterlineLabel"])
            if "generateFiberImage" in params_dict:
                params.generateFiberImage = Param.from_dict(params_dict["generateFiberImage"])
            if "centerlineOutputType" in params_dict:
                params.centerlineOutputType = Param.from_dict(params_dict["centerlineOutputType"])
            if "renderMode" in params_dict:
                params.renderMode = Param.from_dict(params_dict["renderMode"])
            if "centerlineMaskWidthPx" in params_dict:
                params.centerlineMaskWidthPx = Param.from_dict(params_dict["centerlineMaskWidthPx"])
            elif "maskType" in params_dict:
                params.centerlineMaskWidthPx.value = 1
            if "maskOutputMode" in params_dict:
                params.maskOutputMode = Param.from_dict(params_dict["maskOutputMode"])
            elif "maskBinary" in params_dict:
                legacy_mask_binary = Param.from_dict(params_dict["maskBinary"])
                params.maskOutputMode.value = "Binary"
            if "generateCenterlineLabel" not in params_dict and "generateFiberImage" not in params_dict:
                legacy_render_mode = str(params.renderMode.get_value()).strip().lower()
                params.generateCenterlineLabel.value = legacy_render_mode == "mask mode"
                params.generateFiberImage.value = legacy_render_mode != "mask mode"
            params.centerlineOutputType.value = "Binary"
            params.maskOutputMode.value = "Binary"
            params.jointPoints = Param.from_dict(params_dict["jointPoints"])
            params.showJoints = Optional.from_dict(params_dict["showJoints"])
            if "showCenterlineOverlay" in params_dict:
                params.showCenterlineOverlay = Optional.from_dict(params_dict["showCenterlineOverlay"])
            if "centerlineOverlayColor" in params_dict:
                params.centerlineOverlayColor = Param.from_dict(params_dict["centerlineOverlayColor"])
            if "centerlineOverlayBrightness" in params_dict:
                params.centerlineOverlayBrightness = Param.from_dict(params_dict["centerlineOverlayBrightness"])
            params.useJoints = Optional.from_dict(params_dict["useJoints"])          
            params.alignment = Param.from_dict(params_dict["alignment"])
            params.meanAngle = Param.from_dict(params_dict["meanAngle"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            params.length = distribution_from_dict(params_dict.get("length"), params.length)
            params.width = distribution_from_dict(params_dict.get("width"), params.width)
            params.straightness = distribution_from_dict(params_dict.get("straightness"), params.straightness)
            if "intensity" in params_dict:
                params.intensity = distribution_from_dict(params_dict.get("intensity"), params.intensity)
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

        def sync_legacy_output_fields(self):
            generate_centerline = bool(self.generateCenterlineLabel.get_value())
            generate_fiber = bool(self.generateFiberImage.get_value())
            self.centerlineOutputType.value = "Binary"
            self.maskOutputMode.value = "Binary"
            self.renderMode.value = "Mask Mode" if generate_centerline and not generate_fiber else "Fiber Mode"

        def to_dict(self):
            self.sync_legacy_output_fields()
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "generateCenterlineLabel": self.generateCenterlineLabel.to_dict(),
                "generateFiberImage": self.generateFiberImage.to_dict(),
                "centerlineOutputType": self.centerlineOutputType.to_dict(),
                "renderMode": self.renderMode.to_dict(),
                "centerlineMaskWidthPx": self.centerlineMaskWidthPx.to_dict(),
                "maskOutputMode": self.maskOutputMode.to_dict(),
                "jointPoints": self.jointPoints.to_dict(),
                "showJoints": self.showJoints.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
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
                "intensity": self.intensity.to_dict(),
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
            self.generateCenterlineLabel.set_name("generate centerline mask")
            self.generateFiberImage.set_name("generate fiber image")
            self.centerlineOutputType.set_name("centerline mask output")
            self.renderMode.set_name("render mode")
            self.centerlineMaskWidthPx.set_name("centerline mask width")
            self.maskOutputMode.set_name("mask output")
            self.jointPoints.set_name("joint points")
            self.useJoints.set_name("Use joints")
            self.showJoints.set_name("Show Joints")   
            self.showCenterlineOverlay.set_name("Show centerline overlay")
            self.centerlineOverlayColor.set_name("centerline overlay color")
            self.centerlineOverlayBrightness.set_name("centerline overlay brightness")
            self.alignment.set_name("alignment")
            self.meanAngle.set_name("mean angle")
            self.widthChange.set_name("width change")
            self.imageWidth.set_name("image width")
            self.imageHeight.set_name("image height")
            self.imageBuffer.set_name("edge buffer")

            self.length.set_names()
            self.straightness.set_names()
            self.width.set_names()
            self.intensity.set_names()

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
            self.generateCenterlineLabel.set_hint("Generate a binary centerline mask derived from the fiber structure.")
            self.generateFiberImage.set_hint("Generate a fiber image derived from the fiber structure.")
            self.centerlineOutputType.set_hint("Binary centerline mask output format.")
            self.renderMode.set_hint("Controls whether output is a realistic fiber image or a segmentation-style mask.")
            self.centerlineMaskWidthPx.set_hint("The rendered width in pixels of the centerline mask.")
            self.maskOutputMode.set_hint("Legacy binary centerline mask output format.")
            self.jointPoints.set_hint("The number of joint points in the fiber network")
            self.useJoints.set_hint("Toggle to use joint point constraints during generation")
            self.showJoints.set_hint("Check to display joint points on the image")
            self.showCenterlineOverlay.set_hint("Overlay a centerline trace over the rendered fiber image")
            self.centerlineOverlayColor.set_hint("Display color for the centerline overlay")
            self.centerlineOverlayBrightness.set_hint("Brightness multiplier for the centerline overlay")
            self.alignment.set_hint("A value between 0 and 1 indicating how close fibers are to the mean angle on average")
            self.meanAngle.set_hint("The average fiber angle in degrees")
            self.widthChange.set_hint("The maximum segment-to-segment width change of a fiber in pixels")
            self.imageWidth.set_hint("The width of the saved image in pixels")
            self.imageHeight.set_hint("The height of the saved image in pixels")
            self.imageBuffer.set_hint("The size in pixels of the empty border around the edge of the image")

            self.length.set_hints()
            self.straightness.set_hints()
            self.width.set_hints()
            self.intensity.set_hints()

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
            self.sync_legacy_output_fields()
            self.nFibers.verify(0, Param.greater)
            self.segmentLength.verify(0.0, Param.greater)
            if self.useJoints.use:
                self.jointPoints.verify(0, Param.greater_eq)
            self.widthChange.verify(0.0, Param.greater_eq)
            if not bool(self.generateCenterlineLabel.get_value()) and not bool(self.generateFiberImage.get_value()):
                raise ValueError("At least one derived output must be enabled")
            if str(self.centerlineOutputType.get_value()).strip().lower() != "binary":
                raise ValueError("Value of \"centerline mask output\" must be 'binary'")
            allowed_render_modes = {"fiber mode", "mask mode"}
            render_mode = str(self.renderMode.get_value()).strip().lower()
            if render_mode not in allowed_render_modes:
                raise ValueError(f"Value of \"render mode\" must be one of {sorted(list(allowed_render_modes))}")
            self.centerlineMaskWidthPx.verify(0, Param.greater)
            mask_output_mode = str(self.maskOutputMode.get_value()).strip().lower()
            if mask_output_mode != "binary":
                raise ValueError("Value of \"mask output\" must be 'binary'")
            self.alignment.verify(0.0, Param.greater_eq)
            self.alignment.verify(1.0, Param.less_eq)
            self.meanAngle.verify(0.0, Param.greater_eq)
            self.meanAngle.verify(180.0, Param.less_eq)

            self.imageWidth.verify(0, Param.greater)
            self.imageHeight.verify(0, Param.greater)
            self.imageBuffer.verify(0, Param.greater)
            self.centerlineOverlayBrightness.verify(0.0, Param.greater)

            allowed_centerline_colors = {"green", "neon green", "cyan", "magenta", "yellow"}
            centerline_color = str(self.centerlineOverlayColor.get_value()).strip().lower()
            if centerline_color not in allowed_centerline_colors:
                raise ValueError(f"Value of \"centerline overlay color\" must be one of {sorted(list(allowed_centerline_colors))}")

            self.length.verify()
            self.straightness.verify()
            self.width.verify()
            self.intensity.verify()

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

    @staticmethod
    def should_generate_centerline_label(params):
        if hasattr(params, "generateCenterlineLabel"):
            return bool(getattr(params.generateCenterlineLabel, "value", True))
        return str(getattr(params.renderMode, "value", "Fiber Mode")).strip().lower() == "mask mode"

    @staticmethod
    def should_generate_fiber_image(params):
        if hasattr(params, "generateFiberImage"):
            return bool(getattr(params.generateFiberImage, "value", True))
        return str(getattr(params.renderMode, "value", "Fiber Mode")).strip().lower() != "mask mode"

    @staticmethod
    def get_centerline_output_mode(params):
        return "binary"

    @staticmethod
    def is_binary_centerline_output(params):
        return True

    @staticmethod
    def is_mask_mode(params):
        return FiberImage.should_generate_centerline_label(params) and not FiberImage.should_generate_fiber_image(params)

    @staticmethod
    def get_mask_output_mode(params):
        return FiberImage.get_centerline_output_mode(params)

    @staticmethod
    def is_binary_mask_output(params):
        return FiberImage.is_binary_centerline_output(params)

    @staticmethod
    def _preview_only_export_param_keys():
        return {
            "showJoints",
            "showCenterlineOverlay",
            "centerlineOverlayColor",
            "centerlineOverlayBrightness",
        }

    @staticmethod
    def _legacy_export_param_keys():
        return {
            "centerlineOutputType",
            "renderMode",
            "maskOutputMode",
        }

    @staticmethod
    def _gaussian_psf_export_param_keys():
        return {
            "psfGaussianNA",
            "psfGaussianWavelength",
            "psfPixelSizeZ",
            "psfPixelSizeY",
            "psfPixelSizeX",
        }

    @staticmethod
    def _vectorial_psf_export_param_keys():
        return {
            "psfVectorialNA",
            "psfVectorialMediumRI",
            "psfVectorialSampleRI",
            "psfVectorialWavelength",
            "psfVectorialPolarization",
            "psfVectorialVolumeZ",
            "psfVectorialVolumeY",
            "psfVectorialVolumeX",
            "psfVectorialShapeZ",
            "psfVectorialShapeY",
            "psfVectorialShapeX",
        }

    @staticmethod
    def _fiber_only_export_param_keys():
        return {
            "intensity",
            "scale",
            "downSample",
            "blur",
            "blurRadius",
            "noise",
            "noiseMean",
            "noiseModel",
            "noiseStdDev",
            "saltPepperProb",
            "distance",
            "distanceFalloff",
            "cap",
            "normalize",
            "psfEnabled",
            "psfType",
            *FiberImage._gaussian_psf_export_param_keys(),
            *FiberImage._vectorial_psf_export_param_keys(),
        }

    def should_export_generation_param(self, key, raw_value):
        params = self.params
        generate_centerline = FiberImage.should_generate_centerline_label(params)
        generate_fiber = FiberImage.should_generate_fiber_image(params)
        noise_model = str(params.noiseModel.get_value()).strip().lower() if hasattr(params, "noiseModel") else "no noise"
        noise_enabled = FiberImage.should_apply_noise(params, is_3d=hasattr(params, "imageDepth"))
        psf_type = str(params.psfType.get_value()).strip().lower() if hasattr(params, "psfType") else "none"
        psf_enabled = bool(getattr(getattr(params, "psfEnabled", None), "use", False)) and psf_type != "none"

        if key in FiberImage._preview_only_export_param_keys() or key in FiberImage._legacy_export_param_keys():
            return False
        if key == "generateCenterlineLabel":
            return generate_centerline
        if key == "generateFiberImage":
            return generate_fiber
        if key == "centerlineMaskWidthPx":
            return generate_centerline
        if key in FiberImage._fiber_only_export_param_keys() and not generate_fiber:
            return False
        if key == "noiseModel":
            return generate_fiber and noise_enabled and noise_model != "no noise"
        if key in {"noise", "noiseMean"}:
            return generate_fiber and noise_model in {"poisson", "poisson+gaussian"}
        if key == "noiseStdDev":
            return generate_fiber and noise_model in {"gaussian", "poisson+gaussian"}
        if key == "saltPepperProb":
            return generate_fiber and noise_model == "salt-and-pepper"
        if key == "psfEnabled":
            return generate_fiber and psf_enabled
        if key == "psfType":
            return generate_fiber and psf_enabled
        if key in FiberImage._gaussian_psf_export_param_keys():
            return generate_fiber and psf_enabled and psf_type == "3d gaussian"
        if key in FiberImage._vectorial_psf_export_param_keys():
            return generate_fiber and psf_enabled and psf_type == "vectorial (shg)"
        if isinstance(raw_value, dict) and "use" in raw_value and not raw_value.get("use", False):
            return False
        return True

    def get_generation_parameter_description(self, key):
        descriptions = {
            "length": "Distribution used to sample fiber lengths.",
            "width": "Distribution used to sample fiber widths.",
            "straightness": "Distribution used to sample fiber straightness.",
            "intensity": "Distribution used to sample Fiber Image intensities.",
        }
        if key in descriptions:
            return descriptions[key]
        attr = getattr(self.params, key, None)
        if hasattr(attr, "get_hint"):
            return attr.get_hint()
        return "Applied parameter value."

    @staticmethod
    def get_mask_line_width(params):
        try:
            width_value = int(round(float(getattr(params.centerlineMaskWidthPx, "value", 1))))
        except (TypeError, ValueError):
            width_value = 1
        return max(1, width_value)

    @staticmethod
    def render_fibers_to_image(fibers, size, default_intensity=255.0, binary=False, line_width_override=None):
        """Render fibers into a grayscale image for either realistic output or label masks."""
        width, height = size
        base = np.zeros((height, width), dtype=np.float32)
        for fiber in fibers:
            intensity = 255.0 if binary else getattr(fiber, "intensity", default_intensity)
            if intensity is None:
                intensity = default_intensity
            try:
                intensity = float(intensity)
            except (TypeError, ValueError):
                intensity = default_intensity
            if intensity <= 0:
                continue
            intensity = max(0.0, min(255.0, intensity))
            overlay = Image.new('L', (width, height), 0)
            draw = ImageDraw.Draw(overlay)
            for segment in fiber:
                if line_width_override is not None:
                    line_width = max(1, int(round(float(line_width_override))))
                else:
                    line_width = max(1, int(round(float(segment.width))))
                draw.line(
                    [(segment.start.x, segment.start.y), (segment.end.x, segment.end.y)],
                    fill=int(round(intensity)),
                    width=line_width
                )
            overlay_np = np.array(overlay, dtype=np.float32)
            if binary:
                base = np.maximum(base, overlay_np)
            else:
                base += overlay_np
        base = np.clip(base, 0, 255).astype(np.uint8)
        return Image.fromarray(base, 'L')

    def render_fiber_image_2d(self):
        return self.render_fibers_to_image(
            self.fibers,
            (self.params.imageWidth.get_value(), self.params.imageHeight.get_value())
        )

    def render_centerline_label_2d(self):
        base_image = self.render_fibers_to_image(
            self.fibers,
            (self.params.imageWidth.get_value(), self.params.imageHeight.get_value()),
            default_intensity=255.0,
            binary=True,
            line_width_override=self.get_mask_line_width(self.params)
        )
        np_image = np.array(base_image, dtype=np.float32)
        np_image = (np_image > 127).astype(np.uint8) * 255
        return Image.fromarray(np.clip(np_image, 0, 255).astype(np.uint8), 'L')

    def render_base_image_2d(self):
        return self.render_fiber_image_2d()

    @staticmethod
    def add_noise_to_array(np_image, params):
        model = str(params.noiseModel.get_value()).lower()
        output = np.asarray(np_image, dtype=np.float32).copy()
        if model == "poisson":
            mean = float(params.noise.get_value())
            noise = poisson(mean).rvs(output.size).reshape(output.shape)
            output = output + noise
        elif model == "gaussian":
            std = float(params.noiseStdDev.get_value())
            noise = np.random.normal(0.0, std, size=output.shape)
            output = output + noise
        elif model == "salt-and-pepper":
            p = float(params.saltPepperProb.get_value())
            rnd = np.random.rand(*output.shape)
            output[rnd < (p / 2.0)] = 0.0
            output[rnd > 1.0 - (p / 2.0)] = 255.0
        elif model == "speckle":
            speckle = np.random.normal(1.0, 0.2, size=output.shape)
            output = output * speckle
        elif model == "poisson+gaussian":
            mean = float(params.noise.get_value())
            p_noise = poisson(mean).rvs(output.size).reshape(output.shape)
            g_std = float(params.noiseStdDev.get_value())
            g_noise = np.random.normal(0.0, g_std, size=output.shape)
            output = output + p_noise + g_noise
        return np.clip(output, 0, 255).astype(np.uint8)

    @staticmethod
    def should_apply_noise(params, is_3d=False):
        model = str(params.noiseModel.get_value()).lower()
        if model == "poisson":
            noise_param = params.noiseMean if is_3d and hasattr(params, "noiseMean") else params.noise
            return noise_param.use
        if model == "gaussian":
            return params.noiseStdDev.use
        if model == "salt-and-pepper":
            return params.saltPepperProb.use
        if model == "speckle":
            return True
        if model == "poisson+gaussian":
            noise_param = params.noiseMean if is_3d and hasattr(params, "noiseMean") else params.noise
            return noise_param.use or params.noiseStdDev.use
        return False

    @staticmethod
    def draw_scale_bar_on_image(image, params):
        if not hasattr(params, "scale") or not params.scale.use:
            return image
        output = image.copy()
        target_size = FiberImage.TARGET_SCALE_SIZE * output.width / params.scale.get_value()
        floor_pow = np.floor(np.log10(target_size))
        options = [10**floor_pow, 5 * 10**floor_pow, 10**(floor_pow + 1)]
        best_size = min(options, key=lambda x: abs(target_size - x))

        if abs(np.floor(np.log10(best_size))) <= 2:
            label = f"{best_size:.2f} µ"
        else:
            label = f"{best_size:.1e} µ"

        cap_size = int(FiberImage.CAP_RATIO * output.height)
        x_buff = int(FiberImage.BUFF_RATIO * output.width)
        y_buff = int(FiberImage.BUFF_RATIO * output.height)
        scale_height = output.height - y_buff - cap_size
        scale_right = x_buff + int(best_size * params.scale.get_value())

        draw = ImageDraw.Draw(output)
        draw.line((x_buff, scale_height, scale_right, scale_height), fill=255)
        draw.line((x_buff, scale_height + cap_size, x_buff, scale_height - cap_size), fill=255)
        draw.line((scale_right, scale_height + cap_size, scale_right, scale_height - cap_size), fill=255)
        draw.text((x_buff, scale_height - cap_size - y_buff), label, fill=255)
        return output

    @classmethod
    def apply_postprocessing_2d(cls, image, params):
        np_image = np.array(image, dtype=np.float32)
        mask_mode = cls.is_mask_mode(params)
        binary_mask = mask_mode and cls.is_binary_mask_output(params)

        if binary_mask:
            thresholded = (np_image > 127).astype(np.uint8) * 255
            return Image.fromarray(thresholded, 'L')

        if params.distance.use:
            np_image = ImageUtility.distance_function(Image.fromarray(np.clip(np_image, 0, 255).astype(np.uint8), 'L'), params.distance.get_value())
            np_image = np.array(np_image, dtype=np.float32)

        if not mask_mode and getattr(params, "psfEnabled", None) and params.psfEnabled.use:
            manager = PSFManager(params)
            psf_result = manager.apply(np_image, volume=False)
            if psf_result is not None:
                np_image = psf_result.astype(np.float32)

        if (not mask_mode or not binary_mask) and cls.should_apply_noise(params, is_3d=False):
            np_image = cls.add_noise_to_array(np_image, params).astype(np.float32)

        if params.blur.use:
            np_image = gaussian_filter(np_image, sigma=params.blur.get_value())

        if params.cap.use:
            np_image = np.clip(np_image, 0, params.cap.get_value())

        if params.normalize.use:
            max_value = np.max(np_image)
            if max_value > 0:
                np_image = np_image * float(params.normalize.get_value()) / max_value

        np_image = np.clip(np_image, 0, 255)
        mode = 'L'
        output = Image.fromarray(np_image.astype(np.uint8), mode)

        if not mask_mode and params.scale.use:
            output = cls.draw_scale_bar_on_image(output, params)

        if params.downSample.use:
            new_size = (
                int(output.width * params.downSample.get_value()),
                int(output.height * params.downSample.get_value())
            )
            resize_mode = Image.NEAREST if mask_mode else Image.BILINEAR
            output = output.resize(new_size, resize_mode)

        return output
    
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
            if not self.should_export_generation_param(k, v):
                continue

            # Special-case noise model: include formatted value with parameters
            if k == 'noiseModel' and noise_model_value is not None:
                params_data.append({"Parameter": k, "Value": noise_model_value})
                continue

            if isinstance(v, dict):
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
                if hasattr(self.params, "intensity"):
                    fiber.intensity = self.params.intensity.sample()
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
        self.image = self.render_base_image_2d()

    def apply_effects(self):
        self.image = self.apply_postprocessing_2d(self.image, self.params)

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
        self.image = self.draw_scale_bar_on_image(self.image, self.params)

    def add_noise(self):
        model = str(self.params.noiseModel.get_value()).lower()
        if model == "no noise":
            return
        np_image = self.add_noise_to_array(np.array(self.image, dtype=np.float32), self.params)
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
            self.segmentLength.value = 6.0
            self.width.mean.value = 3.0
            self.width.sigma.value = 0.75
            self.straightness.min.value = 0.94
            self.straightness.max.value = 0.99
            self.imageDepth = Param(value=512, name="image depth", hint="The depth of the saved volume in pixels")
            self.curvature = Param(value=0.8, name="curvature", hint="The curvature of fibers in 3D")
            self.branchingProbability = Param(value=0.1, name="branching probability", hint="The probability of fibers branching")
            self.meanDirection = Param(value=[0.0, 0.0, 1.0], name="mean direction", hint="The average fiber direction as a 3D vector")
            self.blurRadius = Optional(value=5.0, name="blur radius", hint="Check to enable Gaussian blurring; value is the radius of the blur in pixels", use=False)
            self.noiseMean = Optional(value=10.0, name="noise mean", hint="Check to add Poisson noise; value is the Poisson mean on a scale of 0 (black) to 255 (white)", use=False)
            self.distanceFalloff = Optional(value=64.0, name="distance falloff", hint="Check to apply a distance filter; value controls the sharpness of the intensity falloff", use=False)
            self.alignment3D = Param(value=0.65, name="alignment", hint="A value between 0 and 1 indicating how close fibers are to the mean direction on average")
            self.minAngleChange = Param(value=0.0, name="min angle change", hint="Minimum angle change in degrees")
            self.maxAngleChange = Param(value=20.0, name="max angle change", hint="Maximum angle change in degrees")
            self.blur = self.blurRadius
            self.noise = self.noiseMean
            self.distance = self.distanceFalloff
            self.min_angle_change = self.minAngleChange
            self.max_angle_change = self.maxAngleChange
            
        @staticmethod
        def from_dict(params_dict):
            params = FiberImage3D.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            if "generateCenterlineLabel" in params_dict:
                params.generateCenterlineLabel = Param.from_dict(params_dict["generateCenterlineLabel"])
            if "generateFiberImage" in params_dict:
                params.generateFiberImage = Param.from_dict(params_dict["generateFiberImage"])
            if "centerlineOutputType" in params_dict:
                params.centerlineOutputType = Param.from_dict(params_dict["centerlineOutputType"])
            if "renderMode" in params_dict:
                params.renderMode = Param.from_dict(params_dict["renderMode"])
            if "centerlineMaskWidthPx" in params_dict:
                params.centerlineMaskWidthPx = Param.from_dict(params_dict["centerlineMaskWidthPx"])
            elif "maskType" in params_dict:
                params.centerlineMaskWidthPx.value = 1
            if "maskOutputMode" in params_dict:
                params.maskOutputMode = Param.from_dict(params_dict["maskOutputMode"])
            elif "maskBinary" in params_dict:
                legacy_mask_binary = Param.from_dict(params_dict["maskBinary"])
                params.maskOutputMode.value = "Binary"
            if "generateCenterlineLabel" not in params_dict and "generateFiberImage" not in params_dict:
                legacy_render_mode = str(params.renderMode.get_value()).strip().lower()
                params.generateCenterlineLabel.value = legacy_render_mode == "mask mode"
                params.generateFiberImage.value = legacy_render_mode != "mask mode"
            params.centerlineOutputType.value = "Binary"
            params.maskOutputMode.value = "Binary"
            params.alignment3D = Param.from_dict(params_dict["alignment3D"])
            params.meanDirection = Param.from_dict(params_dict["meanDirection"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageDepth = Param.from_dict(params_dict["imageDepth"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            if "showCenterlineOverlay" in params_dict:
                params.showCenterlineOverlay = Optional.from_dict(params_dict["showCenterlineOverlay"])
            if "centerlineOverlayColor" in params_dict:
                params.centerlineOverlayColor = Param.from_dict(params_dict["centerlineOverlayColor"])
            if "centerlineOverlayBrightness" in params_dict:
                params.centerlineOverlayBrightness = Param.from_dict(params_dict["centerlineOverlayBrightness"])
            params.length = distribution_from_dict(params_dict.get("length"), params.length)
            params.width = distribution_from_dict(params_dict.get("width"), params.width)
            params.straightness = distribution_from_dict(params_dict.get("straightness"), params.straightness)
            if "intensity" in params_dict:
                params.intensity = distribution_from_dict(params_dict.get("intensity"), params.intensity)
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
            params.minAngleChange = Param.from_dict(params_dict["minAngleChange"])
            params.maxAngleChange = Param.from_dict(params_dict["maxAngleChange"])
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
            params.blur = params.blurRadius
            params.noise = params.noiseMean
            params.distance = params.distanceFalloff
            params.min_angle_change = params.minAngleChange
            params.max_angle_change = params.maxAngleChange
            return params

        def to_dict(self):
            self.sync_legacy_output_fields()
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "generateCenterlineLabel": self.generateCenterlineLabel.to_dict(),
                "generateFiberImage": self.generateFiberImage.to_dict(),
                "centerlineOutputType": self.centerlineOutputType.to_dict(),
                "renderMode": self.renderMode.to_dict(),
                "centerlineMaskWidthPx": self.centerlineMaskWidthPx.to_dict(),
                "maskOutputMode": self.maskOutputMode.to_dict(),
                "alignment3D": self.alignment3D.to_dict(),
                "meanDirection": self.meanDirection.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageDepth": self.imageDepth.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "intensity": self.intensity.to_dict(),
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
            self.imageDepth.set_name("image depth")
            self.curvature.set_name("curvature")
            self.branchingProbability.set_name("branching probability")
            self.meanDirection.set_name("mean direction")
            self.blurRadius.set_name("blur radius")
            self.noiseMean.set_name("noise mean")
            self.distanceFalloff.set_name("distance falloff")
            self.alignment3D.set_name("alignment")
            self.minAngleChange.set_name("min angle change")
            self.maxAngleChange.set_name("max angle change")

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
            self.minAngleChange.set_hint("Minimum angle change between segments in degrees")
            self.maxAngleChange.set_hint("Maximum angle change between segments in degrees")

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
            self.minAngleChange.verify(0.0, Param.greater_eq)
            self.minAngleChange.verify(180.0, Param.less_eq)
            self.maxAngleChange.verify(0.0, Param.greater_eq)
            self.maxAngleChange.verify(180.0, Param.less_eq)

    def __init__(self, params):
        super().__init__(params)
        self.image = np.zeros((params.imageDepth.get_value(), params.imageHeight.get_value(), params.imageWidth.get_value()), dtype=np.uint8)
        self.topology_links = []
        self.validation_metrics = {}

    def to_dict(self):
        return {
            "params": self.params.to_dict(),
            "fibers": [fiber.to_dict() for fiber in self.fibers],
            "joint_points": [{"x": point.x, "y": point.y, "z": point.z} for point in self.joint_points],
            "topology_links": self.topology_links,
            "validation_metrics": self.validation_metrics,
        }

    @staticmethod
    def from_dict(fiber_image_dict):
        params = FiberImage3D.Params.from_dict(fiber_image_dict["params"])
        fiber_image = FiberImage3D(params)
        fiber_image.fibers = [Fiber.from_dict(fiber_dict) for fiber_dict in fiber_image_dict["fibers"]]
        fiber_image.joint_points = [
            Vector(point.get("x", 0.0), point.get("y", 0.0), point.get("z", 0.0))
            for point in fiber_image_dict.get("joint_points", [])
        ]
        fiber_image.topology_links = list(fiber_image_dict.get("topology_links", []))
        fiber_image.validation_metrics = dict(fiber_image_dict.get("validation_metrics", {}))
        return fiber_image

    @staticmethod
    def _closest_point_on_segment_3d(point, start, end):
        point_arr = point.to_array().astype(float)
        start_arr = start.to_array().astype(float)
        end_arr = end.to_array().astype(float)
        seg = end_arr - start_arr
        seg_len_sq = float(np.dot(seg, seg))
        if seg_len_sq <= 1e-8:
            closest = start_arr
            t = 0.0
        else:
            t = float(np.clip(np.dot(point_arr - start_arr, seg) / seg_len_sq, 0.0, 1.0))
            closest = start_arr + t * seg
        distance = float(np.linalg.norm(point_arr - closest))
        return Vector(*closest), t, distance

    @staticmethod
    def _segment_segment_distance_3d(p0, p1, q0, q1):
        p0 = p0.to_array().astype(float)
        p1 = p1.to_array().astype(float)
        q0 = q0.to_array().astype(float)
        q1 = q1.to_array().astype(float)

        u = p1 - p0
        v = q1 - q0
        w0 = p0 - q0
        a = float(np.dot(u, u))
        b = float(np.dot(u, v))
        c = float(np.dot(v, v))
        d = float(np.dot(u, w0))
        e = float(np.dot(v, w0))
        denom = a * c - b * b
        eps = 1e-8

        if a <= eps and c <= eps:
            return float(np.linalg.norm(p0 - q0))
        if a <= eps:
            s = 0.0
            t = float(np.clip(e / c if c > eps else 0.0, 0.0, 1.0))
        elif c <= eps:
            t = 0.0
            s = float(np.clip(-d / a if a > eps else 0.0, 0.0, 1.0))
        else:
            if denom <= eps:
                s = 0.0
            else:
                s = float(np.clip((b * e - c * d) / denom, 0.0, 1.0))
            t = (b * s + e) / c
            if t < 0.0:
                t = 0.0
                s = float(np.clip(-d / a, 0.0, 1.0))
            elif t > 1.0:
                t = 1.0
                s = float(np.clip((b - d) / a, 0.0, 1.0))

        closest_p = p0 + s * u
        closest_q = q0 + t * v
        return float(np.linalg.norm(closest_p - closest_q))

    def _add_joint_point_unique_3d(self, point):
        key = tuple(int(round(coord * 4.0)) for coord in (point.x, point.y, point.z))
        if not hasattr(self, "_joint_point_keys_3d"):
            self._joint_point_keys_3d = set()
        if key not in self._joint_point_keys_3d:
            self._joint_point_keys_3d.add(key)
            self.joint_points.append(point)

    def _attach_endpoint_to_segment_3d(self, fiber, endpoint_index, joint_point, segment_start, segment_end):
        if len(fiber.points) < 2:
            return

        tangent = segment_end.subtract(segment_start)
        if tangent.is_zero():
            return
        tangent = tangent.normalize()

        if endpoint_index == 0:
            neighbor_index = 1
            old_direction = fiber.points[neighbor_index].subtract(fiber.points[0])
        else:
            neighbor_index = len(fiber.points) - 2
            old_direction = fiber.points[-1].subtract(fiber.points[neighbor_index])

        if old_direction.is_zero():
            old_direction = tangent
        else:
            old_direction = old_direction.normalize()

        if tangent.dot_product(old_direction) < 0:
            tangent = tangent.scalar_multiply(-1.0)

        blended_direction = tangent.scalar_multiply(0.6).add(old_direction.scalar_multiply(0.4))
        if blended_direction.is_zero():
            blended_direction = tangent
        else:
            blended_direction = blended_direction.normalize()

        segment_length = fiber.points[neighbor_index].subtract(fiber.points[endpoint_index]).length()
        segment_length = max(0.5, segment_length)

        fiber.points[endpoint_index] = Vector(joint_point.x, joint_point.y, joint_point.z)
        if endpoint_index == 0:
            fiber.points[neighbor_index] = joint_point.add(blended_direction.scalar_multiply(segment_length))
        else:
            fiber.points[neighbor_index] = joint_point.subtract(blended_direction.scalar_multiply(segment_length))

    def apply_topology_3d(self):
        self.topology_links = []
        self.joint_points = []
        self._joint_point_keys_3d = set()

        branch_probability = float(np.clip(self.params.branchingProbability.get_value(), 0.0, 1.0))
        if branch_probability <= 0.0 or len(self.fibers) < 2:
            return

        mean_width = float(self.params.width.mean.get_value()) if hasattr(self.params.width, "mean") else 0.0
        capture_radius = max(
            2.5,
            1.25 * float(self.params.segmentLength.get_value()),
            1.25 * mean_width,
        )
        target_links = max(0, int(round(branch_probability * len(self.fibers))))
        used_endpoints = set()
        linked_pairs = set()

        for _ in range(target_links):
            best_global_candidate = None

            for fiber_idx, fiber in enumerate(self.fibers):
                if len(fiber.points) < 2:
                    continue
                for endpoint_index in (0, len(fiber.points) - 1):
                    endpoint_key = (fiber_idx, 0 if endpoint_index == 0 else 1)
                    if endpoint_key in used_endpoints:
                        continue

                    endpoint = fiber.points[endpoint_index]
                    for other_idx, other_fiber in enumerate(self.fibers):
                        if other_idx == fiber_idx or len(other_fiber.points) < 2:
                            continue
                        pair_key = tuple(sorted((fiber_idx, other_idx)))
                        if pair_key in linked_pairs:
                            continue

                        for seg_idx in range(len(other_fiber.points) - 1):
                            seg_start = other_fiber.points[seg_idx]
                            seg_end = other_fiber.points[seg_idx + 1]
                            joint_point, t_value, distance = self._closest_point_on_segment_3d(endpoint, seg_start, seg_end)
                            if distance > capture_radius:
                                continue

                            interior_bonus = 0.35 if 0.1 < t_value < 0.9 else 0.0
                            endpoint_bonus = 0.1 if endpoint_index in (0, len(fiber.points) - 1) else 0.0
                            score = distance - interior_bonus - endpoint_bonus
                            if best_global_candidate is None or score < best_global_candidate[0]:
                                best_global_candidate = (
                                    score,
                                    fiber_idx,
                                    endpoint_index,
                                    other_idx,
                                    seg_idx,
                                    joint_point,
                                    seg_start,
                                    seg_end,
                                )

            if best_global_candidate is None:
                break

            _, fiber_idx, endpoint_index, other_idx, seg_idx, joint_point, seg_start, seg_end = best_global_candidate
            fiber = self.fibers[fiber_idx]
            self._attach_endpoint_to_segment_3d(fiber, endpoint_index, joint_point, seg_start, seg_end)
            fiber.has_joint = True
            self.fibers[other_idx].has_joint = True
            self._add_joint_point_unique_3d(joint_point)
            self.topology_links.append({
                "fiber_id": fiber_idx,
                "connected_fiber_id": other_idx,
                "segment_index": seg_idx,
                "x": joint_point.x,
                "y": joint_point.y,
                "z": joint_point.z,
            })
            used_endpoints.add((fiber_idx, 0 if endpoint_index == 0 else 1))
            linked_pairs.add(tuple(sorted((fiber_idx, other_idx))))

    def count_joints(self):
        if self.topology_links:
            return list(self.joint_points)
        return []

    @staticmethod
    def _count_graph_components(node_count, edge_pairs):
        if node_count <= 0:
            return 0
        adjacency = {i: set() for i in range(node_count)}
        for left, right in edge_pairs:
            adjacency[left].add(right)
            adjacency[right].add(left)
        visited = set()
        components = 0
        for node in range(node_count):
            if node in visited:
                continue
            components += 1
            stack = [node]
            visited.add(node)
            while stack:
                current = stack.pop()
                for neighbor in adjacency[current]:
                    if neighbor not in visited:
                        visited.add(neighbor)
                        stack.append(neighbor)
        return components

    def build_geometric_contact_edges_3d(self, contact_radius=None):
        if contact_radius is None:
            contact_radius = max(
                1.0,
                0.5 * float(self.params.centerlineMaskWidthPx.get_value()) + 0.75,
                0.2 * float(self.params.segmentLength.get_value()),
            )

        edge_pairs = set()
        for left_idx, left_fiber in enumerate(self.fibers):
            if len(left_fiber.points) < 2:
                continue
            for right_idx in range(left_idx + 1, len(self.fibers)):
                right_fiber = self.fibers[right_idx]
                if len(right_fiber.points) < 2:
                    continue

                close_enough = False
                for left_seg_idx in range(len(left_fiber.points) - 1):
                    p0 = left_fiber.points[left_seg_idx]
                    p1 = left_fiber.points[left_seg_idx + 1]
                    for right_seg_idx in range(len(right_fiber.points) - 1):
                        q0 = right_fiber.points[right_seg_idx]
                        q1 = right_fiber.points[right_seg_idx + 1]
                        if self._segment_segment_distance_3d(p0, p1, q0, q1) <= contact_radius:
                            edge_pairs.add((left_idx, right_idx))
                            close_enough = True
                            break
                    if close_enough:
                        break
        return sorted(edge_pairs)

    def calculate_validation_metrics_3d(self, fiber_volume=None, centerline_volume=None):
        path_lengths = []
        straightness_values = []
        widths = []
        turn_angles = []
        segment_dirs = []

        for fiber in self.fibers:
            if len(fiber.points) < 2:
                continue
            path_len = 0.0
            local_dirs = []
            for seg_idx in range(len(fiber.points) - 1):
                delta = fiber.points[seg_idx + 1].subtract(fiber.points[seg_idx])
                seg_len = delta.length()
                if seg_len <= 1e-8:
                    continue
                path_len += seg_len
                local_dirs.append(delta.normalize())
                segment_dirs.append(delta.normalize())
                if seg_idx < len(fiber.widths):
                    widths.append(fiber.widths[seg_idx])
            chord = fiber.points[-1].subtract(fiber.points[0]).length()
            if path_len > 0:
                path_lengths.append(path_len)
                straightness_values.append(chord / path_len)
            for seg_a, seg_b in zip(local_dirs, local_dirs[1:]):
                dot = float(np.clip(seg_a.dot_product(seg_b), -1.0, 1.0))
                turn_angles.append(float(np.degrees(np.arccos(dot))))

        mean_direction = Vector(*self.params.meanDirection.get_value())
        if mean_direction.is_zero():
            mean_direction = Vector(0.0, 0.0, 1.0)
        mean_direction = mean_direction.normalize()
        alignment_scores = [abs(seg.dot_product(mean_direction)) for seg in segment_dirs] if segment_dirs else []

        if fiber_volume is None:
            fiber_volume = self.render_fiber_volume_3d()
        if centerline_volume is None:
            centerline_volume = self.render_centerline_volume_3d()

        fiber_voxels = int((fiber_volume > 0).sum())
        centerline_voxels = int((centerline_volume > 0).sum())
        _, centerline_components = label(centerline_volume > 0)
        topology_edge_pairs = [
            (int(link["fiber_id"]), int(link["connected_fiber_id"]))
            for link in self.topology_links
            if "fiber_id" in link and "connected_fiber_id" in link
        ]
        geometric_contact_edges = self.build_geometric_contact_edges_3d()

        self.validation_metrics = {
            "fiber_count": int(len(self.fibers)),
            "topology_link_count": int(len(self.topology_links)),
            "topology_graph_component_count": int(self._count_graph_components(len(self.fibers), topology_edge_pairs)),
            "geometric_contact_edge_count": int(len(geometric_contact_edges)),
            "geometric_contact_component_count": int(self._count_graph_components(len(self.fibers), geometric_contact_edges)),
            "joint_count_3d": int(len(self.joint_points)),
            "raster_centerline_component_count": int(centerline_components),
            "fiber_voxel_count": fiber_voxels,
            "centerline_voxel_count": centerline_voxels,
            "fiber_to_centerline_voxel_ratio": float(fiber_voxels / max(centerline_voxels, 1)),
            "mean_path_length": float(np.mean(path_lengths)) if path_lengths else 0.0,
            "std_path_length": float(np.std(path_lengths)) if path_lengths else 0.0,
            "mean_straightness": float(np.mean(straightness_values)) if straightness_values else 0.0,
            "std_straightness": float(np.std(straightness_values)) if straightness_values else 0.0,
            "mean_segment_width": float(np.mean(widths)) if widths else 0.0,
            "std_segment_width": float(np.std(widths)) if widths else 0.0,
            "mean_turn_angle_deg": float(np.mean(turn_angles)) if turn_angles else 0.0,
            "std_turn_angle_deg": float(np.std(turn_angles)) if turn_angles else 0.0,
            "realized_alignment_to_mean_direction": float(np.mean(alignment_scores)) if alignment_scores else 0.0,
        }
        return self.validation_metrics
        
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
    def _line_voxels_3d(start, end):
        x1, y1, z1 = [int(round(v)) for v in start]
        x2, y2, z2 = [int(round(v)) for v in end]
        points = [(x1, y1, z1)]
        points.extend(FiberImage3D.bresenham_3d(x1, y1, z1, x2, y2, z2))
        return points

    @staticmethod
    def get_rendered_tube_diameter_3d(width_value, min_diameter=1):
        try:
            diameter = float(width_value)
        except (TypeError, ValueError):
            diameter = float(min_diameter)
        return max(min_diameter, diameter)

    @staticmethod
    def get_rendered_tube_radius_3d(width_value, min_diameter=1):
        diameter = FiberImage3D.get_rendered_tube_diameter_3d(width_value, min_diameter=min_diameter)
        if diameter <= 1:
            return 0.0
        return max(0.0, (float(diameter) - 1.0) / 2.0)

    @staticmethod
    def _sample_segment_points_3d(start, end, spacing=0.35):
        start = np.asarray(start, dtype=np.float32)
        end = np.asarray(end, dtype=np.float32)
        seg = end - start
        seg_length = float(np.linalg.norm(seg))
        if seg_length <= 1e-8:
            return start[np.newaxis, :]
        n_steps = max(1, int(math.ceil(seg_length / max(spacing, 1e-3))))
        t = np.linspace(0.0, 1.0, n_steps + 1, dtype=np.float32)
        return start[np.newaxis, :] + t[:, np.newaxis] * seg[np.newaxis, :]

    @staticmethod
    def _stamp_ball_3d(volume, point, radius, value, binary=False):
        z_dim, y_dim, x_dim = volume.shape
        x0, y0, z0 = point
        radius = max(0.0, float(radius))

        min_x = max(0, int(math.floor(x0 - radius - 1)))
        max_x = min(x_dim - 1, int(math.ceil(x0 + radius + 1)))
        min_y = max(0, int(math.floor(y0 - radius - 1)))
        max_y = min(y_dim - 1, int(math.ceil(y0 + radius + 1)))
        min_z = max(0, int(math.floor(z0 - radius - 1)))
        max_z = min(z_dim - 1, int(math.ceil(z0 + radius + 1)))
        if min_x > max_x or min_y > max_y or min_z > max_z:
            return

        z_coords, y_coords, x_coords = np.indices(
            (max_z - min_z + 1, max_y - min_y + 1, max_x - min_x + 1),
            dtype=np.float32
        )
        x_coords += min_x
        y_coords += min_y
        z_coords += min_z

        dist_sq = (x_coords - x0) ** 2 + (y_coords - y0) ** 2 + (z_coords - z0) ** 2
        mask = dist_sq <= (radius ** 2)
        if not np.any(mask):
            return

        region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
        if binary:
            region[mask] = 255.0
        else:
            region[mask] += value

    @staticmethod
    def _downsample_supersampled_mask(mask, factor):
        z_size, y_size, x_size = mask.shape
        reshaped = mask.reshape(
            z_size // factor, factor,
            y_size // factor, factor,
            x_size // factor, factor,
        )
        return reshaped.max(axis=(1, 3, 5))

    @staticmethod
    def _rasterize_segment_supersampled_3d(volume, start, end, radius, value, binary=False, factor=4):
        z_dim, y_dim, x_dim = volume.shape
        x0, y0, z0 = start
        x1, y1, z1 = end
        radius = max(0.0, float(radius))
        effective_radius = max(radius, 0.45)

        min_x = max(0, int(math.floor(min(x0, x1) - effective_radius - 1)))
        max_x = min(x_dim - 1, int(math.ceil(max(x0, x1) + effective_radius + 1)))
        min_y = max(0, int(math.floor(min(y0, y1) - effective_radius - 1)))
        max_y = min(y_dim - 1, int(math.ceil(max(y0, y1) + effective_radius + 1)))
        min_z = max(0, int(math.floor(min(z0, z1) - effective_radius - 1)))
        max_z = min(z_dim - 1, int(math.ceil(max(z0, z1) + effective_radius + 1)))
        if min_x > max_x or min_y > max_y or min_z > max_z:
            return

        coarse_z = max_z - min_z + 1
        coarse_y = max_y - min_y + 1
        coarse_x = max_x - min_x + 1
        fine_z = coarse_z * factor
        fine_y = coarse_y * factor
        fine_x = coarse_x * factor

        fine_z_coords, fine_y_coords, fine_x_coords = np.indices(
            (fine_z, fine_y, fine_x),
            dtype=np.float32,
        )
        fine_x_coords = min_x - 0.5 + (fine_x_coords + 0.5) / factor
        fine_y_coords = min_y - 0.5 + (fine_y_coords + 0.5) / factor
        fine_z_coords = min_z - 0.5 + (fine_z_coords + 0.5) / factor

        seg = np.array([x1 - x0, y1 - y0, z1 - z0], dtype=np.float32)
        seg_len_sq = float(np.dot(seg, seg))
        if seg_len_sq <= 1e-8:
            t = np.zeros_like(fine_x_coords, dtype=np.float32)
        else:
            t = (
                (fine_x_coords - x0) * seg[0]
                + (fine_y_coords - y0) * seg[1]
                + (fine_z_coords - z0) * seg[2]
            ) / seg_len_sq
            t = np.clip(t, 0.0, 1.0)

        closest_x = x0 + t * seg[0]
        closest_y = y0 + t * seg[1]
        closest_z = z0 + t * seg[2]
        dist_sq = (
            (fine_x_coords - closest_x) ** 2
            + (fine_y_coords - closest_y) ** 2
            + (fine_z_coords - closest_z) ** 2
        )
        fine_mask = dist_sq <= (effective_radius ** 2)
        if not np.any(fine_mask):
            return

        coarse_mask = FiberImage3D._downsample_supersampled_mask(fine_mask, factor)
        if not np.any(coarse_mask):
            return

        region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
        if binary:
            region[coarse_mask] = 255.0
        else:
            region[coarse_mask] += value

    @staticmethod
    def _rasterize_segment_3d(volume, start, end, radius, value, binary=False):
        z_dim, y_dim, x_dim = volume.shape
        x0, y0, z0 = start
        x1, y1, z1 = end
        radius = max(0.0, float(radius))

        # Thin 3D structures need dense subvoxel sampling; pure center-distance
        # rasterization under-resolves oblique segments and creates dotted output.
        if radius < 0.75:
            FiberImage3D._rasterize_segment_supersampled_3d(
                volume,
                start,
                end,
                radius,
                value,
                binary=binary,
                factor=4,
            )
            return

        min_x = max(0, int(math.floor(min(x0, x1) - radius - 1)))
        max_x = min(x_dim - 1, int(math.ceil(max(x0, x1) + radius + 1)))
        min_y = max(0, int(math.floor(min(y0, y1) - radius - 1)))
        max_y = min(y_dim - 1, int(math.ceil(max(y0, y1) + radius + 1)))
        min_z = max(0, int(math.floor(min(z0, z1) - radius - 1)))
        max_z = min(z_dim - 1, int(math.ceil(max(z0, z1) + radius + 1)))
        if min_x > max_x or min_y > max_y or min_z > max_z:
            return

        z_coords, y_coords, x_coords = np.indices(
            (max_z - min_z + 1, max_y - min_y + 1, max_x - min_x + 1),
            dtype=np.float32
        )
        x_coords += min_x
        y_coords += min_y
        z_coords += min_z

        seg = np.array([x1 - x0, y1 - y0, z1 - z0], dtype=np.float32)
        seg_len_sq = float(np.dot(seg, seg))
        if seg_len_sq <= 1e-8:
            t = np.zeros_like(x_coords, dtype=np.float32)
        else:
            t = ((x_coords - x0) * seg[0] + (y_coords - y0) * seg[1] + (z_coords - z0) * seg[2]) / seg_len_sq
            t = np.clip(t, 0.0, 1.0)

        closest_x = x0 + t * seg[0]
        closest_y = y0 + t * seg[1]
        closest_z = z0 + t * seg[2]
        dist_sq = (x_coords - closest_x) ** 2 + (y_coords - closest_y) ** 2 + (z_coords - closest_z) ** 2
        mask = dist_sq <= (radius ** 2)
        if not np.any(mask):
            return

        region = volume[min_z:max_z + 1, min_y:max_y + 1, min_x:max_x + 1]
        if binary:
            region[mask] = 255.0
        else:
            region[mask] += value

    @staticmethod
    def render_fibers_to_volume(
        fibers,
        shape,
        default_intensity=255.0,
        binary=False,
        centerline_only=False,
        line_width_override=None
    ):
        volume = np.zeros(shape, dtype=np.float32)
        for fiber in fibers:
            intensity = 255.0 if binary else getattr(fiber, "intensity", default_intensity)
            if intensity is None:
                intensity = default_intensity
            try:
                intensity = float(intensity)
            except (TypeError, ValueError):
                intensity = default_intensity
            if intensity <= 0:
                continue
            intensity = max(0.0, min(255.0, intensity))
            for segment in fiber:
                start = np.array([segment.start.x, segment.start.y, segment.start.z], dtype=np.float32)
                end = np.array([segment.end.x, segment.end.y, segment.end.z], dtype=np.float32)
                if line_width_override is not None:
                    radius = FiberImage3D.get_rendered_tube_radius_3d(line_width_override, min_diameter=1)
                else:
                    radius = 0.0 if centerline_only else FiberImage3D.get_rendered_tube_radius_3d(segment.width, min_diameter=1)
                FiberImage3D._rasterize_segment_3d(volume, start, end, radius, intensity, binary=binary)
        return np.clip(volume, 0, 255).astype(np.uint8)

    def render_fiber_volume_3d(self):
        shape = (
            self.params.imageDepth.get_value(),
            self.params.imageHeight.get_value(),
            self.params.imageWidth.get_value()
        )
        return self.render_fibers_to_volume(self.fibers, shape)

    def render_centerline_volume_3d(self):
        shape = (
            self.params.imageDepth.get_value(),
            self.params.imageHeight.get_value(),
            self.params.imageWidth.get_value()
        )
        output = self.render_fibers_to_volume(
            self.fibers,
            shape,
            default_intensity=255.0,
            binary=True,
            centerline_only=True,
            line_width_override=self.get_mask_line_width(self.params)
        ).astype(np.float32)
        return (output > 127).astype(np.uint8) * 255

    def render_base_volume_3d(self):
        return self.render_fiber_volume_3d()
        
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
        alignment = self.params.alignment3D.get_value()
        return [
            RngUtility3D.sample_oriented_direction(mean_direction, alignment).normalize()
            for _ in range(self.params.nFibers.get_value())
        ]

    def generate_fibers_3d(self, abort_check=None):
        directions = self.generate_directions_3d()

        for direction in directions:
            if abort_check and abort_check():
                break
            fiber_params = Fiber.Params()

            fiber_params.segment_length = self.params.segmentLength.get_value()
            fiber_params.width_change = self.params.widthChange.get_value()
            fiber_params.min_angle_change = self.params.minAngleChange.get_value()
            fiber_params.max_angle_change = self.params.maxAngleChange.get_value()
            fiber_params.curvature_scale = self.params.curvature.get_value()

            fiber_params.n_segments = max(1, round(self.params.length.sample() / self.params.segmentLength.get_value()))
            fiber_params.straightness = self.params.straightness.sample()
            fiber_params.start_width = self.params.width.sample()

            end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
            fiber_params.start = self.find_fiber_start_3d(end_distance, direction)
            fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

            fiber = Fiber(fiber_params)
            fiber.generate_3d()
            if abort_check and abort_check():
                break
            if hasattr(self.params, "intensity"):
                fiber.intensity = self.params.intensity.sample()
            self.fibers.append(fiber)
    
    def smooth_3d(self):
        for fiber in self.fibers:
            if self.params.bubble.use:
                fiber.bubble_smooth_3d(self.params.bubble.get_value())
            if self.params.swap.use:
                fiber.swap_smooth_3d(self.params.swap.get_value())
            if self.params.spline.use:
                fiber.spline_smooth(self.params.spline.get_value())
        self.apply_topology_3d()
        for fiber in self.fibers:
            fiber.calculate_orientations()
        self.joint_points = self.count_joints()
                
    def add_noise_3d(self):
        model = str(self.params.noiseModel.get_value()).lower()
        if model == "no noise":
            return
        noise_params = deepcopy(self.params)
        noise_params.noise = noise_params.noiseMean
        self.image = self.add_noise_to_array(self.image.astype(np.float32), noise_params)

    def draw_scale_bar_3d(self):
        if not self.params.scale.use:
            return
        pixels_per_micron = float(self.params.scale.get_value())
        if pixels_per_micron <= 0:
            return
        microns = 10.0
        length_px = max(1, int(round(microns * pixels_per_micron)))
        z = max(0, self.image.shape[0] - 2)
        y = max(1, self.image.shape[1] - 8)
        x_start = 4
        x_end = min(self.image.shape[2] - 1, x_start + length_px)
        self.image[z, y:y + 2, x_start:x_end] = 255

    @classmethod
    def apply_postprocessing_3d(cls, volume, params):
        output = np.asarray(volume, dtype=np.float32).copy()
        mask_mode = cls.is_mask_mode(params)
        binary_mask = mask_mode and cls.is_binary_mask_output(params)

        if binary_mask:
            return (output > 127).astype(np.uint8) * 255

        if params.distanceFalloff.use:
            output = ImageUtility3D.distance_function_3d(output.astype(np.uint8), params.distanceFalloff.get_value()).astype(np.float32)

        if not mask_mode and getattr(params, "psfEnabled", None) and params.psfEnabled.use:
            manager = PSFManager(params)
            psf_result = manager.apply(output, volume=True)
            if psf_result is not None:
                output = psf_result.astype(np.float32)

        if (not mask_mode or not binary_mask) and cls.should_apply_noise(params, is_3d=True):
            noise_params = deepcopy(params)
            noise_params.noise = noise_params.noiseMean
            output = cls.add_noise_to_array(output, noise_params).astype(np.float32)

        if params.blurRadius.use:
            output = ImageUtility3D.gaussian_blur_3d(output, params.blurRadius.get_value()).astype(np.float32)

        if params.cap.use:
            output = ImageUtility3D.cap_3d(output, params.cap.get_value()).astype(np.float32)

        if params.normalize.use:
            max_value = np.max(output)
            if max_value > 0:
                output = output / max_value * float(params.normalize.get_value())

        output = np.clip(output, 0, 255).astype(np.uint8)

        if not mask_mode and params.scale.use:
            temp = FiberImage3D(params)
            temp.image = output.copy()
            temp.draw_scale_bar_3d()
            output = temp.image

        if params.downSample.use:
            step = max(1, int(round(1 / params.downSample.get_value())))
            output = output[::step, ::step, ::step]

        return output

    def apply_effects_3d(self):
        self.image = self.apply_postprocessing_3d(self.image, self.params)

    def get_image(self):
        return self.image

    # 3D-specific CSV export: extend parent with depth/volume metrics
    def to_csv_data(self):
        network_df, summary_df, segments_df, points_df, joints_df, params_df = super().to_csv_data()
        joints_df = pd.DataFrame([
            {
                "Joint ID": idx,
                "X": joint.x,
                "Y": joint.y,
                "Z": joint.z,
            }
            for idx, joint in enumerate(self.joint_points)
        ])
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
                metrics = self.validation_metrics or self.calculate_validation_metrics_3d()
                network_df.loc[0, 'Topology Link Count'] = metrics.get('topology_link_count', 0)
                network_df.loc[0, 'Topology Graph Components'] = metrics.get('topology_graph_component_count', 0)
                network_df.loc[0, 'Geometric Contact Edge Count'] = metrics.get('geometric_contact_edge_count', 0)
                network_df.loc[0, 'Geometric Contact Components'] = metrics.get('geometric_contact_component_count', 0)
                network_df.loc[0, '3D Joint Count'] = metrics.get('joint_count_3d', 0)
                network_df.loc[0, 'Raster Centerline Components'] = metrics.get('raster_centerline_component_count', 0)
                network_df.loc[0, 'Fiber Voxel Count'] = metrics.get('fiber_voxel_count', 0)
                network_df.loc[0, 'Centerline Voxel Count'] = metrics.get('centerline_voxel_count', 0)
                network_df.loc[0, 'Fiber/Centerline Voxel Ratio'] = metrics.get('fiber_to_centerline_voxel_ratio', 0.0)
                network_df.loc[0, 'Mean Turn Angle (deg)'] = metrics.get('mean_turn_angle_deg', 0.0)
                network_df.loc[0, 'Std Turn Angle (deg)'] = metrics.get('std_turn_angle_deg', 0.0)
                network_df.loc[0, 'Realized Alignment To Mean Dir'] = metrics.get('realized_alignment_to_mean_direction', 0.0)
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
            if "generateCenterlineLabel" in params_dict:
                params.generateCenterlineLabel = Param.from_dict(params_dict["generateCenterlineLabel"])
            if "generateFiberImage" in params_dict:
                params.generateFiberImage = Param.from_dict(params_dict["generateFiberImage"])
            if "centerlineOutputType" in params_dict:
                params.centerlineOutputType = Param.from_dict(params_dict["centerlineOutputType"])
            if "renderMode" in params_dict:
                params.renderMode = Param.from_dict(params_dict["renderMode"])
            if "centerlineMaskWidthPx" in params_dict:
                params.centerlineMaskWidthPx = Param.from_dict(params_dict["centerlineMaskWidthPx"])
            elif "maskType" in params_dict:
                params.centerlineMaskWidthPx.value = 1
            if "maskOutputMode" in params_dict:
                params.maskOutputMode = Param.from_dict(params_dict["maskOutputMode"])
            elif "maskBinary" in params_dict:
                legacy_mask_binary = Param.from_dict(params_dict["maskBinary"])
                params.maskOutputMode.value = "Binary"
            if "generateCenterlineLabel" not in params_dict and "generateFiberImage" not in params_dict:
                legacy_render_mode = str(params.renderMode.get_value()).strip().lower()
                params.generateCenterlineLabel.value = legacy_render_mode == "mask mode"
                params.generateFiberImage.value = legacy_render_mode != "mask mode"
            params.centerlineOutputType.value = "Binary"
            params.maskOutputMode.value = "Binary"
            params.alignment = Param.from_dict(params_dict["alignment"])
            params.meanAngle = Param.from_dict(params_dict["meanAngle"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            if "showCenterlineOverlay" in params_dict:
                params.showCenterlineOverlay = Optional.from_dict(params_dict["showCenterlineOverlay"])
            if "centerlineOverlayColor" in params_dict:
                params.centerlineOverlayColor = Param.from_dict(params_dict["centerlineOverlayColor"])
            if "centerlineOverlayBrightness" in params_dict:
                params.centerlineOverlayBrightness = Param.from_dict(params_dict["centerlineOverlayBrightness"])
            params.length = distribution_from_dict(params_dict.get("length"), params.length)
            params.width = distribution_from_dict(params_dict.get("width"), params.width)
            params.straightness = distribution_from_dict(params_dict.get("straightness"), params.straightness)
            if "intensity" in params_dict:
                params.intensity = distribution_from_dict(params_dict.get("intensity"), params.intensity)
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
            self.sync_legacy_output_fields()
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "generateCenterlineLabel": self.generateCenterlineLabel.to_dict(),
                "generateFiberImage": self.generateFiberImage.to_dict(),
                "centerlineOutputType": self.centerlineOutputType.to_dict(),
                "renderMode": self.renderMode.to_dict(),
                "centerlineMaskWidthPx": self.centerlineMaskWidthPx.to_dict(),
                "maskOutputMode": self.maskOutputMode.to_dict(),
                "alignment": self.alignment.to_dict(),
                "meanAngle": self.meanAngle.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "intensity": self.intensity.to_dict(),
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
            self.min_angle_change = self.minAngleChange
            self.max_angle_change = self.maxAngleChange

        @staticmethod
        def from_dict(params_dict):
            params = ImageCollection3D.Params()
            params.nFibers = Param.from_dict(params_dict["nFibers"])
            params.segmentLength = Param.from_dict(params_dict["segmentLength"])
            if "generateCenterlineLabel" in params_dict:
                params.generateCenterlineLabel = Param.from_dict(params_dict["generateCenterlineLabel"])
            if "generateFiberImage" in params_dict:
                params.generateFiberImage = Param.from_dict(params_dict["generateFiberImage"])
            if "centerlineOutputType" in params_dict:
                params.centerlineOutputType = Param.from_dict(params_dict["centerlineOutputType"])
            if "renderMode" in params_dict:
                params.renderMode = Param.from_dict(params_dict["renderMode"])
            if "centerlineMaskWidthPx" in params_dict:
                params.centerlineMaskWidthPx = Param.from_dict(params_dict["centerlineMaskWidthPx"])
            elif "maskType" in params_dict:
                params.centerlineMaskWidthPx.value = 1
            if "maskOutputMode" in params_dict:
                params.maskOutputMode = Param.from_dict(params_dict["maskOutputMode"])
            elif "maskBinary" in params_dict:
                legacy_mask_binary = Param.from_dict(params_dict["maskBinary"])
                params.maskOutputMode.value = "Binary"
            if "generateCenterlineLabel" not in params_dict and "generateFiberImage" not in params_dict:
                legacy_render_mode = str(params.renderMode.get_value()).strip().lower()
                params.generateCenterlineLabel.value = legacy_render_mode == "mask mode"
                params.generateFiberImage.value = legacy_render_mode != "mask mode"
            params.centerlineOutputType.value = "Binary"
            params.maskOutputMode.value = "Binary"
            params.alignment3D = Param.from_dict(params_dict["alignment3D"])
            params.meanDirection = Param.from_dict(params_dict["meanDirection"])
            params.widthChange = Param.from_dict(params_dict["widthChange"])
            params.imageWidth = Param.from_dict(params_dict["imageWidth"])
            params.imageHeight = Param.from_dict(params_dict["imageHeight"])
            params.imageDepth = Param.from_dict(params_dict["imageDepth"])
            params.imageBuffer = Param.from_dict(params_dict["imageBuffer"])
            if "showCenterlineOverlay" in params_dict:
                params.showCenterlineOverlay = Optional.from_dict(params_dict["showCenterlineOverlay"])
            if "centerlineOverlayColor" in params_dict:
                params.centerlineOverlayColor = Param.from_dict(params_dict["centerlineOverlayColor"])
            if "centerlineOverlayBrightness" in params_dict:
                params.centerlineOverlayBrightness = Param.from_dict(params_dict["centerlineOverlayBrightness"])
            params.length = distribution_from_dict(params_dict.get("length"), params.length)
            params.width = distribution_from_dict(params_dict.get("width"), params.width)
            params.straightness = distribution_from_dict(params_dict.get("straightness"), params.straightness)
            if "intensity" in params_dict:
                params.intensity = distribution_from_dict(params_dict.get("intensity"), params.intensity)
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
            params.blur = params.blurRadius
            params.noise = params.noiseMean
            params.distance = params.distanceFalloff
            params.min_angle_change = params.minAngleChange
            params.max_angle_change = params.maxAngleChange
            return params

        def to_dict(self):
            self.sync_legacy_output_fields()
            return {
                "nFibers": self.nFibers.to_dict(),
                "segmentLength": self.segmentLength.to_dict(),
                "generateCenterlineLabel": self.generateCenterlineLabel.to_dict(),
                "generateFiberImage": self.generateFiberImage.to_dict(),
                "centerlineOutputType": self.centerlineOutputType.to_dict(),
                "renderMode": self.renderMode.to_dict(),
                "centerlineMaskWidthPx": self.centerlineMaskWidthPx.to_dict(),
                "maskOutputMode": self.maskOutputMode.to_dict(),
                "alignment3D": self.alignment3D.to_dict(),
                "meanDirection": self.meanDirection.to_dict(),
                "widthChange": self.widthChange.to_dict(),
                "imageWidth": self.imageWidth.to_dict(),
                "imageHeight": self.imageHeight.to_dict(),
                "imageDepth": self.imageDepth.to_dict(),
                "imageBuffer": self.imageBuffer.to_dict(),
                "showCenterlineOverlay": self.showCenterlineOverlay.to_dict(),
                "centerlineOverlayColor": self.centerlineOverlayColor.to_dict(),
                "centerlineOverlayBrightness": self.centerlineOverlayBrightness.to_dict(),
                "length": self.length.to_dict(),
                "width": self.width.to_dict(),
                "straightness": self.straightness.to_dict(),
                "intensity": self.intensity.to_dict(),
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
            image.image = image.render_base_volume_3d()
            image.calculate_validation_metrics_3d(fiber_volume=image.image)
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
                    base_val = min_dist * falloff if min_dist > 0 else 255.0
                    scale = float(input_array[y, x]) / 255.0
                    output_array[y, x] = min(255, int(base_val * scale))

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
                        base_val = min_dist * falloff if min_dist > 0 else 255.0
                        scale = float(input_array[z, y, x]) / 255.0
                        output_array[z, y, x] = min(255, int(base_val * scale))

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

        sheet_descriptions = {
            "Network Summary": "Global network metrics: alignment, straightness, densities, size, and 3D validation metrics when applicable.",
            "Fiber Summary": "Per-fiber properties including path length, straightness, and alignment.",
            "Fiber Segments": "Per-segment endpoints, widths, orientations, and alignment score.",
            "Fiber Points": "Per-point coordinates and per-point orientation/width where available.",
            "Joint Points": "Detected joint/intersection coordinates in pixels or voxels.",
            "Generation Parameters": "Only parameters that actively influenced the generated outputs or post-processing pipeline.",
        }
        for sheet_name, desc in sheet_descriptions.items():
            add(sheet_name, "(sheet)", desc)

        field_definitions = {
            "Network Summary": {
                "Fiber Count": "Total number of fibers in the image.",
                "Segment Count": "Total number of segments across all fibers.",
                "Network Alignment": "Nematic order parameter |mean exp(i·2θ)| over all segments (0–1).",
                "Network Mean Angle (deg)": "Dominant network orientation in degrees, range [0, 180).",
                "Avg Fiber Alignment": "Average of per-fiber alignment scores (nematic, 0–1).",
                "Std Fiber Alignment": "Standard deviation of per-fiber alignment.",
                "Avg Straightness (morph)": "Mean chord/path straightness across fibers (0–1).",
                "Std Straightness (morph)": "Standard deviation of morphological straightness.",
                "Total Fiber Length (px)": "Sum of all segment lengths in pixels.",
                "Image Width (px)": "Image width in pixels.",
                "Image Height (px)": "Image height in pixels.",
                "Image Depth (px)": "Image depth in voxels for 3D exports.",
                "Image Area (px^2)": "Image area = width × height (pixels squared).",
                "Image Volume (px^3)": "Image volume = width × height × depth (pixels cubed).",
                "Length Density (px/px^2)": "Total fiber length divided by 2D image area.",
                "Length Density (px/px^3)": "Total fiber length divided by 3D image volume.",
                "Joint Count": "Number of detected joints (segment intersections or shared endpoints).",
                "3D Joint Count": "Number of explicit 3D topology joints after the topology pass.",
                "Joint Density (#/px^2)": "Joint count divided by image area.",
                "Avg Segment Width": "Mean of segment widths.",
                "Std Segment Width": "Standard deviation of segment widths.",
                "Min Segment Width": "Minimum segment width.",
                "Max Segment Width": "Maximum segment width.",
                "Mean Segment Length (px)": "Average length of segments in pixels.",
                "Topology Link Count": "Number of explicit fiber-to-fiber links added by the 3D topology pass.",
                "Topology Graph Components": "Connected-component count in the explicit topology graph.",
                "Geometric Contact Edge Count": "Number of fiber pairs that come into geometric contact based on segment distance.",
                "Geometric Contact Components": "Connected-component count in the geometric-contact graph.",
                "Raster Centerline Components": "Connected-component count in the exported rasterized centerline mask.",
                "Fiber Voxel Count": "Number of nonzero voxels in the rendered Fiber Image volume.",
                "Centerline Voxel Count": "Number of nonzero voxels in the rasterized Centerline Mask volume.",
                "Fiber/Centerline Voxel Ratio": "Fiber voxel count divided by centerline voxel count.",
                "Mean Turn Angle (deg)": "Mean angle between consecutive 3D segment directions.",
                "Std Turn Angle (deg)": "Standard deviation of turn angles between consecutive 3D segments.",
                "Realized Alignment To Mean Dir": "Average absolute dot product between segment directions and the requested mean direction.",
            },
            "Fiber Summary": {
                "Fiber ID": "Zero-based index of the fiber.",
                "Start X": "X coordinate of the first point (px).",
                "Start Y": "Y coordinate of the first point (px).",
                "End X": "X coordinate of the last point (px).",
                "End Y": "Y coordinate of the last point (px).",
                "Segment Count": "Number of segments in the fiber.",
                "Segment Length": "Nominal segment length used during generation (px).",
                "Straightness Param": "Generator straightness parameter sampled for the fiber (input).",
                "Path Length": "Sum of segment lengths along the fiber (px).",
                "Straightness Morph": "Chord length divided by path length (0–1).",
                "Start Width": "Starting width parameter for the fiber (px).",
                "Mean Width": "Average segment width within the fiber (px).",
                "Mean Angle XY": "Mean segment orientation in the XY plane (deg).",
                "Std Angle XY": "Standard deviation of XY orientations (deg).",
                "Fiber Alignment": "|mean exp(i·2θ)| computed over this fiber's segments (0–1).",
                "Has Joint Point": "True if any segment participates in a joint.",
            },
            "Fiber Segments": {
                "Fiber ID": "Zero-based index of the fiber containing this segment.",
                "Segment Index": "Zero-based index of the segment within the fiber.",
                "Start X": "X coordinate of segment start (px).",
                "Start Y": "Y coordinate of segment start (px).",
                "Start Z": "Z coordinate (0 in 2D; voxel index in 3D).",
                "End X": "X coordinate of segment end (px).",
                "End Y": "Y coordinate of segment end (px).",
                "End Z": "Z coordinate (0 in 2D; voxel index in 3D).",
                "Width": "Segment width (px).",
                "Orientation XY": "Orientation in XY plane (deg).",
                "Orientation YZ": "Orientation in YZ plane (deg; 3D only).",
                "Orientation XZ": "Orientation in XZ plane (deg; 3D only).",
                "Alignment Score (0-1)": "Segment alignment vs network mean: 0.5·(1+cos(2·Δθ)).",
            },
            "Fiber Points": {
                "Fiber ID": "Zero-based index of the fiber containing this point.",
                "Point Index": "Zero-based index of the point within the fiber.",
                "X": "X coordinate (px).",
                "Y": "Y coordinate (px).",
                "Z": "Z coordinate (0 in 2D; voxel index in 3D).",
                "Width": "Width value at this point, if available (px).",
                "Orientation XY": "Orientation at this point in XY plane (deg).",
                "Orientation YZ": "Orientation at this point in YZ plane (deg; 3D only).",
                "Orientation XZ": "Orientation at this point in XZ plane (deg; 3D only).",
            },
            "Joint Points": {
                "Joint ID": "Zero-based index of the joint.",
                "X": "X coordinate of the joint (px).",
                "Y": "Y coordinate of the joint (px).",
                "Z": "Z coordinate of the joint (voxel index; 3D only).",
            },
        }

        sheet_frames = {
            "Network Summary": network_df,
            "Fiber Summary": summary_df,
            "Fiber Segments": segments_df,
            "Fiber Points": points_df,
            "Joint Points": joints_df,
        }
        for sheet_name, frame in sheet_frames.items():
            definitions = field_definitions.get(sheet_name, {})
            for field in frame.columns:
                desc = definitions.get(field)
                if desc:
                    add(sheet_name, field, desc)

        add("Generation Parameters", "Parameter", "Name of an applied parameter. Preview-only and inactive parameters are omitted.")
        add("Generation Parameters", "Value", "Applied parameter value; noise rows include model-specific details when relevant.")
        for parameter_name in dict.fromkeys(params_df["Parameter"].tolist()):
            add("Generation Parameters", parameter_name, fiber_image.get_generation_parameter_description(parameter_name))

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
        if "intensity" in params_dict:
            params.intensity.set_bounds(0, 255)
        params.set_names()
        params.set_hints()
        return params

    def write_results(self, params, collection, out_folder: str):
        if not os.path.exists(out_folder):
            os.makedirs(out_folder)

        dataset_rows = []
        for i in range(collection.size()):
            fiber_image = collection.get(i)
            centerline_mask = fiber_image.render_centerline_label_2d() if FiberImage.should_generate_centerline_label(fiber_image.params) else None
            fiber_render = None
            if FiberImage.should_generate_fiber_image(fiber_image.params):
                base_image = fiber_image.render_fiber_image_2d()
                fiber_render = FiberImage.apply_postprocessing_2d(base_image, fiber_image.params)
            sample_name = f"2d_sample_{i:03d}"
            sample_dir = os.path.join(out_folder, sample_name)
            sample = build_canonical_sample(
                fiber_image,
                image_id=sample_name,
                sample_id=sample_name,
                centerline_mask=centerline_mask,
                fiber_image_array=fiber_render,
            )
            export_canonical_research_package(sample_dir, sample, include_excel=True)
            dataset_rows.append(build_dataset_manifest_rows(sample, sample_dir))
        if dataset_rows:
            write_dataset_manifest(out_folder, dataset_rows)

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
        if "intensity" in params_dict:
            params.intensity.set_bounds(0, 255)
        params.set_names()
        params.set_hints()
        return params

    def write_results(self, params, collection, out_folder: str):
        out_folder = os.path.join(out_folder)
        if not os.path.exists(out_folder):
            os.makedirs(out_folder)

        dataset_rows = []
        for i in range(collection.size()):
            fiber_image = collection.get(i)
            centerline_mask = fiber_image.render_centerline_volume_3d() if FiberImage.should_generate_centerline_label(fiber_image.params) else None
            base_volume = fiber_image.render_fiber_volume_3d() if FiberImage.should_generate_fiber_image(fiber_image.params) else None
            if centerline_mask is not None or base_volume is not None:
                fiber_image.calculate_validation_metrics_3d(fiber_volume=base_volume, centerline_volume=centerline_mask)
            fiber_render = FiberImage3D.apply_postprocessing_3d(base_volume, fiber_image.params) if base_volume is not None else None
            sample_name = f"3d_sample_{i:03d}"
            sample_dir = os.path.join(out_folder, sample_name)
            sample = build_canonical_sample(
                fiber_image,
                image_id=sample_name,
                sample_id=sample_name,
                centerline_mask=centerline_mask,
                fiber_image_array=fiber_render,
            )
            export_canonical_research_package(sample_dir, sample, include_excel=True)
            dataset_rows.append(build_dataset_manifest_rows(sample, sample_dir))
        if dataset_rows:
            write_dataset_manifest(out_folder, dataset_rows)

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
        self.collection_2d = None
        self.collection_3d = None
        self.display_index = 0
        self.display_index_2d = 0
        self.display_index_3d = 0
        self.scene = None
        self.original_fibers_by_index = []
        self.original_fibers_by_index_2d = []
        self.original_fibers_by_index_3d = []

        # Guard flag to suppress redraws during UI mode switches
        self._suspend_redraw = False

        self._resize_redraw_timer = QTimer(self)
        self._resize_redraw_timer.setSingleShot(True)
        self._resize_redraw_timer.timeout.connect(self.handle_resize_redraw)

        self.init_gui()
        self.display_params()

    def init_gui(self):
        self.resize(1280, 820)
        self.setMinimumSize(1100, 700)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)

        main_layout = QGridLayout(central_widget)
        main_layout.setColumnStretch(0, 3)
        main_layout.setColumnStretch(1, 2)
        main_layout.setRowStretch(0, 1)

        # Create display frame
        display_frame = QFrame(self)
        display_layout = QVBoxLayout(display_frame)
        display_frame.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)

        # Add the display frame to the main layout
        main_layout.addWidget(display_frame, 0, 0, 4, 1)

        # Create a QStackedWidget to hold both 2D and 3D displays
        self.display_stack = QStackedWidget(self)
        self.display_stack.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.display_stack.setMinimumSize(QSize(320, 320))
        self.image_display_2d = self.create_image_display_2d(display_frame)
        self.image_display_3d = self.create_image_display_3d(display_frame)
        self.display_stack.addWidget(self.image_display_2d)
        self.display_stack.addWidget(self.image_display_3d)

        display_layout.addWidget(self.display_stack, 1)
        right_panel = QWidget(self)
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_panel.setSizePolicy(QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Expanding)
        main_layout.addWidget(right_panel, 0, 1, 5, 1)

        session_header_frame = QGroupBox("Session", right_panel)
        session_header_layout = QGridLayout(session_header_frame)
        right_layout.addWidget(session_header_frame)

        session_header_layout.addWidget(QLabel("Parameters:"), 0, 0)
        self.load_button = QPushButton("Open...", session_header_frame)
        session_header_layout.addWidget(self.load_button, 0, 1)

        session_header_layout.addWidget(QLabel("Number of images:"), 1, 0)
        self.n_images_field = QLineEdit(session_header_frame)
        session_header_layout.addWidget(self.n_images_field, 1, 1)

        self.seed_check = QCheckBox("Seed:", session_header_frame)
        session_header_layout.addWidget(self.seed_check, 2, 0)
        self.seed_field = QLineEdit(session_header_frame)
        session_header_layout.addWidget(self.seed_field, 2, 1)

        self.mode_toggle_button = QPushButton("Switch to 3D Mode", session_header_frame)
        session_header_layout.addWidget(self.mode_toggle_button, 0, 2)
        self.reset_button = QPushButton("Reset", session_header_frame)
        session_header_layout.addWidget(self.reset_button, 1, 2)
        self.generate_button = QPushButton("Generate...", session_header_frame)
        session_header_layout.addWidget(self.generate_button, 2, 2)
        self.abort_button = QPushButton("Abort", session_header_frame)
        self.abort_button.setEnabled(False)
        session_header_layout.addWidget(self.abort_button, 3, 2)

        self.tab_widget = QTabWidget(right_panel)
        right_layout.addWidget(self.tab_widget, 1)

        create_structure_tab = QWidget()
        match_real_data_tab = QWidget()
        enhance_realism_tab = QWidget()
        preview_export_tab = QWidget()

        self.create_structure_tab_index = self.tab_widget.addTab(create_structure_tab, "Create Structure")
        self.match_real_data_tab_index = self.tab_widget.addTab(match_real_data_tab, "Match Real Data")
        self.enhance_realism_tab_index = self.tab_widget.addTab(enhance_realism_tab, "Enhance Realism")
        self.preview_export_tab_index = self.tab_widget.addTab(preview_export_tab, "Preview & Export")

        create_structure_layout = QVBoxLayout(create_structure_tab)
        self.create_structure_tabs = QTabWidget(create_structure_tab)
        create_structure_layout.addWidget(self.create_structure_tabs)

        structure_tab = QWidget()
        distributions_tab = QWidget()
        outputs_tab = QWidget()
        fiber_render_tab = QWidget()
        advanced_post_tab = QWidget()

        self.structure_subtab_index = self.create_structure_tabs.addTab(structure_tab, "Structure")
        self.distributions_subtab_index = self.create_structure_tabs.addTab(distributions_tab, "Distributions")
        self.outputs_subtab_index = self.create_structure_tabs.addTab(outputs_tab, "Outputs")
        self.fiber_render_subtab_index = self.create_structure_tabs.addTab(fiber_render_tab, "Fiber Render")
        self.advanced_subtab_index = self.create_structure_tabs.addTab(advanced_post_tab, "Advanced")

        fiber_tab = structure_tab
        render_tab = outputs_tab
        effects_tab = fiber_render_tab

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

        preview_controls_frame = QGroupBox("Preview", display_frame)
        preview_controls_layout = QGridLayout(preview_controls_frame)
        display_layout.addWidget(preview_controls_frame)

        preview_controls_layout.addWidget(QLabel("Preview target:"), 0, 0)
        self.preview_target_combo = QComboBox(preview_controls_frame)
        self.preview_target_combo.addItems([
            "Fiber Image",
            "Centerline Mask",
            "Enhanced (Planned)",
            "Reference (Planned)",
            "Compare (Planned)",
        ])
        preview_controls_layout.addWidget(self.preview_target_combo, 0, 1)
        self.open_napari_button = QPushButton("Open in napari", preview_controls_frame)
        preview_controls_layout.addWidget(self.open_napari_button, 0, 2)

        self.preview_3d_view_label = QLabel("3D view:", preview_controls_frame)
        preview_controls_layout.addWidget(self.preview_3d_view_label, 1, 0)
        self.preview_3d_view_combo = QComboBox(preview_controls_frame)
        self.preview_3d_view_combo.addItems([
            "Projection",
            "Attenuated Projection",
            "Isosurface",
        ])
        preview_controls_layout.addWidget(self.preview_3d_view_combo, 1, 1)

        self.show_joints_checkbox = QCheckBox("Show joint points", preview_controls_frame)
        preview_controls_layout.addWidget(self.show_joints_checkbox, 2, 0, 1, 2)

        self.show_centerline_checkbox = QCheckBox("Show centerline overlay", preview_controls_frame)
        preview_controls_layout.addWidget(self.show_centerline_checkbox, 3, 0, 1, 2)

        self.centerline_color_widget = QWidget(preview_controls_frame)
        centerline_color_layout = QHBoxLayout(self.centerline_color_widget)
        centerline_color_layout.setContentsMargins(0, 0, 0, 0)
        centerline_color_layout.setSpacing(6)
        self.centerline_color_label = QLabel("Color:", self.centerline_color_widget)
        self.centerline_color_combo = QComboBox(self.centerline_color_widget)
        self.centerline_color_combo.addItems(["Neon Green", "Cyan", "Magenta", "Yellow"])
        centerline_color_layout.addWidget(self.centerline_color_label)
        centerline_color_layout.addWidget(self.centerline_color_combo)
        centerline_color_layout.addStretch(1)
        preview_controls_layout.addWidget(self.centerline_color_widget, 4, 0, 1, 2)

        # Outputs tab components
        outputs_layout = QVBoxLayout(outputs_tab)
        outputs_tab.setLayout(outputs_layout)

        image_config_frame = QGroupBox("Image Dimensions", outputs_tab)
        image_config_layout = QGridLayout(image_config_frame)
        outputs_layout.addWidget(image_config_frame)

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

        output_products_frame = QGroupBox("Derived Outputs", outputs_tab)
        render_grid = QGridLayout(output_products_frame)
        outputs_layout.addWidget(output_products_frame)

        self.generate_centerline_checkbox = QCheckBox("Generate centerline mask", output_products_frame)
        render_grid.addWidget(self.generate_centerline_checkbox, 0, 0, 1, 2)

        self.generate_fiber_checkbox = QCheckBox("Generate fiber image", output_products_frame)
        fiber_output_row = QWidget(output_products_frame)
        fiber_output_row_layout = QHBoxLayout(fiber_output_row)
        fiber_output_row_layout.setContentsMargins(0, 0, 0, 0)
        fiber_output_row_layout.setSpacing(4)
        fiber_output_row_layout.addWidget(self.generate_fiber_checkbox)
        self.output_relationship_info_button = self.create_info_button(
            "Fiber Image only: blur, downsampling, normalize/cap/scale, distance or distance falloff, "
            "noise, scale bar, and PSF. Centerline Mask remains structural."
        )
        fiber_output_row_layout.addWidget(self.output_relationship_info_button)
        fiber_output_row_layout.addStretch(1)
        render_grid.addWidget(fiber_output_row, 1, 0, 1, 3)

        self.centerline_mask_width_label = QLabel("Centerline Width (px):")
        self.centerline_mask_width_field = QLineEdit(output_products_frame)
        render_grid.addWidget(self.centerline_mask_width_label, 2, 0)
        render_grid.addWidget(self.centerline_mask_width_field, 2, 1)

        outputs_layout.addStretch(1)

        # Structure tab components
        fiber_layout = QVBoxLayout(fiber_tab)
        fiber_tab.setLayout(fiber_layout)

        # Distributions tab components
        distributions_layout = QVBoxLayout(distributions_tab)
        distributions_tab.setLayout(distributions_layout)

        distribution_frame = QGroupBox("Structure Distributions", distributions_tab)
        distribution_layout = QGridLayout(distribution_frame)
        distributions_layout.addWidget(distribution_frame)

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

        distribution_layout.addWidget(QLabel("Intensity distribution:"), 3, 0)
        self.intensity_button = QPushButton("Modify...", distribution_frame)
        distribution_layout.addWidget(self.intensity_button, 3, 1)
        self.intensity_display = QLineEdit(distribution_frame)
        self.intensity_display.setReadOnly(True)
        self.intensity_display.setMinimumSize(200, 20)
        distribution_layout.addWidget(self.intensity_display, 3, 2, 1, 15)

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

        # Checkbox for "Use joints"
        self.use_joints_checkbox = QCheckBox("Use joints", values_frame)
        values_layout.addWidget(self.use_joints_checkbox, 5, 2)
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
        values_layout.setColumnStretch(2, 1)
        values_layout.setColumnStretch(3, 2)

        smoothing_frame = QGroupBox("Smoothing", fiber_tab)
        smoothing_layout = QGridLayout(smoothing_frame)
        fiber_layout.addWidget(smoothing_frame)

        smoothing_layout.addWidget(QLabel("Bubble:"), 0, 0)
        self.bubble_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.bubble_check, 0, 1)
        self.bubble_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.bubble_field, 0, 2)
        self.bubble_check.stateChanged.connect(self.on_optional_effect_changed)

        smoothing_layout.addWidget(QLabel("Swap:"), 1, 0)
        self.swap_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.swap_check, 1, 1)
        self.swap_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.swap_field, 1, 2)
        self.swap_check.stateChanged.connect(self.on_optional_effect_changed)

        smoothing_layout.addWidget(QLabel("Spline:"), 2, 0)
        self.spline_check = QCheckBox("", smoothing_frame)
        smoothing_layout.addWidget(self.spline_check, 2, 1)
        self.spline_field = QLineEdit(smoothing_frame)
        smoothing_layout.addWidget(self.spline_field, 2, 2)
        self.spline_check.stateChanged.connect(self.on_optional_effect_changed)

        # Effects tab components
        effects_layout = QVBoxLayout(effects_tab)
        effects_tab.setLayout(effects_layout)

        noise_frame = QGroupBox("Noise", effects_tab)
        noise_layout = QGridLayout(noise_frame)
        effects_layout.addWidget(noise_frame)

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
        self.noise_check.stateChanged.connect(self.on_optional_effect_changed)

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

        blur_frame = QGroupBox("Blur & Downsampling", effects_tab)
        blur_layout = QGridLayout(blur_frame)
        effects_layout.addWidget(blur_frame)

        self.blur_label = QLabel("Blur:")
        self.blur_check = QCheckBox("", blur_frame)
        self.blur_field = QLineEdit(blur_frame)
        blur_layout.addWidget(self.blur_label, 0, 0)
        blur_layout.addWidget(self.blur_check, 0, 1)
        blur_layout.addWidget(self.blur_field, 0, 2)
        self.blur_check.stateChanged.connect(self.on_optional_effect_changed)

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
        self.sample_check.stateChanged.connect(self.on_optional_effect_changed)

        intensity_frame = QGroupBox("Intensity & Scaling", effects_tab)
        intensity_layout = QGridLayout(intensity_frame)
        effects_layout.addWidget(intensity_frame)

        self.scale_label = QLabel("Scale:")
        self.scale_check = QCheckBox("", intensity_frame)
        self.scale_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.scale_label, 0, 0)
        intensity_layout.addWidget(self.scale_check, 0, 1)
        intensity_layout.addWidget(self.scale_field, 0, 2)
        self.scale_check.stateChanged.connect(self.on_optional_effect_changed)

        intensity_layout.addWidget(QLabel("Normalize:"), 1, 0)
        self.normalize_check = QCheckBox("", intensity_frame)
        intensity_layout.addWidget(self.normalize_check, 1, 1)
        self.normalize_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.normalize_field, 1, 2)
        self.normalize_check.stateChanged.connect(self.on_optional_effect_changed)

        intensity_layout.addWidget(QLabel("Cap:"), 2, 0)
        self.cap_check = QCheckBox("", intensity_frame)
        intensity_layout.addWidget(self.cap_check, 2, 1)
        self.cap_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.cap_field, 2, 2)
        self.cap_check.stateChanged.connect(self.on_optional_effect_changed)

        self.distance_label = QLabel("Distance:")
        self.distance_check = QCheckBox("", intensity_frame)
        self.distance_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.distance_label, 3, 0)
        intensity_layout.addWidget(self.distance_check, 3, 1)
        intensity_layout.addWidget(self.distance_field, 3, 2)
        self.distance_check.stateChanged.connect(self.on_optional_effect_changed)

        self.distance_falloff_label = QLabel("Distance Falloff:")
        self.distance_falloff_check = QCheckBox("", intensity_frame)
        self.distance_falloff_field = QLineEdit(intensity_frame)
        intensity_layout.addWidget(self.distance_falloff_label, 4, 0)
        intensity_layout.addWidget(self.distance_falloff_check, 4, 1)
        intensity_layout.addWidget(self.distance_falloff_field, 4, 2)

        effects_layout.addStretch(1)

        self.mode_toggle_button.clicked.connect(self.toggle_mode)
        self.generate_button.clicked.connect(self.generate_pressed)
        self.abort_button.clicked.connect(self.abort_pressed)
        self.reset_button.clicked.connect(self.reset_pressed)
        self.prev_button.clicked.connect(self.prev_pressed)
        self.next_button.clicked.connect(self.next_pressed)
        self.load_button.clicked.connect(self.load_pressed)
        self.length_button.clicked.connect(self.length_pressed)
        self.width_button.clicked.connect(self.width_pressed)
        self.straight_button.clicked.connect(self.straight_pressed)
        self.intensity_button.clicked.connect(self.intensity_pressed)
        self.centerline_mask_width_field.editingFinished.connect(self.redraw_image)
        self.noise_model_combo.currentIndexChanged.connect(self.on_noise_model_changed)
        self.noise_mean_check.stateChanged.connect(self.on_optional_effect_changed)
        self.noise_std_check.stateChanged.connect(self.on_optional_effect_changed)
        self.saltpepper_check.stateChanged.connect(self.on_optional_effect_changed)
        self.blur_radius_check.stateChanged.connect(self.on_optional_effect_changed)
        self.distance_falloff_check.stateChanged.connect(self.on_optional_effect_changed)

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

        match_real_data_layout = QVBoxLayout(match_real_data_tab)
        match_real_data_tab.setLayout(match_real_data_layout)

        input_group = QGroupBox("Input Data", match_real_data_tab)
        input_layout = QGridLayout(input_group)
        match_real_data_layout.addWidget(input_group)
        input_layout.addWidget(QLabel("Reference source:"), 0, 0)
        self.match_input_combo = QComboBox(input_group)
        self.match_input_combo.addItems(["Extracted centerlines (planned)", "Raw images (planned)"])
        input_layout.addWidget(self.match_input_combo, 0, 1)
        self.match_input_button = QPushButton("Choose input...", input_group)
        self.match_input_button.setEnabled(False)
        input_layout.addWidget(self.match_input_button, 1, 0, 1, 2)

        extraction_group = QGroupBox("Extract Structure", match_real_data_tab)
        extraction_layout = QGridLayout(extraction_group)
        match_real_data_layout.addWidget(extraction_group)
        extraction_layout.addWidget(QLabel("Extractor:"), 0, 0)
        self.extractor_combo = QComboBox(extraction_group)
        self.extractor_combo.addItems(["CT-FIRE", "Ridge Detection", "SOAX"])
        extraction_layout.addWidget(self.extractor_combo, 0, 1)
        self.run_extraction_button = QPushButton("Run Extraction", extraction_group)
        self.run_extraction_button.setEnabled(False)
        extraction_layout.addWidget(self.run_extraction_button, 1, 0, 1, 2)

        self.match_real_data_note = QLabel(
            "This workflow is scaffolded. The UI is now centered on structure-first generation, "
            "and extractor integration is the next backend step.",
            match_real_data_tab
        )
        self.match_real_data_note.setWordWrap(True)
        match_real_data_layout.addWidget(self.match_real_data_note)
        match_real_data_layout.addStretch(1)

        enhance_realism_layout = QVBoxLayout(enhance_realism_tab)
        enhance_realism_tab.setLayout(enhance_realism_layout)

        model_group = QGroupBox("Model Selection", enhance_realism_tab)
        model_layout = QGridLayout(model_group)
        enhance_realism_layout.addWidget(model_group)
        model_layout.addWidget(QLabel("Pipeline:"), 0, 0)
        self.enhancement_pipeline_combo = QComboBox(model_group)
        self.enhancement_pipeline_combo.addItems(["Duo VAE / cGAN (planned)", "Custom model (planned)"])
        model_layout.addWidget(self.enhancement_pipeline_combo, 0, 1)
        model_layout.addWidget(QLabel("Modality:"), 1, 0)
        self.enhancement_modality_combo = QComboBox(model_group)
        self.enhancement_modality_combo.addItems(["SHG", "Polarized", "Other (planned)"])
        model_layout.addWidget(self.enhancement_modality_combo, 1, 1)

        inference_group = QGroupBox("Inference", enhance_realism_tab)
        inference_layout = QVBoxLayout(inference_group)
        enhance_realism_layout.addWidget(inference_group)
        self.enhance_current_button = QPushButton("Enhance Current", inference_group)
        self.enhance_current_button.setEnabled(False)
        self.enhance_batch_button = QPushButton("Enhance Batch", inference_group)
        self.enhance_batch_button.setEnabled(False)
        inference_layout.addWidget(self.enhance_current_button)
        inference_layout.addWidget(self.enhance_batch_button)

        self.enhance_realism_note = QLabel(
            "This workflow is scaffolded for the centerline-to-realism pipeline. "
            "Fiber images remain the handoff point to the planned DL models.",
            enhance_realism_tab
        )
        self.enhance_realism_note.setWordWrap(True)
        enhance_realism_layout.addWidget(self.enhance_realism_note)
        enhance_realism_layout.addStretch(1)

        preview_export_layout = QVBoxLayout(preview_export_tab)
        preview_export_tab.setLayout(preview_export_layout)

        export_group = QGroupBox("Export", preview_export_tab)
        export_layout = QGridLayout(export_group)
        preview_export_layout.addWidget(export_group)
        self.export_current_button = QPushButton("Export Current Sample", export_group)
        export_layout.addWidget(self.export_current_button, 0, 0)
        self.export_all_button = QPushButton("Export All Samples", export_group)
        export_layout.addWidget(self.export_all_button, 0, 1)
        export_layout.addWidget(QLabel("Export detail:"), 1, 0)
        self.export_detail_combo = QComboBox(export_group)
        self.export_detail_combo.addItems([
            "Concise package",
            "Full geometry package",
        ])
        export_layout.addWidget(self.export_detail_combo, 1, 1)
        self.export_session_checkbox = QCheckBox("Include session restore", export_group)
        export_layout.addWidget(self.export_session_checkbox, 2, 0, 1, 2)
        self.export_custom_checkbox = QCheckBox("Choose name and location", export_group)
        export_layout.addWidget(self.export_custom_checkbox, 3, 0, 1, 2)

        summary_group = QGroupBox("Preview Summary", preview_export_tab)
        summary_layout = QVBoxLayout(summary_group)
        preview_export_layout.addWidget(summary_group)
        self.preview_export_summary = QLabel(summary_group)
        self.preview_export_summary.setWordWrap(True)
        self.preview_export_summary.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        summary_layout.addWidget(self.preview_export_summary)
        preview_export_layout.addStretch(1)

        self.apply_psf_checkbox.stateChanged.connect(self.on_psf_configuration_changed)
        self.psf_type_combo.currentIndexChanged.connect(self.on_psf_configuration_changed)
        self.preview_psf_button.clicked.connect(self.preview_psf_kernel)
        self.preview_target_combo.currentIndexChanged.connect(self.redraw_image)
        self.preview_target_combo.currentIndexChanged.connect(self.refresh_preview_export_summary)
        self.export_detail_combo.currentIndexChanged.connect(self.refresh_preview_export_summary)
        self.export_session_checkbox.stateChanged.connect(self.refresh_preview_export_summary)
        self.preview_3d_view_combo.currentIndexChanged.connect(self.redraw_image)
        self.preview_3d_view_combo.currentIndexChanged.connect(self.refresh_centerline_overlay)
        self.open_napari_button.clicked.connect(self.open_current_preview_in_napari)
        self.show_joints_checkbox.stateChanged.connect(self.redraw_image)
        self.show_centerline_checkbox.stateChanged.connect(self.refresh_centerline_overlay)
        self.centerline_color_combo.currentIndexChanged.connect(self.refresh_centerline_overlay)
        self.generate_centerline_checkbox.stateChanged.connect(self.on_output_configuration_changed)
        self.generate_fiber_checkbox.stateChanged.connect(self.on_output_configuration_changed)
        self.export_current_button.clicked.connect(self.save_current_preview_pressed)
        self.export_all_button.clicked.connect(self.save_all_preview_pressed)
        self.refresh_ui_state()

    def refresh_centerline_overlay(self):
        self.refresh_ui_state()
        if getattr(self, '_suspend_redraw', False) or self.collection is None:
            return
        if self.is_3d_mode:
            if '3D Image' not in self.viewer.layers:
                self.redraw_image()
            else:
                self.update_3d_centerline_layer()
        else:
            self.redraw_image()

    def on_output_configuration_changed(self, *_args):
        self.refresh_ui_state()
        self.redraw_image()

    def on_optional_effect_changed(self, *_args):
        self.refresh_ui_state()
        self.redraw_image()

    def on_psf_configuration_changed(self, *_args):
        self.refresh_ui_state()
        self.redraw_image()

    @staticmethod
    def set_line_edit_active(field, active):
        field.setEnabled(active)
        field.setReadOnly(not active)

    def set_optional_row_editable(self, check_box, field, visible=True):
        check_box.setVisible(visible)
        field.setVisible(visible)
        check_box.setEnabled(visible)
        field.setEnabled(visible)
        field.setReadOnly(not visible)

    @staticmethod
    def set_combo_item_enabled(combo_box, index, enabled):
        model = combo_box.model()
        item = model.item(index) if hasattr(model, "item") else None
        if item is not None:
            item.setEnabled(enabled)

    def get_requested_preview_target(self):
        preview_map = {
            "Fiber Image": "fiber_image",
            "Centerline Mask": "centerline_mask",
            "Enhanced (Planned)": "enhanced",
            "Reference (Planned)": "reference",
            "Compare (Planned)": "compare",
        }
        return preview_map.get(self.preview_target_combo.currentText(), "fiber_image")

    def get_export_detail_level(self):
        if not hasattr(self, "export_detail_combo"):
            return EXPORT_DETAIL_CONCISE
        return EXPORT_DETAIL_FULL if self.export_detail_combo.currentText() == "Full geometry package" else EXPORT_DETAIL_CONCISE

    def get_3d_view_mode(self):
        if not hasattr(self, "preview_3d_view_combo"):
            return "projection"
        mode_map = {
            "Projection": "projection",
            "Attenuated Projection": "attenuated",
            "Isosurface": "isosurface",
        }
        return mode_map.get(self.preview_3d_view_combo.currentText(), "projection")

    def create_info_button(self, text):
        button = QToolButton(self)
        button.setText("i")
        button.setCursor(Qt.CursorShape.PointingHandCursor)
        button.setAutoRaise(True)
        button.setStyleSheet(
            "QToolButton { color: #d4a017; font-weight: 700; border: none; padding: 0px 2px; }"
            "QToolButton:hover { color: #f2c94c; }"
        )
        button.setToolTip(text)
        button.setToolTipDuration(0)
        button.clicked.connect(lambda _checked=False, b=button, t=text: QToolTip.showText(b.mapToGlobal(QPoint(b.width() // 2, b.height())), t, b))
        return button

    def get_active_preview_target(self):
        requested = self.get_requested_preview_target()
        available = []
        if self.generate_fiber_checkbox.isChecked():
            available.append("fiber_image")
        if self.generate_centerline_checkbox.isChecked():
            available.append("centerline_mask")
        if requested in available:
            return requested
        if available:
            return available[0]
        return None

    @staticmethod
    def preview_target_to_label(preview_target):
        labels = {
            "fiber_image": "Fiber Image",
            "centerline_mask": "Centerline Mask",
            "enhanced": "Enhanced (Planned)",
            "reference": "Reference (Planned)",
            "compare": "Compare (Planned)",
            None: "None",
        }
        return labels.get(preview_target, "Fiber Image")

    def sync_preview_target_choices(self):
        fiber_enabled = self.generate_fiber_checkbox.isChecked()
        centerline_enabled = self.generate_centerline_checkbox.isChecked()
        enabled_states = {
            0: fiber_enabled,
            1: centerline_enabled,
            2: False,
            3: False,
            4: False,
        }
        for index, enabled in enabled_states.items():
            self.set_combo_item_enabled(self.preview_target_combo, index, enabled)

        active_target = self.get_active_preview_target()
        active_label = self.preview_target_to_label(active_target)
        current_label = self.preview_target_combo.currentText()
        if active_target is not None and current_label != active_label:
            block = self.preview_target_combo.blockSignals(True)
            self.preview_target_combo.setCurrentText(active_label)
            self.preview_target_combo.blockSignals(block)

    def refresh_preview_export_summary(self):
        mode_label = "3D" if self.is_3d_mode else "2D"
        preview_label = self.preview_target_to_label(self.get_active_preview_target())
        enabled_outputs = []
        if self.generate_centerline_checkbox.isChecked():
            enabled_outputs.append("Centerline Mask")
        if self.generate_fiber_checkbox.isChecked():
            enabled_outputs.append("Fiber Image")
        if not enabled_outputs:
            enabled_outputs.append("None")
        collection_size = self.collection.size() if self.collection is not None else 0
        output_folder = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
        summary_lines = [
            f"Mode: {mode_label}",
            f"Available outputs: {', '.join(enabled_outputs)}",
            f"Active preview: {preview_label}",
            f"Export detail: {self.export_detail_combo.currentText()}",
        ]
        if self.is_3d_mode:
            summary_lines.append(f"3D view: {self.preview_3d_view_combo.currentText()}")
        summary_lines.extend([
            f"Generated images: {collection_size}",
            f"Default output folder: {output_folder}",
        ])
        if self.export_session_checkbox.isChecked():
            summary_lines.append("Session restore: included")
        self.preview_export_summary.setText("\n".join(summary_lines))

    def refresh_ui_state(self):
        self.centerline_mask_width_label.setEnabled(True)
        self.set_line_edit_active(self.centerline_mask_width_field, True)
        self.intensity_button.setEnabled(True)
        self.intensity_display.setEnabled(True)

        self.mean_angle_label.setVisible(not self.is_3d_mode)
        self.mean_angle_field.setVisible(not self.is_3d_mode)
        self.alignment_label.setVisible(not self.is_3d_mode)
        self.alignment_field.setVisible(not self.is_3d_mode)
        self.joint_points_label.setVisible(not self.is_3d_mode)
        self.joint_points_field.setVisible(not self.is_3d_mode)
        self.use_joints_checkbox.setVisible(not self.is_3d_mode)

        self.mean_direction_label.setVisible(self.is_3d_mode)
        self.mean_direction_field.setVisible(self.is_3d_mode)
        self.alignment3D_label.setVisible(self.is_3d_mode)
        self.alignment3D_field.setVisible(self.is_3d_mode)
        self.min_angle_change_label.setVisible(self.is_3d_mode)
        self.min_angle_change_field.setVisible(self.is_3d_mode)
        self.max_angle_change_label.setVisible(self.is_3d_mode)
        self.max_angle_change_field.setVisible(self.is_3d_mode)
        self.image_depth_label.setVisible(self.is_3d_mode)
        self.image_depth_field.setVisible(self.is_3d_mode)
        self.curvature_label.setVisible(self.is_3d_mode)
        self.curvature_field.setVisible(self.is_3d_mode)
        self.branching_probability_label.setVisible(self.is_3d_mode)
        self.branching_probability_field.setVisible(self.is_3d_mode)

        self.show_joints_checkbox.setVisible(not self.is_3d_mode)
        self.show_centerline_checkbox.setVisible(True)
        self.centerline_color_widget.setVisible(self.show_centerline_checkbox.isChecked())
        self.preview_3d_view_label.setVisible(self.is_3d_mode)
        self.preview_3d_view_combo.setVisible(self.is_3d_mode)
        has_preview_data = self.collection is not None and self.collection.size() > 0
        self.preview_3d_view_combo.setEnabled(self.is_3d_mode and has_preview_data)
        self.open_napari_button.setVisible(True)
        self.open_napari_button.setEnabled(has_preview_data)
        self.export_current_button.setEnabled(has_preview_data)
        self.export_all_button.setEnabled(has_preview_data)
        self.export_detail_combo.setEnabled(True)
        self.export_session_checkbox.setEnabled(True)
        self.export_custom_checkbox.setEnabled(True)

        self.set_optional_row_editable(self.bubble_check, self.bubble_field, True)
        self.set_optional_row_editable(self.swap_check, self.swap_field, True)
        self.set_optional_row_editable(self.spline_check, self.spline_field, True)
        self.set_optional_row_editable(self.sample_check, self.sample_field, True)
        self.set_optional_row_editable(self.cap_check, self.cap_field, True)
        self.set_optional_row_editable(self.normalize_check, self.normalize_field, True)
        self.set_optional_row_editable(self.scale_check, self.scale_field, True)
        self.set_optional_row_editable(self.blur_check, self.blur_field, not self.is_3d_mode)
        self.set_optional_row_editable(self.blur_radius_check, self.blur_radius_field, self.is_3d_mode)
        self.set_optional_row_editable(self.distance_check, self.distance_field, not self.is_3d_mode)
        self.set_optional_row_editable(self.distance_falloff_check, self.distance_falloff_field, self.is_3d_mode)

        self.scale_label.setVisible(True)
        self.scale_check.setVisible(True)
        self.scale_field.setVisible(True)
        self.blur_label.setVisible(not self.is_3d_mode)
        self.blur_check.setVisible(not self.is_3d_mode)
        self.blur_field.setVisible(not self.is_3d_mode)
        self.blur_radius_label.setVisible(self.is_3d_mode)
        self.blur_radius_check.setVisible(self.is_3d_mode)
        self.blur_radius_field.setVisible(self.is_3d_mode)
        self.distance_label.setVisible(not self.is_3d_mode)
        self.distance_check.setVisible(not self.is_3d_mode)
        self.distance_field.setVisible(not self.is_3d_mode)
        self.distance_falloff_label.setVisible(self.is_3d_mode)
        self.distance_falloff_check.setVisible(self.is_3d_mode)
        self.distance_falloff_field.setVisible(self.is_3d_mode)

        self.set_line_edit_active(self.joint_points_field, not self.is_3d_mode)

        self.create_structure_tabs.setTabEnabled(self.fiber_render_subtab_index, True)
        self.create_structure_tabs.setTabEnabled(self.advanced_subtab_index, True)

        self.noise_model_label.setEnabled(True)
        self.noise_model_combo.setEnabled(True)
        self.apply_psf_checkbox.setEnabled(True)
        self.psf_type_combo.setEnabled(True)
        self.preview_psf_button.setEnabled(self.apply_psf_checkbox.isChecked() and self.psf_type_combo.currentText() != "None")
        self.sync_preview_target_choices()

        self.update_noise_controls_visibility()
        self.update_psf_controls_visibility()
        self.refresh_preview_export_summary()

    def update_image_counter(self):
        """Update the image counter label (e.g., 1/10)."""
        if self.collection is not None and self.collection.size() > 0:
            self.image_counter_label.setText(f"{self.display_index + 1}/{self.collection.size()}")
        else:
            self.image_counter_label.setText("0/0")
        has_previous = self.collection is not None and self.collection.size() > 0 and self.display_index > 0
        has_next = self.collection is not None and self.collection.size() > 0 and self.display_index < self.collection.size() - 1
        self.prev_button.setEnabled(has_previous)
        self.next_button.setEnabled(has_next)

    def sync_mode_runtime_state(self):
        if self.is_3d_mode:
            self.collection = self.collection_3d
            self.display_index = self.display_index_3d
            self.original_fibers_by_index = self.original_fibers_by_index_3d
        else:
            self.collection = self.collection_2d
            self.display_index = self.display_index_2d
            self.original_fibers_by_index = self.original_fibers_by_index_2d

    def store_mode_runtime_state(self):
        if self.is_3d_mode:
            self.collection_3d = self.collection
            self.display_index_3d = self.display_index
            self.original_fibers_by_index_3d = list(self.original_fibers_by_index)
        else:
            self.collection_2d = self.collection
            self.display_index_2d = self.display_index
            self.original_fibers_by_index_2d = list(self.original_fibers_by_index)

    def clear_current_mode_runtime_state(self):
        if self.is_3d_mode:
            self.collection_3d = None
            self.display_index_3d = 0
            self.original_fibers_by_index_3d = []
        else:
            self.collection_2d = None
            self.display_index_2d = 0
            self.original_fibers_by_index_2d = []
        self.collection = None
        self.display_index = 0
        self.original_fibers_by_index = []

    def toggle_mode(self):
        # Prevent auto-redraw while switching and updating controls
        self._suspend_redraw = True
        self.store_mode_runtime_state()

        self.is_3d_mode = not self.is_3d_mode
        if self.is_3d_mode:
            self.params = self.params_3d
            self.out_folder = self.out_folder_3d
            self.mode_toggle_button.setText("Switch to 2D Mode")
            self.display_stack.setCurrentWidget(self.image_display_3d)
        else:
            self.params = self.params_2d
            self.out_folder = self.out_folder_2d
            self.mode_toggle_button.setText("Switch to 3D Mode")
            self.display_stack.setCurrentWidget(self.image_display_2d)

        self.sync_mode_runtime_state()

        # Update UI for the new mode
        self.update_ui_mode()
        self.display_params()
        self.update_image_counter()

        # Re-enable redraw for future changes
        self._suspend_redraw = False
        self.restore_current_mode_preview()

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
                self.show_2d_placeholder()
            except Exception:
                pass

        if hasattr(self, 'image_display_3d_placeholder') and self.image_display_3d_placeholder is not None:
            try:
                self.show_3d_placeholder()
            except Exception:
                pass

    def show_2d_placeholder(self, message="No 2D preview yet.\nClick \"Generate\" to create a 2D image."):
        if hasattr(self, 'viewer_2d') and self.viewer_2d is not None:
            try:
                self.viewer_2d.layers.clear()
            except Exception:
                pass
        if hasattr(self, 'image_display_2d_placeholder') and self.image_display_2d_placeholder is not None:
            self.image_display_2d_placeholder.setText(message)
        if hasattr(self, 'image_display_2d_stack') and self.image_display_2d_stack is not None:
            self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_placeholder)

    def create_image_display_2d_placeholder(self, parent):
        placeholder = QLabel(parent)
        placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        placeholder.setWordWrap(True)
        placeholder.setStyleSheet("background-color: black; color: white;")
        placeholder.setText("No 2D preview yet.\nClick \"Generate\" to create a 2D image.")
        placeholder.setMinimumSize(320, 320)
        placeholder.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        return placeholder

    def create_image_display_3d_placeholder(self, parent):
        placeholder = QLabel(parent)
        placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        placeholder.setWordWrap(True)
        placeholder.setStyleSheet("background-color: black; color: white;")
        placeholder.setText("No 3D preview yet.\nClick \"Generate\" to create a 3D volume.")
        placeholder.setMinimumSize(320, 320)
        placeholder.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        return placeholder

    def show_3d_placeholder(self, message="No 3D preview yet.\nClick \"Generate\" to create a 3D volume."):
        if hasattr(self, 'viewer') and self.viewer is not None:
            try:
                self.viewer.layers.clear()
            except Exception:
                pass
        if hasattr(self, 'image_display_3d_placeholder') and self.image_display_3d_placeholder is not None:
            self.image_display_3d_placeholder.setText(message)
        if hasattr(self, 'image_display_3d_stack') and self.image_display_3d_stack is not None:
            self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_placeholder)

    def show_2d_viewer(self):
        if hasattr(self, 'image_display_2d_stack') and self.image_display_2d_stack is not None:
            self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_viewer_widget)

    def show_3d_viewer(self):
        if hasattr(self, 'image_display_3d_stack') and self.image_display_3d_stack is not None:
            self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_viewer_widget)

    def show_placeholder_for_current_mode(self, missing_output=False):
        if self.is_3d_mode:
            message = (
                "Enable a centerline or fiber output to preview 3D images."
                if missing_output else
                "No 3D preview yet.\nClick \"Generate\" to create a 3D volume."
            )
            self.show_3d_placeholder(message)
        else:
            message = (
                "Enable a centerline or fiber output to preview 2D images."
                if missing_output else
                "No 2D preview yet.\nClick \"Generate\" to create a 2D image."
            )
            self.show_2d_placeholder(message)

    def restore_current_mode_preview(self):
        self.refresh_preview_export_summary()
        if self.get_active_preview_target() is None:
            self.show_placeholder_for_current_mode(missing_output=True)
            return
        if self.collection is None or self.collection.size() == 0:
            self.show_placeholder_for_current_mode()
            return
        fiber_image, rendered_output = self._render_output_for_index(self.display_index)
        self.display_image(rendered_output, fiber_image=fiber_image)

    def create_image_display_2d(self, parent):
        try:
            self.viewer_2d = napari.Viewer(ndisplay=2, show=False)
        except TypeError:
            self.viewer_2d = napari.Viewer(ndisplay=2)

        container = QWidget(parent)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        self.image_display_2d_stack = QStackedWidget(container)
        self.image_display_2d_placeholder = self.create_image_display_2d_placeholder(container)
        viewer_widget = getattr(self.viewer_2d.window, "_qt_viewer", None)
        if viewer_widget is None:
            viewer_widget = self.viewer_2d.window._qt_window
        self.image_display_2d_viewer_widget = viewer_widget
        try:
            self.image_display_2d_viewer_widget.setParent(container)
        except Exception:
            pass
        self.image_display_2d_viewer_widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.image_display_2d_viewer_widget.hide()
        self.image_display_2d_stack.addWidget(self.image_display_2d_placeholder)
        self.image_display_2d_stack.addWidget(self.image_display_2d_viewer_widget)
        self.image_display_2d_stack.setCurrentWidget(self.image_display_2d_placeholder)
        layout.addWidget(self.image_display_2d_stack)

        container.setMinimumSize(QSize(320, 320))
        container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        return container

    def create_image_display_3d(self, parent):
        # Initialize the napari viewer without using a standalone top-level window.
        try:
            self.viewer = napari.Viewer(ndisplay=3, show=False)
        except TypeError:
            self.viewer = napari.Viewer(ndisplay=3)

        container = QWidget(parent)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        self.image_display_3d_stack = QStackedWidget(container)
        self.image_display_3d_placeholder = self.create_image_display_3d_placeholder(container)
        self.advanced_viewer = None
        viewer_widget = getattr(self.viewer.window, "_qt_viewer", None)
        if viewer_widget is None:
            viewer_widget = self.viewer.window._qt_window
        self.image_display_3d_viewer_widget = viewer_widget
        try:
            self.image_display_3d_viewer_widget.setParent(container)
        except Exception:
            pass
        self.image_display_3d_viewer_widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.image_display_3d_viewer_widget.hide()
        self.image_display_3d_stack.addWidget(self.image_display_3d_placeholder)
        self.image_display_3d_stack.addWidget(self.image_display_3d_viewer_widget)
        self.image_display_3d_stack.setCurrentWidget(self.image_display_3d_placeholder)
        layout.addWidget(self.image_display_3d_stack)

        container.setMinimumSize(QSize(320, 320))
        container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)

        return container

    def resizeEvent(self, event):
        super().resizeEvent(event)
        if hasattr(self, "_resize_redraw_timer"):
            self._resize_redraw_timer.start(50)

    def handle_resize_redraw(self):
        if getattr(self, "_suspend_redraw", False):
            return
        if self.is_3d_mode or self.collection is None:
            return
        if self.get_active_preview_target() is None:
            return
        self.redraw_image()

    # [Removed] Save 3D View button handler

    def update_render_mode_visibility(self):
        self.refresh_ui_state()

    def update_ui_mode(self):
        self.refresh_ui_state()

    def parse_params(self):
        self.params.nImages.parse(self.n_images_field.text(), int)
        self.params.seed.parse(self.seed_check.isChecked(), self.seed_field.text(), int)
        self.params.nFibers.parse(self.n_fibers_field.text(), int)
        self.params.segmentLength.parse(self.segment_field.text(), float)
        self.params.widthChange.parse(self.width_change_field.text(), float)
        self.params.generateCenterlineLabel.value = self.generate_centerline_checkbox.isChecked()
        self.params.generateFiberImage.value = self.generate_fiber_checkbox.isChecked()
        self.params.centerlineOutputType.value = "Binary"
        self.params.centerlineMaskWidthPx.parse(self.centerline_mask_width_field.text(), int)
        self.params.maskOutputMode.value = "Binary"
        if hasattr(self.params, "sync_legacy_output_fields"):
            self.params.sync_legacy_output_fields()

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

        self.params.showCenterlineOverlay.use = self.show_centerline_checkbox.isChecked()
        self.params.centerlineOverlayColor.parse(self.centerline_color_combo.currentText(), str)
        self.params.centerlineOverlayBrightness.parse("1.2", float)

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
        self.n_images_field.setText(self.params.nImages.get_string())
        self.seed_check.setChecked(self.params.seed.use)
        self.seed_field.setText(self.params.seed.get_string())

        self.length_display.setText(self.params.length.get_string())
        self.width_display.setText(self.params.width.get_string())
        self.straight_display.setText(self.params.straightness.get_string())
        self.intensity_display.setText(self.params.intensity.get_string())

        self.n_fibers_field.setText(self.params.nFibers.get_string())
        self.segment_field.setText(self.params.segmentLength.get_string())
        self.width_change_field.setText(self.params.widthChange.get_string())
        self.generate_centerline_checkbox.setChecked(FiberImage.should_generate_centerline_label(self.params))
        self.generate_fiber_checkbox.setChecked(FiberImage.should_generate_fiber_image(self.params))
        self.centerline_mask_width_field.setText(self.params.centerlineMaskWidthPx.get_string())

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
            self.distance_falloff_check.setChecked(self.params.distanceFalloff.use)
            self.blur_radius_field.setText(self.params.blurRadius.get_string())
            self.blur_radius_check.setChecked(self.params.blurRadius.use)
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

        self.show_centerline_checkbox.setChecked(self.params.showCenterlineOverlay.use)
        current_centerline_color = str(self.params.centerlineOverlayColor.get_value()) if self.params.centerlineOverlayColor.get_value() is not None else "Neon Green"
        idx = self.centerline_color_combo.findText(current_centerline_color)
        if idx >= 0:
            self.centerline_color_combo.setCurrentIndex(idx)
        else:
            self.centerline_color_combo.setCurrentIndex(0)

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
        self.refresh_ui_state()
        
    def update_joint_points_field(self):
        if not self.use_joints_checkbox.isChecked():
            self.joint_points_field.setText("")  # Clear when unselecting
        else:
            if not self.joint_points_field.text():
                self.joint_points_field.setText(self.params.jointPoints.get_string())
        self.refresh_ui_state()
        
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
            self.store_mode_runtime_state()
            # Convenience for current index
            fiber_image = self.collection.get(self.display_index)
            self.original_fibers = deepcopy(self.original_fibers_by_index[self.display_index])

            # Redraw the image properly (re-smooth if smoothing enabled, rebuild, post-process, display)
            self.redraw_image()

            # Update image counter
            self.update_image_counter()
            self.refresh_ui_state()

            # Update joint points field if needed
            if not self.use_joints_checkbox.isChecked():
                self.joint_points_field.setText(str(len(fiber_image.joint_points)))

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
            self.clear_current_mode_runtime_state()
            self.sync_mode_runtime_state()
            self.display_params()
            self.update_image_counter()
            self.show_placeholder_for_current_mode()
        except Exception as e:
            self.show_error(str(e))
    
    def prev_pressed(self):
        if self.collection and self.display_index > 0:
            self.display_index -= 1
            self.store_mode_runtime_state()
            self.redraw_image()
            self.update_image_counter()

    def next_pressed(self):
        if self.collection and self.display_index < self.collection.size() - 1:
            self.display_index += 1
            self.store_mode_runtime_state()
            self.redraw_image()
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

    def _update_fiber_params_from_ui(self, fiber_params):
        """Update a FiberImage/FiberImage3D params object from current UI state for saving."""
        try:
            if hasattr(fiber_params, 'generateCenterlineLabel'):
                fiber_params.generateCenterlineLabel.value = bool(self.generate_centerline_checkbox.isChecked())
            if hasattr(fiber_params, 'generateFiberImage'):
                fiber_params.generateFiberImage.value = bool(self.generate_fiber_checkbox.isChecked())
            if hasattr(fiber_params, 'centerlineOutputType'):
                fiber_params.centerlineOutputType.value = "Binary"
            if hasattr(fiber_params, 'centerlineMaskWidthPx'):
                fiber_params.centerlineMaskWidthPx.value = int(self.centerline_mask_width_field.text() or fiber_params.centerlineMaskWidthPx.value)
            if hasattr(fiber_params, 'maskOutputMode'):
                fiber_params.maskOutputMode.value = "Binary"
            if hasattr(fiber_params, 'sync_legacy_output_fields'):
                fiber_params.sync_legacy_output_fields()
            if hasattr(fiber_params, 'showCenterlineOverlay'):
                fiber_params.showCenterlineOverlay.use = bool(self.show_centerline_checkbox.isChecked())
            if hasattr(fiber_params, 'centerlineOverlayColor'):
                fiber_params.centerlineOverlayColor.value = self.centerline_color_combo.currentText()
            if hasattr(fiber_params, 'centerlineOverlayBrightness'):
                fiber_params.centerlineOverlayBrightness.value = 1.2

            # Common smoothing options
            fiber_params.bubble.use = bool(self.bubble_check.isChecked())
            fiber_params.bubble.value = int(self.bubble_field.text() or fiber_params.bubble.value)
            fiber_params.swap.use = bool(self.swap_check.isChecked())
            fiber_params.swap.value = int(self.swap_field.text() or fiber_params.swap.value)
            fiber_params.spline.use = bool(self.spline_check.isChecked())
            fiber_params.spline.value = int(self.spline_field.text() or fiber_params.spline.value)

            # Post-processing options (2D names)
            if hasattr(fiber_params, 'distance'):
                if self.is_3d_mode and hasattr(self, 'distance_falloff_check'):
                    fiber_params.distance.use = bool(self.distance_falloff_check.isChecked())
                    fiber_params.distance.value = float(self.distance_falloff_field.text() or fiber_params.distance.value)
                else:
                    fiber_params.distance.use = bool(self.distance_check.isChecked())
                    fiber_params.distance.value = float(self.distance_field.text() or fiber_params.distance.value)
            if hasattr(fiber_params, 'distanceFalloff'):
                fiber_params.distanceFalloff.use = bool(self.distance_falloff_check.isChecked())
                fiber_params.distanceFalloff.value = float(self.distance_falloff_field.text() or fiber_params.distanceFalloff.value)
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
                if self.is_3d_mode and hasattr(self, 'blur_radius_check'):
                    fiber_params.blur.use = bool(self.blur_radius_check.isChecked())
                    fiber_params.blur.value = float(self.blur_radius_field.text() or fiber_params.blur.value)
                else:
                    fiber_params.blur.use = bool(self.blur_check.isChecked())
                    fiber_params.blur.value = float(self.blur_field.text() or fiber_params.blur.value)
            if hasattr(fiber_params, 'blurRadius'):
                fiber_params.blurRadius.use = bool(self.blur_radius_check.isChecked())
                fiber_params.blurRadius.value = float(self.blur_radius_field.text() or fiber_params.blurRadius.value)
            if hasattr(fiber_params, 'scale'):
                fiber_params.scale.use = bool(self.scale_check.isChecked())
                fiber_params.scale.value = float(self.scale_field.text() or fiber_params.scale.value)

            # Noise model handling (2D: noise/noiseStdDev/saltPepperProb; 3D: noiseMean/noiseStdDev/saltPepperProb)
            model = self.noise_model_combo.currentText().lower()
            if hasattr(fiber_params, 'noiseModel'):
                fiber_params.noiseModel.value = model.title() if model != 'no noise' else 'No Noise'
            # 2D Poisson mean
            if hasattr(fiber_params, 'noise'):
                noise_enabled = self.noise_mean_check.isChecked() if self.is_3d_mode else self.noise_check.isChecked()
                noise_text = self.noise_mean_field.text() if self.is_3d_mode else self.noise_field.text()
                fiber_params.noise.use = (model in ('poisson', 'poisson+gaussian')) and noise_enabled
                if noise_text:
                    fiber_params.noise.value = float(noise_text)
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

    def _apply_ui_smoothing_to_fiber_image(self, fiber_image):
        is_volume = isinstance(fiber_image, FiberImage3D)
        for fiber in fiber_image.fibers:
            if fiber_image.params.bubble.use:
                if is_volume:
                    fiber.bubble_smooth_3d(fiber_image.params.bubble.get_value())
                else:
                    fiber.bubble_smooth(fiber_image.params.bubble.get_value())
            if fiber_image.params.swap.use:
                if is_volume:
                    fiber.swap_smooth_3d(fiber_image.params.swap.get_value())
                else:
                    fiber.swap_smooth(fiber_image.params.swap.get_value())
            if fiber_image.params.spline.use:
                fiber.spline_smooth(fiber_image.params.spline.get_value())
        for fiber in fiber_image.fibers:
            fiber.calculate_orientations()

    def _build_render_fiber_image(self, index):
        source_image = self.collection.get(index)
        render_params = deepcopy(source_image.params)
        self._update_fiber_params_from_ui(render_params)
        render_image = FiberImage3D(render_params) if self.is_3d_mode else FiberImage(render_params)

        try:
            render_image.fibers = deepcopy(self.original_fibers_by_index[index])
        except Exception:
            render_image.fibers = deepcopy(source_image.fibers)

        self._apply_ui_smoothing_to_fiber_image(render_image)
        if self.is_3d_mode:
            render_image.apply_topology_3d()
            for fiber in render_image.fibers:
                fiber.calculate_orientations()
            render_image.joint_points = render_image.count_joints()
        else:
            try:
                render_image.joint_points = render_image.count_joints()
            except Exception:
                render_image.joint_points = deepcopy(getattr(source_image, 'joint_points', []))

        return render_image

    def _preview_target_suffix(self, preview_target):
        return "centerline_mask" if preview_target == "centerline_mask" else "fiber"

    def build_session_restore_state(self):
        return {
            "current_mode": "3D" if self.is_3d_mode else "2D",
            "params_2d": self.params_2d.to_dict() if hasattr(self, "params_2d") else None,
            "params_3d": self.params_3d.to_dict() if hasattr(self, "params_3d") else None,
            "display_index_2d": getattr(self, "display_index_2d", 0),
            "display_index_3d": getattr(self, "display_index_3d", 0),
            "active_preview_target": self.get_active_preview_target(),
            "preview_target_label": self.preview_target_combo.currentText(),
            "preview_3d_view": self.get_3d_view_mode(),
            "show_joints": bool(self.show_joints_checkbox.isChecked()),
            "show_centerline_overlay": bool(self.show_centerline_checkbox.isChecked()),
            "centerline_overlay_color": self.centerline_color_combo.currentText(),
            "generate_centerline_mask": bool(self.generate_centerline_checkbox.isChecked()),
            "generate_fiber_image": bool(self.generate_fiber_checkbox.isChecked()),
            "export_detail": self.get_export_detail_level(),
            "out_folder_2d": getattr(self, "out_folder_2d", None),
            "out_folder_3d": getattr(self, "out_folder_3d", None),
        }

    def _default_sample_name(self, index):
        return f"{'3d' if self.is_3d_mode else '2d'}_sample_{index:03d}"

    def _build_export_sample_for_index(self, index, sample_name=None):
        render_image = self._build_render_fiber_image(index)
        centerline_mask = None
        fiber_output = None
        enhanced_output = None
        base_fiber_output = None

        if self.generate_centerline_checkbox.isChecked():
            if self.is_3d_mode:
                centerline_mask = render_image.render_centerline_volume_3d()
            else:
                centerline_mask = render_image.render_centerline_label_2d()

        if self.generate_fiber_checkbox.isChecked():
            if self.is_3d_mode:
                base_fiber_output = render_image.render_fiber_volume_3d()
                fiber_output = FiberImage3D.apply_postprocessing_3d(base_fiber_output, render_image.params)
            else:
                base_fiber_output = render_image.render_fiber_image_2d()
                fiber_output = FiberImage.apply_postprocessing_2d(base_fiber_output, render_image.params)

        if self.is_3d_mode:
            render_image.calculate_validation_metrics_3d(
                fiber_volume=base_fiber_output,
                centerline_volume=centerline_mask,
            )

        sample_name = sample_name or self._default_sample_name(index)
        return build_canonical_sample(
            render_image,
            image_id=sample_name,
            sample_id=sample_name,
            centerline_mask=centerline_mask,
            fiber_image_array=fiber_output,
            enhanced_image=enhanced_output,
        )

    def _export_sample_to_directory(self, index, sample_dir, export_detail, include_session_restore):
        sample_name = os.path.basename(sample_dir)
        sample = self._build_export_sample_for_index(index, sample_name=sample_name)
        if export_detail == EXPORT_DETAIL_FULL:
            export_full_raw_geometry(sample_dir, sample, include_excel=True)
        else:
            export_canonical_research_package(sample_dir, sample, include_excel=True)
        if include_session_restore:
            export_session_restore(sample_dir, self.build_session_restore_state())
        return build_dataset_manifest_rows(sample, sample_dir)

    def _render_output_for_index(self, index, output_target=None):
        render_image = self._build_render_fiber_image(index)
        preview_target = output_target or self.get_active_preview_target()
        if preview_target is None:
            raise ValueError("Enable at least one derived output before previewing or saving.")
        if preview_target == "centerline_mask":
            if self.is_3d_mode:
                final_output = render_image.render_centerline_volume_3d()
                render_image.calculate_validation_metrics_3d(centerline_volume=final_output)
            else:
                final_output = render_image.render_centerline_label_2d()
        else:
            if self.is_3d_mode:
                base_output = render_image.render_fiber_volume_3d()
                render_image.calculate_validation_metrics_3d(fiber_volume=base_output)
                final_output = FiberImage3D.apply_postprocessing_3d(base_output, render_image.params)
            else:
                base_output = render_image.render_fiber_image_2d()
                final_output = FiberImage.apply_postprocessing_2d(base_output, render_image.params)
        return render_image, final_output

    def save_current_preview_pressed(self):
        self._save_selected_result(custom=self.export_custom_checkbox.isChecked())

    def save_all_preview_pressed(self):
        self._save_all_results(custom=self.export_custom_checkbox.isChecked())

    def save_results_pressed(self):
        """Prompt to choose exporting the selected sample or all samples, with optional custom naming/location."""
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to export. Click Generate first.")
                return

            # Ask user which scope to export
            box = QMessageBox(self)
            box.setWindowTitle("Export")
            box.setText("Export the current sample or all generated samples?")
            save_selected_btn = box.addButton("Export Current", QMessageBox.ButtonRole.AcceptRole)
            save_all_btn = box.addButton("Export All", QMessageBox.ButtonRole.AcceptRole)
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
        """Export the currently displayed sample as a canonical package."""
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to export. Click Generate first.")
                return

            base_out = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
            export_detail = self.get_export_detail_level()
            include_session_restore = self.export_session_checkbox.isChecked()
            sample_name = self._default_sample_name(self.display_index)

            if custom:
                parent_dir = QFileDialog.getExistingDirectory(self, "Select Export Directory", base_out)
                if not parent_dir:
                    return
                sample_name_input, ok = QInputDialog.getText(
                    self,
                    "Sample Folder Name",
                    "Sample folder name:",
                    text=sample_name,
                )
                if not ok:
                    return
                sample_name = sample_name_input.strip() or sample_name
                parent_dir = os.path.abspath(parent_dir)
            else:
                parent_dir = self._make_unique_save_dir(base_out)

            sample_dir = self._make_unique_named_dir(parent_dir, sample_name)
            manifest_row = self._export_sample_to_directory(
                self.display_index,
                sample_dir,
                export_detail=export_detail,
                include_session_restore=include_session_restore,
            )
            write_dataset_manifest(parent_dir, [manifest_row])

            QMessageBox.information(self, "Exported", f"Exported current sample package to:\n{sample_dir}")
        except Exception as e:
            self.show_error(str(e))

    def _rebuild_2d_image_from_fiber_list(self, fiber_image, fibers_list):
        """Rebuild a 2D PIL image from a provided list of fibers using the given fiber_image params."""
        return FiberImage.render_fibers_to_image(
            fibers_list,
            (fiber_image.params.imageWidth.get_value(), fiber_image.params.imageHeight.get_value())
        )

    def _save_all_results(self, custom: bool = False):
        """Export all generated samples as canonical packages."""
        try:
            if self.collection is None or self.collection.size() == 0:
                self.show_error("No generated images to export. Click Generate first.")
                return
            base_out = self.out_folder_3d if self.is_3d_mode else self.out_folder_2d
            export_detail = self.get_export_detail_level()
            include_session_restore = self.export_session_checkbox.isChecked()
            if custom:
                parent_dir = QFileDialog.getExistingDirectory(self, "Select Export Directory", base_out)
                if not parent_dir:
                    return
                default_prefix = f"{'3d' if self.is_3d_mode else '2d'}_sample_"
                prefix, ok = QInputDialog.getText(self, "Sample Prefix", "Sample folder prefix:", text=default_prefix)
                if not ok:
                    return
                prefix = (prefix.strip() or default_prefix)
            else:
                parent_dir = self._make_unique_save_dir(base_out)
                prefix = f"{'3d' if self.is_3d_mode else '2d'}_sample_"

            dataset_rows = []
            for i in range(self.collection.size()):
                sample_dir = self._make_unique_named_dir(parent_dir, f"{prefix}{i:03d}")
                dataset_rows.append(
                    self._export_sample_to_directory(
                        i,
                        sample_dir,
                        export_detail=export_detail,
                        include_session_restore=include_session_restore,
                    )
                )

            write_dataset_manifest(parent_dir, dataset_rows)
            QMessageBox.information(self, "Exported", f"Exported {self.collection.size()} sample packages to:\n{parent_dir}")
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

    def _make_unique_named_dir(self, parent_folder: str, base_name: str) -> str:
        os.makedirs(parent_folder, exist_ok=True)
        candidate = os.path.join(parent_folder, base_name)
        counter = 1
        while os.path.exists(candidate):
            candidate = os.path.join(parent_folder, f"{base_name}_{counter:02d}")
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

    def intensity_pressed(self):
        dialog = DistributionDialog(self.params.intensity)
        dialog.exec()
        self.params.intensity = dialog.distribution
        self.display_params()
      
    def display_image(self, image, fiber_image=None):
        if self.is_3d_mode:
            self.display_image_3d(image, fiber_image=fiber_image)
        else:
            self.display_image_2d(image, fiber_image=fiber_image)
            
    def redraw_image(self):
        # Skip redraws while we are in the middle of switching modes
        if getattr(self, '_suspend_redraw', False):
            return
        self.restore_current_mode_preview()
    
    def re_smooth_fibers(self):
        return self._build_render_fiber_image(self.display_index)
                    
    def rebuild_image_from_fibers(self):
        fiber_image = self._build_render_fiber_image(self.display_index)
        return fiber_image.render_base_image_2d()
    
    def apply_postprocessing(self, image):
        params = deepcopy(self.collection.get(self.display_index).params)
        self._update_fiber_params_from_ui(params)
        return FiberImage.apply_postprocessing_2d(image, params)
    
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

    @staticmethod
    def resolve_centerline_overlay_color(color_name, brightness):
        base_colors = {
            "green": (0, 255, 0),
            "neon green": (57, 255, 20),
            "cyan": (0, 255, 255),
            "magenta": (255, 0, 255),
            "yellow": (255, 255, 0),
        }
        key = str(color_name).strip().lower()
        base_color = base_colors.get(key, base_colors["neon green"])
        try:
            brightness_value = float(brightness)
        except (TypeError, ValueError):
            brightness_value = 1.0
        brightness_value = max(brightness_value, 0.1)
        return tuple(min(255, int(round(channel * brightness_value))) for channel in base_color)

    @classmethod
    def get_centerline_overlay_style(cls, params):
        color_name = getattr(getattr(params, "centerlineOverlayColor", None), "value", "Neon Green")
        brightness = getattr(getattr(params, "centerlineOverlayBrightness", None), "value", 1.0)
        rgb = cls.resolve_centerline_overlay_color(color_name, brightness)
        napari_color = "#{:02X}{:02X}{:02X}".format(*rgb)
        return rgb, napari_color

    def get_centerline_overlay_style_from_ui(self):
        color_name = self.centerline_color_combo.currentText() if hasattr(self, "centerline_color_combo") else "Neon Green"
        rgb = self.resolve_centerline_overlay_color(color_name, 1.2)
        napari_color = "#{:02X}{:02X}{:02X}".format(*rgb)
        return rgb, napari_color

    @staticmethod
    def overlay_centerlines_on_image(base_image, fiber_image, color, width=2):
        rgb = base_image.convert("RGB") if base_image.mode != "RGB" else base_image.copy()
        draw = ImageDraw.Draw(rgb)
        try:
            width_px = float(fiber_image.params.imageWidth.get_value())
            height_px = float(fiber_image.params.imageHeight.get_value())
            if width_px <= 0 or height_px <= 0:
                return rgb
            scale_x = rgb.width / width_px
            scale_y = rgb.height / height_px
        except Exception:
            scale_x = 1.0
            scale_y = 1.0

        max_x = max(rgb.width - 1, 0)
        max_y = max(rgb.height - 1, 0)
        for fiber in getattr(fiber_image, "fibers", []):
            points = getattr(fiber, "points", None)
            if not points or len(points) < 2:
                continue
            line_points = []
            for point in points:
                x = int(round(point.x * scale_x))
                y = int(round(point.y * scale_y))
                if x < 0 or y < 0 or x > max_x or y > max_y:
                    x = min(max(x, 0), max_x)
                    y = min(max(y, 0), max_y)
                line_points.append((x, y))
            if len(line_points) >= 2:
                draw.line(line_points, fill=color, width=width)
        return rgb

    @staticmethod
    def get_centerline_paths_3d(fiber_image):
        paths = []
        for fiber in getattr(fiber_image, "fibers", []):
            points = getattr(fiber, "points", [])
            if len(points) < 2:
                continue
            paths.append(
                np.asarray(
                    [[point.z, point.y, point.x] for point in points],
                    dtype=float,
                )
            )
        return paths

    @staticmethod
    def get_fiber_segment_shapes_3d(fiber_image):
        segments = []
        widths = []
        for fiber in getattr(fiber_image, "fibers", []):
            for segment in fiber:
                segments.append(
                    np.asarray(
                        [
                            [segment.start.z, segment.start.y, segment.start.x],
                            [segment.end.z, segment.end.y, segment.end.x],
                        ],
                        dtype=float,
                    )
                )
                widths.append(FiberImage3D.get_rendered_tube_diameter_3d(segment.width, min_diameter=1))
        return segments, np.asarray(widths, dtype=float)

    def get_viewer_camera_state(self):
        try:
            return {
                "angles": tuple(self.viewer.camera.angles),
                "center": tuple(self.viewer.camera.center),
                "zoom": float(self.viewer.camera.zoom),
                "perspective": float(self.viewer.camera.perspective),
            }
        except Exception:
            return None

    def restore_viewer_camera_state(self, state):
        if not state:
            return
        try:
            self.viewer.camera.angles = state["angles"]
            self.viewer.camera.center = state["center"]
            self.viewer.camera.zoom = state["zoom"]
            self.viewer.camera.perspective = state["perspective"]
        except Exception:
            pass

    def _set_advanced_viewer_closed(self, *_args):
        self.advanced_viewer = None
        self.advanced_viewer_is_3d = None

    def _get_or_create_advanced_napari_viewer(self, is_3d):
        viewer = getattr(self, "advanced_viewer", None)
        viewer_mode = getattr(self, "advanced_viewer_is_3d", None)
        if viewer is not None and viewer_mode == is_3d:
            try:
                _ = len(viewer.layers)
                return viewer
            except Exception:
                self.advanced_viewer = None
                self.advanced_viewer_is_3d = None
        elif viewer is not None:
            try:
                viewer.window._qt_window.close()
            except Exception:
                pass
            self.advanced_viewer = None
            self.advanced_viewer_is_3d = None

        try:
            viewer = napari.Viewer(ndisplay=3 if is_3d else 2, show=False)
        except TypeError:
            viewer = napari.Viewer(ndisplay=3 if is_3d else 2)
        self.advanced_viewer = viewer
        self.advanced_viewer_is_3d = is_3d
        try:
            mode_label = "3D" if is_3d else "2D"
            viewer.window._qt_window.setWindowTitle(f"Fiber Generator - Advanced {mode_label} Viewer")
            viewer.window._qt_window.destroyed.connect(self._set_advanced_viewer_closed)
        except Exception:
            pass
        return viewer

    def update_3d_centerline_layer_for_viewer(self, viewer, fiber_image=None, visible=True):
        if viewer is None:
            return

        layer_name = 'Centerline Overlay'
        centerline_layer = viewer.layers[layer_name] if layer_name in viewer.layers else None
        if not visible:
            if centerline_layer is not None:
                centerline_layer.visible = False
            return

        if fiber_image is None:
            if self.collection is None:
                return
            fiber_image = self._build_render_fiber_image(self.display_index)

        if not isinstance(fiber_image, FiberImage3D):
            if centerline_layer is not None:
                centerline_layer.visible = False
            return

        centerline_paths = self.get_centerline_paths_3d(fiber_image)
        if not centerline_paths:
            if centerline_layer is not None:
                centerline_layer.visible = False
            return

        _, napari_color = self.get_centerline_overlay_style_from_ui()

        if centerline_layer is None:
            viewer.add_shapes(
                data=centerline_paths,
                name=layer_name,
                shape_type='path',
                edge_color=napari_color,
                edge_width=1.0,
                opacity=1.0,
            )
        else:
            centerline_layer.data = centerline_paths
            centerline_layer.edge_color = napari_color
            centerline_layer.edge_width = 1.0
            centerline_layer.opacity = 1.0
            centerline_layer.visible = True

    def update_3d_centerline_layer(self, fiber_image=None):
        if not hasattr(self, 'viewer') or self.viewer is None:
            return

        camera_state = self.get_viewer_camera_state()
        self.update_3d_centerline_layer_for_viewer(
            self.viewer,
            fiber_image=fiber_image,
            visible=(
                self.show_centerline_checkbox.isChecked()
                and self.get_active_preview_target() != "centerline_mask"
            ),
        )
        self.restore_viewer_camera_state(camera_state)

    def populate_2d_viewer(self, viewer, image, fiber_image=None, include_overlay=False, include_joints=False, reset_view=True):
        if viewer is None:
            return

        viewer.layers.clear()

        if not isinstance(image, Image.Image):
            try:
                image = Image.fromarray(np.array(image))
            except Exception:
                image = self.collection.get_image(self.display_index)

        if fiber_image is None and self.collection is not None:
            fiber_image = self.collection.get(self.display_index)

        display_image = image
        if include_overlay and fiber_image is not None:
            centerline_rgb, _ = self.get_centerline_overlay_style_from_ui()
            display_image = self.overlay_centerlines_on_image(display_image, fiber_image, color=centerline_rgb)

        base_image = display_image.convert('RGBA')
        if include_joints and fiber_image is not None:
            overlay = Image.new('RGBA', base_image.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(overlay)
            for joint in fiber_image.joint_points:
                draw.ellipse(
                    (joint.x - 3, joint.y - 3, joint.x + 3, joint.y + 3),
                    outline='red',
                    fill='red'
                )
            base_image = Image.alpha_composite(base_image, overlay)

        image_data = np.array(base_image.convert('RGB'))
        viewer.dims.ndisplay = 2
        viewer.add_image(
            image_data,
            name='2D Image',
            rgb=True,
            interpolation2d='nearest',
        )
        if reset_view:
            viewer.reset_view()

    def populate_3d_viewer(self, viewer, image, fiber_image=None, include_overlay=False, reset_view=True, view_mode=None):
        if viewer is None:
            return

        viewer.layers.clear()

        if isinstance(image, np.ndarray):
            image_data = image
        else:
            try:
                image_data = np.array(image)
            except Exception:
                image_data = None

        if image_data is None or image_data.ndim != 3:
            image_data = self.collection.get_image(self.display_index)
        if image_data.ndim == 2:
            image_data = image_data[np.newaxis, ...]

        if fiber_image is None and self.collection is not None:
            fiber_image = self.collection.get(self.display_index)

        selected_view_mode = view_mode or self.get_3d_view_mode()
        image_kwargs = {
            'name': '3D Image',
            'colormap': 'gray',
            'contrast_limits': (0, 255),
        }
        viewer.dims.ndisplay = 3
        rendering_mode = {
            "projection": "mip",
            "attenuated": "attenuated_mip",
            "isosurface": "iso",
        }.get(selected_view_mode, "mip")
        image_kwargs['rendering'] = rendering_mode
        image_kwargs['interpolation3d'] = 'nearest'
        if rendering_mode == "iso":
            nonzero = image_data[image_data > 0]
            image_kwargs['iso_threshold'] = float(np.percentile(nonzero, 35)) if nonzero.size else 1.0

        try:
            viewer.add_image(image_data, **image_kwargs)
        except Exception:
            fallback_kwargs = {
                'name': '3D Image',
                'colormap': 'gray',
                'contrast_limits': (0, 255),
                'rendering': 'mip',
                'interpolation3d': 'nearest',
            }
            viewer.dims.ndisplay = 3
            viewer.add_image(image_data, **fallback_kwargs)

        if fiber_image is not None:
            self.update_3d_centerline_layer_for_viewer(
                viewer,
                fiber_image=fiber_image,
                visible=include_overlay,
            )
        if reset_view:
            viewer.reset_view()

    def open_current_preview_in_napari(self):
        if self.collection is None or self.collection.size() == 0:
            self.show_error(f"No generated {'3D' if self.is_3d_mode else '2D'} preview to open.")
            return
        preview_target = self.get_active_preview_target()
        if preview_target is None:
            self.show_error("Enable a centerline or fiber output before opening a preview.")
            return

        viewer = self._get_or_create_advanced_napari_viewer(self.is_3d_mode)
        fiber_image, rendered_output = self._render_output_for_index(self.display_index, output_target=preview_target)
        if self.is_3d_mode:
            self.populate_3d_viewer(
                viewer,
                rendered_output,
                fiber_image=fiber_image,
                include_overlay=(
                    self.show_centerline_checkbox.isChecked()
                    and preview_target != "centerline_mask"
                ),
                reset_view=True,
                view_mode=self.get_3d_view_mode(),
            )
        else:
            self.populate_2d_viewer(
                viewer,
                rendered_output,
                fiber_image=fiber_image,
                include_overlay=(
                    self.show_centerline_checkbox.isChecked()
                    and preview_target != "centerline_mask"
                ),
                include_joints=self.show_joints_checkbox.isChecked(),
                reset_view=True,
            )
        try:
            viewer.window._qt_window.show()
            viewer.window._qt_window.raise_()
            viewer.window._qt_window.activateWindow()
        except Exception:
            pass

    def update_3d_fiber_preview_layer(self, fiber_image=None):
        if not hasattr(self, 'viewer') or self.viewer is None:
            return

        fiber_layer = self.viewer.layers['Fiber Preview'] if 'Fiber Preview' in self.viewer.layers else None
        if self.get_active_preview_target() != "fiber_image":
            if fiber_layer is not None:
                fiber_layer.visible = False
            return

        if fiber_image is None:
            if self.collection is None:
                return
            fiber_image = self._build_render_fiber_image(self.display_index)

        segment_shapes, segment_widths = self.get_fiber_segment_shapes_3d(fiber_image)
        if not segment_shapes:
            if fiber_layer is not None:
                fiber_layer.visible = False
            return

        if fiber_layer is None:
            self.viewer.add_shapes(
                data=segment_shapes,
                name='Fiber Preview',
                shape_type='line',
                face_color=np.array([0.0, 0.0, 0.0, 0.0]),
                edge_color='white',
                edge_width=segment_widths,
                opacity=0.9
            )
        else:
            fiber_layer.data = segment_shapes
            fiber_layer.face_color = np.array([0.0, 0.0, 0.0, 0.0])
            fiber_layer.edge_color = 'white'
            fiber_layer.edge_width = segment_widths
            fiber_layer.opacity = 0.9
            fiber_layer.visible = True

    def display_image_2d(self, image, fiber_image=None):
        self.show_2d_viewer()
        self.populate_2d_viewer(
            self.viewer_2d,
            image,
            fiber_image=fiber_image,
            include_overlay=(
                self.show_centerline_checkbox.isChecked()
                and self.get_active_preview_target() != "centerline_mask"
            ),
            include_joints=self.show_joints_checkbox.isChecked(),
            reset_view=True,
        )

    def display_image_3d(self, image, fiber_image=None):
        self.show_3d_viewer()
        self.populate_3d_viewer(
            self.viewer,
            image,
            fiber_image=fiber_image,
            include_overlay=(
                self.show_centerline_checkbox.isChecked()
                and self.get_active_preview_target() != "centerline_mask"
            ),
            reset_view=True,
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
        self.set_optional_row_editable(self.noise_std_check, self.noise_std_field, show_std)

        # Salt-Pepper prob widgets
        self.saltpepper_label.setVisible(show_sp)
        self.set_optional_row_editable(self.saltpepper_check, self.saltpepper_field, show_sp)

        # Poisson mean widgets depend on mode
        if self.is_3d_mode:
            self.noise_mean_label.setVisible(show_poisson_mean)
            self.set_optional_row_editable(self.noise_mean_check, self.noise_mean_field, show_poisson_mean)
            # Hide 2D Poisson mean controls
            self.noise_label.setVisible(False)
            self.set_optional_row_editable(self.noise_check, self.noise_field, False)
        else:
            self.noise_label.setVisible(show_poisson_mean)
            self.set_optional_row_editable(self.noise_check, self.noise_field, show_poisson_mean)
            # Hide 3D Poisson mean controls
            self.noise_mean_label.setVisible(False)
            self.set_optional_row_editable(self.noise_mean_check, self.noise_mean_field, False)

    def update_psf_controls_visibility(self):
        enabled = self.apply_psf_checkbox.isChecked()
        mode = self.psf_type_combo.currentText().lower()
        show_gaussian = "gaussian" in mode
        show_vectorial = "vectorial" in mode
        self.psf_gaussian_group.setVisible(show_gaussian)
        self.psf_vectorial_group.setVisible(show_vectorial)
        self.preview_psf_button.setEnabled(enabled and self.psf_type_combo.currentText() != "None")
        for field in self.psf_gaussian_group.findChildren(QLineEdit):
            self.set_line_edit_active(field, show_gaussian)
        for field in self.psf_vectorial_group.findChildren(QLineEdit):
            self.set_line_edit_active(field, show_vectorial)

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
