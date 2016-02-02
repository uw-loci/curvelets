
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
      disp('reset the ROI mananger');
    end
    setupFunction;
    % global variables and assignments -start
            global pseudo_address caIMG filename pathname separate_rois finalize_rois roi roi_shape h cell_selection_data xmid ymid matdata gmask combined_name_for_ctFIRE ROI_text clrr2    
            matdata=[];filename = CAfilename;pathname = CApathname;fibFeat = [];% CA output features of the whole image
            separate_rois=[];%Stores all ROIs of the image for access
            plotrgbFLAG = CAcontrol.plotrgbFLAG;  % flag for displaying RGB image 
            specifyROIsize = CAcontrol.specifyROIsize;  % default Size of the 'specify' ROI - taken as input from calling function - CurveAlign 
            loadROIFLAG = CAcontrol.loadROIFLAG; % ??
            guiFig_absPOS = CAcontrol.guiFig_absPOS; %stores the position of calling function CurveAlign's GUI
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
    % global variables and assignments -end
    
    %roi_mang_fig - roi manager figure setup - starts
        roi_mang_fig = figure(201);clf;                                     %Figure containing ROI Manager
        set(roi_mang_fig,'Resize','on','Color',defaultBackground,'Units','pixels','Position',[50 50 round(SW/5) round(SH*0.9)],'Visible','on','MenuBar','none','name','ROI Manager','NumberTitle','off','UserData',0);
        set(roi_mang_fig,'KeyPressFcn',@roi_mang_keypress_fn);              %Assigning the function that is called when any key is pressed while roi_mang_fig is active
        relative_horz_displacement=20;                                      % Horz dist of ROI analysis figure from ROI Manager figure
        caIMG_fig=figure(248); clf;                                         %caImg_fig - figure where image is shown and curvelets are plotted
        set(caIMG_fig,'Resize','on','Units','pixels','position',guiFig_absPOS,'name',sprintf('CurveAlign ROI:%s',filename),'MenuBar','none','NumberTitle','off','visible', 'off')
        set(caIMG_fig,'KeyPressFcn',@roi_mang_keypress_fn);                 %Assigning the function that is called when any key is pressed while caIMG_fig is active
        %  add overAx axis object for the overlaid image 
             overPanel = uipanel('Parent', caIMG_fig,'Units','normalized','Position',[0 0 1 1]);
             overAx= axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);    
        BWv = {};                                                           % cell to save the selected ROIs
        backup_fig=figure;set(backup_fig,'Visible','off');
    % roi_mang_fig - roi manager figure setup - ends
       
    %opening previous file location - using address3.mat file
        openDefaultFileLocationFn;
    
    %defining buttons of ROI manager - starts
        roi_table=uitable('Parent',roi_mang_fig,'Units','normalized','Position',[0.05 0.05 0.45 0.9],'CellSelectionCallback',@cell_selection_fn);
        reset_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.75 0.96 0.2 0.03],'String','Reset','Callback',@reset_fn,'TooltipString','Press to reset');
        filename_box=uicontrol('Parent',roi_mang_fig,'Style','text','String','filename','Units','normalized','Position',[0.05 0.955 0.45 0.04],'BackgroundColor',[1 1 1]);
        load_caIMG_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.9 0.4 0.035],'String','Open File','Callback',@load_caIMG,'TooltipString','Open caIMG');
        roi_shape_choice_text=uicontrol('Parent',roi_mang_fig,'Style','text','string','Draw ROI Menu (d)','Units','normalized','Position',[0.55 0.86 0.4 0.035]);
        roi_shape_choice=uicontrol('Parent',roi_mang_fig,'Enable','off','Style','popupmenu','string',{'New ROI?','Rectangle','Freehand','Ellipse','Polygon','Specify...'},'Units','normalized','Position',[0.55 0.82 0.4 0.035],'Callback',@roi_shape_choice_fn);
        save_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.78 0.4 0.035],'String','Save ROI (s)','Enable','on','Callback',@save_roi);
        combine_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.74 0.4 0.035],'String','Combine ROIs','Enable','on','Callback',@combine_rois,'Enable','off','TooltipString','Combine two or more ROIs');
        rename_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.7 0.4 0.035],'String','Rename ROI','Callback',@rename_roi);
        delete_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.66 0.4 0.035],'String','Delete ROI','Callback',@delete_roi);
        measure_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.62 0.4 0.035],'String','Measure ROI','Callback',@measure_roi,'TooltipString','Displays ROI Properties');
        load_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.58 0.4 0.035],'String','Load ROI','TooltipString','Loads ROIs of other caIMGs','Enable','on','Callback',@load_roi_fn);
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
        status_message=uicontrol('Parent',roi_mang_fig,'Style','text','Fontsize',10,'Units','normalized','Position',[0.515 0.05 0.485 0.265+shift_disp],'String','Press Open File and select a file','BackgroundColor','g');
        set([rename_roi_box,delete_roi_box,measure_roi_box],'Enable','off');        % setting intital confugaration
        % YL: add CA output table. Column names and column format
             columnname = {'No.','caIMG Label','ROI label','Shape','Xc','Yc','z','Orentation','Alignment Coeff.'};
             columnformat = {'numeric','char','char','char','numeric','numeric','numeric','numeric' ,'numeric'};
     %defining buttons of ROI manager - ends
   
     if isempty (CAdatacurrent)
         if exist(fullfile(pathname,'ROI_management',sprintf('%s_ROIsCA.mat',filenameNE)))
             load(fullfile(pathname,'ROI_management',sprintf('%s_ROIsCA.mat',filenameNE)),'CAroi_data_current','separate_rois')
             % resolve the ROI conflict in the defined ROI .mat file and 
             if ~isempty(separate_rois)
                 ROInamestemp1 = fieldnames(separate_rois);
                 % update the separate_rois using the ROIs mat file
                 if(exist(fullfile(ROImanDir,roiMATname),'file')~=0)%if file is present . value ==2 if present
                     separate_roistemp2=importdata(fullfile(ROImanDir,roiMATname));
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
             CAroi_data_current = [];
         end
     else
         CAroi_data_current = CAdatacurrent;
     end
     
     %setting up CAroi_table_fig -starts
         selectedROWs = []; % Selected rows in CA output uitable
         CAroi_table_fig = figure(242);clf  % Create the CA output uitable
         figPOS = [0.55 0.45 0.425 0.425];  %      figPOS = get(caIMG_fig,'Position');  figPOS = [figPOS(1)+0.5*figPOS(3) figPOS(2)+0.75*figPOS(4) figPOS(3)*1.25 figPOS(4)*0.275];  
         set(CAroi_table_fig,'Units','normalized','Position',figPOS,'Visible','on','NumberTitle','off','name','CurveAlign ROI analysis output table');
         CAroi_output_table = uitable('Parent',CAroi_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],'Data', CAroi_data_current,'ColumnName', columnname,'ColumnFormat', columnformat,'ColumnEditable', [false false false false false false false false false],'RowName',[],'CellSelectionCallback',{@CAot_CellSelectionCallback});    
         %Save and Delete button in CAroi_table_fig
             DeleteROIout=uicontrol('Parent',CAroi_table_fig,'Style','Pushbutton','Units','normalized','Position',[0.9 0.01 0.08 0.08],'String','Delete','Callback',@DeleteROIout_Callback);
             SaveROIout=uicontrol('Parent',CAroi_table_fig,'Style','Pushbutton','Units','normalized','Position',[0.80 0.01 0.08 0.08],'String','Save All','Callback',@SaveROIout_Callback);
    %setting up CAroi_table_fig -ends
    
    %YL - loads the image specified
        [filename] = load_CAcaIMG(filename,pathname);
    
%-------------------------------------------------------------------------
%output table callback functions
    function openDefaultFileLocationFn()
    % opens last opened file location if any
        f1=fopen('address3.mat');
        if(f1<=0)
        pseudo_address='';%pwd;
         else
            pseudo_address = importdata('address3.mat');
            if(pseudo_address==0)
                pseudo_address = '';%pwd;
                disp('using default path to load file(s)'); % YL
            else
                disp(sprintf( 'using saved path to load file(s), current path is %s ',pseudo_address));
            end
        end 
    end

    function CAot_CellSelectionCallback(hobject, eventdata,handles)
        handles.currentCell=eventdata.Indices;
        selectedROWs = unique(handles.currentCell(:,1));
        
        selectedZ = CAroi_data_current(selectedROWs,7);
        
        if numSections > 1
            for j = 1:length(selectedZ)
                Zv(j) = selectedZ{j};
            end
            
            if size(unique(Zv)) == 1
                zc = unique(Zv);
            else
                error('only display ROIs in the same section of a stack')
            end
            
        else
            zc = 1;
        end
        
        if numSections == 1
                
            IMGO(:,:,1) = uint8(caIMG(:,:,1));
            IMGO(:,:,2) = uint8(caIMG(:,:,1));
            IMGO(:,:,3) = uint8(caIMG(:,:,1));
            IMGtemp = imread(fullfile(CApathname,CAfilename));
        elseif numSections > 1
            
            IMGtemp = imread(fullfile(CApathname,CAfilename),zc);
            if size(IMGtemp,3) > 1
%                 IMGtemp = rgb2gray(IMGtemp);
%                  IMGtemp = IMGtemp(:,:,1);
                 if plotrgbFLAG == 0
                     IMGtemp = rgb2gray(IMGtemp);
                     disp('color image was loaded but converted to grayscale image')
                 elseif plotrgbFLAG == 1
                     
                     disp('display color image');
                     
                 end

            end
                IMGO(:,:,1) = uint8(IMGtemp);
                IMGO(:,:,2) = uint8(IMGtemp);
                IMGO(:,:,3) = uint8(IMGtemp);
        
        end
        
    
        if cropIMGon == 1      % 
        
        for i= 1:length(selectedROWs)
           CAroi_name_selected =  CAroi_data_current(selectedROWs(i),3);
          
           if numSections > 1
               roiNamefull = [filename,sprintf('_s%d_',zc),CAroi_name_selected{1},'.tif'];
           elseif numSections == 1
                roiNamefull = [filename,'_', CAroi_name_selected{1},'.tif']; 
           end
           
           mapName = fullfile(ROIanaIndOutDir,[roiNamefull '_procmap.tiff']);
           if exist(mapName,'file')
               IMGmap = imread(mapName);
               disp(sprintf('alignment map file is %s',mapName))
           else
               disp(sprintf('alignment map file does not exist'))
               IMGmap = zeros(size(IMGO));
           end
           
           
           if(separate_rois.(CAroi_name_selected{1}).shape==1)
               % vertices is not actual vertices but data as [ a b c d] and
               % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)]
               data2=separate_rois.(CAroi_name_selected{1}).roi;
               a=data2(1);b=data2(2);c=data2(3);d=data2(4);
               IMGO(b:b+d-1,a:a+c-1,1) = IMGmap(:,:,1);
               IMGO(b:b+d-1,a:a+c-1,2) = IMGmap(:,:,2);
               IMGO(b:b+d-1,a:a+c-1,3) = IMGmap(:,:,3);
               xx(i) = a+c/2;  yy(i)= b+d/2; ROIind(i) = selectedROWs(i);
               aa(i) = a; bb(i) = b;cc(i) = c; dd(i) = d;
               
           else
               error('cropped image ROI analysis for shapes other than rectangle is not availabe so far')  
               
           end
                   
        end
        
         figure(caIMG_fig);   imshow(IMGO); hold on;
         for i = 1:length(selectedROWs)
            text(xx(i),yy(i),sprintf('%d',ROIind(i)),'fontsize', 10,'color','m')
            rectangle('Position',[aa(i) bb(i) cc(i) dd(i)],'EdgeColor','y','linewidth',3)
         end
       hold off
       
        end
       
      
        if cropIMGon == 0
            figure(caIMG_fig);   imshow(IMGO); hold on;
          
           for i= 1:length(selectedROWs)
           CAroi_name_selected =  CAroi_data_current(selectedROWs(i),3);
          
           if numSections > 1
               roiNamefull = [filename,sprintf('_s%d_',zc),CAroi_name_selected{1},'.tif'];
           elseif numSections == 1
                roiNamefull = [filename,'_', CAroi_name_selected{1},'.tif']; 
           end
           IMGmap = imread(fullfile(ROIanaIndOutDir,[roiNamefull '_procmap.tiff']));


            data2=[];vertices=[];
            %%YL: adapted from cell_selection_fn
            if(separate_rois.(CAroi_name_selected{1}).shape==1)
                % vertices is not actual vertices but data as [ a b c d] and
                % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)]
                data2=separate_rois.(CAroi_name_selected{1}).roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                BW=roipoly(IMGtemp,vertices(:,1),vertices(:,2));

            elseif(separate_rois.(CAroi_name_selected{1}).shape==2)
                vertices=separate_rois.(CAroi_name_selected{1}).roi;
                BW=roipoly(IMGtemp,vertices(:,1),vertices(:,2));

            elseif(separate_rois.(CAroi_name_selected{1}).shape==3)
                data2=separate_rois.(CAroi_name_selected{1}).roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                %the rect enclosing the ellipse.
                % equation of ellipse region->
                % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                s1=size(IMGtemp,1);s2=size(image,2);
                for m=1:s1
                    for n=1:s2
                        dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                        if(dist<=1.00)
                            BW(m,n)=logical(1);
                        else
                            BW(m,n)=logical(0);
                        end
                    end
                end
                %figure;imshow(255*uint8(BW));
            elseif(separate_rois.(CAroi_name_selected{1}).shape==4)
                vertices=separate_rois.(CAroi_name_selected{1}).roi;
                BW=roipoly(IMGtemp,vertices(:,1),vertices(:,2));

            end

            B=bwboundaries(BW);
            %                   figure(caIMG_fig);
            for k2 = 1:length(B)
                boundary = B{k2};
                plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
            end
            [yc xc]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)

            text(xc,yc,sprintf('%d',selectedROWs(i)),'fontsize', 10,'color','m')

           
           end
        
          hold off    
        end
        
         function[xmid,ymid]=midpoint_fn(BW)
           s1_BW=size(BW,1); s2_BW=size(BW,2);
           xmid=0;ymid=0;count=0;
           for i2=1:s1_BW
               for j2=1:s2_BW
                   if(BW(i2,j2)==logical(1))
                      xmid=xmid+i2;ymid=ymid+j2;count=count+1; 
                   end
               end
           end
           xmid=floor(xmid/count);ymid=floor(ymid/count);
        end 

        
    end

    function DeleteROIout_Callback(hobject,handles)
        
        CAroi_data_current(selectedROWs,:) = [];
        if ~isempty(CAroi_data_current)
            for i = 1:length(CAroi_data_current(:,1))
                CAroi_data_current(i,1) = {i};
            end
 
        end
        
        set(CAroi_output_table,'Data',CAroi_data_current)
        
    end

    function SaveROIout_Callback(hobject,handles)
         if ~isempty(CAroi_data_current)
             %YL: may need to delete the existing files 
           save(fullfile(ROIDir,'ROI_management',sprintf('%s_ROIsCA.mat',filenameNE)),'CAroi_data_current','separate_rois') ;
           if exist(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCA.xlsx',filenameNE)),'file')
               delete(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCA.xlsx',filenameNE)));
           end
           xlswrite(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCA.xlsx',filenameNE)),[columnname;CAroi_data_current],'CA ROI alignment analysis') ;
           
            else
             %delete exist output file if data is empty
            if exist(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCTF.mat',filenameNE)),'file')
               delete(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCTF.mat',filenameNE)))
            end

            if exist(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCTF.xlsx',filenameNE)),'file')
               delete(fullfile(ROIdir,'ROI_management',sprintf('%s_ROIsCTF.xlsx',filenameNE)));
           end
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
 
    function [filename] = load_CAcaIMG(filename,pathname)
%         Steps-
%         1 open the location of the last caIMG
%         2 check for folders.  If one of them is not present then make these directories
%         3 check whether caIMGname_ROIs are present in the pathname/ROI/ROI_management
%         4 Skip -(read caIMG - convert to RGB caIMG . Reason - colored
%         fibres need to be overlaid. ) Try grayscale caIMG first
%         5 if folders are present then check for the caIMGname_ROIs.mat in ROI_management folder
%         6 if file is present then load the ROIs in roi_table of roi_mang_fig
        
        set(status_message,'string','File is being opened. Please wait....');
         try
            message_CAOUTdata_present=0; % flag for presence of fiber features
            pseudo_address=pathname;
            save('address3.mat','pseudo_address');
            % Checking for directories
                if(exist(ROIpostIndDir,'dir')==0)
                    mkdir(ROImanDir);mkdir(ROIpostIndDir);
                else
                    if(exist(ROImanDir,'dir')==0),mkdir(ROImanDir); end
                    if(exist(ROIpostIndDir,'dir')==0),mkdir(ROIpostIndDir); end
                end
            %Reading images
                if numSections == 1
                    caIMG=imread(fullfile(pathname,filename));
                elseif numSections > 1
                    caIMG=imread(fullfile(pathname,filename), CAcontrol.idx);
                end
            %Resolving RGB or grayscale image and displaying
                if(size(caIMG,3)==3)
                    if plotrgbFLAG == 0
                        IMGtemp = rgb2gray(caIMG);
                        disp('color image was loaded but converted to grayscale image')
                        caIMG_copy = IMGtemp;
                        caIMG(:,:,1)=caIMG_copy;caIMG(:,:,2)=caIMG_copy;caIMG(:,:,3)=caIMG_copy;
                    elseif plotrgbFLAG == 1
                        IMGtemp = caIMG;
                        disp('color image is used');
                    end
                    clear IMGtemp %not clear ???
                end
                figure(caIMG_fig);   imshow(caIMG); hold on;

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
                matdata = load(CAoutmatName);
                fibFeat = matdata.fibFeat;
            end
            if(exist(fullfile(ROImanDir,roiMATname),'file')~=0)%if file is present . value ==2 if present
                separate_rois=importdata(fullfile(ROImanDir,roiMATname));
                message_rois_present=1;
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
 %            figure(caIMG_fig);imshow(caIMG,'Border','tight');hold on;
            if(message_rois_present==1&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROI(s) are present and CAroi data is present');  
            elseif(message_rois_present==1&&message_CAOUTdata_present==0)
                set(status_message,'String','Previously defined ROIs are present');  
            elseif(message_rois_present==0&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROIs not present. CAroi data is present');  
            end
            set(load_caIMG_box,'Enable','off');
        catch
           set(status_message,'String','ROI managment/analysis for individual image.'); 
           set(load_caIMG_box,'Enable','on');
         end
        % on loading image - disabling load image box and enabling roi
        % shape selection box
        set(load_caIMG_box,'Enable','off');set(roi_shape_choice,'Enable','on'); 
end

    function[]=roi_mang_keypress_fn(object,eventdata,handles)
        if(eventdata.Key=='s')
            save_roi(0,0);
        elseif(eventdata.Key=='d')
            draw_roi_sub(0,0);
        end
    end
    % Resume Code Formatting here
    function[]=draw_roi_sub(object,handles)
       set(save_roi_box,'Enable','on');
       roi_shape=get(roi_shape_choice,'Value')-1;
       if(roi_shape==0)
          roi_shape=1; 
       end
       count=1;%finding the ROI number
       fieldname=['ROI' num2str(count)];

       while(isfield(separate_rois,fieldname)==1)
           count=count+1;fieldname=['ROI' num2str(count)];
       end
      % close; %closes the pop up window

       figure(caIMG_fig);
       s1=size(caIMG,1);s2=size(caIMG,2);
	   mask(1:s1,1:s2)=logical(0);  %yl+
       finalize_rois=0;
       rect_fixed_size=0;
       while(finalize_rois==0)
           if(roi_shape==1)
                if(rect_fixed_size==0)% for resizeable Rectangular ROI
                    h=imrect;
                     wait_fn();
                     finalize_rois=1;
                    %finalize_roi=1;
%                         set(status_message,'String',['Rectangular ROI selected' char(10) 'Draw ROI']);
                elseif(rect_fixed_size==1)% fornon resizeable Rect ROI 
                    h = imrect(gca, [10 10 ROIwidth ROIheight]);
                     wait_fn();
                     finalize_rois=1;
                    addNewPositionCallback(h,@(p) title(mat2str(p,3)));
                    fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
                    setPositionConstraintFcn(h,fcn);
                     setResizable(h,0);
                end
            elseif(roi_shape==2)
                h=imfreehand;wait_fn();finalize_rois=1;
            elseif(roi_shape==3)
                h=imellipse;wait_fn();finalize_rois=1;
            elseif(roi_shape==4)
                h=impoly;finalize_rois=1;wait_fn();
            end
            if(finalize_rois==1)
                break;
            end

       end
       roi=getPosition(h);
        function[]=wait_fn()
%                 while(finalize_rois==0)
%                    pause(0.25); 
%                 end
         end
            
   end     
    
    function[]=reset_fn(object,handles)
%         close all; 
%        save('CAroicurrent.mat','CApathname','CAfilename','CAdatacurrent','CAcontrol','-v7.3');
%        disp(sprintf('current CAroi data was saved at %s',fullfile(pwd, 'CAroicurrent.mat')));
%        CAroi();
         clear BWv
    end 
    
    function[]=load_caIMG(object,handles)
%         Steps-
%         1 open the location of the last caIMG
%         2 check for the folder ROI then ROI/ROI_management and ROI_analysis. If one of them is not present then make these directories
%         3 check whether caIMGname_ROIs are present in the pathname/ROI/ROI_management
%         4 Skip -(read caIMG - convert to RGB caIMG . Reason - colored
%         fibres need to be overlaid. ) Try grayscale caIMG first
%         5 if folders are present then check for the caIMGname_ROIs.mat in ROI_management folder
%         5.5 define mask and boundary 
%         6 if file is present then load the ROIs in roi_table of roi_mang_fig
        
        [filename,pathname,filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select caIMG',pseudo_address,'MultiSelect','off'); 
        
        set(status_message,'string','File is being opened. Please wait....');
         try
             message_roi_present=1;message_CAOUTdata_present=0;
            pseudo_address=pathname;
            save('address3.mat','pseudo_address');
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
            caIMG=imread([pathname filename]);
            if(size(caIMG,3)==3)
               if plotrgbFLAG == 0
                    caIMG = rgb2gray(caIMG);
                    caIMG_copy = caIMG; 
                    caIMG(:,:,1)=caIMG_copy;
                    caIMG(:,:,2)=caIMG_copy;
                    caIMG(:,:,3)=caIMG_copy;
                    disp('color image was loaded but converted to grayscale image')
                elseif plotrgbFLAG == 1
                    caIMG_copy = caIMG(:,:,1);
                    disp('display color image');
            
                end

            end
            
            
            set(filename_box,'String',filename);
            dot_position=findstr(filename,'.');dot_position=dot_position(end);
            if(exist(fullfile(pathname,'CA_Out',[filename '_fibFeatures' '.csv']),'file')~=0)%~=0 instead of ==1 because value is equal to 2
                %set(analyzer_box,'Enable','on');
                message_CAOUTdata_present=1;
                matdata=importdata(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']));
                clrr2 = rand(size(matdata.data.Fa,2),3);
            end
            if(exist(fullfile(ROImanDir,roiMATname),'file')~=0)%if file is present . value ==2 if present
                separate_rois=importdata(fullfile(ROImanDir,roiMATname));
                message_rois_present=1;
            else
                temp_kip='';
                separate_rois=[];
                save(fullfile(ROImanDir,roiMATname),'separate_rois');
            end
            
            s1=size(caIMG,1);s2=size(caIMG,2);
            mask(1:s1,1:s2)=logical(0);boundary(1:s1,1:s2)=uint8(0);
            
            if(isempty(separate_rois)==0)
                size_saved_operations=size(fieldnames(separate_rois),1);
                names=fieldnames(separate_rois); 
                for i=1:size_saved_operations
                    Data{i,1}=names{i,1};
                end
                set(roi_table,'Data',Data);
            end
            figure(caIMG_fig);imshow(caIMG,'Border','tight');hold on;
            if(message_rois_present==1&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROI(s) are present and ctFIRE data is present');  
            elseif(message_rois_present==1&&message_CAOUTdata_present==0)
                set(status_message,'String','Previously defined ROIs are present');  
            elseif(message_rois_present==0&&message_CAOUTdata_present==1)
                set(status_message,'String','Previously defined ROIs not present .ctFIRE data is present');  
            end
            set(load_caIMG_box,'Enable','off');
           % set([draw_roi_box],'Enable','on');
            
        catch
           set(status_message,'String','error in loading caIMG.'); 
           set(load_caIMG_box,'Enable','on');
        end
        set(load_caIMG_box,'Enable','off');
        if(isempty(separate_rois)==0)
            %text_coordinates_to_file_fn;  
            %display('calling text_coordinates_to_file_fn');
        end
        set(roi_shape_choice,'Enable','on');
        
    end

    function[]=roi_shape_choice_fn(object,handles)
%         set(save_roi_box,'Enable','on');  %yl
        global rect_fixed_size;
        %temp=isempty(findobj('type','figure','name','Select ROI shape'));
        %display(first_time_draw_roi);
       % roi_shape_temp=get(object,'value');
	   roi_shape_temp=get(roi_shape_choice,'value');  %yl+
        
          if(roi_shape_temp==2)
             set(status_message,'String','Rectangular Shape ROI selected. Draw the ROI over the CA ROI figure');   
          elseif(roi_shape_temp==3)
              set(status_message,'String','Freehand ROI selected. Draw the ROI over the CA ROI figure');  
          elseif(roi_shape_temp==4)
              set(status_message,'String','Ellipse shaped ROI selected. Draw the ROI over the CA ROI figure');  
          elseif(roi_shape_temp==5)
              set(status_message,'String','Polygon shaped ROI selected. Draw the ROI over the CA ROI figure');  
          elseif(roi_shape_temp==6)
                
          end
          figure(caIMG_fig);
           s1=size(caIMG,1);s2=size(caIMG,2);
           mask(1:s1,1:s2)=logical(0);
           finalize_rois=0;
           %display(roi_shape_temp);
           % while(finalize_rois==0)
               if(roi_shape_temp==2)
                    % for resizeable Rectangular ROI
%                        display('in rect');
                        roi_shape=1;
                        h=imrect;
                         wait_fn();
                         finalize_rois=1;
                elseif(roi_shape_temp==3)
%                    display('in freehand');roi_shape=2;
                    roi_shape=2;
                    h=imfreehand;wait_fn();finalize_rois=1;
                elseif(roi_shape_temp==4)
%                   display('in Ellipse');roi_shape=3;
                    roi_shape=3;
                    h=imellipse;wait_fn();finalize_rois=1;
                elseif(roi_shape_temp==5)
%                    display('in polygon');roi_shape=4;
                    roi_shape=4;
                    h=impoly;wait_fn();finalize_rois=1;
               elseif(roi_shape_temp==6)
                  roi_shape=1;
                   roi_shape_popup_window;%wait_fn();
               end
                if(roi_shape_temp~=6)
                    roi=getPosition(h);
                end
                
%                 if(finalize_rois==1)
%                     break;
%                 end
%            end
           
           function[]=roi_shape_popup_window()
                ROIwidth=specifyROIsize(1); ROIheight=specifyROIsize(2);
                
                x=1;y=1;
                rect_fixed_size=0;% 1 if size is fixed and 0 if not
                position=[20 SH*0.6 200 200];
                left=position(1);bottom=position(2);%width=position(3);height=position(4);
                defaultBackground = get(0,'defaultUicontrolBackgroundColor');
                popup_new_roi=figure('Units','pixels','Position',[round(SW*0.05) round(0.65*SH)  200 100],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);          
%                 roi_shape_text=uicontrol('Parent',popup_new_roi,'Style','text','string','select ROI type','Units','normalized','Position',[0.05 0.9 0.9 0.10]);
%                 roi_shape_menu=uicontrol('Parent',popup_new_roi,'Style','popupmenu','string',{'Rectangle','Freehand','Ellipse','Polygon'},'Units','normalized','Position',[0.05 0.75 0.9 0.10],'Callback',@roi_shape_menu_fn);
%                 rect_roi_checkbox=uicontrol('Parent',popup_new_roi,'Style','checkbox','Units','normalized','Position',[0.05 0.6 0.1 0.10],'Callback',@rect_roi_checkbox_fn);
                rect_roi_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Fixed Size Rect ROI','Units','normalized','Position',[0.15 0.8 0.6 0.15]);
                rect_roi_height=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(ROIheight),'Position',[0.05 0.5 0.2 0.15],'enable','on','Callback',@rect_roi_height_fn);
                rect_roi_height_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Height','Units','normalized','Position',[0.28 0.5 0.2 0.15],'enable','on');
                rect_roi_width=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(ROIwidth),'Position',[0.52 0.5 0.2 0.15],'enable','on','Callback',@rect_roi_width_fn);
                rect_roi_width_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Width','Units','normalized','Position',[0.73 0.5 0.2 0.15],'enable','on');
                x_start_box=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(x),'Position',[0.05 0.3 0.2 0.15],'enable','on','Callback',@x_change_fn);
                x_start_text=uicontrol('Parent',popup_new_roi,'Style','text','string','ROI X','Units','normalized','Position',[0.28 0.3 0.2 0.15],'enable','on');
                y_start_box=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(y),'Position',[0.52 0.3 0.2 0.15],'enable','on','Callback',@y_change_fn);
                y_start_text=uicontrol('Parent',popup_new_roi,'Style','text','string','ROI Y','Units','normalized','Position',[0.73 0.3 0.2 0.15],'enable','on');
                rf_numbers_ok=uicontrol('Parent',popup_new_roi,'Style','pushbutton','string','Ok','Units','normalized','Position',[0.05 0.10 0.45 0.2],'Callback',@ok_fn,'Enable','on');
                
                
                    function[]=rect_roi_width_fn(object,handles)
                       ROIwidth=str2num(get(object,'string')); 
                    end

                    function[]=rect_roi_height_fn(object,handles)
                        ROIheight=str2num(get(object,'string'));
                    end

                    function[]=ok_fn(object,handles)
                        figure(popup_new_roi);close;
                         figure(caIMG_fig);
                          h = imrect(gca, [x y ROIwidth ROIheight]);setResizable(h,0);  %yl+
                         wait_fn();
                         finalize_rois=1;
                        %display('drawn');
                        addNewPositionCallback(h,@(p) title(mat2str(p,3)));
                        fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
                        setPositionConstraintFcn(h,fcn);
                         roi=getPosition(h);
                    end
                    
                    function[]=wait_fn()
%                                 while(finalize_rois==0)
%                                    pause(0.25); 
%                                 end
                    end
            end
                    
                    function[]=x_change_fn(object,handles)
                        x=str2num(get(object,'string')); 
                        %display(x);
                    end
                    
                    function[]=y_change_fn(object,handles)
                        y=str2num(get(object,'string')); 
                        %display(y);
                    end           
            function[]=wait_fn()
%                 while(finalize_rois==0)
%                    pause(0.25); 
%                 end
            end

    end

    function[]=save_roi(object,handles)   
        % searching for the biggest operation number- starts
        finalize_rois=1;
        
       roi=getPosition(h);
        Data=get(roi_table,'Data'); %display(Data(1,1));
        count=1;count_max=1;
           if(isempty(separate_rois)==0)
               while(count<1000)
                  fieldname=['ROI' num2str(count)];
                   if(isfield(separate_rois,fieldname)==1)
                      count_max=count;
                   end
                  count=count+1;
               end
               fieldname=['ROI' num2str(count_max+1)];
           else
               fieldname=['ROI1'];
           end
           
        if(roi_shape==2)%ie  freehand
            separate_rois.(fieldname).roi=roi;% format -> roi=[a b c d] then vertices are [(a,b),(a+c,b),(a,b+d),(a+c,b+d)]
            %display(roi);
        elseif(roi_shape==1)% ie rectangular ROI
            separate_rois.(fieldname).roi=roi;
            %display(roi);
        elseif(roi_shape==3)
             separate_rois.(fieldname).roi=roi;
             %display(roi);
        elseif(roi_shape==4)
            separate_rois.(fieldname).roi=roi;
            %display(roi);
        end
        
        %saving date and time of operation-starts
        c=clock;fix(c);
        
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        separate_rois.(fieldname).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        separate_rois.(fieldname).time=time;
        separate_rois.(fieldname).shape=roi_shape;
        
        if(iscell(roi_shape)==0)
            %display('single ROI');
            if(roi_shape==1)
                data2=roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                
            elseif(roi_shape==2)
                vertices=roi;
                BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
            elseif(roi_shape==3)
              data2=roi;
              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
              s1=size(caIMG,1);s2=size(caIMG,2);
              for m=1:s1
                  for n=1:s2
                        dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                        %%display(dist);pause(1);
                        if(dist<=1.00)
                            BW(m,n)=logical(1);
                        else
                            BW(m,n)=logical(0);
                        end
                  end
              end
            elseif(roi_shape==4)
                vertices=roi;
                BW=roipoly(caIMG,vertices(:,1),vertices(:,2));                      
            end
            [xm,ym]=midpoint_fn(BW);
        
            %display(xm);display(ym);
            separate_rois.(fieldname).xm=xm;
            separate_rois.(fieldname).ym=ym;
        end
        
        % saving the matdata into the concerned file- starts
            
%             using the following three statements
%             load(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data');
%             data.PostProGUI = matdata2.data.PostProGUI;
%             save(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data','-append');
%             
        
%             load(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data');
%             data.ROI_analysis= matdata.data.ROI_analysis;
%             % data of the latest operation is appended
            %save(fullfile(pathname,'ROI_analysis\',[filename,'_rois.mat']),'separate_rois','-append');
        % saving the matdata into the concerned file- ends
        separate_rois_temp=separate_rois;
        %display(separate_rois);
        names=fieldnames(separate_rois);%display(names);
        s3=size(names,1);
%         for i=1:s3
%            %display(separate_rois.(names{i,1})); 
%         end
        save(fullfile(ROImanDir,roiMATname),'separate_rois','-append'); 
        set(status_message,'String',['mask saved in- ' fullfile(ROImanDir,roiMATname)]);
        %display('before update_rois');pause(10);
        update_rois;Data=get(roi_table,'Data');
        %display('after update_rois');
        set(save_roi_box,'Enable','off');
        
        index_temp=[];
%         display(size(cell_selection_data));
%         display(cell_selection_data);
        
        %display(size(cell_selection_data,1));
        if(size(cell_selection_data,1)==1)
            %index_temp(1)=1;
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
    end

    function[]=combine_rois(object,handles)
%         There can be three cases
%         1 combining individual ROIs
%         2 combining a combined and individual ROIs
%         3 combining multiple combined ROIs
        
        s1=size(cell_selection_data,1);
        Data=get(roi_table,'Data'); %display(Data(1,1));
        combined_rois_present=0; 
        roi_names=fieldnames(separate_rois);%display(roi_names);%pause(5);
        for i=1:s1
            %display(separate_rois.(roi_names{cell_selection_data(i,1),1}));
            %display(roi_names{cell_selection_data(i,1),1});
             if(iscell(separate_rois.(roi_names{cell_selection_data(i,1),1}).shape)==1)
                combined_rois_present=1; 
                %display(combined_rois_present);
                break;
             end
         end

        
        combined_roi_name=[];
        % this loop finds the name of the combined ROI - starts
        for i=1:s1
           %display(separate_rois.(temp2{cell_selection_data(i,1),1}));
           %display(roi_names(cell_selection_data(i,1)));
           if(i==1)
            combined_roi_name=['comb_s_' roi_names{cell_selection_data(i,1),1}];
           elseif(i<s1)
            combined_roi_name=[combined_roi_name '_' roi_names{cell_selection_data(i,1),1}];
           elseif(i==s1)
               combined_roi_name=[combined_roi_name '_' roi_names{cell_selection_data(i,1),1} '_e'];
           end
        end
        % this loop finds the name of the combined ROI - ends
       % display(combined_roi_name);
        
        % this loop stores all the component ROI parameters in an array
        if(combined_rois_present==0)
            for i=1:s1
                separate_rois.(combined_roi_name).shape{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape;
                separate_rois.(combined_roi_name).roi{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi; 
            end
            %fprintf('combined ROIs absent');
        else
            %fprintf('combined ROIs present');
            count=1;
            for i=1:s1
                if(iscell(separate_rois.(roi_names{cell_selection_data(i,1),1}).shape)==0)
                    separate_rois.(combined_roi_name).shape{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape;
                    separate_rois.(combined_roi_name).roi{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi; 
                    count=count+1;
                    %fprintf('tick %d ',i);
                else
                    stemp=size(separate_rois.(roi_names{cell_selection_data(i,1),1}).roi,2);
                    %fprintf('roi name=%s rois within it=%d',roi_names{cell_selection_data(i,1),1},stemp);
                    for j=1:stemp
                        separate_rois.(combined_roi_name).shape{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape{j};
                        separate_rois.(combined_roi_name).roi{count}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi{j}; 
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
        save(fullfile(ROImanDir,roiMATname),'separate_rois','-append');
        update_rois;
    end

    function[]=update_rois
        %it updates the roi in the ui table
        separate_rois=importdata(fullfile(ROImanDir,roiMATname));
        %display(separate_rois);
        %display('flag1');pause(5);
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
                %text_coordinates_to_file_fn; % do not want to call this
                %function for writing all ROI text files and caIMGs
        end
        %display('flag2');pause(5);
    end

    function[]=cell_selection_fn(object,handles)
        BWv = {}; % initialize the cell to save the selected ROIs

        figure(caIMG_fig);imshow(caIMG);hold on
        warning('off');
        combined_name_for_ctFIRE=[];
        
        %finding whether the selection contains a combination of ROIs
        stemp=size(handles.Indices,1);
        if(stemp>1)
            set(combine_roi_box,'Enable','on');
 %yl-
 %else
%            set(combine_roi_box,'Enable','off');
            set(rename_roi_box,'Enable','off');
        elseif(stemp==1)
            set(combine_roi_box,'Enable','off');
            set(rename_roi_box,'Enable','on');
        end
        if(stemp>=1)
           set([rename_roi_box,delete_roi_box,measure_roi_box,save_roi_text_box,save_roi_mask_box],'Enable','on');
        else
            set([rename_roi_box,delete_roi_box,measure_roi_box,save_roi_text_box,save_roi_mask_box],'Enable','off');
        end
         
        Data=get(roi_table,'Data'); %display(Data(1,1));
         combined_rois_present=0; 
         for i=1:stemp
             if(iscell(separate_rois.(Data{handles.Indices(i,1),1}).shape)==1)
                combined_rois_present=1; break;
             end
         end

     if(combined_rois_present==0)      
                xmid=[];ymid=[];
                s1=size(caIMG,1);s2=size(caIMG,2);
                
               mask(1:s1,1:s2)=logical(0);
               BW(1:s1,1:s2)=logical(0);
               roi_boundary(1:s1,1:s2,1)=uint8(0);roi_boundary(1:s1,1:s2,2)=uint8(0);roi_boundary(1:s1,1:s2,3)=uint8(0);
               overlaid_caIMG(1:s1,1:s2,1)=caIMG(1:s1,1:s2);overlaid_caIMG(1:s1,1:s2,2)=caIMG(1:s1,1:s2);
               Data=get(roi_table,'Data');
               
               s3=size(handles.Indices,1);%display(s3);%pause(5);
               if(s3>0)
                   set(CA_to_roi_box,'enable','on');
               elseif(s3<=0)
                   set(CA_to_roi_box,'enable','off');
                   return;
               end
               cell_selection_data=handles.Indices;
               
               figure(caIMG_fig);
               for k=1:s3
                   combined_name_for_ctFIRE=[combined_name_for_ctFIRE '_' Data{handles.Indices(k,1),1}];
                   data2=[];vertices=[];
                  
                  if(separate_rois.(Data{handles.Indices(k,1),1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices =[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                    
                  elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(caIMG,1);s2=size(caIMG,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==4)
                      %display('polygon');
                      vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  end
                  BWv{k} = BW;  % put all the selected ROIs together
                  mask=mask|BW;
                  s1=size(caIMG,1);s2=size(caIMG,2);
                  % Old method 
%                   for i=2:s1-1
%                         for j=2:s2-1
%                             North=BW(i-1,j);NorthWest=BW(i-1,j-1);NorthEast=BW(i-1,j+1);
%                             West=BW(i,j-1);East=BW(i,j+1);
%                             SouthWest=BW(i+1,j-1);South=BW(i+1,j);SouthEast=BW(i+1,j+1);
%                             if(BW(i,j)==logical(1)&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
%                                 roi_boundary(i,j,1)=uint8(255);
%                                 roi_boundary(i,j,2)=uint8(255);
%                                 roi_boundary(i,j,3)=uint8(0);
%                             end
%                         end
%                   end

                  %dilating the roi_boundary if the caIMG is bigger than
                  %the size of the figure
                  % No need to dilate the boundary it seems because we are
                  % now using the plot function
                  im_fig_size=get(caIMG_fig,'Position');
                  im_fig_width=im_fig_size(3);im_fig_height=im_fig_size(4);
                  s1=size(caIMG,1);s2=size(caIMG,2);
                  factor1=ceil(s1/im_fig_width);factor2=ceil(s2/im_fig_height);
                  if(factor1>factor2)
                     dilation_factor=factor1; 
                  else
                     dilation_factor=factor2;
                  end
                  
                  %  New method of showing boundaries
                  B=bwboundaries(BW);%display(length(B));
                  
                  for k2 = 1:length(B)
                     boundary = B{k2};
                     plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                  end
                  %pause(10);
%                   if(dilation_factor>1)  
%                     roi_boundary=dilate_boundary(roi_boundary,dilation_factor);
%                   end
                  
                     [xmid(k),ymid(k)]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
            
               end
               gmask=mask;
               
        
                if(get(index_box,'Value')==1)
                   for k=1:s3
                     figure(caIMG_fig);ROI_text(k)=text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                       %text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                   end
                end

               backup_fig=copyobj(caIMG_fig,0);set(backup_fig,'Visible','off');
    
     elseif(combined_rois_present==1)
               
               s1=size(caIMG,1);s2=size(caIMG,2);
               mask(1:s1,1:s2)=logical(0);
               BW(1:s1,1:s2)=logical(0);
               roi_boundary(1:s1,1:s2,1)=uint8(0);roi_boundary(1:s1,1:s2,2)=uint8(0);roi_boundary(1:s1,1:s2,3)=uint8(0);
               overlaid_caIMG(1:s1,1:s2,1)=caIMG(1:s1,1:s2);overlaid_caIMG(1:s1,1:s2,2)=caIMG(1:s1,1:s2);overlaid_caIMG(1:s1,1:s2,3)=caIMG(1:s1,1:s2);
               mask2=mask;
               Data=get(roi_table,'Data');
               s3=size(handles.Indices,1);%display(s3);%pause(5);
               cell_selection_data=handles.Indices;
               if(s3>0)
                   set(CA_to_roi_box,'enable','on');
               else
                    set(CA_to_roi_box,'enable','off');
               end
               for k=1:s3
                   if (iscell(separate_rois.(Data{handles.Indices(k,1),1}).roi)==1)
                       combined_name_for_ctFIRE=[combined_name_for_ctFIRE '_' Data{handles.Indices(k,1),1}];
                      s_subcomps=size(separate_rois.(Data{handles.Indices(k,1),1}).roi,2);
                     % display(s_subcomps);
                     
                      for p=1:s_subcomps
                          data2=[];vertices=[];
                          if(separate_rois.(Data{handles.Indices(k,1),1}).shape{p}==1)
                            data2=separate_rois.(Data{handles.Indices(k,1),1}).roi{p};
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape{p}==2)
                              vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi{p};
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape{p}==3)
                              data2=separate_rois.(Data{handles.Indices(k,1),1}).roi{p};
                              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                              s1=size(caIMG,1);s2=size(caIMG,2);
                              for m=1:s1
                                  for n=1:s2
                                        dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                        if(dist<=1.00)
                                            BW(m,n)=logical(1);
                                        else
                                            BW(m,n)=logical(0);
                                        end
                                  end
                              end
                          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape{p}==4)
                              vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi{p};
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          end
                          if(p==1)
                             mask2=BW; 
                          else
                             mask2=mask2|BW;
                          end
                          
                          %plotting boundaries
                          B=bwboundaries(BW);
                          figure(caIMG_fig);
                          for k2 = 1:length(B)
                             boundary = B{k2};
                             plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                          end
                          
                      end
                      BW=mask2;
                   else
                      combined_name_for_ctFIRE=[combined_name_for_ctFIRE '_' Data{handles.Indices(k,1),1}];
                      data2=[];vertices=[];
                      if(separate_rois.(Data{handles.Indices(k,1),1}).shape==1)
                        data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices =[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==2)
                          vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==3)
                          data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          s1=size(caIMG,1);s2=size(caIMG,2);
                          for m=1:s1
                              for n=1:s2
                                    dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                    if(dist<=1.00)
                                        BW(m,n)=logical(1);
                                    else
                                        BW(m,n)=logical(0);
                                    end
                              end
                          end
                      elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==4)
                          vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      end
                      
                   end
                   
                      s1=size(caIMG,1);s2=size(caIMG,2);
%                       for i=2:s1-1
%                             for j=2:s2-1
%                                 North=BW(i-1,j);NorthWest=BW(i-1,j-1);NorthEast=BW(i-1,j+1);
%                                 West=BW(i,j-1);East=BW(i,j+1);
%                                 SouthWest=BW(i+1,j-1);South=BW(i+1,j);SouthEast=BW(i+1,j+1);
%                                 if(BW(i,j)==logical(1)&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
%                                     roi_boundary(i,j,1)=uint8(255);
%                                     roi_boundary(i,j,2)=uint8(255);
%                                     roi_boundary(i,j,3)=uint8(0);
%                                 end
%                             end
%                       end
                  B=bwboundaries(BW);
                  figure(caIMG_fig);
                  for k2 = 1:length(B)
                     boundary = B{k2};
                     plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                  end
                      mask=mask|BW;
               end
               % if size of the caIMG is big- then to plot the boundary of
               % ROI right - starts
%                   im_fig_size=get(im_fig,'Position');
%                   im_fig_width=im_fig_size(3);im_fig_height=im_fig_size(4);
%                   s1=size(caIMG,1);s2=size(caIMG,2);
%                   factor1=ceil(s1/im_fig_width);factor2=ceil(s2/im_fig_height);
%                   if(factor1>factor2)
%                      dilation_factor=factor1; 
%                   else
%                      dilation_factor=factor2;
%                   end
%                   if(dilation_factor>1)
%                       
%                     roi_boundary=dilate_boundary(roi_boundary,dilation_factor);
%                   end
                % if size of the caIMG is big- then to plot the boundary of
               % ROI right - ends
               if(get(index_box,'Value')==1)
                   for k=1:s3
                     figure(caIMG_fig);ROI_text(k)=text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                       %text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                   end
                end
               gmask=mask;
               %figure;imshow(255*uint8(gmask));
               %clf(im_fig);figure(im_fig);imshow(overlaid_caIMG+roi_boundary,'Border','tight');hold on;
              %backup_fig=copyobj(im_fig,0);set(backup_fig,'Visible','off');  
              
     end
     %display(cell_selection_data);
       % display(combined_name_for_ctFIRE);
      
        function[output_boundary]=dilate_boundary(boundary,dilation_factor)
            % for dilation_factor 2 and 3 the mask will be 3*3 block for
            % 4,5 it is 5*5 block and so on
           % for dilation_factor 2 and 3 the mask will be 3*3 block for
            % 4,5 it is 5*5 block and so on
            output_boundary(:,:,:)=boundary(:,:,:);
            dilation_factor=uint8(dilation_factor);
           if(dilation_factor==2*(dilation_factor/2))
              %dilation_factor is an even number
              block_size=dilation_factor+1;
           else
              %dilation_factor is an odd number
              block_size=dilation_factor;
           end
           
           s1_boundary=size(boundary,1);s2_boundary=size(boundary,2);
           buffer_size=(block_size+1)/2;
           buffer_size=double(buffer_size);
           
           for i2=buffer_size:s1_boundary-buffer_size
               for j2=buffer_size:s2_boundary-buffer_size
                    if(boundary(i2,j2,1)==uint8(255))
                        for m2=i2-buffer_size+1:i2+buffer_size-1
                            for n2=j2-buffer_size+1:j2+buffer_size-1
                               %for yellow color
                                output_boundary(m2,n2,1)=uint8(255);
                                output_boundary(m2,n2,2)=uint8(255);
                                output_boundary(m2,n2,3)=uint8(0);
                            end
                        end
                    end
               end
           end

        end
        hold off;% YL
        
        figure(roi_mang_fig); % opening the manager as the open window, previously the caIMG window was the current open window
        
    end

    function[xmid,ymid]=midpoint_fn(BW)
           kip=bwboundaries(BW);
            xcenters=0;ycenters=0;%store the ans
            for counter=1:size(kip,2)
                %runs number of times number of ROIs are present
                kipTemp=kip{1,counter};
                xcenters(counter)=xcenters(counter)+mean(kipTemp(:,1));
                ycenters(counter)=ycenters(counter)+mean(kipTemp(:,2));
            end
            xmid=mean(xcenters);ymid=mean(ycenters);
    end 
        
    function[]=rename_roi(object,handles)
        %display(cell_selection_data);
        index=cell_selection_data(1,1);
        %defining pop up -starts
        position=[300 300 200 200];
        left=position(1);bottom=position(2);ROIwidth=position(3);ROIheight=position(4);
        
        rename_roi_popup=figure('Units','pixels','Position',[left+ROIwidth+15 bottom+ROIheight-200 200 100],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);
        message_box=uicontrol('Parent',rename_roi_popup,'Style','text','Units','normalized','Position',[0.05 0.75 0.9 0.2],'String','Enter the new name below','BackgroundColor',defaultBackground);
        newname_box=uicontrol('Parent',rename_roi_popup,'Style','edit','Units','normalized','Position',[0.05 0.2 0.9 0.45],'String','','BackgroundColor',defaultBackground,'Callback',@ok_fn);
        ok_box=uicontrol('Parent',rename_roi_popup,'Style','Pushbutton','Units','normalized','Position',[0.5 0.05 0.4 0.2],'String','Ok','BackgroundColor',defaultBackground,'Callback',@ok_fn);
        %defining pop up -ends
        
        %2 make new field delete old in ok_fn
        function[]=ok_fn(object,handles)
           new_fieldname=get(newname_box,'string');
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
               separate_rois.(new_fieldname)=separate_rois.(temp_fieldnames{index,1});
               separate_rois=rmfield(separate_rois,temp_fieldnames{index,1});
               save(fullfile(ROImanDir,roiMATname),'separate_rois','-append');
                update_rois;
                close(rename_roi_popup);% closes the dialgue box
           else
               set(status_message,'String','ROI with the entered name already present, use another name');
               close;%closes the rename window
               error_figure=figure('Units','pixels','Position',[left+ROIwidth+15 bottom+ROIheight-200 200 100],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);
               error_message_box=uicontrol('Parent',error_figure,'Style','text','Units','normalized','Position',[0.05 0.05 0.9 0.9],'String','Error-Name Already Exists','ForegroundColor',[1 0 0],'FontSize',15);
               pause(2);
               close(error_figure);
           end
        end
     end

    function[]=delete_roi(object,handles)
        %display(cell_selection_data);
        %display(size(cell_selection_data,1));
        %defining pop up -starts
       temp_fieldnames=fieldnames(separate_rois);
       if(size(cell_selection_data,1)==1)
           % Single ROI is deleted 
           message='ROI ';endmessage=' is deleted';
       else
           %multiple ROIs deleted
           message='ROIs ';endmessage=' are deleted';
       end
       for i=1:size(cell_selection_data,1)
           index=cell_selection_data(i,1);
           if(i==1)
                message=[message ' ' temp_fieldnames{index,1}];
           else
               message=[message ',' temp_fieldnames{index,1}];
           end
            separate_rois=rmfield(separate_rois,temp_fieldnames{index,1});
       end
       message=[message endmessage];
       set(status_message,'String',message);
       save(fullfile(ROImanDir,roiMATname),'separate_rois');
        update_rois;
        %defining pop up -ends
        
        %2 make new field delete old in ok_fn
       
     end
 
    function[]=measure_roi(object,handles)
       s1=size(caIMG,1);s2=size(caIMG,2); 
       Data=get(roi_table,'Data');
       s3=size(cell_selection_data,1);%display(s3);
       %display(cell_selection_data);
       roi_number=size(cell_selection_data,1);
        measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 470 300],'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
        measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
        names=fieldnames(separate_rois);
        measure_data{1,1}='Names';measure_data{1,2}='Min pixel value';measure_data{1,3}='Max pixel value';measure_data{1,4}='Area';measure_data{1,5}='Mean pixel value';
        measure_index=2;
       for k=1:s3
           data2=[];vertices=[];
          %display(Data{cell_selection_data(k,1),1});
          %%display(separate_rois.(Data{handles.Indices(k,1),1}).roi);
          if (iscell(separate_rois.(Data{cell_selection_data(k,1),1}).roi)==0)
              if(separate_rois.(Data{cell_selection_data(k,1),1}).shape==1)
                %display('rectangle');
                % vertices is not actual vertices but data as [ a b c d] and
                % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                %figure;imshow(255*uint8(BW));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==2)
                  %display('freehand');
                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                  %figure;imshow(255*uint8(BW));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==3)
                  %display('ellipse');
                  data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                  %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                  %the rect enclosing the ellipse. 
                  % equation of ellipse region->
                  % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                  s1=size(caIMG,1);s2=size(caIMG,2);
                  for m=1:s1
                      for n=1:s2
                            dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                            %%display(dist);pause(1);
                            if(dist<=1.00)
                                BW(m,n)=logical(1);
                            else
                                BW(m,n)=logical(0);
                            end
                      end
                  end
                  %figure;imshow(255*uint8(BW));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==4)
                  %display('polygon');
                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                  %figure;imshow(255*uint8(BW));
              end
          elseif (iscell(separate_rois.(Data{cell_selection_data(k,1),1}).roi)==1)
              s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
              BW(1:s1,1:s2)=logical(0);
              for m=1:s_subcomps
                  if(separate_rois.(Data{cell_selection_data(k,1),1}).shape{m}==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{m};
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW2=roipoly(caIMG,vertices(:,1),vertices(:,2));
                    %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{m}==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi{m};
                      BW2=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{m}==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{m};
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      %s1=size(caIMG,1);s2=size(caIMG,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW2(m,n)=logical(1);
                                else
                                    BW2(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{m}==4)
                      %display('polygon');
                      vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi{m};
                      BW2=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      %figure;imshow(255*uint8(BW));
                  end
                  BW=BW|BW2;
              end
          end
          [min,max,area,mean]=roi_stats(BW);
          measure_data{k+1,1}=Data{cell_selection_data(k,1),1};
          measure_data{k+1,2}=min;
          measure_data{k+1,3}=max;
          measure_data{k+1,4}=area;
          measure_data{k+1,5}=mean;
       end
       set(measure_table,'Data',measure_data);
        set(measure_fig,'Visible','on');
       set(status_message,'string','Refer to the new window containing table for features of ROI(s)');
        
     function[min,max,area,mean]=roi_stats(BW)
        min=255;max=0;mean=0;area=0;
        for i=1:s1
            for j=1:s2
                if(BW(i,j)==logical(1))
                    if(caIMG(i,j)<min)
                        min=caIMG(i,j);
                    end
                    if(caIMG(i,j)>max)
                        max=caIMG(i,j);
                    end
                    mean=mean+double(caIMG(i,j));
                    area=area+1;
                end
            end
        end
        mean=double(mean)/double(area);
     end
       
    end
     
    function[]=index_fn(object,handles)
        if(get(index_box,'Value')==1)
            Data=get(roi_table,'Data');
            s3=size(xmid,2);%display(s3);
           for k=1:s3
             figure(caIMG_fig);ROI_text(k)=text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
             set(ROI_text(k),'Visible','on');
           end
        elseif(get(index_box,'Value')==0)
           s3=size(xmid,2);%display(s3);
           for k=1:s3
             set(ROI_text(k),'Visible','off');
           end 
        end
    end
%--------------------------------------------------------------------------
%start post-processing with ROI analyzer
%YL December2015: modified from CTroi ROI analyzer
    function[]=analyzer_launch_fn(object,handles)
        %        1 define buttons 2 from cell_select data define mask where mask=mask|BW
        %        3 locate curveles/fiber positions based on the coordinates recorded in the .csv
        %        fiber feature file.
        %        4 generate curvelets/fiber data
        %        5 implement "looking fibers" function
        %        6 implement "generate stats" function
        %        7 implement automatic ROI detection
       % CA ROIanalyzer output folder for individual image
%        
        if numSections > 1
            display(' ROI post-analysis on a single slice of a stack')
        end
        CAroiANA_ifolder = ROIpostIndDir;
        if(exist(CAroiANA_ifolder,'dir')==0)%check for ROI folder
               mkdir(CAroiANA_ifolder);
        end
        
        Data=get(roi_table,'Data');
   
        global plot_statistics_box;
        set(status_message,'string','Select ROI in the ROI manager and then select an operation in ROI analyzer window');
   
        
        roi_anly_fig = figure(243); clf;
        set(roi_anly_fig,'Resize','off','Color',defaultBackground,'Units','pixels','Position',[50+round(SW/5)+relative_horz_displacement 50 round(0.125*SW) round(SH*0.25)],'Visible','off','MenuBar','none','name','Post-processing with ROI analyzer','NumberTitle','off','UserData',0);
        
        panel=uipanel('Parent',roi_anly_fig,'Units','Normalized','Position',[0 0 1 1]);
        filename_box2=uicontrol('Parent',panel,'Style','text','String','ROI Analyzer','Units','normalized','Position',[0.05 0.86 0.9 0.14]);%,'BackgroundColor',[1 1 1]);
        check_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Check Fibres','Units','normalized','Position',[0.05 0.72 0.9 0.14],'Callback',@check_fibres_fn,'TooltipString','Shows Fibers within ROI');
        plot_statistics_box=uicontrol('Parent',panel,'Style','pushbutton','String','Plot statistics','Units','normalized','Position',[0.05 0.58 0.9 0.14],'Callback',@plot_statisitcs_fn,'enable','off','TooltipString','Plots statistics of fibers shown');
        more_settings_box2=uicontrol('Parent',panel,'Style','pushbutton','String','More Settings','Units','normalized','Position',[0.05 0.44 0.9 0.14],'Callback',@more_settings_fn,'TooltipString','Change Fiber source ,Fiber selection definition','Enable','off');
        generate_stats_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Generate Stats','Units','normalized','Position',[0.05 0.30 0.9 0.14],'Callback',@generate_stats_fn,'TooltipString','Displays and produces Excel file of statistics','Enable','off');
        automatic_roi_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Automatic ROI detection','Units','normalized','Position',[0.05 0.16 0.9 0.14],'Callback',@automatic_roi_fn,'TooltipString','Function to find ROI with max avg property value','Enable','off');
        visualisation_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Visualisation of fibres','Units','normalized','Position',[0.05 0.02 0.9 0.14],'Callback',@visualisation,'Enable','off','TooltipString','Shows Fibres in different colors based on property values');
        
        %variables for this function - used in sub functions
       
        mask = [];
        fiber_source = 'Curvelets';%other value can be ctFIRE
        fiber_method = 'Center';   %other value can be whole
        fiber_data = [];
        global first_time;
        first_time = 1;
        SHG_pixels = 0; SHG_ratio = 0; total_pixels = 0;
        SHG_threshold = 5;%  default value
        SHG_threshold_method = 0;%0 for hard threshold and 1  for soft threshold
        %analyzer functions -start
        check_fibres_fn
        function[]=check_fibres_fn(handles,object)
            %'Rectangle','Freehand','Ellipse','Polygon' = 1,2,3,4
            % to access selectedd rois - say names contain the names of all
            % rois of the image then roi
            % =separate_rois(names(cell_selection_data(i,1))).roi
            %close(im_fig);
            
            plot_fiber_centers=0;%1 if we need to plot and 0 if not
            %im_fig=copyobj(backup_fig,0);
            fiber_data = [];
            s3 = size(cell_selection_data,1);s1 = size(caIMG,1);s2 = size(caIMG,2);
            indices = [];
            for k=1:s3
                indices(k)=cell_selection_data(k,1);
            end
            
            temp_array(1:s3)=0;
            for m=1:s3
                temp_array(m)=cell_selection_data(m,1);
            end
            
%             display_rois(temp_array);
            names = fieldnames(separate_rois);%display(names);
            
%             for k = 1:s3
%                 BW = BWv{k};
%                 %now finding the SHG pixels for each ROI
%                 SHG_pixels(k)=0; total_pixels_temp = 0; SHG_ratio(k)=0;
%                 for m=1:s1
%                     for n=1:s2
%                         if(BW(m,n) == logical(1) && caIMG(m,n)>=SHG_threshold)
%                             SHG_pixels(k)=SHG_pixels(k)+1;
%                         end
%                         if(BW(m,n)==logical(1))
%                             total_pixels_temp=total_pixels_temp+1;
%                         end
%                     end
%                 end
%                 SHG_ratio(k)=SHG_pixels(k)/total_pixels_temp;
%                 total_pixels(k)=total_pixels_temp;
%             end
%             display(SHG_pixels);display(SHG_ratio);display(total_pixels);display(SHG_threshold);
                 
            %mask defined successfully
            %figure;imshow(255*uint8(mask),'Border','tight');
            
            size_fibers=length(fibFeat);
            
            if(strcmp(fiber_source,'Curvelets')==1)
                fiber_data = fibFeat;
                
                %display(fiber_data);
            elseif(strcmp(fiber_source,'postPRO')==1)
                fiber_data = [];
                set(status_message,'String','Post Processing Data not present');
            end
      
            marS = 10 ;linW = 1; len = size(caIMG,1)/64;
            
%    fieldnames(matdata) = ('fibFeat' 'tempFolder' 'keep' 'distThresh' 'fibProcMeth'...
% 'imgNameP'  'featNames','bndryMeas', 'tifBoundary','coords');                
            distThresh = matdata.distThresh;
            tifBoundary = matdata.tifBoundary;
            bndryMode = tifBoundary;
            coords = matdata.coords; 
            figure(caIMG_fig);hold on; 
           % if csv or tif boundary exists, overlay it on the original image
           if bndryMode == 3 %YL: only consider tiff boundary so far 
               bndryFnd = checkBndryFiles(bndryMode, pathname,{[filename fileEXT ]});
               if (~isempty(bndryFnd))
                   if bndryMode == 1 || bndryMode == 2
                       
                       coords = csvread([pathName sprintf('boundary for %s.csv',item_selected)]);
                       plot(coords(:,1),coords(:,2),'m','Parent',overAx);
                       plot(coords(:,1),coords(:,2),'*m','Parent',overAx);
                       
                   elseif bndryMode == 3
                       if ~exist(fullfile(pathname,'CA_Boundary'),'dir')
                           mkdir(fullfile(pathname,'CA_Boundary'));
                       end
                       bff = fullfile(pathname,'CA_Boundary', sprintf('mask for %s%s.tif',filename,fileEXT));
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
           
            for i = 1: length(fibFeat)
                
                ca = fibFeat(i,4)*pi/180;
                xc = fibFeat(i,3);
                yc = fibFeat(i,2);
                
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
                    ind2 = find((fibFeat(:,28) <= matdata.distThresh & fibFeat(:,29) == 0) == 1); % within the outside boundary distance but not within the inside 
                    
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
       
                % show curvelet direction
                xc1 = (xc - len * cos(ca));
                xc2 = (xc + len * cos(ca));
                yc1 = (yc + len * sin(ca));
                yc2 = (yc - len * sin(ca));
                
               if (fiber_data(i,1) == 0)
                    plot(xc,yc,'r.','MarkerSize',marS,'Parent',overAx); % show curvelet center
                    plot([xc1 xc2],[yc1 yc2],'r-','linewidth',linW,'Parent',overAx); % show curvelet angle
               elseif (fiber_data(i,1) >= 1)         
                   plot(xc,yc,'g.','MarkerSize',marS,'Parent',overAx); % show curvelet center 
                   plot([xc1 xc2],[yc1 yc2],'g-','linewidth',linW,'Parent',overAx); % show curvelet angle
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
            
            CAAfig = figure(243);clf, set(CAAfig,'position', [300 400 200*length(BWv) 200],'visible','off');
                      
            for i = 1:length(BWv)
                ind = find( fiber_data(:,1) == i);
                ROIfeature{i} = fibFeat(ind,featureLABEL);
                roiNamelist = Data{cell_selection_data(i,1),1};  % roi name on the list
                figure(CAAfig); subplot(1,length(BWv),i);
                hist(ROIfeature{i});
                xlabel('Angle [degrees]');
                ylabel('Frequency');
                title(sprintf('%s',roiNamelist));
                axis square
                
                
                if numSections > 1
                    roiANAiname = [filename,sprintf('_s%d_features_',i),roiNamelist,'.csv'];
                elseif numSections == 1
                    roiANAiname = [filename,'_features_',roiNamelist,'.csv'];
                end
                
              if  exist(fullfile(CAroiANA_ifolder,roiANAiname),'file')
                  delete(fullfile(CAroiANA_ifolder,roiANAiname));
              end
                csvwrite(fullfile(CAroiANA_ifolder,roiANAiname),fibFeat(ind,:));
           
            end
            
            hold off   
            
            % figure(caIMG_fig)
%             set(visualisation_box2,'Enable','on');
%             set(plot_statistics_box,'Enable','on');
%             set(generate_stats_box2,'Enable','on');
            
        end
    end

%--------------------------------------------------------------------------
	function[]=CA_to_roi_fn(object,handles)
        
        %% Option for ROI analysis
     % save current parameters
       if CAcontrol.fibMode ~= 0
           set(status_message, 'string', ' ROI analysis can not be applied to the CT-FIRE+CA mode, while ROI-postprocssing can.' )
           return
       end
           
        ROIanaChoice = questdlg('ROI analysis for the cropped ROI of rectgular shape or the ROI mask of any shape?', ...
            'ROI analysis','Cropped rectangular ROI','ROI mask of any shape','Cropped rectangular ROI');
        if isempty(ROIanaChoice)
           set(status_message, 'string', ' Choose the ROI analysis type to proceed.' )
           return 
        end
        switch ROIanaChoice
            case 'Cropped rectangular ROI'
                cropIMGon = 1;
                disp('CA alignment analysis on the the cropped rectangular ROIs')
                disp('loading ROI')
                          
            case 'ROI mask of any shape'
                cropIMGon = 0;
                disp('CA alignment analysis on the the ROI mask of any shape');
                disp('loading ROI')
                
        end
  
        
       % steps
%        1 find the caIMG within the roi using gmask
%        2 save the caIMG in ROI management
%        3 find a way to run ctFIRE on the saved caIMG
%        4 prompt the user to call the ctFIRE by default values or call the interface itself
        %5 call ctFIRE by default value
%         
%         steps for the sub function
%         1 run a par for loop
%         2 check if one selection is a combination
%         3 if not then write the caIMG 
%         4 run the ctFIRE
%         5 delete the caIMG
           
        s1=size(caIMG,1);s2=size(caIMG,2);
        temp_caIMG(1:s1,1:s2)=uint8(0);
        if(exist(ROIanaIndDir,'dir')==0)%check for ROI folder
               mkdir(ROIanaIndDir);
        end
        if(exist(ROIanaIndOutDir,'dir')==0)%check for ROI folder
               mkdir(ROIanaIndOutDir);
        end
        
% load CurveAlign parameters
            CA_P = load(fullfile(pathname,'currentP_CA.mat'));
            
% structure CA_P include fields: 
%'keep', 'coords', 'distThresh', 'makeAssocFlag', 'makeMapFlag', 
%'makeOverFlag', 'makeFeatFlag', 'infoLabel', 'bndryMode', 'bdryImg', 
%'pathName', 'fibMode','numSections','advancedOPT'
        BWcell = CA_P.bdryImg;
        bndryMode = CA_P.bndryMode;
        distThresh = CA_P. distThresh;
        ROIbw = BWcell;  %  for the full size image

        for i = 1:numSections
            s_roi_num=size(cell_selection_data,1);
            Data=get(roi_table,'Data');
            separate_rois_copy=separate_rois;
            cell_selection_data_copy=cell_selection_data;
            Data_copy=Data;
            if numSections == 1
              caIMG_copy=caIMG(:,:,1);pathname_copy=pathname;filename_copy=filename;
            else
                IMGtemp = imread(IMGname,i);
                if size(IMGtemp,3) > 1
                    if plotrgbFLAG == 0
                        IMGtemp = rgb2gray(IMGtemp);
                        disp('color image was loaded but converted to grayscale image')
                        caIMG(:,:,1) = IMGtemp;
                        caIMG(:,:,2) = IMGtemp;
                        caIMG(:,:,3) = IMGtemp;
                        
                    elseif plotrgbFLAG == 1
                        caIMG = IMGtemp;
                        disp('display color image');
                        
                    end
                end
                caIMG_copy = caIMG(:,:,1);
                delete IMGtemp
            end
                      
           for k=1:s_roi_num
               ROIshape_ind = separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape;
               if cropIMGon == 0     % use ROI mask
                   
                   if(ROIshape_ind == 1)
                       data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                       a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                       vertices =[a,b;a+c,b;a+c,b+d;a,b+d;];
                       BW=roipoly(caIMG_copy,vertices(:,1),vertices(:,2));
                   elseif (ROIshape_ind == 2 )  % 2: freehand
                       vertices = separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                       BW=roipoly(caIMG_copy,vertices(:,1),vertices(:,2));
                   elseif (ROIshape_ind == 3 )  % 3: oval
                       data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                       a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                       %s1=size(image_copy,1);s2=size(image_copy,2);
                       for m=1:s1
                           for n=1:s2
                               dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                               if(dist<=1.00)
                                   BW(m,n)=logical(1);
                               else
                                   BW(m,n)=logical(0);
                               end
                           end
                       end
                   
                   elseif (ROIshape_ind == 4 )  % 4: polygon
                       vertices = separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                       BW=roipoly(caIMG_copy,vertices(:,1),vertices(:,2));
                       
                   else
                       disp('CurveAlign ROI analyis  works on cropped rectangular ROI shape rather than BW ')
                       
                       
                   end
                   [yc xc] = midpoint_fn(BW); z = i;
                   
                   ROIimg = caIMG_copy.*uint8(BW);
                   
               elseif cropIMGon == 1 
                   
                   if ROIshape_ind == 1   % use cropped ROI image
                       data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                       a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                       ROIimg = caIMG_copy(b:b+d-1,a:a+c-1); % YL to be confirmed
                       % add boundary conditions
                       if ~isempty(BWcell)
                           ROIbw  =  BWcell(b:b+d-1,a:a+c-1);  
                       else
                           ROIbw = [];
                       end
                       xc = round(a+c/2); yc = round(b+d/2); z = i;
                   else
                       error('cropped image ROI analysis for shapes other than rectangle is not availabe so far')

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
                   roiBWname = sprintf('mask for %s.tif',roiNamefull);
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
               
%                CA_P.makeMapFlag =1; CA_P.makeOverFlag = 1;
               [~,stats]=processROI(ROIimg, roiNamefull, ROIanaIndOutDir, CA_P.keep, CA_P.ROIcoords, CA_P.distThresh, CA_P.makeAssocFlag, CA_P.makeMapFlag, CA_P.makeOverFlag, CA_P.makeFeatFlag, 1, CA_P.infoLabel, CA_P.bndryMode, CA_P.ROIbdryImg, ROIanaIndDir, CA_P.fibMode, CA_P.advancedOPT,1);
               CAroi_data_current = get(CAroi_output_table,'Data');
                 if ~isempty(CAroi_data_current)
                     items_number_current = length(CAroi_data_current(:,1));
                 else
                     items_number_current = 0;
                 end
                 
                 CAroi_data_add = {items_number_current+1,sprintf('%s',filename),sprintf('%s',roiNamelist),ROIshapes{ROIshape_ind},xc,yc,z,stats(1),stats(5)}; 
                 CAroi_data_current = [CAroi_data_current;CAroi_data_add];
                 set(CAroi_output_table,'Data',CAroi_data_current)
                 figure(CAroi_table_fig)
      
        end
            
%     combined_name_for_ctFIRE_copy=combined_name_for_ctFIRE;
        

        end 
        
        function[xmid,ymid]=midpoint_fn(BW)
           kip=bwboundaries(BW);
            xcenters=0;ycenters=0;%store the ans
            for counter=1:size(kip,2)
                %runs number of times number of ROIs are present
                kipTemp=kip{1,counter};
                xcenters(counter)=xcenters(counter)+mean(kipTemp(:,1));
                ycenters(counter)=ycenters(counter)+mean(kipTemp(:,2));
            end
            xmid=mean(xcenters);ymid=mean(ycenters);
        end 
        
        
    end	
  
    function[]=load_roi_fn(object,handles)
        %file extension of the iamge assumed is .txt
        %[filename,pathname,filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select caIMG',pseudo_address,'MultiSelect','off'); 
        try 
            [filename_temp,pathname_temp,filterindex]=uigetfile({'*.txt'},'Select ROI',pseudo_address,'MultiSelect','off');
            fileID=fopen(fullfile(pathname_temp,filename_temp));
            combined_rois_present=fscanf(fileID,'%d\n',1);
            if(combined_rois_present==0)
                % for one ROI
                new_roi=[];
                active_filename=filename_temp; %format- testcaIMG1_ROI1_coordinates.txt
               underscore_places=findstr(active_filename,'_');
               actual_filename=active_filename(1:underscore_places(end-1)-1);
               roi_name=active_filename(underscore_places(end-1)+1:underscore_places(end)-1);
               display(fullfile(pathname_temp,filename_temp));%pause(5);
               total_rois_number=fscanf(fileID,'%d\n',1);
                roi_number=fscanf(fileID,'%d\n',1);
                date=fgetl(fileID);
                time=fgetl(fileID);
                shape=fgetl(fileID);
                vertex_size=fscanf(fileID,'%d\n',1);
                %roi_temp(1:vertex_size,1:4)=0;
                for i=1:vertex_size
                  roi_temp(i,:)=str2num(fgets(fileID));  
                end

                count=1;count_max=1;
                if(isempty(separate_rois)==0)
                   while(count<1000)
                      fieldname=['ROI' num2str(count)];
                       if(isfield(separate_rois,fieldname)==1)
                          count_max=count;
                       end
                      count=count+1;
                   end
                   fieldname=['ROI' num2str(count_max+1)];
                else
                   fieldname=['ROI1'];
                end
                display(fieldname);

                separate_rois.(fieldname).roi=roi_temp;
                separate_rois.(fieldname).date=date;
                separate_rois.(fieldname).time=time;
                separate_rois.(fieldname).shape=str2num(shape);
                save(fullfile(ROImanDir,roiMATname),'separate_rois','-append'); 
                update_rois;
            elseif(combined_rois_present==1)
                % for multiple ROIs
    %             num_temp=size(filename_temp,2);
                total_rois_number=fscanf(fileID,'%d\n',1);
                filename_temp='combined_ROI_';
                count=1;count_max=1;
                if(isempty(separate_rois)==0)
                   while(count<1000)
                      filename_temp=['combined_ROI_' num2str(count)];
                       if(isfield(separate_rois,filename_temp)==1)
                          count_max=count;
                       end
                      count=count+1;
                   end
                   filename_temp=['combined_ROI_' num2str(count_max)];
                else
                   filename_temp=['combined_ROI_1'];
                end
                display(filename_temp);display(total_rois_number);

                for k=1:total_rois_number
                    if(k~=1)
                        combined_rois_present=fscanf(fileID,'%d\n',1);
                    end
                    roi_number=fscanf(fileID,'%d\n',1);display(roi_number);
                    date=fgetl(fileID);display(date);
                    time=fgetl(fileID);display(time);
                    shape=fgetl(fileID);display(shape);
                    vertex_size=fscanf(fileID,'%d\n',1);display(vertex_size);
                    %roi_temp(1:vertex_size,1:4)=0;
                    for i=1:vertex_size
                      roi_temp(i,:)=str2num(fgets(fileID));  
                    end
                    separate_rois.(filename_temp).roi{k}=roi_temp;
                    separate_rois.(filename_temp).date=date;
                    separate_rois.(filename_temp).time=time;
                    separate_rois.(filename_temp).shape{k}=str2num(shape);

                end
                save(fullfile(ROImanDir,roiMATname),'separate_rois','-append'); 
                update_rois;
            end
            Data=get(roi_table,'Data');
            display_rois(size(Data,1));
        catch
            set(status_message,'String','error in loading ROI');
        end
        
    end

    function[BW]=get_mask(Data,iscell_variable,roi_index_queried)
        k=roi_index_queried;
        if(iscell_variable==0)
              if(separate_rois.(Data{cell_selection_data(k,1),1}).shape==1)
                data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==2)
                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==3)
                  data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                  s1=size(caIMG,1);s2=size(caIMG,2);
                  for m=1:s1
                      for n=1:s2
                            dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                            if(dist<=1.00)
                                BW(m,n)=logical(1);
                            else
                                BW(m,n)=logical(0);
                            end
                      end
                  end
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==4)
                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
             end
        end
    end

    function[]=display_rois(indices)
       % format of indices = [1, 2 ,3] 
       % takes in number array named 'indices' 
       % responsibility of calling function to send valid ROI numbers from
       % the uitable
       %working - same as cell_selection_fn . Only difference is that the
       %numbers would be taken not from uitable but as indices
        stemp=size(indices,2);
        %display(indices),display(stemp);
        figure(caIMG_fig);%imshow(caIMG);
        warning('off');
        Data=get(roi_table,'Data'); %display(Data(1,1));
         combined_rois_present=0; 
         for i=1:stemp
             if(iscell(separate_rois.(Data{indices(i),1}).shape)==1)
                combined_rois_present=1; break;
             end
         end

        if(combined_rois_present==0) 
            xmid=[];ymid=[];
               s1=size(caIMG,1);s2=size(caIMG,2); 
               mask(1:s1,1:s2)=logical(0);
               BW(1:s1,1:s2)=logical(0);
               roi_boundary(1:s1,1:s2,1)=uint8(0);roi_boundary(1:s1,1:s2,2)=uint8(0);roi_boundary(1:s1,1:s2,3)=uint8(0);
               overlaid_caIMG(1:s1,1:s2,1)=caIMG(1:s1,1:s2);overlaid_caIMG(1:s1,1:s2,2)=caIMG(1:s1,1:s2);
               Data=get(roi_table,'Data');
               
               s3=stemp;
               figure(caIMG_fig);
               for k=1:s3
                   data2=[];vertices=[];
                  if(separate_rois.(Data{indices(k),1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{indices(k),1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                    
                  elseif(separate_rois.(Data{indices(k),1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{indices(k),1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  elseif(separate_rois.(Data{indices(k),1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{indices(k),1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(caIMG,1);s2=size(caIMG,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{indices(k),1}).shape==4)
                      %display('polygon');
                      vertices=separate_rois.(Data{indices(k),1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  end
                  mask=mask|BW;
                  B=bwboundaries(BW);%display(length(B));
                  for k2 = 1:length(B)
                     boundary = B{k2};
                     plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                  end
                  [xmid(k),ymid(k)]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
               end
               gmask=mask;
                if(get(index_box,'Value')==1)
                   for k=1:s3
                      figure(caIMG_fig);ROI_text(k)=text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on; 
                     %text(ymid(k),xmid(k),Data{indices(k),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
                   end
                end
    
     elseif(combined_rois_present==1)
               
               s1=size(caIMG,1);s2=size(caIMG,2);
               mask(1:s1,1:s2)=logical(0);
               BW(1:s1,1:s2)=logical(0);
               roi_boundary(1:s1,1:s2,1)=uint8(0);roi_boundary(1:s1,1:s2,2)=uint8(0);roi_boundary(1:s1,1:s2,3)=uint8(0);
               overlaid_caIMG(1:s1,1:s2,1)=caIMG(1:s1,1:s2);overlaid_caIMG(1:s1,1:s2,2)=caIMG(1:s1,1:s2);
               mask2=mask;
               Data=get(roi_table,'Data');
               s3=stemp;
               figure(caIMG_fig);
               for k=1:s3
                   if (iscell(separate_rois.(Data{indices(k),1}).roi)==1)
                      s_subcomps=size(separate_rois.(Data{indices(k),1}).roi,2);
                     % display(s_subcomps);
                     
                      for p=1:s_subcomps
                          data2=[];vertices=[];
                          if(separate_rois.(Data{indices(k),1}).shape{p}==1)
                            data2=separate_rois.(Data{indices(k),1}).roi{p};
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{indices(k),1}).shape{p}==2)
                              vertices=separate_rois.(Data{indices(k),1}).roi{p};
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{indices(k),1}).shape{p}==3)
                              data2=separate_rois.(Data{indices(k),1}).roi{p};
                              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                              s1=size(caIMG,1);s2=size(caIMG,2);
                              for m=1:s1
                                  for n=1:s2
                                        dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                        if(dist<=1.00)
                                            BW(m,n)=logical(1);
                                        else
                                            BW(m,n)=logical(0);
                                        end
                                  end
                              end
                          elseif(separate_rois.(Data{indices(k),1}).shape{p}==4)
                              vertices=separate_rois.(Data{indices(k),1}).roi{p};
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          end
                          if(p==1)
                             mask2=BW; 
                          else
                             mask2=mask2|BW;
                          end
                          
                          %plotting boundaries
                          B=bwboundaries(BW);
                          figure(caIMG_fig);
                          for k2 = 1:length(B)
                             boundary = B{k2};
                             plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                          end
                      end
                      BW=mask2;
                   else
                      data2=[];vertices=[];
                      if(separate_rois.(Data{indices(k),1}).shape==1)
                        data2=separate_rois.(Data{indices(k),1}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{indices(k),1}).shape==2)
                          vertices=separate_rois.(Data{indices(k),1}).roi;
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{indices(k),1}).shape==3)
                          data2=separate_rois.(Data{indices(k),1}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          s1=size(caIMG,1);s2=size(caIMG,2);
                          for m=1:s1
                              for n=1:s2
                                    dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                    if(dist<=1.00)
                                        BW(m,n)=logical(1);
                                    else
                                        BW(m,n)=logical(0);
                                    end
                              end
                          end
                      elseif(separate_rois.(Data{indices(k),1}).shape==4)
                          vertices=separate_rois.(Data{indices(k),1}).roi;
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      end
                      
                   end
                   
                  s1=size(caIMG,1);s2=size(caIMG,2);
                  B=bwboundaries(BW);
                  
                  for k2 = 1:length(B)
                     boundary = B{k2};
                     plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                  end
                      mask=mask|BW;
               end
        end
        
        function[xmid,ymid]=midpoint_fn(BW)
           kip=bwboundaries(BW);
            xcenters=0;ycenters=0;%store the ans
            for counter=1:size(kip,2)
                %runs number of times number of ROIs are present
                kipTemp=kip{1,counter};
                xcenters(counter)=xcenters(counter)+mean(kipTemp(:,1));
                ycenters(counter)=ycenters(counter)+mean(kipTemp(:,2));
            end
            xmid=mean(xcenters);ymid=mean(ycenters);
        end 
        
    end

    function[]=showall_rois_fn(object,handles)
        Data=get(roi_table,'Data');
       if(get(showall_box,'Value')==1)
           stemp=size(Data,1);
           indices=1:stemp;
           display_rois(indices);
           for k2=1:stemp
              cell_selection_data(k2,1)=k2; cell_selection_data(k2,2)=1; 
           end
       else
           figure(caIMG_fig);imshow(caIMG);
       end
       % part to find xmid and ymid of all ROIs so that these can be used
       % in show_indices_fn
        Data=get(roi_table,'Data'); %display(Data(1,1));
         combined_rois_present=0; 
         stemp=size(Data,1);display(stemp);
         for i=1:stemp
             if(iscell(separate_rois.(Data{i,1}).shape)==1)
                combined_rois_present=1; break;
             end
         end

        if(combined_rois_present==0)      
                %xmid=[];ymid=[];
                s1=size(caIMG,1);s2=size(caIMG,2); 
               BW(1:s1,1:s2)=logical(0);
               s3=stemp;
               for k=1:s3
                   data2=[];vertices=[];
                  if(separate_rois.(Data{k,1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{k,1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                    
                  elseif(separate_rois.(Data{k,1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{k,1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  elseif(separate_rois.(Data{k,1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{k,1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(caIMG,1);s2=size(caIMG,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{k,1}).shape==4)
                      %display('polygon');
                      vertices=separate_rois.(Data{k,1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                  end
                  B=bwboundaries(BW);%display(length(B));
                  [xmid(k),ymid(k)]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
               end
               
                if(get(index_box,'Value')==1)
                   for k=1:s3
                     figure(caIMG_fig);ROI_text(k)=text(ymid(k),xmid(k),Data{k,1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                       %text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                   end
                end
        
                 backup_fig=copyobj(caIMG_fig,0);set(backup_fig,'Visible','off');
    
     elseif(combined_rois_present==1)
               
                s1=size(caIMG,1);s2=size(caIMG,2);
               BW(1:s1,1:s2)=logical(0);
               Data=get(roi_table,'Data');
               s3=stemp;
               for k=1:s3
                   if (iscell(separate_rois.(Data{cell_selection_data(k,1),1}).roi)==1)
                       s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                      for p=1:s_subcomps
                          data2=[];vertices=[];
                          if(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==1)
                            data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==2)
                              vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==3)
                              data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                              s1=size(caIMG,1);s2=size(caIMG,2);
                              for m=1:s1
                                  for n=1:s2
                                        dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                        if(dist<=1.00)
                                            BW(m,n)=logical(1);
                                        else
                                            BW(m,n)=logical(0);
                                        end
                                  end
                              end
                          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==4)
                              vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          end
                          if(p==1)
                             mask2=BW; 
                             [xmid(k),ymid(k)]=midpoint_fn(BW);
                          else
                             mask2=mask2|BW;
                          end
                          
                          %plotting boundaries
                          B=bwboundaries(BW);
                          figure(caIMG_fig);
                          for k2 = 1:length(B)
                             boundary = B{k2};
                             plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                          end
                          
                      end
                      BW=mask2;
                   else
                      data2=[];vertices=[];
                          if(separate_rois.(Data{k,1}).shape==1)
                            %display('rectangle');
                            % vertices is not actual vertices but data as [ a b c d] and
                            % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                            data2=separate_rois.(Data{k,1}).roi;
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(caIMG,vertices(:,1),vertices(:,2));

                          elseif(separate_rois.(Data{k,1}).shape==2)
                              %display('freehand');
                              vertices=separate_rois.(Data{k,1}).roi;
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));

                          elseif(separate_rois.(Data{k,1}).shape==3)
                              %display('ellipse');
                              data2=separate_rois.(Data{k,1}).roi;
                              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                              %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                              %the rect enclosing the ellipse. 
                              % equation of ellipse region->
                              % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                              s1=size(caIMG,1);s2=size(caIMG,2);
                              for m=1:s1
                                  for n=1:s2
                                        dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                        %%display(dist);pause(1);
                                        if(dist<=1.00)
                                            BW(m,n)=logical(1);
                                        else
                                            BW(m,n)=logical(0);
                                        end
                                  end
                              end
                              %figure;imshow(255*uint8(BW));
                          elseif(separate_rois.(Data{k,1}).shape==4)
                              %display('polygon');
                              vertices=separate_rois.(Data{k,1}).roi;
                              BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                          end
                          B=bwboundaries(BW);%display(length(B));
                          [xmid(k),ymid(k)]=midpoint_fn(BW);

                   end
                  s1=size(caIMG,1);s2=size(caIMG,2);
                  B=bwboundaries(BW);
                  figure(caIMG_fig);
                  for k2 = 1:length(B)
                     boundary = B{k2};
                     plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                  end
               end 
               if(get(index_box,'Value')==1)
                   for k=1:s3
                     figure(caIMG_fig);ROI_text(k)=text(ymid(k),xmid(k),Data{k,1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                       %text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 0]);hold on;
                   end
                end
               %gmask=mask;
        end
    end

    function[]=text_coordinates_to_file_fn()
       %saves a text file containing all the ROI coordinates in a file
       % text file destination is - fullfile(ROImanDir,[filename,'ROI_coordinates.txt']
        %format of text file=
%        Total ROIs
%        for each ROI- combined_roi_present , 
%        roi number , shape, coordinates in form of vertices - (x,y) - to be decided
       
    % This function also saves the masks for ROIs
    
       %run a loop for the number of ROIs
       %save coordinates of each in a separate line
       % insert a \n after every ROI
       Data=get(roi_table,'Data');
       stemp=size(Data,1);
       roi_names=fieldnames(separate_rois);
       s1=size(caIMG,1);s2=size(caIMG,2);
        for i=1:stemp
            destination=fullfile(ROImanDir,[filename,'_',roi_names{i,1},'_coordinates.txt']);
            fileID = fopen(destination,'wt');
            vertices=[];  BW(1:s1,1:s2)=logical(0);
             if(iscell(separate_rois.(Data{i,1}).shape)==0)
                 % no combined ROI present then 
%                  fprintf('shape of %d ROI = %d \n',i, separate_rois.(Data{i,1}).shape);
%                  fprintf('date=%s time=%s \n',separate_rois.(Data{i,1}).date,separate_rois.(Data{i,1}).time);
%                  fprintf('roi=%s\n',separate_rois.(Data{i,1}).roi);
                 num_of_rois=1;
                 fprintf(fileID,'%d\n',iscell(separate_rois.(Data{i,1}).shape));
                 fprintf(fileID,'%d\n%s\n%s\n%d\n',num_of_rois,separate_rois.(Data{i,1}).date,separate_rois.(Data{i,1}).time,separate_rois.(Data{i,1}).shape);                 
                 stemp1=size(separate_rois.(Data{i,1}).roi,1);
                 stemp2=size(separate_rois.(Data{i,1}).roi,2);
                 array=separate_rois.(Data{i,1}).roi;
                 if(separate_rois.(Data{i,1}).shape==1)
                     fprintf(fileID,'1\n');
                 elseif(separate_rois.(Data{i,1}).shape==2)
                     fprintf(fileID,'%d\n',stemp1);
                 elseif(separate_rois.(Data{i,1}).shape==3)
                     fprintf(fileID,'1\n');
                 elseif(separate_rois.(Data{i,1}).shape==4)
                     fprintf(fileID,'%d\n',stemp1);
                 end
                 
                 for m=1:stemp1
                     for n=1:stemp2
                        fprintf(fileID,'%d ',array(m,n));
                     end
                     fprintf(fileID,'\n');
                 end
                 fprintf(fileID,'\n');
                 %display(separate_rois.(Data{i,1}));
                  %pause(5);
                  if(separate_rois.(Data{i,1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{i,1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                  elseif(separate_rois.(Data{i,1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{i,1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  elseif(separate_rois.(Data{i,1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{i,1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(caIMG,1);s2=size(caIMG,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{i,1}).shape==4)
                      %display('polygon');
                      vertices=separate_rois.(Data{i,1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2)); 
                  end
                  %figure;imshow(255*uint8(BW));%pause(10);
                  imwrite(BW,fullfile(ROIanaIndDir, [filename '_'  (Data{i,1}) 'mask.tif']));
             elseif(iscell(separate_rois.(Data{i,1}).shape)==1)
                 s_subcomps=size(separate_rois.(Data{i,1}).roi,2);
                 for k=1:s_subcomps
                     num_of_rois=k;
                     fprintf(fileID,'%d\n',iscell(separate_rois.(Data{i,1}).shape));
                     fprintf(fileID,'%d\n%s\n%s\n%d\n',num_of_rois,separate_rois.(Data{i,1}).date,separate_rois.(Data{i,1}).time,separate_rois.(Data{i,1}).shape{k});                 
                     stemp1=size(separate_rois.(Data{i,1}).roi{k},1);
                     stemp2=size(separate_rois.(Data{i,1}).roi{k},2);
                     array=separate_rois.(Data{i,1}).roi{k};
                     for m=1:stemp1
                         for n=1:stemp2
                            fprintf(fileID,'%d ',array(m,n));
                         end
                         fprintf(fileID,'\n');
                     end
                     fprintf(fileID,'\n');
                     vertices=[];
                      if(separate_rois.(Data{i,1}).shape{k}==1)
                        data2=separate_rois.(Data{i,1}).roi{k};
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{i,1}).shape{k}==2)
                          vertices=separate_rois.(Data{i,1}).roi{k};
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{i,1}).shape{k}==3)
                          data2=separate_rois.(Data{i,1}).roi{k};
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          s1=size(caIMG,1);s2=size(caIMG,2);
                          for m=1:s1
                              for n=1:s2
                                    dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                    if(dist<=1.00)
                                        BW(m,n)=logical(1);
                                    else
                                        BW(m,n)=logical(0);
                                    end
                              end
                          end
                      elseif(separate_rois.(Data{i,1}).shape{k}==4)
                          vertices=separate_rois.(Data{i,1}).roi{k};
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      end
                      if(k==1)
                         mask2=BW; 
                      else
                         mask2=mask2|BW;
                      end
                    imwrite(mask2,fullfile(ROIanaIndDir, [filename '_'  (Data{i,1}) 'mask.tif']));
                 end
                 %figure;imshow(255*uint8(mask2));
                %display(separate_rois.(Data{i,1}));
             end
             fclose(fileID);
        end

    end

    function[]=save_text_roi_fn(object,handles)
        s3=size(cell_selection_data,1);s1=size(caIMG,1);s2=size(caIMG,2);
        roi_names=fieldnames(separate_rois);
        Data=get(roi_table,'Data');
        for i=1:s3
            destination=fullfile(ROImanDir,[filename,'_',roi_names{cell_selection_data(i,1),1},'_coordinates.txt']);
            display(destination);
            fileID = fopen(destination,'wt');
            set(status_message,'String',['mask saved in- ',destination]);
            vertices=[];  BW(1:s1,1:s2)=logical(0);
             if(iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)==0)
                 display('single ROI');
                 % no combined ROI present then 
%                  fprintf('shape of %d ROI = %d \n',i, separate_rois.(Data{i,1}).shape);
%                  fprintf('date=%s time=%s \n',separate_rois.(Data{i,1}).date,separate_rois.(Data{i,1}).time);
%                  fprintf('roi=%s\n',separate_rois.(Data{i,1}).roi);
                 num_of_rois=1;
                 fprintf(fileID,'%d\n',iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape));
                 fprintf(fileID,'%d\n',num_of_rois);
                 fprintf(fileID,'%d\n%s\n%s\n%d\n',num_of_rois,separate_rois.(Data{cell_selection_data(i,1),1}).date,separate_rois.(Data{cell_selection_data(i,1),1}).time,separate_rois.(Data{cell_selection_data(i,1),1}).shape);                 
                 stemp1=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi,1);
                 stemp2=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi,2);
                 array=separate_rois.(Data{cell_selection_data(i,1),1}).roi;
                 if(separate_rois.(Data{cell_selection_data(i,1),1}).shape==1)
                     fprintf(fileID,'1\n');
                 elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape==2)
                     fprintf(fileID,'%d\n',stemp1);
                 elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape==3)
                     fprintf(fileID,'1\n');
                 elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape==4)
                     fprintf(fileID,'%d\n',stemp1);
                 end
                 
                 for m=1:stemp1
                     for n=1:stemp2
                        fprintf(fileID,'%d ',array(m,n));
                     end
                     fprintf(fileID,'\n');
                 end
                 fprintf(fileID,'\n');
                 
             elseif(iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)==1)
                 display('combined ROIs');
                 s_subcomps=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi,2);
                 display(s_subcomps);
                 for k=1:s_subcomps
                     num_of_rois=k;
                     fprintf(fileID,'%d\n',iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape));
                     if(k==1)
                        fprintf(fileID,'%d\n',s_subcomps); 
                     end
                     fprintf(fileID,'%d\n%s\n%s\n%d\n',num_of_rois,separate_rois.(Data{cell_selection_data(i,1),1}).date,separate_rois.(Data{cell_selection_data(i,1),1}).time,separate_rois.(Data{cell_selection_data(i,1),1}).shape{k});                 
                     stemp1=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi{k},1);
                     stemp2=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi{k},2);
                     fprintf(fileID,'%d\n',stemp1);
                     array=separate_rois.(Data{cell_selection_data(i,1),1}).roi{k};
                     for m=1:stemp1
                         for n=1:stemp2
                            fprintf(fileID,'%d ',array(m,n));
                         end
                         fprintf(fileID,'\n');
                     end
                     fprintf(fileID,'\n'); 
                 end
             end
             fclose(fileID);
        end
    end

    function[]=save_mask_roi_fn(object,handles)
        stemp=size(cell_selection_data,1);s1=size(caIMG,1);s2=size(caIMG,2);
        Data=get(roi_table,'Data');
        ROInameSEL = '';   % selected ROI name
        for i=1:stemp
            vertices=[];  BW(1:s1,1:s2)=logical(0);
             if(iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)==0)
                  if(separate_rois.(Data{cell_selection_data(i,1),1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{cell_selection_data(i,1),1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                  elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{cell_selection_data(i,1),1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      
                  elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{cell_selection_data(i,1),1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(caIMG,1);s2=size(caIMG,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape==4)
                      %display('polygon');
                      vertices=separate_rois.(Data{cell_selection_data(i,1),1}).roi;
                      BW=roipoly(caIMG,vertices(:,1),vertices(:,2)); 
                  end
                  %figure;imshow(255*uint8(BW));%pause(10);
                  imwrite(BW,fullfile(ROIanaIndDir,[filename '_'  (Data{cell_selection_data(i,1),1}) 'mask.tif']));
                                   
             elseif(iscell(separate_rois.(Data{cell_selection_data(i,1),1}).shape)==1)
                 s_subcomps=size(separate_rois.(Data{cell_selection_data(i,1),1}).roi,2);
                 for k=1:s_subcomps
                     vertices=[];
                      if(separate_rois.(Data{cell_selection_data(i,1),1}).shape{k}==1)
                        data2=separate_rois.(Data{cell_selection_data(i,1),1}).roi{k};
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape{k}==2)
                          vertices=separate_rois.(Data{cell_selection_data(i,1),1}).roi{k};
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape{k}==3)
                          data2=separate_rois.(Data{cell_selection_data(i,1),1}).roi{k};
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          s1=size(caIMG,1);s2=size(caIMG,2);
                          for m=1:s1
                              for n=1:s2
                                    dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                    if(dist<=1.00)
                                        BW(m,n)=logical(1);
                                    else
                                        BW(m,n)=logical(0);
                                    end
                              end
                          end
                      elseif(separate_rois.(Data{cell_selection_data(i,1),1}).shape{k}==4)
                          vertices=separate_rois.(Data{cell_selection_data(i,1),1}).roi{k};
                          BW=roipoly(caIMG,vertices(:,1),vertices(:,2));
                      end
                      if(k==1)
                         mask2=BW; 
                      else
                         mask2=mask2|BW;
                      end
                 end
                 imwrite(mask2,fullfile(ROIanaIndDir, [filename '_'  (Data{cell_selection_data(i,1),1}) 'mask.tif']),'Compression','none');  %YL: set compression mode to 'none' so that imagej can open it 
%                  set(status_message,'String',sprintf('Mask saved in -%s',fullfile(ROIanaIndDir, [filename '_'  (Data{cell_selection_data(i,1),1}) 'mask.tif'])));
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
                     set(status_message,'String',sprintf('%d mask file for %s  was saved in %s',stemp,ROInameSEL,ROIanaIndDir));
                 else
                     set(status_message,'String',sprintf('%d mask files for %s  were saved in %s',stemp,ROInameSEL,ROIanaIndDir));
                 end
             else
                 set(status_message,'String', 'Saving individual mask(s)')
             end
        
        end

    end

    function[x_min,y_min,x_max,y_max]=enclosing_rect(coordinates,shape)
        
        if(shape==3)
            %ellipse - needed because the ellipse parameters are passed
            % wheras in rect, freehand and polygon- vertices are already
            % known
            a=coordinates(1);b=coordinates(2);c=coordinates(3);d=coordinates(4);
            % by equation of ellipse
            x_min=floor(a/2);x_max=floor(a/2+c);
            y_min=floor(b/2);y_max=floor(b/2+d);
        else
            x_coordinates=coordinates(:,1);y_coordinates=coordinates(:,2);
            s1=size(x_coordinates,1);
            %display(s1);
            x_min=x_coordinates(1);x_max=x_coordinates(1);
            y_min=y_coordinates(1);y_max=y_coordinates(1);
            for i=2:s1
               if(x_coordinates(i)<x_min)
                  x_min=x_coordinates(i); 
               end
               if(y_coordinates(i)<y_min)
                  y_min=y_coordinates(i); 
               end
               if(x_coordinates(i)>x_max)
                  x_max=x_coordinates(i); 
               end
               if(y_coordinates(i)>y_max)
                  y_max=y_coordinates(i); 
               end
            end
            
        end
        vertices_out=[x_min,y_min;x_max,y_min;x_max,y_max;x_min,y_max];
        %display(vertices_out);display(size(caIMG));
        BW2=roipoly(caIMG,vertices_out(:,1),vertices_out(:,2));
        figure;imshow(255*uint8(BW2));% shows the enclosing rect as a mask of the image
        
    end
     
     function[x_min,y_min,x_max,y_max]=enclosing_rect2(coordinates)
        x_coordinates=coordinates(:,1);y_coordinates=coordinates(:,2);
        s1=size(x_coordinates,1);
%         display(s1);
        x_min=x_coordinates(1);x_max=x_coordinates(1);
        y_min=y_coordinates(1);y_max=y_coordinates(1);
        for i=2:s1
           if(x_coordinates(i)<x_min)
              x_min=x_coordinates(i); 
           end
           if(y_coordinates(i)<y_min)
              y_min=y_coordinates(i); 
           end
           if(x_coordinates(i)>x_max)
              x_max=x_coordinates(i); 
           end
           if(y_coordinates(i)>y_max)
              y_max=y_coordinates(i); 
           end
        end
        vertices_out=[x_min,y_min;x_max,y_min;x_max,y_max;x_min,y_max];
       % display(vertices_out);display(size(image));
       % BW2=roipoly(image,vertices_out(:,1),vertices_out(:,2));
%          figure;imshow(255*uint8(BW2));
    end

     function [] = mask_to_roi_fn(object,handles)

    %MASK_TO_ROI Summary of this function goes here
    %   Detailed explanation goes here
        
        [mask_filename,mask_pathname,filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select Mask image',pseudo_address,'MultiSelect','off');
        mask_image=imread([mask_pathname mask_filename]);
        mask_image=transpose(mask_image);
        [s1,s2]=size(mask_image);imout(1:s1,1:s2)=uint8(0);
        boundaries=bwboundaries(mask_image);
        %YL: add option to load rectangular ROIs
        recFLAG = 2;
        ROIshapeChoice = questdlg('load rectangular ROI or ROI in other shapes?', ...
                 'ROI shape','Rectangular ROI','Freehand ROI','All retangular ROI(s)');
             if isempty(ROIshapeChoice)
                 error('choose the shape of the ROI to be loaded')
             end
             switch ROIshapeChoice
                 case 'All retangular ROI(s)'     
                     recFLAG = 1;%1 for rectangular ROI
                     disp('loading rectangular ROIs.')
                 case 'Freehand ROI'
                     recFLAG = 2;%2 for freehand ROI
                     disp('Loading non-rectangular ROIs')
             end
        
        for i=1:size(boundaries,1)
            boundaries_temp=boundaries{i,1};
            mask_to_roi_sub_fn(boundaries_temp,recFLAG);
        end
        save(fullfile(ROImanDir,roiMATname),'separate_rois','-append'); 
        update_rois;

        function[]=mask_to_roi_sub_fn(boundaries,recFLAG)
           
            count=1;count_max=1;flag=0;
            if(isfield(separate_rois,'imported_maskROI1'))
                count=2;count_max=count;
                while(count<1000)
                    fieldname=['imported_maskROI' num2str(count)];
                     if(isfield(separate_rois,fieldname)==0)
                        break;
                     end
                     count=count+1;
                end
            else
               fieldname= 'imported_maskROI1';
            end
                c=clock;fix(c);
                %setting the date
                date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
                separate_rois.(fieldname).date=date;
                 %setting the time
                time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
                separate_rois.(fieldname).time=time;
                %setting the roi_shape
                separate_rois.(fieldname).shape = recFLAG;

                %setting the enclosing_rect
                [x_min,y_min,x_max,y_max]=enclosing_rect2(boundaries);
                
                enclosing_rect_values=[x_min,y_min,x_max,y_max];
                separate_rois.(fieldname).enclosing_rect=enclosing_rect_values;

                %setting middle x and middle y
                [xm,ym]=midpoint_fn(mask_image);
                separate_rois.(fieldname).xm=xm;
                separate_rois.(fieldname).ym=ym;

                %setting the roi values i.w the vertex values
                if recFLAG == 1     % rectangular shape
                    a = x_min; b= y_min; c = x_max-x_min+1; d = y_max-y_min+1;
                    separate_rois.(fieldname).roi= [a b c d];
                elseif recFLAG == 2 % freehand
                     separate_rois.(fieldname).roi=boundaries;
                   
                end
                 
        end
     end

    
end


