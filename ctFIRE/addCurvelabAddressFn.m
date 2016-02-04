function[]=addCurvelabAddressFn(lastPATHname)
    %Adds the folder containing CurveLab toolbox to the search path of
    %calling function. Address of CurveLab toolbox is stored in
    %CurveletAddress.mat. If no such file is present then the user is
    %prompted to select the folder conatining the toolbox and the same is
    %saved for future reference in CurveletAddress.mat
    if exist('CurveletAddress.mat','file')
        %use parameters from the last run
        CurveletAddress= importdata('CurveletAddress.mat');

        if isequal(CurveletAddress,0)
            CurveletAddress = '';
        end
    else
        %use default parameters
        CurveletAddress = '';
    end
    if(isempty(CurveletAddress)==1)
         CurveletAddress = uigetdir(lastPATHname,'Select Curvelab Toolbox folder');
         CurveletAddress =[CurveletAddress 'fdct_wrapping_matlab'];
         save('CurveletAddress.mat','CurveletAddress' );
    end
    addpath(CurveletAddress);
end
