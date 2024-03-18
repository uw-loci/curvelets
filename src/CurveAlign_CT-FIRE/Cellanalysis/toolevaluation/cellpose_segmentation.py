from cellpose import io, models

def predict(model_name, input_data_path, **kwargs):
    ''' Uses cellpose models to generate ndarray mask of an image 
    
    Parameters:

    - model_name, a str that represents the name of a pretrained cellpose mode
        Options include:
        * cyto
        * cyto2
        * cyto3
        * ctyo4
        * tissuenet_cp3: tissuenet dataset
        * livecell_cp3: livecell dataset
        * yeast_PhC_cp3: YEAZ dataset
        * yeast_BF_cp3: YEAZ dataset
        * bact_phase_cp3: omnipose dataset
        * bact_fluor_cp3: omnipose dataset
        * deepbacs_cp3: deepbacs dataset
        * cyto2_cp3: cellpose dataset

    - input_data_path, a str that contains the path to an image for segmentation
    - kwargs:
        * channels, a list of size 2 that tells cellpose what channel to segment in and what channel has nuclei
        * diameter, an int that represents cell diameter in pixels

    Returns:
    - masks, an ndarray with each pixel being labeled
    
    '''
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