from __future__ import annotations

import numpy as np


def smooth_mask(mask: np.ndarray, sigma: float = 5.0) -> np.ndarray:
    """Gaussian-smooth a binary mask and rescale to [0, 1].

    sigma=5 gives ~10-px FWHM, measuring agreement at fiber scale rather than
    pixel scale.  Adapted from tme-quant/tests/test_fire_2d_angle.py.
    """
    from skimage import exposure, filters

    mask = mask.astype(np.float32)
    mask = exposure.rescale_intensity(mask, out_range=(0.0, 1.0))
    density = filters.gaussian(mask, sigma=sigma, preserve_range=False)
    return exposure.rescale_intensity(density, out_range=(0.0, 1.0)).astype(np.float32)


def soft_iou(mask_1: np.ndarray, mask_2: np.ndarray, beta: float = 1e-3) -> float:
    """Soft IoU on two float masks already smoothed to [0, 1].

    Formula: (m1·m2).sum() / (m1²+m2²-m1·m2).sum()
    beta prevents 0/0 when both masks are empty.
    """
    intersection = mask_1 * mask_2
    union = mask_1**2 + mask_2**2 - mask_1 * mask_2
    return float((intersection.sum() + beta) / (union.sum() + beta))


def rasterize_fiber_result(X, F, image_shape: tuple) -> np.ndarray:
    """Rasterize fire_2d_angle fiber output to a 1-px uint8 skeleton image.

    Uses Bresenham line drawing between consecutive fiber vertices, then
    morphological skeletonize to guarantee 1-px thickness.
    X: vertex array [row, col, ...]; F: list of fibers (dicts with 'v' key,
    or plain vertex-index lists).
    """
    from skimage.draw import line as draw_line

    H, W = image_shape[:2]
    canvas = np.zeros((H, W), dtype=np.uint8)
    X_arr = np.asarray(X)
    for fiber in F:
        v_list = fiber["v"] if isinstance(fiber, dict) else list(fiber)
        for seg in range(len(v_list) - 1):
            v0, v1 = v_list[seg], v_list[seg + 1]
            if v0 >= len(X_arr) or v1 >= len(X_arr):
                continue
            r0 = int(np.clip(round(float(X_arr[v0, 0])), 0, H - 1))
            c0 = int(np.clip(round(float(X_arr[v0, 1])), 0, W - 1))
            r1 = int(np.clip(round(float(X_arr[v1, 0])), 0, H - 1))
            c1 = int(np.clip(round(float(X_arr[v1, 1])), 0, W - 1))
            rr, cc = draw_line(r0, c0, r1, c1)
            canvas[rr, cc] = 1
    return canvas  # draw_line already produces 1-px lines; skeletonize (_distance_pybind) not needed
