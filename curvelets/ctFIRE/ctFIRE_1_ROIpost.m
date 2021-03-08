function ctFIRE_1_ROIpost(filePath,fileName,ctfmatname, imgPath,imgName,savePath,roiP)

%based on ctFIRE_1 as well as  the funciton of analyzer_launch_fn in CTFroi 
%input: 
%filePath: original file path
%fileName: original file name
%ctfmatname: original fiber extraction mat file
%imgPath: roi path
%imgName: roi name
%savepath: roi savePath
%roiP: ROI parameters:
% roiP.BW = BW;          % ROI mask
% roiP.fibersource = 1;  % 1: use original fiber extraction output; 2: use selectedOUT out put
% roiP.fibermode = 1;    % 1: fibermode, check the fiber middle point 2: check the hold fiber
% Output:
% 1: ROI overlaid image
% 2: ROI csv files for fiber properties
%3. add fiberflag in original mat file

tic
% loading cP ,ctfP and data
load(ctfmatname,'cP','ctfP','data')

bins = cP.BINs;
sz0 = get(0,'screensize');
sw0 = sz0(3);
sh0 = sz0(4);

% parameters for showing the image
plotflag = cP.plotflag; %1: plot overlaid fibers and save;
plotflagnof = cP.plotflagnof; % plot non-overlaid fibers and save
cP.postp = 1;
postp = cP.postp;  % 1: load .mat file
cP.RO = 1;

% run option:
if     cP.RO == 1 ,    runCT = 1;   runORI = 0;  disp(' only run ctFIRE');
elseif cP.RO == 2,     runCT = 0;   runORI = 1;  disp(' only run FIRE');
elseif cP.RO == 3,     runCT = 1;   runORI = 1;  disp('run both ctFIRE and FIRE');
else   error('Need to set a correct run option(RO = 1,2,or 3) ')
end

LW1 = cP.LW1;     % default 0.5,line width of the extracted fibers
LL1 = cP.LL1;     %default 30,length limit(threshold), only show fibers with length >LL
FNL = cP.FNL;     %default 9999; %: fiber number limit(threshold), maxium fiber number to show
RES = cP.RES;     %resoultion of the overlaid image, [dpi]
widMAX = cP.widMAX;
texton = 0;%cP.Flabel;  % texton = 1, label the fibers; texton = 0: no label
angHV = cP.angHV ;lenHV = cP.lenHV ;strHV = cP.strHV ;widHV = cP.widHV;
% options for width calculation
widcon = cP.widcon; % all the control parameters for width calculation
wid_mm = widcon.wid_mm; % minimum maximum fiber width
wid_mp = widcon.wid_mp; % minimum points to apply fiber points selection
wid_sigma = widcon.wid_sigma; % confidence region, default +- 1 sigma
wid_max = widcon.wid_max;     % calculate the maximum width of each fiber, deault 0, not calculate; 1: caculate
wid_opt = widcon.wid_opt;     % choice for width calculation, default 1 use all

if widMAX < wid_mm
    disp(sprintf('Please make sure the maximum fiber width is correct. Using default min maximum width %d.',wid_mm));
    wid_th = wid_mm;
else
    wid_th = widMAX;
end

% add the option to automatically calculate the number of histogram bins
dirout = savePath;% directory to to store the overlayed image output

%% name the output image
Iname =imgName;        % image name
fullname = fullfile(imgPath, imgName);
% Fdot = strfind(Iname,'.'); % find the '.' in the Iname;
% Inamenf = Iname(1:Fdot(end)-1);   % image name with no format information
[~,Inamenf,~] = fileparts(Iname);
info = imfinfo(fullname);

pixw = info(1).Width;  % get the image size
pixh = info(1).Height;
pix = [pixw pixh];

% initialization
IS1 =[]; IS = []; im3 = [];

% process one image

IS1 = imread(fullname);

fmat1 = fullfile(dirout,sprintf('FIREout_%s.mat',Inamenf));    % FIRE .mat output
fmat2 = fullfile(dirout,sprintf('ctFIREout_%s.mat',Inamenf));  % ctFIRE.mat output
fctr = fullfile(dirout,['CTR_',Inamenf,'.mat']);% filename of the curvelet transformed reconstructed image dataset
CTimg = fullfile(dirout, ['CTRimg_',Inamenf,'.tif']);  % filename of the curvelet transformed reconstructed image
fOL1 = fullfile(dirout,['OL_FIRE_',Inamenf,'.tif']); %filename of overlaid image for FIRE output
fOL2 = fullfile(dirout, ['OL_ctFIRE_',Inamenf,'.tif']); %filename of overlaid image for ctFIRE output
fNOL1 = fullfile(dirout,['NOL_FIRE_',Inamenf,'.tif']); %filename of non overlaid image for FIRE output
fNOL2 = fullfile(dirout, ['NOL_ctFIRE_',Inamenf,'.tif']); %filename of non overlaid image for ctFIRE output
fOL1w = fullfile(dirout, ['OLw_FIRE_',Inamenf,'.tif']); %filename of overlay image for ctFIRE output with individual fiber width
fOL2w = fullfile(dirout, ['OLw_ctFIRE_',Inamenf,'.tif']); %filename of overlay image for ctFIRE output with individual fiber width

outxls = 0;
if outxls == 1   %   only for Windows with excel
    
    histA1 = fullfile(dirout,sprintf('HistANG_FIRE_%s.xlsx',Inamenf));      % FIRE output:xls angle histogram values
    histL1 = fullfile(dirout,sprintf('HistLEN_FIRE_%s.xlsx',Inamenf));      % FIRE output:xls length histgram values
    histA2 = fullfile(dirout,sprintf('HistANG_ctFIRE_%s.xlsx',Inamenf));      % ctFIRE output:xls angle histogram values
    histL2 = fullfile(dirout,sprintf('HistLEN_ctFIRE_%s.xlsx',Inamenf));      % ctFIRE output:xls length histgram values
    
    histSTR1 = fullfile(dirout,sprintf('HistSTR_FIRE_%s.xlsx',Inamenf));      % FIRE output:xls straightness histogram values
    histWID1 = fullfile(dirout,sprintf('HistWID_FIRE_%s.xlsx',Inamenf));      % FIRE output:xls width histgram values
    histSTR2 = fullfile(dirout,sprintf('HistSTR_ctFIRE_%s.xlsx',Inamenf));      % ctFIRE output:xls straightness histogram values
    histWID2 = fullfile(dirout,sprintf('HistWID_ctFIRE_%s.xlsx',Inamenf));      % ctFIRE output:xls width histgram values
    % -----------------------------------------------------------------
    
else % for Windows and Mac
    
    histA1 = fullfile(dirout,sprintf('HistANG_FIRE_%s.csv',Inamenf));      % FIRE output:xls angle histogram values
    histL1 = fullfile(dirout,sprintf('HistLEN_FIRE_%s.csv',Inamenf));      % FIRE output:xls length histgram values
    histA2 = fullfile(dirout,sprintf('HistANG_ctFIRE_%s.csv',Inamenf));      % ctFIRE output:xls angle histogram values
    histL2 = fullfile(dirout,sprintf('HistLEN_ctFIRE_%s.csv',Inamenf));      % ctFIRE output:xls length histgram values
    
    histSTR1 = fullfile(dirout,sprintf('HistSTR_FIRE_%s.csv',Inamenf));      % FIRE output:xls straightness histogram values
    histWID1 = fullfile(dirout,sprintf('HistWID_FIRE_%s.csv',Inamenf));      % FIRE output:xls width histgram values
    histSTR2 = fullfile(dirout,sprintf('HistSTR_ctFIRE_%s.csv',Inamenf));      % ctFIRE output:xls straightness histogram values
    histWID2 = fullfile(dirout,sprintf('HistWID_ctFIRE_%s.csv',Inamenf));      % ctFIRE output:xls width histgram values
    histWID3 = fullfile(dirout,sprintf('HistWIDmax_ctFIRE_%s.csv',Inamenf));      % ctFIRE output:xls width histgram values
    
    %-----------------------------------------------------------------
end

if length(size(IS1)) > 2   
    IS = rgb2gray(IS1); 
    disp('color image was loaded but converted to grayscale image') 
else
    IS = IS1; 
end

IMG = IS;  % for curvelet reconstruction
im3(1,:,:) = IS;
IS1 = flipud(IS);  % associated with the following 'axis xy', IS1-->IS


%% run FIRE on curvelet transform based reconstruction image
ROIname = roiP.ROIname;
fiber_source = roiP.fibersource;
mask = roiP.BW ;
mdEST_OP = roiP.fiber_midpointEST;  % midddle point estimation option, 1: use end point coordinate; 2: based on fiber length

try
    size_fibers=size(data.Fa,2);
    if fiber_source == 1;
        fiberflag = zeros(size_fibers,1);
    elseif fiber_source == 2
        if(isfield(data,'PostProGUI')&&isfield(data.PostProGUI,'fiber_indices'))
            fiberflag_temp = data.PostProGUI.fiber_indices(:,2);
        else
            error('Post Processing Data not present');
        end
    end
    
    for i  = 1: size_fibers 
        %YL: make fiber middle point estimation options be consistent with
        %that in CurveAlign
        if mdEST_OP == 1 %use fiber end coordinates
            fsp = data.Fa(i).v(1);
            fep = data.Fa(i).v(end);
            sp = data.Xa(fep,:);  % start point
            ep = data.Xa(fsp,:);  % end point
            cen = round(mean([sp; ep]));
            x = cen(1);
            y = cen(2);
        elseif mdEST_OP == 2  % use fiber length
            % use interpolated coordinates to estimate the fiber center or middle point
            vertex_indices_INT = data.Fai(i).v;
            s2 = size(vertex_indices_INT,2);
            x= round(data.Xai(vertex_indices_INT(round(s2/2)),1));    % x of fiber center point
            y= round(data.Xai(vertex_indices_INT(round(s2/2)),2));     % y of fiber center point
            % If [y x] is out of boundary due to interpolation,
            % then use the un-interpolated coordinates
            if x> size(IMG,2) || y > size(IMG,1)|| x < 1 || y< 1
                vertex_indices = data.Fa(i).v;
                s2=size(vertex_indices,2);
                x = data.Xa(vertex_indices(floor(s2/2)),1);
                y = data.Xa(vertex_indices(floor(s2/2)),2);
                fprintf('Interpolated coordinates of fiber %d is out of boundary, orignial coordinates is used for fiber middle point estimation. \n',i)
                if mask(y,x)==1
                    fprintf('This fiber is inside the ROI\n')
                else
                    fprintf('This fiber is NOT inside the ROI\n')
                end
            end
        end
        if(mask(y,x)==1) % x and y seem to be interchanged in plot
            % function.
            %         plot_fiber_centers = 1
            %         if(plot_fiber_centers==1)
            %             plot(x,y,'--rs','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','g','MarkerSize',10); hold on;
            %         end
            %         %             next step is a debug check
            %         fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
            
            if fiber_source == 1;
                if data.M.L(i) >LL1
                    fiberflag(i) = 1;
                end
            elseif fiber_source == 2
                
                if fiberflag_temp(i) == 1;
                    
                    fibeflag(i) = 1;
                end
            end
            
        end % mask
        
    end   % fibers
    
    FN = find(fiberflag == 1);
    
    FLout = data.M.L(FN);
    LFa = length(FN);
    
    if plotflag == 1 % overlay ctFIRE extracted fibers on the original image
        rng(1001) ;
        clrr2 = rand(LFa,3); % set random color
        gcf52 = findobj(0,'Name','ctFIRE ROI output: overlaid image');
        if isempty(gcf52)
            gcf52 = figure('name','ctFIRE ROI output: overlaid image','numbertitle','off');
        end
        figure(gcf52); 
        set(gcf52,'position',round([(0.02*sw0+0.2*sh0) 0.1*sh0 0.75*sh0,0.75*sh0*pixh/pixw]));
        set(gcf52,'PaperUnits','inches','PaperPosition',[0 0 pixw/RES pixh/RES])
        imshow(IS1); colormap gray; axis xy; axis equal; hold on;
        
        for LL = 1:LFa
            VFa.LL = data.Fa(1,FN(LL)).v;
            XFa.LL = data.Xa(VFa.LL,:);
            plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',LW1);
            
            %YL02262014: add fiber annotation
            if texton == 1
                shftt = 2;
                if XFa.LL(1,1)< XFa.LL(end,1)
                    text(XFa.LL(1+shftt,1),abs(XFa.LL(1+shftt,2)-pixh-1),sprintf('%d',LL),'color',clrr2(LL,1:3),'fontsize',9);
                    %                 text(XFa.LL(1+2,1),abs(XFa.LL(1+2,2)-pixh-1),sprintf('%d',LL),'color','w','fontsize',12);
                elseif XFa.LL(1,1)> XFa.LL(end,1)
                    text(XFa.LL(end-shftt,1),abs(XFa.LL(end-shftt,2)-pixh-1),sprintf('%d',LL),'color',clrr2(LL,1:3),'fontsize',9);
                end
            end
            axis equal;
            axis([1 pixw 1 pixh]);
        end
        %             set(gca, 'visible', 'off');
        set(gcf52,'Units','normal');
        set(gca,'Position',[0 0 1 1]);
        print(gcf52,'-dtiff', ['-r',num2str(RES)], fOL2);
        %figure(gcf52);imshow(fOL2);
        hold off   % gcf52
        %             set(gcf52,'position',[(0.02*sw0+0.5*sh0) 0.1*sh0 0.75*sh0,0.75*sh0*pixh/pixw]);
    end % plotflag
    
    
    % show the comparison of length hist
    X2L = FLout;        % length
    if lenHV
        inc = (max(FLout)-min(FLout))/bins;
        edgesL = min(FLout):inc:max(FLout);
        edges = edgesL;    % bin edges
        gcf201 = findobj(0,'Name','ctFIRE ROI output: length distribution');
        if isempty(gcf201)
            gcf201 = figure('name','ctFIRE ROI output: length distribution','numbertitle','off');
        end
        figure(gcf201);
        set(gcf201,'position',[0.60*sw0 0.55*sh0 0.35*sh0,0.35*sh0])
        [NL,BinL] = histc(X2L,edges);
        bar(edges,NL,'histc');
        xlim([min(FLout) max(FLout)]);
        
        axis square
        %     xlim([edges(1) edges(end)]);
        % YLtemp            title(sprintf('Extracted length hist'),'fontsize',12);
        xlabel('Length(pixels)','fontsize',12);
        ylabel('Frequency','fontsize',12);
        
        if outxls == 1
            xlswrite(histL2,X2L);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histL2_all,X2L,sheetname);
            end
        else
            csvwrite(histL2,X2L);
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
        gcf202 = findobj(0,'Name','ctFIRE ROI output: angle distribution');
        if isempty(gcf202)
            gcf202 = figure('name','ctFIRE ROI output: angle distribution','numbertitle','off','Visible','on');
        end
        figure(gcf202);
        set(gcf202,'position',[(0.60*sw0+0.35*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [NA,BinA] = histc(X2A,edges);
        bar(edges,NA,'histc');
        xlim([0 180]);
        axis square
        % YLtemp           title(sprintf('Extracted angle hist'),'fontsize',12);
        xlabel('Angle(degree)','fontsize',12)
        ylabel('Frequency','fontsize',12)
        
        if outxls == 1
            xlswrite(histA2,X2A);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histA2_all,X2A,sheetname);
            end
        else
            csvwrite(histA2,X2A);
            
        end
    end
    
    % straightness analysis
    
    if strHV
        
        fnum = length(data.Fa);  % number of the extracted fibers
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
        gcf203 = findobj(0,'Name','ctFIRE ROI output: straightness distribution');
        if isempty(gcf203)
            gcf203 = figure('name','ctFIRE ROI output: straightness distribution','numbertitle','off','Visible','on');
        end
        figure(gcf203);
        set(gcf203,'position',[(0.375*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [Nstr,Binstr] = histc(X2str,edges);
        bar(edges,Nstr,'histc');
        xlim([min(X2str) 1]);
        
        axis square
        % YLtemp        title(sprintf('Fiber straightness hist'),'fontsize',12);
        xlabel('Straightness(dimensionless)','fontsize',12)
        ylabel('Frequency','fontsize',12)
        
        if outxls == 1
            xlswrite(histSTR2,X2str);
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histSTR2_all,X2str,sheetname);
            end
        else
            csvwrite(histSTR2,X2str);
        end
        
    end % strHV
    
    
    if widHV == 1
        rng(1001) ;
        clrr2 = rand(LFa,3); % set random color
        
        fR = data.Ra;
        fRlim = [min(fR) max(fR)];
        NWlim = [1.0 10.0]; % normalized width limitation
        fRN = [fR-fRlim(1)]*(NWlim(2) - NWlim(1))/(fRlim(2)-fRlim(1))+NWlim(1);
        for LL = 1:LFa
            VFa.LL = data.Fa(1,FN(LL)).v;
            XFa.LL = data.Xa(VFa.LL,:);
            % to obtain the width
            RNFa.LL = fRN(VFa.LL,1);
            RFa.LL = fR(VFa.LL,1);
            NPnum = length(XFa.LL(:,1)); % nuber of vectors in each fiber
            widall = 2*data.Ra(VFa.LL);
            temp = find(widall <= wid_th);
            wtemp = widall(temp);
            %YL02142014
            if wid_opt == 1            % use all the points except artifact to calculate fiber width
                widave_sp(LL) = mean(wtemp); % estimated average fiber width
                widmax_sp(LL) = max(wtemp);  % estimated maximum fiber width
            else
                if length(wtemp) > wid_mp     % set a minimum sample size(wid_mp) for statistic analysis
                    widstd = std(wtemp);   % std of the points
                    widmean = mean(wtemp); % mean of the points
                    temp2 = find(wtemp<= widmean+wid_sigma*widstd & wtemp>= widmean - wid_sigma*widstd);
                    widave_sp(LL) = mean(wtemp(temp2));  % averaged fiber width of the selected points
                    widmax_sp(LL) = max(wtemp(temp2));   % maximum fiber width of the selected points
                else
                    widave_sp(LL) = mean(wtemp);% estimated average fiber width
                    widmax_sp(LL) = max(wtemp);% estimated maxium fiber width
                end
                
            end
            
        end
        
        fwid = widave_sp; % define the width as averaged width
        X2wid = fwid;
        
        edgeswid = min(X2wid):(max(X2wid)-min(X2wid))/bins:max(X2wid);
        edges = edgeswid;    % bin edges
        gcf204 = findobj(0,'Name','ctFIRE ROI output: width distribution');
        if isempty(gcf204)
            gcf204 = figure('name','ctFIRE ROI output: width distribution','numbertitle','off','Visible','on');
        end
        figure(gcf204);
        set(gcf204,'position',[(0.175*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [Nwid,Binwid] = histc(X2wid,edges);
        bar(edges,Nwid,'histc');
        xlim([min(X2wid) max(X2wid)]);
        
        axis square
        % YLtemp         title(sprintf('Fiber width hist'),'fontsize',12);
        xlabel('Width(pixels)','fontsize',12)
        ylabel('Frequency','fontsize',12)
        
        if outxls == 1
            xlswrite(histWID2,X2wid');
            if cP.stack == 1
                sheetname = sprintf('S%d',SN); %
                xlswrite(histWID2_all,X2wid',sheetname);
                
            end
        else
            csvwrite(histWID2,X2wid');
        end
        
        %             % YL022414:    % histogram of maximum fiber width
        if wid_max == 1
            fwid = widmax_sp;
            X2wid = fwid;
            
            edgeswid = min(X2wid):(max(X2wid)-min(X2wid))/bins:max(X2wid);
            edges = edgeswid;    % bin edges
            gcf204b = findobj(0,'Name','ctFIRE ROI output:maximum width distribution');
            if isempty(gcf204b)
                gcf204b = figure('name','ctFIRE ROI output:maximum width distribution','numbertitle','off','Visible','off');
            end
            figure(gcf204b)
            set(gcf204,'position',[(0.175*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
            [Nwid,Binwid] = histc(X2wid,edges);
            bar(edges,Nwid,'histc');
            xlim([min(X2wid) max(X2wid)]);
            axis square
            % YLtemp         title(sprintf('Fiber width hist'),'fontsize',12);
            xlabel('Width(pixels)','fontsize',12)
            ylabel('Frequency','fontsize',12)
            
            if outxls == 1
                xlswrite(histWID2,X2wid');
                if cP.stack == 1
                    sheetname = sprintf('S%d',SN); %
                    xlswrite(histWID2_all,X2wid',sheetname);
                    
                end
            else
                csvwrite(histWID3,X2wid'); % YL02242014
            end
        end  % output the maximum width of each fiber
        
    end % widHV
    data.ROIpost.(ROIname).fiberflag = fiberflag;
    save(ctfmatname,'data','-append');
    
catch exp_temp
    home
    disp(sprintf('ctFIRE post ROI analysis on %s  is skipped\n error: %s',imgName,exp_temp.message));
    if postp ~= 1
        if exist(fmat2,'file')
            delete(fmat2);
            fprintf('%s is DELETED due to incomplete fiber information \n',fmat2)
        end
    end

end
% gcf20 = figure(20); close(gcf20);
t_run = toc;
fprintf('total run time for processing this image =  %2.1f minutes\n',t_run/60)
end %runCT



