# Copyright 2022 The fftea authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import numpy
import math
import random

kNumsPerLine = 4

def randReal(r):
  return random.uniform(-r, r);

def randCplx(r):
  return complex(randReal(r), randReal(r));

def realBufStr(a):
  def impl(b):
    return ', '.join(['%.8f' % x for x in b])
  if len(a) <= kNumsPerLine:
    return impl(a)
  s = '\n'
  i = 0
  while i < len(a):
    j = min(i + kNumsPerLine, len(a))
    s += '        %s,' % impl(a[i:j])
    if j < len(a):
      s += ' //'
    s += '\n'
    i = j
  return s + '      '

def cplxBufStr(a):
  b = []
  for z in a:
    b.append(numpy.real(z))
    b.append(numpy.imag(z))
  return realBufStr(b)

def makeFftCase(n):
  a = [randCplx(10) for i in range(n)];
  f = numpy.fft.fft(a)
  print('    testFft(')
  print('      [%s],' % cplxBufStr(a))
  print('      [%s],' % cplxBufStr(f))
  print('    );')

print("  test('FFT', () {");
makeFftCase(1)
makeFftCase(2)
makeFftCase(4)
makeFftCase(8)
makeFftCase(16)
makeFftCase(32)
makeFftCase(64)
makeFftCase(128)

def makeRealFftCase(n):
  a = [randReal(10) for i in range(n)];
  f = numpy.fft.fft(a)
  print('    testRealFft(')
  print('      [%s],' % realBufStr(a))
  print('      [%s],' % cplxBufStr(f))
  print('    );')

print('  });\n')
print("  test('Real FFT', () {");
makeRealFftCase(1)
makeRealFftCase(2)
makeRealFftCase(4)
makeRealFftCase(8)
makeRealFftCase(16)
makeRealFftCase(32)
makeRealFftCase(64)
makeRealFftCase(128)
print('  });')
