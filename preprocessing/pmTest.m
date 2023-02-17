%test pmBioFormats.m
% refer to:
% https://docs.openmicroscopy.org/bio-formats/6.7.0/developers/matlab-dev.html

%%
%[ImgData, I] = pmBioFormats(ff,OutputFolder,BioFOptionFlag)
% ff = 'fullfile(filePath,fileName,fileExtension)'
% OutputFolder = Path to output folder
% BioFOptionFlag = Options: (1) read in and parse entire file
% addpath('/Users/ympro/Downloads/bfmatlab');

% ff = '/Users/ympro/Desktop/YumingWork/CurveAlignV5.0.BetaMac-2018b/testimages/2B_D9_ROI1.tif';
%%
clear,clc, home, close all
imageFolder = '/Users/ympro/Google Drive/Sabrina_ImageAnalysisProjectAtLOCI_2021.6_/programming/BF-testImages/';
imageList = dir([imageFolder '*.*']);
for i = 1:length(imageList)
   fprintf('image %d: %s \n', i, imageList(i).name); 
end
%%
ff = fullfile(imageFolder,imageList(6).name);
outputFolder = '/Users/ympro/Desktop/YumingWork/CurveAlignV5.0.BetaMac-2018b/testimages/BFtest';
bioFOptionFlag = 1;
[data, I] = pmBioFormats(ff,outputFolder,bioFOptionFlag);
seriesCount = size(data, 1);
series1 = data{1, 1};
% series2 = data{2, 1};
% series3 = data{3, 1};
metadataList = data{1, 2};
% etc
series1_planeCount = size(series1, 1);

%%
series1_plane1 = series1{1, 1};
series1_label1 = series1{1, 2};
series1_plane2 = series1{2, 1};
series1_label2 = series1{2, 2};
series1_plane3 = series1{3, 1};
series1_label3 = series1{3, 2};

series1_colorMap1 = data{1, 3}{1, 1};
figure('Name', series1_label1);
if isempty(series1_colorMap1)
  colormap(gray);
else
  colormap(series1_colorMap1);
end

figure,imagesc(series1_plane1);
figure,imshow(series1_plane2);
figure,imagesc(series1_plane3);
%%
% You can also create an animated movie (assumes 8-bit unsigned data):
% 
% cmap = gray(256);
% for p = 1 : size(series1, 1)
%   M(p) = im2frame(uint8(series1{p, 1}), cmap);
% end
% if feature('ShowFigureWindows')
%   movie(M);
% end

%% original metadata
% Query some metadata fields (keys are format-dependent)
metadata = data{1, 2};
subject = metadata.get('Subject');
title = metadata.get('Title');

%To print out all of the metadata key/value pairs for the first series:

metadataKeys = metadata.keySet().iterator();
for i=1:metadata.size()
  key = metadataKeys.nextElement();
  value = metadata.get(key);
  fprintf('%s = %s\n', key, value)
end

%%
% OME metadata
% Conversion of metadata to the OME standard is one of Bio-Formats? primary features. The OME metadata is always stored the same way, regardless of input file format.
% 
% To access physical voxel and stack sizes of the data:

omeMeta = data{1, 4};
stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices

voxelSizeXdefaultValue = omeMeta.getPixelsPhysicalSizeX(0).value();           % returns value in default unit
voxelSizeXdefaultUnit = omeMeta.getPixelsPhysicalSizeX(0).unit().getSymbol(); % returns the default unit type
voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeXdouble = voxelSizeX.doubleValue();                                  % The numeric value represented by this object after conversion to type double
voxelSizeY = omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeYdouble = voxelSizeY.doubleValue();                                  % The numeric value represented by this object after conversion to type double
voxelSizeZ = omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeZdouble = voxelSizeZ.doubleValue();                                  % The numeric value represented by this object after conversion to type double

%%
% By default, bfopen uses bfInitLogging to initialize the logging system at the WARN level. To change the root logging level, use the DebugTools methods as described in the Logging section.
% Set the logging level to DEBUG
loci.common.DebugTools.setRootLevel('DEBUG');

%%
% Reading from an image file
% The main inconvenience of the bfopen.m function is that it loads all the content of an image regardless of its size.
% 
% To access the file reader without loading all the data, use the low-level bfGetReader.m function:
imageName = imageList(6).name;
ff = fullfile(imageFolder,imageName);
reader = bfGetReader(ff);
% You can then access the OME metadata using the getMetadataStore() method:
% 
omeMeta = reader.getMetadataStore();
sizeC = omeMeta.getChannelCount(0);
sizeSeries = 1;
sizeTimepoints = 98;
stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
voxelSizeXdefaultValue = omeMeta.getPixelsPhysicalSizeX(0).value();           % returns value in default unit
voxelSizeXdefaultUnit = omeMeta.getPixelsPhysicalSizeX(0).unit().getSymbol(); % returns the default unit type
voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeXdouble = voxelSizeX.doubleValue();                                  % The numeric value represented by this object after conversion to type double
voxelSizeY = omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeYdouble = voxelSizeY.doubleValue();                                  % The numeric value represented by this object after conversion to type double
% voxelSizeZ = omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER); % in µm
% voxelSizeZdouble = voxelSizeZ.doubleValue();                                  % The numeric value represented by this object after conversion to type double

% Individual planes can be queried using the bfGetPlane.m function:
% 
% series1_plane1 = bfGetPlane(reader, 1);
% To switch between series in a multi-image file, use the setSeries(int) method. To retrieve a plane given a set of (z, c, t) coordinates, these coordinates must be linearized first using getIndex(int, int, int)
% Read plane from series iSeries at Z, C, T coordinates (iZ, iC, iT)
% All indices are expected to be 1-based


iSeries = 1; 
iZ = 1; 
iC= 2; 
iT = 1;
reader.setSeries(iSeries - 1);
iPlane = reader.getIndex(iZ - 1, iC -1, iT - 1) + 1;
I = bfGetPlane(reader, iPlane);
figBF = figure; imagesc(I);
figureTitle = sprintf('%dx%dx%d pixels, Z=%d/%d,  Channel= %d/%d, Timepoint=%d/%d,pixelSize=%3.2f um, Series =%d/%d', stackSizeX,stackSizeY,stackSizeZ,iZ,stackSizeZ,iC,sizeC,iT,sizeTimepoints,voxelSizeXdouble,iSeries,sizeSeries);
title(figureTitle,'FontSize',10);
axis image equal
drawnow;


%%
% Saving files
% The basic code for saving a 5D array into an OME-TIFF file is located in the bfsave.m function.

% For instance, the following code will save a single image of 64 pixels by 64 pixels with 8 unsigned bits per pixels:

plane = zeros(64, 64, 'uint8');
bfsave(plane, 'single-plane.ome.tiff');
%And the following code snippet will produce an image of 64 pixels by 64 pixels with 2 channels and 2 timepoints:

plane = zeros(64, 64, 1, 2, 2, 'uint8');
bfsave(plane, 'multiple-planes.ome.tiff');
%By default, bfsave will create a minimal OME-XML metadata object containing basic information such as the pixel dimensions, 
%the dimension order and the pixel type. To customize the OME metadata, it is possible to create a metadata object from the input array using createMinimalOMEXMLMetadata.m, add custom metadata and pass this object directly to bfsave:

plane = zeros(64, 64, 1, 2, 2, 'uint8');
metadata = createMinimalOMEXMLMetadata(plane);
pixelSize = ome.units.quantity.Length(java.lang.Double(.05), ome.units.UNITS.MICROMETER);
metadata.setPixelsPhysicalSizeX(pixelSize, 0);
metadata.setPixelsPhysicalSizeY(pixelSize, 0);
pixelSizeZ = ome.units.quantity.Length(java.lang.Double(.2), ome.units.UNITS.MICROMETER);
metadata.setPixelsPhysicalSizeZ(pixelSizeZ, 0);
bfsave(plane, 'metadata.ome.tiff', 'metadata', metadata);
% The dimension order of the file on disk can be specified in two ways:
% 
% either by passing an OME-XML metadata option as a key/value pair as shown above
% 
% or as an optional positional argument of bfsave
% 
% If a metadata object is passed to bfsave, its dimension order stored internally will take precedence.
% 
% For more information about the methods to store the metadata, see the MetadataStore Javadoc page.

