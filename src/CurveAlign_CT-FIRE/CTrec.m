function OUTct = CTrec(imgName,imgPath)
% basic verson for obtaining curvelet transform based reconstruction image  
% with the functionality of denoising the image and enhancing the fiber edges
% Specify the curvelet coefficient threshold and scale combinations in advace
% Input:
%    imgName: name of the image to be processed
%    imgPath: path of the image to be processed
% Output:
%    OUTct: a 2D array of the reconstructed image
% save the reconstructed results in a subfolder \imgPath\ctFIREout\

% Yuming Liu, LOCI, UW-Madison, since June 2012

dir1 = imgPath;
mkdir(imgPath,'ctFIREout');
dir2 = [imgPath,'ctFIREout\'];

for iN = 1 
    fname = imgName;
    disp(sprintf('file name %d = %s',iN,fname));
    fctr = [dir2,'CTR_',fname(1:end-5),'.mat'];% filename of the curvelet transformed reconstructed image dataset
    CTimg = [dir2, 'CTRimg_',fname(1:end-5),'.tif'];  % filename of the curvelet transformed reconstructed image

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
    pctg = 0.2;  % 0803: 0.2 ; 

    % Forward curvelet transform
    disp(sprintf('reconstructing image %d',iN));
    C = fdct_wrapping(double(IS),0);
    
%     nbscales =ceil(log2(min(N1,N2)) - 3)

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
     s = length(C) - 3:length(C)-1 ;
    %    s = 1:length(C);

    for iS = s 
        Ct{iS} = C{iS};
    end
    Y = ifdct_wrapping(Ct,0);
    CTr = real(Y);
    figure(100+iN);clf
    set(gcf,'position',[100 50 pixw*0.6 pixh*0.6]);
    title1 = fname(1:end-5);
    title2 = strrep(title1,'_','-');
    
    ax(1) = subplot(1,2,1); colormap gray; imagesc(IS); axis('image'); title(sprintf('Original image%d, %s',iN,title2));
    ax(2) = subplot(1,2,2); colormap gray; imagesc(CTr); axis('image'); title(sprintf('CT partial reconstruction,s%d - s%d',s(1),s(end)));
    pause(2);
    linkaxes([ax(2) ax(1)],'xy');
    save(fctr,'CTr'); 

    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 2*pixw/128 pixh/128]);
    print('-dtiff', '-r128', CTimg);  % CT reconstructed image
    OUTct = CTr;
    clear C Ct
end  % iN
       
