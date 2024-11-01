from curvelops import FDCT3D, curveshow

import matplotlib.pyplot as plt
import numpy as np
import cv2
import os
import time
import fdct3d_wrapper

folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage"
num_images = 32

img = [f for f in os.listdir(folder_path) if f.endswith((".tif"))]
first_img = cv2.imread(os.path.join(folder_path, img[0]), cv2.IMREAD_GRAYSCALE)

nx, ny = first_img.shape
nz = num_images

img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)

for i, file_name in enumerate(img[:num_images]):
    img_path = os.path.join(folder_path, file_name)
    image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
    img_stack[i, :, :] = image
print(img_stack.shape)

start = time.process_time()
fdct = FDCT3D(dims=img_stack.shape, nbscales=4, nbangles_coarse=16, allcurvelets=True)

print(fdct.shape)

coeff = fdct @ img_stack.flatten()
reconstructed_img = fdct.inverse(coeff)
structured = fdct.struct(coeff)
print(time.process_time() - start, " ", num_images)


def visualize_curvelet_coefficients(structured_coeffs, wedges_per_plot=100):

    num_scales = len(structured_coeffs)

    for scale in range(num_scales):
        scale_coeffs = structured_coeffs[scale]

        if scale == 0:
            plt.figure(figsize=(8, 8))
            plt.title(f"Scale {scale} (Low-frequency)")
            scale_coeffs_array = np.array(scale_coeffs)
            middle_slice = scale_coeffs_array.shape[0] // 2

            coeffs_slice = np.abs(scale_coeffs_array[middle_slice])
            normalized_coeffs = (coeffs_slice - coeffs_slice.min()) / (
                coeffs_slice.max() - coeffs_slice.min()
            )

            plt.imshow(normalized_coeffs, cmap="viridis")
            plt.colorbar()
            plt.show()
            continue

        num_wedges = len(scale_coeffs)
        grid_size = int(np.sqrt(wedges_per_plot))
        num_plots = int(np.ceil(num_wedges / wedges_per_plot))

        print(
            f"\nScale {scale} - {num_wedges} wedges total, split into {num_plots} plots"
        )

        for plot_idx in range(num_plots):
            start_wedge = plot_idx * wedges_per_plot
            end_wedge = min(start_wedge + wedges_per_plot, num_wedges)

            plt.figure(figsize=(16, 9))
            plt.suptitle(
                f"Scale {scale} - Wedges {start_wedge} to {end_wedge-1}\n({end_wedge-start_wedge} wedges)",
                fontsize=16,
            )

            for i, wedge in enumerate(range(start_wedge, end_wedge)):
                wedge_coeffs = np.array(scale_coeffs[wedge])
                middle_slice = wedge_coeffs.shape[0] // 2

                plt.subplot(grid_size, grid_size, i + 1)
                plt.title(f"Wedge {wedge}")
                plt.imshow(np.abs(wedge_coeffs[middle_slice]), cmap="viridis")
                plt.axis("off")

            plt.tight_layout()
            plt.show()


visualize_curvelet_coefficients(structured)
