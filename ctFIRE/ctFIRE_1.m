function [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,savePath,cP,ctfP)
% function [OUTf,OUTctf] = ctFIRE_1(imgPath,imgName,savePath,cP,ctfP)

% ctFIRE to process one image each time 
% Input: 
%   imgPath: path of the image to be processed
%   imgName: name of the image to be processed
%   savePath: path of the output
%   cP: control parameters for control output image and file
%   ctfP: structure ctFIRE  parameters adjustable on the control panel

% Output:
%   OUTctf: a structure containing the extracted fiber information
%   OUTf: a structure containing the extracted fiber information
% with options to process the original as well as show and save result images in
% a subfolder imgPath\ctFIREout\
  
% set search path for  FIRE functions
% addpath(genpath('../')); 
% addpath(genpath(fullfile('./FIREmod/')))
tic
% status,msg] = xlswrite(filename,A,sheet,range)
edgesA = 0:10:180;            % angle histogram edges
% edgesL = 15:20:115;            % length histogram edges

sz0 = get(0,'screensize');
sw0 = sz0(3);
sh0 = sz0(4);

% cP = struct('plotflag',[],'RO',[],'LW1',[],'LL1',[],'FNL',[],'Flabel',[]);
% ctfp = struct('value',[],'status',[],'pct',[],'SS',[]);
% parameters for showing the image
plotflag = cP.plotflag; %1: plot output image; 0: no output image

postp = cP.postp;  % 1: load .mat file

% run option:
if     cP.RO == 1 ,    runCT = 1;   runORI = 0;  disp(' only run ctFIRE');
elseif cP.RO == 2,     runCT = 0;   runORI = 1;  disp(' only run FIRE');
elseif cP.RO == 3,     runCT = 1;   runORI = 1;  disp('run both ctFIRE and FIRE');
else   error('Need to set a correct run option(RO = 1,2,or 3) ')
end

LW1 = cP.LW1; % default 0.5,line width of the extracted fibers 
LL1 = cP.LL1;  %default 30,length limit(threshold), only show fibers with length >LL
FNL = cP.FNL;   %default 2999; %: fiber number limit(threshold), maxium fiber number to show
texton = cP.Flabel;  % texton = 1, label the fibers; texton = 0: no label
angH = cP.angH ;lenH = cP.lenH ;angV = cP.angV ;lenV = cP.lenV;

dirout = savePath;% directory to to store the overlayed image output

% initilize the output variable
OUTf = struct([]);   % initialize the output
OUTctf = struct([]);   % initialize the output

 if ctfP.status == 1
     disp('using updated FIRE parameter')
 else
     disp('using default FIRE parameters')
 end

%ctFIRE/FIRE parameters
 p1 = ctfP.value;
 
if cP.RO ~= 2    % 2: only run FIRE
    
    p2 = ctfP.value;
    p2.thresh_im2 = 0;
    pct = ctfP.pct;
    SS = ctfP.SS;
end
 
%% name the output image
Iname =imgName;        % image name
fullname = [imgPath, imgName];
Fdot = strfind(Iname,'.'); % find the '.' in the Iname;
Inamenf = Iname(1:Fdot(end)-1);   % image name with no format information  

info = imfinfo(fullname);

pixw = info(1).Width;  % get the image size
pixh = info(1).Height;   
pix = [pixw pixh];

%% name the image stack
% num_images = numel(info);
% for ii = 1:num_images
%     IS1 = imread(fullname,1,'PixelRegion', {[1 pixw] [1 pixh]}); 
%     disp(sprintf('reading slice %d of %d ',ii,num_images))
%     fmat1 = [dirout,sprintf('FIREout_%s_s%d.mat',Inamenf,ii)];    % FIRE .mat output 
%     fmat2 = [dirout,sprintf('ctFIREout_%s_s%d.mat',Inamenf,ii)];  % FIRE .mat output 
%     fctr = [dirout,sprintf('CTR_%s_s%d.mat',Inamenf,ii)];% filename of the curvelet transformed reconstructed image dataset
%     fOL1 = [dirout,sprintf('OL_FIRE_%s_s%d.tif',Inamenf,ii)]; %filename of overlay image for FIRE output
%     fOL2 = [dirout, sprintf('OL_ctFIRE_%s_s%d.tif',Inamenf,ii)]; %filename of overlay image for ctFIRE output 
% end
%%

fmat1 = [dirout,sprintf('FIREout_%s.mat',Inamenf)];    % FIRE .mat output 
fmat2 = [dirout,sprintf('ctFIREout_%s.mat',Inamenf)];  % ctFIRE.mat output
histA1 = [dirout,sprintf('HistA_FIRE_%s.xlsx',Inamenf)];      % xls angle histogram values
histL1 = [dirout,sprintf('HistL_FIRE_%s.xlsx',Inamenf)];      % xls length histgram values     

histA2 = [dirout,sprintf('HistA_ctFIRE_%s.xlsx',Inamenf)];      % xls angle histogram values
histL2 = [dirout,sprintf('HistL_ctFIRE_%s.xlsx',Inamenf)];      % xls length histgram values     


fctr = [dirout,'CTR_',Inamenf,'.mat'];% filename of the curvelet transformed reconstructed image dataset
CTimg = [dirout, 'CTRimg_',Inamenf,'.tif'];  % filename of the curvelet transformed reconstructed image
fOL1 = [dirout,'OL_FIRE_',Inamenf,'.tif']; %filename of overlay image for FIRE output
fOL2 = [dirout, 'OL_ctFIRE_',Inamenf,'.tif']; %filename of overlay image for ctFIRE output 

% initialization 
IS1 =[]; IS = []; im3 = [];
% IS1 = imread(fullname,1,'PixelRegion', {[1 pixw] [1 pixh]}); 
IS1 = imread(fullname); 

if length(size(IS1)) > 2 ,  IS =IS1(:,:,1); else   IS = IS1; end
 
im3(1,:,:) = IS;
IS1 = flipud(IS);  % associated with the following 'axis xy', IS1-->IS

mask_ori = IS > 0.8*p1.thresh_im2; % mask_ori to reduce the artifacts in the reconstructed image

%     ISresh = sort(reshape(IS,1,pixw*pixh));        
%     Ith(ii,1:15) = ISresh(ceil(pixw*pixh*[0.85:0.01:0.99]));
%     p1.thresh_im2= ISresh(ceil(pixw*pixh*0.90));
%     clear ISresh

if runORI == 1
     try
       %run main FIRE code
        if postp == 1%7  
           load(fmat1,'data');
        else
          p= p1;
          data1 = fire_2D_ang1(p,im3,0);  %uses im3 and p as inputs and outputs everything
          disp(sprintf('Original image has been processed'))
          data = data1;
          save(fmat1,'data','Iname','p1');
          OUTf = data;
        end

      
        FN = find(data.M.L > LL1);
        FLout = data.M.L(FN);
        LFa = length(FN);

        if LFa > FNL
            LFa = FNL;
            FN = FN(1:LFa);
            FLout = data.M.L(FN);
        end
            
        if plotflag == 1
             rng(1001) ;          
             clrr1 = rand(LFa,3); % set random color       
            % overlay FIRE extracted fibers on the original image
            gcf51 = figure(51);clf;
            set(gcf51,'name','FIRE output: overlaid image ','numbertitle','off')
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
            set(gcf51,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128]);
            print(gcf51,'-dtiff', '-r128', fOL1);  % overylay FIRE extracted fibers on the original image
            set(gcf51,'position',[0.01*sw0 0.2*sh0 0.5*sh0,0.5*sh0*pixh/pixw]);
        end   % plotflag
        
        % show the comparison of length hist
        inc = (max(FLout)-min(FLout))/10; 
        edgesL = min(FLout):inc:max(FLout);  
        edges = edgesL;    % bin edges
        X1L = FLout;        % length 
        if lenH
            gcf101 = figure(101); clf
            set(gcf101,'name','FIRE output: length distribution ','numbertitle','off')

            set(gcf101,'position',[0.60*sw0 0.55*sh0 0.35*sh0,0.35*sh0])
            [NL,BinL] = histc(X1L,edges);
            bar(edges,NL,'histc');
            axis square
        %     xlim([edges(1) edges(end)]);
            title(sprintf('Extracted length hist'),'fontsize',12);
            xlabel('Length(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)
        end

        if lenV
            xlswrite(histL1,X1L);
        end
            
     % angle distribution:       
        ang_xy = data.M.angle_xy(FN);
        % convert angle 
        temp = ang_xy;
        ind1 = find(temp>0);
        ind2 = find(temp<0);
        ang_xy(ind1)= pi-ang_xy(ind1);
        ang_xy(ind2) = -ang_xy(ind2);
        FA2 = ang_xy*180/pi;   % extracted fiber angle
        X1A = FA2; 

       if angH
            edges = edgesA;    % bin edges
            gcf102 = figure(102); clf
            set(gcf102,'name','FIRE output: angle distribution ','numbertitle','off')
            set(gcf102,'position',[(0.60*sw0+0.35*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
            [NA,BinA] = histc(X1A,edges);
            bar(edges,NA,'histc');
            axis square
            title(sprintf('Extracted angle hist'),'fontsize',12);
            xlabel('Angle(degree)','fontsize',12)
            ylabel('Frequency','fontsize',12) 
       end

       if angV
            xlswrite(histA1,X1A);
       end
          
    catch
        home
        disp(sprintf('FIRE on original Image is skipped'));
     end
             
end % runORI

%% run FIRE on curvelet transform based reconstruction image
if runCT == 1 %
    CTr = CTrec_1(imgPath,imgName,fctr,pct,SS,plotflag); %YL012913
    % add mask_ori
    CTr = CTr.*mask_ori;
%     IS2 = flipud(CTr);
%     imagesc(IS2);axis xy; axis equal; colormap gray;
%     title(sprintf('CT-based reconstructed image'), 'fontsize',12);

    %run main FIRE code 
    try
       
        if postp == 1% 
            load(fmat2,'data');
        else
            im3 = []; im3(1,:,:) = CTr;
            p = p2;
            data2 = fire_2D_ang1(p,im3,0);  %uses im3 and p as inputs and outputs everything listed below
            home
            disp(sprintf('Reconstructed image has been processed'))
            data = data2; 
            save(fmat2,'data','Iname','fctr','p2');
            OUTctf = data;
        end

        FN = find(data.M.L>LL1);
        FLout = data.M.L(FN);
        LFa = length(FN);
        if LFa > FNL
            LFa = FNL;
            FN = FN(1:LFa);
            FLout = data.M.L(FN);
        end
    
        
        if plotflag == 1
            rng(1001) ;          
            clrr2 = rand(LFa,3); % set random color 
            % overlay CTpFIRE extracted fibers on the original image
            gcf52 = figure(52);clf;
            set(gcf52,'name','ctFIRE output: overlaid image ','numbertitle','off')
            set(gcf52,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128])
            imshow(IS1); colormap gray; axis xy; axis equal; hold on;
            for LL = 1:LFa
                VFa.LL = data.Fa(1,FN(LL)).v;
                XFa.LL = data.Xa(VFa.LL,:);
                plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',LW1);
                hold on
                axis equal;
                axis([1 pixw 1 pixh]);
            end
             set(gca, 'visible', 'off')
             print(gcf52,'-dtiff', '-r128', fOL2);
             set(gcf52,'position',[(0.02*sw0+0.5*sh0) 0.2*sh0 0.5*sh0,0.5*sh0*pixh/pixw]);
        end % plotflag
        
             % show the comparison of length hist
        if lenH
            
            inc = (max(FLout)-min(FLout))/10; 
            edgesL = min(FLout):inc:max(FLout);  
            edges = edgesL;    % bin edges
            X2L = FLout;        % length 
            gcf201 = figure(201); clf
            set(gcf201,'name','ctFIRE output: length distribution ','numbertitle','off')
            set(gcf201,'position',[0.60*sw0 0.075*sh0 0.35*sh0,0.35*sh0])
            [NL,BinL] = histc(X2L,edges);
            bar(edges,NL,'histc');
            axis square
        %     xlim([edges(1) edges(end)]);
            title(sprintf('Extracted length hist'),'fontsize',12);
            xlabel('Length(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)     
        end

        if lenV
            xlswrite(histL2,X2L);    
        end
  
     % angle distribution:       
        ang_xy = data.M.angle_xy(FN);
        % convert angle 
        temp = ang_xy;
        ind1 = find(temp>0);
        ind2 = find(temp<0);
        ang_xy(ind1)= pi-ang_xy(ind1);
        ang_xy(ind2) = -ang_xy(ind2);
        FA2 = ang_xy*180/pi;   % extracted fiber angle
        X2A = FA2; 

        if angH
            edges = edgesA;    % bin edges
            gcf202 = figure(202); clf
            set(gcf202,'name','ctFIRE output: angle distribution ','numbertitle','off')
            set(gcf202,'position',[(0.60*sw0+0.35*sh0) 0.075*sh0 0.35*sh0,0.35*sh0])
            [NA,BinA] = histc(X2A,edges);
            bar(edges,NA,'histc');
            axis square
            title(sprintf('Extracted angle hist'),'fontsize',12);
            xlabel('Angle(degree)','fontsize',12)
            ylabel('Frequency','fontsize',12)
        end

        if angV
            xlswrite(histA2,X2A);
        end
  
    catch
            home
            disp(sprintf('ctFIRE on reconstruction image is skipped'));
    end
                 

end %runCT

gcf20 = figure(20); close(gcf20); 
t_run = toc;  
fprintf('total run time for processing this image =  %2.1f minutes\n',t_run/60)

    