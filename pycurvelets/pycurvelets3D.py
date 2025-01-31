import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from curvelops import FDCT3D
import cv2
import os
import sys
import time
import math

matplotlib.use("TkAgg")


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
    folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage_simple"
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
    s = 3  # scale
    w = 0  # wedge

    # Create a copy of original transform
    X_modified = X.copy()

    # Modify specific curvelet coefficient
    coefficients = X_modified[s][w]
    t1, t2, t3 = coefficients.shape
    t1 = math.ceil((t1 + 1) / 2)
    t2 = math.ceil((t2 + 1) / 2)
    t3 = math.ceil((t3 + 1) / 2)
    coefficients[t1][t2][t3] = 1
    X_modified[s][w] = coefficients

    m, n, p = img_stack.shape

    # Spatial domain
    Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)

    # Frequency domain
    F = np.fft.ifftshift(np.fft.fftn(np.real(Y)))

    # Reorder the data for display
    Y = np.transpose(Y, [1, 0, 2])
    F = np.transpose(F, [1, 0, 2])

    # Display
    # h = np.real(Y)[0 : nx // 2, 0 : ny // 2, 0 : nz // 2]

    fig = plt.figure(figsize=(10, 8))

    for ix in range(nx):
        ax = fig.add_subplot(111, projection="3d")
        h = np.real(Y)[ix, :, :]

        X, Y = np.meshgrid(np.arange(h.shape[1]), np.arange(h.shape[0]))
        ax.plot_surface(X, Y, h, cmap="viridis")
        # plt.colorbar()
        plt.show()


create_3d_curvelet_demo()
