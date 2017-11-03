
function [] = CAroi(CApathname,CAfilename,CAdatacurrent,CAcontrol)
        % Input:
        %CAcontrol: structue to control the display and parameters
        % CAcontrol.imgAx: axis to the output image
        % CAcontrol.idx: the idxTH slice of a stack
        % CAcontrol.plotrgbFLAG: for  ROI definition/management of color image

        % CAroi is based on the roi_gui_v3(renamed as CTFroi) function previously designed for CT-FIRE ROI analysis
        % ROI module project started in December 2014 as part of the LOCI collagen quantification tool development efforts.

        % Log:
        % 1. December 2014 to May 2015: two undergraduate students from India Institute of Technology at Jodhpur, Guneet S. Mehta and Prashant Mittal
        % supervised and mentored by both LOCI and IITJ, took the development of CT-FIRE ROI module as a part of their Bachelor of Technology Project.
        % Guneet S. Mehta was responsible for implementing the code and Prashant Mittal for testing and debugging.
        % 2. May 2015:  Prashant Mittal quit the project after he graduated.
        % 3. May 2015-August 2015: Guneet S. Mehta continuously works on the improvement of the CT-FIRE ROI module.
        % 4. On August 13th, Guneet S. Mehta started as a graduate research assistant at UW-LOCI, working with Yuming Liu toward finalizing the CT-FIRE ROI module
        %  as well as adapting it for CurveAlign ROI analysis.
        % 5. On August 23rd 2015, Yuming Liu started adapting the CT-FIRE ROI module for CurveAlign analysis

        if nargin == 0
            load('CAroicurrent.mat','rolCApathname','CAfilename','CAroi_datacurrent','CAcontrol');
            disp('Reset the ROI Mananger.');
        end
        setupFunction;
        pseudo_address = '';               % default path
        IMGdata = [];                      % original image data
        % CA output features of the whole image
        filename = CAfilename;pathname = CApathname;fibFeat = [];
        CAoutmatName = '';                  % mat file name in "CA_Out" folder
        separate_rois=[];                   %Stores all ROIs of the image for access
        finalize_rois = [];                 % flag to finalize roi shape selection
        roi = [];                           % roi edge coordinates
        roi_shape = 1;                      % shape of ROI. 0: no shape; 1: rectangle; 2: freestyle; 3: elipse; 4: polygon
        h = [];                             % handle to an ROI object
        cell_selection_data = [];      % selected ROI nx2 [row col]
        ROI_text=cell(0,2);
        xmid = nan; ymid = nan;             % ROI center x,y coordinates
        gmask = [];                         % mask that exists across differenct functions
        load_tableflag = 0;                 % 1: load ROI table from previous analysis results
        plotrgbFLAG = CAcontrol.plotrgbFLAG;                                % flag for displaying RGB image
        specifyROIpos = ones(1,4);
        specifyROIpos(1,3:4) = CAcontrol.specifyROIsize;                          % default Size of the 'specify' ROI - taken as input from calling function - CurveAlign
        loadROIFLAG = CAcontrol.loadROIFLAG;                                % ??
        guiFig_absPOS = CAcontrol.guiFig_absPOS;                            %stores the position of calling function CurveAlign's GUI
        measure_fig = -1;                   % initialize the figure containing the summary statistics table
        SSize = get(0,'screensize');SW2 = SSize(3); SH = SSize(4);

        [~,filenameNE,fileEXT] = fileparts(filename);
        %YL: Output files and Directories -start
        %folders for CA ROI analysis on defined ROI(s) of individual image
        ROIanaIndDir = fullfile(pathname,'CA_ROI','Individual','ROI_analysis');
        ROIanaIndOutDir = fullfile(ROIanaIndDir,'CA_Out');
        if loadROIFLAG == 0
            ROImanDir = fullfile(pathname,'ROI_management');
            roiMATname = sprintf('%s_ROIs.mat',filenameNE);
        elseif loadROIFLAG == 1
            ROImanDir = CAcontrol.folderROIman;
            roiMATname = CAcontrol.roiMATnamefull;
            CAroi_data_current = [];
        end
        % folders for CA post ROI analysis of individual image
        ROIpostIndDir = fullfile(pathname,'CA_ROI','Individual','ROI_post_analysis');
        ROIDir = fullfile(pathname,'CA_ROI');
        %YL: Output files and Directories -end
        IMGname = fullfile(pathname,filename);                          %stores the fullfile name of the image being used
        IMGinfo = imfinfo(IMGname);                                     %stores image information like - extension, name etc
        numSections = numel(IMGinfo);                                   % number of sections of the image- 1 for normal images, n for stack containing n slices
        cropIMGon = 1;                                                  % Flag for usage of ROIs  1: use cropped image for analysis;  0: apply the ROI mask to the original image then do analysis
        ROIshapes = {'Rectangle','Freehand','Ellipse','Polygon'};       %Defines all possible ROI shapes that can be drawn
        SSize = get(0,'screensize');SW = SSize(3); SH = SSize(4);       %SW - width of screen, SH - Height of screen
        defaultBackground = get(0,'defaultUicontrolBackgroundColor');   %storing default background

        roi_mang_fig = findobj(0,'Tag','ROI Mananger List-CA');
        if isempty(roi_mang_fig)
            roi_mang_fig = figure('Resize','on','Color',defaultBackground,'Units','pixels',...
                'Position',[0.052*SW 0.09*SH round(0.2*SW) round(SH*0.8)],'Visible','on','MenuBar','none',...
                'name','ROI Manager','NumberTitle','off','UserData',0,'Tag','ROI Mananger List-CA');
        else
            figure(roi_mang_fig)
        end
%         set(roi_mang_fig,'KeyPressFcn',@roi_mang_keypress_fn);              %Assigning the function that is called when any key is pressed while roi_mang_fig is active
        relative_horz_displacement=20;                                      % Horz dist of ROI analysis figure from ROI Manager figure
        fig_temp = findobj(0,'Tag','ROI Manager Figure-CA');
        if ~isempty(fig_temp)
            close(fig_temp)
        end
        image_fig=figure('Resize','on','Units','pixels','position',guiFig_absPOS,...
            'name',sprintf('CurveAlign ROI:%s',filename),'MenuBar','figure',...
            'NumberTitle','off','visible', 'off','Tag','ROI Manager Figure-CA');
        %  add overAx axis object for the overlaid image
        set(image_fig,'KeyPressFcn',@roi_mang_keypress_fn);              %Assigning the function that is called when any key is pressed while roi_mang_fig is active

        overPanel = uipanel('Parent', image_fig,'Units','normalized','Position',[0 0 1 1]);
        overAx= axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);
        BWv = {};                                                           % cell to save the selected ROIs
        backup_fig=figure;set(backup_fig,'Visible','off');
        % roi_mang_fig - roi manager figure setup - ends

        %opening previous file location - using lastPATH_CAroi.mat file
        openDefaultFileLocationFn;

        %defining buttons of ROI manager - starts
        roi_table=uitable('Parent',roi_mang_fig,'Units','normalized','Position',[0.05 0.05 0.45 0.9],'Tag','ROI_list','CellSelectionCallback',@cell_selection_fn);
        reset_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.75 0.96 0.2 0.03],'String','Reset','Callback',@reset_fn,'TooltipString','Press to Reset');
        filename_box=uicontrol('Parent',roi_mang_fig,'Style','text','String','filename','Units','normalized','Position',[0.05 0.955 0.45 0.04],'BackgroundColor',[1 1 1]);
        load_image_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.9 0.4 0.035],'String','Open File','Callback',@load_image,'TooltipString','Open Image','Visible', 'on');
        roi_shape_choice_text=uicontrol('Parent',roi_mang_fig,'Style','text','string','Draw ROI Menu (d)','Units','normalized','Position',[0.55 0.86 0.4 0.035]);
        roi_shape_choice=uicontrol('Parent',roi_mang_fig,'Enable','off','Style','popupmenu','string',{'New ROI?','Rectangle','Freehand','Ellipse','Polygon','Specify...'},'Units','normalized','Position',[0.55 0.82 0.4 0.035],'Callback',@roi_shape_choice_fn);
        save_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.78 0.4 0.035],'String','Save ROI (s)','Enable','on','Callback',@save_roi);
        combine_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.74 0.4 0.035],'String','Combine ROIs','Enable','on','Callback',@combine_rois,'Enable','off','TooltipString','Combine 2 or more ROIs');
        rename_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.7 0.4 0.035],'String','Rename ROI','Callback',@rename_roi);
        delete_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.66 0.4 0.035],'String','Delete ROI','Callback',@delete_roi);
        measure_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.62 0.4 0.035],'String','Measure ROI','Callback',@measure_roi,'TooltipString','Displays ROI Properties');
        load_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.58 0.4 0.035],'String','Load ROI from Text','TooltipString','Loads ROI coordinates from CSV file','Enable','on','Callback',@load_roi_fn);
        load_roi_from_mask_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.54 0.4 0.035],'String','Load ROI from Mask','Callback',@mask_to_roi_fn,'Enable','on');
        save_roi_text_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.50 0.4 0.035],'String','Save ROI Text','Callback',@save_text_roi_fn,'Enable','off');
        save_roi_mask_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.46 0.4 0.035],'String','Save ROI Mask','Callback',@save_mask_roi_fn,'Enable','off');
        analyzer_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.42 0.4 0.035],'String','CA ROI Analyzer','Callback',@analyzer_launch_fn,'Enable','off','TooltipString','ROI analysis for previous CA features of the whole image');
        CA_to_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.38 0.4 0.035],'String','Apply CA on ROI','Callback',@CA_to_roi_fn,'Enable','off','TooltipString','Apply CurveAlign on the selected ROI');
        shift_disp=-0.10;    %used for relative positions of subsequent buttons
        index_box=uicontrol('Parent',roi_mang_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.364+shift_disp 0.08 0.025],'Callback',@index_fn);
        index_text=uicontrol('Parent',roi_mang_fig,'Style','Text','Units','normalized','Position',[0.631 0.36+shift_disp 0.16 0.025],'String','Labels');
        showall_box=uicontrol('Parent',roi_mang_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.394+shift_disp 0.08 0.025],'Callback',@showall_rois_fn);
        showall_text=uicontrol('Parent',roi_mang_fig,'Style','Text','Units','normalized','Position',[0.631 0.39+shift_disp 0.16 0.025],'String','Show All');
        status_title=uicontrol('Parent',roi_mang_fig,'Style','text','Fontsize',9,'Units','normalized','Position',[0.585 0.305+shift_disp 0.4 0.045],'String','Message Window');
        status_message=uicontrol('Parent',roi_mang_fig,'Style','text','Fontsize',10,'Units','normalized','Position',[0.515 0.05 0.485 0.265+shift_disp],'String','Click "Open File" and select a file','BackgroundColor','g');
        set([rename_roi_box,measure_roi_box],'Enable','off');        % setting intital confugaration
        % YL: add CA output table. Column names and column format
        columnname = {'No.','Image Label','ROI Label','Orentation','Alignment','FeatNum','Methods','Boundary','CROP','POST','Shape','Xc','Yc','Z'};
        columnformat = {'numeric','char','char','char','char' ,'char','char','char','char','char','char','numeric','numeric','numeric'};
        columnwidth = {30 100 60 70 70 60 60 60 40 40 60 30 30 30 };   %
        %defining buttons of ROI manager - ends
        if isempty (CAdatacurrent)
            if exist(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.mat',filenameNE)),'file')
                ROItableChoice = questdlg('Load previous ROI analysis output table?', ...
                    'Loading ROI output table','YES','NO','NO');
                if isempty(ROItableChoice)
                    ROItableChoice = 'NO';  % default is not to load the previous analysis
                end
                switch ROItableChoice
                    case 'YES'
                        load_tableflag = 1;
                        load(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.mat',filenameNE)),'CAroi_data_current','separate_rois')
                        disp('Previous ROI analysis results were loaded.')
                    case 'NO'
                        CAroi_data_current = [];
                        disp('Previous ROI analysis results were not loaded.');
                end
            else
                CAroi_data_current = [];
            end
        else
            CAroi_data_current = CAdatacurrent;
        end

        %setting up CAroi_table_fig -starts
        selectedROWs = [];                 % Selected rows in CA output uitable
        CAroi_table_fig = figure(242);clf  % Create the CA output uitable
        figPOS = [0.665 0.65 0.325 0.325];  %
        figPOS2 = [0.665 0.10 0.455*SH/SW2 0.455];  % figure position of roi histgram
        set(CAroi_table_fig,'Units','normalized','Position',figPOS,'Visible','on',...
            'MenuBar','None','NumberTitle','off','name','CurveAlign ROI Analysis Output Table');
        CAroi_output_table = uitable('Parent',CAroi_table_fig,'Units','normalized',...
            'Position',[0.05 0.05 0.9 0.9],'Data', CAroi_data_current,'ColumnName', columnname,...
            'ColumnFormat', columnformat,'ColumnWidth',columnwidth,...
            'ColumnEditable', [false false false false false false false false false false false false false false],...
            'RowName',[],'CellSelectionCallback',{@CAot_CellSelectionCallback});
        %Save and Delete button in CAroi_table_fig
        DeleteROIout=uicontrol('Parent',CAroi_table_fig,'Style','Pushbutton','Units','normalized','Position',[0.9 0.01 0.08 0.08],'String','Delete','Callback',@DeleteROIout_Callback);
        SaveROIout=uicontrol('Parent',CAroi_table_fig,'Style','Pushbutton','Units','normalized','Position',[0.80 0.01 0.08 0.08],'String','Save All','Callback',@SaveROIout_Callback);
        %setting up CAroi_table_fig -ends
        %YL - loads the image specified
        [filename] = load_CAimage(filename,pathname);
%-------------------------------------------------------------------------
%output table callback functions
    function openDefaultFileLocationFn()
        % opens last opened file location if any
        f1=fopen('lastPATH_CAroi.mat');
        if(f1<=0)               %if lastPATH_CAroi.mat is not present
            pseudo_address='';  %in this case the folder containing the CAroi.m script is used by default by MATLAB
        else
            pseudo_address = importdata('lastPATH_CAroi.mat');
            if(pseudo_address==0)
                pseudo_address = '';%if lastPATH_CAroi.mat file is present but does not contain an
                disp('Using default path to load file(s).');
            else
                disp(sprintf( 'Using saved path to load file(s). Current path is %s ',pseudo_address));
            end
        end
    end

    function CAot_CellSelectionCallback(hobject, eventdata,handles)
        %Function which is called whenever a ROI is selected on the window called
        %CurveAlign ROI analysis output table
        handles.currentCell=eventdata.Indices;
        selectedROWs = unique(handles.currentCell(:,1));
        selectedZ = CAroi_data_current(selectedROWs,14);
        if numSections > 1
            for j = 1:length(selectedZ)
                Zv(j) = selectedZ{j};
            end
            if size(unique(Zv)) == 1
                zc = unique(Zv);
            else
                disp('Only display ROIs in the same section of a stack.')
                return
            end
        else
            zc = 1;
        end
        if numSections == 1
            IMGO(:,:,1) = uint8(IMGdata(:,:,1));
            IMGO(:,:,2) = uint8(IMGdata(:,:,1));
            IMGO(:,:,3) = uint8(IMGdata(:,:,1));
            IMGtemp = imread(fullfile(CApathname,CAfilename));
        elseif numSections > 1
            IMGtemp = imread(fullfile(CApathname,CAfilename),zc);
            if size(IMGtemp,3) > 1
                if plotrgbFLAG == 0
                    IMGtemp = rgb2gray(IMGtemp);
                    disp('Color image was loaded but converted to grayscale image.')
                elseif plotrgbFLAG == 1
                    disp('Display Color Image');
                end
            end
            IMGO(:,:,1) = uint8(IMGtemp);
            IMGO(:,:,2) = uint8(IMGtemp);
            IMGO(:,:,3) = uint8(IMGtemp);
        end
        cropFLAG_selected = unique(CAroi_data_current(selectedROWs,9));
        if size(cropFLAG_selected,1)~=1
            disp('Please select ROIs processed with the same method.')
            return
        elseif size(cropFLAG_selected,1)==1
            cropFLAG = cropFLAG_selected;
        end
        postFLAG_selected = unique(CAroi_data_current(selectedROWs,10));
        if size(postFLAG_selected,1)~=1
            disp('Please select ROIs processed with the same method.')
            return
        elseif size(postFLAG_selected,1)==1
            postFLAG = postFLAG_selected;
        end
        if strcmp(cropFLAG,'YES')      %
            for i= 1:length(selectedROWs)
                CAroi_name_selected =  CAroi_data_current(selectedROWs(i),3);
                if numSections > 1
                    roiNamefullNE = [filename,sprintf('_s%d_',zc),CAroi_name_selected{1}];
                elseif numSections == 1
                    roiNamefullNE = [filename,'_', CAroi_name_selected{1}];
                end
                olName = fullfile(ROIanaIndOutDir,[roiNamefullNE '_overlay.tiff']);
                if exist(olName,'file')
                    IMGol = imread(olName);
                else
                    IMGol = zeros(size(IMGO));
                end
                if(separate_rois.(CAroi_name_selected{1}).shape==1)
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)]
                    data2=separate_rois.(CAroi_name_selected{1}).roi;
                    a= round(data2(1));b=round(data2(2));c=round(data2(3));d=round(data2(4));
                    IMGO(b:b+d-1,a:a+c-1,1) = IMGol(:,:,1);
                    IMGO(b:b+d-1,a:a+c-1,2) = IMGol(:,:,2);
                    IMGO(b:b+d-1,a:a+c-1,3) = IMGol(:,:,3);
                    xx(i) = a+c/2;  yy(i)= b+d/2; ROIind(i) = selectedROWs(i);
                    aa(i) = a; bb(i) = b;cc(i) = c; dd(i) = d;
                else
                    disp('Cropped image ROI analysis for shapes other than rectangles is not available so far.')
                    return
                end
            end
            figure(image_fig); imshow(IMGO); hold on;
            for i = 1:length(selectedROWs)
                text(xx(i),yy(i),sprintf('%d',ROIind(i)),'fontsize', 10,'color','m')
                rectangle('Position',[aa(i) bb(i) cc(i) dd(i)],'EdgeColor','m','linewidth',3)
            end
            hold off
        end

        if strcmp(cropFLAG,'NO')
            ii = 0; boundaryV = {};yy = []; xx = []; RV = [];
            for i= 1:length(selectedROWs)
                CAroi_name_selected =  CAroi_data_current(selectedROWs(i),3);
                if ~iscell(separate_rois.(CAroi_name_selected{1}).shape)
                    ii = ii + 1;
                    CAroi_name_selected =  CAroi_data_current(selectedROWs(i),3);
                    if numSections > 1
                        roiNamefullNE = [filename,sprintf('_s%d_',zc),CAroi_name_selected{1}];
                    elseif numSections == 1
                        roiNamefullNE = [filename,'_', CAroi_name_selected{1}];
                    end
%                     olName = fullfile(ROIanaIndOutDir,[roiNamefullNE '_overlay.tiff']);
%                     if exist(olName,'file')
%                         IMGol = imread(olName);
%                     else
%                         IMGol = zeros(size(IMGO));
%                     end
                    IMGol = [];
                    if strcmp(postFLAG,'NO')
                        olName = fullfile(ROIanaIndOutDir,[roiNamefullNE '_overlay.tiff']);
                        if exist(olName,'file')
                            IMGol = imread(olName);
                        end
                    else
                        olName = fullfile(pathname,'CA_Out',[filename '_overlay.tiff']);
                        if exist(olName,'file')
                            if numSections == 1
                                IMGol = imread(olName);
                            elseif numSections > 1
                                IMGol = imread(olName,zc);
                            end
                        end
                    end
                    if isempty(IMGol)
                        IMGol = zeros(size(IMGO));
                    end
                    data3 = separate_rois.(CAroi_name_selected{1}).enclosing_rect;
                    a = data3(1);  % x of upper left corner of the enclosing rectangle
                    b = data3(2);   % y of upper left corner of the enclosing rectangle
                    c = data3(3)-data3(1);  % width of the enclosing rectangle
                    d = data3(4) - data3(2);  % height of the enclosing rectangle
                    % replay the region of interest with the data in the
                    % ROI analysis output
                    boundary = separate_rois.(CAroi_name_selected{1}).boundary{1};
                    IMGO(b:b+d-1,a:a+c-1,1) = IMGol(b:b+d-1,a:a+c-1,1);
                    IMGO(b:b+d-1,a:a+c-1,2) = IMGol(b:b+d-1,a:a+c-1,2);
                    IMGO(b:b+d-1,a:a+c-1,3) = IMGol(b:b+d-1,a:a+c-1,3);
                    boundaryV{ii} = boundary;
                    yy(ii) = separate_rois.(CAroi_name_selected{1}).xm;
                    xx(ii) = separate_rois.(CAroi_name_selected{1}).ym;
                    RV(ii) = i;
                    ROIind(ii) = selectedROWs(i);
                else
                    disp('Selected ROI is a combined one and was not displayed.')
                end
            end
            figure(image_fig);imshow(IMGO); hold on;
            if ii > 0
                for ii = 1:length(selectedROWs)
                    text(xx(ii),yy(ii),sprintf('%d',ROIind(ii)),'fontsize', 10,'color','m')
                    boundary = boundaryV{ii};
                    plot(boundary(:,2), boundary(:,1), 'm', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                    text(xx(ii),yy(ii),sprintf('%d',selectedROWs(RV(ii))),'fontsize', 10,'color','m')
                end
            else
                disp('NO ROI analysis output was visulized.')
            end
            hold off
        end

    end

    function DeleteROIout_Callback(hobject,handles)
        %Function called when a ROI is deleted on the the window called
        %CurveAlign ROI analysis output table
        CAroi_data_current(selectedROWs,:) = [];
        if ~isempty(CAroi_data_current)
            for i = 1:length(CAroi_data_current(:,1))
                CAroi_data_current(i,1) = {i};
            end
        end
        set(CAroi_output_table,'Data',CAroi_data_current)
    end

    function SaveROIout_Callback(hobject,handles)
        %Function called when a ROI is saved on the the window called
        %CurveAlign ROI analysis output table
        if ~isempty(CAroi_data_current)
            %YL: may need to delete the existing files - Here the
            %ROIsCA.mat is appended while ROIsCA.xlsx is deleted and then
            %rewritten
            save(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.mat',filenameNE)),'CAroi_data_current','separate_rois') ;
            if exist(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.xlsx',filenameNE)),'file')
                delete(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.xlsx',filenameNE)));
            end
            try
                xlswrite(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.xlsx',filenameNE)),[columnname;CAroi_data_current],'CA ROI Alignment Analysis') ;
            catch
                xlwrite(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.xlsx',filenameNE)),[columnname;CAroi_data_current],'CA ROI Alignment Analysis') ;
            end
            disp(sprintf('Table output was saved in %s', fullfile(ROIDir,'Individual')))
        else
            %delete existing output file if data is empty
            if exist(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.mat',filenameNE)),'file')
                delete(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.mat',filenameNE)))
            end
            if exist(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.xlsx',filenameNE)),'file')
                delete(fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.xlsx',filenameNE)));
            end
            disp(sprintf('Output table is empty and previous output was deleted if it exists in %s', fullfile(ROIDir,'Individual')))
        end
    end
%end of output table callback functions

    function setupFunction()
       %Adds default paths for CurveLab functions that are needed
        if (~isdeployed)
            addpath('../CurveLab-2.1.2/fdct_wrapping_matlab');
            addpath(genpath(fullfile('../FIRE')));
            addpath('../20130227_xlwrite');
            addpath('.');
            addpath('../xlscol/');
        end
        warning('off','all');%removes all warnings that might come up on command window
    end

    function [filename] = load_CAimage(filename,pathname)
        set(status_message,'string','File is being opened. Please wait...');
        try
            message_CAOUTdata_present=0; % flag for presence of fiber features
            pseudo_address=pathname;
            save('lastPATH_CAroi.mat','pseudo_address');
            % Checking for directories
            if(exist(ROIpostIndDir,'dir')==0)
                mkdir(ROImanDir);mkdir(ROIpostIndDir);
            else
                if(exist(ROImanDir,'dir')==0),mkdir(ROImanDir); end
                if(exist(ROIpostIndDir,'dir')==0),mkdir(ROIpostIndDir); end
            end

            %Reading images
            if numSections == 1
                IMGdata=imread(fullfile(pathname,filename));
            elseif numSections > 1
                IMGdata=imread(fullfile(pathname,filename), CAcontrol.idx);
            end

            %Resolving RGB or grayscale image and displaying
            if(size(IMGdata,3)==3)
                if plotrgbFLAG == 0
                    disp('Color image was loaded but converted to grayscale image.')
                    IMGdata_copy = rgb2gray(IMGdata);
                    IMGdata(:,:,1)=IMGdata_copy;IMGdata(:,:,2)=IMGdata_copy;IMGdata(:,:,3)=IMGdata_copy;
                elseif plotrgbFLAG == 1
                    disp('Display Color Image');
                end
            end
            figure(image_fig);imshow(IMGdata); hold on;

            set(filename_box,'String',filename);
            [~,filename] = fileparts(filename); %separating filename from full address
            if numSections == 1
                CAoutmatName = fullfile(pathname,'CA_Out',[filenameNE '_fibFeatures' '.mat']);
            elseif numSections > 1
                CAoutmatName = fullfile(pathname,'CA_Out',[filenameNE '_s' num2str(CAcontrol.idx) '_fibFeatures' '.mat']);
            end

            if exist(CAoutmatName,'file')%~=0 instead of ==1 because value is equal to 2
                set(analyzer_box,'Enable','on');
                message_CAOUTdata_present=1;
            end
            if(exist(fullfile(ROImanDir,roiMATname),'file')~=0)%if file is present . value ==2 if present
                if load_tableflag == 0 && isempty(separate_rois)
                    separate_rois=importdata(fullfile(ROImanDir,roiMATname));
                    message_rois_present=1;
                    disp(sprintf('ROI table was loaded from %s',fullfile(ROImanDir,roiMATname)))
                else
                    message_rois_present=1;
                    disp(sprintf('ROI table was loaded from %s',fullfile(ROIDir,'Individual',sprintf('%s_ROIsCA.mat',filenameNE))))
                end
            else
                separate_rois=[];
                save(fullfile(ROImanDir,roiMATname),'separate_rois');
            end
            if(isempty(separate_rois)==0)
                size_saved_operations=size(fieldnames(separate_rois),1);
                names=fieldnames(separate_rois);
                Data=cell(size(names));
                for i=1:size_saved_operations
                    Data{i,1}=names{i,1};
                end
                set(roi_table,'Data',Data);
            end

            if(message_rois_present==1&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROI(s) are present and CAroi data is present.');
            elseif(message_rois_present==1&&message_CAOUTdata_present==0)
                set(status_message,'String','Previously defined ROIs are present');
            elseif(message_rois_present==0&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROIs not present. CAroi data is present');
            end
            set(load_image_box,'Enable','off');
        catch
            set(status_message,'String','ROI managment/analysis for individual image.');
            set(load_image_box,'Enable','on');
        end
        % on loading image - disabling load image box and enabling roi
        % shape selection box
        set(load_image_box,'Enable','off');set(roi_shape_choice,'Enable','on');
    end

    function[]=roi_mang_keypress_fn(~,eventdata,~)
        % When s is pressed then roi is saved
        % when 'd' is pressed a new roi is drawn
        % x is to cancel the ROI drawn already on the figure
        if(eventdata.Key=='s')
            save_roi(0,0);
        elseif(eventdata.Key=='d')
            draw_roi_sub(0,0);
            set(save_roi_box,'Enable','on');%enabling save button after drawing ROI
        elseif(eventdata.Key=='x')
            if(~isempty(h)&&h~=0)
                delete(h);
                set(roi_shape_choice,'Value',1)
                set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            end
        end
    end

    function[]=draw_roi_sub(~,~)
        roi_shape=get(roi_shape_choice,'Value')-1;
        if(roi_shape == 0)
            if ~isempty(h)&&h~=0
                delete(h);
                set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            else
                set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            end
            disp('ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            return
        end
        count=1;%finding the ROI number
        fieldname=['ROI' num2str(count)];
        while(isfield(separate_rois,fieldname)==1)
            count=count+1;fieldname=['ROI' num2str(count)];
        end
        figure(image_fig);%image is gray scale image - dimensions =2

        rect_fixed_size=0;
        if(roi_shape==1)
            if(rect_fixed_size==0)% for resizeable Rectangular ROI
                h=imrect;
            elseif(rect_fixed_size==1)% fornon resizeable Rect ROI
                h = imrect(gca, [10 10 width height]);
                setResizable(h,0);
            end
            fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
        elseif(roi_shape==2)
            h=imfreehand;
            fcn = makeConstrainToRectFcn('imfreehand',get(gca,'XLim'),get(gca,'YLim'));
        elseif(roi_shape==3)
            h=imellipse;
            fcn = makeConstrainToRectFcn('imellipse',get(gca,'XLim'),get(gca,'YLim'));
        elseif(roi_shape==4)
            h=impoly;
            fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),get(gca,'YLim'));
        elseif(roi_shape==5)
            roi_shape=1;
            roi_shape_popup_window;
        end
        set(status_message,'string','Press "S" key to save ROI');
        if(roi_shape == 0 && roi_shape ~=5)
            setPositionConstraintFcn(h,fcn);
        end
    end

    function[]=reset_fn(object,handles)
%         close all;
%        save('CAroicurrent.mat','CApathname','CAfilename','CAdatacurrent','CAcontrol','-v7.3');
%        disp(sprintf('Current CAroi data was saved in %s',fullfile(pwd, 'CAroicurrent.mat')));
%        CAroi();
         clear BWv
    end

    function[]=load_image(object,handles)
%         Steps-
%         1 open the location of the last IMGdata
%         2 check for the folder ROI then ROI/ROI_management and ROI_analysis. If one of them is not present then make these directories
%         3 check whether IMGdataname_ROIs are present in the pathname/ROI/ROI_management
%         4 Skip -(read IMGdata - convert to RGB IMGdata . Reason - colored
%         fibres need to be overlaid. ) Try grayscale IMGdata first
%         5 if folders are present then check for the IMGdataname_ROIs.mat in ROI_management folder
%         5.5 define mask and boundary
%         6 if file is present then load the ROIs in roi_table of roi_mang_fig

        [filename,pathname,filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select image',pseudo_address,'MultiSelect','off');

        set(status_message,'string','File is being opened. Please wait....');
         try
             message_roi_present=1;message_CAOUTdata_present=0;
            pseudo_address=pathname;
            save('lastPATH_CAroi.mat','pseudo_address');
            if(exist(ROIdir,'dir')==0)%check for ROI folder
                mkdir(ROIdir);mkdir(ROImanDir);
                mkdir(ROIanaIndDir);mkdir(ROIanaIndOutDir);
            else
                if(exist(ROImanDir,'dir')==0)%check for ROI/ROI_management folder
                    mkdir(ROImanDir);
                end
                if(exist(ROIpostIndDir,'dir')==0)%check for ROI/ROI_analysis folder
                   mkdir(ROIpostIndDir');
                end
            end
            IMGdata=imread([pathname filename]);
            if(size(IMGdata,3)==3)
               if plotrgbFLAG == 0
                    IMGdata = rgb2gray(IMGdata);
                    IMGdata_copy = IMGdata;
                    IMGdata(:,:,1)=IMGdata_copy;
                    IMGdata(:,:,2)=IMGdata_copy;
                    IMGdata(:,:,3)=IMGdata_copy;
                    disp('Color image was loaded but converted to grayscale image.')
                elseif plotrgbFLAG == 1
                    IMGdata_copy = IMGdata(:,:,1);
                    disp('Display Color Image');

                end

            end

            set(filename_box,'String',filename);
            dot_position=findstr(filename,'.');dot_position=dot_position(end);
            if(exist(fullfile(pathname,'CA_Out',[filename '_fibFeatures' '.csv']),'file')~=0)%~=0 instead of ==1 because value is equal to 2
                %set(analyzer_box,'Enable','on');
                message_CAOUTdata_present=1;
            end
            if(exist(fullfile(ROImanDir,roiMATname),'file')~=0)%if file is present . value ==2 if present
                separate_rois=importdata(fullfile(ROImanDir,roiMATname));
                message_rois_present=1;
            else
                temp_kip='';
                separate_rois=[];
                save(fullfile(ROImanDir,roiMATname),'separate_rois');
            end

            s1=size(IMGdata,1);s2=size(IMGdata,2);
            mask(1:s1,1:s2)=logical(0);boundary(1:s1,1:s2)=uint8(0);

            if(isempty(separate_rois)==0)
                size_saved_operations=size(fieldnames(separate_rois),1);
                names=fieldnames(separate_rois);
                for i=1:size_saved_operations
                    Data{i,1}=names{i,1};
                end
                set(roi_table,'Data',Data);
            end
            figure(image_fig);imshow(IMGdata,'Border','tight');hold on;
            if(message_rois_present==1&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROI(s) are present and CT-FIRE data is present.');
            elseif(message_rois_present==1&&message_CAOUTdata_present==0)
                set(status_message,'String','Previously defined ROIs are present.');
            elseif(message_rois_present==0&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROIs are NOT present .ctFIRE data is present.');
            end
            set(load_image_box,'Enable','off');
           % set([draw_roi_box],'Enable','on');

        catch
           set(status_message,'String','Error loading image.');
           set(load_image_box,'Enable','on');
        end
        set(load_image_box,'Enable','off');
        set(roi_shape_choice,'Enable','on');

    end

%
    function[]=roi_shape_choice_fn(~,~)
        set(save_roi_box,'Enable','on');
        roi_shape_temp=get(roi_shape_choice,'value');
        %yl: delete the handle 'h' from "imroi" class
        if(roi_shape_temp==1)
            if ~isempty(h)
                delete(h)
                set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            else
                set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            end
            disp('ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            return
        end
        if(roi_shape_temp==2)
            set(status_message,'String','Rectangular shaped ROI selected. Press "X" to stop drawing.');
        elseif(roi_shape_temp==3)
            set(status_message,'String','Freehand ROI selected. Press "X" to stop drawing.');
        elseif(roi_shape_temp==4)
            set(status_message,'String','Ellipse shaped ROI selected. Press "X" to stop drawing.');
        elseif(roi_shape_temp==5)
            set(status_message,'String','Polygon shaped ROI selected. Press "X" to stop drawing.');
        elseif(roi_shape_temp==6)
            set(status_message,'String','Fixed Size Rectangular ROI selected. Press "X" to stop drawing.');
        end
        figure(image_fig);

        if(roi_shape_temp==2)
            roi_shape=1;
        elseif(roi_shape_temp==3)
            roi_shape=2;
        elseif(roi_shape_temp==4)
            roi_shape=3;
        elseif(roi_shape_temp==5)
            roi_shape=4;
        elseif(roi_shape_temp==6)
            roi_shape=1;
            roi_shape_popup_window;
        end
        if(roi_shape_temp>=2&&roi_shape_temp<=5)
            draw_roi_sub(0,0);
        end
    end

    function[]=roi_shape_popup_window()
        x = specifyROIpos(1); y= specifyROIpos(2);
        width=specifyROIpos(3); height=specifyROIpos(4);
        defaultBackground = get(0,'defaultUicontrolBackgroundColor');
        popup_new_roi=figure('Units','pixels','Position',[round(SW2*0.05) round(0.65*SH)  200 100],'Menubar','none','NumberTitle','off','Name','Select ROI Shape','Visible','on','Color',defaultBackground);
        rect_roi_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Fixed Size Rect ROI','Units','normalized','Position',[0.15 0.8 0.6 0.15]);
        rect_roi_height=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(height),'Position',[0.05 0.5 0.2 0.15],'enable','on','Callback',@rect_roi_height_fn);
        rect_roi_height_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Height','Units','normalized','Position',[0.28 0.5 0.2 0.15],'enable','on');
        rect_roi_width=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(width),'Position',[0.52 0.5 0.2 0.15],'enable','on','Callback',@rect_roi_width_fn);
        rect_roi_width_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Width','Units','normalized','Position',[0.73 0.5 0.2 0.15],'enable','on');
        x_start_box=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(x),'Position',[0.05 0.3 0.2 0.15],'enable','on','Callback',@x_change_fn);
        x_start_text=uicontrol('Parent',popup_new_roi,'Style','text','string','ROI X','Units','normalized','Position',[0.28 0.3 0.2 0.15],'enable','on');
        y_start_box=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(y),'Position',[0.52 0.3 0.2 0.15],'enable','on','Callback',@y_change_fn);
        y_start_text=uicontrol('Parent',popup_new_roi,'Style','text','string','ROI Y','Units','normalized','Position',[0.73 0.3 0.2 0.15],'enable','on');
        rf_numbers_ok=uicontrol('Parent',popup_new_roi,'Style','pushbutton','string','OK','Units','normalized','Position',[0.05 0.10 0.45 0.2],'Callback',@ok_fn,'Enable','on');

        function[]=rect_roi_width_fn(object,handles)
            width=str2num(get(object,'string'));
            specifyROIpos(3) = width;
        end
        function[]=rect_roi_height_fn(object,handles)
            height=str2num(get(object,'string'));
            specifyROIpos(4) = height;
        end
        function[]=x_change_fn(object,handles)
            x=str2num(get(object,'string'));
            specifyROIpos(1) = x;
        end
        function[]=y_change_fn(object,handles)
            y=str2num(get(object,'string'));
            specifyROIpos(2) = y;
        end

        function[]=ok_fn(object,handles)
            figure(popup_new_roi);close;%closes the popped up window
            figure(image_fig);
            h = imrect(gca, [x y width height]);
            setResizable(h,0);
            addNewPositionCallback(h,@(p) title(mat2str(p,3)));
            fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
            setPositionConstraintFcn(h,fcn);
            roi=getPosition(h);
        end
    end

    function[]=save_roi(~,~)
        %Entries of a Roi -
        %1. roi - contains coordinates of ROIs , (special case - ellipse
        %contains a,b,c,d and equation of ellipse - (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
        %2. shape - 1(rect) 2(freehand) 3 (ellipse) 4(freehand)
        %3. date - date of creation
        %4. time - time of creation
        %5. enclosing_rect - rectangle enclosing the ROI - [x_min,y_min,x_max,y_max]
        %6. xm - mean x position of ROI - used for printing the ROI Label
        %7. ym - mean y position of ROI - used for printing the ROI Label

        %        set(save_roi_box,'Enable','off');
        if(~isempty(h)&&h~=0)
            roi = round(getPosition(h));
        else
            disp('No ROI handle is active.')
            return;%return is handle h is invalid
        end
        %        delete(h);%debugyl
        if ~isempty(separate_rois)
            ROIs_exist = fieldnames(separate_rois);
        else
            ROIs_exist = [];
        end
        if(~isempty(ROIs_exist))
            count_max = length(ROIs_exist);
            ROI_num = count_max + 1;
            fieldname=['ROI' num2str(ROI_num)];
            % change the ROI name if it already exists in the table.
            while ~isempty(cell2mat(strfind(ROIs_exist,fieldname)))
                ROI_num = ROI_num + 1;
                fieldname=['ROI' num2str(ROI_num)];
            end
        else
            fieldname='ROI1';
        end
        if(roi_shape==1||roi_shape==2||roi_shape==3||roi_shape==4)
            separate_rois.(fieldname).roi= round(roi);
        end
        c=clock;fix(c);
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        separate_rois.(fieldname).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        separate_rois.(fieldname).time=time;
        separate_rois.(fieldname).shape=roi_shape;
        if(roi_shape==1)%rect
            data2=round(roi);
            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d];
            vertices(end+1,:)=vertices(1,:); % close the rectangle
            BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));% alternatively, BW = createMask(h);
            x_min=a;x_max=a+c;y_min=b;y_max=b+d;
            % update the parameters for the ROI specification using the
            % current ROI information
            specifyROIpos = round([a b c d]);
        elseif(roi_shape==2)%freehand
            vertices=round(roi);
            vertices(end+1,:)=vertices(1,:); % closes the freehand
            BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
            [x_min,y_min,x_max,y_max]=enclosing_rect(vertices);
        elseif(roi_shape==3)%elipse
            data2= round(roi);
            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
            s1 = size(IMGdata,1);
            s2 = size(IMGdata,2);
            %              BW = createMask(h,image_fig); % Ambiguous syntax. Associated axes contains more than one image.
            vertices = getVertices(h);
            vertices(end+1,:)=vertices(1,:); % close the elipse
            BW=roipoly(IMGdata,vertices(:,1),vertices(:,2)); % replace createMask
            x_min=a;x_max=a+c;y_min=b;y_max=b+d;
        elseif(roi_shape==4)%polygon
            vertices=round(roi);
            vertices(end+1,:)=vertices(1,:); % close the rectangle
            BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
            [x_min,y_min,x_max,y_max]=enclosing_rect(vertices);
        end
        enclosing_rect_values=[x_min,y_min,x_max,y_max];
        [xm,ym]=midpoint_fn(BW);
        separate_rois.(fieldname).enclosing_rect=enclosing_rect_values;
        separate_rois.(fieldname).xm=xm;
        separate_rois.(fieldname).ym=ym;
        separate_rois.(fieldname).boundary= {fliplr(vertices)};%%only use of bwboundaries- any further use of bwboundaries will use this field
        % directly update the ROI table by adding the new ROI before saving it into the .mat file
        Data=get(roi_table,'Data');
        Data = vertcat(Data,{fieldname});
        set(roi_table,'Data',Data);
        save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois','-append');
        kip=cell_selection_data;
        %         update_rois;
        pause(0.1);
        cell_selection_data=kip;
        %         Data=get(roi_table,'Data');

        %displaying previously selected ROis and the currently saved Rois
        if(size(cell_selection_data,1)==1)%one ROI selected
            for k2=1:size(cell_selection_data,1)
                index_temp(k2)=cell_selection_data(k2);
            end
            index_temp(end+1)=size(Data,1);
        elseif(size(cell_selection_data,1)>1)
            for k2=1:size(cell_selection_data,1)
                index_temp(k2)=cell_selection_data(k2);
            end
            index_temp(end+1)=size(Data,1);
        elseif(size(cell_selection_data,1)==0)
            index_temp=[];
            index_temp(1)=size(Data,1);
        end
        cell_selection_data(end+1,1)=index_temp(end);
        cell_selection_data(end,2)=1;%not end+1 because anentry has already been added
        eventdata.Indices = cell_selection_data(:,1);%displays the previously selected ROIs and the latest saved ROI
        cell_selection_fn(roi_table.Tag,eventdata)
    end


    function[]=combine_rois(~,~)
        s1=size(cell_selection_data,1);
        combined_rois_present=0; %0 is combined is not present and 1 if present
        roi_names=fieldnames(separate_rois);
        for i=1:s1
            if(iscell(separate_rois.(roi_names{cell_selection_data(i,1),1}).shape)==1)
                combined_rois_present=1;
                break
           end
        end

        for i=1:s1
            if(i==1)
                combined_roi_name=['comb_s_' roi_names{cell_selection_data(i,1),1}];
            elseif(i<s1)
                combined_roi_name=[combined_roi_name '_' roi_names{cell_selection_data(i,1),1}]; %#ok<*AGROW>
            elseif(i==s1)
                combined_roi_name=[combined_roi_name '_' roi_names{cell_selection_data(i,1),1} '_e'];
            end
        end
        % this loop stores all the component ROI parameters in an array
        if(combined_rois_present==0)
            for i=1:s1
                separate_rois.(combined_roi_name).shape{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape;
                separate_rois.(combined_roi_name).roi{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi;
                separate_rois.(combined_roi_name).xm{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).xm;
                separate_rois.(combined_roi_name).ym{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).ym;
                separate_rois.(combined_roi_name).boundary{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).boundary;
            end
        else
            count=1;
            for i=1:s1
                if(iscell(separate_rois.(roi_names{cell_selection_data(i,1),1}).shape)==0)%ith ROI is a single ROI
                    separate_rois.(combined_roi_name).shape{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape;
                    separate_rois.(combined_roi_name).roi{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi;
                    separate_rois.(combined_roi_name).xm{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).xm;
                    separate_rois.(combined_roi_name).ym{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).ym;
                    separate_rois.(combined_roi_name).boundary{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).boundary;
                    count=count+1;
                else %ith instance is a combined ROI
                    stemp=size(separate_rois.(roi_names{cell_selection_data(i,1),1}).roi,2);
                    for j=1:stemp
                        separate_rois.(combined_roi_name).shape{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape{j};
                        separate_rois.(combined_roi_name).roi{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi{j};
                        separate_rois.(combined_roi_name).xm{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).xm{j};
                        separate_rois.(combined_roi_name).ym{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).ym{j};
                        separate_rois.(combined_roi_name).boundary{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).boundary{j};
                        count=count+1;
                    end
                end
            end
        end
        c=clock;fix(c);
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        separate_rois.(combined_roi_name).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        separate_rois.(combined_roi_name).time=time;
        % directly update the ROI table by adding the new ROI before saving it into the .mat file
        Data=get(roi_table,'Data');
        Data = vertcat(Data,{combined_roi_name});
        set(roi_table,'Data',Data);
        save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois','-append');
    end

    function[]=update_rois
        %This function updates all ROIs in the uitable
        separate_rois=importdata(fullfile(ROImanDir,roiMATname));
        if(isempty(separate_rois)==0)
            size_saved_operations=size(fieldnames(separate_rois),1);
            names=fieldnames(separate_rois);
            for i=1:size_saved_operations
                Data{i,1}=names{i,1};
            end
            if(size_saved_operations>0)
                set(roi_table,'Data',Data);
            elseif(size_saved_operations==0)
                temp_data=[];
                set(roi_table,'Data',temp_data);
            end
        end
    end

    function[]=cell_selection_fn(src,eventdata)
       % restore default background color that can be possbily changed in "showall_rois_fn"
       set(roi_table,'BackgroundColor',[1 1 1;0.94 0.94 0.94]); % default background color
       cell_selection_data=eventdata.Indices;
       % clear a cell selection will trigger this function
       if isempty(cell_selection_data)
%            disp('Cell selection function was triggered.')  % for debug
%            purpose
           if get(showall_box,'Value')==1
               if ~isempty(get(roi_table,'Data'))
                   set(roi_table,'BackgroundColor',[0 0.4471 0.7412;0 0.4471 0.7412]); % highlight all the cells
                   % set table propropers may trigger the cell_selection
                   % callback fuction and change the cell_selection_data
                   cell_selection_data = ones(size(get(roi_table,'Data'),1),2);
                   cell_selection_data(:,1) = [1:size(get(roi_table,'Data'),1)]';
                   set(showall_box,'Value',1);
               else
                   set(showall_box,'Value',0);
               end
           end
           return
       end
        if(get(showall_box,'Value')==1 && size(cell_selection_data,1)~= size(get(roi_table,'Data'),1))
            set(showall_box,'Value',0);
        elseif (get(showall_box,'Value')==0 && size(cell_selection_data,1)== size(get(roi_table,'Data'),1))
            set(showall_box,'Value',1);
        elseif(get(showall_box,'Value')==1 && size(cell_selection_data,1)== size(get(roi_table,'Data'),1))
            set(roi_table,'BackgroundColor',[0 0.4471 0.7412;0 0.4471 0.7412]); % highlight all the cells
            cell_selection_data = ones(size(get(roi_table,'Data'),1),2);
            cell_selection_data(:,1) = [1:size(get(roi_table,'Data'),1)]';
            set(showall_box,'Value',1);
        end
        figure(image_fig);
        if ~isempty(CAroi_data_current)
            imshow(IMGdata);
        end
        hold on ;
        % make "text" objects in visible and delete "line" i.e. ROI boundary objects
        FIG_OBs=findobj(image_fig);
        Text_OBs =findall(FIG_OBs,'type','text');  % find text objects
        Line_OBs = findall(FIG_OBs,'type','line');       % find line objects
        % if h exists but is inactive or h doesnot exist, delete text/line
        try
            % h is a timer?
            if ~isvalid(h)   % h is an imroi object
                set(Text_OBs,'Visible','off');
                delete(Line_OBs);
            end
        catch
            if isempty(h)    % h is not an imroi object and is empty
                set(Text_OBs,'Visible','off');
                delete(Line_OBs);
            end
        end

        Data=get(roi_table,'Data');
        stemp=size(eventdata.Indices,1);
        if(stemp>1)
            set(combine_roi_box,'Enable','on');
            set(rename_roi_box,'Enable','off');
            ROIname_selected = '';
            for k=1:stemp
                ROIname_selected = [ROIname_selected Data{eventdata.Indices(k,1)} ' '];
            end
            ROI_message = sprintf('%s are selected and displayed.', ROIname_selected);

        elseif(stemp==1)
            set(combine_roi_box,'Enable','off');
            set(rename_roi_box,'Enable','on');
            ROI_message = sprintf('%s are selected and displayed', Data{eventdata.Indices(:,1)});
        end
        % change availability
        if(stemp>=1)
           set([CA_to_roi_box,analyzer_box,measure_roi_box,save_roi_text_box,save_roi_mask_box],'Enable','on');
        else
            set([CA_to_roi_box,analyzer_box,measure_roi_box,save_roi_text_box,save_roi_mask_box],'Enable','off');
            return;%because no ROI is selected - simpy return from function
        end
        for k=1:stemp
            try
                if (iscell(separate_rois.(Data{eventdata.Indices(k,1),1}).roi)==1)%if one of the selected ROI is a combined  ROI
                    s_subcomps=size(separate_rois.(Data{eventdata.Indices(k,1),1}).roi,2);
                    for p=1:s_subcomps
                        B=separate_rois.(Data{eventdata.Indices(k,1),1}).boundary{p};
                        for k2 = 1:length(B)
                            boundary = B{k2};
                            plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
                        end
                    end

                elseif (iscell(separate_rois.(Data{eventdata.Indices(k,1),1}).roi)==0)%if kth selected ROI is an individual ROI
                    boundary = (cell2mat(separate_rois.(Data{eventdata.Indices(k,1),1}).boundary));
                    plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
                end
            catch EXP1
                disp(sprintf('%s is NOT displayed, error message: %s',Data{eventdata.Indices(k,1)},EXP1.message));
                try
                    if (iscell(separate_rois.(Data{eventdata.Indices(k,1),1}).roi)==1)%if one of the selected ROI is a combined  ROI
                        s_subcomps=size(separate_rois.(Data{eventdata.Indices(k,1),1}).roi,2);
                        for p=1:s_subcomps
                            roi_shapeIND = separate_rois.(Data{eventdata.Indices(k,1),1}).shape{p};
                            roi_coords = separate_rois.(Data{eventdata.Indices(k,1),1}).roi{p};
                            [BD_temp xm_temp ym_temp] = roi_2_boundary(roi_shapeIND, roi_coords);
                            [x_min,y_min,x_max,y_max] = enclosing_rect(fliplr(BD_temp));
                            separate_rois.(Data{eventdata.Indices(k,1),1}).enclosing_rect{p} = [x_min,y_min,x_max,y_max];
                            separate_rois.(Data{eventdata.Indices(k,1),1}).boundary{p} = {BD_temp};
                            separate_rois.(Data{eventdata.Indices(k,1),1}).xm{p} = xm_temp;
                            separate_rois.(Data{eventdata.Indices(k,1),1}).ym{p} = ym_temp;
                            B = separate_rois.(Data{eventdata.Indices(k,1),1}).boundary{p};
                            for k2 = 1:length(B)
                                boundary = B{k2};
                                plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
                            end
                            disp(sprintf('Coordinates of a ROI boundary, enclosing rectangle, and its center were added for %s',...
                            Data{eventdata.Indices(k,1),1}));
                        end
                    elseif (iscell(separate_rois.(Data{eventdata.Indices(k,1),1}).roi)==0)%if kth selected ROI is an individual ROI
                        roi_shapeIND = separate_rois.(Data{eventdata.Indices(k,1),1}).shape;
                        roi_coords = separate_rois.(Data{eventdata.Indices(k,1),1}).roi;
                        [BD_temp xm_temp ym_temp] = roi_2_boundary(roi_shapeIND, roi_coords);
                        [x_min,y_min,x_max,y_max]= enclosing_rect(fliplr(BD_temp));
                        separate_rois.(Data{eventdata.Indices(k,1),1}).enclosing_rect = [x_min,y_min,x_max,y_max];
                        separate_rois.(Data{eventdata.Indices(k,1),1}).boundary = {BD_temp};
                        separate_rois.(Data{eventdata.Indices(k,1),1}).xm = xm_temp;
                        separate_rois.(Data{eventdata.Indices(k,1),1}).ym = ym_temp;
                        boundary = BD_temp;
                        plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
                        disp(sprintf('Coordinates of a ROI boundary, enclosing rectangle, and its center were added for %s',...
                            Data{eventdata.Indices(k,1),1}));
                    end
                    save(fullfile(ROImanDir,roiMATname),'separate_rois');

                catch EXP2
                    disp(sprintf('%s boundary conversion failed, error message: %s',Data{eventdata.Indices(k,1)},EXP2.message));
                end
            end
        end
        if(get(index_box,'Value')==1)
            for k=1:stemp
                try
                    if(iscell(separate_rois.(Data{eventdata.Indices(k,1),1}).xm)==1)
                        subcompNumber=size(separate_rois.(Data{eventdata.Indices(k,1),1}).xm,2);
                        for k2=1:subcompNumber
                            figure(image_fig);
                            tempStr=Data{cell_selection_data(k,1),1};
                            tempStr=strrep(tempStr,'_',' ');
                            %ROI_text(k)=text(separate_rois.(Data{eventdata.Indices(k,1),1}).ym{k2},separate_rois.(Data{eventdata.Indices(k,1),1}).xm{k2},tempStr,'HorizontalAlignment','center','color',[1 1 0]);
                            hold on;
                        end
                    else
                        xmid_temp=separate_rois.(Data{eventdata.Indices(k,1),1}).xm;
                        ymid_temp=separate_rois.(Data{eventdata.Indices(k,1),1}).ym;
                        figure(image_fig);
                        ROI_text{cell_selection_data(k,1),2}=text(ymid_temp,xmid_temp,Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                    end
                catch EXP3
                    disp(sprintf('Label for %s is NOT displayed , error message: %s',Data{eventdata.Indices(k,1)},EXP3.message));
                end
            end
        end
       hold off; % hold off from the image_fig
       % add ROI handle information in the message window
        try
            if isvalid(h)  %
                ROI_message = [ROI_message 'Press "X" to quit ROI annotation.'];
            else
                ROI_message = [ROI_message 'ROI annotation is not activated.'];
            end
        catch
            ROI_message = [ROI_message 'ROI annotation is not activated.'];
        end
       set(status_message,'String',ROI_message)
    end

    function [BD xc yc] = roi_2_boundary(roi_shapeIND, roi_coords)
        % convert ROI coordinates to boundary coordinates and add center
        % coordinators [xc yc]
        if(roi_shapeIND == 1)
            aa = roi_coords(1);bb = roi_coords(2);cc = roi_coords(3);dd = roi_coords(4);
            vertices_temp = [aa,bb;aa+cc,bb;aa+cc,bb+dd;aa,bb+dd;];
            BWtemp = roipoly(IMGdata,vertices_temp(:,1),vertices_temp(:,2));
        elseif(roi_shapeIND == 2 || roi_shapeIND == 4) % freehand, polygon ROI object
            BWtemp = roipoly(IMGdata,roi_coords(:,1),roi_coords(:,2));
        elseif(roi_shapeIND == 3)
            aa=roi_coords(1);bb=roi_coords(2);cc=roi_coords(3);dd=roi_coords(4);
            s1=size(IMGdata,1);s2=size(IMGdata,2);
            for m=1:s1
                for n=1:s2
                    dist=(n-(aa+cc/2))^2/(cc/2)^2+(m-(bb+dd/2))^2/(dd/2)^2;
                    if(dist<=1.00)
                        BWtemp(m,n)=logical(1);
                    else
                        BWtemp(m,n)=logical(0);
                    end
                end
            end
        end
        [xc yc] = midpoint_fn(BWtemp);
        BDc = bwboundaries(BWtemp);
        BD = BDc{1};
    end

    function[]=rename_roi(~,~)
        index=cell_selection_data(1,1);
        position=[300 300 200 200];
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        rename_roi_popup=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 100],'Menubar','none','NumberTitle','off','Name','Select ROI Shape','Visible','on','Color',defaultBackground);
        message_box=uicontrol('Parent',rename_roi_popup,'Style','text','Units','normalized','Position',[0.05 0.75 0.9 0.2],'String','Enter the new name below','BackgroundColor',defaultBackground);
        newname_box=uicontrol('Parent',rename_roi_popup,'Style','edit','Units','normalized','Position',[0.05 0.2 0.9 0.45],'String','','BackgroundColor',defaultBackground,'Callback',@ok_fn);
        ok_box=uicontrol('Parent',rename_roi_popup,'Style','Pushbutton','Units','normalized','Position',[0.5 0.05 0.4 0.2],'String','OK','BackgroundColor',defaultBackground,'Callback',@ok_fn);

        function[]=ok_fn(object,handles)
            new_fieldname=get(newname_box,'string');
            if isempty(new_fieldname)
                disp('New ROI name was not entered.')
                set(status_message,'String','New ROI name was not entered.')
                return
            end
            temp_fieldnames=fieldnames(separate_rois);
            num_fieldnames=size(temp_fieldnames,1);
            new_fieldname_present=0;
            for m=1:num_fieldnames
                if(strcmp(temp_fieldnames(m),new_fieldname))
                    new_fieldname_present=1;%the new name entered is same as one of the ROI names already present
                    break;
                end
            end
            if(new_fieldname_present==0)
                % update ROI talbe
                ROI_data = get(roi_table,'Data');
                ROI_data{index} = new_fieldname;
                set(roi_table,'Data',ROI_data);
                % update .mat file
                separate_rois.(new_fieldname)=separate_rois.(temp_fieldnames{index,1});
                separate_rois=rmfield(separate_rois,temp_fieldnames{index,1});
                separate_rois = orderfields(separate_rois,ROI_data);  % keep the same order as the ROI table
                save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois','-append');
                %               update_rois;
                close(rename_roi_popup);% closes the dialgue box
            else %condition if new name matches name of already present ROI
                set(status_message,'String','ROI with the entered name already exists, please use another name.');
                %                close;%closes the rename window
                set(newname_box,'string','');
                error_figure=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 100],'Menubar','none','NumberTitle','off','Name','Select ROI Shape','Visible','on','Color',defaultBackground);
                error_message_box=uicontrol('Parent',error_figure,'Style','text','Units','normalized','Position',[0.05 0.05 0.9 0.9],'String','Error: Name Already Exists','ForegroundColor',[1 0 0],'FontSize',15);
                pause(1.5);
                close(error_figure);
            end
        end
    end


    function[]=delete_roi(~,~)
        %Deletes the selected ROIs
        temp_fieldnames=fieldnames(separate_rois);
        if (size(cell_selection_data,1)==0)
            disp('No ROI is selected');
            set(status_message,'String','No ROI is selected');
            return
        elseif(size(cell_selection_data,1)==1)
            message_start = ''; message_end=' is deleted';
        elseif(size(cell_selection_data,1)> 1)
            message_start = '';message_end = ' are deleted';
        end

        for i=1:size(cell_selection_data,1)
            index=cell_selection_data(i,1);
            if(i==1)
                message_start =[message_start ' ' temp_fieldnames{index,1}];
            else
                message_start =[message_start ',' temp_fieldnames{index,1}];
            end
            separate_rois=rmfield(separate_rois,temp_fieldnames{index,1});
        end

        %update ROI table by deleting the seleted ROIs
        Table_data = get(roi_table,'Data');
        Table_data(cell_selection_data(:,1)) = [];   % delete the selected ROI data
        %         ROI_text(cell_selection_data(:,1),:) = [];   % update the ROI text that will be displayed
        set(roi_table,'Data',Table_data);            % update ROI table, trigger cell_selection_fn , set cell_selection_data as an empty matrix: 0-by-2
        save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois');

        message_deletion = [message_start message_end];
        set(status_message,'String',message_deletion);
        % make "text" objects in visible and delete "line" i.e. ROI boundary objects
        b=findobj(image_fig);
        c=findall(b,'type','text');set(c,'Visible','off');
        c=findall(b,'type','line');delete(c);
    end


    function[]=measure_roi(~,~)
        s1=size(IMGdata,1);s2=size(IMGdata,2);
        Data=get(roi_table,'Data');
        s3=size(cell_selection_data,1);
        if ishandle(measure_fig) == 0
            measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 470 300],...
                'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
        else
            figure(measure_fig);
        end
        measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
        measure_data{1,1}='Names';measure_data{1,2}='Min Pixel Value';measure_data{1,3}='Max Pixel Value';measure_data{1,4}='Area';measure_data{1,5}='Mean Pixel Value';

        for k=1:s3
            vertices=[];
            if (iscell(separate_rois.(Data{cell_selection_data(k,1),1}).roi)==0)
                vertices = fliplr(cell2mat(separate_rois.(Data{cell_selection_data(k,1),1}).boundary));
                BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));

            elseif (iscell(separate_rois.(Data{cell_selection_data(k,1),1}).roi)==1)
                s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                BW(1:s1,1:s2)=logical(0);
                for m=1:s_subcomps
                    vertices = fliplr(cell2mat(separate_rois.(Data{cell_selection_data(k,1),1}).boundary{m}));
                    BW2 = roipoly(IMGdata,vertices(:,1),vertices(:,2));
                    BW=BW|BW2;
                end
            end
            [min2,max2,area,mean2]=roi_stats(BW);
            measure_data{k+1,1}=Data{cell_selection_data(k,1),1};
            measure_data{k+1,2}=min2;
            measure_data{k+1,3}=max2;
            measure_data{k+1,4}=area;
            measure_data{k+1,5}=mean2;
        end
        set(measure_table,'Data',measure_data);
        set(measure_fig,'Visible','on');
        set(status_message,'string','Refer to new pop-up window containing the table of ROI features.');

        function[MIN,MAX,area,MEAN]=roi_stats(BW)
            MAX=max(max(IMGdata(BW)));
            MIN=min(min(IMGdata(BW)));
            area=sum(sum(uint8(BW)));
            MEAN=mean(IMGdata(BW));

        end

    end

%--------------------------------------------------------------------------
% Callback function for the box "Labels"
    function[]=index_fn(~,~)
  % display ROI names when the box is checked, remove the ROI name when it
  % is un-checked.
  % if no cells are selected,  return
      if isempty(cell_selection_data)
          disp('No ROI is selected')
          return
      end
      % if any cell is selced
        stemp=size(cell_selection_data,1);
        Data=get(roi_table,'Data');
        cell_selection_temp=cell_selection_data(:,1);
         if(get(index_box,'Value')==1)
            disp('ROI name will be displayed for selected ROIs except for combined ROIs.')
            if stemp == 0
                disp('No ROI is selected')
                return
            end
            figure(image_fig)
            for k=1:stemp
                IND_temp = cell_selection_temp(k);
                if(iscell(separate_rois.(Data{IND_temp,1}).xm)==1)%debug &&isempty(find(cell_selection_temp==k))==0)
                     %do nothing - display nothing in case of combined ROIs
                     disp(sprintf('Name of the combined ROI: %s was not displayed.', Data{cell_selection_data(k,1),1}));
                elseif(iscell(separate_rois.(Data{IND_temp,1}).xm)==0)% debug &&isempty(find(cell_selection_temp==k))==0)
                    ROIname_temp = Data{cell_selection_data(k,1),1};
                    xmid_temp =separate_rois.(ROIname_temp).xm;
                    ymid_temp =separate_rois.(ROIname_temp).ym;
                    ROI_text{IND_temp,1} = ROIname_temp;  % ROI name
                    ROI_text{IND_temp,2} = text(ymid_temp,xmid_temp,ROIname_temp,'HorizontalAlignment','center','color',[1 1 0]);
                    hold on
                end
            end
            hold off
        elseif(get(index_box,'Value')==0)
            disp('ROI name will not be displayed for any ROI.')
            if stemp == 0
                disp('No ROI is selected')
                return
            end
            for k=1:stemp
                IND_temp = cell_selection_temp(k);
                if(iscell(separate_rois.(Data{IND_temp,1}).xm)==1)% combined ROI
                    disp(sprintf('Name of the combined ROI: %s was not displayed.', Data{cell_selection_data(k,1),1}));
                else   % individual ROI
                    set(ROI_text{IND_temp,2},'Visible','off');
                end
            end
        end
    end
%--------------------------------------------------------------------------
%% start post-processing with ROI analyzer
%YL December2015: modified from CTroi ROI analyzer
    function[]=analyzer_launch_fn(object,handles)
        % CA ROIanalyzer output folder for individual image
        if isempty(cell_selection_data)
            set(status_message,'string','No ROI was selected for the analysis.')
            return
        end
        % prepare the mask for the selected ROI files
        BWv = {}; % initialize the cell to save the selected ROIs
        stemp=size(cell_selection_data,1);
        %finding whether the selection contains a combination of ROIs
        Data=get(roi_table,'Data');
        combined_rois_present=0;
        for ii = 1:stemp
            if(iscell(separate_rois.(Data{cell_selection_data(ii,1),1}).shape)==1)
                combined_rois_present=1; break;
            end
        end
        s1=size(IMGdata,1);s2=size(IMGdata,2);
        mask(1:s1,1:s2)=logical(0);
        BW(1:s1,1:s2)=logical(0);
        ROIshape_indv = {};xmid = []; ymid = []; ROInameV = {};
        if(combined_rois_present==0)
            for kk=1:stemp
                ROIshape_indv{kk} = separate_rois.(Data{cell_selection_data(kk,1),1}).shape;
                ROInameV{kk} = Data{cell_selection_data(kk,1),1};
                vertices= fliplr(separate_rois.(Data{cell_selection_data(kk,1),1}).boundary{1});
                BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                BWv{kk} = BW;  % put all the selected ROIs together
                mask = mask|BW;
                xmid(kk) = separate_rois.(Data{cell_selection_data(kk,1),1}).xm;
                ymid(kk)= separate_rois.(Data{cell_selection_data(kk,1),1}).ym;%finds the midpoint of points where BW=logical(1)
            end
            gmask = mask;
            backup_fig=copyobj(image_fig,0);set(backup_fig,'Visible','off');
        elseif(combined_rois_present==1)
            mask2 = mask;
            for kk = 1:stemp
                ROInameV{kk} = Data{cell_selection_data(kk,1),1};
                if (iscell(separate_rois.(Data{cell_selection_data(kk,1),1}).shape)==1)
                    s_subcomps=size(separate_rois.(Data{cell_selection_data(kk,1),1}).shape,2);%number of sub components of combined ROIs
                    for p=1:s_subcomps
                        vertices = fliplr(separate_rois.(Data{cell_selection_data(kk,1),1}).boundary{1,p}{1});
                        BW = roipoly(IMGdata,vertices(:,1),vertices(:,2));
                        if(p==1)
                            mask2 = BW;
                        else
                            mask2 = mask2|BW;
                        end
                    end
                    BW = mask2;
                    BWv{kk} = BW;
                    xmid(kk)= nan; ymid(kk) = nan;
                    ROIshape_indv{kk} = nan;
                elseif (iscell(separate_rois.(Data{cell_selection_data(kk,1),1}).shape)== 0)
                    ROIshape_indv{kk} = separate_rois.(Data{cell_selection_data(kk,1),1}).shape;
                    xmid(kk) = separate_rois.(Data{cell_selection_data(kk,1),1}).xm;
                    ymid(kk)= separate_rois.(Data{cell_selection_data(kk,1),1}).ym;%finds the midpoint of points where BW=logical(1)
                    vertices= fliplr(separate_rois.(Data{cell_selection_data(kk,1),1}).boundary{1});
                    BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                    BWv{kk} = BW;  % put all the selected ROIs together
                    mask=mask|BW;
                end
            end
            gmask=mask;
        end
        %end of mask creation
        if numSections > 1
            display('ROI Post-analysis on a single slice of a stack.')
        elseif numSections == 1
            display('ROI Post-analysis on a single image.')
        end
        CAroiANA_ifolder = ROIpostIndDir;
        if(exist(CAroiANA_ifolder,'dir')==0)%check for ROI folder
            mkdir(CAroiANA_ifolder);
        end
        set(status_message,'string','ROI analyzer based on previous full image analysis is being applied to the selected ROI(s).');
        roi_anly_fig = findobj(0,'Name','ROI Histogram in ROI Manager');
        if isempty(roi_anly_fig)
            roi_anly_fig = figure('Resize','on','Units','Normalized','Position',figPOS2,...
                'Visible','off','MenuBar','figure','Name','ROI Histogram in ROI Manager','NumberTitle','off','UserData',0);
        end
        htabgroup = uitabgroup(roi_anly_fig);
        %variables for this function - used in sub functions
        fiber_source = 'Curvelets';%other value can be ctFIRE
        fiber_data = [];
        s3 = size(cell_selection_data,1);
        s1 = size(IMGdata,1);
        s2 = size(IMGdata,2);
        indices = [];
        for k=1:s3
            indices(k)=cell_selection_data(k,1);
        end
        temp_array(1:s3)=0;
        for m=1:s3
            temp_array(m)=cell_selection_data(m,1);
        end
        marS = 10 ;linW = 1; len = size(IMGdata,1)/64;
        matdata_CApost = load(CAoutmatName,'fibFeat','tifBoundary','fibProcMeth','distThresh','coords');
        fibFeat_load = matdata_CApost.fibFeat;
        distThresh = matdata_CApost.distThresh;
        tifBoundary = matdata_CApost.tifBoundary;
        bndryMode = tifBoundary;
        coords = matdata_CApost.coords;
        fibProcMeth = matdata_CApost.fibProcMeth; % 0: curvelets; 1,2,3: CTF fibers
        fibMode = fibProcMeth;
        cropIMGon = 0;
        cropFLAG = 'NO';                 % analysis based on orignal full image analysis
        if fibMode == 0 % "curvelets"
            modeID = 'Curvelets';
        else %"CTF fibers" 1,2,3
            modeID = 'CTF Fibers';
        end
        if bndryMode == 0
            bndryID = 'NO';
        elseif bndryMode == 2 || bndryMode == 3
            bndryID = 'YES';
        end
        postFLAGt = 'YES';
        figure(image_fig);hold on;
        % if csv or tif boundary exists, overlay it on the original image
        if bndryMode == 3 %YL: only consider tiff boundary so far
            bndryFnd = checkBndryFiles(bndryMode, fullfile(pathname,'CA_Boundary'),{[filename fileEXT ]});
            if (~isempty(bndryFnd))
                if bndryMode == 1 || bndryMode == 2
                    coords = csvread([pathName sprintf('Boundary for %s.csv',item_selected)]);
                    plot(coords(:,1),coords(:,2),'m','Parent',overAx);
                    plot(coords(:,1),coords(:,2),'*m','Parent',overAx);
                elseif bndryMode == 3
                    if ~exist(fullfile(pathname,'CA_Boundary'),'dir')
                        mkdir(fullfile(pathname,'CA_Boundary'));
                    end
                    bff = fullfile(pathname,'CA_Boundary', sprintf('Mask for %s%s.tif',filename,fileEXT));
                    bdryImg = imread(bff);
                    [B,L] = bwboundaries(bdryImg,4);
                    coords = B;%vertcat(B{:,1});
                    for k = 1:length(coords)%2:length(coords)
                        boundary = coords{k};
                        plot(boundary(:,2), boundary(:,1), 'm','Parent',overAx)
                    end
                end
            end
        end
        for i = 1: size(fibFeat_load,1)
            ca = fibFeat_load(i,4)*pi/180;
            xc = fibFeat_load(i,3);
            yc = fibFeat_load(i,2);
            if bndryMode == 0
                if gmask(yc,xc) == 1
                    for j = 1:length(BWv)
                        BW = BWv{j};
                        if BW(yc,xc) == 1
                            fiber_data(i,1) = j;
                            break
                        end
                    end
                elseif gmask(yc,xc) == 0;
                    fiber_data(i,1) = 0;
                end
            elseif bndryMode >= 1   % boundary conditions
                % only count fibers/cuvelets that are within the
                % specified distance from the boundary  and within the
                % ROI defined here while excluding those within the tumor
                fiber_data(i,1) = 0;
                % within the outside boundary distance but not within the inside
                ind2 = find((fibFeat_load(:,28) <= distThresh & fibFeat_load(:,29) == 0) == 1);
                if ~isempty(find(ind2 == i))
                    if gmask(yc,xc) == 1
                        for j = 1:length(BWv)
                            BW = BWv{j};
                            if BW(yc,xc) == 1
                                fiber_data(i,1) = j;
                                break
                            end
                        end
                    end
                end
            end
        end
        ROIfeature = {};
        if bndryMode == 0
            featureLABEL = 4;
            featurename = 'Absolute Angle';
        elseif bndryMode >= 1
            featureLABEL = 30;
            featurename = 'Relative Angle';
        end
        for i = 1:length(BWv)
            if ~isnan(ROIshape_indv{i})
                ROIshape = ROIshapes{ROIshape_indv{i}};
            else
                ROIshape = '';
            end
            xc = ymid(i);yc = xmid(i); % ROI center
            ind = find( fiber_data(:,1) == i);
            fibFeat = fibFeat_load(ind,:);
            fibNUM = size(fibFeat,1);
            roiNamelist = Data{cell_selection_data(i,1),1};  % roi name on the list
            if numSections == 1
                csvFEAname = [filename '_' roiNamelist '_fibFeatures.csv']; % csv name for ROI i
                matFEAname = [filename '_' roiNamelist '_fibFeatures.mat']; % mat name for ROI i
                ROIimgname =  [filename '_' roiNamelist];
            elseif numSections > 1
                csvFEAname = [filename sprintf('_s%d_',CAcontrol.idx) roiNamelist '_fibFeatures.csv']; % csv name for ROI i
                matFEAname = [filename sprintf('_s%d_',CAcontrol.idx) roiNamelist '_fibFeatures.mat']; % mat name for ROI i
                ROIimgname =  [filename sprintf('_s%d_',CAcontrol.idx) roiNamelist];
            end
            % save data of the ROI
            csvwrite(fullfile(ROIpostIndDir,csvFEAname), fibFeat);
            disp(sprintf('%s  was saved', fullfile(ROIpostIndDir,csvFEAname)))
            matdata_CApost.fibFeat = fibFeat;
            save(fullfile(ROIpostIndDir,matFEAname), 'fibFeat','tifBoundary','fibProcMeth','distThresh','coords');
            % statistical analysis on the ROI features;
            ROIfeature{i} = fibFeat_load(ind,featureLABEL);
            try
                stats = makeStatsOROI(ROIfeature{i},ROIpostIndDir,ROIimgname,bndryMode);
                ANG_value = stats(1);  % orientation
                ALI_value = stats(5);  % alignment
            catch EXP2
                ANG_value = nan; ALI_value = nan;
                ROIstatsFLAG = 1;
                disp(sprintf('%s, ROI %d  ROI stats were skipped. Error message:%s',IMGname,k,EXP2.message))
            end
            if numSections > 1
                z = CAcontrol.idx;
            else
                z = 1;
            end
            CAroi_data_current = get(CAroi_output_table,'Data');
            if ~isempty(CAroi_data_current)
                items_number_current = length(CAroi_data_current(:,1));
            else
                items_number_current = 0;
            end
            CAroi_data_add = {items_number_current+1,sprintf('%s',filename),...
                sprintf('%s',roiNamelist),sprintf('%.1f',stats(1)),sprintf('%.2f',stats(5)),...
                sprintf('%d',fibNUM),modeID,bndryID,...
                cropFLAG,postFLAGt,ROIshape,xc,yc,z};
            CAroi_data_current = [CAroi_data_current;CAroi_data_add];
            set(CAroi_output_table,'Data',CAroi_data_current)
            figure(CAroi_table_fig)
            % histogram
            figure(roi_anly_fig);
            tabfig_name{items_number_current+1} = uitab(htabgroup, 'Title', sprintf('%d-%s',items_number_current+1,ROInameV{i}));
            hax(items_number_current+1) = axes('Parent', tabfig_name{items_number_current+1});
            set(hax(items_number_current+1),'Position',[0.12 0.12 0.84 0.84]);
            hist(ROIfeature{i});
            xlabel('Angle [degrees]');
            ylabel('Frequency');
            axis square
        end
        hold off
    end
%% --------------------------------------------------------------------------
	function[]=CA_to_roi_fn(object,handles)
        %% Option for ROI analysis
     % save current parameters
       if CAcontrol.fibMode ~= 0
           set(status_message, 'string', 'Direct ROI analysis can not be applied to the CT-FIRE mode so far. Try post-processing with ROI analyzer instead.' )
           return
       end
        ROIanaChoice = questdlg('Do ROI analysis for the cropped rectgular shaped ROI or the ROI mask of any shape?', ...
            'ROI Analysis','Cropped Rectangular ROI','ROI Mask of Any Shape','Cropped Rectangular ROI');
        if isempty(ROIanaChoice)
           set(status_message, 'string', ' Choose the ROI analysis type to proceed.' )
           return
        end
        switch ROIanaChoice
            case 'Cropped Rectangular ROI'
                cropIMGon = 1;
                disp('CA alignment analysis on the the cropped rectangular ROIs.')
            case 'ROI Mask of Any Shape'
                cropIMGon = 0;
                disp('CA alignment analysis on the the ROI mask of any shape.');
        end
        s1=size(IMGdata,1);
        s2=size(IMGdata,2);
        if(exist(ROIanaIndDir,'dir')==0)%check for ROI folder
               mkdir(ROIanaIndDir);
        end
        if(exist(ROIanaIndOutDir,'dir')==0)%check for ROI folder
            mkdir(ROIanaIndOutDir);
        end
        % histogram output figure
        roi_anly_fig = findobj(0,'Name','ROI Histogram in ROI Manager');
        if isempty(roi_anly_fig)
            roi_anly_fig = figure('Resize','on','Units','Normalized','Position',figPOS2,...
                'Visible','off','MenuBar','figure','Name','ROI Histogram in ROI Manager','NumberTitle','off','UserData',0);
        end
        htabgroup = uitabgroup(roi_anly_fig);
        % load CurveAlign parameters
        CA_P = load(fullfile(pathname,'currentP_CA.mat'));
        % structure CA_P include fields:
        %'keep', 'coords', 'distThresh', 'makeAssocFlag', 'makeMapFlag',
        %'makeOverFlag', 'makeFeatFlag', 'infoLabel', 'bndryMode', 'bdryImg',
        %'pathName', 'fibMode','numSections','advancedOPT'
        BWcell = CA_P.bdryImg;
        ROIbw = BWcell;  %  for the full size image
        for i = 1:numSections
            s_roi_num=size(cell_selection_data,1);
            Data=get(roi_table,'Data');
            separate_rois_copy=separate_rois;
            cell_selection_data_copy=cell_selection_data;
            if numSections == 1
              IMGdata_copy=IMGdata(:,:,1);
            else
                IMGtemp = imread(IMGname,i);
                if size(IMGtemp,3) > 1
                    if plotrgbFLAG == 0
                        IMGtemp = rgb2gray(IMGtemp);
                        disp('Color image was loaded but converted to grayscale image.')
                        IMGdata(:,:,1) = IMGtemp;
                        IMGdata(:,:,2) = IMGtemp;
                        IMGdata(:,:,3) = IMGtemp;
                    elseif plotrgbFLAG == 1
                        IMGdata = IMGtemp;
                        disp('Display Color Image');
                    end
                    IMGdata_copy = IMGdata(:,:,1);
                else
                    IMGdata_copy = IMGtemp;
                end
                delete IMGtemp
            end
            for k=1:s_roi_num
                if cropIMGon == 0     % use ROI mask
                    if   ~iscell(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape)
                        ROIshape_ind = separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape;
                        BD_temp = separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).boundary;
                        boundary = BD_temp{1};
                        BW = roipoly(IMGdata_copy,boundary(:,2),boundary(:,1));
                        [yc xc] = midpoint_fn(BW); z = i;
                    elseif iscell(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape)
                        ROIshape_ind = nan;
                        s_subcomps=size(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape,2);
                        s1=size(IMGdata_copy,1);
                        s2=size(IMGdata_copy,2);
                        BW(1:s1,1:s2)=logical(0);
                        for m=1:s_subcomps
                            boundary = cell2mat(separate_rois_copy.(Data{cell_selection_data(k,1),1}).boundary{m});
                            BW2 = roipoly(IMGdata_copy,boundary(:,2),boundary(:,1));
                            BW=BW|BW2;
                        end
                        xc = nan; yc = nan; z = i;
                    end
                    ROIimg = IMGdata_copy.*uint8(BW);

                elseif cropIMGon == 1
                    if   ~iscell(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape)
                        ROIshape_ind = separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape;

                        if ROIshape_ind == 1   % use cropped ROI image
                            data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                            a=round(data2(1));b=round(data2(2));c=round(data2(3));d=round(data2(4));
                            ROIimg = IMGdata_copy(b:b+d-1,a:a+c-1); % YL to be confirmed
                            % add boundary conditions
                            if ~isempty(BWcell)
                                ROIbw  =  BWcell(b:b+d-1,a:a+c-1);
                            else
                                ROIbw = [];
                            end
                            xc = round(a+c/2); yc = round(b+d/2); z = i;
                        else
                            disp(sprintf('Cropped image ROI analysis for shapes other than rectangles is not available so far.\n %s: %s',...
                                Data{cell_selection_data_copy(k,1),1},ROIshapes{ROIshape_ind}))
                            break
                        end
                    else  % combined ROI
                        disp(sprintf('%s: Cropped image ROI analysis for combined ROIs is not supported.',Data{cell_selection_data_copy(k,1),1}));
                        break
                    end

                end
                roiNamelist = Data{cell_selection_data_copy(k,1),1};  % roi name on the list
                if numSections > 1
                    roiNamefull = [filename,sprintf('_s%d_',i),roiNamelist,'.tif'];
                elseif numSections == 1
                    roiNamefull = [filename,'_',roiNamelist,'.tif'];
                end
                imwrite(ROIimg,fullfile(ROIanaIndDir,roiNamefull));
                %add ROI .tiff boundary name
                if ~isempty(BWcell)
                    roiBWname = sprintf('Mask for %s.tif',roiNamefull);
                    if ~exist(fullfile(ROIanaIndDir,'CA_Boundary'),'dir')
                        mkdir(fullfile(ROIanaIndDir,'CA_Boundary'));
                    end
                    imwrite(ROIbw,fullfile(ROIanaIndDir,'CA_Boundary',roiBWname));
                    CA_P.ROIbdryImg = ROIbw;
                    CA_P.ROIcoords =  bwboundaries(ROIbw,4);
                else
                    CA_P.ROIbdryImg = [];
                    CA_P.ROIcoords =  [];
                end
                [~,roiNamefullNE] = fileparts(roiNamefull);
                [~,stats]=processROI(ROIimg, roiNamefullNE, ROIanaIndOutDir, CA_P.keep, CA_P.ROIcoords, CA_P.distThresh, CA_P.makeAssocFlag, CA_P.makeMapFlag, CA_P.makeOverFlag, CA_P.makeFeatFlag, 1, CA_P.infoLabel, CA_P.bndryMode, CA_P.ROIbdryImg, ROIanaIndDir, CA_P.fibMode, CA_P.advancedOPT,1);
                % count the number of features from the output feature file
                angFilename = fullfile(ROIanaIndOutDir,[roiNamefullNE '_values.csv']);
                if exist(angFilename,'file')
                    ang_load = importdata(angFilename);
                    if CA_P.bndryMode == 0  % no boundary
                        fibANG = ang_load;
                    else
                        fibANG = ang_load(:,1);
                    end
                    fibNUM = size(fibANG,1);
                else
                    fibNUM = nan; fibANG = nan;
                end
                CAroi_data_current = get(CAroi_output_table,'Data');
                if ~isempty(CAroi_data_current)
                    items_number_current = length(CAroi_data_current(:,1));
                else
                    items_number_current = 0;
                end
                if ~isnan(ROIshape_ind)
                    ROIshape = ROIshapes{ROIshape_ind};
                else
                    ROIshape = '';
                end
                if cropIMGon == 1
                   cropFLAG = 'YES';   % analysis based on cropped image
                elseif cropIMGon == 0
                   cropFLAG = 'NO';    % analysis based on orignal image with the region other than the ROI set to 0.
                end
                postFLAG = 'NO'; % Yes: use post-processing based on available results in the output folder
                modeID = 'Curvelets'; % "curvelets" or "CT-FIRE"
                if CA_P.fibMode == 0 % "curvelets"
                    modeID = 'Curvelets';
                else %"CTF fibers" 1,2,3
                    modeID = 'CTF Fibers';
                end
                if CA_P.bndryMode == 0
                    bndryID = 'NO';
                elseif CA_P.bndryMode == 2 || CA_P.bndryMode == 3
                    bndryID = 'YES';
                end
                CAroi_data_add = {items_number_current+1,sprintf('%s',filename),...
                    sprintf('%s',roiNamelist),sprintf('%.1f',stats(1)),sprintf('%.2f',stats(5)),...
                    sprintf('%d',fibNUM),modeID,bndryID,...
                    cropFLAG,postFLAG,ROIshape,xc,yc,z};
                CAroi_data_current = [CAroi_data_current;CAroi_data_add];
                set(CAroi_output_table,'Data',CAroi_data_current)
                figure(CAroi_table_fig)
                % histogram
                figure(roi_anly_fig);
                tabfig_name{items_number_current+1} = uitab(htabgroup, 'Title', sprintf('%d-%s',items_number_current+1,roiNamelist));
                hax(items_number_current+1) = axes('Parent', tabfig_name{items_number_current+1});
                set(hax(items_number_current+1),'Position',[0.08 0.08 0.84 0.84]);
                hist(fibANG);
                xlabel('Angle [degrees]');
                ylabel('Frequency');
                %             title(sprintf('%s',roiNamelist));
                axis square

            end
        end
    end
    function[]=load_roi_fn(~,~)
        [text_filename_all,text_pathname,~]=uigetfile({'*.csv'},'Select ROI coordinates file(s).',pseudo_address,'MultiSelect','on');
        if ~iscell(text_filename_all)
            text_filename_all = {text_filename_all};
        end
        for j=1:size(text_filename_all,2)
            text_filename = text_filename_all{1,j};
            boundaries_temp = csvread([text_pathname text_filename]); % c1: y; c2:x
            BD_to_roi_fn(boundaries_temp);
            save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois','-append');
            update_rois;
        end

    end
    function[xmid,ymid]=midpoint_fn(BW)
        %Used to find the center of a mask
        stat=regionprops(BW,'centroid');
        xmid=round(stat.Centroid(2));
        ymid=round(stat.Centroid(1));
    end
    function[]=showall_rois_fn(object,~)

        Data=get(roi_table,'Data');
        if isempty(Data)
            disp('No ROI exists')
            set(object,'Value',0);
            return
        end
        showall_flag = get(object,'Value');
        %unselect the possibly selected cells
        set(roi_table,'Data', vertcat({''},Data)); % change the data will trigger the cell_selection_fn
        set(roi_table,'Data',Data);

        stemp=size(Data,1);
        indices=1:stemp;
        if(showall_flag == 1)
            cell_selection_data = ones(stemp,2);
            cell_selection_data(:,1) = indices';
            eventdata.Indices = cell_selection_data;
            cell_selection_fn(roi_table.Tag,eventdata);
            %after unselect all the cells, the background color setting works
            set(roi_table,'BackgroundColor',[0 0.4471 0.7412;0 0.4471 0.7412]);
            cell_selection_data = eventdata.Indices;  %
            set(object,'Value',1);
            set(status_message, 'String','All ROIs are selected and displayed.')
        else         % box of "Show All" was unchecked
            figure(image_fig);
            b=findobj(gcf);
            c=findall(b,'type','text');set(c,'Visible','off');
            c=findall(b,'type','line');delete(c);
            % restore default background color that can be possbily changed in "showall_rois_fn"
            set(roi_table,'BackgroundColor',[1 1 1;0.94 0.94 0.94]); % default background color
            cell_selection_data = [];
            set(status_message, 'String','No ROI is selected or displayed.')
        end

    end

    function[]=save_text_roi_fn(~,~)

        %text output directory
        text_DIR = fullfile(ROImanDir,'ROI_text');
        if ~exist(text_DIR,'dir')
            mkdir(text_DIR);
        end
        s3=size(cell_selection_data,1);
        roi_names=fieldnames(separate_rois);
        Data=get(roi_table,'Data');
        for i=1:s3
            destination=fullfile(text_DIR,[filename,'_',roi_names{cell_selection_data(i,1),1},'_coordinates.csv']);
            roi_individual=separate_rois.(Data{cell_selection_data(i,1),1}).boundary; %
            if ~iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)
                csvwrite(destination,roi_individual);  % two columns: 1c: y, 2c: x
                set(status_message,'string',['ROI coordinates were saved in ' text_DIR '.']);
            else
                set(status_message,'string','Combined ROI can NOT be saved as a text file.');
            end
        end
    end


%Use boundary to create mask and save the mask
    function[]=save_mask_roi_fn(~,~)
        %mask output directory
        mask_DIR = fullfile(ROImanDir,'ROI_mask');
        if ~exist(mask_DIR,'dir')
            mkdir(mask_DIR);
        end
        stemp=size(cell_selection_data,1);
        s1=size(IMGdata,1);
        s2=size(IMGdata,2);
        Data=get(roi_table,'Data');
        ROInameSEL = '';   % selected ROI name
        for i=1:stemp
             if(iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)==0)
                  vertices= fliplr(separate_rois.(Data{cell_selection_data(i,1),1}).boundary{1});
                  BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                  imwrite(BW,fullfile(mask_DIR,[filename '_'  (Data{cell_selection_data(i,1),1}) 'mask.tif']),...
                   'Compression','none');
             elseif(iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)==1)
                 s_subcomps=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi,2);
                 for k=1:s_subcomps
                      vertices = fliplr(separate_rois.(Data{cell_selection_data(i,1),1}).boundary{1,k}{1});
                      BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                      if(k==1)
                         mask2=BW;
                      else
                         mask2=mask2|BW;
                      end
                 end
                 imwrite(mask2,fullfile(mask_DIR, [filename '_'  (Data{cell_selection_data(i,1),1}) 'mask.tif']),...
                     'Compression','none');
             end
              %update the message window
             if i == 1
                 ROInameSEL = Data{cell_selection_data(i,1),1};
             elseif i> 1 & i < stemp
                 ROInameSEL = horzcat(ROInameSEL,',',Data{cell_selection_data(i,1),1});
             elseif i == stemp
                 ROInameSEL = horzcat(ROInameSEL,' and ',Data{cell_selection_data(i,1),1});
             end
             if i == stemp
                 if stemp == 1
                     set(status_message,'String',sprintf('%d mask file for %s  was saved in %s',stemp,ROInameSEL,mask_DIR));
                 else
                     set(status_message,'String',sprintf('%d mask files for %s  were saved in %s',stemp,ROInameSEL,mask_DIR));
                 end
             else
                 set(status_message,'String', 'Saving individual mask(s)...')
             end
        end
    end

     function[]=mask_to_roi_fn(~,~)

        [mask_filename_all,mask_pathname,~]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select Mask Image',pseudo_address,'MultiSelect','on');
        % if single image is opened, covert filename from string type to
        % cell type
        if ~iscell(mask_filename_all)
           mask_filename_all = {mask_filename_all};
        end
        for j=1:size(mask_filename_all,2)
            mask_filename=mask_filename_all{1,j};
            mask_image=imread([mask_pathname mask_filename]);
            boundaries=bwboundaries(mask_image);%bwboundaries needed because no info on bounary in ROI database
            for i=1:size(boundaries,1)
                boundaries_temp=boundaries{i,1};
                BD_to_roi_fn(boundaries_temp);
            end
            save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois','-append');
            update_rois;
        end

    end

% add ROI based on Boudary coordinates
    function[] = BD_to_roi_fn(boundaries)
        if(isfield(separate_rois,'ROI1'))
            count=2;
            while(count<1000)
                fieldname=['ROI' num2str(count)];
                if(isfield(separate_rois,fieldname)==0)
                    break;
                end
                count=count+1;
            end
        else
            fieldname= 'ROI1';
        end
        c=clock;fix(c);
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        separate_rois.(fieldname).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        separate_rois.(fieldname).time=time;
        separate_rois.(fieldname).shape=2;  %all ROIs saved are loaded as freehand ROIs
        [x_min,y_min,x_max,y_max]=enclosing_rect(fliplr(boundaries));
        enclosing_rect_values=[x_min,y_min,x_max,y_max];
        separate_rois.(fieldname).enclosing_rect=enclosing_rect_values;
%         tempImage=roipoly(mask_image,boundaries(:,2),boundaries(:,1));
        tempImage=roipoly(IMGdata,boundaries(:,2),boundaries(:,1));  % plot ROI on the current image
        [xm,ym]=midpoint_fn(tempImage);
        separate_rois.(fieldname).xm=xm;
        separate_rois.(fieldname).ym=ym;
        separate_rois.(fieldname).roi=fliplr(boundaries);
        separate_rois.(fieldname).boundary={boundaries};%Required to find boundary of new mask
    end


    function[x_min,y_min,x_max,y_max]=enclosing_rect(coordinates)
        x_min=round(min(coordinates(:,1)));
        x_max=round(max(coordinates(:,1)));
        y_min=round(min(coordinates(:,2)));
        y_max=round(max(coordinates(:,2)));
    end


end
