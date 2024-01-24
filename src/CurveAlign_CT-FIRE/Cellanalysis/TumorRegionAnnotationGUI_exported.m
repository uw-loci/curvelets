classdef TumorRegionAnnotationGUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TumorRegionDetectionoptionsUIFigure  matlab.ui.Figure
        SliderDensityParameter          matlab.ui.control.Slider
        SliderGrideRow                  matlab.ui.control.Slider
        SliderGridCol                   matlab.ui.control.Slider
        GridRowsEditField               matlab.ui.control.NumericEditField
        GridRowsEditFieldLabel          matlab.ui.control.Label
        ParametersEditField             matlab.ui.control.NumericEditField
        ParametersEditFieldLabel        matlab.ui.control.Label
        GridColumnsEditField            matlab.ui.control.NumericEditField
        GridColumnsEditFieldLabel       matlab.ui.control.Label
        SendtoROImanagerCheckBox        matlab.ui.control.CheckBox
        CancelButton                    matlab.ui.control.Button
        OKButton                        matlab.ui.control.Button
        PathtoimageEditField            matlab.ui.control.EditField
        PathtoimageEditFieldLabel       matlab.ui.control.Label
        DefaultparametersCheckBox       matlab.ui.control.CheckBox
        ImagetypeDropDown               matlab.ui.control.DropDown
        ImagetypeDropDownLabel          matlab.ui.control.Label
        AnnotationMethodsDropDown       matlab.ui.control.DropDown
        AnnotationMethodsDropDownLabel  matlab.ui.control.Label
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        parameterOptions = struct('imagePath','','imageName','','imageType','HE bright field',...
            'method','ranking', 'gridColumn', 50,'gridRow', 50,'parameter_threshold',5,... 
            'defaultParameters',1,'sendtoROImanager',1);
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp)
            app.CallingApp = mainApp;
            app.parameterOptions.imagePath = pwd;%mainApp.CAPannotations.imagePath;
            app.parameterOptions.imageName = mainApp.CAPannotations.imageName;
            app.PathtoimageEditField.Value = fullfile(app.parameterOptions.imagePath,...
               app.parameterOptions.imageName);
            
        end

        % Callback function: ImagetypeDropDown, ImagetypeDropDown
        function ImagetypeDropDownValueChanged(app, event)
            value = app.ImagetypeDropDown.Value;
            app.parameterOptions.imageType = app.ImagetypeDropDown.Value;
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            delete(app)
        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            app.CallingApp.figureOptions.plotAnnotations = 1;
            app.CallingApp.plotImage_public;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create TumorRegionDetectionoptionsUIFigure and hide until all components are created
            app.TumorRegionDetectionoptionsUIFigure = uifigure('Visible', 'off');
            app.TumorRegionDetectionoptionsUIFigure.Position = [100 100 519 453];
            app.TumorRegionDetectionoptionsUIFigure.Name = 'Tumor Region Detection-options';

            % Create AnnotationMethodsDropDownLabel
            app.AnnotationMethodsDropDownLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.AnnotationMethodsDropDownLabel.HorizontalAlignment = 'right';
            app.AnnotationMethodsDropDownLabel.Position = [60 299 114 22];
            app.AnnotationMethodsDropDownLabel.Text = 'Annotation Methods';

            % Create AnnotationMethodsDropDown
            app.AnnotationMethodsDropDown = uidropdown(app.TumorRegionDetectionoptionsUIFigure);
            app.AnnotationMethodsDropDown.Items = {'Ranking', 'Area threshold (in Pixels)', 'Distance Based'};
            app.AnnotationMethodsDropDown.Position = [210 299 173 22];
            app.AnnotationMethodsDropDown.Value = 'Ranking';

            % Create ImagetypeDropDownLabel
            app.ImagetypeDropDownLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.ImagetypeDropDownLabel.HorizontalAlignment = 'right';
            app.ImagetypeDropDownLabel.Position = [60 335 65 22];
            app.ImagetypeDropDownLabel.Text = 'Image type';

            % Create ImagetypeDropDown
            app.ImagetypeDropDown = uidropdown(app.TumorRegionDetectionoptionsUIFigure);
            app.ImagetypeDropDown.Items = {'H&E', 'Single channel', 'Two-channel', 'Others'};
            app.ImagetypeDropDown.DropDownOpeningFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.Position = [210 335 173 22];
            app.ImagetypeDropDown.Value = 'H&E';

            % Create DefaultparametersCheckBox
            app.DefaultparametersCheckBox = uicheckbox(app.TumorRegionDetectionoptionsUIFigure);
            app.DefaultparametersCheckBox.Text = 'Default parameters';
            app.DefaultparametersCheckBox.Position = [112 108 124 22];
            app.DefaultparametersCheckBox.Value = true;

            % Create PathtoimageEditFieldLabel
            app.PathtoimageEditFieldLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.PathtoimageEditFieldLabel.HorizontalAlignment = 'right';
            app.PathtoimageEditFieldLabel.Position = [60 387 80 22];
            app.PathtoimageEditFieldLabel.Text = 'Path to image';

            % Create PathtoimageEditField
            app.PathtoimageEditField = uieditfield(app.TumorRegionDetectionoptionsUIFigure, 'text');
            app.PathtoimageEditField.Editable = 'off';
            app.PathtoimageEditField.Position = [174 373 283 36];

            % Create OKButton
            app.OKButton = uibutton(app.TumorRegionDetectionoptionsUIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [404 28 100 22];
            app.OKButton.Text = 'OK';

            % Create CancelButton
            app.CancelButton = uibutton(app.TumorRegionDetectionoptionsUIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [270 28 100 22];
            app.CancelButton.Text = 'Cancel';

            % Create SendtoROImanagerCheckBox
            app.SendtoROImanagerCheckBox = uicheckbox(app.TumorRegionDetectionoptionsUIFigure);
            app.SendtoROImanagerCheckBox.Text = 'Send to ROI manager';
            app.SendtoROImanagerCheckBox.Position = [280 108 138 22];
            app.SendtoROImanagerCheckBox.Value = true;

            % Create GridColumnsEditFieldLabel
            app.GridColumnsEditFieldLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.GridColumnsEditFieldLabel.HorizontalAlignment = 'right';
            app.GridColumnsEditFieldLabel.Position = [60 252 80 22];
            app.GridColumnsEditFieldLabel.Text = 'Grid Columns';

            % Create GridColumnsEditField
            app.GridColumnsEditField = uieditfield(app.TumorRegionDetectionoptionsUIFigure, 'numeric');
            app.GridColumnsEditField.Position = [176 253 35 22];
            app.GridColumnsEditField.Value = 50;

            % Create ParametersEditFieldLabel
            app.ParametersEditFieldLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.ParametersEditFieldLabel.HorizontalAlignment = 'right';
            app.ParametersEditFieldLabel.Position = [60 173 67 22];
            app.ParametersEditFieldLabel.Text = 'Parameters';

            % Create ParametersEditField
            app.ParametersEditField = uieditfield(app.TumorRegionDetectionoptionsUIFigure, 'numeric');
            app.ParametersEditField.Position = [178 173 33 22];
            app.ParametersEditField.Value = 5;

            % Create GridRowsEditFieldLabel
            app.GridRowsEditFieldLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.GridRowsEditFieldLabel.HorizontalAlignment = 'right';
            app.GridRowsEditFieldLabel.Position = [60 212 62 22];
            app.GridRowsEditFieldLabel.Text = 'Grid Rows';

            % Create GridRowsEditField
            app.GridRowsEditField = uieditfield(app.TumorRegionDetectionoptionsUIFigure, 'numeric');
            app.GridRowsEditField.Position = [178 212 36 22];
            app.GridRowsEditField.Value = 50;

            % Create SliderGridCol
            app.SliderGridCol = uislider(app.TumorRegionDetectionoptionsUIFigure);
            app.SliderGridCol.Position = [235 271 170 3];
            app.SliderGridCol.Value = 50;

            % Create SliderGrideRow
            app.SliderGrideRow = uislider(app.TumorRegionDetectionoptionsUIFigure);
            app.SliderGrideRow.Position = [235 222 170 3];
            app.SliderGrideRow.Value = 50;

            % Create SliderDensityParameter
            app.SliderDensityParameter = uislider(app.TumorRegionDetectionoptionsUIFigure);
            app.SliderDensityParameter.Limits = [0 10];
            app.SliderDensityParameter.MajorTicks = [0 2 4 6 8 10];
            app.SliderDensityParameter.MajorTickLabels = {'0', '2', '4', '6', '8', '10'};
            app.SliderDensityParameter.MinorTicks = [1 2 3 4 5 6 7 8 9 10];
            app.SliderDensityParameter.Position = [235 183 170 3];
            app.SliderDensityParameter.Value = 5;

            % Show the figure after all components are created
            app.TumorRegionDetectionoptionsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TumorRegionAnnotationGUI_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TumorRegionDetectionoptionsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TumorRegionDetectionoptionsUIFigure)
        end
    end
end