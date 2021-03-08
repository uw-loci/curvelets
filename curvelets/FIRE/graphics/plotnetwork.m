function[] = plotnetwork(X,Edge,edge_color,lw,linestyle,dim)
%PLOTNETWORK - plots network
% plotnetwork(X,Edge,edge_color,cell_color,dim)
%
%this function plots a 2D lattice, adn the cells on top of it:
% X, the coordinates of each edge
% Edge, a list of the edges.  Edge is an Mx2 array, where
% M is the number of edges and each row is the two vertices in that edge
% Cell V is a Nx2 array of cell edge positions.  It is an optional input
% e are the strains exerted on the edges.  if entered, the edges are
% colorcoded by the strains
%
% plotnetwork(X,Edge,edge_color,lw,linestyle,dim)
flag_edgecolor = 0;
if exist('edge_color')
    if ~isempty(edge_color)
        flag_edgecolor = 1;
    end
end
if flag_edgecolor == 0
    %edge_color = [0 0 1];
    edge_color  = 'rand';
end

if nargin<4
    lw = 2;
end

if nargin<5
    linestyle = '-';
end

if nargin<6
    if size(X,2)==2
        dim = 2;
    elseif size(X,2)==3
        dim = 3;
    else
        dim = 2;
    end
end

len = size(Edge,1);

if size(Edge,2) == 2
    Edge = [Edge zeros(len,1) ones(len,1)]; %no cells, all edges present
elseif size(Edge,2) == 3
    Edge = [Edge ones(len,1)]; %all edges exist
end

hold on
col = colormap;
for i=1:size(Edge,1)
    if Edge(i,4)~=0 %edge exists
        x1 = X(Edge(i,1),1);
        y1 = X(Edge(i,1),2);
        x2 = X(Edge(i,2),1);
        y2 = X(Edge(i,2),2);    

        if dim == 2 %then we have 2D data to plot
            h = line([x1 x2],[y1 y2]);
        elseif dim == 3 %then we plot 3D data
            z1 = X(Edge(i,1),3);
            z2 = X(Edge(i,2),3);       
            h = line([x1 x2],[y1 y2],[z1 z2]);
        end
        
        if strcmp(edge_color,'rand')
            set(h,'Color',rand(1,3)*.75 ,'LineWidth',lw,'LineStyle',linestyle)
        else
            set(h,'Color',edge_color,'LineWidth',lw,'LineStyle',linestyle)
        end
    end
end

if exist('e')
    title(['max|strain| = ' num2str(max((e)))])
end

function[h] = ellipse(xc,yc,a,b,phi,col);
    %ellipse(xc,yc,maj,min,theta,col
    %This function draws a solid ellipse at
    %xc,yc = position
    %a,b   = major and minor axes
    %phi   = angle of ellipse
    %col   = color of ellipse

    if isempty('col')
        col = 'b';
    end
    
    t = (0:.05:1)*2*pi;
    
    % Parametric equation of the ellipse
        x = a*cos(t);
        y = b*sin(t);

    % Coordinate transform 
        X = cos(phi)*x - sin(phi)*y;
        Y = sin(phi)*x + cos(phi)*y;
        X = X + xc;
        Y = Y + yc;
        
    % Plot ellipse
        h = patch(X,Y,col);
 