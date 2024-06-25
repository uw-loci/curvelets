classdef cellanalysisObjectMeasurement_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ObjectmeasurementsUIFigure  matlab.ui.Figure
        BoxplotsButton              matlab.ui.control.Button
        ViolinplotsButton           matlab.ui.control.Button
        SaveButton                  matlab.ui.control.Button
        CloseButton                 matlab.ui.control.Button
        HistogramsButton            matlab.ui.control.Button
        UITable                     matlab.ui.control.Table
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        objectMeasurement   % structure to show the objectmeasurement;  
        selectedCell % cell to show visualization
        BinNumber % number of bins for histogram, default 10
        UIAxes % axes for figures
        ParameterVisAPP % parameter setter
        Vis_Title % title for visualization
        X_Title % x-axis title for visualization
        Y_Title % y-axis title for visualization
        FiberColor % fiber color for visualization
        CellColor % cell color for visualization
    end
    
    methods (Access = private)
        
        function sliderValueChangedFcn(app, src, event)
            if round(event.Value) == 0
                % edge case where bin number is 0 -- auto set to 1
                app.BinNumber = 1;
            else
                app.BinNumber = round(event.Value);
            end
            histCreateFcn(app, event);
        end

        function closeScriptFcn(app, src, event)
            app.BinNumber = -1;
        end
        
        function histCreateFcn(app, src, event)
            % find selected cell
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
                
                % create histogram with fiber and cell orientations overlapping
                if isempty(app.BinNumber) || app.BinNumber < 0
                    app.BinNumber = 25;

                    screen_size = get(0, 'ScreenSize');
                  
                    % configuring figure
                    fig_title = sprintf('Histogram of %s', coi);
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
                        "ValueChangedFcn",@(src,event)sliderValueChangedFcn(app,src,event));
                    app.UIAxes = axes(figure);
                    addlistener(app.UIAxes, 'ObjectBeingDestroyed', ...
                        @(src,event)closeScriptFcn(app,src,event));
                end

                cellData = cell2mat(cellData);
                fiberData = cell2mat(fiberData);
                if index > 7
                    minData = min(cellData);
                    maxData = max(cellData);
                else
                    minData = min(min(cellData), min(fiberData));
                    maxData = max(max(cellData), max(fiberData));
                end
                
                % configuring histograms
                % hist_title = sprintf('Frequency of %s', coi);

                if index == 7
                    edges = linspace(0, 180, app.BinNumber + 1);
                else
                    edges = linspace(minData, maxData, app.BinNumber + 1);
                end
                
                cla(app.UIAxes, 'reset');
                app.UIAxes.Position = [0.20, 0.15, 0.7, 0.75];
                cellHist = histogram(app.UIAxes, cellData, edges, 'facealpha', 0.5, ...
                    'FaceColor', app.CellColor); 
                hold(app.UIAxes, 'on');
                fiberHist = histogram(app.UIAxes, fiberData, edges, 'facealpha', 0.5, ...
                    'FaceColor', app.FiberColor);
                title(app.UIAxes, app.Vis_Title);
                xlabel(app.UIAxes, app.X_Title);
                ylabel(app.UIAxes, app.Y_Title);
                legend(app.UIAxes, 'Cells','Fibers');
            else
                disp('Cannot make histogram based on selection.')
            end
        end
    end
    
    methods (Access = public)
        
        function histStartFcn(app, src, event)
            histCreateFcn(app, event);
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

        % Button down function: UITable
        function UITableButtonDown(app, event)

        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            app.selectedCell = event.Indices;
        end

        % Button pushed function: BoxplotsButton
        function BoxplotsButtonPushed(app, event)
            % find selected cell
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

                % create violinplot with fiber and cell orientations side-by-side
                cellData = cell2mat(cellData);
                fiberData = cell2mat(fiberData);
                fig_title = sprintf("Boxplot of %s", coi);
                box_title = sprintf("Distribution of %s", coi);

                groupCell = repmat({'Cell'}, length(cellData), 1);
                groupFiber = repmat({'Fiber'}, length(fiberData), 1);
                figure('Name', fig_title);
                box = boxplot([cellData; fiberData], [groupCell; groupFiber], ...
                    "BoxStyle", "outline", ...
                    "Colors", [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]]);
                set(box, "LineWidth", 2);
                h = findobj(gca, "Tag", "Box");
                for j = 1:length(h)
                    patch(get(h(j), 'XData'), ...
                        get(h(j), 'YData'), ...
                        get(h(j), 'Color'), ...
                        'FaceAlpha', .5);
                end
                ylabel(coi);
                title(box_title)
            else
                disp('Cannot make boxplot based on selection.')
            end
        end

        % Button pushed function: ViolinplotsButton
        function ViolinplotsButtonPushed(app, event)
            % find selected cell
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

                % create violinplot with fiber and cell orientations side-by-side
                cellData = cell2mat(cellData);
                fiberData = cell2mat(fiberData);
                fig_title = sprintf("Violinplot of %s", coi);
                box_title = sprintf("Distribution of %s", coi);

                groupCell = repmat({'Cell'}, length(cellData), 1);
                groupFiber = repmat({'Fiber'}, length(fiberData), 1);
                figure('Name', fig_title);
                ylabel(coi)
                title(box_title)
                vs = violinplot([cellData; fiberData], [groupCell; groupFiber]);
            else
                disp('Cannot make violinplot based on selection.')
            end
        end

        % Button pushed function: HistogramsButton
        function HistogramsButtonPushed(app, event)
            app.ParameterVisAPP = hist_parameterVis(app);
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
            app.UITable.ButtonDownFcn = createCallbackFcn(app, @UITableButtonDown, true);
            app.UITable.Position = [29 71 791 309];

            % Create HistogramsButton
            app.HistogramsButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.HistogramsButton.ButtonPushedFcn = createCallbackFcn(app, @HistogramsButtonPushed, true);
            app.HistogramsButton.Position = [361 23 126 22];
            app.HistogramsButton.Text = 'Histograms';

            % Create CloseButton
            app.CloseButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [513 23 126 22];
            app.CloseButton.Text = 'Close';

            % Create SaveButton
            app.SaveButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [665 23 120 22];
            app.SaveButton.Text = 'Save';

            % Create ViolinplotsButton
            app.ViolinplotsButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.ViolinplotsButton.ButtonPushedFcn = createCallbackFcn(app, @ViolinplotsButtonPushed, true);
            app.ViolinplotsButton.Position = [208 22 126 23];
            app.ViolinplotsButton.Text = 'Violinplots';

            % Create BoxplotsButton
            app.BoxplotsButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.BoxplotsButton.ButtonPushedFcn = createCallbackFcn(app, @BoxplotsButtonPushed, true);
            app.BoxplotsButton.Position = [56 22 126 23];
            app.BoxplotsButton.Text = 'Boxplots';

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