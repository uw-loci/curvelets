% Takes an input of a UITable (with column names and values), and 
% creates possibilities of statistical figures based off of it.

function statisticalVisualization(table)

    app = struct();
    app.BinNumber = -1;
    app.CellBin = -1;
    app.FiberBin = -1;
    appearanceOptions = struct('title', '', 'x_label', '', 'y_label', '', ...
            'cellColor', [0.00,0.45,0.74], 'fiberColor', [0.85,0.33,0.10]);
    typeOptions = struct('plotType', 'Boxplot', 'measurementType', 'Center-X', ...
            'objectType', 'Cell');
    uiStartup();

    function uiStartup()
        % Create UIFigure and hide until all components are created
        app.UIFigure = uifigure('Visible', 'off');
        app.UIFigure.Position = [100 100 320 390];
        app.UIFigure.Name = 'Statistical Visualization';

        % Create ObjectTypeDropDownLabel
        app.ObjectTypeDropDownLabel = uilabel(app.UIFigure);
        app.ObjectTypeDropDownLabel.Position = [32 348 133 22];
        app.ObjectTypeDropDownLabel.Text = 'Object Type';

        % Create ObjectTypeDropDown
        app.ObjectTypeDropDown = uidropdown(app.UIFigure);
        app.ObjectTypeDropDown.Items = {'Cell', 'Fiber', 'Cell & Fiber'};
        app.ObjectTypeDropDown.ValueChangedFcn = @(src, event)ObjectTypeDropDownValueChanged (src, event);
        app.ObjectTypeDropDown.Position = [188 348 101 22];
        app.ObjectTypeDropDown.Value = 'Cell';

        % Create PlotTypeDropDownLabel
        app.PlotTypeDropDownLabel = uilabel(app.UIFigure);
        app.PlotTypeDropDownLabel.Position = [32 307 55 22];
        app.PlotTypeDropDownLabel.Text = 'Plot Type';

        % Create PlotTypeDropDown
        app.PlotTypeDropDown = uidropdown(app.UIFigure);
        app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', 'Histogram'};
        app.PlotTypeDropDown.ValueChangedFcn = @(src, event)PlotTypeDropDownValueChanged (src, event);
        app.PlotTypeDropDown.Position = [188 307 101 22];
        app.PlotTypeDropDown.Value = 'Boxplot';

        % Create MeasurementTypeDropDownLabel
        app.MeasurementTypeDropDownLabel = uilabel(app.UIFigure);
        app.MeasurementTypeDropDownLabel.Position = [32 266 159 22];
        app.MeasurementTypeDropDownLabel.Text = 'Measurement Type';

        % Create MeasurementTypeDropDown
        app.MeasurementTypeDropDown = uidropdown(app.UIFigure);
        app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y', 'Orientation', 'Area', 'Circularity'};
        app.MeasurementTypeDropDown.ValueChangedFcn =  @(src, event)MeasurementTypeDropDownValueChanged (src, event);
        app.MeasurementTypeDropDown.Position = [188 266 101 22];
        app.MeasurementTypeDropDown.Value = 'Center-X';

        % Create XAxisLabelEditFieldLabel
        app.XAxisLabelEditFieldLabel = uilabel(app.UIFigure);
        app.XAxisLabelEditFieldLabel.Position = [32 180 72 22];
        app.XAxisLabelEditFieldLabel.Text = 'X-Axis Label';

        % Create XAxisLabelEditField
        app.XAxisLabelEditField = uieditfield(app.UIFigure, 'text');
        app.XAxisLabelEditField.ValueChangedFcn = @(src, event)XAxisLabelEditFieldValueChanged (src, event);
        app.XAxisLabelEditField.Position = [32 157 257 22];

        % Create YAxisLabelEditFieldLabel
        app.YAxisLabelEditFieldLabel = uilabel(app.UIFigure);
        app.YAxisLabelEditFieldLabel.Position = [32 131 71 22];
        app.YAxisLabelEditFieldLabel.Text = 'Y-Axis Label';

        % Create YAxisLabelEditField
        app.YAxisLabelEditField = uieditfield(app.UIFigure, 'text');
        app.YAxisLabelEditField.ValueChangedFcn = @(src, event)YAxisLabelEditFieldValueChanged (src, event);
        app.YAxisLabelEditField.Position = [32 108 257 22];

        % Create TitleEditFieldLabel
        app.TitleEditFieldLabel = uilabel(app.UIFigure);
        app.TitleEditFieldLabel.Position = [32 229 27 22];
        app.TitleEditFieldLabel.Text = 'Title';

        % % Create TitleEditField
        app.TitleEditField = uieditfield(app.UIFigure, 'text');
        app.TitleEditField.ValueChangedFcn =  @(src, event)TitleEditFieldValueChanged (src, event);
        app.TitleEditField.Position = [32 206 257 22];

        % Create FiberColorButton
        app.FiberColorButton = uibutton(app.UIFigure, 'push');
        app.FiberColorButton.ButtonPushedFcn = @(src, event)FiberColorButtonPushed (src, event);
        app.FiberColorButton.BackgroundColor = [0.851 0.3294 0.102];
        app.FiberColorButton.Position = [262 68 28 23];
        app.FiberColorButton.Text = '';

        % Create FiberColorLabel
        app.FiberColorLabel = uilabel(app.UIFigure);
        app.FiberColorLabel.Position = [177 69 64 22];
        app.FiberColorLabel.Text = 'Fiber Color';

        % Create CellColorButton
        app.CellColorButton = uibutton(app.UIFigure, 'push');
        app.CellColorButton.ButtonPushedFcn = @(src, event)CellColorButtonPushed (src, event);
        app.CellColorButton.BackgroundColor = [0 0.451 0.7412];
        app.CellColorButton.Position = [117 68 28 23];
        app.CellColorButton.Text = '';

        % % Create CellColorLabel
        app.CellColorLabel = uilabel(app.UIFigure);
        app.CellColorLabel.Position = [35 69 58 22];
        app.CellColorLabel.Text = 'Cell Color';

        % % Create ApplyButton
        app.ApplyButton = uibutton(app.UIFigure, 'push');
        app.ApplyButton.ButtonPushedFcn =  @(src, event)ApplyButtonPushed (src, event);
        app.ApplyButton.Position = [176 24 113 25];
        app.ApplyButton.Text = 'Apply';

        % % Create CancelButton
        app.CancelButton = uibutton(app.UIFigure, 'push');
        app.CancelButton.ButtonPushedFcn =  @(src, event)CancelButtonPushed (src, event);
        app.CancelButton.Position = [34 24 110 25];
        app.CancelButton.Text = 'Cancel';

        % Show the figure after all components are created
        app.UIFigure.Visible = 'on';
    end

    %---------------------- Callback functions ----------------------%
    function ObjectTypeDropDownValueChanged(~, event)
        typeOptions.objectType = event.Value;
        if ~strcmp(event.Value, 'Cell')
            app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y',...
                    'Orientation'};
        else
            app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y',...
                    'Orientation', 'Area', 'Circularity'};
        end

        if strcmp(event.Value, 'Cell & Fiber')
            app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', ...
                'Histogram (Side-By-Side)', 'Histogram (Overlapping)'};
        else
            app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', 'Histogram'};
        end
    end

    function PlotTypeDropDownValueChanged(~, event)
        typeOptions.plotType = event.Value;
    end

    function MeasurementTypeDropDownValueChanged(~, event)
        typeOptions.measurementType = event.Value;
    end

    function TitleEditFieldValueChanged(~, event)
        appearanceOptions.title = event.Value;
    end

    function XAxisLabelEditFieldValueChanged(~, event)
        appearanceOptions.x_label = event.Value;
    end

    function YAxisLabelEditFieldValueChanged(~, event)
        appearanceOptions.y_label = event.Value;
    end

    function CellColorButtonPushed(~, ~)
        cellColor = uisetcolor([0 0.4470 0.7410]);
        app.CellColorButton.BackgroundColor = cellColor;
        appearanceOptions.cellColor = app.CellColorButton.BackgroundColor;
    end

    function FiberColorButtonPushed(~, ~)
        fiberColor = uisetcolor([0.8500 0.3250 0.0980]);
        app.FiberColorButton.BackgroundColor = fiberColor;
        appearanceOptions.fiberColor = app.FiberColorButton.BackgroundColor;
    end

    function ApplyButtonPushed(~, ~)
        plotType = typeOptions.plotType;
        objType = typeOptions.objectType;

        if strcmp(plotType, 'Boxplot')
            boxplotFcn(table);
        elseif strcmp(plotType, 'Violinplot')
            violinplotFcn(table);
        elseif strcmp(plotType, 'Histogram')
            histogramFcn(table);
        elseif strcmp(objType, 'Cell & Fiber')
            if strcmp(plotType, 'Histogram (Side-By-Side)')
                histogramSideBySideFcn(table);
            elseif strcmp(plotType, 'Histogram (Overlapping)')
                histogramFcn(table);
            end
        end

        delete(app.UIFigure);
    end

    function CancelButtonPushed(~, ~)
        delete(app.UIFigure);
    end

    %---------------------- Figure functions ----------------------%
    function boxplotFcn(table)
        columnData = table.ColumnName;
        tableData = table.Data;
        
        % find index of measurement
        for i = 1:size(columnData)
            if strcmp(columnData{i, 1}, typeOptions.measurementType)
                index = i;
                break;
            end
        end
        
        % find cell
        cellNumber = cellCount(table);
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
        fiberNumber = fiberCount(table);
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

        fig_title = sprintf("Boxplot of %s of %s", typeOptions.measurementType,...
            typeOptions.objectType);
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

        if strcmp(typeOptions.objectType, "Cell")
            boxplot(app.UIAxes, cellData, 'Labels', groupCell, ...
                "BoxStyle", "outline", ...
                "Colors", appearanceOptions.cellColor);
        elseif strcmp(typeOptions.objectType, "Fiber")
            boxplot(app.UIAxes, fiberData, groupFiber, ...
                "BoxStyle", "outline", ...
                "Colors", appearanceOptions.fiberColor);
        else
            boxplot(app.UIAxes, [cellData; fiberData], [groupCell; groupFiber], ...
                "BoxStyle", "outline", ...
                "Colors", [appearanceOptions.cellColor; appearanceOptions.fiberColor])
            h = findobj(gca, "Tag", "Box");
            for j = 1:length(h)
                patch(get(h(j), 'XData'), ...
                    get(h(j), 'YData'), ...
                    get(h(j), 'Color'), ...
                    'FaceAlpha', .5);
            end
        end

        xlabel(app.UIAxes, appearanceOptions.x_label);
        ylabel(app.UIAxes, appearanceOptions.y_label);
        title(app.UIAxes, appearanceOptions.title);
    end

    function violinplotFcn(table)

        columnData = table.ColumnName;
        tableData = table.Data;
        
        % find index of measurement
        for i = 1:size(columnData)
            if strcmp(columnData{i, 1}, typeOptions.measurementType)
                index = i;
                break;
            end
        end
        
        % find cell
        cellNumber = cellCount(table);
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
        fiberNumber = fiberCount(table);
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
        fig_title = sprintf("Violinplot of %s of %s", typeOptions.measurementType,...
            typeOptions.objectType);

        cellData = cell2mat(cellData);
        fiberData = cell2mat(fiberData);

        figure('NumberTitle', 'Off', 'Name', fig_title);
        groupCell = repmat({'Cell'}, length(cellData), 1);
        groupFiber = repmat({'Fiber'}, length(fiberData), 1);

        if strcmp(typeOptions.objectType, "Cell")
            violinplot(cellData, groupCell, 'ViolinColor', appearanceOptions.cellColor);
        elseif strcmp(typeOptions.objectType, "Fiber")
            violinplot(fiberData, groupFiber, 'ViolinColor', appearanceOptions.fiberColor);
        else
            violinplot([cellData; fiberData], [groupCell; groupFiber], ...
                'ViolinColor', [appearanceOptions.cellColor; appearanceOptions.fiberColor]);
                
        end
        xlabel(appearanceOptions.x_label);
        ylabel(appearanceOptions.y_label);
        title(appearanceOptions.title);
    end

    function histogramFcn(table)
        columnData = table.ColumnName;
        tableData = table.Data;
        
        % find index of measurement
        for i = 1:size(columnData)
            if strcmp(columnData{i, 1}, typeOptions.measurementType)
                index = i;
                break;
            end
        end
        
        % find cell
        cellNumber = cellCount(table);
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
        fiberNumber = fiberCount(table);
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
                typeOptions.measurementType, typeOptions.objectType);
            fig_width = 750;
            fig_height = 500;
            fig_left = (screen_size(3) - fig_width) / 2;
            fig_bottom = (screen_size(4) - fig_height) / 2;
            position = [fig_left, fig_bottom, fig_width, fig_height];

            figure = uifigure('Name', fig_title, ...
                "WindowStyle", "normal", ...
                "Position", position);
            uislider(figure, ...
                "Orientation", "vertical", ...
                "Value", 25, ...
                "Position", [20, 150, 3, 200], ...
                "Limits", [0, 50], ...
                "ValueChangedFcn",@(src,event)sliderOneValueChangedFcn(src,event));
            app.UIAxes = axes(figure);
            addlistener(app.UIAxes, 'ObjectBeingDestroyed', ...
                @closeOneScriptFcn);
        end

        cellData = cell2mat(cellData);
        fiberData = cell2mat(fiberData);

        % checking object type for visualization
        if strcmp(typeOptions.objectType, "Cell")
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
        if strcmp(typeOptions.objectType, "Cell")
            histogram(app.UIAxes, cellData, edges, 'facealpha', 0.5, ...
                'FaceColor', appearanceOptions.cellColor); 
        elseif strcmp(typeOptions.objectType, "Fiber")
            histogram(app.UIAxes, fiberData, edges, 'facealpha', 0.5, ...
                'FaceColor', appearanceOptions.fiberColor);
        else
            histogram(app.UIAxes, cellData, edges, 'facealpha', 0.5, ...
                'FaceColor', appearanceOptions.cellColor); 
            hold(app.UIAxes, 'on');
            histogram(app.UIAxes, fiberData, edges, 'facealpha', 0.5, ...
                'FaceColor', appearanceOptions.fiberColor);
            legend(app.UIAxes, {'Cell', 'Fiber'});
        end
        title(app.UIAxes, appearanceOptions.title);
        xlabel(app.UIAxes, appearanceOptions.x_label);
        ylabel(app.UIAxes, appearanceOptions.y_label);
    end

    function histogramSideBySideFcn(table)
        columnData = table.ColumnName;
        tableData = table.Data;

        % find index of measurement
        for i = 1:size(columnData)
            if strcmp(columnData{i, 1}, typeOptions.measurementType)
                index = i;
                break;
            end
        end
        
        % find cell
        cellNumber = cellCount(table);
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
        fiberNumber = fiberCount(table);
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
                typeOptions.measurementType, typeOptions.objectType);
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
                @closeBothScriptFcn);
            addlistener(app.FiberAxes, 'ObjectBeingDestroyed', ...
                @closeBothScriptFcn);
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
            'FaceColor', appearanceOptions.cellColor); 
        fiberHist = histogram(app.FiberAxes, fiberData, fiberEdges, 'facealpha', 0.5, ...
            'FaceColor', appearanceOptions.fiberColor);

        cellTitle = sprintf("Histogram of Cell %s", appearanceOptions.title);
        fiberTitle = sprintf("Histogram of Fiber %s", appearanceOptions.title);

        title(app.CellAxes, cellTitle);
        xlabel(app.CellAxes, appearanceOptions.x_label);
        ylabel(app.CellAxes, appearanceOptions.y_label);

        title(app.FiberAxes, fiberTitle);
        xlabel(app.FiberAxes, appearanceOptions.x_label);
        ylabel(app.FiberAxes, appearanceOptions.y_label);

        cellSlider.ValueChangedFcn = @(src,event)updateHistogram(app.CellAxes, ...
            cellData, cellSlider.Value, cellHist, appearanceOptions.cellColor);
        fiberSlider.ValueChangedFcn = @(src,event)updateHistogram(app.FiberAxes, ...
            fiberData, fiberSlider.Value, fiberHist, appearanceOptions.fiberColor);
    end

    %---------------------- Helper functions ----------------------%

    % counts number of cell values in data
    function [cells] = cellCount(table) 
        columnData = table.ColumnName;
        tableData = table.Data;

        i = 1;
        while i < length(columnData) & ~strcmp(columnData{i}, "Class")
            i = i + 1;
        end
        
        cells = 0;
        
        for j = 1:length(tableData)
            if(strcmp(tableData{j, i}, "Cell"))
                cells = cells + 1;
            end
        end
    end

    % counts number of fiber values in data
    function [fibers] = fiberCount(table) 
        columnData = table.ColumnName;
        tableData = table.Data;

        i = 1;
        while i < length(columnData) & ~strcmp(columnData{i}, "Class")
            i = i + 1;
        end
        
        fibers = 0;
        
        for j = 1:length(tableData)
            if(strcmp(tableData{j, i}, "Fiber"))
                fibers = fibers + 1;
            end
        end
    end

    function sliderOneValueChangedFcn(~, event)
        if round(event.Value) == 0
            % edge case where bin number is 0 -- auto set to 1
            app.BinNumber = 1;
        else
            app.BinNumber = round(event.Value);
        end
        histogramFcn(table);
    end

    function updateHistogram(ax, data, binCount, histHandle, faceColor) %#ok<INUSD>
        histogram(ax, data, 'NumBins', round(binCount), 'FaceColor', faceColor);
    end

    function closeOneScriptFcn()
        app.BinNumber = -1;
    end

    function closeBothScriptFcn()
        app.FiberBin = -1;
        app.CellBin = -1;
    end

end