from curvelops import FDCT3D, curveshow

import napari
import itertools
import matplotlib.pyplot as plt
import numpy as np
import cv2
import os
import time
import fdct3d_wrapper

folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage"
num_images = 4

img = [f for f in os.listdir(folder_path) if f.endswith((".tif"))]
first_img = cv2.imread(os.path.join(folder_path, img[0]), cv2.IMREAD_GRAYSCALE)

nx, ny = first_img.shape
nz = num_images

img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)

for i, file_name in enumerate(img[:num_images]):
    img_path = os.path.join(folder_path, file_name)
    image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
    img_stack[i, :, :] = image

start = time.process_time()
C3D = FDCT3D(dims=img_stack.shape, nbscales=4, nbangles_coarse=8, allcurvelets=True)

img_c = C3D.struct(C3D @ img_stack)
# sizes = set()

# viewer = napari.Viewer()
# viewer.add_image(np.transpose(np.abs(img_c[0][0]), (2, 0, 1)))

# for i in range(len(img_c)):
#     for img in img_c[i]:
#         sizes.add((np.array(img)).shape)

# print(sizes)

sizes = set()
coefficients_by_shape = {}


for i in range(len(img_c)):
    for img in img_c[i]:
        img_array = np.array(img)
        shape = img_array.shape
        sizes.add(shape)

        if shape not in coefficients_by_shape:
            coefficients_by_shape[shape] = []
        coefficients_by_shape[shape].append(img_array)

print("Unique shapes:", sizes)

stacks_by_shape = {
    shape: np.stack(coeffs) for shape, coeffs in coefficients_by_shape.items()
}

with napari.gui_qt():
    viewer = napari.Viewer()

    for shape, stack in stacks_by_shape.items():
        viewer.add_image(
            np.abs(stack),  # Take the magnitude (if complex)
            name=f"Shape {shape}",
        )


napari.run()
# img_slice = img_c[0, :, :, 0]
# napari.view_image(img_slice, colormap="viridis")
# napari.run()

# for scale in img_c:

#     print(len(scale), " A")
#     for i in scale:
#         print(len(i))

# viewer = napari.Viewer(ndisplay=3)

# slice_index = len(img_c[0]) // 2
# image_layer = viewer.add_image(np.abs(img_c[slice_index]), rendering="mip")
# napari.run()
