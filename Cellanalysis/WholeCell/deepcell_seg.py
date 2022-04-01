from skimage.io import imread, imsave
from deepcell.applications import CytoplasmSegmentation, Mesmer
import numpy as np

def deepcell(img_path):
    im = imread(img)
    im = np.expand_dims(im,0)
    app = CytoplasmSegmentation()
    labeled_image = app.predict(im)
    return labeled_image
