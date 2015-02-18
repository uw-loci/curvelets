% 6th Jan - overlaying the boundary of ROIs

function[]=roi_gui()
    
%     Developer - Guneet Singh Mehta
%     Indian Institute of Technology, Jodhpur
%     Former Research Intern at LOCI,UW Madison
%     email- mehta_guneet@iitj.ac.in
%     Duration - December 1 - December 30 th 2014
%     


    % image - global variable storing image
    global image;
    global format;
    global use_selected_fibers;
    global fiber_data; 
    global matdata;
    global filename;
    global mask;% create a mask of the same size as the image and then try to find the fibers in roi_window
    global roi_method;% 1 for selecting fiber if midpoint is within ROI, 
                      % 2 for selecting fiber if the entire fiber is
                      % within the ROI
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
    SW = SSize(3); SH = SSize(4);
   ROI_fig = figure('Resize','off','Units','pixels','Position',[50 50 round(SW/5) round(SH*0.9)],'Visible','on','MenuBar','none','name','Selected Fibers','NumberTitle','off','UserData',0);
    defaultBackground = get(0,'defaultUicontrolBackgroundColor'); drawnow;
    set(ROI_fig,'Color',defaultBackground);
    
    %reset_button=uicontrol('Parent',guiCtrl,'Style','Pushbutton','Units','normalized','Position',[0.7 0.95 0.25 0.04],'String','Reset','FontUnits','normalized','Callback',@reset_fn);
    
    % defining GUI buttons starts
    reset_button=uicontrol('Parent',ROI_fig,'Style','Pushbutton','Units','normalized','Position',[0.7 0.95 0.25 0.04],'String','Reset','FontUnits','normalized','Callback',@reset_fn);
    load_image_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0 0.88 0.45 0.05],'String','Select File','Callback',@load_image,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    imagename_box=uicontrol('Parent',ROI_fig,'Style','text','Units','normalized','Position',[0.5 0.88 0.45 0.05],'String','Filename','BackGroundColor',[1 1 1],'FontUnits','normalized');
    
    % Load ROI buttons- text and load ROI 
    load_ROI_message=uicontrol('Parent',ROI_fig,'Style','text','Units','normalized','Position',[0 0.8 0.45 0.05],'String',' ','BackGroundColor',[1 1 1],'FontUnits','normalized');
    load_ROI_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0.5 0.8 0.45 0.05],'String','Load ROI ','Callback',@load_ROI_popup_window,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
    fiber_data_location_tag=uicontrol('Parent',ROI_fig,'Style','text','Units','normalized','Position',[0 0.74 0.5 0.03],'String','Enter the source of fibers');
    % fibe_data_location allows user to select 1 for ctfire data and 2 for
    % post processing fiber data
    fiber_data_location=uicontrol('Parent',ROI_fig,'Style','popupmenu','Tag','Fiber Data location','Units','normalized','Position',[0 0.7 0.45 0.05],'String',{'CTFIRE Fiber data','Post Processing Fiber data'},'Callback',@fiber_data_location_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    define_roi_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0.5 0.7 0.45 0.05],'String','New ROI','Callback',@new_roi,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
    finalize_roi_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0.5 0.6 0.45 0.05],'String','Finalize ROI','Callback',@finalize_roi_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    delete_roi_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0 0.6 0.45 0.05],'String','Delete ROI','Callback',@delete_roi_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
   
    % defining the method to select the fibers- i.e assigning value of
    % roi_method either 1 or 2
    roi_method_define_box=uicontrol('Parent',ROI_fig,'Style','text','Units','normalized','Position',[0 0.48 0.55 0.05],'String','Enter fiber selection method for ROI');
    roi_method_define=uicontrol('Parent',ROI_fig,'Style','popupmenu','Units','normalized','Position',[0 0.42 0.4 0.05],'String',{'Midpoint','Entire Fibre'},'Callback',@roi_method_define_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
    check_for_fibers_in_roi_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0 0.35 0.45 0.05],'String','Check for fibres in ROI','Callback',@check_for_fibers_in_roi,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
    %generate excel file
    generate_fibers=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0.5 0.35 0.45 0.05],'String','Generate Xls file','Callback',@generate_fiber_properties,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
    roi_message_heading_box=uicontrol('Parent',ROI_fig,'Style','text','Units','normalized','Position',[0 0.25 0.45 0.05],'String','Enter messagefor ROI below','BackGroundColor',defaultBackground,'FontUnits','normalized');
    roi_message_box=uicontrol('Parent',ROI_fig,'Style','edit','Units','normalized','Position',[0 0.2 0.45 0.05],'String',' ','Callback',@roi_message_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    save_roi_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0.5 0.2 0.45 0.05],'String','Save ROI','Callback',@save_roi,'BackGroundColor',defaultBackground,'FontUnits','normalized');
    
    
    % defining GUI buttons ends
    
    %point1_box=uicontrol('Parent',ROI_fig,'Style','edit','Units','normalized','Position',[0 0.88 0.45 0.05],'String','Select File','Callback',@load_image,'BackGroundColor',defaultBackground,'FontUnits','normalized');
   
    
    % how to access the saved ROIs= data.ROI_analysis.operation3.roi{1,1}{1,1}
    
    
   % figure;imshow(image);
   
    function[]=reset_fn(object,handles)
        close all;
        roi_gui();
    end
    
    function[]=load_image(object,handles)
        % image is loaded and data_fiber defined here 
        [filename pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg'},'Select image','MultiSelect','off'); 
        display(filename);
        display(pathname);
        %image=imread([pathname 'ctFIREout\OL_ctFIRE_' filename]);
        image=imread([pathname  filename]);
        set(imagename_box,'String',filename);
        
       s1=size(image,1);s2=size(image,2);
       display(point1);display(point2);
       for i=1:s1
           for j=1:s2
               mask(i,j)=logical(0);
               temp_image(i,j)=uint8(0);
           end
       end
        
        if(size(image,3)>1)
            %image=rgb2gray(image);
        end
        figure;imshow(image);
        
        display(use_selected_fibers);
       
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
            %display(kip_length);
            %display(kip_length_start);
            %display(kip_length_end);
            
            %display(k1);
            count=1;
            
            for i=1:s1
                %display(fiber_length_fn(i));
                %pause(0.5);
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
        display(isempty(matdata.data.ROI_analysis));
        if(isempty(matdata.data.ROI_analysis)==0&&numel(fieldnames(matdata.data.ROI_analysis))~=0)
           set(load_ROI_message,'string','Previous ROIs present'); 
        else
            set(load_ROI_message,'string','No Previous ROIs present'); 
        end
        
    end

    function[]=new_roi(object,handles)
       
        roi=[];
        roi_message=[];
        mask=[];
        BW=[];
        roi_shape=2; % 1 for rectangle , 2 for freehand ROIs
        % once the ROI is defined as rectangle then only rectangle rois
        % would be allowed. 
        %roi_shape is defined in a roi_shape_popup_window function defined
        %at the end of this function
         
        roi_shape_popup_window;% calls a popup window to set value of roi_shape
       
       % pause(5);% this is done so as to give user the time to chose the 
        % roi shape. This needs to be replaced by a way in which the
        % program pauses till ok is pushed in the popup window.
        
        
         % steps- 
        % 1 open an image
    %     2 open h=imfreehand
    %     3 convert h to a a binary mask and then into a uint8 mask
    %     4 ask if ROI is final and needs to be saved ?
    %     5 show ROI in the image
    %     6 store the ROI boundary using pos=getPosition(h) in image.mat file

    % Code to define the ROIs and their shape etc in ok_fn of
    % roi_shape_popup_window
    
        
    end

    function[]=check_for_fibers_in_roi(object,handles)
        s1=size(fiber_data,1);
        display(s1);
       
        figure;imshow(image);hold on;
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
        %
        
        %display(size(image));
        %display(fiber_data);
        plot_fibers(fiber_data,'testing',0,1);
    end

    function[]=generate_fiber_properties(object,handles)
        
        %checking for directory of ROI_analysis
        if(exist(horzcat(pathname,'ROI_analysis'),'dir')==0)
                    mkdir(pathname,'ROI_analysis');
        end
        
        s3=size(fiber_data,1);
%         display(s3);%pause(3); YL
        count=0;
        for i=1:s3
            if(fiber_data(i,2)==1)
                count=count+1;
                data_length(count,1)=fiber_data(i,3);
                data_width(count,1)=fiber_data(i,4);
                data_angle(count,1)=fiber_data(i,5);
                data_straight(count,1)=fiber_data(i,6);
                
            end
        end
        % display(data_length);pause(3);
        %display(data_width);pause(3);
        %display(data_angle);pause(3);
        %display(data_straight);pause(3);
        
        %default values- since the following code is copied from selectedOUT
        stats_of_median=1;stats_of_mode=1;stats_of_mean=1;
        stats_of_variance=1;stats_of_std=1;stats_of_numfibers=1;
        stats_of_max=1;stats_of_min=1;  stats_of_alignment=1;
                
        for k=1:4
            if(k==1)
                data=data_length;
            elseif(k==2)
                data=data_width;
            elseif(k==3)
                data=data_straight;
            elseif(k==4)
                data=data_angle;
            end

            a=2;
            D{1,2,k}=filename;
            file_number_batch_mode=1; % for convenience - since only 
            %one file is there. Since the code is copied it contains this
            %variable. Ideally it should have been made 1
            if stats_of_median==1
                D{a,1,k}='Median';
                D{a,file_number_batch_mode+1,k}=median(data);
                a=a+1;
            end
            if stats_of_mode==1
                D{a,1,k}='Mode';
                D{a,file_number_batch_mode+1,k}=mode(data);
                a=a+1;
            end
            if stats_of_mean==1
                D{a,1,k}='Mean';
                D{a,file_number_batch_mode+1,k}=mean(data);
                a=a+1;
            end
            if stats_of_variance==1
                D{a,1,k}='Variance';
                D{a,file_number_batch_mode+1,k}=var(data);
                a=a+1;
            end
            if stats_of_std==1
                D{a,1,k}='Standard Deviation';
                D{a,file_number_batch_mode+1,k}=std(data);
                a=a+1;
            end
            if stats_of_min==1
                D{a,1,k}='Min';
                D{a,file_number_batch_mode+1,k}=min(data);
                a=a+1;
            end
            if stats_of_max==1
                D{a,1,k}='Max';
                D{a,file_number_batch_mode+1,k}=max(data);
                a=a+1;
            end
            if stats_of_numfibers==1
                D{a,1,k}='Number of Fibers';
                D{a,file_number_batch_mode+1,k}=count;
                a=a+1;
            end

            if stats_of_alignment==1
%                     display('Alignment'); % YL
                D{a,1,k}='Alignment';
                if(k==4)
                    D{a,file_number_batch_mode+1,k}=find_alignment(data);
                end
                a=a+1;
            end

            %display(D(:,:,1));%pause(3);
        end
        D{2,1,5}='SHG intensity within ROI';
        D{2,2,5}=find_SHG_intensity_in_ROI();
        display(D);
        %xls_filename=
        xlswrite([pathname 'ROI_analysis\' filename ' operation' num2str(operation_number)],D(:,:,1),'length');
        xlswrite([pathname 'ROI_analysis\' filename ' operation' num2str(operation_number)],D(:,:,2),'width');
        xlswrite([pathname 'ROI_analysis\' filename ' operation' num2str(operation_number)],D(:,:,3),'angle');
        xlswrite([pathname 'ROI_analysis\' filename ' operation' num2str(operation_number)],D(:,:,4),'straightness');
        xlswrite([pathname 'ROI_analysis\' filename ' operation' num2str(operation_number)],D(:,:,5),'SHG intensity');
        
        function[alignment]=find_alignment(angles)
        
        % the array angles - should be a column vector
        if size(angles,2)~=1
            angles=angles';
        end
        angles2=2*(angles*pi/180);
        alignment=circ_r(angles2);
        
        function r = circ_r(alpha, w, d, dim)
            % r = circ_r(alpha, w, d)
            %   Computes mean resultant vector length for circular data.
            %
            %   Input:
            %     alpha	sample of angles in radians
            %     [w		number of incidences in case of binned angle data]
            %     [d    spacing of bin centers for binned data, if supplied
            %           correction factor is used to correct for bias in
            %           estimation of r, in radians (!)]
            %     [dim  compute along this dimension, default is 1]
            %
            %     If dim argument is specified, all other optional arguments can be
            %     left empty: circ_r(alpha, [], [], dim)
            %
            %   Output:
            %     r		mean resultant length
            %
            % PHB 7/6/2008
            %
            % References:
            %   Statistical analysis of circular data, N.I. Fisher
            %   Topics in circular statistics, S.R. Jammalamadaka et al.
            %   Biostatistical Analysis, J. H. Zar
            %
            % Circular Statistics Toolbox for Matlab
            
            % By Philipp Berens, 2009
            % berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html
            
            if nargin < 4
                dim = 1;
            end
            
            if nargin < 2 || isempty(w)
                % if no specific weighting has been specified
                % assume no binning has taken place
                w = ones(size(alpha));
            else
                if size(w,2) ~= size(alpha,2) || size(w,1) ~= size(alpha,1)
                    error('Input dimensions do not match');
                end
            end
            
            if nargin < 3 || isempty(d)
                % per default do not apply correct for binned data
                d = 0;
            end
            
            % compute weighted sum of cos and sin of angles
            r = sum(w.*exp(1i*alpha),dim);
            
            % obtain length
            r = abs(r)./sum(w,dim);
            
            % for data with known spacing, apply correction factor to correct for bias
            % in the estimation of r (see Zar, p. 601, equ. 26.16)
            if d ~= 0
                c = d/2/sin(d/2);
                r = c*r;
            end
        end
        
        end
    
        function[average]=find_SHG_intensity_in_ROI()
            s1=size(image,1);s2=size(image,2);
            sum=0;counter=0;
            for k1=1:s1
                for k2=1:s2
                    if(mask(k1,k2)==255)
                        sum=sum+double(image(k1,k2)); 
                        counter=counter+1;
                    end
                end
            end
            average=sum/counter;
            
        end
    end

    function[]=finalize_roi_fn(object,handles)
       finalize_roi=1; 
    end

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

    function[]=fiber_data_location_fn(object,handles)
       if(get(object,'value')==1)
           use_selected_fibers=1;
       elseif(get(object,'value')==2)
          use_selected_fibers=2;
       end
    end

    function[]=roi_message_fn(object,handles)
       roi_message=get(object,'string'); 
    end

    function[]=save_roi(object,handles)
        % check for presence of fields ROI
        % while saving ROI check for the last ROI with biggest number
        % if biggest number is 'N' then save the ROI as ROI_(N+1)
        % ROI is saved as coordinates of the ROI as pos1=getPosition(h);
        % recreate mask from saved coordinate by - BW2=roipoly(image,pos(:,1),pos(:,2))
%         
%         We need to save each ROI as it is made and save positions of each
%         Documentation/Location of ROIs- data.ROI_analysis.operation1
%         operation1.date- show the date and time stamp
%         operation1.roi1- boundary of 1st ORI
%         operation1.roi2-boundary of 2nd ROI and so on
        
        % searching for the biggest operation number- starts
           count=1;
           fieldname=['operation',num2str(count)];
           % the statment below needs to be changed so that
           % count=max_count+1
           % because if user deletes
            %operation8 and operation 1-10 were present then the new operation will be called operation8 and not operation 11
           while(isfield(matdata.data.ROI_analysis,fieldname)==1)
              count=count+1; 
              fieldname=['operation',num2str(count)];
           end
           % here fieldname named field does not exist in matdata.data.ROI_analysis 
           
        % searching for the biggest operation number- ends
        
        %saving ROIs in matdata
        matdata.data.ROI_analysis.(fieldname).roi=roi;
        
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
        
    end

    function[]=load_ROI(object,handles)

        %operation_number=3;
        %defining mask-starts
        s1=size(image,1);s2=size(image,2);

        for i=1:s1
            for j=1:s2
                mask(i,j)=logical(0);
                BW(i,j)=logical(0);
                roi_boundary(i,j)=0;
            end
        end
        BW(1:s1,1:s2)=logical(0);
        mask(1:s1,1:s2)=logical(0);
        %defining mask-ends
        
        display(size(operation_number));
        number_of_rois=size(operation_number,2);
        % now running loop multiple times

        display(number_of_rois);
        for k=1:number_of_rois %used for multiple ROIs - working
                % now finding the ROIs
                fieldname=['operation' num2str(operation_number(k))];
                s3=size(matdata.data.ROI_analysis.(fieldname).roi,2);
                display(operation_number(k));
                if(matdata.data.ROI_analysis.(fieldname).shape==2)
                    % if shape=2 then freehand ROI
                    for i=1:s3

                        position=matdata.data.ROI_analysis.(fieldname).roi{1,i}{1,1}{1,1};
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

                        BW=roipoly(image,position(:,1),position(:,2));
                        mask=mask|BW;
                    end
                
                elseif(matdata.data.ROI_analysis.(fieldname).shape==1)
                    % shape==1 then  rectangular ROI
                   rect_coordinates=matdata.data.ROI_analysis.(fieldname).roi{1,1}{1,1}{1,1};
                   y1=floor(rect_coordinates(1));% floor becuase the point positions may be in decimals
                   x1=floor(rect_coordinates(2));
                   y2=floor(rect_coordinates(3));
                   x2=floor(rect_coordinates(4));
                   
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
                
                end
        end
        
        % showing the mask alone
        figure;imshow(uint8(mask)*255);
        figure;imshow(roi_boundary);

        % showing the image within the ROIs
        for i=1:s1
            for j=1:s2
                if mask(i,j)
                   temp_image(i,j)=image(i,j); 
                else
                    temp_image(i,j)=uint8(0);
                end
            end
        end

        figure;imshow(temp_image);

    end

    function[]=load_ROI_popup_window(object,handles)
               %next two statements get the position of ROI GUI and open a new
        %popup window next to it
%         position=get(ROI_fig,'Position');
%         left=position(1);bottom=position(2);width=position(3);height=position(4);
%         
%         ROI_load_popup_window=figure('Units','pixels','Position',[left+width+15 bottom 250 250],'Menubar','none','NumberTitle','off','Name','Select Stats','Visible','on','Color',defaultBackground);
%         
         count=1;
           fieldname=['operation',num2str(count)];
           while(isfield(matdata.data.ROI_analysis,fieldname)==1)
              count=count+1; 
              fieldname=['operation',num2str(count)];
           end
           count=count-1;% because if N operations are there count turns out to be N+1
           display(count);
           s3=count;
           
           %table=nan{s3,4};% creates a table of s3 rows and 4 columns
           % columns for - operation name, date, time and user comment
           
           for i=1:s3 % 3 here for only testimage1, needs to be changed for general case to 1
               fieldname=['operation',num2str(i)];
               table(i,1)={i};
               table(i,2)={matdata.data.ROI_analysis.(fieldname).date};
               table(i,3)={matdata.data.ROI_analysis.(fieldname).time};
               table(i,4)={matdata.data.ROI_analysis.(fieldname).roi_message};
                %table(i,1)={'abcd'};
           end
           
           display(table);
           ROI_popup = figure('Resize','on','Units','pixels','Position',[50 50 800 400],'Visible','on','MenuBar','none','name','Selected Fibers','NumberTitle','off','UserData',0);
           tabGroup = uitabgroup(ROI_popup );
           t5 = uitab(tabGroup);
           selNames = {'Operation Number','date','time','user message of ROI'};
           valuePanel = uitable('Parent',t5,'ColumnName',selNames,'Units','normalized','Position',[.05 .2 .9 .75]);
           operation_number_title_box=uicontrol('Parent',t5,'style','text','string','Enter operation number','Units','normalized','Position',[0 .10 .25 .05]);
           operation_number_title_box=uicontrol('Parent',t5,'style','edit','string','','Units','normalized','Position',[0.3 .10 .25 .05],'BackGroundColor',[1 1 1],'Callback',@operation_number_fn);
           ok_box=uicontrol('Parent',t5,'style','pushbutton','string','Ok','Units','normalized','Position',[0.4 .05 .10 .05],'BackGroundColor',[1 1 1],'Callback',@call_load_ROI);
           
           set(t5,'Title','Values');
            set(valuePanel,'Data',table);
            
        function[]=operation_number_fn(object,handles)
           operation_number=str2num(get(object,'string'));
           fprintf('operation number is %d',operation_number);
        end
        
        function[]=call_load_ROI(object,handles)
           close;%closes the load_ROI_popup_window
           load_ROI;
        end
    end

    function[]=roi_method_define_fn(object,handles)
       if(strcmp(get(object,'string'),'Midpoint'))
           roi_method=1;
           
       else
           roi_method=2;
       end
       
       roi_method=get(object,'value');
       display(roi_method);
       fprintf('\nisfloat = %d\n',isfloat(roi_method));
    end

    function[]=roi_shape_popup_window()
    %remember to add object and handles as input argument while integrating
     %position=get(ROI_fig,'Position');
        %roi_shape=2; % 1 for rectangle , 2 for freehand ROIs
        % once the ROI is defined as rectangle then only rectangle rois
        % would be allowed. 
        
        position=[50 50 200 200];
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        defaultBackground = get(0,'defaultUicontrolBackgroundColor'); 
        popup=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 200],'Menubar','none','NumberTitle','off','Name','Remove Fibers','Visible','on','Color',defaultBackground);
        rf_numbers_text=uicontrol('Parent',popup,'Style','text','string','select ROI type','Units','normalized','Position',[0.05 0.9 0.9 0.10]);
        rf_numbers_menu=uicontrol('Parent',popup,'Style','popupmenu','string',{'Rectangular','Freehand'},'Units','normalized','Position',[0.05 0.75 0.9 0.10]);
        rf_numbers_ok=uicontrol('Parent',popup,'Style','pushbutton','string','Ok','Units','normalized','Position',[0.05 0.50 0.45 0.10],'Callback',@ok_fn);
        
     function[]=ok_fn(object,handles)
        
         display(get(rf_numbers_menu,'value'));
      roi_shape=get(rf_numbers_menu,'value');
       display(roi_shape);
       
       % step 1 and 2 openning an image and defining the ROI as 'h' object 
        finalize_roi=0;
         close; % closes the pop up window
        figure;imshow(image);
        s1=size(image,1);s2=size(image,2);
        for i=1:s1
            for j=1:s2
                mask(i,j)=logical(0);
            end
        end

        %step 3 
        count=0;
        while(finalize_roi==0)
            
            % save using the following command
            % save(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data','-append');
            
                count=count+1;
                if(roi_shape==1)
                        h=imrect;
                elseif(roi_shape==2)
                        h=imfreehand;
                end
                %roi_temp=getPosition(h);
                roi{count}={mat2cell(getPosition(h))};
                
                BW=createMask(h);
               
                if(finalize_roi==1)
                    break;
                end
                % BW is the mask corresponding to the current ROI, we will OR 
                % this with mask to get a union of both
               % display(size(mask));
                %display(size(BW));
                %pause(5);
                mask=mask|BW;
                
                
                display(count);
            
            

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
        orignal_image=imread(fullfile(pathname,[filename,'.',format]));
%         gray123=orignal_image;   % YL: replace "gray" with "gray123", as gray is a reserved name for Matlab  
         gray123=orignal_image;
%         gray123(:,:,1)=orignal_image(:,:);
%         gray123(:,:,2)=orignal_image(:,:);
%         gray123(:,:,3)=orignal_image(:,:);
        %figure;imshow(gray123);
        
        string=horzcat(string,' size=', num2str(size(gray123,1)),' x ',num2str(size(gray123,2)));
        gcf= figure('name',string,'NumberTitle','off');imshow(gray123);hold on;       
        string=horzcat('image size=',num2str(size(gray123,1)),'x',num2str(size(gray123,2)));% not used
        %text(1,1,string,'HorizontalAlignment','center','color',[1 0 0]);
        
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

    function[]=delete_roi_fn(Object,handles)
         delete_popup = figure('Resize','on','Units','pixels','Position',[50 50 200 200],'Visible','on','MenuBar','none','name','Delete Fibers','NumberTitle','off','UserData',0);
         %define_roi_box=uicontrol('Parent',ROI_fig,'Style','pushbutton','Units','normalized','Position',[0.5 0.7 0.45 0.05],'String','New ROI','Callback',@new_roi,'BackGroundColor',defaultBackground,'FontUnits','normalized');
         text=uicontrol('Parent',delete_popup,'Style','text','Units','normalized','Position',[0 0.9 0.95 0.1],'String','Enter operation numbers to be deleted');
         numbers=uicontrol('Parent',delete_popup,'Style','edit','Units','normalized','Position',[0 0.2 0.95 0.63],'String','');
         ok_button=uicontrol('Parent',delete_popup,'Style','pushbutton','Units','normalized','Position',[0.4 0.0 0.5 0.1],'String','Ok','Callback',@ok_fn);
        
        function[]=ok_fn(object,handles)
           string=get(numbers,'string');
           operation_numbers=str2num(string);
           s1=size(operation_numbers,2);
           display(s1);display(operation_numbers);
           
           load(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data');
           for i=1:s1
               fieldname=['operation' num2str(operation_numbers(i))];
               display(fieldname);
               data.ROI_analysis=rmfield(data.ROI_analysis,fieldname);
           end
           save(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data','-append');
%             load(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data');
%             %data.ROI_analysis= matdata.data.ROI_analysis;
%             % data of the latest operation is appended
%             for i=1:s1
%               fieldname=[operation operation_numbers(i)];
%               display(fieldname);
%               display(matdata.data.ROI_analysis.(fieldname));
%               data.ROI_analysis=rmfield(data.ROI_analysis,fieldname);
%               display(matdata.data.ROI_analysis.(fieldname));
%            end
%             save(fullfile(pathname,'ctFIREout',['ctFIREout_',filename,'.mat']),'data','-append');
%         % saving the matdata into the concerned file- ends
%             display('deletion done');
%             close;
%         
        end
    end
end


