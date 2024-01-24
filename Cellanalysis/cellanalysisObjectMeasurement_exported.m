classdef cellanalysisObjectMeasurement_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ObjectmeasurmentsUIFigure  matlab.ui.Figure
        SaveButton                 matlab.ui.control.Button
        CloseButton                matlab.ui.control.Button
        HistogramsButton           matlab.ui.control.Button
        UITable                    matlab.ui.control.Table
    end

    
    properties (Access = public)
        CallingApp % main app class handle
        objectMeasurement   % structure to show the objectmeasurement;  
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP)
            app.UITable.ColumnName = {'Image','Name','Class','Parent','Center-X','Center-Y','Orientation','Area','Circularity','ShapeMode','Perimeter'};         
            measurementName = {'position','orientation','area','circularity', 'shapemode'};
            imageName = mainAPP.CAPobjects.imageName;
            objectNumber = size(mainAPP.CAPobjects.cells,2);
            measurementsNumber = size(measurementName,2)+1+4;
            tableData = cell(objectNumber,measurementsNumber);
            for i = 1:objectNumber
                tableData{i,1} = imageName;
                tableData{i,2} = sprintf('cell%d',i);
                tableData{i,3} = 'cell';
                tableData{i,4} = 'TumorAnnotation'
                tableData{i,5} = mainAPP.CAPobjects.cells(1,i).position(1);
                tableData{i,6} = mainAPP.CAPobjects.cells(1,i).position(2);
                tableData{i,7} = mainAPP.CAPobjects.cells(1,i).orientation;
                tableData{i,8} = mainAPP.CAPobjects.cells(1,i).area;
                tableData{i,9} = mainAPP.CAPobjects.cells(1,i).circularity;
                tableData{i,10} = mainAPP.CAPobjects.cells(1,i).vampireShapeMode;
            end
            app.UITable.Data = tableData;
     
  
        end

        % Button down function: UITable
        function UITableButtonDown(app, event)
            
            
        end

        % Button pushed function: CloseButton
        function CloseButtonPushed(app, event)
            app.delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ObjectmeasurmentsUIFigure and hide until all components are created
            app.ObjectmeasurmentsUIFigure = uifigure('Visible', 'off');
            app.ObjectmeasurmentsUIFigure.Position = [100 100 847 416];
            app.ObjectmeasurmentsUIFigure.Name = 'Object measurments';
            app.ObjectmeasurmentsUIFigure.Scrollable = 'on';

            % Create UITable
            app.UITable = uitable(app.ObjectmeasurmentsUIFigure);
            app.UITable.ColumnName = {'Image'; 'Name'; 'Class'; 'Parent'; 'Center-X'; 'Center-Y'; 'Orientation'; 'Area'; 'Circularity'; 'ShapeMode'; 'Perimeter'};
            app.UITable.RowName = {};
            app.UITable.ButtonDownFcn = createCallbackFcn(app, @UITableButtonDown, true);
            app.UITable.Position = [24 87 791 309];

            % Create HistogramsButton
            app.HistogramsButton = uibutton(app.ObjectmeasurmentsUIFigure, 'push');
            app.HistogramsButton.Position = [380 21 126 22];
            app.HistogramsButton.Text = 'Histograms';

            % Create CloseButton
            app.CloseButton = uibutton(app.ObjectmeasurmentsUIFigure, 'push');
            app.CloseButton.ButtonPushedFcn = createCallbackFcn(app, @CloseButtonPushed, true);
            app.CloseButton.Position = [532 21 126 22];
            app.CloseButton.Text = 'Close';

            % Create SaveButton
            app.SaveButton = uibutton(app.ObjectmeasurmentsUIFigure, 'push');
            app.SaveButton.Position = [684 21 100 22];
            app.SaveButton.Text = 'Save';

            % Show the figure after all components are created
            app.ObjectmeasurmentsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = cellanalysisObjectMeasurement_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ObjectmeasurmentsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ObjectmeasurmentsUIFigure)
        end
    end
end