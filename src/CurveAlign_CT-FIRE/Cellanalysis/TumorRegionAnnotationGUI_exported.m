classdef TumorRegionAnnotationGUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TumorRegionDetectionoptionsUIFigure  matlab.ui.Figure
        SliderDensityParameter          matlab.ui.control.Slider
        SliderGridRow                   matlab.ui.control.Slider
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
            app.parameterOptions.imagePath = mainApp.imagePath;
            app.parameterOptions.imageName = mainApp.imageName;
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
            %         parameterOptions = struct('imagePath','','imageName','','imageType','HE bright field',...
            %             'method','ranking', 'gridColumn', 50,'gridRow', 50,'parameter_threshold',5,...
            %             'defaultParameters',1,'sendtoROImanager',1);
            if ~strcmp(app.parameterOptions.imageType,'HE bright field')
                disp('Only available for HE bright field images so far')
                return
            end
%              parameterOptions = struct('imagePath','','imageName','','imageType','HE bright field',...
%             'method','ranking', 'gridColumn', 50,'gridRow', 50,'parameter_threshold',5,... 
%             'defaultParameters',1,'sendtoROImanager',1);
            gridCols = app.parameterOptions.gridColumn;
            gridRows = app.parameterOptions.gridRow;
            thresholdP = app.parameterOptions.parameter_threshold;
            % three options
            % 1-Ranking
            % 2-Area threshold (in Pixels)
            % 3-Distance Based
            if strcmp(app.AnnotationMethodsDropDown.Value,'Ranking')
               % thresholdValue = app.ParametersEditField.Value;
                turmorDetected = imageCardTumor(app.CallingApp.imageName,'Rank',...
                    [gridCols gridRows],thresholdP);
            elseif strcmp(app.AnnotationMethodsDropDown.Value,'Area threshold (in Pixels)')
               % thresholdValue = app.ParametersEditField.Value;
                turmorDetected = imageCardTumor(app.CallingApp.imageName,'Thres',...
                    [gridCols gridRows],thresholdP);
            elseif strcmp(app.AnnotationMethodsDropDown.Value,'Distance Based')
                % thresholdValue = app.ParametersEditField.Value;
                turmorDetected = imageCardTumor(app.CallingApp.imageName,'Radius',...
                    [gridCols gridRows],nan,thresholdP);
            else
                fprintf('This tumor annotation method-%s is not available \ n',app.AnnotationMethodsDropDown.Value)
                return
            end
            % add more annotation properties in the main program
            app.CallingApp.CAPannotations.tumorAnnotations.tumorArray = turmorDetected.tumorArray;
            annotationNumber = size (app.CallingApp.CAPannotations.tumorAnnotations.tumorArray,2);
            % statsArray = cell(1,annotationNumber); % struct('Mask','','Centroid','','Area','','Perimeter','')
            % nrow = app.CallingApp.CAPimage.imageInfo.Height;
            % ncol = app.CallingApp.CAPimage.imageInfo.Width;
            % for i = 1: annotationNumber
            %     tumorData = app.CallingApp.CAPannotations.tumorAnnotations.tumorArray(1,i);
            %     tumorBoundaryCol = tumorData.boundary(:,2);
            %     tumorBoundaryRow = tumorData.boundary(:,1);    
            %     tumorMask = poly2mask(tumorBoundaryCol,tumorBoundaryRow,nrow,ncol);
            %     stats = regionprops(tumorMask,'Centroid','Area','Perimeter','Orientation');
            %     statsArray{1,i}.Mask = tumorMask;
            %     statsArray{1,i}.Centroid = stats.Centroid;
            %     statsArray{1,i}.Area = stats.Area;
            %     statsArray{1,i}.Perimeter = stats.Perimeter;
            %     statsArray{1,i}.Orientation = stats.Orientation;
            % end
            % app.CallingApp.CAPannotations.tumorAnnotations.statsArray = statsArray;
            app.CallingApp.annotationView.Type = repmat({'tumor'},annotationNumber,1);
            app.CallingApp.annotationType = 'tumor';
            app.CallingApp.figureOptions.plotImage =0;
            app.CallingApp.figureOptions.plotObjects =0;
            app.CallingApp.figureOptions.plotAnnotations = 1;
            % delete fibers if exist
            if ~isempty (app.CallingApp.fibersView.fiberH1)
                fiberNumber =  size(app.CallingApp.fibersView.fiberH1,1);
                for i= 1: fiberNumber
                    delete(app.CallingApp.fibersView.fiberH1{i,1});
                end
            end
            app.CallingApp.plotImage_public;
            app.CallingApp.TabGroup.SelectedTab = app.CallingApp.ROImanagerTab;

        end

        % Value changed function: SliderDensityParameter
        function SliderDensityParameterValueChanged(app, event)
            value = app.SliderDensityParameter.Value;
            app.SliderDensityParameter.Value = round(value);
            app.parameterOptions.parameter_threshold =  app.SliderDensityParameter.Value;
            app.ParametersEditField.Value = app.SliderDensityParameter.Value;
        end

        % Value changed function: SliderGridCol
        function SliderGridColValueChanged(app, event)
            value = app.SliderGridCol.Value;                      
            app.SliderGridCol.Value = round(value);
            app.parameterOptions.gridColumn =  app.SliderGridCol.Value;
            app.GridColumnsEditField.Value = app.SliderGridCol.Value;
        end

        % Value changed function: SliderGridRow
        function SliderGridRowValueChanged(app, event)
            value = app.SliderGridRow.Value;
            app.SliderGridRow.Value = round(value);
            app.parameterOptions.gridRow =  app.SliderGridRow.Value;
            app.GridRowsEditField.Value = app.SliderGridRow.Value;
        end

        % Value changed function: GridRowsEditField
        function GridRowsEditFieldValueChanged(app, event)
            value = app.GridRowsEditField.Value;
            app.SliderGridRow.Value = value; 
            app.parameterOptions.gridRow =  app.SliderGridRow.Value;
        end

        % Value changed function: GridColumnsEditField
        function GridColumnsEditFieldValueChanged(app, event)
            value = app.GridColumnsEditField.Value;
            app.SliderGridCol.Value = value;
            app.parameterOptions.gridColumn =  app.SliderGridCol.Value;
        end

        % Value changed function: ParametersEditField
        function ParametersEditFieldValueChanged(app, event)
            value = app.ParametersEditField.Value;
            app.SliderDensityParameter.Value = value;
            app.parameterOptions.parameter_threshold =  app.SliderDensityParameter.Value;
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
            app.ImagetypeDropDown.Items = {'HE bright field', 'Fluorescence_1-Channel', 'Fluorescence_2-Channel', 'Two-channel', 'Phase contrast', 'Gray scale'};
            app.ImagetypeDropDown.DropDownOpeningFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.Position = [210 335 173 22];
            app.ImagetypeDropDown.Value = 'HE bright field';

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
            app.GridColumnsEditField.ValueChangedFcn = createCallbackFcn(app, @GridColumnsEditFieldValueChanged, true);
            app.GridColumnsEditField.Position = [176 253 35 22];
            app.GridColumnsEditField.Value = 50;

            % Create ParametersEditFieldLabel
            app.ParametersEditFieldLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.ParametersEditFieldLabel.HorizontalAlignment = 'right';
            app.ParametersEditFieldLabel.Position = [60 173 67 22];
            app.ParametersEditFieldLabel.Text = 'Parameters';

            % Create ParametersEditField
            app.ParametersEditField = uieditfield(app.TumorRegionDetectionoptionsUIFigure, 'numeric');
            app.ParametersEditField.ValueChangedFcn = createCallbackFcn(app, @ParametersEditFieldValueChanged, true);
            app.ParametersEditField.Position = [178 173 33 22];
            app.ParametersEditField.Value = 5;

            % Create GridRowsEditFieldLabel
            app.GridRowsEditFieldLabel = uilabel(app.TumorRegionDetectionoptionsUIFigure);
            app.GridRowsEditFieldLabel.HorizontalAlignment = 'right';
            app.GridRowsEditFieldLabel.Position = [60 212 62 22];
            app.GridRowsEditFieldLabel.Text = 'Grid Rows';

            % Create GridRowsEditField
            app.GridRowsEditField = uieditfield(app.TumorRegionDetectionoptionsUIFigure, 'numeric');
            app.GridRowsEditField.ValueChangedFcn = createCallbackFcn(app, @GridRowsEditFieldValueChanged, true);
            app.GridRowsEditField.Position = [178 212 36 22];
            app.GridRowsEditField.Value = 50;

            % Create SliderGridCol
            app.SliderGridCol = uislider(app.TumorRegionDetectionoptionsUIFigure);
            app.SliderGridCol.ValueChangedFcn = createCallbackFcn(app, @SliderGridColValueChanged, true);
            app.SliderGridCol.Position = [235 271 245 3];
            app.SliderGridCol.Value = 50;

            % Create SliderGridRow
            app.SliderGridRow = uislider(app.TumorRegionDetectionoptionsUIFigure);
            app.SliderGridRow.ValueChangedFcn = createCallbackFcn(app, @SliderGridRowValueChanged, true);
            app.SliderGridRow.Position = [235 222 245 3];
            app.SliderGridRow.Value = 50;

            % Create SliderDensityParameter
            app.SliderDensityParameter = uislider(app.TumorRegionDetectionoptionsUIFigure);
            app.SliderDensityParameter.Limits = [0 20];
            app.SliderDensityParameter.MajorTicks = [0 5 10 15 20];
            app.SliderDensityParameter.MajorTickLabels = {'0', '5', '10', '15', '20'};
            app.SliderDensityParameter.ValueChangedFcn = createCallbackFcn(app, @SliderDensityParameterValueChanged, true);
            app.SliderDensityParameter.MinorTicks = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
            app.SliderDensityParameter.Position = [235 183 245 3];
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