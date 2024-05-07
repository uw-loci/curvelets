import numpy as np
import skimage as ski
from scipy.optimize import linear_sum_assignment

def label_overlap(x, y):
    '''StarDist method'''
    x = x.ravel()
    y = y.ravel()
    overlap = np.zeros((1+x.max(),1+y.max()), dtype=np.uint)
    for i in range(len(x)):
        overlap[x[i],y[i]] += 1
    return overlap

def _safe_divide(x,y, eps=1e-10):
    '''StarDist method'''
    """computes a safe divide which returns 0 if y is zero"""
    if np.isscalar(x) and np.isscalar(y):
        return x/y if np.abs(y)>eps else 0.0
    else:
        out = np.zeros(np.broadcast(x,y).shape, np.float32)
        np.divide(x,y, out=out, where=np.abs(y)>eps)
        return out

def intersection_over_union(overlap):
    '''StarDist method'''
    if np.sum(overlap) == 0:
        return overlap
    n_pixels_pred = np.sum(overlap, axis=0, keepdims=True)
    n_pixels_true = np.sum(overlap, axis=1, keepdims=True)
    return _safe_divide(overlap, (n_pixels_pred + n_pixels_true - overlap))

def single_image(y_true, y_pred, thresh=0.5):
    '''Structure based entirely on StarDist matching()'''
    thresh = float(thresh) if np.isscalar(thresh) else map(float, thresh)

    #TODO: try swapping for stardist's version
    y_true, _, map_rev_true = ski.segmentation.relabel_sequential(y_true)
    y_pred, _, map_rev_pred = ski.segmentation.relabel_sequential(y_pred)

    overlap = label_overlap(y_true, y_pred)
    scores = intersection_over_union(overlap)[1:, 1:]
    n_true, n_pred = scores.shape
    n_matched = min(n_true, n_pred)

    not_trivial = n_matched > 0
    if not_trivial:
        costs = -(scores >= thresh).astype(float) - scores / (2 * n_matched)
        true_ind, pred_ind = linear_sum_assignment(costs)
        assert n_matched == len(true_ind) == len(pred_ind)
        match_ok = scores[true_ind,pred_ind] >= thresh
        tp = np.count_nonzero(match_ok)
    else:
        tp = 0
    fp = n_pred - tp
    fn = n_true - tp
    ap = tp/(tp+fp) if tp > 0 else 0

    stats = {'precision' : ap, 
             'tp' : tp, 
             'fp' : fp, 
             'fn' : fn, 
             'n_pred' : n_pred, 
             'n_true' : n_true
            }

    return stats


def get_metrics(y_true, y_pred, thresh=0.5):
    stats_all = tuple(single_image(y_t, y_p, thresh) for y_t, y_p in zip(y_true, y_pred))
    n_images = len(stats_all)

    acc = {}
    for stats in stats_all:
        for k, v in stats.items():
            acc[k] = acc.setdefault(k, 0) + v

    acc[k] /= n_images

    return acc
