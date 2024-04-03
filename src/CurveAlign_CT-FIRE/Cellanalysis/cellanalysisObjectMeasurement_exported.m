classdef cellanalysisObjectMeasurement_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ObjectmeasurementsUIFigure  matlab.ui.Figure
        SaveButton                  matlab.ui.control.Button
        CloseButton                 matlab.ui.control.Button
        HistogramsButton            matlab.ui.control.Button
        UITable                     matlab.ui.control.Table
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        objectMeasurement   % structure to show the objectmeasurement;  
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            app.CallingApp = mainAPP;
            app.UITable.ColumnName = {'Image','Name','Class','Parent','Center-X','Center-Y','Orientation','Area','Circularity','ShapeMode','Perimeter'};         
            measurementName = {'position','orientation','area','circularity', 'shapemode'};
            imageName = mainAPP.imageName;
%             objectNumber = size(mainAPP.CAPobjects.cells.cellArray,2);
            cellSelected = mainAPP.objectsView.Selection;
            cellSelectedNumber = length(cellSelected);
            objectNumber = cellSelectedNumber;
            if strcmp(mainAPP.annotationView.Selection,'') && mainAPP.CAPannotations.cellDetectionFlag == 0
                annotationName = 'Tumor-annotation';
                objectNumber = size(mainAPP.CAPobjects.cells.cellArray,2);
            elseif ~strcmp(mainAPP.annotationView.Selection,'') && mainAPP.CAPannotations.cellDetectionFlag == 0
                annotationName = 'Tumor-annotation';
                objectNumber = 0;
                app.UITable.Data = '';
                return;
            else
                annotationSelected = mainAPP.annotationView.Selection;   %cell selection from the GUI
                annotationName = mainAPP.annotationView.Name{annotationSelected};
            end
            measurementsNumber = size(measurementName,2)+1+4;
            tableData = cell(objectNumber,measurementsNumber);  
            
            for i = 1:objectNumber
                if strcmp(mainAPP.annotationView.Selection,'')
                    iS = i;
                else
                    iS = cellSelected(i);  % object on the list
                end
                if strcmp(mainAPP.CAPimage.CellanalysisMethod,'StarDist') || strcmp(mainAPP.CAPimage.CellanalysisMethod,'FromMaskfiles-SD') 
                    tableData{i,1} = imageName;
                    tableData{i,2} = sprintf('cell%d',iS);
                    tableData{i,3} = 'Cell';
                    tableData{i,4} = annotationName;%'TumorAnnotation';
                    tableData{i,5} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).position(2));
                    tableData{i,6} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).position(1));
                    cellOrientation = mainAPP.CAPobjects.cells.cellArray(1,iS).orientation;
                    if cellOrientation < 0
                        cellOrientation = 180 + cellOrientation;
                    end
                    tableData{i,7} = sprintf('%3.1f',cellOrientation);
                    tableData{i,8} = mainAPP.CAPobjects.cells.cellArray(1,iS).area;
                    tableData{i,9} = mainAPP.CAPobjects.cells.cellArray(1,iS).circularity;
                    tableData{i,10} = mainAPP.CAPobjects.cells.cellArray(1,iS).vampireShapeMode;
                else %cellpose and deepcell
                    tableData{i,1} = imageName;
                    tableData{i,2} = sprintf('cell%d',iS);
                    tableData{i,3} = 'cell';
                    tableData{i,4} = annotationName; %'TumorAnnotation';
                    tableData{i,5} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).Position(1));
                    tableData{i,6} = round(mainAPP.CAPobjects.cells.cellArray(1,iS).Position(2));
                    cellOrientation = mainAPP.CAPobjects.cells.cellArray(1,iS).Orientation;
                    if cellOrientation < 0
                        cellOrientation = 180 + cellOrientation;
                    end
                    tableData{i,7} = sprintf('%3.1f',cellOrientation);
                    tableData{i,8} = mainAPP.CAPobjects.cells.cellArray(1,iS).Area;
                    tableData{i,9} = mainAPP.CAPobjects.cells.cellArray(1,iS).Circularity;
                    tableData{i,10} = '';
                end
            end
            
            
            % add fiber info
            fibersSelected = mainAPP.fibersView.Selection;
            fibersSelectedNumber = length(fibersSelected);
            fiberNumber = fibersSelectedNumber;
            
            if fiberNumber > 0
                j = 0;
                for ii = i+1: i+fiberNumber
                    j = j + 1;
                    iS = fibersSelected(j);
                    fiberOrientation = mainAPP.fibersView.orientation{iS};
                    centerX = mainAPP.fibersView.centerX{iS};
                    centerY = mainAPP.fibersView.centerY{iS};
                    tableData{ii,1} = imageName;
                    tableData{ii,2} = sprintf('fiber%d',iS);
                    tableData{ii,3} = 'fiber';
                    tableData{ii,4} = annotationName;%'
                    tableData{ii,5} = centerX;
                    tableData{ii,6} = centerY;
                    tableData{ii,7} = sprintf('%3.1f',fiberOrientation);
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
            OBJoutputName_temp = sprintf('%s_objectsMeasurement*.xlsx',imageNameNOE);
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
            OBJoutputName = sprintf('%s_objectsMeasurement%d.xlsx',imageNameNOE,nOutputfiles+1);
            writecell(app.UITable.ColumnName',fullfile(OBJoutputPath,OBJoutputName),'Sheet','ObjectMeasurements','Range','A1');
            writecell(app.UITable.Data,fullfile(OBJoutputPath,OBJoutputName),'Sheet','ObjectMeasurements','Range','A2');
            fprintf('Objects measurement is saved to %s \n',fullfile(OBJoutputPath,OBJoutputName));

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ObjectmeasurementsUIFigure and hide until all components are created
            app.ObjectmeasurementsUIFigure = uifigure('Visible', 'off');
            app.ObjectmeasurementsUIFigure.Position = [100 100 847 416];
            app.ObjectmeasurementsUIFigure.Name = 'Object measurements';
            app.ObjectmeasurementsUIFigure.Scrollable = 'on';

            % Create UITable
            app.UITable = uitable(app.ObjectmeasurementsUIFigure);
            app.UITable.ColumnName = {'Image'; 'Name'; 'Class'; 'Parent'; 'Center-X'; 'Center-Y'; 'Orientation'; 'Area'; 'Circularity'; 'ShapeMode'; 'Perimeter'};
            app.UITable.RowName = {};
            app.UITable.ButtonDownFcn = createCallbackFcn(app, @UITableButtonDown, true);
            app.UITable.Position = [24 87 791 309];

            % Create HistogramsButton
            app.HistogramsButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.HistogramsButton.Position = [380 21 126 22];
            app.HistogramsButton.Text = 'Histograms';

            % Create CloseButton
            app.CloseButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [532 21 126 22];
            app.CloseButton.Text = 'Close';

            % Create SaveButton
            app.SaveButton = uibutton(app.ObjectmeasurementsUIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [684 21 100 22];
            app.SaveButton.Text = 'Save';

            % Show the figure after all components are created
            app.ObjectmeasurementsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = cellanalysisObjectMeasurement_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ObjectmeasurementsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ObjectmeasurementsUIFigure)
        end
    end
end