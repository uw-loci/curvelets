classdef cellanalysisObjectMeasurement_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ObjectmeasurementsUIFigure  matlab.ui.Figure
        StatisticalPlotsButton      matlab.ui.control.Button
        SaveButton                  matlab.ui.control.Button
        CloseButton                 matlab.ui.control.Button
        UITable                     matlab.ui.control.Table
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        objectMeasurement   % structure to show the objectmeasurement;  
        selectedCell % cell to show visualization
        BinNumber % number of bins for histogram, default 10
        CellBin % number of bins for both histogram, cell
        FiberBin % number of bins for both histogram, fiber
        UIAxes % axes for figures
        CellAxes % axes for cell
        FiberAxes % axes for fiber
        ParameterVisAPP % parameter setter for statistical plot
        PlotType % type of statistical plot
        MeasurementType % type of measurement value
        ObjectType % type of object type
        Vis_Title % title for visualization
        X_Title % x-axis title for visualization
        Y_Title % y-axis title for visualization
        FiberColor % fiber color for visualization
        CellColor % cell color for visualization
    end
    
    methods (Access = private)
        
        function sliderOneValueChangedFcn(app, src, event)
            if round(event.Value) == 0
                % edge case where bin number is 0 -- auto set to 1
                app.BinNumber = 1;
            else
                app.BinNumber = round(event.Value);
            end
            histogramOneFcn(app, event);
        end

        %{
        function sliderCellValueChangedFcn(app, src, event)
            if round(event.Value) == 0
                % edge case where bin number is 0 -- auto set to 1
                app.CellBin = 1;
            else
                app.CellBin = round(event.Value);
            end
            histogramBothFcn(app, event);
        end

        function sliderFiberValueChangedFcn(app, src, event)
            if round(event.Value) == 0
                % edge case where bin number is 0 -- auto set to 1
                app.FiberBin = 1;
            else
                app.FiberBin = round(event.Value);
            end
            histogramBothFcn(app, event);
        end

        function closeScriptFcn(app, src, event)
            app.BinNumber = -1;
            app.FiberBin = -1;
            app.CellBin = -1;
        end
        %}

        function closeOneScriptFcn(app, src, event)
            app.BinNumber = -1;
        end

        function closeBothScriptFcn(app, src, event)
            app.FiberBin = -1;
            app.CellBin = -1;
        end
        
        function boxplotCreateFcn(app, src, event)

            columnData = app.UITable.ColumnName;
            tableData = app.UITable.Data;
            
            % find index of measurement
            for i = 1:size(columnData)
                if strcmp(columnData{i, 1}, app.MeasurementType)
                    index = i;
                    break;
                end
            end
            
            % find cell
            cellSelected = app.CallingApp.objectsView.Selection;
            cellNumber = length(cellSelected);
            cellData = cell(cellNumber, 1);

            for i = 1:cellNumber
                cellPart = tableData{i, index};
                if ischar(cellPart)
                    if cellPart < 0
                        cellPart = 180 + cellPart;
                    end
                    cellData{i, 1} = str2double(cellPart);
                else
                    cellData{i, 1} = cellPart;
                end
            end
            
            % find fiber 
            fibersSelected = app.CallingApp.fibersView.Selection;
            fiberNumber = length(fibersSelected);
            fiberData = cell(fiberNumber, 1);
            
            j = 0;
            while j < fiberNumber
                    j = j+1;
                    fiberPart = tableData{j + cellNumber, index};
                    if ischar(fiberPart)
                        fiberData{j, 1} = str2double(fiberPart);
                    else
                        fiberData{j, 1} = fiberPart;
                    end
            end

            % configuring figure

            fig_title = sprintf("Boxplot of %s of %s", app.MeasurementType,...
                app.ObjectType);
            fig_width = 750;
            fig_height = 500;
            screen_size = get(0, 'ScreenSize');
            fig_left = (screen_size(3) - fig_width) / 2;
            fig_bottom = (screen_size(4) - fig_height) / 2;
            position = [fig_left, fig_bottom, fig_width, fig_height];
            figure = uifigure('Name', fig_title, ...
                    "WindowStyle", "normal", ...
                    "Position", position);
            app.UIAxes = axes(figure);

            cellData = cell2mat(cellData);
            fiberData = cell2mat(fiberData);

            groupCell = repmat({'Cell'}, length(cellData), 1);
            groupFiber = repmat({'Fiber'}, length(fiberData), 1);

            if strcmp(app.ObjectType, "Cell")
                box = boxplot(app.UIAxes, cellData, 'Labels', groupCell, ...
                    "BoxStyle", "outline", ...
                    "Colors", app.CellColor);
            elseif strcmp(app.ObjectType, "Fiber")
                box = boxplot(app.UIAxes, fiberData, groupFiber, ...
                    "BoxStyle", "outline", ...
                    "Colors", app.FiberColor);
            else
                box = boxplot(app.UIAxes, [cellData; fiberData], [groupCell; groupFiber], ...
                    "BoxStyle", "outline", ...
                    "Colors", [app.CellColor; app.FiberColor])
                h = findobj(gca, "Tag", "Box");
                for j = 1:length(h)
                    patch(get(h(j), 'XData'), ...
                        get(h(j), 'YData'), ...
                        get(h(j), 'Color'), ...
                        'FaceAlpha', .5);
                end
            end

            xlabel(app.UIAxes, app.X_Title);
            ylabel(app.UIAxes, app.Y_Title);
            title(app.UIAxes, app.Vis_Title);
        end

        function violinplotCreateFcn(app, src, event)

            columnData = app.UITable.ColumnName;
            tableData = app.UITable.Data;
            
            % find index of measurement
            for i = 1:size(columnData)
                if strcmp(columnData{i, 1}, app.MeasurementType)
                    index = i;
                    break;
                end
            end
            
            % find cell
            cellSelected = app.CallingApp.objectsView.Selection;
            cellNumber = length(cellSelected);
            cellData = cell(cellNumber, 1);

            for i = 1:cellNumber
                cellPart = tableData{i, index};
                if ischar(cellPart)
                    if cellPart < 0
                        cellPart = 180 + cellPart;
                    end
                    cellData{i, 1} = str2double(cellPart);
                else
                    cellData{i, 1} = cellPart;
                end
            end
            
            % find fiber 
            fibersSelected = app.CallingApp.fibersView.Selection;
            fiberNumber = length(fibersSelected);
            fiberData = cell(fiberNumber, 1);
            
            j = 0;
            while j < fiberNumber
                    j = j+1;
                    fiberPart = tableData{j + cellNumber, index};
                    if ischar(fiberPart)
                        fiberData{j, 1} = str2double(fiberPart);
                    else
                        fiberData{j, 1} = fiberPart;
                    end
            end

            % configuring figure
            fig_title = sprintf("Violinplot of %s of %s", app.MeasurementType,...
                app.ObjectType);

            cellData = cell2mat(cellData);
            fiberData = cell2mat(fiberData);

            fig = figure('NumberTitle', 'Off', 'Name', fig_title);
            groupCell = repmat({'Cell'}, length(cellData), 1);
            groupFiber = repmat({'Fiber'}, length(fiberData), 1);

            if strcmp(app.ObjectType, "Cell")
                vs = violinplot(cellData, groupCell, 'ViolinColor', app.CellColor);
            elseif strcmp(app.ObjectType, "Fiber")
                vs = violinplot(fiberData, groupFiber, 'ViolinColor', app.FiberColor);
            else
                vs = violinplot([cellData; fiberData], [groupCell; groupFiber], ...
                    'ViolinColor', [app.CellColor; app.FiberColor]);
                    
            end
            xlabel(app.X_Title);
            ylabel(app.Y_Title);
            title(app.Vis_Title);
        end
       

        function histogramOneFcn(app, src, event)
            % find selected cell
            %{
            if app.selectedCell(1,1) == 0
                index = 7;
            else
                index = app.selectedCell(1,2);
            end

            temp_coi = app.UITable.ColumnName(index);
            coi = temp_coi{1};
            tableData = app.UITable.Data;
            
            if index >=5 && index <= 9 
                % find cell orientations
                cellSelected = app.CallingApp.objectsView.Selection;
                cellSelectedNumber = length(cellSelected) + 1;
                cellNumber = cellSelectedNumber;
                cellData = cell(cellNumber, 1);
                for i = 1:cellNumber
                    cellPart = tableData{i, index};
                    if ischar(cellPart)
                        if cellPart < 0
                            cellPart = 180 + cellPart;
                        end
                        cellData{i, 1} = str2double(cellPart);
                    else
                        cellData{i, 1} = cellPart;
                    end

                end
                
                % find fiber orientations
                fibersSelected = app.CallingApp.fibersView.Selection;
                fibersSelectedNumber = length(fibersSelected) - 1;
                fiberNumber = fibersSelectedNumber;
                fiberData = cell(fiberNumber, 1);
                
                j = 0;
                while j < fiberNumber
                        j = j+1;
                        fiberPart = tableData{j + cellNumber, index};
                        if ischar(fiberPart)
                            fiberData{j, 1} = str2double(fiberPart);
                        else
                            fiberData{j, 1} = fiberPart;
                        end
                end
            %}

            columnData = app.UITable.ColumnName;
            tableData = app.UITable.Data;
            
            % find index of measurement
            for i = 1:size(columnData)
                if strcmp(columnData{i, 1}, app.MeasurementType)
                    index = i;
                    break;
                end
            end
            
            % find cell
            cellSelected = app.CallingApp.objectsView.Selection;
            cellNumber = length(cellSelected);
            cellData = cell(cellNumber, 1);

            for i = 1:cellNumber
                cellPart = tableData{i, index};
                if ischar(cellPart)
                    if cellPart < 0
                        cellPart = 180 + cellPart;
                    end
                    cellData{i, 1} = str2double(cellPart);
                else
                    cellData{i, 1} = cellPart;
                end
            end
            
            % find fiber 
            fibersSelected = app.CallingApp.fibersView.Selection;
            fiberNumber = length(fibersSelected);
            fiberData = cell(fiberNumber, 1);
            
            j = 0;
            while j < fiberNumber
                    j = j+1;
                    fiberPart = tableData{j + cellNumber, index};
                    if ischar(fiberPart)
                        fiberData{j, 1} = str2double(fiberPart);
                    else
                        fiberData{j, 1} = fiberPart;
                    end
            end
                
            % create histogram with fiber and cell orientations overlapping
            if isempty(app.BinNumber) || app.BinNumber < 0
                app.BinNumber = 25;

                screen_size = get(0, 'ScreenSize');
              
                % configuring figure
                fig_title = sprintf('Histogram of %s of %s', ...
                    app.MeasurementType, app.ObjectType);
                fig_width = 750;
                fig_height = 500;
                fig_left = (screen_size(3) - fig_width) / 2;
                fig_bottom = (screen_size(4) - fig_height) / 2;
                position = [fig_left, fig_bottom, fig_width, fig_height];

                figure = uifigure('Name', fig_title, ...
                    "WindowStyle", "normal", ...
                    "Position", position);
                slider = uislider(figure, ...
                    "Orientation", "vertical", ...
                    "Value", 25, ...
                    "Position", [20, 150, 3, 200], ...
                    "Limits", [0, 50], ...
                    "ValueChangedFcn",@(src,event)sliderOneValueChangedFcn(app,src,event));
                app.UIAxes = axes(figure);
                addlistener(app.UIAxes, 'ObjectBeingDestroyed', ...
                    @(src,event)closeOneScriptFcn(app,src,event));
            end

            cellData = cell2mat(cellData);
            fiberData = cell2mat(fiberData);

            % checking object type for visualization
            if strcmp(app.ObjectType, "Cell")
                minData = min(cellData);
                maxData = max(cellData);
            else
                minData = min(fiberData);
                maxData = max(fiberData);
            end
            
            % configuring histograms
            if index == 7
                edges = linspace(0, 180, app.BinNumber + 1);
            else
                edges = linspace(minData, maxData, app.BinNumber + 1);
            end
            
            cla(app.UIAxes, 'reset');
            app.UIAxes.Position = [0.20, 0.15, 0.7, 0.75];
            if strcmp(app.ObjectType, "Cell")
                cellHist = histogram(app.UIAxes, cellData, edges, 'facealpha', 0.5, ...
                    'FaceColor', app.CellColor); 
            elseif strcmp(app.ObjectType, "Fiber")
                fiberHist = histogram(app.UIAxes, fiberData, edges, 'facealpha', 0.5, ...
                    'FaceColor', app.FiberColor);
            else
                cellHist = histogram(app.UIAxes, cellData, edges, 'facealpha', 0.5, ...
                    'FaceColor', app.CellColor); 
                hold(app.UIAxes, 'on');
                fiberHist = histogram(app.UIAxes, fiberData, edges, 'facealpha', 0.5, ...
                    'FaceColor', app.FiberColor);
                legend(app.UIAxes, {'Cell', 'Fiber'});
            end
            title(app.UIAxes, app.Vis_Title);
            xlabel(app.UIAxes, app.X_Title);
            ylabel(app.UIAxes, app.Y_Title);
        end

        function histogramBothFcn(app, src, event)

            columnData = app.UITable.ColumnName;
            tableData = app.UITable.Data;
            
            % find index of measurement
            for i = 1:size(columnData)
                if strcmp(columnData{i, 1}, app.MeasurementType)
                    index = i;
                    break;
                end
            end
            
            % find cell
            cellSelected = app.CallingApp.objectsView.Selection;
            cellNumber = length(cellSelected);
            cellData = cell(cellNumber, 1);

            for i = 1:cellNumber
                cellPart = tableData{i, index};
                if ischar(cellPart)
                    if cellPart < 0
                        cellPart = 180 + cellPart;
                    end
                    cellData{i, 1} = str2double(cellPart);
                else
                    cellData{i, 1} = cellPart;
                end
            end
            
            % find fiber 
            fibersSelected = app.CallingApp.fibersView.Selection;
            fiberNumber = length(fibersSelected);
            fiberData = cell(fiberNumber, 1);
            
            j = 0;
            while j < fiberNumber
                    j = j+1;
                    fiberPart = tableData{j + cellNumber, index};
                    if ischar(fiberPart)
                        fiberData{j, 1} = str2double(fiberPart);
                    else
                        fiberData{j, 1} = fiberPart;
                    end
            end
                
            % create histogram with fiber and cell orientations overlapping
            if (isempty(app.CellBin) || isempty(app.FiberBin) ...
                    || app.CellBin < 0 || app.FiberBin < 0)
                app.CellBin = 25;
                app.FiberBin = 25;

                screen_size = get(0, 'ScreenSize');
              
                % configuring figure
                fig_title = sprintf('Histogram of %s of %s', ...
                    app.MeasurementType, app.ObjectType);
                fig_width = 1500;
                fig_height = 480;
                fig_left = (screen_size(3) - fig_width) / 2;
                fig_bottom = (screen_size(4) - fig_height) / 2;
                position = [fig_left, fig_bottom, fig_width, fig_height];

                figure = uifigure('Name', fig_title, ...
                    "WindowStyle", "normal", ...
                    "Position", position);
                cellSlider = uislider(figure, ...
                    "Orientation", "vertical", ...
                    "Value", 25, ...
                    "Position", [50, 50, 20, 250], ...
                    "Limits", [1, 50]);
                fiberSlider = uislider(figure, ...
                    "Orientation", "vertical", ...
                    "Value", 25, ...
                    "Position", [800, 50, 20, 250], ...
                    "Limits", [1, 50]);

                app.CellAxes = uiaxes(figure, 'Position', [100, 20, 600, 400]);
                app.FiberAxes = uiaxes(figure, 'Position', [850, 20, 600, 400]);
                addlistener(app.CellAxes, 'ObjectBeingDestroyed', ...
                    @(src,event)closeBothScriptFcn(app,src,event));
                addlistener(app.FiberAxes, 'ObjectBeingDestroyed', ...
                    @(src,event)closeBothScriptFcn(app,src,event));
            end

            cellData = cell2mat(cellData);
            fiberData = cell2mat(fiberData);

            minCellData = min(cellData);
            maxCellData = max(cellData);
            minFiberData = min(fiberData);
            maxFiberData = max(fiberData);

            if index == 7
                fiberEdges = linspace(0, 180, app.FiberBin + 1);
                cellEdges = linspace(0, 180, app.CellBin + 1);
            else
                fiberEdges = linspace(minFiberData, maxFiberData, app.FiberBin + 1);
                cellEdges = linspace(minCellData, maxCellData, app.CellBin + 1);
            end

            cellHist = histogram(app.CellAxes, cellData, cellEdges, 'facealpha', 0.5, ...
                'FaceColor', app.CellColor); 
            fiberHist = histogram(app.FiberAxes, fiberData, fiberEdges, 'facealpha', 0.5, ...
                'FaceColor', app.FiberColor);

            cellTitle = sprintf("Histogram of Cell %s", app.Vis_Title);
            fiberTitle = sprintf("Histogram of Fiber %s", app.Vis_Title);

            title(app.CellAxes, cellTitle);
            xlabel(app.CellAxes, app.X_Title);
            ylabel(app.CellAxes, app.Y_Title);

            title(app.FiberAxes, fiberTitle);
            xlabel(app.FiberAxes, app.X_Title);
            ylabel(app.FiberAxes, app.Y_Title);

            cellSlider.ValueChangedFcn = @(src,event)updateHistogram(app, ...
                app.CellAxes, cellData, cellSlider.Value, cellHist, app.CellColor);
            fiberSlider.ValueChangedFcn = @(src,event)updateHistogram(app, ...
                app.FiberAxes, fiberData, fiberSlider.Value, fiberHist, app.FiberColor);

        end

        function updateHistogram(app, ax, data, binCount, histHandle, faceColor)
            histogram(ax, data, 'NumBins', round(binCount), 'FaceColor', faceColor);
        end
    end
    
    methods (Access = public)
        
        function boxplotStartFcn(app, src, event)
            boxplotCreateFcn(app, event);
        end

        function violinplotStartFcn(app, src, event)
            violinplotCreateFcn(app, event);
        end

        function histogramStartOneFcn(app, src, event)
            histogramOneFcn(app, event);
        end

        function histogramStartBothFcn(app, src, event)
            histogramBothFcn(app, event);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            app.CallingApp = mainAPP;
            app.UITable.ColumnName = {'Image','Name','Class','Parent','Center-X','Center-Y','Orientation','Area','Circularity','ShapeMode','Perimeter'};         
            measurementName = {'position','orientation','area','circularity', 'shapemode'};
            imageName = mainAPP.imageName;
%             objectNumber = size(mainAPP.CAPobjects.cells.cellArray,2);
            cellSelected = mainAPP.objectsView.Selection;
            cellSelectedNumber = length(cellSelected);
            objectNumber = cellSelectedNumber;
            if strcmp(mainAPP.annotationView.Selection,'') && mainAPP.CAPannotations.cellDetectionFlag == 0
                annotationName = 'Tumor-annotation';
                objectNumber = size(mainAPP.CAPobjects.cells.cellArray,2);
            elseif ~strcmp(mainAPP.annotationView.Selection,'') && mainAPP.CAPannotations.cellDetectionFlag == 0
                annotationName = 'Tumor-annotation';
                objectNumber = 0;
                app.UITable.Data = '';
                return;
            else
                annotationSelected = mainAPP.annotationView.Selection;   %cell selection from the GUI
                annotationName = mainAPP.annotationView.Name{annotationSelected};
            end
            measurementsNumber = size(measurementName,2)+1+4;
            tableData = cell(objectNumber,measurementsNumber);  
            
            for i = 1:objectNumber
                if strcmp(mainAPP.annotationView.Selection,'')
                    iS = i;
                else
                    iS = cellSelected(i);  % object on the list
                end
                if strcmp(mainAPP.CAPimage.CellanalysisMethod,'StarDist') || strcmp(mainAPP.CAPimage.CellanalysisMethod,'FromMaskfiles-SD') 
                    tableData{i,1} = imageName;
                    tableData{i,2} = sprintf('cell%d',iS);
                    tableData{i,3} = 'Cell';
                    tableData{i,4} = annotationName;%'TumorAnnotation';
                    tableData{i,5} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).position(2));
                    tableData{i,6} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).position(1));
                    cellOrientation = mainAPP.CAPobjects.cells.cellArray(1,iS).orientation;
                    if cellOrientation < 0
                        cellOrientation = 180 + cellOrientation;
                    end
                    tableData{i,7} = sprintf('%3.1f',cellOrientation);
                    tableData{i,8} = mainAPP.CAPobjects.cells.cellArray(1,iS).area;
                    tableData{i,9} = mainAPP.CAPobjects.cells.cellArray(1,iS).circularity;
                    tableData{i,10} = mainAPP.CAPobjects.cells.cellArray(1,iS).vampireShapeMode;
                else %cellpose and deepcell
                    tableData{i,1} = imageName;
                    tableData{i,2} = sprintf('cell%d',iS);
                    tableData{i,3} = 'cell';
                    tableData{i,4} = annotationName; %'TumorAnnotation';
                    tableData{i,5} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).Position(1));
                    tableData{i,6} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).Position(2));
                    cellOrientation = mainAPP.CAPobjects.cells.cellArray(1,iS).Orientation;
                    if cellOrientation < 0
                        cellOrientation = 180 + cellOrientation;
                    end
                    tableData{i,7} = sprintf('%3.1f',cellOrientation);
                    tableData{i,8} = mainAPP.CAPobjects.cells.cellArray(1,iS).Area;
                    tableData{i,9} = mainAPP.CAPobjects.cells.cellArray(1,iS).Circularity;
                    tableData{i,10} = '';
                end
            end
            
            
            % add fiber info
            fibersSelected = mainAPP.fibersView.Selection;
            fibersSelectedNumber = length(fibersSelected);
            fiberNumber = fibersSelectedNumber;
            
            if fiberNumber > 0
                j = 0;
                for ii = i+1: i+fiberNumber
                    j = j + 1;
                    iS = fibersSelected(j);
                    fiberOrientation = mainAPP.fibersView.orientation{iS};
                    centerX = mainAPP.fibersView.centerX{iS};
                    centerY = mainAPP.fibersView.centerY{iS};
                    tableData{ii,1} = imageName;
                    tableData{ii,2} = sprintf('fiber%d',iS);
                    tableData{ii,3} = 'fiber';
                    tableData{ii,4} = annotationName;%'
                    tableData{ii,5} = centerX;
                    tableData{ii,6} = centerY;
                    tableData{ii,7} = sprintf('%3.1f',fiberOrientation);
                end

            end    
            app.selectedCell = 0;
            app.UITable.Data = tableData;
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            app.selectedCell = event.Indices;
        end

        % Button pushed function: StatisticalPlotsButton
        function StatisticalPlotsButtonPushed(app, event)
            app.ParameterVisAPP = statisticalPlotVis(app);
        end

        % Button pushed function: CloseButton
        function CloseButtonPushed(app, event)
            app.delete
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            % find existing measurements file
            [~,imageNameNOE] = fileparts(app.CallingApp.imageName);
            OBJoutputName_temp = sprintf('%s_objectsMeasurement*.xlsx',imageNameNOE);
            if ~isempty(app.CallingApp.fiberdataPath)
               OBJoutputPath = app.CallingApp.fiberdataPath;
            else
                CAoutputFolder = fullfile(app.CallingApp.imagePath,'CA_Out');
                if ~exist(CAoutputFolder,'dir')
                    mkdir(CAoutputFolder);
                end
                OBJoutputPath = CAoutputFolder;
            end
            nOutputfiles = length(dir(fullfile(OBJoutputPath,OBJoutputName_temp)));
            OBJoutputName = sprintf('%s_objectsMeasurement%d.xlsx',imageNameNOE,nOutputfiles+1);
            writecell(app.UITable.ColumnName',fullfile(OBJoutputPath,OBJoutputName),'Sheet','ObjectMeasurements','Range','A1');
            writecell(app.UITable.Data,fullfile(OBJoutputPath,OBJoutputName),'Sheet','ObjectMeasurements','Range','A2');
            fprintf('Objects measurement is saved to %s \n',fullfile(OBJoutputPath,OBJoutputName));

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ObjectmeasurementsUIFigure and hide until all components are created
            app.ObjectmeasurementsUIFigure = uifigure('Visible', 'off');
            app.ObjectmeasurementsUIFigure.Position = [100 100 847 416];
            app.ObjectmeasurementsUIFigure.Name = 'Object measurements';
            app.ObjectmeasurementsUIFigure.Scrollable = 'on';

            % Create UITable
            app.UITable = uitable(app.ObjectmeasurementsUIFigure);
            app.UITable.ColumnName = {'Image'; 'Name'; 'Class'; 'Parent'; 'Center-X'; 'Center-Y'; 'Orientation'; 'Area'; 'Circularity'; 'ShapeMode'; 'Perimeter'};
            app.UITable.RowName = {};
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Position = [29 71 791 309];

            % Create CloseButton
            app.CloseButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [559 23 126 22];
            app.CloseButton.Text = 'Close';

            % Create SaveButton
            app.SaveButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [700 23 120 22];
            app.SaveButton.Text = 'Save';

            % Create StatisticalPlotsButton
            app.StatisticalPlotsButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.StatisticalPlotsButton.ButtonPushedFcn = createCallbackFcn(app, @StatisticalPlotsButtonPushed, true);
            app.StatisticalPlotsButton.Position = [29 23 126 23];
            app.StatisticalPlotsButton.Text = 'Statistical Plots';

            % Show the figure after all components are created
            app.ObjectmeasurementsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = cellanalysisObjectMeasurement_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ObjectmeasurementsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ObjectmeasurementsUIFigure)
        end
    end
end