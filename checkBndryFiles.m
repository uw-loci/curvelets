function bndryFnd = checkBndryFiles(bndryMode, pathName, fileName)
% Make sure all boundary files are there
% returns a cell array of boundary file names.
% Boundary files must be in same directory as image files.
% CSV naming convention: boundary for [Image Name w/ ext].csv
% Tif naming convention: mask for [Image Name w/ ext].tif
%
% Inputs
%   bndryMode = 2: csv boundaries, = 3: tif boundaries
%   pathname = path to the current set of images
%   fileName = CELL array of filenames    
%    
% Outputs
%   bndryFnd = CELL array of found boundary files, empty if a file is missing
%    
% Jeremy Bredfeldt, LOCI 2014

    %list out current directory
    fileList = dir(pathName);
    lenFileList = length(fileList);
    numImgs = length(fileName);   
    
    %preallocate space for boundary files cell array
    bndryFnd = cell(numImgs);    
    
    for i = 1:numImgs
        fndFlag = 0; %reset found flag        
        if bndryMode == 2
            bndryName = ['boundary for ' fileName{i} '.csv'];
        elseif bndryMode == 3
            bndryName = ['mask for ' fileName{i} '.tif'];
        else
            disp('Wrong boundary mode. No boundary files available.');
            return;
        end
        
        %search directory for a file with correct naming convention 
        for j = 1:lenFileList
            %search for pattern
            if regexp(fileList(j).name,bndryName,'once','ignorecase') == 1
                bndryFnd{i} = fileList(j).name;
                disp(['Found ' fileList(j).name]);
                fndFlag = 1;
                break;
            end
        end
        if fndFlag == 0
            %missing a ctFire file, abort analysis
            disp(['Cannot find: "' bndryName '." Make sure all boundary files are present and named correctly. See users manual.']);
            bndryFnd = {};
            break;
        end
    end

end