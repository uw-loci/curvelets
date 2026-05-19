
from __future__ import annotations

import math
import random

import numpy as np

from core.abort import _raise_if_aborted
from core.geometry import Circle, Vector

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
        abort_check=None,
    ):
        _raise_if_aborted(abort_check)
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
            _raise_if_aborted(abort_check)
            decay = 1.0 / (mode * mode)
            offset_u += np.random.normal(0.0, base_amplitude * decay) * np.sin(np.pi * mode * t_values)
            offset_v += np.random.normal(0.0, base_amplitude * decay) * np.sin(np.pi * mode * t_values)

        offset_field = offset_u[:, np.newaxis] * basis_u[np.newaxis, :] + offset_v[:, np.newaxis] * basis_v[np.newaxis, :]

        if target_length > chord_length + 1e-6:
            low_scale = 0.0
            high_scale = 4.0
            for _ in range(14):
                _raise_if_aborted(abort_check)
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
        _raise_if_aborted(abort_check)
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
