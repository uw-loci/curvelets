import numpy as np
import tifffile
from deepcell.applications import NuclearSegmentation, CytoplasmSegmentation, Mesmer
import os

key = 'POtyuCIN.nWwQ1FXgroiE8zKTWLgf5rdqGRJeKQHf'
os.environ.update({"DEEPCELL_ACCESS_TOKEN": key})

def predict(model_name, input_data, **kwargs):
    ''' Uses DeepCell models to generate ndarray mask of an image 
    
    Parameters:

    - model_name, a str that represents the name of a pretrained cellpose mode
        Options include:
        * NuclearSegmentation
        * CytoplasmSegmentation
        * Mesmer (for 2 channel images with nuclear and tissue information)

    - input_data_path, a str that contains the path to an image for segmentation

    Returns:
    - masks, an ndarray with each pixel being labeled
    
    '''

    model = None
    if model_name == 'NuclearSegmentation':
        model = NuclearSegmentation()
    elif model_name == 'CytoplasmSegmentation':
        model = CytoplasmSegmentation()
    elif model_name == 'Mesmer':
        model = Mesmer()
    else:
        Exception(f"{model_name} was provided but only models NuclearSegmentation and CytoplasmSegmentation are available")

    image = tifffile.imread(input_data)
    if len(image.shape) != 4:
        if image.ndim == 3:
            chan_dim = np.argmin(image.shape)
            if chan_dim == 0:
                Exception(f"Image is of shape: {image.shape} when DeepCell is expecting (B,X,Y,C)")
            else:
                image = np.expand_dims(image, 0)
        elif image.ndim == 2:
            image = np.expand_dims(image, 0)
            image = np.expand_dims(image, 3)
        else:
            Exception(f"Image is of shape: {image.shape} when DeepCell is expecting (B,X,Y,C)")

    image_mpp = None
    if 'image_mpp' in kwargs:
        image_mpp = kwargs['image_mpp']

    mask = model.predict(image, image_mpp=image_mpp)

    return mask