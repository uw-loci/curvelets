function IPoints = intersection(Xa, Fa)
% INTERSECTION - takes all the nucleation points, including those that are
% created when the fibers are extended, and the fibers, and return the
% intersection points

%disp(Xa);

sizefa = size(Fa);

NPsize = size(Xa);
NPmark = zeros(NPsize(1),1);

for i = 1:sizefa(2)
    sizeEachFiber = size(Fa(i).v);
    for j = 1:sizeEachFiber(2)
        NPmark(Fa(i).v(j)) = NPmark(Fa(i).v(j)) + 1;
    end
end

k = 0;
for j = 1:NPsize(1)
    if NPmark(j,1) > 1
        k = k + 1;
        %disp(Xa(j,:));
    end
end
count = zeros(k,3);
j = 1;
for i = 1:NPsize(1)
    if NPmark(i) > 1
        count(j,1) = Xa(i,1);
        count(j,2) = Xa(i,2);
        count(j,3) = Xa(i,3);
        j = j + 1;
    end
end
%disp(count);
IPoints = count;



