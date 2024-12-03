import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from curvelops import FDCT3D
import cv2
import os
import sys
import time

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
    folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage"
    num_images = 4

    img = [f for f in os.listdir(folder_path) if f.endswith((".tif"))]
    first_img = cv2.imread(os.path.join(folder_path, img[0]), cv2.IMREAD_GRAYSCALE)

    nx, ny = first_img.shape
    nz = num_images

    # Create 3D image stack
    img_stack = np.zeros((nx, ny, nz), dtype=first_img.dtype)
    for i, file_name in enumerate(img[:num_images]):
        img_path = os.path.join(folder_path, file_name)
        image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        img_stack[:, :, i] = image

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

    # Create a copy of the original transform
    X_modified = X.copy()

    # Modify the specific coefficient
    coefficients = X_modified[s][w]
    t1, t2, t3 = coefficients.shape
    t1 = (t1 + 1) // 2
    t2 = (t2 + 1) // 2
    t3 = (t3 + 1) // 2
    coefficients[t1, t2, t3] = 1
    X_modified[s][w] = coefficients

    m, n, p = img_stack.shape

    # Inverse Transform
    Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)

    # Prepare data for visualization
    Y = np.transpose(Y, [1, 0, 2])

    real_Y = np.real(Y)
    F = np.fft.ifftshift(np.fft.fftn(Y))
    F = np.transpose(F, [1, 0, 2])

    # Advanced 3D visualization
    fig = plt.figure(figsize=(16, 6))

    # Spatial domain 3D slice animation
    ax1 = fig.add_subplot(121, projection="3d")
    slices = [real_Y[:, :, i] for i in range(nz)]

    def update_spatial_slice(frame):
        ax1.clear()
        ax1.contourf(
            np.arange(nx),
            np.arange(ny),
            slices[frame],
            zdir="z",
            offset=frame,
            cmap="gray",
            alpha=0.7,
        )
        ax1.set_title("Spatial Domain Slices")
        ax1.set_xlabel("X")
        ax1.set_ylabel("Y")
        ax1.set_zlabel("Z")
        ax1.set_xlim(0, nx)
        ax1.set_ylim(0, ny)
        ax1.set_zlim(0, nz)

    # Frequency domain 3D slice animation
    ax2 = fig.add_subplot(122, projection="3d")
    freq_slices = [F[:, :, i] for i in range(nz)]

    def update_frequency_slice(frame):
        ax2.clear()
        ax2.contourf(
            np.arange(nx),
            np.arange(ny),
            freq_slices[frame],
            zdir="z",
            offset=frame,
            cmap="gray",
            alpha=0.7,
        )
        ax2.set_title("Frequency Domain Slices")
        ax2.set_xlabel("X")
        ax2.set_ylabel("Y")
        ax2.set_zlabel("Z")
        ax2.set_xlim(0, nx)
        ax2.set_ylim(0, ny)
        ax2.set_zlim(0, nz)

    # Visualization animation
    input("Press Enter to start the slice animations...")

    for frame in range(nz):
        update_spatial_slice(frame)
        update_frequency_slice(frame)
        plt.pause(0.5)

    plt.show(block=True)


# Run the demonstration
create_3d_curvelet_demo()
