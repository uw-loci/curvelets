from shapely.geometry import Polygon, LineString
import scipy.io as sio

def findRectPoints(X,Y):

    points = []
    for i in range(len(X)):
        points.append((X[i],Y[i]))
    polygon = Polygon(points)
    rect = list(zip(*polygon.minimum_rotated_rectangle.exterior.coords.xy))
    sio.savemat('rect.mat', {'rect':rect})