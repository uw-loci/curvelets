from cellpose import io, models
from metrics_tool import get_metrics
import numpy as np

def predict(model_name, input_data, **kwargs):
    ''' Uses cellpose models to generate ndarray mask of an image 
    
    Parameters:

    - model_name, a str that represents the name of a pretrained cellpose mode
        Options include:
        * cyto
        * cyto2
        * cyto3
        * tissuenet_cp3: tissuenet dataset
        * livecell_cp3: livecell dataset
        * yeast_PhC_cp3: YEAZ dataset
        * yeast_BF_cp3: YEAZ dataset
        * bact_phase_cp3: omnipose dataset
        * bact_fluor_cp3: omnipose dataset
        * deepbacs_cp3: deepbacs dataset
        * cyto2_cp3: cellpose dataset

    - input_data_path, a str that contains the path to an image for segmentation 
                       or ndarray with data
    - kwargs:
        * channels, a list of size 2 that tells cellpose what channel to segment in and what channel has nuclei
        * diameter, an int that represents cell diameter in pixels
        * flow_threshold, a float for the maximum allowed error of the flows for each mask
        * resample, a boolean such that dynamics can be run at the rescaled size (resample=False), or the dynamics can be run on the resampled, 
                    interpolated flows at the true image size (resample=True)

    Returns:
    - masks, an ndarray with each pixel being labeled
    
    '''
    model = None
    if model_name != 'cyto' or model_name != 'cyto2' or model_name != 'cyto3' or model_name != 'nuclei':
        model = models.CellposeModel(model_type=model_name)
    else:
        model = models.Cellpose(model_type=model_name)

    if type(input_data) == str:
        image = io.imread(input_data)
    else:
        image = input_data
    if len(image.shape) != 3:
        Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (Y,X,C) or (C,Y,X)")

    chan = [0,0]
    if 'channels' in kwargs:
        chan= kwargs['channels']

    diam = None
    if 'diameter' in kwargs:
        diam = kwargs['diameter']

    flow_tresh = 0.4
    if 'flow_treshold' in  kwargs:
        flow_tresh = kwargs['flow_threshold']

    resample = True
    if 'resample' in kwargs:
        resample = kwargs['resample']

    cellprob_tresh = 0
    if 'cellprob_threshold' in kwargs:
        cellprob_tresh = kwargs['cellprob_threshold']

    masks, *_ = model.eval(image, channels=chan, diameter=diam, flow_threshold=flow_tresh, resample=resample, cellprob_threshold=cellprob_tresh)

    return masks

def evaluate(gt_masks, pred_masks, ious=[0.1, 0.3, 0.5, 0.7, 0.9]):
    ''' Uses cellpose evaluation to produce accuracy metrics
    
    Parameters:

    - gt_masks, ndarray of ground truth annotations in the shape of [B,X,Y]
    - pred_masks, ndarray of predicted masks in the same size as gt_masks
    - ious, a list of floats representing IOU thresholds to test at

    Returns:
    - metrics, an ndarray with each pixel being labeled
    
    '''
    # return average_precision(gt_masks, pred_masks, ious)
    # B, X, Y = gt_masks.shape

    # # ap, tp, fp, fn
    # metrics = [np.zeros(len(ious)), np.zeros(len(ious)), np.zeros(len(ious)), np.zeros(len(ious))]
    
    # for b in range(B):
    #     result = average_precision(gt_masks[b], pred_masks[b], ious)
    #     # print(f'b({b}) result: {result}')
    #     for i in range(4):
    #         # if i == 3:
    #         #     print(f'b({b}): metrics ({metrics[i]}) += result ({result[i]})')
    #         metrics[i] += np.nan_to_num(result[i])
    #         # print(f'i: {i} @ metric: {metrics[i]} + result: {result[i]}')
    #         # metrics[i] /= (b+1)
    #     # print(f'        In total, metrics: {metrics}')
    # for i in range(len(ious)):
    #     print(f'iou: {ious[i]} = {metrics[1][i]} / ({metrics[1][i]} + {metrics[2][i]} + {metrics[3][i]}) = {metrics[1][i] / (metrics[1][i] + metrics[2][i] + metrics[3][i])}')
    #     metrics[0][i] = metrics[1][i] / (metrics[1][i] + metrics[2][i] + metrics[3][i])
    # # for i, iou in enumerate(ious):
    # #     result = average_precision(gt_masks, pred_masks, iou)
    # #     print(f"iou: {iou} = metrics: {result}")
    # #     for m, metric in enumerate(metrics):
    # #         metric[i] = result[m]
    # return tuple(metrics)

    results = [get_metrics(gt_masks, pred_masks, t) for t in ious]
    # results = [matching(gt_masks, pred_masks, thresh=t) for t in ious]
    ap = []
    tp = [] 
    fp = []
    fn = []
    for i in range(len(ious)):
        r = results[i]
        ap.append(r['precision'])
        tp.append(r['tp'])
        fp.append(r['fp'])
        fn.append(r['fn'])

    return (ap, tp, fp, fn)