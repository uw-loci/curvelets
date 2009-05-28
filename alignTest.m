% Find the angle between tumor and collagen

function alignTest()
global img;



hVector = 0;
vVector = 0;
img_sz = size(img);
wide = img_sz(2);
tall = img_sz(1);


%hull is a vertical and a horizontal line through the midpoint of the image

for k=1:2

    switch k
        case 1
            hull = [0 tall/2; wide/4 tall/2; wide/2 tall/2; 3*wide/4 tall/2; wide tall/2];  %horizontal    
        case 2
            hull = [wide/2 tall; wide/2 3*tall/4; wide/2 tall/2; wide/2 tall/4; wide/2 0];  %vertical
    end    

    
% take curvelet transform
C = fdct_wrapping(img,1,2);

%set the low pass filter coefficients to zero
C{1}{1} = zeros(size(C{1}{1}));

% make edges zero
C_indent = pixel_indent(C,2);

% get center position of each curvelet
center_pos = findPos(C_indent);

% get the angles for curvelets
angles = collAngle(C_indent);

% group the centers together
centers = groupCenter(center_pos);

% make the centers into vectors
[x,y] = centerPlot(centers);

%calculate angles
angle_tumor = cell(32,1);

h = waitbar(0,'Computing');

    figure(1);plot(y,x,'yd');

    for ii = 1:length(centers)
        goto = size(centers{ii});
        if goto(2) ==0;
            continue
        else
            for jj = 1:goto(2);
                center = [centers{ii}(1,jj),centers{ii}(2,jj)];
                angle = angles{ii};
                angle_tumor{ii}(jj) = angleLine(center, angle, hull);
            end
        end
    waitbar(ii/length(centers),h);
    end


close(h)
angle_vec = 0;

%make into vector

for ii = 1:length(angle_tumor)
        temp = angle_tumor{ii}; 
        angle_vec = [angle_vec temp];
        temp = 0;
end

angle_vec = angle_vec(2:end);
angle_vec = angle_vec(find(angle_vec >= 0));


if k > 1
        vVector = angle_vec;
else
        hVector = angle_vec;
end        
end
   
rCalcs(hVector,vVector);



% 
% fid = fopen('xLoc.txt', 'wt');
% fprintf(fid, '%6.2f\n', xx(:,1));
% fclose(fid);
% % 
% fid = fopen('yLoc.txt', 'wt');
% fprintf(fid, '%6.2f\n', xx(:,2));
% fclose(fid);
% % 
% fid = fopen('yCluster.txt', 'wt');
% fprintf(fid, '%6.2f\n', Iy);
% fclose(fid);
% 
% fid = fopen('xCluster.txt', 'wt');
% fprintf(fid, '%6.2f\n', Ix);
% fclose(fid);





