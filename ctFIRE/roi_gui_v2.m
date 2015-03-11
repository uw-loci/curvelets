% 6th Jan - overlaying the boundary of ROIs
%kip=b.(fields{1})
% Line 385 display(floor(position(j,1)));display(floor(position(j,2)));
function[]=roi_gui_v2()
    
%     Developer - Guneet Singh Mehta
%     Indian Institute of Technology, Jodhpur
%     Former Research Intern at LOCI,UW Madison
%     email- mehta_guneet@iitj.ac.in
%     Duration - December 1 - December 30 th 2014

    % image - global variable storing image
    global image;
     im_fig=figure('name','Image');
    global roi_table;
    global pseudo_address;
    global fiber_data_backup;
    global format;
    global roi_boundary;
    global use_selected_fibers;
    global fiber_data; 
    global matdata;
    global filename;
    global cell_selection_data;
    global mask;% create a mask of the same size as the image and then try to find the fibers in roi_window
    global roi_method;% 1 for selecting fiber if midpoint is within ROI, 
                      % 2 for selecting fiber if the entire fiber is
                      % within the ROI
    
    
    pseudo_address=[];
    roi_method=1;% using default value
    image=[];
    use_selected_fibers=2; % 2 to use post processing results and 1 to use results of CTFIREout
    % fiber_data_location allows user to select 1 for ctfire data and 2 for
    % post processing fiber data. fiber_data_location_fn changes the value
    % of use_selected_fibers in GUI
    
    finalize_roi=0; %finalize roi depicts whether the roi is ready to be saved/executed
    % finalize_roi=1 if we need to save or process the mask and 0 if we are
    % defining more rois in the image
    
    fiber_data=[];
    pathname=[];
    point1=[1,1];point2=[50,50]; % defaults for rectangular ROI
    roi_shape=1;% value=1 if rectangular and value=2 if freeehand
    % can also add ellipse and similar shapes
    
    roi=[]; %contains all the ROIs. One issue - to filter out smaller ROIs of 2 points 
    % 2 point ROIs are being formed as well.
    roi_message=[];% contains the user defined string for each saved ROI
    
    operation_number=[];% indicates the operation number selected by user out of the ROIs already present in the current file
    SSize = get(0,'screensize');
    SW2 = SSize(3); SH = SSize(4);
    roi_fig = figure('Resize','off','Units','pixels','Position',[50 50 round(SW2/5) round(SH*0.9)],'Visible','on','MenuBar','none','name','ROI Manager','NumberTitle','off','UserData',0);
    
    defaultBackground = get(0,'defaultUicontrolBackgroundColor'); drawnow;
    set(roi_fig,'Color',defaultBackground);
    roi_table=uitable('Parent',roi_fig,'Units','normalized','Position',[0.05 0.05 0.45 0.9],'CellSelectionCallback',@cell_selection_fn);
    
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
    
    reset_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.75 0.96 0.2 0.03],'String','Reset','Callback',@reset_fn);
    open_file_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.9 0.4 0.045],'String','Open File','Callback',@load_image);
    filename_box=uicontrol('Parent',roi_fig,'Style','text','Units','normalized','Position',[0.55 0.85 0.4 0.045],'String','','BackgroundColor',[1 1 1]);
    open_file_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.8 0.4 0.045],'String','Check','Callback',@check_for_fibers_in_roi);
    update_roi_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.75 0.4 0.045],'String','Rename ROI','Callback',@rename_roi);
    draw_roi_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.70 0.4 0.045],'String','Draw ROI','Callback',@new_roi);
    finalize_roi_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.65 0.4 0.045],'String','Finalize ROI','Callback',@finalize_roi_fn);
    save_roi_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.6 0.4 0.045],'String','Save ROI','Callback',@save_roi);
    delete_roi_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.55 0.4 0.045],'String','Delete ROI','Callback',@delete_roi_fn);
    measure_box=uicontrol('Parent',roi_fig,'Style','Pushbutton','Units','normalized','Position',[0.55 0.5 0.4 0.045],'String','Measure','Callback',@measure_fn);
    
    showall_box=uicontrol('Parent',roi_fig,'Style','Checkbox','Units','normalized','Position',[0.55 0.14 0.1 0.045],'Callback',@showall_fn);
    showall_text=uicontrol('Parent',roi_fig,'Style','Text','Units','normalized','Position',[0.6 0.13 0.3 0.045],'String','Show all');
    status_message=uicontrol('Parent',roi_fig,'Style','text','Units','normalized','Position',[0.55 0.05 0.4 0.09],'String','','BackgroundColor',[1 1 1]);
    %checked functions -starts
    function[]=reset_fn(object,handles)
        close all;
        roi_gui_v2();
    end 
    
    function[]=load_image(object,handles)
         % image is loaded and data_fiber defined here 
        [filename pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select image',pseudo_address,'MultiSelect','off'); 

        display(filename);
        display(pathname);
        pseudo_address=pathname;
         save('address2.mat','pseudo_address');
        image=imread([pathname  filename]);
       s1=size(image,1);s2=size(image,2);
       display(point1);display(point2);
       for i=1:s1
           for j=1:s2
               mask(i,j)=logical(0);
               temp_image(i,j)=uint8(0);
               roi_boundary(i,j,1:3)=uint8(0);
           end
       end
        figure(im_fig);imshow(image);hold on;
        
        display(use_selected_fibers);
       set(filename_box,'String',filename);
        % Now rest of the function reads the fiber data
        dot_position=findstr('.',filename);
        dot_position=dot_position(end);
        format=filename(dot_position+1:end);
        filename=filename(1:dot_position-1);
        
        if(use_selected_fibers==1)
           matdata=importdata([pathname 'ctFIREout\ctFIREout_' filename '.mat']);
           
            % creating the field ROI_analysis in matdata.data if the field
            % is not present
            if(isfield(matdata.data,'ROI_analysis')==0)
               matdata.data.ROI_analysis=[];  % this does not add the field to the orignal file. We need to write it again. Done in save_roi function.   
            end
           fiber_data=matdata.data.PostProGUI.fiber_indices;
           
        elseif(use_selected_fibers==2)
%              if(isfield(matdata.data,'ROI_analysis')==0)
%                matdata.data.ROI_analysis=[];  % this does not add the field to the orignal file. We need to write it again. Done in save_roi function.   
%             end           
            address=pathname;
            matdata=importdata(fullfile(address,'ctFIREout',['ctFIREout_',filename,'.mat']));
            
            % creating the field ROI_analysis in matdata.data if the field
            % is not present
            if(isfield(matdata.data,'ROI_analysis')==0)
               matdata.data.ROI_analysis=[];     
            end
            
            s1=size(matdata.data.Fa,2);
            
            % assigns 1 to all fibers initially -INITIALIZATION
            fiber_data=[];
            for i=1:s1
                fiber_data(i,1)=i; fiber_data(i,2)=1; fiber_data(i,3)=0;
            end
            
            % s2 is the length threshold used in the ctFIRE
            ctFIRE_length_threshold=matdata.cP.LL1;
            %if length of the fiber is less than the threshold s2 then
            %assign 0 to that fiber
            
            
            %Now fiber indices will have the following columns=
            % column1 - fiber number column2=visible(if ==1)
            %column 3-length  column4- width column5- angle
            %column6 - straight
            
            xls_widthfilename=fullfile(address,'ctFIREout',['HistWID_ctFIRE_',filename,'.csv']);
            xls_lengthfilename=fullfile(address,'ctFIREout',['HistLEN_ctFIRE_',filename,'.csv']);
            xls_anglefilename=fullfile(address,'ctFIREout',['HistANG_ctFIRE_',filename,'.csv']);
            xls_straightfilename=fullfile(address,'ctFIREout',['HistSTR_ctFIRE_',filename,'.csv']);
            fiber_width=csvread(xls_widthfilename);
            fiber_length=csvread(xls_lengthfilename); % no need of fiber_length - as data is entered using fiber_length_fn
            fiber_angle=csvread(xls_anglefilename);
            fiber_straight=csvread(xls_straightfilename);
            
            
            kip_length=sort(fiber_length);      kip_angle=sort(fiber_angle);        kip_width=sort(fiber_width);        kip_straight=sort(fiber_straight);
            kip_length_start=kip_length(1);   kip_angle_start=kip_angle(1,1);     kip_width_start=kip_width(1,1);     kip_straight_start=kip_straight(1,1);
            kip_length_end=kip_length(end);   kip_angle_end=kip_angle(end,1);     kip_width_end=kip_width(end,1);     kip_straight_end=kip_straight(end,1);
            count=1;
            
            for i=1:s1
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
             
            
        end
        size_saved_operations=size(fieldnames(matdata.data.ROI_analysis),1);
        names=fieldnames(matdata.data.ROI_analysis);
        for i=1:size_saved_operations
            Data{i,1}=names{i,1};
        end
        set(roi_table,'Data',Data);
        fiber_data_backup=fiber_data;
     

    end

    function[]=check_for_fibers_in_roi(object,handles)
        fiber_data=fiber_data_backup;
        s1=size(fiber_data,1);
        display(s1);
       
        figure(im_fig);hold on;
        % this loop checks whether the mid point of the fiber lies within
        % the ROI or not 
        if(roi_method==1)
            for i=1:s1
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
                        plot(x,y,'--rs','LineWidth',2,...
                          'MarkerEdgeColor','k',...
                          'MarkerFaceColor','g',...
                          'MarkerSize',10); 
                          hold on;
                          % next step is a debug check
                         fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
                    else
                        fiber_data(i,2)=0;
                    end
               end
            end
        else
           if(roi_method==2)
                for i=1:s1 % s1 is number of fibers in image selected out of Post pro GUI
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
                            plot(xmid,ymid,'--rs','LineWidth',2,...
                              'MarkerEdgeColor','k',...
                              'MarkerFaceColor','g',...
                              'MarkerSize',10); 
                              hold on;
                              % next step is a debug check- for output on
                              % screen
                             fprintf('%d %d %d %d \n',x,y,size(mask,1),size(mask,2));
                        end
                    end
                end
           end
        end
        
        
        %display(size(image));
        %display(fiber_data);
        plot_fibers(fiber_data,'testing',0,1);
    end

    function[]=showall_fn(handles,object)
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
       if(get(showall_box,'value')==1)
          data_size=size(Data,1);
          for i=1:data_size
             handles.Indices(i,1)=i; 
             handles.Indices(i,2)=1; 
          end
       end 
       s1=size(handles.Indices,1);
       cell_selection_data=handles.Indices;
       for i=1:s1
          display(Data{handles.Indices(i,1),1}); 
       end
       % task 1 ends
       
       %task 2 and 3 starts
       s1=size(handles.Indices,1);
       for k=1:s1
          % let us call entire data of one operation to be operation_data 
          operation_data=matdata.data.ROI_analysis.(Data{handles.Indices(k,1),1});
          if(operation_data.shape==1)% for rect
              display('rect');
              rect_coordinates=operation_data.roi{1,1}{1,1}{1,1};
              x1=floor(rect_coordinates(1));% floor becuase the point positions may be in decimals
                   y1=floor(rect_coordinates(2));
                   x2=floor(rect_coordinates(3));
                   y2=floor(rect_coordinates(4));
                   
                   if(x2>x1&&y2>y1)
                       for m=x1:x2
                           for n=y1:y2
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x1>x2&&y1>y2)
                       for m=x2:x1
                           for n=y2:y1
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x1>x2&&y2>y1)
                       
                       for m=x2:x1
                           for n=y1:y2
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x2>x1&&y1>y2)
                       
                       for m=x1:x2
                           for n=y2:y1
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   mask=mask|BW;
                kip2(:,:,1)=uint8(roi_boundary(:,:,1));kip2(:,:,2)=0;kip2(:,:,3)=0;
                %display(size(image));display(size(kip2));display(size(overlaid_image));
                %pause(10);
%                overlaid_image(:,:,1)=image(:,:)+kip2(:,:,1);
          elseif(operation_data.shape==2)% for freehand
              display('freehand');
              s3=size(operation_data.roi,2);
                for i=1:s3

                        position=operation_data.roi{1,i}{1,1}{1,1};
                        %s4 = size of roi boundary points
                        %display(size(position));
                        s4=size(position,1);
                        %display(s4);
                        for j=1:s4
                            roi_boundary(floor(position(j,2)),floor(position(j,1)))=uint8(255);
                            if(j<5)
%                                 %display(floor(position(j,1)));display(floor(position(j,2)));
                            end
                        end
% 
                        BW=roipoly(image,position(:,1),position(:,2));
%                         s1=size(image,1);s2=size(image,2);
%                         
%                        
%                         for m=2:s1-1
%                             for n=2:s2-1
%                                  NW=BW(m-1,n-1);N=BW(m-1,n);NE=BW(m-1,n+1);
%                                  W=BW(m,n-1);E=BW(m,n+1);
%                                  SW=BW(m+1,n-1);S=BW(m+1,n);SE=BW(m+1,n+1);
%                                  if(BW(m,n)==1&&(NW==0||N==0||NE==0||W==0||E==0||SW==0||S==0||SE==0))
%                                     roi_boundary(m,n,1:3)=uint8(255); 
%                                  else
%                                      roi_boundary(m,n,1:3)=uint8(0); 
%                                  end
%                             end
%                         end
                         mask=mask|BW;
                        
                end
%                 %figure;imshow(roi_boundary);
%                 kip2(:,:,1)=roi_boundary(:,:,1);kip2(:,:,2)=0;kip2(:,:,3)=0;
%                 display(size(image));display(size(kip2));display(size(overlaid_image));
%                 %pause(10);
%                 overlaid_image(:,:,1)=uint8(kip2(:,:,1))+uint8(image(:,:));

          end
       end
       %task 2 and 3 ends
       
%        figure;imshow(uint8(mask)*255);
%         figure;imshow(roi_boundary);
%        
        figure(im_fig);imshow(uint8(image)+uint8(roi_boundary(:,:,1)));hold on;
        %figure;imshow(mask);
       
    end

    function[]=cell_selection_fn(object,handles)
        % o Initilization
%         1 needs to identify the operations and their numbers and strings
%         2 needs to define mask
%         3 needs to plot the roi_boundary on img_fig
%         4 add wait and resume messages

       %initialization starts
       s1=size(image,1);s2=size(image,2);
       for i=1:s1
           for j=1:s2
                mask(i,j)=logical(0);
                BW(i,j)=logical(0);
                roi_boundary(i,j)=uint8(0);
                overlaid_image(i,j,1:3)=uint8(0);
           end
       end
       %initilization ends
       
       % task 1 starts
       Data=get(roi_table,'Data');
       if(get(showall_box,'value')==1)
          data_size=size(Data,1);
          for i=1:data_size
             handles.Indices(i,1)=i; 
             handles.Indices(i,2)=1; 
          end
       end
       s1=size(handles.Indices,1);
       cell_selection_data=handles.Indices;
       for i=1:s1
          display(Data{handles.Indices(i,1),1}); 
       end
       % task 1 ends
       
       %task 2 and 3 starts
       s1=size(handles.Indices,1);
       for k=1:s1
          % let us call entire data of one operation to be operation_data 
          operation_data=matdata.data.ROI_analysis.(Data{handles.Indices(k,1),1});
          if(operation_data.shape==1)% for rect
              display('rect');
              rect_coordinates=operation_data.roi{1,1}{1,1}{1,1};
              x1=floor(rect_coordinates(1));% floor becuase the point positions may be in decimals
                   y1=floor(rect_coordinates(2));
                   x2=floor(rect_coordinates(3));
                   y2=floor(rect_coordinates(4));
                   
                   if(x2>x1&&y2>y1)
                       for m=x1:x2
                           for n=y1:y2
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x1>x2&&y1>y2)
                       for m=x2:x1
                           for n=y2:y1
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x1>x2&&y2>y1)
                       
                       for m=x2:x1
                           for n=y1:y2
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x2>x1&&y1>y2)
                       
                       for m=x1:x2
                           for n=y2:y1
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   mask=mask|BW;
                kip2(:,:,1)=uint8(roi_boundary(:,:,1));kip2(:,:,2)=0;kip2(:,:,3)=0;
                %display(size(image));display(size(kip2));display(size(overlaid_image));
                %pause(10);
%                overlaid_image(:,:,1)=image(:,:)+kip2(:,:,1);
          elseif(operation_data.shape==2)% for freehand
              display('freehand');
              s3=size(operation_data.roi,2);
                for i=1:s3

                        position=operation_data.roi{1,i}{1,1}{1,1};
                        %s4 = size of roi boundary points
                        %display(size(position));
                        s4=size(position,1);
                        %display(s4);
                        for j=1:s4
                            roi_boundary(floor(position(j,2)),floor(position(j,1)))=uint8(255);
                            if(j<5)
                               %display(floor(position(j,1)));display(floor(position(j,2)));
                            end
                        end
                        BW=roipoly(image,position(:,1),position(:,2));                     
                         mask=mask|BW;
                end               
          end
       end
       %task 2 and 3 ends

        figure(im_fig);imshow(uint8(image)+uint8(roi_boundary(:,:,1)));hold on;
        %figure;imshow(mask);
    end

    function []=plot_fibers(fiber_data,string,pause_duration,print_fiber_numbers)
        % a is the .mat file data
        % orignal image is the gray scale image, gray123 is the orignal image in
        % rgb
        % fiber_indices(:,1)= fibers to be plotted
        % fiber_indices(:,2)=0 if fibers are not to be shown and 1 if fibers
        % are to be shown
        
        % fiber_data is the fiber_indices' working copy which may or may not
        % be the global fiber_indices
        
        a=matdata; 
%         orignal_image=imread(fullfile(pathname,[filename,'.',format]));
% %         gray123=orignal_image;   % YL: replace "gray" with "gray123", as gray is a reserved name for Matlab  
%          gray123=orignal_image;
% %         gray123(:,:,1)=orignal_image(:,:);
% %         gray123(:,:,2)=orignal_image(:,:);
% %         gray123(:,:,3)=orignal_image(:,:);
%         %figure;imshow(gray123);
%         
%         string=horzcat(string,' size=', num2str(size(gray123,1)),' x ',num2str(size(gray123,2)));
%         gcf= figure('name',string,'NumberTitle','off');
%         imshow(uint8(gray123)+uint8(roi_boundary(:,:,1)));hold on;       
%         string=horzcat('image size=',num2str(size(gray123,1)),'x',num2str(size(gray123,2)));% not used
%         %text(1,1,string,'HorizontalAlignment','center','color',[1 0 0]);
%         
        %%YL: fix the color of each fiber
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
                plot(x_cord,y_cord,'LineStyle','-','color',color1,'linewidth',0.005);hold on;
                % pause(4);
                final_threshold=0;
                if(print_fiber_numbers==1&&final_threshold~=1)
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
        hold off % YL: allow the next high-level plotting command to start over
        %YL: save the figure  with a speciifed resolution afer final thresholding
        % GSM - final_threshold!= 1 therefore for the time being making it
        % 1
        final_threshold=0;
        if(final_threshold==1)
            RES = 300;  % default resolution, in dpi
            set(gca, 'visible', 'off');
            set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(gray123,1)/RES size(gray123,2)/RES]);
            set(gcf,'Units','normal');
            set (gca,'Position',[0 0 1 1]);
            OL_sfName = fullfile(pathname,'selectout',[filename,'_overlaid_selected_fibers','.tif']);
            
            %GSM - commenting the statement below
            %print(gcf,'-dtiff', ['-r',num2str(RES)], OL_sfName);  % overylay selected extracted fibers on the original image
            %              saveas(gcf,horzcat(address,'\selectout\',getappdata(guiCtrl,'filename'),'_overlaid_selected_fibers','.tif'),'tif');
        end
    end

    function[]=new_roi(object,handles)
       
        roi=[];
        roi_message=[];
        mask=[];
        BW=[];
        roi_shape=2; % 1 for rectangle , 2 for freehand ROIs
       
        %roi_shape is defined in a roi_shape_popup_window function defined
        %at the end of this function
        roi_shape_popup_window;% calls a popup window to set value of roi_shape
      
            function[]=roi_shape_popup_window()
        
                %roi_shape=2; % 1 for rectangle , 2 for freehand ROIs
                % once the ROI is defined as rectangle then only rectangle rois
                % would be allowed. 
                width=200; height=200;
                rect_fixed_size=0;% 1 if size is fixed and 0 if not
                position=[50 50 200 200];
                left=position(1);bottom=position(2);width=position(3);height=position(4);
                defaultBackground = get(0,'defaultUicontrolBackgroundColor'); 
                popup=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 200],'Menubar','none','NumberTitle','off','Name','Select ROI shape','Visible','on','Color',defaultBackground);
                roi_shape_text=uicontrol('Parent',popup,'Style','text','string','select ROI type','Units','normalized','Position',[0.05 0.9 0.9 0.10]);
                roi_shape_menu=uicontrol('Parent',popup,'Style','popupmenu','string',{'Rectangular','Freehand'},'Units','normalized','Position',[0.05 0.75 0.9 0.10],'Callback',@roi_shape_menu_fn);
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
                       else
                          set([rect_roi_height rect_roi_height_text rect_roi_width rect_roi_width_text ],'enable','off');
                       end
                    end

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

                    function[]=ok_fn(object,handles)
                          roi_shape=get(roi_shape_menu,'value');
                           display(roi_shape);
                           % defining operation_number in new_roi case -starts
                           count=1;
                               fieldname=['operation',num2str(count)];
                               while(isfield(matdata.data.ROI_analysis,fieldname)==1)
                                  count=count+1; 
                                  fieldname=['operation',num2str(count)];
                               end

                               display(count);
                               operation_number=count;
                         % defining operation_number in new_roi case - ends

                           % step 1 and 2 openning an image and defining the ROI as 'h' object 
                            finalize_roi=0;
                             close; % closes the pop up window
                            figure(im_fig);
                            s1=size(image,1);s2=size(image,2);
                            for i=1:s1
                                for j=1:s2
                                    mask(i,j)=logical(0);
                                end
                            end

                            %step 3 
                                    if(roi_shape==1)
                                            set(status_message,'String',['Rectangular ROI selected' char(10) 'Now Draw ROI']);
                                    elseif(roi_shape==2)
                                            set(status_message,'String',['Freehand ROI selected' char(10) 'Now Draw ROI']);
                                    end
                            count=0;
                            while(finalize_roi==0)

                                % save using the following command
                                % save(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data','-append');

                                    count=count+1;
                                    if(roi_shape==1)
                                        if(rect_fixed_size==0)% for resizeable Rectangular ROI
                                            h=imrect;
                                            %finalize_roi=1;
                    %                         set(status_message,'String',['Rectangular ROI selected' char(10) 'Draw ROI']);
                                        elseif(rect_fixed_size==1)% fornon resizeable Rect ROI 
                                            h = imrect(gca, [10 10 width height]);
                                            addNewPositionCallback(h,@(p) title(mat2str(p,3)));
                                            fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
                                            setPositionConstraintFcn(h,fcn);
                                            setResizable(h,0); 
                                            wait_fn();% waits till the user selects finalize_roi button
                                            %pause(5);
                                            finalize_roi=1;
                    %                         if(finalize_roi==0)
                    %                             uiwait(ROI_fig);
                    %                         else
                    %                            uiresume(ROI_fig); 
                    %                         end
                                        end
                                    elseif(roi_shape==2)
                                            h=imfreehand;
                                           % finalize_roi=1;
                    %                         set(status_message,'String',['Freehand ROI selected' char(10) 'Draw ROI']);
                                    end
                                    %roi_temp=getPosition(h);
                                    roi{count}={mat2cell(getPosition(h))};

                                    BW=createMask(h);
                                    mask=mask|BW;
                                    if(finalize_roi==1)
                                        break;
                                    end
                                    display(count);
                            end
                            set(status_message,'String','Press "Check for Fibres in ROI" to view fibres within ROI');
                            s1=size(mask,1);s2=size(mask,2);
                            for i=1:s1
                                for j=1:s2
                                    roi_boundary(i,j,1:3)=0;
                                end
                            end
                            for i=2:s1-1
                                for j=2:s2-1
                                        North=mask(i-1,j);NorthWest=mask(i-1,j-1);NorthEast=mask(i-1,j+1);
                                        West=mask(i,j-1);East=mask(i,j+1);
                                        SouthWest=mask(i+1,j-1);South=mask(i+1,j);SouthEast=mask(i+1,j+1);
                                        if(mask(i,j)==1&&(NorthWest==0||North==0||NorthEast==0||West==0||East==0||SouthWest==0||South==0||SouthEast==0))
                                            roi_boundary(i,j,1)=uint8(255);
                                            roi_boundary(i,j,2)=uint8(255);
                                            roi_boundary(i,j,3)=uint8(255);
                                        end
                                end
                            end

                            fprintf('number of ROIS = %d',count);
                            display(roi);
                            %step 4 - assuming finalized ROI- skipped for now

                            % step 5 Show ROI in image
                           s1=size(image,1);s2=size(image,2);
                            for i=1:s1
                               for j=1:s2
                                  if mask(i,j)
                                      temp_image(i,j)=uint8(image(i,j));
                                  else
                                      temp_image(i,j)=uint8(0);
                                  end
                               end
                           end

                           % the next two lines just show the images
                           figure;imshow(temp_image);
                          % figure;imshow(image);
                            end

                    function[]=wait_fn()
                                while(finalize_roi==0)
                                   pause(0.25); 
                                end
                    end

             end

    end

    function[]=finalize_roi_fn(object,handles)
       finalize_roi=1; 
       
       set(status_message,'String','Click on the image again to finalize ROI');
    end

    function[]=save_roi(object,handles)
            
        % searching for the biggest operation number- starts
        count=1;
          matdata=importdata([pathname 'ctFIREout\ctFIREout_' filename '.mat']);
           count_max=1;
           while(count<10000)
              fieldname=['operation',num2str(count)];
               if(isfield(matdata.data.ROI_analysis,fieldname)==1)
                  count_max=count;
              end
              
              count=count+1;
           end
           
           fieldname=['operation',num2str(count_max+1)];
           
        if(roi_shape==2)%ie  freehand
            matdata.data.ROI_analysis.(fieldname).roi=roi;
        elseif(roi_shape==1)% ie rectangular ROI
            flag=0;
            s1=size(image,1);s2=size(image,2);
            for i=1:s1
                for j=1:s2
                    if(mask(i,j)==logical(1))
                       x1=i;y1=j;%because x and y are interchanged in mask creation
                       x2=i;y2=j;%because x and y are interchanged in mask creation
                       min=x1+y1;
                       max=x2+y2;
                       flag=1;break;
                    end
                end
                if(flag==1)
                    break;
                end
            end

            for i=1:s1
                for j=1:s2
                    if(mask(i,j)==logical(1)&&(i+j>max))
                       x2=i;y2=j; %because x and y are interchanged in mask creation
                    end
                end
            end
            roi{1,1}{1,1}{1,1}=[x1 y1 x2 y2];
            matdata.data.ROI_analysis.(fieldname).roi=roi;
        end
        
        %saving date and time of operation-starts
        c=clock;
        fix(c);
        
        date=[num2str(c(2)) '-' num2str(c(3)) '-' num2str(c(1))] ;% saves 20 dec 2014 as 12-20-2014
        matdata.data.ROI_analysis.(fieldname).date=date;
        time=[num2str(c(4)) ':' num2str(c(5)) ':' num2str(uint8(c(6)))]; % saves 11:50:32 for 1150 hrs and 32 seconds
        matdata.data.ROI_analysis.(fieldname).time=time;
        %saving date and time of operation-ends
        
        % saving the user message for an ROI
        matdata.data.ROI_analysis.(fieldname).roi_message=roi_message;
        
        %saving shape of ROI
        matdata.data.ROI_analysis.(fieldname).shape=roi_shape;
        
        %saving fiber_data of ROI
        matdata.data.ROI_analysis.(fieldname).fiber_data=fiber_data;
        
        % saving the matdata into the concerned file- starts
            
%             using the following three statements
%             load(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data');
%             data.PostProGUI = matdata2.data.PostProGUI;
%             save(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data','-append');
%             
        
            load(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data');
            data.ROI_analysis= matdata.data.ROI_analysis;
            % data of the latest operation is appended
            save(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data','-append');
        % saving the matdata into the concerned file- ends
        display('saving done');
        update_rois;
    end

    function[]=update_rois()
       if(use_selected_fibers==1)
           matdata=importdata([pathname 'ctFIREout\ctFIREout_' filename '.mat']);
           
            % creating the field ROI_analysis in matdata.data if the field
            % is not present
            if(isfield(matdata.data,'ROI_analysis')==0)
               matdata.data.ROI_analysis=[];  % this does not add the field to the orignal file. We need to write it again. Done in save_roi function.   
            end
           fiber_data=matdata.data.PostProGUI.fiber_indices;
           
        elseif(use_selected_fibers==2)
%              if(isfield(matdata.data,'ROI_analysis')==0)
%                matdata.data.ROI_analysis=[];  % this does not add the field to the orignal file. We need to write it again. Done in save_roi function.   
%             end           
            address=pathname;
            matdata=importdata(fullfile(address,'ctFIREout',['ctFIREout_',filename,'.mat']));
            
            % creating the field ROI_analysis in matdata.data if the field
            % is not present
       end  
        size_saved_operations=size(fieldnames(matdata.data.ROI_analysis),1);
        names=fieldnames(matdata.data.ROI_analysis);
        for i=1:size_saved_operations
            Data{i,1}=names{i,1};
        end
        set(roi_table,'Data',Data);
       
      
    end 

    function[]=rename_roi(object,handles)
        display(cell_selection_data);
        matdata=importdata(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']));
        index=cell_selection_data(1,1);
        
        %1 now make a window and pop up and ask the new name
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
           temp_fieldnames=fieldnames(matdata.data.ROI_analysis);
           matdata.data.ROI_analysis.(new_fieldname)=matdata.data.ROI_analysis.(temp_fieldnames{index,1});
           matdata.data.ROI_analysis=rmfield(matdata.data.ROI_analysis,temp_fieldnames{index,1});
           
           % 3 write the file as append
           % now saving the data in matfile 
           load(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data');
            data.ROI_analysis= matdata.data.ROI_analysis;
            % data of the latest operation is appended
            save(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data','-append');
            %4 update the roi data
            update_rois;
           close;% closes the popup window
        end
    end
     
    function[]=delete_roi_fn(Object,handles)
         
           % use cell_selection_data, its size =s1
           s1=size(cell_selection_data,1);
           load(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data');
           temp_fieldnames=fieldnames(matdata.data.ROI_analysis);
           for i=1:s1
               display(temp_fieldnames(i,1));
               data.ROI_analysis=rmfield(data.ROI_analysis,temp_fieldnames{i,1});
           end
           save(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data','-append');
           update_rois;
    end
 
    
    
%auxilary functions - begin
         function[length]=fiber_length_fn(fiber_index)
            length=0;
            %s1=size(indices,2);
            %for j=1:s1-1
            %x1=a.data.Xa(indices(j),1);y1=a.data.Xa(indices(j),2);
            %x2=a.data.Xa(indices(j+1),1);y2=a.data.Xa(indices(j+1),2);
            %length=length +cartesian_distance(x1,y1,x2,y2);
            %end
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
%auxilary functions - end
    % checked functions - ends
    
    function[]=measure_fn(handles,object)
           
%         steps
%         1 run a loop for s1 number of times
%         2 make a field called Data, like cellSelection function
%         3 take each ROI in one iteration, make the mask BW , find max,min,number of pixels and sum then sum/number
%         4 data should have fields - max min average and Area(number of pixels)
%         5 then display the window
%         
        roi_number=size(cell_selection_data,1);
        measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 300 300],'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
        measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
        Data=get(roi_table,'data');
        names=fieldnames(matdata.data.ROI_analysis);
        measure_data{1,1}='names';measure_data{1,2}='min';measure_data{1,3}='max';measure_data{1,4}='Area';measure_data{1,5}='mean';
        for k=1:roi_number
             s1=size(image,1);s2=size(image,2);
               for i=1:s1
                   for j=1:s2
                        mask(i,j)=logical(0);
                        BW(i,j)=logical(0);
                   end
               end
               
                operation_data=matdata.data.ROI_analysis.(Data{cell_selection_data(k,1),1});
          if(operation_data.shape==1)% for rect
              display('rect');
              rect_coordinates=operation_data.roi{1,1}{1,1}{1,1};
              x1=floor(rect_coordinates(1));% floor becuase the point positions may be in decimals
                   y1=floor(rect_coordinates(2));
                   x2=floor(rect_coordinates(3));
                   y2=floor(rect_coordinates(4));
                   
                   if(x2>x1&&y2>y1)
                       for m=x1:x2
                           for n=y1:y2
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x1>x2&&y1>y2)
                       for m=x2:x1
                           for n=y2:y1
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x1>x2&&y2>y1)
                       
                       for m=x2:x1
                           for n=y1:y2
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   
                   if(x2>x1&&y1>y2)
                       
                       for m=x1:x2
                           for n=y2:y1
                               BW(m,n)=logical(1);

                               if(m==x1||m==x2||n==y1||n==y2)
                                   roi_boundary(m,n)=uint8(255);% for rectangular boundary
                               end
                           end
                       end
                   end
                   mask=mask|BW;
                kip2(:,:,1)=uint8(roi_boundary(:,:,1));kip2(:,:,2)=0;kip2(:,:,3)=0;
                %display(size(image));display(size(kip2));display(size(overlaid_image));
                %pause(10);
%                overlaid_image(:,:,1)=image(:,:)+kip2(:,:,1);
          elseif(operation_data.shape==2)% for freehand
              display('freehand');
              s3=size(operation_data.roi,2);
                for i=1:s3

                        position=operation_data.roi{1,i}{1,1}{1,1};
                        %s4 = size of roi boundary points
                        %display(size(position));
                        s4=size(position,1);
                        %display(s4);
                        for j=1:s4
                            roi_boundary(floor(position(j,2)),floor(position(j,1)))=uint8(255);
                            if(j<5)
                               %display(floor(position(j,1)));display(floor(position(j,2)));
                            end
                        end
                        BW=roipoly(image,position(:,1),position(:,2));                     
                         mask=mask|BW;
                end               
          end
               
              max=0;min=0;num_pixels=0;sum=0;average=0;
                for i=1:s1
                    for j=1:s2
                        if(mask(i,j)==logical(1))
                           if(image(i,j)>max)
                               max=image(i,j);
                           end
                           if(image(i,j)<min)
                               min=image(i,j);
                           end
                           num_pixels=num_pixels+1;
                           sum=sum+double(image(i,j));
                        end
                        
                    end
                end
                
                if(num_pixels~=0)
                            average=sum/num_pixels;
                end
                        measure_data{k+1,1}=names{cell_selection_data(k,1),1};
                        measure_data{k+1,2}=min;
                        measure_data{k+1,3}=max;
                        measure_data{k+1,4}=num_pixels;
                        measure_data{k+1,5}=average;
             
        end
        display(measure_data);
        set(measure_table,'Data',measure_data);
        set(measure_fig,'Visible','on');
    end

end


