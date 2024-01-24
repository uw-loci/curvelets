
function CreateParameters_cluster(ImagePath, ImageName, mode)
%yl09012017: create parameters for CurveAlignFE_cluster.m
% Input:
%    ImagePath: image directory
%    ImageName: name of the image
%    mode: 1: CT-FIRE; 2: CurveAlign full image analysis, 3: CurveAlign ROI analysis
% Output:
%    saved in a txt file

if mode == 1
    disp('Create parameters to run CT-FIRE on computer clusters,not ready yet')
elseif mode  == 2
    disp('Create parameters to run CurveAlign  on computer clusters')
    [~,filename1] = fileparts(ImageName);
    %& option1: load from mat file
    %% option2: define here
    pathName = ImagePath;   %image directory  
    fileName = ImageName;   %full image name with fomrat extension
    keep = 0.001;           %fraction of the largest curvelet transform coefficients to be used
    distThresh = 100;       %distance threshold when boundary is considered
    makeAssocFlag = 1;      %Check box to display fiber-boundary association
    makeMapFlag = 1;        %Check box to create heatmap
    makeOverFlag = 1;       %Checkbox to create overlay image
    makeFeatFlag = 1;       %Checkbox to output feature files
    sliceIND = [];  % index of slice in stack. For non-stack image, it is set to empty
    bndryMode = 0; % dropdown menu: 0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary
%     BoundaryDir = fullpath(ImagePath,'CA_Boundary');
    fibMode = 1; % dropdown menu: 0: CT; 1:CT-FIRE Segments;2: CT-FIRE fibers;3:'CT-FIRE Endpoints'
    numSections = 1; % stack > 1, single image = 1
    % addvanced options
    exclude_fibers_inmaskFLAG = 1;   % for tiff bounday, 1: exclude fibers inside the mask, 0: keep the fibers inside the mask
    plotrgbFLAG = 0;    % 0: donot display RGB image; 1: display RGB image
    seleted_scale = 1;      % 1 : the second finest scale, 2: the third finest scale...
    curvelets_group_radius = 10;  % radius to group curvelets
    minimum_nearest_fibers = 2;  % minimum nearest fibers  should be set as 2^n, n>=1
    minimum_box_size = 32; % box size should be set as 2^n, n>=5
    fiber_midpointEST = 1; %1: estimation based on endpoint coordinates; 2: ^estimation based on fiber length
    
    %% save the parameters into a txt file
    txtfilename = fullfile(pathName,['CAPcluster_',ImageName,'.txt']);
    fid = fopen(txtfilename,'w');
    % run parameters
    fprintf(fid,'%s\n',pathName);
    fprintf(fid,'%s\n' ,fileName);
    fprintf(fid,'%5.4f\n',keep);
    fprintf(fid,'%d\n',distThresh);
    fprintf(fid,'%d\n',makeAssocFlag);
    fprintf(fid,'%d\n',makeMapFlag);
    fprintf(fid,'%d\n',makeOverFlag);
    fprintf(fid,'%d\n',makeFeatFlag);
    fprintf(fid,'%d\n',sliceIND);
    fprintf(fid,'%d\n',bndryMode);
    fprintf(fid,'%d\n',fibMode);
    fprintf(fid,'%d\n',numSections);
    fprintf(fid,'%d\n',exclude_fibers_inmaskFLAG);
    fprintf(fid,'%d\n',plotrgbFLAG);
    fprintf(fid,'%d\n', seleted_scale);
    fprintf(fid,'%d\n',curvelets_group_radius);
    fprintf(fid,'%d\n',minimum_nearest_fibers);
    fprintf(fid,'%d\n', minimum_box_size);
    fprintf(fid,'%d\n',fiber_midpointEST);
    fclose(fid)
    fprintf('parameter file for CHTC cluster is saved as %s \n',filename)
    return
elseif mode  == 3
    disp('Create parameters to run CurveAlign ROI analysis on computer clusters')
    pathName = ImagePath;   %image directory
    fileName = ImageName;   %full image name with fomrat extension
    stack_flag = 0; %1: stack; 0: non-stack
    fibMode = 1; % dropdown menu: 0: CT; 1:CT-FIRE Segments;2: CT-FIRE fibers;3:'CT-FIRE Endpoints'
    bndryMode = 0; % dropdown menu: 0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary
    postFLAG = 1;  % 1: post ROI analysis; 0: direct ROI anaysis;
    cropIMGon = 0; % 1: use cropped image for direct ROI analysis; 1: use full-size image for direct ROI analysis
    plotrgbFLAG = 0;    % 0: donot display RGB image; 1: display RGB image
    prlflag = 2;   % 0: no parallel; 1: multicpu version; 2: cluster version
%% save the parameters into a txt file
    txtfilename = fullfile(pathName,['CAroiPcluster_',ImageName,'.txt']);
    fid = fopen(txtfilename,'w');
    % run parameters
    k = 1;
    fprintf(fid,'%%P%d:%s\n',k,'Image folder name'); 
    fprintf(fid,'%s\n',pathName);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'Image name'); 
    fprintf(fid,'%s\n' ,fileName);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'stack flag: 1: stack; 0:non-stack'); 
    fprintf(fid,'%d\n',stack_flag);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'Fiber analysis mode,0: CT; 1:CTF fiber segments;2: CTF fibers;3: CTF fiber endpoints'); 
    fprintf(fid,'%d\n',fibMode);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'Boundary mode,0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary'); 
    fprintf(fid,'%d\n',bndryMode);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'Post ROI analysis flag, 1: post ROI analysis; 0: direct ROI anaysis'); 
    fprintf(fid,'%d\n',postFLAG);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'crop image for analysis or not, 1: crop; 0: not crop'); 
    fprintf(fid,'%d\n',cropIMGon);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'Display RGB image or not: 1:display RGB color image; 0:donot display RGB color'); 
    fprintf(fid,'%d\n',plotrgbFLAG);k = k+1;
    fprintf(fid,'%%P%d:%s\n',k,'Type of parallel computing, 1: multicpu version; 2: cluster version'); 
    fprintf(fid,'%d\n',prlflag);k = k+1;
    fclose(fid)
    fprintf('parameter file for CHTC cluster is saved as %s \n',txtfilename)
    return
end
