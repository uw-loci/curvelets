
from __future__ import annotations

import math
from copy import deepcopy
from typing import Iterator, List

import numpy as np
from scipy.interpolate import splrep, splev
from scipy.ndimage import label

from core.abort import GenerationAborted, _raise_if_aborted
from core.distributions import Gaussian, PiecewiseLinear, Uniform
from core.geometry import Circle, MiscUtility, MiscUtility3D, Vector
from core.params import Optional, Param
from core.rng import RngUtility, RngUtility3D

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

    def generate(self, abort_check=None):
        _raise_if_aborted(abort_check)
        self.points = RngUtility.random_chain(self.params.start, self.params.end, self.params.n_segments, self.params.segment_length)
        width = self.params.start_width
        for i in range(self.params.n_segments):
            if i % 32 == 0:
                _raise_if_aborted(abort_check)
            self.widths.append(width)
            variability = min(abs(width), self.params.width_change)
            width += RngUtility.next_double(-variability, variability)
            self.calculate_orientations()  # Calculate orientations after generating points
    
    def generate_3d(self, abort_check=None):
        self.abort_flag = False
        _raise_if_aborted(abort_check)

        self.points = RngUtility3D.generate_endpoint_constrained_curve_3d(
            self.params.start,
            self.params.end,
            self.params.n_segments,
            self.params.segment_length,
            self.params.straightness,
            self.params.max_angle_change,
            getattr(self.params, "curvature_scale", 1.0),
            abort_check=abort_check,
        )
        width = self.params.start_width
        self.widths = []

        for i in range(self.params.n_segments):
            if self.abort_flag:
                raise GenerationAborted("Generation aborted.")
            if i % 32 == 0:
                _raise_if_aborted(abort_check)
            self.widths.append(width)
            variability = min(abs(width), self.params.width_change)
            width += RngUtility.next_double(-variability, variability)

        _raise_if_aborted(abort_check)
        self.calculate_orientations()

    # 3. Add the following method to the Fiber class:
    def abort(self):
        """Sets the abort flag to True, causing generate_3d to stop processing."""
        print("DEBUG: Fiber.abort() called, setting abort_flag to True")
        self.abort_flag = True
        print("Abort flag set for 3D generation.")
        
    def bubble_smooth(self, passes, abort_check=None):
        deltas = MiscUtility.to_deltas(self.points)
        for _ in range(passes):
            _raise_if_aborted(abort_check)
            for j in range(len(deltas) - 1):
                if j % 32 == 0:
                    _raise_if_aborted(abort_check)
                self.try_swap(deltas, j, j + 1)
        self.points = MiscUtility.from_deltas(deltas, self.points[0])
        
    def bubble_smooth_3d(self, passes, abort_check=None):
        deltas = MiscUtility3D.to_deltas_3d(self.points)
        for _ in range(passes):
            _raise_if_aborted(abort_check)
            for j in range(len(deltas) - 1):
                if j % 32 == 0:
                    _raise_if_aborted(abort_check)
                self.try_swap(deltas, j, j + 1)
        self.points = MiscUtility3D.from_deltas_3d(deltas, self.points[0])

    def swap_smooth(self, ratio, abort_check=None):
        deltas = MiscUtility.to_deltas(self.points)
        for iteration in range(ratio * len(deltas)):
            if iteration % 64 == 0:
                _raise_if_aborted(abort_check)
            u = RngUtility.rng.randint(0, len(deltas) - 1)
            v = RngUtility.rng.randint(0, len(deltas) - 1)
            self.try_swap(deltas, u, v)
        self.points = MiscUtility.from_deltas(deltas, self.points[0])
        
    def swap_smooth_3d(self, ratio, abort_check=None):
        deltas = MiscUtility3D.to_deltas_3d(self.points)
        for iteration in range(ratio * len(deltas)):
            if iteration % 64 == 0:
                _raise_if_aborted(abort_check)
            u = RngUtility.rng.randint(0, len(deltas) - 1)
            v = RngUtility.rng.randint(0, len(deltas) - 1)
            self.try_swap(deltas, u, v)
        self.points = MiscUtility3D.from_deltas_3d(deltas, self.points[0])

    def spline_smooth(self, spline_ratio, abort_check=None):
        _raise_if_aborted(abort_check)
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
            if i % max(1, spline_ratio * 8) == 0:
                _raise_if_aborted(abort_check)
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
