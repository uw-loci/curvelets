from stardist.models import StarDist2D
from csbdeep.utils import normalize

import numpy as np
import tifffile

def predict(model_name, input_data, **kwargs):
    model = StarDist2D.from_pretrained(model_name)
    
    image = tifffile.imread(input_data)
    if len(image.shape) != 3:
        Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (Y,X,C) or (C,Y,X)")

    labels, details = model.predict_instances(normalize(image))
    
    return labels