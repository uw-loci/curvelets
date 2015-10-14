function[]=selectedOUT()
% run after the CT-FIRE main program generate the csv files for
% width,length,angle, and straightness
% to visualize properties of each fiber  and remove oversegmented fibers, selective output
% based on the absolute thresholds or relative percentages for a single
% image/stack or multiple images
%LOG:
%July, 2014,YL: This advanced output feature was mainly conceived by Y. Liu (YL), G. Mehta(GM),and J. Bredfeldt (JB)
% implemented by  Guneet Singh Mehta, optimized and integrated into the main program by Y. Liu
% LOCI, UW-Madison

% March-April: GM and P. 
%July,2014: YL uses the 'xlwrite' developed by Alec de Zegher to save excel files in Mac OS.
% need to initialisation of POI Libsfunction in MAC OS and add Java POI Libs to matlab javapath
%August 2015: GM optimizes the visualization of the output of selectedOUT
%August 2015: YL adds the function for multiple stacks analysis  
warning('off','all');
MAC = 0 ; % 1: mac os; 0: windows os
if ~ismac
   MAC = 0;
   
else
   MAC = 1;
   
end
if (~isdeployed)
    if MAC == 1
        javaaddpath('../20130227_xlwrite/poi_library/poi-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/xmlbeans-2.3.0.jar');
        javaaddpath('../20130227_xlwrite/poi_library/dom4j-1.6.1.jar');
        javaaddpath('../20130227_xlwrite/poi_library/stax-api-1.0.1.jar');
        addpath('../20130227_xlwrite');
    end
    addpath('.');
    addpath('../xlscol/');
end
       
%         edit(fullfile(matlabroot,'bin','maci64','java.opts')); add
%         -Xmxm512m
%         edit(fullfile(matlabroot,'bin','win64','java.opts'))
%          freememory = java.lang.Runtime.getRuntime.freeMemory
%          totalmemory = java.lang.Runtime.getRuntime.totalMemory
%           maxmemory = java.lang.Runtime.getRuntime.maxMemory
          
 
fig = findall(0,'type','figure');
if length(fig) > 0
    keepf = find(fig == 1);
    if length(keepf) > 0
        fig(keepf) = [];
    end
    close(fig);
end

f1=fopen('address2.mat');
% YL: don't save address2.mat in the begining,such that the most recent
% successfully loaded path can be loaded
if(f1<=0)
%     display('current_address is not present');
    pseudo_address='';%pwd;
%     save('address2.mat','pseudo_address'); 
    
else
    pseudo_address = importdata('address2.mat');
    if(pseudo_address==0)
        pseudo_address = '';%pwd;
%         save('address2.mat','pseudo_address'); 
        disp('using default path to load file(s)'); % YL
    else
        disp(sprintf( 'using saved path to load file(s), current path is %s ',pseudo_address));
    end
end
% display(pseudo_address);
%% YL
file_number_max = 1e4;  % Maximum number of images to be analyzed is 10,000

COLL = xlscol(1:file_number_max); % convert to excel column letters be be used in xlwrite or xlswrite function
crsname = [];    % combined raw data sheet name  
Maxnumf = 50;  % maximum number of files in the combined rawdata sheet
Cole    = 5;  % column for each file

filename = {};  %  file name of the image
filenamestack = {};  %file name for the stack
slicenumber = [];   % slice position;
slicestack = [];    % slice associated stack
%% YL: tab for visualizing the properties of the selected fiber
SSize = get(0,'screensize');
SW = SSize(3); SH = SSize(4);
guiFig = figure('Resize','off','Units','pixels','Position',[round(SW)/5 round(SH/2) round(SH/2) round(SH/3)],'Visible','off','MenuBar','none','name','Selected Fibers','NumberTitle','off','UserData',0);
defaultBackground = get(0,'defaultUicontrolBackgroundColor'); drawnow;
set(guiFig,'Color',defaultBackground)

 %the tabgroup, tabs and panels where the selected image and results will be displayed
tabGroup = uitabgroup(guiFig);
t5 = uitab(tabGroup);
selNames = {'fiberN','width','length','angle','straightness'};
valuePanel = uitable('Parent',t5,'ColumnName',selNames,'Units','normalized','Position',[.05 .2 .95 .75]);

 global D2;
 global file_number;

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
guiCtrl=figure('Units','Pixels','position',[25,75,250,650],'Menubar','none','NumberTitle','off','Name','Analysis Module','Visible','on','Color',defaultBackground);
%address=uigetdir([],'choose the folder containing the image');


address=[];

setappdata(guiCtrl,'address',address);
setappdata(guiCtrl,'visualise_fibers',[]);
setappdata(guiCtrl,'filename',[]);
setappdata(guiCtrl,'nfibers',[]);
setappdata(guiCtrl,'imglocation',[]);
setappdata(guiCtrl,'result_xls_filename',[]);
%setappdata(guiCtrl,'opvalue',[]);
%setappdata(guiCtrl,'topn',[]);1
%setappdata(guiCtrl,'result_xls_filename',[]);
setappdata(guiCtrl,'thresh_length_start',0);
setappdata(guiCtrl,'thresh_length_end',100);
setappdata(guiCtrl,'thresh_width_start',0);
setappdata(guiCtrl,'thresh_width_end',100);
setappdata(guiCtrl,'thresh_straight_start',0);
setappdata(guiCtrl,'thresh_straight_end',100);
setappdata(guiCtrl,'thresh_angle_start',0);
setappdata(guiCtrl,'thresh_angle_end',100);
%setappdata(guiCtrl,'thresholded_xls_filename',[]);
setappdata(guiCtrl,'batchmode',0);
setappdata(guiCtrl,'batchmode_filename',[]);
setappdata(guiCtrl,'format',[]);
setappdata(guiCtrl,'batchmode_combined_stats_xlsfilename',[]);
%fiber_indices - for example if there are 302 fibers and we need to
%show only 1,2,3,4,5 then fiber_indices(1:5,2)=1 else ==0 i.e 1 means
%show and 0 means dont show
fiber_indices=[];

removed_fibers=[];

batchmode_length_raw=[];
batchmode_width_raw=[];
batchmode_angle_raw=[];
batchmode_straight_raw=[];
batchmode_statistics_modified_name=[];

display_images_in_batchmode=1;% 1 if yes 0 if no

%matdata= contains the structure of .matfile data- described in
%set_filename
matdata=[];
kip_length_start=0;kip_length_end=0;kip_width_start=0;kip_width_end=0;
kip_angle_start=0;kip_angle_end=0;kip_straight_start=0;kip_straight_end=0;

% defining bounds because if the user decides not to use thresholding
width_lower_bound=0; width_upper_bound=1000;
length_lower_bound=0;length_upper_bound=10000;
angle_lower_bound=0;angle_upper_bound=180;
straight_lower_bound=0;straight_upper_bound=1;
use_thresholded_fibers=0;
% for percentage - threshold_type_value=1 else for pixels
% threshold_type_value=2
top_or_bottom_N=10;
thresh_type_value=1; % thresh_type value=1 for percentages , 2 for absolute values , 3 for top N , 4 for bottom N
final_threshold=0;
file_number_batch_mode=0;
file_number=1;
C=[];
D=[];%used in printing the xls_file for batchmode processing
% setappdata(guiCtrl,'width_thresh',[]);


% combined_stats start
combined_stats(1,1,1)={'length'};combined_stats(1,1,2)={'width'};combined_stats(1,1,3)={'angle'};combined_stats(1,1,4)={'straightness'};
%combined_stats=[];   % C(:,:,1) contains the fiber numbers, combined_stats(:,:,2) contains length
combined_stats_index=[];
for kipper=1:4
    combined_stats(2,1,kipper)={'Median'};
    combined_stats(3,1,kipper)={'Mode'};
    combined_stats(4,1,kipper)={'Mean'};
    combined_stats(5,1,kipper)={'Variance'};
    combined_stats(6,1,kipper)={'Standard Deviation'};
    combined_stats(7,1,kipper)={'Minimum'};
    combined_stats(8,1,kipper)={'Maximum'};
    combined_stats(9,1,kipper)={'Number Of Fibers'};
    combined_stats(10,1,kipper)={'Alignment'};
end
%display(combined_stats);
% combined_stats end

batchmode_box=uicontrol('Parent',guiCtrl,'Style','checkbox','Units','normalized','Position',[0 0.93 0.1 0.07],'Callback',@batchmode_fn);
batchmode_text=uicontrol('Parent',guiCtrl,'Style','text','Units','normalized','Position',[0.08 0.925 0.25 0.05],'String','Batch Mode');

stack_box=uicontrol('Parent',guiCtrl,'Style','checkbox','Units','normalized','Position',[0.35 0.93 0.1 0.07],'Callback',@stack_box_fn);
stack_text=uicontrol('Parent',guiCtrl,'Style','text','Units','normalized','Position',[0.43 0.925 0.25 0.05],'String','Stack Mode');


reset_button=uicontrol('Parent',guiCtrl,'Style','Pushbutton','Units','normalized','Position',[0.7 0.95 0.25 0.04],'String','Reset','FontUnits','normalized','Callback',@reset_fn);
filename_box=uicontrol('Parent',guiCtrl,'Style','pushbutton','Units','normalized','Position',[0 0.88 0.45 0.05],'String','Select File','Callback',@set_filename,'BackGroundColor',defaultBackground,'FontUnits','normalized');


visualise_fiber_button=uicontrol('Parent',guiCtrl,'style','pushbutton','Units','normalized','Position',[0 0.825 0.45 0.05],'String','Visualise Fibers','Callback',@visualise_fibers_popupwindow_fn,'enable','off');

show_filename_panel=uipanel('Parent',guiCtrl,'Units','normalized','Position',[0.5 0.825 0.45 0.1],'Visible','on');
show_filename_panel_text=uicontrol('Parent',show_filename_panel,'Units','normalized','Position',[0 0.8 1 0.18],'Style','text','String','Filename');
show_filename_panel_filename=uicontrol('Parent',show_filename_panel,'Units','normalized','Position',[0 0 1 0.75],'Style','text');

removefibers_box=uicontrol('Parent',guiCtrl,'Style','pushbutton','Units','normalized','Position',[0 0.77 0.45 0.05],'String','Remove Fibers', 'Callback', @remove_fibers_popupwindow_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized','enable','off');
save_fibers_button1=uicontrol('Parent',guiCtrl,'Style','pushbutton','Units','normalized','Position',[0.5 0.77 0.45 0.05],'String','Save Fibers', 'Callback', @save_fibers_button1_fn,'BackGroundColor',defaultBackground,'FontUnits','normalized','enable','off');

threshold_panel_decide=uipanel('Parent',guiCtrl,'Units','normalized','Position',[0 0.67 1 0.08],'Visible','on');
use_threshold_checkbox=uicontrol('Parent',threshold_panel_decide,'style','checkbox','Units','normalized','Position',[0 0.71 0.1 0.3],'Callback',@enable_thresh_panel,'enable','off');
use_threshold_text=uicontrol('Parent',threshold_panel_decide,'style','text','Units','normalized','Position',[0.08 0.7 0.9 0.3],'string','check the box if thresholding is desired','enable','off');

thresh_type=uicontrol('Parent',threshold_panel_decide,'style','popupmenu','Units','normalized','Position',[0,0.35 1 0.2],'String',{'percentage';'Absolute Values';'Top N';'Bottom N'},'Enable','off','Callback',@thresh_type_value_fn);

threshold_panel=uipanel('Parent',guiCtrl,'Title','Thresholds (in percentages) ','Units','normalized','Position',[0 0.38 1 0.25],'Visible','on');

thresh_length_radio=uicontrol('Parent',threshold_panel,'Style','radiobutton','Units','normalized','Position',[0 0.80 0.1 0.1],'Callback',@tradio_length,'enable','off');
thresh_width_radio=uicontrol('Parent',threshold_panel,'Style','radiobutton','Units','normalized','Position',[0 0.55 0.1 0.1],'Callback',@tradio_width,'enable','off');
thresh_straight_radio=uicontrol('Parent',threshold_panel,'Style','radiobutton','Units','normalized','Position',[0 0.30 0.1 0.1],'Callback',@tradio_straight,'enable','off');
thresh_angle_radio=uicontrol('Parent',threshold_panel,'Style','radiobutton','Units','normalized','Position',[0 0.05 0.1 0.1],'Callback',@tradio_angle,'enable','off');

text_length=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.06 0.8 0.25 0.1],'enable','off','String','Length');
text_width=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.06 0.55 0.25 0.1],'enable','off','String','Width');
text_straight=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.06 0.30 0.25 0.1],'enable','off','String','Straightness');
text_angle=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.06 0.05 0.25 0.1],'enable','off','String','Angle');

thresh_length_start=uicontrol('Parent',threshold_panel,'String','0','Style','edit','Units','normalized','Position',[0.35 0.8 0.1 0.1],'enable','off','Callback',@thresh_length_start_fn);
thresh_width_start=uicontrol('Parent',threshold_panel,'String','0','Style','edit','Units','normalized','Position',[0.35 0.55 0.1 0.1],'enable','off','Callback',@thresh_width_start_fn);
thresh_straight_start=uicontrol('Parent',threshold_panel,'String','0','Style','edit','Units','normalized','Position',[0.35 0.3 0.1 0.1],'enable','off','Callback',@thresh_straight_start_fn);
thresh_angle_start=uicontrol('Parent',threshold_panel,'String','0','Style','edit','Units','normalized','Position',[0.35 0.05 0.1 0.1],'enable','off','Callback',@thresh_angle_start_fn);

thresh_length_to=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.50 0.8 0.1 0.1],'String','to','BackGroundColor',defaultBackground,'enable','off');
thresh_width_to=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.50 0.55 0.1 0.1],'String','to','BackGroundColor',defaultBackground,'enable','off');
thresh_straight_to=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.50 0.3 0.1 0.1],'String','to','BackGroundColor',defaultBackground,'enable','off');
thresh_angle_to=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.50 0.05 0.1 0.1],'String','to','BackGroundColor',defaultBackground,'enable','off');

thresh_length_end=uicontrol('Parent',threshold_panel,'String','100','Style','edit','Units','normalized','Position',[0.65 0.8 0.1 0.1],'enable','off','Callback',@thresh_length_end_fn);
thresh_width_end=uicontrol('Parent',threshold_panel,'String','100','Style','edit','Units','normalized','Position',[0.65 0.55 0.1 0.1],'enable','off','Callback',@thresh_width_end_fn);
thresh_straight_end=uicontrol('Parent',threshold_panel,'String','100','Style','edit','Units','normalized','Position',[0.65 0.3 0.1 0.1],'enable','off','Callback',@thresh_straight_end_fn);
thresh_angle_end=uicontrol('Parent',threshold_panel,'String','100','Style','edit','Units','normalized','Position',[0.65 0.05 0.1 0.1],'enable','off','Callback',@thresh_angle_end_fn);

thresh_length_unit=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.85 0.8 0.1 0.1],'enable','off','String','%');
thresh_width_unit=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.85 0.55 0.1 0.1],'enable','off','String','%');
thresh_straight_unit=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.85 0.30 0.1 0.1],'enable','off','String','%');
thresh_angle_unit=uicontrol('Parent',threshold_panel,'Style','text','Units','normalized','Position',[0.85 0.05 0.1 0.1],'enable','off','String','%');

threshold_now_button=uicontrol('Parent',guiCtrl,'Style','pushbutton','Units','normalized','Position',[0 0.30 0.45 0.05],'enable','off','string','threshold now','Callback',@threshold_now);
threshold_final_button=uicontrol('Parent',guiCtrl,'Style','pushbutton','Units','normalized','Position',[0.5 0.30 0.45 0.05],'enable','off','string','Save Fibers','Callback',@threshold_final_fn);

%threshold_final_button  threshold_now_button
% stats for -
stats_for_panel=uipanel('Parent',guiCtrl,'Title','Generate stats for ','Units','normalized','Position',[0 0.18 1 0.1]);
stats_for_length_radio=uicontrol('Parent',stats_for_panel,'Style','radiobutton','Units','normalized','Position',[0 0 0.08 1],'Callback',@stats_for_length_fn,'enable','off','Value',1);
stats_for_length_text=uicontrol('Parent',stats_for_panel,'Style','text','Units','normalized','Position',[0.08 0 0.17 0.7],'String','Length','enable','off');
stats_for_length=1;

stats_for_width_radio=uicontrol('Parent',stats_for_panel,'Style','radiobutton','Units','normalized','Position',[0.25 0 0.08 1],'Callback',@stats_for_width_fn,'enable','off','Value',1);
stats_for_width_text=uicontrol('Parent',stats_for_panel,'Style','text','Units','normalized','Position',[0.33 0 0.17 0.7],'String','Width','enable','off');
stats_for_width=1;

stats_for_straight_radio=uicontrol('Parent',stats_for_panel,'Style','radiobutton','Units','normalized','Position',[0.5 0 0.08 1],'Callback',@stats_for_straight_fn,'enable','off','Value',1);
stats_for_straight_text=uicontrol('Parent',stats_for_panel,'Style','text','Units','normalized','Position',[0.58 0 0.17 0.7],'String','Straight','enable','off');
stats_for_straight=1;

stats_for_angle_radio=uicontrol('Parent',stats_for_panel,'Style','radiobutton','Units','normalized','Position',[0.75 0 0.08 1],'Callback',@stats_for_angle_fn,'enable','off','Value',1);
stats_for_angle_text=uicontrol('Parent',stats_for_panel,'Style','text','Units','normalized','Position',[0.83 0 0.17 0.7],'String','Angle','enable','off');
stats_for_angle=1;


%output stats
stats_of_median=1;stats_of_mode=1;stats_of_mean=1;
stats_of_variance=1;stats_of_std=1;stats_of_numfibers=1;
stats_of_max=1;stats_of_min=1;  stats_of_alignment=1;

generate_stats_button=uicontrol('Parent',guiCtrl,'style','pushbutton','Units','normalized','Position',[0 0.12 0.45 0.05],'String','Generate stats','Callback',@generate_stats_popupwindow,'enable','off');
generate_raw_datasheet=0; %=1 if raw data sheet is to be generated and 0 if not

status_panel=uipanel('Parent',guiCtrl,'units','normalized','Position',[0 0.01 1 0.11],'Title','Status','BackGroundColor',defaultBackground);
status_text=uicontrol('Parent',status_panel,'units','normalized','Position',[0.05 0.05 0.9 0.9],'Style','text','BackGroundColor',defaultBackground,'String','Select File(s) [Batchmode Not Selected] ','HorizontalAlignment','left');

    function[]=reset_fn(hObject,eventsdata,handles)
        fig = findall(0,'type','figure');
        keepf = find(fig == 1);
        fig(keepf) = [];
        close(fig);
        selectedOUT();
    end

    function set_filename(hObject,eventdata,handles)
        
        %save(horzcat(address,'ctFIREout\ctFIREout_',getappdata(guiCtrl,'filename'),'.mat'),'matdata');
        
        
        %display('in set_filename');
        %display(pseudo_address);
        if(getappdata(guiCtrl,'batchmode')==0)
            set(status_text,'String','Opening File...');
        else
            set(status_text,'String','Opening Files...');
        end
        
        set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text generate_stats_button],'enable','off');
        %         if(getappdata(guiCtrl,'batchmode')==1)
        %             set(generate_stats_button,'enable','on');
        %         end
        set([use_threshold_checkbox use_threshold_text removefibers_box visualise_fiber_button],'enable','off');
        %set([batchmode_text batchmode_box],'enable','off');
        parent=get(hObject,'Parent');
        
        if(get(stack_box,'Value')==1)
		  [filenametemp pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select file',pseudo_address,'MultiSelect','on');
          %  filename=stack_to_slices(filename,pathname); % GSM - set filename field of the guiCtrl - yet to do
            %return;
            [filenametemp pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select file',pseudo_address,'MultiSelect','on');
            %             filename=stack_to_slices(filename,pathname); % GSM - set filename field of the guiCtrl - yet to do
            %return;
            if ~iscell(filenametemp)  % single stack
                ff = fullfile(pathname, filenametemp);
                info = imfinfo(ff);
                numSections = numel(info);
                slicenumber = 1: numSections; 
                slicestack = ones(1,numSections);
                ks = 0;
                for ifns = 1:numSections
                    ks = ks + 1;
                    [~,filenamewithoutext,fnext]  =  fileparts(filenametemp)
                    filename(ks) = {sprintf('%s_s%d%s',filenamewithoutext,ifns,fnext)};
                    
                end
                filenamestack = {filenametemp}
            
            else                % multiple stacks
                filenamestack = filenametemp;
                ks = 0;
                for ifn = 1: length(filenametemp);
                    ff = fullfile(pathname, filenametemp{ifn});
                    info = imfinfo(ff);
                    numSections = numel(info);
                    for ifns = 1:numSections
                        ks = ks + 1;
                        [~,filenamewithoutext,fnext]  =  fileparts(filenametemp{ifn})
                        filename(ks) = {sprintf('%s_s%d%s',filenamewithoutext,ifns,fnext)};
                        slicenumber(ks) = ifns; 
                        slicestack(ks) = ifn;
                    end
                end
                
            end
        end
    
        
        if (getappdata(guiCtrl,'batchmode')==1)
            
            
            %             display(pseudo_address);
            if(get(stack_box,'Value')>=0)
                if(get(stack_box,'Value')==0)
                [filename1 pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select file',pseudo_address,'MultiSelect','on');
                else
                    filename1=filename;
                end
                % if the image has no associated .mat file, then should throw it out.
                
                if iscell(filename1)
                    filename = filename1;
                    matPath = strcat(pathname,'ctFIREout');
                    [~,imgName,~] = cellfun(@fileparts,filename1,'UniformOutput',false);
                    Mtemp1 = repmat({'.mat'},1,length(imgName));
                    Mtemp2 = repmat({'ctFIREout_'},1,length(imgName));
                    matcPath = repmat({matPath},1,length(imgName));
                    matName = cellfun(@strcat,Mtemp2,imgName,Mtemp1,'UniformOutput',false);
                    matfull = cellfun(@fullfile,matcPath,matName,'UniformOutput',false);
                    fileflag = cellfun(@(x)exist(x,'file'),matfull,'UniformOutput',false);
                    ki = 0;
                    for fi = 1:length(filename1)
                        if fileflag{fi} == 0
                            ki = ki + 1;
                            disp(sprintf('The image %s is skipped, as no associated .mat file exists',filename1{fi}));
                            filename(fi-ki+1) = [];
                            
                        end
                    end
                    if ki > 0
                        display(sprintf('%d of %d skipped as the absense of the .mat file', ki,length(filename1)));
                    elseif ki == 0
                        display(sprintf('To process %d images. All of the associated .mat files exist',length(filename1)));
                    end
                    
                end
                
                if isequal(pathname,0)
                    disp('Please choose images to start the batch-mode analysis')
                    return
                end
                
                if ~iscell(filename)
                    disp('Please choose at least 2 images to start the batch-mode analysis')
                    return
                end
                
                %% YL: only after successfully load the files, enable the generate_stats_button
                set(generate_stats_button,'enable','on');
                
                %YL: maximum file number to meet the column limit of the excel spreadsheet
                if iscell(filename)
                   
                    
%                     file_number_max = 250;
                    
                    if length(filename)> file_number_max
                        disp(sprintf('Maximum number of images is %d, please reselect the images',file_number_max));
                        return
                    else
                        pseudo_address=pathname;
                        file_number=size(filename,2);
                        address=pathname;
                        
                        
                        LastN = mod(file_number,Maxnumf);
                        Nsheets = ceil(file_number/Maxnumf);
                        for si = 1:Nsheets
                            if file_number <= Maxnumf
                                crsname{si} = sprintf('Combined Raw Data 1-%d',file_number);
                                
                            else
                                
                                crsname{si} = sprintf('Combined Raw Data %d-%d',(si-1)*Maxnumf+1,si*Maxnumf);
                                
                                if si == Nsheets && LastN ~= 0
                                    crsname{si} = sprintf('Combined Raw Data %d-%d',(si-1)*Maxnumf+1,(si-1)*Maxnumf+LastN);
                                    
                                end
                            end
                            
                        end
                        if Nsheets > 1
                            disp(sprintf('There are %d sheets to be used for saving combined raw data:',Nsheets));
                            display(crsname)
                        elseif Nsheets == 1
                            disp(sprintf('Sheet to be used for saving combined raw data is:',Nsheets));
                            display(crsname)
                        end
                        
                        
                    end
                end
                
                
                set([batchmode_text batchmode_box stack_box stack_text],'enable','off');
                set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text ],'enable','on');
                
                
                
                temp=dir(fullfile(address,'selectout','batchmode_statistics*'));
                %             display(size(temp));%pause(10); YL
                if(size(temp,1)>=1)
                    batchmode_statistics_modified_name=horzcat('batchmode_statistics',num2str(size(temp,1)+1),'.xlsx');
                    %                 display('multiple batchmode files');%pause(10);
                else
                    batchmode_statistics_modified_name='batchmode_statistics1.xlsx';  %YL: add the index "1" to the first file name
                end
                %             display(pseudo_address);
                
                
                save('address2.mat','pseudo_address');
                
                setappdata(guiCtrl,'batchmode_filename',filename);
                
                %Make the selectout folder if not present- start
                if(exist(horzcat(address,'selectout'),'dir')==0)
                    mkdir(address,'selectout');
                end
                %Make the selectout folder if not present- end
                
                % YL: clear up the message to be displayed
                %             display('in set_filename');
                disp(sprintf('%d images have been loaded',file_number));
                set([use_threshold_checkbox  use_threshold_text ],'enable','on');
            end
            %             display(filename);
            %             display(getappdata(guiCtrl,'batchmode_filename'));
            
            
            %YL:not need to load .mat file here
            %             for j=1:file_number
            %                  disp(sprintf('loading %d / %d', j, file_number));
            %                  fiber_indices=[];
            %                  image=imread(fullfile(address,filename{j}));
            %                  setappdata(guiCtrl,'filename',filename{j});
            %                  set(show_filename_panel_filename,'String',filename{j});
            %                  display(fullfile(address,'ctFIREout',['ctFIREout_',filename{j},'.mat']));
            %                  index2=strfind(filename{j},'.');index2=index2(end);
            %                  kip_filename=filename{j};
            %                  matdata=importdata(fullfile(address,'ctFIREout',['ctFIREout_',kip_filename(1:index2-1),'.mat']));
            %                  s1=size(matdata.data.Fa,2);
            %                  count=1;
            % %                 xls_widthfilename=fullfile(address,'ctFIREout',['HistWID_ctFIRE_',kip_filename(1:index2-1),'.csv']);
            % %                 xls_lengthfilename=fullfile(address,'ctFIREout',['HistLEN_ctFIRE_',kip_filename(1:index2-1),'.csv']);
            % %                 xls_anglefilename=fullfile(address,'ctFIREout',['HistANG_ctFIRE_',kip_filename(1:index2-1),'.csv']);
            % %                 xls_straightfilename=fullfile(address,'ctFIREout',['HistSTR_ctFIRE_',kip_filename(1:index2-1),'.csv']);
            % %                 fiber_width=csvread(xls_widthfilename);
            % %                 fiber_length=csvread(xls_lengthfilename); % no need of fiber_length - as data is entered using fiber_length_fn
            % %                 fiber_angle=csvread(xls_anglefilename);
            % %                 fiber_straight=csvread(xls_straightfilename);
            % %
            %                  for i=1:s1
            %                      %display(fiber_length_fn(i));
            %                      %pause(0.5);
            %                      ctFIRE_length_threshold=matdata.cP.LL1;
            %                      if(fiber_length_fn(i) <= ctFIRE_length_threshold)  %YL: change from "<" to "<="  to be consistent with original ctFIRE_1
            %                          fiber_indices(i,1)=i;
            %                          fiber_indices(i,2)=0;
            %
            %                          fiber_indices(i,3)=0;%length
            %                          fiber_indices(i,4)=0;%width
            %                          fiber_indices(i,5)=0;%angle
            %                          fiber_indices(i,6)=0;%straight
            %                      else
            %                          fiber_indices(i,1)=i;
            %                          fiber_indices(i,2)=1;
            %                          fiber_indices(i,3)=0; %GSM not fiber_length_fn(i);
            %                          fiber_indices(i,4)=0; %GSM not fiber_width(count);
            %                          fiber_indices(i,5)=0; %GSM not fiber_angle(count);
            %                          fiber_indices(i,6)=0; %GSM not fiber_straight(count); Since we need to save time in opening all files and reading data while osetting filenames
            %                          count=count+1;
            %                      end
            % %                     %display(fiber_indices);
            % %                     %pause(4);
            % %
            %                  end
            %                  if(display_images_in_batchmode==1)
            %                      gcf= figure('name',kip_filename,'NumberTitle','off');imshow(image);
            %                      %set(gcf,'visible','off');  % YL: don't show original image in batch mode
            %                      plot_fibers(fiber_indices,horzcat(kip_filename,' orignal fibers'),0,1); % YL: comment out, don't plot fiber in  batch mode analysis
            %                  end
            %
            %             end
            %display(isempty(filename));
            
            
        elseif(getappdata(guiCtrl,'batchmode')==0&&get(stack_box,'Value')==0)
            set([batchmode_text batchmode_box stack_box stack_text],'enable','off');
            %[imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select an Image','MultiSelect','off');
            
            
            % Checking for address2.mat if not then create one- Start
            
            
            %             display(pseudo_address);
            % Checking for address2.mat if not then create one- end
            
            [filename pathname filterindex]=uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select file',pseudo_address,'MultiSelect','off');
            if isequal(pathname,0)
                disp('Please choose a image to start the single image analysis')
                return
            end
            
            
            pseudo_address=pathname;
            address=pathname;
            %             display(pseudo_address);
            
            save('address2.mat','pseudo_address');
            set(show_filename_panel_filename,'String',filename);
            
            
            %Make the selectout folder if not present- start
            if(exist(horzcat(address,'selectout'))==0)
                mkdir(address,'selectout');
            end
            %Make the selectout folder if not present- end
            
            removed_fibers=[];
            parent=get(hObject,'Parent');
            kip_index=strfind(filename,'.');
            kip_index=kip_index(end);% anywhere kip comes it indicates trash value
            format=filename(kip_index:end);
            filename=filename(1:kip_index-1);
            
            %display(format);
            %display(filename);
            setappdata(parent,'filename',filename);
            setappdata(parent,'format',format);
            
            a=imread(fullfile(address,[filename,getappdata(guiCtrl,'format')]));
            if size(a,3)==4
                %check for rgb
                a=a(:,:,1:3);
            end
            gcf= figure('name',filename,'NumberTitle','off');imshow(a);
            
            
            matdata=importdata(fullfile(address,'ctFIREout',['ctFIREout_',filename,'.mat']));
            
            %reentering the PostProGUI data in matdata
            matdata.data.PostProGUI=[];
            %display(matdata);
            
            % s1 indicates the number of fibers in the .mat file
            s1=size(matdata.data.Fa,2);
            
            % assigns 1 to all fibers initially -INITIALIZATION
            fiber_indices=[];
            for i=1:s1
                fiber_indices(i,1)=i; fiber_indices(i,2)=1; fiber_indices(i,3)=0;
            end
            
            % s2 is the length threshold used in the ctFIRE
            ctFIRE_length_threshold=matdata.cP.LL1;
            %if length of the fiber is less than the threshold s2 then
            %assign 0 to that fiber
            
            
            %Now fiber indices will have the following columns=
            % column1 - fiber number column2=visile(if ==1)
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
                    fiber_indices(i,2)=0;
                    
                    fiber_indices(i,3)=fiber_length_fn(i);
                    fiber_indices(i,4)=0;%width
                    fiber_indices(i,5)=0;%angle
                    fiber_indices(i,6)=0;%straight
                else
                    fiber_indices(i,2)=1;
                    fiber_indices(i,3)=fiber_length_fn(i);
                    fiber_indices(i,4)=fiber_width(count);
                    fiber_indices(i,5)=fiber_angle(count);
                    fiber_indices(i,6)=fiber_straight(count);
                    count=count+1;
                end
                
            end
            %display(count);
            %display(fiber_indices);
            plot_fibers(fiber_indices,horzcat(filename,' orignal fibers'),0,1);
            if(isempty(filename)==0&&get(batchmode_box,'Value')==0)
                set(save_fibers_button1,'enable','on');
                set([visualise_fiber_button removefibers_box],'enable','on');
                set(filename_box,'enable','off');
                set(status_text,'String','Select Visualise Fibers to specific Fibers  Select Remove Fibers to remove specific fibers');
            elseif(isempty(filename)==0&&get(batchmode_box,'Value')==1)
                set(save_fibers_button1,'enable','off');
                
                set([filename_box visualise_fiber_button removefibers_box ],'enable','off');
                set(status_text,'String','Select Thresholds (if desired) and then the fiber attributes for fibers');
                set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text ],'enable','on');
                set([use_threshold_checkbox use_threshold_text ],'enable','on');
                
            end
            
            if(getappdata(guiCtrl,'batchmode')==0)
                set(status_text,'String','File Opened');
            else
                set(status_text,'String','Files Opened');
            end
        end
        if(get(batchmode_box,'Value')==1)
            set(status_text,'String','Files Opened');
        end
        set([filename_box ],'enable','off');
    end
    
    function[]=remove_fibers_popupwindow_fn(hObject,eventsdata,handles)
        
        position=get(guiCtrl,'Position');
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        rf_panel=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 200],'Menubar','none','NumberTitle','off','Name','Remove Fibers','Visible','on','Color',defaultBackground);
        rf_numbers_edit_box=uicontrol('Parent',rf_panel,'Style','edit','Units','normalized','Position',[0.05 0.2 0.8 0.60],'Callback',@set_nfibers);
        rf_numbers_edit_text=uicontrol('Parent',rf_panel,'Style','text','Units','normalized','Position',[0 0.8 0.9 0.18],'String','Enter Fiber Numbers (separated by spaces) for Deselection, below');
        rf_numbers_remove=uicontrol('Parent',rf_panel,'Style','Pushbutton','Units','normalized','Position',[0.05 0.05 0.45 0.12],'String','Ok','Callback',@remove_fibers);
        
        function[]=set_nfibers(hObject,eventsdata,handles)
            nfibers=get(hObject,'String');
            
            setappdata(guiCtrl,'nfibers',nfibers);
            remove_fibers(0,0,0);
            %display(nfibers);
            %display(getappdata(guiCtrl,'nfibers'));
        end
        
        function remove_fibers(hObject,eventsdata,handles)
            
            nfibers=str2num(getappdata(guiCtrl,'nfibers'));
            removed_fibers=horzcat(removed_fibers,' ',get(rf_numbers_edit_box,'String'));
            %display(get(rf_numbers_edit_box));
            %display(nfibers);
            message=horzcat('Removed Fiber Numbers = ',removed_fibers);
            set(status_text,'String',message);
            % display(nfibers);
            %display(size(nfibers));
            %display(isa(nfibers,'char'));
            s1=size(nfibers,2);
            close;
            for i=1:s1
                fiber_indices(nfibers(i),2)=0;
                %this is done coz we need to make change in the orignal
                % fibers being used
                %wheras in threshold now we work on a temporary copy 'fiber_indices2'and when
                %final threshold is pressed the 'fiber_indices' is assigned
                %the value of'fiber_indices2'
            end
            plot_fibers(fiber_indices,horzcat(getappdata(guiCtrl,'filename'),'after removal'),0,1);
        end
    end

    function[]=stack_box_fn(hObject,eventsdata,handles)
        if(get(stack_box,'Value')==1)
            set(batchmode_box,'Value',1);
            set([batchmode_text batchmode_box],'enable','off');
            setappdata(guiCtrl,'batchmode',1);
        else
            set(batchmode_box,'Value',0);
            set([batchmode_text batchmode_box],'enable','on');
            setappdata(guiCtrl,'batchmode',0);
        end
        
        position_of_postpgui=get(guiCtrl,'Position');
%         display(position_of_postpgui); % YL
        
        if(get(hObject,'value')==1)
            left=position_of_postpgui(1);
            bottom=position_of_postpgui(2);
            popupwindow=figure('Units','Pixels','position',[left+70 bottom+560 350 80],'Menubar','none','NumberTitle','off','Name','Analysis Module','Visible','on','Color',defaultBackground);
            %stats_for_angle_radio=uicontrol('Parent',stats_for_panel,'Style','radiobutton','Units','normalized','Position',[0.75 0 0.08 1],'Callback',@stats_for_angle_fn,'enable','off','Value',1);
            dialogue=uicontrol('Parent',popupwindow,'Style','text','Units','normalized','Position',[0.05 0.5 0.9 0.45],'String','Display Images in Stackmode ?');
            yes_box=uicontrol('Parent',popupwindow,'Style','pushbutton','Units','normalized','Position',[0.05 0.05 0.4 0.4],'String','Yes','Callback',@yes_fn);
            no_box=uicontrol('Parent',popupwindow,'Style','pushbutton','Units','normalized','Position',[0.5 0.05 0.4 0.4],'String','NO','Callback',@no_fn);
         end
        
        function[]=yes_fn(hObject,handles,eventsdata)
           display_images_in_batchmode=1; 
%            display(display_images_in_batchmode);
           disp('Overlaid images will be generated and displayed in this analysis'); % YL
           close;
        end
        
        function[]=no_fn(hObject,handles,eventsdata)
            display_images_in_batchmode=0;
%             display(display_images_in_batchmode);
            disp('NO overlaid image will be generated and displayed in this analysis'); %YL
            close;
        end
    end

    function[]=visualise_fibers_popupwindow_fn(hObject,eventsdata,handles)
        position=get(guiCtrl,'Position');
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        
        vf_panel=figure('Units','pixels','Position',[left+width+15 bottom+height-200 200 200],'Menubar','none','NumberTitle','off','Name','Visualise Fibers','Visible','on','Color',defaultBackground);
        vf_numbers_edit_box=uicontrol('Parent',vf_panel,'Style','edit','Units','normalized','Position',[0.05 0.2 0.8 0.60],'Callback',@visualise_fiber_enter_numbers_fn);
        vf_numbers_edit_text=uicontrol('Parent',vf_panel,'Style','text','Units','normalized','Position',[0 0.8 0.9 0.18],'String','Enter Fiber Numbers (separated by spaces) for Visualisation, below');
        vf_numbers_remove=uicontrol('Parent',vf_panel,'Style','Pushbutton','Units','normalized','Position',[0.05 0.05 0.45 0.12],'String','Ok','Callback',@visualise_fibers_fn);
        
        
        function visualise_fiber_enter_numbers_fn(hObject,eventsdata,handles)
            parent=get(hObject,'Parent');
            vfibers=get(hObject,'String');
            setappdata(guiCtrl,'visualise_fibers',vfibers);
            %display(vfibers);
            %display('kill');
            %close(vf_panel);
            visualise_fibers_fn(0,0,0);
        end
        
        function visualise_fibers_fn(hObject,eventsdata,handles)
            
            s2=size(matdata.data.Fa,2);
            for i=1:s2
                data_fibers(i,1)=i;
                data_fibers(i,2)=0;
            end
            %display(data_fibers);
            display(getappdata(guiCtrl,'visualise_fibers'));
            fiber_number_for_visualization=str2num(getappdata(guiCtrl,'visualise_fibers'));
            display(fiber_number_for_visualization);
            s3=size(fiber_number_for_visualization,2);
%             display(s3);YL
            message={};
            
            selFIBs = nan(s3,5);  % table to show the selected fibers
            
            for i=1:s3
                data_fibers(fiber_number_for_visualization(1,i),2)=1;
                length_of_visualised_fiber=fiber_indices(fiber_number_for_visualization(1,i),3);
                width_of_visualised_fiber=fiber_indices(fiber_number_for_visualization(1,i),4);
                angle_of_visualised_fiber=fiber_indices(fiber_number_for_visualization(1,i),5);
                straight_of_visualised_fiber=fiber_indices(fiber_number_for_visualization(1,i),6);
                %                 string=horzcat('Fiber ',num2str(fiber_indices(fiber_number_for_visualization(1,i),1)),' length=',num2str(length_of_visualised_fiber),' width=',num2str(width_of_visualised_fiber),' angle=',num2str(angle_of_visualised_fiber),' straightness=',num2str(straight_of_visualised_fiber));
                %                 message(i,:)={string};
                selFIBs(i,1) = fiber_indices(fiber_number_for_visualization(1,i),1);
                selFIBs(i,2) =   width_of_visualised_fiber;% width
                selFIBs(i,3) =   length_of_visualised_fiber;% length
                selFIBs(i,4) =   angle_of_visualised_fiber;% angle
                selFIBs(i,5) =   straight_of_visualised_fiber;% straightness
                
            end
            close;
            set(t5,'Title','Values');
            set(valuePanel,'Data',selFIBs);
            plot_fibers(data_fibers,horzcat(getappdata(guiCtrl,'filename'),'Visualised Fibers'),0,1);
            set(guiFig,'Visible','on');
            %             fiber_data_popup_window=figure('Units','pixels','Position',[left bottom+height+40 500 200],'Menubar','none','NumberTitle','off','Name','Fiber Data','Visible','on','Color',defaultBackground);
            %             display(message);
            %             fiber_data_text=uicontrol('Parent',fiber_data_popup_window,'Style','text','Units','normalized','Position',[0.01 0.01 0.98 0.98],'String',message);
            
        end
    end

    function[]=save_fibers_button1_fn(hObject,eventsdata,handles)
        
        set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text],'enable','on');
        set([use_threshold_checkbox use_threshold_text removefibers_box visualise_fiber_button ],'enable','on');
        set([visualise_fiber_button removefibers_box save_fibers_button1],'enable','off');
        plot_fibers1(fiber_indices,horzcat(getappdata(guiCtrl,'filename'),'Finalized Fibers'),0,0);
        
        set(generate_stats_button,'enable','on');
        %pause(5);
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

% after remove the fiber
    function []=plot_fibers1(fiber_data,string,pause_duration,print_fiber_numbers)
        % a is the .mat file data
        % orignal image is the gray scale image, gray123 is the orignal image in
        % rgb
        % fiber_indices(:,1)= fibers to be plotted
        % fiber_indices(:,2)=0 if fibers are not to be shown and 1 if fibers
        % are to be shown
        
        % fiber_data is the fiber_indices' working copy which may or may not
        % be the global fiber_indices
        
        a=matdata;
        orignal_image=imread(fullfile(address,[getappdata(guiCtrl,'filename'),getappdata(guiCtrl,'format')]));
%         gray123=orignal_image;
       if(size(orignal_image,3)==3)
          orignal_image=rgb2gray(orignal_image); 
       end
       gray123(:,:,1)=orignal_image(:,:);
       gray123(:,:,2)=orignal_image(:,:);
       gray123(:,:,3)=orignal_image(:,:);
        %figure;imshow(gray123);
        
        string=horzcat(string,' size=', num2str(size(gray123,1)),' x ',num2str(size(gray123,2)));
        gcf= figure('name',string,'NumberTitle','off');imshow(gray123);hold on;
        string=horzcat('image size=',num2str(size(gray123,1)),'x',num2str(size(gray123,2)));
        %text(1,1,string,'HorizontalAlignment','center','color',[1 0 0]);
        %%YL: fix the color of each fiber
        rng(1001) ;
        clrr2 = rand(size(a.data.Fa,2),3); % set random color
        
        for i=1:size(a.data.Fa,2)
            if fiber_data(i,2)==1
                
                point_indices=a.data.Fa(1,i).v;
                s1=size(point_indices,2);
                x_cord=[];y_cord=[];
                for j=1:s1
                    x_cord(j)=a.data.Xa(point_indices(j),1);
                    y_cord(j)=a.data.Xa(point_indices(j),2);
                end
                color1= clrr2(i,1:3); %rand(3,1); YL: fix the color of each fiber
                plot(x_cord,y_cord,'LineStyle','-','color',color1,'linewidth',0.005);hold on;
                % pause(4);
                if(print_fiber_numbers==1&&final_threshold~=1)
                    
                    %text(x_cord(s1),y_cord(s1),num2str(i),'HorizontalAlignment','center','color',color1);
                    %%YL show the fiber label from the left ending point,
                    shftx = 5;   % shift the text position to avoid the image edge
                    bndd = 10;   % distance from boundary
                    if x_cord(end) < x_cord(1)
                        
                        if x_cord(s1)< bndd
                            text(x_cord(s1)+shftx,y_cord(s1),num2str(i),'HorizontalAlignment','center','color',color1);
                        else
                            text(x_cord(s1),y_cord(s1),num2str(i),'HorizontalAlignment','center','color',color1);
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
        hold off
        
        
        RES = 300;  % default resolution, in dpi
        set(gca, 'visible', 'off');
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(gray123,1)/RES size(gray123,2)/RES]);
        set(gcf,'Units','normal');
        set (gca,'Position',[0 0 1 1]);
        OL_sfName = fullfile(address,'selectout',[getappdata(guiCtrl,'filename'),'_overlaid_selected_fibers','.tif']);
        print(gcf,'-dtiff', ['-r',num2str(RES)], OL_sfName);  % overylay selected extracted fibers on the original image
        
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
    %YL: process stack
        if(get(stack_box,'Value')==1)
            
%             orignal_image=imread(fullfile(address,[getappdata(guiCtrl,'filename'),getappdata(guiCtrl,'format')]));
        else
            orignal_image=imread(fullfile(address,[getappdata(guiCtrl,'filename'),getappdata(guiCtrl,'format')]));
            
        end
%        orignal_image=imread(fullfile(address,[getappdata(guiCtrl,'filename'),getappdata(guiCtrl,'format')]));
%         gray123=orignal_image;   % YL: replace "gray" with "gray123", as gray is a reserved name for Matlab  
        if(size(orignal_image,3)==3)
           orignal_image=rgb2gray(orignal_image); 
        end
        gray123(:,:,1)=orignal_image(:,:);
        gray123(:,:,2)=orignal_image(:,:);
        gray123(:,:,3)=orignal_image(:,:);
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
        if(final_threshold==1)
            RES = 300;  % default resolution, in dpi
            set(gca, 'visible', 'off');
            set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(gray123,1)/RES size(gray123,2)/RES]);
            set(gcf,'Units','normal');
            set (gca,'Position',[0 0 1 1]);
            OL_sfName = fullfile(address,'selectout',[getappdata(guiCtrl,'filename'),'_overlaid_selected_fibers','.tif']);
            
            print(gcf,'-dtiff', ['-r',num2str(RES)], OL_sfName);  % overylay selected extracted fibers on the original image
            %              saveas(gcf,horzcat(address,'\selectout\',getappdata(guiCtrl,'filename'),'_overlaid_selected_fibers','.tif'),'tif');
        end
    end

    function enable_thresh_panel(hObject,eventdata,handles)
        %set( [ thresh_angle_to thresh_angle_start thresh_angle_end text_angle thresh_straight_to thresh_straight_start thresh_straight_end text_straight ] ,'enable','on');
        % set( [ok_threshold thresh_type thresh_length_to thresh_length_start thresh_length_end text_length thresh_width_to thresh_width_start thresh_width_end text_width ] ,'enable','on');
        
        %stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text
        if(get(hObject,'Value')==1)
            set([thresh_length_radio thresh_width_radio thresh_straight_radio thresh_angle_radio thresh_type  ],'enable','on');
            if(get(batchmode_box,'Value')==0)
                set([visualise_fiber_button ],'enable','on');
            end
            set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text],'enable','on');
            
            set(status_text,'String','Specify Thresholds');
        else
            set([thresh_length_radio thresh_width_radio thresh_straight_radio thresh_angle_radio thresh_type  ],'enable','off');
            if(get(batchmode_box,'Value')==0)
                set([visualise_fiber_button ],'enable','off');
            end
            set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text],'enable','on');
            
            set(status_text,'String',[]);
        end
        use_thresholded_fibers=1;
    end

    function thresh_type_value_fn(hObject,eventdata,handles)
        value=get(hObject,'Value');
        if value==1
            set(threshold_panel,'Title','Thresholds (in percentages) ');
            set([thresh_length_unit thresh_width_unit thresh_straight_unit thresh_angle_unit],'String','%');
            set(thresh_length_start ,'String','0' ); set(thresh_length_end ,'String','100' );
            set(thresh_width_start ,'String','0' ); set(thresh_width_end ,'String','100' );
            set(thresh_angle_start ,'String','0' ); set(thresh_angle_end ,'String','100' );
            set(thresh_straight_start ,'String','0' ); set(thresh_straight_end ,'String','100' );
        elseif value==2
            set(threshold_panel,'Title','Thresholds (in absolute bounds) ');
            set([thresh_length_unit thresh_width_unit],'String','pixels');
            set(thresh_angle_unit,'String','Degree');
            set(thresh_straight_unit,'String','0-1');
            set(thresh_length_start ,'String',num2str(kip_length_start) ); set(thresh_length_end ,'String',num2str(kip_length_end) );
            set(thresh_width_start ,'String',num2str(kip_width_start) ); set(thresh_width_end ,'String',num2str(kip_width_end) );
            set(thresh_angle_start ,'String',num2str(kip_angle_start) ); set(thresh_angle_end ,'String',num2str(kip_angle_end) );
            set(thresh_straight_start ,'String',num2str(kip_straight_start) ); set(thresh_straight_end ,'String',num2str(kip_straight_end) );
         elseif value==3
            set([thresh_length_unit thresh_width_unit],'String','#');
            set(thresh_angle_unit,'String','#');
            set(thresh_straight_unit,'String','#');
            display(size(fiber_indices,1));
            %set([threshold_now_button threshold_final_button],'enable','on')
            
        elseif value==4
            set([thresh_length_unit thresh_width_unit],'String','#');
            set(thresh_angle_unit,'String','#');
            set(thresh_straight_unit,'String','#');
            display(size(fiber_indices,1));
           % set([threshold_now_button threshold_final_button],'enable','on')
            
        end
        %display(value);
        thresh_type_value=value;
    end

    function[]=tradio_length(hObject,eventsdata,handles)
        
        if(get(thresh_type,'Value')==1)
            set(status_text,'String','Default Lower bound = 0% and Upper bound=100%');
        else
            set(status_text ,'String',horzcat('Default Lower bound is =',num2str(kip_length_start),' pixels and Upper Bound is =',num2str(kip_length_end),'pixels'));
        end
        
        if(get(hObject,'Value')==1)
            set([text_length thresh_length_start thresh_length_end thresh_length_to thresh_length_unit  ],'enable','on'); set(thresh_length_radio,'Value',1);
            if(get(thresh_type,'Value')>2)
                set([text_width thresh_width_start thresh_width_end thresh_width_to thresh_width_unit  ],'enable','off'); set(thresh_width_radio,'Value',0);
                set([text_straight thresh_straight_start thresh_straight_end thresh_straight_to thresh_straight_unit  ],'enable','off'); set(thresh_straight_radio,'Value',0);
                set([text_angle thresh_angle_start thresh_angle_end thresh_angle_to thresh_angle_unit  ],'enable','off');set(thresh_angle_radio,'Value',0);
            end
            
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','on')
            end
            if(thresh_type_value==3)
               set(thresh_length_start,'enable','off');set(thresh_length_end,'enable','on');
            elseif(thresh_type_value==4)
                set(thresh_length_start,'enable','on');set(thresh_length_end,'enable','off');
            end
            set([thresh_length_start thresh_length_end],'String',[]);
        else
            set([text_length thresh_length_start thresh_length_end thresh_length_unit thresh_length_to  ],'enable','off');
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','off')
            end
        end
    end

    function[]=tradio_width(hObject,eventsdata,handles)
        
        if(get(thresh_type,'Value')==1)
            set(status_text,'String','Default Lower bound = 0% and Upper bound=100%');
        else
            set(status_text ,'String',horzcat('Default Lower bound is =',num2str(kip_width_start),' pixels and Upper Bound is =',num2str(kip_width_end),'pixels'));
        end
        
        if(get(hObject,'Value')==1)
            
            set([text_width thresh_width_start thresh_width_end thresh_width_to thresh_width_unit  ],'enable','on'); set(thresh_width_radio,'Value',1);
            
            if(get(thresh_type,'Value')>2)
                set([text_length thresh_length_start thresh_length_end thresh_length_to thresh_length_unit  ],'enable','off'); set(thresh_length_radio,'Value',0);
                set([text_straight thresh_straight_start thresh_straight_end thresh_straight_to thresh_straight_unit  ],'enable','off'); set(thresh_straight_radio,'Value',0);
                set([text_angle thresh_angle_start thresh_angle_end thresh_angle_to thresh_angle_unit  ],'enable','off');set(thresh_angle_radio,'Value',0);
            end
            
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','on')
            end
            if(thresh_type_value==3)
               set(thresh_width_start,'enable','off');set(thresh_width_end,'enable','on');
            elseif(thresh_type_value==4)
                set(thresh_width_start,'enable','on');set(thresh_width_end,'enable','off');
            end
            set([thresh_width_start thresh_width_end],'String',[]);
        else
            set([text_width thresh_width_start thresh_width_end thresh_width_unit thresh_width_to  ],'enable','off');
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','off')
            end
        end
    end

    function[]=tradio_straight(hObject,eventsdata,handles)
        
        if(get(thresh_type,'Value')==1)
            set(status_text,'String','Default Lower bound = 0% and Upper bound=100%');
        else
            set(status_text ,'String',horzcat('Default Lower bound is =',num2str(kip_straight_start),' and Upper Bound is =',num2str(kip_straight_end)));
        end
        
        if(get(hObject,'Value')==1)
            
            set([text_straight thresh_straight_start thresh_straight_end thresh_straight_to thresh_straight_unit  ],'enable','on'); set(thresh_straight_radio,'Value',1);
            if(get(thresh_type,'value')>2)
                set([text_length thresh_length_start thresh_length_end thresh_length_to thresh_length_unit  ],'enable','off'); set(thresh_length_radio,'Value',0);
                set([text_width thresh_width_start thresh_width_end thresh_width_to thresh_width_unit  ],'enable','off'); set(thresh_width_radio,'Value',0);    
                set([text_angle thresh_angle_start thresh_angle_end thresh_angle_to thresh_angle_unit  ],'enable','off');set(thresh_angle_radio,'Value',0);
            end
            
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','on')
            end
            if(thresh_type_value==3)
               set(thresh_straight_start,'enable','off');set(thresh_straight_end,'enable','on');
            elseif(thresh_type_value==4)
                set(thresh_straight_start,'enable','on');set(thresh_straight_end,'enable','off');
            end
            set([thresh_straight_start thresh_straight_end],'String',[]);
        else
            set([text_straight thresh_straight_start thresh_straight_end thresh_straight_unit thresh_straight_to ],'enable','off');
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','off')
            end
        end
    end


    function[]=tradio_angle(hObject,eventsdata,handles)
        
        if(get(thresh_type,'Value')==1)
            set(status_text,'String','Default Lower bound = 0% and Upper bound=100%');
        else
            set(status_text ,'String',horzcat('Default Lower bound is =',num2str(kip_angle_start),' Degrees and Upper Bound is =',num2str(kip_angle_end),'Degrees'));
        end
        
        if(get(hObject,'Value')==1)
            
            if(get(thresh_type,'Value')>2)
                set([text_length thresh_length_start thresh_length_end thresh_length_to thresh_length_unit  ],'enable','off'); set(thresh_length_radio,'Value',0);
                set([text_width thresh_width_start thresh_width_end thresh_width_to thresh_width_unit  ],'enable','off'); set(thresh_width_radio,'Value',0);
                set([text_straight thresh_straight_start thresh_straight_end thresh_straight_to thresh_straight_unit  ],'enable','off'); set(thresh_straight_radio,'Value',0);
            end
            
            set([text_angle thresh_angle_start thresh_angle_end thresh_angle_to thresh_angle_unit  ],'enable','on');set(thresh_angle_radio,'Value',1);
            
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','on')
            end
            if(thresh_type_value==3)
               set(thresh_angle_start,'enable','off');set(thresh_angle_end,'enable','on');
            elseif(thresh_type_value==4)
                set(thresh_angle_start,'enable','on');set(thresh_angle_end,'enable','off');
            end
            set([thresh_angle_start thresh_angle_end],'String',[]);
        else
            set([text_angle thresh_angle_start thresh_angle_end thresh_angle_to thresh_angle_unit ],'enable','off');
            if(get(batchmode_box,'Value')==0)
                set([threshold_final_button  threshold_now_button],'enable','off')
            end
        end
    end

    function[]=thresh_length_start_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        a=get(hObject,'string');
        %display(a);
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_length_start',a);
    end

    function[]=thresh_length_end_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        a=get(hObject,'string');
        %display(a);
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_length_end',a);
    end

    function[]=thresh_width_start_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        %a=getappdata(parent2,'thresh_length_end');
        %display(a);
        a=get(hObject,'string');
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_width_start',a);
    end

    function[]=thresh_width_end_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        %a=getappdata(parent2,'thresh_length_end');
        %display(a);
        a=get(hObject,'string');
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_width_end',a);
    end

    function[]=thresh_straight_start_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        %a=getappdata(parent2,'thresh_length_end');
        %display(a);
        a=get(hObject,'string');
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_straight_start',a);
    end

    function[]=thresh_straight_end_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        %a=getappdata(parent2,'thresh_length_end');
        %display(a);
        a=get(hObject,'string');
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_straight_end',a);
    end

    function[]=thresh_angle_start_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        %a=getappdata(parent2,'thresh_length_end');
        %display(a);
        a=get(hObject,'string');
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_angle_start',a);
    end

    function[]=thresh_angle_end_fn(hObject,eventdata,handles)
        % because the button is a child of threshpanel which in turn is a child
        % of guictrl which has all associated properties
        parent1=get(hObject,'Parent');
        %parent2=getappdata(parent1,'Parent');
        parent2=get(parent1,'Parent');
        %a=getappdata(parent2,'thresh_length_end');
        %display(a);
        a=get(hObject,'string');
        if(thresh_type_value>=3)
           top_or_bottom_N= str2num(get(hObject,'string'));
        end
        setappdata(parent2,'thresh_angle_end',a);
    end

    function[] =stats_for_length_fn(hObject,eventdata,handles)
        
        if(get(hObject,'Value')==1)
            stats_for_length=1;% display(1);
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
            
        else
            stats_for_length=0;
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        end;
        
        if(stats_for_length==1||stats_for_width==1||stats_for_straight||stats_for_angle==1)
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','off');
        else
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','on');
        end
    end

    function[] =stats_for_width_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            stats_for_width=1;
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        else
            stats_for_width=0;
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        end
        
        if(stats_for_length==1||stats_for_width==1||stats_for_straight||stats_for_angle==1)
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','off');
        else
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','on');
        end
        %display(1);
    end

    function[] =stats_for_straight_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            stats_for_straight=1; %display(1);
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        else
            stats_for_straight=0; %display(1);
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        end
        
        if(stats_for_length==1||stats_for_width==1||stats_for_straight||stats_for_angle==1)
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','off');
        else
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','on');
        end
    end

    function[] =stats_for_angle_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            stats_for_angle=1; %display(1);
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        else
            stats_for_angle=0; %display(1);
            if(stats_for_length==1||stats_for_width==1||stats_for_straight==1||stats_for_angle==1)
                set(generate_stats_button,'enable','on');
            else
                set(generate_stats_button,'enable','off');
            end
        end
        if(stats_for_length==1||stats_for_width==1||stats_for_straight||stats_for_angle==1)
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','off');
        else
            set([use_threshold_checkbox use_threshold_text thresh_type],'enable','on');
        end
    end

    function threshold_now(hObject,eventdata,handles)
        plotflag2 = 1; %YL: 1 plot fibers; 0: don't plot fiber , will add its control on the GUI
        rawon = 1 ;   %YL: 1: generate raw data; 0: just generate statistics, will add its control on the GUI
        % s2 indicated the total fibers in the .mat file
        fiber_indices2=fiber_indices;
        s2=size(fiber_indices2,1);
        s1=0;
        filename=getappdata(guiCtrl,'filename');
        
        for i=1:s2
            if(fiber_indices2(i,2)==1)
                s1=s1+1;
                data_length(s1)=fiber_indices2(i,3);
                data_width(s1)=fiber_indices2(i,4);
                data_angle(s1)=fiber_indices2(i,5);
                data_straight(s1)=fiber_indices2(i,6);
            end
        end
        
        %s1 is the total number of fibers with the visible option =1
        sorted_width_array=sort(data_width);
        sorted_length_array=sort(data_length);
        sorted_angle_array=sort(data_angle);
        sorted_straight_array=sort(data_straight);
        if(thresh_type_value==1)
            if(get(thresh_width_radio,'Value')==1)
                
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_width_start')))>=1)
                    width_lower_bound=sorted_width_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_width_start'))));
                else
                    width_lower_bound=sorted_width_array(1);
                end
                
                
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_width_end')))<=s1)
                    width_upper_bound=sorted_width_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_width_end'))));
                else
                    width_upper_bound=sorted_width_array(s1);
                end
%                 display(width_upper_bound);
%                 display(width_lower_bound);
            end
            if(get(thresh_length_radio,'Value')==1)
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_length_start')))>=1)
                    length_lower_bound=sorted_length_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_length_start'))));
                else
                    length_lower_bound=sorted_length_array(1);
                end
                
                
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_length_end')))<=s1)
                    length_upper_bound=sorted_length_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_length_end'))));
                else
                    length_upper_bound=sorted_length_array(s1);
                end
%                 display(length_upper_bound);
%                 display(length_lower_bound);
            end
            if(get(thresh_angle_radio,'Value')==1)
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_angle_start')))>=1)
                    angle_lower_bound=sorted_angle_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_angle_start'))));
                else
                    angle_lower_bound=sorted_angle_array(1);
                end
                
                
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_angle_end')))<=s1)
                    angle_upper_bound=sorted_angle_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_angle_end'))));
                else
                    angle_upper_bound=sorted_angle_array(s1);
                end
%                 display(angle_upper_bound);
%                 display(angle_lower_bound);
            end
            if(get(thresh_straight_radio,'Value')==1)
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_straight_start')))>=1)
                    straight_lower_bound=sorted_straight_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_straight_start'))));
                else
                    straight_lower_bound=sorted_straight_array(1);
                end
                
                
                if(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_straight_end')))<=s1)
                    straight_upper_bound=sorted_straight_array(floor(s1*0.01*str2num(getappdata(guiCtrl,'thresh_straight_end'))));
                else
                    straight_upper_bound=sorted_straight_array(s1);
                end
%                 display(straight_upper_bound);
%                 display(straight_lower_bound);
            end
        elseif(thresh_type_value==2)
            if(get(thresh_width_radio,'Value')==1)
                width_lower_bound=str2num(getappdata(guiCtrl,'thresh_width_start'));
                width_upper_bound=str2num(getappdata(guiCtrl,'thresh_width_end'));
            end
            if(get(thresh_length_radio,'Value')==1)
                length_lower_bound=str2num(getappdata(guiCtrl,'thresh_length_start'));
                length_upper_bound=str2num(getappdata(guiCtrl,'thresh_length_end'));
            end
            if(get(thresh_angle_radio,'Value')==1)
                angle_lower_bound=str2num(getappdata(guiCtrl,'thresh_angle_start'));
                angle_upper_bound=str2num(getappdata(guiCtrl,'thresh_angle_end'));
            end
            if(get(thresh_straight_radio,'Value')==1)
                straight_lower_bound=str2num(getappdata(guiCtrl,'thresh_straight_start'));
                straight_upper_bound=str2num(getappdata(guiCtrl,'thresh_straight_end'));
            end
            
            elseif(thresh_type_value==3||thresh_type_value==4)
            % order = length width angle and straightness
         
            if(get(thresh_length_radio,'Value')==1 && get(thresh_width_radio,'Value')==0 && get(thresh_angle_radio,'Value')==0 && get(thresh_straight_radio,'Value')==0 )
                column=3;%display('length');
            elseif (get(thresh_length_radio,'Value')==0 && get(thresh_width_radio,'Value')==1 && get(thresh_angle_radio,'Value')==0 && get(thresh_straight_radio,'Value')==0 )
                column=4;
            elseif(get(thresh_length_radio,'Value')==0 && get(thresh_width_radio,'Value')==0 && get(thresh_angle_radio,'Value')==1 && get(thresh_straight_radio,'Value')==0 )
                column=5;
            elseif(get(thresh_length_radio,'Value')==0 && get(thresh_width_radio,'Value')==0 && get(thresh_angle_radio,'Value')==0 && get(thresh_straight_radio,'Value')==1 )
                column=6;
            else
               set(status_text,'string','Please select only one parameter for top N or bottom N');
               return;
            end
            
            
            s1=size(fiber_indices,1);
            fiber_indices_copy=fiber_indices;
            
%             display(column);display(s1); %YL
            
            for i=1:s1-1
                for j=i+1:s1
                      if (fiber_indices_copy(j,2)<fiber_indices_copy(i,2))
                         temp=fiber_indices_copy(j,:);
                         fiber_indices_copy(j,:)=fiber_indices_copy(i,:);
                         fiber_indices_copy(i,:)=temp;
                         %display(fiber_indices_copy(j,:));display(temp);pause(1);
                      end
                end
            end
%             display(fiber_indices_copy);%pause(5); %YL
            
            zero_entries=0;
            for i=1:s1
                if(fiber_indices_copy(i,2)==0)
                    zero_entries=zero_entries+1;
                end
            end
            
            for i=zero_entries+1:s1-1
                for j=i+1:s1
                      if (fiber_indices_copy(j,column)<fiber_indices_copy(i,column))
                         temp=fiber_indices_copy(j,:);
                         fiber_indices_copy(j,:)=fiber_indices_copy(i,:);
                         fiber_indices_copy(i,:)=temp;
                         %display(fiber_indices_copy(j,:));display(temp);pause(1);
                      end
                end
            end
%             display(fiber_indices_copy);%pause(10);
            
            if(thresh_type_value==3)
                for i=1:s1
                   if(i<s1-top_or_bottom_N+1)
                      fiber_indices_copy(i,2)=0; 
                   else

                   end
                end
            elseif(thresh_type_value==4)
                for i=1:s1
                   if(i>zero_entries+top_or_bottom_N)
                      fiber_indices_copy(i,2)=0; 
                   else

                   end
                end
            end
            
%             display(fiber_indices_copy);%pause(5); %YL
            
            
            fiber_indices2=fiber_indices_copy;
         
            
        end
        % display(width_lower_bound);display(width_upper_bound);
        % display(length_lower_bound);display(length_upper_bound);
        %display(angle_lower_bound);display(angle_upper_bound);
        %display(straight_lower_bound);display(straight_upper_bound);
        
        
        if(thresh_type>2)
            for i=1:s2
                if(fiber_indices2(i,2)==1)
                    %fiber indices has length in 3rd column, width in 4th
                    %angle in 5th and straight in 6th
                    if(fiber_indices2(i,3)>=length_lower_bound&&fiber_indices2(i,3)<=length_upper_bound && fiber_indices2(i,4)>=width_lower_bound&&fiber_indices2(i,4)<=width_upper_bound &&fiber_indices2(i,5)>=angle_lower_bound&&fiber_indices2(i,5)<=angle_upper_bound && fiber_indices2(i,6)>=straight_lower_bound&&fiber_indices2(i,6)<=straight_upper_bound)
                        fiber_indices2(i,2)=1;% not necessary to do so coz it already is 1
                    else
                        fiber_indices2(i,2)=0;
                    end
                end
            end
        end
        % plot_fibers(fiber_indices2,'after thresholding',0);
        
        if (display_images_in_batchmode==1&&final_threshold==0)
                plot_fibers(fiber_indices2,horzcat(getappdata(guiCtrl,'filename'),'after thresholding'),0,1);
                visualisation2(fiber_indices2);
                display(final_threshold);
        end
       
        if(final_threshold==1)
            fiber_indices=[];
            fiber_indices=fiber_indices2;
            %YL: add plotflag2 to control the overlaid image output 
            if display_images_in_batchmode==1
                display(final_threshold);
                plot_fibers(fiber_indices2,horzcat(getappdata(guiCtrl,'filename'),'after thresholding'),0,1);
            end% write the data in the xls sheet
            
            if(getappdata(guiCtrl,'batchmode')==0)
                selected_fibers_xls_filename=fullfile(address,'selectout',[filename,'_statistics.xlsx']);
                C{1,1}=filename;
                
                C{2,1}='fiber numbers';C{2,2}='length';C{2,3}='width';C{2,4}='angle';C{2,5}='straightness';
                count=1;
                for i=1:s2
                    if(fiber_indices(i,2)==1)
                        C{count+2,1}=fiber_indices(i,1);
                        C{count+2,2}=fiber_indices(i,3);
                        C{count+2,3}=fiber_indices(i,4);
                        C{count+2,4}=fiber_indices(i,5);
                        C{count+2,5}=fiber_indices(i,6);
                        count=count+1;
                    end
                end
                if MAC == 1&&generate_raw_datasheet==1
                    xlwrite(selected_fibers_xls_filename,C,'Selected Fibers');
                    display('if condition');%pause(10);
                elseif MAC == 0&&generate_raw_datasheet==1
                    xlswrite(selected_fibers_xls_filename,C,'Selected Fibers');
%                     display('else condition');%pause(10);% YL
                end
            elseif(getappdata(guiCtrl,'batchmode')==1)
                % if batchmode is on then print the data on the same
                % xlsx file
                selected_fibers_batchmode_xls_filename=fullfile(address,'selectout',batchmode_statistics_modified_name);
                batchmode_length_raw{1,file_number_batch_mode}=filename;
                batchmode_width_raw{1,file_number_batch_mode}=filename;
                batchmode_angle_raw{1,file_number_batch_mode}=filename;
                batchmode_straight_raw{1,file_number_batch_mode}=filename;
                C{1,5*file_number_batch_mode-4}=filename;
                C{2,5*file_number_batch_mode-4}='fiber_numbers';
                C{2,5*file_number_batch_mode-3}='length';
                C{2,5*file_number_batch_mode-2}='width';
                C{2,5*file_number_batch_mode-1}='angle';
                C{2,5*file_number_batch_mode-0}='straightness';
                count=1;
               
                    for i=1:s2
                        if(fiber_indices(i,2)==1)
                            batchmode_length_raw{count+1,file_number_batch_mode}=fiber_indices(i,3);
                            batchmode_width_raw{count+1,file_number_batch_mode}=fiber_indices(i,4);
                            batchmode_angle_raw{count+1,file_number_batch_mode}=fiber_indices(i,5);
                            batchmode_straight_raw{count+1,file_number_batch_mode}=fiber_indices(i,6);
                            C{count+2,5*file_number_batch_mode-4}=fiber_indices(i,1);
                            C{count+2,5*file_number_batch_mode-3}=fiber_indices(i,3);%length
                            C{count+2,5*file_number_batch_mode-2}=fiber_indices(i,4);%width
                            C{count+2,5*file_number_batch_mode-1}=fiber_indices(i,5);%angle
                            C{count+2,5*file_number_batch_mode}=fiber_indices(i,6);%straight
                            count=count+1;
                        end
                    end
                   
%                     if (file_number_batch_mode==file_number)
%                         
%                         if MAC == 1
%                             
%                             %%YL: handle the maximum column of each sheet
%                             %%limitation (255 columns)
%                             Maxnumf = 50;  % maximum number of files in each sheets
%                             Cole    = 5;  % column for each file
%                             if file_number <=Maxnumf && generate_raw_datasheet==1 
%                                 xlwrite( selected_fibers_batchmode_xls_filename,C,sprintf('Combined Raw Data 1-%d',file_number));
%                             else
%                                 LastN = mod(file_number,Maxnumf);
%                                 if LastN == 0
%                                     Nsheets = floor(file_number/Maxnumf);
%                                 else
%                                     Nsheets = floor(file_number/Maxnumf) +1;
%                                 end
%                                 for i = 1:Nsheets
%                                     if i < Nsheets && generate_raw_datasheet==1
%                                         xlwrite( selected_fibers_batchmode_xls_filename,C(:,(i-1)*Maxnumf*Cole+1:i*Maxnumf*Cole),sprintf('Combined Raw Data %d-%d',(i-1)*Maxnumf+1,i*Maxnumf));
%                                     else
%                                         if LastN == 0  && generate_raw_datasheet==1 
%                                             xlwrite( selected_fibers_batchmode_xls_filename,C(:,(i-1)*Maxnumf*Cole+1:i*Maxnumf*Cole),sprintf('Combined Raw Data %d-%d',(i-1)*Maxnumf+1,i*Maxnumf));
%                                         elseif   generate_raw_datasheet==1 
%                                             xlwrite( selected_fibers_batchmode_xls_filename,C(:,(i-1)*Maxnumf*Cole+1:((i-1)*Maxnumf+LastN)*Cole),sprintf('Combined Raw Data %d-%d',(i-1)*Maxnumf+1,(i-1)*Maxnumf+LastN));
%                                         end
%                                     end
%                                 end
%                                 
%                                 
%                             end
%                             
%                             if (generate_raw_datasheet==1)
%                             xlwrite( selected_fibers_batchmode_xls_filename,batchmode_length_raw,'Length Data');
%                             xlwrite( selected_fibers_batchmode_xls_filename,batchmode_width_raw,'Width Data');
%                             xlwrite( selected_fibers_batchmode_xls_filename,batchmode_angle_raw,'Angle Data');
%                             xlwrite( selected_fibers_batchmode_xls_filename,batchmode_straight_raw,'Straight Data');
%                             end
%                             
%                         else
%                             
%                             % 						xlswrite( selected_fibers_batchmode_xls_filename,C,'Combined Raw Data');
%                             
%                             %%YL: handle the maximum column of each sheet
%                             %%limitation (255 columns)
%                             Maxnumf = 50;  % maximum number of files in each sheets
%                             Cole    = 5;  % column for each file
%                             if file_number <=Maxnumf  && generate_raw_datasheet==1 
%                                 xlswrite( selected_fibers_batchmode_xls_filename,C,sprintf('Combined Raw Data 1-%d',file_number));
%                             else
%                                 LastN = mod(file_number,Maxnumf);
%                                 if LastN == 0
%                                     Nsheets = floor(file_number/Maxnumf);
%                                 else
%                                     Nsheets = floor(file_number/Maxnumf) +1;
%                                 end
%                                 for i = 1:Nsheets
%                                     if i < Nsheets  && generate_raw_datasheet==1 
%                                         xlswrite( selected_fibers_batchmode_xls_filename,C(:,(i-1)*Maxnumf*Cole+1:i*Maxnumf*Cole),sprintf('Combined Raw Data %d-%d',(i-1)*Maxnumf+1,i*Maxnumf));
%                                     else
%                                         if LastN == 0  && generate_raw_datasheet==1 
%                                             xlswrite( selected_fibers_batchmode_xls_filename,C(:,(i-1)*Maxnumf*Cole+1:i*Maxnumf*Cole),sprintf('Combined Raw Data %d-%d',(i-1)*Maxnumf+1,i*Maxnumf));
%                                         elseif(generate_raw_datasheet==1)
%                                             xlswrite( selected_fibers_batchmode_xls_filename,C(:,(i-1)*Maxnumf*Cole+1:((i-1)*Maxnumf+LastN)*Cole),sprintf('Combined Raw Data %d-%d',(i-1)*Maxnumf+1,(i-1)*Maxnumf+LastN));
%                                         end
%                                     end
%                                 end
%                             end
%                             
%                             if(generate_raw_datasheet==1)
%                             xlswrite( selected_fibers_batchmode_xls_filename,batchmode_length_raw,'Length Data');
%                             xlswrite( selected_fibers_batchmode_xls_filename,batchmode_width_raw,'Width Data');
%                             xlswrite( selected_fibers_batchmode_xls_filename,batchmode_angle_raw,'Angle Data');
%                             xlswrite( selected_fibers_batchmode_xls_filename,batchmode_straight_raw,'Straight Data');
%                             end
%                         end
%                     end
%% save the results to the excel file after each image is analyzed
               
                    fnbm = file_number_batch_mode; % 
                    
                    if MAC == 1

                                                %%YL: handle the maximum column of each sheet
                        %%limitation (255 columns)
%                        
%                         Maxnumf = 2;  % maximum number of files in each sheets
%                         Cole    = 5;  % column for each file
                        
                        if generate_raw_datasheet==1
                            ish = ceil(fnbm/Maxnumf);   % image belows to "ish" th sheet for the combined raw data
                            if mod(fnbm, Maxnumf) == 0
                                cstr = (Maxnumf-1)*Cole + 1;   % column start position
                            else
                                cstr = (mod(fnbm, Maxnumf) -1)*Cole + 1;
                            end
                            ctemp = C(:,(fnbm-1)*5+1:fnbm*5); % YL: test the memory issue
                            
                            xlwrite( selected_fibers_batchmode_xls_filename,ctemp,crsname{ish},strcat(COLL{cstr},'1'));
                            xlwrite( selected_fibers_batchmode_xls_filename,batchmode_length_raw(:,file_number_batch_mode),'Length Data',strcat(COLL{file_number_batch_mode},'1'));
                            xlwrite( selected_fibers_batchmode_xls_filename,batchmode_width_raw(:,file_number_batch_mode),'Width Data',strcat(COLL{file_number_batch_mode},'1'));
                            xlwrite( selected_fibers_batchmode_xls_filename,batchmode_angle_raw(:,file_number_batch_mode),'Angle Data',strcat(COLL{file_number_batch_mode},'1'));
                            xlwrite( selected_fibers_batchmode_xls_filename,batchmode_straight_raw(:,file_number_batch_mode),'Straight Data',strcat(COLL{file_number_batch_mode},'1'));
                            
                            clear ctemp;
                        end
                    
                    else  % use xls write
% YL: replace xlswrite  with xlwrite  
                        % 						xlswrite( selected_fibers_batchmode_xls_filename,C,'Combined Raw Data');

                        %%YL: handle the maximum column of each sheet
                        %%limitation (255 columns)
%                        
%                         Maxnumf = 2;  % maximum number of files in each sheets
%                         Cole    = 5;  % column for each file
                        
                        if generate_raw_datasheet==1
                            ish = ceil(fnbm/Maxnumf);   % image belows to "ish" th sheet for the combined raw data
                            if mod(fnbm, Maxnumf) == 0
                                cstr = (Maxnumf-1)*Cole + 1;   % column start position
                            else
                                cstr = (mod(fnbm, Maxnumf) -1)*Cole + 1;
                            end
                            xlswrite( selected_fibers_batchmode_xls_filename,C(:,(fnbm-1)*5+1:fnbm*5),crsname{ish},strcat(COLL{cstr},'1'));
                            xlswrite( selected_fibers_batchmode_xls_filename,batchmode_length_raw(:,file_number_batch_mode),'Length Data',strcat(COLL{file_number_batch_mode},'1'));
                            xlswrite( selected_fibers_batchmode_xls_filename,batchmode_width_raw(:,file_number_batch_mode),'Width Data',strcat(COLL{file_number_batch_mode},'1'));
                            xlswrite( selected_fibers_batchmode_xls_filename,batchmode_angle_raw(:,file_number_batch_mode),'Angle Data',strcat(COLL{file_number_batch_mode},'1'));
                            xlswrite( selected_fibers_batchmode_xls_filename,batchmode_straight_raw(:,file_number_batch_mode),'Straight Data',strcat(COLL{file_number_batch_mode},'1'));
                        end
                    end
     
                
            end
            
        else
            % YL
            % GSM - done before the if condition
            %if display_images_in_batchmode==1
             %   plot_fibers(fiber_indices2,horzcat(getappdata(guiCtrl,'filename'),'after thresholding'),0,1);
            %end
        end
    end

    function threshold_final_fn(hObject,eventdata,handles)
        final_threshold=1;
        threshold_now();
        set(status_text,'String','Select from Length Width Straight and/or Angle');
        
        set([use_threshold_checkbox use_threshold_text thresh_type threshold_final_button],'enable','off');
        set([thresh_length_radio thresh_width_radio thresh_straight_radio thresh_angle_radio],'enable','off');
        set([text_length text_width text_straight text_angle],'enable','off');
        set([thresh_length_start thresh_length_to thresh_length_end thresh_length_unit],'enable','off');
        set([thresh_width_start thresh_width_to thresh_width_end thresh_width_unit],'enable','off');
        set([thresh_straight_start thresh_straight_to thresh_straight_end thresh_straight_unit],'enable','off');
        set([thresh_angle_start thresh_angle_to thresh_angle_end thresh_angle_unit],'enable','off');
        set([threshold_now_button visualise_fiber_button],'enable','off');
        
    end


    function[]=generate_stats_popupwindow(hObject,eventsdata,handles)
         
        set(status_text,'String','Deselect/Select Statistics');
        position=get(guiCtrl,'Position');
        left=position(1);bottom=position(2);width=position(3);height=position(4);
        
        gs_panel=figure('Units','pixels','Position',[left+width+15 bottom 250 250],'Menubar','none','NumberTitle','off','Name','Select Stats','Visible','on','Color',defaultBackground);
        
        output_stats_panel=uipanel('Parent',gs_panel,'Title','Output Stats','Units','normalized','Position',[0 0 1 0.85]);
        dialogue_text=uicontrol('Parent',gs_panel,'Style','text','Units','normalized','Position',[0 0.86 1 0.13],'String','Select/ Deselect desired output stats');
        median_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0 0.85 0.1 0.1],'Callback',@stats_of_median_fn,'Value',1);
        median_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.06 0.66 0.21 0.28],'String','Median');
        
        mode_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.31 0.85 0.1 0.1],'Callback',@stats_of_mode_fn,'Value',1);
        mode_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.41 0.66 0.11 0.28],'String','Mode');
        
        
        mean_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.58 0.85 0.1 0.1],'Callback',@stats_of_mean_fn,'Value',1);
        mean_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.68 0.66 0.11 0.28],'String','Mean');
        
        variance_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.0 0.54 0.1 0.1],'Callback',@stats_of_variance_fn,'Value',1);
        variance_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.06 0.35 0.21 0.28],'String','Variance');
        
        std_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.31 0.54 0.1 0.1],'Callback',@stats_of_std_fn,'Value',1);
        std_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.41 0.35 0.21 0.28],'String','Std dev');
        
        
        min_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.62 0.54 0.1 0.1],'Callback',@stats_of_min_fn,'Value',1);
        min_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.68 0.35 0.11 0.28],'String','Min');
        
        max_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.0 0.25 0.1 0.1],'Callback',@stats_of_max_fn,'Value',1);
        max_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.06 0.11 0.21 0.28],'String','Max');
        
        numfiber_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.31 0.25 0.1 0.1],'Callback',@stats_of_numfiber_fn,'Value',1);
        numfiber_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.36 0.11 0.25 0.28],'String','number of fibers');
        
        alignment_radio=uicontrol('Parent',output_stats_panel,'Style','radiobutton','Units','normalized','Position',[0.6 0.25 0.1 0.1 ],'Callback',@stats_of_alignment_fn,'Value',1);
        alignment_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.7 0.25 0.21 0.1],'String','Alignment');
        
        produce_stats=uicontrol('Parent',output_stats_panel,'Style','pushbutton','Units','normalized','Position',[0 0 0.45 0.22],'string','Ok','Callback',@generate_stats_final);
        generate_raw_datasheet_checkbox=uicontrol('Parent',output_stats_panel,'Style','checkbox','Units','normalized','Position',[0.5 0.1 0.1 0.1],'Callback',@generate_raw_datasheet_fn);
        generate_raw_datasheet_text=uicontrol('Parent',output_stats_panel,'Style','text','Units','normalized','Position',[0.58 0 0.36 0.22],'String','Generate sheet for raw data');
        if(generate_raw_datasheet==1)
            set(generate_raw_datasheet_checkbox,'Value',1);
        end
        
        function[]=stats_of_median_fn(hObject,eventsdata,handles)
            
            if(get(hObject,'Value')==1)
                stats_of_median=1;
            else
                stats_of_median=0;
            end
        end
        
        function[]=stats_of_mode_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_mode=1;
            else
                stats_of_mode=0;
            end
        end
        
        function[]=stats_of_mean_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_mean=1;
            else
                stats_of_mean=0;
            end
        end
        
        function[]=stats_of_variance_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_variance=1;
            else
                stats_of_variance=0;
            end
        end
        
        function[]=stats_of_std_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_std=1;
            else
                stats_of_std=0;
            end
        end
        
        function[]=stats_of_min_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_min=1;
            else
                stats_of_min=0;
            end
        end
        
        function[]=stats_of_max_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_max=1;
            else
                stats_of_max=0;
            end
        end
        
        function[]=stats_of_numfiber_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_numfibers=1;
            else
                stats_of_numfibers=0;
            end
        end
        
        function[]=stats_of_alignment_fn(hObject,eventsdata,handles)
            if(get(hObject,'Value')==1)
                stats_of_alignment=1;
            else
                stats_of_alignment=0;
            end
        end
        
        
    end

    function[C]= generate_stats_final(hObject,eventsdata,handles)
        
        tic
        close;% one close for generated picture and one close for generate popup window
        % display('I am in');
      % GSM - closing all previously opened figures
      
        %%figures = findall(0,'type','figure');
        %size_figures=size(figures);
        %for k=2:size_figures
            %close(figures(k));
          % pause(2);
        %end
        % GSM - closing of figures ends
        
        %opening a new figure to show statistics
        measure_fig = figure('Resize','off','Units','pixels','Position',[50 50 470 300],'Visible','off','MenuBar','none','name','Measure Data','NumberTitle','off','UserData',0);
        measure_table=uitable('Parent',measure_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);
       
        D2{1,2}='Mean Values';D2{2,1}='Parameters';
        D2{2,2}='Length';D2{2,3}='Width';D2{2,4}='Straightness';D2{2,5}='Angle';
        set(status_text,'String','Generating stats');
        
        if(getappdata(guiCtrl,'batchmode')==0)
            filename=getappdata(guiCtrl,'filename');
            C{1,2}=filename; 
            C{2,1}='Parameters';
           
            D2{3,1}=filename;
            i=3;j=1;
            if stats_of_median==1
                C{i,j}='Median';i=i+1;
            end
            if stats_of_mode==1
                C{i,j}='Mode';i=i+1;
            end
            if stats_of_mean==1
                C{i,j}='Mean';i=i+1;
            end
            if stats_of_variance==1
                C{i,j}='Variance';i=i+1;
            end
            if stats_of_std==1
                C{i,j}='Standard Deviation';i=i+1;
            end
            if stats_of_min==1
                C{i,j}='Min';i=i+1;
            end
            if stats_of_max==1
                C{i,j}='Max';i=i+1;
            end
            if stats_of_numfibers==1
                C{i,j}='Number of Fibers';i=i+1;
            end
            
            if stats_of_alignment==1
                C{i,j}='Alignment';i=i+1;
            end
            
            %data_width=B(:,1);data_length=B(:,2);data_angle=B(:,3);data_straight=B(:,4);
            s3=size(fiber_indices,1);
            count=1;
            for i=1:s3
                if(fiber_indices(i,2)==1)
                    data_length(count,1)=fiber_indices(i,3);
                    data_width(count,1)=fiber_indices(i,4);
                    data_angle(count,1)=fiber_indices(i,5);
                    data_straight(count,1)=fiber_indices(i,6);
                    count=count+1;
                end
            end
            D2{3,2}=mean(data_length);
            D2{3,3}=mean(data_width);
            D2{3,4}=mean(data_angle);
            D2{3,5}=mean(data_straight);
            set(measure_table,'Data',D2);
            set(measure_fig,'Visible','on');
            i=2;j=2;
            %display(stats_for_width);
            
            if stats_for_width==1
                C{i,j}='Width';
                outarray=make_stats(data_width,'width');
                
                outarray=transpose(outarray);
                s2=size(outarray);
                %display(outarray);display(size(outarray));
                for k=1:s2
                    C{2+k,j}=outarray(k,1);
                    %display(outarray(k,1));
                end
                j=j+1;
            end
            
            if stats_for_length==1
                C{i,j}='Length';
                outarray=make_stats(data_length,'length');
                
                outarray=transpose(outarray);
                s2=size(outarray);
                % display(outarray);display(size(outarray));
                for k=1:s2
                    C{2+k,j}=outarray(k,1);
                    %display(outarray(k,1));
                end
                j=j+1;
            end
            
            if stats_for_angle==1
                C{i,j}='Angle';
                outarray=make_stats(data_angle,'angle');
                
                outarray=transpose(outarray);
                s2=size(outarray);
                %display(outarray);display(size(outarray));
                for k=1:s2
                    C{2+k,j}=outarray(k,1);
                    %display(outarray(k,1));
                end
                j=j+1;
            end
            
            if stats_for_straight==1
                C{i,j}='Straightness';
                outarray=make_stats(data_straight,'straight');
                
                outarray=transpose(outarray);
                s2=size(outarray);
                %display(outarray);display(size(outarray));
                for k=1:s2
                    C{2+k,j}=outarray(k,1);
                    %display(outarray(k,1));
                end
                j=j+1;
            end
            if MAC == 1
                xlwrite(fullfile(address,'selectout',[getappdata(guiCtrl,'filename'),'_statistics.xlsx']),C,'statistics');
            else
                xlswrite(fullfile(address,'selectout',[getappdata(guiCtrl,'filename'),'_statistics.xlsx']),C,'statistics');
            end
            
            %if(get(thresh_length_radio,'Value')==0&&get(thresh_angle_radio,'Value')==0&&get(thresh_width_radio,'Value')==0&&get(thresh_straight_radio,'Value')==0)
                final_threshold=1;
                threshold_now;
                
            %end
            % combined_stats start
            %combined_stats(1,1,1)={'length'};combined_stats(1,1,2)={'width'};combined_stats(1,1,3)={'angle'};combined_stats(1,1,4)={'straightness'};
            %for i=1:4
            %combined_stats(2,1,i)={'Median'};
            %combined_stats(3,1,i)={'Mode'};
            %combined_stats(4,1,i)={'Mean'};
            %combined_stats(5,1,i)={'Variance'};
            %combined_stats(6,1,i)={'Standard Deviation'};
            %combined_stats(7,1,i)={'Minimum'};
            % combined_stats(8,1,i)={'Maximum'};
            %combined_stats(9,1,i)={'Number Of Fibers'};
            %combined_stats(10,1,i)={'Alignment'};
            %end
            
            %writing data now - using - filename , data_length
            %.data_width data_straight data_angle
            
            % No sense starts
            %for i=1:4
            %if(i==1)
            % data=data_length;
            %elseif(i==2)
            % data=data_width;
            % elseif(i==3)
            % data=data_angle;
            %elseif(i==4)
            % data=data_straight;
            % end
            
            %combined_stats(1,combined_stats_index+1,i)={filename};
            %combined_stats(2,combined_stats_index+1,i)={median(data)};
            %combined_stats(3,combined_stats_index+1,i)={mode(data)};
            % combined_stats(4,combined_stats_index+1,i)={mean(data)};
            % combined_stats(5,combined_stats_index+1,i)={var(data)};
            % combined_stats(6,combined_stats_index+1,i)={std(data)};
            % combined_stats(7,combined_stats_index+1,i)={min(data)};
            % combined_stats(8,combined_stats_index+1,i)={max(data)};
            % combined_stats(9,combined_stats_index+1,i)={size(data,1)};
            % if(i==3)
            %combined_stats(10,combined_stats_index+1,i)={find_alignment(data)};
            % end
            %if(combined_stats_index==file_number)
            %display(combined_stats);
            
            % xlswrite(horzcat(address,'batchmode_combined_stats'),combined_stats(:,:,1),'Length');
            % xlswrite(horzcat(address,'batchmode_combined_stats'),combined_stats(:,:,2),'width');
            % xlswrite(horzcat(address,'batchmode_combined_stats'),combined_stats(:,:,3),'Angle');
            % xlswrite(horzcat(address,'batchmode_combined_stats'),combined_stats(:,:,4),'Straightness');
            % No sense ends
            %end
            % end
            % combined_stats end
            % for closing Generate Stats subwindow
            matdata2=matdata;
            
            matdata2.data.PostProGUI.use_threshold=get(use_threshold_checkbox,'Value');
            matdata2.data.PostProGUI.threshold_type=get(thresh_type,'Value');
            matdata2.data.PostProGUI.thresh_length_radio=get(thresh_length_radio,'Value');
            matdata2.data.PostProGUI.thresh_width_radio=get(thresh_width_radio,'Value');
            matdata2.data.PostProGUI.thresh_angle_radio=get(thresh_angle_radio,'Value');
            matdata2.data.PostProGUI.straight_length_radio=get(thresh_straight_radio,'Value');
            
            matdata2.data.PostProGUI.thresh_length_start=str2num(get(thresh_length_start,'String'));
            matdata2.data.PostProGUI.thresh_width_start=str2num(get(thresh_width_start,'String'));
            matdata2.data.PostProGUI.thresh_straight_start=str2num(get(thresh_straight_start,'String'));
            matdata2.data.PostProGUI.thresh_angle_start=str2num(get(thresh_angle_start,'String'));
            
            matdata2.data.PostProGUI.thresh_length_end=str2num(get(thresh_length_end,'String'));
            matdata2.data.PostProGUI.thresh_width_end=str2num(get(thresh_width_end,'String'));
            matdata2.data.PostProGUI.thresh_straight_end=str2num(get(thresh_straight_end,'String'));
            matdata2.data.PostProGUI.thresh_angle_end=str2num(get(thresh_angle_end,'String'));
            
            matdata2.data.PostProGUI.stats_for_length_radio=get(stats_for_length_radio,'Value');
            matdata2.data.PostProGUI.stats_for_width_radio=get(stats_for_width_radio,'Value');
            matdata2.data.PostProGUI.stats_for_straight_radio=get(stats_for_straight_radio,'Value');
            matdata2.data.PostProGUI.stats_for_angle_radio=get(stats_for_angle_radio,'Value');
            
            matdata2.data.PostProGUI.stats_of_median=stats_of_median;
            matdata2.data.PostProGUI.stats_of_mode=stats_of_mode;
            matdata2.data.PostProGUI.stats_of_mean=stats_of_mean;
            matdata2.data.PostProGUI.stats_of_variance=stats_of_variance;
            matdata2.data.PostProGUI.stats_of_std=stats_of_std;
            matdata2.data.PostProGUI.stats_of_numfibers=stats_of_numfibers;
            matdata2.data.PostProGUI.stats_of_max=stats_of_max;
            matdata2.data.PostProGUI.stats_of_min=stats_of_min;
            matdata2.data.PostProGUI.stats_of_alignment=stats_of_alignment;
            matdata2.data.PostProGUI.fiber_indices=fiber_indices;
            matdata2.data.PostProGUI.removed_fibers=removed_fibers;
            matdata=matdata2;
            % 07-18-14YL: don't change the structure of the original
            % ctFIRE*.mat, just add the addtional one
            load(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data');
            data.PostProGUI = matdata2.data.PostProGUI;
            save(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data','-append');
            

            
        elseif(getappdata(guiCtrl,'batchmode')==1)
            %close;%to close the popup window of generate fibers
            filenames=getappdata(guiCtrl,'batchmode_filename');
            display('in generate_stats_final');
%             display(filenames);
            s1=size(filenames,2);
            setappdata(guiCtrl,'batchmode_combined_stats_xlsfilename',fullfile(address,'selectout',batchmode_statistics_modified_name));
            for j=1:s1
                file_number=j;
                % here the filename and format is separated in from fil
                % like testimage1.tif
                disp(sprintf('Analyzing the %d  / %d image, %s\n',j,s1,filenames{j})); %YL: show the process  
                filename_trash=filenames{j};
                file_number_batch_mode=j;
                kip_index=strfind(filename_trash,'.');
                kip_index=kip_index(end);
                filename=filename_trash(1:kip_index-1);
                D2{2+j,1}=filename;
                format=filename_trash(kip_index:end);
                setappdata(guiCtrl,'filename',filename);
                setappdata(guiCtrl,'format',format);
                
%yl               
               if(get(stack_box,'Value')== 0)  % multiple images
                  a=imread(fullfile(address,[filename,getappdata(guiCtrl,'format')]));

               elseif (get(stack_box,'Value')== 1)   % stack(s)
                    filenamestack{slicestack(j)}
                    slicenumber(j)
                   a = imread(fullfile (address,filenamestack{slicestack(j)}),slicenumber(j));
               end
                   
     
      %          a=imread(fullfile(address,[filename,getappdata(guiCtrl,'format')]));
                if size(a,3)==4
                    %check for rgb
                    a=a(:,:,1:3);
                end
                if(display_images_in_batchmode==1)
                    gcf= figure('name',filename,'NumberTitle','off');imshow(a);
                end
                matdata=[];
                matdata=importdata(fullfile(address,'ctFIREout',['ctFIREout_',filename,'.mat']));
                %display(matdata);
                
                % s1 indicates the number of fibers in the .mat file
                s2=size(matdata.data.Fa,2);
                
                % assigns 1 to all fibers initially -INITIALIZATION
                fiber_indices=[];
                for i=1:s2
                    fiber_indices(i,1)=i; fiber_indices(i,2)=1; fiber_indices(i,3)=0;
                end
                
                % s2 is the length threshold used in the ctFIRE
                ctFIRE_length_threshold=matdata.cP.LL1;
                %if length of the fiber is less than the threshold s2 then
                %assign 0 to that fiber
                
                
                %Now fiber indices will have the following columns=
                % column1 - fiber number column2=visile(if ==1)
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
                count=1;
                
                for i=1:s2
                    %display(fiber_length_fn(i));
                    %pause(0.5);
                    if(fiber_length_fn(i)<= ctFIRE_length_threshold) %YL: change from "<" to "<="  to be consistent with original ctFIRE_1
                        fiber_indices(i,2)=0;
                        
                        fiber_indices(i,3)=0;%length;
                        fiber_indices(i,4)=0;%width
                        fiber_indices(i,5)=0;%angle
                        fiber_indices(i,6)=0;%straight
                    else
                        fiber_indices(i,2)=1;
                        fiber_indices(i,3)=fiber_length(count);
                        fiber_indices(i,4)=fiber_width(count);
                        fiber_indices(i,5)=fiber_angle(count);
                        fiber_indices(i,6)=fiber_straight(count);
%                         fiber_length2(count)=fiber_length(count);
%                         fiber_width2(count)=fiber_width(count);
%                         fiber_angle2(count)=fiber_angle(count);
%                         fiber_length2(count)=fiber_length(count);
                        count=count+1;
                    end
                    
                end
                final_threshold=1;
                threshold_now;
                generate_stats_batchmode();
                
                matdata2=matdata;
                
                matdata2.data.PostProGUI.use_threshold=get(use_threshold_checkbox,'Value');
                matdata2.data.PostProGUI.threshold_type=get(thresh_type,'Value');
                matdata2.data.PostProGUI.thresh_length_radio=get(thresh_length_radio,'Value');
                matdata2.data.PostProGUI.thresh_width_radio=get(thresh_width_radio,'Value');
                matdata2.data.PostProGUI.thresh_angle_radio=get(thresh_angle_radio,'Value');
                matdata2.data.PostProGUI.straight_length_radio=get(thresh_straight_radio,'Value');
                
                matdata2.data.PostProGUI.thresh_length_start=str2num(get(thresh_length_start,'String'));
                matdata2.data.PostProGUI.thresh_width_start=str2num(get(thresh_width_start,'String'));
                matdata2.data.PostProGUI.thresh_straight_start=str2num(get(thresh_straight_start,'String'));
                matdata2.data.PostProGUI.thresh_angle_start=str2num(get(thresh_angle_start,'String'));
                
                matdata2.data.PostProGUI.thresh_length_end=str2num(get(thresh_length_end,'String'));
                matdata2.data.PostProGUI.thresh_width_end=str2num(get(thresh_width_end,'String'));
                matdata2.data.PostProGUI.thresh_straight_end=str2num(get(thresh_straight_end,'String'));
                matdata2.data.PostProGUI.thresh_angle_end=str2num(get(thresh_angle_end,'String'));
                
                matdata2.data.PostProGUI.stats_for_length_radio=get(stats_for_length_radio,'Value');
                matdata2.data.PostProGUI.stats_for_width_radio=get(stats_for_width_radio,'Value');
                matdata2.data.PostProGUI.stats_for_straight_radio=get(stats_for_straight_radio,'Value');
                matdata2.data.PostProGUI.stats_for_angle_radio=get(stats_for_angle_radio,'Value');
                
                matdata2.data.PostProGUI.stats_of_median=stats_of_median;
                matdata2.data.PostProGUI.stats_of_mode=stats_of_mode;
                matdata2.data.PostProGUI.stats_of_mean=stats_of_mean;
                matdata2.data.PostProGUI.stats_of_variance=stats_of_variance;
                matdata2.data.PostProGUI.stats_of_std=stats_of_std;
                matdata2.data.PostProGUI.stats_of_numfibers=stats_of_numfibers;
                matdata2.data.PostProGUI.stats_of_max=stats_of_max;
                matdata2.data.PostProGUI.stats_of_min=stats_of_min;
                matdata2.data.PostProGUI.stats_of_alignment=stats_of_alignment;
                matdata2.data.PostProGUI.fiber_indices=fiber_indices;
                matdata2.data.PostProGUI.removed_fibers=removed_fibers;
                matdata=matdata2;
                
                % 07-18-14YL: don't change the structure of the original
                % ctFIRE*.mat, just add the addtional one
                load(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data');
                data.PostProGUI = matdata2.data.PostProGUI;
                save(fullfile(address,'ctFIREout',['ctFIREout_',getappdata(guiCtrl,'filename'),'.mat']),'data','-append');
                
            end
            set(measure_table,'Data',D2);
            set(measure_fig,'Visible','on');
            %%YL: save the D for each individual image 
            %%YL: for MC output
%             if MAC == 1
%                 xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,1),'length statistics');
%                 xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,2),'width statistics');
%                 xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,3),'straight statistics');
%                 xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,4),'angle statistics');
%             else
%                 
%                 xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,1),'length statistics');
%                 xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,2),'width statistics');
%                 xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,3),'straight statistics');
%                 xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,:,4),'angle statistics');
%             end
        end
        
        set(status_text,'String','Stats Generated');
        disp('Done!')
        toc
    end

    function[]=generate_stats_batchmode()
        
        
        filename=getappdata(guiCtrl,'filename');
        s3=size(fiber_indices,1);
%         display(s3);%pause(3); YL
        count=0;
        for i=1:s3
            if(fiber_indices(i,2)==1)
                count=count+1;
                data_length(count,1)=fiber_indices(i,3);
                data_width(count,1)=fiber_indices(i,4);
                data_angle(count,1)=fiber_indices(i,5);
                data_straight(count,1)=fiber_indices(i,6);
                
            end
        end
        % display(data_length);pause(3);
        %display(data_width);pause(3);
        %display(data_angle);pause(3);
        %display(data_straight);pause(3);
        
        if(file_number_batch_mode==1)
            
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
                D2{2+file_number,k+1}=mean(data);
                D{file_number_batch_mode,2,k}=filename;
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
            
            
            
        elseif(file_number_batch_mode>1&&file_number_batch_mode<=file_number)
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
                D2{2+file_number,k+1}=mean(data);
                D{1,file_number_batch_mode+1,k}=filename;
                if stats_of_median==1
                    %D{a,1,k}='Median';
                    D{a,file_number_batch_mode+1,k}=median(data);
                    a=a+1;
                end
                if stats_of_mode==1
                    %D{a,1,k}='Mode';
                    D{a,file_number_batch_mode+1,k}=mode(data);
                    a=a+1;
                end
                if stats_of_mean==1
                    %D{a,1,k}='Mean';
                    D{a,file_number_batch_mode+1,k}=mean(data);
                    a=a+1;
                end
                if stats_of_variance==1
                    %D{a,1,k}='Variance';
                    D{a,file_number_batch_mode+1,k}=var(data);
                    a=a+1;
                end
                if stats_of_std==1
                    %D{a,1,k}='Standard Deviation';
                    D{a,file_number_batch_mode+1,k}=std(data);
                    a=a+1;
                end
                if stats_of_min==1
                    %D{a,1,k}='Min';
                    D{a,file_number_batch_mode+1,k}=min(data);
                    a=a+1;
                end
                if stats_of_max==1
                    %D{a,1,k}='Max';
                    D{a,file_number_batch_mode+1,k}=max(data);
                    a=a+1;
                end
                if stats_of_numfibers==1
                    %D{a,1,k}='Number of Fibers';
                    D{a,file_number_batch_mode+1,k}=count;
                    a=a+1;
                end
                
                if stats_of_alignment==1 &&stats_for_angle==1&&k==4
                    %D{a,1,k}='Alignment';
                    D{a,file_number_batch_mode+1,k}=find_alignment(data);
                    a=a+1;
                end
                
               % display(D(:,:,1));%pause(3);
            end
            
            
        end
        
        if MAC == 1
            if file_number_batch_mode == 1
                xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,1),'length statistics');
                xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,2),'width statistics');
                xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,3),'straight statistics');
                xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,4),'angle statistics');
            end
            xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,1),'length statistics',strcat(COLL{file_number_batch_mode+1},'1'));
            xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,2),'width statistics',strcat(COLL{file_number_batch_mode+1},'1'));
            xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,3),'straight statistics',strcat(COLL{file_number_batch_mode+1},'1'));
            xlwrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,4),'angle statistics',strcat(COLL{file_number_batch_mode+1},'1'));
        else
             if file_number_batch_mode == 1
                xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,1),'length statistics');
                xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,2),'width statistics');
                xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,3),'straight statistics');
                xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode,4),'angle statistics');
            end
            xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,1),'length statistics',strcat(COLL{file_number_batch_mode+1},'1'));
            xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,2),'width statistics',strcat(COLL{file_number_batch_mode+1},'1'));
            xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,3),'straight statistics',strcat(COLL{file_number_batch_mode+1},'1'));
            xlswrite(fullfile(address,'selectout',batchmode_statistics_modified_name),D(:,file_number_batch_mode+1,4),'angle statistics',strcat(COLL{file_number_batch_mode+1},'1'));
        end
    end

    function [outarray]=make_stats(inarray,parameter)
        
        i=1;
        if stats_of_median==1
            outarray(i)=median(inarray);i=i+1;
        end
        
        if stats_of_mode==1
            outarray(i)=mode(inarray);i=i+1;
        end
        
        if stats_of_mean==1
            outarray(i)=mean(inarray);i=i+1;
        end
        
        if stats_of_variance==1
            outarray(i)=var(inarray);i=i+1;
        end
        
        if stats_of_std==1
            outarray(i)=std(inarray);i=i+1;
        end
        
        if stats_of_min==1
            outarray(i)=min(inarray);i=i+1;
        end
        
        if stats_of_max==1
            outarray(i)=max(inarray);i=i+1;
        end
        
        if stats_of_numfibers==1
            outarray(i)=size(inarray,1);i=i+1;
        end
        
        if stats_of_alignment==1&&strcmp(parameter,'angle')
            outarray(i)=find_alignment(inarray);
        end
    end

    function[alignment]=find_alignment(angles)
        %Author- Guneet Singh Mehta Summer Research Intern UW Madison Indian
        %Institute of Technology Jodhpur
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

    function batchmode_fn(hObject,eventsdata,handles)
        
        parent=get(hObject,'Parent');
        if(get(hObject,'value')==1)
%             set(generate_stats_button,'enable','on'); %YL
            set([visualise_fiber_button removefibers_box],'enable','off');
            
            setappdata(guiCtrl,'batchmode',1);
            
            set(status_text,'String','Select Files [Batchmode Selected]');
            % set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text generate_stats_button],'enable','on');
            % set(generate_stats_button,'enable','on');
        else
            set(generate_stats_button,'enable','off');
            setappdata(guiCtrl,'batchmode',0);
            
            set(status_text,'String','Select Files [Batchmode Not Selected]');
            %set([stats_for_length_radio stats_for_length_text stats_for_width_radio stats_for_width_text stats_for_straight_radio stats_for_straight_text stats_for_angle_radio stats_for_angle_text generate_stats_button],'enable','off');
            %set(generate_stats_button,'enable','off');
        end
        position_of_postpgui=get(guiCtrl,'Position');
%         display(position_of_postpgui); % YL
        
        if(get(hObject,'value')==1)
            left=position_of_postpgui(1);
            bottom=position_of_postpgui(2);
            popupwindow=figure('Units','Pixels','position',[left+70 bottom+560 350 80],'Menubar','none','NumberTitle','off','Name','Analysis Module','Visible','on','Color',defaultBackground);
            %stats_for_angle_radio=uicontrol('Parent',stats_for_panel,'Style','radiobutton','Units','normalized','Position',[0.75 0 0.08 1],'Callback',@stats_for_angle_fn,'enable','off','Value',1);
            dialogue=uicontrol('Parent',popupwindow,'Style','text','Units','normalized','Position',[0.05 0.5 0.9 0.45],'String','Display Images in Batchmode ?');
            yes_box=uicontrol('Parent',popupwindow,'Style','pushbutton','Units','normalized','Position',[0.05 0.05 0.4 0.4],'String','Yes','Callback',@yes_fn);
            no_box=uicontrol('Parent',popupwindow,'Style','pushbutton','Units','normalized','Position',[0.5 0.05 0.4 0.4],'String','NO','Callback',@no_fn);
         end
        
        function[]=yes_fn(hObject,handles,eventsdata)
           display_images_in_batchmode=1; 
%            display(display_images_in_batchmode);
           disp('Overlaid images will be generated and displayed in this analysis'); % YL
           close;
        end
        
        function[]=no_fn(hObject,handles,eventsdata)
            display_images_in_batchmode=0;
%             display(display_images_in_batchmode);
            disp('NO overlaid image will be generated and displayed in this analysis'); %YL
            close;
        end
        
        
    end

    function[slices_filename]=stack_to_slices(local_filename,local_address)
        
        a=imfinfo([local_address local_filename]);
        s1=size(a,1);
        kip=strfind(local_filename,'.');
        kip=kip(end);
        local_filename2=local_filename(1:kip-1);
        display(s1);
        for i=1:s1
            a=imread([local_address local_filename],i);
            slices_filename(i)={horzcat(local_filename2,'_s',num2str(i),'.tif')};
            %cfigure;imshow(a);
            imwrite(a,horzcat(local_address,local_filename2,'_s',num2str(i),'.tif'));
            %pause(3);
        end
    end

    function[]=generate_raw_datasheet_fn(hObject,eventsdata,handles)
       if(get(hObject,'Value')==1)
          generate_raw_datasheet=1; 
       else
           generate_raw_datasheet=0;
       end
    end

    function []=visualisation(fiber_data,string,pause_duration,print_fiber_numbers)
        % idea conceived by Prashant Mittal
        % implemented by Guneet Singh Mehta and Prashant Mittal
        a=matdata; 
        orignal_image=imread(fullfile(address,[getappdata(guiCtrl,'filename'),getappdata(guiCtrl,'format')]));
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
        if(get(thresh_length_radio,'value')==1)
            fig_length=figure;set(fig_length,'Visible','off','name','length visualisation');imshow(gray123);colormap cool;colorbar;hold on;
            display(fig_length);
        end
        if(get(thresh_width_radio,'value')==1)
            fig_width=figure;set(fig_width,'Visible','off','name','width visualisation');imshow(gray123);colorbar;colormap cool;hold on;
            display(fig_width);
        end
        if(get(thresh_angle_radio,'value')==1)
            fig_angle=figure;set(fig_angle,'Visible','off','name','angle visualisation');imshow(gray123);colorbar;colormap cool;hold on;
            display(fig_angle);
        end
        if(get(thresh_straight_radio,'value')==1)
            fig_straightness=figure;set(fig_straightness,'Visible','off','name','straightness visualisation');imshow(gray123);colorbar;colormap cool;hold on;
            display(fig_straightness);
        end
        
        
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
            if(k==1&&get(thresh_length_radio,'value')==0),continue; end       
             if(k==2&&get(thresh_width_radio,'value')==0),continue; end       
             if(k==3&&get(thresh_angle_radio,'value')==0),continue; end       
             if(k==4&&get(thresh_straight_radio,'value')==0),continue; end       
            
            if(k==1&&get(thresh_length_radio,'value')==1)
                fprintf('in k=1 and thresh_length_radio=%d',get(thresh_length_radio,'value'));
                max=max_l;min=min_l;display(max);display(min);
%                 colorbar('Ticks',[0,size_colors],'yticks',{num2str(0),num2str(size_colors)});
                cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_length;
            end
             if(k==2&&get(thresh_width_radio,'value')==1)
                 
                 max=max_w;min=min_w;%display(max);display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_width;
             end
             if(k==3&&get(thresh_angle_radio,'value')==1)
                 
                 max=max_a;min=min_a;%display(max);display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_angle;
             end
             if(k==4&&get(thresh_straight_radio,'value')==1)
                 
                 max=max_s;min=min_s;%display(max);display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',[0,size_colors-1],'YTickLabel',['min ';'max ']);
                current_fig=fig_straightness;
             end
             fprintf('in k=%d and length=%d width=%d angle=%d straight=%d',k,get(thresh_length_radio,'value'),get(thresh_width_radio,'value'),get(thresh_angle_radio,'value'),get(thresh_straight_radio,'value'));
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
                     %display(color_final);%pause(0.01);
                    figure(current_fig);plot(x_cord,y_cord,'LineStyle','-','color',color_final,'linewidth',0.005);hold on;
    
                    if(print_fiber_numbers==1&&final_threshold~=1)
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

    function []=visualisation2(fiber_data)
            
        % idea conceived by Prashant Mittal
        % implemented by Guneet Singh Mehta and Prashant Mittal
        pause_duration=0;
        print_fiber_numbers=0;
        a=matdata; 
        %address=pathname;
        orignal_image=imread(fullfile(address,[getappdata(guiCtrl,'filename'),getappdata(guiCtrl,'format')]));
        
        if(size(orignal_image,3)==3)
        gray123(:,:,1)=orignal_image(:,:,1);
        gray123(:,:,2)=orignal_image(:,:,2);
        gray123(:,:,3)=orignal_image(:,:,3);
        else
            gray123(:,:,1)=orignal_image(:,:);
            gray123(:,:,2)=orignal_image(:,:);
            gray123(:,:,3)=orignal_image(:,:);
        end
%         steps-
%         1 open figures according to the buttons on in the GUI
%         2 define colors for l,w,s,and angle
% %         3 change the position of figures so that all are visible
%             4 define max and min of each parameter
%             5 according to max and min define intensity of base and variable- call fibre_data which contains all data
        x_map=[0 ,0.114,0.299,0.413,0.587,0.7010,0.8860,1.000];
        %T_map=[0 0 0.5;0 0.5 0;0.5 0 0;1 0 0.5;1 0.5 0;0 1 0.5;0.5 1 0;0.5 0 1];
        T_map=[1 0.6 0.2;0 1 0;1 0 0;1 1 0;1 0 1;0 1 1;0 0 1];
        color_number=size(T_map,1);
        %map = interp1(x_map,T_map,linspace(0,1,255));
        for k2=1:255
            if(k2<floor(255/color_number)&&k2>=1)
                map(k2,:)=T_map(1,:);
            elseif(k2<floor(2*255/color_number)&&k2>=floor(255/color_number))
                map(k2,:)=T_map(2,:);
            elseif(k2<floor(3*255/color_number)&&k2>=(2*255/color_number))
                map(k2,:)=T_map(3,:);
            elseif(k2<floor(4*255/color_number)&&k2>=(3*255/color_number))
                map(k2,:)=T_map(4,:);
            elseif(k2<floor(5*255/color_number)&&k2>=(4*255/color_number))
                map(k2,:)=T_map(5,:);
            elseif(k2<floor(6*255/color_number)&&k2>=(5*255/color_number))
                map(k2,:)=T_map(6,:);
            elseif(k2<floor(7*255/color_number)&&k2>=(6*255/color_number))
                map(k2,:)=T_map(7,:);
            elseif(k2<floor(255)&&k2>=(7*255/color_number))
                map(k2,:)=T_map(color_number,:);
            end
        end
        colormap(map);%hsv is also good
        colors=colormap;size_colors=size(colors,1);
        
            fig_length=figure;set(fig_length,'Visible','off','name','length visualisation');imshow(gray123);colormap(map);colorbar;hold on;
            %display(fig_length);
            fig_width=figure;set(fig_width,'Visible','off','name','width visualisation');imshow(gray123);colorbar;colormap(map);hold on;
            %display(fig_width);
            fig_angle=figure;set(fig_angle,'Visible','off','name','angle visualisation');imshow(gray123);colorbar;colormap(map);hold on;
            %display(fig_angle);
            fig_straightness=figure;set(fig_straightness,'Visible','off','name','straightness visualisation');imshow(gray123);colorbar;colormap(map);hold on;
            %display(fig_straightness);
       % pause(5);
        flag_temp=0;
        
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
        jump_l=(max_l-min_l)/color_number;jump_w=(max_w-min_w)/color_number;
        jump_a=(max_a-min_a)/color_number;jump_s=(max_s-min_s)/color_number;
        for i=1:color_number+1
            % floor is used only in length and angle because differences in
            % width and straightness are in decimal places
            ytick_l(i)=floor(size_colors*(i-1)*jump_l/(max_l-min_l));
            %ytick_label_l{i}=num2str(floor(min_l+(i-1)*jump_l));
            ytick_label_l{i}=num2str(round(floor(min_l+(i-1)*jump_l)*100)/100);
            
            ytick_w(i)=size_colors*(i-1)*jump_w/(max_w-min_w);
            %ytick_label_w{i}=num2str(min_w+(i-1)*jump_w);
            ytick_label_w{i}=num2str(round(100*(min_w+(i-1)*jump_w))/100);
            
            ytick_a(i)=floor(size_colors*(i-1)*jump_a/(max_a-min_a));
            %ytick_label_a{i}=num2str(floor(min_a+(i-1)*jump_a));
            ytick_label_a{i}=num2str(round(100*(min_a+(i-1)*jump_a))/100);
            
            ytick_s(i)=size_colors*(i-1)*jump_s/(max_s-min_s);
            %ytick_label_s{i}=num2str(min_s+(i-1)*jump_s);
            ytick_label_s{i}=num2str(round(100*(min_s+(i-1)*jump_s))/100);
        end
        ytick_l(color_number+1)=252;
        ytick_w(color_number+1)=252;
        ytick_a(color_number+1)=252;
        ytick_s(color_number+1)=252;
        %display(ytick_a);display(ytick_label_a);
        rng(1001) ;
        
        for k=1:4
            tick=0;
            if(k==1&&get(thresh_length_radio,'value')==1)
%                fprintf('in k=1 and thresh_length_radio=%d',get(thresh_length_radio,'value'));
%                 colorbar('Ticks',[0,size_colors],'yticks',{num2str(0),num2str(size_colors)});
                tick=1;
                display('in length');
                figure(fig_length);
                xlabel('Measurements in Pixels');
                max=max_l;min=min_l;
                cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',ytick_l,'YTickLabel',ytick_label_l);
                current_fig=fig_length;
            end
             if(k==2&&get(thresh_width_radio,'value')==1)
                 tick=1;
                 figure(fig_width);
                 xlabel('Measurements in Pixels');
                 max=max_w;min=min_w;%%display(max);%display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',ytick_w,'YTickLabel',ytick_label_w);
                current_fig=fig_width;
             end
             if(k==3&&get(thresh_angle_radio,'value')==1)
                 tick=1;
                 figure(fig_angle);
                 xlabel('Measurements in Degrees');
                 max=max_a;min=min_a;%%display(max);%display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',ytick_a,'YTickLabel',ytick_label_a);
                current_fig=fig_angle;
             end
             if(k==4&&get(thresh_straight_radio,'value')==1)
                 tick=1;
                 figure(fig_straightness);
                 xlabel('Measurements in ratio of fiber length/dist between fiber endpoints');
                 max=max_s;min=min_s;%%display(max);%display(min);
                 cbar_axes=colorbar('peer',gca);
                set(cbar_axes,'YTick',ytick_s,'YTickLabel',ytick_label_s);
                current_fig=fig_straightness;
             end
 %            fprintf('in k=%d and length=%d width=%d angle=%d straight=%d',k,get(thresh_length_radio,'value'),get(thresh_width_radio,'value'),get(thresh_angle_radio,'value'),get(thresh_straight_radio,'value'));
             %fprintf('current figure=%d\n',current_fig);%pause(10);
             %continue;
            if(tick==1)
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
            end
            hold off % YL: allow the next high-level plotting command to start over
        end
        end


end