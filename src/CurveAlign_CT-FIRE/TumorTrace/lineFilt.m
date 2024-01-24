% lineFilt.m
% apply Savitzky-Golay smoothing filter
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function plots = lineFilt(vals)

plots = sgolayfilt(vals,3,101);

end