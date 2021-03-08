function OUTctf = ctFIRE_1(imgName,imgPath)

% ctFIRE to process one image each time 
% image
% Input: 
%   imgName: name of the image to be processed
%   imgPath: path of the image to be processed

% Output:
%   OUTctf: a structure containing the extracted fiber information
% with options to process the original as well as show and save result images in
% a subfolder \imgPath\ctFIREout\
  
% set search path for  FIRE functions
cd Z:\liu372\CAA\FIRE\example\;
pd1 = pwd;
addpath(genpath('../')); 

tic

% parameters for showing the image
LW1 = 0.5;         % line width of the extracted fibers 
LL1 = 30;  %082812: length limit(threshold), only show fibers with length >LL
FNL = 2999; %: fiber number limit(threshold), maxium fiber number to be shown 
texton = 0;  % texton = 1, label the fibers; texton = 0: no label


mkdir(imgPath,'ctFIREout');
dir6 = [imgPath,'ctFIREout\'];% directory to to store the overlayed image output
dir4 = dir6;     % directory to store CT reconstruction images and the FIRE and ctFIRE structure output 

% set the method to run, 1: run; 0:not run
runORI = 1;  % 1: process the original image
runCT = 1; %   1: process the CT reconstruction image 

plotORI = 0;  % plot and save the results of the FIRE results
plotCT = 1;   % plot and save the results of the ctFIRE results

OUTctf = [];   % initialize the output
iNF = 1          % only process one image each time

for iN = iNF 
    
    fname =imgName;
    fname0 = fname;
    %% for image name ends with ".tiff"
    fmat1 = [dir6,sprintf('JBreg%d_FIREout_%s',iN,fname0(1:end-5)),'.mat'];
    fmat2 = [dir6,sprintf('JBreg%d_FIRECTrout_%s',iN,fname0(1:end-5)),'.mat'];
    fctr = [dir6,'CTR_',fname(1:end-5),'.mat'];% filename of the curvelet transformed reconstructed image dataset
    fOL1 = [dir4,'OL_FIRE_',fname(1:end-5),'.tif']; %filename of overlay 1
    fOL2 = [dir4, 'OL_CTpFIRE_',fname(1:end-5),'.tif']; %filename of overlay 2

    %fire parameters
     p1.path = pd1;
     p1 = param_reg1_0530(p1);
     p2 = param_reg1_0530(p1);
     p2.thresh_im2 = 0; 
     
    info = imfinfo(fname);
    num_images = numel(info);
    pixw = info(1).Width;  % find the image size
    pixh = info(1).Height;   
    pix = [pixw pixh];
       
    % initialization 
    ImgL = [0,100];
    OUT = [];
    kk = 0;
    IS1 =[];
    IS = [];
    im3 = [];
   ii = 1; %1:num_images

   if iN == 0
       IS = imread(fname,ii,'PixelRegion', {[1 pixw] [1 pixh]});   
   else
      IS1 = imread(fname);  
      if length(size(IS1)) > 2
          IS =IS1(:,:,1);
      else
          IS = IS1;
      end
   end
    
    disp(sprintf('reading slice %d of %d ',ii,num_images))
    im3(1,:,:) = IS;
    IS1 = flipud(IS1);  % associated with the following 'axis xy'
    % mask_ori to reduce the artifacts in the reconstructed image
    mask_ori = IS > 0.8*p1.thresh_im2; 

    ISresh = sort(reshape(IS,1,pixw*pixh));        
    Ith(ii,1:15) = ISresh(ceil(pixw*pixh*[0.85:0.01:0.99]));
    p1.thresh_im2= ISresh(ceil(pixw*pixh*0.90));
    
    p = p1;
    
   % mask_ori to reduce the artifacts in the reconstructed image
    mask_ori = IS > 0.8*p1.thresh_im2; 
    
    Llow = 0; %p.thresh_im2-20;
    Lup =  p.thresh_im2*2;
    ImgL = [Llow,Lup];
   clear ISresh

   if runORI == 1
        try
        %run main FIRE code
            if iN == 0%7  
               load(fmat1,'data');
            else
                  figure(1); clf
                  data1 = fire_2D_ang1(p,im3,0);  %uses im3 and p as inputs and outputs everything
                  data = data1;
                  save(fmat1,'data','fname','p1');
                 
            end
            
            home
            disp(sprintf('Image -%s: Test%d of %d has been processed',fname0,iN,length(Fnum)))
           if plotORI == 1
                    FN = find(data.M.L > LL1);
                    FLout = data.M.L(FN);
                    LFa = length(FN);

                    if LFa > FNL
                        LFa = FNL;
                    end
                     rng(1001)           
                     clrr1 = rand(LFa,3); % set random color       

                   % overlay FIRE extracted fibers on the original image
                    figure(51);clf;
                    set(gcf,'position',[100 50 pixw/2 pixh/2]);
                    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128]);
                    imshow(IS1); colormap gray; axis xy; hold on;

                   for LL = 1:LFa

                        VFa.LL = data.Fa(1,FN(LL)).v; 
                        XFa.LL = data.Xa(VFa.LL,:);
                        plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr1(LL,1:3),'linewidth',LW1);

                        hold on
                        axis equal;
                        axis([1 pixw 1 pixh]);

                   end
                   set(gca, 'visible', 'off')
                   print('-dtiff', '-r128', fOL1);  % overylay FIRE extracted fibers on the original image
           end   % plotORI
        catch
            home
            kk = kk +1;
            sskipped(kk) = ii;                   % slice skipped
            disp(sprintf('IMG %d is skipped',iN));
%             disp('Press any key to continue ...')
%             pause

        end    
   end % runORI

   %% run FIRE on curvelet transform based reconstruction image
  if runCT == 1 %
   
%      load(fctr,'CTr');

    CTr = CTrec(imgName,imgPath);
  % add mask_ori
    CTr = CTr.*mask_ori;
     
    IS2 = flipud(CTr);
    imagesc(IS2);axis xy; axis equal; colormap gray;
    title(sprintf('CT-based reconstructed image'), 'fontsize',12);
    
%run main FIRE code 
try
     p = p2;
     ImgL = [0  p.thresh_im2*2]
     im3 = [];
     im3(1,:,:) = CTr;
     ii = 1;
    if iN == 0% 
        load(fmat2,'data');
    else
        figure(1); clf
        data2 = fire_2D_ang1(p,im3,0);  %uses im3 and p as inputs and outputs everything listed below
        home
        disp(sprintf('Reconstructed image of Test%d has been processed',iN))
        data = data2; 
        save(fmat2,'data','fname','fctr','p2');
        OUTctf = data;
    end
    
    if plotCT == 1
        FN = find(data.M.L>LL1);
        FLout = data.M.L(FN);
        LFa = length(FN);

        if LFa > FNL
            LFa = FNL;
        end

        rng(1001)           
        clrr2 = rand(LFa,3); % set random color 

        % overlay CTpFIRE extracted fibers on the original image
        figure(52);clf;
        set(gcf,'position',[300 50 pixw/2 pixh/2]);
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128])
        imshow(IS1); colormap gray; axis xy; axis equal; hold on;
    %     clrr0 = 'rgbmcyg';
        for LL = 1:LFa

            VFa.LL = data.Fa(1,FN(LL)).v;
            XFa.LL = data.Xa(VFa.LL,:);
            plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',LW1);
            hold on
            axis equal;
            axis([1 pixw 1 pixh]);
        end
         set(gca, 'visible', 'off')
         print('-dtiff', '-r128', fOL2);
     
    end % plotCT
        
     catch
            home
            kk = kk +1;
            sskipped(kk) = ii;                   % slice skipped
            disp(sprintf('Reconstruction IMG %d is skipped',iN));
        end    
     
   end %runCT
   
end % iNF

t_run = toc;  
fprintf('total run time for ctFIRE = %2.1f minutes\n',t_run/60)

    