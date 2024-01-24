import pandas as pd
import csv


def read_pickle():

    object = pd.read_pickle(r'mask.tif_boundary_coordinate_stack.pickle')
    length = len(object[0])
    f = open('cells.csv', 'w')
    writer = csv.writer(f)
    array = []
    writer.writerow(array)
    f.close()