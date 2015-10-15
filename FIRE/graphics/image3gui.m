function varargout = image3gui(varargin)
% IMAGE3GUI M-file for image3gui.fig
%      IMAGE3GUI, by itself, creates a new IMAGE3GUI or raises the existing
%      singleton*.
%
%      H = IMAGE3GUI returns the handle to a new IMAGE3GUI or the handle to
%      the existing singleton*.
%
%      IMAGE3GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGE3GUI.M with the given input arguments.
%
%      IMAGE3GUI('Property','Value',...) creates a new IMAGE3GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before image3gui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to image3gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help image3gui

% Last Modified by GUIDE v2.5 06-Dec-2006 12:08:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @image3gui_OpeningFcn, ...
                   'gui_OutputFcn',  @image3gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before image3gui is made visible.
function image3gui_OpeningFcn(hObject, eventdata, h, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to image3gui (see VARARGIN)

% Choose default command line output for image3gui
h.output = h;
h.fs = 12; %default axis font size

% Update handles structure
guidata(hObject, h);
set([h.axes1 h.axes2],'FontSize',h.fs);



for i=1:length(varargin)
    im3 = double(varargin{i});
    im3 = 255*(im3-min(im3(:)))/(max(im3(:)) - min(im3(:)) + eps);
    im3 = uint8(im3);
    eval(['h.im' num2str(i) '=im3;']);
   
    eval(['ax = h.axes'   num2str(i) ';']);
    eval(['sl = h.slider' num2str(i) ';']);
    
    axes(ax);
    colormap gray
    if ndims(im3)==2
        image(im3);
    elseif ndims(im3)==3
        zind = 1;
        im = squeeze(im3(zind,:,:));
        image(im);
    end
    set(ax,'FontSize',h.fs);
    axis image
    
    %update slider
        k = size(im3,1);
        set(sl,'Min',1);        
        if ndims(im3)==2
            set(sl,'Max',1+eps);
        else
            set(sl,'Max',k);
        end
        set(sl,'Value',zind);
        if k~=1
            set(sl,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);
        else
            set(sl,'SliderStep',[1 1])
        end
end
    
guidata(hObject,h);
1;

% UIWAIT makes image3gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = image3gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*******************************************
%           CALLBACK FUNCTIONS
%*******************************************
    % --- Executes on button press in update1.
    function update_Callback(hObject, eventdata, h)
    % hObject    handle to update1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        if hObject==h.update1
            ax = h.axes1;
            ed = h.edit1;
            sl = h.slider1;
            tx = h.text1;
        elseif hObject==h.update2
            ax = h.axes2;
            ed = h.edit2;
            sl = h.slider2;    
            tx = h.text2;
        end
               
        %get image variable
            axes(ax);
            colormap gray
            varall = evalin('base','who');

            imstring = get(ed,'String');
            im3 = double(evalin('base',imstring));    
            imsc= uint8(255*(im3-min(im3(:)))/(max(im3(:))-min(im3(:))+eps));

        k = size(im3,1);
        zind = max(1,get(sl,'Value'));
        zind = min(k,zind);
            
        %update plot        
            if ndims(im3)==2
                image(imsc);
            elseif ndims(im3)==3
                im = squeeze(imsc(zind,:,:));
                image(im);
            end
            set(ax,'FontSize',h.fs);
            axis image
        %update slider
            set(sl,'Min',1);        
            if ndims(im3)==2
                set(sl,'Max',1);
            else
                set(sl,'Max',k);
            end
            set(sl,'Value',zind);
            if k~=1
                set(sl,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);
            else
                set(sl,'SliderStep',[1 1])
            end
        %update slider textbox
            set(tx,'String',num2str(get(sl,'Value')));

        
        %update handles with new image
            if hObject == h.update1
                h.im1 = imsc;
            elseif hObject == h.update2
                h.im2 = imsc;
            end
            guidata(hObject,h);
            
    % --- Executes on slider movement.
    function slider_Callback(hObject, eventdata, h)
    % hObject    handle to slider1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider        
        zind = round(get(hObject,'Value'));
        set(hObject,'Value',zind);
        if hObject==h.slider1
            ax = h.axes1;
            ed = h.edit1;
            sl = h.slider1;
            tx = h.text1;
            if ~isfield(h,'im1')
                return
            else
                im3= h.im1;
            end
        elseif hObject==h.slider2
            ax = h.axes2;
            ed = h.edit2;
            sl = h.slider2;    
            tx = h.text2;
            if ~isfield(h,'im2')
                return
            else
                im3= h.im2;
            end
        end
        if ndims(im3)==2
            return
        end
        axes(ax);
        %update plot        
            if ndims(im3)==2
                image(im3);
            elseif ndims(im3)==3
                im = squeeze(im3(zind,:,:));
                image(im);
            end
            axis image
       %update slider textbox
            set(tx,'String',num2str(get(sl,'Value')));
            
        1;
