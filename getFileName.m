function imgName = getFileName(imgType,fileName)

% getFileName.m
% This function creates filenames for the output of makeOutput.m
% 
% Carolyn Pehlke, Laboratory of Optical and Computational Instrumentation, July 2010

if (iscell(imgType) && iscell(fileName))
    
    nameEnd = cellfun(@(x,y) regexp(x,y),fileName,imgType);
    
    for yy = 1:length(fileName)
        imgName{yy} = fileName{yy}(1:nameEnd-1);
    end
    
else
    nameEnd = regexp(fileName,imgType);
    imgName = fileName(1:nameEnd-1);
end