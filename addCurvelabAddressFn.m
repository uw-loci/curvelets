function[]=addCurvelabAddressFn(lastPATHname)
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
