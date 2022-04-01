from cellpose import models, io
import scipy.io as sio

def cyto_seg(img_path,chan=[0,0]):
    img = io.imread(img_path)
    model = models.Cellpose(gpu=False, model_type='cyto')
    masks, flows, styles, diams = model.eval(img, diameter=None, channels=chan)
    sio.savemat('masks.mat', {'masks':masks})
    return masks
