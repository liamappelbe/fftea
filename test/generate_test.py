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

# Generate fftea_generated_test.dart:
#   python3 test/generate_test.py

import numpy
import math
import random
import struct
import os

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
//   python3 test/generate_test.py

import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:test/test.dart';
import 'util.dart';

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

def generate(write, impl, sizes):
  write(kPreamble)

  def makeFftCase(n):
    matfile = 'test/data/fft_%d.mat' % n
    def maker():
      a = [randCplx(10) for i in range(n)]
      f = cplxToArray(numpy.fft.fft(a))
      b = cplxToArray(a)
      return [b[0], b[1], f[0], f[1]]
    createDataset(matfile, maker)
    write("  test('%s %d', () async {" % (impl, n))
    write("    await testFft('%s', %s(%d));" % (matfile, impl, n))
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
    write("    await testRealFft('%s', %s(%d));" % (matfile, impl, n))
    write('  });\n')

  for n in sizes:
    makeRealFftCase(n)

  write('}\n')

def generateMisc(write):
  write(kPreamble)

  def makeWindowCase(n, name, fn):
    write("  test('Window %s %d', () {" % (name, n))
    write('    expectClose(')
    write('      Window.%s(%s),' % (name, n))
    write('      [%s],' % realBufStr(fn(n)))
    write('    );')
    write('  });\n')

  makeWindowCase(16, 'hamming', numpy.hamming)
  makeWindowCase(16, 'hanning', numpy.hanning)
  makeWindowCase(16, 'bartlett', numpy.bartlett)
  makeWindowCase(16, 'blackman', numpy.blackman)

  def makeWindowApplyCase(n):
    a = [randReal(10) for i in range(n)]
    b = numpy.hamming(n) * a
    c = [randCplx(10) for i in range(n)]
    d = numpy.hamming(n) * c
    write("  test('Window apply %d', () {" % n)
    write('    final w = Window.hamming(16);')
    write('    final a = [%s];' % realBufStr(a))
    write('    expectClose(')
    write('      w.applyWindowReal(Float64List.fromList(a)),')
    write('      [%s],' % realBufStr(b))
    write('    );');
    write('    final b = [%s];' % cplxBufStr(c))
    write('    expectClose(')
    write('      toFloats(w.applyWindow(makeArray(b))),')
    write('      [%s],' % cplxBufStr(d))
    write('    );');
    write('  });\n')

  makeWindowApplyCase(16)

  def makeStftCase(n, pn, nc, cs):
    a = [randReal(10) if i < n else 0 for i in range(pn)]
    w = numpy.hanning(nc)
    b = []
    i = 0
    while (i + nc) <= len(a):
      b.append(numpy.fft.fft(a[i:(i+nc)] * w))
      i += cs
    write("  test('STFT %d %d %d %d', () {" % (n, pn, nc, cs))
    write('    testStft(')
    write('      %s,' % nc)
    write('      %s,' % cs)
    write('      [%s],' % realBufStr(a[:n]))
    write('      [')
    for c in b:
      write('      [%s],' % cplxBufStr(c))
    write('      ],')
    write('    );')
    write('  });')

  makeStftCase(128, 128, 16, 8)
  makeStftCase(47, 51, 16, 5)

  write('}\n')

def run(gen, filename, *args):
  outFile = os.path.normpath(os.path.join(os.path.dirname(__file__), filename))
  print('Writing %s' % outFile)
  with open(outFile, 'w') as f:
    gen(writer(f), *args)

run(generate, 'radix2_fft_generated_test.dart', 'Radix2FFT',
    [2 ** i for i in range(11)])
run(generate, 'naive_fft_generated_test.dart', 'NaiveFFT',
    [i + 1 for i in range(16)])
run(generate, 'prime_padded_fft_generated_test.dart', 'PrimePaddedFFT',
    [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 1009, 7919, 28657])
run(generate, 'composite_fft_generated_test.dart', 'CompositeFFT',
    [i + 1 for i in range(12)] + [461, 752, 1980, 2310, 2442, 3410, 4913, 7429])
run(generate, 'fft_generated_test.dart', 'FFT',
    [i + 1 for i in range(12)] + [461, 752, 1980, 2310, 2442, 3410, 4913, 7429])
run(generateMisc, 'fftea_generated_misc_test.dart')
print('Done :)')
