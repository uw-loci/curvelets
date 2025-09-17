"""
Feature computation for curvelets/fibers.

This module implements the feature extraction algorithms that compute
density, alignment, and other fiber characteristics from curvelet data.
"""

from typing import List, Optional, Sequence
import numpy as np
from scipy.spatial import cKDTree

from ..types import Curvelet, FeatureTable, FeatureOptions


def compute_features(
    curvelets: Sequence[Curvelet],
    options: Optional[FeatureOptions] = None,
) -> FeatureTable:
    """
    Compute fiber features from curvelets.
    
    This implements the feature computation from getCT.m, including:
    - Nearest neighbor density features
    - Local alignment features  
    - Box-based density and alignment
    
    Parameters
    ----------
    curvelets : Sequence[Curvelet]
        List of extracted curvelets
    options : FeatureOptions, optional
        Feature computation parameters
        
    Returns
    -------
    FeatureTable
        Dictionary of computed features for each curvelet
    """
    if options is None:
        options = FeatureOptions()
    
    if not curvelets:
        return {}
    
    n_curvelets = len(curvelets)
    
    # Extract positions and angles
    centers = np.array([[c.center_row, c.center_col] for c in curvelets])
    angles = np.array([c.angle_deg for c in curvelets])
    weights = np.array([c.weight or 1.0 for c in curvelets])
    
    # Build spatial index for efficient nearest neighbor queries
    tree = cKDTree(centers)
    
    # Compute nearest neighbor features
    mnf = options.minimum_nearest_fibers
    neighbor_counts = [2**i * mnf for i in range(4)]  # [mnf, 2*mnf, 4*mnf, 8*mnf]
    
    density_features = np.zeros((n_curvelets, len(neighbor_counts)))
    alignment_features = np.zeros((n_curvelets, len(neighbor_counts)))
    
    for i, n_neighbors in enumerate(neighbor_counts):
        # Find k+1 nearest neighbors (including self)
        distances, indices = tree.query(centers, k=min(n_neighbors + 1, n_curvelets))
        
        for j in range(n_curvelets):
            if len(distances.shape) == 1:
                # Single curvelet case
                neighbor_dists = distances[1:]  # Exclude self
                neighbor_indices = indices[1:]
            else:
                neighbor_dists = distances[j, 1:]  # Exclude self
                neighbor_indices = indices[j, 1:]
            
            # Density: mean distance to neighbors
            if len(neighbor_dists) > 0:
                density_features[j, i] = np.mean(neighbor_dists)
            
            # Alignment: circular mean of neighbor angles
            if len(neighbor_indices) > 0:
                neighbor_angles = angles[neighbor_indices]
                # Convert to radians and compute circular mean
                angle_rad = neighbor_angles * 2 * np.pi / 180  # Double angle for fiber symmetry
                alignment_features[j, i] = np.abs(np.mean(np.exp(1j * angle_rad)))
    
    # Compute box-based features
    mbs = options.minimum_box_size
    box_sizes = [2**i * mbs for i in range(3)]  # [mbs, 2*mbs, 4*mbs]
    
    box_density = np.zeros((n_curvelets, len(box_sizes)))
    box_alignment = np.zeros((n_curvelets, len(box_sizes)))
    
    for i, box_size in enumerate(box_sizes):
        half_size = box_size // 2
        
        for j, center in enumerate(centers):
            # Define box around current curvelet
            row_min = max(0, center[0] - half_size)
            row_max = center[0] + half_size
            col_min = max(0, center[1] - half_size)
            col_max = center[1] + half_size
            
            # Find curvelets within box
            in_box = (
                (centers[:, 0] >= row_min) & (centers[:, 0] <= row_max) &
                (centers[:, 1] >= col_min) & (centers[:, 1] <= col_max)
            )
            
            box_curvelets = np.where(in_box)[0]
            
            # Box density: number of curvelets per unit area
            box_area = (row_max - row_min) * (col_max - col_min)
            box_density[j, i] = len(box_curvelets) / box_area
            
            # Box alignment: alignment of curvelets in box
            if len(box_curvelets) > 1:
                box_angles = angles[box_curvelets]
                angle_rad = box_angles * 2 * np.pi / 180
                box_alignment[j, i] = np.abs(np.mean(np.exp(1j * angle_rad)))
    
    # Compile feature table
    features = {
        'center_row': centers[:, 0],
        'center_col': centers[:, 1],
        'angle_deg': angles,
        'weight': weights,
    }
    
    # Add nearest neighbor features
    for i, n_neighbors in enumerate(neighbor_counts):
        features[f'density_nn_{n_neighbors}'] = density_features[:, i]
        features[f'alignment_nn_{n_neighbors}'] = alignment_features[:, i]
    
    # Add box features  
    for i, box_size in enumerate(box_sizes):
        features[f'density_box_{box_size}'] = box_density[:, i]
        features[f'alignment_box_{box_size}'] = box_alignment[:, i]
    
    return features


def compute_density_features(centers: np.ndarray, neighbor_counts: List[int]) -> np.ndarray:
    """
    Compute nearest neighbor density features.
    
    Parameters
    ----------
    centers : np.ndarray
        Curvelet center coordinates (N x 2)
    neighbor_counts : List[int]
        Numbers of neighbors to consider
        
    Returns
    -------
    np.ndarray
        Density features (N x len(neighbor_counts))
    """
    tree = cKDTree(centers)
    n_curvelets = len(centers)
    density_features = np.zeros((n_curvelets, len(neighbor_counts)))
    
    for i, n_neighbors in enumerate(neighbor_counts):
        distances, _ = tree.query(centers, k=min(n_neighbors + 1, n_curvelets))
        
        for j in range(n_curvelets):
            if len(distances.shape) == 1:
                neighbor_dists = distances[1:]
            else:
                neighbor_dists = distances[j, 1:]
            
            if len(neighbor_dists) > 0:
                density_features[j, i] = np.mean(neighbor_dists)
    
    return density_features


def compute_alignment_features(
    centers: np.ndarray, 
    angles: np.ndarray, 
    neighbor_counts: List[int]
) -> np.ndarray:
    """
    Compute nearest neighbor alignment features.
    
    Parameters
    ----------
    centers : np.ndarray
        Curvelet center coordinates (N x 2)
    angles : np.ndarray
        Curvelet angles in degrees (N,)
    neighbor_counts : List[int]
        Numbers of neighbors to consider
        
    Returns
    -------
    np.ndarray
        Alignment features (N x len(neighbor_counts))
    """
    tree = cKDTree(centers)
    n_curvelets = len(centers)
    alignment_features = np.zeros((n_curvelets, len(neighbor_counts)))
    
    for i, n_neighbors in enumerate(neighbor_counts):
        _, indices = tree.query(centers, k=min(n_neighbors + 1, n_curvelets))
        
        for j in range(n_curvelets):
            if len(indices.shape) == 1:
                neighbor_indices = indices[1:]
            else:
                neighbor_indices = indices[j, 1:]
            
            if len(neighbor_indices) > 0:
                neighbor_angles = angles[neighbor_indices]
                # Use circular statistics for fiber angles (0-180 deg symmetry)
                angle_rad = neighbor_angles * 2 * np.pi / 180
                alignment_features[j, i] = np.abs(np.mean(np.exp(1j * angle_rad)))
    
    return alignment_features
