classdef ROIbasedDensityCalculation_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        DensityCalculationByCAROIUIFigure  matlab.ui.Figure
        ResetButton                 matlab.ui.control.Button
        RunButton                   matlab.ui.control.Button
        MessageWindowTextArea       matlab.ui.control.TextArea
        MessageWindowTextAreaLabel  matlab.ui.control.Label
        ParametersPanel             matlab.ui.container.Panel
        DistanceEditField           matlab.ui.control.NumericEditField
        DistanceEditFieldLabel      matlab.ui.control.Label
        ThresholdEditField          matlab.ui.control.NumericEditField
        ThresholdEditFieldLabel     matlab.ui.control.Label
        UITable                     matlab.ui.control.Table
        ImageFolderEditField        matlab.ui.control.EditField
        ImageFolderEditFieldLabel   matlab.ui.control.Label
        ImageListListBox            matlab.ui.control.ListBox
        ImageListListBoxLabel       matlab.ui.control.Label
        LoadimagesButton            matlab.ui.control.Button
    end

    
    properties (Access = private)
        %         pathNameGlobal=pwd;  % image folder name
        DICcolNames = {'ROI#','Threshold','Distance','Image name','ROI name', 'Intensity-inner','Intensity-boundary','Intensity-outer',...
                'Density-inner','Density-boundary','Density-outer','Area-inner','Area-outer'}; 
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
                        app.ImageFolderEditField.Value = DICimagePath;
                    catch
                        DICimagePath = pwd;
                        app.ImageFolderEditField.Value = DICimagePath;
                        save(fullfile(pwd,'DICparameters.mat'),'DICimagePath');
                    end
                else
                    DICimagePath = pwd;
                    app.ImageFolderEditField.Value = DICimagePath;
                    app.DICimagePath = DICimagePath;
                    save(fullfile(pwd,'DICparameters.mat'),'DICimagePath');
                end
            else
                %                 DICimagePath = imagePath;
                %                 app.ImageFolderEditField.Value = DICimagePath;
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

        % Callback function: ImageFolderEditField, LoadimagesButton
        function LoadimagesButtonPushed(app, event)

            statusMessage = 'Loading images...';
            app.MessageWindowTextArea.Value = statusMessage;
            if isempty(app.imagePathfromCA)
                [fileName, pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg;*.png;';'*.*'},'Select Image',app.ImageFolderEditField.Value,'MultiSelect','on');
               
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
            app.ImageFolderEditField.Value= pathName;
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
            app.ImageFolderEditField.Enable = 'off';  
            app.DistanceEditField.Enable = 'off';
            app.ThresholdEditField.Enable = 'off';
            RUNerrormessage = '';
  
            parameterDensitycalculation.imageFolder = app.ImageFolderEditField.Value;
            parameterDensitycalculation.thresholdBG = app.ThresholdEditField.Value;
            parameterDensitycalculation.distanceOUT = app.DistanceEditField.Value;            
            imageNumber = length(app.ImageListListBox.Items);
            pathName = parameterDensitycalculation.imageFolder;
            thresholdBG =  parameterDensitycalculation.thresholdBG;
            distanceOUT = parameterDensitycalculation.distanceOUT;
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
            app.ImageFolderEditField.Enable = 'on'; 
            app.DistanceEditField.Enable = 'on';
            app.ThresholdEditField.Enable = 'on';
            drawnow
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            delete(app)
            ROIbasedDensityCalculation
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create DensityCalculationByCAROIUIFigure and hide until all components are created
            app.DensityCalculationByCAROIUIFigure = uifigure('Visible', 'off');
            app.DensityCalculationByCAROIUIFigure.Position = [100 100 1088 697];
            app.DensityCalculationByCAROIUIFigure.Name = 'DensityCalculationByCAROI';

            % Create LoadimagesButton
            app.LoadimagesButton = uibutton(app.DensityCalculationByCAROIUIFigure, 'push');
            app.LoadimagesButton.ButtonPushedFcn = createCallbackFcn(app, @LoadimagesButtonPushed, true);
            app.LoadimagesButton.Position = [68 624 100 35];
            app.LoadimagesButton.Text = 'Load image(s)';

            % Create ImageListListBoxLabel
            app.ImageListListBoxLabel = uilabel(app.DensityCalculationByCAROIUIFigure);
            app.ImageListListBoxLabel.HorizontalAlignment = 'right';
            app.ImageListListBoxLabel.Position = [72 499 61 22];
            app.ImageListListBoxLabel.Text = 'Image List';

            % Create ImageListListBox
            app.ImageListListBox = uilistbox(app.DensityCalculationByCAROIUIFigure);
            app.ImageListListBox.Items = {'image1', 'image2', 'image3', '...'};
            app.ImageListListBox.Position = [72 418 327 74];
            app.ImageListListBox.Value = 'image1';

            % Create ImageFolderEditFieldLabel
            app.ImageFolderEditFieldLabel = uilabel(app.DensityCalculationByCAROIUIFigure);
            app.ImageFolderEditFieldLabel.HorizontalAlignment = 'right';
            app.ImageFolderEditFieldLabel.Position = [72 585 76 22];
            app.ImageFolderEditFieldLabel.Text = 'Image Folder';

            % Create ImageFolderEditField
            app.ImageFolderEditField = uieditfield(app.DensityCalculationByCAROIUIFigure, 'text');
            app.ImageFolderEditField.ValueChangedFcn = createCallbackFcn(app, @LoadimagesButtonPushed, true);
            app.ImageFolderEditField.HorizontalAlignment = 'center';
            app.ImageFolderEditField.FontSize = 10.5;
            app.ImageFolderEditField.Position = [72 532 327 54];

            % Create UITable
            app.UITable = uitable(app.DensityCalculationByCAROIUIFigure);
            app.UITable.ColumnName = {''};
            app.UITable.RowName = {};
            app.UITable.Position = [429 26 643 631];

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.DensityCalculationByCAROIUIFigure);
            app.ParametersPanel.Title = 'Parameters';
            app.ParametersPanel.Position = [68 274 331 123];

            % Create ThresholdEditFieldLabel
            app.ThresholdEditFieldLabel = uilabel(app.ParametersPanel);
            app.ThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.ThresholdEditFieldLabel.Position = [49 59 59 22];
            app.ThresholdEditFieldLabel.Text = 'Threshold';

            % Create ThresholdEditField
            app.ThresholdEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.ThresholdEditField.Position = [123 59 150 22];
            app.ThresholdEditField.Value = 5;

            % Create DistanceEditFieldLabel
            app.DistanceEditFieldLabel = uilabel(app.ParametersPanel);
            app.DistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.DistanceEditFieldLabel.Position = [52 10 52 22];
            app.DistanceEditFieldLabel.Text = 'Distance';

            % Create DistanceEditField
            app.DistanceEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.DistanceEditField.Position = [119 10 154 22];
            app.DistanceEditField.Value = 20;

            % Create MessageWindowTextAreaLabel
            app.MessageWindowTextAreaLabel = uilabel(app.DensityCalculationByCAROIUIFigure);
            app.MessageWindowTextAreaLabel.HorizontalAlignment = 'right';
            app.MessageWindowTextAreaLabel.Position = [72 205 100 22];
            app.MessageWindowTextAreaLabel.Text = 'Message Window';

            % Create MessageWindowTextArea
            app.MessageWindowTextArea = uitextarea(app.DensityCalculationByCAROIUIFigure);
            app.MessageWindowTextArea.Interruptible = 'off';
            app.MessageWindowTextArea.Editable = 'off';
            app.MessageWindowTextArea.Position = [72 26 327 169];

            % Create RunButton
            app.RunButton = uibutton(app.DensityCalculationByCAROIUIFigure, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Position = [187 624 100 35];
            app.RunButton.Text = 'Run';

            % Create ResetButton
            app.ResetButton = uibutton(app.DensityCalculationByCAROIUIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [299 624 100 35];
            app.ResetButton.Text = 'Reset';

            % Show the figure after all components are created
            app.DensityCalculationByCAROIUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ROIbasedDensityCalculation_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.DensityCalculationByCAROIUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.DensityCalculationByCAROIUIFigure)
        end
    end
end