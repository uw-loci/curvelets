function saveRelativemeasurements(ROImeasurements,ROIlist,fiberObject,saveOptions)
% saveRelativemeasurements.m function saves outputs from function
% "getAlignment2ROI.m" to a excel file and a image
%Inputs:
% ROImeasurements: measurements from the getAlignment2ROI function
% ROIlist:list of ROIs, structures with 
% fiberObject- a structure with fiber centers and angles; % center = [y x]
% saveOptions: a structure with saveDataFlag,saveFigureFlag,overwriteFlag,
% outputFolder,originalImagename,outputdataFilename,outputfigureFilename
% saveOptions= struct('saveDataFlag',1,'saveFigureFlag', 0,'overwriteFlag',1,...
%     'outputFolder',[],'originalImagename',[],'outputdataFilename',[],...
%     'outputfigureFilename',[])

% example shown in getTifBoundary.m
%By Laboratory for Optical and Computational Instrumentation, UW-Madison
%since 2009

if nargin < 3
    error('number of inputs should be no less than 3')
elseif nargin > 4
    error('number of inputs should be no more than 4')
end
if saveOptions.saveDataFlag == 0 && saveOptions.saveFigureFlag == 0
    disp('NO relative measurements are saved. ')
    return
end

nROI = length(ROIlist);
OBJlist = fiberObject;
fprintf(' The relative angles of fibers within the specified distance to each boundary include \n' )
fprintf(' 1) angle to the nearest point on the boundary \n')
fprintf(' 2) angle to the boundary mask orientaiton \n')
fprintf(' 3) angle to the line conecting the fiber center and boundary mask center \n')
%
saveBWmeasurementsData = fullfile(saveOptions.outputFolder,saveOptions.outputdataFilename);
if exist(saveBWmeasurementsData,'file') == 2 && saveOptions.overwriteFlag == 1
    delete(saveBWmeasurementsData)
end
ROImeasurementsDetails = repmat(struct('angle2boundaryEdge',[],'angle2boundaryCenter',[],...
    'angle2centersLine',[],'fibercenterRow',[],'fibercenterCol',[],...
    'fiberangleList',[],'distanceList',[],'boundaryPointRow',[],...
    'boundaryPointCol',[]),nROI,1);
ROImeasurements_fieldnames = fieldnames(ROImeasurementsDetails);
nFields_details = length(ROImeasurements_fieldnames);
ROIsummary = repmat(struct('name',[],'centerRow',[],'centerCol',[],'orientation',[],'area',[],...
    'meanofangle2boundaryEdge',[],'meanofangle2boundaryCenter',[],...
    'meanofangle2centersLine',[],'nFibers',[]),nROI,1);
ROIsummary_fieldnames = fieldnames(ROIsummary);
nFields_summary = length(ROIsummary_fieldnames);
measurementsData_summary = nan(nROI,nFields_summary);
%save summary variable names to an xlsx file
writecell(ROIsummary_fieldnames',saveBWmeasurementsData,'Sheet','Boundary-summary','Range','A1')
for i = 1:nROI
    % ROIlist.coords = coords{i};
    % ROIlist.imWidth = size(IMG,2);
    % ROIlist.imHeight = size(IMG,1);
    %get ROI properties
    imageI = zeros(ROIlist(i).imHeight,ROIlist(i).imWidth);
    roiMask = roipoly(imageI,ROIlist(i).coords(:,2),ROIlist(i).coords(:,1));
    roiProps = regionprops(roiMask,'all');
    if length(roiProps) == 1
        ROIsummary(i,1).name = saveOptions.annotationIndex;
        ROIsummary(i,1).centerRow = roiProps.Centroid(1,2); % Y
        ROIsummary(i,1).centerCol = roiProps.Centroid(1,1); % X
        ROIsummary(i,1).orientation = roiProps.Orientation;
        % convert to [0 180]degrees
        if ROIsummary(i,1).orientation < 0
            ROIsummary(i,1).orientation = 180+ROIsummary(i,1).orientation;
        end
        ROIsummary(i,1).area = roiProps.Area;
    else
        error('The coordinates should be from a signle region of interest')
    end
    if ~isempty(ROImeasurements)
        %details
        ROImeasurementsDetails(i,1).angle2boundaryEdge = ROImeasurements.angle2boundaryEdge;
        ROImeasurementsDetails(i,1).angle2boundaryCenter = ROImeasurements.angle2boundaryCenter;
        ROImeasurementsDetails(i,1).angle2centersLine = ROImeasurements.angle2centersLine;
        ROImeasurementsDetails(i,1).fibercenterRow = ROImeasurements.fibercenterList(:,1); %Y
        ROImeasurementsDetails(i,1).fibercenterCol = ROImeasurements.fibercenterList(:,2); %X
        ROImeasurementsDetails(i,1).fiberangleList = ROImeasurements.fiberangleList;
        ROImeasurementsDetails(i,1).distanceList = ROImeasurements.distanceList;
        ROImeasurementsDetails(i,1).boundaryPointRow = ROImeasurements.boundaryPoints(:,1); %Y
        ROImeasurementsDetails(i,1).boundaryPointCol = ROImeasurements.boundaryPoints(:,2); %X
        %summary
        ROIsummary(i,1).meanofangle2boundaryEdge = nanmean(ROImeasurements.angle2boundaryEdge);
        ROIsummary(i,1).meanofangle2boundaryCenter = nanmean(ROImeasurements.angle2boundaryCenter);
        ROIsummary(i,1).meanofangle2centersLine = nanmean(ROImeasurements.angle2centersLine);
        ROIsummary(i,1).nFibers = ROImeasurements.nFibers;

        %save details to xlsx file
        writecell(ROImeasurements_fieldnames',saveBWmeasurementsData,'Sheet',sprintf('Boundary%d-details',saveOptions.annotationIndex),'Range','A1')
        measurementsData = [];%nan(ROImeasurements.nFibers,nFields_details);
        for iField = 1:nFields_details
            fieldData = ROImeasurementsDetails(i,1).(ROImeasurements_fieldnames{iField});
            if ~isempty(fieldData)
                measurementsData(:,iField) = fieldData;
            else
                fprintf('%s of boundary %d is empty \n',ROImeasurements_fieldnames{iField},saveOptions.annotationIndex);
            end
        end
        writematrix(measurementsData,saveBWmeasurementsData,'Sheet',sprintf('Boundary%d-details',saveOptions.annotationIndex),'Range','A2')
        %summary data
        for iField = 1:nFields_summary
            fieldData = ROIsummary(i,1).(ROIsummary_fieldnames{iField});
            if ~isempty(fieldData)
                measurementsData_summary(i,iField) = fieldData;
            else
                fprintf('%s of boundary %d is empty \n',ROIsummary_fieldnames{iField},i);
            end
        end
    end
end
% save ROI summary data
writematrix(measurementsData_summary,saveBWmeasurementsData,'Sheet','Boundary-summary','Range','A2')
% save boundary-object overlay figure
if saveOptions.saveFigureFlag == 1
    saveBWmeasurementsFigure = fullfile(saveOptions.outputFolder,saveOptions.outputfigureFilename);
    % save the ROI and fiber postions to a tiff file
    figBF = findobj(0,'Tag','BoundaryAngles');
    if isempty(figBF)
        figBF = figure('Name','CurveAlign relative angles to a boundary region',...
            'Tag','BoundaryAngles','Visible','on','NumberTitle','off');
        imshow(fullfile(saveOptions.imageFolder,saveOptions.originalImagename),'Border','tight');
        axis off
        hold on
    else
        figure(figBF)
        hold on
    end
    set(figBF,'Position',[400 300 ROIlist(1).imWidth ROIlist(1).imHeight])
    %show all ROIs and fibers locations
    for iR = 1:nROI
        coords = ROIlist(iR).coords;
        plot(coords(:,2),coords(:,1),'y-')  % X-coords(:,2) Y-coords(:,1)
        % text(ROIsummary(i,1).centerCol,ROIsummary(i,1).centerRow,sprintf('%d',iR),...
        %     'FontWeight','bold','Color','y','FontSize',7)
        fibercenterList = [ROImeasurementsDetails(iR,1).fibercenterRow ROImeasurementsDetails(iR,1).fibercenterCol]; %Y X
        fiberangleList  = ROImeasurementsDetails(iR,1).fiberangleList;
        boundaryPointsList = [ROImeasurementsDetails(iR,1).boundaryPointRow ROImeasurementsDetails(iR,1).boundaryPointCol]; % Y X
        len = 5;
        for i = 1:length(fibercenterList)
            objectCenter = fibercenterList(i,:); % [y x]
            objectAngle = fiberangleList(i);
            % objectVector = 15*[cos(objectAngle*pi/180) -sin(objectAngle*pi/180) 0];
            % drawline("Color",'g','Position',[0+objectCenter(1) 0+objectCenter(2); objectVector(1)+objectCenter(1) objectVector(2)+objectCenter(2)])
            objectStart = [objectCenter(2)+len*cos(objectAngle*pi/180),objectCenter(1)-len*sin(objectAngle*pi/180)]; %[x y]
            objectEnd = [objectCenter(2)-len*cos(objectAngle*pi/180),objectCenter(1)+len*sin(objectAngle*pi/180)];   % [x y]
            plot([objectStart(1);objectEnd(1)],[objectStart(2);objectEnd(2)],'g-','LineWidth',0.5)
            % plot(objectCenter(1),objectCenter(2), 'Color','r','MarkerSize', 2);
            if saveOptions.plotAssociationFlag == 1
                boundaryPoint = boundaryPointsList(i,:);
                plot([objectCenter(2);boundaryPoint(2)],[objectCenter(1);boundaryPoint(1)],'b-')
            end
        end
        hold off
        saveBWmeasurementsFigure = fullfile(saveOptions.outputFolder,saveOptions.outputfigureFilename);
        set(figBF,'PaperUnits','inches','PaperPosition',[0 0 ROIlist(1).imWidth/200 ROIlist(1).imHeight/200]);
        print(figBF,'-dtiffn', '-r200', saveBWmeasurementsFigure)
    end

end

end