MATLAB Compiler

1. Prerequisites for Deployment 

. Verify the MATLAB Compiler Runtime (MCR) is installed and ensure you    
  have installed version 7.16.   

. If the MCR is not installed, run MCRInstaller, located in:

  <matlabroot>*\toolbox\compiler\deploy\win64\MCRInstaller.exe

For more information about the MCR and the MCR Installer, see 
“Working With the MCR” in the MATLAB Compiler User’s Guide.    


NOTE: You will need administrator rights to run MCRInstaller. 


2. Files to Deploy and Package

Files to package for Standalone 
================================
-CurveAlign_v2.exe
-MCRInstaller.exe 
   -include when building component by clicking "Add MCR" link 
    in deploytool
-This readme file 

3. Definitions

For information on deployment terminology, go to 
http://www.mathworks.com/help. Select your product and see 
the Glossary in the User’s Guide.


* NOTE: <matlabroot> is the directory where MATLAB is installed on the target machine.





