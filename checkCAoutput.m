function CAFnd = checkCAoutput(pathName, fileName)
% Check the CA output files in "CA_Out" folder.
% Returns a cell array of CA output file names.
% Naming convention: [imgName '*fibFeatures.MAT']
%
% Inputs
%    pathname = path to the current set of images
%    fileName = CELL array of filenames    
%    
% Outputs
%    CAFnd = CELL array of found CA output files, empty if no file is
%    found
%    
% modified from checkCTFiles.m in CurveAlign implementation

    %list out current directory
    numImgs = length(fileName);   
    %preallocate space for CA files cell array
    CAFnd = cell(numImgs,1);   
    for i = 1:numImgs
        fndFlag = 0; %reset found flag
        %parse out only filename, without extension
        [~, imgName, ~] = fileparts(fileName{i});
        iteminfo = imfinfo(fullfile(pathName,fileName{i}));
        numSections = numel(iteminfo);
        if numSections == 1
            FEAdataName = [imgName '_fibFeatures.mat'];
        elseif numSections > 1
            FEAdataName = [imgName '_s*_fibFeatures.mat'];
        end
        %search directory for a file with correct naming convention 
         FEAfiles = dir(fullfile(pathName,'CA_Out',FEAdataName));
         if ~isempty(FEAfiles)
                CAFnd{i,1} = FEAfiles(1).name;
                fndFlag = 1;
         end
         if fndFlag == 0  %missing a ctfire overlay image,
            CAFnd{i} = {};
         end
    end

end