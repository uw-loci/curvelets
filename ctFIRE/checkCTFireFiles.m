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
    numImgs = length(fileName);   
    
    %preallocate space for ctFire files cell array
    ctfFnd = cell(numImgs);    
    
    for i = 1:numImgs
        fndFlag = 0; %reset found flag
        %parse out only filename, without extension
        [~, imgName, ~] = fileparts(fileName{i});
        ctFireName = ['ctFIREout_' imgName '.mat'];
        %search directory for a file with correct naming convention 
         matfiles = dir(fullfile(pathName,ctFireName));
         if ~isempty(matfiles)
                ctfFnd{i} = matfiles(1).name;
                if (length(matfiles) > 1)
                    disp(sprintf('Found %d mat file(s) for %s \n first .mat is %s',length(matfiles),imgName,ctfFnd{i}));
                elseif (length(matfiles) == 1)
                    disp(sprintf('Found %s',ctfFnd{i}));
                end
                fndFlag = 1;
         end
         
        if fndFlag == 0
            %missing a ctFire file, abort analysis
            disp(['Cannot find ' ctFireName '. Make sure all CT-Fire output files are present and named correctly. See users manual.']);
            ctfFnd = {};
            break;
        end
    end

end