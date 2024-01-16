classdef intersectionGUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        FiberIntersectionPointDetectionUIFigure  matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        TabGroup                    matlab.ui.container.TabGroup
        OriginalTab                 matlab.ui.container.Tab
        UIAxesOriginal              matlab.ui.control.UIAxes
        OverlayTab                  matlab.ui.container.Tab
        UIAxesOver                  matlab.ui.control.UIAxes
        CenterLineTab               matlab.ui.container.Tab
        UIAxesRidge                 matlab.ui.control.UIAxes
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
        filenameSave;
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
        pointShape;
        pointSelectedShape;
        selectedTab; % Description
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, imgName, imgSize, data, dirout, name)
            % % only keep the CurveAlign GUI open
            fig_ALL = findall(0,'type','figure');
            fig_keep{1} = findall(0,'Tag','IP detection main GUI');
            fig_keep{2} = findall(0,'Tag','CurveAlign main GUI');
            fig_keep{3} = findall(0,'Tag','CT-FIRE main GUI');
            if ~isempty(fig_ALL)
                for ik = 1:length(fig_keep)
                    if ~isempty(fig_keep{ik})
                        if length(fig_keep{ik})> 1
                            fig_keep_check = fig_keep{ik}(end); 
                        else
                            fig_keep_check = fig_keep{ik};
                        end
                        iKeep  = 0;
                        deleteIndex = [];
                        for ij = 1:length(fig_ALL)
                            if (strcmp (fig_ALL(ij).Name,fig_keep_check.Name) == 1)
                                iKeep = iKeep+1;
                                deleteIndex(iKeep) = ij;
                            end
                        end
                        fig_ALL(deleteIndex(1)) = []; %if theere are more than one
                        % figures with the same tag, only keep the most recent GUI
                    end
                end
                delete(fig_ALL)
                clear ik ij fig_ALL fig_keep
            end

            app.FiberIntersectionPointDetectionUIFigure.WindowState = 'normal';
            screenSize= get(0,'screensize');
            screenWidth = screenSize(3);
            screenHeight = screenSize(4);
            UIfigure_pos = app.FiberIntersectionPointDetectionUIFigure.Position;
            UIFigure_X = screenWidth*0.05;
            UIFigure_Width = UIfigure_pos(3);
            UIFigure_Height = UIfigure_pos(4);
            UIFigure_Y = screenHeight-screenHeight*0.1-UIFigure_Height; 
            app.FiberIntersectionPointDetectionUIFigure.Position = [UIFigure_X UIFigure_Y UIFigure_Width UIFigure_Height];
            s = uistyle('HorizontalAlignment','left'); % create a style
            addStyle(app.UITable,s) % adjust the style
            set(app.SelectDataButton,'enable','off');
            % set(app.ResetButton,'enable','off');
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
            app.UIAxesOriginal.Toolbar.Visible = 'on';
            app.UIAxesOriginal.Interactions = [];
            app.pointColor = 'Red';
            app.pointSelectedColor = 'Yellow';
            app.pointSize = 15;
            app.pointSelectedSize = 15;
            app.pointShape = '.';
            app.pointSelectedShape = '.';
            app.selectedTab = 1; % 1: show image in the original Tab; 2: overlay tab; 3: centerline tab 
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
                app.ipCalculation.operation = [];
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
                        operation.name = 'Method';
                        operation.data = 'Junction by interpolation';
                    case 'Junction by regular'
                        for i = 1:data.trim.LFa
                            Fa(i) = data.Fa(data.trim.FN(i));
                        end
                        IP = lineIntersection(data.Xa, im3, Fa);
                        app.CalculationmethodsDropDown.Value = 'Regular';
                        operation.name = 'Method';
                        operation.data = 'Junction by regular';
                    case 'Nucleation'
                        IP = intersection(data.Xa, data.Fa);
                        app.CalculationmethodsDropDown.Value = 'Nucleation';
                        operation.name = 'Method';
                        operation.data = 'Nucleation';
                end
                app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
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
                imshow(img, 'parent', app.UIAxesOriginal, 'InitialMagnification','fit');
                hold(app.UIAxesOriginal, 'on')
                title(app.UIAxesOriginal, 'fiber results');
                xlabel(app.UIAxesOriginal, '');
                ylabel(app.UIAxesOriginal, '');
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
                [~,app.filenameSave] = fileparts(name);
                app.filepathSave = dirout;
            end
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            % The steps to select different cells are as follows:
            % 1) Click a single cell
            % 2) Hold the CTRL key and click a different cell
            % 3) Release the CTRL key and hold the SHIFT key. Click the same cell again.
            indices = event.Indices;
            app.rowNumber = event.Indices;
            RefreshButtonPushed(app, event)
            numberSelected = size(indices);
            numberSelected = numberSelected(1);
            for i = 1:numberSelected
                x(i) = app.intersectionTable(indices(i,1),1);
                y(i) = app.intersectionTable(indices(i,1),2);
            end
            index = string(app.intersectionTable(indices(1),3));
%             for i = 1:numberSelected
%                 delete(app.showingPoint(i));
%             end 
            if strcmp(app.pointSelectedColor, 'Red')
                for i = 1:numberSelected
                    app.showingPoint(i) = plot(app.UIAxesOriginal,x(i),y(i),'r.','MarkerSize', ...
                        app.pointSelectedSize,'Marker',app.pointSelectedShape,'LineWidth',2);
                end
            elseif strcmp(app.pointSelectedColor, 'Yellow')
                for i = 1:numberSelected
                    app.showingPoint(i) = plot(app.UIAxesOriginal,x(i),y(i),'y.','MarkerSize', ...
                        app.pointSelectedSize,'Marker',app.pointSelectedShape,'LineWidth',2);
                end
            elseif strcmp(app.pointSelectedColor, 'Blue')
                for i = 1:numberSelected
                    app.showingPoint(i) = plot(app.UIAxesOriginal,x(i),y(i),'b.','MarkerSize', ...
                        app.pointSelectedSize,'Marker',app.pointSelectedShape,'LineWidth',2);
                end
            elseif strcmp(app.pointSelectedColor, 'Index')
                for i = 1:numberSelected
                    app.showingPoint(i) = text(app.UIAxesOriginal,x(i),y(i),index,'Color','white', ...
                        'BackgroundColor','black','FontSize',12,"FontWeight","bold");
                end
            end
%             app.showingPoint = plot(app.UIAxesOriginal,x,y,'y.' ...
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
            hold(app.UIAxesOriginal,'off')
            C = num2cell(app.intersectionTable);
            tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
            img = app.image;
            imshow(img, 'parent', app.UIAxesOriginal);
            hold(app.UIAxesOriginal, 'on')
            title(app.UIAxesOriginal, 'fiber results');
            xlabel(app.UIAxesOriginal, '');
            ylabel(app.UIAxesOriginal, '');
            if app.ipChecked 
                if strcmp(app.pointColor, 'Red')
                    app.plotPoints = plot(app.UIAxesOriginal,app.intersectionTable(:,1), ...
                        app.intersectionTable(:,2),'r.','MarkerSize',app.pointSize, ...
                        'Marker',app.pointShape,'LineWidth',2);
                elseif strcmp(app.pointColor, 'Yellow')
                    app.plotPoints = plot(app.UIAxesOriginal,app.intersectionTable(:,1), ...
                        app.intersectionTable(:,2),'y.','MarkerSize',app.pointSize, ...
                        'Marker',app.pointShape,'LineWidth',2);
                elseif strcmp(app.pointColor, 'Blue')
                    app.plotPoints = plot(app.UIAxesOriginal,app.intersectionTable(:,1), ...
                        app.intersectionTable(:,2),'b.','MarkerSize',app.pointSize, ...
                        'Marker',app.pointShape,'LineWidth',2);
                end
            end
            if app.indexChecked
                index = string(app.intersectionTable(:,3));
                x = app.intersectionTable(:,1);
                y = app.intersectionTable(:,2);
                app.indexShow = text(app.UIAxesOriginal,x,y,index,'Color','white', ...
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
            dataSaved = app.filenameSave;
            fData = fullfile(app.filepathSave, dataSaved);
            data = app.data1;
            data.intersectionCalculation = app.ipCalculation;
            save(fData,'data','-append')
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
            % app.intersectionTable = app.ogData;
            % RefreshButtonPushed(app, event)
            % operation.name = 'Reset';
            % operation.data = [];
            % app.ipCalculation.operation = [app.ipCalculation.operation; ...
            %        operation];
            intersectionGUI
%            delete(app)
%            RefreshButtonPushed(app, event)
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
 
                if app.TabGroup.SelectedTab == app.OriginalTab
                    selectedAxes =   app.UIAxesOriginal;
                elseif app.TabGroup.SelectedTab == app.OverlayTab
                    selectedAxes =   app.UIAxesOver;
                elseif app.TabGroup.SelectedTab == app.CenterLineTab
                    selectedAxes = app.UIAxesRidge;
                end
                hold(selectedAxes,'on')
                if strcmp(app.pointColor, 'Red')
                        app.plotPoints = plot(selectedAxes,app.intersectionTable(:,1), ...
                            app.intersectionTable(:,2),'r.','MarkerSize',app.pointSize, ...
                            'Marker',app.pointShape,'LineWidth',2);
                elseif strcmp(app.pointColor, 'Yellow')
                        app.plotPoints = plot(selectedAxes,app.intersectionTable(:,1), ...
                            app.intersectionTable(:,2),'y.','MarkerSize',app.pointSize, ...
                            'Marker',app.pointShape,'LineWidth',2);
                elseif strcmp(app.pointColor, 'Blue')
                        app.plotPoints = plot(selectedAxes,app.intersectionTable(:,1), ...
                            app.intersectionTable(:,2),'b.','MarkerSize',app.pointSize, ...
                            'Marker',app.pointShape,'LineWidth',2);
                end
                hold(selectedAxes,'off')
                drawnow
               
            else
                delete(app.plotPoints)
            end
        end

        % Value changed function: ShowIndexCheckBox
        function ShowIndexCheckBoxValueChanged(app, event)
            app.indexChecked = app.ShowIndexCheckBox.Value;

            if app.indexChecked
                % if app.selectedTab == 1
                %     selectedAxes =   app.UIAxesOriginal;
                % elseif app.selectedTab == 2
                %     selectedAxes =   app.UIAxesOver;
                % elseif app.selectedTab == 3
                %     selectedAxes =   app.UIAxesRidge;
                % end
                if app.TabGroup.SelectedTab == app.OriginalTab
                    selectedAxes =   app.UIAxesOriginal;
                elseif app.TabGroup.SelectedTab == app.OverlayTab
                    selectedAxes =   app.UIAxesOver;
                elseif app.TabGroup.SelectedTab == app.CenterLineTab
                    selectedAxes = app.UIAxesRidge;
                end
                index = string(app.intersectionTable(:,3));
                x = app.intersectionTable(:,1);
                y = app.intersectionTable(:,2);
                app.indexShow = text(selectedAxes,x,y,index,'Color','white', ...
                    'BackgroundColor','black','FontSize',12,"FontWeight","bold");
            else
                delete(app.indexShow)
            end
        end

        % Button pushed function: SelectImageButton
        function SelectImageButtonPushed(app, event)
            [filename,filepath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.png';'*.*'}, ...
                'Select an image file',app.lastPATHname);
            drawnow;
           if filename == 0
               disp('NO image file is selected.  Select an image file to proceed')
               return
           else
               app.lastPATHname = filepath;
           end
            % figure(app.FiberIntersectionPointDetectionUIFigure)
            app.TabGroup.SelectedTab = app.OriginalTab;
            app.selectedTab = 1;
            fullname = [filepath, filename];
            ImageFile = imread(fullname);
            app.image = ImageFile;
            % imshow(ImageFile, 'parent', app.UIAxesOriginal, 'InitialMagnification','fit');
            % hold(app.UIAxesOriginal, 'on')
            % title(app.UIAxesOriginal, 'fiber results');
            % xlabel(app.UIAxesOriginal, '');
            % ylabel(app.UIAxesOriginal, '');
            app.sizeImg = size(app.image);
            imgHeight = app.sizeImg(1); 
            imgWidth = app.sizeImg(2);
            app.TextArea.Value = filename;
            % show original image in the "Original" Tab
            % app.UIAxesOriginal.NextPlot = 'replace';
            imshow(app.image, 'parent', app.UIAxesOriginal, 'InitialMagnification','fit');
            hold(app.UIAxesOriginal, 'on')
            title(app.UIAxesOriginal, sprintf('%s', filename));
            % xlabel(app.UIAxesOriginal, '');
            % ylabel(app.UIAxesOriginal, '');
            axis(app.UIAxesOriginal,'equal')
            xlim(app.UIAxesOriginal,[1 imgWidth])
            ylim(app.UIAxesOriginal, [1 imgHeight])
          
            % import CT-FIRE output data file
            dataFilename = "ctFIREout_" + filename;
            [~,dataFilename,~] = fileparts(dataFilename);
            dataFilename = dataFilename + ".mat";
            dataPath = filepath + "ctFIREout/";
            CTFdata = load(fullfile(dataPath,dataFilename));
            %show centerlines overlaid over the original image in the
            %"Overlay" Tab
            %show center line or ridge in the"CenterLine" Tab
            imshow(app.image, 'parent', app.UIAxesOver, 'InitialMagnification','fit');
            imshow(zeros(imgHeight,imgWidth), 'parent', app.UIAxesRidge, 'InitialMagnification','fit');
            hold(app.UIAxesOver, 'on')
            hold(app.UIAxesRidge, 'on')
            LL1 = CTFdata.cP.LL1; % 
            FN = find(CTFdata.data.M.L > LL1);
            FLout = CTFdata.data.M.L(FN);
            % disp(FLout);
            LFa = length(FN);
            trim.FN = FN;
            trim.FLout = FLout;
            trim.LFa = LFa;
            CTFdata.data.trim = trim;
            rng(1001);
            clrr1 = rand(LFa,3); % set random color
            for LL = 1:LFa
                VFa.LL = CTFdata.data.Fa(1,FN(LL)).v;
                XFa.LL = CTFdata.data.Xa(VFa.LL,:);
                plot(app.UIAxesOver,XFa.LL(:,1),XFa.LL(:,2), '-','color',clrr1(LL,1:3),'linewidth',1);
                plot(app.UIAxesRidge,XFa.LL(:,1),XFa.LL(:,2), '-','color',clrr1(LL,1:3),'linewidth',0.25);
            end 
            axis(app.UIAxesOver,'equal')
            xlim(app.UIAxesOver,[1 imgWidth])
            ylim(app.UIAxesOver, [1 imgHeight])
            axis(app.UIAxesRidge,'equal')
            xlim(app.UIAxesRidge,[1 imgWidth])
            ylim(app.UIAxesRidge, [1 imgHeight])

            hold(app.UIAxesOver, 'off')
            hold(app.UIAxesRidge,'off')
            axis(app.UIAxesRidge,'image')
            app.TabGroup.SelectedTab = app.OverlayTab;
            app.selectedTab = 2;
            drawnow
            set(app.SelectDataButton,'enable','on');
            app.imageNameSave = filename;
            if contains(filename, 'OL_')
                dataFilename = erase(filename, 'OL_');
                dataFilename = "ctFIREout_" + dataFilename;
                [~,dataFilename,~] = fileparts(dataFilename);
                dataFilename = dataFilename + ".mat";
                dataPath = filepath;
            else
                dataFilename = "ctFIREout_" + filename;
                [~,dataFilename,~] = fileparts(dataFilename);
                dataFilename = dataFilename + ".mat";
                dataPath = filepath + "ctFIREout/";
            end
            drawnow;
            figure(app.FiberIntersectionPointDetectionUIFigure)
            dataFullname = dataPath + dataFilename;
            app.filenameSave = dataFilename;
            dataFile = CTFdata;%load(dataFullname);
            im3 = zeros(1, app.sizeImg(1), app.sizeImg(2));
            app.im3d = im3;
            app.ipCalculation.operation = [];
            if exist('dataFile.data.intersectionCalculation', 'var')
                IP = dataFile.data.intersectionCalculation.IP;
                app.ipCalculation.operation = dataFile.data.intersectionCalculation.operation;
                switch dataFile.data.intersectionCalculation.operation(1,2)
                    case 'Junction by interpolation'
                        app.CalculationmethodsDropDown.Value = 'Interpolation';
                    case 'Junction by regular'
                        app.CalculationmethodsDropDown.Value = 'Regular';
                    case 'Nucleation'
                        app.CalculationmethodsDropDown.Value = 'Nucleation';
                end
            else
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
                        operation.name = 'Method';
                        operation.data = 'Junction by interpolation';
                    case 'Junction by regular'
                        for i = 1:dataFile.data.trim.LFa
                            Fa(i) = dataFile.data.Fa(dataFile.data.trim.FN(i));
                        end
                        IP = lineIntersection(dataFile.data.Xa, im3, Fa);
                        app.CalculationmethodsDropDown.Value = 'Regular';
                        operation.name = 'Method';
                        operation.data = 'Junction by regular';
                    case 'Nucleation'
                        IP = intersection(dataFile.data.Xa, dataFile.data.Fa);
                        % IP1 = dataFile.data.xlink;
                        % figure('Position',[100 200 max(IP(:,1)) max(IP(:,2))],'Name','IP point comparison');
                        % imshow(app.image)
                        % hold on
                        % plot(IP(:,1),IP(:,2),'r.')
                        %  plot(IP1(:,1),IP1(:,2),'bo')
                        %  hold off
                        %  pause
                        app.CalculationmethodsDropDown.Value = 'Nucleation';
                        operation.name = 'Method';
                        operation.data = 'Nucleation';
                end
            end
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                operation];
            app.intersectionTable = [];
            for i = 1:length(IP)
                app.intersectionTable = [app.intersectionTable; IP(i,1) IP(i,2) i];
                app.ogData = [app.intersectionTable; IP(i,1) IP(i,2) i];
            end
            C = num2cell(app.intersectionTable);
            tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
            app.UITable.Data = tdata;
            app.TextArea_2.Value = dataFilename;
            app.ShowIntersectionCheckBox.Value = 1;
            app.ShowIntersectionCheckBoxValueChanged; % show the indexCheckBox
            % app.ipChecked = app.ShowIntersectionCheckBox.Value;
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
            app.filepathSave = dataPath;
            app.data1 = dataFile.data;
        end

        % Button pushed function: SelectDataButton
        function SelectDataButtonPushed(app, event)
            try
                [filename,filepath] = uigetfile('*.mat', 'Select a data file', app.lastPATHname);
                if filename == 0
                    disp('NO data file is selected.  Select a data file to proceed')
                    return
                else
                    app.lastPATHname = filepath;
                end
                drawnow;
                figure(app.FiberIntersectionPointDetectionUIFigure)
                fullname = [filepath, filename];
                app.filenameSave = filename;
                dataFile = load(fullname);
                im3 = zeros(1, app.sizeImg(1), app.sizeImg(2));
                app.im3d = im3;
                % for i = 1:dataFile.data.trim.LFa
                %     Fai(i) = dataFile.data.Fai(dataFile.data.trim.FN(i));
                % end
                % IP = lineIntersection(dataFile.data.Xai, im3, Fai);
                app.ipCalculation.operation = [];
                if exist('dataFile.data.intersectionCalculation', 'var')
                    IP = dataFile.data.intersectionCalculation.IP;
                    app.ipCalculation.operation = dataFile.data.intersectionCalculation.operation;
                    switch dataFile.data.intersectionCalculation.operation(1,2)
                        case 'Junction by interpolation'
                            app.CalculationmethodsDropDown.Value = 'Interpolation';
                        case 'Junction by regular'
                            app.CalculationmethodsDropDown.Value = 'Regular';
                        case 'Nucleation'
                            app.CalculationmethodsDropDown.Value = 'Nucleation';
                    end
                else
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
                            operation.name = 'Method';
                            operation.data = 'Junction by interpolation';
                        case 'Junction by regular'
                            for i = 1:dataFile.data.trim.LFa
                                Fa(i) = dataFile.data.Fa(dataFile.data.trim.FN(i));
                            end
                            IP = lineIntersection(dataFile.data.Xa, im3, Fa);
                            app.CalculationmethodsDropDown.Value = 'Regular';
                            operation.name = 'Method';
                            operation.data = 'Junction by regular';
                        case 'Nucleation'
                            IP = intersection(dataFile.data.Xa, dataFile.data.Fa);
                            app.CalculationmethodsDropDown.Value = 'Nucleation';
                            operation.name = 'Method';
                            operation.data = 'Nucleation';
                    end
                end
                app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
                for i = 1:length(IP)
                    app.intersectionTable = [app.intersectionTable; IP(i,1) IP(i,2) i];
                    app.ogData = [app.intersectionTable; IP(i,1) IP(i,2) i];
                end
                C = num2cell(app.intersectionTable);
                tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
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

        % Close request function: FiberIntersectionPointDetectionUIFigure
        function FiberIntersectionPointDetectionUIFigureCloseRequest(app, event)
            delete(app)
        end

        % Button pushed function: PropertiesButton
        function PropertiesButtonPushed(app, event)
            app.propertyWindow = intersectionProperties(app, app.pointColor, ...
                app.pointSelectedColor, app.pointSize, app.pointSelectedSize, ...
                app.pointShape, app.pointSelectedShape);
        end

        % Value changed function: CalculationmethodsDropDown
        function CalculationmethodsDropDownValueChanged(app, event)
            method = app.CalculationmethodsDropDown.Value;
            app.ipCalculation.operation = [];
            switch method
                case '-Selected'
                case 'Interpolation'
                    for i = 1:app.data1.trim.LFa
                        Fai(i) = app.data1.Fai(app.data1.trim.FN(i));
                    end
                    IP = lineIntersection(app.data1.Xai, app.im3d, Fai);
                    operation.name = 'Method';
                    operation.data = 'Junction by interpolation';
                case 'Regular'
                    for i = 1:app.data1.trim.LFa
                        Fa(i) = app.data1.Fa(app.data1.trim.FN(i));
                    end
                    IP = lineIntersection(app.data1.Xa, app.im3d, Fa);
                    operation.name = 'Method';
                    operation.data = 'Junction by regular';
                case 'Nucleation'
                    IP = intersection(app.data1.Xa,app.data1.Fa);
                    operation.name = 'Method';
                    operation.data = 'Nucleation';
            end
            app.ipCalculation.operation = [app.ipCalculation.operation; ...
                   operation];
            app.intersectionTable = [];
            for i = 1:length(IP)
                app.intersectionTable = [app.intersectionTable; IP(i,1) IP(i,2) i];
                app.ogData = [app.intersectionTable; IP(i,1) IP(i,2) i];
            end
            C = num2cell(app.intersectionTable);
            tdata = cell2table(C,'VariableNames',{'X', 'Y', 'Index'});
            app.UITable.Data = tdata;
            if app.ipChecked 
                if strcmp(app.pointColor, 'Red')
                    app.plotPoints = plot(app.UIAxesOriginal,app.intersectionTable(:,1), ...
                        app.intersectionTable(:,2),'r.','MarkerSize',app.pointSize, ...
                        'Marker',app.pointShape,'LineWidth',2);
                elseif strcmp(app.pointColor, 'Yellow')
                    app.plotPoints = plot(app.UIAxesOriginal,app.intersectionTable(:,1), ...
                        app.intersectionTable(:,2),'y.','MarkerSize',app.pointSize, ...
                        'Marker',app.pointShape,'LineWidth',2);
                elseif strcmp(app.pointColor, 'Blue')
                    app.plotPoints = plot(app.UIAxesOriginal,app.intersectionTable(:,1), ...
                        app.intersectionTable(:,2),'b.','MarkerSize',app.pointSize, ...
                        'Marker',app.pointShape,'LineWidth',2);
                end
            end
            if app.indexChecked
                index = string(app.intersectionTable(:,3));
                x = app.intersectionTable(:,1);
                y = app.intersectionTable(:,2);
                app.indexShow = text(app.UIAxesOriginal,x,y,index,'Color','white', ...
                    'BackgroundColor','black','FontSize',12,"FontWeight","bold");
            end
        end

        % Button down function: OriginalTab
        function OriginalTabButtonDown(app, event)
            if app.ShowIntersectionCheckBox.Value == 1
                delete(app.plotPoints)
                app.ShowIntersectionCheckBoxValueChanged; % show the indexCheckBox
            end

        end

        % Button down function: OverlayTab
        function OverlayTabButtonDown(app, event)
            if app.ShowIntersectionCheckBox.Value == 1
                delete(app.plotPoints)
                app.ShowIntersectionCheckBoxValueChanged; % show the indexCheckBox
            end

        end

        % Button down function: CenterLineTab
        function CenterLineTabButtonDown(app, event)
            if app.ShowIntersectionCheckBox.Value == 1
                delete(app.plotPoints)
                app.ShowIntersectionCheckBoxValueChanged; % show the indexCheckBox
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create FiberIntersectionPointDetectionUIFigure and hide until all components are created
            app.FiberIntersectionPointDetectionUIFigure = uifigure('Visible', 'off');
            app.FiberIntersectionPointDetectionUIFigure.AutoResizeChildren = 'off';
            app.FiberIntersectionPointDetectionUIFigure.Position = [100 100 900 600];
            app.FiberIntersectionPointDetectionUIFigure.Name = 'Fiber Intersection Point Detection';
            app.FiberIntersectionPointDetectionUIFigure.Resize = 'off';
            app.FiberIntersectionPointDetectionUIFigure.CloseRequestFcn = createCallbackFcn(app, @FiberIntersectionPointDetectionUIFigureCloseRequest, true);
            app.FiberIntersectionPointDetectionUIFigure.Scrollable = 'on';
            app.FiberIntersectionPointDetectionUIFigure.Tag = 'IP detection main GUI';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.FiberIntersectionPointDetectionUIFigure);
            app.GridLayout.ColumnWidth = {600, 150, 119, 0};
            app.GridLayout.RowHeight = {22, 60, 22, 60, '0x', 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 0};
            app.GridLayout.ColumnSpacing = 5.6;
            app.GridLayout.RowSpacing = 6.68421052631579;
            app.GridLayout.Padding = [5.6 6.68421052631579 5.6 6.68421052631579];
            app.GridLayout.Scrollable = 'on';

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {'X'; 'Y'; 'Index'};
            app.UITable.ColumnWidth = {45, 45, 60};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.ColumnEditable = true;
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Layout.Row = [1 20];
            app.UITable.Layout.Column = 2;

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

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.Layout.Row = [1 20];
            app.TabGroup.Layout.Column = 1;

            % Create OriginalTab
            app.OriginalTab = uitab(app.TabGroup);
            app.OriginalTab.AutoResizeChildren = 'off';
            app.OriginalTab.Title = 'Original';
            app.OriginalTab.ButtonDownFcn = createCallbackFcn(app, @OriginalTabButtonDown, true);

            % Create UIAxesOriginal
            app.UIAxesOriginal = uiaxes(app.OriginalTab);
            title(app.UIAxesOriginal, 'Original Image')
            app.UIAxesOriginal.PlotBoxAspectRatio = [1 1 1];
            app.UIAxesOriginal.Position = [1 1 600 550];

            % Create OverlayTab
            app.OverlayTab = uitab(app.TabGroup);
            app.OverlayTab.AutoResizeChildren = 'off';
            app.OverlayTab.Title = 'Overlay';
            app.OverlayTab.ButtonDownFcn = createCallbackFcn(app, @OverlayTabButtonDown, true);

            % Create UIAxesOver
            app.UIAxesOver = uiaxes(app.OverlayTab);
            title(app.UIAxesOver, 'Overlay')
            zlabel(app.UIAxesOver, 'Z')
            app.UIAxesOver.PlotBoxAspectRatio = [1 1 1];
            app.UIAxesOver.Position = [1 1 600 550];

            % Create CenterLineTab
            app.CenterLineTab = uitab(app.TabGroup);
            app.CenterLineTab.AutoResizeChildren = 'off';
            app.CenterLineTab.Title = 'CenterLine';
            app.CenterLineTab.ButtonDownFcn = createCallbackFcn(app, @CenterLineTabButtonDown, true);

            % Create UIAxesRidge
            app.UIAxesRidge = uiaxes(app.CenterLineTab);
            title(app.UIAxesRidge, 'Ridge')
            zlabel(app.UIAxesRidge, 'Z')
            app.UIAxesRidge.PlotBoxAspectRatio = [1 1 1];
            app.UIAxesRidge.Position = [1 1 600 550];

            % Show the figure after all components are created
            app.FiberIntersectionPointDetectionUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = intersectionGUI_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.FiberIntersectionPointDetectionUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.FiberIntersectionPointDetectionUIFigure)
        end
    end
end