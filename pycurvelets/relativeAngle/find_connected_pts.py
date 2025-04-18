import numpy as np
from get_first_neighbor import get_first_neighbor


def find_connected_pts(boundary_coords, idx, num):
    """
    Find list of `num` connected points around the given index in `boundary_coords`.
    Equivalent to MATLAB's FindConnectedPts.

    Parameters:
        boundary_coords: np.ndarray of shape (N, 2) — (row, col) pairs of outline
        idx: int — index into boundary_coords
        num: int — number of connected points to return (must be odd)

    Returns:
        con_pts: np.ndarray of shape (num, 2) — connected points around center
    """
    con_pts = np.full((num, 2), np.nan)
    hnum = (num - 1) // 2
    mid = hnum
    con_pts[mid] = boundary_coords[idx]

    visited = np.zeros(len(boundary_coords), dtype=bool)
    sidx = idx

    # Fill before center
    for i in range(mid - 1, -1, -1):
        visited[idx] = True
        idx = get_first_neighbor(boundary_coords, idx, visited, direction=1)
        if idx is None:
            return np.full((num, 2), np.nan)
        con_pts[i] = boundary_coords[idx]

    # Fill after center
    idx = sidx
    for i in range(mid + 1, num):
        visited[idx] = True
        idx = get_first_neighbor(boundary_coords, idx, visited, direction=2)
        if idx is None:
            return np.full((num, 2), np.nan)
        con_pts[i] = boundary_coords[idx]

    return con_pts
