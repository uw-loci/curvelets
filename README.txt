The purpose of this standalone MATLAB package is to allow users to quickly and
automatically quantify the alignment of periodic structures (e.g. collagen
fibers) in an image, with respect to a user-specified boundary or an absolute
reference. The program reads in image files, finds the locations and
orientations of edges via the Fast Discrete Curvelet Transform
(http://curvelet.org/), and returns the orientation data along with descriptive
statistics and other optional outputs. The output may be displayed on the
screen and/or written to .csv files. A reduced version containing only the
functions to generate and minimally process the orientation data is available
for use with Octave.

The optional accessory program, CurvePrep, is for easy preparation of images to
be analyzed with the CurveAlign program. It is available as a MATLAB m-file or
a standalone for Mac or PC.

For more information, see the web site at:
   http://loci.wisc.edu/software/curvelet-based-alignment-analysis
