function IPyx_skeleton = skeletonIntersection(dataPath,imagePath)
% This fuction uses skeleton to find the intersection point
% based on a python module named centerline
% input: 
%   dataPath: full path to the CT-FIRE output .mat file, e.g.:
%              dataPath ='H:\GitHub.06.2022\AnalysisTools\testImages\ctFIREout\ctFIREout_synSize512-fiber100.mat';
%   imagePath: full path to the original image, e.g.:
%               imagePath= 'H:\GitHub.06.2022\AnalysisTools\testImages\synSize512-fiber100.tif';
%   [Y X] of the IP points, e.g.:
%               coordPath = fullfile(pwd,'IPxy_skeleton.mat');
% output: 
% 1) save IP coordinates into a .mat file in the same folder as the loaded
% data file 
% 2) IPxy_skeleton: coordinates of the detected intersection points
% Example:
% dataPath ='..\testImages\ctFIREout\ctFIREout_synSize512-fiber100.mat'
% imagePath= '..\testImages\synSize512-fiber100.tif'
% skeletonIntersection(dataPath,imagePath)
% in python enviroment, use the following syntax:
% dataPath ='H:\\GitHub.06.2022\\AnalysisTools\\testImages\\ctFIREout\\ctFIREout_synSize512-fiber100.mat'
% imagePath= 'H:\\GitHub.06.2022\\AnalysisTools\\testImages\\synSize512-fiber100.tif'
%% coordPath = 'IPyx_skeleton.mat'
% import IPdetection
% IPdetection.IP_skeleton(dataPath,imagePath)
% addpath('./FiberCenterlineExtraction');
% Use the GUI to manage the python environment
% pyenv
% terminate(pyenv)
% py.sys.path;
%  % 'C:\\Program Files\\MATLAB\\R2023b\\interprocess\\bin\\win64\\pycli',
%  % '', 'C:\\ProgramData\\miniconda3\\envs\\collagen\\python311.zip', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\DLLs', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages\\win32', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages\\win32\\lib', 
%  % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages\\Pythonwin']
% insert(py.sys.path,int32(0),fullfile(pwd,'FiberCenterlineExtraction'))
[imgDir,imgNOE] = fileparts(imagePath);
coordPath = fullfile(imgDir,'ctFIREout',sprintf('Iyx_skeleton_%s.mat',imgNOE));
if exist(coordPath,'file')
    load(coordPath,'IPyx_skeleton')
    disp("Using the pre-saved IP coordinates output from directly running the python module" )
else
    fprintf('No IP coordinates from skeleton-based analysis was found \n')
    try 
        % clear classes
        fprintf('Running python module for skeleton-based IP detection... \n')
        IPskeleton = py.importlib.import_module('IPdetection');
        IPyx_skeleton = double(IPskeleton.IP_skeleton(dataPath,imagePath));
        fprintf('Python module for skeleton-based IP analysis went through \n')
        fprintf('IP results saved at %s \n', fileparts(dataPath));
    catch EXP1
        error("Skeleton-based IP detection didnot go through. Error mesage: %s \n",EXP1.message)
    end

end

% %% visualize the IP points
% figure, imshow(imagePath)
% axis image equal
% colormap gray
% hold on
% plot(IPxy(:,2),IPxy(:,1),'ro','MarkerSize',5)
% hold off