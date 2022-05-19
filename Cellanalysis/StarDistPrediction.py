from stardist.models import StarDist2D
from csbdeep.utils import Path, normalize
from glob import glob
from tifffile import imread
import scipy.io as sio
from PIL import Image

# This function calls StarDist using thresholds provided by the program 
# itself and the model '2D_versatile_he' which segments the nuclei. 
def prediction(images, index):

    X = sorted(glob(images))

    print('Analyzing ' + X[index])

    X = list(map(imread,X))

    axis_norm = (0,1) 

    model = StarDist2D.from_pretrained('2D_versatile_he')
    
    img = normalize(X[index], 1,99.8, axis=axis_norm)

    labels, details = model.predict_instances(img, prob_thresh=0.2, nms_thresh=0.5)

    im = Image.fromarray(labels)
    im.save('mask.tif')

    sio.savemat('labels.mat', {'labels':labels})
    sio.savemat('details.mat', {'details':details})

    return labels, details
