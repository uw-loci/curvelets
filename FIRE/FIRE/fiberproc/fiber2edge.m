function[E Vout] = fiber2edge(F,V)
%FIBER2EDGE - converts a fiber array to an edge array, where the vertices
%of the edge array are the points of intersection of the fibers
if isempty(F)
    E = [];
    Vout = [];
    return
end

ei = 0;
for i=1:length(V)
    Vout(i).v = [];
    Vout(i).e = [];
    Vout(i).f = [];
end
for i=1:length(V)
    V(i).b = 0;
end
for i=1:length(F)
    v1 = F(i).v(1);
    v2 = F(i).v(end);
    V(v1).b=1;
    V(v2).b=1;
end

for fi=1:length(F)
    v = F(fi).v;
    nv= 0;
    for vj=v
        nj = length( unique(V(vj).f)); %number of fibers passing through v(j)
        if nj > 1 | V(vj).b>0 %if vertex contains 2 fibers or if vertex is on boundary
            if nv==0 %no vertices yet that intersect two fibers
                v1 = vj;
                nv=nv+1;
            else %nv>0
                ei = ei+1;
                v2 = v1;
                v1 = vj;
                E(ei,:) = [v1 v2]; %vertex 1, vertex 2, fiber number
                Vout(v1).v(end+1) = v2;
                Vout(v1).e(end+1) = ei;
                Vout(v1).f(end+1) = fi;
                Vout(v2).v(end+1) = v1;
                Vout(v2).e(end+1) = ei;
            end            
        end
    end
end
    