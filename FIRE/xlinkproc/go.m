addpath ../fiberproc:../graphics:../initproc:../xlink:../beamproc:../measure:../networks:../fiber_manualproc:../scripts


iold = i;
i=5;
X = XA{i};
F = FA{i};
V = VA{i};

if ~exist('XA')
    load go_2007june02
    im3 = loadim_2007june02(i);
end


xlink_indic = zeros(length(V),1);

for vi=1:length(V)
    fi = V(vi).f;
    if length(fi) > 1 %we have a x-link
        xlink_indic(vi) = 1;
    end
end

i_xlink = find(xlink_indic==1);

for ix = i_xlink'
    zoomxlink(im3,X,F,V,ix,40,0)
    1;
end
