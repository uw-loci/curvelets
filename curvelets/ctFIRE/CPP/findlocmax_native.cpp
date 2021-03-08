#include "mex.h"
#include <cstdint>
#include <vector>
#include <array>
#include <omp.h>
// Matlab is colomn major.
template<typename T,int d>
struct FindLocalMax
{
    static constexpr T epsilon = 1e-3;
    inline int fastrand(int& g_seed) { 
        g_seed = (214013*g_seed+2531011); 
        return (g_seed>>16)&0x7FFF; 
    } 
    FindLocalMax(int sizex,int sizey,int sizez, T* image,std::vector<std::array<int,d>>& pts,int radius,T dmin)
    {
        static_assert(d==3,"");
    }
    FindLocalMax(int sizey,int sizez, T* image,std::vector<std::array<int,d>>& pts,int radius,T dmin)
    {
        static_assert(d==2,"");
        const int nThreads = omp_get_max_threads();
        std::vector<int> seeds(nThreads);
        for(int i = 1;i < nThreads;++i) seeds[i] = fastrand(seeds[0]);
        #pragma omp parallel for
        for(int i = 0;i < sizez;++i){
            const int tid = omp_get_thread_num();
            for(int j = 0;j < sizey;++j){
                const uint64_t offset = sizey * i + j;
                image[offset] += epsilon * T(fastrand(seeds[tid]))/T(0x7FFF);}}

        std::vector<std::vector<std::array<int,d>>> thread_buffer(nThreads);
        #pragma omp parallel for
        for(int i = 0;i < sizez;++i){
            const int tid = omp_get_thread_num();
            for(int j = 0;j < sizey;++j){
                const uint64_t offset = sizey * i + j;
                if(image[offset] < dmin) continue;
                bool local_max = true;
                for(int ii = -radius;ii <= radius&&local_max;++ii){
                    const int z=ii+i;
                    if(z>=0&&z<sizez){
                        for(int jj = -radius;jj <= radius&&local_max;++jj){
                            if(ii == 0 && jj == 0) continue;
                            const int y=jj+j;                        
                            if(y>=0&&y<sizey){
                                uint64_t neighbor_offset = z * sizey + y;
                                if(image[offset] <= image[neighbor_offset])
                                    local_max = false;}}}}
                if(local_max) {thread_buffer[tid].push_back({i+1,j+1});}}}//matlab wants one based indexing

        pts.clear();
        for(int t = 0;t < nThreads;++t)
            for(int i = 0;i < thread_buffer[t].size();++i)
                pts.push_back(thread_buffer[t][i]);
    }
};
void mexFunction(int nlhs,mxArray* plhs[],
                 int nrhs,const mxArray* prhs[])
/*
  input:
      double sizex,
      double sizey,
      double sizez,
      double image[][],
      double radius,
      double dmin
*/
{
    if(nrhs!=6) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:nrhs","Six inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:nlhs","One output required.");
    }
    
    if( !mxIsDouble(prhs[0]) || 
        mxIsComplex(prhs[0]) ||
        mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:notScalar","Input channels must be a scalar.");
    }
    const uint64_t sizex=mxGetScalar(prhs[0]);
    if( !mxIsDouble(prhs[1]) || 
        mxIsComplex(prhs[1]) ||
        mxGetNumberOfElements(prhs[1])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:notScalar","Input width must be a scalar.");
    }
    const uint64_t sizey=mxGetScalar(prhs[1]);
    if( !mxIsDouble(prhs[2]) || 
        mxIsComplex(prhs[2]) ||
        mxGetNumberOfElements(prhs[2])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:notScalar","Input height must be a scalar.");
    }
    const uint64_t sizez=mxGetScalar(prhs[2]);
    if( !mxIsDouble(prhs[4]) || 
        mxIsComplex(prhs[4]) ||
        mxGetNumberOfElements(prhs[4])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:notScalar","Input radius must be a scalar.");
    } 
    const int radius=mxGetScalar(prhs[4]);
    if( !mxIsDouble(prhs[5]) || 
        mxIsComplex(prhs[5]) ||
        mxGetNumberOfElements(prhs[5])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:notScalar","Input minimum distance must be a scalar.");
    } 
    const double dmin=mxGetScalar(prhs[5]);
    mexPrintf("image size: %i x %i x%i.\n",sizex,sizey,sizez);
    mexPrintf("radius: %i. minimum distance: %f.\n",radius,dmin);
    mexPrintf("mxClassID of the image: %i.\n",mxGetClassID(prhs[3]));
    if(mxGetNumberOfElements(prhs[3])!=sizex*sizey*sizez){
        mexErrMsgIdAndTxt("MyToolbox:findlocalmax:dimensionMismatch","Input image and imput dimension mismatched.");
    }
    std::vector<std::array<int,2>> pts;
    std::vector<std::array<int,3>> pts_3D;
    switch(mxGetClassID(prhs[3])){
    case mxSINGLE_CLASS: 
        if(sizex==1)
            FindLocalMax<float,2>((int)sizey,(int)sizez,(float*)mxGetPr(prhs[3]),pts,radius,(float)dmin);
        else
            FindLocalMax<float,3>((int)sizex,(int)sizey,(int)sizez,(float*)mxGetData(prhs[3]),pts_3D,radius,(float)dmin);
        break;
    }
    if(sizex==1){
        mwSize out_size[2]={pts.size(),3};
        plhs[0] = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
        int32_t* ptr = (int32_t*)mxGetData(plhs[0]);
        #pragma omp parallel for
        for(int i = 0;i < pts.size();++i){
            ptr[i]              = pts[i][0];
            ptr[i+pts.size()]   = pts[i][1];
            ptr[i+2*pts.size()] = 1;
        }
    }
    
}
