# built-in libraries
import os
# external libraries
import pandas as pd
from tkinter import END
import scipy.io as sio

def collect_seleced_bstack(csv, buildmodel):
	print('## collect_selected_bstack.py')
	if buildmodel:
		ui = pd.read_csv(csv)
		setpaths = ui['set location']
		tag = ui['tag']
		bstacks = []
		for setidx, setpath in enumerate(setpaths):
			pickles = [_ for _ in os.listdir(setpath) if _.lower().endswith('pickle')]
			bstack = [pd.read_pickle(os.path.join(setpath, pkl)) for pkl in pickles if tag[setidx] in pkl]
			bstacks = bstacks + bstack
		try:
			df = pd.concat(bstacks, ignore_index=True)
		except:
			print('Failed: CSV file is empty.')
			df = None
	else:
		raise NameError('collect_seleced_bstack is only for buildmodel')
		return
	return df
