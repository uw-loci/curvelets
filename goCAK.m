function goCAK(CAPfile)
%tempFolder = uigetdir(pathNameGlobal,'Select Output Directory:');
%compile: mcc -m goCAK.m
% compile: mcc -m goCAK.m -a ./CurveLab-2.1.2/fdct_wrapping_matlab -a ./CircStat2012a  -R '-startmsg,"Starting gocak Windows 64-bit ..."'

if ~isdeployed
    addpath('./CircStat2012a','./CurveLab-2.1.2/fdct_wrapping_matlab');
end
%  OS = 0;        %numeric
% pathName = 'C:\Users\yuming\Desktop\CAA\widthandcancerprogression\Humandata_from_Jeremy with ROIs\';% string
% fileName1 = '1B_D3_SHG_ROI_TACS3positive.tif-1.tif';    % string
% fibMode = 1; % dropdown menu: 0: CT; 1:CT-FIRE Segments;2: CT-FIRE fibers;3:'CT-FIRE Endpoints'
% bndryMode = 0; % dropdown menu: 0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary
% keep = 0.05;
% distThresh = 100;
% %check if user directed to output boundary association lines (where
% %on the boundary the curvelet is being compared)
% makeAssocFlag = 1;   % check box
% 
% makeFeatFlag = 1;   % check box
% makeOverFlag = 1;   % check box
% makeMapFlag = 1;   % check box
% 
% infoLabel = 'delete later';  % string
% 
% filename = fullfile(pathName,['CAPfile_',fileName1,'.txt']);
% 
% fid = fopen(filename,'w');
% % run parameters
% fprintf(fid,'%2.1f\n',OS);
% fprintf(fid,'%s\n',pathName);
% fprintf(fid,'%s\n' ,fileName1);
% fprintf(fid,'%2.1f\n',fibMode);
% fprintf(fid,'%2.1f\n',bndryMode);
% fprintf(fid,'%5.4f\n',keep);
% fprintf(fid,'%4.3f\n',distThresh);
% fprintf(fid,'%2.1f\n',makeAssocFlag);
% fprintf(fid,'%2.1f\n',makeFeatFlag);
% fprintf(fid,'%2.1f\n',makeOverFlag);
% fprintf(fid,'%2.1f\n',makeMapFlag);
% fprintf(fid,'%s\n',infoLabel);
% 
% fclose(fid);

%
% CAPfile = 'CAPfile_1B_D3_SHG_ROI_TACS3positive.tif-1.tif.txt';
fid = fopen(CAPfile);
OS = str2num(fgetl(fid));%fscanf('%2.1f',fid)
pathName = fgetl(fid);
% pathName = pwd;
fileName1 = fgetl(fid);    % string
fibMode = str2num(fgetl(fid)); % dropdown menu: 0: CT; 1:CT-FIRE Segments;2: CT-FIRE fibers;3:'CT-FIRE Endpoints'
bndryMode = str2num(fgetl(fid)); % dropdown menu: 0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary
keep = str2num(fgetl(fid));
distThresh = str2num(fgetl(fid));
%check if user directed to output boundary association lines (where
%on the boundary the curvelet is being compared)
makeAssocFlag = str2num(fgetl(fid));   % check box
makeFeatFlag = str2num(fgetl(fid));   % check box
makeOverFlag = str2num(fgetl(fid));   % check box
makeMapFlag = str2num(fgetl(fid));   % check box
infoLabel = fgetl(fid);  % string
fclose(fid)

% if loading CT-FIRE data
if fibMode ~= 0
    ctfFnd = '';
    ctfFnd = checkCTFireFiles(pathName, {fileName1});
    if (isempty(ctfFnd))
    
        disp('One or more CT-FIRE files are missing.');
        return;
    end
end

fileName = {fileName1};
if OS == 1
    outDir = [pathName '\CA_Out\'];   % for PC
elseif OS == 0
    outDir = [pathName '/CA_Out/'];     % for MAC
end
if ~exist(outDir,'dir')
    mkdir(outDir);
end

%         IMG = getappdata(imgOpen,'img');
% keep = get(enterKeep,'UserData');
% distThresh = get(enterDistThresh,'UserData');
% keepValGlobal = keep;
% distValGlobal = distThresh;
% save('lastParams.mat','pathNameGlobal','keepValGlobal','distValGlobal');

% set([imgRun makeHist makeRecon enterKeep enterDistThresh imgOpen makeValues makeAssoc makeFeat makeMap makeOver],'Enable','off')

if isempty(keep)
    %indicates the % of curvelets to process (after sorting by
    %coefficient value)
    keep = .001;
end

if isempty(distThresh)
    %this is default and is in pixels
    distThresh = 100;
end

if bndryMode == 2 || bndryMode == 3
    %     setappdata(guiFig,'boundary',1)
elseif bndryMode == 0
    coords = []; %no boundary
    bdryImg = [];
else
    %     [fileName2,pathName] = uiputfile('*.csv','Specify output file for boundary coordinates:',pathNameGlobal);
    %     fName = fullfile(pathName,fileName2);
    %     csvwrite(fName,coords);
end

if bndryMode == 2 || bndryMode == 3
    %check to make sure the proper boundary files exist
    bndryFnd = checkBndryFiles(bndryMode, pathName, fileName);
    if (~isempty(bndryFnd))
        %Found all boundary files
        %         set(enterDistThresh,'Enable','on');
        %         set(infoLabel,'String',[str 'Enter distance value. Click Run.']);
        %         set(makeAssoc,'Enable','on');
    else
        %Missing one or more boundary files
        %         set(infoLabel,'String',[str 'One or more boundary files are missing.']);
        %         return;
    end
end

% %check if user directed to output boundary association lines (where
% %on the boundary the curvelet is being compared)
% makeAssocFlag = get(makeAssoc,'Value') == get(makeAssoc,'Max');
%
% makeFeatFlag = get(makeFeat,'Value') == get(makeFeat,'Max');
% makeOverFlag = get(makeOver,'Value') == get(makeOver,'Max');
% makeMapFlag = get(makeMap,'Value') == get(makeMap,'Max');
%check to see if we should process the whole stack or current image
%wholeStackFlag = get(wholeStack,'Value') == get(wholeStack,'Max');


%loop through all images in batch list
for k = 1:length(fileName)
    disp(['Processing image # ' num2str(k) ' of ' num2str(length(fileName)) '.']);
    [~, imgName, ~] = fileparts(fileName{k});
    ff = fullfile(pathName,fileName{k});
    info = imfinfo(ff);
    numSections = numel(info);
    
    %Get the boundary data
    if bndryMode == 2
        coords = csvread([pathName bndryFnd{k}]);
    elseif bndryMode == 3
        bff = fullfile(pathName, bndryFnd{k});
        bdryImg = imread(bff);
        [B,L] = bwboundaries(bdryImg,4);
        coords = B;%vertcat(B{:,1});
        %                  coords = vertcat(B{2:end,1});
    end
    
    %loop through all sections if image is a stack
    for i = 1:numSections
        
        if numSections > 1
            IMG = imread(ff,i,'Info',info);
            set(stackSlide,'Value',i);
            slider_chng_img(stackSlide,0);
        else
            IMG = imread(ff);
        end
        if size(IMG,3) > 1
            %if rgb, pick one color
            IMG = IMG(:,:,1);
        end
        
%         figure(1);
        IMG = imadjust(IMG);
%         %             imshow(IMG,'Parent',imgAx);
%         imshow(IMG);
        
        
        if bndryMode == 1 || bndryMode == 2   % csv boundary
            bdryImg = [];
            [fibFeat] = processImageCK(IMG, imgName, outDir, keep, coords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, i, infoLabel, bndryMode, bdryImg, pathName, fibMode, 0,numSections);
        else %bndryMode = 3  tif boundary
            %                      ff = [pathName fileName{k}];
            % bff = [pathName '[pathName bndryFnd{k}];
            %                      CAP = {'ff','imgName', 'outDir', 'keep', 'coords', 'distThresh', makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, i, infoLabel, bndryMode, bdryImgN, pathName, fibMode, flag1,numSections}
            
            [fibFeat] = processImageCK(IMG, imgName, outDir, keep, coords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, i, infoLabel, bndryMode, bdryImg, pathName, fibMode, 0,numSections);
            
            disp(sprintf('done with %s',imgName));
            %                      [fibFeat] = processImage(IMG, imgName, outDir, keep, coords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, i, infoLabel, bndryMode, bdryImg, pathName, fibMode, 0,numSections);
        end
    end
end

return

end