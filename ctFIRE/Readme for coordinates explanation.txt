Format of ROI coordinate text file-

for each ROI-
1. combined_roi or simple - 1 if combined and 0 if simple
2. number of roi - 1 if simple roi and the roi's number in a combined ROI
3. date
4. time
5. shape of ROI- 1 if rectangle ,2 if freehand, 3 if ellipse and 4 if polygon
6. roi coordinate
7. newline character \n - 

Eg- 
0
1
5-30-2015
11:24:24
1
1.040000e+02 189 209 1.440000e+02 

this means
1 '0' because ROI is simple and not a combined one
2 '1' because it is the only ROI in the simple ROI
3 created on 30th March 2015
4 time of creation - 11:24:24
5 '1' means it is a rectangular ROI
6 point(104,189) and point (209,144) are the two diagonals of the rectangle

For more info on ellipse coordinates please refer to the code of roi_gui_v3.m in cell_selection_fn-

		data2=separate_rois.(Data{handles.Indices(k,1),1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(image,1);s2=size(image,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end