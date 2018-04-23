function [] = compare2Fiji(ImMat,FijiImag)
% Define compare2Fiji function to compare Matlab converted to 8Bit files with the same image in
% Fiji
%Steps
%   1. Read in both files as pixel intensity maps
%   2. Compare the pixel intensities for differences
%   3. Report any differences
%[filePath1,fileName1,fileExtension1] = fileparts(ImagMatlab); % Parse path/file details
%[filePath2,fileName2,fileExtension2] = fileparts(FijiImag); % Parse path/file details
IMatlab = imread(ImMat); % read in Matlab converted image
IFiji = imread(FijiImag); % read in Fiji converted image
% Display image details
whos IMatlab
whos IFiji
% Find percent differences between pixels Matlab to Fiji image
DiffImg = imabsdiff(IMatlab,IFiji);
logInd = DiffImg ~= 0;
IMatDiff = IMatlab(logInd);
IFijiDiff = IFiji(logInd);
percentDiff = double(IMatDiff)./double(IFijiDiff);
[m1,n1] = size(IMatlab);
[m2,n2] = size(IFiji);
if m1 == m2 && n1 == n2
   [m3,n3] = size(IMatDiff);
    percentPixDiff = m3/(m1*n1);
    wghtPixDiff = mean([mean(percentDiff),1.]); % average of the % differences of each pixel between each image
    fprintf('%f%% of the total pixels in the images have different values.\n',percentPixDiff*100)
    fprintf('The images are %f%% the same, comparing averaged pixel value difference %% between images.\n',wghtPixDiff*100)
else
    display('The length and width (pixel) dimensions of compared images do not match.')
        drawnow
        return;
end
%tf = isequal(IMatlab,IFiji);
%if tf == 1
%    compresult = 'The compared images are the same.';
% else
%     if tf == 0
%         compresult = 'The compared images are NOT the same.';
%     else
%         display('There was an error in image comparison.')
%         drawnow
%         return;
%     end
% end
% display(compresult)
end
