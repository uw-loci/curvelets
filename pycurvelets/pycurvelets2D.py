from curvelops import FDCT2D, curveshow

import matplotlib.pyplot as plt
import numpy as np

# taken by Demystifying_Curvelets of Curvelops
img = plt.imread(
    "../doc/testImages/CellAnalysis_testImages/FiberImage/2B_D9_ROI1.tif",
    format="TIF",
)
img = img.swapaxes(0, 1)

fig, ax = plt.subplots()
ax.imshow(img.swapaxes(0, 1))
ax.axis("off")

img = img.astype(float)
img /= 255.0
C2D = FDCT2D(img.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False)

img_c = C2D.struct(C2D @ img)

# In our previous example, we considered a "wedge" to be symmetric with respect
# to the origin. The `FDCT2D` does not do this by default. Moreover, it will always
# output each unsymmetrized wedge separately. In this example, `nbangles_coarse = 8`
# really only gives us 4 independent wedges. We will symmetrize them as follows

nx = 101
nz = 101
x = np.linspace(-1, 1, nx)
z = np.linspace(-1, 1, nz)

for iscale in range(len(img_c)):
    if len(img_c[iscale]) == 1:  # Not a curvelet transform
        print(f"Wedges in scale {iscale+1}: {len(img_c[iscale])}")
        continue
    nbangles = len(img_c[iscale])
    for iwedge in range(nbangles // 2):
        img_c[iscale][iwedge] = (
            img_c[iscale][iwedge]  # Wedge
            + img_c[iscale][iwedge + nbangles // 2]  # Symmetric counterpart
        ) / np.sqrt(2)
    img_c[iscale] = img_c[iscale][: nbangles // 2]
    print(f"Wedges in scale {iscale+1}: {len(img_c[iscale])}")


figs_axes = curveshow(
    img_c,
    basesize=3,
    kwargs_imshow=dict(vmin=-1, vmax=1, extent=[x[0], x[-1], z[-1], z[0]]),
)
for c_scale, (fig, axes) in zip(img_c, figs_axes):
    for iwedge, (c_wedge, ax) in enumerate(zip(c_scale, np.atleast_1d(axes).ravel())):
        ax.text(
            0.5,
            0.95,
            f"Shape: {c_wedge.shape}",
            horizontalalignment="center",
            verticalalignment="center",
            transform=ax.transAxes,
        )


plt.show()
