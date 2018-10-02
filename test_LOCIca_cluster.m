% test_LOCIca_cluster.m
clear,clc,home;
% create parameter file file
jobtarfile = '1045(-)1v2_Job-1test.tar';
imageextension = '.tif';
AnalysisMode = '3';

LOCIca_cluster(jobtarfile,imageextension,AnalysisMode)
