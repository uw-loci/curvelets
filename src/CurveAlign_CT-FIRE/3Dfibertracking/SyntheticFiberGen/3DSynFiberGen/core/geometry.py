
from __future__ import annotations

import math
import numpy as np


def _rng_utility():
    from core.rng import RngUtility

    return RngUtility


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
        from PyQt6.QtWidgets import QMessageBox
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
        theta = _rng_utility().next_double(min_theta, max_theta)
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
                point = Vector(_rng_utility().next_double(inner.center().x - inner.radius(), inner.center().x + inner.radius()),
                               _rng_utility().next_double(inner.center().y - inner.radius(), inner.center().y + inner.radius()))
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
            delta = Vector(_rng_utility().next_double(box_left, box_right), _rng_utility().next_double(-box_height, box_height))
            result = disk1.center() + delta.un_rotate(axis)
            if disk1.contains(result) and disk2.contains(result):
                return result
        raise RuntimeError("Failed to find a valid intersection in disk_disk_intersect")
