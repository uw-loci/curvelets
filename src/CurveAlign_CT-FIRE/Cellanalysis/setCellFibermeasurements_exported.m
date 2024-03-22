classdef setCellFibermeasurements_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        setCellFibermeasurementsUIFigure  matlab.ui.Figure
        SetMeasurementsPanel  matlab.ui.container.Panel
        PlotobjectandboundarypointassociationCheckBox  matlab.ui.control.CheckBox
        SaveoverlayfiguretoatiffileCheckBox  matlab.ui.control.CheckBox
        SavemeasurementstoaxlsxfileCheckBox  matlab.ui.control.CheckBox
        ExcluefiberswithinanannotationCheckBox  matlab.ui.control.CheckBox
        CancelButton          matlab.ui.control.Button
        OKButton              matlab.ui.control.Button
        RelativeanglemeasurementsCheckBox  matlab.ui.control.CheckBox
        MaximumdistancetoboundaryEditField  matlab.ui.control.NumericEditField
        MaximumdistancetoboundaryEditFieldLabel  matlab.ui.control.Label
    end

    
    properties (Access = public)
        callingApp % the APP calling the current app 
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            if nargin == 2
                %  app.measurementsSettings = struct('relativeAngleFlag',1, 'distance2boundary', 100,...
                % 'excludeInboundaryfiberFlag',0,'saveMeasurementsdataFlag',1,'saveMeasurementsfigFlag',0); % default measurements settings;
                app.callingApp = mainAPP;
                app.RelativeanglemeasurementsCheckBox.Value = mainAPP.measurementsSettings.relativeAngleFlag;
                app.MaximumdistancetoboundaryEditField.Value = mainAPP.measurementsSettings.distance2boundary;
                app.ExcluefiberswithinanannotationCheckBox.Value = mainAPP.measurementsSettings.excludeInboundaryfiberFlag;
                app.SavemeasurementstoaxlsxfileCheckBox.Value = mainAPP.measurementsSettings.saveMeasurementsdataFlag;
                app.SaveoverlayfiguretoatiffileCheckBox.Value = mainAPP.measurementsSettings.saveMeasurementsfigFlag;
                app.PlotobjectandboundarypointassociationCheckBox.Value = mainAPP.measurementsSettings.plotAssociationFlag;
            end

        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            app.callingApp.measurementsSettings.relativeAngleFlag = app.RelativeanglemeasurementsCheckBox.Value;
            app.callingApp.measurementsSettings.distance2boundary = app.MaximumdistancetoboundaryEditField.Value;
            app.callingApp.measurementsSettings.excludeInboundaryfiberFlag = app.ExcluefiberswithinanannotationCheckBox.Value;
            app.callingApp.measurementsSettings.saveMeasurementsdataFlag = app.SavemeasurementstoaxlsxfileCheckBox.Value;
            app.callingApp.measurementsSettings.saveMeasurementsfigFlag = app.SaveoverlayfiguretoatiffileCheckBox.Value;
            app.callingApp.measurementsSettings.plotAssociationFlag = app.PlotobjectandboundarypointassociationCheckBox.Value;
            disp('Measurements setting is done')
            delete(app)
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            disp('No change to the current measurements setting')
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create setCellFibermeasurementsUIFigure and hide until all components are created
            app.setCellFibermeasurementsUIFigure = uifigure('Visible', 'off');
            app.setCellFibermeasurementsUIFigure.Position = [100 100 335 324];
            app.setCellFibermeasurementsUIFigure.Name = 'setCellFibermeasurements';
            app.setCellFibermeasurementsUIFigure.Tag = 'setCFmeasurements';

            % Create SetMeasurementsPanel
            app.SetMeasurementsPanel = uipanel(app.setCellFibermeasurementsUIFigure);
            app.SetMeasurementsPanel.Title = 'Set Measurements';
            app.SetMeasurementsPanel.Position = [12 5 324 317];

            % Create MaximumdistancetoboundaryEditFieldLabel
            app.MaximumdistancetoboundaryEditFieldLabel = uilabel(app.SetMeasurementsPanel);
            app.MaximumdistancetoboundaryEditFieldLabel.HorizontalAlignment = 'right';
            app.MaximumdistancetoboundaryEditFieldLabel.Position = [43 223 178 22];
            app.MaximumdistancetoboundaryEditFieldLabel.Text = 'Maximum distance to boundary  ';

            % Create MaximumdistancetoboundaryEditField
            app.MaximumdistancetoboundaryEditField = uieditfield(app.SetMeasurementsPanel, 'numeric');
            app.MaximumdistancetoboundaryEditField.Tooltip = {'the maximum distance that an objective or a fiber can have to the associated boundary'};
            app.MaximumdistancetoboundaryEditField.Position = [236 223 59 22];
            app.MaximumdistancetoboundaryEditField.Value = 100;

            % Create RelativeanglemeasurementsCheckBox
            app.RelativeanglemeasurementsCheckBox = uicheckbox(app.SetMeasurementsPanel);
            app.RelativeanglemeasurementsCheckBox.Text = 'Relative angle measurements';
            app.RelativeanglemeasurementsCheckBox.WordWrap = 'on';
            app.RelativeanglemeasurementsCheckBox.Position = [43 255 218 22];
            app.RelativeanglemeasurementsCheckBox.Value = true;

            % Create OKButton
            app.OKButton = uibutton(app.SetMeasurementsPanel, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [103 14 100 23];
            app.OKButton.Text = 'OK';

            % Create CancelButton
            app.CancelButton = uibutton(app.SetMeasurementsPanel, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [208 14 100 23];
            app.CancelButton.Text = 'Cancel';

            % Create ExcluefiberswithinanannotationCheckBox
            app.ExcluefiberswithinanannotationCheckBox = uicheckbox(app.SetMeasurementsPanel);
            app.ExcluefiberswithinanannotationCheckBox.Text = 'Exclue fibers within an annotation';
            app.ExcluefiberswithinanannotationCheckBox.Position = [41 189 256 22];

            % Create SavemeasurementstoaxlsxfileCheckBox
            app.SavemeasurementstoaxlsxfileCheckBox = uicheckbox(app.SetMeasurementsPanel);
            app.SavemeasurementstoaxlsxfileCheckBox.Text = 'Save measurements to a .xlsx file';
            app.SavemeasurementstoaxlsxfileCheckBox.Position = [41 157 222 22];
            app.SavemeasurementstoaxlsxfileCheckBox.Value = true;

            % Create SaveoverlayfiguretoatiffileCheckBox
            app.SaveoverlayfiguretoatiffileCheckBox = uicheckbox(app.SetMeasurementsPanel);
            app.SaveoverlayfiguretoatiffileCheckBox.Text = 'Save overlay figure to a .tif file';
            app.SaveoverlayfiguretoatiffileCheckBox.Position = [40 124 221 22];

            % Create PlotobjectandboundarypointassociationCheckBox
            app.PlotobjectandboundarypointassociationCheckBox = uicheckbox(app.SetMeasurementsPanel);
            app.PlotobjectandboundarypointassociationCheckBox.Text = 'Plot object and boundary point association';
            app.PlotobjectandboundarypointassociationCheckBox.Position = [41 93 250 22];

            % Show the figure after all components are created
            app.setCellFibermeasurementsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = setCellFibermeasurements_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.setCellFibermeasurementsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.setCellFibermeasurementsUIFigure)
        end
    end
end