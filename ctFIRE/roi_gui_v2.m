% 6th Jan - overlaying the boundary of ROIs
%kip=b.(fields{1})

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
    global format;
    global roi_boundary;
    global use_selected_fibers;
    global fiber_data; 
    global matdata;
    global filename;
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
    roi_fig = figure('Resize','off','Units','pixels','Position',[50 50 round(SW2/5) round(SH*0.9)],'Visible','on','MenuBar','none','name','Selected Fibers','NumberTitle','off','UserData',0);
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
    
    message_box=uicontrol('Parent',roi_fig,'Style','text','Units','normalized','Position',[0.55 0.05 0.4 0.09],'String','','BackgroundColor',[1 1 1]);
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
        
     

    end

    function[]=check_for_fibers_in_roi(object,handles)
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
       s1=size(handles.Indices,1);
       Data=get(roi_table,'Data');
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
                display(size(image));display(size(kip2));display(size(overlaid_image));
                %pause(10);
%                overlaid_image(:,:,1)=image(:,:)+kip2(:,:,1);
          elseif(operation_data.shape==2)% for freehand
              display('freehand');
              s3=size(operation_data.roi,2);
                for i=1:s3

                        position=operation_data.roi{1,i}{1,1}{1,1};
                        %s4 = size of roi boundary points
                        display(size(position));
                        s4=size(position,1);
                        display(s4);
                        for j=1:s4
                            roi_boundary(floor(position(j,2)),floor(position(j,1)))=uint8(255);
                            if(j<5)
                                display(floor(position(j,1)));display(floor(position(j,2)));
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
        figure;imshow(mask);
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
    
    
end


