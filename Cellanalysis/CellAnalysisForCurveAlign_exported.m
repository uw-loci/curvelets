classdef CellAnalysisForCurveAlign_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIfigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        TabGroup                       matlab.ui.container.TabGroup
        ImageTab                       matlab.ui.container.Tab
        UITableImageInfo               matlab.ui.control.Table
        ROImanagerTab                  matlab.ui.container.Tab
        Panel                          matlab.ui.container.Panel
        ObjectsPanel                   matlab.ui.container.Panel
        ObjectsselectionDropDown       matlab.ui.control.DropDown
        ObjectsselectionDropDownLabel  matlab.ui.control.Label
        ListObjects                    matlab.ui.control.ListBox
        AnnotationsPanel               matlab.ui.container.Panel
        Panel_3                        matlab.ui.container.Panel
        AddsButton                     matlab.ui.control.Button
        DetectobjectButton             matlab.ui.control.Button
        DeleteButton                   matlab.ui.control.Button
        SelectallButton                matlab.ui.control.Button
        ListAnnotations                matlab.ui.control.ListBox
        LogTab                         matlab.ui.container.Tab
        RightPanel                     matlab.ui.container.Panel
        UIAxes                         matlab.ui.control.UIAxes
        FileMenu                       matlab.ui.container.Menu
        OpenMenu                       matlab.ui.container.Menu
        ImportcellmaskMenu             matlab.ui.container.Menu
        ImportfiberfeaturesfileMenu    matlab.ui.container.Menu
        ExportMenu                     matlab.ui.container.Menu
        ToolsMenu                      matlab.ui.container.Menu
        MoveMenu                       matlab.ui.container.Menu
        RectangleMenu                  matlab.ui.container.Menu
        PolygonMenu                    matlab.ui.container.Menu
        FreehandMenu                   matlab.ui.container.Menu
        ElipseMenu                     matlab.ui.container.Menu
        SpecifyMenu                    matlab.ui.container.Menu
        ViewMenu                       matlab.ui.container.Menu
        ShowanalysispanelMenu          matlab.ui.container.Menu
        ShowannotationsMenu            matlab.ui.container.Menu
        ShowsegmentationsMenu          matlab.ui.container.Menu
        MeasureMenu                    matlab.ui.container.Menu
        MeasurmentmanagerMenu          matlab.ui.container.Menu
        ShowobjectmeasurmentsMenu      matlab.ui.container.Menu
        ShowannotationROImeasurmentsMenu  matlab.ui.container.Menu
        AnalyzeMenu                    matlab.ui.container.Menu
        PreprocessingMenu              matlab.ui.container.Menu
        CellAnalysisMenu               matlab.ui.container.Menu
        TumorregionannotationMenu      matlab.ui.container.Menu
        FiberquantificationMenu        matlab.ui.container.Menu
        TACSscalculationMenu           matlab.ui.container.Menu
        Menu_2                         matlab.ui.container.Menu
        HelpMenu                       matlab.ui.container.Menu
        UsersmanaulMenu                matlab.ui.container.Menu
        GithubWikipageMenu             matlab.ui.container.Menu
        GitHubsourcecodeMenu           matlab.ui.container.Menu
        ContextMenu                    matlab.ui.container.ContextMenu
        Menu                           matlab.ui.container.Menu
        Menu2                          matlab.ui.container.Menu
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = public)
        CAPannotations     % CurveAlign Plus annotations: ROI, tumor regions
        CAPobjects         % CurveAlign Plus objects: cell,fiber, tumor regions
        CAPmeasurements    % CurveAlign Plus measurements: annotations,objects
        figureOptions = struct('plotImage',1,'plotAnnotations',0,'plotObjects','0');
        figureH1
        imageName        %
        imagePath          %
        boundary
        objectsView = struct('Index',[],'boundaryX',[],'boundaryY',[],'centerX',[],'centerY',[],'cellH1',{''},...
            'cellH2',{''},'Selection','','Name','','Type','');  
        annotationView = struct('Index',[],'boundaryX',[],'boundaryY',[],'annotationH1',{''},...
            'annotationH2',{''},'Selection','','Name','','Type','');  
        cellanalysisAPP          % cellanalysisGUI app
        tumoranalysisAPP         % TumorRegionAnnotationGUI app
        objectmeasurementAPP     % show object measurement app
        annotationmeasurementAPP     % show object measurement app
        CAPimage = struct('imageName','','imagePath','','imageInfo','','imageData',[],'CellanalysisMethod','StarDist');  % image structure
    end
    
    methods (Access = private)
        
        function plotImage(app)            
%             app.figureOptions.plotImage = 0;
%             app.figureOptions.plotObjects = 1;
            if app.figureOptions.plotImage == 1
                set(app.UIAxes,'NextPlot','replace');
                app.figureH1 = imshow(app.CAPobjects.imageData2, 'Parent',app.UIAxes); 
            end
            
            if app.figureOptions.plotObjects== 1
                 app.figureH1 = imshow(app.CAPobjects.imageData2, 'Parent',app.UIAxes); 
                % plot individual cells
                objectColor = 'r';
                objectLineWidth = 2;
                objectsTemp = app.CAPobjects.cells.cellArray;
                cellNumber = size(objectsTemp,2);
                app.objectsView.boundaryX = cell(cellNumber,1);
                app.objectsView.boundaryY = cell(cellNumber,1);
                app.objectsView.cellH1 = cell(cellNumber,1);
                for i = 1:cellNumber
                    app.objectsView.index(i) = i;
                    app.objectsView.type{i} = 'cell';
                    boundaryXY =   squeeze(objectsTemp(1,i).boundray);
                    app.objectsView.boundaryX{i} = [boundaryXY(1,:)';boundaryXY(1,1)];
                    app.objectsView.boundaryY{i} = [boundaryXY(2,:)';boundaryXY(2,1)];
                    centerXY = objectsTemp(1,i).position;
                    app.objectsView.centerX(i) = centerXY(1,1);
                    app.objectsView.centerY(i) = centerXY(1,2);
                    app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.type{i},i);
                    set(app.UIAxes,'NextPlot','add');
                    app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryY{i},app.objectsView.boundaryX{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                end  
                    
%                 disp('highlight selected objects...')
%                 pause
%                 app.plotSelection;
               % add the objects to the list
               %ListObjectsValueChanged
               app.ListObjects.Items = app.objectsView.Name;
            end

        end
  
        function plotSelection(app)
            
            % hightlight selected cell(s)
            if app.figureOptions.plotObjects == 1
                cellSelected = app.objectsView.Selection;   %cell selection from the GUI
                cellSelectedNumber = length(cellSelected);
                objectHighlightColor = 'y';
                objectHightLineWidth = 3;
                try
                    highlightedCellNumber = size(app.objectsView.cellH2,1);
                    for ii = 1:highlightedCellNumber
                        delete(app.objectsView.cellH2{ii,1})
                    end
                catch err
                    fprintf('%s \n', err.message)
                end
                app.objectsView.cellH2 = cell(cellSelectedNumber,1);  % initialize the cellH2
                for i = 1: cellSelectedNumber
                    iSelection = cellSelected(i);
                    fprintf('highlight object %d \n',iSelection)
                    set(app.UIAxes,'NextPlot','add');
                    if strcmp(app.CAPimage.CellanalysisMethod,'StarDist')
                        app.objectsView.cellH2{i,1} =plot(app.objectsView.boundaryY{iSelection},...
                            app.objectsView.boundaryX{iSelection},[objectHighlightColor '-'],...
                            'LineWidth',objectHightLineWidth,'Parent',app.UIAxes);
                    else   %cellpose and deepcell
                        app.objectsView.cellH2{i,1} =plot(app.objectsView.boundaryX{iSelection},...
                            app.objectsView.boundaryY{iSelection},[objectHighlightColor '-'],...
                            'LineWidth',objectHightLineWidth,'Parent',app.UIAxes);
                    end
                end
            end
            
                        % hightlight selected cell(s) of annotations
            if app.figureOptions.plotAnnotations == 1
                cellSelected = app.annotationView.Selection;   %cell selection from the GUI
                cellSelectedNumber = length(cellSelected);
                annotationHighlightColor = 'y';
                annotationHightLineWidth = 3;
                try
                    highlightedCellNumber = size(app.annotationView.annotationH2,1);
                    for ii = 1:highlightedCellNumber
                        delete(app.annotationView.annotationH2{ii,1})
                    end
                catch err
                    fprintf('%s \n', err.message)
                end
                app.annotationView.annotationH2 = cell(cellSelectedNumber,1);  % initialize the selected 
                ii = 0;
                for i = cellSelected
                    fprintf('highlight annotation %d \n',i)
                    ii = ii + 1;
                    set(app.UIAxes,'NextPlot','add');
                    app.annotationView.annotationH2{ii,1} =plot(app.annotationView.boundaryY{i},app.annotationView.boundaryX{i},[annotationHighlightColor '-'],'LineWidth',annotationHightLineWidth,'Parent',app.UIAxes);
                end
            end
   
        end
        

    end
    
    methods (Access = public)
        
        function plotImage_public(app)
            if app.figureOptions.plotImage == 1
                set(app.UIAxes,'NextPlot','replace')
                %                 try
                %                     imageData2 = imread(app.CAPannotations.imageName);
                %                 catch
                %                     imageData2 = imread(app.CAPobjects.imageName);
                %                 end
                %                 app.figureH1 = imshow(imageData2, 'Parent',app.UIAxes);
                %                 app.figureH1 = imshow(fullfile(app.imagePath, app.imageName), 'Parent',app.UIAxes);
                app.figureH1 = imagesc(app.CAPimage.imageData, 'Parent',app.UIAxes);
            end

            if app.figureOptions.plotObjects== 1

                % plot individual cells
                objectColor = 'r';
                objectLineWidth = 2;
                objectsTemp = app.CAPobjects.cells.cellArray;
                cellNumber = size(objectsTemp,2);
                app.objectsView.boundaryX = cell(cellNumber,1);
                app.objectsView.boundaryY = cell(cellNumber,1);
                app.objectsView.cellH1 = cell(cellNumber,1);
                if strcmp(app.CAPimage.CellanalysisMethod,'StarDist')
                    for i = 1:cellNumber
                        app.objectsView.index(i) = i;
                        app.objectsView.type{i} = 'cell';
                        boundaryXY =   squeeze(objectsTemp(1,i).boundray);
                        app.objectsView.boundaryX{i} = [boundaryXY(1,:)';boundaryXY(1,1)];
                        app.objectsView.boundaryY{i} = [boundaryXY(2,:)';boundaryXY(2,1)];
                        centerXY = objectsTemp(1,i).position;
                        app.objectsView.centerX(i) = centerXY(1,1);
                        app.objectsView.centerY(i) = centerXY(1,2);
                        app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryY{i},app.objectsView.boundaryX{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                        %                     plot(app.objectsView.centerY(i),app.objectsView.centerX(i),'m.','LineWidth',objectLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                    end

                else  % cellpose or deepcell
                    for i = 1:cellNumber
                        app.objectsView.index(i) = i;
                        app.objectsView.type{i} = 'cell';
                        boundaryXY =   squeeze(objectsTemp(1,i).Boundary);
                        app.objectsView.boundaryX{i} = [boundaryXY(:,1);boundaryXY(1,1)];
                        app.objectsView.boundaryY{i} = [boundaryXY(:,2);boundaryXY(1,2)];
                        centerXY = objectsTemp(1,i).Position;
                        app.objectsView.centerX(i) = centerXY(1,1);
                        app.objectsView.centerY(i) = centerXY(1,2);
                        app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryX{i},app.objectsView.boundaryY{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                    end
                    %                 disp('highlight selected objects...')
                    %                 pause
                    %                 app.plotSelection;
                    % add the objects to the list
                    %ListObjectsValueChanged
                    app.ListObjects.Items = app.objectsView.Name;
                end
            end
            
            if app.figureOptions.plotAnnotations== 1
%                  app.figureH1 = imshow(app.CAPobjects.imageData2, 'Parent',app.UIAxes); 
                % plot individual cells
                annotationColor = 'g';
                annotationLineWidth = 2;
                annotationTemp = app.CAPannotations.tumorAnnotations.tumorArray;
                annotationNumber = size(annotationTemp,2);                
                app.annotationView.boundaryX = cell(annotationNumber,1);
                app.annotationView.boundaryY = cell(annotationNumber,1);  
                app.annotationView.annotationH1 = cell(annotationNumber,1);

                for i = 1:annotationNumber
                    app.annotationView.index(i) = i;
                    app.annotationView.type{i} = 'annotation';
                    boundaryXY =   squeeze(annotationTemp(1,i).boundary);
                    app.annotationView.boundaryX{i} = [boundaryXY(:,1);boundaryXY(1,1)];
                    app.annotationView.boundaryY{i} = [boundaryXY(:,2);boundaryXY(1,2)];
                    app.annotationView.Name{i} = sprintf('%s%d',app.annotationView.type{i},i);
                    set(app.UIAxes,'NextPlot','add');
                    % overlay grid
     %               app.gridplot{i} = plot(annotationTemp(1,i).points(:,2), annotationTemp(1,i).points(:,1), 'r.','Parent',app.UIAxes);  
                    app.annotationView.annotationH1{i,1} =plot(app.annotationView.boundaryY{i},app.annotationView.boundaryX{i},[annotationColor '-'],'LineWidth',annotationLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                end
               app.ListAnnotations.Items = app.annotationView.Name;
            end
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, cellanalysisModule)
            
        end

        % Menu selected function: CellAnalysisMenu
        function CellAnalysisMenuSelected(app, event)
            
          if isempty(app.CAPimage.imageName)
              disp('No image is loaded. Open an image to continue the analysis.')
              return
          end
           app.cellanalysisAPP = cellanalysisGUI(app);      
        end

        % Value changed function: ListObjects
        function ListObjectsValueChanged(app, event)
            itemName = app.ListObjects.Value;   
            app.objectsView.Selection = str2num(strrep(itemName,'cell',''));
            app.plotSelection
        end

        % Menu selected function: ShowobjectmeasurmentsMenu
        function ShowobjectmeasurmentsMenuSelected(app, event)
%             object_data_Name = 'guiTestdata2.mat';object_data_path = pwd;
%             app.CAPobjects = load(fullfile(object_data_path,object_data_Name));
%             app.figureOptions.plotObjects = 1;
%             app.plotImage_public;
            app.objectmeasurementAPP = cellanalysisObjectMeasurement(app);
        end

        % Menu selected function: TumorregionannotationMenu
        function TumorregionannotationMenuSelected(app, event)

          if isempty(app.CAPobjects)
              disp('No cell is detected. Detect cells first to continue the analysis.')
              return
          end
            app.tumoranalysisAPP = TumorRegionAnnotationGUI(app);          
        end

        % Value changed function: ListAnnotations
        function ListAnnotationsValueChanged(app, event)
            itemName = app.ListAnnotations.Value; 
            app.annotationView.Selection = str2num(strrep(itemName,'annotation',''));
            app.figureOptions.plotAnnotions = 1;
            app.plotSelection
        end

        % Close request function: UIfigure
        function UIfigureCloseRequest(app, event)
             delete(app.cellanalysisAPP)
             delete(app.tumoranalysisAPP)
             delete(app.objectmeasurementAPP)
             delete(app.annotationmeasurementAPP)
             delete(app)
           
        end

        % Button pushed function: DetectobjectButton
        function DetectobjectButtonPushed(app, event)
            % detect the objects within the selected annotation
            nrow = 512;
            ncol = 512;
            itemName = app.ListAnnotations.Value;
            annotationIndex = str2num(strrep(itemName,'annotation',''));
            app.CAPannotations
            tumorX = app.annotationView.boundaryX{annotationIndex};
            tumorY = app.annotationView.boundaryY{annotationIndex};
            tumorsingleMask = poly2mask(tumorY,tumorX,nrow,ncol);
            objectNumber = size(app.CAPobjects.cells.cellArray,2);
            cellsFlag = zeros(objectNumber,1);
            for ic = 1:objectNumber
                cellcenterY = app.objectsView.centerY(ic);%cells(ic,1)(ic,1);
                cellcenterX = app.objectsView.centerX(ic);%cellCenters(ic,2);
                if cellcenterX > ncol
                    fprintf('Object %d is out of boundary centerX%d > Image width%d \n', ic, cellcenterX,ncol);
                    cellcenterX = ncol;
                end
                if cellcenterY > nrow
                    fprintf('Object %d is out of boundary centerX%d > Image Height%d \n', ic, cellcenterY,nrow);
                    cellcenterY = nrow;
                end

                if tumorsingleMask(cellcenterX,cellcenterY) == 1   % 
                    cellsFlag(ic) = 1;
                end
            end
            objectinTumorFlag = find(cellsFlag == 1);
            app.figureOptions.plotObjects = 1;
            app.figureOptions.plotAnnotations = 0;
            app.objectsView.Selection = objectinTumorFlag;
            app.annotationView.Selection = annotationIndex;
            if ~isempty(objectinTumorFlag)
            app.plotSelection;
            selectedNumber = length(objectinTumorFlag);
            selectedObjectName = cell(selectedNumber,1);
            for i = 1:selectedNumber
              selectedObjectName{i,1} = app.objectsView.Name{objectinTumorFlag(i)};
            end
            app.ListObjects.Items = selectedObjectName;
            end
            
        end

        % Menu selected function: ShowannotationROImeasurmentsMenu
        function ShowannotationROImeasurmentsMenuSelected(app, event)
            
        end

        % Menu selected function: OpenMenu
        function OpenMenuSelected(app, event)

            [imageGet, pathGet]=uigetfile({'*.tif';'*.png';'*.jpeg';'*.*'},'Select Cell Images',pwd,'MultiSelect','off'); 
            if ~isempty(imageGet) && ~isempty(pathGet)
                delete(app);
                app = CellAnalysisForCurveAlign; % reset app
                app.imageName = imageGet;
                app.imagePath = pathGet;
                app.CAPimage.imageName = imageGet;
                app.CAPimage.imagePath = pathGet;
                app.CAPimage.imageInfo = imfinfo(fullfile(pathGet,imageGet));
                app.CAPimage.imageData = imread(fullfile(pathGet,imageGet));
                
            else
                return
            end
            %listImageInform;
           %app.UITable.ColumnName = {'Name','Value'};
            imageInfo = app.CAPimage.imageInfo; %imfinfo(fullfile(app.imagePath,app.imageName));
            tableData{1,1} = 'Image Name';
            tableData{2,1} =  'Image Path'; 
            tableData{3,1} =  'Height';
            tableData{4,1} =  'Width';
            tableData{5,1} =  'BitDepth';
            tableData{6,1} =  'Xresolution';
            tableData{7,1} =  'Yresolution';
            tableData{8,1} =  'Resolution Unit';
            tableData{9,1} =  'Others:';
            tableData{1,2} = app.imageName;
            tableData{2,2} = app.imagePath; 
            tableData{3,2}= num2str(imageInfo.Height); 
            tableData{4,2}= num2str(imageInfo.Width);
            tableData{5,2}= num2str(imageInfo.BitDepth);
            tableData{6,2}= num2str(imageInfo.XResolution);
            tableData{7,2}= num2str(imageInfo.YResolution);
            tableData{8,2}= imageInfo.ResolutionUnit;
            tableData{9,2}= '';
            app.UITableImageInfo.Data = tableData;
            
            %display image
            app.figureOptions.plotImage = 1;
            app.plotImage_public;
            %imshow(fullfile(app.imagePath,app.imageName),"Parent",app.UIAxes)
            
        end

        % Button down function: ImageTab
        function ImageTabButtonDown(app, event)
            if isempty(app.imageName)
                OpenMenuSelected(app)
            end
        end

        % Value changed function: ObjectsselectionDropDown
        function ObjectsselectionDropDownValueChanged(app, event)
            value = app.ObjectsselectionDropDown.Value;
            if strcmp(value, 'None')

            elseif strcmp(value,'All')

            else

            end
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIfigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {723, 723};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {493, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIfigure and hide until all components are created
            app.UIfigure = uifigure('Visible', 'off');
            app.UIfigure.AutoResizeChildren = 'off';
            app.UIfigure.Position = [100 100 1243 723];
            app.UIfigure.Name = 'Cell Analysis for CurveAlign+';
            app.UIfigure.CloseRequestFcn = createCallbackFcn(app, @UIfigureCloseRequest, true);
            app.UIfigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIfigure);
            app.GridLayout.ColumnWidth = {493, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [7 24 458 672];

            % Create ImageTab
            app.ImageTab = uitab(app.TabGroup);
            app.ImageTab.Title = 'Image';
            app.ImageTab.ButtonDownFcn = createCallbackFcn(app, @ImageTabButtonDown, true);

            % Create UITableImageInfo
            app.UITableImageInfo = uitable(app.ImageTab);
            app.UITableImageInfo.ColumnName = {'Name'; 'Value'};
            app.UITableImageInfo.RowName = {};
            app.UITableImageInfo.Position = [2 1 456 647];

            % Create ROImanagerTab
            app.ROImanagerTab = uitab(app.TabGroup);
            app.ROImanagerTab.Title = 'ROI manager';

            % Create Panel
            app.Panel = uipanel(app.ROImanagerTab);
            app.Panel.Position = [0 31 457 604];

            % Create AnnotationsPanel
            app.AnnotationsPanel = uipanel(app.Panel);
            app.AnnotationsPanel.Title = 'Annotations';
            app.AnnotationsPanel.Position = [1 1 260 601];

            % Create ListAnnotations
            app.ListAnnotations = uilistbox(app.AnnotationsPanel);
            app.ListAnnotations.Items = {};
            app.ListAnnotations.ValueChangedFcn = createCallbackFcn(app, @ListAnnotationsValueChanged, true);
            app.ListAnnotations.Position = [12 111 199 467];
            app.ListAnnotations.Value = {};

            % Create Panel_3
            app.Panel_3 = uipanel(app.AnnotationsPanel);
            app.Panel_3.Position = [12 7 212 79];

            % Create SelectallButton
            app.SelectallButton = uibutton(app.Panel_3, 'push');
            app.SelectallButton.Position = [1 11 100 22];
            app.SelectallButton.Text = 'Select all';

            % Create DeleteButton
            app.DeleteButton = uibutton(app.Panel_3, 'push');
            app.DeleteButton.Position = [108 11 100 22];
            app.DeleteButton.Text = 'Delete';

            % Create DetectobjectButton
            app.DetectobjectButton = uibutton(app.Panel_3, 'push');
            app.DetectobjectButton.ButtonPushedFcn = createCallbackFcn(app, @DetectobjectButtonPushed, true);
            app.DetectobjectButton.Position = [2 42 100 22];
            app.DetectobjectButton.Text = 'Detect object';

            % Create AddsButton
            app.AddsButton = uibutton(app.Panel_3, 'push');
            app.AddsButton.Position = [108 42 100 22];
            app.AddsButton.Text = 'Add(s)';

            % Create ObjectsPanel
            app.ObjectsPanel = uipanel(app.Panel);
            app.ObjectsPanel.Title = 'Objects';
            app.ObjectsPanel.Position = [239 1 217 601];

            % Create ListObjects
            app.ListObjects = uilistbox(app.ObjectsPanel);
            app.ListObjects.Items = {};
            app.ListObjects.ValueChangedFcn = createCallbackFcn(app, @ListObjectsValueChanged, true);
            app.ListObjects.Position = [21 111 171 467];
            app.ListObjects.Value = {};

            % Create ObjectsselectionDropDownLabel
            app.ObjectsselectionDropDownLabel = uilabel(app.ObjectsPanel);
            app.ObjectsselectionDropDownLabel.HorizontalAlignment = 'right';
            app.ObjectsselectionDropDownLabel.Position = [1 59 98 22];
            app.ObjectsselectionDropDownLabel.Text = 'Objects selection';

            % Create ObjectsselectionDropDown
            app.ObjectsselectionDropDown = uidropdown(app.ObjectsPanel);
            app.ObjectsselectionDropDown.Items = {'Nuclei', 'Whole cell', 'Collagen', 'All', 'None'};
            app.ObjectsselectionDropDown.ValueChangedFcn = createCallbackFcn(app, @ObjectsselectionDropDownValueChanged, true);
            app.ObjectsselectionDropDown.Position = [52 12 159 28];
            app.ObjectsselectionDropDown.Value = 'Nuclei';

            % Create LogTab
            app.LogTab = uitab(app.TabGroup);
            app.LogTab.Title = 'Log';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.BorderType = 'none';
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [48 24 648 672];

            % Create FileMenu
            app.FileMenu = uimenu(app.UIfigure);
            app.FileMenu.Text = 'File';

            % Create OpenMenu
            app.OpenMenu = uimenu(app.FileMenu);
            app.OpenMenu.MenuSelectedFcn = createCallbackFcn(app, @OpenMenuSelected, true);
            app.OpenMenu.Text = 'Open...';

            % Create ImportcellmaskMenu
            app.ImportcellmaskMenu = uimenu(app.FileMenu);
            app.ImportcellmaskMenu.Text = 'Import cell mask...';

            % Create ImportfiberfeaturesfileMenu
            app.ImportfiberfeaturesfileMenu = uimenu(app.FileMenu);
            app.ImportfiberfeaturesfileMenu.Text = 'Import fiber features file..';

            % Create ExportMenu
            app.ExportMenu = uimenu(app.FileMenu);
            app.ExportMenu.Text = 'Export';

            % Create ToolsMenu
            app.ToolsMenu = uimenu(app.UIfigure);
            app.ToolsMenu.Text = 'Tools';

            % Create MoveMenu
            app.MoveMenu = uimenu(app.ToolsMenu);
            app.MoveMenu.Text = 'Move';

            % Create RectangleMenu
            app.RectangleMenu = uimenu(app.ToolsMenu);
            app.RectangleMenu.Text = 'Rectangle';

            % Create PolygonMenu
            app.PolygonMenu = uimenu(app.ToolsMenu);
            app.PolygonMenu.Text = 'Polygon';

            % Create FreehandMenu
            app.FreehandMenu = uimenu(app.ToolsMenu);
            app.FreehandMenu.Text = 'Free hand';

            % Create ElipseMenu
            app.ElipseMenu = uimenu(app.ToolsMenu);
            app.ElipseMenu.Text = 'Elipse';

            % Create SpecifyMenu
            app.SpecifyMenu = uimenu(app.ToolsMenu);
            app.SpecifyMenu.Text = 'Specify';

            % Create ViewMenu
            app.ViewMenu = uimenu(app.UIfigure);
            app.ViewMenu.Text = 'View';

            % Create ShowanalysispanelMenu
            app.ShowanalysispanelMenu = uimenu(app.ViewMenu);
            app.ShowanalysispanelMenu.Text = 'Show analysis panel';

            % Create ShowannotationsMenu
            app.ShowannotationsMenu = uimenu(app.ViewMenu);
            app.ShowannotationsMenu.Text = 'Show annotations';

            % Create ShowsegmentationsMenu
            app.ShowsegmentationsMenu = uimenu(app.ViewMenu);
            app.ShowsegmentationsMenu.Text = 'Show segmentations';

            % Create MeasureMenu
            app.MeasureMenu = uimenu(app.UIfigure);
            app.MeasureMenu.Text = 'Measure';

            % Create MeasurmentmanagerMenu
            app.MeasurmentmanagerMenu = uimenu(app.MeasureMenu);
            app.MeasurmentmanagerMenu.Text = 'Measurment manager';

            % Create ShowobjectmeasurmentsMenu
            app.ShowobjectmeasurmentsMenu = uimenu(app.MeasureMenu);
            app.ShowobjectmeasurmentsMenu.MenuSelectedFcn = createCallbackFcn(app, @ShowobjectmeasurmentsMenuSelected, true);
            app.ShowobjectmeasurmentsMenu.Text = 'Show object measurments';

            % Create ShowannotationROImeasurmentsMenu
            app.ShowannotationROImeasurmentsMenu = uimenu(app.MeasureMenu);
            app.ShowannotationROImeasurmentsMenu.MenuSelectedFcn = createCallbackFcn(app, @ShowannotationROImeasurmentsMenuSelected, true);
            app.ShowannotationROImeasurmentsMenu.Text = 'Show annotation(ROI) measurments';

            % Create AnalyzeMenu
            app.AnalyzeMenu = uimenu(app.UIfigure);
            app.AnalyzeMenu.Text = 'Analyze';

            % Create PreprocessingMenu
            app.PreprocessingMenu = uimenu(app.AnalyzeMenu);
            app.PreprocessingMenu.Text = 'Preprocessing';

            % Create CellAnalysisMenu
            app.CellAnalysisMenu = uimenu(app.AnalyzeMenu);
            app.CellAnalysisMenu.MenuSelectedFcn = createCallbackFcn(app, @CellAnalysisMenuSelected, true);
            app.CellAnalysisMenu.Text = 'Cell Analysis';

            % Create TumorregionannotationMenu
            app.TumorregionannotationMenu = uimenu(app.AnalyzeMenu);
            app.TumorregionannotationMenu.MenuSelectedFcn = createCallbackFcn(app, @TumorregionannotationMenuSelected, true);
            app.TumorregionannotationMenu.Text = 'Tumor region annotation';

            % Create FiberquantificationMenu
            app.FiberquantificationMenu = uimenu(app.AnalyzeMenu);
            app.FiberquantificationMenu.Text = 'Fiber quantification';

            % Create TACSscalculationMenu
            app.TACSscalculationMenu = uimenu(app.AnalyzeMenu);
            app.TACSscalculationMenu.Text = 'TACSs calculation';

            % Create Menu_2
            app.Menu_2 = uimenu(app.UIfigure);

            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIfigure);
            app.HelpMenu.Text = 'Help';

            % Create UsersmanaulMenu
            app.UsersmanaulMenu = uimenu(app.HelpMenu);
            app.UsersmanaulMenu.Text = 'User''s manaul';

            % Create GithubWikipageMenu
            app.GithubWikipageMenu = uimenu(app.HelpMenu);
            app.GithubWikipageMenu.Text = 'Github Wiki page';

            % Create GitHubsourcecodeMenu
            app.GitHubsourcecodeMenu = uimenu(app.HelpMenu);
            app.GitHubsourcecodeMenu.Text = 'GitHub source code';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIfigure);

            % Create Menu
            app.Menu = uimenu(app.ContextMenu);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.ContextMenu);
            app.Menu2.Text = 'Menu2';
            
            % Assign app.ContextMenu
            app.LeftPanel.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.UIfigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CellAnalysisForCurveAlign_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIfigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIfigure)
        end
    end
end