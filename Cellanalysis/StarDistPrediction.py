from stardist.models import StarDist2D
from csbdeep.utils import Path, normalize
from glob import glob
from tifffile import imread
import scipy.io as sio

def prediction(images, index):

    X = sorted(glob(images))

    X = list(map(imread,X))

    axis_norm = (0,1) 

    model = StarDist2D.from_pretrained('2D_versatile_he')
    
    img = normalize(X[index], 1,99.8, axis=axis_norm)

    labels, details = model.predict_instances(img)

    sio.savemat('labels.mat', {'labels':labels})
    sio.savemat('details.mat', {'details':details})

    return labels, details
