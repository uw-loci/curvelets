function bfView

% define the font size used in the GUI
fz1 = 9 ; % font size for the title of a panel
fz2 = 10; % font size for the text in a panel
fz3 = 12; % font size for the button
fz4 = 14; % biggest fontsize size

global r; 
global ImgData;

% Create figure window
fig = uifigure('Position',[100 100 500 390]);
fig.Name = "bfView";

% Manage app layout
main = uigridlayout(fig);
main.ColumnWidth = {250,250};
main.RowHeight = {110,110,120};

% Create UI components
lbl_1 = uilabel(main,'Position',[100 400 50 20],'Text','Import');
lbl_1.Layout.Row = 1;
lbl_1.Layout.Column = 1;
btn_1 = uibutton(fig,'push','Position',[100 330 50 20],'Text','Load','ButtonPushedFcn',@import_Callback);
ds = uidropdown(fig,'Position',[100 280 100 20]);
ds.Items = ["Sampling 1" "Sampling 2" "Sampling 3"];

lbl_2 = uilabel(main,'Text','Export');
lbl_2.Layout.Row = 2;
lbl_2.Layout.Column = 1;
ss = uidropdown(fig,'Position',[100 220 120 20]);
ss.Items = ["SaveOption 1" "SaveOption 2" "SaveOption 3"];
btn_2 = uibutton(fig,'Position',[100 170 50 20],'Text','Save');

lbl_3 = uilabel(main);
lbl_3.Text = 'Info';
lbl_3.Layout.Row = 3;
lbl_3.Layout.Column = 1;
tarea = uitextarea(main);
tarea.Layout.Row = 3;
tarea.Layout.Column = 1;
tarea.Value= 'This area displays info';

lbl_4 = uilabel(main,'Text','Metadata');
lbl_4.Layout.Row = 1;
lbl_4.Layout.Column = 2;
btn_3 = uibutton(fig,'Position',[350 330 130 20],'Text','Display Metadata','ButtonPushedFcn',@dispmeta_Callback);
btn_4 = uibutton(fig,'Position',[350 300 150 20],'Text','Display OME-XML Data','ButtonPushedFcn',@disOMEpmeta_Callback);

lbl_5 = uilabel(main,'Text','Split Windows');
lbl_5.Layout.Row = 2;
lbl_5.Layout.Column = 2;
btn_5 = uicheckbox(fig,'Position',[360 230 150 20],'Text','Channels');
btn_6 = uicheckbox(fig,'Position',[360 200 150 20],'Text','Timepoints');
btn_7 = uicheckbox(fig,'Position',[360 170 150 20],'Text','Focal Planes');

lbl_6 = uilabel(main);
lbl_6.Text = 'View';
lbl_6.Layout.Row = 3;
lbl_6.Layout.Column = 2;
dbar = uicheckbox(fig,'Position', [350 80 150 20],'Text','Scalebar');
color = uidropdown(fig,'Position',[350 50 120 20]); 
color.Items = ["Color 1" "Color 2" "Color 3"];
btn_8 = uibutton(fig,'Position',[400 10 80 20],'Text','OK','BackgroundColor','[0.4260 0.6590 0.1080]');

%% Create the function for the import callback
    function import_Callback(Img,eventdata)
        [fileName pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg;*.svs';'*.*'},'File Selector','MultiSelect','on');
        if isequal(fileName,0)
            disp('User selected Cancel')
        else
            disp(['User selected ', fullfile(pathName,fileName)])
        end
        
        ff = fullfile(pathName,fileName);
        ImgData = bfopen(ff);
        r = bfGetReader(ff);
        numSeries = r.getSeriesCount();
%         omeMeta = ImgData{1, 4};
%         omeXML = char(omeMeta.dumpXML());
    end
%% 
    function dispmeta_Callback(ImgData,eventdata)
        
        
    end
%% 
    function disOMEpmeta_Callback(ImgData,eventdata)
        
        
    end


end


