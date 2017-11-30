import numpy as np
import scipy

a = np.zeros(10)

scipy.io.savemat('Data/test/test.mat', {'a':a})
print('Data Saved')