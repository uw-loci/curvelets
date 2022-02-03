function bioFormatsMatlabGUI
clear,clc, home, close all
addpath(genpath(fullfile('C:/Users/sabri/Documents/GitHub/curvelets/bfmatlab-6.7.0')));

% define the font size used in the GUI
fz1 = 9 ; % font size for the title of a panel
fz2 = 10; % font size for the text in a panel
fz3 = 12; % font size for the button
fz4 = 14; % biggest fontsize size

global r;
global Img;
valList = {1,1,1,1};
ff = '';
ImgData = {};
stackSizeX = 0;
stackSizeY = 0;
stackSizeZ = 0;
seriesCount = 0;
nChannels = 0;
nTimepoints = 0;
nFocalplanes = 0;
voxelSizeXdouble = 1; %
voxelSizeYdouble = 1;
scaleBar = 1;
heightPix = 2;
scaleBarPos='';
fColor = '';
scaleBarCheck = 0;
fontNo = 0;
boldText = 0;
overlayVal = 0;

I = [];
BFcontrol = struct('imagePath','','imageName','','seriesCount',1,'nChannels',1,...
    @ -109,9 +113,11 @@ lbl_6.Layout.Row = 3;
lbl_6.Layout.Column = 2;

% scalebar
scaleBarLabel = uilabel(fig,'Position',[320 80 120 20],'Text','Scale Bar');
scaleBarCheck = uicheckbox(fig,'Position', [380 80 15 20],...
    'ValueChangedFcn', @setScaleBar);
% scaleBarLabel = uilabel(fig,'Position',[320 80 120 20],'Text','Scale Bar');
scaleBarInit = uibutton(fig,'Position', [320 80 92 20],'Text','Scale Bar',...
    'ButtonPushedFcn', @setScaleBar);
pixelInput = uieditfield(fig,'numeric','Position', [420 80 74 20],'Limits',[1 50],...
    'Value', 1);

% color map options
color_lbl = uilabel(fig,'Position',[320 50 80 20],'Text','Colormap');
@ -122,7 +128,7 @@ color.Items = ["Default Colormap" "MATLAB Color: JET" "MATLAB Color: Gray" "MATL
    % ok button [horizonal vertical element_length element_height]
    btnOK = uibutton(fig,'Position',[360 10 60 20],'Text','OK','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@return_Callback);
    % cancel button
    btnCancel = uibutton(fig,'Position',[430 10 60 20],'Text','Cancel','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@exit_Callback);
    btnCancel = uibutton(fig,'Position',[430 10 60 20],'Text','Cancel','ButtonPushedFcn',@exit_Callback);
    %% set colormap
    function setColor(src,event)
    colormap = color.Value;
    @ -351,36 +357,60 @@ btnCancel = uibutton(fig,'Position',[430 10 60 20],'Text','Cancel','BackgroundCo
    end
%% function dispSplitImages(hObject,src,eventData,handles)
    function setScaleBar(src,event)
        fig_1 = uifigure('Position',[80 50 240 200]);
        scaleBarCheck = 1;
        fig_1 = uifigure('Position',[80 50 240 260]);
        fig_1.Name = "Scale Bar";
        if isempty (voxelSizeXdouble) || isempty (voxelSizeYdouble)
            scaleBarMsg = uilabel(fig_1,'Position',[15 230 120 20],'Text','Width in Pixels');
        else
            
            scaleBarMsg = uilabel(fig_1,'Position',[15 230 120 20],'Text','Width in microns');
        end
        
        scaleBarMsg = uilabel(fig_1,'Position',[15 160 120 20],'Text','Width in microns');
        width = uieditfield(fig_1,'numeric','Position', [120 160 100 20],'Limits',[1 50],...
            'Value', 1);
        scaleBarPosMsg = uilabel(fig_1,'Position',[15 100 120 20],'Text','Position');
        position = uidropdown(fig_1,'Position',[120 100 100 20]);
        width = uieditfield(fig_1,'numeric','Position', [120 230 100 20],'Limits',[1 50],...
            'Value', 10);
        scaleBarPosMsg = uilabel(fig_1,'Position',[15 110 120 20],'Text','Position');
        position = uidropdown(fig_1,'Position',[120 110 100 20]);
        position.Items = ["Upper Right" "Upper Left" "Lower Right"...
            "Lower Left"];
        heightPixelsMsg = uilabel(fig_1,'Position',[15 130 120 20],'Text','Height in Pixels');
        heightPixels = uieditfield(fig_1,'numeric','Position', [120 130 100 20],'Limits',[1 50],...
            'Value', 1);
        fontcolorMsg = uilabel(fig_1,'Position',[15 70 120 20],'Text','Font Color');
        fontcolor = uidropdown(fig_1,'Position',[120 70 100 20]);
        heightPixelsMsg = uilabel(fig_1,'Position',[15 200 120 20],'Text','Height in Pixels');
        heightPixels = uieditfield(fig_1,'numeric','Position', [120 200 100 20],'Limits',[1 50],...
            'Value', 2);
        fontcolorMsg = uilabel(fig_1,'Position',[15 140 120 20],'Text','Font Color');
        fontcolor = uidropdown(fig_1,'Position',[120 140 100 20]);
        fontcolor.Items = ["white" "black" "cyan"...
            "red"];
        fontSizeMsg = uilabel(fig_1,'Position',[15 170 120 20],'Text','Font Size');
        fontSize = uieditfield(fig_1,'numeric','Position', [120 170 100 20],'Limits',[1 80],...
            'Value', 8);
        boldTextMsg = uilabel(fig_1,'Position',[15 80 60 20],'Text','Bold Text');
        boldTextCheck = uicheckbox(fig_1,'Position', [90 80 15 20])
        overlayMsg = uilabel(fig_1,'Position',[120 80 60 20],'Text','Overlay');
        overlayCheck = uicheckbox(fig_1,'Position', [195 80 15 20])
        
        scaleBarBtn = uibutton(fig_1,'Position',[200 10 40 20],'Text','Done','BackgroundColor','[0.4260 0.6590 0.1080]');
        scaleBarBtn.ButtonPushedFcn = {@getScaleBarValue,width,position,heightPixels,fontcolor};
        scaleBarBtn = uibutton(fig_1,'Position',[130 10 50 20],'Text','Ok','BackgroundColor','[0.4260 0.6590 0.1080]');
        scaleBarBtn.ButtonPushedFcn = {@getScaleBarValue,width,position,heightPixels,fontcolor,fontSize,boldTextCheck,overlayCheck};
        %         BFvisualziation(BFcontrol,axVisualization)
        %        fig_1.UserData = struct("Editfield",width,"Dropdown",position);
        scaleBarCancel = uibutton(fig_1,'Position',[185 10 50 20],'Text','Cancel');
        scaleBarCancel.ButtonPushedFcn = {@closeScaleBar,fig_1}
    end

%%
    function closeScaleBar(src,event,fig_1)
        close(fig_1);
        scaleBarCheck = 0;
    end

%%
    function getScaleBarValue(src,event,width,position,heightPixels,fontcolor)
        function getScaleBarValue(src,event,width,position,heightPixels,fontcolor,fontSize,boldTextCheck,overlayCheck)
            scaleBar = width.Value;
            scaleBarPos = position.Value;
            heightPix = heightPixels.Value;
            fColor = fontcolor.Value;
            fontNo = fontSize.Value;
            overlayVal = overlayCheck.Value;
            boldText = boldTextCheck.Value;
            BFvisualziation(BFcontrol,axVisualization);
        end
        %% visualization function
        @ -403,43 +433,68 @@ btnCancel = uibutton(fig,'Position',[430 10 60 20],'Text','Cancel','BackgroundCo
        imagesc(I,'Parent',axVisualization);
        set(axVisualization,'YTick',[],'XTick',[]);
        colormap(axVisualization,BFcontrol.colormap);
        if scaleBarCheck.Value == 1
            if scaleBarCheck == 1
                switch scaleBarPos
                    case 'Upper Right'
                        [row, col, ~] = size(I);
                        x = [col-scaleBar/voxelSizeXdouble, col];
                        y = round([row*.10, row*.10]);
                        y = round([row*.05, row*.05]);
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        text(x(1),round(row*.05),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', 8,'Color',fColor);
                        hold on;
                        if boldText == 1
                            text((x(2)-x(1))/2+x(1)-10,round(row*.07),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                            hold on;
                        else
                            text((x(2)-x(1))/2+x(1)-10,round(row*.07),[num2str(round(scaleBar)) '\mum'],'FontSize', fontNo,'Color',fColor);
                            hold on;
                        end
                        
                        
                    case 'Upper Left'
                        [row, col, ~] = size(I);
                        x = [0,scaleBar/voxelSizeXdouble];
                        y = round([row*.10, row*.10]);
                        y = round([row*.05, row*.05]);
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        text(x(1),round(row*.05),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', 8,'Color',fColor);
                        hold on;
                        
                        if boldText == 1
                            text(x(2)/2-10,round(row*.07),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                            hold on;
                        else
                            text(x(2)/2-10,round(row*.07),[num2str(round(scaleBar)) '\mum'],'FontSize', fontNo,'Color',fColor);
                            hold on;
                        end
                        
                        
                    case 'Lower Right'
                        [row, col, ~] = size(I);
                        x = [col-scaleBar/voxelSizeXdouble, col];
                        y = round([row*.95, row*.95]);
                        y = round([row*.93, row*.93]);
                        
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        text(x(1),round(row*.90),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', 8,'Color',fColor);
                        hold on;
                        if boldText == 1
                            text((x(2)-x(1))/2+x(1)-10,round(row*.95),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                            hold on;
                        else
                            text((x(2)-x(1))/2+x(1)-10,round(row*.95),[num2str(round(scaleBar)) '\mum'],'FontSize', fontNo,'Color',fColor);
                            hold on;
                        end
                        
                    case 'Lower Left'
                        [row, col, ~] = size(I);
                        x = [col-scaleBar/voxelSizeXdouble, col];
                        y = round([row*.95, row*.95]);
                        x = [0,scaleBar/voxelSizeXdouble];
                        y = round([row*.93, row*.93]);
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        text(x(1),round(row*.90),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', 8,'Color',fColor);
                        hold on;
                        if boldText == 1
                            text(x(2)/2-10,round(row*.95),[num2str(round(scaleBar)) '\mum'],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                            hold on;
                        else
                            text(x(2)/2-10,round(row*.95),[num2str(round(scaleBar)) '\mum'],'FontSize', fontNo,'Color',fColor);
                            hold on;
                        end
                        
                        
                end
                
            end
        end
        
        
        
        
        axis image equal
        drawnow;
    end
%% save button callback to save images using bfsave function
    function save_Callback (src,eventData)
        val = ss.Value;
        %         ss.Items = [,"Regular" "MATLAB readable" "Metadata"];
        switch val
            case 'Regualar'
                selpath = uigetdir(path);
                [a b] = fileparts(selpath);
                bfsave(I, b);  %strsplit   %strfind
                
            case 'MATLAB readable'
                [I pathName] = uiputfile;
                fprintf(pathName);
                
            case 'Metadata'
                selpath = uigetdir(path);
                [a b] = fileparts(selpath);
                metadata = createMinimalOMEXMLMetadata(I);
                pixelSize = ome.units.quantity.Length(java.lang.Double(.05), ome.units.UNITS.MICROMETER);
                metadata.setPixelsPhysicalSizeX(pixelSize,voxelSizeXdouble);
                metadata.setPixelsPhysicalSizeY(pixelSize, voxelSizeXdouble);
                pixelSizeZ = ome.units.quantity.Length(java.lang.Double(.2), ome.units.UNITS.MICROMETER);
                metadata.setPixelsPhysicalSizeZ(pixelSizeZ,stackSizeZ);
                bfsave(I, b,'metadata.ome.tiff', 'metadata', metadata);
        end
        
        
    end


%% ok button callback to return selected image
    function return_Callback(src,eventData)
        assignin('base','BFoutput',I)
    end
%% cancel button to close the window
    function exit_Callback(src,eventData)
        close(fig)
    end
end