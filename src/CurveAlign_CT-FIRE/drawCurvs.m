function drawCurvs(object, Ax, len, color_flag, angles, marS, linW,bndryMeas)

% drawCurvs.m - draw curvelets on an image as points (centers) and lines
%
% Inputs
%   object      list of curvelet centers and angles (see newCurv func)
%   Ax          handle to the image axis where the curvelets should be drawn
%   len         length of the curvelet indicator line
%   color_flag  curvelets to be green (0) or red (1)
%   angles?
%   marS?       mark size
%   linW?       line width
%  bndryMeas : 0: no boundary; 1: with boundary
% Optional Inputs
%
% Outputs
% 
%
% By Jeremy Bredfeldt and Yuming Liu Laboratory for Optical and
% Computational Instrumentation 2013

if bndryMeas == 1
    for ii = 1:length(object)    
        ca = object(ii).angle*pi/180;
        xc = object(ii).center(1,2);
        %yc = size(IMG,1)+1-r(ii).center(1,1);
        yc = object(ii).center(1,1);
        %YL11-26-14: make the color consistent with Version 2.3
        if (color_flag == 0)
%             if angles(ii) > 60
%                 plot(xc,yc,'r.','MarkerSize',marS,'Parent',Ax); % show curvelet center     
%             elseif angles(ii) > 30
%                 plot(xc,yc,'y.','MarkerSize',marS,'Parent',Ax); % show curvelet center     
%             else
%                 plot(xc,yc,'g.','MarkerSize',marS,'Parent',Ax); % show curvelet center     
%             end
            plot(xc,yc,'g.','MarkerSize',marS,'Parent',Ax); % show curvelet center  
        else
            plot(xc,yc,'r.','MarkerSize',marS,'Parent',Ax); % show curvelet center     
        end            

        % show curvelet direction
        xc1 = (xc - len * cos(ca));
        xc2 = (xc + len * cos(ca));
        yc1 = (yc + len * sin(ca));
        yc2 = (yc - len * sin(ca));
        if (color_flag == 0)         %YL: make the line color consistent with the colormap of the "makemap"
%             if angles(ii) > 60      % angles (60, 90]
%                 plot([xc1 xc2],[yc1 yc2],'r-','linewidth',linW,'Parent',Ax); % show curvelet angle
%             elseif angles(ii) > 45  % angles (45, 60]
%                 plot([xc1 xc2],[yc1 yc2],'y-','linewidth',linW,'Parent',Ax); % show curvelet angle
%             else  % angles [0-45]
%                 plot([xc1 xc2],[yc1 yc2],'g-','linewidth',linW,'Parent',Ax); % show curvelet angle
%             end
            plot([xc1 xc2],[yc1 yc2],'g-','linewidth',linW,'Parent',Ax); % show curvelet angle
        else
            plot([xc1 xc2],[yc1 yc2],'r-','linewidth',linW,'Parent',Ax); % show curvelet angle
        end
    end
else % no boundary
    for ii = 1:length(object)    
        ca = object(ii).angle*pi/180;
        xc = object(ii).center(1,2);
        %yc = size(IMG,1)+1-r(ii).center(1,1);
        yc = object(ii).center(1,1);
        if (color_flag == 0)
            plot(xc,yc,'r.','MarkerSize',marS,'Parent',Ax); % show curvelet center
        end

        % show curvelet direction
        xc1 = (xc - len * cos(ca));
        xc2 = (xc + len * cos(ca));
        yc1 = (yc + len * sin(ca));
        yc2 = (yc - len * sin(ca));
        if (color_flag == 0)         %YL: 
            plot([xc1 xc2],[yc1 yc2],'g-','linewidth',linW,'Parent',Ax); % show curvelet angle
        end
    end
end