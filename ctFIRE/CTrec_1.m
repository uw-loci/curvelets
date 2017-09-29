function OUTct = CTrec_1(img,fctr,pct,SS,plotflag)
% obtaining curvelet transform based reconstruction image
% with the functionality of denoising the image and enhancing the fiber edges
% Specify the curvelet coefficient threshold and scale combinations in advace
% Input:
%    img: 2D array
%    fctr: name of the reconstructed image .mat file
%    pct: percentile of the curvelet coefficients to be kept
%    SS: selected scales to be used to reconstruct the image
%    plotflag: plot or not the reconstructed image

% Output:
%    OUTct: a 2D array of the reconstructed image
% save the reconstructed results in a subfolder \imgPath\ctFIREout\\

%
% Yuming Liu, LOCI, UW-Madison, since June 2012

% dir1 = imgPath;
% dir2 = [dir1,'ctFIREout\'];
CTimg = strrep(strrep(fctr,'CTR_','CTRimg_'),'.mat','.tif');
IS = img;
[pixh pixw] = size(IS);

% Set the percentage of coefficients used in the partial reconstruction
pctg = pct;
% Forward curvelet transform
C = fdct_wrapping(double(IS),0); % nbscales =ceil(log2(min(N1,N2)) - 3)

% Get the threshold value
cfs =[];
for s=1:length(C)
    for w=1:length(C{s})
        cfs = [cfs; abs(C{s}{w}(:))];
    end
end
%     cfs = sort(cfs); cfs = cfs(end:-1:1);
cfs = sort(cfs,'descend');

% get specific threshold
nb = round(pctg*length(cfs));
cutoff = cfs(nb);

% Set small coefficients to zero
for s=1:length(C)
    for w=1:length(C{s})
        C{s}{w} = C{s}{w} .* (abs(C{s}{w})>cutoff);
    end
end

% create an empty cell array of the same dimensions
Ct = cell(size(C));
for cc = 1:length(C)
    for dd = 1:length(C{cc})
        Ct{cc}{dd} = zeros(size(C{cc}{dd}));
    end
end

% select the scale(s) at which the coefficients will be used
%      s = length(C) - 3:length(C)-1 ;
s = length(C)-SS:length(C)-1;
%    s = 1:length(C);

for iS = s
    Ct{iS} = C{iS};
end
Y = ifdct_wrapping(Ct,0);
CTr = real(Y);

OUTct = CTr;

if plotflag
    gcf2 = figure('name','CT reconstructed image ','numbertitle','off','Visible','off');
    screenZ = get(0,'screensize');
    f1x = round(0.54*screenZ(4)); % figure1 x start point
    f1y = round(0.35*screenZ(4));   % figure 1 y start point
    f1wid =round(0.5*screenZ(4)); % width of figure1
    imagesc(CTr); colormap gray; axis('image'); title(sprintf('CT partial reconstruction of s%d - s%d',s(1),s(end)));
    set(gcf2,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128]);
    print(gcf2,'-dtiff', '-r128', CTimg);  % CT reconstructed image
    set(gcf2,'position',[f1x, f1y, f1wid,round(f1wid*pixh/pixw)]);
end
disp('curvelet transform based reconstruction is done')




