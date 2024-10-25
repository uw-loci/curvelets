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
print(img_stack.shape)

FDCT3D_stack = FDCT3D(
    dims=img_stack.shape, nbscales=4, nbangles_coarse=16, allcurvelets=True
)

coeff = FDCT3D_stack @ img_stack
coeff_magnitude = np.abs(coeff)
