function varargout = image3gui1(varargin)
%IMAGE3GUI1 - for visualizing slices of a 3d or 4d image array
%3d images are represented as 3d matrices of the form im3(z,y,x)
%and im3(z,:,:) is displayed as the user scrolls
%4d images are represented as IM3{t}{z,y,x}, and the two scroll bars are
%used to visualize the IM3{t}(z,:,:) slice.
%
%the image of interest can either be read input into the function, or if it
%is in the workspace, you can type it into the text box in the lower left
%corner and press the update button.
%
%IMAGE3GUI1 M-file for image3gui1.fig
%      IMAGE3GUI1, by itself, creates a new IMAGE3GUI1 or raises the existing
%      singleton*.
%
%      H = IMAGE3GUI1 returns the handle to a new IMAGE3GUI1 or the handle to
%      the existing singleton*.
%
%      IMAGE3GUI1('Property','Value',...) creates a new IMAGE3GUI1 using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to image3gui1_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      IMAGE3GUI1('CALLBACK') and IMAGE3GUI1('CALLBACK',hObject,...) call the
%      local function named CALLBACK in IMAGE3GUI1.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help image3gui1

% Last Modified by GUIDE v2.5 22-Dec-2006 12:27:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @image3gui1_OpeningFcn, ...
                   'gui_OutputFcn',  @image3gui1_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before image3gui1 is made visible.
function image3gui1_OpeningFcn(hObject, eventdata, h, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for image3gui1
h.output = hObject;

if length(varargin)==1
    if iscell(varargin{1})
        h.IM3=varargin{1};    
    else
        h.IM3{1} = varargin{1};
    end
    if length(h.IM3)==1
        h.IM3{2} = h.IM3{1};
    end
    im3 = h.IM3{1};
    i=1;

% handles
    axim = h.axes1;
    edim = h.edit4;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;    
    
%plot the image    
    axes(axim);
    colormap gray
    im3 = double(im3);
    imsc= uint8((255*(im3-min(im3(:))))/(max(im3(:))-min(im3(:))+eps));
    h.im3 = imsc;
    
    im2 = squeeze(imsc(i,:,:));
    image(im2);
    axis image
    1;
    guidata(hObject, h);
%update sliders
    set(slim, 'Value',i);
    set(txtim,'String',num2str(get(slim,'Value')));
    set(slim,'Min',1);
    k = size(h.IM3{1},1);
    set(slim,'Max',k);
    set(slim,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);

    set(slX,'Value',i);
    set(txtX,'String',num2str(get(slX,'Value')));
    k = length(h.IM3)
    set(slX,'Min',1);
    set(slX,'Max',k);
    set(slX,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);        
end

% Update handles structure
guidata(hObject, h);
1;


% UIWAIT makes image3gui1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = image3gui1_OutputFcn(hObject, eventdata, handles)
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



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*******************************************************
%
%                 CALLBACK FUNCTIONS
%
%*******************************************************

% --- Executes during object creation, after setting all properties.
function update_Callback(hObject, eventdata, h)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% handles
    axim = h.axes1;
    edim = h.edit4;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;

%get teh plot variables
    i = 1;

    varall = evalin('base','who');
    imstring = get(edim,'String');
    
    IM3 = evalin('base',imstring);         
    if ~iscell(IM3)
        h.IM3{1} = IM3;
    end
    if length(h.IM3) == 1;
        h.IM3{2} = h.IM3{1};
    end    
    im3   = double(h.IM3{i});

%plot the image    
    axes(axim);
    colormap gray
    imsc= uint8(255*(im3-min(im3(:)))/(max(im3(:))-min(im3(:))+eps));
    h.im3 = imsc;
    
    im2 = squeeze(imsc(i,:,:));
    image(im2);
    axis image
    
%update sliders
    set(slim, 'Value',i);
    set(txtim,'String',num2str(get(slim,'Value')));
    set(slim,'Min',1);
    k = size(h.IM3{1},1);
    set(slim,'Max',k);
    set(slim,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);

    set(slX,'Value',i);
    set(txtX,'String',num2str(get(slX,'Value')));
    k = length(h.IM3);
    set(slX,'Min',1);
    set(slX,'Max',k);
    set(slX,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);
        
%update variables
    guidata(hObject,h);
    
function slidertime_Callback(hObject, eventdata, h)
% handles
    axim = h.axes1;
    edim = h.edit4;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;    
    
% update plots    
    tind = round(get(hObject,'Value'));
    zind = round(get(slim,'Value'));
    set(slX,'Value',tind);

    %plot image
        axes(axim)
        im3   = double(h.IM3{tind}); 
        colormap gray
        imsc= uint8(255*(im3-min(im3(:)))/(max(im3(:))-min(im3(:))+eps));
        h.im3 = imsc;
    
        im2 = squeeze(imsc(zind,:,:));
        image(im2);
        axis image
        1;
        
                        
%update sliders
    set(txtX,'String',num2str(get(slX,'Value')));    

%update variables
    guidata(hObject,h);
    
    
function sliderz_Callback(hObject, eventdata, h)
% handles
    axim = h.axes1;
    edim = h.edit4;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;    
    
% update plots    
    tind = round(get(slX,'Value'));
    zind = round(get(slim,'Value'));

    %plot image
        axes(axim)    
        im2 = squeeze(h.im3(zind,:,:));
        image(im2);
        axis image
                
%update sliders
    set(txtim,'String',num2str(get(slim,'Value')));
    
%update variables
    guidata(hObject,h);
