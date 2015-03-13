function varargout = fiberproc_manual(varargin)
% FIBERPROC_MANUAL M-file for fiberproc_manual.fig
%      FIBERPROC_MANUAL, by itself, creates a new FIBERPROC_MANUAL or raises the existing
%      singleton*.
%
%      H = FIBERPROC_MANUAL returns the handle to a new FIBERPROC_MANUAL or the handle to
%      the existing singleton*.
%
%      FIBERPROC_MANUAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FIBERPROC_MANUAL.M with the given input arguments.
%
%      FIBERPROC_MANUAL('Property','Value',...) creates a new FIBERPROC_MANUAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fiberproc_manual_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fiberproc_manual_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% h = fiberproc_manual(X,F,V,imr>25)

% Edit the above text to modify the response to help fiberproc_manual

% Last Modified by GUIDE v2.5 04-Dec-2006 13:25:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fiberproc_manual_OpeningFcn, ...
                   'gui_OutputFcn',  @fiberproc_manual_OutputFcn, ...
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


% --- Executes just before fiberproc_manual is made visible.
function fiberproc_manual_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fiberproc_manual (see VARARGIN)

% Choose default command line output for fiberproc_manual
handles.output = hObject;

if length(varargin)<3
    error('need to enter X,F,V when calling function')
end
handles.X = varargin{1};
handles.F = varargin{2};
handles.V = varargin{3};
if length(varargin)>=4
    handles.bw= varargin{4};
else
    handles.bw = [];
end
if length(varargin)>=5
    handles.A = varargin{5};
end

figure(1); cla
X = handles.X;
F = handles.F;
if ~isfield(handles,'A')
    plotfiber(X,F,2,0,[],'o');
else
    plotbeams(X,A,F,2,0,[],'o');
end
handles.fig = gcf;

% Update handles structure
guidata(hObject, handles);
1;
% UIWAIT makes fiberproc_manual wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = fiberproc_manual_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUSH BUTTON FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function DelVert_Callback(hObject, eventdata, handles)
    % hObject    handle to load_image (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles (h)    structure with handles and user data (see GUIDATA)
        figure(handles.fig);
        handles = gdeletevertex(handles);
        guidata(hObject, handles);        

    function DelFib_Callback(hObject, eventdata, handles)
        figure(handles.fig);
        handles = gdeletefiber(handles);
        guidata(hObject, handles);
        
    function ConnectFib_Callback(hObject, eventdata, handles)
        figure(handles.fig);
        handles = gconnectfiber(handles);
        guidata(hObject, handles);
        
    function MergeFib_Callback(hObject, eventdata, handles)
        figure(handles.fig);
        handles = gmergefiber(handles);
        guidata(hObject, handles);      
        
    function GetFiberID(hObject, eventdata, handles)
        figure(handles.fig);
        [id vid] = ggetfiberid(handles);
        if length(id)==1 & length(id{1}==1)
            title(['fiber id = ' num2str(id{1}) ', vert = ' num2str(vid)]);
        end
        
    function Replot_Callback(hObject, eventdata, handles)
        figure(handles.fig);
        cla
        if ~isfield(handles,'A');
            plotfiber(handles.X,handles.F,2,0,[],'o');
        else
            plotbeams(handles.X,handles.A,handles.F,2,0,[],'o');
        end
        xlabel('X'); ylabel('Y'); zlabel('Z');
        
    function Plotbw_Callback(hObject, eventdata, handles)
        figure(handles.fig);
        if ~isempty(handles.bw)
            plot3bw(handles.bw)
        end
        
    function Save_Callback(hObject, eventdata, handles)
        Fman = handles.F;
        Xman = handles.X;
        Vman = handles.V;
        
        save XFV Xman Vman Fman
        