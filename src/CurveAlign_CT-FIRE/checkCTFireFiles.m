function ctfFnd = checkCTFireFiles(pathName, fileName)
% Make sure all CT-FIRE files are there
% returns a array of flags 
% CTFireOut files must be in same directory as SHG image files.
% Naming convention: ctFIREout_[Image Name wout ext].mat
%
% Inputs
%    pathname = path to the current set of images
%    fileName = CELL array of filenames    
%    
% Outputs
%    ctfFnd = logic array of output files existance, with 0 indicating not
%    output found, 1 found output file
%    
% Jeremy Bredfeldt, LOCI 2014

    %list out current directory
    img_path = strrep(pathName,'ctFIREout','');
    fileList = dir(pathName);
    lenFileList = length(fileList);
    numImgs = length(fileName);   
    
    %preallocate space for ctFire files cell array
     ctfFnd = zeros(numImgs,1);    
    for i = 1:numImgs
        fndFlag = 0; %reset found flag
        %parse out only filename, without extension
        [~, imgName, ~] = fileparts(fileName{i});
        info = imfinfo(fullfile(img_path,fileName{i}));
        numSections = numel(info);
        if numSections == 1
            ctFireName = ['ctFIREout_' imgName '.mat'];
            ctfCSVname = ['Hist*_' imgName '.csv'];
        else
            ctFireName = ['ctFIREout_' imgName '_s1.mat'];  % first slice
            ctfCSVname = ['Hist*_' imgName '_s1.csv'];
        end
        %search directory for a file with correct naming convention 
         matfiles = dir(fullfile(pathName,ctFireName));
         csvfiles = dir(fullfile(pathName,ctfCSVname));
         if ~isempty(matfiles)
                ctfFnd_mat = matfiles(1).name;
                if (numSections > 1)
                    fprintf('%2d/%2d:Found mat file %s for the first slice of %s  \n',i,numImgs,ctfFnd_mat,imgName);
                elseif (numSections == 1)
                    disp(sprintf('%2d/%2d:Found %s',i,numImgs,ctfFnd_mat));
                end
                if length(csvfiles) == 4
                    fprintf('    Found all %d correspoingding csv files for %s \n',4,ctFireName)  
                    ctfFnd(i) = 1;
                else
                    fprintf('    Found only %d correspoingding csv files for %s \n',length(csvfiles),ctFireName)
                    ctfFnd(i) = 0;
                end
         else
             disp(sprintf('%2d/%2d: Can not find mat file for %s.',i,numImgs,imgName));
         end
    end

end