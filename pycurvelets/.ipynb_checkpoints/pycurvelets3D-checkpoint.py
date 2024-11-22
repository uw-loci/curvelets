from curvelops import FDCT3D, curveshow

import napari
import inspect
import itertools
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import numpy as np
import cv2
import os
import time


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
C3D = FDCT3D(dims=img_stack.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False)

img_c = C3D.struct(C3D @ img_stack)

"""
Visualization by using a cross-section of the middle rather than visualizing the 3D wedges
individually, following the MATLAB fdct3d_demo_basic.m implementation.
"""

# create a zero'd image stack np array
X = np.zeros(img_stack.shape)

# get the scale index and wedge index
s = 3
w = 0
img_stack_complex = img_stack.astype(np.complex128)

# forward transform that np array
X = C3D.fdct(4, 8, 0, img_stack_complex)

# iterate through
coefficients = X[s][w]
t1, t2, t3 = coefficients.shape
t1 = (t1 + 1) // 2
t2 = (t2 + 1) // 2
t3 = (t3 + 1) // 2
coefficients[t1, t2, t3] = 1
X[s][w] = coefficients

# inverse transform
Y = C3D.ifdct(X)

# spatial vs frequency domain
F = np.fft.ifftshift(np.fft.fftn(Y))

# reorder data for display
Y = np.transpose(Y, [1, 0, 2])
F = np.transpose(F, [1, 0, 2])
real_Y = np.real(Y)

# display 1
slices = [real_Y[:, :, i] for i in range(nz)]


print("Creating figure...")
fig = plt.figure()

print("Adding 3D subplot...")
ax = fig.add_subplot(projection="3d")

ax.set_xlabel("x")
ax.set_ylabel("y")
ax.set_zlabel("z")

ax.set_xlim([0, nx])
ax.set_ylim([0, ny])
ax.set_zlim([0, nz])

# create plot
slice_index = nz // 2  # getting middle slice
h = ax.contourf(
    np.arange(nx),
    np.arange(ny),
    slices[slice_index],
    zdir="z",
    offset=slice_index,
    cmap="gray",
    alpha=0.7,
)


# trying to make it animated
def update(frame):
    global h
    for coll in h.collections:
        coll.remove()  # clear prev slice
    ax.contourf(
        np.arange(nx),
        np.arange(ny),
        slices[frame],
        zdir="z",
        offset=frame,
        cmap="gray",
        alpha=0.7,
    )


# anim to easily flip through images
print("\nSliced display of the curvelet")
print(
    "Press any key to start the animation which displays the curvelet at different slices"
)
input("Press Enter to start the animation...")

ani = FuncAnimation(fig, update, frames=range(nz), interval=100, blit=False)
plt.pause(0.1)
plt.show()


"""
Uses a hashset to go through coefficients by shape and groups those with the same shape together.
Afterwards, those same shapes are placed into the same image stack, which is then visualized
through napari viewer. Currently, it is not possible to differentiate scales within
napari viewer, but every wedge is separated as a layer within napari viewer.
"""
# sizes = set()
# coefficients_by_shape = {}

# for i in range(len(img_c)):
#     for img in img_c[i]:
#         img_array = np.array(img)
#         shape = img_array.shape
#         sizes.add(shape)

#         if shape not in coefficients_by_shape:
#             coefficients_by_shape[shape] = []
#         coefficients_by_shape[shape].append(img_array)

# print("Unique shapes:", sizes)

# stacks_by_shape = {
#     shape: np.stack(coeffs) for shape, coeffs in coefficients_by_shape.items()
# }

# with napari.gui_qt():
#     viewer = napari.Viewer()

#     for shape, stack in stacks_by_shape.items():
#         viewer.add_image(
#             np.abs(stack),  # Take the magnitude (if complex)
#             name=f"Shape {shape}",
#         )


# napari.run()
