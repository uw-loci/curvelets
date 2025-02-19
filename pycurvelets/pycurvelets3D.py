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

def create_3d_curvelet(folder_path, num_images, nb_scales, nb_angles):
    '''
    This function takes a set of collagen fiber images and visualizes them in the 3D space
    after doing the forward and inverse fourier transform on the images. Both the original
    and reconstructed data are portrayed through Mayavi, a 3D viewer.

    Parameters:

    - folder_path: the folder path (can be relative or absolute) that consists of the images that
    will be used to visualize the images
    - num_images: the number of images that is requested to be visualized under the Mayavi 3D
    viewer. Must be less than or equal to the actual number of images within folder_path directory
    - nb_scales: the number of scales for which FDCT3D should be processed under
    - nb_angles: the number of angles for which FDCT3D should be processed under
    '''
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

    # It is expected that all images are in a TIFF file
    img_files = [f for f in os.listdir(folder_path) if f.endswith(".tif")]
    first_img = cv2.imread(os.path.join(folder_path, img_files[0]), cv2.IMREAD_GRAYSCALE)

    # Identify dimensions of the images
    nx, ny = first_img.shape
    nz = num_images

    # Create 3D image stack
    img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
    for i, file_name in enumerate(img_files[:num_images]):
        img_path = os.path.join(folder_path, file_name)
        image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        img_stack[i, :, :] = image

    # Create 3D Curvelet Transform data structure
    C3D = FDCT3D(dims=img_stack.shape, nbscales=nb_scales, nbangles_coarse=nb_angles, allcurvelets=False)

    # Forward transform
    img_stack_complex = img_stack.astype(np.complex128)
    X = C3D.fdct(4, 8, 0, img_stack_complex)  # Corrected call

    # Modify a specific curvelet coefficient
    s = 2  # scale
    w = 3  # wedge (must be valid for the given scale)

    X_modified = [coeff.copy() for coeff in X]  

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

    m, n, p = img_stack.shape

    # Inverse transform
    Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)  

    # Create a grid for the 3D plot
    x, y, z = np.mgrid[:nx, :ny, :nz]

    img_stack_transposed = np.transpose(img_stack, (1, 2, 0)) 
    Y_transposed = np.transpose(np.abs(Y),(1,2,0))

    # Visualize the original and reconstructed data in 3D
    mlab.figure("Original Data")
    mlab.contour3d(x, y, z, img_stack_transposed, contours=10, opacity=0.5)
    mlab.axes()
    mlab.outline()
    mlab.title("Original Data")

    mlab.figure("Reconstructed Data")
    mlab.contour3d(x, y, z, Y_transposed, contours=10, opacity=0.5)
    mlab.axes()
    mlab.outline()
    mlab.title("Reconstructed Data")

    mlab.show()

# Run 3D curvelet transform on image
create_3d_curvelet( "../doc/testImages/CellAnalysis_testImages/3dImage_simple", 128, 4, 8)
