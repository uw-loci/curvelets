function [Ct OUTct feature_set] = ctFeatures(imgPath,imgName,fctr,pct,SS,plotflag,clrflag)


% obtaining curvelet transform based reconstruction image
% with the functionality of denoising the image and enhancing the fiber edges
% Specify the curvelet coefficient threshold and scale combinations in advace
% Input:
%    imgName: name of the image to be processed
%    imgPath: path of the image to be processed
%    fctr: name of the reconstructed image .mat file
%    pct: percentile of the curvelet coefficients to be kept (can be a
%    vector)
%    SS: selected scales to be used to reconstruct the image
%    plotflag: plot or not the reconstructed image
%    clrflag: color flag for plotting

% Output:
%    OUTct: a 2D array of the reconstructed image
%    feature_set: one set of features, per observation, in this case, the
%    observations are each subimage patch
% save the reconstructed results in a subfolder \imgPath\ctFIREout\

% Yuming Liu, Jeremy Bredfeldt, LOCI, UW-Madison, since Feb 2013

% dir1 = imgPath;
% dir2 = [dir1,'ctFIREout\'];
CTimg = strrep(strrep(fctr,'CTR_','CTRimg_'),'.mat','.tif');
fctr = 'testsort1.mat';

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

    %JB Edit    
    %chop the image into pieces, then perform CT on each piece
    crop_w = 511; %this can change, and may need to be optimized
    crop_h = crop_w;
    num_w = floor(pixw/crop_w);
    num_h = floor(pixh/crop_h);
    num_p = length(pct); %number of percentages to try
    
    feature_set = zeros(num_w*num_h,2,num_p); %many observations, 2 features, num_p is a 3rd dimension    
    tidx = 0;
    for xx = 1:num_w
        for yy = 1:num_h            
    %for xx = 4:5
        %for yy = 4:5        
            tidx = tidx + 1;
            disp(sprintf('crop %d,%d',xx,yy));
            xst = (xx-1)*crop_w+1;
            yst = (yy-1)*crop_w+1;
            ISc = IS(yst:yst+crop_h,xst:xst+crop_w); %cropped image
            
            avg_grey(xx,yy) = sum(sum(ISc));
            
            % Forward curvelet transform
            C = fdct_wrapping(double(ISc),0); % nbscales =ceil(log2(min(N1,N2)) - 3)

            % Get the threshold value
            cfs =[];
            Cc = cell(size(C));
            
            for s=1:length(C)
                for w=1:length(C{s})
                    cfs = [cfs; abs(C{s}{w}(:))];
                end
            end
            %     cfs = sort(cfs); cfs = cfs(end:-1:1);
            cfs = sort(cfs,'descend');

            %loop through percentages
            for pp = 1:num_p            
            
                % Set the percentage of coefficients used in the partial reconstruction
                pctg = pct(pp);
                % get specific threshold
                nb = round(pctg*length(cfs));
                cutoff = cfs(nb);

                % Set small coefficients to zero
                
                scn = zeros(1,length(C));                
                R2 = zeros(1,length(C));
                %ctps = [];
                %sum_sctps = zeros(1,length(C));
                for s=1:length(C)
                    numAngs = length(C{s});
                    numCut = zeros(1,numAngs);
                    for w=1:numAngs
                        Cc{s}{w} = C{s}{w} .* (abs(C{s}{w})>cutoff);
                        %number of coefficients above the
                        %cutoff for this orientation and scale
                        numCut(w) = length(find (abs(Cc{s}{w})>cutoff));
                        %add up the number of of big coefficients in each scale
                        scn(s) = scn(s) + numCut(w);                        
                    end

                    %compute the alignment in the angles of the big coefficients at each scale
                    %the actual orientation doesn't matter, just how
                    %aligned are the curvelets                    
                    if numAngs > 1
                        angs = (1:(numAngs/2))*4*pi/numAngs; %angles
                        w = numCut(1:length(angs)); %bin weights
                        wN = w-min(w); %normalized bin weights
                        d = angs(2)-angs(1); %bin spacing                   
                        R2(s) = circ_r(angs,wN,d,2); %compute alignment
                    else
                        R2(s) = 1.0;
                    end
                end  
                
                tot_sc = length(C);
                soi = tot_sc - 1;
                feature_set(tidx,1,pp) = scn(soi); %prevalence
                feature_set(tidx,2,pp) = R2(soi); %alignment

                % create an empty cell array of the same dimensions
                Ct = cell(size(C));
                for cc = 1:length(C)
                    for dd = 1:length(C{cc})
                        Ct{cc}{dd} = zeros(size(C{cc}{dd}));
                    end
                end

                % select the scale(s) at which the coefficients will be used
                %s = length(C) - 3:length(C)-1 ;
                %s = length(C)-SS:length(C)-1;
                %s = 1:(length(C)-1);
                s = length(C)-1;

                for iS = s
                    Ct{iS} = Cc{iS};
                end

                Y = ifdct_wrapping(Ct,0);
                CTr = real(Y);

                OUTct = CTr;

                if plotflag

%                     figure(55); clf;
%                     imagesc(CTr); colormap gray; %colorbar;
%                     figure(56); clf;
%                     imagesc(ISc); colormap gray; %colorbar;
%                     tCTr = CTr-min(min(CTr));
%                     t2CTr = 255*tCTr/max(max(tCTr));
%                     imwrite(uint8(t2CTr),'recon.tiff','tiff','WriteMode','append','Compression','none');
%                     imwrite(ISc,'orig.tiff','tiff','WriteMode','append','Compression','none');
%                     figure(pp); hold on; %clf;
%                     if clrflag == 0
%                         plot(R2,'b*');
%                     else
%                         plot(R2,'ro');
%                     end
%                     
%                     figure(pp+num_p); hold on;
%                     if clrflag == 0
%                         plot(scn,'b*');
%                     else
%                         plot(scn,'ro');
%                     end
                    
                    figure(pp+num_p*2); hold on;
                    if clrflag == 0
                        plot(scn(soi),R2(soi),'b*');                        
                    else
                        plot(scn(soi),R2(soi),'ro');
                    end
                    
                    %pause;
                end
            end                        
        end
    end

    
    
end  % iN

disp('curvelet transform based reconstruction is done')



