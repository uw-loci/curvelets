classdef CellAnalysisForCurveAlign_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIfigure                       matlab.ui.Figure
        FileMenu                       matlab.ui.container.Menu
        OpenMenu                       matlab.ui.container.Menu
        ImportcellmaskMenu             matlab.ui.container.Menu
        ImportfiberfeaturesfileMenu    matlab.ui.container.Menu
        ExportMenu                     matlab.ui.container.Menu
        ToolsMenu                      matlab.ui.container.Menu
        RectangleMenu                  matlab.ui.container.Menu
        PolygonMenu                    matlab.ui.container.Menu
        FreehandMenu                   matlab.ui.container.Menu
        EllipseMenu                    matlab.ui.container.Menu
        SpecifiedRECTMenu              matlab.ui.container.Menu
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
        GitHubWikipageMenu             matlab.ui.container.Menu
        GitHubsourcecodeMenu           matlab.ui.container.Menu
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        TabGroup                       matlab.ui.container.TabGroup
        ImageTab                       matlab.ui.container.Tab
        UITableImageInfo               matlab.ui.control.Table
        ROImanagerTab                  matlab.ui.container.Tab
        Panel                          matlab.ui.container.Panel
        ObjectsPanel                   matlab.ui.container.Panel
        SetAnnotationButton            matlab.ui.control.Button
        SelectionDropDown              matlab.ui.control.DropDown
        ListObjects                    matlab.ui.control.ListBox
        AnnotationsPanel               matlab.ui.container.Panel
        ListAnnotations                matlab.ui.control.ListBox
        Panel_3                        matlab.ui.container.Panel
        DrawdButton                    matlab.ui.control.Button
        AddtButton                     matlab.ui.control.Button
        DetectobjectButton             matlab.ui.control.Button
        DeleterButton                  matlab.ui.control.Button
        PythonEnvironmentTab           matlab.ui.container.Tab
        LoadPythonInterpreterButton    matlab.ui.control.Button
        TerminatePythonInterpreterButton  matlab.ui.control.Button
        UpdatePyenvButton              matlab.ui.control.Button
        InsertpathButton               matlab.ui.control.Button
        pyenvStatus                    matlab.ui.control.TextArea
        pyenvStatusTextAreaLabel       matlab.ui.control.Label
        EXEmodeDropDown                matlab.ui.control.DropDown
        EXEmodeDropDownLabel           matlab.ui.control.Label
        PythonSearchPath               matlab.ui.control.TextArea
        PythonSearchPathTextAreaLabel  matlab.ui.control.Label
        PathtoPythonInstallation       matlab.ui.control.TextArea
        PathtoPythonInstallationLabel  matlab.ui.control.Label
        LogTab                         matlab.ui.container.Tab
        RightPanel                     matlab.ui.container.Panel
        UIAxes                         matlab.ui.control.UIAxes
        ContextMenu                    matlab.ui.container.ContextMenu
        Menu                           matlab.ui.container.Menu
        Menu2                          matlab.ui.container.Menu
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end


    properties (Access = public)
        CAPannotations= struct('tumorAnnotations','','cellAnnotations','',...
            'fiberAnnotations','','customAnnotations','','cellDetectionFlag',0,'fiberDetectionFlag',0);     % CurveAlign Plus annotations: ROI, tumor regions
        CAPobjects = struct('cells','','fibers','');         % CurveAlign Plus objects: cell,fiber, tumor regions
        CAPmeasurements    % CurveAlign Plus measurements: annotations,objects
        figureOptions = struct('plotImage',1,'plotAnnotations',0,'plotObjects','0','plotFibers',0);
        figureH1
        imageName        %
        imagePath
        fiberdataFile
        fiberdataPath%
        boundary
        objectsView = struct('Index',[],'boundaryX',[],'boundaryY',[],'centerX',[],'centerY',[],'cellH1',{''},...
            'cellH2',{''},'Selection','','Name','','Type','');
        fibersView = struct('Index',[],'centerX',[],'centerY',[],'Orientation',nan,'fiberH1',{''},'fiberH1b',{''},...
            'fiberH2',{''},'fiberH2b',{''},'Selection','','Name','','Type','');
        annotationView = struct('Index',[],'boundaryX',[],'boundaryY',[],'annotationH1',{''},...
            'annotationH2',{''},'Selection','','Name','','Type',{''},'Stats',[]);  % annotationType: 'tumor','SingleCell','custom_annotation','
        cellanalysisAPP          % cellanalysisGUI app
        tumoranalysisAPP         % TumorRegionAnnotationGUI app
        objectmeasurementAPP     % show object measurement app
        annotationmeasurementAPP     % show object measurement app
        CAPimage = struct('imageName','','imagePath','','imageInfo','','imageData',[],'CellanalysisMethod','StarDist');  % image structure
        setMeasurementsAPP       % set parameters for the measurement
        measurementsSettings = struct('relativeAngleFlag',1, 'distance2boundary', 100,...
            'excludeInboundaryfiberFlag',0,'saveMeasurementsdataFlag',1,'saveMeasurementsfigFlag',0,'plotAssociationFlag',1); % default measurements settings
        annotationType = 'tumor'; % annotationType: 'tumor','SingleCell','custom_annotation','

        mype; % my python environment
    end

    properties (Access = private)
        annotationShape = []; % Description
        ROIshapes = {'Rectangle','Polygon','Freehand','Ellipse','SpecifiedRECT'};
        annotationDrawing % Handle to draw the annotation
        drawingFuncs = {@drawrectangle,@drawpolygon,@drawfreehand,@drawellipse,@drawspecifiedRECT}; % annotation drawing functions
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
                    app.objectsView.Index(i) = i;
                    app.objectsView.Type{i} = 'cell';
                    boundaryXY =   squeeze(objectsTemp(1,i).boundray);
                    app.objectsView.boundaryX{i} = [boundaryXY(1,:)';boundaryXY(1,1)];
                    app.objectsView.boundaryY{i} = [boundaryXY(2,:)';boundaryXY(2,1)];
                    centerXY = objectsTemp(1,i).position;
                    app.objectsView.centerX(i) = centerXY(1,1);
                    app.objectsView.centerY(i) = centerXY(1,2);
                    app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.Type{i},i);
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
                    % fprintf('highlight cell %d \n',iSelection)
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

            % hightlight selected fiber(s)
            if app.figureOptions.plotFibers == 1
                fiberSelected = app.fibersView.Selection;   %cell selection from the GUI
                fiberSelectedNumber = length(fiberSelected);
                objectHighlightColor = 'y';
                objectHightLineWidth = 3;
                try
                    highlightedFiberNumber = size(app.fibersView.fiberH2,1);
                    for ii = 1:highlightedFiberNumber
                        delete(app.fibersView.fiberH2{ii,1})
                    end
                catch err
                    fprintf('%s \n', err.message)
                end
                app.fibersView.fiberH2 = cell(fiberSelectedNumber,1);  % initialize the fiberH2
                for i = 1: fiberSelectedNumber
                    iSelection = fiberSelected(i);
                    % fprintf('highlight fiber %d \n',iSelection)
                    set(app.UIAxes,'NextPlot','add');
                    if strcmp(app.CAPimage.CellanalysisMethod,'StarDist')
                        fiberEndX12 = app.fibersView.fiberEndsX{iSelection,1};
                        fiberEndY12 =  app.fibersView.fiberEndsY{iSelection,1};
                        app.fibersView.fiberH2{i,1} = plot(fiberEndX12,...
                            fiberEndY12,[objectHighlightColor '-'],...
                            'LineWidth',objectHightLineWidth,'Parent',app.UIAxes);
                    else   %cellpose and deepcell
                        %                         app.objectsView.cellH2{i,1} =plot(app.objectsView.boundaryX{iSelection},...
                        %                             app.objectsView.boundaryY{iSelection},[objectHighlightColor '-'],...
                        %                             'LineWidth',objectHightLineWidth,'Parent',app.UIAxes);
                        disp('fiber analysis for whole cell is not available.')
                        return
                    end
                end
            end

            % hightlight selected cell(s) of annotations
            if app.figureOptions.plotAnnotations == 1
                item_selected = app.ListAnnotations.Value;
                itemIndex = find(strcmp(app.ListAnnotations.Items,item_selected) == 1);
                cellSelected = itemIndex;%app.annotationView.Selection;   %cell selection from the GUI
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
                    % fprintf('highlight annotation %d \n',i)
                    ii = ii + 1;
                    set(app.UIAxes,'NextPlot','add');
                    app.annotationView.annotationH2{ii,1} =plot(app.annotationView.boundaryX{i},app.annotationView.boundaryY{i},...
                        [annotationHighlightColor '-'],'LineWidth',annotationHightLineWidth,'Parent',app.UIAxes);
                end
            end

        end
        
        function add_annotation(app)
            disp('add annotation to the list')
            if strcmp(app.annotationType,'custom_annotation')
                if ~isempty(app.annotationDrawing)
                    % annotationView = struct('Index',[],'boundaryX',[],'boundaryY',[],'annotationH1',{''},...
                    % 'annotationH2',{''},'Selection','','Name','','Type','tumor');  % annotationType: 'tumor','SingleCell','custom_annotation','
                    % app.annotationView.Type = {'custom_annotation'};
                    app.figureOptions.plotImage = 0;
                    app.figureOptions.plotObjects = 0;
                    app.figureOptions.plotFibers = 0;
                    app.figureOptions.plotAnnotations = 1;
                    app.plotImage_public
                else
                    fprintf('No annotation can be drawn \n')
                end
            elseif strcmp(app.annotationType,'cell_computed')
                disp('Adding computed cell as an annotaiton')
                app.figureOptions.plotImage = 0;
                app.figureOptions.plotObjects = 0;
                app.figureOptions.plotFibers = 0;
                app.figureOptions.plotAnnotations = 1;
                app.plotImage_public
            elseif strcmp(app.annotationType,'fiber_computed')
                disp('Adding computed fiiber as an annotaiton')
                disp('No available at this point')
            else
                fprintf('No annotation is added \n')
            end

        end
        
        function measure_annotation(app)
            % add statistics for the custom boundary
            item_index = app.annotationView.Selection;  %single 
            annotationBoundaryCol = double(app.annotationView.boundaryX{item_index});
            annotationBoundaryRow = double(app.annotationView.boundaryY{item_index});
            nrow = app.CAPimage.imageInfo.Height;
            ncol = app.CAPimage.imageInfo.Width;
            annotationMask = poly2mask(annotationBoundaryCol,annotationBoundaryRow,nrow,ncol);
            stats = regionprops(annotationMask,'Centroid','Area','Perimeter','Orientation');
            app.CAPmeasurements.Mask{item_index,1} = annotationMask;
            app.CAPmeasurements.Centroid{item_index,1} = stats.Centroid;
            app.CAPmeasurements.Area{item_index,1} = stats.Area;
            app.CAPmeasurements.Perimeter{item_index,1} = stats.Perimeter;
            app.CAPmeasurements.Orientation{item_index,1} = stats.Orientation;
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
                app.figureH1 = imagesc(app.CAPimage.imageData,'HitTest','off', 'Parent',app.UIAxes);
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
                app.objectsView.Name = cell(cellNumber,1);
                cellsViewH = findall(app.UIAxes,'Type','Line','Tag','cellsView');
                if ~isempty(cellsViewH)
                    delete(cellsViewH);
                end
                if strcmp(app.CAPimage.CellanalysisMethod,'StarDist')
                    for i = 1:cellNumber
                        app.objectsView.Index(i) = i;
                        app.objectsView.Type{i} = 'cell';
                        boundaryXY =   flip(squeeze(objectsTemp(1,i).boundray)); %boundaryYX ->boundaryXY
                        app.objectsView.boundaryX{i} = [boundaryXY(1,:)';boundaryXY(1,1)];
                        app.objectsView.boundaryY{i} = [boundaryXY(2,:)';boundaryXY(2,1)];
                        centerXY = objectsTemp(1,i).position;
                        app.objectsView.centerX(i) = centerXY(1,1);
                        app.objectsView.centerY(i) = centerXY(1,2);
                        app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.Type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryX{i},app.objectsView.boundaryY{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes,'Tag','cellsView'); % 'Parent',figureH2)
                        %                     plot(app.objectsView.centerY(i),app.objectsView.centerX(i),'m.','LineWidth',objectLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                    end
                    app.SelectionDropDown.Value = app.SelectionDropDown.Items{1};

                elseif strcmp(app.CAPimage.CellanalysisMethod,'Cellpose') || strcmp(app.CAPimage.CellanalysisMethod,'DeepCell') % cellpose or deepcell
                    for i = 1:cellNumber
                        app.objectsView.Index(i) = i;
                        app.objectsView.Type{i} = 'cell';
                        boundaryXY =   squeeze(objectsTemp(1,i).Boundary);
                        app.objectsView.boundaryX{i} = [boundaryXY(:,1);boundaryXY(1,1)];
                        app.objectsView.boundaryY{i} = [boundaryXY(:,2);boundaryXY(1,2)];
                        centerXY = objectsTemp(1,i).Position;
                        app.objectsView.centerX(i) = centerXY(1,1);
                        app.objectsView.centerY(i) = centerXY(1,2);
                        app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.Type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryX{i},app.objectsView.boundaryY{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes,'Tag','cellsView');
                        app.SelectionDropDown.Value =  app.SelectionDropDown.Items{1};
                    end
                elseif strcmp(app.CAPimage.CellanalysisMethod,'FromMaskfiles-SD')  % from StarDist mask files
                    for i = 1:cellNumber
                        app.objectsView.Index(i) = i;
                        app.objectsView.Type{i} = 'cell';
                        boundaryXY =   flip(squeeze(objectsTemp(1,i).boundray));  %boundaryYX ->boundaryXY
                        app.objectsView.boundaryX{i} = [boundaryXY(1,:)';boundaryXY(1,1)];
                        app.objectsView.boundaryY{i} = [boundaryXY(2,:)';boundaryXY(2,1)];
                        centerXY = objectsTemp(1,i).position;
                        app.objectsView.centerX(i) = centerXY(1,1);
                        app.objectsView.centerY(i) = centerXY(1,2);
                        app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.Type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryX{i},app.objectsView.boundaryY{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes,'Tag','cellsView'); % 'Parent',figureH2)
                        %                     plot(app.objectsView.centerY(i),app.objectsView.centerX(i),'m.','LineWidth',objectLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                    end
                    app.SelectionDropDown.Value = app.SelectionDropDown.Items{1};

                elseif strcmp(app.CAPimage.CellanalysisMethod,'FromMask-others')  %  mask from cellpose or deepcell
                    for i = 1:cellNumber
                        app.objectsView.Index(i) = i;
                        app.objectsView.Type{i} = 'cell';
                        boundaryXY =   squeeze(objectsTemp(1,i).Boundary);
                        app.objectsView.boundaryX{i} = [boundaryXY(:,1);boundaryXY(1,1)];
                        app.objectsView.boundaryY{i} = [boundaryXY(:,2);boundaryXY(1,2)];
                        centerXY = objectsTemp(1,i).Position;
                        app.objectsView.centerX(i) = centerXY(1,1);
                        app.objectsView.centerY(i) = centerXY(1,2);
                        app.objectsView.Name{i} = sprintf('%s%d',app.objectsView.Type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        app.objectsView.cellH1{i,1} =plot(app.objectsView.boundaryX{i},app.objectsView.boundaryY{i},[objectColor '-'],'LineWidth',objectLineWidth, 'Parent',app.UIAxes,'Tag','cellsView');
                        app.SelectionDropDown.Value =  app.SelectionDropDown.Items{1};
                    end
                    
                end

                % add the objects to the list
                %ListObjectsValueChanged
                app.ListObjects.Items = app.objectsView.Name;
            end

            if app.figureOptions.plotFibers == 1
                % plot individual fibers
                fiberColor = 'g';
                fiberLineWidth = 2;
                fibersTemp = app.CAPobjects.fibers.fibFeat;
                fiberNumber = size(fibersTemp,1);
                app.fibersView.centerX = cell(fiberNumber,1);
                app.fibersView.centerY = cell(fiberNumber,1);
                app.fibersView.cellH1 = cell(fiberNumber,1);
                app.fibersView.cellH1b = app.fibersView.cellH1;
                app.fibersView.fiberEndsX = cell(fiberNumber,1);
                app.fibersView.fiberEndsY = cell(fiberNumber,1);
                app.fibersView.orientation = cell(fiberNumber,1);
                app.fibersView.Name = cell(fiberNumber,1);
                if strcmp(app.CAPimage.CellanalysisMethod,'StarDist')
                    fiberBDwidth = 1;
                    fiberCenterMarkerSize = 3;
                    fiberLength = 5;
                    fiberEndsXY = cell(fiberNumber,1);
                    for ii = 1: fiberNumber
                        fiberAngles(ii) = fibersTemp(ii,4);
                        ca = fiberAngles(ii)*pi/180;
                        xc(ii) = fibersTemp(ii,3); % column
                        yc(ii) = fibersTemp(ii,2); % row
                        % show curvelet/fiber direction
                        xc1 = (xc(ii) - fiberLength * cos(ca));
                        xc2 = (xc(ii) + fiberLength * cos(ca));
                        yc1 = (yc(ii) + fiberLength * sin(ca));
                        yc2 = (yc(ii) - fiberLength * sin(ca));
                        app.fibersView.fiberEndsX{ii,1} = [xc1;xc2];
                        app.fibersView.fiberEndsY{ii,1} = [yc1;yc2];

                    end

                    for i = 1:fiberNumber
                        app.fibersView.index(i) = i;
                        app.fibersView.type{i} = 'fiber';
                        app.fibersView.centerX{i} = xc(i);
                        app.fibersView.centerY{i} = yc(i);
                        app.fibersView.orientation{i} = fiberAngles(i);
                        app.fibersView.Name{i} = sprintf('%s%d','fiber',i);
                        set(app.UIAxes,'NextPlot','add');
                        fiberEndX12 = app.fibersView.fiberEndsX{i,1};
                        fiberEndY12 =  app.fibersView.fiberEndsY{i,1};
                        app.fibersView.fiberH1{i,1} =plot(fiberEndX12,fiberEndY12,[fiberColor '-'],'LineWidth',fiberLineWidth, 'Parent',app.UIAxes); % 'Parent',figureH2)
                        app.fibersView.fiberH1b{i,1} = plot(xc(i),yc(i),'r.','MarkerSize',fiberCenterMarkerSize,'Parent',app.UIAxes); % show curvelet/fiber center
                    end
                    app.SelectionDropDown.Value =  app.SelectionDropDown.Items{3};

                else  % cellpose or deepcell
                    disp('NO annotation is available for full cell segmentaion.')
                    return
                end

                % add the objects to the list
                %ListObjectsValueChanged
                app.ListObjects.Items = [app.objectsView.Name; app.fibersView.Name];
            end

            if app.figureOptions.plotAnnotations== 1
                %                  app.figureH1 = imshow(app.CAPobjects.imageData2, 'Parent',app.UIAxes);
                % plot individual cells
                annotationColor = 'm';
                annotationLineWidth = 2;
                if strcmp(app.annotationType,'tumor')
                    % delete the previous annotations
                    try
                        app.ListAnnotations.Items = {''};
                        AHnumber = size(app.annotationView.annotationH1,1);
                        for i = 1: AHnumber
                            delete(app.annotationView.annotationH1{i,1});
                        end

                    catch ME
                        fprintf('%s \n', ME.message)
                    end
                    annotationTemp = app.CAPannotations.tumorAnnotations.tumorArray;
                    annotationNumber = size(annotationTemp,2);
                    app.annotationView.boundaryX = cell(annotationNumber,1);
                    app.annotationView.boundaryY = cell(annotationNumber,1);
                    app.annotationView.annotationH1 = cell(annotationNumber,1);
                    app.annotationView.Name = cell(annotationNumber,1);
                    for i = 1:annotationNumber
                        app.annotationView.Index(i) = i;
                        % app.annotationView.Type{i} = 'annotation';
                        boundaryYX =   squeeze(annotationTemp(1,i).boundary);
                        app.annotationView.boundaryX{i} = [boundaryYX(:,2);boundaryYX(1,2)];
                        app.annotationView.boundaryY{i} = [boundaryYX(:,1);boundaryYX(1,1)];
                        app.annotationView.Name{i} = sprintf('%s%d',app.annotationView.Type{i},i);
                        set(app.UIAxes,'NextPlot','add');
                        % overlay grid
                        %               app.gridplot{i} = plot(annotationTemp(1,i).points(:,2), annotationTemp(1,i).points(:,1), 'r.','Parent',app.UIAxes);
                        app.annotationView.annotationH1{i,1} =plot(app.annotationView.boundaryX{i},app.annotationView.boundaryY{i},...
                            [annotationColor '-'],'LineWidth',annotationLineWidth,'Tag',app.annotationView.Name{i}, 'Parent',app.UIAxes); % 'Parent',figureH2)
                        app.annotationView.Selection = i;
                        app.measure_annotation;
                    end
                    app.ListAnnotations.Items = app.annotationView.Name;

                elseif strcmp(app.annotationType,'custom_annotation') % add custom annotation one by one
                    if strcmp(app.annotationShape,'Rectangle') || strcmp(app.annotationShape,'Ellipse')
                        annotationTemp = app.annotationDrawing.Vertices; %Position; % position of current drawn annotation
                    elseif strcmp(app.annotationShape,'Freehand') || strcmp(app.annotationShape,'Polygon')
                        annotationTemp = app.annotationDrawing.Position;
                    end
                    annotationNumber = size(app.ListAnnotations.Items,2);
                    if ~isempty(app.ListAnnotations.Items)
                        if isempty(app.ListAnnotations.Items{1})
                            i_add = 1;
                        else

                            i_add = annotationNumber + 1;
                        end
                    else
                        i_add = 1;
                    end
                    app.annotationView.Index(i_add) = i_add;
                    % close the boundary
                    app.annotationView.boundaryX{i_add} = [annotationTemp(:,1);annotationTemp(1,1)]; 
                    app.annotationView.boundaryY{i_add} = [annotationTemp(:,2);annotationTemp(1,2)]; 
                    % % add statistics for the custom boundary
                    % annotationBoundaryCol = app.annotationView.boundaryX{i_add};
                    % annotationBoundaryRow = app.annotationView.boundaryY{i_add};
                    % nrow = app.CAPimage.imageInfo.Height;
                    % ncol = app.CAPimage.imageInfo.Width;
                    % annotationMask = poly2mask( annotationBoundaryCol,annotationBoundaryRow,nrow,ncol);
                    % stats = regionprops(annotationMask,'Centroid','Area','Perimeter','Orientation');
                    % statsArray{1,i_add}.Mask = annotationMask;
                    % statsArray{1,i_add}.Centroid = stats.Centroid;
                    % statsArray{1,i_add}.Area = stats.Area;
                    % statsArray{1,i_add}.Perimeter = stats.Perimeter;
                    % statsArray{1,i_add}.Orientation = stats.Orientation;
                    % app.CAPannotations.customAnnotations.statsArray = statsArray;
                    %add other properties
                    tempName = sprintf('%s%d',app.annotationType,i_add);
                    noExist=length(find(strcmp(app.ListAnnotations.Items,tempName)== 1));
                    if noExist == 0
                        app.annotationView.Name{i_add} = tempName;
                    else
                        app.annotationView.Name{i_add} = sprintf('%s-%d',tempName,noExist);
                    end
                    app.annotationView.Type{i_add} = app.annotationType;
                    set(app.UIAxes,'NextPlot','add');
                    app.annotationView.annotationH1{i_add,1} =plot(app.annotationView.boundaryX{i_add},app.annotationView.boundaryY{i_add},...
                        [annotationColor '-'],'LineWidth',annotationLineWidth, 'Tag',app.annotationView.Name{i_add},'Parent',app.UIAxes); % 'Parent',figureH2)
                    app.ListAnnotations.Items{i_add} = app.annotationView.Name{i_add};
                    app.annotationView.Selection = i_add;
                    app.measure_annotation;

                elseif strcmp(app.annotationType,'cell_computed') % add computed cell one by one
                    annotationNumber = size(app.ListAnnotations.Items,2);
                    if ~isempty(app.ListAnnotations.Items)
                        if isempty(app.ListAnnotations.Items{1})
                            i_add = 1;
                        else

                            i_add = annotationNumber + 1;
                        end
                    else
                        i_add = 1;
                    end
                    app.annotationView.Index(i_add) = i_add;
                    %find cell index
                    cellSelected = app.ListObjects.Value;
                    cellIndex = str2num(strrep(cellSelected,'cell',''));
                    % find cell boundary
                    app.annotationView.boundaryX{i_add} = app.objectsView.boundaryX{cellIndex}; 
                    app.annotationView.boundaryY{i_add} = app.objectsView.boundaryY{cellIndex};  
                    %add other properties
                    tempName = sprintf('%s_computed%d',cellSelected,i_add);
                    noExist=length(find(strcmp(app.ListAnnotations.Items,tempName)== 1));
                    if noExist == 0
                        app.annotationView.Name{i_add} = tempName;
                    else
                        app.annotationView.Name{i_add} = sprintf('%s-%d',tempName,noExist);
                    end
                    app.annotationView.Type{i_add} = app.annotationType;
                    set(app.UIAxes,'NextPlot','add');
                    app.annotationView.annotationH1{i_add,1} =plot(app.annotationView.boundaryX{i_add},app.annotationView.boundaryY{i_add},...
                        [annotationColor '-'],'LineWidth',annotationLineWidth, 'Tag',app.annotationView.Name{i_add},'Parent',app.UIAxes); % 'Parent',figureH2)
                    app.ListAnnotations.Items{i_add} = app.annotationView.Name{i_add};
                    app.annotationView.Selection = i_add;
                    app.measure_annotation;
                end
            end

        end
        
        function draw_annotation(app)

            if isempty(app.annotationShape)
               disp('Choose the annotation shape first to proceed')
               return
            end
            % fprintf('deleted previous selected roi(s) \n')
            roiLog = findobj(app.UIAxes,'Type','images.roi');
            delete(roiLog);
            if ~isempty(app.annotationDrawing)
                delete(app.annotationDrawing)
            end
            
            if strcmp(app.annotationShape,'SpecifiedRECT')
               disp('ROI specification is not available. Choose another shape to proceed')
               return
            else
                ROIindex = find(strcmp(app.ROIshapes,app.annotationShape) == 1);
                if ~isempty(ROIindex)
                    app.drawingFuncs = {@drawrectangle,@drawpolygon,@drawfreehand,@drawellipse,@drawspecifiedRECT}; % draw functions
                    app.annotationDrawing = app.drawingFuncs{ROIindex}(app.UIAxes,'Color','y','Tag','roiH');
                    app.TabGroup.SelectedTab = app.ROImanagerTab;
                    % fprintf('manual annotation shape: %s \n',app.annotationShape)
                else
                    disp('NO valid shape is slected')
                    return
                end
            end

        end
        
        function delete_annotation(app)
            % app.ListAnnotations.Items{i_add} = app.annotationView.Name{i_add};
            item_selected = app.ListAnnotations.Value;
            itemIndex = find(strcmp(app.ListAnnotations.Items,item_selected) == 1);
            line_handle = findall(app.UIAxes,'Type','Line','Tag',item_selected);
            delete(line_handle)
            % app.ListAnnotations.Items(itemIndex) =[]; 
            app.annotationView.Index(itemIndex) = [];
            app.annotationView.boundaryX(itemIndex)= [];
            app.annotationView.boundaryY(itemIndex) = [];
            app.annotationView.Name(itemIndex) = [];
            delete(app.annotationView.annotationH1{itemIndex});
            delete(app.annotationView.annotationH2{1});
            app.annotationView.annotationH1(itemIndex) = [];
            app.ListAnnotations.Items = app.annotationView.Name; % syn ListAnnotations and annotaitonView
            % app.ListAnnotations.Value = [];
            % app.annotationView.Selection = [];
        end
        
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, cellanalysisModule)
            if ~isdeployed
                addpath('./WholeCell');
                addpath('./vampire');
                addpath('./');
            end
            UIfigure_pos = app.UIfigure.Position;
            ssU = get(0,'screensize'); % screen size of the user's display
            if UIfigure_pos(3) < ssU(3)
               posX = round((ssU(3)-UIfigure_pos(3))*0.5);
               if UIfigure_pos(4) < ssU(4)
                   posY = round((ssU(4)-UIfigure_pos(4))*0.5);
                   app.UIfigure.Position = [posX posY UIfigure_pos(3) UIfigure_pos(4)];          
               end
            end
            %add a listener function to a draw ROI function
            set(app.UIfigure,'KeyPressFcn',@roi_mang_keypress_fn);              %Assigning the function that is called when any key is pressed while roi_mang_fig is active
            function[]=roi_mang_keypress_fn(~,eventdata,~)
                % When s is pressed then roi is saved
                % when 'd' is pressed a new roi is drawn
                % x is to cancel the ROI drawn already on the figure
                if(eventdata.Key=='t')
                    app.add_annotation;
                elseif(eventdata.Key=='d')
                    app.draw_annotation;
                elseif(eventdata.Key=='r')
                    app.delete_annotation;
                    % set(save_roi_box,'Enable','on');%enabling save button after drawing ROI
                % elseif(eventdata.Key=='x')
                %     if(~isempty(h)&&h~=0)
                %         delete(h);
                %         set(roi_shape_choice,'Value',1)
                %         set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
                %     end
                end
  
            end
            % check current python enviroment
            app.mype = pyenv;
            if isempty(app.mype)
                disp('Python environment is not set up yet. Use the tab "Python Environment" to set it up')
            else
                terminate(pyenv);
                py.list;
                app.mype = pyenv;
                app.pyenvStatus.Value = sprintf('%s, ProcessID:%s',app.mype.Status,app.mype.ProcessID);
                app.EXEmodeDropDown.Value = sprintf('%s',app.mype.ExecutionMode);
                path2stardist = fileparts(which('StarDistPrediction.py'));
                path2cellpose = fileparts(which('cellpose_seg.py'));
                insert(py.sys.path,int32(0),path2stardist);
                insert(py.sys.path,int32(0),path2cellpose);
                app.PythonSearchPath.Value = sprintf('%s',py.sys.path);
                app.PathtoPythonInstallation.Value = sprintf('%s',app.mype.Executable);
                disp('Current Python environment is loaded and can be updated using the tab "Python Environment"')
            end
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
            if strcmp(itemName(1:4),'cell')
                app.objectsView.Selection = str2num(strrep(itemName,'cell',''));
                app.figureOptions.plotObjects = 1;
                app.figureOptions.plotFibers = 0;
                app.figureOptions.plotAnnotations = 0;
            else
                app.fibersView.Selection = str2num(strrep(itemName,'fiber',''));
                app.figureOptions.plotObjects = 0;
                app.figureOptions.plotFibers = 1;
                app.figureOptions.plotAnnotations = 0;
            end
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
            item_index = find(strcmp(app.ListAnnotations.Items,itemName) == 1);
            if length(item_index)~= 1
                error('Only one annotation can be selected.')
            end
            app.annotationType = app.annotationView.Type{item_index};
            app.annotationView.Selection = item_index; 
            app.figureOptions.plotAnnotations = 1;
            app.figureOptions.plotObjects = 0;
            try
                highlightedCellNumber = size(app.objectsView.cellH2,1);
                for ii = 1:highlightedCellNumber
                    delete(app.objectsView.cellH2{ii,1})
                end
                highlightedFiberNumber = size(app.fibersView.fiberH2,1);
                for ii = 1:highlightedFiberNumber
                    delete(app.fibersView.fiberH2{ii,1})
                end
            catch err
                fprintf('%s \n', err.message)
            end
            app.CAPannotations.cellDetectionFlag = 0;
            app.figureOptions.plotFibers = 0;
            app.figureOptions.plotObjects = 0;
            app.ListObjects.Items = {''};
            app.SelectionDropDown.Value = 'None';
            app.plotSelection
        end

        % Close request function: UIfigure
        function UIfigureCloseRequest(app, event)
            delete(app.cellanalysisAPP)
            delete(app.tumoranalysisAPP)
            delete(app.objectmeasurementAPP)
            delete(app.annotationmeasurementAPP)
            delete(app.setMeasurementsAPP)
            delete(app)

        end

        % Button pushed function: DetectobjectButton
        function DetectobjectButtonPushed(app, event)
            if isempty(app.ListAnnotations.Items)
               disp('No annotation is available')
               return
            else
               if isempty(app.objectsView.Name{1})
                disp('No object is available')
                return
               end
            end
            % detect the objects within the selected annotation
            nrow = app.CAPimage.imageInfo.Height;
            ncol = app.CAPimage.imageInfo.Width;
            item_selected = app.ListAnnotations.Value;
            annotationIndex = find(strcmp(app.ListAnnotations.Items,item_selected) == 1);
            if length(annotationIndex) ~= 1
                error('Only support object detection within a single annotation')
            end
            app.annotationType =  app.annotationView.Type{annotationIndex};
            annotationRow = app.annotationView.boundaryY{annotationIndex};  
            annotationCol = app.annotationView.boundaryX{annotationIndex};  
            annoName = app.annotationView.Name{annotationIndex};
            annotationMask = poly2mask(annotationCol,annotationRow,ncol,nrow);
            if strcmp(app.annotationType,'tumor')
                % %tumorsingleMask = app.CAPannotations.tumorAnnotations.statsArray{1,annotationIndex}.Mask;%poly2mask(tumorY,tumorX,nrow,ncol);    % convert boundary to mask
                % stats.Centroid = app.CAPannotations.tumorAnnotations.statsArray{1,annotationIndex}.Centroid;
                % stats.Area = app.CAPannotations.tumorAnnotations.statsArray{1,annotationIndex}.Area;
                % stats.Perimeter= app.CAPannotations.tumorAnnotations.statsArray{1,annotationIndex}.Perimeter;
                fprintf('find associated objects for the selected tumor region \n')
            elseif strcmp(app.annotationType,'custom_annotation')
                % % annotationMask = app.CAPannotations.tumorAnnotations.statsArray{1,annotationIndex}.Mask;%poly2mask(tumorY,tumorX,nrow,ncol);    % convert boundary to mask
                % stats = regionprops( annotationMask,'Centroid','Area','Perimeter');
                % stats.Mask = annotationMask;
                % stats.Centroid = stats.Centroid;
                % stats.Area = stats.Area;
                % stats.Perimeter = stats.Perimeter;
                fprintf('find associated objects for the user specified annotation \n')
            end

            % figure; imshow(tumorsingleMask); hold on; plot(tumorCol,tumorRow,'yo') 
            % coords = bwboundaries(tumorsingleMask,4);
            % for k = 1:length(coords)%2:length(coords)
            %     boundary = coords{k};
            %     plot(boundary(:,2), boundary(:,1), 'm*')
            % end
            bwROI = struct('name','','coords',[],'imWidth',[],'imHeight',[],'index2object',[],'dist',[]);
            coords = bwboundaries(annotationMask,4);  % create boundary points for relative alignment calculation
            if length(coords) ~=1
                error('Only a signle closed annotation can be loaded')
            else
                bwROI.coords = coords{1};  % [y x]
                bwROI.imWidth = ncol;
                bwROI.imHeight = nrow;
                bwROI.name = annoName;
            end

            %cells detection
            if ~isempty(app.CAPobjects.cells)
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

                    if annotationMask(cellcenterX,cellcenterY) == 1   %
                        cellsFlag(ic) = 1;
                    end
                end
                objectinTumorIndex = find(cellsFlag == 1);
                app.figureOptions.plotObjects = 1;
                app.figureOptions.plotAnnotations = 0;
                app.objectsView.Selection = objectinTumorIndex;
                app.annotationView.Selection = annotationIndex;
                if ~isempty(objectinTumorIndex)
                    app.plotSelection;
                    selectedNumber = length(objectinTumorIndex);
                    selectedCellName = cell(selectedNumber,1);
                    for i = 1:selectedNumber
                        selectedCellName{i,1} = app.objectsView.Name{objectinTumorIndex(i)};
                    end
                    app.ListObjects.Items = selectedCellName;
                    app.CAPannotations.cellDetectionFlag = 1;
                    app.SelectionDropDown.Value =  app.SelectionDropDown.Items{1};
                end
                % fiber detection
                if ~isempty(app.CAPobjects.fibers)
                    fiberNumber = size(app.CAPobjects.fibers.fibFeat,1);
                    fibersinsideFlag = zeros(fiberNumber,1);
                    fibersOutsideDistanceFlag = zeros(fiberNumber,1);
                    % fibers within a distance to the boundary
                    fibersList.center = [cell2mat(app.fibersView.centerY) cell2mat(app.fibersView.centerX)];  % Y, X
                    fibersList.angle = cell2mat(app.fibersView.orientation);

                    % [idx_dist,dist_fiber] = knnsearch([tumorCol tumorRow],fibersList.center);
                    [idx_dist,dist_fiber] = knnsearch(fliplr(bwROI.coords),fliplr(fibersList.center));

                    distThresh = app.measurementsSettings.distance2boundary;
                    fiberIndexs = find(dist_fiber <= distThresh);
                    if ~isempty(fiberIndexs)
                        fiberswithinDistance2tumorIndex = fiberIndexs;
                    else
                        fiberswithinDistance2tumorIndex = [];
                    end

                    % fibers within or outside the tumor
                    for iF = 1:fiberNumber
                        fibercenterY = app.fibersView.centerY{iF};%cells(ic,1)(ic,1);
                        fibercenterX = app.fibersView.centerX{iF};%cellCenters(ic,2);
                        if fibercenterX > ncol
                            fprintf('Fiber %d is out of boundary centerX%d > Image width%d \n', iF, fibercenterX,ncol);
                            fibercenterX = ncol;
                        end
                        if fibercenterY > nrow
                            fprintf('Object %d is out of boundary centerX%d > Image Height%d \n', iF, fibercenterY,nrow);
                            cellcenterY = nrow;
                        end
                        if annotationMask(fibercenterY,fibercenterX) == 1   %
                            fibersinsideFlag(iF) = 1;
                        else
                            if dist_fiber(iF) <= distThresh 
                                fibersOutsideDistanceFlag(iF) = 1;  % fibers outside the tumor and within the specified distance to the tumor
                                % %check the fiber postion
                                % df = figure; imshow(tumorsingleMask);hold on; plot(tumorX,tumorY,'r*');plot(fibersList.center(iF,1),fibersList.center(iF,2),'mo'), hold off; pause(1);delete(df);
                            end
                        end
                    end
                    %fibers within the tumor 
                    fiberinTumorIndex = find(fibersinsideFlag == 1);
                    % fibers within the distance but outside the tumor
                    fibersOutsideDistanceIndex = find(fibersOutsideDistanceFlag == 1);
                    % choose the detected fibers
                    fibersSelected = [];
                    if app.measurementsSettings.relativeAngleFlag == 1
                        if app.measurementsSettings.excludeInboundaryfiberFlag == 1
                            fibersSelected =  fibersOutsideDistanceIndex ;
                        else
                            fibersSelected = fiberswithinDistance2tumorIndex;
                        end
                    else
                        fibersSelected = fiberinTumorIndex;
                    end

                    if ~isempty(fibersSelected)
                        app.figureOptions.plotFibers = 1;
                        app.figureOptions.plotObjects = 0;
                        app.figureOptions.plotAnnotations = 0;
                        app.fibersView.Selection = fibersSelected;
                        app.annotationView.Selection = annotationIndex;
                        app.plotSelection;
                        selectedNumber = length(fibersSelected);
                        selectedfiberName = cell(selectedNumber,1);
                        for i = 1:selectedNumber
                            selectedfiberName{i,1} = app.fibersView.Name{fibersSelected(i)};
                        end
                        app.ListObjects.Items = [selectedCellName;selectedfiberName];
                        app.CAPannotations.fiberDetectionFlag = 1;
                        app.SelectionDropDown.Value =  app.SelectionDropDown.Items{3};
                        if app.measurementsSettings.relativeAngleFlag == 1
                            fiberOBJlist = repmat(struct('center',[],'angle',[]),1,selectedNumber);
                            for i = 1:selectedNumber
                                fiberOBJlist(i).center = fibersList.center(fibersSelected(i),:); % y, x
                                fiberOBJlist(i).angle = fibersList.angle(fibersSelected(i));
                            end
                            bwROI.index2object = idx_dist(fibersSelected);
                            bwROI.dist = dist_fiber(fibersSelected);
                            ROImeasurements = getAlignment2ROI(bwROI,fiberOBJlist);
                            saveOptions= struct('saveDataFlag',1,'saveFigureFlag', 1,'overwriteFlag',1,...
                                'outputFolder',[],'originalImagename',[],'imageFolder',[],'outputdataFilename',[],...
                                'outputfigureFilename',[],'plotAssociationFlag',0,'annotationIndex',1);
                            saveOptions.saveDataFlag = app.measurementsSettings.saveMeasurementsdataFlag;
                            saveOptions.saveFigureFlag = app.measurementsSettings.saveMeasurementsfigFlag;
                            saveOptions.plotAssociationFlag = app.measurementsSettings.plotAssociationFlag;
                            saveOptions.outputFolder = app.fiberdataPath;
                            saveOptions.originalImagename = app.imageName;
                            saveOptions.imageFolder = app.imagePath;
                            [~,imageNameNOE] = fileparts(app.imageName);
                            saveOptions.outputdataFilename = sprintf('%s_boundaryObjectsMeasurements.xlsx',imageNameNOE);
                            saveOptions.outputfigureFilename = sprintf('%s_boudaryObjectsoverlay.tif',imageNameNOE);
                            saveRelativemeasurements(ROImeasurements,bwROI,fiberOBJlist,saveOptions)
                            if saveOptions.saveDataFlag == 1
                                fprintf('Relative measurements to the annotated region is saved to %s \n ', ...
                                    fullfile(saveOptions.outputFolder,saveOptions.outputdataFilename));
                            else
                                disp('No releative measurents data file is saved')
                            end
                            if saveOptions.saveFigureFlag == 1
                                fprintf('Figure of the annotated region and associated objects is saved to %s \n ', ...
                                    fullfile(saveOptions.outputFolder,saveOptions.outputfigureFilename));
                            else
                                disp('No figure related to the relative measurements is saved')
                            end
                            
                        end
                    end
                end  % fibers detection

            end  % cells detection
 
        end

        % Menu selected function: ShowannotationROImeasurmentsMenu
        function ShowannotationROImeasurmentsMenuSelected(app, event)
            app.annotationmeasurementAPP = cellanalysisAnnotationMeasurement(app);
        end

        % Menu selected function: OpenMenu
        function OpenMenuSelected(app, event)

            [imageGet, pathGet]=uigetfile({'*.tif';'*.png';'*.jpeg';'*.*'},'Select Cell Images',pwd,'MultiSelect','off');
            if imageGet ~= 0
                delete(app);
                app = CellAnalysisForCurveAlign; % reset app
                app.imageName = imageGet;
                app.imagePath = pathGet;
                app.CAPimage.imageName = imageGet;
                app.CAPimage.imagePath = pathGet;
                app.CAPimage.imageInfo = imfinfo(fullfile(pathGet,imageGet));
                app.CAPimage.imageData = imread(fullfile(pathGet,imageGet));

            else
                disp('Select a new image to proceed.')
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

        % Value changed function: SelectionDropDown
        function SelectionDropDownValueChanged(app, event)
            value = app.SelectionDropDown.Value;
            if strcmp(value, 'None')

            elseif strcmp(value,'All')

            else

            end
        end

        % Menu selected function: ImportfiberfeaturesfileMenu
        function ImportfiberfeaturesfileMenuSelected(app, event)
            if isempty(app.CAPobjects.cells)
                disp('Please do cell analysis first.')
                return
            end
            [~,nameNE] = fileparts(app.CAPimage.imageName);
            if isempty(app.fiberdataPath)
                app.fiberdataPath = app.imagePath;
            end
            fiberPath = app.fiberdataPath;
            [fiberdataFile, fiberdataPath]=uigetfile({[nameNE '*fibFeatures.mat'];'*.*'},...
                'Select fiber feature file generated by CurveAlign',fiberPath,'MultiSelect','off');
            if fiberdataFile == 0
                disp('NO fiber file is selected.')
                return
            else
                app.fiberdataPath = fiberdataPath;
                app.fiberdataFile = fiberdataFile;
                app.CAPobjects.fibers = load(fullfile(fiberdataPath,fiberdataFile));
                app.figureOptions.plotImage = 0;
                app.figureOptions.plotObjects = 0;
                app.figureOptions.plotAnnotations = 0;
                app.figureOptions.plotFibers =1;
                app.plotImage_public;
                app.SelectionDropDown.Value =  app.SelectionDropDown.Items{3};
            end
        end

        % Menu selected function: ExportMenu
        function ExportMenuSelected(app, event)
            if isempty (app.CAPannotations.tumorAnnotations)
                 disp('No tumor annotation is found.  Complete the annotation to proceed.')
                 return
            else
                filePath_Out = fullfile(app.imagePath,'CellAnalysis_Out');
                if ~exist(filePath_Out,'dir')
                    mkdir(filePath_Out)
                end
                [~,nameNE] = fileparts(app.imageName);
                fileName_out = sprintf('%s-CellAnalysis.mat',nameNE);
                CAPfibers = app.CAPobjects.fibers;
                CAPcells = app.CAPobjects.cells;
                CAPtumors = app.CAPannotations;
                CAPimageName = app.imageName;
                CAPimagePath = app.imagePath;
                save(fullfile(filePath_Out,fileName_out), 'CAPimagePath','CAPimageName','CAPtumors','CAPcells','CAPfibers');
                fprintf('Cell analysis output data file is created:%s \n',fullfile(filePath_Out,fileName_out));
            end
        end

        % Menu selected function: MeasurmentmanagerMenu
        function MeasurmentmanagerMenuSelected(app, event)
            %  app.measurementsSettings = struct('relativeAngleFlag',1, 'distance2boundary', 100,...
            % 'excludeInboundaryfiberFlag',0,'saveMeasurementsdataFlag',1,'saveMeasurementsfigFlag',0); % default measurements settings;
            % app.setMeasurementsAPP = setCellFibermeasurements(app.measurementsSettings);
            app.setMeasurementsAPP = setCellFibermeasurements(app);

        end

        % Menu selected function: EllipseMenu, FreehandMenu, PolygonMenu, 
        % ...and 2 other components
        function ROIshapeMenuSelected(app, event)
            if ~isempty(app.annotationDrawing)
                delete(app.annotationDrawing)
                roiLog = findobj(app.UIAxes,'Type','images.roi');
                delete(roiLog);
                % fprintf('deleted previous selected roi(s) \n')
            end
            ROIshapes = app.ROIshapes;
            ROIselectionmenus = {app.RectangleMenu,app.PolygonMenu,app.FreehandMenu,app.EllipseMenu,app.SpecifiedRECTMenu}; % ROI shape menu
            for i = 1:length(ROIshapes)
                currentShape = ROIshapes{i};
                currentMenu = ROIselectionmenus{i};
                if strcmp(event.Source.Text,currentShape)
                    if currentMenu.Checked == 1
                        currentMenu.Checked = 0;
                        app.annotationShape = [];
                        app.TabGroup.SelectedTab = app.ROImanagerTab;

                    else % only one ROI shape can be selected
                        for j = 1:length(ROIshapes)
                            if j == i
                                currentMenu.Checked = 1;

                            else
                                ROIselectionmenus{j}.Checked = 0;
                            end
                        end
                        app.annotationShape = currentShape;
                        app.draw_annotation
                    end

                    break
                end
            end
      
        end

        % Button pushed function: AddtButton
        function AddtButtonPushed(app, event)
            app.annotationType = 'custom_annotation';
            app.add_annotation
        end

        % Button pushed function: DeleterButton
        function DeleterButtonPushed(app, event)
            app.delete_annotation
        end

        % Button pushed function: DrawdButton
        function DrawdButtonPushed(app, event)
            app.draw_annotation
        end

        % Button pushed function: UpdatePyenvButton
        function UpdatePyenvButtonPushed(app, event)
            [pe_fileName,pe_filePath] = uigetfile({'*python*.exe';'*.*'}, 'Select the python exe file', app.PathtoPythonInstallation.Value{1});
            if pe_fileName == 0
                disp('No change is made to python environment')
            else
                pe_currentDir = fileparts(app.PathtoPythonInstallation.Value{1});
                if strcmp(pe_currentDir,pe_filePath(1:end-1))
                    disp('Loaded path is same to the previous path. NO change to the python environment')
                else
                    terminate(pyenv)
                    app.mype = pyenv(Version=fullfile(pe_filePath,pe_fileName),ExecutionMode="OutOfProcess");
                    path2stardist = fileparts(which('StarDistPrediction.py'));
                    path2cellpose = fileparts(which('cellpose_seg.py'));
                    insert(py.sys.path,int32(0),path2stardist);
                    insert(py.sys.path,int32(0),path2cellpose);
                    app.PythonSearchPath.Value = sprintf('%s',py.sys.path);
                    app.PathtoPythonInstallation.Value = fullfile(pe_filePath,pe_fileName);
                    app.EXEmodeDropDown.Value = app.mype.ExecutionMode;
                    app.pyenvStatus.Value = sprintf('%s, ProcessID:%s',app.mype.Status,app.mype.ProcessID);
                    fprintf('Python environment is directed to %s \n', app.PathtoPythonInstallation.Value{1});
                end
            end
        end

        % Button pushed function: InsertpathButton
        function InsertpathButtonPushed(app, event)
            moduleFoldername = uigetdir(fileparts(app.PathtoPythonInstallation.Value{1}), 'Pick a Directory of a python module');
            if moduleFoldername == 0
                disp('NO module directory is selected. Python search path is NOT changed.')
            else
                insert(py.sys.path,int32(0),moduleFoldername);
                fprintf('"%s" is added to the python search path \n',moduleFoldername)
                app.PythonSearchPath.Value = sprintf('%s', py.sys.path);
            end
        end

        % Button pushed function: LoadPythonInterpreterButton
        function LoadPythonInterpreterButtonPushed(app, event)
            pe_currentPath = app.PathtoPythonInstallation.Value{1};
            app.mype = pyenv(Version=pe_currentPath,ExecutionMode="OutOfProcess");
            path2stardist = fileparts(which('StarDistPrediction.py'));
            path2cellpose = fileparts(which('cellpose_seg.py'));
            insert(py.sys.path,int32(0),path2stardist);
            insert(py.sys.path,int32(0),path2cellpose);
            app.PythonSearchPath.Value = sprintf('%s',py.sys.path);
            app.PathtoPythonInstallation.Value = pe_currentPath;
            app.EXEmodeDropDown.Value = app.mype.ExecutionMode;
            app.pyenvStatus.Value = sprintf('%s, ProcessID:%s',app.mype.Status,app.mype.ProcessID);
            fprintf('Python environment is directed to %s \n', app.PathtoPythonInstallation.Value{1});
        end

        % Button pushed function: TerminatePythonInterpreterButton
        function TerminatePythonInterpreterButtonPushed(app, event)
            terminate(pyenv);
            app.mype = pyenv;
            app.pyenvStatus.Value = sprintf('%s, ProcessID:%s',app.mype.Status,'N/A');
            app.PythonSearchPath.Value = sprintf('%s',py.sys.path);
        end

        % Button pushed function: SetAnnotationButton
        function SetAnnotationButtonPushed(app, event)
            itemName = app.ListObjects.Value;
            if strcmp(itemName(1:4),'cell')
                app.annotationType = 'cell_computed';
            elseif strcmp(itemName(1:5),'fiber')
                app.annotationType = 'fiber_computed';
            else
                error('No a valid object selection for setting an annotaiton')
            end
            app.add_annotation;
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
            app.UIfigure.Name = 'Cell Analysis for CurveAlign 6.0';
            app.UIfigure.Resize = 'off';
            app.UIfigure.CloseRequestFcn = createCallbackFcn(app, @UIfigureCloseRequest, true);
            app.UIfigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIfigure.Tag = 'cell4caMain';

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
            app.ImportfiberfeaturesfileMenu.MenuSelectedFcn = createCallbackFcn(app, @ImportfiberfeaturesfileMenuSelected, true);
            app.ImportfiberfeaturesfileMenu.Text = 'Import fiber features file..';

            % Create ExportMenu
            app.ExportMenu = uimenu(app.FileMenu);
            app.ExportMenu.MenuSelectedFcn = createCallbackFcn(app, @ExportMenuSelected, true);
            app.ExportMenu.Text = 'Export';

            % Create ToolsMenu
            app.ToolsMenu = uimenu(app.UIfigure);
            app.ToolsMenu.Text = 'Tools';

            % Create RectangleMenu
            app.RectangleMenu = uimenu(app.ToolsMenu);
            app.RectangleMenu.MenuSelectedFcn = createCallbackFcn(app, @ROIshapeMenuSelected, true);
            app.RectangleMenu.Text = 'Rectangle';

            % Create PolygonMenu
            app.PolygonMenu = uimenu(app.ToolsMenu);
            app.PolygonMenu.MenuSelectedFcn = createCallbackFcn(app, @ROIshapeMenuSelected, true);
            app.PolygonMenu.Text = 'Polygon';

            % Create FreehandMenu
            app.FreehandMenu = uimenu(app.ToolsMenu);
            app.FreehandMenu.MenuSelectedFcn = createCallbackFcn(app, @ROIshapeMenuSelected, true);
            app.FreehandMenu.Text = 'Freehand';

            % Create EllipseMenu
            app.EllipseMenu = uimenu(app.ToolsMenu);
            app.EllipseMenu.MenuSelectedFcn = createCallbackFcn(app, @ROIshapeMenuSelected, true);
            app.EllipseMenu.Text = 'Ellipse';

            % Create SpecifiedRECTMenu
            app.SpecifiedRECTMenu = uimenu(app.ToolsMenu);
            app.SpecifiedRECTMenu.MenuSelectedFcn = createCallbackFcn(app, @ROIshapeMenuSelected, true);
            app.SpecifiedRECTMenu.Text = 'SpecifiedRECT';

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
            app.MeasurmentmanagerMenu.MenuSelectedFcn = createCallbackFcn(app, @MeasurmentmanagerMenuSelected, true);
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

            % Create GitHubWikipageMenu
            app.GitHubWikipageMenu = uimenu(app.HelpMenu);
            app.GitHubWikipageMenu.Text = 'GitHub Wiki page';

            % Create GitHubsourcecodeMenu
            app.GitHubsourcecodeMenu = uimenu(app.HelpMenu);
            app.GitHubsourcecodeMenu.Text = 'GitHub source code';

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

            % Create Panel_3
            app.Panel_3 = uipanel(app.AnnotationsPanel);
            app.Panel_3.Position = [12 12 212 69];

            % Create DeleterButton
            app.DeleterButton = uibutton(app.Panel_3, 'push');
            app.DeleterButton.ButtonPushedFcn = createCallbackFcn(app, @DeleterButtonPushed, true);
            app.DeleterButton.Position = [108 4 100 23];
            app.DeleterButton.Text = 'Delete(r)';

            % Create DetectobjectButton
            app.DetectobjectButton = uibutton(app.Panel_3, 'push');
            app.DetectobjectButton.ButtonPushedFcn = createCallbackFcn(app, @DetectobjectButtonPushed, true);
            app.DetectobjectButton.Position = [2 3 100 22];
            app.DetectobjectButton.Text = 'Detect object';

            % Create AddtButton
            app.AddtButton = uibutton(app.Panel_3, 'push');
            app.AddtButton.ButtonPushedFcn = createCallbackFcn(app, @AddtButtonPushed, true);
            app.AddtButton.Position = [108 34 100 23];
            app.AddtButton.Text = 'Add (t)';

            % Create DrawdButton
            app.DrawdButton = uibutton(app.Panel_3, 'push');
            app.DrawdButton.ButtonPushedFcn = createCallbackFcn(app, @DrawdButtonPushed, true);
            app.DrawdButton.Position = [2 34 100 23];
            app.DrawdButton.Text = 'Draw (d)';

            % Create ListAnnotations
            app.ListAnnotations = uilistbox(app.AnnotationsPanel);
            app.ListAnnotations.Items = {};
            app.ListAnnotations.ValueChangedFcn = createCallbackFcn(app, @ListAnnotationsValueChanged, true);
            app.ListAnnotations.Position = [13 101 211 475];
            app.ListAnnotations.Value = {};

            % Create ObjectsPanel
            app.ObjectsPanel = uipanel(app.Panel);
            app.ObjectsPanel.Title = 'Objects';
            app.ObjectsPanel.Position = [239 1 217 601];

            % Create ListObjects
            app.ListObjects = uilistbox(app.ObjectsPanel);
            app.ListObjects.Items = {};
            app.ListObjects.ValueChangedFcn = createCallbackFcn(app, @ListObjectsValueChanged, true);
            app.ListObjects.Position = [12 101 199 475];
            app.ListObjects.Value = {};

            % Create SelectionDropDown
            app.SelectionDropDown = uidropdown(app.ObjectsPanel);
            app.SelectionDropDown.Items = {'Cell', 'Fiber', 'Cell+Fiber', 'None', 'All'};
            app.SelectionDropDown.ValueChangedFcn = createCallbackFcn(app, @SelectionDropDownValueChanged, true);
            app.SelectionDropDown.Position = [36 15 149 28];
            app.SelectionDropDown.Value = 'Cell';

            % Create SetAnnotationButton
            app.SetAnnotationButton = uibutton(app.ObjectsPanel, 'push');
            app.SetAnnotationButton.ButtonPushedFcn = createCallbackFcn(app, @SetAnnotationButtonPushed, true);
            app.SetAnnotationButton.Tooltip = {'Set selected object(s) as annotation'};
            app.SetAnnotationButton.Position = [36 56 148 23];
            app.SetAnnotationButton.Text = 'Set Annotation';

            % Create PythonEnvironmentTab
            app.PythonEnvironmentTab = uitab(app.TabGroup);
            app.PythonEnvironmentTab.Title = 'Python Environment';

            % Create PathtoPythonInstallationLabel
            app.PathtoPythonInstallationLabel = uilabel(app.PythonEnvironmentTab);
            app.PathtoPythonInstallationLabel.HorizontalAlignment = 'right';
            app.PathtoPythonInstallationLabel.Position = [124 591 144 22];
            app.PathtoPythonInstallationLabel.Text = 'Path to Python Installation';

            % Create PathtoPythonInstallation
            app.PathtoPythonInstallation = uitextarea(app.PythonEnvironmentTab);
            app.PathtoPythonInstallation.Editable = 'off';
            app.PathtoPythonInstallation.Position = [116 496 319 91];

            % Create PythonSearchPathTextAreaLabel
            app.PythonSearchPathTextAreaLabel = uilabel(app.PythonEnvironmentTab);
            app.PythonSearchPathTextAreaLabel.HorizontalAlignment = 'right';
            app.PythonSearchPathTextAreaLabel.Position = [115 282 115 22];
            app.PythonSearchPathTextAreaLabel.Text = 'Python  Search Path';

            % Create PythonSearchPath
            app.PythonSearchPath = uitextarea(app.PythonEnvironmentTab);
            app.PythonSearchPath.Editable = 'off';
            app.PythonSearchPath.Position = [113 91 320 185];

            % Create EXEmodeDropDownLabel
            app.EXEmodeDropDownLabel = uilabel(app.PythonEnvironmentTab);
            app.EXEmodeDropDownLabel.HorizontalAlignment = 'right';
            app.EXEmodeDropDownLabel.Enable = 'off';
            app.EXEmodeDropDownLabel.Position = [15 434 62 22];
            app.EXEmodeDropDownLabel.Text = 'EXE mode';

            % Create EXEmodeDropDown
            app.EXEmodeDropDown = uidropdown(app.PythonEnvironmentTab);
            app.EXEmodeDropDown.Items = {'OutOfProcess', 'InProcess'};
            app.EXEmodeDropDown.Enable = 'off';
            app.EXEmodeDropDown.Position = [119 420 316 36];
            app.EXEmodeDropDown.Value = 'OutOfProcess';

            % Create pyenvStatusTextAreaLabel
            app.pyenvStatusTextAreaLabel = uilabel(app.PythonEnvironmentTab);
            app.pyenvStatusTextAreaLabel.HorizontalAlignment = 'right';
            app.pyenvStatusTextAreaLabel.Position = [14 344 74 22];
            app.pyenvStatusTextAreaLabel.Text = 'pyenv Status';

            % Create pyenvStatus
            app.pyenvStatus = uitextarea(app.PythonEnvironmentTab);
            app.pyenvStatus.Editable = 'off';
            app.pyenvStatus.Position = [113 333 321 35];

            % Create InsertpathButton
            app.InsertpathButton = uibutton(app.PythonEnvironmentTab, 'push');
            app.InsertpathButton.ButtonPushedFcn = createCallbackFcn(app, @InsertpathButtonPushed, true);
            app.InsertpathButton.Tooltip = {'Add the selected path to the python search path '};
            app.InsertpathButton.Position = [10 208 89 36];
            app.InsertpathButton.Text = 'Insert ';

            % Create UpdatePyenvButton
            app.UpdatePyenvButton = uibutton(app.PythonEnvironmentTab, 'push');
            app.UpdatePyenvButton.ButtonPushedFcn = createCallbackFcn(app, @UpdatePyenvButtonPushed, true);
            app.UpdatePyenvButton.Tooltip = {'Change the path to the python environment'};
            app.UpdatePyenvButton.Position = [10 551 82 36];
            app.UpdatePyenvButton.Text = 'Update';

            % Create TerminatePythonInterpreterButton
            app.TerminatePythonInterpreterButton = uibutton(app.PythonEnvironmentTab, 'push');
            app.TerminatePythonInterpreterButton.ButtonPushedFcn = createCallbackFcn(app, @TerminatePythonInterpreterButtonPushed, true);
            app.TerminatePythonInterpreterButton.Position = [251 31 171 36];
            app.TerminatePythonInterpreterButton.Text = 'Terminate Python Interpreter';

            % Create LoadPythonInterpreterButton
            app.LoadPythonInterpreterButton = uibutton(app.PythonEnvironmentTab, 'push');
            app.LoadPythonInterpreterButton.ButtonPushedFcn = createCallbackFcn(app, @LoadPythonInterpreterButtonPushed, true);
            app.LoadPythonInterpreterButton.Tooltip = {'Load Python Inter '};
            app.LoadPythonInterpreterButton.Position = [60 31 141 36];
            app.LoadPythonInterpreterButton.Text = 'Load Python Interpreter';

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