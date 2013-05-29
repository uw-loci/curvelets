function[F] = mergefiber(F,V,f1,f2)
%MERGEFIBER - merges 2 fibers together so that they meet at the vertex
%the two have in common
%vm = the vertex in between the two fibers
%ve = the new end vertex for fiber1
    fiber1 = F(f1).v;
    fiber2 = F(f2).v;

    if length(fiber1)>=1 & length(fiber2)>=1
        if fiber1(1) == fiber2(1)
            fmerge = [fliplr(fiber2(2:end)) fiber1];
        elseif fiber1(1) == fiber2(end)
            fmerge = [fiber2(1:end-1) fiber1];
        elseif fiber1(end)==fiber2(1)
            fmerge = [fiber1(1:end) fiber2(2:end)];
        elseif fiber1(end)== fiber2(end)
            fmerge = [fiber1(1:end) fliplr(fiber2(1:end-1))];
        else
            error('these fibers don''t share an end vertex')
        end
    else
        fmerge = [fiber1 fiber2];
    end
        
%change the vertex list to that the vertex dangling off of fiber 2,
%which has been removed, is now listed as dangling off fiber 1
    F(f1).v = fmerge;
    F(f2).v = [];