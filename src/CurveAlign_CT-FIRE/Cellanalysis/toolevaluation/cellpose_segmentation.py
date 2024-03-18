from cellpose import io, models

def predict(model_name, input_data_path, **kwargs):
    model = None
    if model_name != 'cyto' or model_name != 'cyto2' or model_name != 'cyto3' or model_name != 'nuclei':
        model = models.CellposeModel(model_type=model_name)
    else:
        model = models.Cellpose(model_type=model_name)

    image = io.imread(input_data_path)
    if len(image.shape) != 3:
        Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (Y,X,C) or (C,Y,X)")

    # if image.shape[0] > 2 and image.shape[2] > 2:
    #     Exception(f"Image is of shape: {image.shape} when Cellpose is expecting (Y,X,C) or (C,Y,X)")
    chan = [0,0]
    if 'channels' in kwargs:
        chan= kwargs['channels']

    diam = None
    if 'diameter' in kwargs:
        diam = kwargs['diameter']

    masks, *_ = model.eval(image, channels=chan, diameter=diam)

    return masks