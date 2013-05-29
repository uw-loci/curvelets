function[X F V R] = fiber_mergevert(X,F,V,R,s_image,nhoodmerge,plotflag)    
    %first compute pairwise distances between vertices
    %and find where that distance is small
        VM = make_vertexmatrix(X,s_image);        
        mflag = zeros(size(X,1),1); %indicates that x(i) has been removed by merging
  
    %then loop through x and find nearby vertices, merging the two together
    %if thery are close together
        for i=1:size(X,1)
            if mflag(i)==0
                
                iclose = findclose(X,i,nhoodmerge,VM);
                %then merge the two vertices together
                    j=0;
                    for imerge = iclose'
                        j=j+1;
                        if mflag(imerge)==0 %vertex hasn't been merged and disappeared yet
                            mflag(imerge) = 1;
                            v1 = i;
                            v2 = iclose(j);
                            x1 = X(v1,:);
                            x2 = X(v2,:);
                            P  = [x1; x2];

                            
                            ii = [];
                            %ii = [48   871   872   873   874 51   919   920   921];                            
                            if all(ismember([v1 v2],ii));
                                plotflag = 1;
                                cla; plotfiber(X,F,3,0,[],'o')
                                1;
                            end
                            
                            
                            if plotflag==1
                                plot3(x1(1),x1(2),x1(3),'yo','LineStyle','-','Color','k','MarkerFaceColor','y','MarkerSize',15);
                                plot3(x2(1),x2(2),x2(3),'ys','LineStyle','-','Color','k','MarkerFaceColor','y','MarkerSize',15);
                                pause(.001)
                            end
                            
                            [F V] = mergevertex(F, V, v1, v2, X);

                            X(v1,:) = ((x1+x2)/2);
                            X(v2,:) = ((x1+x2)/2);                            
                            %update VM
                                xnew    = round(X(v1,:));
                                xold    = round(x1);
                                VM(xold(3),xold(2),xold(1)) = 0;
                                VM(xnew(3),xnew(2),xnew(1)) = v1;  
                            
                            if plotflag==1
                                plotfiber(X,F,3,0,[],'o')
                                xnew = X(v1,:);
                                plot3(xnew(1),xnew(2),xnew(3),'ko','MarkerSize',15,'MarkerFaceColor','g');
                                plotflag = 0;
                            end                            
                        end
                    end                    
            end
        end
                            
    
    %finally, trim vertices
        [X F V R] = trimxfv(X,F,[],R);
end
