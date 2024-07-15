from cellpose import models, io
import scipy.io as sio

def cyto_seg(img_path,model_name,chan=[0,0]):
    img = io.imread(img_path)
    # model = models.Cellpose(gpu=False, model_type='cyto')
    model = models.Cellpose(gpu=False, model_type = model_name)
    mask, flows, styles, diams = model.eval(img, diameter=None, channels=chan)
    sio.savemat('mask4cells.mat', {'mask4cells':mask})
    return mask
