import numpy
import math
import random
import os

def fftconv(a, b):
  aa = numpy.fft.rfft(a)
  bb = numpy.fft.rfft(b)
  return numpy.fft.irfft([aa[i] * bb[i] for i in range(len(aa))])

print(fftconv([1, 2, 3, 0, 0, 0, 0, 0], [-2, 1, -1, 0, 0, 0, 0, 0]))
