% look_SEL_fibers.m
%% view seleced fibers after using advanced output processing
%Yuming Liu, UW-LOCI, July, 2014

function look_SEL_fibers(selPath,selName,savePath,cP)

% Input:
%   selPath: path of the image to be processed
%   selName: name of the image to be processed
%   savePath: path of the output
%   cP: control parameters for control output image and file

plotflag = cP.plotflag; %1: plot overlaid fibers ;

%%YL: to use the xlwrite in MAC OS, will use xlwrite authorized by Alec de Zegher
%% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
MAC = 1;  % 1: mac os; 0: windows os
if MAC == 1
    if (~isdeployed)
        javaaddpath('../20130227_xlwrite/poi_library/poi-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/xmlbeans-2.3.0.jar');
        javaaddpath('../20130227_xlwrite/poi_library/dom4j-1.6.1.jar');
        javaaddpath('../20130227_xlwrite/poi_library/stax-api-1.0.1.jar');
        addpath('../20130227_xlwrite');
    end
end


bins = cP.BINs;
sz0 = get(0,'screensize');
sw0 = sz0(3);
sh0 = sz0(4);
fz1 = 10;  % fontsize for the axis labels
fz2 = 7;   % fontsize for the text in the figure
clr1 = 'rgbc';  % width, length , angle, straightness
clr2 = 'kkkk';  % color of the selected fibers
clr3 = 'rgbc';  % bar color for width, length, angle, straightness

LW1 = cP.LW1; % default 0.5,line width of the extracted fibers
LL1 = cP.LL1;  %default 30,length limit(threshold), only show fibers with length >LL
FNL = cP.FNL;   %default 9999; %: fiber number limit(threshold), maxium fiber number to show
RES = cP.RES;   %resoultion of the overlaid image, [dpi]
% texton = cP.Flabel;  % texton = 1, label the fibers; texton = 0: no label
angHV = cP.angHV ;lenHV = cP.lenHV ;strHV = cP.strHV ;widHV = cP.widHV;

if cP.stack == 0
    % read the excel file
    filesel = [selPath,selName];
    [~,~,selSTA]= xlsread(filesel,'statistics');
    [~,~,selFIB]= xlsread(filesel,'Selected Fibers');
    imgName = selSTA{1,2};
    OLList = dir([selPath,imgName,'*.tif']);
    if plotflag
        
        gcf1 = figure('Resize','on','Units','pixels','Position',[225 250 512 512],'Visible','on',...
            'MenuBar','figure','name','Overlaid selected fibers','NumberTitle','off','UserData',0);
        imshow([selPath OLList.name]); axis equal image;
    end
    
    widMean = selSTA{5,2};
    lenMean = selSTA{5,3};
    angMean = selSTA{5,4};
    strMean = selSTA{5,5};
    
    widStd = selSTA{7,2};
    lenStd = selSTA{7,3};
    angStd = selSTA{7,4};
    strStd = selSTA{7,5};
    fibNum = selSTA{10,2};
    
    % selected fibers
    widSEL = vertcat(selFIB{3:end,3});
    lenSEL = vertcat(selFIB{3:end,2});
    angSEL = vertcat(selFIB{3:end,4});
    strSEL = vertcat(selFIB{3:end,5});
    % show the comparison of length hist
    if lenHV
        FLout = lenSEL;
        X2L = FLout;
        inc = (max(FLout)-min(FLout))/bins;
        edgesL = min(FLout):inc:max(FLout);
        edges = edgesL;    % bin edges
        gcf202 = figure(202); clf
        set(gcf202,'name',sprintf('lenHIST:%s',imgName),'numbertitle','off')
        set(gcf202,'position',[0.60*sw0 0.55*sh0 0.35*sh0,0.35*sh0])
        [NL,BinL] = histc(X2L,edges);
        bar(edges,NL,'histc');
        xlim([min(FLout) max(FLout)]);
        
        axis square
        %     xlim([edges(1) edges(end)]);
        % YLtemp            title(sprintf('Extracted length hist'),'fontsize',fz1);
        xlabel('Length(pixels)','fontsize',fz1);
        ylabel('Frequency','fontsize',fz1);
        
        gcf212 = figure(212); clf
        set(gcf212,'name',sprintf('length:%s',imgName),'numbertitle','off')
        set(gcf212,'position',[0.60*sw0 0.25*sh0 0.35*sh0,0.20*sh0])
        
        plot(lenSEL,[clr1(2),'o-']);
        xlim([0 fibNum*1.2]);
        ylim([0.5*min(lenSEL) max(lenSEL)*1.2]);
        text(fibNum*0.25,max(lenSEL)*1.10,sprintf('length = %3.2f +/- %3.2f (n = %d)',lenMean,lenStd,fibNum),'color',clr2(3),'fontsize',fz2);
        xlabel('Fiber number[#]','fontsize',fz1)
        ylabel('Length [pixels]','fontsize',fz1)
        
    end
    
    % angle distribution:
    
    if angHV
        FA2 = angSEL;
        X2A = FA2;
        edgesA = 0:180/bins:180;
        edges = edgesA;    % bin edges
        gcf203 = figure(203); clf
        set(gcf203,'name',sprintf('angHIST:%s',imgName),'numbertitle','off')
        set(gcf203,'position',[(0.60*sw0+0.35*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [NA,BinA] = histc(X2A,edges);
        bar(edges,NA,'histc');
        axis square
        % YLtemp           title(sprintf('Extracted angle hist'),'fontsize',fz1);
        xlabel('Angle(degree)','fontsize',fz1)
        ylabel('Frequency','fontsize',fz1)
        
        gcf213 = figure(213); clf
        set(gcf213,'name',sprintf('angle:%s',imgName),'numbertitle','off')
        set(gcf213,'position',[(0.60*sw0+0.35*sh0) 0.25*sh0 0.35*sh0,0.20*sh0])
        plot(lenSEL,[clr1(3),'o-']);
        xlim([0 fibNum*1.2]);
        ylim([0.5*min(angSEL) max(angSEL)*1.2]);
        text(fibNum*0.25,max(angSEL)*1.10,sprintf('angle = %3.2f +/- %3.2f (n = %d)',angMean,angStd,fibNum),'color',clr2(3),'fontsize',fz2);
        xlabel('Fiber number[#]','fontsize',fz1)
        ylabel('Angle [degree]','fontsize',fz1)
        
    end
    
    % straightness analysis
    
    if strHV
        
        fstr = strSEL;   % fiber straightness
        X2str = fstr;  %
        
        edgesSTR = min(X2str):(1-min(X2str))/bins:1;
        edges = edgesSTR;    % bin edges
        gcf204 = figure(204); clf
        set(gcf204,'name',sprintf('strHIST:%s',imgName),'numbertitle','off')
        set(gcf204,'position',[(0.375*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [Nstr,Binstr] = histc(X2str,edges);
        bar(edges,Nstr,'histc');
        xlim([min(X2str) 1]);
        axis square
        %         title(sprintf('Fiber straightness hist'),'fontsize',fz1);
        xlabel('Straightness(-)','fontsize',fz1)
        ylabel('Frequency','fontsize',fz1)
        
        
        
        gcf214 = figure(214); clf
        set(gcf214,'name',sprintf('straigthness:%s',imgName),'numbertitle','off')
        set(gcf214,'position',[(0.375*sw0+0.05*sh0) 0.25*sh0 0.35*sh0,0.20*sh0])
        plot(strSEL,[clr1(4),'o-']);
        xlim([0 fibNum*1.2]);
        ylim([0.5*min(strSEL) max(strSEL)*1.2]);
        text(fibNum*0.25,max(strSEL)*1.10,sprintf('str = %3.2f +/- %3.2f (n = %d)',strMean,strStd,fibNum),'color',clr2(4),'fontsize',fz2);
        xlabel('Fiber number[#]','fontsize',fz1)
        ylabel('Straightness [-]','fontsize',fz1)
        
    end % strHV
    
    
    if widHV == 1
        
        % histogram of fiber width
        fwid = widSEL;
        X2wid = fwid;
        
        edgeswid = min(X2wid):(max(X2wid)-min(X2wid))/bins:max(X2wid);
        edges = edgeswid;    % bin edges
        gcf201 = figure(201); clf
        set(gcf201,'name',sprintf('widHIST:%s',imgName),'numbertitle','off')
        set(gcf201,'position',[(0.175*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [Nwid,Binwid] = histc(X2wid,edges);
        bar(edges,Nwid,'histc');
        axis square
        % YLtemp         title(sprintf('Fiber width hist'),'fontsize',fz1);
        xlabel('Width(pixels)','fontsize',fz1)
        ylabel('Frequency','fontsize',fz1)
        
        
        gcf211 = figure(211); clf
        set(gcf211,'name',sprintf('Width:%s',imgName),'numbertitle','off')
        set(gcf211,'position',[(0.175*sw0+0.05*sh0) 0.25*sh0 0.35*sh0,0.20*sh0])
        plot(widSEL,[clr1(1),'o-']);
        xlim([0 fibNum*1.2]);
        ylim([0.5*min(widSEL) max(widSEL)*1.2]);
        text(fibNum*0.25,max(widSEL)*1.10,sprintf('width = %3.2f +/- %3.2f (n = %d)',widMean,widStd,fibNum),'color',clr2(1),'fontsize',fz2);
        xlabel('Fiber number[#]','fontsize',fz1)
        ylabel('Width [pixels]','fontsize',fz1)
        
        
    end % widHV
    
    
    
elseif cP.stack == 1
    % read the xls file
    filesel = [selPath,selName];
    staName = {'width statistics','length statistics','angle statistics','straight statistics'};
    dataName = {'Width Data','Length Data','Angle Data','Straight Data'};
    selSTAall = struct('widSTA',[],'lenSTA',[],'angSTA',[],'strSTA',[],'sheetName',[],'imgName',[]);
    selFIBall = struct('widDAT',[],'lenDAT',[],'angDAT',[],'strDAT',[],'sheetName',[],'imgName',[]);
    STAnames = fieldnames(selSTAall);
    DATnames = fieldnames(selFIBall);
    totalFIB = 0 ; % initialize the total fiber number
    for i = 1:4
        [~,~,selSTA]= xlsread(filesel,staName{i});
        [~,~,selFIB]= xlsread(filesel,dataName{i});
        
        [~,imgNUM] = size(selFIB);
        selSTAall_temp = nan(imgNUM,3); % [fibMean, fibstd, fibNUM]
        
        for j = 1:imgNUM
            
            imgName{j} = selSTA{1,1+j};
            selSTAall_temp(j,1) =selSTA{4,1+j};  % mean
            selSTAall_temp(j,2) =selSTA{6,1+j};  % std
            selSTAall_temp(j,3) = selSTA{9,1+j}; % fiber number
            tempV = vertcat(selFIB{2:end,j});
            nanindex = find(isnan(tempV)== 1);
            tempV(nanindex) = [];
            %             selFIBdata_temp
            selFIBall.(DATnames{i}) = vertcat(selFIBall.(DATnames{i}),tempV);
        end
        
        selSTAall.(STAnames{i}) = selSTAall_temp;
        selSTAall.imName = imgName;
        
    end
    
    %% add a new sheet for combined selected files
    sheetTab = {selName,'Width','Length','Angle','Straightness'};
    fiberall = horzcat(selFIBall.(DATnames{1}),selFIBall.(DATnames{2}),selFIBall.(DATnames{3}),selFIBall.(DATnames{4}));
    %YL: save the combined fibers into an individual file 'selNameall', rather than add
    %aditional sheet into the original excel file 'selName'
    selNameall = [selName(1:end-5),'_all.xlsx']; 
    if MAC == 1
        
        xlwrite(fullfile(selPath,selNameall),sheetTab,'Combined ALL','A1');
        xlwrite(fullfile(selPath,selNameall),fiberall,'Combined ALL','B2');
    else
        xlswrite(fullfile(selPath,selNameall),sheetTab,'Combined ALL','A1');
        xlswrite(fullfile(selPath,selNameall),fiberall,'Combined ALL','B2');
    end
   
    
    if plotflag
        
        for i = 1:length(imgName)
            OLList = dir([selPath,imgName{i},'_overlaid_selected_fibers.tif']); % replace the "*" with "_overlaid_selected_fibers" to get unique image name
            gcf1 = figure('Resize','on','Units','pixels','Position',[225+20*i 250+15*i 512 512],'Visible','on',...
                'MenuBar','figure','name',sprintf('Overlaid selected fibers,image%d,%s',i,imgName{i}),'NumberTitle','off','UserData',0);
            imshow([selPath OLList.name]); axis equal image;
        end
    end
    %% show the statistics of the combined fibers
    % show the comparison of length hist
    if lenHV
        i = 2;
        FLout = selFIBall.(DATnames{i});
        X2L = FLout;
        lenBAR = selSTAall.(STAnames{i});
        lenSEL = X2L;
        fibNum = length(X2L); %or sum(LenBAR(:,3))
        lenMean = mean(X2L); %
        lenStd = std(X2L);   %
        
        inc = (max(FLout)-min(FLout))/bins;
        edgesL = min(FLout):inc:max(FLout);
        edges = edgesL;    % bin edges
        gcf302 = figure(302); clf
        set(gcf302,'name',sprintf('lenHIST:%s',selName),'numbertitle','off')
        set(gcf302,'position',[0.60*sw0 0.55*sh0 0.35*sh0,0.35*sh0])
        [NL,BinL] = histc(X2L,edges);
        bar(edges,NL,'histc');
        xlim([min(FLout) max(FLout)]);
        
        axis square
        %     xlim([edges(1) edges(end)]);
        % YLtemp            title(sprintf('Extracted length hist'),'fontsize',fz1);
        xlabel('Length(pixels)','fontsize',fz1);
        ylabel('Frequency','fontsize',fz1);
        %
        
        %
        gcf312 = figure(312); clf
        set(gcf312,'name',sprintf('length,combined:%s',selName),'numbertitle','off')
        set(gcf312,'position',[0.60*sw0 0.25*sh0 0.35*sh0,0.20*sh0])
        bar(lenBAR(:,1),clr3(2));hold on
        errorbar(lenBAR(:,1),lenBAR(:,2));
        
        %         xlim([0 imgNUM]);
        ylim([0.5*min(lenMean) max(lenMean)*2]);
        text(1,max(lenMean)*1.80,sprintf('length = %3.2f +/- %3.2f (n = %d)',lenMean,lenStd,fibNum),'color',clr2(i),'fontsize',fz2);
        for j = 1:imgNUM
            text(j-0.1,lenBAR(j,1)*1.1,sprintf('%d',lenBAR(j,3)),'color',clr2(i),'fontsize',fz2)
        end
        xlabel('Image number[#]','fontsize',fz1)
        ylabel('Length [pixels]','fontsize',fz1)
        
    end
    
    % angle distribution:
    
    if angHV
        
        i = 3;
        FA2 = selFIBall.(DATnames{i});
        X2A = FA2;
        angBAR = selSTAall.(STAnames{i});
        angSEL = X2A;
        angNum = length(X2A); %or sum(LenBAR(:,3))
        angMean = mean(X2A); %
        angStd = std(X2A);   %
        
        edgesA = 0:180/bins:180;
        edges = edgesA;    % bin edges
        gcf303 = figure(303); clf
        set(gcf303,'name',sprintf('angHIST:%s',selName),'numbertitle','off')
        set(gcf303,'position',[(0.60*sw0+0.35*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [NA,BinA] = histc(X2A,edges);
        bar(edges,NA,'histc');
        axis square
        % YLtemp           title(sprintf('Extracted angle hist'),'fontsize',fz1);
        xlabel('Angle(degree)','fontsize',fz1)
        ylabel('Frequency','fontsize',fz1)
        
        
        gcf313 = figure(313); clf
        set(gcf313,'name',sprintf('angle,combined:%s',selName),'numbertitle','off')
        set(gcf313,'position',[(0.60*sw0+0.35*sh0) 0.25*sh0 0.35*sh0,0.20*sh0])
        bar(angBAR(:,1),clr3(i));hold on
        errorbar(angBAR(:,1),angBAR(:,2));
        %         xlim([0 imgNUM]);
        ylim([0.5*min(angMean) max(angMean)*1.5]);
        text(1,max(angMean)*1.40,sprintf('angle = %3.2f +/- %3.2f (n = %d)',angMean,angStd,fibNum),'color',clr2(3),'fontsize',fz2);
        for j = 1:imgNUM
            text(j-0.1,angBAR(j,1)*1.1,sprintf('%d',angBAR(j,3)),'color',clr2(i),'fontsize',fz2);
        end
        xlabel('Image number[#]','fontsize',fz1)
        ylabel('Angle [degree]','fontsize',fz1)
        
    end
    
    % straightness analysis
    
    if strHV
        
        i = 4;
        fstr = selFIBall.(DATnames{i});% fiber straightness
        X2str = fstr;
        strBAR = selSTAall.(STAnames{i});
        strSEL = X2str;
        strNum = length(X2str); %or sum(LenBAR(:,3))
        strMean = mean(X2str); %
        strStd = std(X2str);   %
        
        
        edgesSTR = min(X2str):(1-min(X2str))/bins:1;
        edges = edgesSTR;    % bin edges
        gcf304 = figure(304); clf
        set(gcf304,'name',sprintf('strHIST:%s',selName),'numbertitle','off')
        set(gcf304,'position',[(0.375*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [Nstr,Binstr] = histc(X2str,edges);
        bar(edges,Nstr,'histc');
        xlim([min(X2str) 1]);
        axis square
        %         title(sprintf('Fiber straightness hist'),'fontsize',fz1);
        xlabel('Straightness(-)','fontsize',fz1)
        ylabel('Frequency','fontsize',fz1)
 
        
        gcf314 = figure(314); clf
        set(gcf314,'name',sprintf('straigthness,combined:%s',selName),'numbertitle','off')
        set(gcf314,'position',[(0.375*sw0+0.05*sh0) 0.25*sh0 0.35*sh0,0.20*sh0])
        bar(strBAR(:,1),clr3(i));hold on
        errorbar(strBAR(:,1),strBAR(:,2));
        %         xlim([0 imgNUM]);
        ylim([0.5*min(strMean) max(strMean)*1.5]);
        text(1,max(strMean)*1.40,sprintf('straightness = %3.2f +/- %3.2f (n = %d)',strMean,strStd,fibNum),'color',clr2(3),'fontsize',fz2);
        for j = 1:imgNUM
            text(j-0.1,strBAR(j,1)*1.1,sprintf('%d',strBAR(j,3)),'color',clr2(i),'fontsize',fz2)
        end
        xlabel('Image number[#]','fontsize',fz1)
        ylabel('Straightness [-]','fontsize',fz1)
        
    end % strHV
    
    % widith histogram
    if widHV == 1
        
        i = 1;
        fwid = selFIBall.(DATnames{i});
        X2wid = fwid;
        widBAR = selSTAall.(STAnames{i});
        widSEL = X2wid;
        widNum = length(X2wid); %or sum(LenBAR(:,3))
        widMean = mean(X2wid); %
        widStd = std(X2wid);   %
        
        
        edgeswid = min(X2wid):(max(X2wid)-min(X2wid))/bins:max(X2wid);
        edges = edgeswid;    % bin edges
        gcf201 = figure(201); clf
        set(gcf201,'name',sprintf('widHIST:%s',selName),'numbertitle','off')
        set(gcf201,'position',[(0.175*sw0+0.05*sh0) 0.55*sh0 0.35*sh0,0.35*sh0])
        [Nwid,Binwid] = histc(X2wid,edges);
        bar(edges,Nwid,'histc');
        axis square
        % YLtemp         title(sprintf('Fiber width hist'),'fontsize',fz1);
        xlabel('Width(pixels)','fontsize',fz1)
        ylabel('Frequency','fontsize',fz1)
        
        
        gcf311 = figure(311); clf
        
        set(gcf311,'name',sprintf('Width,combined:%s',selName),'numbertitle','off')
        set(gcf311,'position',[(0.175*sw0+0.05*sh0) 0.25*sh0 0.35*sh0,0.20*sh0])
        bar(widBAR(:,1),clr3(i));hold on
        errorbar(widBAR(:,1),widBAR(:,2));
        
        %         xlim([0 imgNUM]);
        ylim([0.5*min(widMean) max(widMean)*2]);
        text(1,max(widMean)*1.80,sprintf('width = %3.2f +/- %3.2f (n = %d)',widMean,widStd,fibNum),'color',clr2(i),'fontsize',fz2);
        for j = 1:imgNUM
            text(j-0.1,widBAR(j,1)*1.1,sprintf('%d',widBAR(j,3)),'color',clr2(i),'fontsize',fz2)
        end
        xlabel('Image number[#]','fontsize',fz1)
        ylabel('Width [pixels]','fontsize',fz1)
        
        
    end % widHV
    
end