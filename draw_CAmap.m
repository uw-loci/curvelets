function draw_CAmap(filepath,filename)
% draw heatmap image based on the CA output data
load(fullfile(filepath,filename),'imgNameP','sliceNum','IMG','IMG2','procmap','clrmap','Swidth','Sheight');

guiMap = figure;
set(guiMap,'Units','normalized','Position',[0.275+0.25 0.0875 0.25 0.25*Swidth/Sheight],'name','CurveAlign Angle Map','NumberTitle','off','Visible','on');
mapPanel = uipanel('Parent', guiMap,'Units','normalized','Position',[0 0 1 1]);
mapAx = axes('Parent',mapPanel,'Units','normalized','Position',[0 0 1 1]);
imshow(IMG2);
hold on
h = imshow(procmap);
colormap(clrmap);
alpha(h,0.5); %change the transparency of the overlay
hold off
%save the image to file
filepath_CA = strrep(filepath,'parallel_temp','');
if isempty(sliceNum)
    saveMapFname = fullfile(filepath_CA,strcat(imgNameP,'_procmap.tiff'));
else
    saveMapFname = fullfile(filepath_CA,sprintf('%s_s%d_procmap.tiff',imgNameP,sliceNum));
end
set(guiMap,'PaperUnits','inches','PaperPosition',[0 0 size(IMG,2)/200 size(IMG,1)/200]);
print(guiMap,'-dtiffn', '-r200', saveMapFname);
fprintf('    Saved  %s \n',saveMapFname);
end

