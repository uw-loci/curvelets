import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from new_curv import new_curv
import matplotlib.pyplot as plt
import scipy.io
import numpy as np
import os

"""
None of these pytest functions accurately test new_curv -- it only tests the inc value,
which is easily manipulatable. Need to identify how to get the solution matrix and compare it
with a resultant np array. In addition, it is identified that the new_curv.py erroneously
creates more coordinates than the MATLAB function, so the reason must be explored.
"""


def test_new_curv_1():
    """
    Test function of test image -- real1.tif
    """
    img = plt.imread(
        os.path.join(os.path.dirname(__file__), "testImages", "real1.tif"),
        format="TIF",
    )

    mat_data = scipy.io.loadmat("testResults/test_new_curvs_1.mat")
    mat = mat_data["mat"]

    in_curves, ct, inc = new_curv(img, {"keep": 0.01, "scale": 1, "radius": 3})
    in_curves_converted = np.array(
        [(d["center"], d["angle"]) for d in in_curves],
        dtype=[("center", "O"), ("angle", "O")],
    )

    assert inc == 5.625
    # assert np.allclose(in_curves_converted["center"], mat["center"])
    # assert np.allclose(in_curves_converted["angle"], mat["angle"])


def test_new_curv_2():
    """
    Test function of test image -- syn1.tif
    """
    img = plt.imread(
        os.path.join(os.path.dirname(__file__), "testImages", "syn1.tif"),
        format="TIF",
    )

    in_curves, ct, inc = new_curv(img, {"keep": 0.1, "scale": 2, "radius": 5})

    assert inc == 11.25
    # assert ct


def test_new_curv_3():
    """
    Test function of test image -- syn2.tif
    """
    img = plt.imread(
        "testImages/syn2.tif",
        format="TIF",
    )

    in_curves, ct, inc = new_curv(img, {"keep": 0.01, "scale": 1, "radius": 3})

    assert inc == 5.625
