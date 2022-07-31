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

# Generate all *_generated_test.dart files:
#   python3 test/generate_test.py

# Requires numpy.

import numpy
import math
import random
import struct
import os

random.seed(2365817263)

kNumsPerLine = 4

kPreamble = '''// Copyright 2022 The fftea authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// GENERATED FILE. DO NOT EDIT.

// Test cases generated with numpy as a reference implementation, using:
//   python3 test/generate_test.py && dart format .

// ignore_for_file: unused_import
// ignore_for_file: require_trailing_commas

import 'package:fftea/fftea.dart';
import 'package:fftea/impl.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {'''

def randReal(r):
  return random.uniform(-r, r)

def randCplx(r):
  return complex(randReal(r), randReal(r))

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

def writer(f):
  def write(s):
    f.write('%s\n' % s)
  return write

def writeMatrix(filename, m):
  print('  Writing %s' % filename)
  with open(filename, 'wb') as f:
    f.write(b'MAT ')
    f.write(len(m).to_bytes(4, 'little'))
    for mm in m:
      f.write(len(mm).to_bytes(4, 'little'))
      for x in mm:
        f.write(bytearray(struct.pack('d', x)))

_data = set()
def createDataset(filename, maker):
  if filename not in _data:
    _data.add(filename)
    writeMatrix(filename, maker())

def cplxToArray(c):
  return [
    [numpy.real(z) for z in c],
    [numpy.imag(z) for z in c],
  ]

def generate(write, impl, sizes, extraCtorArg = ''):
  write(kPreamble)

  def ctor(n):
    if impl.startswith('Fixed'):
      return '%s()' % impl
    return '%s(%d%s)' % (impl, n, extraCtorArg)

  def makeFftCase(n):
    matfile = 'test/data/fft_%d.mat' % n
    def maker():
      a = [randCplx(10) for i in range(n)]
      f = cplxToArray(numpy.fft.fft(a))
      b = cplxToArray(a)
      return [b[0], b[1], f[0], f[1]]
    createDataset(matfile, maker)
    write("  test('%s %d', () async {" % (impl, n))
    write("    await testFft('%s', %s);" % (matfile, ctor(n)))
    write('  });\n')

  for n in sizes:
    makeFftCase(n)

  def makeRealFftCase(n):
    matfile = 'test/data/real_fft_%d.mat' % n
    def maker():
      a = [randReal(10) for i in range(n)]
      f = cplxToArray(numpy.fft.fft(a))
      return [a, f[0], f[1]]
    createDataset(matfile, maker)
    write("  test('Real %s %d', () async {" % (impl, n))
    write("    await testRealFft('%s', %s);" % (matfile, ctor(n)))
    write('  });\n')

  for n in sizes:
    makeRealFftCase(n)

  write('}\n')

def generateMisc(write):
  write(kPreamble)

  def makeWindowCase(n, name, fn):
    matfile = 'test/data/window_%s_%d.mat' % (name, n)
    def maker():
      return [fn(n)]
    createDataset(matfile, maker)
    write("  test('Window %s %d', () async {" % (name, n))
    write("    await testWindow('%s', Window.%s(%s));" % (matfile, name, n))
    write('  });\n')

  def makeWindowApplyRealCase(n, name, fn):
    matfile = 'test/data/window_apply_real_%s_%d.mat' % (name, n)
    def maker():
      a = [randReal(10) for i in range(n)]
      b = fn(n) * a
      return [a, b]
    createDataset(matfile, maker)
    write("  test('Window apply real %s %d', () async {" % (name, n))
    write("    await testWindowApplyReal('%s', Window.%s(%s));" % (
        matfile, name, n))
    write('  });\n')

  def makeWindowApplyComplexCase(n, name, fn):
    matfile = 'test/data/window_apply_complex_%s_%d.mat' % (name, n)
    def maker():
      a = [randReal(10) for i in range(n)]
      b = cplxToArray(fn(n) * a)
      a_ = cplxToArray(a)
      return [a_[0], a_[1], b[0], b[1]]
    createDataset(matfile, maker)
    write("  test('Window apply complex %s %d', () async {" % (name, n))
    write("    await testWindowApplyComplex('%s', Window.%s(%s));" % (
        matfile, name, n))
    write('  });\n')

  for i in [1, 2, 3, 16, 47]:
    makeWindowCase(i, 'hamming', numpy.hamming)
    makeWindowCase(i, 'hanning', numpy.hanning)
    makeWindowCase(i, 'bartlett', numpy.bartlett)
    makeWindowCase(i, 'blackman', numpy.blackman)
    makeWindowApplyRealCase(i, 'hamming', numpy.hamming)
    makeWindowApplyComplexCase(i, 'hamming', numpy.hamming)

  def makeStftCase(n, chunkSize, chunkStride, windowName = None, windowFn = None):
    padn = math.ceil((n - chunkSize) / chunkStride) * chunkStride + chunkSize
    hasWin = windowName is not None
    wn = windowName if hasWin else 'null'
    matfile = 'test/data/stft_%s_%d_%d_%d.mat' % (
        wn, n, chunkSize, chunkStride)
    def maker():
      a = [randReal(10) if i < n else 0 for i in range(padn)]
      w = windowFn(chunkSize) if hasWin else None
      b = [a[:n]]
      i = 0
      while (i + chunkSize) <= len(a):
        z = a[i:(i+chunkSize)]
        if hasWin:
          z = z * w
        f = cplxToArray(numpy.fft.fft(z))
        b.append(f[0])
        b.append(f[1])
        i += chunkStride
      return b
    createDataset(matfile, maker)
    winCtor = ', Window.%s(%s)' % (windowName, chunkSize) if hasWin else ''
    write("  test('STFT %s %d %d %d', () async {" % (wn, n, chunkSize, chunkStride))
    write("    await testStft('%s', STFT(%d%s), %d);" % (matfile, chunkSize, winCtor, chunkStride))
    write('  });\n')

  for n in [47, 128, 1234]:
    for chunkSize in [16, 23]:
      for chunkStride in [5, chunkSize]:
        makeStftCase(n, chunkSize, chunkStride)
        makeStftCase(n, chunkSize, chunkStride, 'hamming', numpy.hamming)

  write('}\n')

def circConv(a, b, n):
  # Numpy and scipy seem to offset the result. So just doing slow naive version.
  aa = [a[i] if i < len(a) else 0 for i in range(n)]
  bb = [b[i] if i < len(b) else 0 for i in range(n)]
  cc = [sum([aa[j] * bb[(i - j) % n] for j in range(n)]) for i in range(n)]
  return cc

def generateConv(write, sizes):
  write(kPreamble)
  for an, bn, cn in sizes:
    matfile = 'test/data/conv_%d_%d_%d.mat' % (an, bn, cn)
    def maker():
      a = [randReal(10) for i in range(an)]
      b = [randReal(10) for i in range(bn)]
      c = circConv(a, b,cn)
      return [a, b, c]
    createDataset(matfile, maker)
    write("  test('Convolve %d %d', () async {" % (an, bn))
    write("    await testConv('%s', %d);" % (matfile, cn))
    write('  });\n')
  write('}\n')

def run(gen, testName, *args):
  outFile = os.path.normpath(os.path.join(
      os.path.dirname(__file__), testName + '_generated_test.dart'))
  print('Writing %s' % outFile)
  with open(outFile, 'w') as f:
    gen(writer(f), *args)

run(generate, 'fixed2_fft', 'Fixed2FFT', [2])
run(generate, 'fixed3_fft', 'Fixed3FFT', [3])
run(generate, 'radix2_fft', 'Radix2FFT', [2 ** i for i in range(11)])
run(generate, 'naive_fft', 'NaiveFFT', [i + 1 for i in range(16)])
run(generate, 'prime_padded_fft', 'PrimeFFT',
    [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 1009, 7919, 28657], ', true')
run(generate, 'prime_unpadded_fft', 'PrimeFFT',
    [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 1009, 7919, 28657], ', false')
run(generate, 'composite_fft', 'CompositeFFT',
    [i + 1 for i in range(12)] + [461, 752, 1980, 2310, 2442, 3410, 4913, 7429])
run(generate, 'fft', 'FFT',
    [i + 1 for i in range(12)] + [461, 752, 1980, 2310, 2442, 3410, 4913, 7429])
run(generateConv, 'convolution',
    [(1, 1, 1), (5, 47, 47), (91, 12, 91), (127, 129, 128), (337, 321, 330),
    (1024, 1024, 1024), (2000, 3000, 1400)])
run(generateMisc, 'misc')
print('Done :)')
