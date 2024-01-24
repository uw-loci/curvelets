import pandas as pd
from collections import namedtuple, deque
import math
import itertools
import functools
from functools import reduce
from itertools import product
import numpy as np
from scipy.interpolate import UnivariateSpline
import cv2
import random
from skimage import morphology, img_as_bool, transform, img_as_ubyte, img_as_float, img_as_uint, exposure, filters, io
from skimage.measure import label, regionprops
from scipy import stats
from shapely.geometry import LineString, MultiPoint
from shapely.ops import split
from ridge_detection.lineDetector import LineDetector
from ridge_detection.params import Params,load_json
from PIL import Image
import matplotlib.pyplot as plt
import colorsys

class CenterLine():
    def __init__(self, 
        centerline_image=None, 
        line_dict=None, 
        dataframe=None, 
        associate_image=None, 
        image_size=None, 
        draw_from_raw=False, 
        min_fiber_length=5, 
        relink_fiber=False):
        """
            args: 
                centerline_image (array): a binary mask for the fibers
                line_dict (dictionary): a line_dict {'line_ID': [Point]}
                dataframe (df): check `example_annotations.csv` for reference
                associate_image (array): a collagen image
                image_size (tuple): (H, W)
                draw_from_raw (bool): use skeletonization on associate_image, when other higher priority inputs are not given
                min_fiber_length (int): minimum length of fibers kept
            comments:
                line_dict will always be created at initialization (None by default), the priority of inputs used to draw centerline_image
                line_dict > dataframe > centerline_image
        """
        self.centerline_image = img_as_float(centerline_image) if centerline_image is not None else None
        self.associate_image = img_as_float(associate_image) if associate_image is not None else None
        self.line_dict = line_dict 
        self.linked_line_dict = None
        self.Point = namedtuple('Point', 'x y')
        self.Joint = namedtuple('Joint', 'line_ID joint_ID dir gradient')
        self.Line = namedtuple('Line', 'points head tail')
        self.Segment = namedtuple('Segment', 'point_0, point_1, length')
        if image_size is None:
            if self.centerline_image is not None:
                image_size = self.centerline_image.shape
            elif self.associate_image is not None:
                image_size = self.associate_image.shape
            else:
                image_size = (512, 512)
        self.image_size = image_size
        self.min_fiber_length = min_fiber_length

        if self.line_dict is not None:
            self.centerline_image = self.draw_line_dict(line_dict=self.line_dict, image_size=image_size)

        elif self.line_dict is None and dataframe is not None:
            """
                Create a line_dict from the dataframe if line_dict is not given
            """
            line_dict = self.dataframe_to_lines(dataframe)
            centerline_image = self.draw_line_dict(line_dict, image_size=image_size)
            joints_coords, filtered_image = self.joint_filter(centerline_image)
            self.line_dict = self.image_to_line_dict(filtered_image)
            self.centerline_image = centerline_image
            relink_fiber=True  
        
        elif self.line_dict is None and centerline_image is not None:
            """
                Create a line_dict from the centerline_image if line_dict is not given
            """
            joints_coords, filtered_image = self.joint_filter(centerline_image) # masks have joints
            self.line_dict = self.image_to_line_dict(filtered_image)

        else: 
            if draw_from_raw:
                print("Draw masks using skeletonization")
                associate_image = exposure.rescale_intensity(associate_image*1.0, out_range=(0, 2))
                image = morphology.skeletonize(img_as_bool(associate_image))
                joints_coords, filtered_image = self.joint_filter(image)
                self.line_dict = self.image_to_line_dict(filtered_image)  
                relink_fiber = True

        if relink_fiber:
            self.linking_fibers()
            self.line_dict = self.linked_line_dict
            self.centerline_image = self.draw_line_dict(line_dict=self.line_dict, image_size=image_size)


    def dataframe_to_lines(self, label_csv):
        """
            This function generates a line_dict from a dataframe
            args:
                label_csv (df): check `example_annotations.csv` for reference
        """
        line_IDs = set(label_csv.iloc[:, 0])
        line_dict = {}
        for line_ID in line_IDs:
            line_dict[str(line_ID)] = []
        for idx in range(len(label_csv)):
            line_ID = label_csv.iloc[idx, 0]
            line_coords = self.Point(label_csv.iloc[idx, 1], label_csv.iloc[idx, 2]) # x, y 
            line_dict[str(line_ID)].append(line_coords)
        for line_ID in line_IDs:
            line_dict[str(line_ID)] = self.Line(points=line_dict[str(line_ID)], head=-1, tail=-1)
        line_dict = self.sort_line_dict(line_dict)
        return line_dict

    def mat_to_lines(self, mat_data):
        """
            This function generates a line_dict from a matlab mat file produced by ctFIRE.
            args:
                mat_data (dictionary): read from .mat file, check `centerline-baselines.ipynb` for reference
        """
        mat_data_Fa = mat_data['Fa']
        mat_data_xa = mat_data['Xa'][0][0]  
        line_dict = {}
        for k, fiber_ids in enumerate(mat_data_Fa[0][0][0]['v']):
            line_dict[str(k)] = []
            for id in fiber_ids[0]:
                line_coords = self.Point(float(mat_data_xa[id-1, 0]), float(mat_data_xa[id-1, 1]))
                line_dict[str(k)].append(line_coords)
            line_dict[str(k)] = self.Line(points=line_dict[str(k)], head=-1, tail=-1)
        line_dict = self.sort_line_dict(line_dict)
        return line_dict

    def image_to_line_dict(self, filtered_image):
        """
            This function takes a fiber mask (joints filtered) and return a line_dict, note that this is lossy
            args:
                fibered_image (array): a fiber mask (joints filtered)
        """
        labeled = label(filtered_image, connectivity=2)
        regions = regionprops(labeled)
        line_dict = {}
        # return_regions = []
        for idx, region in enumerate(regions):
            if region.area<self.min_fiber_length: continue
            points = [self.Point(x=coord[1], y=coord[0]) for coord in region.coords]
            line_dict[str(idx)] = self.Line(points=points, head=-1, tail=-1)
            # return_regions.append(region)
        line_dict = self.sort_line_dict(line_dict)
        return line_dict


    def joint_filter(self, image):
        """
            This function takes a fiber mask and replace joints with 0
            args:
                image (array): a fiber mask
            returns:
                array: coordinates of joints in an array [N, i, j]
                array: fiber masks (joints filtered)
        """
        image = img_as_float(image)
        coords = []
        corner_tpl = np.array([[1, 0, 1], [0, 0, 0], [1, 0, 1]])
        edge_tpl = np.array([[1, 0, 1], [0, 0, 0], [0, 1, 0]])
        tr_tpl = deque([1, 0, 1, 0 ,0 ,1, 0, 0])
        tr_tpls = []
        for i in range(8):
            tr_tpl.rotate(i)
            tr_tpls.append(np.asarray(tr_tpl))

        for i in range(1, image.shape[0]-1):
            for j in range(1, image.shape[1]-1):
                kernel = image[i-1:i+2, j-1:j+2]
                ks = np.count_nonzero(kernel)
                sn_kernel = np.asarray([
                    kernel[0, 0], kernel[0, 1], kernel[0, 2], kernel[1, 2], 
                    kernel[2, 2], kernel[2, 1], kernel[2, 0], kernel[1, 0]
                ])
                if kernel[1, 1] == 1:
                    if ks==6:
                        coords.append(np.asarray([i, j]))
                    elif np.count_nonzero(kernel*corner_tpl)>=3 or np.count_nonzero(kernel*edge_tpl)>=3:
                        coords.append(np.asarray([i, j]))
                    elif max([np.count_nonzero(sn_kernel*i) for i in tr_tpls])>=3:
                        coords.append(np.asarray([i, j]))
        for coord in coords:
            image[int(coord[0]), int(coord[1])] = 0
        
        return np.vstack(coords) if len(coords)>0 else np.array([]), img_as_ubyte(image)

    def sort_points(self, input_points):
        """
            This function sorts points of a line in spatial order and returns a set of sorted points (that can be connected sequentially)
            args:
                input_points ([Point]): list of Point objects
            returns:
                [Point]: list of Point objects
        """
        sorted_points = []
        unsorted_points = input_points
        unsorted_points = sorted(unsorted_points, key=lambda k: [k.x, k.y])
        start_point = unsorted_points.pop(0)
        sorted_points.append(start_point)
        while len(unsorted_points) > 0:
            current_start_point = sorted_points[-1]
            closest_start_idx = min(range(len(unsorted_points)), 
                key=lambda i: (unsorted_points[i].x-current_start_point.x)**2+(unsorted_points[i].y-current_start_point.y)**2)
            start_dist = (unsorted_points[closest_start_idx].x-current_start_point.x)**2+(unsorted_points[closest_start_idx].y-current_start_point.y)**2
            if len(sorted_points) < 2: 
                sorted_points.append(unsorted_points.pop(closest_start_idx))
                continue
            current_end_point = sorted_points[0]
            closest_end_idx = min(range(len(unsorted_points)), 
                key=lambda i: (unsorted_points[i].x-current_end_point.x)**2+(unsorted_points[i].y-current_end_point.y)**2)
            end_dist = (unsorted_points[closest_end_idx].x-current_end_point.x)**2+(unsorted_points[closest_end_idx].y-current_end_point.y)**2
            if start_dist <= end_dist: sorted_points.append(unsorted_points.pop(closest_start_idx))
            else: sorted_points.insert(0, unsorted_points.pop(closest_end_idx))
        return sorted_points

    def sort_line_dict(self, line_dict):
        """
            This function sorts points of all lines in a line_dict and return copy
        """
        points_dist = lambda pt_0, pt_1 : math.sqrt((pt_0.x-pt_1.x)**2 + (pt_0.y-pt_1.y)**2)
        sorted_line_dict = {}
        for k, v in line_dict.items():
            points = v.points
            sorted_points = self.sort_points(points)
            v = v._replace(points=sorted_points)
            if points_dist(points[0], points[-1]) > 3 or len(points) >= self.min_fiber_length:
                sorted_line_dict[k] = v
        return sorted_line_dict

    def draw_line(self, points, image, offset=(0, 0)):
        """
            This function draws a set of points that defines a centerline on a image (in-place)
            args:
                points ([Point]): list of Point objects
                image (array): a canvas to draw a line
            returns:
                array: a drawing
        """
        points_x = [point.x-offset[0] for point in points]
        points_y = [point.y-offset[1] for point in points]
        points = np.vstack((points_x, points_y)).T.astype(np.int32)
        # Linear length along the line:
        # distance = np.cumsum( np.sqrt(np.sum( np.diff(points, axis=0)**2, axis=1 )) )
        # distance = np.insert(distance, 0, 0)/distance[-1]
        # Build a list of the spline function, one for each dimension:
        if False: #points.shape[0] > 2:
            splines = [UnivariateSpline(distance, coords, k=1, s=.1) for coords in points.T]
            # Computed the spline for the asked distances:
            alpha = np.linspace(0, 1, 75)
            points_fitted = np.rint(np.vstack( spl(alpha) for spl in splines ).T).astype(np.int32)
        else:
            points_fitted = points
        points_fitted = points_fitted.reshape((-1, 1, 2)) 
        if len(image.shape) == 3:
            color = (random.randint(0,255), random.randint(0,255), random.randint(0,255))
            image = cv2.polylines(image, [points_fitted], isClosed=False, color=color, thickness=1)
        else:
            color = 225
            image = cv2.polylines(image, [points_fitted], isClosed=False, color=color, thickness=1)
        return image  


    def draw_line_dict(self, line_dict, image_size=(512, 512)):
        """
            This function draws a line_dict on an image and returns the drawing
        """
        image = np.zeros((image_size[0], image_size[1]), np.uint8)
        for k, v in line_dict.items():
            points = v.points
            image = self.draw_line(points, image)
        image = morphology.dilation(image)
        image = img_as_ubyte(transform.resize(image, (image_size[0], image_size[1]), order=0, anti_aliasing=True))
        _, image = cv2.threshold(image,0,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        image = morphology.skeletonize(img_as_bool(image))
        image = morphology.remove_small_objects(image, min_size=self.min_fiber_length, connectivity=2)
        return image


    def line_gradient(self, line, start=-1): # -1 point backwards
        """
            This function computes the outwards angle at either end of a centerline
            args:
                line ([Point]): a list of sorted Point objects that define a line
        """
        points_angle = lambda pt_1, pt_2 : math.atan2((pt_1.y-pt_2.y), (pt_1.x-pt_2.x)) # point to first point
        points_dist = lambda pt_1, pt_2 : math.sqrt((pt_1.x-pt_2.x)**2 + (pt_1.y-pt_2.y)**2)
        if start==1:
            line = list(reversed(line))
        angle = points_angle(line[0], line[1]) # point to first point
        if len(line)>2:
            if (points_dist(line[1], line[2])+points_dist(line[0], line[1]))==0:
                decay = points_dist(line[0], line[1])/1
            else:
                decay = points_dist(line[0], line[1])/(points_dist(line[1], line[2])+points_dist(line[0], line[1]))
            delta_x = line[1].x + decay*(line[2].x - line[1].x) + decay**2*(line[2].x - line[0].x)
            delta_y = line[1].y + decay*(line[2].y - line[1].y) + decay**2*(line[2].y - line[0].y)
            angle = points_angle(line[0], self.Point(delta_x, delta_y))
        angle = angle * 180 / math.pi
        return angle


    def connect_lines(self, line_dict):
        """
            This function connects centerlines based on their tail/head matches
        """
        count = 0
        line_dict_copy = line_dict.copy()
        for k in list(line_dict_copy.keys()):
            try:
                v = line_dict_copy[k]
                if int(v.head) * int(v.tail) <= 0:
                    if int(v.head)>=0:
                        v_0 = line_dict_copy[v.head]
                        if v_0.head==k:
                            line_dict_copy[v.head] = self.Line(list(reversed(v.points))+v_0.points, head=v.tail, tail=v_0.tail)
                            del line_dict_copy[k]
                        if v_0.tail==k:
                            line_dict_copy[v.head] = self.Line(v_0.points+v.points, head=v_0.head, tail=v.tail)
                            del line_dict_copy[k]
                    if int(v.tail)>=0:
                        v_0 = line_dict_copy[v.tail]
                        if v_0.head==k:
                            line_dict_copy[v.tail] = self.Line(v.points+v_0.points, head=v.head, tail=v_0.tail)
                            del line_dict_copy[k]
                        if v_0.tail==k:
                            # print(Line(v.points+list(reversed(v_0.points)), head=v.head, tail=v_0.head))
                            line_dict_copy[v.tail] = self.Line(v.points+list(reversed(v_0.points)), head=v.head, tail=v_0.head)
                            # print(line_dict_copy)
                            del line_dict_copy[k]
            except Exception as e:
                # print(e)
                pass
        return line_dict_copy 


    def linking_fibers(self, line_dict=None, joint_thresh=3, angle_thresh=60):
        """
            This function takes a line_dict (joints filtered) and return a line_dict with linked fibers. 
            Fiber end points with similar incident angles at the same joint will be connected.
            args:
                joint_thresh (int): radius within a joint to search for fiber end points
                angle_thresh (int): maximum angle degree of two connectable fiber end points
        """
        if line_dict is None:
            line_dict = self.line_dict.copy()
        else:
            line_dict = line_dict.copy()
        end_points = [[item.points[0], item.points[-1]] for key, item in line_dict.items()]
        if len(end_points) < 2:
            self.linked_line_dict = line_dict
            return
        end_points = reduce(lambda x1, x2 : x1+x2, end_points) # flatten
        close_points = lambda pt_1, pt_2, dist_thresh : math.sqrt((pt_1.x-pt_2.x)**2 + (pt_1.y-pt_2.y)**2) < dist_thresh
        
        joints = []
        while len(end_points):
            current_point = end_points.pop() # pop one element
            
            for point in end_points:
                pop_point = close_points(current_point, point, joint_thresh) # compare to the rest
                if pop_point:
                    end_points.remove(point)
                if pop_point:
                    joints.append(current_point)
        joints = list(set(joints))

        grad_list = []
        joint_IDs = []
        for idx, joint in enumerate(joints):
            for k, v in line_dict.items():
                # print(v.points)
                if close_points(v.points[0], joint, joint_thresh):
                    angle_start = self.line_gradient(v.points, -1) # backwards
                    grad_list.append(self.Joint(k, idx, -1, angle_start))
                    joint_IDs.append(idx)
                if close_points(v.points[-1], joint, joint_thresh):
                    angle_end = self.line_gradient(v.points, 1) # forwards
                    grad_list.append(self.Joint(k, idx, 1, angle_end))
                    joint_IDs.append(idx)
        joint_IDs = list(set(joint_IDs))

        joint_dict = {}
        for joint_ID in joint_IDs:
            joint_dict[str(joint_ID)] = []
        for joint_ID in joint_IDs:
            for grad in grad_list:
                if grad.joint_ID==joint_ID:
                    joint_dict[str(joint_ID)].append(grad)
        link_dict = {}
        for k, v in joint_dict.items():
            grads = [i.gradient for i in v]
            diff = [abs(abs(i[0]-i[1])-180) for i in list(product(grads, grads))]
            result = [i for i, x in enumerate(diff) if x<angle_thresh]
            result = [frozenset((i//len(grads), i%len(grads))) for i in result]
            result = set(result)
            result = [set(i) for i in result]
            if len(result) > 1:
                pair_score = [abs(abs(grads[tuple(line_pair)[0]]-grads[tuple(line_pair)[1]])-180) for line_pair in result]
                sorted_result = [x for _, x in sorted(zip(pair_score, result))]
                running_set = set()
                pruned_result = []
                for line_pair in sorted_result:
                    if len(line_pair.intersection(running_set))==0:
                        pruned_result.append(line_pair)
                        running_set = running_set.union(line_pair)

                result = [tuple(i) for i in pruned_result]
            else:
                result = [tuple(i) for i in result]
            link_dict[k] = result

        for (k_1,v_1), (k_2,v_2) in zip(link_dict.items(), joint_dict.items()):
            for i in v_1:
                line_a = v_2[i[0]]
                line_b = v_2[i[1]]
                if line_a.dir==1: # a tail
                    line_dict[line_a.line_ID] = self.Line(line_dict[line_a.line_ID].points, head=line_dict[line_a.line_ID].head, tail=line_b.line_ID) #
                if line_a.dir==-1: # a head
                    line_dict[line_a.line_ID] = self.Line(line_dict[line_a.line_ID].points, head=line_b.line_ID, tail=line_dict[line_a.line_ID].tail)
                if line_b.dir==1: # b tail
                    line_dict[line_b.line_ID] = self.Line(line_dict[line_b.line_ID].points, head=line_dict[line_b.line_ID].head, tail=line_a.line_ID)
                if line_b.dir==-1: # b head
                    line_dict[line_b.line_ID] = self.Line(line_dict[line_b.line_ID].points, head=line_a.line_ID, tail=line_dict[line_b.line_ID].tail)

        line_dict_copy = line_dict.copy()
        heads = max([int(v.head) for k, v in line_dict_copy.items()])
        tails = max([int(v.tail) for k, v in line_dict_copy.items()])
        max_attemp = 0
        while not(heads==-1 and tails==-1):
            max_attemp += 1
            line_dict_copy = self.connect_lines(line_dict_copy)
            heads = max([int(v.head) for k, v in line_dict_copy.items()])
            tails = max([int(v.tail) for k, v in line_dict_copy.items()])
            if max_attemp > 10:
                break
        line_dict_copy = self.sort_line_dict(line_dict_copy)
        self.linked_line_dict = line_dict_copy

    def export_line_dict(self, fname, line_dict=None):
        """
            This function exports a line_dict as a csv file. The format follows ImageJ ridge_detector results.
            args:
                fname (string): file path for saving
        """
        if line_dict is None:
            line_dict = self.line_dict
        P = []
        X = []
        Y = []
        id = 0
        for k, v in line_dict.items():
            points = v.points
            for point in points:
                X.append(point.x)
                Y.append(point.y)
                P.append(id)
            id += 1
        d = {'Polylines': P, 'X': X, 'Y': Y}
        df = pd.DataFrame(data=d)
        df.to_csv(fname)

    def ridge_detector(self, input_image=None, config_fname="ridge_detector_params.json"):
        """
            This function runs ridge_detector on an input image and return a line_dict.
        """
        if input_image is None and self.associate_image is not None:
            input_image = img_as_ubyte(self.associate_image)
        json_data = load_json(config_fname)
        params = Params(config_fname)
        detect = LineDetector(params=config_fname)
        img = Image.fromarray(input_image)
        result = detect.detectLines(img)
        line_dict = {}
        for id, r in enumerate(result):
            line_dict[str(id)] = []
            x_coords = r.getXCoordinates()
            y_coords = r.getYCoordinates()
            for i in range(len(x_coords)):
                line_coords = self.Point(float(x_coords[i]), float(y_coords[i]))
                line_dict[str(id)].append(line_coords)
            line_dict[str(id)] = self.Line(points=line_dict[str(id)], head=-1, tail=-1)
        line_dict = self.sort_line_dict(line_dict)
        return line_dict

    def single_fiber_feats(self, fragments):
        points_dist = lambda pt_0, pt_1 : math.sqrt((pt_0.x-pt_1.x)**2 + (pt_0.y-pt_1.y)**2)
        segment_angle = lambda segment : math.atan2((segment.point_1.y-segment.point_0.y), (segment.point_1.x-segment.point_0.x)) #* 180 / math.pi
        seg_angles = []
        seg_lengths = []
        for fragment in fragments:
            # p0, p1 = fragment # (x1, y1), (x2, y2)
            sx, sy = fragment.coords.xy[0][0], fragment.coords.xy[1][0]
            ex, ey = fragment.coords.xy[0][-1], fragment.coords.xy[1][-1]
            # if sx <= ex:
            point_0 = self.Point(sx, sy)
            point_1 = self.Point(ex, ey)
            # if sx > ex:
                # point_1 = self.Point(sx, sy)
                # point_0 = self.Point(ex, ey)
            seg = self.Segment(point_0, point_1, points_dist(point_0, point_1))
            seg_angle = segment_angle(seg)
            seg_length = seg.length
        seg_angles.append(seg_angle)
        seg_lengths.append(seg_length)
        tuple_count = 0
        waviness = 0
        if len(fragments) > 1:
            fragments_tuple = [(fragments[i], fragments[i+1]) for i in range(len(fragments)-1)]
            for item in fragments_tuple:
                t_len = item[0].length + item[1].length
                d_len = np.sqrt((item[0].coords.xy[0][0]-item[1].coords.xy[0][-1])**2 + (item[0].coords.xy[1][0]-item[1].coords.xy[1][-1])**2)
                waviness += (t_len-d_len) /t_len * 2 
                tuple_count += 1
            if len(fragments) > 2:
                fragments_tuple = [(fragments[i], fragments[i+1], fragments[i+2]) for i in range(len(fragments)-2)]
                for item in fragments_tuple:
                    t_len = item[0].length + item[1].length + item[2].length
                    d_len = np.sqrt((item[0].coords.xy[0][0]-item[2].coords.xy[0][-1])**2 + (item[0].coords.xy[1][0]-item[2].coords.xy[1][-1])**2)
                    waviness += (t_len-d_len)/t_len * 3 
                    tuple_count += 1
        waviness = waviness / max(1, tuple_count)
        waviness = np.tanh(waviness*2)
        return seg_angles, seg_lengths, waviness

    def compute_fiber_feats(self, seg_length=4, smooth_sigma=2):
        """
            This function computes centerline features from the centerline_image
            args:
                seg_length (int): the mean of segment length used to fit each fiber
                smooth_sigma (int): smoothing factor for soft mask
        """
        # compute cirvar, cirmean, lenvar, lenmean, num_segs, alignment coefficient (normalized)
        points_dist = lambda pt_0, pt_1 : math.sqrt((pt_0.x-pt_1.x)**2 + (pt_0.y-pt_1.y)**2)
        segment_angle = lambda segment : math.atan2((segment.point_1.y-segment.point_0.y), (segment.point_1.x-segment.point_0.x)) #* 180 / math.pi
        # _, filtered_image = self.joint_filter(self.centerline_image)
        # line_dict = self.image_to_line_dict(filtered_image)
        # self.linking_fibers(line_dict)
        line_dict = self.line_dict
        line_regions = []
        angles = []
        lengths = []
        full_lengths = []
        waviness = []
        single_segment = 0
        for k, v in line_dict.items():
            points = v.points
            # min_x = min([p.x for p in points])
            # min_y = min([p.y for p in points])
            # max_x = max([p.x for p in points])
            # max_y = max([p.y for p in points])
            image = np.zeros((512, 512), np.uint8)
            image = self.draw_line(points, image)
            # image = morphology.skeletonize(image)
            sub_regions = regionprops(label(image, connectivity=2))
            _, image = self.joint_filter(sub_regions[0].image)
            labeled = label(image, connectivity=2)
            regions = regionprops(labeled)
            line_regions.extend(regions)
        line_regions = [i for i in line_regions if i.area>=self.min_fiber_length]
        for region in line_regions:   
            points = [self.Point(point[1]+1, point[0]+1) for point in region.coords]
            points = self.sort_points(points)
            shape_line = LineString([(point.x, point.y) for point in points])
            num_seg = int(np.ceil(shape_line.length/seg_length))
            split_points = [int(i*seg_length) for i in range(1, num_seg)]
            splitter = MultiPoint([shape_line.interpolate(i) for i in split_points])
            if len(splitter) < 1: fragments = [shape_line]
            else: fragments = split(shape_line, splitter)
            seg_angles, seg_lengths, wav = self.single_fiber_feats(fragments)
            angles.extend(seg_angles)
            lengths.extend(seg_lengths)
            full_lengths.append(region.area)
            waviness.append(wav)
            
        if smooth_sigma > 0: density = smooth_mask(self.centerline_image, smooth_sigma=smooth_sigma)
        else: density = self.centerline_image
        if len(waviness)>0:
            angles_norm = norm_counts(angles, lengths)
            cirmean = stats.circmean(angles_norm, high=math.pi/2, low=-math.pi/2)
            cirvar = stats.circvar(angles_norm, high=math.pi/2, low=-math.pi/2)
            lenmean = np.mean(full_lengths)
            # lenvar = np.var(exposure.rescale_intensity(np.vstack(lengths), out_range=(0, 1)))
            lenvar = np.std(full_lengths)
            intensity = np.count_nonzero(self.centerline_image)
            # waviness = np.mean(np.asarray(waviness)) * (len(lengths) + single_segment)/len(lengths)
            waviness = np.mean(waviness)
            feats = {
                'cir_mean' : cirmean, 'cir_var' : cirvar, 'len_mean' : lenmean, 'len_var' : lenvar, 
                'waviness' : waviness, 'intensity' : intensity, 'density' : density
                }
        else:
            feats = {
                'cir_mean' : -1, 'cir_var' : -1, 'len_mean' : -1, 'len_var' : -1,
                'waviness' : -1, 'intensity' : -1, 'density' : density}
        self.feats = feats
        self.regions = line_regions

    def create_overlay(self, figsize=(20, 20)):
        assert self.associate_image is not None
        assert self.line_dict is not None
        fig, ax = plt.subplots(1, 3, figsize=figsize)
        ax[0].imshow(self.associate_image, cmap=plt.cm.gray)
        canvas = np.ones((self.image_size[0], self.image_size[1], 3), np.uint8) * 0
        line_dict = self.line_dict
        for k, v in line_dict.items():
            points = v.points
            image = np.zeros((512, 512), np.uint8)
            image = self.draw_line(points, image)
            (r, g, b) = colorsys.hsv_to_rgb(np.random.uniform(0, 1), 1.0, 1.0)
            R, G, B = int(255 * r), int(255 * g), int(255 * b)
            canvas[np.where(image>0)] = np.array([R, G, B])
        ax[1].imshow(canvas)

        ### overlay
        im_arr = self.associate_image
        canvas = img_as_ubyte(np.repeat(im_arr[:, :, np.newaxis], 3, axis=2)) 
        line_dict = self.line_dict
        for k, v in line_dict.items():
            points = v.points
            image = np.zeros((512, 512), np.uint8)
            image = self.draw_line(points, image)
            (r, g, b) = colorsys.hsv_to_rgb(np.random.uniform(0, 1), 1.0, 1.0)
            R, G, B = int(255 * r), int(255 * g), int(255 * b)
            canvas[np.where(image>0)] = np.array([R, G, B])
        ax[2].imshow(canvas)
        plt.show()

    
def smooth_mask(mask, smooth_sigma=2):
    """
        This function returns a soften mask from a binary mask.
    """
    mask = img_as_float(mask)
    mask = exposure.rescale_intensity(mask, out_range=(0, 1))
    density = exposure.rescale_intensity(filters.gaussian(  mask,
                                                            # morphology.dilation(mask, 
                                                            # footprint=morphology.disk(1)), 
                                                            sigma=smooth_sigma, 
                                                            preserve_range=False), 
                                        out_range=(0, 1))
    return density

def norm_counts(counts, weights, beta=0.1):
    """
        This function returns a set of reweighted counts, based on the weights of bins
        args:
            counts ([int]): histogram to be reweighted
            weights ([float]): weights for the bins
    """
    weights = [i+beta for i in weights] # smooth
    weights = [i/ min(weights) for i in weights]
    counts_norm = [list(itertools.repeat(count, int(weight*100)))  for count, weight in zip(counts, weights)]
    return functools.reduce(lambda x1, x2 : x1+x2, counts_norm) 

def iou(mask_1, mask_2, beta=1e-3, soft=False):
    """
        This function computes a (soft) IoU of two input masks.
    """
    if soft:
        union = mask_1**2 + mask_2**2 - mask_1*mask_2
        intersection = mask_1 * mask_2
    else:
        union = np.logical_or(mask_1, mask_2)
        intersection = np.logical_and(mask_1, mask_2)
    ratio = (intersection.sum()+beta)/(union.sum()+beta)
    return ratio, union, intersection


def norm_feats(vecs):
    """
        This function normalize the features to 0-1.
    """
    vecs_1 = vecs.copy()
    for col in range(vecs_1.shape[1]):
        vecs_1[:, col] = exposure.rescale_intensity(vecs_1[:, col], out_range=(0, 1))
    return vecs_1
    