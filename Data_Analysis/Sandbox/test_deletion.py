import numpy as np

a = np.ones((64,365,20))
b = np.ones(20)

b[18] = 0
b[19] = 0

c = np.where(b == 0)
a = np.delete(a, c, 2)