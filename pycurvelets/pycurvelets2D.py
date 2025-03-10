from curvelops import FDCT2D, curveshow, fdct2d_wrapper

import matplotlib.pyplot as plt
import numpy as np

img = plt.imread(
    "../doc/testImages/CellAnalysis_testImages/3dImage_fire/s5part1__cmle000.tif",
    format="TIF",
)

def pycurvelets2D(IMG, keep, sscale, radius):
    '''
    Adaptation of newCurv.m at ~/curvelets/src/CurveAlign_CT-FIRE/newCurv.m
    
    Parameters:
    IMG - actual image URL 
    keep - how much of the curvelets we decide to keep (threshold)
    sscale - what scale we will be measuring
    radius - extent to which we are going to group curvelets
    '''

# -------------------------- 1) perform 2d forward discrete curvelet transform ---------------------------------------
    C2D = FDCT2D(img.shape, nbscales=4, nbangles_coarse=8, allcurvelets=False)

    # coefficient mat
    imgC = C2D.struct(C2D @ img)
    shape = (len(imgC), len(imgC[0]), imgC[0][0].size)
    emptyC = np.zeros(shape)
    print(emptyC)

# --------------- 2) selects scale at which coefficients will be used (scale of interest) ----------------------------
    scale = len(imgC) - sscale 

    # scale coefficients to remove artifacts ****CURRENTLY ONLY FOR 1024x1024 
    tempA = [1, .64, .52, .5, .46, .4, .35, .3]
    tempB = np.hstack((tempA, np.flip(tempA), tempA, np.flip(tempA)))
    scaleMat = np.hstack((tempB, tempB))

    for i in range(len(imgC[scale])):
        imgC[scale][i] = np.abs(imgC[scale][i])

# ------------------- 3) choose threshold the remaining coeffs based on user-defined threshold -----------------------
    maxValsForAbs = [np.max(arr) for arr in imgC[scale]]
    absMax = np.max(maxValsForAbs)
    bins = np.arange(0, absMax * 0.01 + absMax, 0.01 * absMax)
    histVals = [np.histogram(arr, bins=bins)[0] for arr in imgC[scale]]
    sumHist = [np.sum(row, axis=0) for row in histVals]

    totalHist = np.hstack([sumHist[i] for i in range(len(sumHist))])
    sumVals = np.sum(totalHist, axis=0)
    cumVals = np.cumsum(sumVals)

    cumMax = np.max(cumVals)
    loc = np.where(cumVals > (1 - keep) * cumMax)[0][0]
    maxVal = bins[loc]

    emptyC[scale] = [x * (np.abs(x) >= maxVal) for x in imgC[scale]]

# ------------ 4) find center and spatial orientation of each curvelet corresponding to remaining coeffs -------------
    X_rows, Y_cols = fdct2d_wrapper.fdct2d_param_wrap(emptyC)

    long = len(imgC[scale]) / 2
    angles = np.array(long)
    row = np.array(long)
    col = np.array(long)
    increment = 360 / len(imgC[scale])
    startAngle = 225

    for wedgeIdx in range(0, long):
        test = np.where(imgC[scale][wedgeIdx])
        if any(test):
            angle = np.zeros(np.size(test))
            for i in range(2):
                for specificAngle in range(len(test)):
                    tempAngle = startAngle - (increment * (wedgeIdx - 1))
                    shiftTemp = startAngle - (increment * wedgeIdx)
                    angle[specificAngle] = np.mean([tempAngle, shiftTemp])
            
            ind = angle < 0
            angle[ind] += 360

            IND = angle > 225
            angle[IND] -= 180

            idx = angle < 45
            angle[idx] += 180

            angles[wedgeIdx] = angle

            row[wedgeIdx] = np.round(X_rows[scale][wedgeIdx][test]).astype(int) 
            col[wedgeIdx] = np.round(Y_cols[scale][wedgeIdx][test]).astype(int)

            angle = []
        
        else:
            angles[wedgeIdx] = 0
            row[wedgeIdx] = 0
            col[wedgeIdx] = 0

    cTest = [np.any(arr) for arr in imgC[scale]]
    idx = np.where(cTest)

    col = np.array(col[idx])
    row = np.array(row[idx])
    angs = np.array(angles[idx])
    
    curves = np.zeros((len(row), 3))
    curves[:, 1] = row
    curves[:, 2] = col
    curves[:, 3] = angs
    curves2 = curves

# ------------- 5) group adjacent curvelets within given radius to estimate local fiber orientations -----------------
    groups = np.arange(0, len(curves))
    for i in range(len(curves2)):
        if np.all(curves2[i, :]):
            cLow = curves2[:, 2] > np.ceil(curves2[i, 2] - radius)
            cHi = curves2[:, 2] < np.floor(curves2[i, 2] + radius)
            cRad = np.multiply(cLow, cHi)

            rLow = curves2[:, 1] < np.ceil(curves2[i, 1] + radius)
            rHi = curves2[:, 1] > np.floor(curves2[i, 1] - radius)
            rRad = np.multiply(rLow, rHi)

            inNH = bool(np.multiply(cRad, rRad))
            curves2[inNH, :] = 0
            groups[i] = np.where(inNH)
        
    notEmpty = [groups[i] != None for i in range(len(groups))]
    combNH = groups[notEmpty]


# ------------- 6) perform application-specific analytics using measured angles and locations ------------------------


pycurvelets2D(img, 0.001, 2, 3)