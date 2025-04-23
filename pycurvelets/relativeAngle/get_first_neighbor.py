import numpy as np


def get_first_neighbor(mask, idx, visited, direction):
    """
    Get the index of the first contiguous 8-connected neighbor in the mask list.
    Equivalent to MATLAB's GetFirstNeighbor.

    Parameters:
        mask: np.ndarray of shape (N, 2) — list of [row, col] foreground pixels
        idx: int — current index in mask
        visited: np.ndarray of bool, shape (N,) — marks visited indices
        direction: int — 1 = backward, 2 = forward

    Returns:
        int — index of the neighbor in `mask` or same `idx` if not found
    """
    pt = mask[idx]  # (row, col)

    if direction == 1:
        npt = np.array(
            [
                [pt[0] + 1, pt[1]],  # S 140 407
                [pt[0] + 1, pt[1] - 1],  # SW 140 406
                [pt[0], pt[1] - 1],  # W 139 406
                [pt[0] - 1, pt[1] - 1],  # NW 138 406
                [pt[0] - 1, pt[1]],  # N 138 407
                [pt[0] - 1, pt[1] + 1],  # NE 138 408
                [pt[0], pt[1] + 1],  # E 139 408
                [pt[0] + 1, pt[1] + 1],  # SE 140 408
            ]
        )
    elif direction == 2:
        npt = np.array(
            [
                [pt[0] - 1, pt[1]],  # N 138 407
                [pt[0] - 1, pt[1] + 1],  # NE 138 408
                [pt[0], pt[1] + 1],  # E 139 408
                [pt[0] + 1, pt[1] + 1],  # SE 140 408
                [pt[0] + 1, pt[1]],  # S 140 407
                [pt[0] + 1, pt[1] - 1],  # SW 140 406
                [pt[0], pt[1] - 1],  # W 139 406
                [pt[0] - 1, pt[1] - 1],  # NW 138 406
            ]
        )
    else:
        raise ValueError("Direction must be 1 or 2")

    # Lookup table: convert each neighbor position into a matching index
    rows = mask[:, 0]
    cols = mask[:, 1]

    for neighbor in npt:
        matches = np.where((rows == neighbor[0]) & (cols == neighbor[1]))[0]
        if matches.size > 0:
            neighbor_idx = matches[0]
            if not visited[neighbor_idx]:
                return neighbor_idx

    return idx  # If nothing found, return the original index (like MATLAB)
