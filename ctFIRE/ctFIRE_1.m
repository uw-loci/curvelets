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
% edgesA = 0:10:180;            % angle histogram edges
% edgesL = 15:20:115;            % length histogram edges
bins = cP.BINs;

sz0 = get(0,'screensize');
sw0 = sz0(3);
sh0 = sz0(4);

% cP = struct('plotflag',[],'RO',[],'LW1',[],'LL1',[],'FNL',[],'Flabel',[]);
% ctfp = struct('value',[],'status',[],'pct',[],'SS',[]);
% parameters for showing the image
plotflag = cP.plotflag; %1: plot overlaid fibers and save;
plotflagnof = cP.plotflagnof; % plot non-overlaid fibers and save


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
angHV = cP.angHV ;lenHV = cP.lenHV ;strHV = cP.strHV ;widHV = cP.widHV;

dirout = savePath;% directory to to store the overlayed image output

% initilize the output variable
OUTf = struct([]);   % initialize the output
OUTctf = struct([]);   % initialize the output

% if ctfP.status == 1
%     disp('using updated  parameters')
% else
%     disp('using default parameters')
% end

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

% initialization
IS1 =[]; IS = []; im3 = [];

if cP.stack == 1  % process one slice of a stack
    SN = cP.slice;
    IS1 = imread(fullname,SN);
    fmat1 = [dirout,sprintf('FIREout_%s_s%d.mat',Inamenf,SN)];    % FIRE .mat output
    fmat2 = [dirout,sprintf('ctFIREout_%s_s%d.mat',Inamenf,SN)];  % FIRE .mat output
    fctr = [dirout,sprintf('CTR_%s_s%d.mat',Inamenf,SN)];% filename of the curvelet transformed reconstructed image dataset
    fOL1 = [dirout,sprintf('OL_FIRE_%s_s%d.tif',Inamenf,SN)]; %filename of overlaid image for FIRE output
    fOL2 = [dirout, sprintf('OL_ctFIRE_%s_s%d.tif',Inamenf,SN)]; %filename of overlaid image for ctFIRE output
    fNOL1 = [dirout,sprintf('NOL_FIRE_%s_s%d.tif',Inamenf,SN)]; %filename of non overlaid image for FIRE output
    fNOL2 = [dirout, sprintf('NOL_ctFIRE_%s_s%d.tif',Inamenf,SN)]; %filename of non overlaid image for ctFIRE output
    fOL1w = [dirout, sprintf('OLw_FIRE_%s_s%d.tif',Inamenf,SN)]; %filename of overlay image for ctFIRE output with individual fiber width
    fOL2w = [dirout, sprintf('OLw_ctFIRE_%s_s%d.tif',Inamenf,SN)]; %filename of overlay image for ctFIRE output with individual fiber width
    
    
    histA1 = [dirout,sprintf('HistANG_FIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls angle histogram values
    histL1 = [dirout,sprintf('HistLEN_FIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls length histgram values
    histA2 = [dirout,sprintf('HistANG_ctFIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls angle histogram values
    histL2 = [dirout,sprintf('HistLEN_ctFIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls length histgram values
    
    histA1_all = [dirout,sprintf('HistANG_FIRE_%s_stack.xlsx',Inamenf)];      % xls angle histogram values for the whole stack
    histL1_all = [dirout,sprintf('HistLEN_FIRE_%s_stack.xlsx',Inamenf)];      % xls length histgram values for the whole stack
    histA2_all = [dirout,sprintf('HistANG_ctFIRE_%s_stack.xlsx',Inamenf)];      % xls angle histogram values for the whole stack
    histL2_all = [dirout,sprintf('HistLEN_ctFIRE_%s_stack.xlsx',Inamenf)];      % xls length histgram values for the whole stack
    
    %% add straightness and width histogram output
    histSTR1 = [dirout,sprintf('HistSTR_FIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls straightness histogram values
    histWID1 = [dirout,sprintf('HistWID_FIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls width histgram values
    histSTR2 = [dirout,sprintf('HistSTR_ctFIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls straightness histogram values
    histWID2 = [dirout,sprintf('HistWID_ctFIRE_%s_s%d.xlsx',Inamenf,SN)];      % xls width histgram values
    
    histSTR1_all = [dirout,sprintf('HistSTR_FIRE_%s_stack.xlsx',Inamenf)];      % xls straightness histogram values for the whole stack
    histWID1_all = [dirout,sprintf('HistWID_FIRE_%s_stack.xlsx',Inamenf)];      % xls width histgram values for the whole stack
    histSTR2_all = [dirout,sprintf('HistSTR_ctFIRE_%s_stack.xlsx',Inamenf)];      % xls straightness values for the whole stack
    histWID2_all = [dirout,sprintf('HistWID_ctFIRE_%s_stack.xlsx',Inamenf)];      % xls width histgram values for the whole stack
    
    
else  % process one image
    
    IS1 = imread(fullname);
    
    fmat1 = [dirout,sprintf('FIREout_%s.mat',Inamenf)];    % FIRE .mat output
    fmat2 = [dirout,sprintf('ctFIREout_%s.mat',Inamenf)];  % ctFIRE.mat output
    fctr = [dirout,'CTR_',Inamenf,'.mat'];% filename of the curvelet transformed reconstructed image dataset
    CTimg = [dirout, 'CTRimg_',Inamenf,'.tif'];  % filename of the curvelet transformed reconstructed image
    fOL1 = [dirout,'OL_FIRE_',Inamenf,'.tif']; %filename of overlaid image for FIRE output
    fOL2 = [dirout, 'OL_ctFIRE_',Inamenf,'.tif']; %filename of overlaid image for ctFIRE output
    fNOL1 = [dirout,'NOL_FIRE_',Inamenf,'.tif']; %filename of non overlaid image for FIRE output
    fNOL2 = [dirout, 'NOL_ctFIRE_',Inamenf,'.tif']; %filename of non overlaid image for ctFIRE output
    fOL1w = [dirout, 'OLw_FIRE_',Inamenf,'.tif']; %filename of overlay image for ctFIRE output with individual fiber width
    fOL2w = [dirout, 'OLw_ctFIRE_',Inamenf,'.tif']; %filename of overlay image for ctFIRE output with individual fiber width
    
    
    histA1 = [dirout,sprintf('HistANG_FIRE_%s.xlsx',Inamenf)];      % FIRE output:xls angle histogram values
    histL1 = [dirout,sprintf('HistLEN_FIRE_%s.xlsx',Inamenf)];      % FIRE output:xls length histgram values
    histA2 = [dirout,sprintf('HistANG_ctFIRE_%s.xlsx',Inamenf)];      % ctFIRE output:xls angle histogram values
    histL2 = [dirout,sprintf('HistLEN_ctFIRE_%s.xlsx',Inamenf)];      % ctFIRE output:xls length histgram values
    
    histSTR1 = [dirout,sprintf('HistSTR_FIRE_%s.xlsx',Inamenf)];      % FIRE output:xls straightness histogram values
    histWID1 = [dirout,sprintf('HistWID_FIRE_%s.xlsx',Inamenf)];      % FIRE output:xls width histgram values
    histSTR2 = [dirout,sprintf('HistSTR_ctFIRE_%s.xlsx',Inamenf)];      % ctFIRE output:xls straightness histogram values
    histWID2 = [dirout,sprintf('HistWID_ctFIRE_%s.xlsx',Inamenf)];      % ctFIRE output:xls width histgram values
    
end


if length(size(IS1)) > 2 ,  IS =IS1(:,:,1); else   IS = IS1; end

IMG = IS;  % for curvelet reconstruction
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
            cP.RO = 2;  % for the individual mat file, make runORI = 1;  runCT = 0;
            save(fmat1,'data','Iname','p1','imgPath','imgName','savePath','cP','ctfP');
        else
            p= p1;
            data1 = fire_2D_ang1(p,im3,0);  %uses im3 and p as inputs and outputs everything
            disp(sprintf('Original image has been processed'))
            data = data1;
            cP.RO = 2;  % for the individual mat file, make runORI = 1;  runCT = 0;
            save(fmat1,'data','Iname','p1','imgPath','imgName','savePath','cP','ctfP');
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
        
        if plotflag == 1 % overlay FIRE extracted fibers on the original image
            rng(1001) ;
            clrr1 = rand(LFa,3); % set random color
            
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
        end  % plogflag
        
        if plotflagnof == 1  % just show extracted fibers
            rng(1001) ;
            clrr1 = rand(LFa,3); % set random color
            gcf151 = figure(151);clf;
            set(gcf151,'name','FIRE output: extracted fibers','numbertitle','off')
            for LL = 1:LFa
                
                VFa.LL = data.Fa(1,FN(LL)).v;
                XFa.LL = data.Xa(VFa.LL,:);
                plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr1(LL,1:3),'linewidth',LW1);
                
                hold on
                axis equal;
                axis([1 pixw 1 pixh]);
                
            end
            %             set(gca, 'visible', 'off')
            set(gcf151,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128]);
            print(gcf151,'-dtiff', '-r128', fNOL1);  % save FIRE extracted fibers
            set(gcf151,'position',[0.01*sw0+40 0.2*sh0+20 0.5*sh0,0.5*sh0*pixh/pixw]);
        end   % plotflagnof
        
        % show the comparison of length hist
        inc = (max(FLout)-min(FLout))/bins;
        edgesL = min(FLout):inc:max(FLout);
        edges = edgesL;    % bin edges
        X1L = FLout;        % length
        if lenHV
            gcf101 = figure(101); clf
            set(gcf101,'name','FIRE output: length distribution ','numbertitle','off')
            
            set(gcf101,'position',[0.60*sw0 0.10*sh0 0.35*sh0,0.35*sh0])
            [NL,BinL] = histc(X1L,edges);
            bar(edges,NL,'histc');
            xlim([min(FLout) max(FLout)]);
            axis square
            %     xlim([edges(1) edges(end)]);
            title(sprintf('Extracted length hist'),'fontsize',12);
            xlabel('Length(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            xlswrite(histL1,X1L);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histL1_all,X1L,sheetname);
            end
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
        
        if angHV
            edgesA = 0:180/bins:180;
            edges = edgesA;    % bin edges
            gcf102 = figure(102); clf
            set(gcf102,'name','FIRE output: angle distribution ','numbertitle','off')
            set(gcf102,'position',[(0.60*sw0+0.35*sh0) 0.10*sh0 0.35*sh0,0.35*sh0])
            [NA,BinA] = histc(X1A,edges);
            bar(edges,NA,'histc');
            axis square
            title(sprintf('Extracted angle hist'),'fontsize',12);
            xlabel('Angle(degree)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            xlswrite(histA1,X1A);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histA1_all,X1A,sheetname);
            end
        end
        
        % straightness analysis
        
        if strHV
            
            fnum = length(data.Fa);  % nuber of the extracted fibers
            % strightness = (length of the straight line connecting the fiber start point and the end point )/ (fiber length)
            fsp = zeros(fnum,1); % fiber start point
            fep = zeros(fnum,1); % fiber end point
            dse = zeros(fnum,1); % distance between start point and end point
            for i = 1:fnum
                fsp(i) = data.Fa(i).v(1);
                fep(i) = data.Fa(i).v(end);
                dse(i) = norm(data.Xa(fep(i),:)-data.Xa(fsp(i),:));
                
            end
            fstr = dse./data.M.L;
            X1str = fstr(FN);  % after applying length limit
            
            edgesSTR = min(X1str):(1-min(X1str))/bins:1;
            edges = edgesSTR;    % bin edges
            gcf103 = figure(103); clf
            set(gcf103,'name','FIRE output: straightness distribution ','numbertitle','off')
            set(gcf103,'position',[(0.375*sw0+0.05*sh0) 0.10*sh0 0.35*sh0,0.35*sh0])
            [Nstr,Binstr] = histc(X1str,edges);
            bar(edges,Nstr,'histc');
            xlim([min(X1str) 1]);
            axis square
            title(sprintf('Fiber straightness hist'),'fontsize',12);
            xlabel('Straightness(dimensionless)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            xlswrite(histSTR1,X1str);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histSTR1_all,X1str,sheetname);
            end
        end % strHV
        
        if widHV == 1
            rng(1001) ;
            clrr2 = rand(LFa,3); % set random color
            
            fR = data.Ra;
            fRlim = [min(fR) max(fR)];
            NWlim = [1.0 10.0]; % normalized width limitation
            fRN = [fR-fRlim(1)]*(NWlim(2) - NWlim(1))/(fRlim(2)-fRlim(1))+NWlim(1);
            %             gcf351 = figure(352);clf
            %             set(gcf351,'name','ctFIRE output: overlaid image with fiber width contrast','numbertitle','off')
            %             set(gcf351,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128])
            %             imshow(IS1); colormap gray; axis xy; axis equal; hold on;
            for LL = 1:LFa
                VFa.LL = data.Fa(1,FN(LL)).v;
                XFa.LL = data.Xa(VFa.LL,:);
                % to obtain the width
                RNFa.LL = fRN(VFa.LL,1);
                RFa.LL = fR(VFa.LL,1);
                NPnum = length(XFa.LL(:,1)); % nuber of vectors in each fiber
                widave(LL) = 2*mean(data.Ra(VFa.LL));   % estimated average fiber width
                %% plot normalized width
                %                 for iNP = 1:NPnum-1
                %                     nfsr = RNFa.LL(iNP);% Normalized fiber segment radius
                %                     fsw = 2*RFa.LL(iNP);% estimated fiber segment width
                %
                %                     plot(XFa.LL(iNP:iNP+1,1),abs(XFa.LL(iNP:iNP+1,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',nfsr);
                %                     hold on
                %                     disp(sprintf('iNP = %d, NPnum = %d,nfsr = %d,fsw = %d',iNP,NPnum, nfsr,fsw));
                %
                %                     %                 axis equal;
                %                     %                 axis([1 pixw 1 pixh]);
                %                     disp(sprintf('plot width of fiber %d of %d fibers', LL, LFa))
                %                 end
                %                 if widave(LL) <3
                %                 disp(sprintf('fiber #%d, average fiber width = %d',LL,widave(LL)))
                %                 figure(351)
                %                 disp('press any key to continue ...')
                %                 pause
                %                 end
            end
            %             set(gca, 'visible', 'off')
            %             print(gcf351,'-dtiff', '-r128', fOL1w);
            %             set(gcf351,'Units','Normalized','position',[0,0,0.3,(sw0*0.3)/sh0*pixh/pixw ]);
            
            % histogram of fiber width
            fwid = widave;
            X1wid = fwid;
            
            edgeswid = min(X1wid):(max(X1wid)-min(X1wid))/bins:max(X1wid);
            edges = edgeswid;    % bin edges
            gcf104 = figure(104); clf
            set(gcf104,'name','FIRE output: width distribution ','numbertitle','off')
            set(gcf104,'position',[(0.175*sw0+0.05*sh0) 0.10*sh0 0.35*sh0,0.35*sh0])
            [Nwid,Binwid] = histc(X1wid,edges);
            bar(edges,Nwid,'histc');
            axis square
            title(sprintf('Fiber width hist'),'fontsize',12);
            xlabel('Width(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            xlswrite(histWID1,X1wid');
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histWID1_all,X1wid',sheetname);
            end
            
            
        end % widHV
        
        
    catch
        home
        disp(sprintf('FIRE on original Image is skipped'));
    end
    
end % runORI

%% run FIRE on curvelet transform based reconstruction image
if runCT == 1 %
    
    try
        
        if postp == 1%
            load(fmat2,'data');
            cP.RO = 1;  % for the individual mat file, make runORI = 0;  runCT = 1;
            save(fmat2,'data','Iname','p2','imgPath','imgName','savePath','cP','ctfP');
        else
            CTr = CTrec_1(IMG,fctr,pct,SS,plotflag); %0: not output curvelet transform results
            CTr = CTr.*mask_ori;
            
            im3 = []; im3(1,:,:) = CTr;
            p = p2;
            data2 = fire_2D_ang1(p,im3,0);  %uses im3 and p as inputs and outputs everything listed below
            home
            disp(sprintf('Reconstructed image has been processed'))
            data = data2;
            cP.RO = 1;  % for the individual mat file, make runORI = 0;  runCT = 1;
            save(fmat2,'data','Iname','p2','imgPath','imgName','savePath','cP','ctfP');
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
        
        if plotflag == 1 % overlay ctFIRE extracted fibers on the original image
            rng(1001) ;
            clrr2 = rand(LFa,3); % set random color
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
        
        if plotflagnof == 1 % just show extracted fibers%
            rng(1001) ;
            clrr2 = rand(LFa,3); % set random color
            
            gcf152 = figure(53);clf;
            set(gcf152,'name','ctFIRE output: extracted fibers ','numbertitle','off')
            set(gcf152,'PaperUnits','inches','PaperPosition',[50 100 pixw/128 pixh/128])
            for LL = 1:LFa
                VFa.LL = data.Fa(1,FN(LL)).v;
                XFa.LL = data.Xa(VFa.LL,:);
                plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',LW1);
                hold on
                axis equal;
                axis([1 pixw 1 pixh]);
            end
            %             set(gca, 'visible', 'off')
            print(gcf152,'-dtiff', '-r128', fNOL2);
            set(gcf152,'position',[(0.02*sw0+0.5*sh0)+40 0.2*sh0+20 0.5*sh0,0.5*sh0*pixh/pixw]);
            
        end % plotflagnof
        
        % show the comparison of length hist
        X2L = FLout;        % length
        if lenHV
            inc = (max(FLout)-min(FLout))/bins;
            edgesL = min(FLout):inc:max(FLout);
            edges = edgesL;    % bin edges
            gcf201 = figure(201); clf
            set(gcf201,'name','ctFIRE output: length distribution ','numbertitle','off')
            set(gcf201,'position',[0.60*sw0 0.55*sh0 0.35*sh0,0.35*sh0])
            [NL,BinL] = histc(X2L,edges);
            bar(edges,NL,'histc');
            xlim([min(FLout) max(FLout)]);
        
            axis square
            %     xlim([edges(1) edges(end)]);
            title(sprintf('Extracted length hist'),'fontsize',12);
            xlabel('Length(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            xlswrite(histL2,X2L);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histL2_all,X2L,sheetname);
            end
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
        
        if angHV
            edgesA = 0:180/bins:180;
            edges = edgesA;    % bin edges
            gcf202 = figure(202); clf
            set(gcf202,'name','ctFIRE output: angle distribution ','numbertitle','off')
            set(gcf202,'position',[(0.60*sw0+0.35*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
            [NA,BinA] = histc(X2A,edges);
            bar(edges,NA,'histc');
            axis square
            title(sprintf('Extracted angle hist'),'fontsize',12);
            xlabel('Angle(degree)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            xlswrite(histA2,X2A);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histA2_all,X2A,sheetname);
            end
        end
        
        % straightness analysis
        
        if strHV
            
            fnum = length(data.Fa);  % nuber of the extracted fibers
            % strightness = (length of the straight line connecting the fiber start point and the end point )/ (fiber length)
            fsp = zeros(fnum,1); % fiber start point
            fep = zeros(fnum,1); % fiber end point
            dse = zeros(fnum,1); % distance between start point and end point
            for i = 1:fnum
                fsp(i) = data.Fa(i).v(1);
                fep(i) = data.Fa(i).v(end);
                dse(i) = norm(data.Xa(fep(i),:)-data.Xa(fsp(i),:));
                
            end
            fstr = dse./data.M.L;   % fiber straightness
            
            X2str = fstr(FN);  % after applying length limit
            
            edgesSTR = min(X2str):(1-min(X2str))/bins:1;
            edges = edgesSTR;    % bin edges
            gcf203 = figure(203); clf
            set(gcf203,'name','ctFIRE output: straightness distribution ','numbertitle','off')
            set(gcf203,'position',[(0.375*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
            [Nstr,Binstr] = histc(X2str,edges);
            bar(edges,Nstr,'histc');
            xlim([min(X2str) 1]);
            
            axis square
            title(sprintf('Fiber straightness hist'),'fontsize',12);
            xlabel('Straightness(dimensionless)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            xlswrite(histSTR2,X2str);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histSTR2_all,X2str,sheetname);
            end
        end % strHV
        
        
        if widHV == 1
            rng(1001) ;
            clrr2 = rand(LFa,3); % set random color
            
            fR = data.Ra;
            fRlim = [min(fR) max(fR)];
            NWlim = [1.0 10.0]; % normalized width limitation
            fRN = [fR-fRlim(1)]*(NWlim(2) - NWlim(1))/(fRlim(2)-fRlim(1))+NWlim(1);
            %             gcf352 = figure(352);clf
            %             set(gcf352,'name','ctFIRE output: overlaid image with fiber width contrast','numbertitle','off')
            %             set(gcf352,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128])
            %             imshow(IS1); colormap gray; axis xy; axis equal; hold on;
            %             LFa = 10;
            for LL = 1:LFa
                VFa.LL = data.Fa(1,FN(LL)).v;
                XFa.LL = data.Xa(VFa.LL,:);
                % to obtain the width
                RNFa.LL = fRN(VFa.LL,1);
                RFa.LL = fR(VFa.LL,1);
                NPnum = length(XFa.LL(:,1)); % nuber of vectors in each fiber
                widave(LL) = 2*mean(data.Ra(VFa.LL));   % estimated average fiber width
                %% plot normalized width
                %                 for iNP = 1:NPnum-1
                %                     nfsr = RNFa.LL(iNP);% Normalized fiber segment radius
                %                     fsw = 2*RFa.LL(iNP);% estimated fiber segment width
                %
                %                     plot(XFa.LL(iNP:iNP+1,1),abs(XFa.LL(iNP:iNP+1,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',nfsr);
                %                     hold on
                %                     disp(sprintf('iNP = %d, NPnum = %d,nfsr = %d,fsw = %d',iNP,NPnum, nfsr,fsw));
                %
                %                     %                 axis equal;
                %                     %                 axis([1 pixw 1 pixh]);
                %                     disp(sprintf('plot width of fiber %d of %d fibers', LL, LFa))
                %                 end
                %                 if widave(LL) <3
                %                 disp(sprintf('fiber #%d, average fiber width = %d',LL,widave(LL)))
                %                 figure(352)
                %                 disp('press any key to continue ...')
                %                 pause
                %                 end
            end
            %             set(gca, 'visible', 'off')
            %             print(gcf352,'-dtiff', '-r128', fOL2w);
            %             set(gcf352,'Units','Normalized','position',[0,0,0.3,(sw0*0.3)/sh0*pixh/pixw ]);
            
            % histogram of fiber width
            fwid = widave;
            X2wid = fwid;
            
            edgeswid = min(X2wid):(max(X2wid)-min(X2wid))/bins:max(X2wid);
            edges = edgeswid;    % bin edges
            gcf204 = figure(204); clf
            set(gcf204,'name','ctFIRE output: width distribution ','numbertitle','off')
            set(gcf204,'position',[(0.175*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
            [Nwid,Binwid] = histc(X2wid,edges);
            bar(edges,Nwid,'histc');
            axis square
            title(sprintf('Fiber width hist'),'fontsize',12);
            xlabel('Width(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            xlswrite(histWID2,X2wid');
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histWID2_all,X2wid',sheetname);
            end
            
            
        end % widHV
        
    catch
        home
        disp(sprintf('ctFIRE on reconstruction image is skipped'));
    end
    
    
end %runCT

% gcf20 = figure(20); close(gcf20);
t_run = toc;
fprintf('total run time for processing this image =  %2.1f minutes\n',t_run/60)

