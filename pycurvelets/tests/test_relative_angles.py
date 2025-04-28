import sys
import os

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), "../relativeAngle"))
)

from get_relative_angles import get_relative_angles, load_coords
import numpy as np
import os


def test_load_coords_1():
    """
    Tests the functions of load_coords, where given a CSV file with (Y, X) columns,
    it should parse it and return a Numpy array in the form of (Y, X).
    """
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "sample_coords.csv",
    )
    result = load_coords(csv_path)
    expected = np.array([[143.0, 205.0], [143.0, 206.0], [142.0, 206.0]])

    # this line checks to see if the two np arrays are close, allowing for small rounding error
    assert np.allclose(result, expected)


def test_load_coords_2():
    """
    Tests the functions of load_coords but with a more complex csv file,
    where given a CSV file with (Y, X) columns, it should parse it and return a
    Numpy array in the form of (Y, X). **ONLY CHECKS FIRST 25 ROWS**
    """
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    result = load_coords(csv_path)
    expected = np.array(
        [
            [143, 205],
            [143, 206],
            [142, 206],
            [141, 206],
            [140, 206],
            [139, 206],
            [138, 206],
            [137, 206],
            [136, 206],
            [135, 206],
            [134, 206],
            [134, 207],
            [133, 207],
            [132, 207],
            [131, 207],
            [130, 207],
            [130, 208],
            [129, 208],
            [128, 208],
            [127, 208],
            [127, 209],
            [126, 209],
            [125, 209],
            [124, 209],
            [124, 210],
        ]
    )

    # this line checks to see if the two np arrays are close, allowing for small rounding error
    assert np.allclose(result[:25], expected)


def test_relative_angles_1():
    """
    Tests the functions of get_relative_angles given the values from boundary_coords.csv
    and real1_BoundaryMeasurements.xlsx. The index2object value was identified by finding
    the row the boundary center coordinate found in boundary_coords.csv.

    This is for fiber coordinate [145, 430].

    Specifically, tests angle2BoundaryEdge, angle2BoundaryCenter, and angle2CentersLine,
    with an allowed margin of error of 0.5 degrees.
    """

    error_margin = 0.5
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    coords = load_coords(csv_path)

    ROI = {
        "coords": coords,
        "imageWidth": 512,
        "imageHeight": 512,
        "index2object": 403,
    }

    object_data = {"center": [145, 430], "angle": 14.0625}

    angles, measurements = get_relative_angles(
        ROI, object_data, angle_option=0, fig_flag=False
    )

    assert abs(angles["angle2boundaryEdge"] - 89.6518396) < error_margin
    assert abs(angles["angle2boundaryCenter"] - 87.5376978) < error_margin
    assert abs(angles["angle2centersLine"] - 26.4437817) < error_margin


def test_relative_angles_2():
    """
    Tests the functions of get_relative_angles given the values from boundary_coords.csv
    and real1_BoundaryMeasurements.xlsx. The index2object value was identified by finding
    the row the boundary center coordinate found in boundary_coords.csv.

    This is for fiber coordinate [94, 473].

    Specifically, tests angle2BoundaryEdge, angle2BoundaryCenter, and angle2CentersLine,
    with an allowed margin of error of 0.5 degrees.
    """

    error_margin = 0.5
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    coords = load_coords(csv_path)

    ROI = {
        "coords": coords,
        "imageWidth": 512,
        "imageHeight": 512,
        "index2object": 390,
    }

    object_data = {"center": [94, 473], "angle": 75.9375}

    angles, measurements = get_relative_angles(
        ROI, object_data, angle_option=0, fig_flag=False
    )

    assert abs(angles["angle2boundaryEdge"] - 78.26128691) < error_margin
    assert abs(angles["angle2boundaryCenter"] - 25.66269783) < error_margin
    assert abs(angles["angle2centersLine"] - 32.81649075) < error_margin


def test_relative_angles_3():
    """
    Tests the functions of get_relative_angles given the values from boundary_coords.csv
    and real1_BoundaryMeasurements.xlsx. The index2object value was identified by finding
    the row the boundary center coordinate found in boundary_coords.csv.

    This is for fiber coordinate [161, 455].

    Specifically, tests angle2BoundaryEdge, angle2BoundaryCenter, and angle2CentersLine,
    with an allowed margin of error of 0.5 degrees.
    """

    error_margin = 0.5
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    coords = load_coords(csv_path)

    ROI = {
        "coords": coords,
        "imageWidth": 512,
        "imageHeight": 512,
        "index2object": 425,
    }

    object_data = {"center": [167, 414], "angle": 2.8125}

    angles, measurements = get_relative_angles(
        ROI, object_data, angle_option=0, fig_flag=False
    )

    assert abs(angles["angle2boundaryEdge"] - 81.65541942) < error_margin
    assert abs(angles["angle2boundaryCenter"] - 81.21230217) < error_margin

    # CAUTION: in this specific case for some reason: MATLAB OUTPUT does NOT match
    # the output in real1_BoundaryMeasurements.xlsx; used MATLAB output instead.
    assert abs(angles["angle2centersLine"] - 35.1965) < error_margin


def test_relative_angles_4():
    """
    Tests the functions of get_relative_angles given the values from boundary_coords.csv
    and real1_BoundaryMeasurements.xlsx. The index2object value was identified by finding
    the row the boundary center coordinate found in boundary_coords.csv.

    This is for fiber coordinate [72, 249].

    Specifically, tests angle2BoundaryEdge, angle2BoundaryCenter, and angle2CentersLine,
    with an allowed margin of error of 0.5 degrees.
    """

    error_margin = 0.5
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    coords = load_coords(csv_path)

    ROI = {
        "coords": coords,
        "imageWidth": 512,
        "imageHeight": 512,
        "index2object": 65,
    }

    object_data = {"center": [72, 249], "angle": 105.6696429}

    angles, measurements = get_relative_angles(
        ROI, object_data, angle_option=0, fig_flag=False
    )

    assert abs(angles["angle2boundaryEdge"] - 65.29739494) < error_margin
    assert abs(angles["angle2boundaryCenter"] - 4.069445028) < error_margin
    assert abs(angles["angle2centersLine"] - 0.379993927) < error_margin


def test_relative_angles_5():
    """
    Tests the functions of get_relative_angles given the values from boundary_coords.csv
    and real1_BoundaryMeasurements.xlsx. The index2object value was identified by finding
    the row the boundary center coordinate found in boundary_coords.csv.

    This is for fiber coordinate [394, 221].

    Specifically, tests angle2BoundaryEdge, angle2BoundaryCenter, and angle2CentersLine,
    with an allowed margin of error of 0.5 degrees.
    """

    error_margin = 0.5
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    coords = load_coords(csv_path)

    ROI = {
        "coords": coords,
        "imageWidth": 512,
        "imageHeight": 512,
        "index2object": 834,
    }

    object_data = {"center": [394, 221], "angle": 95.15625}

    angles, measurements = get_relative_angles(
        ROI, object_data, angle_option=0, fig_flag=False
    )

    assert abs(angles["angle2boundaryEdge"] - 35.48753723) < error_margin
    assert abs(angles["angle2boundaryCenter"] - 6.44394783) < error_margin
    assert abs(angles["angle2centersLine"] - 34.86673667) < error_margin


def test_relative_angles_6():
    """
    Tests the functions of get_relative_angles given the values from boundary_coords.csv
    and real1_BoundaryMeasurements.xlsx. The index2object value was identified by finding
    the row the boundary center coordinate found in boundary_coords.csv.

    This is for fiber coordinate [420, 197].

    Specifically, tests angle2BoundaryEdge, angle2BoundaryCenter, and angle2CentersLine,
    with an allowed margin of error of 0.5 degrees.
    """

    error_margin = 0.5
    csv_path = os.path.join(
        os.path.dirname(__file__),
        "testResults",
        "relative_angle_test_files",
        "boundary_coords.csv",
    )
    coords = load_coords(csv_path)

    ROI = {
        "coords": coords,
        "imageWidth": 512,
        "imageHeight": 512,
        "index2object": 834,
    }

    object_data = {"center": [420, 197], "angle": 92.8125}

    angles, measurements = get_relative_angles(
        ROI, object_data, angle_option=0, fig_flag=False
    )

    assert abs(angles["angle2boundaryEdge"] - 37.83128723) < error_margin
    assert abs(angles["angle2boundaryCenter"] - 8.78769783) < error_margin
    assert abs(angles["angle2centersLine"] - 34.88740348) < error_margin
