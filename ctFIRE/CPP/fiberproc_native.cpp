#include "mex.h"
#include <cstdint>
#include <vector>
#include <array>
#include <omp.h>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <iostream>
#include <mutex>
void mexFunction(int nlhs,mxArray* plhs[],
                 int nrhs,const mxArray* prhs[])
/*
  input:
      double sizex,
      double sizey,
      double sizez,
      double image[][],
      int X(position)[][3],
      int F(ibres)[],
      T R(adius)[],
      struct p

  output:
      int X(position)[][3],
      int F(ibres)[],
      int E(ibres)[],
      int V(ertices)[],
      T R(adius)[],
*/
{
    if(nrhs!=8) {
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:nrhs","Eight inputs required.");
    }
    if(nlhs!=5) {
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:nlhs","Five outputs required.");
    }    
    if( !mxIsDouble(prhs[0]) ||
        mxIsComplex(prhs[0]) ||
        mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:notScalar","Input channels must be a scalar.");
    }
    const uint64_t sizex=mxGetScalar(prhs[0]);
    if( !mxIsDouble(prhs[1]) ||
        mxIsComplex(prhs[1]) ||
        mxGetNumberOfElements(prhs[1])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:notScalar","Input width must be a scalar.");
    }
    const uint64_t sizey=mxGetScalar(prhs[1]);
    if( !mxIsDouble(prhs[2]) ||
        mxIsComplex(prhs[2]) ||
        mxGetNumberOfElements(prhs[2])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:notScalar","Input height must be a scalar.");
    }
    const uint64_t sizez=mxGetScalar(prhs[2]);
    mexPrintf("image size: %i x %i x%i.\n",sizex,sizey,sizez);
    mexPrintf("mxClassID of the image: %i.\n",mxGetClassID(prhs[3]));
    if(mxGetNumberOfElements(prhs[3])!=sizex*sizey*sizez){
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:dimensionMismatch","Input image and imput dimension mismatched.");
    }
    mexPrintf("mxClassID of the X array: %i.\n",mxGetClassID(prhs[4]));
    if(mxGetN(prhs[4])!=3){
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:dimensionMismatch","Input X must be N x 3.");
    }
    if(mxGetClassID(prhs[4])!=mxINT32_CLASS){
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:dimensionMismatch","Input X must be int32_t.");
    }
    std::vector<std::array<int,2>> X_2D;
    std::vector<std::array<int,3>> X_3D;
    std::vector<std::vector<int>> F;
    std::vector<std::vector<int>> Ff;
    std::vector<float> R_float;

    const uint64_t nX=mxGetM(prhs[4]);
    {
        int* pts_ptr = (int*)mxGetData(prhs[4]);
        if(sizex==1){
            X_2D.resize(nX);
            #pragma omp parallel for
            for(int i = 0;i < nX;++i)
                X_2D[i] = {pts_ptr[i]-1,pts_ptr[i+nX]-1};//convert to 0 based-indexing
        }else{
            X_3D.resize(nX);
            #pragma omp parallel for
            for(int i = 0;i < nX;++i)
                X_3D[i] = {pts_ptr[i]-1,pts_ptr[i+nX]-1,pts_ptr[i+2*nX]-1};//convert to 0 based-indexing
        }
    }
    int nfields = mxGetNumberOfFields(prhs[5]);
    mexPrintf("number of F fields: %i.\n",nfields);
    for(int i=0;i<nfields;++i)
        mexPrintf("name of F fields: %s.\n",mxGetFieldNameByNumber(prhs[5],i));

    {
        auto field_pt=mxGetField(prhs[5],0,"v");
        if(mxGetClassID(field_pt) != mxINT32_CLASS ||
           mxIsComplex(field_pt))
            mexErrMsgIdAndTxt("MyToolbox:fiberproc:typemismatch","F.v needs to be mxINT32_CLASS.");        
        int nFv = mxGetM(field_pt);
        F.resize(nFv);
        for(int i = 0;i < nFv;++i){
            auto tmpArray = mxGetCell(field_pt,i);
            int* ptr = (int*)mxGetData(field_pt);
            int size = mxGetM(tmpArray);
            F[i].resize(size);
            for(int j = 0;j < size;++j)
                F[i][j] = ptr[j] - 1;//convert to 0 based-indexing                    
        }
    }
    {
        auto field_pt=mxGetField(prhs[5],0,"f");
        if(mxGetClassID(field_pt) != mxINT32_CLASS ||
           mxIsComplex(field_pt))
            mexErrMsgIdAndTxt("MyToolbox:fiberproc:typemismatch","F.f needs to be mxINT32_CLASS.");        
        int nFf = mxGetM(field_pt);
        Ff.resize(nFf);
        for(int i = 0;i < nFf;++i){
            auto tmpArray = mxGetCell(field_pt,i);
            int* ptr = (int*)mxGetData(field_pt);
            int size = mxGetM(tmpArray);
            Ff[i].resize(size);
            for(int j = 0;j < size;++j)
                Ff[i][j] = ptr[j] - 1;//convert to 0 based-indexing        
        }
    }
    if(mxGetClassID(prhs[6])!=mxSINGLE_CLASS){
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:dimensionMismatch","Input R must be mxSINGLE_CLASS.");}
    
    {
        const uint64_t nX=mxGetM(prhs[6]);
        float* pts_ptr = (float*)mxGetData(prhs[6]);
        R_float.resize(nX);
        #pragma omp parallel for
        for(int i = 0;i < nX;++i)
            R_float[i] = pts_ptr[i];
        
    }

    auto field_pt=mxGetField(prhs[7],0,"thresh_linka");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:typemismatch","p.thresh_linka needs to be double.");
    const float thresh_linka = mxGetPr(field_pt)[0];

    field_pt=mxGetField(prhs[7],0,"s_fiberdir");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:fiberproc:typemismatch","p.s_fiberdir needs to be double.");
    const float s_fiberdir = mxGetPr(field_pt)[0];
    
}
