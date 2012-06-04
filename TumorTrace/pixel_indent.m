function Coeff = pixel_indent(C,pixin)

% C is the curvelet coefficient matrix and pixin is the number of pixels to
% indent in on each side
% Written by Jared Doot, Laboratory for Optical and Computational
% Instrumentation

for s = 1:length(C)
    for w = 1:length(C{s})
        sub=size(C{s}{w});
        for ii = 1:sub(2);
            C{s}{w}(end-pixin:end,ii)=linspace(C{s}{w}(end-pixin,ii),0,pixin+1);
        end
        for ii = 1:sub(2);
            C{s}{w}(1:1+pixin,ii)=fliplr(linspace(C{s}{w}(1+pixin,ii),0,pixin+1));
        end
        for ii = 1:sub(1);
            C{s}{w}(ii,end-pixin:end)=linspace(C{s}{w}(ii,end-pixin),0,pixin+1);
        end
        for ii = 1:sub(1);
            C{s}{w}(ii,1:1+pixin)=fliplr(linspace(C{s}{w}(ii,1+pixin),0,pixin+1));
        end
    end
end

Coeff = C;