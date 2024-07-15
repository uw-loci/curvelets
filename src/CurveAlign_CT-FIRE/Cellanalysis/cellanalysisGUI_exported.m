classdef cellanalysisGUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CellAnalysisoptionsUIFigure    matlab.ui.Figure
        SendtoROImanagerCheckBox       matlab.ui.control.CheckBox
        CancelButton                   matlab.ui.control.Button
        OKButton                       matlab.ui.control.Button
        ModelevaluationCheckBox        matlab.ui.control.CheckBox
        PathtoimageEditField           matlab.ui.control.EditField
        PathtoimageEditFieldLabel      matlab.ui.control.Label
        DefaultparametersCheckBox      matlab.ui.control.CheckBox
        PretrainedmodelsDropDown       matlab.ui.control.DropDown
        PretrainedmodelsDropDownLabel  matlab.ui.control.Label
        MethodsDropDown                matlab.ui.control.DropDown
        MethodsDropDownLabel           matlab.ui.control.Label
        ImagetypeDropDown              matlab.ui.control.DropDown
        ImagetypeDropDownLabel         matlab.ui.control.Label
        ObjecttypeDropDown             matlab.ui.control.DropDown
        ObjecttypeDropDownLabel        matlab.ui.control.Label
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        parameterOptions = struct('imagePath','','imageName','','imageType','HE bright field',...
            'objectType','Nuclei','deeplearningMethod','StarDist', 'pre_trainedModel', '2D_versatile_he',...
            'model_parameters',[],'defaultParameters',1,'modelEvaluation',0,'sendtoROImanager',1);
        preTrainedModels_cellpose = {'cyto','cyto2','cyto3','nuclei',...
                    'tissuenet_cp3','livecell_cp3','yeast_PhC_cp3','yeast_BF_cp3','bact_phase_cp3',...
                    'bact_fluor_cp3','deepbacs_cp3','cyto2_cp3'};
        preTrainedModelIndex = 1;

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
            default_parameters_flag = 0;%app.parameterOptions.defaultParameters;
            samplingFactor = 2;
            stardistParameters = struct('deepMethod',deepMethod,'modelName',deepModel,'defaultParametersFlag',default_parameters_flag,...
                    'prob_thresh',0.2,'nms_threshold',0.5,'Normalization_lowPercentile',1,...
                    'Normalization_highPercentile',99.8);

            if strcmp (deepMethod,'StarDist')
                app.parameterOptions.modelParameters = stardistParameters;
                cellsStarDist = imageCard(imageName,imagePath,samplingFactor,stardistParameters);
                app.CallingApp.CAPobjects.cells = cellsStarDist;  
                app.CallingApp.figureOptions.plotImage = 0;
                app.CallingApp.figureOptions.plotObjects = 1;
                app.CallingApp.plotImage_public;
            elseif strcmp (deepMethod,'Cellpose') 
               if  strcmp(imageType,'HE bright field')
                   fprintf('current image type is : %s \n Open Fluorescence image or phase contrast image to proceed \n',imageType);
                   return
               end
               
               try
                   if strcmp (objectType,'Cytoplasm')
                       preTrained = app.parameterOptions.pre_trainedModel;
                       cellsCellpose = imgCardWholeCell(deepMethod,imageName,imagePath,preTrained);
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
               if  strcmp(imageType,'HE bright field')
                   fprintf('current image type is : %s \n Open Fluorescence image or phase contrast image to proceed \n',imageType);
                   return
               end
               
               try
                   if strcmp (objectType,'Cytoplasm')
                       
                       cellsDeepCell = imgCardWholeCell(deepMethod,imageName,imagePath);
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
            elseif strcmp(app.parameterOptions.deeplearningMethod,'DeepCell')
                app.PretrainedmodelsDropDown.Items = {'DeepCell default model'};
            else
                app.PretrainedmodelsDropDown.Items = {'Not specified'};
            end
            app.PretrainedmodelsDropDownValueChanged;
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
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CellAnalysisoptionsUIFigure and hide until all components are created
            app.CellAnalysisoptionsUIFigure = uifigure('Visible', 'off');
            app.CellAnalysisoptionsUIFigure.Position = [100 100 519 453];
            app.CellAnalysisoptionsUIFigure.Name = 'Cell Analysis-options';

            % Create ObjecttypeDropDownLabel
            app.ObjecttypeDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.ObjecttypeDropDownLabel.HorizontalAlignment = 'right';
            app.ObjecttypeDropDownLabel.Position = [99 294 68 22];
            app.ObjecttypeDropDownLabel.Text = 'Object type';

            % Create ObjecttypeDropDown
            app.ObjecttypeDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.ObjecttypeDropDown.Items = {'Nuclei', 'Cytoplasm', 'All'};
            app.ObjecttypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ObjecttypeDropDownValueChanged, true);
            app.ObjecttypeDropDown.Position = [213 294 187 22];
            app.ObjecttypeDropDown.Value = 'Nuclei';

            % Create ImagetypeDropDownLabel
            app.ImagetypeDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.ImagetypeDropDownLabel.HorizontalAlignment = 'right';
            app.ImagetypeDropDownLabel.Position = [98 351 65 22];
            app.ImagetypeDropDownLabel.Text = 'Image type';

            % Create ImagetypeDropDown
            app.ImagetypeDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.ImagetypeDropDown.Items = {'HE bright field', 'Fluorescence_1-channel', 'Phase contrast', 'Gray scale'};
            app.ImagetypeDropDown.DropDownOpeningFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.ValueChangedFcn = createCallbackFcn(app, @ImagetypeDropDownValueChanged, true);
            app.ImagetypeDropDown.Position = [213 351 187 22];
            app.ImagetypeDropDown.Value = 'HE bright field';

            % Create MethodsDropDownLabel
            app.MethodsDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.MethodsDropDownLabel.HorizontalAlignment = 'right';
            app.MethodsDropDownLabel.Position = [98 238 53 22];
            app.MethodsDropDownLabel.Text = 'Methods';

            % Create MethodsDropDown
            app.MethodsDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.MethodsDropDown.Items = {'StarDist', 'Cellpose', 'DeepCell', 'FromMaskfiles-SD', 'FromMask-others'};
            app.MethodsDropDown.ValueChangedFcn = createCallbackFcn(app, @MethodsDropDownValueChanged, true);
            app.MethodsDropDown.Position = [213 238 187 22];
            app.MethodsDropDown.Value = 'StarDist';

            % Create PretrainedmodelsDropDownLabel
            app.PretrainedmodelsDropDownLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.PretrainedmodelsDropDownLabel.HorizontalAlignment = 'right';
            app.PretrainedmodelsDropDownLabel.Position = [85 171 113 22];
            app.PretrainedmodelsDropDownLabel.Text = 'Pre-trained models';

            % Create PretrainedmodelsDropDown
            app.PretrainedmodelsDropDown = uidropdown(app.CellAnalysisoptionsUIFigure);
            app.PretrainedmodelsDropDown.Items = {'2D_versatile_he'};
            app.PretrainedmodelsDropDown.ValueChangedFcn = createCallbackFcn(app, @PretrainedmodelsDropDownValueChanged, true);
            app.PretrainedmodelsDropDown.Position = [213 171 187 22];
            app.PretrainedmodelsDropDown.Value = '2D_versatile_he';

            % Create DefaultparametersCheckBox
            app.DefaultparametersCheckBox = uicheckbox(app.CellAnalysisoptionsUIFigure);
            app.DefaultparametersCheckBox.Text = 'Default parameters';
            app.DefaultparametersCheckBox.Position = [80 103 124 22];
            app.DefaultparametersCheckBox.Value = true;

            % Create PathtoimageEditFieldLabel
            app.PathtoimageEditFieldLabel = uilabel(app.CellAnalysisoptionsUIFigure);
            app.PathtoimageEditFieldLabel.HorizontalAlignment = 'right';
            app.PathtoimageEditFieldLabel.Position = [100 403 80 22];
            app.PathtoimageEditFieldLabel.Text = 'Path to image';

            % Create PathtoimageEditField
            app.PathtoimageEditField = uieditfield(app.CellAnalysisoptionsUIFigure, 'text');
            app.PathtoimageEditField.Editable = 'off';
            app.PathtoimageEditField.Position = [214 389 262 36];

            % Create ModelevaluationCheckBox
            app.ModelevaluationCheckBox = uicheckbox(app.CellAnalysisoptionsUIFigure);
            app.ModelevaluationCheckBox.Enable = 'off';
            app.ModelevaluationCheckBox.Text = 'Model evaluation';
            app.ModelevaluationCheckBox.Position = [226 103 114 22];

            % Create OKButton
            app.OKButton = uibutton(app.CellAnalysisoptionsUIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [386 33 100 22];
            app.OKButton.Text = 'OK';

            % Create CancelButton
            app.CancelButton = uibutton(app.CellAnalysisoptionsUIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [269 33 100 22];
            app.CancelButton.Text = 'Cancel';

            % Create SendtoROImanagerCheckBox
            app.SendtoROImanagerCheckBox = uicheckbox(app.CellAnalysisoptionsUIFigure);
            app.SendtoROImanagerCheckBox.Text = 'Send to ROI manager';
            app.SendtoROImanagerCheckBox.Position = [348 103 138 22];
            app.SendtoROImanagerCheckBox.Value = true;

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