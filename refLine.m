function refLine(vVector,varargins)
global reference;

if nargin == 0
reference = imdistline(gca);
end
    
   