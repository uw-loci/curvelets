import numpy as np
import os

import pycurvelets.fdct2d_wrapper as fdct2d

if __name__ == "__main__":
    check = fdct2d.fdct2d_param_wrap(1, 2, 4, 8, 0)
