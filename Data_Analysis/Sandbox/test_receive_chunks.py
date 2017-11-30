import sys
import time
import numpy as np
from random import random as rand
sys.path.append('liblsl-Python-1.11/liblsl-Python/pylsl')
from pylsl import StreamInlet, resolve_byprop, StreamInfo, StreamOutlet

# Create LSL inlet
stream = resolve_byprop('name', 'Matlab')
inlet = StreamInlet(stream[0])

print('Got the matlab stream')
counter_epoch = 0

tmp = np.zeros((66,385))

# RECEIVE DATA    
# try to pull a new chunk 
while True:
    chunk, timestamps = inlet.pull_chunk(timeout = .3)
    epoch = np.transpose(np.asarray(chunk))
    
    # if a chunk is received
    if epoch.shape[0] != 0:
        
        if epoch[-1,-1] != 0.0:
            print('got exit cue')
            break
        
        tmp = epoch
        print('epoch received')
        print(counter_epoch)
        print(epoch.shape)
        print
        counter_epoch += 1
            
print('done')