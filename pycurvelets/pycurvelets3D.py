# import numpy as np
# import matplotlib
# import matplotlib.pyplot as plt
# from mpl_toolkits.mplot3d import Axes3D
# from mayavi import mlab
# import plotly.graph_objects as go
# import napari
# from curvelops import FDCT3D
# import cv2
# import os
# import sys
# import time
# import math

# def create_3d_curvelet(folder_path, num_images, nb_scales, nb_angles):
#     '''
#     This function takes a set of collagen fiber images and visualizes them in the 3D space
#     after doing the forward and inverse fourier transform on the images. Both the original
#     and reconstructed data are portrayed through Mayavi, a 3D viewer.

#     Parameters:

#     - folder_path: the folder path (can be relative or absolute) that consists of the images that
#     will be used to visualize the images
#     - num_images: the number of images that is requested to be visualized under the Mayavi 3D
#     viewer. Must be less than or equal to the actual number of images within folder_path directory
#     - nb_scales: the number of scales for which FDCT3D should be processed under
#     - nb_angles: the number of angles for which FDCT3D should be processed under
#     '''
#     print(" ")
#     print("Python 3D Curvelet Transform Demonstration")
#     print(" ")
#     print(
#         "The curvelet is created by setting coefficients to zero except at a specific location."
#     )
#     print("Notice how the curvelet is sharply localized in both space and frequency.")
#     print(" ")
#     print("The curvelet is at the 4th scale. Its energy in the frequency domain")
#     print("is concentrated in the direction of (x,y,z)=(1,-1,-1).")
#     print(
#         "In the spatial domain, it looks like a disc with normal direction (1,-1,-1)."
#     )
#     print("The curvelet oscillates in the normal direction.")
#     print(" ")
#     print(" ")

#     # It is expected that all images are in a TIFF file
#     img_files = [f for f in os.listdir(folder_path) if f.endswith(".tif")]
#     first_img = cv2.imread(os.path.join(folder_path, img_files[0]), cv2.IMREAD_GRAYSCALE)

#     # Identify dimensions of the images
#     nx, ny = first_img.shape
#     nz = num_images

#     # Create 3D image stack
#     img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
#     for i, file_name in enumerate(img_files[:num_images]):
#         img_path = os.path.join(folder_path, file_name)
#         image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
#         img_stack[i, :, :] = image

#     # Create 3D Curvelet Transform data structure
#     C3D = FDCT3D(dims=img_stack.shape, nbscales=nb_scales, nbangles_coarse=nb_angles, allcurvelets=False)

#     # Forward transform
#     img_stack_complex = img_stack.astype(np.complex128)
#     X = C3D.fdct(4, 8, 0, img_stack_complex)  # Corrected call

#     # Modify a specific curvelet coefficient
#     s = 2  # scale
#     w = 3  # wedge (must be valid for the given scale)

#     X_modified = [coeff.copy() for coeff in X]  

#     if s < len(X_modified) and w < len(X_modified[s]):
#         coefficients = X_modified[s][w]
#         t1, t2, t3 = coefficients.shape

#         # Calculate indices relative to the array size
#         t1 = t1 // 2  # Middle index along the first dimension
#         t2 = t2 // 2  # Middle index along the second dimension
#         t3 = t3 // 2  # Middle index along the third dimension

#         # Ensure indices are within bounds
#         if t1 < coefficients.shape[0] and t2 < coefficients.shape[1] and t3 < coefficients.shape[2]:
#             coefficients[t1, t2, t3] = 1  # Modify the coefficient
#             X_modified[s][w] = coefficients
#         else:
#             print(f"Indices out of bounds for scale {s}, wedge {w}")
#     else:
#         print(f"Invalid scale {s} or wedge {w}")

#     m, n, p = img_stack.shape

#     # Inverse transform
#     Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)  

#     # Create a grid for the 3D plot
#     x, y, z = np.mgrid[:nx, :ny, :nz]

#     img_stack_transposed = np.transpose(img_stack, (1, 2, 0)) 
#     Y_transposed = np.transpose(np.abs(Y),(1,2,0))

#     # Visualize the original and reconstructed data in 3D
#     mlab.figure("Original Data")
#     mlab.contour3d(x, y, z, img_stack_transposed, contours=10, opacity=0.5)
#     mlab.axes()
#     mlab.outline()
#     mlab.title("Original Data")

#     mlab.figure("Reconstructed Data")
#     mlab.contour3d(x, y, z, Y_transposed, contours=10, opacity=0.5)
#     mlab.axes()
#     mlab.outline()
#     mlab.title("Reconstructed Data")

#     mlab.show()

# # Run 3D curvelet transform on image
# create_3d_curvelet( "../doc/testImages/CellAnalysis_testImages/3dImage_simple", 128, 4, 8)



import os
import cv2
from mayavi import mlab
from curvelops import FDCT3D
import numpy as np
import napari
from scipy.ndimage import gaussian_filter, zoom

def create_3d_curvelet(folder_path, num_images, nb_scales, nb_angles):
    '''
    This function takes a set of collagen fiber images and visualizes them in the 3D space
    after performing the forward and inverse curvelet transform on the images. Both the original
    and reconstructed data are visualized using Mayavi. Additionally, it allows interactive
    ROI selection using napari to extract specific scales and wedges corresponding to the ROI.

    Parameters:
    - folder_path: Path to the folder containing the images (TIFF format).
    - num_images: Number of images to process (must be <= number of images in the folder).
    - nb_scales: Number of scales for the 3D Curvelet Transform.
    - nb_angles: Number of angles for the 3D Curvelet Transform.
    '''
    print("Python 3D Curvelet Transform Demonstration")
    print("The curvelet is created by setting coefficients to zero except at a specific location.")
    print("Notice how the curvelet is sharply localized in both space and frequency.")

    # Load images
    img_files = [f for f in os.listdir(folder_path) if f.endswith(".tif")]
    first_img = cv2.imread(os.path.join(folder_path, img_files[0]), cv2.IMREAD_GRAYSCALE)
    nx, ny = first_img.shape
    nz = num_images

    # Create 3D image stack
    img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
    for i, file_name in enumerate(img_files[:num_images]):
        img_path = os.path.join(folder_path, file_name)
        image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        img_stack[i, :, :] = image

    # Perform 3D Curvelet Transform
    C3D = FDCT3D(dims=img_stack.shape, nbscales=nb_scales, nbangles_coarse=nb_angles, allcurvelets=False)
    img_stack_complex = img_stack.astype(np.complex128)
    X = C3D.fdct(nb_scales, nb_angles, 0, img_stack_complex)

    # Inverse transform to get reconstructed data
    Y = C3D.ifdct(nx, ny, nz, nb_scales, nb_angles, 0, X)

    # Transpose data for visualization
    img_stack_transposed = np.transpose(img_stack, (1, 2, 0))
    Y_transposed = np.transpose(np.abs(Y), (1, 2, 0))

    # Visualize reconstructed data using Napari
    viewer = napari.Viewer()
    viewer.add_image(Y_transposed, name='Reconstructed Data')

    # Extract orientation information
    # orientations = []

    # for scale in range(nb_scales):
    #     for wedge_index in range(len(X[scale])):
    #         # Extract coefficients for this scale and angle
    #         coeffs = X[scale][wedge_index]
    #         magnitude = np.abs(coeffs)

    #         zoom_factors = (
    #             Y_transposed.shape[0] / magnitude.shape[0],
    #             Y_transposed.shape[1] / magnitude.shape[1],
    #             Y_transposed.shape[2] / magnitude.shape[2]
    #         )
    #         magnitude_resized = zoom(magnitude, zoom_factors, order=1)  

    #          # Map wedge index to 3D orientation
    #         theta = np.pi * (wedge_index // nb_angles) / nb_angles
    #         phi = 2 * np.pi * (wedge_index % nb_angles) / nb_angles

    #         x = np.sin(theta) * np.cos(phi)
    #         y = np.sin(theta) * np.sin(phi)
    #         z = np.cos(theta)

    #         spherical_coords = np.array([x,y,z])

    #         # Append orientation vector for each voxel
    #         for index in np.ndindex(magnitude_resized.shape):
    #             if magnitude_resized[index] > 0:  # Only consider significant coefficients
    #                 orientations.append(spherical_coords)

    #     # Convert orientations to a numpy array
    # orientations = np.array(orientations)

    # # Compute mean orientation
    # mean_orientation = np.mean(orientations, axis=0)    

    # # Compute anisotropy (fractional anisotropy)
    # if len(orientations) > 1:
    #     covariance_matrix = np.cov(orientations, rowvar=False)
    #     eigenvalues = np.linalg.eigvals(covariance_matrix)
    #     anisotropy = np.sqrt(np.var(eigenvalues)) / np.mean(eigenvalues)
    # else:
    #     anisotropy = 0.0

    # # Compute orientation histogram
    # orientation_histogram, _ = np.histogramdd(orientations, bins=10, range=[(-1, 1), (-1, 1), (-1, 1)])

    # return orientations, mean_orientation, anisotropy, orientation_histogram
    # Add orientation map to Napari viewer
    # viewer.add_image(orientation_map, name='Orientation Map')

    napari.run()



def map_wedge_to_orientation(wedge_index, nb_angles):
    """
    Map a wedge index to a 3D orientation (spherical coordinates).

    Parameters:
    - wedge_index: Index of the wedge.
    - nb_angles: Number of angles (wedges).

    Returns:
    - theta: Polar angle (0 to pi).
    - phi: Azimuthal angle (0 to 2pi).
    """
    # Example: Uniform distribution of wedges in 3D space
    theta = np.pi * (wedge_index // nb_angles) / nb_angles
    phi = 2 * np.pi * (wedge_index % nb_angles) / nb_angles
    return theta, phi

def spherical_to_cartesian(theta, phi):
    """
    Convert spherical coordinates to Cartesian coordinates.

    Parameters:
    - theta: Polar angle (0 to pi).
    - phi: Azimuthal angle (0 to 2pi).

    Returns:
    - x, y, z: Cartesian coordinates.
    """
    x = np.sin(theta) * np.cos(phi)
    y = np.sin(theta) * np.sin(phi)
    z = np.cos(theta)
    return np.array([x, y, z])  



# Run the function
create_3d_curvelet("../doc/testImages/CellAnalysis_testImages/3dImage_simple", 4, 4, 8)