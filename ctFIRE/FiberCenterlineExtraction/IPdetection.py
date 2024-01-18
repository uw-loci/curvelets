# import pandas as pd
# from glob import glob
# import math
# import numpy as np
from skimage import io, morphology, img_as_ubyte, img_as_float, filters
# import os
# from tqdm.notebook import tqdm
from matplotlib import pyplot as plt
# from shapely.geometry import LineString, MultiPoint
# from shapely.ops import split
from scipy import io as sio
from centerline import CenterLine, smooth_mask, iou
def IP_skeleton(dataPath,imagePath,coordPath):
    # dataPath = 'examples/sample_ctFIRE.mat'
    # imagePath = "examples/sample_input.png"
    # coordPath = 'IPxy_skeleton.mat'
    mat = sio.loadmat(dataPath)
    mat_data = mat['data']
    centerline_mat = CenterLine()
    line_dict = centerline_mat.mat_to_lines(mat_data)
    centerline_mat = CenterLine(line_dict=line_dict, associate_image=io.imread(imagePath))
    fig, ax = plt.subplots(1, 3, figsize=(20, 20))
    ax[0].imshow(centerline_mat.associate_image, cmap=plt.cm.gray)
    ax[1].imshow(centerline_mat.centerline_image, cmap=plt.cm.gray)
    joints_coords, filtered_image = centerline_mat.joint_filter(centerline_mat.centerline_image)
    ax[2].plot(joints_coords[:, 1], joints_coords[:, 0], color='cyan', marker='o',
            linestyle='None', markersize=6)
    ax[2].imshow(filtered_image, cmap=plt.cm.gray)
    ax[2].plot(joints_coords[:, 1], joints_coords[:, 0], color='cyan', marker='o',
            linestyle='None', markersize=6)
    plt.show()
    mdic = {"IPyx_skeleton": joints_coords, "Label": "IP from python skeleton-based computation","Method":"Skeleton-based"}
    sio.savemat(coordPath,mdic)
    return joints_coords
    # centerline_mat.export_line_dict('examples/example_image_ctFIRE_line_dict.csv')
