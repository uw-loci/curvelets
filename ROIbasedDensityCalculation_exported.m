classdef ROIbasedDensityCalculation_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        DensityCalculationInCAUIFigure  matlab.ui.Figure
        Panel_2                         matlab.ui.container.Panel
        CloseButton                     matlab.ui.control.Button
        OpenCurveAlignButton            matlab.ui.control.Button
        ImageFolderTextArea             matlab.ui.control.TextArea
        ImageFolderTextAreaLabel        matlab.ui.control.Label
        Panel                           matlab.ui.container.Panel
        RunButton                       matlab.ui.control.Button
        ResetButton                     matlab.ui.control.Button
        LoadimagesButton                matlab.ui.control.Button
        LocationOptionsPanel            matlab.ui.container.Panel
        InnerCheckBox                   matlab.ui.control.CheckBox
        OuterCheckBox                   matlab.ui.control.CheckBox
        BoundaryCheckBox                matlab.ui.control.CheckBox
        MeasurementsPanel               matlab.ui.container.Panel
        IntensityCheckBox               matlab.ui.control.CheckBox
        DensityCheckBox                 matlab.ui.control.CheckBox
        MessageWindowTextArea           matlab.ui.control.TextArea
        MessageWindowTextAreaLabel      matlab.ui.control.Label
        ParametersPanel                 matlab.ui.container.Panel
        DistanceEditField               matlab.ui.control.NumericEditField
        DistanceEditFieldLabel          matlab.ui.control.Label
        ThresholdEditField              matlab.ui.control.NumericEditField
        ThresholdEditFieldLabel         matlab.ui.control.Label
        UITable                         matlab.ui.control.Table
        ImageListListBox                matlab.ui.control.ListBox
        ImageListListBoxLabel           matlab.ui.control.Label
    end

    
    properties (Access = private)
        %         pathNameGlobal=pwd;  % image folder name
%         DICcolNames = {'ROI#','Threshold','Distance','Image name','ROI name', 'Intensity-inner','Intensity-boundary','Intensity-outer',...
%                 'Density-inner','Density-boundary','Density-outer','Area-inner','Area-outer'}; 

        DICcolNames = {'ROI#','Threshold','Distance','Image name','ROI name', 'Density-inner','Area-inner','Intensity-inner',...
            'Density-outer','Area-outer','Intensity-outer',...
            'Density-boundary','Intensity-boundary'};
        DICoutwithIndex = []; 
        DICimagePath = '';    % 
        
    end
    
    properties (Access = public)
        imagePathfromCA = ''; % default path is not from CA main GUI
        imageListfromCA = ''; % default images are not from CA main GUI
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            %% Initialisation of POI Libs for xlwrite
            % Add Java POI Libs to matlab javapath
            javaaddpath('./20130227_xlwrite/poi_library/poi-3.8-20120326.jar');
            javaaddpath('./20130227_xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
            javaaddpath('./20130227_xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
            javaaddpath('./20130227_xlwrite/poi_library/xmlbeans-2.3.0.jar');
            javaaddpath('./20130227_xlwrite/poi_library/dom4j-1.6.1.jar');
            javaaddpath('./20130227_xlwrite/poi_library/stax-api-1.0.1.jar');
           
            if isempty(varargin)
                app.RunButton.Enable ='off';
                app.ResetButton.Enable = 'off';
                app.DistanceEditField.Enable = 'off';
                app.ThresholdEditField.Enable = 'off';
                app.ImageListListBox.Enable = 'off';
                app.MessageWindowTextArea.Editable = 'off';
                app.MessageWindowTextArea.Value= sprintf('Click on the "Load Image(s)" button to start the analysis. \n\nThe associated ROI .mat file for each image must exist to do this ROI based analysis');
                app.UITable.ColumnName = app.DICcolNames;
                app.UITable.Data = app.DICoutwithIndex;
                if exist(fullfile(pwd,'DICparameters.mat'),'file')
                    try
                        load('DICparameters.mat','DICimagePath')
                        app.ImageFolderTextArea.Value = DICimagePath;
                    catch
                        DICimagePath = pwd;
                        app.ImageFolderTextArea.Value = DICimagePath;
                        save(fullfile(pwd,'DICparameters.mat'),'DICimagePath');
                    end
                else
                    DICimagePath = pwd;
                    app.ImageFolderTextArea.Value = DICimagePath;
                    app.DICimagePath = DICimagePath;
                    save(fullfile(pwd,'DICparameters.mat'),'DICimagePath');
                end
            else
                %                 DICimagePath = imagePath;
                %                 app.ImageFolderTextArea.Value = DICimagePath;
                %                 save(fullfile(pwd,'DICparameters.mat'),'DICimagePath');
                app.imagePathfromCA = varargin{1};
                app.imageListfromCA = varargin{2};
                app.DICimagePath = app.imagePathfromCA;
                pathName = app.imagePathfromCA;
                fileName = app.imageListfromCA;
                app.LoadimagesButtonPushed
                disp('loading the images from the CA main program')
                app.MessageWindowTextArea.Value= sprintf('loading image from CA main GUI \n\nThe associated ROI .mat file for each image must exist to do this ROI based analysis');
                app.LoadimagesButton.Enable = 'off';
                app.UITable.ColumnName = app.DICcolNames;
                app.UITable.Data = app.DICoutwithIndex;

            end
            
        end

        % Button pushed function: LoadimagesButton
        function LoadimagesButtonPushed(app, event)

            statusMessage = 'Loading images...';
            app.MessageWindowTextArea.Value = statusMessage;
            if isempty(app.imagePathfromCA)
                [fileName, pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg;*.png;';'*.*'},'Select Image',app.ImageFolderTextArea.Value{1},'MultiSelect','on');
               
            else
                fileName = app.imageListfromCA;
                pathName = app.imagePathfromCA;
            end
            if ischar(pathName)
                outDir = fullfile(pathName, 'ROI_management','ROI-DICanalysis'); % folder for density and intensity calculation results
                ROIDir = fullfile(pathName, 'ROI_management');   % ROI folder
                if (~exist(ROIDir,'dir'))
                    app.ImageListListBox.Items(:) = '';
                    ROIDirError = sprintf('No ROI file folder was found at %s, \n Make sure ROI annotation files are ready', pathName);
                    app.MessageWindowTextArea.Value = sprintf('%s \n %s \n',statusMessage,ROIDirError);
                    app.RunButton.Enable = 'off';
                    app.ResetButton.Enable = 'on';
                    app.DistanceEditField.Enable = 'off';
                    app.ThresholdEditField.Enable = 'off';
                    drawnow
                    return
                end
                if (~exist(outDir,'dir'))
                    mkdir(outDir);
                end
            elseif pathName == 0
                app.ImageListListBox.Items(:)= '';
                fileselectionError = 'No file is selected';
                app.MessageWindowTextArea.Value = sprintf('%s \n %s \n',statusMessage,fileselectionError);
                app.RunButton.Enable = 'off';
                app.ResetButton.Enable = 'on';
                app.DistanceEditField.Enable = 'off';
                app.ThresholdEditField.Enable = 'off';
                drawnow
                return;
            end
            app.ImageFolderTextArea.Value= pathName;
            DICimagePath = pathName;
            save(fullfile(pwd,'DICparameters.mat'),'DICimagePath');  
            
            %% check the availablity of the ROI annotation files
            if iscell(fileName) %check if multiple files were selected
                numFiles = length(fileName);
                app.ImageListListBox.Items = fileName;
                disp(sprintf('%d files were selected',numFiles));
            else
                numFiles = 1;
                fileName = {fileName};
                app.ImageListListBox.Items = fileName;
                disp(sprintf('%d file was selected',numFiles));
            end
            deletedfileIndex = [];
            ii = 0;
            for iFile = 1:length(fileName)
                [~,imageName,~] = fileparts(fileName{iFile});
                infoImage = imfinfo(fullfile(pathName,fileName{iFile}));
                if numel(infoImage) == 1
                    ROIfilename = [imageName '_ROIs.mat'];
                    if exist(fullfile(ROIDir,ROIfilename),'file')
                        fprintf('%d/%d: ROI mat file for image %s is found  \n', iFile,length(fileName), imageName)
                    else
                        fprintf('%d/%d: ROI mat file for image %s  is missing, this image will be skipped. \n', iFile,length(fileName), imageName)
                        ii = ii + 1;
                        deletedfileIndex(ii) = iFile;
                    end
                 else
                    fprintf('%s is not a single image and hence will be skipped \n',fileName{iFile})
                    ii = ii + 1;
                    deletedfileIndex(ii) = iFile;
                end
            end
            if ii > 0
                if ii == 1
                    statusMessage = sprintf('%d image out of %d was skipped, only %d will be analyzed', ii, length(fileName),length(fileName)-ii);
                elseif ii > 1
                    statusMessage = sprintf('%d images out of %d were skipped, only %d will be analyzed', ii, length(fileName),length(fileName)-ii);
                end
                fileName(deletedfileIndex) = '';
                app.ImageListListBox.Items = fileName;
            else
                if length(fileName)==1
                    statusMessage = sprintf('The selected %d image will be analyzed',  length(fileName))
                elseif length(fileName)> 1
                    statusMessage = sprintf('All selected %d images will be analyzed',  length(fileName))
                end
            end
            disp(statusMessage)
            app.MessageWindowTextArea.Value = statusMessage;
            if isempty (fileName)
                app.RunButton.Enable = 'off';
                app.ResetButton.Enable = 'on';
                app.DistanceEditField.Enable = 'off';
                app.ThresholdEditField.Enable = 'off';
            else
                app.RunButton.Enable = 'on';
                app.ResetButton.Enable = 'on';
                app.DistanceEditField.Enable = 'on';
                app.ThresholdEditField.Enable = 'on';
                app.ImageListListBox.Enable = 'on';
            end
%delete the images from the CA so that the push button can be used
%indepently
            app.imagePathfromCA = '';
            app.imageListfromCA = '';
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            try
            app.LoadimagesButton.Enable = 'off';
            app.RunButton.Enable ='off';
            app.ResetButton.Enable = 'off';
            app.ImageFolderTextArea.Enable = 'off';  
            app.DistanceEditField.Enable = 'off';
            app.ThresholdEditField.Enable = 'off';
            RUNerrormessage = '';
  
            parameterDensitycalculation.imageFolder = app.ImageFolderTextArea.Value{1};
            parameterDensitycalculation.thresholdBG = app.ThresholdEditField.Value;
            parameterDensitycalculation.distanceOUT = app.DistanceEditField.Value;            
            imageNumber = length(app.ImageListListBox.Items);
            pathName = parameterDensitycalculation.imageFolder;
            thresholdBG =  parameterDensitycalculation.thresholdBG;
            distanceOUT = parameterDensitycalculation.distanceOUT;
            % output options from the GUI
            parameterDensitycalculation.ROIboundary_flag = app.BoundaryCheckBox.Value;
            parameterDensitycalculation.ROIin_flag = app.InnerCheckBox.Value;
            parameterDensitycalculation.ROIout_flag = app.OuterCheckBox.Value;
            parameterDensitycalculation.densityFlag = app.DensityCheckBox.Value;
            parameterDensitycalculation.intensityFlag = app.IntensityCheckBox.Value;

            DICout = [];
            statusMessage = '';
            DICoutTemp = [];
            iSkip = 0;
            skippedImagelist = '';
            
            % Set the input parameter from the density calcuation
            for iImage = 1: imageNumber
                batchmodeFunctionError = '';
                imageName = app.ImageListListBox.Items{iImage};
                statusMessage = sprintf('\n %d/%d: Processing the %s ...\n',iImage, imageNumber,imageName);
                disp(statusMessage)
                app.MessageWindowTextArea.Value = statusMessage;
%                 waitbar(iImage/imageNumber,statusMessage);
                drawnow
                parameterDensitycalculation.imageName= imageName;
                try
                    DICoutTemp = densityBatchMode(parameterDensitycalculation);
                catch ME1
                    DICoutTemp = [];
                    batchmodeFunctionError = sprintf('Catch an error during density calculation %s', ME1.message);                 
                end
                if isempty(DICoutTemp)              
                    statusMessage = sprintf('%s \n Density calculation is skipped. %s \n', statusMessage,batchmodeFunctionError);
                    disp(statusMessage)
                    app.MessageWindowTextArea.Value = statusMessage;                  
                    drawnow
                    iSkip = iSkip + 1;
                    skippedImagelist{1,iSkip} = sprintf('%d-%s,  ',iSkip,imageName);
                    pause(3)
                end
                DICout = [DICout;DICoutTemp];
                DICoutwithIndex_singleBatch = [num2cell(1:size(DICout,1))',num2cell(thresholdBG*ones(size(DICout,1),1)),...
                num2cell(distanceOUT*ones(size(DICout,1),1)),DICout];
                DICoutwithIndex_singleImage = [num2cell(1:size(DICoutTemp,1))',num2cell(thresholdBG*ones(size(DICoutTemp,1),1)),...
                num2cell(distanceOUT*ones(size(DICoutTemp,1),1)),DICoutTemp];
                app.DICoutwithIndex = [app.DICoutwithIndex;DICoutwithIndex_singleImage];
                app.DICoutwithIndex(:,1) = num2cell(1:size(app.DICoutwithIndex,1));
                app.UITable.Data = app.DICoutwithIndex;
            end
            % save results to excel file               
            DICoutComplete = [app.DICcolNames;DICoutwithIndex_singleBatch];
            DICoutPath = fullfile(pathName,'ROI_management','ROI-DICanalysis');
            if ~exist(DICoutPath,'dir')
                mkdir(DICoutPath)
            end
            % fprintf('Output folder for the ROI density/intensity analysis module is : \n  %s  \n',DICoutPath)
            DICoutFileList = dir(fullfile(DICoutPath,sprintf('DICoutput-batch*.xlsx')));
            if isempty(DICoutFileList)
                DICoutFile = fullfile(DICoutPath,sprintf('DICoutput-batch-1.xlsx'));
            else
                DICoutFile = fullfile(DICoutPath,sprintf('DICoutput-batch-%d.xlsx',length(DICoutFileList)+1));
            end
            sheetName = sprintf('TH%d-DIS%d',parameterDensitycalculation.thresholdBG,parameterDensitycalculation.distanceOUT);
            try 
               xlswrite(DICoutFile,DICoutComplete,sheetName);
            catch
                xlwrite(DICoutFile,DICoutComplete,sheetName);
            end
            if iSkip == 0                
                statusMessage = sprintf('Analysis is done! \n No image was skipped \n Density/Intensity output is saved at: \n %s \n\n Click "Reset" to start over \n\n OR Change parameters/images and run again' ,DICoutFile);
            elseif iSkip > 0
                statusMessage = sprintf('Analysis is done! Skipped image list: %s \n Density/Intensity output is saved at: \n %s \n\n Click "Reset" to start over \n\n OR Change parameters/images and run again' ,...
                    [skippedImagelist{:}],DICoutFile);
            end
%             disp(statusMessage);
%             app.MessageWindowTextArea.Value = statusMessage;
%             app.RunButton.Enable = 'on';
            catch ME2
                RUNerrormessage = ME2.message;
            end
            statusMessage = sprintf('\n %s  \n\n %s\n',statusMessage,RUNerrormessage);
            disp(statusMessage)
            app.MessageWindowTextArea.Value = statusMessage;
            app.LoadimagesButton.Enable = 'on';
            app.RunButton.Enable ='on';
            app.ResetButton.Enable = 'on';
            app.ImageFolderTextArea.Enable = 'off'; 
            app.DistanceEditField.Enable = 'on';
            app.ThresholdEditField.Enable = 'on';
            drawnow
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            delete(app)
            ROIbasedDensityCalculation;
        end

        % Value changed function: DensityCheckBox
        function DensityCheckBoxValueChanged(app, event)
            value = app.DensityCheckBox.Value;
            if value == 0
                if app.IntensityCheckBox.Value == 0
                  disp('At least one measurement (density or intensity) should be selected')
                  app.DensityCheckBox.Value = 1;
                end
            end
            
        end

        % Value changed function: IntensityCheckBox
        function IntensityCheckBoxValueChanged(app, event)
            value = app.IntensityCheckBox.Value;
            if value == 0
                if app.DensityCheckBox.Value == 0
                  disp('At least one measurement (density or intensity) should be selected')
                  app.IntensityCheckBox.Value = 1;
                end
            end
        end

        % Button pushed function: OpenCurveAlignButton
        function OpenCurveAlignButtonPushed(app, event)
            CurveAlign;
        end

        % Button pushed function: CloseButton
        function CloseButtonPushed(app, event)
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create DensityCalculationInCAUIFigure and hide until all components are created
            app.DensityCalculationInCAUIFigure = uifigure('Visible', 'off');
            app.DensityCalculationInCAUIFigure.Position = [100 100 1416 799];
            app.DensityCalculationInCAUIFigure.Name = 'DensityCalculationInCA';
            app.DensityCalculationInCAUIFigure.Tag = 'density_module';

            % Create ImageListListBoxLabel
            app.ImageListListBoxLabel = uilabel(app.DensityCalculationInCAUIFigure);
            app.ImageListListBoxLabel.HorizontalAlignment = 'right';
            app.ImageListListBoxLabel.Position = [68 601 61 22];
            app.ImageListListBoxLabel.Text = 'Image List';

            % Create ImageListListBox
            app.ImageListListBox = uilistbox(app.DensityCalculationInCAUIFigure);
            app.ImageListListBox.Items = {'image1', 'image2', 'image3', '...'};
            app.ImageListListBox.Position = [68 520 336 74];
            app.ImageListListBox.Value = 'image1';

            % Create UITable
            app.UITable = uitable(app.DensityCalculationInCAUIFigure);
            app.UITable.ColumnName = {''};
            app.UITable.RowName = {};
            app.UITable.Position = [429 15 972 744];

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.DensityCalculationInCAUIFigure);
            app.ParametersPanel.Title = 'Parameters';
            app.ParametersPanel.Position = [251 386 149 113];

            % Create ThresholdEditFieldLabel
            app.ThresholdEditFieldLabel = uilabel(app.ParametersPanel);
            app.ThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.ThresholdEditFieldLabel.Position = [9 49 59 22];
            app.ThresholdEditFieldLabel.Text = 'Threshold';

            % Create ThresholdEditField
            app.ThresholdEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.ThresholdEditField.Tooltip = {'pixels with Intensity value larger than this threshold will be counted'};
            app.ThresholdEditField.Position = [102 49 38 22];
            app.ThresholdEditField.Value = 5;

            % Create DistanceEditFieldLabel
            app.DistanceEditFieldLabel = uilabel(app.ParametersPanel);
            app.DistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.DistanceEditFieldLabel.Position = [13 12 52 22];
            app.DistanceEditFieldLabel.Text = 'Distance';

            % Create DistanceEditField
            app.DistanceEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.DistanceEditField.Tooltip = {'Distance (in pixels) to the boundary from outside'};
            app.DistanceEditField.Position = [99 12 42 22];
            app.DistanceEditField.Value = 20;

            % Create MessageWindowTextAreaLabel
            app.MessageWindowTextAreaLabel = uilabel(app.DensityCalculationInCAUIFigure);
            app.MessageWindowTextAreaLabel.HorizontalAlignment = 'right';
            app.MessageWindowTextAreaLabel.Position = [68 275 100 22];
            app.MessageWindowTextAreaLabel.Text = 'Message Window';

            % Create MessageWindowTextArea
            app.MessageWindowTextArea = uitextarea(app.DensityCalculationInCAUIFigure);
            app.MessageWindowTextArea.Interruptible = 'off';
            app.MessageWindowTextArea.Editable = 'off';
            app.MessageWindowTextArea.Position = [68 47 332 218];

            % Create MeasurementsPanel
            app.MeasurementsPanel = uipanel(app.DensityCalculationInCAUIFigure);
            app.MeasurementsPanel.Title = 'Measurements';
            app.MeasurementsPanel.Position = [68 315 332 53];

            % Create DensityCheckBox
            app.DensityCheckBox = uicheckbox(app.MeasurementsPanel);
            app.DensityCheckBox.ValueChangedFcn = createCallbackFcn(app, @DensityCheckBoxValueChanged, true);
            app.DensityCheckBox.Tooltip = {'Number of pixels of the selected region(s)'};
            app.DensityCheckBox.Text = ' Density';
            app.DensityCheckBox.Position = [61 1 82 22];
            app.DensityCheckBox.Value = true;

            % Create IntensityCheckBox
            app.IntensityCheckBox = uicheckbox(app.MeasurementsPanel);
            app.IntensityCheckBox.ValueChangedFcn = createCallbackFcn(app, @IntensityCheckBoxValueChanged, true);
            app.IntensityCheckBox.Text = 'Intensity';
            app.IntensityCheckBox.Position = [170 1 82 22];

            % Create LocationOptionsPanel
            app.LocationOptionsPanel = uipanel(app.DensityCalculationInCAUIFigure);
            app.LocationOptionsPanel.Title = 'Location Options';
            app.LocationOptionsPanel.Position = [68 386 162 113];

            % Create BoundaryCheckBox
            app.BoundaryCheckBox = uicheckbox(app.LocationOptionsPanel);
            app.BoundaryCheckBox.Tooltip = {'ROI boundary and its adjacent pixels'};
            app.BoundaryCheckBox.Text = 'Boundary';
            app.BoundaryCheckBox.Position = [38 59 73 22];

            % Create OuterCheckBox
            app.OuterCheckBox = uicheckbox(app.LocationOptionsPanel);
            app.OuterCheckBox.Tooltip = {'ROI outside'};
            app.OuterCheckBox.Text = 'Outer';
            app.OuterCheckBox.Position = [37 30 52 22];

            % Create InnerCheckBox
            app.InnerCheckBox = uicheckbox(app.LocationOptionsPanel);
            app.InnerCheckBox.Tooltip = {'ROI inside'};
            app.InnerCheckBox.Text = 'Inner';
            app.InnerCheckBox.Position = [38 3 49 22];
            app.InnerCheckBox.Value = true;

            % Create Panel
            app.Panel = uipanel(app.DensityCalculationInCAUIFigure);
            app.Panel.BorderType = 'none';
            app.Panel.Position = [68 716 336 72];

            % Create LoadimagesButton
            app.LoadimagesButton = uibutton(app.Panel, 'push');
            app.LoadimagesButton.ButtonPushedFcn = createCallbackFcn(app, @LoadimagesButtonPushed, true);
            app.LoadimagesButton.Position = [6 16 100 35];
            app.LoadimagesButton.Text = 'Load image(s)';

            % Create ResetButton
            app.ResetButton = uibutton(app.Panel, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [230 16 100 35];
            app.ResetButton.Text = 'Reset';

            % Create RunButton
            app.RunButton = uibutton(app.Panel, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Position = [121 16 100 35];
            app.RunButton.Text = 'Run';

            % Create ImageFolderTextAreaLabel
            app.ImageFolderTextAreaLabel = uilabel(app.DensityCalculationInCAUIFigure);
            app.ImageFolderTextAreaLabel.HorizontalAlignment = 'right';
            app.ImageFolderTextAreaLabel.Position = [73 680 76 22];
            app.ImageFolderTextAreaLabel.Text = 'Image Folder';

            % Create ImageFolderTextArea
            app.ImageFolderTextArea = uitextarea(app.DensityCalculationInCAUIFigure);
            app.ImageFolderTextArea.Editable = 'off';
            app.ImageFolderTextArea.Enable = 'off';
            app.ImageFolderTextArea.Position = [73 630 324 51];

            % Create Panel_2
            app.Panel_2 = uipanel(app.DensityCalculationInCAUIFigure);
            app.Panel_2.BorderType = 'none';
            app.Panel_2.Position = [74 12 323 32];

            % Create OpenCurveAlignButton
            app.OpenCurveAlignButton = uibutton(app.Panel_2, 'push');
            app.OpenCurveAlignButton.ButtonPushedFcn = createCallbackFcn(app, @OpenCurveAlignButtonPushed, true);
            app.OpenCurveAlignButton.Tooltip = {'Open CurveAlign main program to annotate ROI or check the ROI density analysis for individual images using ROI manager'};
            app.OpenCurveAlignButton.Position = [14 6 124 22];
            app.OpenCurveAlignButton.Text = 'Open CurveAlign';

            % Create CloseButton
            app.CloseButton = uibutton(app.Panel_2, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [165 6 118 22];
            app.CloseButton.Text = 'Close';

            % Show the figure after all components are created
            app.DensityCalculationInCAUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ROIbasedDensityCalculation_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.DensityCalculationInCAUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.DensityCalculationInCAUIFigure)
        end
    end
end