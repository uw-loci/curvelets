from skimage import data, util, measure
import scipy.io
import numpy as np

def CellPropertyTest():

    image = scipy.io.loadmat('fortest.mat')
    
    desired_properties = [
        "label",
        "image",
        "area",
        "perimeter",
        "bbox",
        "bbox_area",
        "major_axis_length",
        "minor_axis_length","orientation",
        "centroid",
        "equivalent_diameter",
        "extent",
        "eccentricity",
        "convex_area",
        "solidity",
        "euler_number",
    ]

    imageData = image['labels']

    props = measure.regionprops_table(
        imageData, properties=desired_properties
    )

    print(props)
