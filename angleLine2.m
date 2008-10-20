% Rewrite of angleLine

function [angles] = angleLine2(center,angle,hull)

%x_c1 = center(2); y_c1 = center(1);
x_c1 = center(1); y_c1 = center(2);
slope_flag_c = 0;
slope_flag_h = 0;
tol = 10^-5;
angle_hull = [];

% First I want to find another point on the line with the given center and
% angle.  This will allow me find an intersection point with the hull.

if angle == 270
    
    x_c2 = x_c1;
    y_c2 = y_c1 - 5;
    slope_flag_c = 1;

else

    if angle<=270 && angle>=225

        del_x = x_c1 - 5;
    
    else
    
        del_x = x_c1 + 5;
    
    end

    del_y = del_x * tan(angle*pi/180);

    x_c2 = x_c1 + del_x;
    y_c2 = y_c1 + del_y;
    
    slope_c = (y_c2 - y_c1)/(x_c2 - x_c1);
    y_int_c = y_c1 - slope_c * x_c1;

end

% Now I have two points on the line at given center (the center point and 
% one other point) with the given angle.  Notice the special case for 270 
% (vertical line).

% Now I want to find the intersection point with each line segmenmt in the 
% hull and check to see if that intersection is inbetween the hull points
% of the given line segment

len = size(hull);

for ii = 2:len(1)
    
    % to find the intersection point, I am going to need the slope and
    % y_int for each hull line
    
    x_h1 = hull(ii-1,1);
    x_h2 = hull(ii,1);
    y_h1 = hull(ii-1,2);
    y_h2 = hull(ii,2);
    
    % first check if slope of hull line is inf and treat according
    
    if abs(x_h1 - x_h2)<tol
        
      slope_flag_h = 1;
    
    end
    
    slope_h = (y_h2 - y_h1)/(x_h2 - x_h1);
    y_int_h = y_h1 - slope_h * x_h1;
    
    % Now I can find the intersection point of the two lines
    
    % First check slope is inf and treat special
    
    if slope_flag_c == 1 && slope_flag_h == 1
        
        angle_h = 0;
        angle_hull = [angle_hull angle_h];
        
    elseif slope_flag_c == 1;
        
        int_x = x_c1;
        int_y = slope_h * int_x + y_int_h;
        int(ii,:) = [int_x int_y];
        % Now I want to check to see if the intersection is between the two
        % points on the hull.  If it is, I want to calculate the angle
        % between the two line, if not, ignore.
        
        % calculate the distance between the two hull points
        dist1 = sqrt((x_h2 - x_h1)^2 + (y_h2 - y_h1)^2);
        % calculate the distance between each point and the intersection
        dist2 = sqrt((x_h2 - int_x)^2 + (y_h2 - int_y)^2);
        dist3 = sqrt((x_h1 - int_x)^2 + (y_h1 - int_y)^2);
        
        % if the distance between the points is bigger than both the
        % distance from the intersection point to either boundary, then the
        % intersection point lies inbetween the points
        
        if dist1 >= dist2 && dist1 >= dist3
            
            % calculate the angle between the points and treat the
            % intersection point as the origin
     
            if angle == 270
    
                int_x2 = int_x;
                int_y2 = int_y - 5;
      
            else

                if angle<=270 && angle>=225

                    del_x = x_c1 - 5;

                else

                    del_x = x_c1 + 5;

                end

                del_y = del_x * tan(angle*pi/180);

                int_x2 = int_x + del_x;
                int_y2 = int_y + del_y;

            end
            
            x1 = int_x2 - int_x;
            y1 = int_y2 - int_y;
            
            x2 = x_h1 - int_x;
            y2 = y_h1 - int_y;
            
            angle_h =  mod(atan2(abs(x1*y2-y1*x2),x1*x2+y1*y2),2*pi)*180/pi;
            angle_hull = [angle_hull angle_h];   
%         else
% 
%             angle_hull(ii) = 0;

        end
               
    elseif slope_flag_h == 1;
        
        int_x = x_h1;
        int_y = slope_c * int_x + y_int_c;
        int(ii,:) = [int_x int_y];
        % Now I want to check to see if the intersection is between the two
        % points on the hull.  If it is, I want to calculate the angle
        % between the two line, if not, ignore
        
         % calculate the distance between the two hull points
        dist1 = sqrt((x_h2 - x_h1)^2 + (y_h2 - y_h1)^2);
        % calculate the distance between each point and the intersection
        dist2 = sqrt((x_h2 - int_x)^2 + (y_h2 - int_y)^2);
        dist3 = sqrt((x_h1 - int_x)^2 + (y_h1 - int_y)^2);
        
        % if the distance between the points is bigger than both the
        % distance from the intersection point to either boundary, then the
        % intersection point lies inbetween the points
        
        if dist1 >= dist2 && dist1 >= dist3
            
            % calculate the angle between the points

           if angle == 270

                int_x2 = int_x;
                int_y2 = int_y - 5;

           else

                if angle<=270 && angle>=225

                    del_x = x_c1 - 5;

                else

                    del_x = x_c1 + 5;

                end

                del_y = del_x * tan(angle*pi/180);

                int_x2 = int_x + del_x;
                int_y2 = int_y + del_y;

            end

            x1 = int_x2 - int_x;
            y1 = int_y2 - int_y;

            x2 = x_h1 - int_x;
            y2 = y_h1 - int_y;

            angle_h =  mod(atan2(abs(x1*y2-y1*x2),x1*x2+y1*y2),2*pi)*180/pi;           
            angle_hull = [angle_hull angle_h];
%         else
%             
%             angle_hull(ii) = 0;
            
        end
        
    else
        
        int_x = (y_int_c - y_int_h)/(slope_h - slope_c);
        int_y = slope_h * int_x + y_int_h;
        int(ii,:) = [int_x int_y];
        % Now I want to check to see if the intersection is between the two
        % points on the hull.  If it is, I want to calculate the angle
        % between the two line, if not, ignore
    
         % calculate the distance between the two hull points
        dist1 = sqrt((x_h2 - x_h1)^2 + (y_h2 - y_h1)^2);
        % calculate the distance between each point and the intersection
        dist2 = sqrt((x_h2 - int_x)^2 + (y_h2 - int_y)^2);
        dist3 = sqrt((x_h1 - int_x)^2 + (y_h1 - int_y)^2);
        
        % if the distance between the points is bigger than both the
        % distance from the intersection point to either boundary, then the
        % intersection point lies inbetween the points
        
        if dist1 >= dist2 && dist1 >= dist3
            
            % calculate the angle between the points
        if angle == 270

                int_x2 = int_x;
                int_y2 = int_y - 5;

           else

                if angle<=270 && angle>=225

                    del_x = x_c1 - 5;

                else

                    del_x = x_c1 + 5;

                end

                del_y = del_x * tan(angle*pi/180);

                int_x2 = int_x + del_x;
                int_y2 = int_y + del_y;

            end

            x1 = int_x2 - int_x;
            y1 = int_y2 - int_y;

            x2 = x_h1 - int_x;
            y2 = y_h1 - int_y;

            angle_h =  mod(atan2(abs(x1*y2-y1*x2),x1*x2+y1*y2),2*pi)*180/pi;
            angle_hull = [angle_hull angle_h];           
%         else
%             
%             angle_hull(ii) = 200;
                
        end
    
    end

end

    
% check to see if there are more than two angles and choose the one which
% is the closest to the center of the curvelet


ind = find(angle_hull);
dist = [];

if isempty(ind);
    
    angles = 'none';
    
elseif length(ind) == 1;
    
    angles = angle_hull(ind);
    
else
    
    for ii = 1:length(ind)
        
        dist(ii) = sqrt((x_c1- int(ind(ii),1))^2 - (y_c1 - int(ind(ii),2))^2);
        
    end
    
    [val,tru_ind] = min(dist);
    
    angles = angle_hull(ind(tru_ind));
    
end

% if angle_hull >90
%     
%     angle_hull = 180-angle_hull;
%     
% end

    
    