#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Sep 13 22:18:08 2017

@author: neilweiss
"""
import os.path

SUBJECT_ID = '20'
BLOCK = '1'
EPOCH_VERSION = '3'

directory = '../../../Dropbox/NEDE_Dropbox/Data/epoched_v' + EPOCH_VERSION + '/subject_' + SUBJECT_ID
filepath = directory + '/s' + SUBJECT_ID + '_b' + BLOCK + '_epoched.mat'

tmp1 = os.path.isfile(filepath) 
tmp2 = os.path.isdir(directory) 

tmp3 = 4