The TumorTrace program is an automated image analysis tool, developed in
MATLAB (The Mathworks, Inc., Natick, MA), for examining the ECM
surrounding cells or tumors in the context of cellular morphology,
protein expression and movement. It takes as input multiple image
channels, either single images or stacks representing time-series or 3D
data. It then finds a metric for the cell/cell cluster morphology and
outputs plots representing intensity, morphology, collagen fiber
alignment, and cell movement; .csv files containing raw data and image
files containing the regions of interest.

Up to 5 images or image stacks may be uploaded via the GUI, at which
point the user is able to assign a particular measurement to that
image/stack (Morphology, Inner Intensity, Outer Intensity, Outline
Intensity, or Alignment). The first measurement selected must always be
Morphology, but the remaining channels may be assigned any measurement.
The image channel that has been assigned the Morphology measurement is
then segmented automatically using a histogram-based thresholding
method. This segmentation is then used to create a binary mask from
which a single-pixel width outline of the cell or cell cluster is
generated. Then, for each pixel in this outline, the Euclidean distance
between the outline pixel and the centroid of the cell or cell cluster
is found. This is the surrogate metric used to describe the cell/cell
cluster’s morphology.

Three possible regions of interest may then be created, according to the
user’s measurement selection. The outline ROI and inner ROI are used for
intensity measurements, while the outer ROI may be used for either
intensity or fiber alignment measurement. Intensity at the outline ROI
is calculated by applying the single-pixel outline to the desired image
channel and averaging the 8-connect neighborhood surrounding each pixel
in the single-pixel width outline. The inner ROI is designed to capture
the intensity of labeled proteins just inside the boundary of the
cell/cell cluster and its width is based on the size of cell/cell
cluster. The intensity values for the inner ROI are calculated by
applying the inner ROI to the desired image channel and finding the
average intensity inside the region using an averaging filter with
kernel size equal to one half the width of the inner ROI. Intensity
measurements in the outer ROI are performed in the same way, with the
exception that the width of the outer ROI is a user-specified value (in
pixels).

## Download

- [TumorTrace Standalone for PC](https://loci.wisc.edu/files/loci/software/TumorTrace_pkg.exe)
- [TumorTrace Standalone for Mac OS](https://loci.wisc.edu/files/loci/software/TumorTrace_pkg..zip)
- [TumorTrace MATLAB m-files](https://loci.wisc.edu/files/loci/software/TumorTrace_MATLAB.zip)

## Instructions

[IMPORTANT NOTE: Installing the MCR and MATLAB on the same
machine](https://www.mathworks.com/access/helpdesk/help/toolbox/compiler/f12-999353.html#br2jauc-33)

### Standalone for macOS

1. Download and unzip `TumorTrace_pkg.zip`

2. Install the MATLAB Compiler Runtime (MCR) using MCRinstaller.dmg
   (included in package)

3. Add the MCR directory to the system path
   ([instructions](https://loci.wisc.edu/files/loci/software/addMCR_bash.txt),
   [readme.txt](https://loci.wisc.edu/files/loci/software/readme.txt))

4. Launch the program from the Terminal command prompt or by double
   clicking the binary file `TumorTrace`.

### Standalone for Windows

1. Download and run `TumorTrace_pkg.exe`

2. Install the MATLAB Compiler Runtime (MCR) using MCRinstaller.exe
   (included in package)

3. Add the MCR directory to the system path
   ([readme.txt](https://loci.wisc.edu/files/loci/readme_0.txt))  
   \*\*\* This step may be unnecessary for some systems

4. Run the TumorTrace.exe

### MATLAB version

Download and unzip the file `TumorTrace_MATLAB.zip`. With MATLAB's
Current Folder set to the TumorTrace folder, enter `TumorTrace` at the
command prompt to launch the GUI.

**\*\*\* Important Note: In order to use the collagen alignment
measurement in TumorTrace, you must also do the following:**

Go to [curvelet.org](http://curvelet.org/) and download the CurveLab 2.1.2
MATLAB package. Place the contents of the folder `fdct_wrapping_matlab` into
the TumorTrace folder.

## Installation and Usage

[**CLICK HERE TO DOWNLOAD USER GUIDE FOR FULL OPERATION
INSTRUCTIONS**](http://loci.wisc.edu/files/loci/software/TumorTrace_userguide.pdf)
