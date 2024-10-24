from curvelops import FDCT3D, curveshow

import matplotlib.pyplot as plt
import numpy as np
import cv2
import os

folder_path = "../doc/testImages/CellAnalysis_testImages/3dImage"

# taken by Demystifying_Curvelets of Curvelops
img = [f for f in os.listdir(folder_path) if f.endswith((".tif"))]
first_img = cv2.imread(os.path.join(folder_path, img[0]), cv2.IMREAD_GRAYSCALE)

nx, ny = first_img.shape
nz = len(img)

img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)

for i, file_name in enumerate(img):
    img_path = os.path.join(folder_path, file_name)
    image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
    img_stack[i, :, :] = image

FDCT3d = FDCT3D(dims=img_stack.shape, nbscales=4, nbangles_coarse=16, allcurvelets=True)

c = FDCT3d @ img_stack

print(type(c))
print([coeff.shape for coeff in c])
fig, axes = plt.subplots(4, 16, figsize=(15, 15))

for i in range(4):
    for j in range(16):
        wedge = c[i][j]
        axes[i, j].imshow(np.abs(wedge), cmap="gray")
        axes[i, j].set_title(f"Scale {i + 1}, Angle {j+1}")
        axes[i, j].axis("off")
plt.tight_layout()
plt.show()
