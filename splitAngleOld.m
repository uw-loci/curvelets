%% Scale different angles in the image different colors

function [Split] = splitAngle(img_cell)
% Usage:  img_cell is the curvelet coefficients which have been
% thresholded, indented, and had the coarse coefficients zeroed out.
% numAngle is the number of angles to seperate out.  This value can be 
% 0,2,4,8.  Split is a cell which contains the curvelet coeffiecients
% grouped into numAngle different matricies.

if nargin < 2
    numAngle = 0;
end

if numAngle == 2;
    keep = [1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1];
elseif numAngle == 4;
    keep = [1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0;
            0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1;
            0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0;
            0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0];
else
    keep = [1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1;
            0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0;
            0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0;
            0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0;
            0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0;
            0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0;
            0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0];
end

if numAngle == 0;
    Split = img_cell;
else

for xx = 1:length(img_cell)
    for yy = 1:length(img_cell{xx})
        temp{xx}{yy} = zeros(size(img_cell{xx}{yy}));
    end
end    
    
%% Group Different Orientations
for jj = 1:length(keep(:,1))
    for s = 1:length(img_cell)
        for w = 1:length(img_cell{s})/16;
            temp{s}{w} = keep(jj,1)*img_cell{s}{w};
        end
        for w = length(img_cell{s})/16+1:length(img_cell{s})/8;
            temp{s}{w} = keep(jj,2)*img_cell{s}{w};
        end
        for w = length(img_cell{s})/8+1:3*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,3)*img_cell{s}{w};
        end
        for w = 3*length(img_cell{s})/16+1:length(img_cell{s})/4;
            temp{s}{w} = keep(jj,4)*img_cell{s}{w};
        end
        for w = length(img_cell{s})/4+1:5*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,5)*img_cell{s}{w};
        end
        for w = 5*length(img_cell{s})/16+1:3*length(img_cell{s})/8;
            temp{s}{w} = keep(jj,6)*img_cell{s}{w};
        end
        for w = 3*length(img_cell{s})/8+1:7*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,7)*img_cell{s}{w};
        end
        for w = 7*length(img_cell{s})/16+1:length(img_cell{s})/2;
            temp{s}{w} = keep(jj,8)*img_cell{s}{w};
        end
        for w =length(img_cell{s})/2+1:9*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,9)*img_cell{s}{w};
        end
        for w = 9*length(img_cell{s})/16+1:5*length(img_cell{s})/8;
            temp{s}{w} = keep(jj,10)*img_cell{s}{w};
        end
        for w = 5*length(img_cell{s})/8+1:11*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,11)*img_cell{s}{w};
        end
        for w = 11*length(img_cell{s})/16+1:3*length(img_cell{s})/4;
            temp{s}{w} = keep(jj,12)*img_cell{s}{w};
        end
        for w = 3*length(img_cell{s})/4+1:13*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,13)*img_cell{s}{w};
        end
        for w = 13*length(img_cell{s})/16+1:7*length(img_cell{s})/8;
            temp{s}{w} = keep(jj,14)*img_cell{s}{w};
        end
        for w = 7*length(img_cell{s})/8+1:15*length(img_cell{s})/16;
            temp{s}{w} = keep(jj,15)*img_cell{s}{w};
        end
        for w = 15*length(img_cell{s})/16+1:length(img_cell{s});
            temp{s}{w} = keep(jj,16)*img_cell{s}{w};
        end
    end
    Split{jj} = temp;
end

end