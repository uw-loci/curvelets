from skimage.io import imread, imsave
from deepcell.applications import CytoplasmSegmentation, Mesmer
import numpy as np
import scipy.io as sio

def cyto_seg(img_path,model_name,img_mpp):
    im = imread(img_path)
    im = np.expand_dims(im,0)
    im = np.expand_dims(im,-1)
    #print(im.shape)
    if model_name == 'cyto':
        model = CytoplasmSegmentation()
    elif model_name == 'nuclei':
        model = NuclearSegmentation()
    elif model_name == 'tissuenet':
        model = Mesmer()
    else:
        print("PreTrained Deepcell model is not available ")
        return
    masks = model.predict(im,img_mpp) # 4 dimension
    mask = np.squeeze(masks)          # restore to 2D
    sio.savemat('mask4cells_DC.mat', {'mask4cells_DC':mask})
    return mask
