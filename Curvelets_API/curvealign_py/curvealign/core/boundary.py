"""
Boundary analysis for measuring fiber alignment relative to boundaries.

This module implements the boundary measurement algorithms that compute
distances and relative angles between curvelets/fibers and defined boundaries.
"""

from typing import Sequence, Optional
import numpy as np
from scipy.spatial.distance import cdist

from ..types import Curvelet, Boundary, BoundaryMetrics


def measure_boundary_alignment(
    curvelets: Sequence[Curvelet],
    boundary: Boundary,
    dist_thresh: float,
    min_dist: Optional[float] = None,
    exclude_inside_mask: bool = False,
) -> BoundaryMetrics:
    """
    Measure curvelet alignment relative to a boundary.
    
    This implements the boundary analysis from getBoundary.m and getTifBoundary.m,
    computing distances and relative angles between curvelets and boundary.
    
    Parameters
    ----------
    curvelets : Sequence[Curvelet]
        List of curvelets to analyze
    boundary : Boundary
        Boundary definition (polygon coordinates or binary mask)
    dist_thresh : float
        Distance threshold for inclusion in analysis
    min_dist : float, optional
        Minimum distance from boundary
    exclude_inside_mask : bool, default False
        Whether to exclude curvelets inside boundary mask
        
    Returns
    -------
    BoundaryMetrics
        Boundary analysis results including relative angles and distances
    """
    if not curvelets:
        return BoundaryMetrics(
            relative_angles=np.array([]),
            distances=np.array([]),
            inside_mask=np.array([]),
            alignment_stats={}
        )
    
    # Extract curvelet positions and angles
    centers = np.array([[c.center_row, c.center_col] for c in curvelets])
    angles = np.array([c.angle_deg for c in curvelets])
    
    if boundary.kind == "mask":
        return _measure_mask_boundary(centers, angles, boundary, dist_thresh, min_dist, exclude_inside_mask)
    elif boundary.kind in ["polygon", "polygons"]:
        return _measure_polygon_boundary(centers, angles, boundary, dist_thresh, min_dist)
    else:
        raise ValueError(f"Unsupported boundary kind: {boundary.kind}")


def _measure_mask_boundary(
    centers: np.ndarray,
    angles: np.ndarray,
    boundary: Boundary,
    dist_thresh: float,
    min_dist: Optional[float],
    exclude_inside_mask: bool,
) -> BoundaryMetrics:
    """
    Measure alignment relative to a binary mask boundary.
    
    This implements the algorithm from getTifBoundary.m for TIFF mask boundaries.
    """
    mask = boundary.data.astype(bool)
    height, width = mask.shape
    
    # Find boundary pixels (edge of mask)
    from scipy import ndimage
    boundary_pixels = mask ^ ndimage.binary_erosion(mask)
    boundary_coords = np.argwhere(boundary_pixels)  # [row, col] format
    
    if len(boundary_coords) == 0:
        # No boundary found
        n_curvelets = len(centers)
        return BoundaryMetrics(
            relative_angles=np.full(n_curvelets, np.nan),
            distances=np.full(n_curvelets, np.inf),
            inside_mask=np.zeros(n_curvelets, dtype=bool),
            alignment_stats={}
        )
    
    # Compute distances from each curvelet to boundary
    distances = cdist(centers, boundary_coords).min(axis=1)
    
    # Determine which curvelets are inside the mask
    inside_mask = np.zeros(len(centers), dtype=bool)
    for i, (row, col) in enumerate(centers):
        if 0 <= row < height and 0 <= col < width:
            inside_mask[i] = mask[int(row), int(col)]
    
    # Compute relative angles
    relative_angles = np.full(len(centers), np.nan)
    
    for i, center in enumerate(centers):
        # Find closest boundary point
        dists_to_boundary = np.sum((boundary_coords - center)**2, axis=1)
        closest_idx = np.argmin(dists_to_boundary)
        closest_boundary = boundary_coords[closest_idx]
        
        # Compute local boundary orientation
        boundary_angle = _compute_local_boundary_angle(closest_boundary, boundary_coords)
        
        # Compute relative angle
        curvelet_angle = angles[i]
        relative_angle = abs(curvelet_angle - boundary_angle)
        relative_angle = min(relative_angle, 180 - relative_angle)  # 0-90 degree range
        relative_angles[i] = relative_angle
    
    # Apply filtering criteria
    valid_mask = distances <= dist_thresh
    if min_dist is not None:
        valid_mask &= distances >= min_dist
    if exclude_inside_mask:
        valid_mask &= ~inside_mask
    
    # Compute alignment statistics
    valid_angles = relative_angles[valid_mask]
    alignment_stats = {}
    if len(valid_angles) > 0:
        alignment_stats = {
            'mean_relative_angle': float(np.nanmean(valid_angles)),
            'std_relative_angle': float(np.nanstd(valid_angles)),
            'alignment_index': float(np.cos(2 * np.deg2rad(np.nanmean(valid_angles)))),
            'n_valid_curvelets': int(np.sum(valid_mask)),
            'fraction_parallel': float(np.sum(valid_angles < 30) / len(valid_angles)),
            'fraction_perpendicular': float(np.sum(valid_angles > 60) / len(valid_angles)),
        }
    
    return BoundaryMetrics(
        relative_angles=relative_angles,
        distances=distances,
        inside_mask=inside_mask,
        alignment_stats=alignment_stats
    )


def _measure_polygon_boundary(
    centers: np.ndarray,
    angles: np.ndarray,
    boundary: Boundary,
    dist_thresh: float,
    min_dist: Optional[float],
) -> BoundaryMetrics:
    """
    Measure alignment relative to polygon boundary coordinates.
    
    This implements the algorithm from getBoundary.m for coordinate-based boundaries.
    """
    if boundary.kind == "polygon":
        polygons = [boundary.data]
    else:  # "polygons"
        polygons = boundary.data
    
    n_curvelets = len(centers)
    min_distances = np.full(n_curvelets, np.inf)
    relative_angles = np.full(n_curvelets, np.nan)
    inside_mask = np.zeros(n_curvelets, dtype=bool)
    
    for polygon in polygons:
        # Convert polygon to array of coordinates
        if hasattr(polygon, 'exterior'):
            # Shapely polygon
            coords = np.array(polygon.exterior.coords)
        else:
            # Assume it's already a coordinate array
            coords = np.array(polygon)
        
        # Compute distances and angles for this polygon
        poly_distances, poly_angles = _compute_polygon_distances_angles(centers, angles, coords)
        
        # Update minimum distances and corresponding angles
        closer_mask = poly_distances < min_distances
        min_distances[closer_mask] = poly_distances[closer_mask]
        relative_angles[closer_mask] = poly_angles[closer_mask]
        
        # Check if points are inside polygon (simplified - assumes convex)
        # TODO: Implement proper point-in-polygon test
    
    # Apply filtering criteria
    valid_mask = min_distances <= dist_thresh
    if min_dist is not None:
        valid_mask &= min_distances >= min_dist
    
    # Compute alignment statistics
    valid_angles = relative_angles[valid_mask]
    alignment_stats = {}
    if len(valid_angles) > 0:
        alignment_stats = {
            'mean_relative_angle': float(np.nanmean(valid_angles)),
            'std_relative_angle': float(np.nanstd(valid_angles)),
            'alignment_index': float(np.cos(2 * np.deg2rad(np.nanmean(valid_angles)))),
            'n_valid_curvelets': int(np.sum(valid_mask)),
            'fraction_parallel': float(np.sum(valid_angles < 30) / len(valid_angles)),
            'fraction_perpendicular': float(np.sum(valid_angles > 60) / len(valid_angles)),
        }
    
    return BoundaryMetrics(
        relative_angles=relative_angles,
        distances=min_distances,
        inside_mask=inside_mask,
        alignment_stats=alignment_stats
    )


def _compute_local_boundary_angle(point: np.ndarray, boundary_coords: np.ndarray, window: int = 5) -> float:
    """
    Compute local boundary orientation at a given point.
    
    Parameters
    ----------
    point : np.ndarray
        Boundary point coordinates [row, col]
    boundary_coords : np.ndarray
        All boundary coordinates
    window : int, default 5
        Window size for local orientation estimation
        
    Returns
    -------
    float
        Local boundary angle in degrees
    """
    # Find nearby boundary points
    distances = np.sum((boundary_coords - point)**2, axis=1)
    nearby_indices = np.argsort(distances)[:window]
    nearby_points = boundary_coords[nearby_indices]
    
    if len(nearby_points) < 2:
        return 0.0
    
    # Fit line to nearby points using PCA
    centered = nearby_points - np.mean(nearby_points, axis=0)
    if np.all(centered == 0):
        return 0.0
        
    # Compute covariance matrix
    cov = np.cov(centered.T)
    
    # Get principal component (eigenvector with largest eigenvalue)
    eigenvals, eigenvecs = np.linalg.eigh(cov)
    principal_component = eigenvecs[:, -1]
    
    # Convert to angle in degrees
    angle = np.arctan2(principal_component[1], principal_component[0]) * 180 / np.pi
    return angle % 180  # 0-180 degree range


def _compute_polygon_distances_angles(
    centers: np.ndarray, 
    angles: np.ndarray, 
    polygon_coords: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
    """
    Compute distances and relative angles from curvelets to polygon boundary.
    
    Parameters
    ----------
    centers : np.ndarray
        Curvelet center coordinates
    angles : np.ndarray
        Curvelet angles in degrees
    polygon_coords : np.ndarray
        Polygon boundary coordinates
        
    Returns
    -------
    Tuple[np.ndarray, np.ndarray]
        Distances and relative angles for each curvelet
    """
    n_curvelets = len(centers)
    distances = np.zeros(n_curvelets)
    relative_angles = np.zeros(n_curvelets)
    
    for i, (center, angle) in enumerate(zip(centers, angles)):
        # Find closest point on polygon boundary
        dists_to_vertices = np.sum((polygon_coords - center)**2, axis=1)
        closest_vertex_idx = np.argmin(dists_to_vertices)
        
        # TODO: Implement proper distance to line segment
        # For now, use distance to closest vertex
        distances[i] = np.sqrt(dists_to_vertices[closest_vertex_idx])
        
        # Compute local boundary angle
        boundary_angle = _compute_local_boundary_angle(
            polygon_coords[closest_vertex_idx], 
            polygon_coords
        )
        
        # Compute relative angle
        relative_angle = abs(angle - boundary_angle)
        relative_angle = min(relative_angle, 180 - relative_angle)
        relative_angles[i] = relative_angle
    
    return distances, relative_angles
