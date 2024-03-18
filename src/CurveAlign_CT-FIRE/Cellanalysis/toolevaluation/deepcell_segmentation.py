import numpy as np
import tifffile
from deepcell.applications import NuclearSegmentation, CytoplasmSegmentation
import os

key = 'POtyuCIN.nWwQ1FXgroiE8zKTWLgf5rdqGRJeKQHf'
os.environ.update({"DEEPCELL_ACCESS_TOKEN": key})

def predict(model_name, input_data, **kwargs):
    
    model = None
    if model_name == 'NuclearSegmentation':
        model = NuclearSegmentation()
    elif model_name == 'CytoplasmSegmentation':
        model = CytoplasmSegmentation()
    else:
        Exception(f"{model_name} was provided but only models NuclearSegmentation and CytoplasmSegmentation are available")

    image = tifffile.imread(input_data)
    if len(image.shape) != 4:
        if image.ndim == 3:
            chan_dim = np.argmin(image.shape)
            if chan_dim == 0:
                Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (B,X,Y,C)")
            else:
                image = np.expand_dims(image, 0)
        elif image.ndim == 3:
            image = np.expand_dims(image, 0)
            image = np.expand_dims(image, 3)
        else:
            Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (B,X,Y,C)")

    image_mpp = None
    if 'image_mpp' in kwargs:
        image_mpp = kwargs['image_mpp']

    mask = model.predict(image, image_mpp=image_mpp)

    return mask