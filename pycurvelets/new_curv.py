from curvelops import FDCT2D, curveshow, fdct2d_wrapper
import math
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import os

# img_path = "./testImages/syn1.tif"
img = plt.imread(
    "/Users/dongwoolee/Documents/Github/curvelets/doc/testImages/CellAnalysis_testImages/3dImage/s5part1__cmle000.tif",
    # img_path,
    format="TIF",
)


def new_curv(img, curve_cp):
    """
    Python implementation of newCurv.m

    This function applies the Fast Discrete Curvelet Transform to an image, then extracts
    the curvelet coefficients at a given scale with magnitude above a given threshold.
    The orientation (angle, in degrees) and center point of each curvelet is then stored.

    Parameters:
    -----------
    img : ndarray
        Input image
    curve_cp : dict
        Control parameters for curvelets application with fields:
        - keep: fraction of the curvelets to be kept
        - scale: scale to be analyzed
        - radius: radius to group the adjacent curvelets

    Returns:
    --------
    in_curves : list of dict
        List of dictionaries containing the orientation angle and center point of each curvelet
    ct : list of lists
        A nested list containing the thresholded curvelet coefficients
    inc : float
        Angle increment used
    """
    keep = curve_cp["keep"]
    s_scale = curve_cp["scale"]
    radius = curve_cp["radius"]

    # Apply the FDCT to the image
    # Note: Python implementation uses different parameter ordering from MATLAB
    # is_real=0 in MATLAB corresponds to ac=1 in Python (complex-valued transform)
    M, N = img.shape
    is_real = 0  # 0 means complex
    ac = 0  # 1 is curvelets, 0 is wavelets
    nbscales = math.floor(math.log2(min(M, N)) - 3)
    nbangles_coarse = 16  # default
    c = fdct2d_wrapper.fdct2d_forward_wrap(nbscales, nbangles_coarse, ac, img)

    # Create an empty structure of the same dimensions
    ct = []
    for cc in range(len(c)):
        ct.append([])
        for dd in range(len(c[cc])):
            ct[cc].append(np.zeros_like(c[cc][dd]))

    # Select the scale at which the coefficients will be used
    # print(len(c))
    s = (
        len(c) - s_scale - 1
    )  # s_scale: 1: second finest scale, 2: third finest scale, and so on

    # print(s)

    # Take absolute value of coefficients
    for ee in range(len(c[s])):
        c[s][ee] = np.abs(c[s][ee])

    # Find the maximum coefficient value, then discard the lowest (1-keep)*100%
    abs_max = max(np.max(arr) for arr in c[s])
    num_bins = 100  # Use a fixed number of bins
    bins = np.linspace(
        0, abs_max, num_bins + 1
    )  # +1 because np.linspace includes both endpoints

    # Collect all values from c[s] into a single array for easier histogram calculation
    all_values = np.concatenate([arr.flatten() for arr in c[s]])
    bins = np.linspace(
        0, abs_max, 101
    )  # 101 bins to match MATLAB's 0:.01*absMax:absMax
    hist, _ = np.histogram(all_values, bins=bins)
    cum_sum = np.cumsum(hist)
    threshold_idx = np.where(cum_sum > (1 - keep) * cum_sum[-1])[0][0]
    max_val = bins[threshold_idx]

    # Threshold coefficients
    for dd in range(len(c[s])):
        ct[s][dd] = c[s][dd] * (np.abs(c[s][dd]) >= max_val)

    # Get locations of curvelet centers and find angles
    m, n = img.shape
    nbangles_coarse = 16

    long = len(c[s]) // 2
    angs = [np.array([]) for _ in range(long)]
    row = [np.array([]) for _ in range(long)]
    col = [np.array([]) for _ in range(long)]
    inc = 360 / len(c[s])
    start_ang = 225

    SX, SY, FX, FY, NX, NY = fdct2d_wrapper.fdct2d_param_wrap(
        m, n, nbscales, nbangles_coarse, 0
    )

    for scl in range(nbscales):
        for wedge_scl in range(len(FX[scl])):
            nx = NX[scl][wedge_scl]
            ny = NY[scl][wedge_scl]
            cx = math.ceil((nx + 1) / 2)
            cy = math.ceil((ny + 1) / 2)

            sx = SX[scl][wedge_scl]
            sy = SY[scl][wedge_scl]
            IX, IY = np.meshgrid(
                np.arange(1, nx + 1), np.arange(1, ny + 1), indexing="ij"
            )
            SX[scl][wedge_scl] = 1 + M * (sx * (IX - cx) + 0.5)
            SY[scl][wedge_scl] = 1 + N * (sy * (IY - cy) + 0.5)

    for w in range(long):
        # Find non-zero coefficients
        test = np.flatnonzero(ct[s][w])
        if len(test) > 0:
            test_idx_y, test_idx_x = np.unravel_index(test, ct[s][w].shape)
            angle = np.zeros(len(test))
            for bb in range(2):
                # print(len(test))
                for aa in range(len(test)):
                    # Convert angular wedge to measured angle in degrees
                    temp_angle = start_ang - (inc * w)
                    shift_temp = start_ang - (inc * (w + 1))
                    angle[aa] = np.mean([temp_angle, shift_temp])

            # Adjust angles
            ind = angle < 0
            angle[ind] += 360

            IND = angle > 225
            angle[IND] -= 180

            idx = angle < 45
            angle[idx] += 180

            angs[w] = angle

            row[w] = np.zeros(len(test), dtype=int)
            col[w] = np.zeros(len(test), dtype=int)
            for i in range(len(test)):
                row[w][i] = np.round(SX[s][w][test_idx_x[i], test_idx_y[i]])
                col[w][i] = np.round(SY[s][w][test_idx_x[i], test_idx_y[i]])

            angle = []
        else:
            angs[w] = np.array([0])
            row[w] = np.array([0])
            col[w] = np.array([0])

    # Find non-empty arrays
    c_test = [len(c) > 0 and not (len(c) == 1 and c[0] == 0) for c in col]
    bb = np.where(c_test)[0]
    print(bb)
    print(c_test)

    if len(bb) == 0:  # No curvelets found
        print("we screwed")
        return [], ct, inc

    # Concatenate non-empty arrays
    col_flat = np.concatenate([col[i] for i in bb])
    row_flat = np.concatenate([row[i] for i in bb])
    angs_flat = np.concatenate([angs[i] for i in bb])

    curves = np.column_stack((row_flat, col_flat, angs_flat))
    curves2 = curves.copy()

    # Group all curvelets that are closer than 'radius'
    # Replace your grouping logic with:
    groups = [[] for _ in range(len(curves2))]
    for xx in range(len(curves2)):
        if np.all(curves2[xx, :]):  # Check if the curvelet is valid
            # Calculate distance conditions like in MATLAB
            c_low = curves2[:, 1] > np.ceil(curves2[xx, 1] - radius)
            c_hi = curves2[:, 1] < np.floor(curves2[xx, 1] + radius)
            c_rad = c_low & c_hi

            r_hi = curves2[:, 0] < np.ceil(curves2[xx, 0] + radius)
            r_low = curves2[:, 0] > np.floor(curves2[xx, 0] - radius)
            r_rad = r_hi & r_low

            in_nh = c_rad & r_rad
            groups[xx] = np.where(in_nh)[0]  # Store indices of grouped curvelets

            # Zero out the processed curves like in MATLAB
            curves2[in_nh, :] = 0  # Mark grouped curvelets as processed

    # Keep only non-empty groups
    not_empty = [len(g) > 0 for g in groups]
    comb_nh = [g for g in groups if len(g) > 0]
    n_hoods = [curves[g] for g in comb_nh]

    # Helper function for fixing angles
    def fix_angle(angles, inc):
        """
        Match MATLAB's fixAngle function to properly adjust angles
        """
        x = np.array(angles, dtype=float)
        bins = np.arange(np.min(x), np.max(x) + inc, inc)

        temp = x.copy()
        angs = x.copy()
        stdev = []

        for aa in range(len(bins) - 1):
            idx = temp >= bins[-(aa + 1)]
            temp_adj = temp.copy()
            temp_adj[idx] -= 180
            stdev.append(np.std(temp_adj))

        stdev = [np.std(x)] + stdev
        stdev = np.array(stdev)
        I = np.argmin(stdev)
        C = stdev[I]

        if C < np.std(angs) and I < len(bins) - 1:
            idx = angs >= bins[-(I + 1)]
            angs[idx] -= 180

            if I > 0.5 * len(bins):
                angs += 180

        if np.any(angs < 0):
            angs += 180

        return np.mean(angs)

    angles = [fix_angle(nh[:, 2], inc) for nh in n_hoods]
    centers = [
        np.array([round(np.median(nh[:, 0])), round(np.median(nh[:, 1]))])
        for nh in n_hoods
    ]

    objects = [
        {"center": center, "angle": angle} for center, angle in zip(centers, angles)
    ]

    def group6(objects):
        for i in range(len(objects)):
            angle = objects[i]["angle"]
            objects[i]["angle"] = (180 + angle) % 180
        return objects

    objects = group6(objects)

    # Remove curvelets too close to the edge
    all_center_points = np.vstack([obj["center"] for obj in objects])
    cen_row = all_center_points[:, 0]  # First column is row in the center points
    cen_col = all_center_points[:, 1]  # Second column is col in the center points
    im_rows, im_cols = img.shape
    edge_buf = math.ceil(min(im_rows, im_cols) / 100)

    # Find indices of curvelets that are not too close to the edge
    in_idx = np.where(
        (cen_row < im_rows - edge_buf)
        & (cen_col < im_cols - edge_buf)
        & (cen_row > edge_buf)
        & (cen_col > edge_buf)
    )[0]

    in_curves = [objects[i] for i in in_idx]

    df_in_curves = pd.DataFrame(in_curves)
    # Export DataFrame to a CSV file
    df_in_curves.to_csv("./in_curves.csv", index=False)

    print(in_curves)
    print(inc)
    return in_curves, ct, inc


new_curv(img, {"keep": 0.01, "scale": 1, "radius": 3})
