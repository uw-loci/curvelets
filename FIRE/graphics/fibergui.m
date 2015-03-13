function varargout = fibergui(varargin)
%FIBERGUI M-file for fibergui.fig
%      FIBERGUI, by itself, creates a new FIBERGUI or raises the existing
%      singleton*.
%
%      H = FIBERGUI returns the handle to a new FIBERGUI or the handle to
%      the existing singleton*.
%
%      FIBERGUI('Property','Value',...) creates a new FIBERGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to fibergui_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      FIBERGUI('CALLBACK') and FIBERGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in FIBERGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fibergui

% Last Modified by GUIDE v2.5 22-Dec-2006 16:36:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fibergui_OpeningFcn, ...
                   'gui_OutputFcn',  @fibergui_OutputFcn, ...
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


% --- Executes just before fibergui is made visible.
function fibergui_OpeningFcn(hObject, eventdata, h, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for fibergui
h.output = hObject;
h.dz = 8;
h.lw = 5;
if length(varargin)==3
    h.F = varargin{2};
    if iscell(varargin{1})
        h.X = varargin{1};
        h.IM3=varargin{3};
    else
        h.X{1} = varargin{1};
        h.IM3{1}=varargin{3};
    end
    
    
    
    tind=1;
    zind=1;
    im3   = double(h.IM3{tind});
    F     = h.F;
    X     = h.X{tind};

% handles
    axim = h.axes1;
    axF  = h.axes2;
    edX  = h.edit1;
    edF  = h.edit2;
    edim = h.edit3;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;    
    
%plot the image    
    axes(axim);
    colormap gray
    imsc= uint8(255*(im3-min(im3(:)))/(max(im3(:))-min(im3(:))+eps));
    h.im3 = imsc;
    
    im2 = squeeze(imsc(zind,:,:));
    image(im2);
    axis image
    
%plot the fibers
    axes(axF);
    cla
    %image(255*ones(size(im2)));
    image(im2);
    axis image
    if size(X,2)==3 %plot fibers as a series of connected lines
        plotfiber_slice(X,F,max(1,zind-h.dz),min(size(h.im3,1),zind+h.dz),h.lw,0,'g');
    elseif size(X,2)==6 %plot fibers as 3rd order polynomials
        plotbeam_slice(X,F,max(1,zind-h.dz),min(size(h.im3,1),zind+h.dz),h.lw,0,'g');
    end
    
%update sliders
    set(slim, 'Value',zind);
    set(txtim,'String',num2str(get(slim,'Value')));
    set(slim,'Min',1);
    k = size(h.IM3{1},1);
    set(slim,'Max',k);
    set(slim,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);

    set(slX,'Value',i);
    set(txtX,'String',num2str(get(slX,'Value')));
    k = length(h.X)
    set(slX,'Min',1);
    set(slX,'Max',k);
    set(slX,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);
        
%update variables
    guidata(hObject,h);

end




% Update handles structure
guidata(hObject, h);

% UIWAIT makes fibergui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = fibergui_OutputFcn(hObject, eventdata, handles)
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
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
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
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% handles
    axim = h.axes1;
    axF  = h.axes2;
    edX  = h.edit1;
    edF  = h.edit2;
    edim = h.edit3;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;

%get teh plot variables
    tind = 1;
    zind = max(1,get(slim,'Value'));
    
    varall = evalin('base','who');
    imstring = get(edim,'String');
    Fstring  = get(edF,'String');
    Xstring  = get(edX,'String');
    
    IM3 = evalin('base',imstring);    
    X   = evalin('base', Xstring);  
    h.F   = evalin('base', Fstring);  
  
    if ~iscell(IM3)
        h.IM3{1} = IM3;
        h.X{1}   = X;
    else
        h.IM3    = IM3;
        h.X      = X;
    end
    
    im3   = double(h.IM3{tind});
    F     = h.F;
    X     = h.X{tind};

%plot the image    
    axes(axim);
    colormap gray
    imsc= uint8(255*(im3-min(im3(:)))/(max(im3(:))-min(im3(:))+eps));
    h.im3 = imsc;
    
    im2 = squeeze(imsc(zind,:,:));
    image(im2);
    axis image

%update sliders
    k = size(h.IM3{1},1);
    if k>1
        set(slim, 'Value',zind);
        set(txtim,'String',num2str(get(slim,'Value')));
        set(slim,'Min',1);
        set(slim,'Max',k);
        set(slim,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);
    else
        set(slim,'Value',1);
        set(txtim,'String','1');
    end
       
    k = length(h.X);
    if k>1
        set(slX,'Value',i);
        set(txtX,'String',num2str(get(slX,'Value')));
        set(slX,'Min',1);
        set(slX,'Max',k);
        set(slX,'SliderStep',[1/(k-1) min(10/(k-1),k-1)]);
    else
        set(slX,'Value',1);
        set(txtX,'String','1');
    end    
    
%plot the fibers
    axes(axF);
    cla
    %image(255*ones(size(im2)));
    image(im2);
    axis image
    if size(X,2)==3 %plot fibers as a series of connected lines
        plotfiber_slice(X,F,max(1,zind-h.dz),min(size(h.im3,1),zind+h.dz),h.lw,0,'g');
    elseif size(X,2)==6 %plot fibers as 3rd order polynomials
        plotbeam_slice(X,F,max(1,zind-h.dz),min(size(h.im3,1),zind+h.dz),h.lw,0,'g');
    end
        
%update variables
    guidata(hObject,h);
    
function slidertime_Callback(hObject, eventdata, h)
% handles
    axim = h.axes1;
    axF  = h.axes2;
    edX  = h.edit1;
    edF  = h.edit2;
    edim = h.edit3;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;    
    
% update plots    
    tind = round(get(hObject,'Value'));
    zind = round(get(slim,'Value'));
    set(slX,'Value',tind);
    X    = h.X{tind};
    
    %plot image
        axes(axim)
        im3   = double(h.IM3{tind}); 
        colormap gray
        imsc= uint8(255*(im3-min(im3(:)))/(max(im3(:))-min(im3(:))+eps));
        h.im3 = imsc;
    
        im2 = squeeze(imsc(zind,:,:));
        image(im2);
        axis image

    %plot the fibers
        axes(axF);
        cla
        %image(255*ones(size(im2)));
        image(im2)
        axis image
        if size(X,2)==3 %plot fibers as a series of connected lines
            plotfiber_slice(X,F,max(1,i-h.dz),min(size(h.im3,1),i+h.dz),h.lw,0,'g');
        elseif size(X,2)==6 %plot fibers as 3rd order polynomials
            plotbeam_slice(X,F,max(1,i-h.dz),min(size(h.im3,1),i+h.dz),h.lw,0,'g');
        end
                        
%update sliders
    set(txtX,'String',num2str(get(slX,'Value')));    

%update variables
    guidata(hObject,h);
    
    
function sliderz_Callback(hObject, eventdata, h)
% handles
    axim = h.axes1;
    axF  = h.axes2;
    edX  = h.edit1;
    edF  = h.edit2;
    edim = h.edit3;
    slX  = h.slider1;
    slim = h.slider2;
    txtX = h.text1;
    txtim= h.text2;    
    
% update plots    
    tind = round(get(slX,'Value'));
    zind = round(get(slim,'Value'));

    X    = h.X{tind};
    F    = h.F;
    %plot image
        axes(axim)    
        im2 = squeeze(h.im3(zind,:,:));
        image(im2);
        axis image

    %plot the fibers
        axes(axF);
        cla
        image(im2)
        axis image
        if size(X,2)==3 %plot fibers as a series of connected lines
            plotfiber_slice(X,F,max(1,zind-h.dz),min(size(h.im3,1),zind+h.dz),h.lw,0,'g');
        elseif size(X,2)==6 %plot fibers as 3rd order polynomials
            plotbeam_slice(X,F,max(1,zind-h.dz),min(size(h.im3,1),zind+h.dz),h.lw,0,'g');
        end
                
%update sliders
    set(txtim,'String',num2str(get(slim,'Value')));
    
%update variables
    guidata(hObject,h);
