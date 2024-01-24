#!/usr/bin/env python

# internal libraries
from __future__ import division
from copy import deepcopy
import time
import os
from tkinter import END
from datetime import datetime
# external libraries
import numpy as np
from scipy import stats, cluster, spatial, special
from sklearn.cluster import KMeans
from sklearn import preprocessing
import matplotlib as mpl
mpl.use("TkAgg")

def clusterSM_replace(outpth, score, bdpc, clnum, pcnum=None, VamModel=None, BuildModel=None,
              condition=None,setID=None, modelName=None, modelApply=None):
    print('# clusterSM')
    if not isinstance(condition, str):
        condition = str(condition)
    # if BuildModel:
    #     figdst = os.path.join(*[outpth, modelName, 'Example model figures'])
    # else:
    #     figdst = os.path.join(outpth, 'Result based on ' + os.path.splitext(os.path.basename(modelApply))[0])
    # if not os.path.exists(figdst):
    #     try:
    #         os.makedirs(figdst)
    #     except:
    #         print('error???')
    NN = 10

    if pcnum is None:
        pcnum = 20

    if BuildModel:
        VamModel['clnum'] = clnum
        VamModel['pcnum'] = pcnum
    else:
        clnum = VamModel['clnum']
        pcnum = VamModel['pcnum']

    cms00 = score[:, 0:pcnum]
    cms = deepcopy(cms00)

    if BuildModel:
        mincms = np.amin(cms, axis=0)
        VamModel['mincms'] = mincms
        VamModel['boxcoxlambda'] = np.zeros(len(cms.T))
        VamModel['testmean'] = np.zeros(len(cms.T))
        VamModel['teststd'] = np.zeros(len(cms.T))
    else:
        mincms = VamModel['mincms']

    for k in range(len(cms.T)):
        test = cms.T[k]
        test = test - mincms[k] + 1
        if BuildModel:
            test[test < 0] = 0.000000000001
            test, maxlog = stats.boxcox(test)
            test = np.asarray(test)
            VamModel['boxcoxlambda'][k] = maxlog
            VamModel['testmean'][k] = np.mean(test)
            VamModel['teststd'][k] = np.std(test)
            cms.T[k] = (test - np.mean(test)) / np.std(test)
        else:
            test[test < 0] = 0.000000000001
            test = stats.boxcox(test, VamModel['boxcoxlambda'][k])
            cms.T[k] = (test - VamModel['testmean'][k]) / VamModel['teststd'][k]

    cmsn = deepcopy(cms)

    if BuildModel:
        cmsn_Norm = preprocessing.normalize(cmsn)
        if isinstance(clnum, str):
            clnum = int(clnum)

        kmeans = KMeans(n_clusters=clnum, init='k-means++', n_init=3, max_iter=300).fit(
            cmsn_Norm)  # init is plus,but orginally cluster, not available in sklearn
        C = kmeans.cluster_centers_
        VamModel['C'] = C
        D = spatial.distance.cdist(cmsn, C, metric='euclidean')
        IDX = np.argmin(D, axis=1)
        IDX_dist = np.amin(D, axis=1)
    else:
        if isinstance(clnum, str):
            clnum = int(clnum)
        C = VamModel['C']
        D = spatial.distance.cdist(cmsn, C, metric='euclidean')
        # why amin? D shows list of distance to cluster centers.
        IDX = np.argmin(D, axis=1)
        IDX_dist = np.around(np.amin(D, axis=1), decimals=2)
    goodness = special.softmax(D)
    for kss in range(clnum):
        c88 = IDX == kss
    IDXsort = np.zeros(len(IDX))
    # define normalized colormap
    bdst0 = np.empty(len(bdpc.T))
    bdst = deepcopy(bdst0)
    for kss in range(clnum):
        c88 = IDX == kss
        bdpcs = bdpc[c88, :]
        mbd = np.mean(bdpcs, axis=0)
        bdst0 = np.vstack((bdst0, mbd))
    bdst0 = bdst0[1:]
    if BuildModel:
        Y = spatial.distance.pdist(bdst0, 'euclidean')
        Z = cluster.hierarchy.linkage(Y, method='complete')  # 4th row is not in matlab
        Z[:, 2] = Z[:, 2] * 5  # multiply distance manually 10times to plot better.
        VamModel['Z'] = Z
    else:
        Z = VamModel['Z']
    R = cluster.hierarchy.dendrogram(Z, p=0, no_plot=True)
    leaflabel = np.array(R['ivl'])
    dendidx = leaflabel
    for kss in range(clnum):
        c88 = IDX == int(dendidx[kss])
        IDXsort[c88] = kss
    IDX = deepcopy(IDXsort)
    IDX = IDX + 1
    return IDX, IDX_dist, VamModel, goodness

