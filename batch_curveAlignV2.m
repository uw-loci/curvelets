%batch the curvelet process

function batch_curveAlignV2()
topLevelDir = 'P:\Conklin- batch processing template files\';
%topLevelDir = '.\';
%get directory list in top level dir
dateList = dir(topLevelDir);

prompt = {'Enter keep value:','Enter distance thresh (pixels):','Boundary associations? (0 or 1):','Num to process (for demo purposes):'};
dlg_title = 'Input for batch CA';
num_lines = 1;
def = {'0.05','137','0','1e7'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
    disp('Cancelled by user');
    return;
end
keep = str2num(answer{1});
distThresh = str2num(answer{2}); %pixels
makeAssoc = str2num(answer{3});
numToProc = str2num(answer{4});

fileNum = 0;
for i = 1:length(dateList)
%for i = 1:1
    if isequal(regexp(dateList(i).name,'_'),[3 6]) && length(dateList(i).name) == 8
        %if the 3rd and 6th chars are underscores, trust this as a real directory
        curDir = [topLevelDir dateList(i).name];
        
        outDir = [curDir '\curve_align_v2_results'];
        if ~exist(outDir,'dir')
            mkdir(outDir);
        end        
        
        fileList = dir(curDir);
        for j = 1:length(fileList)        
            if regexp(fileList(j).name,'Boundary for') > 0
                fileNum = fileNum + 1;
                bdryName = fileList(j).name;
                disp(['file number = ' num2str(fileNum,1)]);
                disp(['boundary name = ' bdryName]);
                if regexp(bdryName,'normal') > 0
                    imageName = [dateList(i).name ' Trentham ' fileList(j).name(14:length(fileList(j).name)-4) '.tif'];
                    img = imread([curDir '\' imageName]);
                    coords = csvread([curDir '\' bdryName]);
                    [histData,~,~,values,distances,~] = processImage(img, imageName, outDir, keep, coords, distThresh);
                    %normStruct(fileNum).bdryName = bdryName;
                    %normStruct(fileNum).imageName = imageName;
                    %normStruct(fileNum).angles = values;
                    %normStruct(fileNum).distances = distances;
                    %save([topLevelDir 'normCAV2_results.mat'],'normStruct');
                else
                    imageName = [dateList(i).name ' Trentham DCIS ' fileList(j).name(14:length(fileList(j).name)-4) '.tif'];
                    img = imread([curDir '\' imageName]);
                    coords = csvread([curDir '\' bdryName]);
                    [histData,~,~,values,distances,~] = processImage(img, imageName, outDir, keep, coords, distThresh);
                    %dcisStruct(fileNum).bdryName = bdryName;
                    %dcisStruct(fileNum).imageName = imageName;
                    %dcisStruct(fileNum).angles = values;
                    %dcisStruct(fileNum).distances = distances;
                    %save([topLevelDir 'dcisCAV2_results.mat'],'dcisStruct');                    
                end
                allHistData(:,fileNum) = histData(:,2);
                allNameStruct(fileNum).name = imageName;
                disp(['done processing ' imageName]);
                if fileNum == numToProc
                    break;
                end
            end
        end        
    end
end
disp(['processed ' num2str(fileNum) ' images.']);
writeAllHistData(allHistData,histData(:,1),allNameStruct,topLevelDir);


function [histData,recon,comps,values,distances,stats] = processImage(IMG, imgName, tempFolder, keep, coords, distThresh)

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
    
    %save the image to file
    saveOverlayFname = fullfile(tempFolder,strcat(imgName,'_overlay.tiff'));
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 size(IMG)/128]);
    print(gcf,'-dtiff', '-r128', saveOverlayFname);
    hold off;

    %Put together a map of alignment with respect to the
    map = drawMap(inCurvs, angles, IMG);
    imwrite(uint8(map),fullfile(tempFolder,strcat(imgName,'_map.tiff')),'tif');               

    %Compass plot
    U = cosd(xout).*n;
    V = sind(xout).*n;
    comps = vertcat(U,V);
    saveComp = fullfile(tempFolder,strcat(imgName,'_compass_plot.csv'));
    csvwrite(saveComp,comps);

    %Values and stats Output
    values = angles;
    stats = makeStats(values,tempFolder,imgName);
    saveValues = fullfile(tempFolder,strcat(imgName,'_values.csv'));
    csvwrite(saveValues,[values distances]);
                     

end


function writeAllHistData(hist,bins,name_list,topLevelDir)
    fid = fopen([topLevelDir 'AllHistData.txt'],'w+');
    
    %write first line of file with all the file names
    fprintf(fid,'%s\t','bin');
    for ii = 1:length(name_list)
        fprintf(fid,'%s\t',name_list(ii).name);
    end
    fprintf(fid,'\r\n');
    
    for ii = 1:size(hist,1)
        fprintf(fid,'%.2f\t',bins(ii));
        for jj = 1:size(hist,2)
            fprintf(fid,'%d\t',hist(ii,jj));
        end
        fprintf(fid,'\r\n');
    end
    
    fclose(fid);
end
end