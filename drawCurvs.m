function drawCurvs(object, Ax, len, color_flag)

% drawCurvs.m - draw curvelets on an image as points (centers) and lines
%
% Inputs
%   object      list of curvelet centers and angles (see newCurv func)
%   Ax          handle to the image axis where the curvelets should be drawn
%   len         length of the curvelet indicator line
%   color_flag  curvelets to be green (0) or red (1)
%
% Optional Inputs
%
% Outputs
% 
%
% By Jeremy Bredfeldt and Yuming Liu Laboratory for Optical and
% Computational Instrumentation 2013

    for ii = 1:length(object)    
        ca = object(ii).angle*pi/180;
        xc = object(ii).center(1,2);
        %yc = size(IMG,1)+1-r(ii).center(1,1);
        yc = object(ii).center(1,1);
        if (color_flag == 0)
            plot(xc,yc,'g.','MarkerSize',10,'Parent',Ax); % show curvelet center     
        else
            plot(xc,yc,'r.','MarkerSize',10,'Parent',Ax); % show curvelet center     
        end            

        % show curvelet direction
        xc1 = (xc - len * cos(ca));
        xc2 = (xc + len * cos(ca));
        yc1 = (yc + len * sin(ca));
        yc2 = (yc - len * sin(ca));
        if (color_flag == 0)
            plot([xc1 xc2],[yc1 yc2],'g-','linewidth',0.5,'Parent',Ax); % show curvelet angle
        else
            plot([xc1 xc2],[yc1 yc2],'r-','linewidth',0.5,'Parent',Ax); % show curvelet angle
        end
    end
end