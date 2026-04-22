import os
import shutil
import numpy as np
import torch
import torch.nn as nn
import torch.distributions as dist
from modules.utils.util_io import as_np
from modules.utils.logger import Logger, LogLevel

class View(nn.Module):
    def __init__(self, shape):
        super(View, self).__init__()
        self.shape = shape

    def forward(self, x):
        return x.view(*self.shape)

def get_available_devices(rank):
    """
    - loads whichever available GPU/CPU (single worker).
    """
    gpu_ids = []
    device = "cpu"
    if torch.cuda.is_available():
        print("CUDA is available")
        torch.cuda.empty_cache()
        n_gpu = torch.cuda.device_count()
        
        gpu_ids = [i for i in range(n_gpu)]
        device = torch.device(f"cuda:{rank}")
    else:
        """
        support for arm64 MacOS
        https://pytorch.org/blog/introducing-accelerated-pytorch-training-on-mac/
        """
        # this ensures that the current MacOS version is at least 12.3+
        print("CUDA is not available")
        if torch.backends.mps.is_available():
            print("Apple silicon (arm64) is available")
            # this ensures that the current PyTorch installation was built with MPS activated.
            device = "cpu" # discovered using MPS sometimes gives NaN loss - safer not to use it until future updates
            # device = "mps:0"
            gpu_ids.append(0) # (2022) There is no multi-MPS Apple device, yet
            if not torch.backends.mps.is_built():
                print("Current PyTorch installation was not built with MPS activated. Using cpu instead.")
                device = "cpu"

    return device, gpu_ids

def save_model(save_dir, model, device, world_size):
    for model_name in model.model_names:
        save_path = os.path.join(save_dir, "{}.pt".format(model_name))

        net = getattr(model, model_name)
        if world_size == 1:
            torch.save(net.cpu().state_dict(), save_path)
            net.to(model.device)
        elif world_size > 1:
            torch.save(net.cpu().state_dict(), save_path)
            net.to(device)
        else:
            torch.save(net.cpu().state_dict(), save_path)
    return save_dir

def load_model(model, load_dir, world_size, logger):
    try:
        model = model.module
    except:
        pass

    for model_name in model.model_names:
        load_path = os.path.join(load_dir, "{}.pt".format(model_name))
        net = getattr(model, model_name)    
        try:
            state_dict = torch.load(load_path, map_location=str(model.device))
            net.load_state_dict(state_dict, strict=False)
            if logger is not None:
                logger.print("loading model: {}".format(load_path))
                logger.print("  model={} loaded succesfully!".format(model_name))
            else:
                print("loading model: {}".format(load_path))
                print("  model={} loaded succesfully!".format(model_name))

        except Exception as e:
            if logger is not None:
                logger.print("failed to load {} - architecture mismatch! Initializing new instead: {}".format(load_path, model_name), LogLevel.WARNING.name)
            else:
                print("failed to load {} - architecture mismatch! Initializing new instead: {}".format(load_path, model_name), LogLevel.WARNING.name)

def get_losses(model):
    losses = {}
    for name in model.loss_names:
        losses[name] = getattr(model, "loss_{}".format(name))
    return losses
