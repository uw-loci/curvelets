function [fibFeat] = processImage_p(pathName, imgNamefull, tempFolder, keep, coords, distThresh, makeAssoc, makeMap, makeOver, makeFeat, sliceNum, infoLabel, tifBoundary, boundaryImg, fireDir, fibProcMeth, advancedOPT,numSections)
%processImage_p.m
%YL08/07/2017: adapted from processImage.m for parallel computinng
% processImage.m - Process images for fiber analysis. 3 main options:
%   1. Boundary analysis = compare fiber angles to boundary angles and generate statistics
%   2. Absolute angle analysis = just return absolute fiber angles and statistics
%   3. May also select to use the fire results (if fireDir is populated)
%
% Inputs
%   pathName: image directory %IMG = 2D image, size  = [M N]
%   imgNamefull = name of the image with format extension
%   tempFolder = output directory where results will be stored
%   keep = percentage of curvelet coefficients to keep in analysis
%   coords = coordinates of a boundary
%   distThresh = distance from boundary to perform evaluation
%   makeAssoc = show the associations between the boundary and curvelet in the output
%   sliceNum = number of the slice within a stack
%   infoLabel = Label on GUI, this is used if this function is called by a GUI
%   tifBoundary = flag to tell function if the boundary file should be a tif file, rather than the coords list
%   boundaryImg = the actual boundary image, this is only used for output overlay images
%   fireDir = directory to find the FIRE results, used if we want to use FIRE fibers rather than curvelets
%
% Optional Inputs
% advancedOPT: a structure contains the advanced interface controls including
% advancedOPT.exclude_fibers_inmaskFLAG, FLAG to exclude the fibers in the boundary 
%  advancedOPT.curvelets_group_radius, radius to group the curvelet that
%  are close
% advancedOPT.seleted_scale: the default is the 2nd finest scale: ...
%    ceil(log2(min(M,N)) - 3)-1, the range is [2  ceil(log2(min(M,N)) -
%    3)-1]
% advancedOPT.heatmap_STDfilter_size:default 24
% advancedOPT.heatmap_SQUAREmaxfilter_size:default 12
% advancedOPT.heatmap_GAUSSIANdiscfilter_sigma:default 4

% Outputs
%   histData = list of histogram values and bin centers
%   recon = reconstructed curvelet image (if curvelet trans is used)
%   comps = list of compass plot values
%   values = list of all angles found in the image
%   distances = list of distances to the boundary for each angle
%   stats = summary of the statistical analysis, list of values
%   procmap = filtered image showing simple spatial correlation of curvelet angles
%
% By Jeremy Bredfeldt Laboratory for Optical and
% Computational Instrumentation 2013

% get screen size to control figure position 
Swh = get(0,'screensize'); Swidth = Swh(3); Sheight= Swh(4);
%     figure(3); clf;
%     hold all;
%     imshow(IMG);
exclude_fibers_inmaskFLAG = advancedOPT.exclude_fibers_inmaskFLAG;   % for tiff bounday, 1: exclude fibers inside the mask, 0: keep the fibers inside the mask 

% Read image into the workspace
if numSections == 1
    IMG = imread(fullfile(pathName,imgNamefull));
elseif numSections > 1
    IMG = imread(fullfile(pathName,imgNamefull),sliceNum);
end
if size(IMG,3) > 1
    if advancedOPT.plotrgbFLAG == 0
        IMG = rgb2gray(IMG);
        disp('color image was loaded but converted to grayscale image')
    end
end

[~,imgName,~ ] = fileparts(imgNamefull);  % imgName: image name without extention
imgNameLen = length(imgName);
imgNameP = imgName; %plain image name, without slice number
if numSections> 1
    imgName = [imgName(1:imgNameLen) '_s' num2str(sliceNum)];
end
disp(['Image name: ' imgNameP]);
if numSections > 1
    disp(sprintf('Slide number: %d', sliceNum));
end

bndryMeas = ~isempty(coords); %flag that indicates if we are measuring with respect to a boundary


tic;
%add feature control structure: featCP
featCP.minimum_nearest_fibers = advancedOPT.minimum_nearest_fibers;
featCP.minimum_box_size = advancedOPT.minimum_box_size;
featCP.fiber_midpointEST = advancedOPT.fiber_midpointEST;


%Get features that are only based on fibers
if fibProcMeth == 0
%     if infoLabel, set(infoLabel,'String','Computing curvelet transform.'); drawnow; end
    disp('Computing curvelet transform.'); % yl: for CK integration
    curveCP.keep = keep;
    curveCP.scale = advancedOPT.seleted_scale;
    curveCP.radius = advancedOPT.curvelets_group_radius;
    [object, fibKey, totLengthList, endLengthList, curvatureList, widthList, denList, alignList,Ct] = getCT(imgNameP,IMG,curveCP,featCP);
    
    
else
%     if infoLabel, set(infoLabel,'String','Reading FIRE database.'); drawnow; end
     disp('Reading CT-FIRE database.'); % YL: for CK integration
     % add the slice name used in CT-FIRE output
     try
         if numSections > 1
             [object, fibKey, totLengthList, endLengthList, curvatureList, widthList, denList, alignList] = getFIRE(imgName,fireDir,fibProcMeth-1,featCP);
         elseif numSections == 1
             [object, fibKey, totLengthList, endLengthList, curvatureList, widthList, denList, alignList] = getFIRE(imgNameP,fireDir,fibProcMeth-1,featCP);
         end
     catch ERRgetFIRE
         fprintf('CT-FIRE result for %s is not loaded, error message:%s \n',imgName,ERRgetFIRE.message)
         return
     end
end

if isempty(object)
    histData = [];
    recon = [];
    comps = [];
    values = [];
    distances = [];
    stats = [];
    procmap = [];
    return;
end

%Get Features Correlating fibers to boundaries
if bndryMeas
    %there is something in coords (boundary point list), so analyze wrt
    %boundary
%     if infoLabel, set(infoLabel,'String','Analyzing boundary.'); end
     disp('Analyzing boundary.'); % yl: for CK integration
    if tifBoundary == 3%(tifBoundary)
        [resMat,resMatNames,numImPts] = getTifBoundary(coords,boundaryImg,object,imgName,distThresh, fibKey, endLengthList, fibProcMeth-1);
        angles = resMat(:,3);    %nearest relative boundary angle
%         inCurvsFlag = resMat(:,4) < distThresh;
        inCurvsFlag = resMat(:,1) <= distThresh;   % use the nearest boundary distance
        outCurvsFlag = resMat(:,1) > distThresh;    % YL07082015: add outCurvsFlag for tiff boundary
        if exclude_fibers_inmaskFLAG == 1
          inCurvsFlag = resMat(:,1) <= distThresh & resMat(:,2)== 0;
          outCurvsFlag = ~inCurvsFlag;
         end
        distances = resMat(:,1);    % nearest boudary distance
        measBndry = resMat(:,6:7); %YL
    elseif tifBoundary == 1  || tifBoundary == 2% (coordinates boundary,)
        %         [angles,distances,inCurvsFlag,outCurvsFlag,measBndry,numImPts] = getBoundary(coords,IMG,object,imgName,distThresh);
        [angles,distances,inCurvsFlag,outCurvsFlag,inCurvs,outCurvs,measBndry, numImPts] = getBoundary(coords,IMG,object,imgName,distThresh);
        
    end
    bins = 2.5:5:87.5;
else
    if fibProcMeth  == 0  % CT angle
        %angs = vertcat(object.angle);
        %angles = group5(angs,inc);
        distances = NaN(1,length(object));
        %bins = min(angles):inc:max(angles);
        inCurvsFlag = logical(1:length(object));
        outCurvsFlag = ~logical(1:length(object));
        object = group6(object); % Rotate all angles to be from 0 to 180 deg 
        angles = vertcat(object.angle);
    else  % FIRE angle
         inCurvsFlag = logical(1:length(object));
% %         object = group6(object);
         angles = vertcat(object.angle);
        
    end
       
    measBndry = 0;
    numImPts = size(IMG,1)*size(IMG,2); %if no boundary exists, count all the pixels in the image
    bins = 2.5:5:177.5;
end
toc;

if makeFeat
    featNames = {...
        'fiber Key into CTFIRE list', ...
        'end point row', ...
        'end point col', ...
        'fiber abs ang', ...
        'fiber weight', ...
        'total length', ...
        'end to end length', ...
        'curvature', ...
        'width', ...
        sprintf('dist to nearest %d',2^0*featCP.minimum_nearest_fibers), ...
        sprintf('dist to nearest %d',2^1*featCP.minimum_nearest_fibers), ...
        sprintf('dist to nearest %d',2^2*featCP.minimum_nearest_fibers), ...
        sprintf('dist to nearest %d',2^3*featCP.minimum_nearest_fibers), ...
        'mean nearest dist', ...
        'std nearest dist', ...
        sprintf('box density %d',2^0*featCP.minimum_box_size), ...
        sprintf('box density %d',2^1*featCP.minimum_box_size), ...
        sprintf('box density %d',2^2*featCP.minimum_box_size), ...
        sprintf('alignment of nearest %d',2^0*featCP.minimum_nearest_fibers), ...
        sprintf('alignment of nearest %d',2^1*featCP.minimum_nearest_fibers), ...
        sprintf('alignment of nearest %d',2^2*featCP.minimum_nearest_fibers), ...
        sprintf('alignment of nearest %d',2^3*featCP.minimum_nearest_fibers), ...
        'mean nearest align', ...
        'std nearest align', ...
        sprintf('box alignment %d',2^0*featCP.minimum_box_size), ...
        sprintf('box alignment %d',2^1*featCP.minimum_box_size), ...
        sprintf('box alignment %d',2^2*featCP.minimum_box_size), ...
        'nearest dist to bound', ...
        'inside epi region', ...
        'nearest relative boundary angle', ...
        'extension point distance', ...
        'extension point angle', ...
        'boundary point row', ...
        'boundary point col'};
    
    %1. fiber Key into CTFIRE list
    %2. row
    %3. col
    %4. abs ang
    %5. fiber weight
    %6. total length
    %7. end to end length
    %8. curvature
    %9. width
    %10. dist to nearest 2
    %11. dist to nearest 4
    %12. dist to nearest 8
    %13. dist to nearest 16
    %14. mean dist (8-11)
    %15. std dist (8-11)
    %16. box density 32
    %17. box density 64
    %18. box density 128
    %19. alignment of nearest 2
    %20. alignment of nearest 4
    %21. alignment of nearest 8
    %22. alignment of nearest 16
    %23. mean align (14-17)
    %24. std align (14-17)
    %25. box alignment 32
    %26. box alignment 64
    %27. box alignment 128
    %28. nearest dist to bound
    %29. nearest dist to region
    %30. nearest relative boundary angle
    %31. extension point distance
    %32. extension point angle
    %33. boundary point row
    %34. boundary point col
    %Save fiber feature array
    
    
    if tifBoundary> 0    % with boundary
        
        if tifBoundary == 3   % tiff
            %Fiber feature extraction is done now. Compile results
            fibFeat = [fibKey, vertcat(object.center), vertcat(object.angle), vertcat(object.weight), totLengthList, endLengthList, curvatureList, widthList, denList, alignList, resMat];
        elseif tifBoundary == 1  || tifBoundary == 2% (coordinates boundary,)
            fibFeat = [fibKey, vertcat(object.center), vertcat(object.angle), vertcat(object.weight), totLengthList, endLengthList, curvatureList, widthList, denList, alignList];
        end
        
%         distTEMP = fibFeat(:,28);  %
%         inBW = fibFeat(:,29);
%         inCurvsFlagSAVE = distTEMP <= distThresh;   % use the nearest boundary distance
%         if tifBoundary == 3 & exclude_fibers_inmaskFLAG == 1
%           inCurvsFlagSAVE = distTEMP <= distThresh & resMat(:,2)== 0;
%         end
        
        
        if numSections > 1
            savefn = fullfile(tempFolder,[imgNameP '_s' num2str(sliceNum) '_fibFeatures','.mat']);
            savefn1 = fullfile(tempFolder,[imgNameP '_s' num2str(sliceNum) '_fibFeatures' '.csv']);
            savefn2 = fullfile(tempFolder,[imgNameP '_s' num2str(sliceNum) '_fibFeatNames' '.csv']);
        else
            savefn = fullfile(tempFolder,[imgNameP '_fibFeatures.mat']);
            savefn1 = fullfile(tempFolder,[imgNameP '_fibFeatures.csv']);
            savefn2 = fullfile(tempFolder,[imgNameP '_fibFeatNames.csv']);
        end
        save(savefn,'imgNameP','tempFolder','fibProcMeth','keep','distThresh','fibFeat','featNames','bndryMeas', 'tifBoundary','coords','advancedOPT');
        
        csvwrite(savefn1,fibFeat);
        
        filename = savefn2;
        fileID = fopen(filename, 'w');
        
        for i = 1:34
            fprintf(fileID,'f%d : %12s\n',i,featNames{i});
        end
        
        fclose(fileID);
        
    else          % without bounadray
        
        %Fiber feature extraction is done now. Compile results
        Last7F = nan(length(fibKey),7); % set the boundary-associated features to NAN
        fibFeat = [fibKey, vertcat(object.center), vertcat(object.angle), vertcat(object.weight), totLengthList, endLengthList, curvatureList, widthList, denList, alignList,Last7F];
        
        
        if numSections > 1
            savefn = fullfile(tempFolder,[imgNameP '_s' num2str(sliceNum) '_fibFeatures' '.mat']);
            savefn1 = fullfile(tempFolder,[imgNameP '_s' num2str(sliceNum) '_fibFeatures' '.csv']);
            savefn2 = fullfile(tempFolder,[imgNameP '_s' num2str(sliceNum) '_fibFeatNames' '.csv']);
        else
            
            savefn = fullfile(tempFolder,[imgNameP '_fibFeatures.mat']);
            savefn1 = fullfile(tempFolder,[imgNameP '_fibFeatures.csv']);
            savefn2 = fullfile(tempFolder,[imgNameP '_fibFeatNames.csv']);
            
        end
        
        save(savefn,'imgNameP','tempFolder','fibProcMeth','keep','distThresh','fibFeat','featNames','bndryMeas', 'tifBoundary','coords','advancedOPT');
        csvwrite(savefn1,fibFeat);
        
        filename = savefn2;
        fileID = fopen(filename, 'w');
        
        for i = 1:34
            fprintf(fileID,'f%d : %12s\n',i,featNames{i});
            
        end
        
        fclose(fileID);
        
    end
    
    
else
    fibFeat = [];
end

%%
if tifBoundary == 3    % only for tiff boundary , need to keep tiff boundary and csv boundary the same 
    values = angles(inCurvsFlag);
else
    values = angles;
end
histf = figure;clf; set(histf,'Units','normalized','Position',[0.27 0.0875+0.25*Swidth/Sheight 0.125 0.125*Swidth/Sheight],'Name','Histogram of the angles','NumberTitle','off','Visible','off')
hist(values,bins);
[n xout] = hist(values,bins);
xlabel('Angle [degree]')
ylabel('Frequency [#]')

clear values
if (size(xout,1) > 1)
    xout = xout'; %fixing strange behaviour of hist when angles is empty
end
imHist = vertcat(n,xout);

histData = imHist;
saveHist = fullfile(tempFolder,strcat(imgName,'_hist.csv'));
tempHist = circshift(histData,1);
csvwrite(saveHist,tempHist');
histData = tempHist';


if fibProcMeth == 0
    %can do inverse-CT, since mode is CT only
%     if infoLabel, set(infoLabel,'String','Computing inverse curvelet transform.'); end
    disp('Computing inverse curvelet transform.'); % yl: for CK integration
    temp = ifdct_wrapping(Ct,0);
    recon = real(temp);
    %recon = object;
    saveRecon = fullfile(tempFolder,strcat(imgNameP,'_reconstructed.tiff'));
    %fmt = getappdata(imgOpen,'type');
    %recon is written to file in the code below
    if numSections > 1
        imwrite(recon,saveRecon,'WriteMode','append');
    else
        imwrite(recon,saveRecon);
%         histf = figure; set(histf,'position',[600,400,400, 400],'Name','Histogram of the angles','NumberTitle','off','Visible', 'off');
%         hist(angles,bins);
    end
    
else
    %cannot do inverse-CT, since CT-FIRE mode
    recon = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%write out the raw map file (no smearing, etc)

if makeOver  % in paralle computing output image control is not enabled
    %Make another figure for the curvelet overlay:
    disp('Only an empty Overlay image is created in parallel computing so far.'); %yl, for parallel com
    if numSections > 1
        saveOverN = fullfile(tempFolder,sprintf('%s_s%d_overlay.tiff',imgNameP,sliceNum));
    else
        saveOverN = fullfile(tempFolder,sprintf('%s_overlay.tiff',imgNameP));
    end
    imwrite(255*ones(size(IMG)),saveOverN,'tiff')
end

if makeMap
   disp('Only an empty heatmap image is created in parallel computing so far.'); %yl, for parallel com
%     if infoLabel, set(infoLabel,'String','Plotting map.'); drawnow; end

    %Put together a map of alignment
    % add tunable Control Parameters for drawing the heatmap 
    mapCP.STDfilter_size = advancedOPT.heatmap_STDfilter_size;
    mapCP.SQUAREmaxfilter_size = advancedOPT.heatmap_SQUAREmaxfilter_size;
    mapCP.GAUSSIANdiscfilter_sigma = advancedOPT.heatmap_GAUSSIANdiscfilter_sigma;
    
    if tifBoundary == 0       % NO boundary
        [rawmap procmap] = drawMap(object(inCurvsFlag), angles(inCurvsFlag), IMG, bndryMeas,mapCP);
    elseif tifBoundary ==  1 || tifBoundary == 2       % CSV boundary
        [rawmap procmap] = drawMap(inCurvs, angles, IMG, bndryMeas,mapCP);
    elseif  tifBoundary ==  3     % tiff boundary
        [rawmap procmap] = drawMap(object(inCurvsFlag), angles(inCurvsFlag), IMG, bndryMeas,mapCP);
    end
    
    guiMap = figure;
    set(guiMap,'Units','normalized','Position',[0.275+0.25 0.0875 0.25 0.25*Swidth/Sheight],'name','CurveAlign Angle Map','NumberTitle','off','Visible','on');
    %guiMap = figure('Resize','on','Units','pixels','Position',[215 70 600 600],'name','CurveAlign Map','NumberTitle','off','UserData',0);
    mapPanel = uipanel('Parent', guiMap,'Units','normalized','Position',[0 0 1 1]);
    mapAx = axes('Parent',mapPanel,'Units','normalized','Position',[0 0 1 1]);
    if max(max(IMG)) > 255
        IMG2 = ind2rgb(IMG,gray(2^16-1)); %assume 16 bit
    else
        IMG2 = ind2rgb(IMG,gray(255)); %assume 8 bit
    end
    imagesc(IMG2); % yl:imshow doesnot work in parallel loop,use IMAGESC 
    hold on;
    clrmap = zeros(256,3);
    %Set the color map of the map, highly subjective!!!
    if (bndryMeas)
        tg = ceil(10*255/90); ty = ceil(45*255/90); tr = ceil(60*255/90);
        clrmap(tg:ty,2) = clrmap(tg:ty,2)+1;          %green
        clrmap(ty+1:tr,1:2) = clrmap(ty+1:tr,1:2)+1;  %yellow
        clrmap(tr+1:256,1) = clrmap(tr+1:256,1)+1;    %red
    else
        tg = ceil(32); ty = ceil(64); tr = ceil(128);
        clrmap(tg:ty,2) = clrmap(tg:ty,2)+1;          %green
        clrmap(ty+1:tr,1:2) = clrmap(ty+1:tr,1:2)+1;  %yellow
        clrmap(tr+1:256,1) = clrmap(tr+1:256,1)+1;    %red
      
    end
%     h = imshow(procmap,clrmap);
    
    h = imagesc(procmap); colormap(clrmap)%YL

    alpha(h,0.5); %change the transparency of the overlay
    disp('Saving map');
%     if infoLabel, set(infoLabel,'String','Saving map.'); end
    set(guiMap,'PaperUnits','inches','PaperPosition',[0 0 size(IMG,2)/200 size(IMG,1)/200]);
    if numSections > 1
        saveMapN= fullfile(tempFolder,sprintf('%s_s%d_procmap.tiff',imgNameP,sliceNum));
    else
        saveMapN= fullfile(tempFolder,sprintf('%s_procmap.tiff',imgNameP));
    end
    %write out the processed map (with smearing etc)
    print(guiMap,'-dtiffn', '-r200', saveMapN);%, '-append'); %save a temporary copy of the image
  %YL keep v2.3 feature:  Values and stats Output about the angles
      if tifBoundary == 3   % only for tiff boundary
          values = angles(inCurvsFlag);
      else
          values = angles;
      end
    stats = makeStatsO(values,tempFolder,imgName,procmap,tr,ty,tg,bndryMeas,numImPts);
    saveValues = fullfile(tempFolder,strcat(imgName,'_values.csv'));
    if tifBoundary == 3     % tiff boundary
        csvwrite(saveValues,[values distances(inCurvsFlag)]);
    elseif tifBoundary == 1 | tifBoundary == 2  % csv boundary
        csvwrite(saveValues,[values distances]);
    else
        csvwrite(saveValues,values);
    end
    clear values

end
disp(sprintf('%s was processed',imgName))
end
