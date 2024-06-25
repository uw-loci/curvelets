classdef hist_parameterVis_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        TitleEditField            matlab.ui.control.EditField
        TitleEditFieldLabel       matlab.ui.control.Label
        YAxisTitleEditField       matlab.ui.control.EditField
        YAxisTitleEditFieldLabel  matlab.ui.control.Label
        XAxisTitleEditField       matlab.ui.control.EditField
        XAxisTitleEditFieldLabel  matlab.ui.control.Label
        CellColorLabel            matlab.ui.control.Label
        CellColorButton           matlab.ui.control.Button
        FiberColorLabel           matlab.ui.control.Label
        FiberColorButton          matlab.ui.control.Button
        CancelButton              matlab.ui.control.Button
        ApplyButton               matlab.ui.control.Button
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        app
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            app.CallingApp = mainAPP;

            screen_size = get(0, 'ScreenSize');

             % configuring figure
            fig_width = 288;
            fig_height = 257;
            fig_left = (screen_size(3) - fig_width) / 2;
            fig_bottom = (screen_size(4) - fig_height) / 2;
            position = [fig_left, fig_bottom, fig_width, fig_height];
            app.UIFigure.Position = position;

            if app.CallingApp.selectedCell(1,1) == 0
                index = 7;
            else
                index = app.CallingApp.selectedCell(1,2);
            end

            temp_coi = app.CallingApp.UITable.ColumnName(index);
            default_title = sprintf("Frequency of %s", temp_coi{1});
            app.TitleEditField.Value = default_title;
            app.XAxisTitleEditField.Value = temp_coi{1};
            app.UIFigure.Name = 'Histogram Options';
        end

        % Button pushed function: ApplyButton
        function ApplyButtonPushed(app, event)
            app.CallingApp.Vis_Title = app.TitleEditField.Value;
            app.CallingApp.X_Title = app.XAxisTitleEditField.Value;
            app.CallingApp.Y_Title = app.YAxisTitleEditField.Value;
            app.CallingApp.FiberColor = app.FiberColorButton.BackgroundColor;
            app.CallingApp.CellColor = app.CellColorButton.BackgroundColor;
            app.CallingApp.histStartFcn(app.CallingApp, app);
            app.delete;
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            app.delete;
        end

        % Button pushed function: CellColorButton
        function CellColorButtonPushed(app, event)
            cellColor = uisetcolor([0 0.4470 0.7410]);
            app.CellColorButton.BackgroundColor = cellColor;
        end

        % Button pushed function: FiberColorButton
        function FiberColorButtonPushed(app, event)
            fiberColor = uisetcolor([0.8500 0.3250 0.0980]);
            app.FiberColorButton.BackgroundColor = fiberColor;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [600 400 288 257];
            app.UIFigure.Name = 'MATLAB App';

            % Create ApplyButton
            app.ApplyButton = uibutton(app.UIFigure, 'push');
            app.ApplyButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyButtonPushed, true);
            app.ApplyButton.Position = [160 21 113 25];
            app.ApplyButton.Text = 'Apply';

            % Create CancelButton
            app.CancelButton = uibutton(app.UIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [18 21 110 25];
            app.CancelButton.Text = 'Cancel';

            % Create FiberColorButton
            app.FiberColorButton = uibutton(app.UIFigure, 'push');
            app.FiberColorButton.ButtonPushedFcn = createCallbackFcn(app, @FiberColorButtonPushed, true);
            app.FiberColorButton.BackgroundColor = [0.851 0.3255 0.098];
            app.FiberColorButton.Position = [245 59 28 23];
            app.FiberColorButton.Text = '';

            % Create FiberColorLabel
            app.FiberColorLabel = uilabel(app.UIFigure);
            app.FiberColorLabel.Position = [160 60 64 22];
            app.FiberColorLabel.Text = 'Fiber Color';

            % Create CellColorButton
            app.CellColorButton = uibutton(app.UIFigure, 'push');
            app.CellColorButton.ButtonPushedFcn = createCallbackFcn(app, @CellColorButtonPushed, true);
            app.CellColorButton.BackgroundColor = [0 0.4471 0.7412];
            app.CellColorButton.Position = [100 59 28 23];
            app.CellColorButton.Text = '';

            % Create CellColorLabel
            app.CellColorLabel = uilabel(app.UIFigure);
            app.CellColorLabel.Position = [18 60 58 22];
            app.CellColorLabel.Text = 'Cell Color';

            % Create XAxisTitleEditFieldLabel
            app.XAxisTitleEditFieldLabel = uilabel(app.UIFigure);
            app.XAxisTitleEditFieldLabel.HorizontalAlignment = 'right';
            app.XAxisTitleEditFieldLabel.Position = [16 166 65 22];
            app.XAxisTitleEditFieldLabel.Text = 'X-Axis Title';

            % Create XAxisTitleEditField
            app.XAxisTitleEditField = uieditfield(app.UIFigure, 'text');
            app.XAxisTitleEditField.Position = [16 143 257 22];

            % Create YAxisTitleEditFieldLabel
            app.YAxisTitleEditFieldLabel = uilabel(app.UIFigure);
            app.YAxisTitleEditFieldLabel.HorizontalAlignment = 'right';
            app.YAxisTitleEditFieldLabel.Position = [16 119 65 22];
            app.YAxisTitleEditFieldLabel.Text = 'Y-Axis Title';

            % Create YAxisTitleEditField
            app.YAxisTitleEditField = uieditfield(app.UIFigure, 'text');
            app.YAxisTitleEditField.Position = [16 96 257 22];
            app.YAxisTitleEditField.Value = 'Frequency';

            % Create TitleEditFieldLabel
            app.TitleEditFieldLabel = uilabel(app.UIFigure);
            app.TitleEditFieldLabel.HorizontalAlignment = 'right';
            app.TitleEditFieldLabel.Position = [16 214 27 22];
            app.TitleEditFieldLabel.Text = 'Title';

            % Create TitleEditField
            app.TitleEditField = uieditfield(app.UIFigure, 'text');
            app.TitleEditField.Position = [16 191 257 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = hist_parameterVis_exported(varargin)

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