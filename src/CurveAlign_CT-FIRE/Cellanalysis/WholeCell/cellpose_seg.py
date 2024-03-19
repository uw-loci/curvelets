from cellpose import models, io
import scipy.io as sio

def cyto_seg(img_path,chan=[0,0]):
    img = io.imread(img_path)
    model = models.Cellpose(gpu=False, model_type='cyto')
    mask, flows, styles, diams = model.eval(img, diameter=None, channels=chan)
    sio.savemat('mask4cells.mat', {'mask4cells':mask})
    return mask
