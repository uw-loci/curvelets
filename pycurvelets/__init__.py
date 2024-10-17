from math import ceil, floor

import matplotlib.pyplot as plt
import numpy as np
from pylops.signalprocessing import FFT2D
from pylops.utils.tapers import taper2d
from scipy.signal import filtfilt

# all code directly copied from Curvelops to test import:
# https://github.com/PyLops/curvelops/blob/main/notebooks/Desmystifying_Curvelets.ipynb
plt.rcParams.update({"image.interpolation": "blackman"})


def generate_monochromatic_2d(
    theta_deg: float = 0,
    nx: int = 101,
    nz: int = 101,
    freq: float = 10,
    taper: bool = False,
):
    x = np.linspace(-1, 1, nx)
    z = np.linspace(-1, 1, nz)
    dx, dz = x[1] - x[0], z[1] - z[0]
    xm, zm = np.meshgrid(x, z, indexing="ij")
    theta = np.deg2rad(theta_deg)
    vec = np.array([np.sin(theta), np.cos(theta)])
    img = np.cos(2 * np.pi * freq * (vec[0] * xm + vec[1] * zm))

    if taper:
        img *= taper2d(*img.shape, [nx // 5 + 1, nz // 5 + 1])
    return img, x, z, vec


nthetas = 6
frequency = 5
thetas = np.linspace(-90, 60, nthetas)

cols = ceil(np.sqrt(nthetas))
rows = ceil(nthetas / cols)
fig, axes = plt.subplots(rows, cols, figsize=(2 * cols, 2 * rows))
for iax, (theta, ax) in enumerate(zip(thetas, axes.ravel())):
    img, x, z, vec = generate_monochromatic_2d(theta, freq=frequency)
    ax.imshow(img.T, vmin=-1, vmax=1, cmap="gray", extent=[x[0], x[-1], z[-1], z[0]])
    ax.set_title(f"{theta:.0f}°")
    ax.annotate(
        f"",
        xy=(vec[0] * 0.5, vec[1] * 0.5),
        xytext=(0, 0),
        arrowprops=dict(edgecolor="r", facecolor="r"),
    )
    if iax == 0 or iax == cols:
        ax.set_ylabel("z\n" + r"$\downarrow$", rotation=0)
    if iax >= cols:
        ax.set_xlabel(r"x $\rightarrow$")
for ax in axes.ravel():
    ax.xaxis.set_ticks([])
    ax.yaxis.set_ticks([])
fig.suptitle(
    "Figure 2. 2D monochromatic images, with direction\nof change in each image denoted by the red arrow."
)
fig.tight_layout()
plt.show()
