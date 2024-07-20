classdef cellanalysisGUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CellAnalysisoptionsUIFigure     matlab.ui.Figure
        ParametersPanel                 matlab.ui.container.Panel
        OverlapThresholdEditField       matlab.ui.control.NumericEditField
        OverlapThresholdEditFieldLabel  matlab.ui.control.Label
        ProbablilityThresholdEditField  matlab.ui.control.NumericEditField
        ProbablilityThresholdEditFieldLabel  matlab.ui.control.Label
        AdvancedButton                  matlab.ui.control.Button
        MicronPerPixelEditField         matlab.ui.control.NumericEditField
        MicronPerPixelEditFieldLabel    matlab.ui.control.Label
        CellDiameterpixelsEditField     matlab.ui.control.NumericEditField
        CellDiameterpixelsEditFieldLabel  matlab.ui.control.Label
        PercentHighEditField            matlab.ui.control.NumericEditField
        PercentHighEditFieldLabel       matlab.ui.control.Label
        PercentLowEditField             matlab.ui.control.NumericEditField
        PercentLowEditFieldLabel        matlab.ui.control.Label
        NormalizationCheckBox           matlab.ui.control.CheckBox
        ScalingEditField                matlab.ui.control.NumericEditField
        ScalingEditFieldLabel           matlab.ui.control.Label
        SendtoROImanagerCheckBox        matlab.ui.control.CheckBox
        CancelButton                    matlab.ui.control.Button
        OKButton                        matlab.ui.control.Button
        ModelevaluationCheckBox         matlab.ui.control.CheckBox
        PathtoimageEditField            matlab.ui.control.EditField
        PathtoimageEditFieldLabel       matlab.ui.control.Label
        DefaultparametersCheckBox       matlab.ui.control.CheckBox
        PretrainedmodelsDropDown        matlab.ui.control.DropDown
        PretrainedmodelsDropDownLabel   matlab.ui.control.Label
        MethodsDropDown                 matlab.ui.control.DropDown
        MethodsDropDownLabel            matlab.ui.control.Label
        ImagetypeDropDown               matlab.ui.control.DropDown
        ImagetypeDropDownLabel          matlab.ui.control.Label
        ObjecttypeDropDown              matlab.ui.control.DropDown
        ObjecttypeDropDownLabel         matlab.ui.control.Label
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        parameterOptions = struct('imagePath','','imageName','','imageType','HE bright field',...
            'objectType','Nuclei','deeplearningMethod','StarDist', 'pre_trainedModel', '2D_versatile_he',...
            'parameters_type','simple','defaultParameters',1,'modelEvaluation',0,'sendtoROImanager',1);
            % 'scaling_factor', app.ScalingEditField.Value, 'normalizationFlag', app.NormalizationCheckBox.Value, ...
            % 'percentile-Low',app.PercentLowEditField.Value,'percentile_high',app.PercentHighEditField.Value, ...
            % 'prob_thresh',app.ProbablilityThresholdEditField.Value,'nms_threshold',app.OverlapThresholdEditField.Value, ...
            % 'cellDiameter',app.CellDiameterpixelsEditField.Value,'pixelpermicron',app.MicronPerPixelEditField.Value);
        preTrainedModels_cellpose = {'cyto','cyto2','cyto3','nuclei',...
                    'tissuenet_cp3','livecell_cp3','yeast_PhC_cp3','yeast_BF_cp3','bact_phase_cp3',...
                    'bact_fluor_cp3','deepbacs_cp3','cyto2_cp3'};
        preTrainedModels_deepcell = {'cyto','nuclei','tissuenet'};
        object_type = {'Nuclei','Cytoplasm','All'}
        preTrainedModelIndex = 1;

    end
    
    properties (Access = private)
        Property6 % Description
    end
    
    methods (Access = private)
        
        function parametersControloff(app)
            app.ScalingEditField.Enable = 'off';
            app.NormalizationCheckBox.Enable = 'off';
            app.PercentLowEditField.Enable = 'off';
            app.PercentHighEditField.Enable = 'off';
            app.ProbablilityThresholdEditField.Enable = 'off';
            app.OverlapThresholdEditField.Enable = 'off';
            app.CellDiameterpixelsEditField.Enable = 'off';
            app.MicronPerPixelEditField.Enable = 'off';
            app.setDefaultParameters
        end
        
        
        function setDefaultParameters(app)
            app.ScalingEditField.Value = 1;
            app.NormalizationCheckBox.Value = 1;
            app.PercentLowEditField.Value = 1;
            app.PercentHighEditField.Value = 99.8;
            app.ProbablilityThresholdEditField.Value = 0.5;
            app.OverlapThresholdEditField.Value = 0.4;
            app.CellDiameterpixelsEditField.Value = 30;
            app.MicronPerPixelEditField.Value = 1;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp)
            app.CallingApp = mainApp;
            app.CallingApp.CAPimage.CellanalsysisMethod = app.MethodsDropDown.Value;
            app.parameterOptions.imagePath = mainApp.CAPimage.imagePath;
            app.parameterOptions.imageName = mainApp.CAPimage.imageName;
            app.PathtoimageEditField.Value = fullfile(app.parameterOptions.imagePath,...
               app.parameterOptions.imageName);
            app.parameterOptions.pre_trainedModel = app.PretrainedmodelsDropDown.Value;
            app.parameterOptions.deeplearningMethod =  app.MethodsDropDown.Value;
            app.parametersControloff;
            
        end

        % Callback function: ImagetypeDropDown, ImagetypeDropDown
        function ImagetypeDropDownValueChanged(app, event)
            % HE bright field
            % Fluorescence_1-channel
            % Fluorescence-2-channel
            % Phase contrast
            % Gray scale
            value = app.ImagetypeDropDown.Value;
            app.parameterOptions.imageType = app.ImagetypeDropDown.Value;
            if strcmp(value,'HE bright field')
                app.MethodsDropDown.Value = 'StarDist';
            else
                app.MethodsDropDown.Value = 'Cellpose';
            end
            % app.parameterOptions.deeplearningMethod = app.MethodsDropDown.Value;
            app.MethodsDropDownValueChanged;

        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            delete(app)
        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            imageName = app.parameterOptions.imageName;
            imagePath = app.parameterOptions.imagePath;
            imageType = app.parameterOptions.imageType;
            objectType = app.parameterOptions.objectType;
            deepMethod = app.parameterOptions.deeplearningMethod;
            deepModel = app.parameterOptions.pre_trainedModel;
            default_parameters_flag = app.DefaultparametersCheckBox.Value;%app.parameterOptions.defaultParameters;

            if strcmp (deepMethod,'StarDist')
                samplingFactor = app.ScalingEditField.Value;
                stardistParameters = struct('deepMethod',deepMethod,'modelName',deepModel,...
                    'defaultParametersFlag',default_parameters_flag,...
                    'prob_thresh',app.ProbablilityThresholdEditField.Value, ...
                    'nms_threshold',app.OverlapThresholdEditField.Value, ...
                    'Normalization_lowPercentile',app.PercentLowEditField.Value,...
                    'Normalization_highPercentile',app.PercentHighEditField.Value);
                app.parameterOptions.modelParameters = stardistParameters;
                cellsStarDist = imageCard(imageName,imagePath,samplingFactor,stardistParameters);
                app.CallingApp.CAPobjects.cells = cellsStarDist;  
                app.CallingApp.figureOptions.plotImage = 0;
                app.CallingApp.figureOptions.plotObjects = 1;
                app.CallingApp.plotImage_public;
            elseif strcmp (deepMethod,'Cellpose') 
                cellposeParameters = struct('deepMethod',deepMethod,'modelName',deepModel,...
                    'defaultParametersFlag',default_parameters_flag,...
                    'CellDiameter',app.CellDiameterpixelsEditField.Value);
               if  strcmp(imageType,'HE bright field')
                   fprintf('current image type is : %s \n Open Fluorescence image or phase contrast image to proceed \n',imageType);
                   return
               end
               
               try
                   if strcmp (objectType,'Cytoplasm')
                       cellsCellpose = imgCardWholeCell(imageName,imagePath,cellposeParameters);
                       app.CallingApp.CAPobjects.cells = cellsCellpose;
                   else
                       fprintf('Cell analysis by %s for %s is not available. \n', deepMethod,objectType) ;
                       return
                   end
               catch IM
                   fprintf('Cell analysis is skipped. Error message: %s. \n', IM.message);
                   return
               end
               app.CallingApp.CAPimage.CellanalysisMethod = deepMethod;
               app.CallingApp.figureOptions.plotObjects = 1;
               app.CallingApp.plotImage_public;
            elseif strcmp (deepMethod,'DeepCell') 
                deepcellParameters = struct('deepMethod',deepMethod,'modelName',deepModel,...
                    'defaultParametersFlag',default_parameters_flag,...
                    'img_mpp',app.MicronPerPixelEditField.Value);
               if  strcmp(imageType,'HE bright field')
                   fprintf('current image type is : %s \n Open Fluorescence image or phase contrast image to proceed \n',imageType);
                   return
               end
               
               try
                   if strcmp (objectType,'Cytoplasm')
                       cellsDeepCell = imgCardWholeCell(imageName,imagePath,[],deepcellParameters);
                       app.CallingApp.CAPobjects.cells = cellsDeepCell;
                   else
                       fprintf('Cell analysis by %s for %s is not available. \n', deepMethod,objectType) ;
                       return
                   end
               catch IM
                   fprintf('Cell analysis is skipped. Error message: %s. \n', IM.message);
                   return
               end
               app.CallingApp.CAPimage.CellanalysisMethod = deepMethod;
               app.CallingApp.figureOptions.plotObjects = 1;
               app.CallingApp.plotImage_public;
               app.CallingApp.TabGroup.SelectedTab = app.CallingApp.ROImanagerTab;
            elseif strcmp (deepMethod,'FromMaskfiles-SD')
                try
                    if strcmp(objectType,'Nuclei') 
                        app.parameterOptions.modelParameters = stardistParameters;
                        cellsStarDist = imageCard(imageName,imagePath,samplingFactor,stardistParameters);
                        app.CallingApp.CAPobjects.cells = cellsStarDist;
                    else
                        disp('Only support mask files(labels_sd.mat and details_sd.mat) from StarDist')
                    end
                catch IM
                    fprintf('Cell analysis is skipped. Error message: %s. \n', IM.message);
                    return
                end
                app.CallingApp.CAPimage.CellanalysisMethod = deepMethod;
                app.CallingApp.figureOptions.plotObjects = 1;
                app.CallingApp.plotImage_public;
            elseif strcmp (deepMethod,'FromMask-others')
                try
                    if strcmp (objectType,'Cytoplasm')
                        preTrained = app.parameterOptions.pre_trainedModel;
                        cellsCellpose = imgCardWholeCell(deepMethod,imageName,imagePath,preTrained);
                        app.CallingApp.CAPobjects.cells = cellsCellpose;
                    % else strcmp(objectType,'Nuclei')
                    %     cellsStarDist = imageCard(imageName,imagePath,samplingFactor,stardistParameters);
                    %     app.CallingApp.CAPobjects.cells = cellsStarDist;
                    end
                catch IM
                    fprintf('Cell analysis is skipped. Error message: %s. \n', IM.message);
                    return
                end
                app.CallingApp.CAPimage.CellanalysisMethod = deepMethod;
                app.CallingApp.figureOptions.plotObjects = 1;
                app.CallingApp.plotImage_public;
               
            else
                fprintf('Cell analysis NOT available for this method yet: %s \n', deepMethod)
            end
            app.CallingApp.TabGroup.SelectedTab = app.CallingApp.ROImanagerTab;
        end

        % Value changed function: MethodsDropDown
        function MethodsDropDownValueChanged(app, event)
            value = app.MethodsDropDown.Value;
            app.parameterOptions.deeplearningMethod = value;
            if strcmp(app.parameterOptions.deeplearningMethod,'StarDist')
                if strcmp(app.parameterOptions.imageType,'HE bright field')
                    app.PretrainedmodelsDropDown.Items = {'2D_versatile_he'};
                else
                    app.PretrainedmodelsDropDown.Items= {'2D_versatile_fluo','2D_paper_dsb2018'};
                end
            elseif strcmp(app.parameterOptions.deeplearningMethod,'Cellpose')
                % app.PretrainedmodelsDropDown.Items = {'Cellpose generalized model'};
                app.PretrainedmodelsDropDown.Items = app.preTrainedModels_cellpose;
                app.ObjecttypeDropDown.Value = app.ObjecttypeDropDown.Items{2}; % Cytoplasm
                app.parameterOptions.objectType = app.ObjecttypeDropDown.Value;
            elseif strcmp(app.parameterOptions.deeplearningMethod,'DeepCell')
                app.PretrainedmodelsDropDown.Items = app.preTrainedModels_deepcell;
            else
                app.PretrainedmodelsDropDown.Items = {'Not specified'};
            end
            app.PretrainedmodelsDropDownValueChanged;
            app.DefaultparametersCheckBox.Value = 1;
            app.parametersControloff;
        end

        % Value changed function: ObjecttypeDropDown
        function ObjecttypeDropDownValueChanged(app, event)
            value = app.ObjecttypeDropDown.Value;
            app.parameterOptions.objectType = value;
        end

        % Value changed function: PretrainedmodelsDropDown
        function PretrainedmodelsDropDownValueChanged(app, event)
             app.parameterOptions.pre_trainedModel = app.PretrainedmodelsDropDown.Value;
        end

        % Value changed function: DefaultparametersCheckBox
        function DefaultparametersCheckBoxValueChanged(app, event)
            value = app.DefaultparametersCheckBox.Value;
            if value == 1
                app.ParametersPanel.Enable = 'off';
                app.parametersControloff;
            else  % customized parameters
                app.ParametersPanel.Enable = 'on';
                if strcmp(app.parameterOptions.deeplearningMethod,'StarDist')
                    app.ScalingEditField.Enable = 'on';
                    app.NormalizationCheckBox.Enable = 'on';
                    app.PercentLowEditField.Enable = 'on';
                    app.PercentHighEditField.Enable = 'on';
                    app.ScalingEditFieldLabel.Enable = 'on';
                    app.PercentLowEditFieldLabel.Enable = 'on';
                    app.PercentHighEditFieldLabel.Enable = 'on';
                    app.ProbablilityThresholdEditField.Enable = 'on';
                    app.ProbablilityThresholdEditFieldLabel.Enable='on';
                    app.OverlapThresholdEditField.Enable = 'on';
                    app.OverlapThresholdEditFieldLabel.Enable = 'on';
                elseif strcmp(app.parameterOptions.deeplearningMethod,'Cellpose')
                    app.CellDiameterpixelsEditField.Enable = 'on';
                    app.CellDiameterpixelsEditFieldLabel.Enable = 'on';
                elseif strcmp(app.parameterOptions.deeplearningMethod,'DeepCell')
                    app.MicronPerPixelEditField.Enable = 'on';
                    app.MicronPerPixelEditFieldLabel.Enable = 'on';
                else % other methods
                    app.parametersControloff;
                end
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CellAnalysisoptionsUIFigure and hide until all components are created
            app.CellAnalysisoptionsUIFigure = uifigure('Visible', 'off');
            app.CellAnalysisoptionsUIFigure.Position = [100 100 535 515];
            app.CellAnalysisoptionsUIFigure.Name = 'Cell Analysis-options';

            % Create ObjecttypeDropDownLabel
            app.ObjecttypeDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.ObjecttypeDropDownLabel.HorizontalAlignment = 'right';
            app.ObjecttypeDropDownLabel.Position = [86 360 68 22];
            app.ObjecttypeDropDownLabel.Text = 'Object type';

            % Create ObjecttypeDropDown
            app.ObjecttypeDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.ObjecttypeDropDown.Items = {'Nuclei', 'Cytoplasm', 'All'};
            app.ObjecttypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ObjecttypeDropDownValueChanged, true);
            app.ObjecttypeDropDown.Position = [200 360 200 22];
            app.ObjecttypeDropDown.Value = 'Nuclei';

            % Create ImagetypeDropDownLabel
            app.ImagetypeDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.ImagetypeDropDownLabel.HorizontalAlignment = 'right';
            app.ImagetypeDropDownLabel.Position = [86 413 65 22];
            app.ImagetypeDropDownLabel.Text = 'Image type';

            % Create ImagetypeDropDown
            app.ImagetypeDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.ImagetypeDropDown.Items = {'HE bright field', 'Fluorescence_1-channel', 'Phase contrast', 'Gray scale'};
            app.ImagetypeDropDown.DropDownOpeningFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.Position = [201 413 200 22];
            app.ImagetypeDropDown.Value = 'HE bright field';

            % Create MethodsDropDownLabel
            app.MethodsDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.MethodsDropDownLabel.HorizontalAlignment = 'right';
            app.MethodsDropDownLabel.Position = [86 308 53 22];
            app.MethodsDropDownLabel.Text = 'Methods';

            % Create MethodsDropDown
            app.MethodsDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.MethodsDropDown.Items = {'StarDist', 'Cellpose', 'DeepCell', 'FromMaskfiles-SD', 'FromMask-others'};
            app.MethodsDropDown.ValueChangedFcn = createCallbackFcn(app, @MethodsDropDownValueChanged, true);
            app.MethodsDropDown.Position = [201 308 200 22];
            app.MethodsDropDown.Value = 'StarDist';

            % Create PretrainedmodelsDropDownLabel
            app.PretrainedmodelsDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.PretrainedmodelsDropDownLabel.HorizontalAlignment = 'right';
            app.PretrainedmodelsDropDownLabel.Position = [75 256 113 22];
            app.PretrainedmodelsDropDownLabel.Text = 'Pre-trained models';

            % Create PretrainedmodelsDropDown
            app.PretrainedmodelsDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.PretrainedmodelsDropDown.Items = {'2D_versatile_he'};
            app.PretrainedmodelsDropDown.ValueChangedFcn = createCallbackFcn(app, @PretrainedmodelsDropDownValueChanged, true);
            app.PretrainedmodelsDropDown.Position = [203 256 199 22];
            app.PretrainedmodelsDropDown.Value = '2D_versatile_he';

            % Create DefaultparametersCheckBox
            app.DefaultparametersCheckBox = uicheckbox(app.CellAnalysisoptionsUIFigure);
            app.DefaultparametersCheckBox.ValueChangedFcn = createCallbackFcn(app, @DefaultparametersCheckBoxValueChanged, true);
            app.DefaultparametersCheckBox.Text = 'Default parameters';
            app.DefaultparametersCheckBox.Position = [87 49 124 22];
            app.DefaultparametersCheckBox.Value = true;

            % Create PathtoimageEditFieldLabel
            app.PathtoimageEditFieldLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.PathtoimageEditFieldLabel.HorizontalAlignment = 'right';
            app.PathtoimageEditFieldLabel.Position = [86 465 80 22];
            app.PathtoimageEditFieldLabel.Text = 'Path to image';

            % Create PathtoimageEditField
            app.PathtoimageEditField = uieditfield(app.CellAnalysisoptionsUIFigure, 'text');
            app.PathtoimageEditField.Editable = 'off';
            app.PathtoimageEditField.Position = [200 451 262 36];

            % Create ModelevaluationCheckBox
            app.ModelevaluationCheckBox = uicheckbox(app.CellAnalysisoptionsUIFigure);
            app.ModelevaluationCheckBox.Enable = 'off';
            app.ModelevaluationCheckBox.Text = 'Model evaluation';
            app.ModelevaluationCheckBox.Position = [233 49 114 22];

            % Create OKButton
            app.OKButton = uibutton(app.CellAnalysisoptionsUIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [409 11 100 22];
            app.OKButton.Text = 'OK';

            % Create CancelButton
            app.CancelButton = uibutton(app.CellAnalysisoptionsUIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [296 11 100 22];
            app.CancelButton.Text = 'Cancel';

            % Create SendtoROImanagerCheckBox
            app.SendtoROImanagerCheckBox = uicheckbox(app.CellAnalysisoptionsUIFigure);
            app.SendtoROImanagerCheckBox.Enable = 'off';
            app.SendtoROImanagerCheckBox.Text = 'Send to ROI manager';
            app.SendtoROImanagerCheckBox.Position = [355 49 138 22];
            app.SendtoROImanagerCheckBox.Value = true;

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.CellAnalysisoptionsUIFigure);
            app.ParametersPanel.Title = 'Parameters';
            app.ParametersPanel.Position = [16 85 493 155];

            % Create ScalingEditFieldLabel
            app.ScalingEditFieldLabel = uilabel(app.ParametersPanel);
            app.ScalingEditFieldLabel.HorizontalAlignment = 'right';
            app.ScalingEditFieldLabel.Enable = 'off';
            app.ScalingEditFieldLabel.Position = [3 99 44 22];
            app.ScalingEditFieldLabel.Text = 'Scaling';

            % Create ScalingEditField
            app.ScalingEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.ScalingEditField.Limits = [0.1 5];
            app.ScalingEditField.Enable = 'off';
            app.ScalingEditField.Tooltip = {'StarDist, resize an image with the scaling factor'};
            app.ScalingEditField.Position = [62 99 28 22];
            app.ScalingEditField.Value = 1;

            % Create NormalizationCheckBox
            app.NormalizationCheckBox = uicheckbox(app.ParametersPanel);
            app.NormalizationCheckBox.Enable = 'off';
            app.NormalizationCheckBox.Tooltip = {'StarDist, normalize an image'};
            app.NormalizationCheckBox.Text = 'Normalization ';
            app.NormalizationCheckBox.Position = [107 99 99 22];
            app.NormalizationCheckBox.Value = true;

            % Create PercentLowEditFieldLabel
            app.PercentLowEditFieldLabel = uilabel(app.ParametersPanel);
            app.PercentLowEditFieldLabel.HorizontalAlignment = 'right';
            app.PercentLowEditFieldLabel.Enable = 'off';
            app.PercentLowEditFieldLabel.Tooltip = {'StarDist, percentile low'};
            app.PercentLowEditFieldLabel.Position = [230 99 72 22];
            app.PercentLowEditFieldLabel.Text = 'Percent-Low';

            % Create PercentLowEditField
            app.PercentLowEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.PercentLowEditField.Enable = 'off';
            app.PercentLowEditField.Tooltip = {'StarDist, percentile low'};
            app.PercentLowEditField.Position = [306 99 33 22];
            app.PercentLowEditField.Value = 1;

            % Create PercentHighEditFieldLabel
            app.PercentHighEditFieldLabel = uilabel(app.ParametersPanel);
            app.PercentHighEditFieldLabel.HorizontalAlignment = 'right';
            app.PercentHighEditFieldLabel.Enable = 'off';
            app.PercentHighEditFieldLabel.Position = [361 99 75 22];
            app.PercentHighEditFieldLabel.Text = 'Percent-High';

            % Create PercentHighEditField
            app.PercentHighEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.PercentHighEditField.Enable = 'off';
            app.PercentHighEditField.Tooltip = {'StarDist, percentile high'};
            app.PercentHighEditField.Position = [440 99 39 22];
            app.PercentHighEditField.Value = 99.8;

            % Create CellDiameterpixelsEditFieldLabel
            app.CellDiameterpixelsEditFieldLabel = uilabel(app.ParametersPanel);
            app.CellDiameterpixelsEditFieldLabel.HorizontalAlignment = 'right';
            app.CellDiameterpixelsEditFieldLabel.Enable = 'off';
            app.CellDiameterpixelsEditFieldLabel.Tooltip = {'Cellpose, whole cell 30 pixels, wh'};
            app.CellDiameterpixelsEditFieldLabel.Position = [3 21 115 22];
            app.CellDiameterpixelsEditFieldLabel.Text = 'Cell Diameter[pixels]';

            % Create CellDiameterpixelsEditField
            app.CellDiameterpixelsEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.CellDiameterpixelsEditField.Limits = [1 60];
            app.CellDiameterpixelsEditField.Enable = 'off';
            app.CellDiameterpixelsEditField.Tooltip = {'Cellpose,30  for cyto and 17 for nuclei by default'};
            app.CellDiameterpixelsEditField.Position = [124 21 29 22];
            app.CellDiameterpixelsEditField.Value = 30;

            % Create MicronPerPixelEditFieldLabel
            app.MicronPerPixelEditFieldLabel = uilabel(app.ParametersPanel);
            app.MicronPerPixelEditFieldLabel.HorizontalAlignment = 'right';
            app.MicronPerPixelEditFieldLabel.Enable = 'off';
            app.MicronPerPixelEditFieldLabel.Position = [192 21 92 22];
            app.MicronPerPixelEditFieldLabel.Text = 'Micron Per Pixel';

            % Create MicronPerPixelEditField
            app.MicronPerPixelEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.MicronPerPixelEditField.Limits = [0 10];
            app.MicronPerPixelEditField.Enable = 'off';
            app.MicronPerPixelEditField.Tooltip = {'DeepCell parameter, image pixel size'};
            app.MicronPerPixelEditField.Position = [299 21 51 22];
            app.MicronPerPixelEditField.Value = 1;

            % Create AdvancedButton
            app.AdvancedButton = uibutton(app.ParametersPanel, 'push');
            app.AdvancedButton.Enable = 'off';
            app.AdvancedButton.Tooltip = {'Advanced parameters setting'};
            app.AdvancedButton.Position = [379 21 100 23];
            app.AdvancedButton.Text = 'Advanced';

            % Create ProbablilityThresholdEditFieldLabel
            app.ProbablilityThresholdEditFieldLabel = uilabel(app.ParametersPanel);
            app.ProbablilityThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.ProbablilityThresholdEditFieldLabel.Enable = 'off';
            app.ProbablilityThresholdEditFieldLabel.Position = [8 58 120 22];
            app.ProbablilityThresholdEditFieldLabel.Text = 'Probablility Threshold';

            % Create ProbablilityThresholdEditField
            app.ProbablilityThresholdEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.ProbablilityThresholdEditField.Limits = [0 1];
            app.ProbablilityThresholdEditField.Enable = 'off';
            app.ProbablilityThresholdEditField.Tooltip = {'StarDist, StarDist, non-maximum suppression (NMS)  overlap probablity or score threshold '};
            app.ProbablilityThresholdEditField.Position = [162 58 35 22];
            app.ProbablilityThresholdEditField.Value = 0.5;

            % Create OverlapThresholdEditFieldLabel
            app.OverlapThresholdEditFieldLabel = uilabel(app.ParametersPanel);
            app.OverlapThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.OverlapThresholdEditFieldLabel.Enable = 'off';
            app.OverlapThresholdEditFieldLabel.Position = [266 58 112 22];
            app.OverlapThresholdEditFieldLabel.Text = 'Overlap Threshold';

            % Create OverlapThresholdEditField
            app.OverlapThresholdEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.OverlapThresholdEditField.Limits = [0 1];
            app.OverlapThresholdEditField.Enable = 'off';
            app.OverlapThresholdEditField.Tooltip = {'StarDist, non-maximum suppression (NMS)  overlap threshold'};
            app.OverlapThresholdEditField.Position = [404 58 37 22];
            app.OverlapThresholdEditField.Value = 0.4;

            % Show the figure after all components are created
            app.CellAnalysisoptionsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = cellanalysisGUI_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.CellAnalysisoptionsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.CellAnalysisoptionsUIFigure)
        end
    end
end