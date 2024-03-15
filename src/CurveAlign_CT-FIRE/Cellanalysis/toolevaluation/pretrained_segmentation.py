from stardist.models import StarDist2D
from csbdeep.utils import normalize
from stardist.plot import render_label

import numpy as np
import tifffile
from deepcell.applications import NuclearSegmentation, CytoplasmSegmentation, CellTracking
from deepcell.datasets import DynamicNuclearNetSample

import imageio
import matplotlib as mpl
from matplotlib.colors import ListedColormap
import matplotlib.pyplot as plt
import os

from cellpose import models

key = 'POtyuCIN.nWwQ1FXgroiE8zKTWLgf5rdqGRJeKQHf'
os.environ.update({"DEEPCELL_ACCESS_TOKEN": key})