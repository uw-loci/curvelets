#include "mex.h"
#include <cstdint>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <iostream>
#include <mutex>
#include "Link_Fibre.h"
// Matlab is colomn major.
template<typename T,int d>
struct ExtendXLink
{
    static T Dot(const std::array<T,d>& vector1,const std::array<T,d>& vector2)
    {
        T value = 0;
        for(int v = 0;v < d;++v) value += vector1[v] * vector2[v];
        return value;
    }
    static T Length(const std::array<T,d>& vector)
    {
        T value = 0;
        for(int v = 0;v < d;++v) value += vector[v] * vector[v];
        return sqrt(value);
    }
    using Fibre_Type = Fibre<T,d>;
    explicit ExtendXLink(int sizex,int sizey, T* image,const std::vector<std::array<int,d>>& pts,//in {y,x}
                         int thresh_LMPdist,T thresh_LMP,T thresh_ext,T lambda,T thresh_linkd, T thresh_linka,
                         std::vector<std::array<int,d>>& X,std::vector<T>& R,std::vector<std::vector<int>>& F,
                         std::vector<std::vector<int>>& Xfe,std::vector<std::vector<int>>& Xf,
                         std::vector<std::vector<int>>& Xvall,std::vector<std::vector<int>>& Ff)
    {
        mexPrintf("thresh_LMPdist: %d\n",thresh_LMPdist);
        mexPrintf("thresh_LMP    : %f\n",thresh_LMP);
        mexPrintf("thresh_ext    : %f\n",thresh_ext);
        mexPrintf("lambda        : %f\n",lambda);
        mexPrintf("thresh_linkd  : %f\n",thresh_linkd);
        mexPrintf("thresh_a      : %f\n",thresh_linka);

        static_assert(d==2,"");
        //int* index_map = (int*) mxCalloc(sizex * sizey, sizeof(int));
        //bool* nucleation_map = (bool*) mxCalloc(sizex * sizey, sizeof(bool));
        int* index_map = new int[sizex * sizey];
        int* nucleation_map = new int[sizex * sizey];
        memset(nucleation_map,0,sizeof(int) * sizex * sizey);
        memset(index_map,0,sizeof(int) * sizex * sizey);

        #pragma omp parallel for
        for(int i=0;i<pts.size();++i) nucleation_map[pts[i][0] * sizex + pts[i][1]] = i;
        std::vector<std::vector<Fibre_Type>> fibres(pts.size());

        #pragma omp parallel for
        for(int i=0;i<pts.size();++i){
            const int r_i = ceil(image[pts[i][0] * sizex + pts[i][1]]);
            //mexPrintf("radius: %f\n",image[pts[i][0] * sizex + pts[i][1]]);
            const std::array<int,d> nucleation{pts[i][0],pts[i][1]};
            bool found_ = false;
            const std::array<int,d> b_min = {nucleation[0]-r_i,nucleation[1]-r_i};
            const std::array<int,d> b_max = {nucleation[0]+r_i,nucleation[1]+r_i};
            //Step One: finding LMP
            for(int ii = -r_i;ii <= r_i;++ii)
            for(int jj = -r_i;jj <= r_i;++jj){
                const std::array<int,d> p{ii + pts[i][0],jj + pts[i][1]};
                if(p[0] < 0 || p[0] >= sizey || p[1] < 0 || p[1] >= sizex) continue;
                if(p[0] != b_min[0] && p[0] != b_max[0] && p[1] != b_min[1] && p[1] != b_max[1]) continue;
                const T d_value = image[p[0] * sizex + p[1]];
                if(d_value < thresh_LMP) continue;
                bool is_LMP = true;
                for(int iii = -1;iii <= 1 && is_LMP;++iii)
                for(int jjj = -1;jjj <= 1;++jjj){
                    const std::array<int,d> p_n{iii + p[0],jjj + p[1]};
                    if(p_n[0] < 0 || p_n[0] >= sizey || p_n[1] < 0 || p_n[1] >= sizex) continue;
                    if(p_n[0] < b_min[0] || p_n[0] > b_max[0] || p_n[1] < b_min[1] || p_n[1] > b_max[1]) continue;
                    if(p_n[0] != b_min[0] && p_n[0] != b_max[0] && p_n[1] != b_min[1] && p_n[1] != b_max[1]) continue;
                    const T d_value_n = image[p_n[0] * sizex + p_n[1]];
                    if(d_value < d_value_n) {is_LMP = false; break;}}
                if(is_LMP) {
                    bool too_close = false;    
                    for(int b=0;b<fibres[i].size();++b)
                        if(abs(fibres[i][b].link[1][0] -  p[0]) < thresh_LMPdist &&
                           abs(fibres[i][b].link[1][1] -  p[1]) < thresh_LMPdist) {too_close = true; break;}
                    if(too_close) continue;
                    found_ = true;
                    fibres[i].push_back(Fibre_Type{});
                    fibres[i].back().link.push_back(nucleation);
                    fibres[i].back().link.push_back(p);
                    std::array<T,d> dir{T(p[0]-nucleation[0]),T(p[1]-nucleation[1])};
                    const T l = Length(dir);
                    dir = std::array<T,d>{dir[0]/l,dir[1]/l};
                    // Now extend the link;
                    std::array<int,d> p_current(p);
                    bool found_next = true;
                    while(found_next){
                        T max_d = 0;
                        found_next = false;
                        std::array<int,d> next_pt{};
                        std::array<T,d> next_dir{};
                        bool found_nucleation = false;
                        std::array<int,d> nucleation_pt{};
                        const int r_current = ceil(image[p_current[0] * sizex + p_current[1]]);
                        //mexPrintf("r_current: %i.\n",r_current);                        
                        const std::array<int,d> b_min = {p_current[0]-r_current,p_current[1]-r_current};
                        const std::array<int,d> b_max = {p_current[0]+r_current,p_current[1]+r_current};
                        for(int ii = -r_current;ii <= r_current && (!found_nucleation);++ii)
                        for(int jj = -r_current;jj <= r_current;++jj){
                            bool is_LMP = true;
                            const std::array<int,d> p{ii + p_current[0],jj + p_current[1]};
                            if(p[0] < 0 || p[0] >= sizey || p[1] < 0 || p[1] >= sizex) continue;
                            const uint64_t offset = p[0] * sizex + p[1];
                            if(nucleation_map[offset] && (p[0]!=nucleation[0] || p[1]!=nucleation[1])){
                                nucleation_pt = p;
                                found_nucleation = true;
                                break;}
                            if(p[0] != b_min[0] && p[0] != b_max[0] && p[1] != b_min[1] && p[1] != b_max[1]) continue;
                            const T d_value = image[offset];
                            if(d_value < thresh_LMP || d_value < max_d) continue;
                            for(int iii = -1;iii <= 1 && is_LMP;++iii)
                            for(int jjj = -1;jjj <= 1;++jjj){
                                const std::array<int,d> p_n{iii + p[0],jjj + p[1]};
                                if(p_n[0] < 0 || p_n[0] >= sizey || p_n[1] < 0 || p_n[1] >= sizex) continue;
                                if(p_n[0] < b_min[0] || p_n[0] > b_max[0] || p_n[1] < b_min[1] || p_n[1] > b_max[1]) continue;
                                if(p_n[0] != b_min[0] && p_n[0] != b_max[0] && p_n[1] != b_min[1] && p_n[1] != b_max[1]) continue;
                                const T d_value_n = image[p_n[0] * sizex + p_n[1]];
                                if(d_value < d_value_n) {is_LMP = false; break;}}
                            if(is_LMP){
                                std::array<T,d> new_dir{T(p[0]-p_current[0]),T(p[1]-p_current[1])};
                                const T l = Length(new_dir);
                                new_dir = std::array<T,d>{new_dir[0]/l,new_dir[1]/l};
                                if(Dot(new_dir,dir) < thresh_ext) continue;
                                max_d = d_value;
                                next_pt = p;
                                next_dir = new_dir;
                                found_next = true;}}
                        if(found_nucleation){
                            //mexPrintf("Reached nucleation [%i,%i].\n",nucleation_pt[0],nucleation_pt[1]);                            
                            fibres[i].back().link.push_back(nucleation_pt);
                            break;}
                        if(found_next){
                            fibres[i].back().link.push_back(next_pt);
                            p_current = next_pt;
                            dir = {T(1.0 / (1.0 + lambda) * dir[0] + lambda / (1.0 + lambda) * next_dir[0]),
                                   T(1.0 / (1.0 + lambda) * dir[1] + lambda / (1.0 + lambda) * next_dir[1])};
                            const T l = Length(dir);
                            dir = std::array<T,d>{dir[0]/l,dir[1]/l};}
                    };
                    fibres[i].back().direction=dir;
                }
            }
#if 0
            if(!found_) {
                mexPrintf("We have a problem here: [%i,%i]\n",pts[i][0],pts[i][1]);
                mexEvalString("drawnow");
                for(int jj = -r_i;jj <= r_i;++jj){
                    for(int ii = -r_i;ii <= r_i;++ii){
                        const std::array<int,d> p{ii + pts[i][0],jj + pts[i][1]};
                        mexPrintf("%f ",image[p[0] * sizex + p[1]]);
                    }
                    mexPrintf("\n ");
                }
            }
#endif
        }
        mexPrintf("Finished Probing\n");
        const int nNucleation = pts.size();
        std::vector<std::vector<uint64_t>> link_map(nNucleation);
        //Populate link_map
        #pragma omp parallel for
        for(int f = 0;f < fibres.size();++f)
        for(int branch = 0;branch < fibres[f].size();++branch){
            if(fibres[f][branch].link.size() < 2) continue;
            uint64_t offset_begin = fibres[f][branch].link[0][0] * sizex + fibres[f][branch].link[0][1];
            uint64_t offset_end   = fibres[f][branch].link.back()[0] * sizex + fibres[f][branch].link.back()[1];
            if(nucleation_map[offset_end]) {
                if(offset_begin < offset_end){
                    bool found = false;
                    for(int i = 0;i < link_map[nucleation_map[offset_begin]].size();++i)
                        if(link_map[nucleation_map[offset_begin]][i] == offset_end) {found = true;break;}
                    if(found) {fibres[f][branch].link.clear();}
                    else link_map[nucleation_map[offset_begin]].push_back(offset_end);}}}

        //use link_map to delete duplicated fibers
        #pragma omp parallel for
        for(int f = 0;f < fibres.size();++f)
        for(int branch = 0;branch < fibres[f].size();++branch){
            if(fibres[f][branch].link.size() < 0) continue;
            uint64_t offset_begin = fibres[f][branch].link[0][0] * sizex + fibres[f][branch].link[0][1];
            uint64_t offset_end   = fibres[f][branch].link.back()[0] * sizex + fibres[f][branch].link.back()[1];
            if(nucleation_map[offset_end]) {
                if(offset_begin > offset_end){
                    bool found = false;
                    for(int i = 0;i < link_map[nucleation_map[offset_end]].size();++i)
                        if(link_map[nucleation_map[offset_end]][i] == offset_begin) {found = true;break;}
                    if(found) {fibres[f][branch].link.clear();}}}}
        
        int ncounter = 0;
        // Now populate index_map
        for(int f = 0;f < fibres.size();++f)
        for(int branch = 0;branch < fibres[f].size();++branch)
        for(int node = 0;node < fibres[f][branch].link.size();++node){
            const uint64_t offset = fibres[f][branch].link[node][0] * sizex + fibres[f][branch].link[node][1];
            if(!index_map[offset]){
                index_map[offset]=++ncounter;
                X.push_back(std::array<int,d>{fibres[f][branch].link[node][0]+1,fibres[f][branch].link[node][1]+1});}}

        mexPrintf("Copying R\n");
        R.resize(X.size());
        #pragma omp parallel for
        for(int i = 0;i < X.size();++i) R[i] = ceil((image[X[i][0]-1) * sizex + (X[i][1]-1)]);

        std::vector<int> nucleation_pts(nNucleation);//This is using zero based indexing
        #pragma omp parallel for
        for(int i = 0;i < nNucleation;++i) nucleation_pts[i] = index_map[pts[i][0] * sizex + pts[i][1]] - 1;
        
        mexPrintf("Init F\n");
        std::vector<Fibre_Type> F_init;//This is using zero based indexing
   
        std::vector<uint64_t> branch_accum(pts.size()+1);
        branch_accum[0] = 0;
        for(int f = 0;f < fibres.size();++f){
            int fibre_count = 0;
            for(int b = 0;b < fibres[f].size();++b){
                if(fibres[f][b].link.size() > 0) ++fibre_count;}
            branch_accum[f+1] = branch_accum[f] + fibre_count;}        

        F_init.resize(branch_accum[pts.size()]);
        #pragma omp parallel for
        for(int f = 0;f < fibres.size();++f){
            int branch_count = 0;
            for(int branch = 0;branch < fibres[f].size();++branch){
                for(int node = 0;node < fibres[f][branch].link.size();++node){
                    const uint64_t offset = fibres[f][branch].link[node][0] * sizex + fibres[f][branch].link[node][1];
                    F_init[branch_accum[f]+branch_count].link_index.push_back(index_map[offset] - 1);}
                if(fibres[f][branch].link.size() > 0) {
                    F_init[branch_accum[f]+branch_count].direction = fibres[f][branch].direction;
                    ++branch_count;}}}

        LinkFibreAtNucleationPoint<T,d>(X.size(),nucleation_pts,F_init,F,thresh_linka);
   
        mexPrintf("Fibre segments %d\n",F_init.size());
        mexPrintf("Linked Fibres %d\n",F.size());
        mexEvalString("drawnow");

        Xfe.resize(X.size());
        Xf.resize(X.size());
        Xvall.resize(X.size());
        for(int f = 0;f < F.size();++f){
            if(F[f].size()){
                const int index_begin = F[f][0];
                const int index_end   = F[f].back();
                if(index_begin - 1 >= X.size()) mexPrintf("Error1.\n");
                if(index_end   - 1 >= X.size()) mexPrintf("Error2.\n");                    
                Xfe[index_begin - 1].push_back(f+1);
                Xfe[index_end   - 1].push_back(f+1);}
            for(int node = 0;node < F[f].size();++node){
                Xf[F[f][node] - 1].push_back(f+1);
                for(int node2 = 0;node2 < F[f].size();++node2){
                    Xvall[F[f][node] - 1].push_back(F[f][node2] - 1);}}
        }

        Ff.resize(F.size());
        #pragma omp parallel for
        for(int f = 0;f < F.size();++f){
            for(int node = 0;node < F[f].size();++node){
                for(int f2 = 0;f2 < Xf[F[f][node] - 1].size();++f2){
                    if(Xf[F[f][node] - 1][f2] != f + 1) {
                        bool unique = true;
                        for(int ff = 0; ff < Ff[f].size();++ff)
                            if(Ff[f][ff] == Xf[F[f][node] - 1][f2]) {unique = false; break;}
                        if(unique) Ff[f].push_back(Xf[F[f][node] - 1][f2]);}}}}

        delete [] index_map;
        delete [] nucleation_map;
        mexPrintf("Finished Copy back\n");
    }
    explicit ExtendXLink(int sizex,int sizey,int sizez,T* image,const std::vector<std::array<int,d>>& pts,// in {z,y,x}
                         int thresh_LMPdist,T thresh_LMP,T thresh_ext,T lambda,T thresh_linkd,T thresh_linka,
                         std::vector<std::array<int,d>>& X,std::vector<T>& R,std::vector<std::vector<int>>& F,
                         std::vector<std::vector<int>>& Xfe,std::vector<std::vector<int>>& Xf,
                         std::vector<std::vector<int>>& Xvall,std::vector<std::vector<int>>& Ff)
    {
        static_assert(d==3,"");
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
      double nucleation_points[][][],
      struct p

  output:
      int X(position)[][3],
      int F(ibres)[]
      int V(ertices)[],
      T R(adius)[],
*/
{
    if(nrhs!=6) {
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:nrhs","Six inputs required.");
    }
    if(nlhs!=4) {
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:nlhs","Four outputs required.");
    }

    if( !mxIsDouble(prhs[0]) ||
        mxIsComplex(prhs[0]) ||
        mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:notScalar","Input channels must be a scalar.");
    }
    const uint64_t sizex=mxGetScalar(prhs[0]);
    if( !mxIsDouble(prhs[1]) ||
        mxIsComplex(prhs[1]) ||
        mxGetNumberOfElements(prhs[1])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:notScalar","Input width must be a scalar.");
    }
    const uint64_t sizey=mxGetScalar(prhs[1]);
    if( !mxIsDouble(prhs[2]) ||
        mxIsComplex(prhs[2]) ||
        mxGetNumberOfElements(prhs[2])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:notScalar","Input height must be a scalar.");
    }
    const uint64_t sizez=mxGetScalar(prhs[2]);
    mexPrintf("image size: %i x %i x%i.\n",sizex,sizey,sizez);
    mexPrintf("mxClassID of the image: %i.\n",mxGetClassID(prhs[3]));
    if(mxGetNumberOfElements(prhs[3])!=sizex*sizey*sizez){
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:dimensionMismatch","Input image and imput dimension mismatched.");
    }

    mexPrintf("mxClassID of the Nucleations array: %i.\n",mxGetClassID(prhs[4]));
    if(mxGetN(prhs[4])!=3){
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:dimensionMismatch","Input Nucleation must be N x 3.");
    }
    if(mxGetClassID(prhs[4])!=mxINT32_CLASS){
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:dimensionMismatch","Input Nucleation must be int32_t.");
    }
    const uint64_t nNucleation=mxGetM(prhs[4]);
    int nfields = mxGetNumberOfFields(prhs[5]);
    mexPrintf("number of fields: %i.\n",nfields);
    for(int i=0;i<nfields;++i)
        mexPrintf("name of fields: %s.\n",mxGetFieldNameByNumber(prhs[5],i));

    auto field_pt=mxGetField(prhs[5],0,"lam_dirdecay");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:typemismatch","p.lam_dirdecay needs to be double.");
    const float lambda = mxGetPr(field_pt)[0];

    field_pt=mxGetField(prhs[5],0,"thresh_LMP");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:typemismatch","p.thresh_LMP needs to be double.");
    const float thresh_LMP = mxGetPr(field_pt)[0];

    field_pt=mxGetField(prhs[5],0,"thresh_LMPdist");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:typemismatch","p.thresh_LMPdist needs to be double.");
    const float thresh_LMPdist = mxGetPr(field_pt)[0];

    field_pt=mxGetField(prhs[5],0,"thresh_ext");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:typemismatch","p.thresh_ext needs to be double.");
    const float thresh_ext = mxGetPr(field_pt)[0];

    field_pt=mxGetField(prhs[5],0,"thresh_linka");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:typemismatch","p.thresha needs to be double.");
    const float thresh_a = mxGetPr(field_pt)[0];

    field_pt=mxGetField(prhs[5],0,"thresh_linkd");
    if(mxGetClassID(field_pt) != mxDOUBLE_CLASS ||
       mxIsComplex(field_pt))
        mexErrMsgIdAndTxt("MyToolbox:extendxlink:typemismatch","p.thresh_linkd needs to be double.");
    const float thresh_linkd = mxGetPr(field_pt)[0];
    
    mexPrintf("P: %f, %f, %f, %f.\n",lambda,thresh_LMP,thresh_LMPdist,thresh_ext);


    std::vector<std::array<int,2>> X_2D;
    std::vector<std::array<int,3>> X_3D;
    std::vector<std::vector<int>> Xfe;
    std::vector<std::vector<int>> Xf;
    std::vector<std::vector<int>> Xvall;
    std::vector<std::vector<int>> Ff;
    std::vector<std::array<int,2>> pts_2D;
    std::vector<std::array<int,3>> pts_3D;
    int* pts_ptr = (int*)mxGetData(prhs[4]);
    if(sizex==1){
        pts_2D.resize(nNucleation);
        #pragma omp parallel for
        for(int i = 0;i < nNucleation;++i){
            pts_2D[i] = {pts_ptr[i]-1,pts_ptr[i+nNucleation]-1};}//convert to 0 based-indexing
    }else{
        pts_3D.resize(nNucleation);
        #pragma omp parallel for
        for(int i = 0;i < nNucleation;++i){
            pts_3D[i] = {pts_ptr[i]-1,pts_ptr[i+nNucleation]-1,pts_ptr[i+nNucleation*2]-1};}//convert to 0 based-indexing
    }
    std::vector<std::vector<int>> F;
    std::vector<float> R_float;
    switch(mxGetClassID(prhs[3])){
    case mxSINGLE_CLASS:
        if(sizex==1){
            ExtendXLink<float,2>((int)sizey,(int)sizez,(float*)mxGetData(prhs[3]),pts_2D,
                                 (int)thresh_LMPdist,thresh_LMP,thresh_ext,lambda,thresh_linkd,thresh_a,
                                 X_2D,R_float,F,Xfe,Xf,Xvall,Ff);
        }else{
            ExtendXLink<float,3>((int)sizex,(int)sizey,(int)sizez,(float*)mxGetData(prhs[3]),pts_3D,
                                 (int)thresh_LMPdist,thresh_LMP,thresh_ext,lambda,thresh_linkd,thresh_a,
                                 X_3D,R_float,F,Xfe,Xf,Xvall,Ff);
        }
        break;
    }
     if(sizex==1){
         // X
         {
             mwSize out_size[2]={X_2D.size(),3};
             plhs[0] = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
             int32_t* ptr = (int32_t*)mxGetData(plhs[0]);
             #pragma omp parallel for
             for(int i = 0;i < X_2D.size();++i){
                 ptr[i]               = X_2D[i][0];
                 ptr[i+X_2D.size()]   = X_2D[i][1];
                 ptr[i+2*X_2D.size()] = 1;}
         }
         // F
         {
             const char* fieldnames[4];
             fieldnames[0] = (char*) mxMalloc(20);
             fieldnames[1] = (char*) mxMalloc(20);
             fieldnames[2] = (char*) mxMalloc(20);
             fieldnames[3] = (char*) mxMalloc(20);
             memcpy((void*)fieldnames[0],"v",sizeof("v"));
             memcpy((void*)fieldnames[1],"r",sizeof("r"));
             memcpy((void*)fieldnames[2],"a",sizeof("a"));
             memcpy((void*)fieldnames[3],"f",sizeof("f"));
             plhs[1] = mxCreateStructMatrix(F.size(),1,4,fieldnames);
             mxFree((void*)fieldnames[0]);
             mxFree((void*)fieldnames[1]);
             mxFree((void*)fieldnames[2]);
             mxFree((void*)fieldnames[3]);

             {
                 std::vector<int*> v_array(F.size());
                 for(int i = 0;i < F.size();++i){
                     mwSize out_size[2]={1,F[i].size()};
                     mxArray* tmp = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
                     mxSetFieldByNumber(plhs[1],i,0,tmp);
                     v_array[i] = (int*)mxGetData(tmp);}

                 #pragma omp parallel for
                 for(int i = 0;i < F.size();++i){
                     for(int n = 0;n < F[i].size();++n)
                         v_array[i][n] = F[i][n];}

             }
             {
                 std::vector<int*> Ff_array(Ff.size());
                 for(int i = 0;i < Ff.size();++i){
                     mwSize out_size[2]={1,Ff[i].size()};
                     mxArray* tmp = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
                     mxSetFieldByNumber(plhs[1],i,3,tmp);
                     Ff_array[i] = (int*)mxGetData(tmp);}

                 #pragma omp parallel for
                 for(int i = 0;i < Ff.size();++i){
                     for(int n = 0;n < Ff[i].size();++n)
                         Ff_array[i][n] = Ff[i][n];}

             }
         }
         // V
         {
             const char* fieldnames[3];
             fieldnames[0] = (char*) mxMalloc(20);
             fieldnames[1] = (char*) mxMalloc(20);
             fieldnames[2] = (char*) mxMalloc(20);
             memcpy((void*)fieldnames[0],"fe",sizeof("fe"));
             memcpy((void*)fieldnames[1],"f",sizeof("f"));
             memcpy((void*)fieldnames[2],"vall",sizeof("vall"));
             plhs[2] = mxCreateStructMatrix(Xfe.size(),1,3,fieldnames);
             mxFree((void*)fieldnames[0]);
             mxFree((void*)fieldnames[1]);
             mxFree((void*)fieldnames[2]);

             {
                 std::vector<int*> fe_array(Xfe.size());
                 for(int i = 0;i < Xfe.size();++i){
                     mwSize out_size[2]={1,Xfe[i].size()};
                     mxArray* tmp = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
                     mxSetFieldByNumber(plhs[2],i,0,tmp);
                     fe_array[i] = (int*)mxGetData(tmp);
                 }
                 
                 #pragma omp parallel for
                 for(int i = 0;i < Xfe.size();++i){
                     for(int n = 0;n < Xfe[i].size();++n)
                         fe_array[i][n] = Xfe[i][n];}
             }
             {
                 std::vector<int*> f_array(Xf.size());
                 for(int i = 0;i < Xf.size();++i){
                     mwSize out_size[2]={1,Xf[i].size()};
                     mxArray* tmp = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
                     mxSetFieldByNumber(plhs[2],i,1,tmp);
                     f_array[i] = (int*)mxGetData(tmp);}

                 #pragma omp parallel for
                 for(int i = 0;i < Xf.size();++i){
                     for(int n = 0;n < Xf[i].size();++n)
                         f_array[i][n] = Xf[i][n];}
             }
             
             {
                 std::vector<int*> vall_array(Xvall.size());
                 for(int i = 0;i < Xvall.size();++i){
                     mwSize out_size[2]={1,Xvall[i].size()};
                     mxArray* tmp = mxCreateNumericArray(2,out_size,mxINT32_CLASS,mxREAL);
                     mxSetFieldByNumber(plhs[2],i,2,tmp);
                     vall_array[i] = (int*)mxGetData(tmp);}
                 
                 #pragma omp parallel for
                 for(int i = 0;i < Xvall.size();++i){
                     for(int n = 0;n < Xvall[i].size();++n)
                         vall_array[i][n] = Xvall[i][n];}
             }
         }
         // R
         {
             mwSize out_size[2]={R_float.size(),1};
             plhs[3] = mxCreateNumericArray(2,out_size,mxSINGLE_CLASS,mxREAL);
             float* ptr = (float*)mxGetData(plhs[3]);
             #pragma omp parallel for
             for(int i = 0;i < R_float.size();++i)
                 ptr[i] = R_float[i];

         }
     }
}
