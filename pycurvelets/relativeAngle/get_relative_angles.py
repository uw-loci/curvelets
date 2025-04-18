import numpy as np
import cv2
import matplotlib.pyplot as plt
from skimage.draw import polygon, polygon2mask
from skimage.measure import regionprops, label
import csv
import os

from find_outline_slope import find_outline_slope


def circ_r(alpha, w=None, d=0, axis=0):
    """
    Computes mean resultant vector length for circular data.

    Parameters:
    - alpha : array-like
        Sample of angles in radians.
    - w : array-like, optional
        Weights (number of incidences). Default is uniform weights.
    - d : float, optional
        Spacing of bin centers for binned data, in radians. Used for bias correction.
    - axis : int, optional
        Axis along which to compute the result. Default is 0.

    Returns:
    - r : float or array
        Mean resultant length.
    """
    alpha = np.asarray(alpha)

    if w is None:
        w = np.ones_like(alpha)
    else:
        w = np.asarray(w)
        if w.shape != alpha.shape:
            raise ValueError("Input dimensions do not match")

    # Compute weighted sum of unit vectors
    r = np.sum(w * np.exp(1j * alpha), axis=axis)

    # Mean resultant vector length
    r = np.abs(r) / np.sum(w, axis=axis)

    # Bias correction for binned data (Zar, p. 601, eq. 26.16)
    if d != 0:
        c = d / (2 * np.sin(d / 2))
        r *= c

    return r


def get_relative_angles(ROI, obj, angle_option=0, fig_flag=False):
    coords = np.array(ROI["coords"])  # [[y1, x1], [y2, x2], ...]
    image_height = ROI["imageHeight"]
    image_width = ROI["imageWidth"]
    index2object = ROI["index2object"]
    object_center = obj["center"][::-1]  # switch to [x, y]
    object_angle = obj["angle"]

    # Step 1: Create ROI mask and compute properties
    # coords_xy = np.flip(coords, axis=1)  # now shape: (N, 2), with (x, y)

    # Step 2: Use polygon2mask, which behaves more like MATLAB's roipoly
    mask = polygon2mask((image_height, image_width), coords)  # output is bool array

    # Step 3: Label and compute properties (regionprops values are slightly off though)
    labeled = label(mask.astype(np.uint8))
    props = regionprops(labeled)

    if len(props) != 1:
        raise ValueError("Coordinates must define a single region")

    prop = props[0]
    boundary_center = np.array(prop.centroid)[::-1]  # to [x, y]
    roi_angle = -90 + np.degrees(prop.orientation)
    if roi_angle < 0:
        roi_angle = 180 + roi_angle

    ROImeasurements = {
        "center": boundary_center,
        "orientation": roi_angle,
        "area": prop.area,
        "boundary": coords,
    }

    relative_angles = {
        "angle2boundaryEdge": None,
        "angle2boundaryCenter": None,
        "angle2centersLine": None,
    }

    if angle_option in [1, 0]:
        boundary_pt = coords[index2object]
        boundary_angle = find_outline_slope(coords, index2object)
        if (
            any(boundary_pt == 1)
            or boundary_pt[0] == image_height
            or boundary_pt[1] == image_width
        ):
            temp_ang = 0
        else:
            if boundary_angle is None:
                temp_ang = None
            else:
                temp_ang = circ_r(np.radians([object_angle, boundary_angle]))
                temp_ang = np.degrees(np.arcsin(temp_ang))
        relative_angles["angle2boundaryEdge"] = temp_ang

    if angle_option in [2, 0]:
        temp_ang = abs(object_angle - roi_angle)
        if temp_ang > 90:
            temp_ang = 180 - temp_ang
        relative_angles["angle2boundaryCenter"] = temp_ang

    if angle_option in [3, 0]:
        dx = object_center[1] - boundary_center[1]
        dy = object_center[0] - boundary_center[0]
        centers_line_angle = 90 - np.degrees(np.arctan2(dy, dx))
        if centers_line_angle < 0:
            centers_line_angle = abs(centers_line_angle)
        else:
            centers_line_angle = 180 - centers_line_angle
        relative_angles["angle2centersLine"] = abs(centers_line_angle - object_angle)
        if relative_angles["angle2centersLine"] > 90:
            relative_angles["angle2centersLine"] = (
                180 - relative_angles["angle2centersLine"]
            )

    if fig_flag and angle_option == 0:
        fig, ax = plt.subplots()
        ax.imshow(mask, cmap="gray")
        ax.plot(coords[:, 1], coords[:, 0], "c-", label="Boundary")
        ax.plot(object_center[0], object_center[1], "ro", label="Object Center")
        ax.plot(boundary_center[0], boundary_center[1], "go", label="Boundary Center")

        dx = 100 * np.cos(np.radians(object_angle))
        dy = -100 * np.sin(np.radians(object_angle))
        ax.arrow(object_center[0], object_center[1], dx, dy, color="g", head_width=5)

        dx_roi = 100 * np.cos(np.radians(roi_angle))
        dy_roi = -100 * np.sin(np.radians(roi_angle))
        ax.arrow(
            boundary_center[0],
            boundary_center[1],
            dx_roi,
            dy_roi,
            color="m",
            head_width=5,
        )

        ax.plot(
            [object_center[0], boundary_center[0]],
            [object_center[1], boundary_center[1]],
            "r--",
            label="Centers Line",
        )

        ax.set_xlim(0, image_width)
        ax.set_ylim(image_height, 0)
        ax.set_title("Angle Visualization")
        ax.legend()
        plt.show()

    return relative_angles, ROImeasurements


def load_coords_swapped(csv_path):
    """
    Loads tab-separated (Y, X) coordinates from a CSV file and returns (X, Y) NumPy array.
    """
    csv_path = os.path.normpath(os.path.expanduser(csv_path.strip()))

    if not os.path.isfile(csv_path):
        raise FileNotFoundError(f"CSV file not found at: {csv_path}")

    coords = []
    with open(csv_path, newline="") as csvfile:
        reader = csv.reader(csvfile, delimiter="\t")  # <-- TAB as delimiter
        for row in reader:
            if len(row) >= 2:
                y, x = map(float, row[:2])
                coords.append([y, x])
    return np.array(coords)


coords = load_coords_swapped("../testImages/relativeAngleTest/boundary_coords.csv")

ROI = {
    "coords": coords,
    "imageWidth": 512,
    "imageHeight": 512,
    "index2object": 390,
}

object_data = {"center": [94, 473], "angle": 75.9375}

angles, measurements = get_relative_angles(
    ROI, object_data, angle_option=0, fig_flag=False
)

print(angles)
