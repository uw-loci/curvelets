import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
# from mayavi import mlab
import napari
from curvelops import FDCT3D
import cv2
import os
import sys
import time
import math

matplotlib.use("TkAgg")
def visualize_wedge_3d(wedge, scale_num, wedge_num):
    """
    Visualizes a 3D wedge from the curvelet coefficients.
    
    Parameters:
    - wedge (numpy.ndarray): The 3D array of coefficients for a specific wedge.
    """
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection='3d')

    x, y, z = np.nonzero(wedge)
    values = wedge[x, y, z]  

    scatter = ax.scatter(x, y, z, c=values, cmap='viridis', marker='o', s=10)

    cbar = plt.colorbar(scatter, ax=ax, shrink=0.5, aspect=10)
    cbar.set_label('Coefficient Magnitude')

    xy_projection = np.max(wedge, axis=2)  
    X, Y = np.meshgrid(range(wedge.shape[0]), range(wedge.shape[1]))  
    ax.plot_surface(X, Y, np.zeros_like(X), facecolors=plt.cm.coolwarm(xy_projection / xy_projection.max()), alpha=0.6)

    yz_projection = np.max(wedge, axis=0)  
    Y, Z = np.meshgrid(range(wedge.shape[1]), range(wedge.shape[2]))  
    ax.plot_surface(np.zeros_like(Y), Y, Z, facecolors=plt.cm.coolwarm(yz_projection.T / yz_projection.max()), alpha=0.6)


    # Labels and title
    ax.set_xlabel('X-axis')
    ax.set_ylabel('Y-axis')
    ax.set_zlabel('Z-axis')
    ax.set_title('Scale ' + str(scale_num) + ' Wedge ' + str(wedge_num))

    plt.show()


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
    w = 100  # wedge

    X_modified = [coeff.copy() for coeff in X]  # Create a copy of the coefficients
    coefficients = X_modified[s][w]
    visualize_wedge_3d(coefficients, s, w)
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
