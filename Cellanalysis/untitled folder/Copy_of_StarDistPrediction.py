from stardist.models import StarDist2D
from csbdeep.utils import Path, normalize
from glob import glob
from tifffile import imread
import scipy.io as sio
from PIL import Image

from stardist.models import Config2D

def prediction(images, index):

    X = sorted(glob(images))

    print('Analyzing ' + X[index])

    X = list(map(imread,X))

    axis_norm = (0,1) 

    n_channel = 1 if X[0].ndim == 2 else X[0].shape[-1]
    n_rays = 32
    use_gpu = False and gputools_available()
    grid = (2,2)
    conf = Config2D (
        n_rays       = n_rays,
        grid         = grid,
        use_gpu      = use_gpu,
        n_channel_in = n_channel,
    )   

    model = StarDist2D(conf, name='stardist', basedir='he_heavy_augment')
    
    img = normalize(X[index], 1,99.8, axis=axis_norm)

    labels, details = model.predict_instances(img, prob_thresh=0.5, nms_thresh=0.5)

    im = Image.fromarray(labels)
    im.save('mask.tif')

    sio.savemat('labels.mat', {'labels':labels})
    sio.savemat('details.mat', {'details':details})

    return labels, details
