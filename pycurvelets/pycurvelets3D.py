import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# from mayavi import mlab
import plotly.graph_objects as go
import napari
from curvelops import FDCT3D
import cv2
import os
import sys
import time
import math


matplotlib.use("TkAgg")


def rotate_points(x, y, z, theta, phi):
    """
    Rotates the given 3D points by the azimuth (theta) and elevation (phi).

    Parameters:
    - x, y, z: Arrays of points in 3D space
    - theta: Azimuth angle in radians (rotation around Z-axis)
    - phi: Elevation angle in radians (tilt up/down)

    Returns:
    - Rotated (x, y, z) arrays
    """
    # Rotation matrix for azimuth (rotation about Z-axis)
    R_azimuth = np.array(
        [
            [np.cos(theta), -np.sin(theta), 0],
            [np.sin(theta), np.cos(theta), 0],
            [0, 0, 1],
        ]
    )
    # phi = np.asarray(phi).item()
    if np.any(np.isnan(phi)):
        print("NaN detected in phi")
        phi = np.nan_to_num(phi)
    print(f"phi: {phi}, type: {type(phi)}")
    print(f"Phi: {phi.shape}")

    # Rotation matrix for elevation (rotation about Y-axis)
    R_elevation = np.array(
        [[1, 0, 0], [0, np.cos(phi), -np.sin(phi)], [0, np.sin(phi), np.cos(phi)]]
    )

    # Apply both rotations
    R = R_elevation @ R_azimuth
    rotated_points = np.dot(R, np.vstack((x, y, z)))

    return rotated_points[0], rotated_points[1], rotated_points[2]


def plot_wedge(coefficients, s, w, num_azimuth=8, num_elevation=4):
    """
    Plots the wedge in 3D frequency space with the correct azimuth and elevation angles.

    Parameters:
    - coefficients: FDCT3D coefficient matrix
    - s: Scale index (zero-based)
    - w: Wedge index
    - num_azimuth: Number of azimuthal orientations (e.g., 8)
    - num_elevation: Number of elevation layers (e.g., 4)
    """
    wedge_data = coefficients[s][w]  # Extract 3D coefficient array

    # Get the shape of the coefficient array
    shape = wedge_data.shape
    x_range, y_range, z_range = np.meshgrid(
        np.linspace(-1, 1, shape[0]),
        np.linspace(-1, 1, shape[1]),
        np.linspace(-1, 1, shape[2]),
    )

    # Flatten arrays for plotting
    x, y, z = x_range.flatten(), y_range.flatten(), z_range.flatten()
    values = np.abs(wedge_data.flatten())

    # Filter out near-zero values for clarity
    threshold = np.max(values) * 0.1  # Adjust as needed
    mask = values > threshold
    x, y, z, values = x[mask], y[mask], z[mask], values[mask]

    # Compute the azimuth and elevation angles
    azimuth_idx = w % num_azimuth  # Wrap wedge index around azimuth count
    elevation_idx = w // num_azimuth  # Integer division to get elevation layer

    theta_w = (azimuth_idx / num_azimuth) * 2 * np.pi  # Map to [0, 2π]
    phi_w = (
        ((elevation_idx - num_elevation / 2) / num_elevation) * np.pi / 2
    )  # Map to [-π/4, π/4]

    # Rotate points
    x_rot, y_rot, z_rot = rotate_points(x, y, z, theta_w, phi_w)

    # Plot in 3D
    fig = plt.figure(figsize=(8, 8))
    ax = fig.add_subplot(111, projection="3d")
    scatter = ax.scatter(x_rot, y_rot, z_rot, c=values, cmap="viridis", alpha=0.75)

    ax.set_xlabel("ω1 (X-Frequency)")
    ax.set_ylabel("ω2 (Y-Frequency)")
    ax.set_zlabel("ω3 (Z-Frequency)")
    ax.set_title(
        f"Wedge {w} at Scale {s+1}\n(Azimuth={np.degrees(theta_w):.1f}°, Elevation={np.degrees(phi_w):.1f}°)"
    )

    plt.colorbar(scatter, ax=ax, label="Coefficient Magnitude")
    plt.show()


# def plot_wedge(w):
#     theta, phi = np.radians(get_wedge_angles(w))

#     # Convert spherical to Cartesian coordinates
#     x = np.cos(phi) * np.cos(theta)
#     y = np.cos(phi) * np.sin(theta)
#     z = np.sin(phi)

#     # Plot
#     fig = plt.figure(figsize=(8, 8))
#     ax = fig.add_subplot(111, projection="3d")

#     # Plot wedge direction
#     ax.quiver(0, 0, 0, x, y, z, color="r", arrow_length_ratio=0.1)

#     # Sphere for reference
#     u = np.linspace(0, 2 * np.pi, 100)
#     v = np.linspace(0, np.pi, 50)
#     X = np.outer(np.cos(u), np.sin(v))
#     Y = np.outer(np.sin(u), np.sin(v))
#     Z = np.outer(np.ones(np.size(u)), np.cos(v))
#     ax.plot_surface(X, Y, Z, color="lightblue", alpha=0.3)

#     # Labels
#     ax.set_xlabel("X")
#     ax.set_ylabel("Y")
#     ax.set_zlabel("Z")
#     ax.set_title(f"Wedge {w}: θ = {np.degrees(theta):.2f}°, φ = {np.degrees(phi):.2f}°")

#     plt.show()


def create_3d_curvelet_demo():

    # Print introductory information similar to MATLAB script
    print(" ")
    print("Python 3D Curvelet Transform Demonstration")
    print(" ")
    print(
        "The curvelet is created by setting coefficients to zero except at a specific location."
    )
    print("Notice how the curvelet is sharply localized in both space and frequency.")
    print(" ")
    print("The curvelet is at the 4th scale. Its energy in the frequency domain")
    print("is concentrated in the direction of (x,y,z)=(1,-1,-1).")
    print(
        "In the spatial domain, it looks like a disc with normal direction (1,-1,-1)."
    )
    print("The curvelet oscillates in the normal direction.")
    print(" ")

    # Image load
    folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage"
    num_images = 4

    img = [f for f in os.listdir(folder_path) if f.endswith((".tif"))]
    first_img = cv2.imread(os.path.join(folder_path, img[0]), cv2.IMREAD_GRAYSCALE)

    nx, ny = first_img.shape
    nz = num_images

    # Create 3D image stack
    img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
    for i, file_name in enumerate(img[:num_images]):
        img_path = os.path.join(folder_path, file_name)
        image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        img_stack[i, :, :] = image

    # Perform 3D Curvelet Transform
    C3D = FDCT3D(
        dims=img_stack.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False
    )

    # Forward transform
    img_stack_complex = img_stack.astype(np.complex128)
    X = C3D.fdct(4, 8, 0, img_stack_complex)

    # Modify a specific curvelet coefficient
    s = 1  # scale
    w = 50  # wedge

    X_modified = [coeff.copy() for coeff in X]
    print(X_modified[s][w])
    # coefficients = X_modified[s][w]
    total_wedges = len(X_modified[s])
    elevation_indices = np.unique([w % total_wedges for w in range(total_wedges)])
    plot_wedge(X_modified, s, w, total_wedges, elevation_indices)
    # visualize_wedge_3d(coefficients, s, w)
    t1, t2, t3 = coefficients.shape

    # Calculate indices relative to the array size
    t1 = t1 // 2  # Middle index along the first dimension
    t2 = t2 // 2  # Middle index along the second dimension
    t3 = t3 // 2  # Middle index along the third dimension

    m, n, p = img_stack.shape

    # Spatial domain
    Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)

    # Ensure Y is real if it has complex values
    # Y_real = np.real(Y)

    # # Determine middle indices
    # mid_x = m // 2
    # mid_y = n // 2
    # mid_z = p // 2

    # # Create the figure and 3D axis
    # fig = plt.figure(figsize=(10, 10))
    # ax = fig.add_subplot(111, projection="3d")

    # # Set labels and title
    # ax.set_xlabel("X")
    # ax.set_ylabel("Y")
    # ax.set_zlabel("Z")
    # ax.set_title("3D Cross-Sections (XY, YZ, XZ)")

    # plt.show()

    # visualize_spatial_volume(Y)

    # Call the function
    # # visualize_wedge_3d(coefficients, s, w)

    # # Frequency domain
    # F = np.fft.ifftshift(np.fft.fftn(np.real(Y)))

    # # Reorder the data for display
    # Y = np.transpose(Y, [1, 0, 2])
    # F = np.transpose(F, [1, 0, 2])

    # viewer = napari.Viewer()
    # viewer.add_image(np.real(Y), name="Spatial Domain")
    # viewer.add_image(np.real(F), name="Frequency Domain")
    # napari.run()


# Run the demo
create_3d_curvelet_demo()
