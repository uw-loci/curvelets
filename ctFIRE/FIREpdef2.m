% FIREpdef.m
% load .xlsx file associated with param.FIREdef
clear;clc;
xlsfile = 'FIREdefparam.xlsx';
[~,~,FIREpxls]=xlsread(xlsfile,1,'A1:D27');  % the xlsfile has 27 rows and 4 column:
% C1: number of the parameter; C2: parameter name; C3: parameter value; C4: brief description of the paremeter


% create a structure including all the xlsx file information
FIREpdefs = struct('num',[],'name',[],'value',[],'desc',[]);
pfields1 = {'num','name','value','desc'};
FIREpdefs = cell2struct(FIREpxls,pfields1,2);


%% get 3 structures for the paremeters' number, value, description 
FIREpdefnum = struct([]);FIREpdefvalue = struct([]);FIREpdefdesc = struct([]);
pfields =FIREpxls(:,2)';  % field name

% get the parameter's number
FIREpxlsnum = FIREpxls(:,1);
FIREpdefnum = cell2struct(FIREpxlsnum,pfields,1);

%get value of each field from xls file
FIREpxlsvalue = FIREpxls(:,3);
%the value of C1-(r4,r10,r14,r19,r22) need to convert from 'char' type to numerical type 
%  tcnum = [4,10,14,19 ,22]; % type convert numbers, which will be used in FIRE code.
 tcnum = [4,22]; % type convert numbers, which will be used in FIRE code.
  %,10,14,19 , use degree of the angle, instead of cos(degree*pi/180),do this change in the GUI code
  
% for ii = tcnum
%     temp = FIREpxlsvalue{ii};
%     FIREpxlsvalue{ii} = str2num(temp);
% end
FIREpdefvalue = cell2struct(FIREpxlsvalue,pfields,1);

%get description of each field from xls file

FIREpxlsdesc = FIREpxls(:,4);
FIREpdefdesc = cell2struct(FIREpxlsdesc,pfields,1);


pnum = FIREpdefnum;
pvalue =FIREpdefvalue;
pdesc = FIREpdefdesc;


save FIREpdefault.mat 'pvalue' 'pdesc' 'pnum' 'tcnum'
clear 
load FIREpdefault.mat

% whos pvalue pdesc pnum tcnum


