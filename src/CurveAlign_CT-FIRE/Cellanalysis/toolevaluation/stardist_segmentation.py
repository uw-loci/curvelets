from stardist.models import StarDist2D
from csbdeep.utils import normalize

import numpy as np
import tifffile

def predict(model_name, input_data, **kwargs):
    ''' Uses StarDist models to generate ndarray mask of an image 
    
    Parameters:

    - model_name, a str that represents the name of a pretrained cellpose mode
        Options include:
        * 2D_versatile_he
        * 2D_versatile_fluo
        * 2D_paper_dsb2018

    - input_data_path, a str that contains the path to an image for segmentation

    Returns:
    - masks, an ndarray with each pixel being labeled
    
    '''

    model = StarDist2D.from_pretrained(model_name)
    
    image = tifffile.imread(input_data)
    if len(image.shape) != 3:
        Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (Y,X,C) or (C,Y,X)")

    labels, details = model.predict_instances(normalize(image), kwargs=kwargs)
    
    return labels