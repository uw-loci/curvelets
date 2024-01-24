% prepAngs.m
% find the the curvelets located in the outer ROI
% Inputs:
% cent = curvelet centers
% angs = curvelet angles
% region = outer ROI
%
% Outputs:
% angles = angles of curvelets located in outer ROI
% centers = centers of curvelets in outer ROI
% Ind = indices of curvelets in outer ROI
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function [angles,varargout] = prepAngs(cent, angs, region)

if iscell(region)
    for aa = 1:length(region)
    % find the locations of all pixels in the outer ROI
    [rr CC] = find(region{aa});
    ROI{aa} = [rr CC];
    % find all curvelet centers that lie within the outer
    % ROI
    IsIn{aa} = ismember(cent,ROI{aa},'rows');
    Ind{aa} = find(IsIn{aa});
    % find the centers and angles of all curvelets within outer ROI
    angles{aa} = mean(fixAngle(angs(Ind{aa}),5));
    centers{aa} = cent(Ind{aa},:);
    varargout(1) = {centers};
    end
else
    [rr CC] = find(region);
    ROI = [rr CC];
    % find all curvelet centers that lie within the outer
    % ROI
    IsIn = ismember(cent,ROI,'rows');
    Ind = find(IsIn);
    % find the centers and angles of all curvelets within outer ROI
    angles = angs(Ind);
    centers(:,:) = cent(Ind(:),:);
    varargout(1) = {centers};
    varargout(2) = {Ind};
end
end
