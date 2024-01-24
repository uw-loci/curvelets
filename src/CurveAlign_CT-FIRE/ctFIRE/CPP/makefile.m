% for macOS, user must have openmp installed. Installation instructions on https://mac.r-project.org/openmp/ 
if ~ismac
    mex -v findlocmax_native.cpp CXXFLAGS="$CXXFLAGS -fopenmp" LDFLAGS="$LDFLAGS -fopenmp"
    mex -v extend_xlink_native.cpp CXXFLAGS="$CXXFLAGS -fopenmp" LDFLAGS="$LDFLAGS -fopenmp"
else 
    mex -v findlocmax_native.cpp CPPFLAGS="$CPPFLAGS -Xclang -fopenmp" LDFLAGS="$LDFLAGS -lomp"
    mex -v extend_xlink_native.cpp CPPFLAGS="$CPPFLAGS -Xclang -fopenmp" LDFLAGS="$LDFLAGS -lomp"
end 