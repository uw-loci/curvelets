import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from mayavi import mlab
import plotly.graph_objects as go
import napari
from curvelops import FDCT3D
import cv2
import os
import sys
import time
import math

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

    print(" ")

    # Image load
    folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage_fire"
    num_images = 20

    img_files = [f for f in os.listdir(folder_path) if f.endswith(".tif")]
    first_img = cv2.imread(os.path.join(folder_path, img_files[0]), cv2.IMREAD_GRAYSCALE)

    nx, ny = first_img.shape
    nz = num_images

    # Create 3D image stack
    img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
    for i, file_name in enumerate(img_files[:num_images]):
        img_path = os.path.join(folder_path, file_name)
        image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        img_stack[i, :, :] = image

    # Perform 3D Curvelet Transform
    C3D = FDCT3D(dims=img_stack.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False)
    print("Segfault?")
    # Forward transform
    img_stack_complex = img_stack.astype(np.complex128)
    X = C3D.fdct(4, 8, 0, img_stack_complex)  # Corrected call


    print("Segfault?")

    # Modify a specific curvelet coefficient
    s = 2  # scale
    w = 3  # wedge (must be valid for the given scale)

    X_modified = [coeff.copy() for coeff in X]  # Create a copy of the coefficients
    if s < len(X_modified) and w < len(X_modified[s]):
        coefficients = X_modified[s][w]
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
    else:
        print(f"Invalid scale {s} or wedge {w}")
    
    print("Segfault?")

    # Inverse transform
    Y = C3D.ifdct(nx, ny, nz, 4, 8, 0, X_modified)  # Corrected call

    # Adjust z-axis scaling to make slices appear closer
    z_scale = 0.2  # Reduce z-spacing by 80%
    z_coords = np.arange(nz) * z_scale

    # Create a grid for the 3D plot
    x, y, z = np.mgrid[:nx, :ny, :nz]
    z = z * z_scale  # Apply scaling to z-axis

    # Visualize the original and reconstructed data in 3D
    mlab.figure("Original Data")
    mlab.contour3d(x, y, z, img_stack, contours=10, opacity=0.5)
    mlab.axes()
    mlab.outline()
    mlab.title("Original Data")

    mlab.figure("Reconstructed Data")
    mlab.contour3d(nx, ny, nz, np.abs(Y), contours=10, opacity=0.5)
    mlab.axes()
    mlab.outline()
    mlab.title("Reconstructed Data")

    mlab.show()


    # # Create 3D image stack
    # img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
    # for i, file_name in enumerate(img[:num_images]):
    #     img_path = os.path.join(folder_path, file_name)
    #     image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
    #     img_stack[i, :, :] = image

    # # Perform 3D Curvelet Transform
    # C3D = FDCT3D(
    #     dims=img_stack.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False
    # )

    # # Forward transform
    # img_stack_complex = img_stack.astype(np.complex128)
    # X = C3D.fdct(4, 8, 0, img_stack_complex)

    # # Modify a specific curvelet coefficient
    # s = 2  # scale
    # w = 1024  # wedge

    # X_modified = [coeff.copy() for coeff in X]  # Create a copy of the coefficients
    # coefficients = X_modified[s][w]
    # t1, t2, t3 = coefficients.shape

    # # Calculate indices relative to the array size
    # t1 = t1 // 2  # Middle index along the first dimension
    # t2 = t2 // 2  # Middle index along the second dimension
    # t3 = t3 // 2  # Middle index along the third dimension

    # # Ensure indices are within bounds
    # if t1 < coefficients.shape[0] and t2 < coefficients.shape[1] and t3 < coefficients.shape[2]:
    #     coefficients[t1, t2, t3] = 1  # Modify the coefficient
    #     X_modified[s][w] = coefficients
    # else:
    #     print(f"Indices out of bounds for scale {s}, wedge {w}")

    # m, n, p = img_stack.shape

    # # Spatial domain
    # Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)


    # mlab.figure("Original Data")
    # mlab.contour3d(img_stack, contours=10, opacity=0.5)
    # mlab.axes()
    # mlab.outline()

    # mlab.figure("Reconstructed Data")
    # mlab.contour3d(np.abs(Y), contours=10, opacity=0.5)
    # mlab.axes()
    # mlab.outline()

    # mlab.show()

# Run the demo
create_3d_curvelet_demo()
