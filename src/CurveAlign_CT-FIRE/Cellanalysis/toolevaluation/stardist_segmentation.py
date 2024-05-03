from stardist.models import StarDist2D
from stardist.matching import matching_dataset, matching
from csbdeep.utils import normalize

import numpy as np
import tifffile

def predict(model_name, input_data, normalize_max, normalize_min, **kwargs):
    ''' Uses StarDist models to generate ndarray mask of an image 
    
    Parameters:

    - model_name, a str that represents the name of a pretrained cellpose mode
        Options include:
        * 2D_versatile_he
        * 2D_versatile_fluo
        * 2D_paper_dsb2018

    - input_data_path, a str that contains the path to an image for segmentation
                       or ndarray with data

    Returns:
    - masks, an ndarray with each pixel being labeled
    
    '''

    model = StarDist2D.from_pretrained(model_name)
    
    if type(input_data) == str:
        image = tifffile.imread(input_data)
    else:
        image = input_data

    if len(image.shape) != 3:
        Exception(f"Image is of shape: {image.shape} when StarDist is expecting (Y,X,C) or (C,Y,X)")

    nms_prob = 0.5
    if 'nms_thresh' in kwargs:
        nms_prob= kwargs['nms_thresh']

    prob_thresh = 0.5
    if 'prob_thresh' in kwargs:
        prob_thresh= kwargs['prob_thresh']

    labels, details = model.predict_instances(normalize(image, pmin=normalize_min, pmax=normalize_max), nms_thresh=nms_prob, prob_thresh=prob_thresh)
    
    return labels

def evaluate(gt_masks, pred_masks, ious=[0.1, 0.3, 0.5, 0.7, 0.9]):
    ''' Uses stardist evaluation to produce accuracy metrics
    
    Parameters:

    - gt_masks, ndarray of ground truth annotations in the shape of [B,X,Y]
    - pred_masks, ndarray of predicted masks in the same size as gt_masks
    - ious, a list of floats representing IOU thresholds to test at

    Returns:
    - metrics, an ndarray with each pixel being labeled
    
    '''
    results = [matching_dataset(gt_masks, pred_masks, thresh=t, show_progress=False, by_image=False) for t in ious]
    # results = [matching(gt_masks, pred_masks, thresh=t) for t in ious]
    ap = []
    tp = [] 
    fp = []
    fn = []
    for i in range(len(ious)):
        r = results[i]._asdict()
        ap.append(r['precision'])
        tp.append(r['tp'])
        fp.append(r['fp'])
        fn.append(r['fn'])

    return (ap, tp, fp, fn)