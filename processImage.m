function [histData,recon,comps,values,distances,stats,procmap] = processImage(IMG, imgName, tempFolder, keep, coords, distThresh, makeAssoc, sliceNum, infoLabel)

    imgNameLen = length(imgName);
    imgNameP = imgName; %plain image name, without slice number
    imgName = [imgName(1:imgNameLen) '_' num2str(sliceNum)];
    
    bndryMeas = ~isempty(coords); %flag that indicates if we are measuring with respect to a boundary
    
    if infoLabel, set(infoLabel,'String','Computing curvelet transform.'); drawnow; end
    [object, Ct, inc] = newCurv(IMG,keep);
    if bndryMeas
        %there is something in coords (boundary point list), so analyze wrt
        %boundary
        if infoLabel, set(infoLabel,'String','Analyzing boundary.'); end
        [angles,distances,inCurvs,outCurvs,measBndry,~] = getBoundary3(coords,IMG,object,imgName,distThresh);
        bins = 2.5:5:87.5;
    else        
        %angs = vertcat(object.angle);
        %angles = group5(angs,inc);
        distances = NaN(1,length(object));
        %bins = min(angles):inc:max(angles);
        inCurvs = object;
        outCurvs = object([]);
        inCurvs = group6(inCurvs);
        angles = vertcat(inCurvs.angle);
        measBndry = 0;
        bins = 2.5:5:177.5;
    end
        
    [n xout] = hist(angles,bins);
    if (size(xout,1) > 1)
        xout = xout'; %fixing strange behaviour of hist when angles is empty
    end
    imHist = vertcat(n,xout);

    histData = imHist;
    saveHist = fullfile(tempFolder,strcat(imgName,'_hist.csv'));
    tempHist = circshift(histData,1);
    csvwrite(saveHist,tempHist');
    histData = tempHist';

    %recon = 1;
    if infoLabel, set(infoLabel,'String','Computing inverse curvelet transform.'); end
    temp = ifdct_wrapping(Ct,0);
    recon = real(temp);
    %recon = object;
    saveRecon = fullfile(tempFolder,strcat(imgNameP,'_reconstructed.tiff'));
    %fmt = getappdata(imgOpen,'type');
    %recon is written to file in the code below

    %Make another figure for the curvelet overlay:
    %guiOver = figure('Resize','on','Units','pixels','Position',[215 420 300 300],'name','CurveAlign Overlay','MenuBar','none','NumberTitle','off','UserData',0);
    %guiOver = figure('Resize','on','Units','pixels','Position',[215 90 600 600],'name','CurveAlign Overlay','NumberTitle','off','UserData',0);
    disp('Plotting overlay');
    if infoLabel, set(infoLabel,'String','Plotting overlay.'); end
    guiOver = figure(100);
    set(guiOver,'Position',[340 70 600 600],'name','CurveAlign Overlay','Visible','off');
    %guiOver = figure('Resize','on','Units','pixels','Position',[215 90 600 600],'name','CurveAlign Overlay','NumberTitle','off','UserData',0);
    clf;
    overPanel = uipanel('Parent', guiOver,'Units','normalized','Position',[0 0 1 1]);
    overAx = axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);
    %overAx = gca();
    IMG = imadjust(IMG);
    %imshow(IMG,'Parent',overAx);
    imshow(IMG);
    hold on;
    %hold(overAx);
    len = size(IMG,1)/64; %defines length of lines to be displayed, indicating curvelet angle
    
    if bndryMeas
        plot(overAx,coords(:,1),coords(:,2),'y');
        plot(overAx,coords(:,1),coords(:,2),'*y');
    end
    drawCurvs(inCurvs,overAx,len,0); %these are curvelets that are used
    drawCurvs(outCurvs,overAx,len,1); %these are curvelets that are not used
    if (makeAssoc)
        for kk = 1:length(inCurvs)
            %plot the line connecting the curvelet to the boundary
            plot(overAx,[inCurvs(kk).center(1,2) measBndry(kk,2)],[inCurvs(kk).center(1,1) measBndry(kk,1)]);
        end
    end
    %drawCurvs(object,overAx,len,0);
    disp('Saving overlay');
    if infoLabel, set(infoLabel,'String','Saving overlay.'); end
    %save the image to file
    saveOverlayFname = fullfile(tempFolder,strcat(imgNameP,'_overlay_temp.tiff'));
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(IMG)/128]);
    print(gcf,'-dtiffn', '-r128', saveOverlayFname, '-append'); %save a temporary copy of the image
    tempOver = imread(saveOverlayFname); %this is used to build a tiff stack below
    %hold off;

    disp('Plotting map');
    if infoLabel, set(infoLabel,'String','Plotting map.'); drawnow; end
    %Put together a map of alignment
    [rawmap procmap] = drawMap(inCurvs, angles, IMG, bndryMeas);
    guiMap = figure(200);   
    set(guiMap,'Position',[340 70 600 600],'name','CurveAlign Map','Visible','off');
    %guiMap = figure('Resize','on','Units','pixels','Position',[215 70 600 600],'name','CurveAlign Map','NumberTitle','off','UserData',0);
    clf;
    mapPanel = uipanel('Parent', guiMap,'Units','normalized','Position',[0 0 1 1]);
    mapAx = axes('Parent',mapPanel,'Units','normalized','Position',[0 0 1 1]);
    if max(max(IMG)) > 255
        IMG2 = ind2rgb(IMG,gray(2^16-1)); %assume 16 bit
    else
        IMG2 = ind2rgb(IMG,gray(255)); %assume 8 bit
    end
    imshow(IMG2);
    hold on;
    clrmap = zeros(256,3);
    if (bndryMeas)
        tg = ceil(20*255/90); ty = ceil(45*255/90); tr = ceil(60*255/90);
        clrmap(tg:ty,2) = clrmap(tg:ty,2)+1;          %green
        clrmap(ty+1:tr,1:2) = clrmap(ty+1:tr,1:2)+1;  %yellow
        clrmap(tr+1:256,1) = clrmap(tr+1:256,1)+1;    %red
    else
        tg = ceil(64); ty = ceil(128); tr = ceil(192);
        clrmap(tg:ty,2) = clrmap(tg:ty,2)+1;          %green
        clrmap(ty+1:tr,1:2) = clrmap(ty+1:tr,1:2)+1;  %yellow
        clrmap(tr+1:256,1) = clrmap(tr+1:256,1)+1;    %red
%         tb = 2; tr = 8; ty = 14; tg = 255;
%         clrmap(tb:tr,1) = clrmap(tb:tr,1)+1; %red
%         clrmap(tr+1:ty,1:2) = clrmap(tr+1:ty,1:2)+1; %yel
%         clrmap(ty+1:tg,2) = clrmap(ty+1:tg,2)+1; %green
     end
    h = imshow(procmap,clrmap);
    alpha(h,0.5); %change the transparency of the overlay
    disp('Saving map');
    if infoLabel, set(infoLabel,'String','Saving map.'); end
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(IMG)/128]);
    saveMapFname = fullfile(tempFolder,strcat(imgNameP,'_procmap_temp.tiff'));
    %write out the processed map (with smearing etc)
    print(gcf,'-dtiffn', '-r128', saveMapFname, '-append'); %save a temporary copy of the image
    tempMap = imread(saveMapFname); %this is used to build a tiff stack below
    
    
    %write out the raw map file (no smearing, etc)
    if sliceNum > 1
        imwrite(uint8(rawmap),fullfile(tempFolder,strcat(imgNameP,'_rawmap.tiff')),'tif','WriteMode','append'); 
        imwrite(tempMap,fullfile(tempFolder,strcat(imgNameP,'_procmap.tiff')),'WriteMode','append');
        imwrite(tempOver,fullfile(tempFolder,strcat(imgNameP,'_overlay.tiff')),'WriteMode','append');
        imwrite(recon,saveRecon,'WriteMode','append');
    else
        imwrite(uint8(rawmap),fullfile(tempFolder,strcat(imgNameP,'_rawmap.tiff')),'tif');
        imwrite(tempMap,fullfile(tempFolder,strcat(imgNameP,'_procmap.tiff')));
        imwrite(tempOver,fullfile(tempFolder,strcat(imgNameP,'_overlay.tiff')));
        imwrite(recon,saveRecon);
    end
    
    %delete the temporary files (they have been saved in tiff stack above)
    delete(saveMapFname);
    delete(saveOverlayFname);

    %Compass plot
    U = cosd(xout).*n;
    V = sind(xout).*n;
    comps = vertcat(U,V);
    saveComp = fullfile(tempFolder,strcat(imgName,'_compass_plot.csv'));
    csvwrite(saveComp,comps);

    %Values and stats Output
    values = angles;
    stats = makeStats3(values,tempFolder,imgName,procmap,tr,ty,tg,bndryMeas);
    saveValues = fullfile(tempFolder,strcat(imgName,'_values.csv'));
    if bndryMeas
        csvwrite(saveValues,[values distances]);
    else
        csvwrite(saveValues,values);
    end
                     

end