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


def plot_wedge_coefficients(coefficients, s, w):
    """
    Visualizes the nonzero values of the wedge coefficients in 3D frequency space.

    Parameters:
    - coefficients: FDCT3D coefficient matrix
    - s: Scale index (zero-based)
    - w: Wedge index
    """
    wedge_data = coefficients[s][w]  # Extract 3D coefficient array
    k1, k2, k3 = np.nonzero(wedge_data)  # Get indices of nonzero elements
    coeff_values = np.abs(wedge_data[k1, k2, k3])  # Get their absolute magnitudes

    # Normalize the coefficient magnitudes to be in a reasonable radial range
    coeff_min, coeff_max = coeff_values.min(), coeff_values.max()
    r_vals = np.interp(coeff_values, (coeff_min, coeff_max), (5, 15))  # Map to [5,15]

    # Convert k1, k2, k3 to centered coordinates
    k1 = k1 - wedge_data.shape[0] // 2
    k2 = k2 - wedge_data.shape[1] // 2
    k3 = k3 - wedge_data.shape[2] // 2

    # Convert Cartesian to Spherical
    azimuth = np.arctan2(k2, k1)  # Azimuth angle
    elevation = np.arctan2(k3, np.sqrt(k1**2 + k2**2))  # Elevation angle

    # Convert back to Cartesian using r_vals (which now depend on coefficients)
    X = r_vals * np.cos(azimuth) * np.cos(elevation)
    Y = r_vals * np.sin(azimuth) * np.cos(elevation)
    Z = r_vals * np.sin(elevation)

    # Create scatter plot for coefficient locations
    scatter = go.Scatter3d(
        x=X,
        y=Y,
        z=Z,
        mode="markers",
        marker=dict(size=3, color=coeff_values, colorscale="Viridis", opacity=0.8),
        name="Coefficient Magnitudes",
    )

    # Layout settings
    layout = go.Layout(
        title=f"Scale{s} Wedge {w}",
        scene=dict(
            xaxis_title="X",
            yaxis_title="Y",
            zaxis_title="Z",
            aspectmode="data",
        ),
        height=800,
        width=800,
    )

    # Create figure
    fig = go.Figure(data=[scatter], layout=layout)
    fig.show()

    # wedge_data = coefficients[s][w]  # Extract 3D coefficient array
    # k1, k2, k3 = np.nonzero(wedge_data)  # Get indices of nonzero elements
    # coeff_values = np.abs(wedge_data[k1, k2, k3])  # Get their absolute magnitudes

    # # Normalize the coefficient magnitudes to be in a reasonable radial range
    # coeff_min, coeff_max = coeff_values.min(), coeff_values.max()
    # r_vals = np.interp(coeff_values, (coeff_min, coeff_max), (5, 15))

    # azimuth_angle = float(
    #     (2 * np.pi * w) / len(coefficients[s])
    # )  # Azimuth center angle
    # azimuth_range = np.pi / len(
    #     coefficients[s]
    # )  # Small angle to spread wedge in azimuth
    # elevation_angle = float(
    #     (np.pi / 2) * (w / len(coefficients[s]) - 0.5)
    # )  # Elevation center angle
    # elevation_range = np.pi / (
    #     2 * len(coefficients[s])
    # )  # Small angle to spread wedge in elevation

    # # r_vals = np.linspace(5, 15, num=10)  # TO EDIT (radial distance)
    # azimuth_vals = np.linspace(
    #     azimuth_angle - azimuth_range / 2, azimuth_angle + azimuth_range / 2, num=10
    # )
    # elevation_vals = np.linspace(
    #     elevation_angle - elevation_range / 2,
    #     elevation_angle + elevation_range / 2,
    #     num=10,
    # )

    # R, Az, El = np.meshgrid(r_vals, azimuth_vals, elevation_vals, indexing="ij")

    # # Convert spherical to Cartesian
    # X = (R * np.cos(Az) * np.cos(El)).real
    # Y = (R * np.sin(Az) * np.cos(El)).real
    # Z = (R * np.sin(El)).real
    # mesh = go.Mesh3d(
    #     x=X.flatten(), y=Y.flatten(), z=Z.flatten(), alphahull=1, flatshading=True
    # )

    # layout = go.Layout(
    #     scene=dict(
    #         xaxis_title="X",
    #         yaxis_title="Y",
    #         zaxis_title="Z",
    #         aspectmode="data",
    #     ),
    #     height=800,
    #     width=800,
    #     xaxis={"scaleanchor": "y"},
    # )

    # fig = go.Figure(data=[mesh], layout=layout)

    # fig.show()


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
    s = 2  # scale
    w = 10  # wedge

    X_modified = [coeff.copy() for coeff in X]
    # print(X_modified[s][w])
    # coefficients = X_modified[s][w]
    total_wedges = len(X_modified[s])
    elevation_indices = np.unique([w % total_wedges for w in range(total_wedges)])
    plot_wedge_coefficients(X_modified, s, w)
    # plot_wedge(X_modified, s, w, total_wedges, elevation_indices)
    # visualize_wedge_3d(coefficients, s, w)
    # t1, t2, t3 = coefficients.shape

    # Calculate indices relative to the array size
    # t1 = t1 // 2  # Middle index along the first dimension
    # t2 = t2 // 2  # Middle index along the second dimension
    # t3 = t3 // 2  # Middle index along the third dimension

    # m, n, p = img_stack.shape

    # # Spatial domain
    # Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)

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
