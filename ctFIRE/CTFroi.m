function[]=CTFroi(ROIctfp)
% CTFroi is  designed for CT-FIRE ROI analysis (its previous name is roi_gui_v3)
% ROI module project started in December 2014 as part of the LOCI collagen quantification tool development efforts.

% Log:
% December 2014 to May 2015: two undergraduate students from Indian Institute of Technology at Jodhpur, Guneet S. Mehta and Prashant Mittal
% supervised and mentored by both LOCI and IITJ, took the development of CT-FIRE ROI module as a part of their Bachelor of Technology Project.
% Guneet S. Mehta was responsible for implementing the code and Prashant Mittal for testing and debugging.
% May 2015:  Prashant Mittal quit the project after he graduated.
% May 2015-August 2015: Guneet S. Mehta continuously works on the improvement of the CT-FIRE ROI module.
% On August 13th, Guneet S. Mehta started as a graduate research assistant at UW-LOCI, working with Yuming Liu toward finalizing the CT-FIRE ROI module
%  as well as adapting it for CurveAlign ROI analysis.
% On August 27 2015,CTFroi took the current function name.

%    global separate_rois;
   CTFroi_data_current = [];
   if nargin == 0
       ROIctfp = [];
       ROIctfp.filename = [];
       ROIctfp.pathname = [];
       ROIctfp.CTFroi_data_current = [];
       ROIctfp.roiopenflag = 1;    % to enable open button
       separate_rois = [];
%        CTFroi_data_current = [];
   elseif nargin == 1
       disp('Use the parameters from the CT-FIRE main program.')
       disp('Disable the open file button in ROI manager.')
       CTFfilename = ROIctfp.filename;    % selected file name
       CTFpathname = ROIctfp.pathname;    % selected file path
       mdEST_OP = ROIctfp.fiber_midpointEST;  % midddle point estimation option, 1: use end point coordinate; 2: based on fiber length
       [~,filenameNE,fileEXT] = fileparts(CTFfilename);

       if exist(fullfile(CTFpathname,'ROI_management',sprintf('%s_ROIs.mat',filenameNE)))
             load(fullfile(CTFpathname,'ROI_management',sprintf('%s_ROIs.mat',filenameNE)),'CTFroi_data_current','separate_rois');
             if ~isempty(separate_rois)
                 ROInamestemp1 = fieldnames(separate_rois);
                 if(exist(fullfile(CTFpathname,'ROI_management',[filenameNE '_ROIs.mat']),'file')~=0)%if file is present . value ==2 if present
                     separate_roistemp2=importdata(fullfile(CTFpathname,'ROI_management',[filenameNE '_ROIs.mat']));
                     ROInamestemp2 = fieldnames(separate_roistemp2);
                     ROIdif = setdiff(ROInamestemp2,ROInamestemp1);
                     if ~isempty(ROIdif)
                         for ri = 1:length(ROIdif)
                             separate_rois.(ROIdif{ri}) = [];
                             separate_rois.(ROIdif{ri}) =separate_roistemp2.(ROIdif{ri});
                         end
                     end
                 end
              end
       else

            if(exist(fullfile(CTFpathname,'ROI_management',[filenameNE '_ROIs.mat']),'file')~=0)%if file is present . value ==2 if present
                  separate_rois=importdata(fullfile(CTFpathname,'ROI_management',[filenameNE '_ROIs.mat']));
            % create an empty _ROIs.mat mat file, so that '_append' works
            % when adding a new ROI from the begining
            else
                if ~exist(fullfile(CTFpathname,'ROI_management'),'dir')
                    mkdir(fullfile(CTFpathname,'ROI_management'))
                end
                  separate_rois = []; save(fullfile(CTFpathname,'ROI_management',[filenameNE '_ROIs.mat']),'separate_rois');
            end
%             CTFroi_data_current = [];
        end

       ROIctfp.CTFroi_data_current = CTFroi_data_current;
       roiopenflag = ROIctfp.roiopenflag;  % set to 0 for single image ROI analysis, and need to replace the function 'load_image'
       load(fullfile(CTFpathname,'currentP_CTF.mat'),'cP','ctfP');
       ctFP = ctfP; clear ctfP;
       cP.RO = 1;  % use CT-FIRE for fiber extraction
       stackflag = cP.stack;   % 1: stack; 0:non-stack
       if stackflag == 1
           currentIDX = cP.slice;       % current slice indx
           numSections = cP.sselected;  % total slected slices
           cP.stack = 0;    % just run as a single image
       else
           currentIDX = 1;
           numSections = 1;
       end
   end
    pseudo_address = '';           % default path
    IMGdata = [];                    % original image data
    filename = '';                 % image name
    imgEXT = '';                   % image extension
    pathname = '';                 % image path
    roi = [];                      % roi edge coordinates
    roi_shape = 1;                 % shape of ROI. 0: no shape; 1: rectangle; 2: freestyle; 3: elipse; 4: polygon
    h = [];                        % handle to an ROI object
    matdata=[];                    % ctfire output .mat data
    xmid = nan; ymid = nan;        % ROI center x,y coordinates
    clrr2 = [];                    % n x 3 color array for n fibers
    cell_selection_data = [];      % selected ROI nx2 [row col]
    ROI_text=cell(0,2);
    fiber_source='ctFIRE';  %other value can be only postPRO
    fiber_method='mid';     %other value can be whole
    roi_anly_fig=-1;        % initialize figure handle
    statistics_fig = -1;    % initialize figure handle
    measure_fig = -1;       % initialize the figure containing the summary statistics table
    popup_new_roi=0;        %initialize figur hangle to ROI shape selection menu
    %set up the environment, add dependencies
    specifyROIpos = [1 1 256 256]; % default position of the 'specify' ROI, [x y width heigtht]
    %roi_mang_fig - roi manager figure - initilisation starts
    SSize = get(0,'screensize');SW2 = SSize(3); SH = SSize(4);
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    roi_mang_fig = findobj(0,'Tag','ROI Mananger List-CTF');
    if isempty(roi_mang_fig)
        roi_mang_fig = figure('Resize','on','Color',defaultBackground,'Units','pixels',...
            'Position',[round(0.067*SW2) round(0.02*SH) round(0.2*SW2) round(SH*0.8)],...
            'Visible','on','MenuBar','none','name','ROI Manager','NumberTitle','off','UserData',0,'Tag','ROI Mananger List-CTF');
    else
        figure(roi_mang_fig)
    end
    set(roi_mang_fig,'KeyPressFcn',@roi_mang_keypress_fn);
    relative_horz_displacement=20;      %relative horizontal displacement of analysis figure from roi manager
    fig_temp = findobj(0,'Tag','ROI Manager Figure-CTF');
    if ~isempty(fig_temp)
       close(fig_temp)
    end
    image_fig=figure('name','CT-FIRE ROI Analysis Output Figure in ROI Manager',...
        'Units','pixels','Position',[0.269*SW2 0.05*SH 0.474*SH 0.474*SH],...
        'NumberTitle','off','KeyPressFcn',@roi_mang_keypress_fn,'Tag','ROI Manager Figure-CTF');
    % initialisation ends
    guiFig3b = figure('Resize','on','Color',defaultBackground','Units','normalized',...
        'Position',[0.255 0.09 0.474*SH/SW2*2 0.474],'Visible','off',...
    'MenuBar','figure','name','CT-FIRE ROI Output Image','NumberTitle','off','UserData',0);      % enable the Menu bar for additional operations

    %defining buttons - starts
    roi_table=uitable('Parent',roi_mang_fig,'Units','normalized','Position',[0.05 0.05 0.45 0.9],'Tag','ROI_list','CellSelectionCallback',@cell_selection_fn);
%     reset_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.75 0.96 0.2 0.03],'String','Reset','Callback',@reset_fn,'TooltipString','Press To Reset');
    filename_box=uicontrol('Parent',roi_mang_fig,'Style','text','String','filename','Units','normalized','Position',[0.05 0.955 0.45 0.04],'BackgroundColor',[1 1 1]);
    roi_shape_choice_text=uicontrol('Parent',roi_mang_fig,'Style','text','string','Draw ROI Menu (d)','Units','normalized','Position',[0.55 0.86 0.4 0.035]);
    roi_shape_choice=uicontrol('Parent',roi_mang_fig,'Enable','off','Style','popupmenu','string',{'New ROI?','Rectangle','Freehand','Ellipse','Polygon','Specify...'},'Units','normalized','Position',[0.55 0.82 0.4 0.035],'Callback',@roi_shape_choice_fn);
    set(roi_shape_choice,'Enable','off');
    save_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.78 0.4 0.035],'String','Save ROI (s)','Enable','off','Callback',@save_roi);
    combine_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.74 0.4 0.035],'String','Combine ROIs','Enable','on','Callback',@combine_rois,'Enable','off','TooltipString','Combine 2 or more ROIs');
    rename_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.7 0.4 0.035],'String','Rename ROI','Callback',@rename_roi);
    delete_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.66 0.4 0.035],'String','Delete ROI','Callback',@delete_roi);
    measure_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.62 0.4 0.035],'String','Measure ROI','Callback',@measure_roi,'TooltipString','Displays ROI Properties');
    load_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.58 0.4 0.035],'String','Load ROI from Text','TooltipString','Loads ROIs of other images','Enable','on','Callback',@load_roi_fn);
    load_roi_from_mask_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.54 0.4 0.035],'String','Load ROI from Mask','Callback',@mask_to_roi_fn,'Enable','on');
    save_roi_text_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.50 0.4 0.035],'String','Save ROI Text','Callback',@save_text_roi_fn,'Enable','off');
    save_roi_mask_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.46 0.4 0.035],'String','Save ROI Mask','Callback',@save_mask_roi_fn,'Enable','off');

    analyzer_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.42 0.4 0.035],'String','CT-FIRE ROI Analyzer','Callback',@analyzer_launch_fn,'Enable','off');
    ctFIRE_to_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.38 0.4 0.035],'String','Apply CT-FIRE on ROI','Callback',@ctFIRE_to_roi_fn,'Enable','off','TooltipString','Applies CT-FIRE on the selected ROI');
    set(ctFIRE_to_roi_box,'Visible','on');
    shift_disp=-0.06;
    index_box=uicontrol('Parent',roi_mang_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.364+shift_disp 0.08 0.025],'Callback',@index_fn);
    index_text=uicontrol('Parent',roi_mang_fig,'Style','Text','Units','normalized','Position',[0.631 0.36+shift_disp 0.16 0.025],'String','Labels');

    showall_box=uicontrol('Parent',roi_mang_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.394+shift_disp 0.08 0.025],'Callback',@showall_rois_fn);
    showall_text=uicontrol('Parent',roi_mang_fig,'Style','Text','Units','normalized','Position',[0.631 0.39+shift_disp 0.25 0.025],'String','Show All');

    status_title=uicontrol('Parent',roi_mang_fig,'Style','text','Fontsize',9,'Units','normalized','Position',[0.585 0.285+shift_disp 0.4 0.045],'String','Message Window');
    status_message=uicontrol('Parent',roi_mang_fig,'Style','text','Fontsize',10,'Units','normalized','Position',[0.515 0.05 0.485 0.245+shift_disp],'String','Use "Open File" to select a file','BackgroundColor','g');
    set([rename_roi_box,measure_roi_box],'Enable','off');

    %%YL create CT-FIRE output table
          ROIshapes = {'Rectangle','Freehand','Ellipse','Polygon'};
          % Column names and column format
          columnname = {'No.','Image Label','ROI label','Width','Length','Straightness','Angle','FeatNum',...
              'Method','CROP','POST','Shape','Xc','Yc','Z'};
          columnformat = {'numeric','char','char','char','char' ,'char','char','char',...
              'char','char','char','char','numeric','numeric','numeric'};
          columnwidth = {30 100 60 60 60 60 60 60,...
              60 40 40 60 30 30 30};   %
        selectedROWs = [];
        CTFroi_table_fig = figure(246); clf
        figPOS = [0.269 0.05+0.474+0.095 0.474*SH/SW2*2 0.85-0.474-0.095];
         set(CTFroi_table_fig,'Units','normalized','Position',figPOS,'Visible','off',...
             'name','CT-FIRE ROI Analysis Output Table in ROI Manager','NumberTitle','off')
         % make the ROI output table visible if previous ROI analysis results exist
         if ~isempty(CTFroi_data_current)
             set(CTFroi_table_fig,'Visible','on')
         end
         CTFroi_output_table = uitable('Parent',CTFroi_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],...
        'Data', CTFroi_data_current,...
        'ColumnName', columnname,...
        'ColumnFormat', columnformat,...
        'ColumnWidth',columnwidth,...
        'ColumnEditable', [false false false false false false false false false false false],...
        'RowName',[],...
        'CellSelectionCallback',{@CTFot_CellSelectionCallback});
        DeleteROIout=uicontrol('Parent',CTFroi_table_fig,'Style','Pushbutton','Units','normalized','Position',[0.9 0.01 0.08 0.08],'String','Delete','Callback',@DeleteROIout_Callback);
        SaveROIout=uicontrol('Parent',CTFroi_table_fig,'Style','Pushbutton','Units','normalized','Position',[0.80 0.01 0.08 0.08],'String','Save All','Callback',@SaveROIout_Callback);
    %ends - defining buttons

    if nargin == 1
        filename = CTFfilename;
        pathname = CTFpathname;
        clear CTFfilename CTFpathname;
        %YL: define all the output files, directories here
        %folders for CTF ROI analysis on defined ROI(s) of individual image
        ROImanDir = fullfile(pathname,'ROI_management');
        ROIDir = fullfile(pathname,'CTF_ROI');
        ROIanaIndDir = fullfile(pathname,'CTF_ROI','Individual','ROI_analysis');
        % folders for CTF post ROI analysis of individual image
        ROIpostIndDir = fullfile(pathname,'CTF_ROI','Individual','ROI_post_analysis');
        ROIpostIndOutDir = fullfile(ROIpostIndDir,'ctFIREout');
        load_ctfimage();
    else
        error('ROI manager can only be called from CT-FIRE.');
        return;
    end

%-------------------------------------------------------------------------
%output table callback functions
    function CTFot_CellSelectionCallback(~, eventdata,handles)
        %Function to handle cell selection in "ct FIRE ROI output analysis
        %table" figure and plots the selected ROIs on the image
        handles.currentCell=eventdata.Indices;
        selectedROWs = unique(handles.currentCell(:,1));
        selectedZ = CTFroi_data_current(selectedROWs,15);
        if numSections > 1
            for j = 1:length(selectedZ)
                Zv(j) = selectedZ{j};
            end
            if size(unique(Zv)) == 1
                zc = unique(Zv);
            else
                error('Only display ROIs in the same section of a stack.')
            end
        else
            zc = 1;
        end

        for i= 1:length(selectedROWs)
           CTFroi_name_selected =  CTFroi_data_current(selectedROWs(i),3);
           if numSections > 1
               roiNamefull = [filename,sprintf('_s%d_',zc),CTFroi_name_selected{1},'.tif'];
               if zc ~= currentIDX
                   currentIDX = zc;   % change the current slice number to zc;
                   imagetemp = imread(fullfile(pathname,[filename,fileEXT]),currentIDX);
                   IMGdata(:,:,1) = imagetemp;
                   IMGdata(:,:,2) = imagetemp;
                   IMGdata(:,:,3)= imagetemp;
                   clear imagetemp
               end
           elseif numSections == 1
                roiNamefull = [filename,'_', CTFroi_name_selected{1},'.tif'];
           end

           IMGnamefull = fullfile(pathname,[filename,fileEXT]);
           if numSections == 1
                img2 = imread(IMGnamefull);
            elseif numSections > 1
                img2 = imread(IMGnamefull,zc);
            end
            if size(img2,3) > 1
                img2 = rgb2gray(img2);
            end
            IMGO(:,:,1) = uint8(img2);
            IMGO(:,:,2) = uint8(img2);
            IMGO(:,:,3) = uint8(img2);

            cropFLAG_selected = unique(CTFroi_data_current(selectedROWs,10));
            if size(cropFLAG_selected,1)~=1
                disp('Please select ROIs processed with the same method.')
                return
            elseif size(cropFLAG_selected,1)==1
                cropFLAG = cropFLAG_selected;
            end
             postFLAG_selected = unique(CTFroi_data_current(selectedROWs,11));
            if size(postFLAG_selected,1)~=1
                disp('Please select ROIs processed with the same method.')
                return
            elseif size(postFLAG_selected,1)==1
                postFLAG = postFLAG_selected;
            end
             if strcmp(cropFLAG,'YES')
                for i= 1:length(selectedROWs)
                    CTFroi_name_selected =  CTFroi_data_current(selectedROWs(i),3);
                    if numSections > 1
                        roiNamefullNE = [filename,sprintf('_s%d_',zc),CTFroi_name_selected{1}];
                    elseif numSections == 1
                        roiNamefullNE = [filename,'_', CTFroi_name_selected{1}];
                    end
                    IMGol = [];
                    olName = fullfile(ROIanaIndDir,'ctFIREout',sprintf('OL_ctFIRE_%s.tif',roiNamefullNE));
                    if exist(olName,'file')
                        IMGol = imread(olName);
                    else
                        data2=separate_rois.(CTFroi_name_selected{1}).roi;
                        a=round(data2(1));b=round(data2(2));c=round(data2(3));d=round(data2(4));
                        ROIrecWidth = c; ROIrecHeight = d;
                        IMGol = zeros(ROIrecHeight,ROIrecWidth,3);
                    end
                    if separate_rois.(CTFroi_name_selected{1}).shape == 1
                        data2=separate_rois.(CTFroi_name_selected{1}).roi;
                        a=round(data2(1));b=round(data2(2));c=round(data2(3));d=round(data2(4));
                        IMGO(b:b+d-1,a:a+c-1,1) = IMGol(:,:,1);
                        IMGO(b:b+d-1,a:a+c-1,2) = IMGol(:,:,2);
                        IMGO(b:b+d-1,a:a+c-1,3) = IMGol(:,:,3);
                        xx(i) = a+c/2;  yy(i)= b+d/2; ROIind(i) = selectedROWs(i);
                        aa2(i) = a; bb(i) = b;cc(i) = c; dd(i) = d;
                    else
                        error('Cropped image ROI analysis for shapes other than rectangles is not available so far.');
                    end
                end
                 if ~isempty(findobj(0,'Name', 'CT-FIRE ROI Output Image in ROI Manager'))
                    figure(guiFig3b);
                else
                    guiFig3b = figure('Resize','on','Color',defaultBackground','Units',...
                        'normalized','Position',[0.255 0.09 0.474*SH/SW2*1 0.474],'Visible','off',...
                        'MenuBar','figure','Name','CA ROI output Image in ROI manager','NumberTitle','off','UserData',0);      % enable the Menu bar for additional operations
                end
                imshow(IMGO); hold on;
                for i= 1:length(selectedROWs)
                    CTFroi_name_selected =  CTFroi_data_current(selectedROWs(i),3);
                    if separate_rois.(CTFroi_name_selected{1}).shape == 1
                        rectangle('Position',[aa2(i) bb(i) cc(i) dd(i)],'EdgeColor','y','linewidth',3)
                    end
                    text(xx(i),yy(i),sprintf('%d',ROIind(i)),'fontsize', 10,'color','m')
                end
                hold off
            end

            if strcmp(cropFLAG,'NO')
                ii = 0; boundaryV = {};yy = []; xx = []; RV = [];
                for i= 1:length(selectedROWs)
                    CTFroi_name_selected =  CTFroi_data_current(selectedROWs(i),3);
                    if ~iscell(separate_rois.(CTFroi_name_selected{1}).shape)
                        ii = ii + 1;
                        if numSections > 1
                            roiNamefullNE = [filename,sprintf('_s%d_',zc),CTFroi_name_selected{1}];
                        elseif numSections == 1
                            roiNamefullNE = [filename,'_', CTFroi_name_selected{1}];
                        end
                        IMGol = [];
                        if strcmp(postFLAG,'NO')
                            olName = fullfile(ROIanaIndDir,'ctFIREout',sprintf('OL_ctFIRE_%s.tif',roiNamefullNE));
                            if exist(olName,'file')
                                IMGol = imread(olName);
                            end
                        elseif strcmp(postFLAG,'YES')
                            olName = fullfile(ROIpostIndDir,'ctFIREout',sprintf('OL_ctFIRE_%s.tif',roiNamefullNE));
                            if exist(olName,'file')
                               IMGol = imread(olName);
                            end
                        end
                        if isempty(IMGol)
                            IMGol = zeros(size(IMGO));
                        end
                        boundary = separate_rois.(CTFroi_name_selected{1}).boundary{1};
                        [x_min,y_min,x_max,y_max] = enclosing_rect_fn(fliplr(boundary));
                        a = x_min;  % x of upper left corner of the enclosing rectangle
                        b = y_min;   % y of upper left corner of the enclosing rectangle
                        c = x_max-x_min;  % width of the enclosing rectangle
                        d = y_max - y_min;  % height of the enclosing rectangle
                        % replace the region of interest with the data in the
                        % ROI analysis output
                        IMGO(b:b+d-1,a:a+c-1,1) = IMGol(b:b+d-1,a:a+c-1,1);
                        IMGO(b:b+d-1,a:a+c-1,2) = IMGol(b:b+d-1,a:a+c-1,2);
                        IMGO(b:b+d-1,a:a+c-1,3) = IMGol(b:b+d-1,a:a+c-1,3);
                        boundaryV{ii} = boundary;
                        yy(ii) = separate_rois.(CTFroi_name_selected{1}).xm;
                        xx(ii) = separate_rois.(CTFroi_name_selected{1}).ym;
                        RV(ii) = i;
                        ROIind(ii) = selectedROWs(i);
                    else
                        disp('Selected ROI is a combined one and is not displayed.')
                        return
                    end
                end

                if ~isempty(findobj(0,'Name', 'CT-FIRE ROI Output Image in ROI Manager'))
                    figure(guiFig3b);
                else
                    guiFig3b = figure('Resize','on','Color',defaultBackground','Units','normalized',...
                        'Position',[0.255 0.09 0.474*SH/SW2*1 0.474],'Visible','off',...
                        'MenuBar','figure','Name','CT-FIRE ROI Output Image in ROI Manager','NumberTitle','off','UserData',0);      % enable the Menu bar for additional operations
                end
                imshow(IMGO); hold on;
                if ii > 0
                    for ii = 1:length(selectedROWs)
                        text(xx(ii),yy(ii),sprintf('%d',ROIind(ii)),'fontsize', 10,'color','m')
                        boundary = boundaryV{ii};
                        plot(boundary(:,2), boundary(:,1), 'm', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                        text(xx(ii),yy(ii),sprintf('%d',selectedROWs(RV(ii))),'fontsize', 10,'color','m')
                    end
                else
                    disp('NO CT-FIRE ROI analysis output was visualized'.)
                end
                hold off
            end
        end
    end

    function DeleteROIout_Callback(~,~)
        %deletes CTFroi_data_current and sets is to the data of
        %CTFroi_output_table
        CTFroi_data_current(selectedROWs,:) = [];
        if ~isempty(CTFroi_data_current)
            for i = 1:length(CTFroi_data_current(:,1))
                CTFroi_data_current(i,1) = {i};
            end
        end
        set(CTFroi_output_table,'Data',CTFroi_data_current)
    end

    function SaveROIout_Callback(~,~)
        %Sets up .mat and .xlsx files in ROImanDIr
         if ~isempty(CTFroi_data_current)
             %YL: may need to delete the existing files
           save(fullfile(ROImanDir,sprintf('%s_ROIs.mat',filenameNE)),'CTFroi_data_current','separate_rois') ;
           if exist(fullfile(ROImanDir,sprintf('%s_ROIs.xlsx',filenameNE)),'file')
               delete(fullfile(ROImanDir,sprintf('%s_ROIs.xlsx',filenameNE)));
           end
           try
               xlswrite(fullfile(ROImanDir,sprintf('%s_ROIs.xlsx',filenameNE)),[columnname;CTFroi_data_current],'CTF ROI Alignment Analysis') ;
           catch
               xlwrite(fullfile(ROImanDir,sprintf('%s_ROIs.xlsx',filenameNE)),[columnname;CTFroi_data_current],'CTF ROI Alignment Analysis') ;
           end

         else
             %delete exist output file if data is empty
            if exist(fullfile(ROImanDir,sprintf('%s_ROIs.mat',filenameNE)),'file')
               delete(fullfile(ROImanDir,sprintf('%s_ROIs.mat',filenameNE)))
            end
            if exist(fullfile(ROImanDir,sprintf('%s_ROIs.xlsx',filenameNE)),'file')
               delete(fullfile(ROImanDir,sprintf('%s_ROIs.xlsx',filenameNE)));
            end
         end
    end

%end of output table callback functions
%--------------------------------------------------------------------------
% load_ctfimage funcction is based on the load_image function
    function load_ctfimage()
     % Loads image if the script is called from ctFIRe sets up directories if not present.
        set(status_message,'string','File is being opened. Please wait...');
        try
            ctFIREdata_present=0;
            rois_present=0;
            pseudo_address=pathname;
            save('lastPATH_CTF.mat','pseudo_address');
            if(exist(ROIDir,'dir')==0)      %check for ROI folder
                mkdir(ROIDir);mkdir(ROIanaIndDir);mkdir(fullfile(ROIanaIndDir,'ctFIREout'));mkdir(ROIpostIndDir);mkdir(fullfile(ROIpostIndDir,'ctFIREout'));
            end
            if(exist(ROImanDir,'dir')==0)%check for ROI management folder
               mkdir(ROImanDir);
            end

            if stackflag == 1
               IMGdata=imread(fullfile(pathname,filename),currentIDX);
            else
               IMGdata=imread(fullfile(pathname,filename));
            end
            if (size(IMGdata,3)==3)
                IMGdata_copy=rgb2gray(IMGdata);
                disp('Color image was loaded but converted to grayscale image.');
            else
                IMGdata_copy = IMGdata;
            end
            IMGdata(:,:,1)=IMGdata_copy;IMGdata(:,:,2)=IMGdata_copy;IMGdata(:,:,3)=IMGdata_copy;
            set(filename_box,'String',filename);
            dot_position=strfind(filename,'.');dot_position=dot_position(end); %Reading last dot position to find format and filename
            imgEXT=filename(dot_position+1:end);filename=filename(1:dot_position-1);

            if(exist(fullfile(pathname,'ctFIREout', ['ctFIREout_' filename '.mat']),'file')~=0)%~=0 instead of ==1 because value is equal to 2 for file
                set(analyzer_box,'Enable','on');
                ctFIREdata_present=1;
            end

            if(exist(fullfile(ROImanDir,[filename '_ROIs.mat']),'file')~=0&&size(separate_rois,1)~=0)%if file is present . value ==2 if present. Checks if ROIs for the image is present or not
                % empty structure
                if ~isempty(fieldnames(separate_rois))
                    rois_present=1;
                end
            else
                separate_rois=[];save(fullfile(ROImanDir,[filename '_ROIs.mat']),'separate_rois');
            end

            if(isempty(separate_rois)==0)
                size_saved_operations=size(fieldnames(separate_rois),1);
                names=fieldnames(separate_rois);
                %only set roi_table when the names is not empty
                if ~isempty(names)
                    Data=cell(size_saved_operations,1);
                    for i=1:size_saved_operations
                        Data{i,1}=names{i,1};
                    end
                    set(roi_table,'Data',Data);
                end
            end
            figure(image_fig);
            imshow(IMGdata,'Border','tight');
            set(image_fig,'Units','pixels','Position',[0.269*SW2 0.05*SH 0.474*SH 0.474*SH])
            if(rois_present==1&&ctFIREdata_present==1)
                set(status_message,'String','Previously defined ROIs are present, and CT-FIRE data is present.');
            elseif(rois_present==1&&ctFIREdata_present==0)
                set(status_message,'String','Previously defined ROIs are present. CT-FIRE data is NOT present.');
            elseif(rois_present==0&&ctFIREdata_present==1)
                set(status_message,'String','Previously defined ROIs NOT present. CT-FIRE data is present');
            else
                set(status_message,'String','Previously defined ROIs NOT present. CT-FIRE data is NOT present.');
            end
        catch TCexception
            disp(sprintf('%s: %s',filename,TCexception.message))
            set(status_message,'String','ROI managment/analysis for individual image.');
        end
        set(roi_shape_choice,'Enable','on');
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
                set(status_message,'String','ROI annotation is not enabled. Select ROI shape to draw new ROI(s).');
            end
            disp('ROI annotation is not enabled. Select ROI shape to draw new ROI(s).');
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
      set(status_message,'string','Press "S" to save ROI.');
       if(roi_shape == 0 && roi_shape ~=5)
           setPositionConstraintFcn(h,fcn);
       end
    end

    function[]=roi_shape_choice_fn(~,~)
        set(save_roi_box,'Enable','on');
        roi_shape_temp=get(roi_shape_choice,'value');
         %yl: delete the handle 'h' from "imroi" class
        if(roi_shape_temp==1)
            if ~isempty(h)
                delete(h)
                set(status_message,'String','ROI annotation is disabled. Select ROI shape to draw new ROI(s).');
            else
                set(status_message,'String','ROI annotation is not enabled. Select ROI shape to draw new ROI(s).');
            end
            disp('ROI annotation is not enabled. Select ROI shape to draw new ROI(s).');
            return
        end
        if(roi_shape_temp==2)
            set(status_message,'String','Rectangular shape ROI selected. Press "X" to stop drawing.');
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
            separate_rois.(fieldname).roi=round(roi);
        end
        c=clock;fix(c);
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        separate_rois.(fieldname).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        separate_rois.(fieldname).time=time;
        separate_rois.(fieldname).shape=roi_shape;
        if(roi_shape==1)%rect
            data2= round(roi);
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
            [x_min,y_min,x_max,y_max]=enclosing_rect_fn(vertices);
        elseif(roi_shape==3)%elipse
            data2=round(roi);
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
            [x_min,y_min,x_max,y_max]=enclosing_rect_fn(vertices);
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
        separate_rois=importdata(fullfile(ROImanDir,[filename,'_ROIs.mat']));
        size_saved_operations=size(fieldnames(separate_rois),1);
        Data=[];
        if(size_saved_operations>0)
                names=fieldnames(separate_rois);
                for i=1:size_saved_operations
                    Data{i,1}=names{i,1};
                end
        end
        set(roi_table,'Data',Data);
%         update_ROI_text;
       % display(cell_selection_data)
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
        figure(image_fig);  hold on ;

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
            ROI_message = sprintf('%s are selected and displayed', ROIname_selected);

        elseif(stemp==1)
            set(combine_roi_box,'Enable','off');
            set(rename_roi_box,'Enable','on');
            ROI_message = sprintf('%s is selected and displayed', Data{eventdata.Indices(:,1)});
        end
        % change availability
        if(stemp>=1)
           set([ctFIRE_to_roi_box,analyzer_box,measure_roi_box,save_roi_text_box,save_roi_mask_box],'Enable','on');
        else
            set([ctFIRE_to_roi_box,analyzer_box,measure_roi_box,save_roi_text_box,save_roi_mask_box],'Enable','off');
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
                    vertices = (cell2mat(separate_rois.(Data{eventdata.Indices(k,1),1}).boundary));
                    plot(vertices(:,2), vertices(:,1), 'y', 'LineWidth', 2);
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
                            [x_min,y_min,x_max,y_max] = enclosing_rect_fn(fliplr(BD_temp));
                            separate_rois.(Data{eventdata.Indices(k,1),1}).enclosing_rect{p} = [x_min,y_min,x_max,y_max];
                            separate_rois.(Data{eventdata.Indices(k,1),1}).boundary{p} = {BD_temp};
                            separate_rois.(Data{eventdata.Indices(k,1),1}).xm(p) = xm_temp;
                            separate_rois.(Data{eventdata.Indices(k,1),1}).ym(p) = ym_temp;
                            B = separate_rois.(Data{eventdata.Indices(k,1),1}).boundary{p};
                            for k2 = 1:length(B)
                                boundary = B{k2};
                                plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
                            end
                            disp(sprintf('Coordinates of ROI boundary, enclosing rectangle, and its center were added for %s',...
                            Data{eventdata.Indices(k,1),1}));
                        end
                    elseif (iscell(separate_rois.(Data{eventdata.Indices(k,1),1}).roi)==0)%if kth selected ROI is an individual ROI
                        roi_shapeIND = separate_rois.(Data{eventdata.Indices(k,1),1}).shape;
                        roi_coords = separate_rois.(Data{eventdata.Indices(k,1),1}).roi;
                        [BD_temp xm_temp ym_temp] = roi_2_boundary(roi_shapeIND, roi_coords);
                        [x_min,y_min,x_max,y_max]= enclosing_rect_fn(fliplr(BD_temp));
                        separate_rois.(Data{eventdata.Indices(k,1),1}).enclosing_rect = [x_min,y_min,x_max,y_max];
                        separate_rois.(Data{eventdata.Indices(k,1),1}).boundary = {BD_temp};
                        separate_rois.(Data{eventdata.Indices(k,1),1}).xm = xm_temp;
                        separate_rois.(Data{eventdata.Indices(k,1),1}).ym = ym_temp;
                        boundary = BD_temp;
                        plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
                        disp(sprintf('Coordinates of ROI boundary, enclosing rectangle, and its center were added for %s',...
                            Data{eventdata.Indices(k,1),1}));
                    end
                    save(fullfile(ROImanDir,[filename '_ROIs.mat']),'separate_rois');

                catch EXP2
                    disp(sprintf('%s boundary conversion has failed, error message: %s',Data{eventdata.Indices(k,1)},EXP2.message));
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
                catch EXP
                    disp(sprintf('Label for %s is NOT displayed , error message: %s',Data{eventdata.Indices(k,1)},EXP.message));
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

    function update_ROI_text()
       Data=get(roi_table,'Data');
        sizeData=size(Data,1);
        ROI_text=cell(sizeData,4);
        for i=1:sizeData
            ROI_text{i,1}=Data{i};
            try
            if(iscell(separate_rois.(Data{i}).ym)==0)
               ROI_text{i,2}=text(separate_rois.(Data{i}).ym,separate_rois.(Data{i}).xm,Data{i},'HorizontalAlignment','center','color',[1 1 0]);
               set(ROI_text{i,2},'Visible','off');
            else
                temp={};
                for j=1:size(separate_rois.(Data{i}).ym,2)
                    temp{j}=text(separate_rois.(Data{i}).ym{j},separate_rois.(Data{i}).xm{j},Data{i},'HorizontalAlignment','center','color',[0 1 0]);
                    set(temp{j},'Visible','off');
                end
                ROI_text{i,2}=temp;
            end
            catch exception
                disp(sprintf('%s',exception.message))
                disp(sprintf('ROI text for %s is not updated.',Data{i}))
            end
        end
    end

    function show_indices_ROI_text(indices)
        Data=get(roi_table,'Data');
        sizeData=size(Data,1);
        count=1;
        %display(get(index_box,'Value'));
        for i=1:sizeData
            if(get(index_box,'Value')==1&&count<=size(indices,1)&&i==indices(count))
                if(iscell(separate_rois.(Data{i}).ym)==0)
                    set(ROI_text{i,2},'Visible','on');
                else
                    for j=1:size(ROI_text{i,2},2)
                        set(ROI_text{i,2}{j},'Visible','on');
                    end
                end
                count=count+1;
            else
                if(iscell(separate_rois.(Data{i}).ym)==0)
                    set(ROI_text{i,2},'Visible','off');
                else
                    for j=1:size(ROI_text{i,2},2)
                        set(ROI_text{i,2}{j},'Visible','off');
                    end
                end
            end

        end
    end

    function[xmid,ymid]=midpoint_fn(BW)
        %Used to find the center of a mask
        stat=regionprops(BW,'centroid');
        xmid=round(stat.Centroid(2));
        ymid=round(stat.Centroid(1));
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
               set(status_message,'String','ROI with the entered name already exists, use another name.');
%                close;%closes the rename window
               set(newname_box,'string','');
               error_figure=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 100],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);
               error_message_box=uicontrol('Parent',error_figure,'Style','text','Units','normalized','Position',[0.05 0.05 0.9 0.9],'String','Error-Name Already Exists','ForegroundColor',[1 0 0],'FontSize',15);
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
       set(status_message,'string','Refer to the new window containing the table of ROI features.');

     function[MIN,MAX,area,MEAN]=roi_stats(BW)
         MAX=max(max(IMGdata(BW)));
         MIN=min(min(IMGdata(BW)));
         area=sum(sum(uint8(BW)));
         MEAN=mean(IMGdata(BW));

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
        [x_min,y_min,x_max,y_max]=enclosing_rect_fn(fliplr(boundaries));
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

% launch ROI analyzer
    function[]=analyzer_launch_fn(~,~)
        %Launches the analyzer sub window
        %load CTF output file
         if isempty(matdata)
            set(status_message,'string', 'Importing CT-FIRE output file for ROI analyzer.')
            matdata=importdata(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat'])); %matdata stores ctFIRE data
            clrr2 = rand(size(matdata.data.Fa,2),3); %clrr2 contains random colors for fibers , number of fibers = size(matdata.data.Fa,2)
        end
        set(status_message,'string','CT-FIRE data imported. Selected ROI(s) to be analyzed in the ROI analyzer window.');
        fig_temp1 = findobj(0,'Name','Analyzer in ROI Manager-CTF');
        if ~isempty(fig_temp1)
            close(fig_temp1)
        end
        roi_anly_fig = figure('Resize','off','Color',defaultBackground,'Units','pixels','Position',...
            [round(0.267*SW2) round(0.60*SH) round(0.167*SW2) round(0.35*SH)],...
            'Visible','on','MenuBar','none','name','Analyzer in ROI Manager-CTF','NumberTitle','off','UserData',0);


        panel=uipanel('Parent',roi_anly_fig,'Units','Normalized','Position',[0 0 1 1]);
        filename_box2=uicontrol('Parent',panel,'Style','text','String','Based on CTF output of a single image','Units','normalized','Position',[0.05 0.86 0.9 0.14]);
        check_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Check Fibers','Units','normalized','Position',[0.05 0.72 0.9 0.14],'Callback',@check_fibers_fn,'TooltipString','Shows Fibers within ROI');
        plot_statistics_box=uicontrol('Parent',panel,'Style','pushbutton','String','Plot Statistics','Units','normalized','Position',[0.05 0.58 0.9 0.14],'Callback',@plot_statisitcs_fn,'enable','off','TooltipString','Plots statistics of fibers shown');
        more_settings_box2=uicontrol('Parent',panel,'Style','pushbutton','String','More Settings','Units','normalized','Position',[0.05 0.44 0.9 0.14],'Callback',@more_settings_fn2,'TooltipString','Change Fiber source, Fiber selection definition');
        generate_stats_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Generate Stats','Units','normalized','Position',[0.05 0.30 0.9 0.14],'Callback',@generate_stats_fn,'TooltipString','Produces and displays an Excel file of statistics.','Enable','off');
        automatic_roi_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Automatic ROI Detection','Units','normalized','Position',[0.05 0.16 0.9 0.14],'Callback',@automatic_roi_fn,'TooltipString','Function to find ROI with Max Avg property value');
        visualisation_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Visualisation of Fibers','Units','normalized','Position',[0.05 0.02 0.9 0.14],'Callback',@visualisation,'Enable','off','TooltipString','Shows Fibers in different colors based on property values.');

        mask=[];
        fiber_source='ctFIRE';%other value can be only 'postPRO'. Use the fibers of ctFIRE or use the fibers extracted as a result of sub selection in post processing GUI
        fiber_method='mid';%other value can be 'whole'
        fiber_data=[];
        SHG_pixels=0; %Number of pixels considered as SHG in the image
        SHG_ratio=0;% ratio of SHG pixels to the total number of pixels
        total_pixels=0; % total pixels in the image

        try %Checks if the ctFIRE results are present , if not then display error message, close the figure and return
            SHG_threshold=matdata.ctfP.value.thresh_im2;%  value taken from the ctFIRE results
        catch
            set(status_message,'String','CT-FIRE results not present. Run CT-FIRE on image first.'); close (roi_anly_fig);return;
        end
        SHG_threshold_method=0;%0 for hard threshold and 1  for soft threshold

        %analyzer functions -start
        function[]=check_fibers_fn(handles,object)
            plot_fiber_centers=0;%1 to plot and 0 not to plots
            s3=size(cell_selection_data,1); %Number of selected ROIs
            s1 = size(IMGdata,1);
            s2 = size(IMGdata,2);
            indices=cell_selection_data(:,1);

            figure(image_fig);hold on;

            names=fieldnames(separate_rois);
            mask=zeros(s1,s2);
            BW=logical(zeros(s1,s2));
            Data=get(roi_table,'Data');

            for k=1:s3
                if(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==0)% single ROI - not combined
                    vertices = fliplr(cell2mat(separate_rois.(names{cell_selection_data(k,1),1}).boundary));
                    BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                    mask=mask|BW;
                elseif(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==1)% combined ROIs - i.e one ROI containing multiple ROis
                    s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2); %number of components in the combined ROI
                    for p=1:s_subcomps
                        vertices=fliplr(cell2mat(separate_rois.(names{cell_selection_data(k,1),1}).boundary{p}));;
                        BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                        mask=mask|BW;
                    end
                end
                %now finding the SHG pixels for each ROI
                SHG_pixels(k)=size(find(BW==logical(1)&IMGdata(:,:,1)>=SHG_threshold),1);%pixels where BW is 1 and image >threshold
                total_pixels_temp=size(find(BW==logical(1)),1);
                SHG_ratio(k)=SHG_pixels(k)/total_pixels_temp;
                total_pixels(k)=total_pixels_temp;
            end

            size_fibers=size(matdata.data.Fa,2);
            if(strcmp(fiber_source,'ctFIRE')==1)
                fiber_data=[];
                for i=1:size_fibers
                    fiber_data(i,1)=i; fiber_data(i,2)=1; fiber_data(i,3)=0;
                end
                ctFIRE_length_threshold=matdata.cP.LL1;
                xls_widthfilename=fullfile(pathname,'ctFIREout',['HistWID_ctFIRE_',filename,'.csv']);
                xls_lengthfilename=fullfile(pathname,'ctFIREout',['HistLEN_ctFIRE_',filename,'.csv']);
                xls_anglefilename=fullfile(pathname,'ctFIREout',['HistANG_ctFIRE_',filename,'.csv']);
                xls_straightfilename=fullfile(pathname,'ctFIREout',['HistSTR_ctFIRE_',filename,'.csv']);
                fiber_width=csvread(xls_widthfilename);
                fiber_length=csvread(xls_lengthfilename); % no need of fiber_length - as data is entered using fiber_length_fn
                fiber_angle=csvread(xls_anglefilename);
                fiber_straight=csvread(xls_straightfilename);
                %sorted fiber properties
                kip_length=sort(fiber_length);      kip_angle=sort(fiber_angle);        kip_width=sort(fiber_width);        kip_straight=sort(fiber_straight);

                count=1;
                for i=1:size_fibers
                    if(fiber_length_fn(i)<= ctFIRE_length_threshold)%YL: change from "<" to "<="  to be consistent with original ctFIRE_1
                        fiber_data(i,2)=0;
                        fiber_data(i,3)=fiber_length_fn(i);
                        fiber_data(i,4)=0;%width
                        fiber_data(i,5)=0;%angle
                        fiber_data(i,6)=0;%straight
                    else
                        fiber_data(i,2)=1;
                        fiber_data(i,3)=fiber_length_fn(i);
                        fiber_data(i,4)=fiber_width(count);
                        fiber_data(i,5)=fiber_angle(count);
                        fiber_data(i,6)=fiber_straight(count);
                        count=count+1;
                    end
                end
            elseif(strcmp(fiber_source,'postPRO')==1)
                if(isfield(matdata.data,'PostProGUI')&&isfield(matdata.data.PostProGUI,'fiber_indices'))
                    fiber_data=matdata.data.PostProGUI.fiber_indices;
                else
                    set(status_message,'String','Post Processing Data Not Present.');
                    return;
                end
            end

            if(strcmp(fiber_method,'whole')==1) %when the entire fiber is within the ROI
                figure(image_fig);
                for i = 1:size_fibers % s1 is number of fibers in image selected out of Post pro GUI
                    if (fiber_data(i,2)==1)
                        vertex_indices=matdata.data.Fa(i).v;
                        s2=size(vertex_indices,2);
                        flag=1;% becomes zero if one of the fiber points is outside roi, and thus we do not consider the fiber
                        for j=1:s2
                            x=matdata.data.Xa(vertex_indices(j),1);y=matdata.data.Xa(vertex_indices(j),2);
                            if(mask(y,x)==0) % here due to some reason y and x are reversed, still need to figure this out
                                flag=0;
                                fiber_data(i,2)=0;
                                break;
                            end
                        end

                        if(flag==1) % x and y seem to be interchanged in plot
                            %estimate the middle point
                            vertex_indices_INT = matdata.data.Fai(i).v;
                            s2 = size(vertex_indices_INT,2);
                            xmid = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),1));
                            ymid = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),2));
                            if xmid > size(IMGdata,2) || ymid > size(IMGdata,1) || xmid < 1 || ymid < 1
                                vertex_indices = matdata.data.Fa(i).v;
                                s2=size(vertex_indices,2);
                                xmid = round(matdata.data.Xa(vertex_indices(round(s2/2)),1));
                                ymid = round(matdata.data.Xa(vertex_indices(round(s2/2)),2));
                                fprintf('Interpolated coordinates of fiber %d is out of bounds, orignial coordinates will be used for fiber middle point estimation. \n',i)
                            end

                            if(plot_fiber_centers==1)
                                plot(xmid,ymid,'--rs','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','g','MarkerSize',10);
                            end
                            hold on;
                        end
                    end
                end
            elseif(strcmp(fiber_method,'mid')==1)%when the mid point of the fiber is within the ROI
                figure(image_fig);
                for i=1:size_fibers
                    if (fiber_data(i,2)==1)
                        %in later development, middle point calculation should be calculated only
                        %once and saved in the matdata, rather than
                        % do a calculation each time it is used
                        if mdEST_OP == 1 %use fiber end coordinates
                            fsp = matdata.data.Fa(i).v(1);
                            fep = matdata.data.Fa(i).v(end);
                            sp = matdata.data.Xa(fep,:);  % start point
                            ep = matdata.data.Xa(fsp,:);  % end point
                            cen = round(mean([sp; ep]));
                            x = cen(1);
                            y = cen(2);
                        elseif mdEST_OP == 2  % use fiber length
                            %use interpolated coordinates to estimated the fiber center
                            vertex_indices_INT = matdata.data.Fai(i).v;
                            s2 = size(vertex_indices_INT,2);
                            x = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),1));
                            y = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),2));
                            % If [y x] is out of boundary due to interpolation,
                            % then use the un-interpolated coordinates
                            if x> size(IMGdata,2) || y > size(IMGdata,1)|| x < 1 || y< 1
                                vertex_indices=matdata.data.Fa(i).v;
                                s2=size(vertex_indices,2);
                                x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                fprintf('Interpolated coordinates of fiber %d is out of bounds, orignial coordinates will be used for fiber middle point estimation. \n',i)
                                if mask(y,x)==1
                                    fprintf('This fiber is inside the ROI\n')
                                else
                                    fprintf('This fiber is NOT inside the ROI\n')
                                end
                            end
                        end
                        if(mask(y,x)==1) % x and y seem to be interchanged in plot
                            if(plot_fiber_centers==1)
                                plot(x,y,'--rs','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','g','MarkerSize',10); hold on;
                            end
                        else
                            fiber_data(i,2)=0;
                        end
                    end
                end
            end
            plot_fibers(fiber_data,image_fig,0,0);
            set([visualisation_box2,plot_statistics_box,generate_stats_box2],'Enable','on');
        end

        function[]=plot_statisitcs_fn(handles,object)
            % depending on selected ROI find the fibers within the ROI
            % also give an option on number of bins for histogram
            fig_temp2 = findobj(0,'Name','ROI Histograms-CTF ROI Mananger');
            if ~isempty(fig_temp2)
                close(fig_temp2)
            end
            statistics_fig = figure('Resize','on','Color',defaultBackground,...
                'Units','pixels','Position',[round(0.28*SW2+0.474*SH) round(0.05*SH) round(0.50*SH) round(0.55*SH)],...
                'Visible','on','name','ROI Histograms-CTF ROI Mananger','NumberTitle','off','UserData',0);

            Data=get(roi_table,'data');string_temp=Data(cell_selection_data(:,1));
            roi_size_temp=size(string_temp,1);
%             string_temp{roi_size_temp+1,1}='All ROIs';
%             display(string_temp);
            property_box=uicontrol('Parent',statistics_fig,'Style','popupmenu','String',{'All Properties';'Length'; 'Width';'Angle';'Straightness'},'Units','normalized','Position',[0.03 0.92 0.2 0.07],'Callback',@change_in_property_fn,'Enable','on');
            roi_selection_box=uicontrol('Parent',statistics_fig,'Style','popupmenu','String',string_temp,'Units','normalized','Position',[0.37 0.92 0.17 0.07],'Enable','on','Callback',@change_in_roi_fn);
            bin_number_text=uicontrol('Parent',statistics_fig,'Style','text','String','BINs','Units','normalized','Position',[0.55 0.97 0.2 0.03]);
            bin_number_box=uicontrol('Parent',statistics_fig,'Style','edit','String','10','Units','normalized','Position',[0.70 0.97 0.2 0.03],'Callback',@bin_number_fn);

            default_action;
            condition1=1;condition2=0;condition3=0;condition4=0;condition5=0;
            sub1=0;sub2=0;sub3=0;sub4=0;h1=0;h2=0;h3=0;h4=0;

            function[]=bin_number_fn(object,handles)
               default_action;
            end

            function[]=change_in_property_fn(object,handles)
                %display(get(property_box,'value'));

                if(get(property_box,'value')==1)
                    condition1=1;condition2=0;condition3=0;condition4=0;
                elseif(get(property_box,'value')==2)
                    condition2=1;condition1=0;condition3=0;condition4=0;
                elseif(get(property_box,'value')==3)
                    condition3=1;condition1=0;condition2=0;condition4=0;
                elseif(get(property_box,'value')==4)
                    condition4=1;condition1=0;condition2=0;condition3=0;
                end
                default_action;
            end

            function[]=change_in_roi_fn(object,handles)
                default_action;
            end

            function[]=default_action()
%                 steps
%                 1 find mask
%                 2 find fiber_data
%                 3 depending on mid and whole modify fiber_data
%                 4 now plot histogram

%                 condition1=1;condition2=0;condition3=0;condition4=0;condition5=0;
%                 sub1=0;sub2=0;sub3=0;sub4=0;h1=0;h2=0;h3=0;h4=0;

                %step1 - finding mask
                if(get(roi_selection_box,'Value')~=roi_size_temp+1)
                    value=get(roi_selection_box,'value');
                    mask2=get_mask(Data,0,value);
                end
                %figure;imshow(255*uint8(mask2));
                %step2 - finding fiber_data
                size_fibers=size(matdata.data.Fa,2);
                fiber_data=[];
                for i=1:size_fibers
                    fiber_data(i,1)=i; fiber_data(i,2)=1; fiber_data(i,3)=0;
                end
                ctFIRE_length_threshold=matdata.cP.LL1;
                xls_widthfilename=fullfile(pathname,'ctFIREout',['HistWID_ctFIRE_',filename,'.csv']);
                xls_lengthfilename=fullfile(pathname,'ctFIREout',['HistLEN_ctFIRE_',filename,'.csv']);
                xls_anglefilename=fullfile(pathname,'ctFIREout',['HistANG_ctFIRE_',filename,'.csv']);
                xls_straightfilename=fullfile(pathname,'ctFIREout',['HistSTR_ctFIRE_',filename,'.csv']);
                fiber_width=csvread(xls_widthfilename);
                fiber_length=csvread(xls_lengthfilename); % no need of fiber_length - as data is entered using fiber_length_fn
                fiber_angle=csvread(xls_anglefilename);
                fiber_straight=csvread(xls_straightfilename);
                kip_length=sort(fiber_length);      kip_angle=sort(fiber_angle);        kip_width=sort(fiber_width);        kip_straight=sort(fiber_straight);
                kip_length_start=kip_length(1);   kip_angle_start=kip_angle(1,1);     kip_width_start=kip_width(1,1);     kip_straight_start=kip_straight(1,1);
                kip_length_end=kip_length(end);   kip_angle_end=kip_angle(end,1);     kip_width_end=kip_width(end,1);     kip_straight_end=kip_straight(end,1);
                count=1;
                for i=1:size_fibers
                    if(fiber_length_fn(i)<= ctFIRE_length_threshold)%YL: change from "<" to "<="  to be consistent with original ctFIRE_1
                        fiber_data(i,2)=0;
                        fiber_data(i,3)=fiber_length_fn(i);
                        fiber_data(i,4)=0;%width
                        fiber_data(i,5)=0;%angle
                        fiber_data(i,6)=0;%straight
                    else
                        fiber_data(i,2)=1;
                        fiber_data(i,3)=fiber_length_fn(i);
                        fiber_data(i,4)=fiber_width(count);
                        fiber_data(i,5)=fiber_angle(count);
                        fiber_data(i,6)=fiber_straight(count);
                        count=count+1;
                    end
                end

                %step3 - starts
                if(get(roi_selection_box,'Value')~=roi_size_temp+1)
                        if(strcmp(fiber_method,'whole')==1)
                           for i=1:size_fibers % s1 is number of fibers in image selected out of Post pro GUI
                                if (fiber_data(i,2)==1)
                                    vertex_indices=matdata.data.Fa(i).v;
                                    s2=size(vertex_indices,2);
                                    % s2 is the number of points in the ith fiber
                                    for j=1:s2
                                        x=matdata.data.Xa(vertex_indices(j),1);y=matdata.data.Xa(vertex_indices(j),2);
                                        if(mask2(y,x)==0) % here due to some reason y and x are reversed, still need to figure this out
                                            fiber_data(i,2)=0;
                                            break;
                                        end
                                    end
                                end
                            end
                       elseif(strcmp(fiber_method,'mid')==1)
                           figure(image_fig);
                           for i=1:size_fibers
                                if (fiber_data(i,2)==1)
                                    if mdEST_OP == 1 %use fiber end coordinates
                                        fsp = matdata.data.Fa(i).v(1);
                                        fep = matdata.data.Fa(i).v(end);
                                        sp = matdata.data.Xa(fep,:);  % start point
                                        ep = matdata.data.Xa(fsp,:);  % end point
                                        cen = round(mean([sp; ep]));
                                        x = cen(1);
                                        y = cen(2);
                                    elseif mdEST_OP == 2  % use fiber length
                                        %Use interpolated coordinates to estimated the fiber center
                                        vertex_indices_INT = matdata.data.Fai(i).v;
                                        s2 = size(vertex_indices_INT,2);
                                        x = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),1));
                                        y = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),2));
                                        % If [y x] is out of boundary due to interpolation,
                                        % then use the un-interpolated coordinates
                                        if x> size(IMGdata,2) || y > size(IMGdata,1)|| x < 1 || y< 1
                                            vertex_indices=matdata.data.Fa(i).v;
                                            s2=size(vertex_indices,2);
                                            x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                            y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                            fprintf('Interpolated coordinates of fiber %d is out of bounds, orignial coordinates will be used for fiber middle point estimation. \n',i)
                                            if mask(y,x)==1
                                                fprintf('This fiber is inside the ROI\n')
                                            else
                                                fprintf('This fiber is NOT inside the ROI\n')
                                            end
                                        end
                                    end
                                    if(mask2(y,x)==0) % x and y seem to be interchanged in plot
                                        fiber_data(i,2)=0;
                                    end
                                end
                            end
                       end
                    %step3- ends

                    %step 4 - plotting the histogram

                    num_visible_fibers=0;
                    for k2=1:size(fiber_data,1);
                       if(fiber_data(k2,2)==1)
                          num_visible_fibers=num_visible_fibers+1;
                       end
                    end
                    count=1;
                    length_visible_fiber_data(1:num_visible_fibers)=0;width_visible_fiber_data(1:num_visible_fibers)=0;
                    angle_visible_fiber_data(1:num_visible_fibers)=0;straightness_visible_fiber_data(1:num_visible_fibers)=0;
                    for i=1:size(fiber_data,1)
                       if(fiber_data(i,2)==1)
                           length_visible_fiber_data(count)=fiber_data(i,3);width_visible_fiber_data(count)=fiber_data(i,4);
                           angle_visible_fiber_data(count)=fiber_data(i,5);straightness_visible_fiber_data(count)=fiber_data(i,6);
                           count=count+1;
                       end
                    end
                        total_visible_fibers=count;
                       length_mean=mean(length_visible_fiber_data);width_mean=mean(width_visible_fiber_data);
                       angle_mean=mean(angle_visible_fiber_data);straightness_mean=mean(straightness_visible_fiber_data);

                       length_std=std(length_visible_fiber_data);width_std=std(width_visible_fiber_data);
                       angle_std=std(angle_visible_fiber_data);straightness_std=std(straightness_visible_fiber_data);

                       length_string = sprintf('Length = %3.1f %s %3.1f, N = %d',length_mean,char(177),length_std,total_visible_fibers-1);
                       width_string = sprintf('Width = %2.2f %s %2.2f, N = %d',width_mean,char(177),width_std,total_visible_fibers-1);
                       angle_string = sprintf('Angle = %3.1f %s %3.1f, N = %d ',angle_mean,char(177),angle_std,total_visible_fibers-1);
                       straightness_string = sprintf('Straightness = %3.2f %s %3.2f, N = %d',straightness_mean,char(177),straightness_std,total_visible_fibers-1);

                      property_value=get(property_box,'Value');
                      figure(statistics_fig);
                      bin_number=str2num(get(bin_number_box','string'));

                    if(property_value==1)
                      sub1= subplot(2,2,1);hist(length_visible_fiber_data,bin_number);title(length_string);
                      xlabel('Length[pixels]');ylabel('Frequency[#]'); axis square;%display(length_string);pause(5);
                      sub2= subplot(2,2,2);hist(width_visible_fiber_data,bin_number);title(width_string);
                      xlabel('Width[pixels]');ylabel('Frequency[#]'); axis square;%display(width_string);pause(5);
                       sub3= subplot(2,2,3);hist(angle_visible_fiber_data,bin_number);title(angle_string);
                       xlabel('Angle[Degrees]');ylabel('Frequency[#]'); axis square;%display(angle_string);pause(5);
                       sub4= subplot(2,2,4);hist(straightness_visible_fiber_data,bin_number);title(straightness_string);
                       xlabel('Straightness[-]');ylabel('Frequency[#]'); axis square;%display(straightness_string);pause(5);

                    elseif(property_value==2)
                        plot2=subplot(1,1,1);hist(length_visible_fiber_data,bin_number);title(length_string);
                        xlabel('Length[pixels]');ylabel('Frequency[#]'); axis square;
                    elseif(property_value==3)
                        plot3=subplot(1,1,1);hist(width_visible_fiber_data,bin_number);title(width_string);
                        xlabel('Width[pixels]');ylabel('Frequency[#]'); axis square;
                    elseif(property_value==4)
                        plot4=subplot(1,1,1);hist(angle_visible_fiber_data,bin_number);title(angle_string);
                        xlabel('Angle[Degrees]');ylabel('Frequency[#]'); axis square;
                    elseif(property_value==5)
                        plot5=subplot(1,1,1);hist(straightness_visible_fiber_data,bin_number);title(straightness_string);
                        xlabel('Straightness[-]');ylabel('Frequency[#]'); axis square;
                    end
                elseif(get(roi_selection_box,'Value')==roi_size_temp+1)

                end
            end
        end

        function[]=more_settings_fn2(object,handles)
            set(status_message,'string','Select sources of fibers and/or fiber selection function.');
            relative_horz_displacement_settings=30;
            settings_position_vector=[50+round(SW2/5*1.5)+relative_horz_displacement_settings SH-190 260 160];
            settings_fig = figure('Resize','off','Units','pixels','Position',settings_position_vector,'Visible','on','MenuBar','none','name','Settings','NumberTitle','off','UserData',0,'Color',defaultBackground);
            fiber_data_source_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0 0.8 0.45 0.2],'String','Source of fibers');
            fiber_data_source_box=uicontrol('Parent',settings_fig,'Enable','on','Style','popupmenu','Tag','Fiber Data Location','Units','normalized','Position',[0 0.6 0.45 0.2],'String',{'CT-FIRE Fiber Data','Post Processing Fiber Data'},'Callback',@fiber_data_location_fn,'FontUnits','normalized');
            roi_method_define_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0.5 0.8 0.45 0.2],'String','Fiber Selection Method');
            roi_method_define_box=uicontrol('Parent',settings_fig,'Enable','on','Style','popupmenu','Units','normalized','Position',[0.5 0.6 0.45 0.2],'String',{'Midpoint','Entire Fiber'},'Callback',@roi_method_define_fn,'FontUnits','normalized');

            q=0.05;b=0.05;
            ctFIRE_thresh_text=uicontrol('Parent',settings_fig,'Enable','on','Style','pushbutton','Units','normalized','Position',[0.01 0.40 0.3 0.08+b],'String','CT-FIRE Thresh','Callback',@ctFIRE_thresh_fn);
            manual_thresh_text=uicontrol('Parent',settings_fig,'Enable','on','Style','pushbutton','Units','normalized','Position',[0.33 0.40 0.3 0.08+b],'String','Manual Thresh','Callback',@manual_thresh_fn);
            auto_thresh_text=uicontrol('Parent',settings_fig,'Enable','on','Style','pushbutton','Units','normalized','Position',[0.66 0.40 0.3 0.08+b],'String','Auto Thresh','Callback',@auto_thresh_fn);

            thresh_value=uicontrol('Parent',settings_fig,'Enable','on','Style','edit','Units','normalized','Position',[0.01 0.25 0.98 0.08+b],'String',num2str(SHG_threshold),'Background',[1 1 1]);

            ok_box=uicontrol('Parent',settings_fig,'Enable','on','Style','pushbutton','Units','normalized','Position',[0.11 0.01 0.25 0.08+b],'String','OK','Callback',@ok_fn);

            if(strcmp(fiber_source,'ctFIRE')==1)
                set(fiber_data_source_box,'Value',1);
            elseif(strcmp(fiber_source,'postPRO')==1)
                set(fiber_data_source_box,'Value',2);
            end

            if(strcmp(fiber_method,'mid')==1)
                set(roi_method_define_box,'Value',1);
            elseif(strcmp(fiber_method,'whole')==1)
                set(roi_method_define_box,'Value',2);
            end

            function[]=ctFIRE_thresh_fn(object,handles)
                set(thresh_value,'String',num2str(matdata.ctfP.value.thresh_im2));
                set(ctFIRE_thresh_text,'Background',[1 0.8 0.8]);
                set([manual_thresh_text,auto_thresh_text],'Background',get(0,'DefaultUicontrolBackgroundColor'));

            end

            function[]=manual_thresh_fn(object,handles)
                set(thresh_value,'String','Enter Value');
                set(manual_thresh_text,'Background',[1 0.8 0.8]);
                set([ctFIRE_thresh_text,auto_thresh_text],'Background',get(0,'DefaultUicontrolBackgroundColor'));
            end

            function[]=auto_thresh_fn(object,handles)
                set(auto_thresh_text,'Background',[1 0.8 0.8]);
                set([manual_thresh_text,ctFIRE_thresh_text],'Background',get(0,'DefaultUicontrolBackgroundColor'));
                names=fieldnames(separate_rois);
                final_string='';
                for k=1:size(names,1)
                    enclosing_rect=separate_rois.(names{cell_selection_data(k),1}).enclosing_rect;
                    im_sub=IMGdata(enclosing_rect(1):enclosing_rect(3),enclosing_rect(2):enclosing_rect(4));
                    SHG_thresholdForDisplay=graythresh(im_sub)*255;
                    final_string=[final_string,num2str(SHG_thresholdForDisplay),','];
                end
                final_string=final_string(1:end-1);
                set(thresh_value,'String',final_string);
            end

            function[]=ok_fn(object,handles)
                if(~isnan(str2double(get(thresh_value,'string'))))
                    SHG_threshold=str2double(get(thresh_value,'string'));
                else
                    set(status_message,'String','Invalid input for SHG threshold.');
                end
                close(settings_fig);
            end

            function[]=roi_method_define_fn(object,handles)
                if(get(object,'Value')==1)
                    fiber_method='mid';
                elseif(get(object,'Value')==2)
                    fiber_method='whole';
                end
            end

            function[]=fiber_data_location_fn(object,handles)
                if(get(object,'Value')==1)
                    fiber_source='ctFIRE';
                elseif(get(object,'Value')==2)
                    fiber_source='postPRO';
                end
            end

        end

        function[]=automatic_roi_fn(object,handles)
            % Asks the user for fiber property for fiber and finds the ROI of
            % size window_size*window_size where the average value of the
            % property is maximized

            %default values
            property='length';window_size=100;
            use_defined_rois=0;% 1 if we want to compare only the defined ROIs and 0 if we want to see the use square ROIs ofdefined size
            position_vector=[50+round(SW2/5*1.5)+50 SH-260 260 90];
            pop_up_window= figure('Resize','off','Units','pixels','Position',position_vector,'Visible','on','MenuBar','none','name','Settings','NumberTitle','off','UserData',0,'Color',defaultBackground);
            property_message=uicontrol('Parent',pop_up_window,'Enable','on','Style','text','Units','normalized','Position',[0 0.65 0.45 0.35],'String','Choose Property');
            property_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','popupmenu','Tag','Fiber Data Location','Units','normalized','Position',[0 0.3 0.45 0.35],'String',{'Length','Width','Angle','Straightness'},'Callback',@property_select_fn,'FontUnits','normalized');
            window_size_message=uicontrol('Parent',pop_up_window,'Enable','on','Style','text','Units','normalized','Position',[0.5 0.65 0.45 0.35],'String','Enter Window Size');
            window_size_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','edit','Units','normalized','Position',[0.5 0.3 0.45 0.35],'String',num2str(window_size),'Callback',@window_size_fn,'FontUnits','normalized','BackgroundColor',[1 1 1]);
            use_defined_rois_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','checkbox','Units','normalized','Position',[0.3 0 0.65 0.25],'String','Analyze Defined ROIs','FontUnits','normalized');
            ok_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','pushbutton','String','OK','Units','normalized','Position',[0 0 0.25 0.25],'Callback',@ok_fn);

            function[]= property_select_fn(handles,Indices)
                property_index=get(property_box,'Value');
                if(property_index==1),property='length';
                elseif(property_index==2),property='width';
                elseif(property_index==3),property='angle';
                elseif(property_index==4),property='straightness';
                end
            end

            function[]=window_size_fn(object,handles)
                window_size=str2num(get(object,'String'));
            end

            function[]=ok_fn(object,handles)
                use_defined_rois=get(use_defined_rois_box,'value');
                close;
                automatic_roi_sub_fn(property,window_size);
            end

            function[]=automatic_roi_sub_fn(property,window_size)
                if(strcmp(property,'length')==1)
                    property_column=3;%property length is in the 3rd colum
                elseif(strcmp(property,'width')==1)
                    property_column=4;%4th column
                elseif(strcmp(property,'angle')==1)
                    property_column=5;%5th column
                elseif(strcmp(property,'straightness')==1)
                    property_column=6;%6th column
                end

                if(strcmp(fiber_source,'ctFIRE')==1)
                    size_fibers=size(matdata.data.Fa,2);
                    xls_widthfilename=fullfile(pathname,'ctFIREout',['HistWID_ctFIRE_',filename,'.csv']);
                    %                     xls_lengthfilename=fullfile(pathname,'ctFIREout',['HistLEN_ctFIRE_',filename,'.csv']);
                    xls_anglefilename=fullfile(pathname,'ctFIREout',['HistANG_ctFIRE_',filename,'.csv']);
                    xls_straightfilename=fullfile(pathname,'ctFIREout',['HistSTR_ctFIRE_',filename,'.csv']);
                    fiber_width=csvread(xls_widthfilename);
                    %                     fiber_length=csvread(xls_lengthfilename); % no need of fiber_length - as data is entered using fiber_length_fn
                    fiber_angle=csvread(xls_anglefilename);
                    fiber_straight=csvread(xls_straightfilename);
                    count=1;
                    ctFIRE_length_threshold=matdata.cP.LL1;
                    xmid_array(1:size_fibers)=0;ymid_array(1:size_fibers)=0;
                    for i=1:size_fibers
                        fiber_data2(i,1)=i;
                        if(fiber_length_fn(i)<= ctFIRE_length_threshold)%YL: change from "<" to "<="  to be consistent with original ctFIRE_1
                            fiber_data2(i,2)=0;
                            fiber_data2(i,3)=fiber_length_fn(i);
                            fiber_data2(i,4)=0;%width
                            fiber_data2(i,5)=0;%angle
                            fiber_data2(i,6)=0;%straight
                        else
                            fiber_data2(i,2)=1;
                            fiber_data2(i,3)=fiber_length_fn(i);
                            fiber_data2(i,4)=fiber_width(count);
                            fiber_data2(i,5)=fiber_angle(count);
                            fiber_data2(i,6)=fiber_straight(count);
                            count=count+1;
                        end
                        vertex_indices=matdata.data.Fa(i).v;
                        if mdEST_OP == 1 %use fiber end coordinates
                            fsp = matdata.data.Fa(i).v(1);
                            fep = matdata.data.Fa(i).v(end);
                            sp = matdata.data.Xa(fep,:);  % start point
                            ep = matdata.data.Xa(fsp,:);  % end point
                            cen = round(mean([sp; ep]));
                            xmid_array(i) = cen(1);
                            ymid_array(i) = cen(2);
                        elseif mdEST_OP == 2  % use fiber length
                            vertex_indices_INT = matdata.data.Fai(i).v;
                            s2=size(vertex_indices_INT,2);
                            xmid_array(i) = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),1));
                            ymid_array(i) = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),2));
                            % If [y x] is out of boundary due to interpolation,
                            % then use the un-interpolated coordinates
                            if xmid_array(i)> size(IMGdata,2) || ymid_array(i) > size(IMGdata,1)|| xmid_array(i) < 1 || ymid_array(i)< 1
                                vertex_indices=matdata.data.Fa(i).v;
                                s2=size(vertex_indices,2);
                                xmid_array(i) = matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                ymid_array(i) = matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                fprintf('Interpolated coordinates of fiber %d is out of bounds, orignial coordinates will be used for fiber middle point estimation. \n',i)
                            end
                        end
                    end

                elseif(strcmp(fiber_source,'postPRO')==1)
                    if(isfield(matdata.data,'PostProGUI')&&isfield(matdata.data.PostProGUI,'fiber_indices'))
                        fiber_data2=matdata.data.PostProGUI.fiber_indices;
                        size_fibers=size(fiber_data2,1);
                        xmid_array(1:size_fibers)=0;ymid_array(1:size_fibers)=0;
                        for i=1:size_fibers
                            vertex_indices=matdata.data.Fa(i).v;
                            if mdEST_OP == 1 %use fiber end coordinates
                                fsp = matdata.data.Fa(i).v(1);
                                fep = matdata.data.Fa(i).v(end);
                                sp = matdata.data.Xa(fep,:);  % start point
                                ep = matdata.data.Xa(fsp,:);  % end point
                                cen = round(mean([sp; ep]));
                                xmid_array(i) = cen(1);
                                ymid_array(i) = cen(2);
                            elseif mdEST_OP == 2  % use fiber length
                                vertex_indices_INT = matdata.data.Fai(i).v;
                                s2=size(vertex_indices_INT,2);
                                xmid_array(i) = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),1));
                                ymid_array(i) = round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),2));
                                %fprintf('fiber number=%d xmid=%d ymid=%d \n',i,xmid_array(i),ymid_array(i));
                                % If [y x] is out of boundary due to interpolation,
                                % then use the un-interpolated coordinates
                                if xmid_array(i)> size(IMGdata,2) || ymid_array(i) > size(IMGdata,1)|| xmid_array(i) < 1 || ymid_array(i)< 1
                                    vertex_indices=matdata.data.Fa(i).v;
                                    s2=size(vertex_indices,2);
                                    xmid_array(i) = matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                    ymid_array(i) = matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                    fprintf('Interpolated coordinates of fiber %d is out of bounds, orignial coordinates will be used for fiber middle point estimation. \n',i)
                                end
                            end

                        end
                    else
                        set(status_message,'String','Post Processing Data not present.');
                    end
                end
                max=0;min=Inf;x_max=1;y_max=1;x_min=1;y_min=1;
                s1 = size(IMGdata,1);
                s2 = size(IMGdata,2);
                if(use_defined_rois==0)% not using previously defined ROIs
                    first_window_fit=0;
                    for i=1:size_fibers
                        if(xmid_array(i)<floor(window_size/2)||ymid_array(i)<floor(window_size/2)||xmid_array(i)>s1-floor(window_size/2)||ymid_array(i)>s2-floor(window_size/2))
                            continue;%that is if the window would not fit on the fiber location without going over the boundary
                        else
                            if(first_window_fit==0)
                                max=0;min=Inf;x_max=xmid_array(i);y_max=ymid_array(i);
                                first_window_fit=1;% flag for first entry here
                            end
                            x_window=xmid_array(i);
                            y_window=ymid_array(i);
                            count=0;parameter=0;
                            for j=1:size_fibers
                                if(fiber_data2(j,2)==1&&xmid_array(j)>=x_window-floor(window_size/2)&&xmid_array(j)<=x_window+floor(window_size/2)&&ymid_array(j)>=y_window-floor(window_size/2)&&ymid_array(j)<=y_window+floor(window_size/2))
                                    % determining that the fiber is within the window
                                    parameter=parameter+fiber_data2(j,property_column);
                                    count=count+1;
                                end
                            end
                            if(count>0&&parameter/(count)>max)
                                max=parameter/count;x_max=xmid_array(i);y_max=ymid_array(i);
                            end
                        end
                    end

                    a=x_max;b=y_max;
                    vertices=[a,b;a+window_size,b;a+window_size,b+window_size;a,b+window_size];
                    BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                    [xm,ym]=midpoint_fn(BW); % center posiion of the mask
                    figure(image_fig);hold on;
                    vertices(end+1,:) = vertices(1,:);
                    boundary = vertices;
                    plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%yl
                    INDtext = {'MaxLength','MaxWidth','MaxAngle','MaxStraightness'};
                    fieldname = INDtext{property_column-2};
                    figure(image_fig);text(xm,ym,fieldname,'HorizontalAlignment','center','Color',[1 1 0]);
                    hold off
%                     B={BW};%forming a new ROI - needed
 %                     for k2 = 1:length(B)
%                         boundary = B{k2};
%                         plot(boundary(:,2), boundary(:,1), 'y-', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
%                     end
                    separate_rois.(fieldname).roi=[a,b,window_size,window_size];
                    c=clock;fix(c);
                    date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
                    separate_rois.(fieldname).date=date;
                    time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
                    separate_rois.(fieldname).time=time;
                    separate_rois.(fieldname).shape=1;
                    separate_rois.(fieldname).xm=ym;  % x,y switched in the image, need to keep consistent everywhere
                    separate_rois.(fieldname).ym=xm;
                    separate_rois.(fieldname).enclosing_rect=[a,b,a+window_size,b+window_size];
                    separate_rois.(fieldname).boundary={vertices};
                    save(fullfile(ROImanDir,[filename,'_ROIs.mat']),'separate_rois','-append');
                    update_rois;
                elseif(use_defined_rois==1)
                    % only for simple ROIs and not combined ROIs
                    % finding ROI with max avg property value

                    Data=get(roi_table,'Data');
                    % Running loop for all ROIs
                    for k=1:size(Data,1)
                        if iscell(separate_rois.(Data{k,1}).shape)
                           disp('Combined ROI cannot be compared.')
                           return
                        end
                        vertices = fliplr(separate_rois.(Data{k,1}).boundary{1});
                        BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));

                        if(k==1)
                            max=0;
                            vertices_max=vertices;
                        end
                        parameter=0;count=0;
                        for i=1:size_fibers
                            if(BW(ymid_array(i),xmid_array(i)))
                                parameter=parameter+fiber_data2(i,property_column);
                                count=count+1;
                            end
                            if(count>0)%calculating parameter only when count>0
                                if(parameter/count>max)
                                    max=parameter/count;
                                    vertices_max=vertices;
                                end
                            end
                        end

                    end
                    BW=roipoly(IMGdata,vertices_max(:,1),vertices_max(:,2));
%                      B=bwboundaries(BW);
                      vertices_max(end+1,:) = vertices_max(1,:);
                      boundary = vertices_max;
                      figure(image_fig);hold on
                      plot(boundary(:,1), boundary(:,2), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                      hold off
                      %                     B=separate_rois.(Data{k,1}).boundary;
%                     figure(image_fig);
%                     for k2 = 1:length(B)
%                         boundary = B{k2};
%                         plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
%                     end
                    % finding the position to write the text
                    x_text=0;y_text=0;count=1;
                    for i=1:s1
                        for j=1:s2
                            if(BW(i,j))
                                x_text=x_text+i;
                                y_text=y_text+j;
                                count=count+1;
                            end
                        end
                    end
                    x_text=x_text/(count-1);y_text=y_text/(count-1);

                    if(property_column==3)
                        figure(image_fig);text(y_text,x_text,'Max length','Color',[1 1 0],'HorizontalAlignment','center');
                    elseif(property_column==4)
                        figure(image_fig);text(y_text,x_text,'Max Width','Color',[1 1 0],'HorizontalAlignment','center');
                    elseif(property_column==5)
                        figure(image_fig);text(y_text,x_text,'Max Angle','Color',[1 1 0],'HorizontalAlignment','center');
                    elseif(property_column==6)
                        figure(image_fig);text(y_text,x_text,'Max Straightness','Color',[1 1 0],'HorizontalAlignment','center');
                    end
                end
                function[length]=fiber_length_fn(fiber_index)
                    length=0;
                    vertex_indices=matdata.data.Fa(1,fiber_index).v;
                    s12=size(vertex_indices,2);
                    for i2=1:s12-1
                        x1=matdata.data.Xa(vertex_indices(i2),1);y1=matdata.data.Xa(vertex_indices(i2),2);
                        x2=matdata.data.Xa(vertex_indices(i2+1),1);y2=matdata.data.Xa(vertex_indices(i2+1),2);
                        length=length+cartesian_distance(x1,y1,x2,y2);
                    end
                end
            end

        end

        function[]=generate_stats_fn(object,handles)

            set(status_message,'String','Generating Stats. Please Wait...'); drawnow;
            D=[];% D contains the file data
            disp_data=[];% used in pop up %display
            %format of D - contains 9 sheets - all raw data, raw
            %data of l,w,a and s, stats of l,w,a and s
            fig_temp3 = findobj(0,'Name','Summary Statistics-CTF ROI Manager');
            if isempty(fig_temp3)
               close(fig_temp3)
            end
            measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 470 300],...
                'Visible','off','MenuBar','none','name','Summary Statistics-CTF ROI Manager','NumberTitle','off','UserData',0);
            measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
            s3=size(cell_selection_data,1);
            s1 = size(IMGdata,1);
            s2 = size(IMGdata,2);
            names=fieldnames(separate_rois);
            Data=names;
            BW=logical(zeros(s1,s2));
            %reading files
            ctFIRE_length_threshold=matdata.cP.LL1;
            xls_widthfilename=fullfile(pathname,'ctFIREout',['HistWID_ctFIRE_',filename,'.csv']);
            xls_lengthfilename=fullfile(pathname,'ctFIREout',['HistLEN_ctFIRE_',filename,'.csv']);
            xls_anglefilename=fullfile(pathname,'ctFIREout',['HistANG_ctFIRE_',filename,'.csv']);
            xls_straightfilename=fullfile(pathname,'ctFIREout',['HistSTR_ctFIRE_',filename,'.csv']);
            fiber_width=csvread(xls_widthfilename);
            fiber_length=csvread(xls_lengthfilename); % no need of fiber_length - as data is entered using fiber_length_fn
            fiber_angle=csvread(xls_anglefilename);
            fiber_straight=csvread(xls_straightfilename);
            kip_length=sort(fiber_length);      kip_angle=sort(fiber_angle);        kip_width=sort(fiber_width);        kip_straight=sort(fiber_straight);
            size_fibers=size(matdata.data.Fa,2);

            for k=1:s3
                fiber_data2 = []; % initialize
                if(iscell(separate_rois.(names{cell_selection_data(k),1}).shape)==0)
                    vertices= fliplr(separate_rois.(Data{cell_selection_data(k,1),1}).boundary{1});
                    BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                    enclosing_rect=separate_rois.(names{cell_selection_data(k),1}).enclosing_rect;
                    % display(enclosing_rect);
                    if(SHG_threshold_method==1)
                        im_sub=IMGdata(enclosing_rect(1):enclosing_rect(3),enclosing_rect(2):enclosing_rect(4));
                        %figure;imshow(im_sub);
                        SHG_threshold=graythresh(im_sub)*255;
                        %display(SHG_threshold);
                        %pause(5);
                    elseif(SHG_threshold_method==0)

                    end
                elseif(iscell(separate_rois.(names{cell_selection_data(k),1}).shape)==1)
                    s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                    %display(s_subcomps);
                    s1=size(IMGdata,1);s2=size(IMGdata,2);
                    for a=1:s1
                        for b=1:s2
                            mask2(a,b)=logical(0);
                        end
                    end
                    for p=1:s_subcomps
                        vertices = fliplr(separate_rois.(Data{cell_selection_data(k,1),1}).boundary{1,p}{1});
                        BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                        mask2=mask2|BW;
                    end
                    BW=mask2;
                end
                count=1;
                for i=1:size_fibers
                    if(fiber_length_fn(i)<= ctFIRE_length_threshold)%YL: change from "<" to "<="  to be consistent with original ctFIRE_1
                        fiber_data2(i,2)=0;
                        fiber_data2(i,3)=fiber_length_fn(i);
                        fiber_data2(i,4)=0;%width
                        fiber_data2(i,5)=0;%angle
                        fiber_data2(i,6)=0;%straight
                    else
                        fiber_data2(i,2)=1;
                        fiber_data2(i,3)=fiber_length_fn(i);
                        fiber_data2(i,4)=fiber_width(count);
                        fiber_data2(i,5)=fiber_angle(count);
                        fiber_data2(i,6)=fiber_straight(count);
                        count=count+1;
                    end
                end

                %fillinf the D
                count=1;
                if(strcmp(fiber_method,'whole')==1)
                    for i=1:size_fibers % s1 is number of fibers in image selected out of Post pro GUI
                        if (fiber_data2(i,2)==1)
                            vertex_indices=matdata.data.Fa(i).v;
                            s2=size(vertex_indices,2);
                            for j=1:s2
                                x=matdata.data.Xa(vertex_indices(j),1);y=matdata.data.Xa(vertex_indices(j),2);
                                if(BW(y,x)==logical(0)) % here due to some reason y and x are reversed, still need to figure this out
                                    fiber_data2(i,2)=0;
                                    break;
                                end
                            end
                        end
                    end
                elseif(strcmp(fiber_method,'mid')==1)
                    figure(image_fig);
                    for i=1:size_fibers
                        if (fiber_data2(i,2)==1)
                            if mdEST_OP == 1 %use fiber end coordinates
                                fsp = matdata.data.Fa(i).v(1);
                                fep = matdata.data.Fa(i).v(end);
                                sp = matdata.data.Xa(fep,:);  % start point
                                ep = matdata.data.Xa(fsp,:);  % end point
                                cen = round(mean([sp; ep]));
                                x = cen(1);
                                y = cen(2);
                            elseif mdEST_OP == 2  % use fiber length
                                vertex_indices_INT = matdata.data.Fai(i).v;
                                s2=size(vertex_indices_INT,2);
                                x=round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),1));
                                y=round(matdata.data.Xai(vertex_indices_INT(round(s2/2)),2));
                                % If [y x] is out of boundary due to interpolation,
                                % then use the un-interpolated coordinates
                                if x> size(IMGdata,2) || y > size(IMGdata,1)|| x < 1 || y< 1
                                    vertex_indices=matdata.data.Fa(i).v;
                                    s2=size(vertex_indices,2);
                                    x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                    y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                    fprintf('Interpolated coordinates of fiber %d is out of bounds, orignial coordinates will be used for fiber middle point estimation. \n',i)
                                    if mask(y,x)==1
                                        fprintf('This fiber is inside the ROI\n')
                                    else
                                        fprintf('This fiber is NOT inside the ROI\n')
                                    end
                                end
                            end

                            if(BW(y,x)==logical(1)) % x and y seem to be interchanged in plot
                                % function.
                            else
                                fiber_data2(i,2)=0;
                            end
                        end
                    end
                end

                if(k==1)
                    D{2,1,10}='SHG pixels';
                    D{3,1,10}='Total pixels';
                    D{4,1,10}='SHG Ratio';
                    D{5,1,10}='SHG Threshold used';
                    D{6,1,10}='SHG Threshold type';

                    D{2,1,1}='Median';
                    D{3,1,1}='Mode';
                    D{4,1,1}='Mean';
                    D{5,1,1}='Variance';
                    D{6,1,1}='Standard Deviation';
                    D{7,1,1}='Min';
                    D{8,1,1}='Max';
                    D{9,1,1}='Number of fibers';
                    D{10,1,1}='Alignment';

                    D{2,1,2}='Median';
                    D{3,1,2}='Mode';
                    D{4,1,2}='Mean';
                    D{5,1,2}='Variance';
                    D{6,1,2}='Standard Deviation';
                    D{7,1,2}='Min';
                    D{8,1,2}='Max';
                    D{9,1,2}='Number of fibers';
                    D{10,1,2}='Alignment';

                    D{2,1,3}='Median';
                    D{3,1,3}='Mode';
                    D{4,1,3}='Mean';
                    D{5,1,3}='Variance';
                    D{6,1,3}='Standard Deviation';
                    D{7,1,3}='Min';
                    D{8,1,3}='Max';
                    D{9,1,3}='Number of fibers';
                    D{10,1,3}='Alignment';

                    D{2,1,4}='Median';
                    D{3,1,4}='Mode';
                    D{4,1,4}='Mean';
                    D{5,1,4}='Variance';
                    D{6,1,4}='Standard Deviation';
                    D{7,1,4}='Min';
                    D{8,1,4}='Max';
                    D{9,1,4}='Number of fibers';
                    D{10,1,4}='Alignment';

                    disp_data{1,1}='Length';             disp_data{1,s3+2}='Width';          disp_data{1,2*s3+3}='Angle';                    disp_data{1,3*s3+4}='Straightness';
                    disp_data{3,1}='Median';             disp_data{3,s3+2}='Median';         disp_data{3,2*s3+3}='Median';                   disp_data{3,3*s3+4}='Median';
                    disp_data{4,1}='Mode';               disp_data{4,s3+2}='Mode';           disp_data{4,2*s3+3}='Mode';                     disp_data{4,3*s3+4}='Mode';
                    disp_data{5,1}='Mean';               disp_data{5,s3+2}='Mean';           disp_data{5,2*s3+3}='Mean';                     disp_data{5,3*s3+4}='Mean';
                    disp_data{6,1}='Variance';           disp_data{6,s3+2}='Variance';       disp_data{6,2*s3+3}='Variance';                 disp_data{6,3*s3+4}='Variance';
                    disp_data{7,1}='Standard Dev';       disp_data{7,s3+2}='Standard Dev';   disp_data{7,2*s3+3}='Standard Dev';             disp_data{7,3*s3+4}='Standard Dev';
                    disp_data{8,1}='Min';                disp_data{8,s3+2}='Min';            disp_data{8,2*s3+3}='Min';                      disp_data{8,3*s3+4}='Min';
                    disp_data{9,1}='Max';                disp_data{9,s3+2}='Max';            disp_data{9,2*s3+3}='Max';                      disp_data{9,3*s3+4}='Max';
                    disp_data{10,1}='Number of fibers';  disp_data{10,s3+2}='Number of fibers';disp_data{10,2*s3+3}='Number of fibers';      disp_data{10,3*s3+4}='Number of fibers';
                    disp_data{11,1}='Alignment';         disp_data{11,s3+2}='Alignment';     disp_data{11,2*s3+3}='Alignment';               disp_data{11,3*s3+4}='Alignment';
                    disp_data{12,1}='SHG pixels';
                    disp_data{13,1}='Total pixels';
                    disp_data{14,1}='SHG ratio';
                    disp_data{15,1}='SHG Threshold used';

                end
                disp_data{2,1+k}=Data{cell_selection_data(k,1),1};
                disp_data{2,2+k+s3}=Data{cell_selection_data(k,1),1};
                disp_data{2,3+k+2*s3}=Data{cell_selection_data(k,1),1};
                disp_data{2,4+k+3*s3}=Data{cell_selection_data(k,1),1};

                D{1,k+1,1}=Data{cell_selection_data(k,1),1};
                D{1,k+1,2}=Data{cell_selection_data(k,1),1};
                D{1,k+1,3}=Data{cell_selection_data(k,1),1};
                D{1,k+1,4}=Data{cell_selection_data(k,1),1};
                D{1,5*(k-1)+1,5}=Data{cell_selection_data(k,1),1};
                D{1,k,6}=Data{cell_selection_data(k,1),1};
                D{1,k,7}=Data{cell_selection_data(k,1),1};
                D{1,k,8}=Data{cell_selection_data(k,1),1};
                D{1,k,9}=Data{cell_selection_data(k,1),1};
                D{1,k+1,10}=Data{cell_selection_data(k,1),1};

                D{2,k+1,10}=SHG_pixels(k);
                D{3,k+1,10}=total_pixels(k);
                D{4,k+1,10}=SHG_ratio(k);
                D{5,k+1,10}=SHG_threshold;
                if(SHG_threshold_method==0)
                    temp_string='Hard threshold';
                elseif(SHG_threshold_method==1)
                    temp_string='Soft threshold';
                end
                D{6,k+1,10}=temp_string;

                D{2,5*(k-1)+1,5}='fiber number';
                D{2,5*(k-1)+2,5}='length';
                D{2,5*(k-1)+3,5}='width';
                D{2,5*(k-1)+4,5}='angle';
                D{2,5*(k-1)+5,5}='straightness';
                %initialize
                data_length = [];
                data_width = [];
                data_angle = [];
                data_straightness = [];

                num_of_fibers=size(fiber_data2,1);
                count=1;
                for a=1:num_of_fibers
                    if(fiber_data2(a,2)==1)
                        data_length(count)=fiber_data2(a,3);
                        data_width(count)=fiber_data2(a,4);
                        data_angle(count)=fiber_data2(a,5);
                        data_straightness(count)=fiber_data2(a,6);
                        D{count+2,5*(k-1)+1,5}=a;
                        D{count+2,5*(k-1)+2,5}=data_length(count);
                        D{count+2,5*(k-1)+3,5}=data_width(count);
                        D{count+2,5*(k-1)+4,5}=data_angle(count);
                        D{count+2,5*(k-1)+5,5}=data_straightness(count);
                        D{count+1,k,6}=data_length(count);
                        D{count+1,k,7}=data_width(count);
                        D{count+1,k,8}=data_angle(count);
                        D{count+1,k,9}=data_straightness(count);
                        count=count+1;
                    end
                end

                for sheet=1:4
                    if(sheet==1)
                        current_data=data_length;
                    elseif(sheet==2)
                        current_data=data_width;
                    elseif(sheet==3)
                        current_data=data_angle;
                    elseif(sheet==4)
                        current_data=data_straightness;
                    end
                    D{2,k+1,sheet}=median(current_data);        disp_data{3,k+s3*(sheet-1)+sheet}=D{2,k+1,sheet};
                    D{3,k+1,sheet}=mode(current_data);          disp_data{4,k+s3*(sheet-1)+sheet}=D{3,k+1,sheet};
                    D{4,k+1,sheet}=mean(current_data);          disp_data{5,k+s3*(sheet-1)+sheet}=D{4,k+1,sheet};
                    D{5,k+1,sheet}=var(current_data);           disp_data{6,k+s3*(sheet-1)+sheet}=D{5,k+1,sheet};
                    D{6,k+1,sheet}=std(current_data);           disp_data{7,k+s3*(sheet-1)+sheet}=D{6,k+1,sheet};
                    D{7,k+1,sheet}=min(current_data);           disp_data{8,k+s3*(sheet-1)+sheet}=D{7,k+1,sheet};
                    D{8,k+1,sheet}=max(current_data);           disp_data{9,k+s3*(sheet-1)+sheet}=D{8,k+1,sheet};
                    D{9,k+1,sheet}=count-1;                     disp_data{10,k+s3*(sheet-1)+sheet}=D{9,k+1,sheet};
                    D{10,k+1,sheet}=0;                          disp_data{11,k+s3*(sheet-1)+sheet}=D{10,k+1,sheet};
                    disp_data{12,k+s3*(sheet-1)+sheet}=SHG_pixels(k);
                    disp_data{13,k+s3*(sheet-1)+sheet}=total_pixels(k);
                    disp_data{14,k+s3*(sheet-1)+sheet}=SHG_ratio(k);
                    disp_data{15,k+s3*(sheet-1)+sheet}=SHG_threshold;
                end


            end  % end of k
            a1=size(cell_selection_data,1);
            operations='';
            for d=1:a1
                operations=[operations '_' Data{cell_selection_data(d,1),1}];
            end

            if ~exist(ROIpostIndOutDir,'dir')
                mkdir(ROIpostIndOutDir);
            end
            try
                operations = [operations '.xlsx'];
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,1),'Length Stats');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,2),'Width Stats');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,3),'Angle Stats');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,4),'Straightness Stats');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,5),'Raw Data');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,6),'Raw Length Data');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,7),'Raw Width Data');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,8),'Raw Angle Data');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,9),'Raw Straightness Data');
                xlswrite(fullfile(ROIpostIndOutDir,[filename,operations ]),D(:,:,10),'SHG Percentages Data');
            catch
                operations = [operations '.xlsx'];
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,1),'Length Stats');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,2),'Width Stats');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,3),'Angle Stats');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,4),'Straightness Stats');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,5),'Raw Data');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,6),'Raw Length Data');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,7),'Raw Width Data');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,8),'Raw Angle Data');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,9),'Raw Straightness Data');
                xlwrite(fullfile(ROIpostIndOutDir,[filename,operations] ),D(:,:,10),'SHG Percentages Data');
            end

            set(measure_table,'Data',disp_data);
            set(measure_fig,'Visible','on');
            set(generate_stats_box2,'Enable','off');% because the user must press check Fibers button again to get the newly defined fibers
            set(status_message,'String',sprintf('Stats file %s generated and saved in %s', [filename, operations], ROIpostIndOutDir));
            %         set(status_message,'BackgroundColor',[1,1,1]);

        end
        %analyzer functions- end

        function[length]=fiber_length_fn(fiber_index)
            length=0;
            vertex_indices=matdata.data.Fa(1,fiber_index).v;
            s1=size(vertex_indices,2);
            for i=1:s1-1
                x1=matdata.data.Xa(vertex_indices(i),1);y1=matdata.data.Xa(vertex_indices(i),2);
                x2=matdata.data.Xa(vertex_indices(i+1),1);y2=matdata.data.Xa(vertex_indices(i+1),2);
                length=length+cartesian_distance(x1,y1,x2,y2);
            end
        end

        function [dist]=cartesian_distance(x1,y1,x2,y2)
            dist=sqrt((x1-x2)^2+(y1-y2)^2);
        end

        function []=plot_fibers(fiber_data,fig_name,pause_duration,print_fiber_numbers)
            a=matdata;
            figure(fig_name);
            for i=1:size(a.data.Fa,2)
                if fiber_data(i,2)==1
                    point_indices=a.data.Fa(1,fiber_data(i,1)).v;
                    s1=size(point_indices,2);
                    x_cord=[];y_cord=[];
                    for j=1:s1
                        x_cord(j)=a.data.Xa(point_indices(j),1);
                        y_cord(j)=a.data.Xa(point_indices(j),2);
                    end
                    color1 = clrr2(i,1:3); % YL: fix the color of each fiber
                    plot(x_cord,y_cord,'LineStyle','-','color',color1,'LineWidth',1);hold on;
                    if(print_fiber_numbers==1)
                        %%YL show the fiber label from the left ending point,
                        shftx = 5;   % shift the text position to avoid the image edge
                        bndd = 10;   % distance from boundary
                        if x_cord(end) < x_cord(1)

                            if x_cord(s1)< bndd
                                text(x_cord(s1)+shftx,y_cord(s1),num2str(fiber_data(i,1)),'HorizontalAlignment','center','color',color1);
                            else
                                text(x_cord(s1),y_cord(s1),num2str(fiber_data(i,1)),'HorizontalAlignment','center','color',color1);
                            end
                        else
                            if x_cord(1)< bndd
                                text(x_cord(1)+shftx,y_cord(1),num2str(i),'HorizontalAlignment','center','color',color1);
                            else
                                text(x_cord(1),y_cord(1),num2str(i),'HorizontalAlignment','center','color',color1);
                            end
                        end
                    end
                end
            end
        end

        function []=visualisation(handles,indices)
            %plots the fibers with colors mapped to fiber properties, four
            %figures are plotted- one each for length,width ,angle and
            %straighteness
            % idea conceived by Prashant Mittal
            % implemented by Guneet Singh Mehta and Prashant Mittal
            print_fiber_numbers=1;
            a=matdata;
            orignal_image=IMGdata;
            gray123(:,:,1)=orignal_image(:,:,1);
            gray123(:,:,2)=orignal_image(:,:,2);
            gray123(:,:,3)=orignal_image(:,:,3);

            %T_map=[0 0 0.5;0 0.5 0;0.5 0 0;1 0 0.5;1 0.5 0;0 1 0.5;0.5 1
            %0;0.5 0 1];%Other good Map
            T_map=[1 0.6 0.2;0 0 1;0 1 0;1 0 0;1 1 0;1 0 1;0 1 1;0.2 0.4 0.8];

            for k2=1:255 %maps gray intensity to colors
                if(k2<floor(255/8)&&k2>=1)
                    map(k2,:)=T_map(1,:);
                elseif(k2<floor(2*255/8)&&k2>=floor(255/8))
                    map(k2,:)=T_map(2,:);
                elseif(k2<floor(3*255/8)&&k2>=(2*255/8))
                    map(k2,:)=T_map(3,:);
                elseif(k2<floor(4*255/8)&&k2>=(3*255/8))
                    map(k2,:)=T_map(4,:);
                elseif(k2<floor(5*255/8)&&k2>=(4*255/8))
                    map(k2,:)=T_map(5,:);
                elseif(k2<floor(6*255/8)&&k2>=(5*255/8))
                    map(k2,:)=T_map(6,:);
                elseif(k2<floor(7*255/8)&&k2>=(6*255/8))
                    map(k2,:)=T_map(7,:);
                elseif(k2<floor(255)&&k2>=(7*255/8))
                    map(k2,:)=T_map(8,:);
                end
            end
            colormap(map);%hsv is also good
            colors=colormap;
            size_colors=size(colors,1);
            fig_temp4 = findobj(0,'Name','Visulation of Fiber Metrics in ROI-CTF');
            if ~isempty(fig_temp4)
               close(fig_temp4);
            end
          %use tab group to dock figures as the direct dock does not work for compiled application now
            hfiber_visulz = figure('name','Visulation of Fiber Metrics in ROI-CTF','WindowStyle','normal',...
                'Units','pixels','Position',[round(0.34*SW2+0.474*SH) round(0.05*SH) round(0.474*SH) round(0.474*SH)],...
                'Visible','on','NumberTitle','off');
            htabgroup = uitabgroup(hfiber_visulz);
            tabfig_length = uitab(htabgroup, 'Title', 'Length');
            hax1 = axes('Parent', tabfig_length);
            imshow(gray123,'Parent',hax1);colormap(map);colorbar;hold on;
            set(hax1,'Position',[0.02 0.06 0.84 0.84]);
            tabfig_width = uitab(htabgroup, 'Title', 'Width');
            hax2 = axes('Parent', tabfig_width);
            imshow(gray123,'Parent',hax2);colormap(map);colorbar;hold on;
            set(hax2,'Position',[0.02 0.06 0.84 0.84])
            tabfig_angle = uitab(htabgroup, 'Title', 'Angle');
            hax3 = axes('Parent', tabfig_angle);
            imshow(gray123,'Parent',hax3);colormap(map);colorbar;hold on;
            set(hax3,'Position',[0.02 0.06 0.84 0.84])
            tabfig_straightness = uitab(htabgroup, 'Title', 'Straightness');
            hax4 = axes('Parent', tabfig_straightness);
            imshow(gray123,'Parent',hax4);colormap(map);colorbar;hold on;
            set(hax4,'Position',[0.02 0.06 0.84 0.84])
%             fig_width=figure;set(fig_width,'Visible','off','name','Width Visualisation');imshow(gray123,'Border','tight');colorbar;colormap(map);hold on;
%             fig_angle=figure;set(fig_angle,'Visible','off','name','Angle Visualisation');imshow(gray123,'Border','tight');colorbar;colormap(map);hold on;
%             fig_straightness=figure;set(fig_straightness,'Visible','off','name','Straightness Visualisation');imshow(gray123,'Border','tight');colorbar;colormap(map);hold on;

            flag_temp=0;%flag for first fiber to satisfy properties
            %finding max and min of each property
            for i=1:size(a.data.Fa,2)
                if(fiber_data(i,2)==1)
                    if(flag_temp==0)
                        max_l=fiber_data(i,3);max_w=fiber_data(i,4);max_a=fiber_data(i,5);max_s=fiber_data(i,6);
                        min_l=fiber_data(i,3);min_w=fiber_data(i,4);min_a=fiber_data(i,5);min_s=fiber_data(i,6);
                        flag_temp=1;
                    end
                    if(fiber_data(i,3)>max_l),max_l=fiber_data(i,3);end
                    if(fiber_data(i,3)<min_l),min_l=fiber_data(i,3);end

                    if(fiber_data(i,4)>max_w),max_w=fiber_data(i,4);end
                    if(fiber_data(i,4)<min_w),min_w=fiber_data(i,4);end

                    if(fiber_data(i,5)>max_a),max_a=fiber_data(i,5);end
                    if(fiber_data(i,5)<min_a),min_a=fiber_data(i,5);end

                    if(fiber_data(i,6)>max_s),max_s=fiber_data(i,6);end
                    if(fiber_data(i,6)<min_s),min_s=fiber_data(i,6);end
                end
            end
            max_a=180;min_a=0;

            %division of each Property
            jump_l=(max_l-min_l)/8;
            jump_w=(max_w-min_w)/8;
            jump_a=(max_a-min_a)/8;
            jump_s=(max_s-min_s)/8;
            for i=1:9
                % floor is used only in length and angle because differences in
                % width and straightness are in decimal places
                ytick_l(i)=floor(size_colors*(i-1)*jump_l/(max_l-min_l));
                ytick_label_l{i}=num2str(round(floor(min_l+(i-1)*jump_l)*100)/100);

                ytick_w(i)=size_colors*(i-1)*jump_w/(max_w-min_w);
                ytick_label_w{i}=num2str(round(100*(min_w+(i-1)*jump_w))/100);

                ytick_a(i)=floor(size_colors*(i-1)*jump_a/(max_a-min_a));
                ytick_label_a{i}=num2str(round(100*(min_a+(i-1)*jump_a))/100);

                ytick_s(i)=size_colors*(i-1)*jump_s/(max_s-min_s);
                ytick_label_s{i}=num2str(round(100*(min_s+(i-1)*jump_s))/100);
            end
            ytick_l(9)=252;
            ytick_w(9)=252;
            ytick_a(9)=252;
            ytick_s(9)=252;
            rng(1001) ;

            %plotting fibers on figures
            for k=1:4
                if(k==1)
                    axes(hax1)
                    title('Measurements [Pixels]');
                    max=max_l;min=min_l;
                    cbar_axes=colorbar('peer',gca);
                    set(cbar_axes,'YTick',ytick_l,'YTickLabel',ytick_label_l);
                    current_figax= hax1;
                end
                if(k==2)
                    axes(hax2)
                    title('Measurements [Pixels]');
                    max=max_w;min=min_w;
                    cbar_axes=colorbar('peer',gca);
                    set(cbar_axes,'YTick',ytick_w,'YTickLabel',ytick_label_w);
                    current_figax = hax2;
                end
                if(k==3)
                    axes(hax3)
                    title('Measurements [Degrees]');
                    max=max_a;min=min_a;
                    cbar_axes=colorbar('peer',gca);
                    set(cbar_axes,'YTick',ytick_a,'YTickLabel',ytick_label_a);
                    current_figax = hax3;
                end
                if(k==4)
                    axes(hax4)
                    title('Measurements [Ratio of (Dist between fiber endpoints)/(Fiber Length)]');
                    max=max_s;min=min_s;
                    cbar_axes=colorbar('peer',gca);
                    set(cbar_axes,'YTick',ytick_s,'YTickLabel',ytick_label_s);
                    current_figax = hax4;
                end
                axes(current_figax);
                for i=1:size(a.data.Fa,2)
                    if fiber_data(i,2)==1
                        point_indices=a.data.Fa(1,fiber_data(i,1)).v;
                        s1=size(point_indices,2);
                        x_cord=[];y_cord=[];
                        for j=1:s1
                            x_cord(j)=a.data.Xa(point_indices(j),1);
                            y_cord(j)=a.data.Xa(point_indices(j),2);
                        end
                        if(floor(size_colors*(fiber_data(i,k+2)-min)/(max-min))>0)
                            color_final=colors(floor(size_colors*(fiber_data(i,k+2)-min)/(max-min)),:);
                        else
                            color_final=colors(1,:);
                        end
                        plot(x_cord,y_cord,'LineStyle','-','color',color_final,'linewidth',0.005);%hold on;

                        if(print_fiber_numbers==1)
                            shftx = 5;   % shift the text position to avoid the image edge
                            bndd = 10;   % distance from boundary
                            if x_cord(end) < x_cord(1)
                                if x_cord(s1)< bndd
                                    text(x_cord(s1)+shftx,y_cord(s1),num2str(fiber_data(i,1)),'HorizontalAlignment','center','color',color_final);
                                else
                                    text(x_cord(s1),y_cord(s1),num2str(fiber_data(i,1)),'HorizontalAlignment','center','color',color_final);
                                end
                            else
                                if x_cord(1)< bndd
                                    text(x_cord(1)+shftx,y_cord(1),num2str(i),'HorizontalAlignment','center','color',color_final);
                                else
                                    text(x_cord(1),y_cord(1),num2str(i),'HorizontalAlignment','center','color',color_final);
                                end
                            end
                        end
                    end

                end
                hold off % YL: allow the next high-level plotting command to start over
            end
        end


        function[BW]=get_mask(Data,iscell_variable,roi_index_queried)
            s1=size(IMGdata,1);s2=size(IMGdata,2);
            mask2(1:s1,1:s2)=logical(0);
            k=roi_index_queried;
%             iscell_variable=iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape);
            if(iscell_variable==0)
                Boundary = separate_rois.(Data{cell_selection_data(k,1),1}).boundary{1};
                vertices = fliplr(Boundary);
                BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
            else
                s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                for p=1:s_subcomps
                    Boundary = cell2mat(separate_rois.(Data{cell_selection_data(k,1),1}).boundary{p});
                    vertices = fliplr(Boundary);
                    BW=roipoly(IMGdata,vertices(:,1),vertices(:,2));
                    if(p==1)
                        mask2=BW;
                    else
                        mask2=mask2|BW;
                    end
                end
                BW=mask2;
            end
        end

    end
%--------------------------------------------------------------------------
% Callback function for the box "Labels"
    function[]=index_fn(~,~)
  % display ROI names when the box is checked, remove the ROI name when it
  % is un-checked.
      if isempty(cell_selection_data)
          disp('No ROI is selected')
          return
      end
      % if any cell is selced
        stemp=size(cell_selection_data,1);
        Data=get(roi_table,'Data');
        cell_selection_temp=cell_selection_data(:,1);
         if(get(index_box,'Value')==1)
            disp('ROI name will be displayed for selected ROIs except for the combined ROI.')
            if stemp == 0
                disp('No ROI is selected')
                return
            end
            figure(image_fig)
            for k=1:stemp
                IND_temp = cell_selection_temp(k);
                if(iscell(separate_rois.(Data{IND_temp,1}).xm)==1)%debug &&isempty(find(cell_selection_temp==k))==0)
                     %do nothing - display nothing in case of combined ROIs
                     disp(sprintf('Name of the combined ROI: %s is not displayed.', Data{cell_selection_data(k,1),1}));
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
                    disp(sprintf('Name of the combined ROI: %s is not displayed.', Data{cell_selection_data(k,1),1}));
                else   % individual ROI
                    set(ROI_text{IND_temp,2},'Visible','off');
                end
            end
        end
    end
%--------------------------------------------------------------------------
    function[]=ctFIRE_to_roi_fn(~,~)
     % Apply ctFIRE to cropped image/ROI:
%        1 find the image within the roi using gmask
%        2 save the image in ROI management
%        3 find a way to run ctFIRE on the saved image
%        4 run ctFIRE based on the parameters set in the main program
        ROIanaChoice = questdlg('ROI analysis for the cropped rectgular ROI or the ROI mask of any shape?', 'ROI Analysis','Cropped Rectangular ROI','ROI Mask of Any Shape','Cropped Rectangular ROI');
        if isempty(ROIanaChoice)
            error('Please choose the shape of the ROI to be analyzed.')
        end
        switch ROIanaChoice
            case 'Cropped Rectangular ROI'
                cropIMGon = 1;
                disp('CT-FIRE analysis on the the cropped rectangular ROIs, not applicable to the combined ROI.')
                disp('Loading ROI');
            case 'ROI Mask of Any Shape'
                cropIMGon = 0;
                disp('CT-FIRE analysis on the the ROI mask of any shape, not applicable to the combined ROI.');
                disp('Loading ROI')
        end
        s1 = size(IMGdata,1); % size of dimension 1
        s2 = size(IMGdata,2); % size of dimension 2
        if(exist(ROIanaIndDir,'dir')==0)%check for ROI folder
            mkdir(ROIanaIndDir);
        end
        default_sub_function;
        %close ct-fire output figures
        % close unnecessary figures
        ROIana_fig1H = findobj(0,'-regexp','Name','ctFIRE output:*');
        if ~isempty(ROIana_fig1H)
            close(ROIana_fig1H)
            disp('CT-FIRE ROI analysis output figures are closed.')
        end
        ROIana_fig2H = findobj(0, 'Name','CT Reconstructed Image ');
        if ~isempty(ROIana_fig2H)
            close(ROIana_fig2H)
            disp('CT-FIRE ROI analysis output CT-recontructed image is closed.')
        end

        function[]=default_sub_function()
            s_roi_num=size(cell_selection_data,1);
            Data=get(roi_table,'Data');
            image_copy=IMGdata(:,:,1);
            ff = fullfile(pathname, [filename fileEXT]);
            info = imfinfo(ff);
            numSections = numel(info);
            if(s_roi_num>=1)%for multiple ROIs - applying ctFIRE on multiple
                for k=1:s_roi_num
                    image_copy3=image_copy;
                    combined_rois_present=0;
                    if(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==1)
                        combined_rois_present=1;
                    end
                    set(status_message,'string',sprintf('%d/%d: working on %s ',...
                        k,s_roi_num,Data{cell_selection_data(k,1),1}));
                    if(combined_rois_present==0)
                       ROIshape_ind = separate_rois.(Data{cell_selection_data(k,1),1}).shape;
                       if cropIMGon == 0     % use ROI mask
                            %finding the mask
                           vertices = fliplr(separate_rois.(Data{cell_selection_data(k,1),1}).boundary{1});
                           BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                       elseif cropIMGon == 1
                           if ROIshape_ind == 1   % use cropped ROI image
                               data2 = round(separate_rois.(Data{cell_selection_data(k,1),1}).roi);
                               a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                               ROIimg = image_copy(b:b+d-1,a:a+c-1);
                           else
                               error('Cropped image ROI analysis for shapes other than rectangles is not available so far.')
                           end
                       end
                       if cropIMGon == 0
                           image_copy2=image_copy3(:,:,1).*uint8(BW);
                       elseif cropIMGon == 1
                           image_copy2 = ROIimg;
                       end
                       if stackflag == 1 %reading the slices of a stack
                           filename_temp = fullfile(ROIanaIndDir,[filename,sprintf('_s%d_',currentIDX),Data{cell_selection_data(k,1),1},'.tif']);
                       else %reading individual images
                           filename_temp=fullfile(ROIanaIndDir,[filename '_' Data{cell_selection_data(k,1),1} '.tif']);
                       end

                       imwrite(image_copy2,filename_temp);
                       imgpath=ROIanaIndDir;
                       if stackflag == 1
                           imgname=[filename sprintf('_s%d_',currentIDX) Data{cell_selection_data(k,1),1} '.tif'];
                       else
                           imgname=[filename '_' Data{cell_selection_data(k,1),1} '.tif'];
                       end
                       savepath=fullfile(ROIanaIndDir,'ctFIREout');
                       if ~exist(savepath,'dir')
                           mkdir(savepath);
                       end
                       ctFIRE_1(imgpath,imgname,savepath,cP,ctFP);%Calling ctFIRE with parameters

                    elseif(combined_rois_present==1)
                        % for single combined ROI
                       s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                       for p=1:s_subcomps
                           boundary = cell2mat(separate_rois.(Data{cell_selection_data(k,1),1}).boundary{p});
                           vertices = fliplr(boundary);
                           BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                           if(p==1)
                             mask2=BW;
                          else
                             mask2=mask2|BW;
                          end
                       end  % end of p
                       image_copy2=image_copy3(:,:,1).*uint8(mask2);
                       filename_temp=fullfile(ROIanaIndDir, [filename '_' Data{cell_selection_data(k,1),1} '.tif']);
                       imwrite(image_copy2,filename_temp);
                       imgpath = ROIanaIndDir;
                       imgname=[filename '_' Data{cell_selection_data(k,1),1} '.tif'];
                       savepath=fullfile(ROIanaIndDir,'ctFIREout');
                       if ~exist(savepath,'dir')
                           mkdir(savepath);
                       end
                       ctFIRE_1p(imgpath,imgname,savepath,cP,ctFP,1);%calling ctFIRE with parameters
                    end
                end
            end
            [~,filenameNE] = fileparts(filename);
            if ~isempty(CTFroi_data_current)
                items_number_current = length(CTFroi_data_current(:,1));
            else
                items_number_current = 0;
            end
            for k = 1:s_roi_num
                roiNamelist = (Data{cell_selection_data(k,1),1});
                if stackflag == 1
                    imgname2=[filename sprintf('_s%d_',currentIDX) roiNamelist];
                else
                    imgname2=[filename '_' roiNamelist];
                end
                ROIshape_ind = separate_rois.(roiNamelist).shape;
                histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s.csv',imgname2));      % ctFIRE output:xls angle histogram values
                histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s.csv',imgname2));      % ctFIRE output:xls length histgram values
                histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s.csv',imgname2));      % ctFIRE output:xls straightness histogram values
                histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s.csv',imgname2));      % ctFIRE output:xls width histgram values
                if exist(histA2,'file')
                    ROIangle = mean(importdata(histA2));
                    ROIlength = mean(importdata(histL2));
                    ROIstraight = mean(importdata(histSTR2));
                    ROIwidth = mean(importdata(histWID2));
                    fibNUM = length(importdata(histA2));
                else
                    disp(sprintf('%s does not exist. Fiber metrics reading was skipped.',histA2))
                    ROIangle = nan;
                    ROIlength = nan;
                    ROIstraight = nan;
                    ROIwidth = nan;
                    fibNUM = nan;
                end

                try
                    zc = currentIDX;
                catch
                    zc=1;
                end
                 % combined ROI
                if(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==1)
                    ROIshape_value = nan; % arbitary
                    xc = nan;
                    yc = nan;
                else
                    xc = round(separate_rois.(roiNamelist).ym);
                    yc = round(separate_rois.(roiNamelist).xm);
                    ROIshape_value = ROIshapes{ROIshape_ind};
                end
                postFLAG = 'NO';
                if cropIMGon == 0
                    cropFLAG = 'NO';
                elseif cropIMGon == 1
                    cropFLAG = 'YES';
                end
                modeID = 'CTF';  % options: 'CTF' or 'CTF+Threshold' or 'FIRE'
                items_number_current = items_number_current+1;
                CTFroi_data_add = {items_number_current,sprintf('%s',filename),sprintf('%s',roiNamelist),...
                    sprintf('%.1f',ROIwidth),sprintf('%.1f',ROIlength), sprintf('%.2f',ROIstraight),sprintf('%.1f',ROIangle)...
                    sprintf('%d',fibNUM),modeID,cropFLAG,postFLAG,ROIshape_value,round(xc),round(yc),zc,};
                items_number_current = items_number_current+1;
                CTFroi_data_current = [CTFroi_data_current; CTFroi_data_add];
                set(CTFroi_output_table,'Data',CTFroi_data_current)
                set(CTFroi_table_fig,'Visible','on')
            end  % end of number of ROIs
            set(status_message,'string','ROI analaysis on selected ROI(s) is done.');
        end  % end of sub function
    end   % end of ctFIRE_to_roi

    function[]=load_roi_fn(~,~)
        [text_filename_all,text_pathname,~]=uigetfile({'*.csv'},'Select ROI coordinates file(s)',pseudo_address,'MultiSelect','on');
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
            set(status_message, 'String','No ROI was selected or displayed.')
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
        stemp=size(cell_selection_data,1);s1=size(IMGdata,1);s2=size(IMGdata,2);
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

    function[x_min,y_min,x_max,y_max]=enclosing_rect_fn(coordinates)
        x_min=round(min(coordinates(:,1)));
        x_max=round(max(coordinates(:,1)));
        y_min=round(min(coordinates(:,2)));
        y_max=round(max(coordinates(:,2)));
    end

end
