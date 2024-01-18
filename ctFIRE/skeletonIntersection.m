function IPxy_skeleton = skeletonIntersection(dataPath,imagePath,coordPath)
% This fuction uses skeleton to find the intersection point
% based on a python module named centerline
% input: 
%   dataPath: full path to the CT-FIRE output .mat file, e.g.:
%              dataPath ='H:\GitHub.06.2022\AnalysisTools\testImages\ctFIREout\ctFIREout_synSize512-fiber100.mat';
%   imagePath: full path to the original image, e.g.:
%               imagePath= 'H:\GitHub.06.2022\AnalysisTools\testImages\synSize512-fiber100.tif';
%   coordPath: full path to the output .mat file containing the coordinates
%   [Y X] of the IP points, e.g.:
%               coordPath = fullfile(pwd,'IPxy_skeleton.mat');
% output: 
% 1) save IP coordinates into a .mat file with the full path of coordPath
% 2) IPxy_skeleton: coordinates of the detected intersection points
% Example:
% dataPath ='H:\GitHub.06.2022\AnalysisTools\testImages\ctFIREout\ctFIREout_synSize512-fiber100.mat'
% imagePath= 'H:\GitHub.06.2022\AnalysisTools\testImages\synSize512-fiber100.tif'
% coordPath = fullfile(pwd,'IPxy_skeleton.mat')
% skeletonIntersection(dataPath,imagePath,coordPath)

% addpath('./FiberCenterlineExtraction');
pyenv
terminate(pyenv)
py.sys.path;
 % 'C:\\Program Files\\MATLAB\\R2023b\\interprocess\\bin\\win64\\pycli',
 % '', 'C:\\ProgramData\\miniconda3\\envs\\collagen\\python311.zip', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\DLLs', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages\\win32', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages\\win32\\lib', 
 % 'C:\\ProgramData\\miniconda3\\envs\\collagen\\Lib\\site-packages\\Pythonwin']
insert(py.sys.path,int32(0),fullfile(pwd,'FiberCenterlineExtraction'))
if exist(coordPath,'file')
    load(coordPath,'IPxy_skeleton')
    disp("Using the pre-saved IP coordinates output from directly running the python module" )
else
    fprintf('No IP coordinates from skeleton-based analysis was found')
    try 
        % clear classes
        IPskeleton = py.importlib.import_module('IPdetection');
        IPxy_skeleton = double(IPskeleton.IP_skeleton(dataPath,imagePath,coordPath));
    catch EXP1
        fprintf("Skeleton-based IP detection didnot go through. Error mesage: %s \n",EXP1.message)
        IPxy_skeleton =[];
    end

end

% %% visualize the IP points
% figure, imshow(imagePath)
% axis image equal
% colormap gray
% hold on
% plot(IPxy(:,2),IPxy(:,1),'ro','MarkerSize',5)
% hold off