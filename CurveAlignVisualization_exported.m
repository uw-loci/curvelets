classdef CurveAlignVisualization_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CAvisualization                matlab.ui.Figure
        TabGroup                       matlab.ui.container.TabGroup
        VisualizationTab               matlab.ui.container.Tab
        Panel_2                        matlab.ui.container.Panel
        CloseButton                    matlab.ui.control.Button
        OpenCurveAlignButton           matlab.ui.control.Button
        ResetButton                    matlab.ui.control.Button
        HeatmapcontrolPanel            matlab.ui.container.Panel
        colorMaxEditField              matlab.ui.control.NumericEditField
        colorMaxEditFieldLabel         matlab.ui.control.Label
        colorMinEditField              matlab.ui.control.NumericEditField
        colorMinEditFieldLabel         matlab.ui.control.Label
        nColorsDropDown                matlab.ui.control.DropDown
        nColorsDropDownLabel           matlab.ui.control.Label
        ColormapDropDown               matlab.ui.control.DropDown
        ColormapDropDownLabel          matlab.ui.control.Label
        Gaussian_Filter_SizeEditField  matlab.ui.control.NumericEditField
        Gaussian_Filter_SizeEditFieldLabel  matlab.ui.control.Label
        Max_Filter_SizeEditField       matlab.ui.control.NumericEditField
        Max_Filter_SizeEditFieldLabel  matlab.ui.control.Label
        Switch2                        matlab.ui.control.Switch
        BinNumberSlider                matlab.ui.control.Slider
        BinNumberSliderLabel           matlab.ui.control.Label
        PlottingOptionsButtonGroup     matlab.ui.container.ButtonGroup
        HeatmapButton                  matlab.ui.control.RadioButton
        HistogramButton                matlab.ui.control.RadioButton
        BoxplotButton                  matlab.ui.control.RadioButton
        LocationButton                 matlab.ui.control.RadioButton
        FeatureListListBox             matlab.ui.control.ListBox
        FeatureListListBoxLabel        matlab.ui.control.Label
        Panel                          matlab.ui.container.Panel
        FileListListBox                matlab.ui.control.ListBox
        FileListListBoxLabel           matlab.ui.control.Label
        OpenFeatureFileButton          matlab.ui.control.Button
        UIAxes                         matlab.ui.control.UIAxes
        FeatureValuesTab               matlab.ui.container.Tab
        UITable                        matlab.ui.control.Table
        OriginalimageTab               matlab.ui.container.Tab
        UIAxes2                        matlab.ui.control.UIAxes
        OverlayImageTab                matlab.ui.container.Tab
        UIAxes3                        matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        
        filePath = pwd;  % file path
        fileList = cell(1); % all the files opened
        featureList = cell(1); % all the featurs loaded
        fileSelected; % image to be plotted
        featureSelected; % feature to be plotted, default: 04 Absolute angle
        plotOption;     % option of plotting
        Data;          % Data from the feature file
        BinNumber;       % Number of bins for the histogram, default 10
        Histogram = gobjects(0);
        %heatmap parameters
        STDfilter_size;
        SQUAREmaxfilter_size; % default12;
        GAUSSIANdiscfilter_sigma;  % default 0.1;
        colormapSelected; % default 'jet';
        nColorsInColormap; % default '64';
        colorScalingMin; % default 0
        colorScalingMax; % default 180;
    end
    
    
    methods (Access = private)
        
        function LocationScatterPlot(app)
            %             % Update X and Y Labels
            %             app.UIAxes.XLabel.String = '';
            %             app.UIAxes.YLabel.String = '';
            %             % Dont show the histogram slider
            %             app.BinNumberSliderLabel.Visible = 'off';
            %             app.BinNumberSlider.Visible = 'off';
        end
        
        
        function [rawmap, procmap] = CAheatmap(app)
            % Outputs
            % rawmap: 2D image where grey levels indicate angle information
            % procmap: A filtered version of the rawmap
            J = app.Data.imageHeight;
            I = app.Data.imageWidth;
            rawmap = nan(J,I);
            procmap = rawmap;
            featureNumber = size(app.Data.fibFeat,1);
            for iF = 1:featureNumber
                xc = app.UITable.Data.EndPointColumn(iF);
                yc = app.UITable.Data.EndPointRow(iF);
                if (xc > I || xc < 1 || yc > J || yc < 1)
                    continue;
                end
                rawmap(yc,xc) = app.UITable.Data.(app.featureSelected)(iF);
                
            end
            %find the positions of all non-nan values
            map2 = rawmap;
            ind = find(~isnan(rawmap));
            [y,x] = ind2sub([J I],ind);
            %             bndryMeas = 0;
            %             if ~bndryMeas
            %                 %standard deviation filter
            %                 %         fSize = round(I/16);
            %                 %         fSize2 = ceil(fSize/2);
            %                 fSize2 = 18; %mapCP.STDfilter_size;
            %                 map2 = nan(J,I);
            %                 for i = 1:length(ind)
            %                     %find any positions that are in a square region around the
            %                     %current curvelet
            %                     ind2 = find(x > x(i)-fSize2 & x < x(i)+fSize2 & y > y(i)-fSize2 & y < y(i)+fSize2);
            %                     %convert these positions to linear indices
            %                     ind3 = sub2ind([J I],y(ind2),x(ind2));
            %                     %get all the grey level values
            %                     vals = rawmap(ind3);
            %                     if length(vals) > 2
            % %                         %Perform the circular angle uniformity test, first scale values from 0-255 to 0-2*pi
            % %                         %Then scale from 0-1 to 0-255
            % %                         map2(y(i),x(i)) = (circ_r(vals*pi/127.5))*255;
            %                           map2(y(i),x(i))= mean(vals(:));
            %                     end
            %
            %                 end
            %                 %figure(600); imagesc(map2); colorbar;
            %             end
            %max filter
            fSize = app.SQUAREmaxfilter_size;% YL: pass this from the interface %12;% round(J/64);  %YL: fix the fsize to 12 to make the ratio of fsize/sig =3 which is the one used in the version 2.3
            fSize2 = ceil(fSize/2);
            map4 = nan(J,I); %yl nan(size(img));
            tic
            for i = 1:length(ind)
                val = map2(y(i),x(i));
                rows = y(i)-fSize2:y(i)+fSize2;
                cols = x(i)-fSize2:x(i)+fSize2;
                %get rid of out of bounds coordinates
                ind4 = find(rows > 0 & rows < J & cols > 0 & cols < I);
                rows = rows(ind4);
                cols = cols(ind4);
                %now make a square collection of indices
                lenInd = length(ind4);
                lenInd2 = lenInd*lenInd;
                rows = repmat(rows,1,lenInd);
                cols = reshape(repmat(cols,lenInd,1),1,lenInd2);
                %get the linear indices in the original map
                ind5 = sub2ind([J I],rows,cols);
                
                
                %find the number of fibers within the filter region for normalization
                % creates a metric of alignment per fiber, normalizes away density
                % we don't really care about density, we care much more about alignment
                ind6 = find(~isnan(rawmap(ind5)));
                numFibs = length(ind6);
                
                %set the value to the max of the current or what was there
                map4(ind5) = max(map4(ind5),val/numFibs);
            end
            %figure(675); imagesc(map4); colorbar;
            %gaussian filter
            sig =  app.GAUSSIANdiscfilter_sigma; % YL: pass this from the interface % round(J/96); %in pixels; YL: fix the filter size
            h = fspecial('gaussian', [10*sig 10*sig], sig);
            %uint 8 converts nans to zeros
            %              procmap = imfilter(uint8(map4),h,'replicate');
            map4(isnan(map4)) = 0;
            procmap = imfilter(map4,h,'replicate'); %yl
            %figure(700); imagesc(procmap); colorbar;
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Don't show heatmap control panel
            app.HeatmapcontrolPanel.Visible = 'off';
            app.BinNumberSliderLabel.Visible = 'off';
            app.BinNumberSlider.Visible = 'off';
            app.FileListListBox.Enable = 'off';
            app.FeatureListListBox.Enable = 'off';
            app.LocationButton.Enable = 'off';
            app.BoxplotButton.Enable = 'off';
            app.HistogramButton.Enable = 'off';
            app.HeatmapButton.Enable = 'off';
            
            imshow(zeros(1024,1024), 'Parent',app.UIAxes)
            text('FontSize',12,'FontWeight','Bold','Color','r', 'Position',[240 256],'String',sprintf('Feature Visualization:\n\n    %s\n\n    %s\n\n    %s\n\n    %s',...
                'Location','Boxplot', 'Histogram', 'Heatmap'), 'Parent',app.UIAxes); %'HorizontalAlignment', 'right','VerticalAlignment','middle',
            xlabel(app.UIAxes,'')
            ylabel(app.UIAxes,'')
            title(app.UIAxes,'Plotting Area','HorizontalAlignment','right')
           
            app.featureSelected = strrep(app.FeatureListListBox.Value(4:end),' ', '');
            app.BinNumber = app.BinNumberSlider.Value;
            app.colormapSelected = app.ColormapDropDown.Value;
            app.nColorsInColormap = app.nColorsDropDown.Value;
            app.colorScalingMin = app.colorMinEditField.Value;
            app.colorScalingMax = app.colorMaxEditField.Value;
            app.SQUAREmaxfilter_size = app.Max_Filter_SizeEditField.Value;
            app.GAUSSIANdiscfilter_sigma = app.Gaussian_Filter_SizeEditField.Value;  
                
        end

        % Button pushed function: OpenFeatureFileButton
        function OpenFeatureFileButtonPushed(app, event)
            %load the file path of the previous operation
            if exist('caVisualizationData.mat','file')
                load('caVisualizationData.mat','filePath');
                if ischar(filePath)
                    app.filePath = filePath;
                else
                    app.filePath = pwd;
                end
            else
                filePath = app.filePath;
                save('caVisualizationData.mat','filePath');
            end
            [fileName,filePath] = uigetfile({...
                '*.mat','MAT-files (*.mat)'; '*.*',  'All Files (*.*)'},'Select CurveAlign Output .mat feature file',app.filePath,'MultiSelect','off');
            if ~isempty(fileName)
                app.filePath = filePath;
                save('caVisualizationData.mat','filePath');
            else
                error('No feature .mat file is selected');
            end
            if(~iscell(fileName))
                app.fileList{1} = fileName;
                app.fileSelected = fileName;
            end
            app.Data = load(fullfile(app.filePath, app.fileSelected));  % all the features from the .mat file
            app.FileListListBox.Items = app.fileList;
            app.FileListListBox.Value = app.FileListListBox.Items{1};
            %feature list box
            %             featNames = app.Data.featNames;
            %             featNames = cellfun(@(x) x(~isspace(x)),featNames,'UniformOutput', false);
            %             featNames{1} = 'FiberIndex';
            % Format the feature names to be displayed in the GUI
            minimumNearestFibers = app.Data.advancedOPT.minimum_nearest_fibers;
            minimumBoxSize = app.Data.advancedOPT.minimum_box_size;
            FeatureControlParameters.minimumNearestFibers = minimumNearestFibers;
            FeatureControlParameters.minimumBoxSize = minimumBoxSize;
            featureNames = formatFeatureName(FeatureControlParameters); 
            app.FeatureListListBox.Items = featureNames;
            
            % Create variables associated with the feature Names
            featNamesNoSpace = cellfun(@(x) x(~isspace(x)),featureNames,'UniformOutput', false);  % Remove the space in the feature name.
            app.Data.featNames = cellfun(@(x) x(4:end),featNamesNoSpace,'UniformOutput', false); % Remove the numbers in the beginning.
            
            app.FeatureListListBox.Value = app.FeatureListListBox.Items{4}; % Default feature to be displayed 
            
            ImageName = strrep(app.fileSelected,'_fibFeatures.mat','');
            upperFilePath = fullfile(app.filePath,'..');
            app.Data.imageWidth = nan;
            app.Data.imageHeight = nan;
            %show original image in a tab
            try
                findOriginalImage = dir(fullfile(upperFilePath,[ImageName '.*']));
                if ~isempty(findOriginalImage)
                    if iscell(findOriginalImage)
                        error ('%d files have the same name %s but different formats \n',length(findOriginalImage),ImageName);
                    else
                        originalImage = findOriginalImage.name;
                        imageInformation = imfinfo(fullfile(upperFilePath,originalImage));
                         %Store image size into the app.Data.imageWidth/imageHeight
                        app.Data.imageWidth = imageInformation.Width;
                        app.Data.imageHeight = imageInformation.Height;
                        fprintf('Found original image at %s \n', fullfile(upperFilePath,originalImage))
                    end
                    
                else
                    error ('Original image is not found')
                end
                imshow(fullfile(upperFilePath,originalImage),'Parent',app.UIAxes2);
                colormap(app.UIAxes2,'bone');
                colorbar(app.UIAxes2)
                axis(app.UIAxes2,'image','equal')
                title(app.UIAxes2,originalImage, 'Interpreter','none')
                disp('Original image is located and displayed')
             catch ME
                fprintf('%s \n',ME.message)
            end
            
            % show overlay image in a tab
            try
                overlayImage = [ImageName '_overlay.tiff'];
                imshow(fullfile(app.filePath,overlayImage),'Parent',app.UIAxes3)
                axis(app.UIAxes3,'image','equal')
                title(app.UIAxes3,overlayImage, 'Interpreter','none')
                disp('CA overlay image is located and displayed')
            catch ME
                fprintf('%s \n',ME.message)
            end
            
            % Store the data in a table tab
            tData = array2table(app.Data.fibFeat, 'VariableNames',app.Data.featNames');
            app.UITable.Data = tData;
            app.UITable.ColumnName = tData.Properties.VariableNames;
            
            app.BinNumberSlider.Visible = 'on';
            app.FileListListBox.Enable = 'on';
            app.FeatureListListBox.Enable = 'on';
            app.FeatureListListBox.Enable = 'on';
            app.LocationButton.Enable = 'on';
            app.BoxplotButton.Enable = 'on';
            app.HistogramButton.Enable = 'on';
            app.HeatmapButton.Enable = 'on';
            app.PlottingOptionsButtonGroupSelectionChanged(app)
        end

        % Callback function
        function FileListListBoxValueChanged(app, event)
            value = app.FileListListBox.Value;
        end

        % Callback function: BinNumberSlider, HeatmapcontrolPanel, 
        % ...and 1 other component
        function PlottingOptionsButtonGroupSelectionChanged(app, event)
            selectedButton = app.PlottingOptionsButtonGroup.SelectedObject;
            app.plotOption = selectedButton.Text;
                     
            if ~strcmp(app.plotOption, 'Histogram')
                % Don't show histogram slider
                app.BinNumberSliderLabel.Visible = 'off';
                app.BinNumberSlider.Visible = 'off';
            end
            if ~strcmp(app.plotOption, 'Heatmap')
                % Don't show heatmap control panel
                app.HeatmapcontrolPanel.Visible = 'off';
            end
            switch app.plotOption
                case 'Location'
                    cla(app.UIAxes,'reset')
                    %                     hold(app.UIAxes,'on')
                    backgroundIntensity = zeros(app.Data.imageHeight,app.Data.imageWidth);
                    imshow(backgroundIntensity,'Parent',app.UIAxes);
                    hold(app.UIAxes,'on')
                    %                 featureNumber = size(app.Data.fibFeat,1);
                    Xdata = app.UITable.Data.EndPointColumn;
                    Ydata = app.UITable.Data.EndPointRow;
                    scatter(app.UIAxes, Xdata, Ydata,'red','.')
                    title(app.UIAxes,app.fileSelected, 'Interpreter','none')
                    axis(app.UIAxes,'image','equal')
                    
                case 'Box plot'
                    cla(app.UIAxes,'reset')
                    value = app.UITable.Data.(app.featureSelected);
                    boxplot(app.UIAxes,value);
                    app.UIAxes.XTickLabel = app.FeatureListListBox.Value;
                    
                    
                case 'Histogram'
                    % Show histogram slider
                    app.BinNumberSliderLabel.Visible = 'on';
                    app.BinNumberSlider.Visible = 'on';
                    cla(app.UIAxes,'reset')

                    value = app.UITable.Data.(app.featureSelected);
                    histogram(app.UIAxes,value,app.BinNumber)
                    title(app.UIAxes,app.FeatureListListBox.Value)
                    ylabel(app.UIAxes,'Frequency')
                    axis(app.UIAxes,'xy')
 
                    
                case 'Heatmap'
                    app.HeatmapcontrolPanel.Visible = 'on';
                    cla(app.UIAxes,'reset')
                    %                     hold(app.UIAxes,'on')
                    [rawmap, procmap] = CAheatmap(app);
                    %                     save(fullfile(pwd,[app.featureSelected '.mat']),'rawmap','procmap')
                    %                      app.CAvisualization.AutoResizeChildren = 'off';
                    %                     ax1 = subplot(1,2,1,'Parent', app.CAvisualization);
                    %                     ax2 = subplot(1,2,2,'Parent', app.CAvisualization);
                    
                    switch app.Switch2.Value
                        case 'Raw'
                            imagesc(app.UIAxes, rawmap,[app.colorScalingMin,app.colorScalingMax])
                            app.Max_Filter_SizeEditField.Enable = 'off';
                            app.Gaussian_Filter_SizeEditField.Enable = 'off';
                        case 'Filtered'
                            app.Max_Filter_SizeEditField.Enable = 'on';
                            app.Gaussian_Filter_SizeEditField.Enable = 'on';
                            imagesc(app.UIAxes, procmap,[app.colorScalingMin,app.colorScalingMax])
                    end
                    %                     heatmap(app.CAvisualization,rawmap);
                    axis(app.UIAxes,'image', 'equal')
                    title(app.UIAxes,app.FeatureListListBox.Value)
                    % customize the colormap
                    colormapOption = app.colormapSelected;
                    nColors = str2num(app.nColorsInColormap);
                    selectedColormap = colormap(app.UIAxes,colormapOption);
                    customizedColormap = selectedColormap(1:[64/nColors]:end,:,:);
                    colormap(app.UIAxes,customizedColormap)
                    colorbar(app.UIAxes)
                    fprintf('Number of colors is set to %d for %s, each color represents the incremental of %3.2f \n', ...
                        str2num(app.nColorsInColormap), app.featureSelected, (app.colorScalingMax-app.colorScalingMin)/str2num(app.nColorsInColormap));
                    
            end
            
        end

        % Value changing function: BinNumberSlider
        function BinNumberSliderValueChanging(app, event)
            changingValue = event.Value;
            app.BinNumber = floor(changingValue);
        end

        % Value changed function: Max_Filter_SizeEditField
        function Max_Filter_SizeEditFieldValueChanged(app, event)
            value = app.Max_Filter_SizeEditField.Value;
            app.SQUAREmaxfilter_size = value;
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Value changed function: Gaussian_Filter_SizeEditField
        function Gaussian_Filter_SizeEditFieldValueChanged(app, event)
            value = app.Gaussian_Filter_SizeEditField.Value;
            app.GAUSSIANdiscfilter_sigma = value;
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Value changed function: Switch2
        function Switch2ValueChanged(app, event)
            value = app.Switch2.Value;
            switch value
                case 'Raw'
                    app.Max_Filter_SizeEditField.Enable = 'off';
                    app.Gaussian_Filter_SizeEditField.Enable = 'off';
                case 'Filtered'
                    app.Max_Filter_SizeEditField.Enable = 'on';
                    app.Gaussian_Filter_SizeEditField.Enable = 'on';
            end
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Value changed function: ColormapDropDown
        function ColormapDropDownValueChanged(app, event)
            value = app.ColormapDropDown.Value;
            app.colormapSelected = value;
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Callback function: VisualizationTab, nColorsDropDown
        function nColorsDropDownValueChanged(app, event)
            value = app.nColorsDropDown.Value;
            if strcmp(value,'others')
               prompt = {'How many colors will be used in the colormap(2-64)?'};
               name = 'Set number of colors';
               numlines = 1;
               defaultanswer= {'18'};
               options.Resize='on';
               options.WindowStyle='normal';
               options.Interpreter='tex';
               setNumberOfColors = inputdlg(prompt,name,numlines,defaultanswer,options);
               if ~isempty(setNumberOfColors)
                    nColors = str2num(setNumberOfColors{1});
                    if nColors > 64 || nColors < 2
                        fprintf('Number of colors has be between 2 and 64, please re-enter \n')
                        app.nColorsDropDown.Value = app.nColorsInColormap;
                        fprintf('Number of colors is not changed \n');
                    else
                        app.nColorsInColormap = setNumberOfColors{1};
                    end
               else
                   app.nColorsDropDown.Value = app.nColorsInColormap;
                   fprintf('Number of colors is not changed \n');
               end
            else
                app.nColorsInColormap = value;
            end
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Value changed function: colorMinEditField
        function colorMinEditFieldValueChanged(app, event)
            value = app.colorMinEditField.Value;
            fprintf('Entering the color scaling minimum %s \n', num2str(value));
            
            if value > app.colorMaxEditField.Value
                app.colorMinEditField.Value = app.colorScalingMin;
                error('Entering a wrong scaling minimum value %s that is larger than scaling maximum value %s',num2str(value),num2str(app.colorMaxEditField.Value))
            else
                app.colorScalingMin = value;
            end
            
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Value changed function: FeatureListListBox
        function FeatureListListBoxValueChanged(app, event)
            value = app.FeatureListListBox.Value;
            app.featureSelected = strrep(value(4:end),' ',''); % Make the variable name consistent with the table column name;
            app.colorMinEditField.Value = min(app.UITable.Data.(app.featureSelected)(:));
            app.colorMaxEditField.Value = max(app.UITable.Data.(app.featureSelected)(:));
            app.colorScalingMin = app.colorMinEditField.Value;
            app.colorScalingMax = app.colorMaxEditField.Value;
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Value changed function: colorMaxEditField
        function colorMaxEditFieldValueChanged(app, event)
            value = app.colorMaxEditField.Value;
            fprintf('Entering the color scaling maximum %s \n', num2str(value));
            
            if value  < app.colorMinEditField.Value
               app.colorMaxEditField.Value = app.colorScalingMax;
               error('Entering a wrong scaling maximum value %s that is smaller than scaling minum value %s',num2str(value),num2str(app.colorMinEditField.Value))
            else
               app.colorScalingMax = value;
            end
            app.PlottingOptionsButtonGroupSelectionChanged(app);
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            close (findall(0,'Type','figure'));
            CurveAlignVisualization
        end

        % Button pushed function: CloseButton
        function CloseButtonPushed(app, event)
            delete(app)
            disp('CA visualizaiton module is closed')
        end

        % Button pushed function: OpenCurveAlignButton
        function OpenCurveAlignButtonPushed(app, event)
            CurveAlign
            disp('Start CurveAlign from the visualization module')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CAvisualization and hide until all components are created
            app.CAvisualization = uifigure('Visible', 'off');
            app.CAvisualization.IntegerHandle = 'on';
            app.CAvisualization.Position = [100 100 1001 804];
            app.CAvisualization.Name = 'CurveAlign Feature Visualization';
            app.CAvisualization.Tag = 'CA_Visualization';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.CAvisualization);
            app.TabGroup.Position = [36 24 925 748];

            % Create VisualizationTab
            app.VisualizationTab = uitab(app.TabGroup);
            app.VisualizationTab.SizeChangedFcn = createCallbackFcn(app, @nColorsDropDownValueChanged, true);
            app.VisualizationTab.Title = 'Visualization';

            % Create UIAxes
            app.UIAxes = uiaxes(app.VisualizationTab);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            app.UIAxes.XTickLabelRotation = 0;
            app.UIAxes.YTickLabelRotation = 0;
            app.UIAxes.ZTickLabelRotation = 0;
            app.UIAxes.Position = [312 212 525 494];

            % Create Panel
            app.Panel = uipanel(app.VisualizationTab);
            app.Panel.Position = [7 549 228 139];

            % Create OpenFeatureFileButton
            app.OpenFeatureFileButton = uibutton(app.Panel, 'push');
            app.OpenFeatureFileButton.ButtonPushedFcn = createCallbackFcn(app, @OpenFeatureFileButtonPushed, true);
            app.OpenFeatureFileButton.Position = [10 108 112 22];
            app.OpenFeatureFileButton.Text = 'Open Feature File';

            % Create FileListListBoxLabel
            app.FileListListBoxLabel = uilabel(app.Panel);
            app.FileListListBoxLabel.HorizontalAlignment = 'right';
            app.FileListListBoxLabel.Position = [5 75 44 22];
            app.FileListListBoxLabel.Text = 'FileList';

            % Create FileListListBox
            app.FileListListBox = uilistbox(app.Panel);
            app.FileListListBox.Items = {'*Features.mat'};
            app.FileListListBox.Position = [5 2 203 74];
            app.FileListListBox.Value = '*Features.mat';

            % Create FeatureListListBoxLabel
            app.FeatureListListBoxLabel = uilabel(app.VisualizationTab);
            app.FeatureListListBoxLabel.HorizontalAlignment = 'right';
            app.FeatureListListBoxLabel.Position = [9 495 66 22];
            app.FeatureListListBoxLabel.Text = 'FeatureList';

            % Create FeatureListListBox
            app.FeatureListListBox = uilistbox(app.VisualizationTab);
            app.FeatureListListBox.Items = {'01-FiberKeyToCTFIRE', '02-End Point Row', '03-End Point Column', '04-Fiber Absolute Angle', '05-Fiber Weight', '06-Total Length', '07-End2End Length', '08-Curvature', '09-Width', '...', '', ''};
            app.FeatureListListBox.ValueChangedFcn = createCallbackFcn(app, @FeatureListListBoxValueChanged, true);
            app.FeatureListListBox.Position = [12 351 218 139];
            app.FeatureListListBox.Value = '04-Fiber Absolute Angle';

            % Create PlottingOptionsButtonGroup
            app.PlottingOptionsButtonGroup = uibuttongroup(app.VisualizationTab);
            app.PlottingOptionsButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @PlottingOptionsButtonGroupSelectionChanged, true);
            app.PlottingOptionsButtonGroup.Title = 'Plotting Options';
            app.PlottingOptionsButtonGroup.Position = [11 212 218 127];

            % Create LocationButton
            app.LocationButton = uiradiobutton(app.PlottingOptionsButtonGroup);
            app.LocationButton.Text = 'Location';
            app.LocationButton.Position = [11 81 67 22];
            app.LocationButton.Value = true;

            % Create BoxplotButton
            app.BoxplotButton = uiradiobutton(app.PlottingOptionsButtonGroup);
            app.BoxplotButton.Text = 'Box plot';
            app.BoxplotButton.Position = [11 59 65 22];

            % Create HistogramButton
            app.HistogramButton = uiradiobutton(app.PlottingOptionsButtonGroup);
            app.HistogramButton.Text = 'Histogram';
            app.HistogramButton.Position = [11 37 77 22];

            % Create HeatmapButton
            app.HeatmapButton = uiradiobutton(app.PlottingOptionsButtonGroup);
            app.HeatmapButton.Text = 'Heatmap';
            app.HeatmapButton.Position = [11 8 71 22];

            % Create BinNumberSliderLabel
            app.BinNumberSliderLabel = uilabel(app.VisualizationTab);
            app.BinNumberSliderLabel.HorizontalAlignment = 'right';
            app.BinNumberSliderLabel.Position = [11 124 66 22];
            app.BinNumberSliderLabel.Text = 'BinNumber';

            % Create BinNumberSlider
            app.BinNumberSlider = uislider(app.VisualizationTab);
            app.BinNumberSlider.Limits = [0 50];
            app.BinNumberSlider.ValueChangedFcn = createCallbackFcn(app, @PlottingOptionsButtonGroupSelectionChanged, true);
            app.BinNumberSlider.ValueChangingFcn = createCallbackFcn(app, @BinNumberSliderValueChanging, true);
            app.BinNumberSlider.Position = [98 143 150 3];
            app.BinNumberSlider.Value = 10;

            % Create HeatmapcontrolPanel
            app.HeatmapcontrolPanel = uipanel(app.VisualizationTab);
            app.HeatmapcontrolPanel.Title = 'Heatmap control';
            app.HeatmapcontrolPanel.SizeChangedFcn = createCallbackFcn(app, @PlottingOptionsButtonGroupSelectionChanged, true);
            app.HeatmapcontrolPanel.Position = [331 70 505 125];

            % Create Switch2
            app.Switch2 = uiswitch(app.HeatmapcontrolPanel, 'slider');
            app.Switch2.Items = {'Raw', 'Filtered'};
            app.Switch2.ValueChangedFcn = createCallbackFcn(app, @Switch2ValueChanged, true);
            app.Switch2.Position = [48 57 45 20];
            app.Switch2.Value = 'Filtered';

            % Create Max_Filter_SizeEditFieldLabel
            app.Max_Filter_SizeEditFieldLabel = uilabel(app.HeatmapcontrolPanel);
            app.Max_Filter_SizeEditFieldLabel.HorizontalAlignment = 'right';
            app.Max_Filter_SizeEditFieldLabel.Position = [162 65 99 22];
            app.Max_Filter_SizeEditFieldLabel.Text = 'Max_Filter_Size';

            % Create Max_Filter_SizeEditField
            app.Max_Filter_SizeEditField = uieditfield(app.HeatmapcontrolPanel, 'numeric');
            app.Max_Filter_SizeEditField.ValueChangedFcn = createCallbackFcn(app, @Max_Filter_SizeEditFieldValueChanged, true);
            app.Max_Filter_SizeEditField.Position = [278 65 36 22];
            app.Max_Filter_SizeEditField.Value = 12;

            % Create Gaussian_Filter_SizeEditFieldLabel
            app.Gaussian_Filter_SizeEditFieldLabel = uilabel(app.HeatmapcontrolPanel);
            app.Gaussian_Filter_SizeEditFieldLabel.HorizontalAlignment = 'right';
            app.Gaussian_Filter_SizeEditFieldLabel.Position = [325 65 126 22];
            app.Gaussian_Filter_SizeEditFieldLabel.Text = 'Gaussian_Filter_Size';

            % Create Gaussian_Filter_SizeEditField
            app.Gaussian_Filter_SizeEditField = uieditfield(app.HeatmapcontrolPanel, 'numeric');
            app.Gaussian_Filter_SizeEditField.ValueChangedFcn = createCallbackFcn(app, @Gaussian_Filter_SizeEditFieldValueChanged, true);
            app.Gaussian_Filter_SizeEditField.Position = [458 65 35 22];
            app.Gaussian_Filter_SizeEditField.Value = 0.1;

            % Create ColormapDropDownLabel
            app.ColormapDropDownLabel = uilabel(app.HeatmapcontrolPanel);
            app.ColormapDropDownLabel.HorizontalAlignment = 'right';
            app.ColormapDropDownLabel.Position = [8 11 58 22];
            app.ColormapDropDownLabel.Text = 'Colormap';

            % Create ColormapDropDown
            app.ColormapDropDown = uidropdown(app.HeatmapcontrolPanel);
            app.ColormapDropDown.Items = {'jet', 'gray', 'hsv', 'cool', 'summer', 'copper'};
            app.ColormapDropDown.ValueChangedFcn = createCallbackFcn(app, @ColormapDropDownValueChanged, true);
            app.ColormapDropDown.Position = [81 11 68 22];
            app.ColormapDropDown.Value = 'jet';

            % Create nColorsDropDownLabel
            app.nColorsDropDownLabel = uilabel(app.HeatmapcontrolPanel);
            app.nColorsDropDownLabel.HorizontalAlignment = 'right';
            app.nColorsDropDownLabel.Position = [171 11 47 22];
            app.nColorsDropDownLabel.Text = 'nColors';

            % Create nColorsDropDown
            app.nColorsDropDown = uidropdown(app.HeatmapcontrolPanel);
            app.nColorsDropDown.Items = {'2', '4', '8', '16', '32', '64', 'others'};
            app.nColorsDropDown.ValueChangedFcn = createCallbackFcn(app, @nColorsDropDownValueChanged, true);
            app.nColorsDropDown.Position = [233 11 81 22];
            app.nColorsDropDown.Value = '64';

            % Create colorMinEditFieldLabel
            app.colorMinEditFieldLabel = uilabel(app.HeatmapcontrolPanel);
            app.colorMinEditFieldLabel.HorizontalAlignment = 'right';
            app.colorMinEditFieldLabel.Position = [351 36 51 22];
            app.colorMinEditFieldLabel.Text = 'colorMin';

            % Create colorMinEditField
            app.colorMinEditField = uieditfield(app.HeatmapcontrolPanel, 'numeric');
            app.colorMinEditField.ValueChangedFcn = createCallbackFcn(app, @colorMinEditFieldValueChanged, true);
            app.colorMinEditField.Position = [351 11 52 22];

            % Create colorMaxEditFieldLabel
            app.colorMaxEditFieldLabel = uilabel(app.HeatmapcontrolPanel);
            app.colorMaxEditFieldLabel.HorizontalAlignment = 'right';
            app.colorMaxEditFieldLabel.Position = [429 36 54 22];
            app.colorMaxEditFieldLabel.Text = 'colorMax';

            % Create colorMaxEditField
            app.colorMaxEditField = uieditfield(app.HeatmapcontrolPanel, 'numeric');
            app.colorMaxEditField.ValueChangedFcn = createCallbackFcn(app, @colorMaxEditFieldValueChanged, true);
            app.colorMaxEditField.Position = [429 11 54 22];
            app.colorMaxEditField.Value = 180;

            % Create ResetButton
            app.ResetButton = uibutton(app.VisualizationTab, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [147 657 82 22];
            app.ResetButton.Text = 'Reset';

            % Create Panel_2
            app.Panel_2 = uipanel(app.VisualizationTab);
            app.Panel_2.BorderType = 'none';
            app.Panel_2.Position = [557 1 365 55];

            % Create OpenCurveAlignButton
            app.OpenCurveAlignButton = uibutton(app.Panel_2, 'push');
            app.OpenCurveAlignButton.ButtonPushedFcn = createCallbackFcn(app, @OpenCurveAlignButtonPushed, true);
            app.OpenCurveAlignButton.Position = [28 10 152 37];
            app.OpenCurveAlignButton.Text = 'Open CurveAlign';

            % Create CloseButton
            app.CloseButton = uibutton(app.Panel_2, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [192 10 156 37];
            app.CloseButton.Text = 'Close';

            % Create FeatureValuesTab
            app.FeatureValuesTab = uitab(app.TabGroup);
            app.FeatureValuesTab.Title = 'FeatureValues';

            % Create UITable
            app.UITable = uitable(app.FeatureValuesTab);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [50 250 692 447];

            % Create OriginalimageTab
            app.OriginalimageTab = uitab(app.TabGroup);
            app.OriginalimageTab.Title = 'Originalimage';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.OriginalimageTab);
            title(app.UIAxes2, 'Original Image Name')
            app.UIAxes2.XTickLabelRotation = 0;
            app.UIAxes2.YTickLabelRotation = 0;
            app.UIAxes2.ZTickLabelRotation = 0;
            app.UIAxes2.Position = [218 190 509 494];

            % Create OverlayImageTab
            app.OverlayImageTab = uitab(app.TabGroup);
            app.OverlayImageTab.Title = 'OverlayImage';

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.OverlayImageTab);
            title(app.UIAxes3, 'Overlay Image Name')
            app.UIAxes3.XTickLabelRotation = 0;
            app.UIAxes3.YTickLabelRotation = 0;
            app.UIAxes3.ZTickLabelRotation = 0;
            app.UIAxes3.Position = [207 164 536 508];

            % Show the figure after all components are created
            app.CAvisualization.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CurveAlignVisualization_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.CAvisualization)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.CAvisualization)
        end
    end
end