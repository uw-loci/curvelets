classdef cellanalysisAnnotationMeasurement_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AnnotationmeasurementsUIFigure  matlab.ui.Figure
        SaveButton                      matlab.ui.control.Button
        CloseButton                     matlab.ui.control.Button
        HistogramsButton                matlab.ui.control.Button
        UITable                         matlab.ui.control.Table
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        annotationMeasurement   % structure to show the annotationMeasurement;  
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            app.CallingApp = mainAPP;
            app.UITable.ColumnName = {'Image','Annotation','AnnotationType','Parent','Center-X','Center-Y',...
                'Annotation-Area','Annotation-Perimeter','Cell-Number','Cell-Area','Cell-Orientation','Cell-Alignment',...
                'Fiber-Number','Fiber-Orientation','Fiber-Alignment(self)',...
                'Fiber2Annotation(boundary)angle','Fiber2Annotation(overall)angle','Fiber2Annotation(centers)angle'};         
%             measurementName = {'position','orientation','area','circularity', 'shapemode'};
            imageName = mainAPP.imageName;
%             annotationNumber = size(mainAPP.CAPannotations.tumorAnnotations.tumorArray,2);
% annotation selected
            annotationsSelected = mainAPP.annotationView.Selection;
            annotationsSelectedNumber = length(annotationsSelected);
            annotationNumber = annotationsSelectedNumber;
            annotationType = mainAPP.annotationView.Type{annotationsSelected};
%             tumorData = mainAPP.CAPannotations.tumorAnnotations.tumorArray(1,annotationNumber);
%             tumorBoundaryCol = tumorData.boundary(:,2);
%             tumorBoundaryRow = tumorData.boundary(:,1);
%             imageH = mainAPP.CAPimage.imageInfo.Height;
%             imageW = mainAPP.CAPimage.imageInfo.Width;
%             tumorMask = poly2mask(tumorBoundaryCol,tumorBoundaryRow,imageH,imageW);
%             stats = regionprops(tumorMask,'Centroid','Area','Perimeter');
            % if strcmp(annotationType,'tumor')
            %     stats = mainAPP.CAPannotations.tumorAnnotations.statsArray{1,annotationsSelected};
            % elseif strcmp(annotationType,'custom_annotation')
            %     stats = mainAPP.CAPannotations.customAnnotations.statsArray{1,annotationsSelected};
            % end
            annotationCenterX = mainAPP.CAPmeasurements.Centroid{annotationsSelected,1}(1,1);
            annotationCenterY = mainAPP.CAPmeasurements.Centroid{annotationsSelected,1}(1,2);
            annotationArea =  mainAPP.CAPmeasurements.Area{annotationsSelected,1};%stats.Area;
            annotationPerimeter =  mainAPP.CAPmeasurements.Perimeter{annotationsSelected,1};%stats.Perimeter;            
            % cell selected
            objectsSelected = mainAPP.objectsView.Selection;
            objectsSelectedNumber = length(objectsSelected);
            cellNumber = objectsSelectedNumber;
            % initialize cell info
            cellArea = 0;
            cellOverallOrientation = nan;
            cellAlignment = nan;
            
            cellOrientations = nan(cellNumber,1);
            
            for i = 1:cellNumber
                iCell = objectsSelected(i);
                if strcmp(mainAPP.CAPimage.CellanalysisMethod,'StarDist') || strcmp(mainAPP.CAPimage.CellanalysisMethod,'FromMaskfiles-SD')
                    cellArea = cellArea + mainAPP.CAPobjects.cells.cellArray(1,iCell).area;
                    tempOrientation = mainAPP.CAPobjects.cells.cellArray(1,iCell).orientation;
                    if tempOrientation < 0
                        tempOrientation = 180 + tempOrientation;
                    end
                    cellOrientations(i,1) = tempOrientation;
                else %cellpose deepceel
                    cellArea = cellArea + mainAPP.CAPobjects.cells.cellArray(1,iCell).Area;
                    tempOrientation = mainAPP.CAPobjects.cells.cellArray(1,iCell).Orientation;
                    if tempOrientation < 0
                        tempOrientation = 180 + tempOrientation;
                    end
                    cellOrientations(i,1) = tempOrientation;
                end
            end
            % use circular statistic to calculate overall orientation and
            % alignment
            vals = cellOrientations;% fibers satisfying boundary conditions
            vals2 = 2*(vals*pi/180); %convert to radians and mult by 2, then divide by 2: this is to scale 0 to 180 up to 0 to 360, this makes the analysis circular, since we are using orientations and not directions
            cellAlignment = circ_r(vals2); %large alignment means angles are highly aligned, result is between 0 and 1
            aveAngle = (180/pi)*circ_mean(vals2)/2;
            aveAngle = mod(180+aveAngle,180);
            cellOverallOrientation = sprintf('%3.1f',aveAngle);
            
            % fiber detected
            % initialize fiber info
            fiberNumber = nan;
            fiberOverallOrientation = nan;
            fiberAlignment = nan;
            fibersSelected = mainAPP.fibersView.Selection;
            fibersSelectedNumber = length(fibersSelected);
            fiberNumber = fibersSelectedNumber;
            if fiberNumber > 0
                fiberOrientations = mainAPP.CAPobjects.fibers.fibFeat(fibersSelected,4);
                % use circular statistic to calculate overall orientation and
                % alignment
                vals = fiberOrientations;% fibers satisfying boundary conditions
                vals2 = 2*(vals*pi/180); %convert to radians and mult by 2, then divide by 2: this is to scale 0 to 180 up to 0 to 360, this makes the analysis circular, since we are using orientations and not directions
                fiberAlignment = circ_r(vals2); %large alignment means angles are highly aligned, result is between 0 and 1
                aveAngle = (180/pi)*circ_mean(vals2)/2;
                aveAngle = mod(180+aveAngle,180);
                fiberOverallOrientation = sprintf('%3.1f',aveAngle);
            end
   
            if strcmp(mainAPP.annotationView.Selection,'') && mainAPP.CAPannotations.cellDetectionFlag == 0
                annotationName = 'Tumor-annotation';
                annotationNumber = size(mainAPP.CAPannotations.tumorAnnotations.tumorArray,2);
                return;
            elseif ~strcmp(mainAPP.annotationView.Selection,'') && mainAPP.CAPannotations.cellDetectionFlag == 0
                annotationName = 'Tumor-annotation';
                annotationNumber = 0;
                app.UITable.Data = '';
                return;
            else
                annotationSelected = mainAPP.annotationView.Selection;   %cell selection from the GUI
                if length(annotationsSelected) == 1
                    annotationName = mainAPP.annotationView.Name{annotationSelected}; %sprintf('Tumor-annotation%d', annotationSelected);
                else
                    annotationName = '';
                end
            end
            % fill the list table
            measurementsNumber = size(app.UITable.ColumnName,1);
            tableData = cell(annotationNumber,measurementsNumber);  
            for i = 1:annotationNumber  
                tableData{i,1} = imageName;
                tableData{i,2} = annotationName; %sprintf('annotation%d',annotationsSelected(i));
                tableData{i,3} = annotationType; %'Tumor';
                tableData{i,4} = 'Image';%'TumorAnnotation';
                tableData{i,5} = round(annotationCenterX);
                tableData{i,6} = round(annotationCenterY);
                tableData{i,7} = annotationArea;
                tableData{i,8} = round(annotationPerimeter);
                tableData{i,9} = cellNumber;
                tableData{i,10} = cellArea;
                tableData{i,11} = cellOverallOrientation;
                tableData{i,12} = cellAlignment;
                tableData{i,13} = fiberNumber;
                tableData{i,14} = fiberOverallOrientation;
                tableData{i,15} = fiberAlignment;
                % check the relative measurment
                if mainAPP.measurementsSettings.relativeAngleFlag == 1
                    datafilePath = mainAPP.fiberdataPath;
                    [~,imageNameNOE] = fileparts(mainAPP.imageName);
                    datafileName = sprintf('%s_boundaryObjectsMeasurements.xlsx',imageNameNOE);
                    if exist(fullfile(datafilePath,datafileName),'file')
                        try
                            summarystats = readcell(fullfile(datafilePath,datafileName),'Sheet','Boundary-summary');
                            tableData{i,16} = sprintf('%3.1f',summarystats{2,6}); % angle 2 annotation edge
                            tableData{i,17} = sprintf('%3.1f',summarystats{2,8}); % angle 2 annotation overall
                            tableData{i,18} = sprintf('%3.1f',summarystats{2,7}); % angle 2 annotation-fiber centers
                        catch exp1
                            fprintf('error in reading the summary of releative measurements: %s \n',exp1.message)
                        end
                    end
                end
            end
            app.UITable.Data = tableData;

        end

        % Button down function: UITable
        function UITableButtonDown(app, event)
            
            
        end

        % Button pushed function: CloseButton
        function CloseButtonPushed(app, event)
            app.delete
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
             % find existing measurements file
            [~,imageNameNOE] = fileparts(app.CallingApp.imageName);
            OBJoutputName_temp = sprintf('%s_annotationsMeasurement*.xlsx',imageNameNOE);
            if ~isempty(app.CallingApp.fiberdataPath)
               OBJoutputPath = app.CallingApp.fiberdataPath;
            else
                CAoutputFolder = fullfile(app.CallingApp.imagePath,'CA_Out');
                if ~exist(CAoutputFolder,'dir')
                    mkdir(CAoutputFolder);
                end
                OBJoutputPath = CAoutputFolder;
            end
            nOutputfiles = length(dir(fullfile(OBJoutputPath,OBJoutputName_temp)));
            OBJoutputName = sprintf('%s_annotationsMeasurement%d.xlsx',imageNameNOE,nOutputfiles+1);
            writecell(app.UITable.ColumnName',fullfile(OBJoutputPath,OBJoutputName),'Sheet','AnnotationsMeasurement','Range','A1');
            writecell(app.UITable.Data,fullfile(OBJoutputPath,OBJoutputName),'Sheet','AnnotationsMeasurement','Range','A2');
            fprintf('Objects measurement is saved to %s \n',fullfile(OBJoutputPath,OBJoutputName));
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create AnnotationmeasurementsUIFigure and hide until all components are created
            app.AnnotationmeasurementsUIFigure = uifigure('Visible', 'off');
            app.AnnotationmeasurementsUIFigure.Position = [100 100 847 416];
            app.AnnotationmeasurementsUIFigure.Name = 'Annotation measurements';
            app.AnnotationmeasurementsUIFigure.Scrollable = 'on';

            % Create UITable
            app.UITable = uitable(app.AnnotationmeasurementsUIFigure);
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.ButtonDownFcn = createCallbackFcn(app, @UITableButtonDown, true);
            app.UITable.Position = [24 87 791 309];

            % Create HistogramsButton
            app.HistogramsButton = uibutton(app.AnnotationmeasurementsUIFigure, 'push');
            app.HistogramsButton.Position = [380 21 126 22];
            app.HistogramsButton.Text = 'Histograms';

            % Create CloseButton
            app.CloseButton = uibutton(app.AnnotationmeasurementsUIFigure, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [532 21 126 22];
            app.CloseButton.Text = 'Close';

            % Create SaveButton
            app.SaveButton = uibutton(app.AnnotationmeasurementsUIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [684 21 100 22];
            app.SaveButton.Text = 'Save';

            % Show the figure after all components are created
            app.AnnotationmeasurementsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = cellanalysisAnnotationMeasurement_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AnnotationmeasurementsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AnnotationmeasurementsUIFigure)
        end
    end
end