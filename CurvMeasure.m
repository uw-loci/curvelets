function CurvMeasure

% CurvMeasure.m
% This is the initial GUI for the program CurvMeasure, which allows the user to select the measurement scheme.
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010

clear all
close all

% main GUI figure containing two pushbuttons
chooseFig = figure('Resize','off','Units','inches','position',[5 4 4 2],'MenuBar','none','name','CurvMeasure','NumberTitle','off');
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(chooseFig,'Color',defaultBackground)

% button to launch the boundary measurement scheme
pickBoundary = uicontrol(chooseFig,'Style','pushbutton','String','Measure From Boundary','FontWeight','bold','FontName','FixedWidth','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.1 .1 .8 .4],'callback','ClickedCallback','Callback',{@launchBoundary});

% button to launch the absolute measurement scheme
pickAbsolute = uicontrol(chooseFig,'Style','pushbutton','String','Absolute Measurement','FontWeight','bold','FontName','FixedWidth','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.1 .5 .8 .4],'callback','ClickedCallback','Callback',{@launchCurvGui});

% callback functions associated with pushbuttons
    function launchCurvGui(pickAbsolute,eventdata)
        set(chooseFig,'Visible','off')
        curvGUI
    end

    function launchBoundary(pickBoundary,eventdata)
        set(chooseFig,'Visible','off')
        boundaryGUI
    end


end