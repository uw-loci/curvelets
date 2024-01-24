Some modules in CurveAlign/CT-FIRE need to call python modules from the MATLAB e.g. for fiber intersection points calculation, cell and fiber tracking, and etc.

Here are some tips:

(1) The python environment for each module needs to created and discoverable.

(2) Use pyenv command to direct MATLAB to specific python environment.

(3) Insert addtional direcotries to the python search path for user-defined modules or other modules not included in the current environment.

(4) Use the GUI in the CurveAlign tool to load/terminate/update the MATLAB python environment as needed.
