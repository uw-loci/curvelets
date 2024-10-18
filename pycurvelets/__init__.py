from curvelops import FDCT2D, curveshow

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

# taken by Demystifying_Curvelets of Curvelops
img = plt.imread(
    "../doc/testImages/CellAnalysis_testImages/CellImage/2B_D9_ROI1.tif", format="TIF"
)
img = img.swapaxes(0, 1)

fig, ax = plt.subplots()
ax.imshow(img.swapaxes(0, 1))
ax.axis("off")

img = img.astype(float)
img /= 255.0
C2D = FDCT2D(img.shape[:-1], nbscales=4, nbangles_coarse=8, allcurvelets=False)

logo_r = C2D.struct(C2D @ img[..., 0])
logo_g = C2D.struct(C2D @ img[..., 1])
logo_b = C2D.struct(C2D @ img[..., 2])

logo_c = [[] for _ in logo_r]
for iscale, c_angles in enumerate(logo_r):
    logo_c[iscale] = []
    for iwedge, c_wedge in enumerate(c_angles):
        wedges = [
            c[iscale][iwedge][..., np.newaxis].real for c in [logo_r, logo_g, logo_b]
        ]
        out = np.concatenate(wedges, axis=-1)
        out *= np.sqrt(logo_r[iscale][iwedge].size / img[..., 0].size)

        out = (out - out.min()) / (out.max() - out.min())
        logo_c[iscale].append(out)

fig_axes = curveshow(logo_c, kwargs_imshow=dict(extent=[0, 1, 1, 0]))

plt.show()
