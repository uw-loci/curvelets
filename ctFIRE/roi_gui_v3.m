
function[]=roi_gui_v3()
    
%     Developer - Guneet Singh Mehta
%     Indian Institute of Technology, Jodhpur
%     Former Research Intern at LOCI,UW Madison
%     email- mehta_guneet@iitj.ac.in
%     Duration - December 1 - December 30 th 2014
  
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
    %roi_mang_fig - roi manager figure - initilisation starts
    SSize = get(0,'screensize');SW2 = SSize(3); SH = SSize(4);
    defaultBackground = get(0,'defaultUicontrolBackgroundColor'); 
    roi_mang_fig = figure('Resize','off','Color',defaultBackground,'Units','pixels','Position',[50 50 round(SW2/5) round(SH*0.9)],'Visible','on','MenuBar','none','name','ROI Manager','NumberTitle','off','UserData',0);
    relative_horz_displacement=20;% relative horizontal displacement of analysis figure from roi manager
         %roi analysis module is not visible in the beginning
    roi_anly_fig = figure('Resize','off','Color',defaultBackground,'Units','pixels','Position',[50+round(SW2/5)+relative_horz_displacement 50 round(SW2/10) round(SH*0.9)],'Visible','off','MenuBar','none','name','ROI Analysis','NumberTitle','off','UserData',0);
    im_fig=figure;set(im_fig,'Visible','off');
    backup_fig=figure;set(backup_fig,'Visible','off');
    % initialisation ends
    
    %opening previous file location -starts
        f1=fopen('address2.mat');
        if(f1<=0)
        pseudo_address='';%pwd;
         else
            pseudo_address = importdata('address2.mat');
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
    save_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.70 0.4 0.045],'String','Save ROI','Callback',@save_roi);
    rename_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.65 0.4 0.045],'String','Rename ROI','Callback',@rename_roi);
    delete_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.60 0.4 0.045],'String','Delete ROI','Callback',@delete_roi);
    measure_roi_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.55 0.4 0.045],'String','Measure ROI','Callback',@measure_roi);
    analyzer_box=uicontrol('Parent',roi_mang_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.50 0.4 0.045],'String','ctFIRE ROI Analyzer','Callback',@analyzer_launch_fn,'Enable','off');
    index_box=uicontrol('Parent',roi_mang_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.19 0.1 0.045],'Callback',@index_fn);
    index_text=uicontrol('Parent',roi_mang_fig,'Style','Text','Units','normalized','Position',[0.6 0.18 0.3 0.045],'String','Show Indices');
    status_message=uicontrol('Parent',roi_mang_fig,'Style','text','Units','normalized','Position',[0.55 0.05 0.4 0.09],'String','Message','BackgroundColor',[1 1 1]);
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
         
        [filename pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select image',pseudo_address,'MultiSelect','off'); 
         try
            save('address2.mat','pseudo_address');
            display(filename);display(pathname);
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
                matdata=importdata(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']));
            end
            if(exist([pathname,'ROI\ROI_management\',[filename '_ROIs.mat']],'file')~=0)%if file is present . value ==2 if present
                separate_rois=importdata([pathname,'ROI\ROI_management\',[filename '_ROIs.mat']]);
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
        catch
           set(status_message,'String','error in loading Image.'); 
        end
      
    end

    function[]=new_roi(object,handles)
        % Shape of ROIs- 'Rectangle','Freehand','Ellipse','Polygon'
        %         steps-
        %         1 clear im_fig and show the image again
        %         2 ask for the shape of the roi
        %         3 convert the roi into mask and boundary
        %         4 show the image in a figure where mask ==1 and also show the boundary on the im_fig

       % clf(im_fig);figure(im_fig);imshow(image);
       figure(im_fig);hold on;
        roi_shape_popup_window;
        
            function[]=roi_shape_popup_window()
                width=200; height=200;
                rect_fixed_size=0;% 1 if size is fixed and 0 if not
                position=[50 50 200 200];
                left=position(1);bottom=position(2);width=position(3);height=position(4);
                defaultBackground = get(0,'defaultUicontrolBackgroundColor'); 
                popup=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 200],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);
                roi_shape_text=uicontrol('Parent',popup,'Style','text','string','select ROI type','Units','normalized','Position',[0.05 0.9 0.9 0.10]);
                roi_shape_menu=uicontrol('Parent',popup,'Style','popupmenu','string',{'Rectangle','Freehand','Ellipse','Polygon'},'Units','normalized','Position',[0.05 0.75 0.9 0.10],'Callback',@roi_shape_menu_fn);
                rect_roi_checkbox=uicontrol('Parent',popup,'Style','checkbox','Units','normalized','Position',[0.05 0.6 0.1 0.10],'Callback',@rect_roi_checkbox_fn);
                rect_roi_text=uicontrol('Parent',popup,'Style','text','string','Fixed Size Rect ROI','Units','normalized','Position',[0.15 0.6 0.6 0.10]);
                rect_roi_height=uicontrol('Parent',popup,'Style','edit','Units','normalized','String',num2str(height),'Position',[0.05 0.45 0.2 0.10],'enable','off','Callback',@rect_roi_height_fn);
                rect_roi_height_text=uicontrol('Parent',popup,'Style','text','string','Height','Units','normalized','Position',[0.28 0.45 0.2 0.10],'enable','off');
                rect_roi_width=uicontrol('Parent',popup,'Style','edit','Units','normalized','String',num2str(width),'Position',[0.52 0.45 0.2 0.10],'enable','off','Callback',@rect_roi_width_fn);
                rect_roi_width_text=uicontrol('Parent',popup,'Style','text','string','Width','Units','normalized','Position',[0.73 0.45 0.2 0.10],'enable','off');
                rf_numbers_ok=uicontrol('Parent',popup,'Style','pushbutton','string','Ok','Units','normalized','Position',[0.05 0.10 0.45 0.10],'Callback',@ok_fn);

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
                          roi_shape=get(roi_shape_menu,'value');
                           display(roi_shape);
                           count=1;%finding the ROI number
                           fieldname=['ROI' num2str(count)];
                           while(isfield(separate_rois,fieldname)==1)
                               count=count+1;fieldname=['ROI' num2str(count)];
                           end
                           display(fieldname);
                           close; %closes the pop up window
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
                                        display('drawn');
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
                           roi=getPosition(h);display(roi);
                           display('out of loop');
                    end
                    
                    function[]=wait_fn()
                                while(finalize_rois==0)
                                   pause(0.25); 
                                end
                    end
            end
    end

    function[]=finalize_roi_fn(object,handles)
       finalize_rois=1;
       roi=getPosition(h);%  this is to account for the change in position of the roi by dragging
       %display(roi);
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
            display(roi);
        elseif(roi_shape==1)% ie rectangular ROI
            separate_rois.(fieldname).roi=roi;
            display(roi);
        elseif(roi_shape==3)
             separate_rois.(fieldname).roi=roi;
             display(roi);
        elseif(roi_shape==4)
            separate_rois.(fieldname).roi=roi;
            display(roi);
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
        display(separate_rois);
        names=fieldnames(separate_rois);display(names);s3=size(names,1);
        for i=1:s3
           display(separate_rois.(names{i,1})); 
        end
        save(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']),'separate_rois','-append');
        %display(separate_rois);
        
        display('saving done');
        update_rois;
    end

    function[]=update_rois
        %it updates the roi in the ui table
        separate_rois=importdata(fullfile(pathname,'ROI\ROI_management\',[filename,'_ROIs.mat']));
        display(separate_rois);
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
        xmid=[];ymid=[];
       s1=size(image,1);s2=size(image,2);
       for i=1:s1
           for j=1:s2
                mask(i,j)=logical(0);
                BW(i,j)=logical(0);
                roi_boundary(i,j)=uint8(0);
                overlaid_image(i,j,1:3)=uint8(0);
           end
       end
       Data=get(roi_table,'Data');
       s3=size(handles.Indices,1);display(s3);%pause(5);
       cell_selection_data=handles.Indices;
       display(cell_selection_data);
       for k=1:s3
           data2=[];vertices=[];
          display(Data{handles.Indices(k,1),1});
          display(separate_rois.(Data{handles.Indices(k,1),1}).roi);
          if(separate_rois.(Data{handles.Indices(k,1),1}).shape==1)
            display('rectangle');
            % vertices is not actual vertices but data as [ a b c d] and
            % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
            data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
            BW=roipoly(image,vertices(:,1),vertices(:,2));
            %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==2)
              display('freehand');
              vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
              BW=roipoly(image,vertices(:,1),vertices(:,2));
              %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==3)
              display('ellipse');
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
                        %display(dist);pause(1);
                        if(dist<=1.00)
                            BW(m,n)=logical(1);
                        else
                            BW(m,n)=logical(0);
                        end
                  end
              end
              %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{handles.Indices(k,1),1}).shape==4)
              display('polygon');
              vertices=separate_rois.(Data{handles.Indices(k,1),1}).roi;
              BW=roipoly(image,vertices(:,1),vertices(:,2));
              %figure;imshow(255*uint8(BW));
          end
          s1=size(image,1);s2=size(image,2);
          for i=2:s1-1
                for j=2:s2-1
                    North=BW(i-1,j);NorthWest=BW(i-1,j-1);NorthEast=BW(i-1,j+1);
                    West=BW(i,j-1);East=BW(i,j+1);
                    SouthWest=BW(i+1,j-1);South=BW(i+1,j);SouthEast=BW(i+1,j+1);
                    if(BW(i,j)==logical(1)&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
                        roi_boundary(i,j)=uint8(255);
%                         roi_boundary(i,j,2)=uint8(255);
%                         roi_boundary(i,j,3)=uint8(255);
                    end
                end
          end
             [xmid(k),ymid(k)]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
%            [xmid,ymid]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
%            figure(im_fig);text(ymid,xmid,Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
%           %display(separate_rois.(Data{handles.Indices(i,1),1}).roi);
       end
       clf(im_fig);figure(im_fig);imshow(image+roi_boundary,'Border','tight');hold on;
        if(get(index_box,'Value')==1)
           for k=1:s3
             text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
           end
        end
        
       backup_fig=copyobj(im_fig,0);set(backup_fig,'Visible','off');
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

    function[]=rename_roi(object,handles)
        display(cell_selection_data);
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
        display(cell_selection_data);
        display(size(cell_selection_data,1));
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
       s3=size(cell_selection_data,1);display(s3);
       display(cell_selection_data);
       roi_number=size(cell_selection_data,1);
        measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 300 300],'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
        measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
        names=fieldnames(separate_rois);
        measure_data{1,1}='names';measure_data{1,2}='min';measure_data{1,3}='max';measure_data{1,4}='Area';measure_data{1,5}='mean';
        measure_index=2;
       for k=1:s3
           data2=[];vertices=[];
          display(Data{cell_selection_data(k,1),1});
          %display(separate_rois.(Data{handles.Indices(k,1),1}).roi);
          if(separate_rois.(Data{cell_selection_data(k,1),1}).shape==1)
            display('rectangle');
            % vertices is not actual vertices but data as [ a b c d] and
            % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
            data2=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
            a=data2(1);b=data2(2);c=data2(3);d=data2(4);
            vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
            BW=roipoly(image,vertices(:,1),vertices(:,2));
            %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==2)
              display('freehand');
              vertices=separate_rois.(Data{cell_selection_data(k,1),1}).roi;
              BW=roipoly(image,vertices(:,1),vertices(:,2));
              %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==3)
              display('ellipse');
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
                        %display(dist);pause(1);
                        if(dist<=1.00)
                            BW(m,n)=logical(1);
                        else
                            BW(m,n)=logical(0);
                        end
                  end
              end
              %figure;imshow(255*uint8(BW));
          elseif(separate_rois.(Data{cell_selection_data(k,1),1}).shape==4)
              display('polygon');
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
        set(roi_anly_fig,'Visible','on'); 
        filename_box2=uicontrol('Parent',roi_anly_fig,'Style','text','String',[filename '.' format],'Units','normalized','Position',[0.05 0.95 0.9 0.045],'BackgroundColor',[1 1 1]);
        check_box2=uicontrol('Parent',roi_anly_fig,'Style','pushbutton','String','Check Fibres','Units','normalized','Position',[0.05 0.9 0.9 0.045],'Callback',@check_fibres_fn);
        more_settings_box2=uicontrol('Parent',roi_anly_fig,'Style','pushbutton','String','More Settings','Units','normalized','Position',[0.05 0.85 0.9 0.045],'Callback',@more_settings_fn);
        generate_stats_box2=uicontrol('Parent',roi_anly_fig,'Style','pushbutton','String','Generate Stats','Units','normalized','Position',[0.05 0.80 0.9 0.045],'Callback',@generate_stats_fn);
        automatic_roi_box2=uicontrol('Parent',roi_anly_fig,'Style','pushbutton','String','Automatic ROI detection','Units','normalized','Position',[0.05 0.75 0.9 0.045],'Callback',@automatic_roi_fn);
        visualisation_box2=uicontrol('Parent',roi_anly_fig,'Style','pushbutton','String','Visualisation of fibres','Units','normalized','Position',[0.05 0.70 0.9 0.045],'Callback',@visualisation);
        
        %variables for this function - used in sub functions
        mask=[];
        fiber_source='ctFIRE';%other value can be only postPRO
        fiber_method='mid';%other value can be whole
        fiber_data=[];
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
           names=fieldnames(separate_rois);display(names);
           for i=1:s1
               for j=1:s2
                   mask(i,j)=logical(0);BW(i,j)=logical(0);
               end
           end
           for k=1:s3
%                type=separate_rois.(names(cell_selection_data(k))).shape;
%                display(type);
                type=separate_rois.(names{cell_selection_data(k),1}).shape;
                vertices=[];data2=[];
                if(type==1)%Rectangle
                    data2=separate_rois.(names{cell_selection_data(k),1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(image,vertices(:,1),vertices(:,2));
                elseif(type==2)%freehand
                    display('freehand');
                    vertices=separate_rois.(names{cell_selection_data(k),1}).roi;
                    BW=roipoly(image,vertices(:,1),vertices(:,2));
                elseif(type==3)%Ellipse
                      display('ellipse');
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
                                %display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                elseif(type==4)%Polygon
                    display('polygon');
                    vertices=separate_rois.(names{cell_selection_data(k),1}).roi;
                    BW=roipoly(image,vertices(:,1),vertices(:,2));
                end
                mask=mask|BW;
%                 display(separate_rois.(names{cell_selection_data(k),1}).shape);
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
                display(fiber_data);
           elseif(stcmp(fiber_source=='postPRO')==1)
               % take data from the postProcessing GUI data
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
                             fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
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
                             fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
                        else
                            fiber_data(i,2)=0;
                        end
                    end
                end
           end
           plot_fibers(fiber_data,im_fig,0,1);
        end
        
        function[]=more_settings_fn(object,handles)
            settings_fig = figure('Resize','off','Units','pixels','Position',[50 50 200 100],'Visible','on','MenuBar','none','name','Settings','NumberTitle','off','UserData',0,'Color',defaultBackground);
            fiber_data_source_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0 0.5 0.45 0.45],'String','Source of fibers');
            fiber_data_source_box=uicontrol('Parent',settings_fig,'Enable','on','Style','popupmenu','Tag','Fiber Data location','Units','normalized','Position',[0 0.1 0.45 0.45],'String',{'CTFIRE Fiber data','Post Processing Fiber data'},'Callback',@fiber_data_location_fn,'FontUnits','normalized');
            roi_method_define_message=uicontrol('Parent',settings_fig,'Enable','on','Style','text','Units','normalized','Position',[0.5 0.5 0.45 0.45],'String','Fiber selection method ');
            roi_method_define_box=uicontrol('Parent',settings_fig,'Enable','on','Style','popupmenu','Units','normalized','Position',[0.5 0.1 0.45 0.45],'String',{'Midpoint','Entire Fibre'},'Callback',@roi_method_define_fn,'FontUnits','normalized');
            display(fiber_source);display(fiber_method);
            
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
                display(fiber_method);
            end

            function[]=fiber_data_location_fn(object,handles)
                 if(get(object,'Value')==1)
                    fiber_source='ctFIRE';
                elseif(get(object,'Value')==2)
                    fiber_source='postPRO';
                 end
                 display(fiber_source);
            end
        end
    
        function[]=automatic_roi_fn(object,handles)
%             steps
%             1 open a new figure called automatic
%             2 define the window size
%             3 define the number of steps/shifts in each direction
%             4 based on midpoint calculate the average parameter - length first of all
%             5 display the minimum and maximum roi
%             6 save these ROIs by name Auto_ROI_length_max and min
            auto_fig=figure;
            window_size=100;% search window's size
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
            parameter_input='length';% other values='width','angle' and 'straightness'
            max=0;min=Inf;x_max=1;y_max=1;x_min=1;y_min=1;
            tic;
            s1=size(image,1);s2=size(image,2);
            for m=1:1:s1-window_size+1
                for n=1:1:s2-window_size+1
                    parameter=0;
%                     temp_image=image;fprintf('m=%d n=%d\n',m,n);
                           for k=1:size_fibers
                              if(fiber_data2(k,2)==1&&xmid_array(k)>=m&&xmid_array(k)<=m+window_size&&ymid_array(k)>=n&&ymid_array(k)<=n+window_size)
                                if(strcmp(parameter_input,'length')==1)
                                    parameter=parameter+fiber_data2(k,4);
                                end
                              end
                           end
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
           
           if(parameter>max)
               x_max=m;y_max=n;max=parameter;
               fprintf('\nx_max=%d y_max=%d parameter=%d',x_max,y_max,parameter);
           end
           if(parameter<min)
               x_min=m;y_min=n;
           end
             for k=1:size_fibers
              if(fiber_data2(k,2)==1)
                if(strcmp(parameter_input,'length')==1)
                    if(xmid_array(k)>=x_max&&xmid_array(k)<=x_max+window_size&&ymid_array(k)>=y_max&&ymid_array(k)<=y_max+window_size)
                        fiber_data2(k,2)=1; 
                    else
                        fiber_data2(k,2)=0;
                    end
                end
              end
            end
           
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
        rng(1001) ;
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
    end

    function[]=index_fn(object,handles)
        if(get(index_box,'Value')==1)
            Data=get(roi_table,'Data');
            s3=size(xmid,2);display(s3);
           for k=1:s3
             figure(im_fig);text(ymid(k),xmid(k),Data{cell_selection_data(k,1),1},'HorizontalAlignment','center','color',[1 1 1]);hold on;
           end
        end
    end

    
end


