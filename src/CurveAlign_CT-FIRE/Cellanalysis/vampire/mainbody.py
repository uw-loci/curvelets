# built-in libraries
import pickle
from datetime import datetime
# external libraries
# my wrapper
from collect_selected_bstack import *
from update_csv import *
# my core
from bdreg import *
from pca_bdreg import *
from clusterSM_replace import *

def mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply):
    print('## main.py')
    progress = 50
    experimental = True
    realtimedate = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    N = int(numOfCoor)
    if build_model:
        bstack= collect_seleced_bstack(csv, build_model)
        vampire_model = {
            "N": [],
            "bdrn": [],
            "mdd": [],
            "pc": [],
            "clnum": [],
            "pcnum": [],
            "mincms": [],
            "testmean": [],
            "teststd": [],
            "boxcoxlambda": [],
            "C": [],
            "Z": []
        }
        bdpc, vampire_model = bdreg(bstack[0], N, vampire_model, build_model)
        score, vampire_model = pca_bdreg(bdpc, vampire_model, build_model)
        pcnum = None # none is 20 by default
        IDX, IDX_dist, vampire_model, _ = clusterSM_replace(outpth, score, bdpc, clnum, pcnum, vampire_model, build_model, None, None, modelName, modelApply)
        modelname = modelName
        if os.path.exists(os.path.join(*[outpth, modelname, modelname+'.pickle'])):
            f = open(os.path.join(*[outpth, modelname, modelname+'_'+realtimedate+'.pickle']), 'wb')
        else:
            f = open(os.path.join(*[outpth, modelname, modelname+'.pickle']), 'wb')
        pickle.dump(vampire_model, f)
        f.close()

    else:
        UI = pd.read_csv(csv)
        setpaths = UI['set location']
        tag = UI['tag']
        condition = UI['condition']
        setID = UI['set ID'].astype('str')
        for setidx, setpath in enumerate(setpaths):
            pickles = [_ for _ in os.listdir(setpath) if _.lower().endswith('pickle')]
            bdstack = [pd.read_pickle(os.path.join(setpath, pkl)) for pkl in pickles if tag[setidx] in pkl]
            bdstacks = pd.concat(bdstack, ignore_index=True)
            try:
                f = open(modelApply, 'rb')
            except:
                print('error')
            vampire_model = pickle.load(f)
            N = vampire_model['N']
            bdpc, vampire_model = bdreg(bdstacks[0], N, vampire_model, build_model)
            score, vampire_model = pca_bdreg(bdpc, vampire_model, build_model)
            clnum = vampire_model['clnum']
            pcnum = vampire_model['pcnum']

            if experimental:
                IDX, IDX_dist, vampire_model, goodness = clusterSM_replace(outpth, score, bdpc, clnum, pcnum, vampire_model,
                                                                   build_model, condition[setidx], setID[setidx],
                                                                   modelName, modelApply)
                update_csv(IDX, IDX_dist, tag[setidx], setpath, goodness=goodness)
            else:
                IDX, IDX_dist, vampire_model, _ = clusterSM_replace(outpth, score, bdpc, clnum, pcnum, vampire_model,
                                                                   build_model, condition[setidx], setID[setidx],
                                                                   modelName, modelApply)
                update_csv(IDX, IDX_dist, tag[setidx], setpath)

