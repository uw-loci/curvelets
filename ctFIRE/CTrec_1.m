function OUTct = CTrec_1(imgPath,imgName,fctr,pct,SS,plotflag)
% obtaining curvelet transform based reconstruction image
% with the functionality of denoising the image and enhancing the fiber edges
% Specify the curvelet coefficient threshold and scale combinations in advace
% Input:
%    imgName: name of the image to be processed
%    imgPath: path of the image to be processed
%    fctr: name of the reconstructed image .mat file
%    pct: percentile of the curvelet coefficients to be kept
%    SS: selected scales to be used to reconstruct the image
%    plotflag: plot or not the reconstructed image

% Output:
%    OUTct: a 2D array of the reconstructed image
% save the reconstructed results in a subfolder \imgPath\ctFIREout\

% Yuming Liu, LOCI, UW-Madison, since June 2012

% dir1 = imgPath;
% dir2 = [dir1,'ctFIREout\'];
CTimg = strrep(strrep(fctr,'CTR_','CTRimg_'),'.mat','.tif');

for iN = 1
    fname = [imgPath,imgName];
    %     disp(sprintf('file name %d = %s',iN,imgName));
    %     fctr = [dir2,'CTR_',imgName(1:end-5),'.mat'];% filename of the curvelet transformed reconstructed image dataset
    %     CTimg = [dir2, 'CTRimg_',imgName(1:end-5),'.tif'];  % filename of the curvelet transformed reconstructed image
    
    info = imfinfo(fname);
    num_images = numel(info);
    pixw = info(1).Width;  % find the image size
    pixh = info(1).Height;
    IMG = imread(fname);
    
    if length(size(IMG)) > 2
        IS =IMG(:,:,1);
    else
        IS = IMG;
    end
    
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
        gcf2 = figure(55);clf  % figure for reconstruciton image
        set(gcf2,'name','CT reconstructed image ','numbertitle','off')
        screenZ = get(0,'screensize');
        f1x = round(0.54*screenZ(4)); % figure1 x start point
        f1y = round(0.35*screenZ(4));   % figure 1 y start point
        f1wid =round(0.5*screenZ(4)); % width of figure1
        
        
        Fdot = strfind(imgName,'.'); % find the '.' in the image name;
        Inamenf = imgName(1:Fdot(end)-1);   % image name with no format information
        title1 = Inamenf;  title2 = strrep(title1,'_','-');
        imagesc(CTr); colormap gray; axis('image'); title(sprintf('CT partial reconstruction of %s,s%d - s%d',title2,s(1),s(end)));
        
        set(gcf2,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128]);
        print(gcf2,'-dtiff', '-r128', CTimg);  % CT reconstructed image
        set(gcf2,'position',[f1x, f1y, f1wid,round(f1wid*pixh/pixw)]);
        %     save(fctr,'CTr');
    end
    
    
end  % iN

disp('curvelet transform based reconstruction is done')



