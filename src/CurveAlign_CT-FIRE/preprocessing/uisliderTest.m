%uisliderTest.m
%%
fig = uifigure('Position',[500 500 400 200]);
slider1 = uislider(fig,'position',[200 110 110 3]);
% nChannels = 3;
% nTimepoints = 100;
nFocalplanes = 10;
lbl_Focalplanes = uilabel(fig,'Position',[30 100 80 20],'Text','Focalplanes');
numField_3 = uieditfield(fig,'numeric','Position',[115 100 50 20],'Limits',[1 nFocalplanes],...
    'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event,slider1));

%for Focalplanes
nMajorTickLabels = min(5,nFocalplanes);
MajorTickLabelsValue = [1:floor(nFocalplanes/nMajorTickLabels):nFocalplanes];
set(slider1,'Limits',[1 nFocalplanes],'MajorTickLabelsMode','auto',...
    'MajorTicks',MajorTickLabelsValue,'MinorTicksMode','manual',...
    'ValueChangedFcn',@(slider1,event) slideMoving(slider1,numField_3));


% Create ValueChangedFcn callback
function slideMoving(slider1,numField_3)
numField_3.Value = round(slider1.Value);
slider1.Value = numField_3.Value;
end
%

% get focalplanes
function getFocalPlanes_Callback(numField_3,event,slider1)
%         valList{3} = event.Value;
slider1.Value = event.Value ;
numField_3.Value = event.Value;
slideMoving(slider1,numField_3);
sprintf('%s : %d', 'User entered:', numField_3.Value);

end

