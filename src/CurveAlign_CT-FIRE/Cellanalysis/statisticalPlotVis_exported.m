classdef statisticalPlotVis_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        CancelButton                  matlab.ui.control.Button
        ApplyButton                   matlab.ui.control.Button
        CellColorLabel                matlab.ui.control.Label
        CellColorButton               matlab.ui.control.Button
        FiberColorLabel               matlab.ui.control.Label
        FiberColorButton              matlab.ui.control.Button
        ObjectTypeDropDown            matlab.ui.control.DropDown
        ObjectTypeDropDownLabel       matlab.ui.control.Label
        MeasurementTypeDropDown       matlab.ui.control.DropDown
        MeasurementTypeDropDownLabel  matlab.ui.control.Label
        TitleEditField                matlab.ui.control.EditField
        TitleEditFieldLabel           matlab.ui.control.Label
        YAxisLabelEditField           matlab.ui.control.EditField
        YAxisLabelEditFieldLabel      matlab.ui.control.Label
        XAxisLabelEditField           matlab.ui.control.EditField
        XAxisLabelEditFieldLabel      matlab.ui.control.Label
        PlotTypeDropDown              matlab.ui.control.DropDown
        PlotTypeDropDownLabel         matlab.ui.control.Label
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        app
        appearanceOptions = struct('title', '', 'x_title', '', 'y_title', '', ...
            'cellColor', [0.00,0.45,0.74], 'fiberColor', [0.85,0.33,0.10]);
        typeOptions = struct('plotType', 'Boxplot', 'measurementType', 'Center-X', ...
            'objectType', 'Cell');
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            app.CallingApp = mainAPP;

            screen_size = get(0, 'ScreenSize');

             % configuring figure
            fig_width = 320;
            fig_height = 400;
            fig_left = (screen_size(3) - fig_width) / 2;
            fig_bottom = (screen_size(4) - fig_height) / 2;
            position = [fig_left, fig_bottom, fig_width, fig_height];
            app.UIFigure.Position = position;

            app.UIFigure.Name = 'Statistical Plot Options';
        end

        % Value changed function: ObjectTypeDropDown
        function ObjectTypeDropDownValueChanged(app, event)
            app.typeOptions.objectType = app.ObjectTypeDropDown.Value;
            if ~strcmp(app.typeOptions.objectType, 'Cell')
                app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y',...
                    'Orientation'};
            else
                app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y',...
                    'Orientation', 'Area', 'Circularity'};
            end

            if strcmp(app.typeOptions.objectType, 'Cell & Fiber')
                app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', ...
                    'Histogram (Side-By-Side)', 'Histogram (Overlapping)'};
            else
                app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', 'Histogram'};
            end
            
        end

        % Value changed function: PlotTypeDropDown
        function PlotTypeDropDownValueChanged(app, event)
            app.typeOptions.plotType = app.PlotTypeDropDown.Value;
        end

        % Value changed function: MeasurementTypeDropDown
        function MeasurementTypeDropDownValueChanged(app, event)
            app.typeOptions.measurementType = app.MeasurementTypeDropDown.Value;
            
        end

        % Value changed function: TitleEditField
        function TitleEditFieldValueChanged(app, event)
            app.appearanceOptions.title = app.TitleEditField.Value;
            
        end

        % Value changed function: XAxisLabelEditField
        function XAxisLabelEditFieldValueChanged(app, event)
            app.appearanceOptions.x_title = app.XAxisLabelEditField.Value;
            
        end

        % Value changed function: YAxisLabelEditField
        function YAxisLabelEditFieldValueChanged(app, event)
            app.appearanceOptions.y_title = app.YAxisLabelEditField.Value;
            
        end

        % Button pushed function: CellColorButton
        function CellColorButtonPushed(app, event)
            cellColor = uisetcolor([0 0.4470 0.7410]);
            app.CellColorButton.BackgroundColor = cellColor;
            app.appearanceOptions.cellColor = app.CellColorButton.BackgroundColor;
        end

        % Button pushed function: FiberColorButton
        function FiberColorButtonPushed(app, event)
            fiberColor = uisetcolor([0.8500 0.3250 0.0980]);
            app.FiberColorButton.BackgroundColor = fiberColor;
            app.appearanceOptions.fiberColor = app.FiberColorButton.BackgroundColor;
        end

        % Button pushed function: ApplyButton
        function ApplyButtonPushed(app, event)
            % parameters that affect appearance of statistical
            % visualization
            app.CallingApp.Vis_Title = app.appearanceOptions.title;
            app.CallingApp.X_Title = app.appearanceOptions.x_title;
            app.CallingApp.Y_Title = app.appearanceOptions.y_title;
            app.CallingApp.CellColor = app.appearanceOptions.cellColor;
            app.CallingApp.FiberColor = app.appearanceOptions.fiberColor;
            app.CallingApp.ObjectType = app.typeOptions.objectType;
            app.CallingApp.MeasurementType = app.typeOptions.measurementType;

            % parameters that affect type of data processed
            plotType = app.typeOptions.plotType;
            objectType = app.typeOptions.objectType;

            if strcmp(plotType, 'Boxplot')
                app.CallingApp.boxplotStartFcn(app.CallingApp, app);
            elseif strcmp(plotType, 'Violinplot')
                app.CallingApp.violinplotStartFcn(app.CallingApp, app);
            elseif strcmp(plotType, 'Histogram')
                app.CallingApp.histogramStartOneFcn(app.CallingApp, app);
            elseif strcmp(objectType, 'Cell & Fiber')
                if strcmp(plotType, 'Histogram (Side-By-Side)')
                    app.CallingApp.histogramStartBothFcn(app.CallingApp, app);
                else
                    app.CallingApp.histogramStartOneFcn(app.CallingApp, app);
                end
            end

            app.delete;
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            app.delete
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 320 390];
            app.UIFigure.Name = 'MATLAB App';

            % Create PlotTypeDropDownLabel
            app.PlotTypeDropDownLabel = uilabel(app.UIFigure);
            app.PlotTypeDropDownLabel.Position = [32 307 55 22];
            app.PlotTypeDropDownLabel.Text = 'Plot Type';

            % Create PlotTypeDropDown
            app.PlotTypeDropDown = uidropdown(app.UIFigure);
            app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', 'Histogram'};
            app.PlotTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @PlotTypeDropDownValueChanged, true);
            app.PlotTypeDropDown.Position = [188 307 101 22];
            app.PlotTypeDropDown.Value = 'Boxplot';

            % Create XAxisLabelEditFieldLabel
            app.XAxisLabelEditFieldLabel = uilabel(app.UIFigure);
            app.XAxisLabelEditFieldLabel.Position = [32 180 72 22];
            app.XAxisLabelEditFieldLabel.Text = 'X-Axis Label';

            % Create XAxisLabelEditField
            app.XAxisLabelEditField = uieditfield(app.UIFigure, 'text');
            app.XAxisLabelEditField.ValueChangedFcn = createCallbackFcn(app, @XAxisLabelEditFieldValueChanged, true);
            app.XAxisLabelEditField.Position = [32 157 257 22];

            % Create YAxisLabelEditFieldLabel
            app.YAxisLabelEditFieldLabel = uilabel(app.UIFigure);
            app.YAxisLabelEditFieldLabel.Position = [32 131 71 22];
            app.YAxisLabelEditFieldLabel.Text = 'Y-Axis Label';

            % Create YAxisLabelEditField
            app.YAxisLabelEditField = uieditfield(app.UIFigure, 'text');
            app.YAxisLabelEditField.ValueChangedFcn = createCallbackFcn(app, @YAxisLabelEditFieldValueChanged, true);
            app.YAxisLabelEditField.Position = [32 108 257 22];

            % Create TitleEditFieldLabel
            app.TitleEditFieldLabel = uilabel(app.UIFigure);
            app.TitleEditFieldLabel.Position = [32 229 27 22];
            app.TitleEditFieldLabel.Text = 'Title';

            % Create TitleEditField
            app.TitleEditField = uieditfield(app.UIFigure, 'text');
            app.TitleEditField.ValueChangedFcn = createCallbackFcn(app, @TitleEditFieldValueChanged, true);
            app.TitleEditField.Position = [32 206 257 22];

            % Create MeasurementTypeDropDownLabel
            app.MeasurementTypeDropDownLabel = uilabel(app.UIFigure);
            app.MeasurementTypeDropDownLabel.Position = [32 266 159 22];
            app.MeasurementTypeDropDownLabel.Text = 'Measurement Type';

            % Create MeasurementTypeDropDown
            app.MeasurementTypeDropDown = uidropdown(app.UIFigure);
            app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y', 'Orientation', 'Area', 'Circularity'};
            app.MeasurementTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @MeasurementTypeDropDownValueChanged, true);
            app.MeasurementTypeDropDown.Position = [188 266 101 22];
            app.MeasurementTypeDropDown.Value = 'Center-X';

            % Create ObjectTypeDropDownLabel
            app.ObjectTypeDropDownLabel = uilabel(app.UIFigure);
            app.ObjectTypeDropDownLabel.Position = [32 348 133 22];
            app.ObjectTypeDropDownLabel.Text = 'Object Type';

            % Create ObjectTypeDropDown
            app.ObjectTypeDropDown = uidropdown(app.UIFigure);
            app.ObjectTypeDropDown.Items = {'Cell', 'Fiber', 'Cell & Fiber'};
            app.ObjectTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ObjectTypeDropDownValueChanged, true);
            app.ObjectTypeDropDown.Position = [188 348 101 22];
            app.ObjectTypeDropDown.Value = 'Cell';

            % Create FiberColorButton
            app.FiberColorButton = uibutton(app.UIFigure, 'push');
            app.FiberColorButton.ButtonPushedFcn = createCallbackFcn(app, @FiberColorButtonPushed, true);
            app.FiberColorButton.BackgroundColor = [0.851 0.3294 0.102];
            app.FiberColorButton.Position = [262 68 28 23];
            app.FiberColorButton.Text = '';

            % Create FiberColorLabel
            app.FiberColorLabel = uilabel(app.UIFigure);
            app.FiberColorLabel.Position = [177 69 64 22];
            app.FiberColorLabel.Text = 'Fiber Color';

            % Create CellColorButton
            app.CellColorButton = uibutton(app.UIFigure, 'push');
            app.CellColorButton.ButtonPushedFcn = createCallbackFcn(app, @CellColorButtonPushed, true);
            app.CellColorButton.BackgroundColor = [0 0.451 0.7412];
            app.CellColorButton.Position = [117 68 28 23];
            app.CellColorButton.Text = '';

            % Create CellColorLabel
            app.CellColorLabel = uilabel(app.UIFigure);
            app.CellColorLabel.Position = [35 69 58 22];
            app.CellColorLabel.Text = 'Cell Color';

            % Create ApplyButton
            app.ApplyButton = uibutton(app.UIFigure, 'push');
            app.ApplyButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyButtonPushed, true);
            app.ApplyButton.Position = [176 24 113 25];
            app.ApplyButton.Text = 'Apply';

            % Create CancelButton
            app.CancelButton = uibutton(app.UIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [34 24 110 25];
            app.CancelButton.Text = 'Cancel';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = statisticalPlotVis_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end