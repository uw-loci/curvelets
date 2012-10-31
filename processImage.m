function [histData,recon,comps,values,distances,stats,map] = processImage(IMG, imgName, tempFolder, keep, coords, distThresh, makeAssoc)

    [object, Ct, inc] = newCurv(IMG,keep);
    [angles,distances,inCurvs,outCurvs,measBndry,~] = getBoundary3(coords,IMG,object,imgName,distThresh);
    bins = 2.5:5:87.5;
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

    recon = 1;
    %temp = ifdct_wrapping(Ct,0);
    %recon = real(temp);
    %recon = object;
    %saveRecon = fullfile(tempFolder,strcat(imgName,'_reconstructed'));
    %fmt = getappdata(imgOpen,'type');
    %imwrite(recon,saveRecon,fmt)

    %Make another figure for the curvelet overlay:
    %guiOver = figure('Resize','on','Units','pixels','Position',[215 420 300 300],'name','CurveAlign Overlay','MenuBar','none','NumberTitle','off','UserData',0);
    %guiOver = figure('Resize','on','Units','pixels','Position',[215 90 600 600],'name','CurveAlign Overlay','NumberTitle','off','UserData',0);
    disp('Plotting overlay');
    guiOver = figure(1);
    overPanel = uipanel('Parent', guiOver,'Units','normalized','Position',[0 0 1 1]);
    overAx = axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);
    %overAx = gca();
    IMG = imadjust(IMG);
    %imshow(IMG,'Parent',overAx);
    imshow(IMG);
    hold on;
    %hold(overAx);
    len = size(IMG,1)/64; %defines length of lines to be displayed, indicating curvelet angle
    
    plot(overAx,coords(:,1),coords(:,2),'y');
    plot(overAx,coords(:,1),coords(:,2),'*y');
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
    %save the image to file
    saveOverlayFname = fullfile(tempFolder,strcat(imgName,'_overlay.tiff'));
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(IMG)/128]);
    print(gcf,'-dpng', '-r128', saveOverlayFname);
    hold off;

    disp('Plotting map');
    %Put together a map of alignment with respect to the
    map = drawMap(inCurvs, angles, IMG);
    guiMap = figure(2);
    mapPanel = uipanel('Parent', guiMap,'Units','normalized','Position',[0 0 1 1]);
    mapAx = axes('Parent',mapPanel,'Units','normalized','Position',[0 0 1 1]);
    IMG2 = ind2rgb(IMG,gray(2^16-1));
    imshow(IMG2);
    hold on;
    clrmap = zeros(256,3);
    tg = ceil(20*255/90); ty = ceil(45*255/90); tr = ceil(60*255/90);
    clrmap(tg:ty,2) = clrmap(tg:ty,2)+1;
    clrmap(ty+1:tr,1:2) = clrmap(ty+1:tr,1:2)+1;
    clrmap(tr+1:256,1) = clrmap(tr+1:256,1)+1;    
    h = imshow(map,clrmap);
    alpha(h,0.5);
    %set(h, 'AlphaData', 0.25);
    disp('Saving map');
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(IMG)/128]);
    saveMapFname = fullfile(tempFolder,strcat(imgName,'_map.tiff'));
    print(gcf,'-dpng', '-r128', saveMapFname);
    hold off;
    %imwrite(uint8(map),fullfile(tempFolder,strcat(imgName,'_map.tiff')),'tif'); 
    

    %Compass plot
    U = cosd(xout).*n;
    V = sind(xout).*n;
    comps = vertcat(U,V);
    saveComp = fullfile(tempFolder,strcat(imgName,'_compass_plot.csv'));
    csvwrite(saveComp,comps);

    %Values and stats Output
    values = angles;
    stats = makeStats2(values,tempFolder,imgName,map);
    saveValues = fullfile(tempFolder,strcat(imgName,'_values.csv'));
    csvwrite(saveValues,[values distances]);
                     

end