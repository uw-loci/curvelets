function testResults = IPTestFunction(Faip, Xaip, intersectionPoint2)

XaipLength = size(Xaip);
sizefaip = size(Faip);
sizeIP = size(intersectionPoint2);

for i = 1:XaipLength(1)
    inteX = floor(Xaip(i,1));
    fractX = Xaip(i,1) - inteX;
    if fractX >= 0.5
        indeX = inteX + 1;
    else
        indeX = inteX;
    end
    inteY = floor(Xaip(i,2));
    fractY = Xaip(i,2) - inteY;
    if fractY >= 0.5
        indeY = inteY + 1;
    else
        indeY = inteY;
    end
    inteZ = floor(Xaip(i,3));
    fractZ = Xaip(i,3) - inteZ;
    if fractZ >= 0.5
        indeZ = inteZ + 1;
    else
        indeZ = inteZ;
    end
    Xaip(i,1) = indeX;
    Xaip(i,2) = indeY;
    Xaip(i,3) = indeZ;
end

for i = 1:sizefaip(2)
    sizeEachFiber = size(Faip(i).v);
    disp(Faip(i))
    for j = 1:sizeEachFiber(2)
        for k = 1:sizeIP(1)
            if (Xaip(Faip(i).v(j)) == intersectionPoint2(k))
                disp(intersectionPoint2(k, 1) + " " + intersectionPoint2(k, 2) + " " + intersectionPoint2(k, 3))
            end
        end
    end
    disp(" ")
    disp(" ")
end

testResults = intersectionPoint2;