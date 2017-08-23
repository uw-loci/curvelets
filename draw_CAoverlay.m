function draw_CAoverlay(filepath,filename)
% draw overlay image based on the CAout put data
load(fullfile(filepath,filename),'imgNameP','IMG','sliceNum','fibProcMeth','coords','object','angles',...
    'inCurvs','inCurvsFlag','outCurvsFlag','bndryMeas','bndryMode','measBndry','inBndry','Swidth','Sheight')

guiOver = figure(100);clf
set(guiOver,'Units','normalized','Position',[0.27 0.0875 0.25 0.25*Swidth/Sheight],'name','CurveAlign Fiber Overlay','NumberTitle','off','Visible','on');
overPanel = uipanel('Parent', guiOver,'Units','normalized','Position',[0 0 1 1]);
overAx = axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);
imshow(IMG,'Parent',overAx);
hold on;
%hold(overAx);
if fibProcMeth == 0
    len = ceil(size(IMG,1)/128); %defines length of lines to be displayed, indicating curvelet angle
elseif fibProcMeth == 1
    len = ceil(2.5); % from ctfire minimum length of a fiber segment
elseif fibProcMeth == 2 || fibProcMeth == 3
    len = ceil(10); % from ctfire minimum length of a fiber
end


if bndryMeas && bndryMode <3  % csv boundary
    plot(overAx,coords(:,1),coords(:,2),'y');
    plot(overAx,coords(:,1),coords(:,2),'*y');
elseif bndryMeas && bndryMode == 3  % tiffboundary
    %h = imshow(boundaryImg);
    %alpha(h,0.5); %change the transparency of the overlay
    for k = 1:length(coords)%2:length(coords)
        boundary = coords{k};
        plot(boundary(:,2), boundary(:,1), 'y')
        drawnow;
    end
    
end
if bndryMode == 0       % NO boundary
    drawCurvs(object(inCurvsFlag),overAx,len,0,angles(inCurvsFlag),10,1,bndryMeas); %these are curvelets that are used
    
elseif  bndryMode ==  1 || bndryMode == 2  % csv boundary
    drawCurvs(inCurvs,overAx,len,0,angles,10,1,bndryMeas); %these are curvelets that are used for measurement
    drawCurvs(outCurvs,overAx,len,1,vertcat(outCurvs.angle),10,1,bndryMeas); %these are curvelets that are not used
    if (bndryMeas && makeAssoc)
        for kk = 1:length(inCurvs)%length(object)
            plot(overAx,[inCurvs(kk).center(1,2) measBndry(kk,2)],[inCurvs(kk).center(1,1) measBndry(kk,1)],'b'); % YL
        end
    end
elseif bndryMode ==  3       % tiff boundary
    drawCurvs(object(inCurvsFlag),overAx,len,0,angles(inCurvsFlag),10,1,bndryMeas); %these are curvelets that are used
    drawCurvs(object(outCurvsFlag),overAx,len,1,angles(outCurvsFlag),10,1,bndryMeas); %YL07082015: these are curvelets/fibers that are not used
    if (bndryMeas && makeAssoc)
        inCurvs = object(inCurvsFlag);
        inBndry = measBndry(inCurvsFlag,:);
        for kk = 1:length(inCurvs)
            %plot the line connecting the curvelet to the boundary
            plot(overAx,[inCurvs(kk).center(1,2) inBndry(kk,1)],[inCurvs(kk).center(1,1) inBndry(kk,2)],'b');
        end
    end
    
end

%save the image to file
filepath_CA = strrep(filepath,'parallel_temp','');
if isempty(sliceNum)
    saveOverlayFname = fullfile(filepath_CA,strcat(imgNameP,'_overlay.tiff'));
else
    saveOverlayFname = fullfile(filepath_CA,sprintf('%s_s%d_overlay.tiff',imgNameP,sliceNum));
end
set(guiOver,'PaperUnits','inches','PaperPosition',[0 0 size(IMG,2)/200 size(IMG,1)/200]);
print(guiOver,'-dtiffn', '-r200', saveOverlayFname);%YL, '-append'); %save a temporary copy of the image
fprintf('Saved  %s \n',saveOverlayFname);
end
