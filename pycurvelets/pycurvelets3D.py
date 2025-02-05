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
# def visualize_wedge_3d(coefficients, scale, wedge):
#     """Plot 3D visualization of curvelet coefficients"""
#     t1, t2, t3 = coefficients.shape
#     x, y, z, intensity = [], [], [], []

#     # Convert nonzero coefficients to 3D points
#     for i in range(t1):
#         for j in range(t2):
#             for k in range(t3):
#                 if np.abs(coefficients[i, j, k]) > 1e-6:  # Ignore small values
#                     x.append(i)
#                     y.append(j)
#                     z.append(k)
#                     intensity.append(np.abs(coefficients[i, j, k]))

#     # Create Plotly 3D scatter plot
#     fig = go.Figure()
#     fig.add_trace(go.Scatter3d(
#         x=x, y=y, z=z,
#         mode='markers',
#         marker=dict(size=3, color=intensity, colorscale='Viridis', opacity=0.8),
#         name=f'Scale {scale}, Wedge {wedge}'
#     ))

#     fig.update_layout(
#         title="3D Curvelet Wedge Visualization Scale" + str(scale) + " Wedge" + str(wedge) ,
#         scene=dict(xaxis_title="X", yaxis_title="Y", zaxis_title="Z"),
#     )

#     fig.show()

def visualize_spatial_volume(Y):
    """Plot 3D volume rendering of spatial domain"""
    m, n, p = Y.shape

    fig = go.Figure()

    fig.add_trace(go.Volume(
        x=np.repeat(np.arange(m), n * p),
        y=np.tile(np.repeat(np.arange(n), p), m),
        z=np.tile(np.arange(p), m * n),
        value=Y.flatten(),
        isomin=0,
        isomax=np.max(Y),
        opacity=0.1,  # Adjust for better visibility
        surface_count=15,  # Number of contour surfaces
        colorscale="Viridis"
    ))

    fig.update_layout(title="3D Spatial Domain Visualization", scene=dict(
        xaxis_title="X",
        yaxis_title="Y",
        zaxis_title="Z"
    ))

    fig.show()


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
    folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage_fire"
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
    w = 1024  # wedge

    X_modified = [coeff.copy() for coeff in X]  # Create a copy of the coefficients
    coefficients = X_modified[s][w]
    visualize_spatial_volume(coefficients)
    # visualize_wedge_3d(coefficients, s, w)
    t1, t2, t3 = coefficients.shape

    # Calculate indices relative to the array size
    t1 = t1 // 2  # Middle index along the first dimension
    t2 = t2 // 2  # Middle index along the second dimension
    t3 = t3 // 2  # Middle index along the third dimension

    # Ensure indices are within bounds
    if t1 < coefficients.shape[0] and t2 < coefficients.shape[1] and t3 < coefficients.shape[2]:
        coefficients[t1, t2, t3] = 1  # Modify the coefficient
        X_modified[s][w] = coefficients
    else:
        print(f"Indices out of bounds for scale {s}, wedge {w}")

    m, n, p = img_stack.shape

    # Spatial domain
    Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)

    # Call the function
    # visualize_wedge_3d(coefficients, s, w)

    # Frequency domain
    F = np.fft.ifftshift(np.fft.fftn(np.real(Y)))

    # Reorder the data for display
    Y = np.transpose(Y, [1, 0, 2])
    F = np.transpose(F, [1, 0, 2])

    # viewer = napari.Viewer()
    # viewer.add_image(np.real(Y), name="Spatial Domain")
    # viewer.add_image(np.real(F), name="Frequency Domain")
    # napari.run()

# Run the demo
create_3d_curvelet_demo()
