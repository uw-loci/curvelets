from stardist.models import StarDist2D
from csbdeep.utils import Path, normalize
from glob import glob
from tifffile import imread
import scipy.io as sio
from PIL import Image

# This function calls StarDist using thresholds provided by the program 
# itself and the seleted model for the segmentation
# pretrained models include '2D_versatile_he' for nuclei segmentation from HE image,
# '2D_versatile_fluo' for nuclei segmentation from fluorescence image, and
# '2D_paper_dsb2018' for nuclei sgementation from dsb image. 

def prediction(images,index,model_name,default_parameters_flag,prob_threshold, nms_threshold, Normalization_lowPercentile, Normalization_highPercentile):
    X = sorted(glob(images))
    print('Analyzing ' + X[index])
    X = list(map(imread,X))
    # if model_name == '2D_versatile_he':
    model = StarDist2D.from_pretrained(model_name)
    axis_norm = (0,1) 
    if default_parameters_flag == 1:
        img = normalize(X[index])
        labels, details = model.predict_instances(img)                
    else:
        img = normalize(X[index], Normalization_lowPercentile,Normalization_highPercentile, axis=axis_norm)
        labels, details = model.predict_instances(img, prob_thresh=prob_threshold, nms_thresh = nms_threshold)                
    # model = StarDist2D.from_pretrained(model_name)
    # if model_name == 'HE bright field':
    #     # img = normalize(X[index], 1,99.8, axis=axis_norm)
    #     labels, details = model.predict_instances(img, prob_thresh=0.2, nms_thresh=0.5)
    # else:
    #     labels, details = model.predict_instances(normalize(X[index]))
    im = Image.fromarray(labels)
    im.save('mask_sd.tif')
    sio.savemat('labels_sd.mat', {'labels':labels})
    sio.savemat('details_sd.mat', {'details':details})
    return labels, details
