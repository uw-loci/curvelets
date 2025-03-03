import os
import numpy as np
import cv2
import plotly.graph_objects as go
import matplotlib.pyplot as plt
from mayavi import mlab
from curvelops import FDCT3D  

def find_angles(scale, wedge):
    '''
    This follows the 3D Discrete Curvelet Transform paper written by Ying, et al. 
    The documentation states that for each wedge, the polar and azimuthal angle can be identified through the following formulas:

    polar: 2 ^ (-scale / 2)
    azimuthal: wedge * 2 ^ (-scale / 2)
    
    Parameters:
    - scale: the current scale we want to find the angle for
    - wedge: the wedge index we want to find the angle for
    '''
    # this angle is from the z-axis
    polar_angle = 2 ** (-int(scale) / 2)

    # this angle is from the xy-plane
    azimuthal_angle = wedge * 2 ** (-int(scale) / 2) 
    
    return polar_angle, azimuthal_angle

def compute_average_magnitudes(X, s):
    # Compute the average magnitude of coefficients for each wedge at scale s
    average_magnitudes = []
    for w in range(len(X[s])):
        coefficients_3d = np.abs(np.stack(X[s][w], axis=0))
        average_magnitude = np.mean(coefficients_3d)
        average_magnitudes.append(average_magnitude)
    return average_magnitudes

def get_significant_wedges(average_magnitudes, top_percentile=1):
    # Sort wedges by average magnitude in descending order
    sorted_wedges = np.argsort(average_magnitudes)[::-1]

    # Get the top `top_percentile` wedges
    num_top_wedges = int(top_percentile / 100 * len(average_magnitudes))
    significant_wedges = sorted_wedges[:num_top_wedges]
    return significant_wedges

def compute_direction_vectors(significant_wedges, X, s):
    # Compute direction vectors and spatial locations for significant wedges
    spatial_locations = []
    direction_vectors = []

    for w in significant_wedges:
        coefficients_3d = np.abs(np.stack(X[s][w], axis=0))

        # Compute a dynamic threshold (e.g., 99.99th percentile)
        threshold = np.percentile(coefficients_3d, 99.99)

        # Find spatial locations where coefficients exceed the threshold
        k1, k2, k3 = np.where(coefficients_3d > threshold)

        # Compute the direction vector for this wedge
        polar, azimuth = find_angles(s, w)
        x = np.sin(polar) * np.cos(azimuth)
        y = np.sin(polar) * np.sin(azimuth)
        z = np.cos(polar)
        d = np.array([x, y, z])

        # Append spatial locations and direction vectors
        for i in range(len(k1)):
            spatial_locations.append((k1[i], k2[i], k3[i]))
            direction_vectors.append(d)

    return spatial_locations, direction_vectors

def plot_orientations(spatial_locations, direction_vectors):
    # Create a 3D quiver plot using Plotly
    fig = go.Figure()

    # Plot the direction vectors at their spatial locations
    for loc, vec in zip(spatial_locations, direction_vectors):
        k1, k2, k3 = loc
        x, y, z = vec
        fig.add_trace(go.Cone(
            x=[k1], y=[k2], z=[k3],  # Spatial locations
            u=[x], v=[y], w=[z],  # Direction vectors
            colorscale='Blues',  # Color scale for the cones
            sizemode="absolute",  # Scale cones absolutely
            sizeref=10,  # Scale factor for the cones
            anchor="tail"  # Cones start at the spatial locations
        ))

    # Set axis labels and title
    fig.update_layout(
        scene=dict(
            xaxis_title='X (k1)',
            yaxis_title='Y (k2)',
            zaxis_title='Z (k3)',
        ),
        title="Orientations at Spatial Locations"
    )

    # Show the plot
    fig.show()

def create_3d_curvelet(folder_path, num_images, nb_scales, nb_angles):
    '''
    This function takes a set of collagen fiber images and visualizes them in the 3D space
    after doing the forward and inverse Fourier transform on the images. Both the original
    and reconstructed data are portrayed through Mayavi, a 3D viewer.

    Parameters:
    - folder_path: the folder path (can be relative or absolute) that consists of the images that
    will be used to visualize the images
    - num_images: the number of images that is requested to be visualized under the Mayavi 3D
    viewer. Must be less than or equal to the actual number of images within folder_path directory
    - nb_scales: the number of scales for which FDCT3D should be processed under
    - nb_angles: the number of angles for which FDCT3D should be processed under
    '''
    print(" ")
    print("Python 3D Curvelet Transform Demonstration")
    print(" ")
    print("The curvelet is created by setting coefficients to zero except at a specific location.")
    print("Notice how the curvelet is sharply localized in both space and frequency.")
    print(" ")
    print("The curvelet is at the 4th scale. Its energy in the frequency domain")
    print("is concentrated in the direction of (x,y,z)=(1,-1,-1).")
    print("In the spatial domain, it looks like a disc with normal direction (1,-1,-1).")
    print("The curvelet oscillates in the normal direction.")
    print(" ")
    print(" ")

    # It is expected that all images are in a TIFF file
    img_files = [f for f in os.listdir(folder_path) if f.endswith(".tif")]
    first_img = cv2.imread(os.path.join(folder_path, img_files[0]), cv2.IMREAD_GRAYSCALE)

    # Identify dimensions of the images
    nx, ny = first_img.shape
    nz = num_images

    # Create 3D image stack
    img_stack = np.zeros((nz, nx, ny), dtype=first_img.dtype)
    for i, file_name in enumerate(img_files[:num_images]):
        img_path = os.path.join(folder_path, file_name)
        image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
        img_stack[i, :, :] = image

    # Create 3D Curvelet Transform data structure
    C3D = FDCT3D(dims=img_stack.shape, nbscales=nb_scales, nbangles_coarse=nb_angles, allcurvelets=False)

    # Forward transform
    img_stack_complex = img_stack.astype(np.complex128)
    X = C3D.fdct(4, 8, 0, img_stack_complex)  # Corrected call

    # Modify a specific curvelet coefficient
    s = 2  # scale

    X_modified = [coeff.copy() for coeff in X]  

    m, n, p = img_stack.shape

    # Inverse transform
    Y = C3D.ifdct(m, n, p, 4, 8, 0, X_modified)  

    # Step 1: Compute average magnitudes for each wedge
    average_magnitudes = compute_average_magnitudes(X, s)

    # Step 2: Identify significant wedges (top 1%)
    significant_wedges = get_significant_wedges(average_magnitudes, top_percentile=1)

    # Print results
    print("Significant wedges:", significant_wedges)
    print("Number of significant wedges:", len(significant_wedges))

    # Step 3: Compute direction vectors and spatial locations
    spatial_locations, direction_vectors = compute_direction_vectors(significant_wedges, X, s)

    # Step 4: Plot the orientations
    plot_orientations(spatial_locations, direction_vectors)

    # Create a 3D plot using Matplotlib
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')

    # Plot the direction vectors at their spatial locations
    for loc, vec in zip(spatial_locations, direction_vectors):
        ax.quiver(loc[0], loc[1], loc[2], vec[0], vec[1], vec[2], color='r', length=0.4)

    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    ax.set_title(f'Orientations at Spatial Locations (Scale {s})')

    img_stack_transposed = np.transpose(img_stack, (1, 2, 0)) 
    Y_transposed = np.transpose(np.abs(Y), (1, 2, 0))

    plt.show()

    # Reconstructed data plot using Mayavi
    x_data, y_data, z_data = np.mgrid[:nx, :ny, :nz]

    mlab.figure("Reconstructed Data")
    mlab.contour3d(x_data, y_data, z_data, Y_transposed, contours=10, opacity=0.5)
    mlab.axes()
    mlab.outline()
    mlab.title("Reconstructed Data")

    mlab.show()

# Run 3D curvelet transform on image
create_3d_curvelet("../doc/testImages/CellAnalysis_testImages/3dImage_simple", 100, 4, 8)