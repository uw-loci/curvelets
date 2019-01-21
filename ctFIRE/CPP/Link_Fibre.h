#include <vector>
#include <array>
#include <omp.h>
// Matlab is colomn major.
template<typename T,int d>
struct Fibre
{
    std::array<T,d> direction;
    std::vector<std::array<int,d>> link;
    std::vector<int> link_index;
};

struct LinkTo{
    int f;
    bool isStart;
};

struct Terminal{
    int f;
    bool isStart;
};


template<typename T,int d>
struct LinkFibreAtNucleationPoint
{
    T Dot(const std::array<T,d>& vector1,const std::array<T,d>& vector2)
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
    static void Normalize(std::array<T,d>& vector)
    {
        T one_over_length = T(1.0)/Length(vector);
        for(int v = 0;v < d;++v) vector[v] *= one_over_length;
    }    
    using Fibre_Type = Fibre<T,d>;
    explicit LinkFibreAtNucleationPoint(const int nPt,
                                        const std::vector<int>& nucleation_pts,//input arrays are 0 based indexing.
                                        const std::vector<Fibre_Type>& F_in,
                                        std::vector<std::vector<int>>& F_out,//output array is 1 based indexing.
                                        const T thresh_linka,const int sp)
    {
#if 1
        //mexPrintf("nPt %d.\n",nPt);
        //mexEvalString("drawnow");
        std::vector<int> nucleationIndex(nPt);
        #pragma omp parallel for
        for(int i = 0;i < nPt;++i) nucleationIndex[i] = -1;

        const int nNucleation = nucleation_pts.size();
        #pragma omp parallel for
        for(int i = 0;i < nNucleation;++i) {
            if(nucleation_pts[i] >= 0) nucleationIndex[nucleation_pts[i]] = i;}

        std::vector<std::vector<Terminal>> pt_segments(nNucleation);

        //mexPrintf("Processing segments.\n");
        //mexEvalString("drawnow");
        const int nSegments = F_in.size();        
        for(int f = 0;f < nSegments;++f){
            if(F_in[f].link_index.size() != F_in[f].link.size()){mexPrintf("Error. Inconsistent size.\n");}
            if(F_in[f].link_index.size() < 2) {mexPrintf("Error. Found Segment Contains Less Than 2 nodes\n");continue;}
            const int start = F_in[f].link_index[0]; 
            const int end   = F_in[f].link_index.back();
            if(start >= nPt) mexPrintf("Error. Nodal Index Overflow\n");
            if(end >= nPt) mexPrintf("Error. Nodal Index Overflow\n");
            //mexPrintf("%d %d\n",start,end);
            if(nucleationIndex[start] != -1) pt_segments[nucleationIndex[start]].push_back({f,true});
            if(nucleationIndex[end]   != -1) pt_segments[nucleationIndex[end]].push_back({f,false});}

        std::vector<LinkTo> f_to_f_start(nSegments);
        std::vector<LinkTo> f_to_f_end(nSegments);
        
        #pragma omp parallel for
        for(int f = 0;f < nSegments;++f){
            f_to_f_start[f] = {-1,false};
            f_to_f_end[f] = {-1,false};}
        
        mexPrintf("Finding Links.\n");
        mexEvalString("drawnow");

        #pragma omp parallel for
        for(int i = 0;i < nNucleation;++i){
            //for each Nucleation point check each pair of segment that joint here.
            const int nSegmentsOnPt = pt_segments[i].size();
            std::vector<bool> linked(nSegmentsOnPt);
            for(int f  = 0;f  < nSegmentsOnPt;++f) linked[f] = false;
            for(int f1 = 0;f1 < nSegmentsOnPt;++f1){
                if(linked[f1]) continue;
                auto& segmement1 = F_in[pt_segments[i][f1].f];
                //if(segmement1.link.size() < 2) continue;
                std::array<T,d> d1;
                if(pt_segments[i][f1].isStart){
                    int start = 0;
                    int end = std::min(sp,(int)segmement1.link.size()) - 1;
                    //mexPrintf("Linke Length: %d.\n",segmement1.link.size());
                    //mexPrintf("starting: %d - %d.\n",start,end);
                    //mexEvalString("drawnow");
                    for(int v = 0 ;v < d;++v)
                        d1[v] = T(segmement1.link[end][v] - segmement1.link[start][v]);
                }else{
                    int start = std::max(1,(int)segmement1.link.size() - sp) - 1;
                    int end = segmement1.link.size() - 1;
                    mexPrintf("ending: %d - %d.\n",start,end);
                    mexEvalString("drawnow");
                    for(int v = 0 ;v < d;++v)
                        d1[v] = -T(segmement1.link[end][v] - segmement1.link[start][v]);
                }
                Normalize(d1);
                mexPrintf("d1 length: %f.\n",Length(d1));
                for(int f2 = f1 + 1;f2 < nSegmentsOnPt;++f2){
                    //std::array<T,d> d1 = F_in[pt_segments[i][f1].f].direction;
                    //std::array<T,d> d2 = F_in[pt_segments[i][f2].f].direction;
                    if(linked[f2]) continue;
                    auto& segmement2 = F_in[pt_segments[i][f2].f];
                    //if(segmement2.link.size() < 2) continue;
                    std::array<T,d> d2;
                    if(pt_segments[i][f2].isStart){
                        int start = 0;
                        int end = std::min(sp,(int)segmement2.link.size()) - 1;
                        for(int v = 0 ;v < d;++v)
                            d2[v] = T(segmement2.link[end][v] - segmement2.link[start][v]);
                    }else{
                        int start = std::max(1,(int)segmement2.link.size() - sp) - 1;
                        int end = segmement2.link.size() - 1;
                        for(int v = 0 ;v < d;++v)
                             d2[v] = -T(segmement2.link[end][v] - segmement2.link[start][v]);}
                    Normalize(d2);
                    //if(!pt_segments[i][f1].isStart) for(int v = 0; v < d;++v) d1[v] = -d1[v];
                    //if(!pt_segments[i][f2].isStart) for(int v = 0; v < d;++v) d2[v] = -d2[v];
                    T cos_angle = Dot(d1,d2);
                    if(cos_angle < thresh_linka){
                        // If they are within the threshold, mark the pair.
                        linked[f1] = true;
                        linked[f2] = true;
                        if(pt_segments[i][f1].isStart)
                            f_to_f_start[pt_segments[i][f1].f] = {pt_segments[i][f2].f,pt_segments[i][f2].isStart};
                        else
                            f_to_f_end[pt_segments[i][f1].f] = {pt_segments[i][f2].f,pt_segments[i][f2].isStart};
                        if(pt_segments[i][f2].isStart)
                            f_to_f_start[pt_segments[i][f2].f] = {pt_segments[i][f1].f,pt_segments[i][f1].isStart};
                        else
                            f_to_f_end[pt_segments[i][f2].f] = {pt_segments[i][f1].f,pt_segments[i][f1].isStart};
                        // If found a link, stop searching
                        // TODO: using some local metric to pick which one to link.
                        break;}}}}
        
        // Now that we have marked the connections, we should construct the long Fibres
        std::vector<int> fibre_with_free_ends;
        for(int f = 0;f < nSegments;++f){
            if(f_to_f_start[f].f == -1 || f_to_f_end[f].f == -1) fibre_with_free_ends.push_back(f);}
        
        std::vector<bool> fibre_used(nSegments);
        #pragma omp parallel for
        for(int f = 0;f < nSegments;++f) fibre_used[f] = false;
        
        F_out.resize(0);
        std::vector<std::vector<int>*> F_out_tmp;

        //mexPrintf("Linking...\n");
        //mexEvalString("drawnow");

        //TODO: Parallelize this
        for(int i = 0;i < fibre_with_free_ends.size();++i){
            int f_index = fibre_with_free_ends[i];
            if(!fibre_used[f_index]){
                //mexPrintf("new fibre starting: %d\n",f_index);
                //mexEvalString("drawnow");
                //starting a new fibre
                std::vector<int>* f_tmp_ptr = new std::vector<int>();
                bool linked_start;
                linked_start = false;
                if(f_to_f_start[f_index].f == -1) linked_start = true;         
                do{
                    //mexPrintf("%d -> \n",f_index);
                    //mexEvalString("drawnow");
                    if(fibre_used[f_index]) mexPrintf("err... fibre already used %d\n",f_index);
                    //else mexPrintf("-> %d\n",f_index);
                    fibre_used[f_index] = true;
                    if(linked_start){
                        for(int j = 0;j < F_in[f_index].link_index.size();++j)
                            f_tmp_ptr->push_back(F_in[f_index].link_index[j]+1);//We changed the indexing from 0 to 1 here.
                        if(f_to_f_end[f_index].f == -1) break;
                        linked_start = f_to_f_end[f_index].isStart;
                        f_index = f_to_f_end[f_index].f;
                    }else{
                        for(int j = F_in[f_index].link_index.size() - 1;j >= 0;--j)
                            f_tmp_ptr->push_back(F_in[f_index].link_index[j]+1);//We changed the indexing from 0 to 1 here.
                        if(f_to_f_start[f_index].f == -1) break;
                        linked_start = f_to_f_start[f_index].isStart;
                        f_index = f_to_f_start[f_index].f;}
                }while(true);
                F_out_tmp.push_back(f_tmp_ptr);
            }
        }

        //mexPrintf("Populating Output...\n");
        //mexEvalString("drawnow");

        F_out.resize(F_out_tmp.size());
        #pragma omp parallel for
        for(int i = 0;i < F_out_tmp.size();++i){
            F_out[i].resize(F_out_tmp[i]->size());
            for(int j = 0;j < F_out_tmp[i]->size();++j){
                F_out[i][j] = (*F_out_tmp[i])[j];}}
        
        //mexPrintf("Cleanup...\n");
        //mexEvalString("drawnow");

        #pragma omp parallel for
        for(int i = 0;i < F_out_tmp.size();++i)
            delete F_out_tmp[i];

        /*
        mexPrintf("Doing primitive things...\n");
        mexEvalString("drawnow");

        F_out.resize(F_in.size());
        for(int f = 0;f < F_in.size();++f){
            F_out[f].resize(F_in[f].link_index.size());    
            for(int j = 0;j < F_in[f].link_index.size();++j){
                F_out[f][j] = F_in[f].link_index[j]+1;
            }
        }
        */
#else
        F_out.resize(F_in.size());
        for(int f = 0;f < F_in.size();++f){
            F_out[f].resize(F_in[f].link_index.size());    
            for(int j = 0;j < F_in[f].link_index.size();++j){
                F_out[f][j] = F_in[f].link_index[j]+1;
            }
        }
#endif
    }
};
