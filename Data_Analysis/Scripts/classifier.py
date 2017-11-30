import sys
import scipy
import os
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
from random import random as rand
sys.path.append('../liblsl-Python-1.11/liblsl-Python/pylsl')
from pylsl import StreamInlet, resolve_byprop, StreamInfo, StreamOutlet
sys.path.append('../../../EEGnet-VR')
sys.path.append('../../../EEGnet-VR/weights/jenn')
from EEGNet import EEGNet

#SETTINGS
SAVE_EPOCHED_DATA = False
SAVE_CLASSIFICATION_DATA = False
SINGLE_TRIAL_FEEDBACK = False
BLOCK_PREDICTION = False
EPOCH_VERSION = '6'
TRAINING = False

# Create LSL outlet
info = StreamInfo('Python', 'classifications', 3)
outlet = StreamOutlet(info)
print("Outlet Created: Python->Unity")

# Create LSL inlet
stream = resolve_byprop('name', 'Matlab->Python')
inlet = StreamInlet(stream[0])
print("Inlet Created: Matlab->Python")

# Initialize variables
counter_epoch = 0
eeg = np.zeros((64, 385, 20))
pupil = np.zeros((20,241))
head_rotation = np.zeros((20,152))
dwell_time = np.zeros((20))
stimulus_type = np.zeros((20))
billboard_id = np.zeros((20))
billboard_cat = np.zeros((20))
image_no = np.zeros((20))
classification = np.zeros((20))
confidence = np.zeros((20))
target_cat = 0

# Initialize Deep Learning
np.random.seed(123)
EEGnet = EEGNet(type= 'VR')
EEGnet.model.load_weights('../../../EEGnet-VR/weights/jenn/CombinedModelWeights_fold8.hf5')

print("Now Receiving Data")
print()

# Wait for cue from matlab to start a new block
while True:
    # Pull a new chunk
    #chunk, timestamps = inlet.pull_chunk(timeout = 1)
    chunk, timestamps = inlet.pull_chunk(timeout=.1)
    epoch = np.transpose(np.asarray(chunk))
    if epoch.shape[0] != 0:        

        # Check if chunk is cue end current block
        if epoch[-1,-1] == -1:
            BLOCK = int(epoch[-1,-2])
            print("***Finished block: ", BLOCK,"***")
            
        # Check if chunk is cue to end the session
        if epoch[-1,-1] == -2:
            print("Ending session")
            break

        # Check if chunk is cue to start new block
        if epoch[-1,-1] == 1:
            SUBJECT_ID = int(epoch[-1,-3])
            BLOCK = int(epoch[-1,-2])
            print("***Starting block ", BLOCK, "***")
            directory = '../../../Dropbox/NEDE_Dropbox/Data/epoched_v' + EPOCH_VERSION + '/subject_' + str(SUBJECT_ID)
            filepath = directory + '/s' + str(SUBJECT_ID) + '_b' + str(BLOCK) + '_epoched.mat'
            # Check that the file paths are correct
            if SAVE_EPOCHED_DATA:
                if not os.path.exists(directory):
                    os.makedirs(directory)
                    print('made directory: ' + directory)
                if os.path.exists(filepath):
                    raise ValueError('Path already exists. Do not overwrite data!')
    
        # If chunk is an epoch of data
        if epoch[-1,-1] == 0:
            eeg[:,:,counter_epoch] = epoch[0:-2,0:385]
            head_rotation[counter_epoch,:] = epoch[-2,0:head_rotation.shape[1]]
            stimulus_type[counter_epoch] = epoch[-1,0]
            billboard_id[counter_epoch] = epoch[-1,1]
            dwell_time[counter_epoch] = epoch[-1,2]
            billboard_cat[counter_epoch] = epoch[-1,3]
            image_no[counter_epoch] = epoch[-1,4]
            pupil[counter_epoch,:] = epoch[-1, 5:246]
    
            # Classify data
            # process data
            eeg_trial = eeg[:,:,counter_epoch]
            eeg_trial = np.reshape(eeg_trial,eeg_trial.shape + (1,))
            eeg_trial = np.transpose(eeg_trial,(2,0,1))
            eeg_trial = np.reshape(eeg_trial,eeg_trial.shape + (1,))
    
            head_trial = head_rotation[counter_epoch,:]
            head_trial = np.reshape(head_trial,(1,) + head_trial.shape + (1,))
    
            pupil_trial = pupil[counter_epoch,:]
            pupil_trial = np.reshape(pupil_trial,(1,) + pupil_trial.shape + (1,))
    
            dwell_trial = dwell_time[counter_epoch]
            dwell_trial = np.reshape(dwell_trial, (1,1,1))

            #weightsfilename = '../../../EEGnet-VR/weights/test/CombinedModelWeights_fold8.hf5'
            #EEGnet.model.load_weights(weightsfilename)
            #probs = EEGnet.model.predict([eeg_trial, head_trial, pupil_trial, dwell_trial])
            probs = np.random.rand(1,2)
            
            pred_class = np.argmax(probs)
            confidence = probs[0,1]
            stream_out = [billboard_id[counter_epoch], pred_class, confidence]
    
            # random classifier
            #stream_out = [billboard_id[counter_epoch], np.round(3.0 * rand())+1, rand()]
            if SINGLE_TRIAL_FEEDBACK:
                outlet.push_sample(stream_out)
                print('Billboard No: %d    Classification: %d    Confidence: %f' %(stream_out[0], stream_out[1], stream_out[2]))
    
            #t_prev = time.time()
            counter_epoch += 1

inlet.close_stream()
print('inlet closed')
outlet.__del__()
print('outlet closed')
print('Actual target category: %d' %target_cat)

# Delete trials where the subject missed the billboard
missed_trials = np.where(stimulus_type == 0)
eeg = np.delete(eeg, missed_trials, 2)
head_rotation = np.delete(head_rotation, missed_trials, 0)
stimulus_type = np.delete(stimulus_type, missed_trials, 0)
billboard_id = np.delete(billboard_id, missed_trials, 0)
dwell_time = np.delete(dwell_time, missed_trials, 0)
billboard_cat = np.delete(billboard_cat, missed_trials, 0)
pupil = np.delete(pupil, missed_trials, 0)
classification = np.delete(classification, missed_trials, 0)
confidence = np.delete(confidence, missed_trials, 0)

if BLOCK_PREDICTION:
    pred_block = np.round(3.0 * rand())+1
    if pred_block == 1:
        image = Image.open('Pics/car_side-46.jpg').convert("L")
        plt.figure
        arr = np.asarray(image)
        plt.imshow(arr, cmap='gray')
        plt.show()
        plt.title('I know what you want...')
    if pred_block == 2:
        image = Image.open('Pics/grand_piano-2.jpg')
        plt.figure
        plt.imshow(image)
        plt.title('is it a piano you seek?')
    if pred_block == 3:
        image = Image.open('Pics/laptop-7.jpg')
        plt.figure
        plt.imshow(image)
        plt.title('looking for one of these?')
    if pred_block == 4:
        image = Image.open('Pics/schooner-4.jpg')
        plt.figure
        plt.imshow(image)
        plt.title('is this what you had in mind?')


print('Number of targets observed: %d' %np.sum(stimulus_type == 1))

# Save data
if SAVE_EPOCHED_DATA:
    # Check that you are not overwriting existing data
    if os.path.isfile(filepath):
        raise Exception('Data file already exists. Update subject and block number.')

    # If the directory does not already exist, create it
    if not os.path.isdir(directory):
        os.makedirs(directory)

    target_cat = target_cat * np.ones((len(stimulus_type)))
    scipy.io.savemat(filepath, {'EEG': eeg, 'stimulus_type': stimulus_type, 'billboard_id': billboard_id,'dwell_times': dwell_time, 'pupil': pupil, 'head_rotation': head_rotation, 'billboard_cat': billboard_cat, 'image_no': image_no, 'target_category': target_cat, 'classification': classification, 'confidence': confidence})
    print('Data Saved')
print('done')