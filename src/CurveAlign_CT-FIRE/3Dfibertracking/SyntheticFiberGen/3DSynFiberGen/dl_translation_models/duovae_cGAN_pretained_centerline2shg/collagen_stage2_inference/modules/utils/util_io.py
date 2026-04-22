import os
import json
import numpy as np
import torch

def set_all_seeds(seed):
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)

def as_np(x):
    return x.detach().cpu().numpy()

def make_directories(root_dir, sub_dirs):
    sub_dirs_out = {}
    for key in sub_dirs:
        sub_dir = os.path.join(root_dir, key)
        os.makedirs(sub_dir, exist_ok=True)
        sub_dirs_out[key] = sub_dir
    return sub_dirs_out

def load_parameters(param_path, copy_to_dir):
    # load parameters from .json file
    params = json.load(open(param_path, "r"))
    fname = os.path.basename(param_path)

    # keep a record of the parameters for future reference
    if copy_to_dir is not None:
        copy_to_path = os.path.join(copy_to_dir, fname)
        json.dump(params, open(copy_to_path, "w+"), indent=4)
    return params