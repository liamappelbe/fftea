// Copyright 2022 The fftea authors
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

import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:test/test.dart';

Float64List toFloats(Float64x2List a) => Float64List.sublistView(a);
Float64x2List makeArray(List<double> values) {
  return Float64x2List.sublistView(Float64List.fromList(values));
}

void expectClose(List<double> inp, List<double> exp) {
  expect(inp.length, exp.length);
  for (int i = 0; i < inp.length; ++i) {
    expect(inp[i], closeTo(exp[i], 1e-6));
  }
}

void testFft(List<double> inp, List<double> exp) {
  final buf = makeArray(inp);
  final fft = FFT(buf.length)..inPlaceFft(buf);
  expect(buf.length, inp.length / 2);
  expectClose(toFloats(buf), exp);
  fft.inPlaceInverseFft(buf);
  expectClose(toFloats(buf), inp);
}

void testRealFft(List<double> inp, List<double> exp) {
  final fft = FFT(inp.length);
  final buf = fft.realFft(inp);
  expect(buf.length, inp.length);
  expectClose(toFloats(buf), exp);
  final a = fft.realInverseFft(buf);
  expectClose(a, inp);
}

void testStft(
  int chunkSize,
  int chunkStride,
  List<double> inp,
  List<List<double>> exp,
) {
  final stft = STFT(chunkSize, Window.hanning(chunkSize));
  final result = stft.runAndCopy(inp, chunkStride);
  expect(result.length, exp.length);
  for (int i = 0; i < result.length; ++i) {
    expectClose(toFloats(result[i]), exp[i]);
  }
}
