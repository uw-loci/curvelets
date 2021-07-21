classdef intersectionGUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        CalculationmethodsDropDown  matlab.ui.control.DropDown
        CalculationmethodsDropDownLabel  matlab.ui.control.Label
        PropertiesButton            matlab.ui.control.Button
        TextArea_2                  matlab.ui.control.TextArea
        TextArea                    matlab.ui.control.TextArea
        DataselectedLabel           matlab.ui.control.Label
        ImageselectedLabel          matlab.ui.control.Label
        SelectDataButton            matlab.ui.control.Button
        SelectImageButton           matlab.ui.control.Button
        ShowIndexCheckBox           matlab.ui.control.CheckBox
        ShowIntersectionCheckBox    matlab.ui.control.CheckBox
        CombineButton               matlab.ui.control.Button
        AddButton                   matlab.ui.control.Button
        ResetButton                 matlab.ui.control.Button
        AutoCombineButton           matlab.ui.control.Button
        RefreshButton               matlab.ui.control.Button
        ExportButton                matlab.ui.control.Button
        DeleteButton                matlab.ui.control.Button
        UITable                     matlab.ui.control.Table
        UIAxes                      matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        lastPATHname;
        plotPoints;
        indexShow;
        showingPoint;
        sizeImg;
        rowNumber;
        intersectionTable;
        image;
        value;
        ogData;
        ipChecked;
        indexChecked;
        filepathSave;
        imageNameSave;
        ipCalculation;
        propertyWindow;
        data1;
        im3d;
    end
    
    properties (Access = public)
        pointColor;
        pointSelectedColor;
        pointSize;
        pointSelectedSize;
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, imgName, imgSize, data, dirout)
            set(app.SelectDataButton,'enable','off');
            set(app.ResetButton,'enable','off');
            set(app.AddButton,'enable','off');
            set(app.DeleteButton,'enable','off');
            set(app.RefreshButton,'enable','off');
            set(app.CombineButton,'enable','off');
            set(app.AutoCombineButton,'enable','off');
            set(app.ExportButton,'enable','off');
            set(app.ShowIndexCheckBox,'enable','off');
            set(app.ShowIntersectionCheckBox,'enable','off');
            set(app.PropertiesButton,'enable','off');
            set(app.CalculationmethodsDropDown,'enable','off');
            app.UIAxes.Toolbar.Visible = 'on';
            app.UIAxes.Interactions = zoomInteraction;
            app.pointColor = 'Red';
            app.pointSelectedColor = 'Yellow';
            app.pointSize = 15;
            app.pointSelectedSize = 15;
            if exist('lastPATH_CTF.mat','file')
                app.lastPATHname = importdata('lastPATH_CTF.mat');
                if isequal(app.lastPATHname,0)
                    app.lastPATHname = '';
                end
            else
                %use current directory
                app.lastPATHname = '';
            end
            if exist('imgName', 'var') && exist('imgSize', 'var')...
                    && exist ('data', 'var') 
                img = imread(imgName);
                app.image = img;
                im3 = zeros(imgSize);
                app.im3d = im3;
                answer = questdlg('Please select a method to calculate intersection points', ...
                	'Methods of calculation', 'Junction by interpolation', ...
                    'Junction by regular','Nucleation','Junction by interpolation');
                switch answer
                    case 'Junction by interpolation'
                        for i = 1:data.trim.LFa
                            Fai(i) = data.Fai(data.trim.FN(i));
                        end
                        IP = lineIntersection(data.Xai, im3, Fai);
                        app.CalculationmethodsDropDown.Value = 'Interpolation';
                    case 'Junction by regular'
                        for i = 1:data.trim.LFa
                            Fa(i) = data.Fa(data.trim.FN(i));
                        end
                        IP = lineIntersection(data.Xa, im3, Fa);
                        app.CalculationmethodsDropDown.Value = 'Regular';
                    case 'Nucleation'
                        IP = intersection(data.Xa, data.Fa);
                        app.CalculationmethodsDropDown.Value = 'Nucleation';
                end
                app.data1 = data;
%                 for i = 1:data.trim.LFa
%                     Fai(i) = data.Fai(data.trim.FN(i));
%                 end
%                 IP = lineIntersection(data.Xai, im3, Fai);
                app.intersectionTable = [];
                app.ogData = [];
                for i = 1:length(IP)
                    app.intersectionTable = [app.intersectionTable; IP(i,1) IP(i,2) i];
                    app.ogData = [app.intersectionTable; IP(i,1) IP(i,2) i];
                end
                C = num2cell(app.intersectionTable);
                tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
                app.ipCalculation.operation = [];
                imshow(img, 'parent', app.UIAxes, 'InitialMagnification','fit');
                hold(app.UIAxes, 'on')
                title(app.UIAxes, 'fiber results');
                xlabel(app.UIAxes, '');
                ylabel(app.UIAxes, '');
                app.UITable.Data = tdata;
                app.sizeImg = imgSize;
                set(app.SelectDataButton,'enable','on');
                set(app.ResetButton,'enable','on');
                set(app.AddButton,'enable','on');
                set(app.DeleteButton,'enable','on');
                set(app.RefreshButton,'enable','on');
                set(app.CombineButton,'enable','on');
                set(app.AutoCombineButton,'enable','on');
                set(app.ExportButton,'enable','on');
                set(app.ShowIndexCheckBox,'enable','on');
                set(app.ShowIntersectionCheckBox,'enable','on');
                set(app.PropertiesButton,'enable','on');
                set(app.CalculationmethodsDropDown,'enable','on');
                app.imageNameSave = imgName;
                app.filepathSave = dirout;
            end
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            indices = event.Indices;
            app.rowNumber = event.Indices;
            x = app.intersectionTable(indices(1),1);
            y = app.intersectionTable(indices(1),2);
            index = string(app.intersectionTable(indices(1),3));
            delete(app.showingPoint);
            if strcmp(app.pointSelectedColor, 'Red')
                app.showingPoint = plot(app.UIAxes,x,y,'r.','MarkerSize',app.pointSelectedSize);
            elseif strcmp(app.pointSelectedColor, 'Yellow')
                app.showingPoint = plot(app.UIAxes,x,y,'y.','MarkerSize',app.pointSelectedSize);
            elseif strcmp(app.pointSelectedColor, 'Blue')
                app.showingPoint = plot(app.UIAxes,x,y,'b.','MarkerSize',app.pointSelectedSize);
            elseif strcmp(app.pointSelectedColor, 'Index')
                app.showingPoint = text(app.UIAxes,x,y,index,'Color','white', ...
                    'BackgroundColor','black','FontSize',12,"FontWeight","bold");
            end
%             app.showingPoint = plot(app.UIAxes,x,y,'y.' ...
%                 ,'MarkerSize',15);
        end

        % Button pushed function: DeleteButton
        function DeleteButtonPushed(app, event)
           try
               indices = app.rowNumber;
               operation.name = 'Delete';
               x = app.intersectionTable(indices(1),1);
               y = app.intersectionTable(indices(1),2);
               operation.data = [x,y,1];
               app.UITable.Data(indices(1),:) = [];
               app.intersectionTable(indices(1),:) = [];
               RefreshButtonPushed(app, event)
               app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
           catch
               disp("Deletion failed!")
           end
        end

        % Button pushed function: RefreshButton
        function RefreshButtonPushed(app, event)
            hold(app.UIAxes,'off')
            C = num2cell(app.intersectionTable);
            tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
            img = app.image;
            imshow(img, 'parent', app.UIAxes);
            hold(app.UIAxes, 'on')
            title(app.UIAxes, 'fiber results');
            xlabel(app.UIAxes, '');
            ylabel(app.UIAxes, '');
            if app.ipChecked 
                app.plotPoints = plot(app.UIAxes,app.intersectionTable(:,1),...
                    app.intersectionTable(:,2),'r.','MarkerSize',15);
            end
            if app.indexChecked
                index = string(app.intersectionTable(:,3));
                x = app.intersectionTable(:,1);
                y = app.intersectionTable(:,2);
                app.indexShow = text(app.UIAxes,x,y,index,'Color','white', ...
                    'BackgroundColor','black','FontSize',12,"FontWeight","bold");
            end
            app.UITable.Data = tdata;
            C = num2cell(app.intersectionTable);
            tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
            app.UITable.Data = tdata;
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            IP = app.intersectionTable;
            for i = 1:length(IP)
                IP(i,4) = IP(i,3);
                IP(i,3) = 1;
            end
            [~,imgName,~] = fileparts(app.imageNameSave);
            fileSaved = "intersection_points_" + imgName;
            f = fullfile(app.filepathSave, fileSaved);
            % uisave('IP','intersection_points')
            answer = questdlg('Please select file format: ', 'formats: ', ...
                '.xlsx', '.csv', '.xlsx');
            switch answer
                case '.xlsx'
                    f = f + ".xlsx";
%                     xlswrite(f,IP);
                    writematrix(IP, f)
                case '.csv'
                    f = f + ".csv";
                    csvwrite(f,IP);
            end
            app.ipCalculation.IP = app.intersectionTable;
            dataSaved = "intersection_calculation_" + imgName + ".mat";
            fData = fullfile(app.filepathSave, dataSaved);
            intersectionCalculation = app.ipCalculation;
            save(fData,'intersectionCalculation')
        end

        % Button pushed function: AutoCombineButton
        function AutoCombineButtonPushed(app, event)
            answer = inputdlg('Points not closer than','distance', [1 20]);
            distance = 0;
            try 
                distance = str2num(answer{1});
            catch 
                disp('Please enter numeric values!')
            end
            IP = app.intersectionTable;
            sizeIMG = app.sizeImg;
            sizeIMG = [1,sizeIMG(1),sizeIMG(2)];
            app.intersectionTable = ipCombineRegions(IP, sizeIMG, distance);
            RefreshButtonPushed(app, event)
            operation.name = 'AutoCombine';
            operation.data = answer{1};
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            app.intersectionTable = app.ogData;
            RefreshButtonPushed(app, event)
            operation.name = 'Reset';
            operation.data = [];
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
%             intersectionGUI;
%             delete(app)
        end

        % Button pushed function: AddButton
        function AddButtonPushed(app, event)
            answer = inputdlg({'X','Y'},'Coordinates', [1 10; 1 10], {'0'; '0'}); 
            try 
                x = str2num(answer{1});
                y = str2num(answer{2});
            catch ME
                f = msgbox('Please enter numeric values!');
                disp('Please enter numeric values!')
            end
            lengthOfIP = length(app.intersectionTable);
            index = app.intersectionTable(lengthOfIP,3) + 1;
            app.intersectionTable = [app.intersectionTable; x y index];
            operation.name = 'Add';
            operation.data = [x,y,1];
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                operation];
            RefreshButtonPushed(app, event)
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            indices = event.Indices;
            newData = event.NewData;
            oldData = app.intersectionTable(indices(1),indices(2));
            app.intersectionTable(indices(1),indices(2)) = newData;
            operation.name = 'edit';
            operation.data = [indices(1) indices(2) oldData newData];
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                operation];
            RefreshButtonPushed(app, event)
        end

        % Button pushed function: CombineButton
        function CombineButtonPushed(app, event)
            answer = inputdlg('indices','indices', [2 20]); 
            try 
                indexToCombine = str2num(answer{1});
            catch
                disp('Please enter numeric values!')
            end
            count = 1;
            for i = 1:length(indexToCombine)
                found(i) = false;
            end
            for i = 1:length(app.intersectionTable)
                for j = 1:length(indexToCombine)
                    if app.intersectionTable(i,3) == indexToCombine(j)
                        found(j) = true;
                        x(count) = app.intersectionTable(i,1);
                        y(count) = app.intersectionTable(i,2);
                        count = count + 1;
                    end
                end
            end
            count = count - 1;
            if count == length(indexToCombine)
                xAdd = 0;
                yAdd = 0;
                for i = 1:length(indexToCombine)
                    xAdd = xAdd + x(i);
                    yAdd = yAdd + y(i);
                end
                xAdd = round(xAdd / length(indexToCombine));
                yAdd = round(yAdd / length(indexToCombine));
                lengthOfIP = length(app.intersectionTable);
                index = app.intersectionTable(lengthOfIP,3) + 1;
                app.intersectionTable = [app.intersectionTable; xAdd yAdd index];
                i = 1;
                while i ~= lengthOfIP
                    for j = 1:length(indexToCombine)
                        if app.intersectionTable(i,3) == indexToCombine(j)
                            app.UITable.Data(i,:) = [];
                            app.intersectionTable(i,:) = [];
                            lengthOfIP = lengthOfIP - 1;
                        end
                    end
                    i = i + 1;
                end
            end
            operation.name = 'Combine';
            operation.data = [indexToCombine];
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
%             found1 = false;
%             found2 = false;
%             for i = 1:length(app.intersectionTable)
%                 if app.intersectionTable(i,3) == app.combine1
%                     x1 = app.intersectionTable(i,1);
%                     y1 = app.intersectionTable(i,2);
%                     found1 = true;
%                 end
%                 if app.intersectionTable(i,3) == app.combine2
%                     x2 = app.intersectionTable(i,1);
%                     y2 = app.intersectionTable(i,2);
%                     found2 = true;
%                 end
%             end
%             if found1 && found2
%                 xadd = (x1 + x2) / 2;
%                 yadd = (y1 + y2) / 2;
%                 lengthOfIP = length(app.intersectionTable);
%                 index = app.intersectionTable(lengthOfIP,3) + 1;
%                 app.intersectionTable = [app.intersectionTable; xadd yadd index];
%                 for i = 1:length(app.intersectionTable)
%                     if app.intersectionTable(i,3) == app.combine1
%                         app.UITable.Data(i,:) = [];
%                         app.intersectionTable(i,:) = [];
%                         break
%                     end
%                 end
%                 for i = 1:length(app.intersectionTable)
%                     if app.intersectionTable(i,3) == app.combine2
%                         app.UITable.Data(i,:) = [];
%                         app.intersectionTable(i,:) = [];
%                         break
%                     end
%                 end
%                 RefreshButtonPushed(app, event)
%             end
            RefreshButtonPushed(app, event)
        end

        % Value changed function: ShowIntersectionCheckBox
        function ShowIntersectionCheckBoxValueChanged(app, event)
            app.ipChecked = app.ShowIntersectionCheckBox.Value;
            if app.ipChecked
                if strcmp(app.pointColor, 'Red')
                        app.plotPoints = plot(app.UIAxes,app.intersectionTable(:,1), ...
                            app.intersectionTable(:,2),'r.','MarkerSize',app.pointSize);
                elseif strcmp(app.pointColor, 'Yellow')
                        app.plotPoints = plot(app.UIAxes,app.intersectionTable(:,1), ...
                            app.intersectionTable(:,2),'y.','MarkerSize',app.pointSize);
                elseif strcmp(app.pointColor, 'Blue')
                        app.plotPoints = plot(app.UIAxes,app.intersectionTable(:,1), ...
                            app.intersectionTable(:,2),'b.','MarkerSize',app.pointSize);
                end
            else
                delete(app.plotPoints)
            end
        end

        % Value changed function: ShowIndexCheckBox
        function ShowIndexCheckBoxValueChanged(app, event)
            app.indexChecked = app.ShowIndexCheckBox.Value;
            if app.indexChecked
                index = string(app.intersectionTable(:,3));
                x = app.intersectionTable(:,1);
                y = app.intersectionTable(:,2);
                app.indexShow = text(app.UIAxes,x,y,index,'Color','white', ...
                    'BackgroundColor','black','FontSize',12,"FontWeight","bold");
            else
                delete(app.indexShow)
            end
        end

        % Button pushed function: SelectImageButton
        function SelectImageButtonPushed(app, event)
            [filename,filepath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.png';'*.*'}, ...
                'Select File to Open',app.lastPATHname);
            drawnow;
            figure(app.UIFigure)
            fullname = [filepath, filename];
            ImageFile = imread(fullname);
            app.image = ImageFile;
            imshow(ImageFile, 'parent', app.UIAxes, 'InitialMagnification','fit');
            hold(app.UIAxes, 'on')
            title(app.UIAxes, 'fiber results');
            xlabel(app.UIAxes, '');
            ylabel(app.UIAxes, '');
            app.sizeImg = size(app.image);
            % app.Label.Text = filename;
            app.TextArea.Value = filename;
            drawnow
            set(app.SelectDataButton,'enable','on');
            app.imageNameSave = filename;
        end

        % Button pushed function: SelectDataButton
        function SelectDataButtonPushed(app, event)
            try
                [filename,filepath] = uigetfile('*.mat', 'Select File to Open', app.lastPATHname);
                drawnow;
                figure(app.UIFigure)
                fullname = [filepath, filename];
                dataFile = load(fullname);
                im3 = zeros(1, app.sizeImg(1), app.sizeImg(2));
                app.im3d = im3;
                % for i = 1:dataFile.data.trim.LFa
                %     Fai(i) = dataFile.data.Fai(dataFile.data.trim.FN(i));
                % end
                % IP = lineIntersection(dataFile.data.Xai, im3, Fai);
                answer = questdlg('Please select a method to calculate intersection points', ...
                    'Methods of calculation', 'Junction by interpolation', ...
                    'Junction by regular','Nucleation','Junction by interpolation');
                switch answer
                    case 'Junction by interpolation'
                        for i = 1:dataFile.data.trim.LFa
                            Fai(i) = dataFile.data.Fai(dataFile.data.trim.FN(i));
                        end
                        IP = lineIntersection(dataFile.data.Xai, im3, Fai);
                        app.CalculationmethodsDropDown.Value = 'Interpolation';
                    case 'Junction by regular'
                        for i = 1:dataFile.data.trim.LFa
                            Fa(i) = dataFile.data.Fa(dataFile.data.trim.FN(i));
                        end
                        IP = lineIntersection(dataFile.data.Xa, im3, Fa);
                        app.CalculationmethodsDropDown.Value = 'Regular';
                    case 'Nucleation'
                        IP = intersection(dataFile.data.Xa, dataFile.data.Fa);
                        app.CalculationmethodsDropDown.Value = 'Nucleation';
                end
                for i = 1:length(IP)
                    app.intersectionTable = [app.intersectionTable; IP(i,1) IP(i,2) i];
                    app.ogData = [app.intersectionTable; IP(i,1) IP(i,2) i];
                end
                C = num2cell(app.intersectionTable);
                tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
                app.ipCalculation.operation = [];
                app.UITable.Data = tdata;
                % app.Label_2.Text = filename;
                app.TextArea_2.Value = filename;
                drawnow
                set(app.ResetButton,'enable','on');
                set(app.AddButton,'enable','on');
                set(app.DeleteButton,'enable','on');
                set(app.RefreshButton,'enable','on');
                set(app.CombineButton,'enable','on');
                set(app.AutoCombineButton,'enable','on');
                set(app.ExportButton,'enable','on');
                set(app.ShowIndexCheckBox,'enable','on');
                set(app.ShowIntersectionCheckBox,'enable','on');
                set(app.PropertiesButton,'enable','on');
                set(app.CalculationmethodsDropDown,'enable','on');
                app.filepathSave = filepath;
                app.data1 = dataFile.data;
            catch
                app.TextArea_2.Value = 'Some data might be missing!';
                drawnow
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
        end

        % Button pushed function: PropertiesButton
        function PropertiesButtonPushed(app, event)
            app.propertyWindow = intersectionProperties(app, app.pointColor, ...
                app.pointSelectedColor, app.pointSize, app.pointSelectedSize);
        end

        % Value changed function: CalculationmethodsDropDown
        function CalculationmethodsDropDownValueChanged(app, event)
            method = app.CalculationmethodsDropDown.Value;
            switch method
                case '-Selected'
                case 'Interpolation'
                    for i = 1:app.data1.trim.LFa
                        Fai(i) = app.data1.Fai(app.data1.trim.FN(i));
                    end
                    IP = lineIntersection(app.data1.Xai, app.im3d, Fai);
                case 'Regular'
                    for i = 1:app.data1.trim.LFa
                        Fa(i) = app.data1.Fa(app.data1.trim.FN(i));
                    end
                    IP = lineIntersection(app.data1.Xa, app.im3d, Fa);
                case 'Nucleation'
                    IP = intersection(app.data1.Xa,app.data1.Fa);
            end
            app.intersectionTable = [];
            for i = 1:length(IP)
                app.intersectionTable = [app.intersectionTable; IP(i,1) IP(i,2) i];
                app.ogData = [app.intersectionTable; IP(i,1) IP(i,2) i];
            end
            C = num2cell(app.intersectionTable);
            tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
            app.ipCalculation.operation = [];
            app.UITable.Data = tdata;
            if app.ipChecked 
                app.plotPoints = plot(app.UIAxes,app.intersectionTable(:,1),...
                    app.intersectionTable(:,2),'r.','MarkerSize',15);
            end
            if app.indexChecked
                index = string(app.intersectionTable(:,3));
                x = app.intersectionTable(:,1);
                y = app.intersectionTable(:,2);
                app.indexShow = text(app.UIAxes,x,y,index,'Color','white', ...
                    'BackgroundColor','black','FontSize',12,"FontWeight","bold");
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 980 698];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.WindowState = 'maximized';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'21.68x', '4.19x', 119, '0x'};
            app.GridLayout.RowHeight = {22, '1x', 22, '1.03x', '0x', 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 100};
            app.GridLayout.ColumnSpacing = 5.6;
            app.GridLayout.RowSpacing = 6.68421052631579;
            app.GridLayout.Padding = [5.6 6.68421052631579 5.6 6.68421052631579];

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            title(app.UIAxes, 'image')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            app.UIAxes.Layout.Row = [1 20];
            app.UIAxes.Layout.Column = 1;

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {'X'; 'Y'; 'Index'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.ColumnEditable = true;
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Layout.Row = [1 20];
            app.UITable.Layout.Column = 1;

            % Create DeleteButton
            app.DeleteButton = uibutton(app.GridLayout, 'push');
            app.DeleteButton.ButtonPushedFcn = createCallbackFcn(app, @DeleteButtonPushed, true);
            app.DeleteButton.Layout.Row = 10;
            app.DeleteButton.Layout.Column = [3 4];
            app.DeleteButton.Text = {'Delete'; ''};

            % Create ExportButton
            app.ExportButton = uibutton(app.GridLayout, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Layout.Row = 14;
            app.ExportButton.Layout.Column = [3 4];
            app.ExportButton.Text = {'Export'; ''};

            % Create RefreshButton
            app.RefreshButton = uibutton(app.GridLayout, 'push');
            app.RefreshButton.ButtonPushedFcn = createCallbackFcn(app, @RefreshButtonPushed, true);
            app.RefreshButton.Layout.Row = 11;
            app.RefreshButton.Layout.Column = 3;
            app.RefreshButton.Text = 'Refresh';

            % Create AutoCombineButton
            app.AutoCombineButton = uibutton(app.GridLayout, 'push');
            app.AutoCombineButton.ButtonPushedFcn = createCallbackFcn(app, @AutoCombineButtonPushed, true);
            app.AutoCombineButton.Layout.Row = 13;
            app.AutoCombineButton.Layout.Column = [3 4];
            app.AutoCombineButton.Text = {'Auto Combine'; ''};

            % Create ResetButton
            app.ResetButton = uibutton(app.GridLayout, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Layout.Row = 8;
            app.ResetButton.Layout.Column = [3 4];
            app.ResetButton.Text = 'Reset';

            % Create AddButton
            app.AddButton = uibutton(app.GridLayout, 'push');
            app.AddButton.ButtonPushedFcn = createCallbackFcn(app, @AddButtonPushed, true);
            app.AddButton.Layout.Row = 9;
            app.AddButton.Layout.Column = [3 4];
            app.AddButton.Text = {'Add'; ''};

            % Create CombineButton
            app.CombineButton = uibutton(app.GridLayout, 'push');
            app.CombineButton.ButtonPushedFcn = createCallbackFcn(app, @CombineButtonPushed, true);
            app.CombineButton.Layout.Row = 12;
            app.CombineButton.Layout.Column = [3 4];
            app.CombineButton.Text = 'Combine';

            % Create ShowIntersectionCheckBox
            app.ShowIntersectionCheckBox = uicheckbox(app.GridLayout);
            app.ShowIntersectionCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowIntersectionCheckBoxValueChanged, true);
            app.ShowIntersectionCheckBox.Text = 'Show Intersection';
            app.ShowIntersectionCheckBox.Layout.Row = 16;
            app.ShowIntersectionCheckBox.Layout.Column = 3;

            % Create ShowIndexCheckBox
            app.ShowIndexCheckBox = uicheckbox(app.GridLayout);
            app.ShowIndexCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowIndexCheckBoxValueChanged, true);
            app.ShowIndexCheckBox.Text = 'Show Index';
            app.ShowIndexCheckBox.Layout.Row = 17;
            app.ShowIndexCheckBox.Layout.Column = 3;

            % Create SelectImageButton
            app.SelectImageButton = uibutton(app.GridLayout, 'push');
            app.SelectImageButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImageButtonPushed, true);
            app.SelectImageButton.Layout.Row = 6;
            app.SelectImageButton.Layout.Column = [3 4];
            app.SelectImageButton.Text = 'Select Image';

            % Create SelectDataButton
            app.SelectDataButton = uibutton(app.GridLayout, 'push');
            app.SelectDataButton.ButtonPushedFcn = createCallbackFcn(app, @SelectDataButtonPushed, true);
            app.SelectDataButton.Layout.Row = 7;
            app.SelectDataButton.Layout.Column = [3 4];
            app.SelectDataButton.Text = 'Select Data';

            % Create ImageselectedLabel
            app.ImageselectedLabel = uilabel(app.GridLayout);
            app.ImageselectedLabel.Layout.Row = 1;
            app.ImageselectedLabel.Layout.Column = 3;
            app.ImageselectedLabel.Text = 'Image selected:';

            % Create DataselectedLabel
            app.DataselectedLabel = uilabel(app.GridLayout);
            app.DataselectedLabel.Layout.Row = 3;
            app.DataselectedLabel.Layout.Column = 3;
            app.DataselectedLabel.Text = 'Data selected:';

            % Create TextArea
            app.TextArea = uitextarea(app.GridLayout);
            app.TextArea.Layout.Row = 2;
            app.TextArea.Layout.Column = 3;

            % Create TextArea_2
            app.TextArea_2 = uitextarea(app.GridLayout);
            app.TextArea_2.Layout.Row = 4;
            app.TextArea_2.Layout.Column = 3;

            % Create PropertiesButton
            app.PropertiesButton = uibutton(app.GridLayout, 'push');
            app.PropertiesButton.ButtonPushedFcn = createCallbackFcn(app, @PropertiesButtonPushed, true);
            app.PropertiesButton.Layout.Row = 15;
            app.PropertiesButton.Layout.Column = 3;
            app.PropertiesButton.Text = {'Properties'; ''};

            % Create CalculationmethodsDropDownLabel
            app.CalculationmethodsDropDownLabel = uilabel(app.GridLayout);
            app.CalculationmethodsDropDownLabel.Layout.Row = 18;
            app.CalculationmethodsDropDownLabel.Layout.Column = 3;
            app.CalculationmethodsDropDownLabel.Text = {'Calculation methods:'; ''};

            % Create CalculationmethodsDropDown
            app.CalculationmethodsDropDown = uidropdown(app.GridLayout);
            app.CalculationmethodsDropDown.Items = {'-Select-', 'Interpolation', 'Regular', 'Nucleation'};
            app.CalculationmethodsDropDown.ValueChangedFcn = createCallbackFcn(app, @CalculationmethodsDropDownValueChanged, true);
            app.CalculationmethodsDropDown.Layout.Row = 19;
            app.CalculationmethodsDropDown.Layout.Column = 3;
            app.CalculationmethodsDropDown.Value = '-Select-';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = intersectionGUI_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end