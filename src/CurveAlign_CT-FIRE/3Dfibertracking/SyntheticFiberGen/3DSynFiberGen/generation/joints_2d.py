from __future__ import annotations

import time
from copy import deepcopy
from typing import Any, cast

import numpy as np

from core.abort import _raise_if_aborted
from core.geometry import MiscUtility, Vector
from core.rng import RngUtility
from generation.fiber import Fiber

JOINT_MATCH_MAX_ATTEMPTS = 16
JOINT_MATCH_TOLERANCE_RATIO = 0.1


def generate_directions_2d(sample):
    mean_angle_radians = np.radians(sample.params.meanAngle.get_value())
    mean_direction = Vector(np.cos(mean_angle_radians), np.sin(mean_angle_radians))
    alignment_factor = sample.params.alignment.get_value() * sample.params.nFibers.get_value()
    sum_vector = mean_direction.scalar_multiply(alignment_factor)
    chain = RngUtility.random_chain(Vector(), sum_vector, sample.params.nFibers.get_value(), 1.0)
    return [direction.normalize() for direction in MiscUtility.to_deltas(chain)]


def find_start_2d(length, dimension, buffer):
    dimension = float(dimension)
    length = float(length)
    buffer = max(0.0, float(buffer))

    min_val = max(buffer, buffer - length)
    max_val = min(dimension - buffer - length, dimension - buffer)
    if min_val <= max_val:
        return RngUtility.next_double(min_val, max_val)

    min_val = max(0.0, -length)
    max_val = min(dimension - length, dimension)
    if min_val <= max_val:
        return RngUtility.next_double(min_val, max_val)

    return 0.5 * (dimension - length)


def find_fiber_start_2d(sample, length, direction):
    x_length = direction.normalize().x * length
    y_length = direction.normalize().y * length
    x = find_start_2d(x_length, sample.params.imageWidth.get_value(), sample.params.imageBuffer.get_value())
    y = find_start_2d(y_length, sample.params.imageHeight.get_value(), sample.params.imageBuffer.get_value())
    return Vector(x, y)


def count_joints_2d(sample, abort_check=None):
    start_time = time.perf_counter()
    for fiber in sample.fibers:
        fiber.has_joint = False
    joints = set()
    for index, fiber1 in enumerate(sample.fibers):
        if index % 4 == 0:
            _raise_if_aborted(abort_check)
        for fiber2 in sample.fibers[index + 1:]:
            _raise_if_aborted(abort_check)
            for seg1_index, seg1 in enumerate(fiber1):
                if seg1_index % 32 == 0:
                    _raise_if_aborted(abort_check)
                for seg2_index, seg2 in enumerate(fiber2):
                    if seg2_index % 32 == 0:
                        _raise_if_aborted(abort_check)
                    intersection_point = MiscUtility.get_intersection_point(seg1.start, seg1.end, seg2.start, seg2.end)
                    if intersection_point:
                        joints.add(intersection_point)
                        fiber1.has_joint = True
                        fiber2.has_joint = True
                    if MiscUtility.point_on_segment(seg1.end, seg2.start, seg2.end):
                        joints.add(seg1.end)
                        fiber1.has_joint = True
                        fiber2.has_joint = True
                    if MiscUtility.point_on_segment(seg2.end, seg1.start, seg1.end):
                        joints.add(seg2.end)
                        fiber1.has_joint = True
                        fiber2.has_joint = True
    sample.joints = joints
    sample.record_timing("joint_count_2d_seconds", time.perf_counter() - start_time)
    return list(joints)


def generate_fibers_2d(sample, abort_check=None):
    start_time = time.perf_counter()
    target_joint_count = int(sample.params.jointPoints.get_value()) if sample.params.useJoints.use else None
    joint_tolerance = 0 if not sample.params.useJoints.use or target_joint_count <= 0 else max(
        1,
        int(round(target_joint_count * JOINT_MATCH_TOLERANCE_RATIO)),
    )
    max_iterations = JOINT_MATCH_MAX_ATTEMPTS if sample.params.useJoints.use else 1
    best_candidate: dict[str, Any] | None = None
    accepted_iteration = None

    for iteration in range(max_iterations):
        if iteration % 8 == 0:
            _raise_if_aborted(abort_check)
        sample.fibers = []
        sample.joint_points = []
        directions = generate_directions_2d(sample)

        for direction_index, direction in enumerate(directions):
            if direction_index % 8 == 0:
                _raise_if_aborted(abort_check)
            fiber_params = Fiber.Params()
            fiber_params.segment_length = sample.params.segmentLength.get_value()
            fiber_params.width_change = sample.params.widthChange.get_value()
            fiber_params.n_segments = max(1, round(sample.params.length.sample() / sample.params.segmentLength.get_value()))
            fiber_params.straightness = sample.params.straightness.sample()
            fiber_params.start_width = sample.params.width.sample()

            end_distance = fiber_params.n_segments * fiber_params.segment_length * fiber_params.straightness
            fiber_params.start = find_fiber_start_2d(sample, end_distance, direction)
            fiber_params.end = fiber_params.start.add(direction.scalar_multiply(end_distance))

            fiber = Fiber(fiber_params)
            fiber.generate(abort_check=abort_check)
            if hasattr(sample.params, "intensity"):
                fiber.intensity = sample.params.intensity.sample()
            sample.fibers.append(fiber)

        if sample.params.useJoints.use:
            joint_points = count_joints_2d(sample, abort_check=abort_check)
            joint_count = len(joint_points)
            joint_delta = abs(joint_count - target_joint_count)
            best_joint_delta = None if best_candidate is None else best_candidate.get("joint_delta")
            if best_joint_delta is None or joint_delta < best_joint_delta:
                best_candidate = {
                    "fibers": deepcopy(sample.fibers),
                    "joint_points": deepcopy(joint_points),
                    "joint_delta": joint_delta,
                    "joint_count": joint_count,
                    "attempt_index": iteration + 1,
                }
            if joint_delta <= joint_tolerance:
                sample.joint_points = joint_points
                accepted_iteration = iteration + 1
                break
        else:
            sample.joint_points = []
            accepted_iteration = iteration + 1
            break
    else:
        if best_candidate is None:
            raise RuntimeError("Failed to generate the desired number of joints.")
        selected_candidate = cast(dict[str, Any], best_candidate)
        sample.fibers = selected_candidate["fibers"]
        sample.joint_points = selected_candidate["joint_points"]
        accepted_iteration = selected_candidate["attempt_index"]

    sample.joints_dirty = not sample.params.useJoints.use
    sample.invalidate_render_cache()
    sample.generation_metadata["joint_match_target"] = target_joint_count
    sample.generation_metadata["joint_match_tolerance"] = joint_tolerance
    sample.generation_metadata["joint_match_attempts"] = int(accepted_iteration or 1)
    sample.generation_metadata["joint_match_realized"] = int(len(sample.joint_points)) if sample.params.useJoints.use else None
    sample.record_timing("generate_fibers_2d_seconds", time.perf_counter() - start_time)


__all__ = [
    'JOINT_MATCH_MAX_ATTEMPTS',
    'JOINT_MATCH_TOLERANCE_RATIO',
    'count_joints_2d',
    'find_fiber_start_2d',
    'find_start_2d',
    'generate_directions_2d',
    'generate_fibers_2d',
]
