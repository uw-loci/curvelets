function ctfFnd = checkCTFoutput(pathName, fileName)
% Check the CT-FIRE output files in "ctFIREout" folder.
% Returns a cell array of CT-FIRE file names.
% Naming convention: ctFIREout_[Image Name wout ext].mat
%
% Inputs
%    pathname = path to the current set of images
%    fileName = CELL array of filenames    
%    
% Outputs
%    ctfFnd = CELL array of found CT-FIRE output files, empty if no file is
%    found
%    
% modified from checkCTFiles.m in CurveAlign implementation

    %list out current directory
    numImgs = length(fileName);   
    %preallocate space for ctFire files cell array
    ctfFnd = cell(numImgs,1);   
    for i = 1:numImgs
        fndFlag = 0; %reset found flag
        %parse out only filename, without extension
        [~, imgName, ~] = fileparts(fileName{i});
        ctFireName = ['OL_ctFIRE_' imgName '*.tif'];
        %search directory for a file with correct naming convention 
         OLfiles = dir(fullfile(pathName,'ctFIREout',ctFireName));
         if ~isempty(OLfiles)
                ctfFnd{i,1} = OLfiles(1).name;
                fndFlag = 1;
         end
         if fndFlag == 0  %missing a ctfire overlay image,
            ctfFnd{i} = {};
         end
    end

end