from __future__ import annotations

from typing import cast

import numpy as np

from core.abort import _raise_if_aborted
from core.geometry import Vector


def closest_point_on_segment_3d(point, start, end):
    point_arr = point.to_array().astype(float)
    start_arr = start.to_array().astype(float)
    end_arr = end.to_array().astype(float)
    seg = end_arr - start_arr
    seg_len_sq = float(np.dot(seg, seg))
    if seg_len_sq <= 1e-8:
        closest = start_arr
        t_value = 0.0
    else:
        t_value = float(np.clip(np.dot(point_arr - start_arr, seg) / seg_len_sq, 0.0, 1.0))
        closest = start_arr + t_value * seg
    distance = float(np.linalg.norm(point_arr - closest))
    return Vector(*closest), t_value, distance


def segment_segment_distance_3d(p0, p1, q0, q1):
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
        t_value = float(np.clip(e / c if c > eps else 0.0, 0.0, 1.0))
    elif c <= eps:
        t_value = 0.0
        s = float(np.clip(-d / a if a > eps else 0.0, 0.0, 1.0))
    else:
        if denom <= eps:
            s = 0.0
        else:
            s = float(np.clip((b * e - c * d) / denom, 0.0, 1.0))
        t_value = (b * s + e) / c
        if t_value < 0.0:
            t_value = 0.0
            s = float(np.clip(-d / a, 0.0, 1.0))
        elif t_value > 1.0:
            t_value = 1.0
            s = float(np.clip((b - d) / a, 0.0, 1.0))

    closest_p = p0 + s * u
    closest_q = q0 + t_value * v
    return float(np.linalg.norm(closest_p - closest_q))


def _add_joint_point_unique_3d(sample, point):
    key = tuple(int(round(coord * 4.0)) for coord in (point.x, point.y, point.z))
    if not hasattr(sample, "_joint_point_keys_3d"):
        sample._joint_point_keys_3d = set()
    if key not in sample._joint_point_keys_3d:
        sample._joint_point_keys_3d.add(key)
        sample.joint_points.append(point)


def _attach_endpoint_to_segment_3d(fiber, endpoint_index, joint_point, segment_start, segment_end):
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


def apply_topology_3d(sample, abort_check=None):
    sample.topology_links = []
    sample.joint_points = []
    sample._joint_point_keys_3d = set()

    branch_probability = float(np.clip(sample.params.branchingProbability.get_value(), 0.0, 1.0))
    if branch_probability <= 0.0 or len(sample.fibers) < 2:
        return

    mean_width = float(sample.params.width.mean.get_value()) if hasattr(sample.params.width, 'mean') else 0.0
    capture_radius = max(2.5, 1.25 * float(sample.params.segmentLength.get_value()), 1.25 * mean_width)
    target_links = max(0, int(round(branch_probability * len(sample.fibers))))
    used_endpoints = set()
    linked_pairs = set()
    candidate_type = tuple[float, int, int, int, int, Vector, Vector, Vector]

    for _ in range(target_links):
        _raise_if_aborted(abort_check)
        best_global_candidate: candidate_type | None = None

        for fiber_idx, fiber in enumerate(sample.fibers):
            if fiber_idx % 4 == 0:
                _raise_if_aborted(abort_check)
            if len(fiber.points) < 2:
                continue
            for endpoint_index in (0, len(fiber.points) - 1):
                endpoint_key = (fiber_idx, 0 if endpoint_index == 0 else 1)
                if endpoint_key in used_endpoints:
                    continue

                endpoint = fiber.points[endpoint_index]
                for other_idx, other_fiber in enumerate(sample.fibers):
                    if other_idx % 4 == 0:
                        _raise_if_aborted(abort_check)
                    if other_idx == fiber_idx or len(other_fiber.points) < 2:
                        continue
                    pair_key = tuple(sorted((fiber_idx, other_idx)))
                    if pair_key in linked_pairs:
                        continue

                    for seg_idx in range(len(other_fiber.points) - 1):
                        if seg_idx % 32 == 0:
                            _raise_if_aborted(abort_check)
                        seg_start = other_fiber.points[seg_idx]
                        seg_end = other_fiber.points[seg_idx + 1]
                        joint_point, t_value, distance = closest_point_on_segment_3d(endpoint, seg_start, seg_end)
                        if distance > capture_radius:
                            continue

                        interior_bonus = 0.35 if 0.1 < t_value < 0.9 else 0.0
                        endpoint_bonus = 0.1 if endpoint_index in (0, len(fiber.points) - 1) else 0.0
                        score = distance - interior_bonus - endpoint_bonus
                        best_score = None if best_global_candidate is None else best_global_candidate[0]
                        if best_score is None or score < best_score:
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

        selected_candidate = cast(candidate_type, best_global_candidate)
        _, fiber_idx, endpoint_index, other_idx, seg_idx, joint_point, seg_start, seg_end = selected_candidate
        fiber = sample.fibers[fiber_idx]
        _attach_endpoint_to_segment_3d(fiber, endpoint_index, joint_point, seg_start, seg_end)
        fiber.has_joint = True
        sample.fibers[other_idx].has_joint = True
        _add_joint_point_unique_3d(sample, joint_point)
        sample.topology_links.append({
            'fiber_id': fiber_idx,
            'connected_fiber_id': other_idx,
            'segment_index': seg_idx,
            'x': joint_point.x,
            'y': joint_point.y,
            'z': joint_point.z,
        })
        used_endpoints.add((fiber_idx, 0 if endpoint_index == 0 else 1))
        linked_pairs.add(tuple(sorted((fiber_idx, other_idx))))


def count_graph_components(node_count, edge_pairs):
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


def build_geometric_contact_edges_3d(sample, contact_radius=None, abort_check=None):
    if contact_radius is None:
        contact_radius = max(
            1.0,
            0.5 * float(sample.params.centerlineMaskWidthPx.get_value()) + 0.75,
            0.2 * float(sample.params.segmentLength.get_value()),
        )
    contact_radius = max(float(contact_radius), 1e-6)

    edge_pairs = set()
    for left_idx, left_fiber in enumerate(sample.fibers):
        if left_idx % 4 == 0:
            _raise_if_aborted(abort_check)
        left_points = getattr(left_fiber, 'points', [])
        if len(left_points) < 2:
            continue
        for right_idx in range(left_idx + 1, len(sample.fibers)):
            _raise_if_aborted(abort_check)
            right_fiber = sample.fibers[right_idx]
            right_points = getattr(right_fiber, 'points', [])
            if len(right_points) < 2:
                continue
            found_contact = False
            for left_seg_idx in range(len(left_points) - 1):
                if left_seg_idx % 32 == 0:
                    _raise_if_aborted(abort_check)
                left_start = left_points[left_seg_idx]
                left_end = left_points[left_seg_idx + 1]
                for right_seg_idx in range(len(right_points) - 1):
                    if right_seg_idx % 32 == 0:
                        _raise_if_aborted(abort_check)
                    right_start = right_points[right_seg_idx]
                    right_end = right_points[right_seg_idx + 1]
                    distance = segment_segment_distance_3d(left_start, left_end, right_start, right_end)
                    if distance <= contact_radius:
                        edge_pairs.add((left_idx, right_idx))
                        found_contact = True
                        break
                if found_contact:
                    break
    return sorted(edge_pairs)


__all__ = [
    'apply_topology_3d',
    'build_geometric_contact_edges_3d',
    'closest_point_on_segment_3d',
    'count_graph_components',
    'segment_segment_distance_3d',
]
