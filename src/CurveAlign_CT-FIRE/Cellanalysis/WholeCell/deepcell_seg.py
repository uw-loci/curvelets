from skimage.io import imread, imsave
from deepcell.applications import CytoplasmSegmentation, Mesmer
import numpy as np
import scipy.io as sio

def cyto_seg(img_path):
    im = imread(img_path)
    im = np.expand_dims(im,0)
    im = np.expand_dims(im,-1)
    #print(im.shape)
    app = CytoplasmSegmentation()
    mask = app.predict(im)
    sio.savemat('mask.mat', {'mask':mask})
    return mask
