function ctfFnd = checkCTFireFiles(pathName, fileName)
% Make sure all CT-FIRE files are there
% returns a cell array of CT-FIRE file names.
% CTFireOut files must be in same directory as SHG image files.
% Naming convention: ctFIREout_[Image Name wout ext].mat
%
% Inputs
%    pathname = path to the current set of images
%    fileName = CELL array of filenames    
%    
% Outputs
%    ctfFnd = CELL array of found CT-FIRE output files, empty if a file is missing
%    
% Jeremy Bredfeldt, LOCI 2014

    %list out current directory
    fileList = dir(pathName);
    lenFileList = length(fileList);
    numImgs = length(fileName);   
    
    %preallocate space for ctFire files cell array
    ctfFnd = cell(numImgs);    
    
    for i = 1:numImgs
        fndFlag = 0; %reset found flag
        %parse out only filename, without extension
        [~, imgName, ~] = fileparts(fileName{i});
        ctFireName = ['ctFIREout_' imgName '.mat'];
        %search directory for a file with correct naming convention 
        for j = 1:lenFileList
            %search for pattern
            if regexp(fileList(j).name,ctFireName,'once','ignorecase') == 1
                ctfFnd{i} = fileList(j).name;
                disp(['Found ' fileList(j).name]);
                fndFlag = 1;
                break;
            end
        end
        if fndFlag == 0
            %missing a ctFire file, abort analysis
            disp(['Cannot find ' ctFireName '. Make sure all CT-Fire output files are present and named correctly. See users manual.']);
            ctfFnd = {};
            break;
        end
    end

end