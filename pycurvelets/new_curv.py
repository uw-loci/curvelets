from curvelops import FDCT2D, curveshow, fdct2d_wrapper
import math
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import os


img = plt.imread(
    "/Users/dongwoolee/Documents/Github/curvelets/doc/testImages/CellAnalysis_testImages/3dImage/s5part1__cmle000.tif",
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
    nbscales = math.ceil(math.log2(min(M, N)) - 3)
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
        len(c) - s_scale
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
    max_val = bins[threshold_idx + 1]

    # Threshold coefficients
    for dd in range(len(c[s])):
        ct[s][dd] = c[s][dd] * (np.abs(c[s][dd]) >= max_val)

    # Get locations of curvelet centers and find angles
    m, n = img.shape
    nbangles_coarse = 16

    sx, sy, fx, fy, nx, ny = fdct2d_wrapper.fdct2d_param_wrap(
        m, n, nbscales, nbangles_coarse, 0
    )

    # Extract X_rows and Y_cols for the scale we're interested in
    X_rows = np.array(sx[s]) * M  # Scale to match MATLAB values
    Y_cols = np.array(sy[s]) * N
    # X_rows = sx[s]
    # Y_cols = sy[s]

    long = len(c[s])
    angs = [np.array([]) for _ in range(long)]
    row = [np.array([]) for _ in range(long)]
    col = [np.array([]) for _ in range(long)]
    inc = 360 / len(c[s])
    start_ang = 225
    print(long)
    print(row)
    print(col)
    print(inc)

    # print(len(c[s]))
    # print(len(c[s][0][0][0]))

    # Replace your angle calculation with:
    for w in range(long):
        # Find non-zero coefficients
        ct_w = ct[s][w]
        # print(ct_w)
        test = np.nonzero(ct_w)

        if len(test[0]) > 0:
            angle = np.zeros(len(test[0]))
            for aa in range(len(test[0])):
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

            # Get coordinates
            try:
                # Check if X_rows is a list (which seems to be the case)
                # print(isinstance(X_rows, list))
                print(type(X_rows))
                if ct_w.any():
                    # Handle the case where X_rows is a list of arrays
                    # Get the correct X_rows and Y_cols for this wedge
                    # print(f"Shape of X_rows: {np.array(X_rows).shape}")
                    # print(f"Shape of Y_cols: {np.array(Y_cols).shape}")
                    x_rows_wedge = X_rows[w]
                    y_cols_wedge = Y_cols[w]
                    # print(x_rows_wedge)
                    # print(y_cols_wedge)

                    # Get the indices from the test
                    i_coords, j_coords = test

                    row_indices = np.round(X_rows[w] + i_coords).astype(int)
                    col_indices = np.round(Y_cols[w] + j_coords).astype(int)

                    row[w] = row_indices
                    col[w] = col_indices
                else:
                    angs[w] = np.array([0])
                    row[w] = np.array([0])
                    col[w] = np.array([0])
            except Exception as e:
                print(f"Error processing wedge {w}: {e}")
                # Fallback to average values if there's an error
                row[w] = np.array([np.round(np.mean(img.shape[0]))]).astype(int)
                col[w] = np.array([np.round(np.mean(img.shape[1]))]).astype(int)

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
    print(curves2)

    # print(curves2)

    # Group all curvelets that are closer than 'radius'
    # Replace your grouping logic with:
    groups = [[] for _ in range(len(curves))]
    for xx in range(len(curves)):
        if np.all(curves[xx, :]):  # Check if the curvelet is valid
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
    comb_nh = [groups[i] for i in range(len(groups)) if not_empty[i]]
    n_hoods = [curves[g, :] for g in comb_nh]  # Extract grouped curvelets

    # Helper function for fixing angles
    def fix_angle(angles, inc):
        """
        Match MATLAB's fixAngle function to properly adjust angles
        """
        # Convert to single angle (median) if it's an array
        if isinstance(angles, np.ndarray) and len(angles) > 1:
            angle = np.median(angles)
        else:
            angle = angles

        # Adjust angles to be within [0, 180)
        return angle % 180

    # Process each group
    angles = [np.median(fix_angle(hood[:, 2], inc)) for hood in n_hoods]
    centers = [
        np.array([round(np.median(hood[:, 0])), round(np.median(hood[:, 1]))])
        for hood in n_hoods
    ]

    # Create output structures with a single angle per center
    objects = []
    for i in range(len(centers)):
        objects.append({"center": centers[i], "angle": angles[i]})

    # Rotate angles to be within [0, 180) degrees
    def group6(objects):
        for i in range(len(objects)):
            angle = objects[i]["angle"]
            if angle > 180:
                objects[i]["angle"] = angle - 180
        return objects

    objects = group6(objects)

    # Remove curvelets too close to the edge
    all_center_points = np.vstack([obj["center"] for obj in objects])
    cen_row = all_center_points[:, 0]
    cen_col = all_center_points[:, 1]
    im_rows, im_cols = img.shape
    edge_buf = math.ceil(min(im_rows, im_cols) / 100)

    in_idx = np.where(
        (cen_row < im_rows - edge_buf)
        & (cen_col < im_cols - edge_buf)
        & (cen_row > edge_buf)
        & (cen_col > edge_buf)
    )[0]

    in_curves = [objects[i] for i in in_idx]

    pd.set_option("display.max_rows", None)  # Show all rows
    pd.set_option("display.max_columns", None)  # Show all columns
    pd.set_option("display.width", None)  # Auto-detect the display width
    pd.set_option("display.max_colwidth", None)  # Show full content of each cell
    # print("INCURVES START: ", in_curves)
    # print("COEFFICIENT MAT: ", ct)
    print("ANGLE INC: ", inc)

    df_in_curves = pd.DataFrame(in_curves)
    # Export DataFrame to a CSV file
    df_in_curves.to_csv("in_curves.csv", index=False)
    # print(df_in_curves)
    return in_curves, ct, inc


new_curv(img, {"keep": 0.01, "scale": 2, "radius": 3})
