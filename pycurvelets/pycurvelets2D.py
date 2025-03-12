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
    emptyC = [[np.zeros_like(imgC[cc][dd]) for dd in range(len(imgC[cc]))] for cc in range(len(imgC))]

# --------------- 2) selects scale at which coefficients will be used (scale of interest) ----------------------------
    scale = len(imgC) - sscale 

    # scale coefficients to remove artifacts ****CURRENTLY ONLY FOR 1024x1024 
    # tempA = [1, .64, .52, .5, .46, .4, .35, .3] FOR 1024x1024
    tempA = np.array([1, 0.8, 0.6, 0.5])
    tempB = np.hstack((tempA, tempA[::-1], tempA, tempA[::-1]))
    scaleMat = np.hstack((tempB, tempB))

    for i in range(len(imgC[scale])):
        imgC[scale][i] = np.abs(imgC[scale][i])

# ------------------- 3) choose threshold the remaining coeffs based on user-defined threshold -----------------------
    # maxValsForAbs = [np.max(arr) for arr in imgC[scale]]
    # absMax = np.max(maxValsForAbs)
    # bins = np.arange(0, absMax * 0.01 + absMax, 0.01 * absMax)
    # histVals = [np.histogram(arr, bins=bins)[0] for arr in imgC[scale]]
    # sumHist = [np.sum(row, axis=0) for row in histVals]

    abs_max = max([np.max(np.max(x)) for x in imgC[scale]])
    bins = np.arange(0, abs_max + 0.01 * abs_max, 0.01 * abs_max)
    
    hist_vals = []
    for x in imgC[scale]:
        hist_counts, _ = np.histogram(x, bins=bins)
        hist_vals.append(hist_counts)
    
    sum_hist = []
    for x in hist_vals:
        if np.isscalar(x) or (isinstance(x, np.ndarray) and x.ndim == 0):
            sum_hist.append(np.array([x]))  # Convert scalars to 1D arrays
        else:
            sum_hist.append(np.sum(x, axis=0))
    
    tot_hist = np.concatenate([np.atleast_1d(sum_hist[i]) for i in range(len(sum_hist))])
    
    sum_vals = np.sum(tot_hist)
    cum_vals = np.cumsum(tot_hist)
    
    cum_max = np.max(cum_vals)
    loc = np.where(cum_vals > (1 - keep) * cum_max)[0][0]
    max_val = bins[loc]

    for x_idx, x in enumerate(imgC[scale]):
        emptyC[scale][x_idx] = x * (np.abs(x) >= max_val)


# ------------ 4) find center and spatial orientation of each curvelet corresponding to remaining coeffs -------------
    m, n = img.shape
    nbscales = len(imgC)
    nbangles_coarse = len(imgC[1]) // 2
    ac = 0
    X_rows, Y_cols, _, _, _, _ = fdct2d_wrapper.fdct2d_param_wrap(m, n, nbscales, nbangles_coarse, ac)

    long = len(imgC[scale]) // 2
    angles = [None] * long
    row = np.zeros(long)
    col = np.zeros(long)
    increment = 360 / len(imgC[scale])
    startAngle = 225

    for wedgeIdx in range(0, long):
        test = np.where(emptyC[scale][wedgeIdx] != 0)[0]
        if len(test) > 0:
            angle = np.zeros(len(test))
            for i in range(2):
                for specificAngle in range(len(test)):
                    tempAngle = startAngle - (increment * (wedgeIdx - 1))
                    shiftTemp = startAngle - (increment * wedgeIdx)
                    angle[specificAngle] = np.mean([tempAngle, shiftTemp])

            print(angle.shape)
            print(wedgeIdx)
            
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

    c_test = [len(x) > 0 and np.any(x != 0) for x in col]
    bb = np.where(c_test)[0]

    if len(bb) == 0:
        return [], Ct, inc
    
    # Concatenate the non-empty arrays
    col_flat = np.concatenate([col[i] for i in bb])
    row_flat = np.concatenate([row[i] for i in bb])
    angs_flat = np.concatenate([angs[i] for i in bb])
    
    curves = np.column_stack((row_flat, col_flat, angs_flat))
    curves2 = curves.copy()

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

    if len(comb_nh) == 0:
        return [], Ct, inc
    
    n_hoods = [curves[x, :] for x in comb_nh]
    
    def fix_angle(angles, inc):
        """
        Fix angle values to be between 0 and 180 degrees
        """
        return angles % 180
    
    angles = [fix_angle(x[:, 2], inc) for x in n_hoods]
    centers = [np.array([np.round(np.median(x[:, 0])).astype(int), 
                        np.round(np.median(x[:, 1])).astype(int)]) for x in n_hoods]
    
    # Create output structure
    object_list = [{'center': centers[i], 'angle': angles[i]} for i in range(len(centers))]
    
    def rotate(object_list):
        """Rotate all angles to be from 0 to 180 degrees."""
        for i in range(len(object_list)):
            object_list[i]['angle'] = object_list[i]['angle'] % 180
        return object_list
    
    object_list = rotate(object_list)
    
    all_center_points = np.vstack([obj['center'] for obj in object_list])
    cen_row = all_center_points[:, 0]
    cen_col = all_center_points[:, 1]
    
    im_rows, im_cols = img.shape
    edge_buf = np.ceil(min(im_rows, im_cols) / 100).astype(int)
    
    in_idx = np.where((cen_row < im_rows - edge_buf) & 
                    (cen_col < im_cols - edge_buf) & 
                    (cen_row > edge_buf) & 
                    (cen_col > edge_buf))[0]
    
    in_curvs = [object_list[i] for i in in_idx]
    
    return in_curvs, img_c, inc


pycurvelets2D(img, 0.001, 2, 3)