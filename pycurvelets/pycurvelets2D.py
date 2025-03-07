from curvelops import FDCT2D, curveshow

import matplotlib.pyplot as plt
import numpy as np

img = plt.imread(
    "../doc/testImages/CellAnalysis_testImages/3dImage_fire/s5part1__cmle000.tif",
    format="TIF",
)

# parameters needed: keep, sscale, radius

# -------------------------- 1) perform 2d forward discrete curvelet transform ---------------------------------------
C2D = FDCT2D(img.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False)

# coefficient mat
img_c = C2D.struct(C2D @ img)
shape = (len(img_c), len(img_c[0]), img_c[0][0].size)
empty_c = np.zeros(shape)
print(empty_c)

# --------------- 2) selects scale at which coefficients will be used (scale of interest) ----------------------------
scale = len(img_c) - sscale 

# scale coefficients to remove artifacts ****CURRENTLY ONLY FOR 1024x1024 
tempA = [1, .64, .52, .5, .46, .4, .35, .3]


# ------------------- 3) choose threshold the remaining coeffs based on user-defined threshold -----------------------

# ------------ 4) find center and spatial orientation of each curvelet corresponding to remaining coeffs -------------

# ------------- 5) group adjacent curvelets within given radius to estimate local fiber orientations -----------------

# ------------- 6) perform application-specific analytics using measured angles and locations ------------------------