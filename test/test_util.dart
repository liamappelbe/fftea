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

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:test/test.dart';

Float64List toFloats(Float64x2List a) => Float64List.sublistView(a);
Float64x2List makeArray(List<double> values) {
  return Float64x2List.sublistView(Float64List.fromList(values));
}

Float64x2List makeArray2(List<double> real, List<double> imag) {
  if (real.length != imag.length) {
    throw ArgumentError('real and imag should be the same length');
  }
  final result = Float64x2List(real.length);
  for (int i = 0; i < result.length; ++i) {
    result[i] = Float64x2(real[i], imag[i]);
  }
  return result;
}

void expectClose(List<double> inp, List<double> exp) {
  expect(inp.length, exp.length);
  for (int i = 0; i < inp.length; ++i) {
    expect(inp[i], closeTo(exp[i], 1e-6));
  }
}

void expectClose2(List<Float64x2> inp, List<Float64x2> exp) {
  expect(inp.length, exp.length);
  for (int i = 0; i < inp.length; ++i) {
    expect(inp[i].x, closeTo(exp[i].x, 1e-6));
    expect(inp[i].y, closeTo(exp[i].y, 1e-6));
  }
}

Future<void> testFft(String filename, FFT fft) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 4);
  final buf = makeArray2(raw[0], raw[1]);
  fft.inPlaceFft(buf);
  expectClose2(buf, makeArray2(raw[2], raw[3]));
  fft.inPlaceInverseFft(buf);
  expectClose2(buf, makeArray2(raw[0], raw[1]));
}

Future<void> testRealFft(String filename, FFT fft) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 3);
  final buf = fft.realFft(raw[0]);
  expectClose2(buf, makeArray2(raw[1], raw[2]));
  final a = fft.realInverseFft(buf);
  expectClose(a, raw[0]);
}

Future<void> testWindow(String filename, Float64List window) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 1);
  expectClose(window, raw[0]);
}

Future<void> testWindowApplyReal(String filename, Float64List window) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 2);
  expectClose(window.applyWindowReal(raw[0]), raw[1]);
}

Future<void> testWindowApplyComplex(String filename, Float64List window) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 4);
  expectClose2(
    window.applyWindow(makeArray2(raw[0], raw[1])),
    makeArray2(raw[2], raw[3]),
  );
}

Future<void> testStft(
    String filename, STFT stft, int chunkStride, bool streamed) async {
  if (streamed) return;
  final raw = await readMatFile(filename);
  late List<Float64x2List> result;
  if (streamed) {
    result = <Float64x2List>[];
    void reportChunk(Float64x2List o) => result.add(o);
    final rand = Random(1234);
    final n = raw[0].length;
    for (int i = 0; i < n;) {
      final j = min(i + rand.nextInt(3 * chunkStride), n);
      stft.stream(raw[0].sublist(i, j), reportChunk, chunkStride);
      i = j;
    }
    stft.flush(reportChunk);
  } else {
    result = stft.runAndCopy(raw[0], chunkStride);
  }
  expect(result.length, (raw.length - 1) / 2);
  for (int i = 0; i < result.length; ++i) {
    expectClose2(result[i], makeArray2(raw[2 * i + 1], raw[2 * i + 2]));
  }
}

Future<void> testCircConv(String filename, int? n) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 3);
  final result1 = n == null
      ? circularConvolution(raw[0], raw[1])
      : circularConvolution(raw[0], raw[1], n);
  expectClose(result1, raw[2]);
  final result2 = n == null
      ? circularConvolution(raw[1], raw[0])
      : circularConvolution(raw[1], raw[0], n);
  expectClose(result2, raw[2]);
}

Future<void> testLinConv(String filename) async {
  final raw = await readMatFile(filename);
  expect(raw.length, 3);
  final result1 = convolution(raw[0], raw[1]);
  expectClose(result1, raw[2]);
  final result2 = convolution(raw[1], raw[0]);
  expectClose(result2, raw[2]);
}

Future<List<List<double>>> readMatFile(String filename) async {
  final bytes = await File(filename).readAsBytes();
  int p = 0;
  ByteData read(int n) {
    final p0 = p;
    p += n;
    if (p > bytes.length) {
      throw FormatException('Matrix file is corrupted.');
    }
    return ByteData.sublistView(bytes, p0, p);
  }

  if (String.fromCharCodes(Uint8List.sublistView(read(4))) != 'MAT ') {
    throw FormatException('Matrix file is corrupted.');
  }

  final n = read(4).getUint32(0, Endian.little);
  final m = <List<double>>[];
  for (int i = 0; i < n; ++i) {
    final nn = read(4).getUint32(0, Endian.little);
    final mm = <double>[];
    for (int j = 0; j < nn; ++j) {
      mm.add(read(8).getFloat64(0, Endian.little));
    }
    m.add(mm);
  }
  if (p != bytes.length) {
    throw FormatException('Matrix file is corrupted.');
  }
  return m;
}
