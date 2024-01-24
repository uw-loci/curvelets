% makePlots.m
% create output plots for all image channels
% Inputs: 
% IMG = cell array containing images
% BWshow = display outline
% names = cell array of channel names
% plots = plot data for all analysis channels
% maxLength = length of longest data set
% cent = center of cell(s)
% r1 = row location of start point
% c1 = column location of start point
% alignVal = indicates which channel was used for alignment
% pts = location of curvelets used in alignments
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function makePlots(IMG,BWshow,names,plots,maxLength,cent,r1,c1,alignVal,varargin)

if size(varargin,1) > 0
    pts = varargin{1};
end

numPlots = length(plots);

h = figure; set(h,'NextPlot','replacechildren'); set(h,'DefaultAxesXLim',[0 maxLength]); set(h,'DefaultAxesYLim',[0 1.25]); set(h,'Visible','off');
       set(h, 'PaperPositionMode', 'auto'); set(h,'PaperOrientation','landscape'); 

switch numPlots
    case 1
        for dd = 1:length(plots{1})
            subplot(6,5,[1:3,6:8,11:13,16:18,21:23])
            plot([1:length(plots{1}{dd})],plots{1}{dd});  
            L = legend(names{1});
            set(L,'Interpreter','none','Location','NorthEast')
            
            subplot(6,5,[4:5,9:10])
            imshow(BWshow{dd})
            hold on
            plot(cent{dd}(1),cent{dd}(2),'*r')
            plot(c1{dd},r1{dd},'*b')
            hold off
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title('Mask','VerticalAlignment','baseline')
            
            subplot(6,5,[14:15,19:20])
            imshow(IMG{1}{dd})
                if alignVal == 1
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title(names{1},'VerticalAlignment','baseline')

            F = hardcopy(h,'-DOpenGL','-r0');
            if length(plots{1}) == 1
                figure('PaperOrientation','landscape'); imshow(F); set(gca,'Visible','off');
            else
            plotImg(:,:,:,dd) = F(:,:,:);
            cla(AX2)
            end
        end

        close(h)
     if length(plots{1}) > 1
        implay(plotImg)  
     end
        
    case 2
       pos = get(h,'OuterPosition');
       pos(3) = pos(3) + 200;
       pos(4) = pos(4) + 100;
       
       set(h,'OuterPosition',pos);
 
            subplot(6,5,[1:3,6:8,11:13,16:18,21:23])
            AX1 = gca; set(AX1,'Ylim',[0 1.25]);
            AX2 = axes('Position',get(AX1,'Position'),'XAxisLocation','bottom','YAxisLocation','right','Color','none','XColor','k','YColor','k','XLim',[0 maxLength],'YLim',[0 1.2]);
            set(get(AX1,'XLabel'),'String','Location (pixels)');
            set(get(AX1,'YLabel'),'String','Distance from Center (A.U.)');
            set(get(AX2,'YLabel'),'String','Intensity (A.U.)');
         for dd = 1:length(plots{1})
            H1 = line([1:length(plots{1}{dd})],plots{1}{dd},'Color','b','Parent',AX2);
            H2 = line([1:length(plots{2}{dd})],plots{2}{dd},'Color','g','Parent',AX2);
            L = legend([H1 H2],names{1},names{2},2);
            set(L,'Interpreter','none','Location','NorthEast')  
           
            
            subplot(6,5,[4:5,9:10])
            imshow(BWshow{dd})
            hold on
            plot(cent{dd}(1),cent{dd}(2),'*r')
            plot(c1{dd},r1{dd},'*b')
            hold off
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(gca,'DrawMode','fast')
            title('Mask')
            
            subplot(6,5,[14:15,19:20])
            imshow(IMG{1}{dd})
                if alignVal == 1
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title(names{1},'VerticalAlignment','baseline')
            
            subplot(6,5,[24:25,29:30])
            imshow(IMG{2}{dd})
                if alignVal == 2
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title(names{2},'VerticalAlignment','baseline')
            
            F = hardcopy(h,'-DOpenGL','-r0');
            if length(plots{1}) == 1
                figure('PaperOrientation','landscape'); imshow(F); set(gca,'Visible','off');
            else
            plotImg(:,:,:,dd) = F(:,:,:);
            cla(AX2)
            end

        end
        
        close(h)
     if length(plots{1}) > 1
        implay(plotImg)  
     end
     
    case 3
       pos = get(h,'OuterPosition');
       pos(3) = pos(3) + 250;
       pos(4) = pos(4) + 150;
       
       set(h,'OuterPosition',pos);
        
        subplot(8,7,[1:5,8:12,15:19,22:26,29:33,36:40,43:47,50:54])
        AX1 = gca; set(AX1,'Ylim',[0 1.25]);
        AX2 = axes('Position',get(AX1,'Position'),'XAxisLocation','bottom','YAxisLocation','right','Color','none','XColor','k','YColor','k','XLim',[0 maxLength],'YLim',[0 1.2]);
        set(get(AX1,'XLabel'),'String','Location (pixels)');
        set(get(AX1,'YLabel'),'String','Distance from Center (A.U.)');
        set(get(AX2,'YLabel'),'String','Intensity (A.U.)');

        for dd = 1:length(plots{1})
            H1 = line([1:length(plots{1}{dd})],plots{1}{dd},'Color','b','Parent',AX2);
            H2 = line([1:length(plots{2}{dd})],plots{2}{dd},'Color','g','Parent',AX2);
            H3 = line([1:length(plots{3}{dd})],plots{3}{dd},'Color','r','Parent',AX2);
            L = legend([H1 H2 H3],names{1},names{2},names{3},3);
            set(L,'Interpreter','none','Location','NorthEast')
            
            subplot(8,7,[6:7,13:14])
            imshow(BWshow{dd})
            hold on
            plot(cent{dd}(1),cent{dd}(2),'*r')
            plot(c1{dd},r1{dd},'*b')
            hold off
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title('Mask','VerticalAlignment','baseline')
            
            subplot(8,7,[20:21,27:28])
            imshow(IMG{1}{dd})
                if alignVal == 1
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title(names{1},'VerticalAlignment','baseline')
            
            subplot(8,7,[34:35,41:42])
            imshow(IMG{2}{dd})
                if alignVal == 2
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title(names{2},'VerticalAlignment','baseline')
            
            subplot(8,7,[48:49,55:56])
            imshow(IMG{3}{dd})
                if alignVal == 3
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            title(names{3},'VerticalAlignment','baseline')

            F = hardcopy(h,'-DOpenGL','-r0');
            if length(plots{1}) == 1
                figure('PaperOrientation','landscape'); imshow(F); set(gca,'Visible','off');
            else
            plotImg(:,:,:,dd) = F(:,:,:);
            cla(AX2)
            end

        end
    
        close(h)
     if length(plots{1}) > 1
        implay(plotImg)  
     end

    case 4
       pos = get(h,'OuterPosition');
       pos(3) = pos(3) + 300;
       pos(4) = pos(4) + 200;
       
       set(h,'OuterPosition',pos);
        
        subplot(10,9,[1:7,10:16,19:25,28:34,37:43,46:52,55:61,64:70,73:79,82:88])
        AX1 = gca; set(AX1,'Ylim',[0 1.25]);
        AX2 = axes('Parent',h,'Position',get(AX1,'Position'),'XAxisLocation','bottom','YAxisLocation','right','Color','none','XColor','k','YColor','k','XLim',[0 maxLength],'YLim',[0 1.2]);
        set(get(AX1,'XLabel'),'String','Location (pixels)');
        set(get(AX1,'YLabel'),'String','Distance from Center (A.U.)');
        set(get(AX2,'YLabel'),'String','Intensity (A.U.)');
        get(get(AX2,'YLabel'),'Position');
        
        sz = get(h,'Position');
        plotImg = zeros(sz(4),sz(3),3,length(plots{1}),'uint8');
        
        for dd = 1:length(plots{1})
            H1 = line([1:length(plots{1}{dd})],plots{1}{dd},'Color','b','Parent',AX2);
            H2 = line([1:length(plots{2}{dd})],plots{2}{dd},'Color','g','Parent',AX2);
            H3 = line([1:length(plots{3}{dd})],plots{3}{dd},'Color','r','Parent',AX2);
            H4 = line([1:length(plots{4}{dd})],plots{4}{dd},'Color','c','Parent',AX2);
            L = legend([H1 H2 H3 H4],names{1},names{2},names{3},names{4},4);
            set(L,'Interpreter','none','Location','NorthEast')
            
            subplot(10,9,[8:9,17:18],'Units','normalized','Position',[.78 .84 .13 .13])
            imshow(BWshow{dd})
            hold on
            plot(cent{dd}(1),cent{dd}(2),'*r')
            plot(c1{dd},r1{dd},'*b')
            hold off
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String','Mask')
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 20 0])

            
            subplot(10,9,[26:27,35:36],'Units','normalized','Position',[.78 .64 .13 .13])
            imshow(IMG{1}{dd})
                if alignVal == 1
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end            
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String',names{1})
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 20 0])  
            
            subplot(10,9,[44:45,53:54],'Units','normalized','Position',[.78 .44 .13 .13])
            imshow(IMG{2}{dd})
                if alignVal == 2
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end            
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String',names{2})
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 20 0])

            subplot(10,9,[62:63,71:72],'Units','normalized','Position',[.78 .26 .13 .13])
            imshow(IMG{3}{dd})
                if alignVal == 3
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String',names{3})
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 20 0])
            
            subplot(10,9,[80:81,89:90],'Units','normalized','Position',[.78 .05 .13 .13])
            imshow(IMG{4}{dd})
                if alignVal == 4
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 20 0])
            set(get(gca,'XLabel'),'String',names{4})

           
            
            F = hardcopy(h,'-DOpenGL','-r0');

            if length(plots{1}) == 1
                figure('PaperOrientation','landscape'); imshow(F); set(gca,'Visible','off');
            else
            plotImg(:,:,:,dd) = F(:,:,:);
            cla(AX2)
            end
        end
        close(h)
     if length(plots{1}) > 1
        implay(plotImg)  
     end
     
    case 5 
       pos = get(h,'OuterPosition');
       pos(3) = pos(3) + 350;
       pos(4) = pos(4) + 250;
       
       set(h,'OuterPosition',pos);
        
        subplot(12,10,[1:8,11:18,21:28,31:38,41:48,51:58,61:68,71:78,81:88,91:98,101:108,111:118])
        AX1 = gca; set(AX1,'Ylim',[0 1.25]);
        AX2 = axes('Parent',h,'Position',get(AX1,'Position'),'XAxisLocation','bottom','YAxisLocation','right','Color','none','XColor','k','YColor','k','XLim',[0 maxLength],'YLim',[0 1.2]);
        set(get(AX1,'XLabel'),'String','Location (pixels)');
        set(get(AX1,'YLabel'),'String','Distance from Center (A.U.)');
        set(get(AX2,'YLabel'),'String','Intensity (A.U.)');
        get(get(AX2,'YLabel'),'Position');
        
        sz = get(h,'Position');
        plotImg = zeros(sz(4),sz(3),3,length(plots{1}),'uint8');
        
        for dd = 1:length(plots{1})
            H1 = line([1:length(plots{1}{dd})],plots{1}{dd},'Color','b','Parent',AX2);
            H2 = line([1:length(plots{2}{dd})],plots{2}{dd},'Color','g','Parent',AX2);
            H3 = line([1:length(plots{3}{dd})],plots{3}{dd},'Color','r','Parent',AX2);
            H4 = line([1:length(plots{4}{dd})],plots{4}{dd},'Color','c','Parent',AX2);
            H5 = line([1:length(plots{5}{dd})],plots{5}{dd},'Color','m','Parent',AX2);
            L = legend([H1 H2 H3 H4 H5],names{1},names{2},names{3},names{4},4,names{5},5);
            set(L,'Interpreter','none','Location','NorthEast')
            
            subplot(12,10,[9:10,19:20],'Units','normalized','Position',[.78 .85 .1 .1])
            imshow(BWshow{dd})
            hold on
            plot(cent{dd}(1),cent{dd}(2),'*r')
            plot(c1{dd},r1{dd},'*b')
            hold off
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String','Mask')
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 15 0])

            
            subplot(12,10,[29:30,39:40],'Units','normalized','Position',[.78 .7 .1 .1])
            imshow(IMG{1}{dd})
                if alignVal == 1
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end            
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String',names{1})
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 15 0])  
            
            subplot(12,10,[49:50,59:60],'Units','normalized','Position',[.78 .55 .1 .1])
            imshow(IMG{2}{dd})
                if alignVal == 2
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end            
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String',names{2})
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 15 0])

            subplot(12,10,[69:70,79:80],'Units','normalized','Position',[.78 .4 .1 .1])
            imshow(IMG{3}{dd})
                if alignVal == 3
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'String',names{3})
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 15 0])
            
            subplot(12,10,[89:90,99:100],'Units','normalized','Position',[.78 .25 .1 .1])
            imshow(IMG{4}{dd})
                if alignVal == 4
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 15 0])
            set(get(gca,'XLabel'),'String',names{4})
           
            subplot(12,10,[109:110,119:120],'Units','normalized','Position',[.78 .1 .1 .1])
            imshow(IMG{5}{dd})
                if alignVal == 5
                    hold on
                    axis image
                    plot(pts{dd}(:,2),pts{dd}(:,1),'*r')
                    hold off
                end
            set(gca,'XTickLabel',[],'YTickLabel',[])
            set(get(gca,'XLabel'),'Position',get(get(gca,'XLabel'),'Position')-[0 15 0])
            set(get(gca,'XLabel'),'String',names{5})
            
            F = hardcopy(h,'-DOpenGL','-r0');

            if length(plots{1}) == 1
                figure('PaperOrientation','landscape'); imshow(F); set(gca,'Visible','off');
            else
            plotImg(:,:,:,dd) = F(:,:,:);
            cla(AX2)
            end
        end
        close(h)
     if length(plots{1}) > 1
        implay(plotImg)  
     end
        
end

end
        