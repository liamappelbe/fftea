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
import os

kNumsPerLine = 4
kOutFile = 'fftea_generated_test.dart';

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

def generate(f):
  def write(s):
    f.write('%s\n' % s)
  write(kPreamble)

  def makeFftCase(n):
    a = [randCplx(10) for i in range(n)]
    f = numpy.fft.fft(a)
    write('    testFft(')
    write('      [%s],' % cplxBufStr(a))
    write('      [%s],' % cplxBufStr(f))
    write('    );')

  write("  test('FFT', () {")
  makeFftCase(1)
  makeFftCase(2)
  makeFftCase(4)
  makeFftCase(8)
  makeFftCase(16)
  makeFftCase(32)
  makeFftCase(64)
  makeFftCase(128)
  write('  });\n')

  def makeRealFftCase(n):
    a = [randReal(10) for i in range(n)]
    f = numpy.fft.fft(a)
    write('    testRealFft(')
    write('      [%s],' % realBufStr(a))
    write('      [%s],' % cplxBufStr(f))
    write('    );')

  write("  test('Real FFT', () {")
  makeRealFftCase(1)
  makeRealFftCase(2)
  makeRealFftCase(4)
  makeRealFftCase(8)
  makeRealFftCase(16)
  makeRealFftCase(32)
  makeRealFftCase(64)
  makeRealFftCase(128)
  write('  });\n')

  def makeWindowCase(n, name, fn):
    write('    expectClose(')
    write('      Window.%s(%s),' % (name, n))
    write('      [%s],' % realBufStr(fn(n)))
    write('    );')

  write("  test('Window', () {")
  makeWindowCase(16, 'hamming', numpy.hamming)
  makeWindowCase(16, 'hanning', numpy.hanning)
  makeWindowCase(16, 'bartlett', numpy.bartlett)
  makeWindowCase(16, 'blackman', numpy.blackman)
  write('  });\n')

  def makeWindowApplyCase(n):
    a = [randReal(10) for i in range(n)]
    b = numpy.hamming(n) * a
    c = [randCplx(10) for i in range(n)]
    d = numpy.hamming(n) * c
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

  write("  test('Window apply', () {")
  makeWindowApplyCase(16)
  write('  });\n')

  def makeStftCase(n, pn, nc, cs):
    a = [randReal(10) if i < n else 0 for i in range(pn)]
    w = numpy.hanning(nc)
    b = []
    i = 0
    while (i + nc) <= len(a):
      b.append(numpy.fft.fft(a[i:(i+nc)] * w))
      i += cs
    write('    testStft(')
    write('      %s,' % nc)
    write('      %s,' % cs)
    write('      [%s],' % realBufStr(a[:n]))
    write('      [')
    for c in b:
      write('      [%s],' % cplxBufStr(c))
    write('      ],')
    write('    );')

  write("  test('STFT', () {")
  makeStftCase(128, 128, 16, 8)
  makeStftCase(47, 51, 16, 5)
  write('  });')

  write('}\n')

outFile = os.path.normpath(os.path.join(os.path.dirname(__file__), kOutFile))
print('Writing %s' % outFile)
with open(outFile, 'w') as f:
  generate(f)
print('Done :)')
