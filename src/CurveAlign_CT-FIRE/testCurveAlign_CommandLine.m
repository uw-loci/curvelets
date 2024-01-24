% testCurveAlgine_CommandLine.m
% Depending on the analysis mode, one or more of the following parameter files 
% should be prepared before running the analysis: 
    % ctfpfile = 'CTFP_cluster.txt'; % txt file of CT-FIRE parameters
    % capfile = 'CAP_cluster.txt'; % txt file of CurveAlign parameters
    % caroipfile = 'CAroiP_cluster.txt'; % txt file of CurveAlign ROI analysis parameters
% template to prepare the three txt files is : template_CAparameters.xlsx 
% If running ROI analysis, corresponding ROI .mat file should be prepared. 
% Eliceiri's Lab, UW-Madison
% 2020-05



clear,clc,home;
% %% example to test CA command line in matlab source code version 
% imageFolder = 'C:\Users\Aiping\Desktop\CurveAlign-CommandLine-sourcecode\testimagesForCurveAlignCL';%
% imagetype = '.tif';
% analysisMode = '2';  %  0: default, sequentially CTF-CA-CAroi analysis; 1: CT-FIRE; 2:CurveAlign;3:CAroi
% imageRange = '3'; % 'all': default, all images in the image folder ; or specified image indexes, such as '1:2', or '1:2 3' 
% CurveAlign_CommandLine(imageFolder,imagetype,analysisMode,imageRange)

%% example to test CA command line in .exe version 
imageFolder = 'C:\Users\Aiping\Desktop\CurveAlign-CommandLine-sourcecode\testimagesForCurveAlignCL';%
imagetype = '.tif';
analysisMode = '2';  %  0: default, sequentially CTF-CA-CAroi analysis; 1: CT-FIRE; 2:CurveAlign;3:CAroi
imageRange = '1,2'; % 'all': default, all images in the image folder ; or specified image indexes, such as '1:2', or '1:2 3' 
commandName = 'CurveAlign_CommandLine.exe';
CAclCommand = sprintf('%s %s %s %s %s %s',commandName,imageFolder,imagetype,analysisMode,imageRange);   
system(CAclCommand);

