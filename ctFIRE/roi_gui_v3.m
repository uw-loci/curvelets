
function[]=roi_gui_v3()
    
%     Developer - Guneet Singh Mehta
%     Indian Institute of Technology, Jodhpur
%     Former Research Intern at LOCI,UW Madison
%     email- mehta_guneet@iitj.ac.in
%     Duration - December 1 2014 - 28th April 2015
  
%     Steps-
%     0 define global variables
%     1 define figures- roi_mang_fig,im_fig,roi_anly_fig- get screen size and adjust accordingly
%     2 define roi_table
%     3 define reset function,filename box,status box
%     4 define select file box,implement the function that opens last function
%     5 

    % global variables
    
    global pseudo_address;
    global image;
    global filename; global format;global pathname; % if selected image is testimage1.tif then imagename='testimage1' and format='tif'
    global separate_rois;
    global finalize_rois;
    global roi;
    global roi_shape;
    global h;
    global cell_selection_data;
    global xmid;global ymid;
    global matdata;matdata=[];
    global popup_new_roi;
    global gmask;
    global combined_name_for_ctFIRE;
    popup_new_roi=0;
    %roi_mang_fig - roi manager figure - initilisation starts
    SSize = get(0,'screensize');SW2 = SSize(3); SH = SSize(4);
    defaultBackground = get(0,'defaultUicontrolBackgroundColor'); 
    roi_mang_fig = figure('Resize','on','Color',defaultBackground,'Units','pixels','Position',[50 50 round(SW2/5) round(SH*0.9)],'Visible','on','MenuBar','none','name','ROI Manager','NumberTitle','off','UserData',0);
    relative_horz_displacement=20;% relative horizontal displacement of analysis figure from roi manager
         %roi analysis module is not visible in the beginning
   % roi_anly_fig = figure('Resize','off','Color',defaultBackground,'Units','pixels','Position',[50+round(SW2/5)+relative_horz_displacement 50 round(SW2/10) round(SH*0.9)],'Visible','off','MenuBar','none','name','ROI Analysis','NumberTitle','off','UserData',0);
    im_fig=figure;set(im_fig,'Visible','off');
    backup_fig=figure;set(backup_fig,'Visible','off');
    % initialisation ends
    
    %opening previous file location -starts
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
    %ends - opening previous file location
    
    %defining buttons - starts
    roi_table=uitable('Parent',roi_mang_fig,'Units','normalized','Position',[0.05 0.05 0.45 0.9],'CellSelectionCallback',@cell_selection_fn);
    reset_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.75 0.96 0.2 0.03],'String','Reset','Callback',@reset_fn);
    open_file_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.9 0.4 0.045],'String','Open File','Callback',@load_image);
    filename_box=uicontrol('Parent',roi_mang_fig,'Style','text','String','filename','Units','normalized','Position',[0.55 0.85 0.4 0.045],'BackgroundColor',[1 1 1]);
    draw_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.80 0.4 0.045],'String','Draw ROI','Callback',@new_roi);
    finalize_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.75 0.4 0.045],'String','Finalize ROI','Callback',@finalize_roi_fn);
    save_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.70 0.4 0.045],'String','Save ROI','Enable','off','Callback',@save_roi);
    combine_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.65 0.4 0.045],'String','Combine ROIs','Enable','on','Callback',@combine_rois);
    rename_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.60 0.4 0.045],'String','Rename ROI','Callback',@rename_roi);
    delete_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.55 0.4 0.045],'String','Delete ROI','Callback',@delete_roi);
    measure_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.50 0.4 0.045],'String','Measure ROI','Callback',@measure_roi);
    analyzer_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.45 0.4 0.045],'String','ctFIRE ROI Analyzer','Callback',@analyzer_launch_fn,'Enable','off');
    ctFIRE_to_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.40 0.4 0.045],'String','Apply ctFIRE on ROI','Callback',@ctFIRE_to_roi_fn,'Enable','off');
    index_box=uicontrol('Parent',roi_mang_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.29 0.1 0.045],'Callback',@index_fn);
    index_text=uicontrol('Parent',roi_mang_fig,'Style','Text','Units','normalized','Position',[0.6 0.28 0.3 0.045],'String','Show Indices');
    status_title=uicontrol('Parent',roi_mang_fig,'Style','text','Units','normalized','Position',[0.55 0.23 0.4 0.045],'String','Message');
    status_message=uicontrol('Parent',roi_mang_fig,'Style','text','Units','normalized','Position',[0.55 0.05 0.4 0.19],'String','Press Open File and select a file','BackgroundColor',[1 1 1]);
    %ends - defining buttons
    
    function[]=reset_fn(object,handles)
        close all;
        roi_gui_v3();
    end 
    
    function[]=load_image(object,handles)
%         Steps-
%         1 open the location of the last image
%         2 check for the folder ROI then ROI/ROI_management and ROI_analysis. If one of them is not present then make these directories
%         3 check whether imagename_ROIs are present in the pathname/ROI/ROI_management
%         4 Skip -(read image - convert to RGB image . Reason - colored
%         fibres need to be overlaid. ) Try grayscale image first
%         5 if folders are present then check for the imagename_ROIs.mat in ROI_management folder
%         5.5 define mask and boundary 
%         6 if file is present then load the ROIs in roi_table of roi_mang_fig
         
        [filename,pathname,filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select image',pseudo_address,'MultiSelect','off'); 
        set(status_message,'string','File is being opened. Please wait....');
         try
             message_roi_present=1;message_ctFIREdata_present=0;
            pseudo_address=pathname;
            save('address3.mat','pseudo_address');
            %display(filename);%display(pathname);
            if(exist(horzcat(pathname,'ROI'),'dir')==0)%check for ROI folder
                mkdir(pathname,'ROI');mkdir(pathname,'ROI\ROI_management');mkdir(pathname,'ROI\ROI_analysis');
            else
                if(exist(horzcat(pathname,'ROI\ROI_management'),'dir')==0)%check for ROI/ROI_management folder
                    mkdir(pathname,'ROI\ROI_management'); 
                end
                if(exist(horzcat(pathname,'ROI\ROI_analysis'),'dir')==0)%check for ROI/ROI_analysis folder
                   mkdir(pathname,'ROI\ROI_analysis'); 
                end
            end
            image=imread([pathname filename]);
            set(filename_box,'String',filename);
            dot_position=findstr(filename,'.');dot_position=dot_position(end);
            format=filename(dot_position+1:end);filename=filename(1:dot_position-1);
            if(exist([pathname,'ctFIREout\' ['ctFIREout_' filename '.mat']],'file')~=0)%~=0 instead of ==1 because value is equal to 2
                set(analyzer_box,'Enable','on');
                message_ctFIREdata_present=1;
                matdata=importdata(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']));
            end
            if(exist([pathname,'ROI\ROI_management\',[filename '_ROIs.mat']],'file')~=0)%if file is present . value ==2 if present
                separate_rois=importdata([pathname,'ROI\ROI_management\',[filename '_ROIs.mat']]);
                message_rois_present=1;
            else
                temp_kip='';
                separate_rois=[];
                save([pathname,'ROI\ROI_management\',[filename '_ROIs.mat']],'separate_rois');
            end
            
            s1=size(image,1);s2=size(image,2);
            for i=1:s1
                for j=1:s2
                    mask(i,j)=logical(0);boundary(i,j)=uint8(0);
                end
            end
            
            if(isempty(separate_rois)==0)
                size_saved_operations=size(fieldnames(separate_rois),1);
                names=fieldnames(separate_rois); 
                for i=1:size_saved_operations
                    Data{i,1}=names{i,1};
                end
                set(roi_table,'Data',Data);
            end
            figure(im_fig);imshow(image,'Border','tight');hold on;
            if(message_rois_present==1&&message_ctFIREdata_present==1)
                set(status_message,'String','Previously defined ROI(s) are present and ctFIRE data is present');  
            elseif(message_rois_present==1&&message_ctFIREdata_present==0)
                set(status_message,'String','Previously defined ROIs are present');  
            elseif(message_rois_present==0&&message_ctFIREdata_present==1)
                set(status_message,'String','Previously defined ROIs not present .ctFIRE data is present');  
            end
        catch
           set(status_message,'String','error in loading Image.'); 
        end
      
    end

    function[]=new_roi(object,handles)
        set(status_message,'String','Select the ROI shape to be drawn');  
        global rect_fixed_size;
        % Shape of ROIs- 'Rectangle','Freehand','Ellipse','Polygon'
        %         steps-
        %         1 clear im_fig and show the image again
        %         2 ask for the shape of the roi
        %         3 convert the roi into mask and boundary
        %         4 show the image in a figure where mask ==1 and also show the boundary on the im_fig

       % clf(im_fig);figure(im_fig);imshow(image);
       set(save_roi_box,'Enable','off');
       figure(im_fig);hold on;
       %display(popup_new_roi);
       %display(isempty(findobj('type','figure','name',popup_new_roi))); 
       temp=isempty(findobj('type','figure','name','Select ROI shape'));
       fprintf('popup_new_roi=%d and temp=%d\n',popup_new_roi,temp);
       if(popup_new_roi==0)
            roi_shape_popup_window;
            temp=isempty(findobj('type','figure','name','Select ROI shape'));
       elseif(temp==1)
           roi_shape_popup_window;
           temp=isempty(findobj('type','figure','name','Select ROI shape'));
       else
           ok_fn2(0,0);
       end
       
            function[]=roi_shape_popup_window()
                width=200; height=200;
                
                rect_fixed_size=0;% 1 if size is fixed and 0 if not
                position=[50 50 200 200];
                left=position(1);bottom=position(2);width=position(3);height=position(4);
                defaultBackground = get(0,'defaultUicontrolBackgroundColor');
                popup_new_roi=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 200],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);          
                roi_shape_text=uicontrol('Parent',popup_new_roi,'Style','text','string','select ROI type','Units','normalized','Position',[0.05 0.9 0.9 0.10]);
                roi_shape_menu=uicontrol('Parent',popup_new_roi,'Style','popupmenu','string',{'Rectangle','Freehand','Ellipse','Polygon'},'Units','normalized','Position',[0.05 0.75 0.9 0.10],'Callback',@roi_shape_menu_fn);
                rect_roi_checkbox=uicontrol('Parent',popup_new_roi,'Style','checkbox','Units','normalized','Position',[0.05 0.6 0.1 0.10],'Callback',@rect_roi_checkbox_fn);
                rect_roi_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Fixed Size Rect ROI','Units','normalized','Position',[0.15 0.6 0.6 0.10]);
                rect_roi_height=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(height),'Position',[0.05 0.45 0.2 0.10],'enable','off','Callback',@rect_roi_height_fn);
                rect_roi_height_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Height','Units','normalized','Position',[0.28 0.45 0.2 0.10],'enable','off');
                rect_roi_width=uicontrol('Parent',popup_new_roi,'Style','edit','Units','normalized','String',num2str(width),'Position',[0.52 0.45 0.2 0.10],'enable','off','Callback',@rect_roi_width_fn);
                rect_roi_width_text=uicontrol('Parent',popup_new_roi,'Style','text','string','Width','Units','normalized','Position',[0.73 0.45 0.2 0.10],'enable','off');
                rf_numbers_ok=uicontrol('Parent',popup_new_roi,'Style','pushbutton','string','Ok','Units','normalized','Position',[0.05 0.10 0.45 0.10],'Callback',@ok_fn);

                    function[]=roi_shape_menu_fn(object,handles)
                       if(get(object,'value')==1)
                          set([rect_roi_height rect_roi_height_text rect_roi_width rect_roi_width_text ],'enable','on');
                       else%i.e for case of Freehand, Ellipse and Polygon
                          set([rect_roi_height rect_roi_height_text rect_roi_width rect_roi_width_text ],'enable','off');
                       end
                    end
% 
                    function[]=rect_roi_width_fn(object,handles)
                       width=str2num(get(object,'string')); 
                    end

                    function[]=rect_roi_height_fn(object,handles)
                        height=str2num(get(object,'string'));
                    end

                    function[]=rect_roi_checkbox_fn(object,handles)
                        if(get(object,'value')==1)
                            set([rect_roi_height rect_roi_height_text rect_roi_width rect_roi_width_text],'enable','on');
                            rect_fixed_size=1;
                        else
                            set([rect_roi_height rect_roi_height_text rect_roi_width rect_roi_width_text],'enable','off');
                            rect_fixed_size=0;
                        end
                    end
% 
                    function[]=ok_fn(object,handles)
                        %'Rectangle','Freehand','Ellipse','Polygon'
                          roi_shape=get(roi_shape_menu,'value');
                          if(roi_shape==1)
                             set(status_message,'String','Rectangular Shape ROI selected. Draw the ROI on the image');   
                          elseif(roi_shape==2)
                              set(status_message,'String','Freehand ROI selected. Draw the ROI on the image');  
                          elseif(roi_shape==3)
                              set(status_message,'String','Ellipse shaped ROI selected. Draw the ROI on the image');  
                          elseif(roi_shape==4)
                              set(status_message,'String','Polygon shaped ROI selected. Draw the ROI on the image');  
                          end
                           %display(roi_shape);
                           count=1;%finding the ROI number
                           fieldname=['ROI' num2str(count)];
                           while(isfield(separate_rois,fieldname)==1)
                               count=count+1;fieldname=['ROI' num2str(count)];
                           end
                           %display(fieldname);
                          % close; %closes the pop up window
                           figure(im_fig);
                           s1=size(image,1);s2=size(image,2);
                           for i=1:s1 
                               for j=1:s2
                                   mask(i,j)=logical(0);
                               end
                           end
                           finalize_rois=0;
                           while(finalize_rois==0)
                               if(roi_shape==1)
                                    if(rect_fixed_size==0)% for resizeable Rectangular ROI
                                        h=imrect;
                                         wait_fn();
                                         finalize_rois=1;
                                        %finalize_roi=1;
                %                         set(status_message,'String',['Rectangular ROI selected' char(10) 'Draw ROI']);
                                    elseif(rect_fixed_size==1)% fornon resizeable Rect ROI 
                                        h = imrect(gca, [10 10 width height]);
                                         wait_fn();
                                         finalize_rois=1;
                                        %display('drawn');
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
                           
                           roi=getPosition(h);%display(roi);
                           %display('out of loop');
                    end
                    
                    function[]=wait_fn()
                                while(finalize_rois==0)
                                   pause(0.25); 
                                end
                    end
            end
            function[]=ok_fn2(object,handles)
%                           roi_shape=get(roi_shape_menu,'value');
                           %display(roi_shape);
                           count=1;%finding the ROI number
                           fieldname=['ROI' num2str(count)];
                           while(isfield(separate_rois,fieldname)==1)
                               count=count+1;fieldname=['ROI' num2str(count)];
                           end
                           %display(fieldname);
                          % close; %closes the pop up window
                           figure(im_fig);
                           s1=size(image,1);s2=size(image,2);
                           for i=1:s1 
                               for j=1:s2
                                   mask(i,j)=logical(0);
                               end
                           end
                           finalize_rois=0;
                           while(finalize_rois==0)
                               if(roi_shape==1)
                                    if(rect_fixed_size==0)% for resizeable Rectangular ROI
                                        h=imrect;
                                         wait_fn();
                                         finalize_rois=1;
                                        %finalize_roi=1;
                %                         set(status_message,'String',['Rectangular ROI selected' char(10) 'Draw ROI']);
                                    elseif(rect_fixed_size==1)% fornon resizeable Rect ROI 
                                        h = imrect(gca, [10 10 width height]);
                                         wait_fn();
                                         finalize_rois=1;
                                        %display('drawn');
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
                           roi=getPosition(h);%display(roi);
                           %display('out of loop');
              end
                
                 function[]=wait_fn()
                                while(finalize_rois==0)
                                   pause(0.25); 
                                end
                  end
            
    end

    function[]=finalize_roi_fn(object,handles)
       set(save_roi_box,'Enable','on');
       finalize_rois=1;
       roi=getPosition(h);%  this is to account for the change in position of the roi by dragging
       %%display(roi);
       set(status_message,'string','Press Save ROI to save the finalized ROI');
    end

    function[]=save_roi(object,handles)   
        % searching for the biggest operation number- starts
        count=1;count_max=1;
           if(isempty(separate_rois)==0)
               while(count<10000)
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
        for i=1:s3
           %display(separate_rois.(names{i,1})); 
        end
        save(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']),'separate_rois','-append');
        %%display(separate_rois);
        
        %display('saving done');
        update_rois;
        %clf(im_fig);figure(im_fig);imshow(image,'Border','tight');hold on;
    end

    function[]=combine_rois(object,handles)
%         There can be three cases
%         1 combining individual ROIs
%         2 combining a combined and individual ROIs
%         3 combining multiple combined ROIs

%         difficulties likely to be faced are-
%         1 combining ROI1_ROI2 with ROI1
%         2 coordinates in the above case
%         3 change of names of ROIs like ROI1 in ROI1_ROI2 may be different from current ROI1
%         4 

        %display(cell_selection_data);
        temp2=get(roi_table,'Data');
        s1=size(cell_selection_data,1);
        roi_names=fieldnames(separate_rois);
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
        for i=1:s1
            separate_rois.(combined_roi_name).shape{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).shape;
            separate_rois.(combined_roi_name).roi{i}=separate_rois.(roi_names{cell_selection_data(i,1),1}).roi; 
        end
        c=clock;fix(c);
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        separate_rois.(combined_roi_name).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        separate_rois.(combined_roi_name).time=time;
        
        for i=1:s1
            %display(separate_rois.(combined_roi_name).roi{1});
            %display(separate_rois.(combined_roi_name).shape{1});
        end
        %display(separate_rois.(combined_roi_name).time);
        %display(separate_rois.(combined_roi_name).date);
        save(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']),'separate_rois','-append');
        update_rois;
    end

    function[]=update_rois
        %it updates the roi in the ui table
        separate_rois=importdata(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']));
        %display(separate_rois);
        if(isempty(separate_rois)==0)
                size_saved_operations=size(fieldnames(separate_rois),1);
                names=fieldnames(separate_rois); 
                for i=1:size_saved_operations
                    Data{i,1}=names{i,1};
                end
                set(roi_table,'Data',Data);
        end
    end

    function[]=cell_selection_fn(object,handles)
        % o Initilization
%         1 needs to identify the operations and their numbers and strings
%         2 needs to define mask
%         3 needs to plot the roi_boundary on img_fig
%         4 add wait and resume messages
%         pause(0.5);
        warning('off');
        combined_name_for_ctFIRE=[];
        
        %finding whether the selection contains a combination of ROIs
        stemp=size(handles.Indices,1);
        cell_selection_data_temp=handles.Indices;
        temp_names=fieldnames(separate_rois);
         
        Data=get(roi_table,'Data'); %display(Data(1,1));
         combined_rois_present=0; 
         for i=1:stemp
             if(iscell(separate_rois.(Data{handles.Indices(i,1),1}).shape)==1)
                combined_rois_present=1; break;
             end
         end

     if(combined_rois_present==0)      
                xmid=[];ymid=[];
               s1=size(image,1);s2=size(image,2);
               for i=1:s1
                   for j=1:s2
                        mask(i,j)=logical(0);
                        BW(i,j)=logical(0);
                        roi_boundary(i,j,1)=uint8(0);roi_boundary(i,j,3)=uint8(0);roi_boundary(i,j,3)=uint8(0);
                        overlaid_image(i,j,1)=image(i,j);overlaid_image(i,j,2)=image(i,j);overlaid_image(i,j,3)=image(i,j);
                   end
               end
               Data=get(roi_table,'Data');
               s3=size(handles.Indices,1);%display(s3);%pause(5);
               if(s3>0)
                   set(ctFIRE_to_roi_box,'enable','on');
               else
                    set(ctFIRE_to_roi_box,'enable','off');
               end
               cell_selection_data=handles.Indices;
               %display(cell_selection_data);
               for k=1:s3
                   combined_name_for_ctFIRE=[combined_name_for_ctFIRE '_' Data{handles.Indices(k,1),1}];
                   data2=[];vertices=[];
                  %display(Data{handles.Indices(k,1),1});
                  %display(separate_rois.(Data{handles.Indices(k,1),1}).roi);
                  if(separate_rois.(Data{handles.Indices(k,1),1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(image,vertices(:,1),vertices(:,2));
                    %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                      BW=roipoly(image,vertices(:,1),vertices(:,2));
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(image,1);s2=size(image,2);
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
                      BW=roipoly(image,vertices(:,1),vertices(:,2));
                      %figure;imshow(255*uint8(BW));
                  end
                  mask=mask|BW;
                  s1=size(image,1);s2=size(image,2);
                  for i=2:s1-1
                        for j=2:s2-1
                            North=BW(i-1,j);NorthWest=BW(i-1,j-1);NorthEast=BW(i-1,j+1);
                            West=BW(i,j-1);East=BW(i,j+1);
                            SouthWest=BW(i+1,j-1);South=BW(i+1,j);SouthEast=BW(i+1,j+1);
                            if(BW(i,j)==logical(1)&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
                                roi_boundary(i,j,1)=uint8(255);
                                roi_boundary(i,j,2)=uint8(255);
                                roi_boundary(i,j,3)=uint8(0);
                            end
                        end
                  end
                  
                  %dilating the roi_boundary if the image is bigger than
                  %the size of the figure
                  im_fig_size=get(im_fig,'Position');
                  im_fig_width=im_fig_size(3);im_fig_height=im_fig_size(4);
                  s1=size(image,1);s2=size(image,2);
                  factor1=ceil(s1/im_fig_width);factor2=ceil(s2/im_fig_height);
                  if(factor1>factor2)
                     dilation_factor=factor1; 
                  else
                     dilation_factor=factor2;
                  end
                  if(dilation_factor>1)
                      
                    roi_boundary=dilate_boundary(roi_boundary,dilation_factor);
                  end
                  
                     [xmid(k),ymid(k)]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
        %            [xmid,ymid]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
        %            figure(im_fig);text(ymid,xmid,Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
        %           %%display(separate_rois.(Data{handles.Indices(i,1),1}).roi);
               end
               gmask=mask;
               %figure;imshow(255*uint8(gmask));
               clf(im_fig);figure(im_fig);imshow(overlaid_image+roi_boundary,'Border','tight');hold on;
                if(get(index_box,'Value')==1)
                   for k=1:s3
                     text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
                   end
                end

               backup_fig=copyobj(im_fig,0);set(backup_fig,'Visible','off');
    
     elseif(combined_rois_present==1)
               
                profile on;
                s1=size(image,1);s2=size(image,2);
               for i=1:s1
                   for j=1:s2
                        mask(i,j)=logical(0);
                        BW(i,j)=logical(0);
                        roi_boundary(i,j,1)=uint8(0);roi_boundary(i,j,3)=uint8(0);roi_boundary(i,j,3)=uint8(0);
                        overlaid_image(i,j,1)=image(i,j);overlaid_image(i,j,2)=image(i,j);overlaid_image(i,j,3)=image(i,j);
                   end
               end
               mask2=mask;
               Data=get(roi_table,'Data');
               s3=size(handles.Indices,1);%display(s3);%pause(5);
               cell_selection_data=handles.Indices;
               if(s3>0)
                   set(ctFIRE_to_roi_box,'enable','on');
               else
                    set(ctFIRE_to_roi_box,'enable','off');
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
                            BW=roipoly(image,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape{p}==2)
                              vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi{p};
                              BW=roipoly(image,vertices(:,1),vertices(:,2));
                          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape{p}==3)
                              data2=separate_rois.(Data{handles.Indices(k,1),1}).roi{p};
                              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                              s1=size(image,1);s2=size(image,2);
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
                              BW=roipoly(image,vertices(:,1),vertices(:,2));
                          end
                          if(p==1)
                             mask2=BW; 
                          else
                             mask2=mask2|BW;
                          end
                      end
                      BW=mask2;
                   else
                      combined_name_for_ctFIRE=[combined_name_for_ctFIRE '_' Data{handles.Indices(k,1),1}];
                      data2=[];vertices=[];
                      if(separate_rois.(Data{handles.Indices(k,1),1}).shape==1)
                        data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(image,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==2)
                          vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                          BW=roipoly(image,vertices(:,1),vertices(:,2));
                      elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==3)
                          data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          s1=size(image,1);s2=size(image,2);
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
                          BW=roipoly(image,vertices(:,1),vertices(:,2));
                      end
                      
                   end
                   
                      s1=size(image,1);s2=size(image,2);
                      for i=2:s1-1
                            for j=2:s2-1
                                North=BW(i-1,j);NorthWest=BW(i-1,j-1);NorthEast=BW(i-1,j+1);
                                West=BW(i,j-1);East=BW(i,j+1);
                                SouthWest=BW(i+1,j-1);South=BW(i+1,j);SouthEast=BW(i+1,j+1);
                                if(BW(i,j)==logical(1)&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
                                    roi_boundary(i,j,1)=uint8(255);
                                    roi_boundary(i,j,2)=uint8(255);
                                    roi_boundary(i,j,3)=uint8(0);
                                end
                            end
                      end
                      mask=mask|BW;
               end
               % if size of the image is big- then to plot the boundary of
               % ROI right - starts
                  im_fig_size=get(im_fig,'Position');
                  im_fig_width=im_fig_size(3);im_fig_height=im_fig_size(4);
                  s1=size(image,1);s2=size(image,2);
                  factor1=ceil(s1/im_fig_width);factor2=ceil(s2/im_fig_height);
                  if(factor1>factor2)
                     dilation_factor=factor1; 
                  else
                     dilation_factor=factor2;
                  end
                  if(dilation_factor>1)
                      
                    roi_boundary=dilate_boundary(roi_boundary,dilation_factor);
                  end
                % if size of the image is big- then to plot the boundary of
               % ROI right - ends
               
               gmask=mask;
               %figure;imshow(255*uint8(gmask));
               clf(im_fig);figure(im_fig);imshow(overlaid_image+roi_boundary,'Border','tight');hold on;
              backup_fig=copyobj(im_fig,0);set(backup_fig,'Visible','off');  
              
     end
       % display(combined_name_for_ctFIRE);
      
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
        
        figure(roi_mang_fig); % opening the manager as the open window, previously the image window was the current open window
    end

    function[]=rename_roi(object,handles)
        %display(cell_selection_data);
        index=cell_selection_data(1,1);
        %defining pop up -starts
        position=[300 300 200 200];
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        
        rename_roi_popup=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 100],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);
        message_box=uicontrol('Parent',rename_roi_popup,'Style','text','Units','normalized','Position',[0.05 0.75 0.9 0.2],'String','Enter the new name below','BackgroundColor',defaultBackground);
        newname_box=uicontrol('Parent',rename_roi_popup,'Style','edit','Units','normalized','Position',[0.05 0.2 0.9 0.45],'String','','BackgroundColor',defaultBackground);
        ok_box=uicontrol('Parent',rename_roi_popup,'Style','Pushbutton','Units','normalized','Position',[0.5 0.05 0.4 0.2],'String','Ok','BackgroundColor',defaultBackground,'Callback',@ok_fn);
        %defining pop up -ends
        
        %2 make new field delete old in ok_fn
        function[]=ok_fn(object,handles)
           new_fieldname=get(newname_box,'string');
           temp_fieldnames=fieldnames(separate_rois);
           separate_rois.(new_fieldname)=separate_rois.(temp_fieldnames{index,1});
           separate_rois=rmfield(separate_rois,temp_fieldnames{index,1});
           save(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']),'separate_rois','-append');
            update_rois;
            close;% closes the dialgue box
        end
     end

    function[]=delete_roi(object,handles)
        %display(cell_selection_data);
        %display(size(cell_selection_data,1));
        %defining pop up -starts
       temp_fieldnames=fieldnames(separate_rois);
       for i=1:size(cell_selection_data,1)
           index=cell_selection_data(i,1);
            separate_rois=rmfield(separate_rois,temp_fieldnames{index,1});
       end
       save(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']),'separate_rois');
        update_rois;
        %defining pop up -ends
        
        %2 make new field delete old in ok_fn
       
     end
 
    function[]=measure_roi(object,handles)
       s1=size(image,1);s2=size(image,2); 
       Data=get(roi_table,'Data');
       s3=size(cell_selection_data,1);%display(s3);
       %display(cell_selection_data);
       roi_number=size(cell_selection_data,1);
        measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 470 300],'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
        measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
        names=fieldnames(separate_rois);
        measure_data{1,1}='names';measure_data{1,2}='min';measure_data{1,3}='max';measure_data{1,4}='Area';measure_data{1,5}='mean';
        measure_index=2;
       for k=1:s3
           data2=[];vertices=[];
          %display(Data{cell_selection_data(k,1),1});
          %%display(separate_rois.(Data{handles.Indices(k,1),1}).roi);
          if(separate_rois.(Data{cell_selection_data(k,1),1}).shape==1)
            %display('rectangle');
            % vertices is not actual vertices but data as [ a b c d] and
            % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
            data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
            BW=roipoly(image,vertices(:,1),vertices(:,2));
            %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==2)
              %display('freehand');
              vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
              BW=roipoly(image,vertices(:,1),vertices(:,2));
              %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==3)
              %display('ellipse');
              data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
              %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
              %the rect enclosing the ellipse. 
              % equation of ellipse region->
              % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
              s1=size(image,1);s2=size(image,2);
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
              BW=roipoly(image,vertices(:,1),vertices(:,2));
              %figure;imshow(255*uint8(BW));
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
                    if(image(i,j)<min)
                        min=image(i,j);
                    end
                    if(image(i,j)>max)
                        max=image(i,j);
                    end
                    mean=mean+double(image(i,j));
                    area=area+1;
                end
            end
        end
        mean=double(mean)/double(area);
     end
       
    end
     
    function[]=analyzer_launch_fn(object,handles)
%        steps
%        1 define buttons 2 from cell_select data define mask where mask=mask|BW 
%        3 based on the conditions - ctFire/PostPro data , full/midpoint, stackmode/batchmode/single file mode
%        4 generate fiber_data
%        5 implement see fibres function
%        6 implement generate stats function
%        7 implement automatic ROI detection
        global plot_statistics_box;
        set(status_message,'string','Select ROI in the ROI manager and then select an operation in ROI analyzer window');
        roi_anly_fig = figure('Resize','off','Color',defaultBackground,'Units','pixels','Position',[50+round(SW2/5)+relative_horz_displacement 0.7*SH-65 round(SW2/10*1) round(SH*0.35)],'Visible','off','MenuBar','none','name','ROI Analyzer','NumberTitle','off','UserData',0);
        set(roi_anly_fig,'Visible','on'); 
        panel=uipanel('Parent',roi_anly_fig,'Units','Normalized','Position',[0 0 1 1]);
        filename_box2=uicontrol('Parent',panel,'Style','text','String','ROI Analyzer','Units','normalized','Position',[0.05 0.86 0.9 0.14]);%,'BackgroundColor',[1 1 1]);
        check_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Check Fibres','Units','normalized','Position',[0.05 0.72 0.9 0.14],'Callback',@check_fibres_fn);
        plot_statistics_box=uicontrol('Parent',panel,'Style','pushbutton','String','Plot statistics','Units','normalized','Position',[0.05 0.58 0.9 0.14],'Callback',@plot_statisitcs_fn,'enable','off');
        more_settings_box2=uicontrol('Parent',panel,'Style','pushbutton','String','More Settings','Units','normalized','Position',[0.05 0.44 0.9 0.14],'Callback',@more_settings_fn);
        generate_stats_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Generate Stats','Units','normalized','Position',[0.05 0.30 0.9 0.14],'Callback',@generate_stats_fn);
        automatic_roi_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Automatic ROI detection','Units','normalized','Position',[0.05 0.16 0.9 0.14],'Callback',@automatic_roi_fn);
        visualisation_box2=uicontrol('Parent',panel,'Style','pushbutton','String','Visualisation of fibres','Units','normalized','Position',[0.05 0.02 0.9 0.14],'Callback',@visualisation,'Enable','off');
        
        %variables for this function - used in sub functions
        
        
        mask=[];
        fiber_source='ctFIRE';%other value can be only postPRO
        fiber_method='mid';%other value can be whole
        fiber_data=[];
        global first_time;
        first_time=1;
        SHG_pixels=0;SHG_ratio=0;total_pixels=0;
        SHG_threshold=matdata.ctfP.value.thresh_im2;%  value taken from the ctFIRE results
        %analyzer functions -start
        
        function[]=check_fibres_fn(handles,object)
            %'Rectangle','Freehand','Ellipse','Polygon' = 1,2,3,4
            % to access selectedd rois - say names contain the names of all
            % rois of the image then roi
            % =separate_rois(names(cell_selection_data(i,1))).roi
            close(im_fig);
           im_fig=copyobj(backup_fig,0);
           fiber_data=[];
            s3=size(cell_selection_data,1);s1=size(image,1);s2=size(image,2);
           names=fieldnames(separate_rois);%display(names);
           for i=1:s1
               for j=1:s2
                   mask(i,j)=logical(0);BW(i,j)=logical(0);
               end
           end
           %determining whether combined ROIs -starts
           
           combined_rois_present=0;
           Data=get(roi_table,'Data'); 
           for k=1:s3
               if(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==1)
                combined_rois_present=1; break;
               end
           end
           %display(combined_rois_present);
           %determining whether combined ROIs -ends
           
               for k=1:s3 
                   if(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==0)
                       
        %                type=separate_rois.(names(cell_selection_data(k))).shape;
        %                %display(type);
                        type=separate_rois.(names{cell_selection_data(k),1}).shape;
                        vertices=[];data2=[];
                        if(type==1)%Rectangle
                            data2=separate_rois.(names{cell_selection_data(k),1}).roi;
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(image,vertices(:,1),vertices(:,2));
                        elseif(type==2)%freehand
                            %display('freehand');
                            vertices=separate_rois.(names{cell_selection_data(k),1}).roi;
                            BW=roipoly(image,vertices(:,1),vertices(:,2));
                        elseif(type==3)%Ellipse
                              %display('ellipse');
                              data2=separate_rois.(names{cell_selection_data(k),1}).roi;
                              a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                              %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                              %the rect enclosing the ellipse. 
                              % equation of ellipse region->
                              % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                              s1=size(image,1);s2=size(image,2);
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
                        elseif(type==4)%Polygon
                            %display('polygon');
                            vertices=separate_rois.(names{cell_selection_data(k),1}).roi;
                            BW=roipoly(image,vertices(:,1),vertices(:,2));
                        end
                        mask=mask|BW;
        %                 %display(separate_rois.(names{cell_selection_data(k),1}).shape);
                   elseif(iscell(separate_rois.(Data{cell_selection_data(k,1),1}).shape)==1)
                       s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                        %display(s_subcomps);
                        for p=1:s_subcomps
                              data2=[];vertices=[];
                              if(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==1)
                                data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                                BW=roipoly(image,vertices(:,1),vertices(:,2));
                              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==2)
                                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                                  BW=roipoly(image,vertices(:,1),vertices(:,2));
                              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==3)
                                  data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                                  a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                  s1=size(image,1);s2=size(image,2);
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
                                  BW=roipoly(image,vertices(:,1),vertices(:,2));
                              end
                                 mask=mask|BW;
                        end
                   end
                    %now finding the SHG pixels for each ROI
                   SHG_pixels(k)=0;total_pixels_temp=0;SHG_ratio(k)=0;
                   for m=1:s1 
                       for n=1:s2
                           if(BW(m,n)==logical(1)&&image(m,n)>=SHG_threshold)
                              SHG_pixels(k)=SHG_pixels(k)+1; 
                           end
                          if(BW(m,n)==logical(1))
                                 total_pixels_temp=total_pixels_temp+1; 
                          end
                       end
                   end
                   SHG_ratio(k)=SHG_pixels(k)/total_pixels_temp;
                   total_pixels(k)=total_pixels_temp;
                   %display(SHG_ratio);
               end 
           
          
           
           %mask defined successfully
           %figure;imshow(255*uint8(mask),'Border','tight');
           
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
                %display(fiber_data);
           elseif(strcmp(fiber_source,'postPRO')==1)
               if(isfield(matdata.data,'PostProGUI')&&isfield(matdata.data.PostProGUI,'fiber_indices'))
                    fiber_data=matdata.data.PostProGUI.fiber_indices;
               else
                   set(status_message,'String','Post Processing Data not present');
               end
           end
           
           if(strcmp(fiber_method,'whole')==1)
               figure(im_fig);
               for i=1:size_fibers % s1 is number of fibers in image selected out of Post pro GUI
                    if (fiber_data(i,2)==1)              
                        vertex_indices=matdata.data.Fa(i).v;
                        s2=size(vertex_indices,2);
                        % s2 is the number of points in the ith fiber
                        
                        flag=1;% becomes zero if one of the fiber points is outside roi, and thus we do not consider the fiber
                        
                        for j=1:s2
                            x=matdata.data.Xa(vertex_indices(j),1);y=matdata.data.Xa(vertex_indices(j),2);
                            if(mask(y,x)==0) % here due to some reason y and x are reversed, still need to figure this out
                                flag=0;
                                fiber_data(i,2)=0;
                                break;
                            end
                        end
                        xmid=matdata.data.Xa(vertex_indices(floor(s2/2)),1);ymid=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                        if(flag==1) % x and y seem to be interchanged in plot
                            % function.
                            plot(xmid,ymid,'--rs','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','g','MarkerSize',10); 
                              hold on;
                             %fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
                        end
                    end
                end
           elseif(strcmp(fiber_method,'mid')==1)
               figure(im_fig);
               for i=1:size_fibers
                    if (fiber_data(i,2)==1)              
                        vertex_indices=matdata.data.Fa(i).v;
                        s2=size(vertex_indices,2);
                        %pause(1);
                        % this part plots the center of fibers on the image, right
                        % now roi is not considered
                        x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                        y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);

                        if(mask(y,x)==1) % x and y seem to be interchanged in plot
                            % function.
                            plot(x,y,'--rs','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','g','MarkerSize',10); hold on;
                              % next step is a debug check
                             %fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
                        else
                            fiber_data(i,2)=0;
                        end
                    end
                end
           end
           plot_fibers(fiber_data,im_fig,0,1);
           set(visualisation_box2,'Enable','on');
           set(plot_statistics_box,'Enable','on');
           
        end
        
        function[]=plot_statisitcs_fn(handles,object)
            % depending on selected ROI find the fibres within the ROI
            % also give an option on number of bins for histogram
            
            statistics_fig = figure('Resize','on','Color',defaultBackground,'Units','pixels','Position',[50+round(SW2/10*3.1)+relative_horz_displacement 50 round(SW2/10*6.3) round(SH*0.9)],'Visible','on','name','ROI Manager','UserData',0);
            Data=get(roi_table,'data');string_temp=Data(cell_selection_data(:,1));
            roi_size_temp=size(string_temp,1);
            string_temp{roi_size_temp+1,1}='All ROIs';
            display(string_temp);
            property_box=uicontrol('Parent',statistics_fig,'Style','popupmenu','String',{'All Properties';'Length'; 'Width';'Angle';'Straightness'},'Units','normalized','Position',[0.05 0.92 0.2 0.07],'Callback',@change_in_property_fn,'Enable','on');
            roi_selection_box=uicontrol('Parent',statistics_fig,'Style','popupmenu','String',string_temp,'Units','normalized','Position',[0.3 0.92 0.2 0.07],'Enable','on','Callback',@change_in_roi_fn);
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
%                 errors left -
%                 1 need to implement get_mask for combined ROIs also
%                 2
                 
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
                           figure(im_fig);
                           for i=1:size_fibers
                                if (fiber_data(i,2)==1)              
                                    vertex_indices=matdata.data.Fa(i).v;
                                    s2=size(vertex_indices,2);
                                    x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                    y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                    if(mask2(y,x)==0) % x and y seem to be interchanged in plot
                                        fiber_data(i,2)=0;
                                    end
                                end
                            end
                       end
                    %step3- ends

                    %step 4 - plotting the histogram

                    num_visible_fibres=size(fiber_data,1);
                    count=1;
                    for i=1:num_visible_fibres
                       if(fiber_data(i,2)==1)
                           length_visible_fiber_data(count)=fiber_data(i,3);width_visible_fiber_data(count)=fiber_data(i,4);
                           angle_visible_fiber_data(count)=fiber_data(i,5);straightness_visible_fiber_data(count)=fiber_data(i,6);
                           count=count+1;                       
                       end
                    end
                        total_visible_fibres=count;
                       length_mean=mean(length_visible_fiber_data);width_mean=mean(width_visible_fiber_data);
                       angle_mean=mean(angle_visible_fiber_data);straightness_mean=mean(straightness_visible_fiber_data);

                       length_std=std(length_visible_fiber_data);width_std=std(width_visible_fiber_data);
                       angle_std=std(angle_visible_fiber_data);straightness_std=std(straightness_visible_fiber_data);

                       length_string=['Mean= ' num2str(length_mean) ' Std= ' num2str(length_std) ' Fibres= ' num2str(total_visible_fibres)];
                       width_string=['Mean= ' num2str(width_mean) ' Std= ' num2str(width_std) ' Fibres= ' num2str(total_visible_fibres)];
                       angle_string=[' Mean= ' num2str(angle_mean) ' Std= ' num2str(angle_std) ' Fibres= ' num2str(total_visible_fibres)];
                       straightness_string=[' Mean= ' num2str(straightness_mean) ' Std= ' num2str(straightness_std) ' Fibres= ' num2str(total_visible_fibres)];

                      property_value=get(property_box,'Value');
                      figure(statistics_fig);
                      bin_number=str2num(get(bin_number_box','string'));

                    if(property_value==1)
                      sub1= subplot(2,2,1);hist(length_visible_fiber_data,bin_number);title(length_string);
                      sub2= subplot(2,2,2);hist(width_visible_fiber_data,bin_number);title(width_string);
                       sub3= subplot(2,2,3);hist(angle_visible_fiber_data,bin_number);title(angle_string);
                       sub4= subplot(2,2,4);hist(straightness_visible_fiber_data,bin_number);title(straightness_string);

                    elseif(property_value==2)
                        plot2=subplot(1,1,1);hist(length_visible_fiber_data,bin_number);title(length_string);
                    elseif(property_value==3)
                        plot3=subplot(1,1,1);hist(width_visible_fiber_data,bin_number);title(width_string);
                    elseif(property_value==4)
                        plot4=subplot(1,1,1);hist(angle_visible_fiber_data,bin_number);title(angle_string);
                    elseif(property_value==5)
                        plot5=subplot(1,1,1);hist(straightness_visible_fiber_data,bin_number);title(straightness_string);
                    end
                elseif(get(roi_selection_box,'Value')==roi_size_temp+1)
                   fiber_data_copy=fiber_data; 
                   for kipper=1:roi_size_temp
                        mask2=get_mask(Data,0,kipper);
                        fiber_data=fiber_data_copy;
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
                               figure(im_fig);
                               for i=1:size_fibers
                                    if (fiber_data(i,2)==1)              
                                        vertex_indices=matdata.data.Fa(i).v;
                                        s2=size(vertex_indices,2);
                                        x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                        y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                                        if(mask2(y,x)==0) % x and y seem to be interchanged in plot
                                            fiber_data(i,2)=0;
                                        end
                                    end
                                end
                           end
                        %step3- ends

                        %step 4 - plotting the histogram

                        num_visible_fibres=size(fiber_data,1);
                        count=1;
                        for i=1:num_visible_fibres
                           if(fiber_data(i,2)==1)
                               length_visible_fiber_data(count)=fiber_data(i,3);width_visible_fiber_data(count)=fiber_data(i,4);
                               angle_visible_fiber_data(count)=fiber_data(i,5);straightness_visible_fiber_data(count)=fiber_data(i,6);
                               count=count+1;                       
                           end
                        end
%                             total_visible_fibres=count;
%                            length_mean=mean(length_visible_fiber_data);width_mean=mean(width_visible_fiber_data);
%                            angle_mean=mean(angle_visible_fiber_data);straightness_mean=mean(straightness_visible_fiber_data);
% 
%                            length_std=std(length_visible_fiber_data);width_std=std(width_visible_fiber_data);
%                            angle_std=std(angle_visible_fiber_data);straightness_std=std(straightness_visible_fiber_data);
% 
%                            length_string=['Mean= ' num2str(length_mean) ' Std= ' num2str(length_std) ' Fibres= ' num2str(total_visible_fibres)];
%                            width_string=['Mean= ' num2str(width_mean) ' Std= ' num2str(width_std) ' Fibres= ' num2str(total_visible_fibres)];
%                            angle_string=[' Mean= ' num2str(angle_mean) ' Std= ' num2str(angle_std) ' Fibres= ' num2str(total_visible_fibres)];
%                            straightness_string=[' Mean= ' num2str(straightness_mean) ' Std= ' num2str(straightness_std) ' Fibres= ' num2str(total_visible_fibres)];

                          property_value=get(property_box,'Value');
                          figure(statistics_fig);
                          bin_number=str2num(get(bin_number_box','string'));

                        if(property_value==1)
                            %not available for 'All ROIs' option
%                           sub1= subplot(2,2,1);hist(length_visible_fiber_data,bin_number);hold on;
%                           sub2= subplot(2,2,2);hist(width_visible_fiber_data,bin_number);hold on;
%                            sub3= subplot(2,2,3);hist(angle_visible_fiber_data,bin_number);hold on;
%                            sub4= subplot(2,2,4);hist(straightness_visible_fiber_data,bin_number);hold on;

                        elseif(property_value==2)
                            plot2=subplot(roi_size_temp,1,kipper);hist(length_visible_fiber_data,bin_number);title(Data{cell_selection_data(kipper,1),1});hold on;
                        elseif(property_value==3)
                            plot3=subplot(roi_size_temp,1,kipper);hist(width_visible_fiber_data,bin_number);title(Data{cell_selection_data(kipper,1),1});hold on;
                        elseif(property_value==4)
                            plot4=subplot(roi_size_temp,1,kipper);hist(angle_visible_fiber_data,bin_number);title(Data{cell_selection_data(kipper,1),1});hold on;
                        elseif(property_value==5)
                            plot5=subplot(roi_size_temp,1,kipper);hist(straightness_visible_fiber_data,bin_number);title(Data{cell_selection_data(kipper,1),1});hold on;
                        end
                        
                        
                   end
                   hold off;
                end
            end
        end
        
        function[]=more_settings_fn(object,handles)
            set(status_message,'string','Select sources of fibers and/or fiber selection function');
            relative_horz_displacement_settings=30;
            settings_position_vector=[50+round(SW2/5*1.5)+relative_horz_displacement_settings SH-190 160 160];
            settings_fig = figure('Resize','off','Units','pixels','Position',settings_position_vector,'Visible','on','MenuBar','none','name','Settings','NumberTitle','off','UserData',0,'Color',defaultBackground);
            fiber_data_source_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0 0.7 0.45 0.3],'String','Source of fibers');
            fiber_data_source_box=uicontrol('Parent',settings_fig,'Enable','on','Style','popupmenu','Tag','Fiber Data location','Units','normalized','Position',[0 0.4 0.45 0.3],'String',{'CTFIRE Fiber data','Post Processing Fiber data'},'Callback',@fiber_data_location_fn,'FontUnits','normalized');
            roi_method_define_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0.5 0.7 0.45 0.3],'String','Fiber selection method ');
            roi_method_define_box=uicontrol('Parent',settings_fig,'Enable','on','Style','popupmenu','Units','normalized','Position',[0.5 0.4 0.45 0.3],'String',{'Midpoint','Entire Fibre'},'Callback',@roi_method_define_fn,'FontUnits','normalized');
            SHG_define_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0 0.1 0.45 0.2],'String','SHG threshold');
            SHG_define_box=uicontrol('Parent',settings_fig,'Enable','on','Style','edit','Units','normalized','Position',[0.5 0.1 0.45 0.3],'String',num2str(SHG_threshold),'Callback',@SHG_define_fn,'FontUnits','normalized','BackgroundColor',[1 1 1]);
            %display(fiber_source);%display(fiber_method);
            
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

            function[]=roi_method_define_fn(object,handles)
                if(get(object,'Value')==1)
                   fiber_method='mid';
                elseif(get(object,'Value')==2)
                    fiber_method='whole';
                end
                %display(fiber_method);
            end

            function[]=fiber_data_location_fn(object,handles)
                 if(get(object,'Value')==1)
                    fiber_source='ctFIRE';
                elseif(get(object,'Value')==2)
                    fiber_source='postPRO';
                 end
                 %display(fiber_source);
            end
            
            function[]=SHG_define_fn(object,handles)
               SHG_threshold=str2num(get(SHG_define_box,'string'));
            end
        end
    
        function[]=automatic_roi_fn(object,handles)
        % asks for window size and propetry - length ,width 
        % , angle and straightness
        
        %default values
        property='length';window_size=100;
        
        position_vector=[50+round(SW2/5*1.5)+50 SH-160 160 90];
        pop_up_window= figure('Resize','off','Units','pixels','Position',position_vector,'Visible','on','MenuBar','none','name','Settings','NumberTitle','off','UserData',0,'Color',defaultBackground);
        property_message=uicontrol('Parent',pop_up_window,'Enable','on','Style','text','Units','normalized','Position',[0 0.65 0.45 0.35],'String','Choose Property');
        property_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','popupmenu','Tag','Fiber Data location','Units','normalized','Position',[0 0.3 0.45 0.35],'String',{'Length','Width','Angle','Straightness'},'Callback',@property_select_fn,'FontUnits','normalized');
        window_size_message=uicontrol('Parent',pop_up_window,'Enable','on','Style','text','Units','normalized','Position',[0.5 0.65 0.45 0.35],'String','Enter Window SIze');
        window_size_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','edit','Units','normalized','Position',[0.5 0.3 0.45 0.35],'String',num2str(window_size),'Callback',@window_size_fn,'FontUnits','normalized','BackgroundColor',[1 1 1]);
        ok_box=uicontrol('Parent',pop_up_window,'Enable','on','Style','pushbutton','String','Ok','Units','normalized','Position',[0 0 0.45 0.25],'Callback',@ok_fn);
            
            function[]= property_select_fn(handles,Indices)
                property_index=get(object,'Value');
                if(property_index==1),property='length';
                elseif(property_index==2),property='width';
                elseif(property_index==3),property='angle';
                elseif(property_index==4),property='straightness';
                end
            end
            
            function[]=window_size_fn(object,handles)
               window_size=str2num(get(object,'String'));%display(window_size); 
            end
            
            function[]=ok_fn(object,handles)
                close;% closes the pop up window
                automatic_roi_sub_fn(property,window_size);
                
            end
        %automatic_roi_sub_fn(property,window_size);
        
            function[]=automatic_roi_sub_fn(property,window_size)
            % property can be either - length,width,angle,straightness
            %   window_size is the size of the square window
%             steps
%             1 open a new figure called automatic
%             2 define the window size
%             3 define the number of steps/shifts in each direction
%             4 based on midpoint calculate the average parameter - length first of all
%             5 %display the minimum and maximum roi
%             6 save these ROIs by name Auto_ROI_length_max and min
            auto_fig=figure;
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
                s1=size(image,1);s2=size(image,2);size_fibers=size(matdata.data.Fa,2);
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
                ctFIRE_length_threshold=matdata.cP.LL1;
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
                     s2=size(vertex_indices,2);
                     xmid_array(i)=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                     ymid_array(i)=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                     fprintf('fiber number=%d xmid=%d ymid=%d \n',i,xmid_array(i),ymid_array(i));
                end
            elseif(strcmp(fiber_source,'postPRO')==1)
               if(isfield(matdata.data,'PostProGUI')&&isfield(matdata.data.PostProGUI,'fiber_indices'))
                    fiber_data2=matdata.data.PostProGUI.fiber_indices;
                    size_fibers=size(fiber_data2,1);
                    for i=1:size_fibers
                         vertex_indices=matdata.data.Fa(i).v;
                         s2=size(vertex_indices,2);
                         xmid_array(i)=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                         ymid_array(i)=matdata.data.Xa(vertex_indices(floor(s2/2)),2);
                         fprintf('fiber number=%d xmid=%d ymid=%d \n',i,xmid_array(i),ymid_array(i));
                    end
               else
                   set(status_message,'String','Post Processing Data not present');
               end
            end
            %parameter_input='length';% other values='width','angle' and 'straightness'
            max=0;min=Inf;x_max=1;y_max=1;x_min=1;y_min=1;
            tic;
            s1=size(image,1);s2=size(image,2);
            for m=1:1:s1-window_size+1
                for n=1:1:s2-window_size+1
                    parameter=0;count=1;
%                     temp_image=image;fprintf('m=%d n=%d\n',m,n);
                           for k=1:size_fibers
                              if(fiber_data2(k,2)==1&&xmid_array(k)>=m&&xmid_array(k)<=m+window_size&&ymid_array(k)>=n&&ymid_array(k)<=n+window_size)
                                    parameter=parameter+fiber_data2(k,property_column);
                                    count=count+1;
                              end
                           end
                           count=count-1;
                           parameter=parameter/count;
                           if(parameter>max)
                               x_max=m;y_max=n;max=parameter;
                               fprintf('\nx_max=%d y_max=%d parameter=%d',x_max,y_max,parameter);
                           end
                           if(parameter<min)
                               x_min=m;y_min=n;
                           end
%                     figure(auto_fig);imshow(temp_image);pause(1);  
                end
            end
            toc;
           
%            if(parameter>max)
%                x_max=m;y_max=n;max=parameter;
%                fprintf('\nx_max=%d y_max=%d parameter=%d',x_max,y_max,parameter);
%            end
%            if(parameter<min)
%                x_min=m;y_min=n;
%            end
%              for k=1:size_fibers
%               if(fiber_data2(k,2)==1)
%                 if(strcmp(parameter_input,'length')==1)
%                     if(xmid_array(k)>=x_max&&xmid_array(k)<=x_max+window_size&&ymid_array(k)>=y_max&&ymid_array(k)<=y_max+window_size)
%                         fiber_data2(k,2)=1; 
%                     else
%                         fiber_data2(k,2)=0;
%                     end
%                 end
%               end
%             end
%            
            a=x_max;b=y_max;
            vertices=[a,b;a+window_size,b;a+window_size,b+window_size;a,b+window_size];
            BW=roipoly(image,vertices(:,1),vertices(:,2));
            temp_boundary=find_boundary(BW,image);
            figure(auto_fig);imshow(image+temp_boundary);hold on;
            plot_fibers(fiber_data2,auto_fig,0,1);
            fprintf('\nx_max=%d y_max=%d x_min=%d y_min=%d\n',x_max,y_max,x_min,y_min);
            
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
            
            
            D=[];% D contains the file data
            disp_data=[];% used in pop up %display
            %format of D - contains 9 sheets - all raw data, raw
            %data of l,w,a and s, stats of l,w,a and s
            % steps 
%             1 initialize D, s1,s2 and s3
%             2 run a loop for the number of ROIs
%             3 find the fibres present in a particular ROI and save in D - raw sheets
%             4 find the statistics and store in stat sheetts
%             5 save the file in ROI/ROI_analysis
        
           measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 470 300],'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
           measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
           s3=size(cell_selection_data,1);s1=size(image,1);s2=size(image,2);
           names=fieldnames(separate_rois);%display(names);
           Data=names;
           for i=1:s1
               for j=1:s2
                   BW(i,j)=logical(0);
               end
           end
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
%                type=separate_rois.(names(cell_selection_data(k))).shape;
%                %display(type);
                 if(iscell(separate_rois.(names{cell_selection_data(k),1}).shape)==0)
                    type=separate_rois.(names{cell_selection_data(k),1}).shape;
                    vertices=[];data2=[];
                    if(type==1)%Rectangle
                        data2=separate_rois.(names{cell_selection_data(k),1}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(image,vertices(:,1),vertices(:,2));
                    elseif(type==2)%freehand
                        %display('freehand');
                        vertices=separate_rois.(names{cell_selection_data(k),1}).roi;
                        BW=roipoly(image,vertices(:,1),vertices(:,2));
                    elseif(type==3)%Ellipse
                          %display('ellipse');
                          data2=separate_rois.(names{cell_selection_data(k),1}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                          %the rect enclosing the ellipse. 
                          % equation of ellipse region->
                          % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                          s1=size(image,1);s2=size(image,2);
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
                    elseif(type==4)%Polygon
                        %display('polygon');
                        vertices=separate_rois.(names{cell_selection_data(k),1}).roi;
                        BW=roipoly(image,vertices(:,1),vertices(:,2));
                    end
                 elseif(iscell(separate_rois.(names{cell_selection_data(k),1}).shape)==1)
                     s_subcomps=size(separate_rois.(Data{cell_selection_data(k,1),1}).roi,2);
                        %display(s_subcomps);
                        s1=size(image,1);s2=size(image,2);
                        for a=1:s1
                            for b=1:s2
                                mask2(a,b)=logical(0);
                            end
                        end
                        for p=1:s_subcomps
                              data2=[];vertices=[];
                              if(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==1)
                                data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                                BW=roipoly(image,vertices(:,1),vertices(:,2));
                              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==2)
                                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                                  BW=roipoly(image,vertices(:,1),vertices(:,2));
                              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape{p}==3)
                                  data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi{p};
                                  a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                  s1=size(image,1);s2=size(image,2);
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
                                  BW=roipoly(image,vertices(:,1),vertices(:,2));
                              end
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
                           figure(im_fig);
                           for i=1:size_fibers
                                if (fiber_data2(i,2)==1)              
                                    vertex_indices=matdata.data.Fa(i).v;
                                    s2=size(vertex_indices,2);
                                    %pause(1);
                                    % this part plots the center of fibers on the image, right
                                    % now roi is not considered
                                    x=matdata.data.Xa(vertex_indices(floor(s2/2)),1);
                                    y=matdata.data.Xa(vertex_indices(floor(s2/2)),2);

                                    if(BW(y,x)==logical(1)) % x and y seem to be interchanged in plot
                                        % function.
                                    else
                                        fiber_data2(i,2)=0;
                                    end
                                end
                           end
                    end

                     num_of_fibers=size(fiber_data2,1);
            count=1;
            if(k==1)
               D{2,1,10}='SHG pixels';
               D{3,1,10}='Total pixels';
               D{4,1,10}='SHG Ratio';
               D{5,1,10}='SHG Threshold used';
                
               D{2,1,1}='Median';
               D{3,1,1}='Mode';
               D{4,1,1}='Mean';
               D{5,1,1}='Variance';
               D{6,1,1}='Standard Deviation';
               D{7,1,1}='Min';
               D{8,1,1}='Max';
               D{9,1,1}='Number of fibres';
               D{10,1,1}='Alignment';
               
               D{2,1,2}='Median';
               D{3,1,2}='Mode';
               D{4,1,2}='Mean';
               D{5,1,2}='Variance';
               D{6,1,2}='Standard Deviation';
               D{7,1,2}='Min';
               D{8,1,2}='Max';
               D{9,1,2}='Number of fibres';
               D{10,1,2}='Alignment';
               
               D{2,1,3}='Median';
               D{3,1,3}='Mode';
               D{4,1,3}='Mean';
               D{5,1,3}='Variance';
               D{6,1,3}='Standard Deviation';
               D{7,1,3}='Min';
               D{8,1,3}='Max';
               D{9,1,3}='Number of fibres';
               D{10,1,3}='Alignment';
               
               D{2,1,4}='Median';
               D{3,1,4}='Mode';
               D{4,1,4}='Mean';
               D{5,1,4}='Variance';
               D{6,1,4}='Standard Deviation';
               D{7,1,4}='Min';
               D{8,1,4}='Max';
               D{9,1,4}='Number of fibres';
               D{10,1,4}='Alignment';
               
               disp_data{1,1}='Length';             disp_data{1,s3+2}='Width';          disp_data{1,2*s3+3}='Angle';                    disp_data{1,3*s3+4}='Straightness';
               disp_data{3,1}='Median';             disp_data{3,s3+2}='Median';         disp_data{3,2*s3+3}='Median';                   disp_data{3,3*s3+4}='Median';
               disp_data{4,1}='Mode';               disp_data{4,s3+2}='Mode';           disp_data{4,2*s3+3}='Mode';                     disp_data{4,3*s3+4}='Mode';
               disp_data{5,1}='Mean';               disp_data{5,s3+2}='Mean';           disp_data{5,2*s3+3}='Mean';                     disp_data{5,3*s3+4}='Mean';
               disp_data{6,1}='Variance';           disp_data{6,s3+2}='Variance';       disp_data{6,2*s3+3}='Variance';                 disp_data{6,3*s3+4}='Variance';
               disp_data{7,1}='Standard Dev';       disp_data{7,s3+2}='Standard Dev';   disp_data{7,2*s3+3}='Standard Dev';             disp_data{7,3*s3+4}='Standard Dev';
               disp_data{8,1}='Min';                disp_data{8,s3+2}='Min';            disp_data{8,2*s3+3}='Min';                      disp_data{8,3*s3+4}='Min';
               disp_data{9,1}='Max';                disp_data{9,s3+2}='Max';            disp_data{9,2*s3+3}='Max';                      disp_data{9,3*s3+4}='Max';
               disp_data{10,1}='Number of fibres';  disp_data{10,s3+2}='Number of fibres';disp_data{10,2*s3+3}='Number of fibres';      disp_data{10,3*s3+4}='Number of fibres';
               disp_data{11,1}='Alignment';         disp_data{11,s3+2}='Alignment';     disp_data{11,2*s3+3}='Alignment';               disp_data{11,3*s3+4}='Alignment';
            end
            disp_data{2,1+k}=Data{cell_selection_data(k,1),1};  disp_data{2,2+k+s3}=Data{cell_selection_data(k,1),1};   disp_data{2,3+k+2*s3}=Data{cell_selection_data(k,1),1}; disp_data{2,4+k+3*s3}=Data{cell_selection_data(k,1),1};
            
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
            
            D{2,5*(k-1)+1,5}='fiber number';
            D{2,5*(k-1)+2,5}='length';
            D{2,5*(k-1)+3,5}='width';
            D{2,5*(k-1)+4,5}='angle';
            D{2,5*(k-1)+5,5}='straightness';
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
            end
        

           end
           a1=size(cell_selection_data,1);
        operations='';
        for d=1:a1
            operations=[operations '_' Data{cell_selection_data(d,1),1}];
        end
        %display(operations);%pause(5);
%         %xlswrite([pathname 'ROI_analysis\' filename ' operation' num2str(operation_number)],D(:,:,6),'Raw Data');
         xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,5),'Raw data');
         xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,1),'Length Stats');
         xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,2),'Width stats');
         xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,3),'Angle stats');
         xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,4),'straightness stats');
        xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,6),'Raw Length Data');
        xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,7),'Raw Width Data');
        xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,8),'Raw Angle Data');
        xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,9),'Raw Straightness Data');
        xlswrite([pathname 'ROI\ROI_analysis\' filename operations ],D(:,:,10),'SHG percentages Data');
        set(measure_table,'Data',disp_data);
        set(measure_fig,'Visible','on');
        set(generate_stats_box2,'Enable','off');
        end
 
        %analyzer functions- end
        function[boundary]=find_boundary(BW,image)
           s1=size(image,1);s2=size(image,2); 
           for i=1:s1
               for j=1:s2
                   boundary(i,j)=uint8(0);
               end
           end
           
           for i=2:s1-1
                for j=2:s2-1
                    North=BW(i-1,j);NorthWest=BW(i-1,j-1);NorthEast=BW(i-1,j+1);
                    West=BW(i,j-1);East=BW(i,j+1);
                    SouthWest=BW(i+1,j-1);South=BW(i+1,j);SouthEast=BW(i+1,j+1);
                    if(BW(i,j)==logical(1)&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
                        boundary(i,j)=uint8(255);
                    end
                end
          end
        end
        
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
        %rng(1001) ;
        clrr2 = rand(size(a.data.Fa,2),3); % set random color
        for i=1:size(a.data.Fa,2)
            if fiber_data(i,2)==1
                point_indices=a.data.Fa(1,fiber_data(i,1)).v;
                s1=size(point_indices,2);
                x_cord=[];y_cord=[];
                for j=1:s1
                    x_cord(j)=a.data.Xa(point_indices(j),1);
                    y_cord(j)=a.data.Xa(point_indices(j),2);
                end
                color1 = clrr2(i,1:3); %rand(3,1); YL: fix the color of each fiber
                figure(fig_name);plot(x_cord,y_cord,'LineStyle','-','color',color1,'linewidth',0.005);hold on;
                if(print_fiber_numbers==1)
                    %  text(x_cord(s1),y_cord(s1),num2str(i),'HorizontalAlignment','center','color',color1);
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
                pause(pause_duration);
            end
        end
        end
      
        function []=visualisation(handles,indices)
            
        % idea conceived by Prashant Mittal
        % implemented by Guneet Singh Mehta and Prashant Mittal
        pause_duration=0;
        print_fiber_numbers=1;
        string='';
        a=matdata; 
        address=pathname;
        orignal_image=image;
        gray123(:,:,1)=orignal_image(:,:);
        gray123(:,:,2)=orignal_image(:,:);
        gray123(:,:,3)=orignal_image(:,:);
%         steps-
%         1 open figures according to the buttons on in the GUI
%         2 define colors for l,w,s,and angle
% %         3 change the position of figures so that all are visible
%             4 define max and min of each parameter
%             5 according to max and min define intensity of base and variable- call fibre_data which contains all data
        
        colormap cool;%hsv is also good
        colors=colormap;size_colors=size(colors,1);
        
            fig_length=figure;set(fig_length,'Visible','off','name','length visualisation');imshow(gray123);colormap cool;colorbar;hold on;
            %display(fig_length);
        
        
            fig_width=figure;set(fig_width,'Visible','off','name','width visualisation');imshow(gray123);colorbar;colormap cool;hold on;
            %display(fig_width);
        
        
            fig_angle=figure;set(fig_angle,'Visible','off','name','angle visualisation');imshow(gray123);colorbar;colormap cool;hold on;
            %display(fig_angle);
            fig_straightness=figure;set(fig_straightness,'Visible','off','name','straightness visualisation');imshow(gray123);colorbar;colormap cool;hold on;
            %display(fig_straightness);
        
        
        
        flag_temp=0;
        for i=1:size(a.data.Fa,2)
           if(fiber_data(i,2)==1)
               if(flag_temp==0)
                    max_l=fiber_data(i,3);max_w=fiber_data(i,4);max_a=fiber_data(i,5);max_s=fiber_data(i,6);
                    min_l=fiber_data(i,3);min_w=fiber_data(i,4);min_a=fiber_data(i,5);min_s=fiber_data(i,6);
                    flag_temp=1;
               end
               if(fiber_data(i,3)>max_l)max_l=fiber_data(i,3);end
               if(fiber_data(i,3)<min_l)min_l=fiber_data(i,3);end
               
               if(fiber_data(i,4)>max_w)max_w=fiber_data(i,4);end
               if(fiber_data(i,4)<min_w)min_w=fiber_data(i,4);end
               
               if(fiber_data(i,5)>max_a)max_a=fiber_data(i,5);end
               if(fiber_data(i,5)<min_a)min_a=fiber_data(i,5);end
               
               if(fiber_data(i,6)>max_s)max_s=fiber_data(i,6);end
               if(fiber_data(i,6)<min_s)min_s=fiber_data(i,6);end
           end
        end
        
        rng(1001) ;
        for k=1:4
            
            if(k==1)
%                fprintf('in k=1 and thresh_length_radio=%d',get(thresh_length_radio,'value'));
                max=max_l;min=min_l;%display(max);%display(min);
%                 colorbar('Ticks',[0,size_colors],'yticks',{num2str(0),num2str(size_colors)});
                cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_length;
            end
             if(k==2)
                 
                 max=max_w;min=min_w;%%display(max);%display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_width;
             end
             if(k==3)
                 
                 max=max_a;min=min_a;%%display(max);%display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_angle;
             end
             if(k==4)
                 
                 max=max_s;min=min_s;%%display(max);%display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_straightness;
             end
 %            fprintf('in k=%d and length=%d width=%d angle=%d straight=%d',k,get(thresh_length_radio,'value'),get(thresh_width_radio,'value'),get(thresh_angle_radio,'value'),get(thresh_straight_radio,'value'));
             fprintf('current figure=%d\n',current_fig);%pause(10);
             %continue;
             
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
                     %%display(color_final);%pause(0.01);
                    figure(current_fig);plot(x_cord,y_cord,'LineStyle','-','color',color_final,'linewidth',0.005);hold on;
                
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
                    pause(pause_duration);
                end

            end
            hold off % YL: allow the next high-level plotting command to start over
            
        end
    end


    end

    function[]=index_fn(object,handles)
        if(get(index_box,'Value')==1)
            Data=get(roi_table,'Data');
            s3=size(xmid,2);%display(s3);
           for k=1:s3
             figure(im_fig);text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
           end
        end
    end

    function[]=ctFIRE_to_roi_fn(object,handles)
        %major issues-
        %1 fibers coming on the edge of the ROI
        
       % steps
%        1 find the image within the roi using gmask
%        2 save the image in ROI management
%        3 find a way to run ctFIRE on the saved image
%        4 prompt the user to call the ctFIRE by default values or call the interface itself
        %5 call ctFIRE by default value
%         
%         steps for the sub function
%         1 run a par for loop
%         2 check if one selection is a combination
%         3 if not then write the image 
%         4 run the ctFIRE
%         5 delete the image
           
        s1=size(image,1);s2=size(image,2);
        temp_image(1:s1,1:s2)=uint8(0);
        for i=1:s1
            for j=1:s2
                if(gmask(i,j)==logical(1))
                  temp_image(i,j)=image(i,j);
                else
                    temp_image(i,j)=uint8(0);
                end
            end
        end
        if(exist(horzcat(pathname,'ROI\ROI_management\ctFIRE_on_ROI'),'dir')==0)%check for ROI folder
               mkdir(pathname,'ROI\ROI_management\ctFIRE_on_ROI');
        end
        %imwrite(temp_image,[pathname 'ROI\ROI_management\ctFIRE_on_ROI\' [ filename combined_name_for_ctFIRE '.tif']]);
        % calling ctFIRE
         %assigning default values of fields of cP
         cP.plotflag=0;
         cP.RO=1;
         cP.LW1=0.5;
         cP.LL1=30;
         cP.FNL=9999;
         cP.Flabel=0;
         cP.angH=[];
         cP.lenH=[];
         cP.angV=[];
         cP.lenV=[];
         cP.stack=[];
         cP.postp=0;
         cP.BINs=10;
         cP.RES=300;
         cP.widMAX=15;
         cP.plotflagnof=0;
         cP.angHV=1;cP.lenHV=1;cP.strHV=1;cP.widHV=1;
         cP.slice=[];
         cP.widcon = struct('wid_mm',10,'wid_mp',6,'wid_sigma',1,'wid_max',0,'wid_opt',1);
         
         % assigning values to ctFP
         ctFP.pct=0.3;
         ctFP.SS=3;
         ctFP.value=[];
         ctFP.status=1;
         
         ctFP.value.sigma_im=0;
         ctFP.value.sigma_d=0.3;
         ctFP.value.dtype='cityblock';
         ctFP.value.thresh_im=[];
         ctFP.value.thresh_im2=5;
         ctFP.value.thresh_Dxlink=1.5;
         ctFP.value.s_xlinkbox=8;
         ctFP.value.thresh_LMP=0.2;
         ctFP.value.thresh_LMPdist=2;
         ctFP.value.thresh_ext=0.3420;
         ctFP.value.lam_dirdecay=0.5;
         ctFP.value.s_minstep=2;
         ctFP.value.s_maxstep=6;
         ctFP.value.thresh_dang_aextend=0.9848;
         ctFP.value.thresh_dang_L=15;
         ctFP.value.thresh_short_L=15;
         ctFP.value.s_fiberdir=4;
         ctFP.value.thresh_linkd=15;
         ctFP.value.thresh_linka=-0.8660;
         ctFP.value.thresh_flen=15;
         ctFP.value.thresh_numv=3;
         ctFP.value.scale=[1 1 1];
         ctFP.value.s_boundthick=10;
         ctFP.value.blist=1;
         ctFP.value.s_maxspace=5;
         ctFP.value.lambda=0.01;
         ctFP.value.ang_interval=3;
         
         position=[50 50 200 200];
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        defaultBackground = get(0,'defaultUicontrolBackgroundColor');
        temp_popup_window=figure('Units','pixels','Position',[left+width+15+80 bottom+height-200 300 200],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);          
        text1=uicontrol('Parent',temp_popup_window,'Style','text','string','','Units','normalized','Position',[0.05 0.4 0.9 0.55]);    
        set(text1,'string','Do you wish to run the ctFIRE with default parameters ? If you press Customized ctFIRE then all currently open windows will be closed and ctFIRE console will be called. You need to select the image titled as filename_ROInumber in "orignal image location"\ROI\ROI_management\ctFIRE_on_ROI');
        default_run_box=uicontrol('Parent',temp_popup_window,'Style','pushbutton','string','Run Default ctFIRE','Units','normalized','Position',[0.03 0.05 0.45 0.3],'Callback',@default_ctFIRE_fn);     
        customized_run_box=uicontrol('Parent',temp_popup_window,'Style','pushbutton','string','Run Customized ctFIRE','Units','normalized','Position',[0.52 0.05 0.45 0.3],'Callback',@customized_ctFIRE_fn);     
        function[]= default_ctFIRE_fn(object,handles)
            close;%closes the temp_popup_window
            %ctFIRE_1([pathname 'ROI\ROI_Management\ctFIRE_on_ROI\'],[ filename combined_name_for_ctFIRE '.tif'],[pathname 'ROI\ROI_Management\ctFIRE_on_ROI\'],cP,ctFP);
            default_sub_function;% this function is called 
            %set(status_message,'Please wait. ctFIRE is running on the ROI');
        end
        function[]= customized_ctFIRE_fn(object,handles)
            close;%closes the temp_popup_window
            ctFIRE;
        end
        
        function[]=default_sub_function()
%         1 run a par for loop
%         2 check if one selection is a combination
%         3 if not then write the image 
%         4 run the ctFIRE
%         5 delete the image
            
            %display(size(cell_selection_data,1));
            s_roi_num=size(cell_selection_data,1);
            Data=get(roi_table,'Data'); 
            separate_rois_copy=separate_rois;
            cell_selection_data_copy=cell_selection_data;
            Data_copy=Data;
            image_copy=image;pathname_copy=pathname;filename_copy=filename;
            combined_name_for_ctFIRE_copy=combined_name_for_ctFIRE;
            if(s_roi_num>1)
              %try  
                matlabpool open; 
                
                parfor k=1:s_roi_num
                    image_copy2=image_copy;
                    combined_rois_present=0; 
                    if(iscell(separate_rois_copy.(Data_copy{cell_selection_data_copy(k,1),1}).shape)==1)
                        combined_rois_present=1; 
                    end

                    if(combined_rois_present==0)
                       % when combination of ROIs is not present
                       %finding the mask -starts
                       if(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape==1)
                        data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                      elseif(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape==2)
                          vertices=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                          BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                      elseif(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape==3)
                          data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          %s1=size(image,1);s2=size(image,2);
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
                      elseif(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape==4)
                          vertices=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi;
                          BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                       end
                       %display(size(BW));
                       for m=1:s1
                           for n=1:s2
                                if(BW(m,n)==logical(0))
                                    image_copy2(m,n)=0;
                                end
                           end
                       end
                       filename_temp=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\' filename_copy '_' Data{cell_selection_data_copy(k,1),1} '.tif'];
                       imwrite(image_copy2,filename_temp);
                       imgpath=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\'];imgname=[filename_copy '_' Data{cell_selection_data_copy(k,1),1} '.tif'];
                       ctFIRE_1(imgpath,imgname,imgpath,cP,ctFP);%error here - error resolved - making cP.plotflagof=0 nad cP.plotflagnof=0
                   
                    elseif(combined_rois_present==1)
                        % for single combined ROI
                       s_subcomps=size(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi,2);
                       for p=1:s_subcomps
                           image_copy2=image_copy;
                          data2=[];vertices=[];
                          if(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape{p}==1)
                            data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi{p};
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                          elseif(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape{p}==2)
                              vertices=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi{p};
                              BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                          elseif(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape{p}==3)
                              data2=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi{p};
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
                          elseif(separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).shape{p}==4)
                              vertices=separate_rois_copy.(Data{cell_selection_data_copy(k,1),1}).roi{p};
                              BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                          end
                          if(p==1)
                             mask2=BW; 
                          else
                             mask2=mask2|BW;
                          end
                         
                       end
                       BW=mask2;
                       for m=1:s1
                           for n=1:s2
                                if(BW(m,n)==logical(0))
                                    image_copy2(m,n)=0;
                                end
                           end
                       end
                       filename_temp=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\' filename_copy '_' Data{cell_selection_data_copy(k,1),1} '.tif'];
                       imwrite(image_copy2,filename_temp);
                       imgpath=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\'];imgname=[filename_copy '_' Data{cell_selection_data_copy(k,1),1} '.tif'];
                       ctFIRE_1(imgpath,imgname,imgpath,cP,ctFP);%error here

                      
                    end
                end
                    matlabpool close;
            elseif(s_roi_num==1)
                % code for single ROI
                Data=get(roi_table,'Data'); 
                combined_rois_present=0; 
                if(iscell(separate_rois.(Data{cell_selection_data(1,1),1}).shape)==1)
                    combined_rois_present=1; 
                end
                image_copy2=image;
                if(combined_rois_present==0)
                      if(separate_rois.(Data{cell_selection_data(1,1),1}).shape==1)
                        data2=separate_rois.(Data{cell_selection_data(1,1),1}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(image,vertices(:,1),vertices(:,2));
                        elseif(separate_rois.(Data{cell_selection_data(1,1),1}).shape==2)
                          vertices=separate_rois.(Data{cell_selection_data(1,1),1}).roi;
                          BW=roipoly(image,vertices(:,1),vertices(:,2));
                        elseif(separate_rois.(Data{cell_selection_data(1,1),1}).shape==3)
                          data2=separate_rois.(Data{cell_selection_data(1,1),1}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          %s1=size(image,1);s2=size(image,2);
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
                         elseif(separate_rois.(Data{cell_selection_data(1,1),1}).shape==4)
                          vertices=separate_rois.(Data{cell_selection_data(1,1),1}).roi;
                          BW=roipoly(image,vertices(:,1),vertices(:,2));
                      end
                       for m=1:s1
                           for n=1:s2
                                if(BW(m,n)==logical(0))
                                    image_copy2(m,n)=0;
                                end
                           end
                       end
                       filename_temp=[pathname 'ROI\ROI_management\ctFIRE_on_ROI\' filename '_' Data{cell_selection_data(1,1),1} '.tif'];
                       imwrite(image_copy2,filename_temp);
                       imgpath=[pathname 'ROI\ROI_management\ctFIRE_on_ROI\'];imgname=[filename '_' Data{cell_selection_data(1,1),1} '.tif'];
                       ctFIRE_1(imgpath,imgname,imgpath,cP,ctFP);%error here

                elseif(combined_rois_present==1)
%                     try
%                         matlabpool open;
%                     catch
%                         matlabpool close;
%                     end
                        matlabpool open;
                        s_subcomps=size(separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).roi,2);
                        combined_name=Data{cell_selection_data_copy(1,1),1};
                        combined_name=combined_name(7:end);
                       for p=1:s_subcomps
                           underscore_indices=findstr(combined_name,'_');
                           ROI_sub_name(p,:)=combined_name(underscore_indices(1):underscore_indices(2)-1);
                           combined_name=combined_name(underscore_indices(2):end);
                       end
                        
                        parfor p=1:s_subcomps
                           image_copy2=image_copy;
                          data2=[];vertices=[];
                          if(separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).shape{p}==1)
                            data2=separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).roi{p};
                            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                            BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                          elseif(separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).shape{p}==2)
                              vertices=separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).roi{p};
                              BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                          elseif(separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).shape{p}==3)
                              data2=separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).roi{p};
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
                          elseif(separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).shape{p}==4)
                              vertices=separate_rois_copy.(Data{cell_selection_data_copy(1,1),1}).roi{p};
                              BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
                          end
%                           if(p==1)
%                              mask2=BW; 
%                           else
%                              mask2=mask2|BW;
%                           end
                           for m=1:s1
                               for n=1:s2
                                    if(BW(m,n)==logical(0))
                                        image_copy2(m,n)=0;
                                    end
                               end
                           end
                            filename_temp=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\' filename_copy '_' ROI_sub_name(p,:) '.tif'];
                           imwrite(image_copy2,filename_temp);
                           imgpath=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\'];imgname=[filename_copy '_' ROI_sub_name(p,:) '.tif'];
                           ctFIRE_1(imgpath,imgname,imgpath,cP,ctFP);%error here

                       end
                       matlabpool close;
                       %BW=mask2;
%                        for m=1:s1
%                            for n=1:s2
%                                 if(BW(m,n)==logical(0))
%                                     image_copy2(m,n)=0;
%                                 end
%                            end
%                        end
%                        filename_temp=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\' filename_copy '_' Data{cell_selection_data_copy(1,1),1} '.tif'];
%                        imwrite(image_copy2,filename_temp);
%                        imgpath=[pathname_copy 'ROI\ROI_management\ctFIRE_on_ROI\'];imgname=[filename_copy '_' Data{cell_selection_data_copy(1,1),1} '.tif'];
%                        ctFIRE_1(imgpath,imgname,imgpath,cP,ctFP);%error here

                end
                
            end
        end
        
     function[BW]=get_mask(Data,iscell_variable,roi_index_queried)
        if(iscell_variable==0)
              if(separate_rois.(Data{cell_selection_data(k,1),1}).shape==1)
                data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                BW=roipoly(image,vertices(:,1),vertices(:,2));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==2)
                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  BW=roipoly(image,vertices(:,1),vertices(:,2));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==3)
                  data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                  s1=size(image,1);s2=size(image,2);
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
                  BW=roipoly(image,vertices(:,1),vertices(:,2));
             end
        end
    end

        
    end

    function[BW]=get_mask(Data,iscell_variable,roi_index_queried)
        k=roi_index_queried;
        if(iscell_variable==0)
              if(separate_rois.(Data{cell_selection_data(k,1),1}).shape==1)
                data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                BW=roipoly(image,vertices(:,1),vertices(:,2));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==2)
                  vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  BW=roipoly(image,vertices(:,1),vertices(:,2));
              elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==3)
                  data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
                  a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                  s1=size(image,1);s2=size(image,2);
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
                  BW=roipoly(image,vertices(:,1),vertices(:,2));
             end
        end
    end

end


