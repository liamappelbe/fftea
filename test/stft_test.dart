// Copyright 2023 The fftea authors
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
import 'test_util.dart';

class Verifier {
  List<List<double>> _chunks = [];
  FFT? _fft;

  void call(Float64x2List chunk) {
    final n = chunk.length;
    if (n != _fft?.size) {
      _fft = FFT(n);
    }
    expectClose2(chunk, chunk.discardConjugates().createConjugates(n));
    _chunks.add(_fft!.realInverseFft(chunk));
  }

  void verify(List<List<double>> chunks) {
    expect(_chunks.length, chunks.length);
    for (int i = 0; i < _chunks.length; ++i) {
      expectClose(_chunks[i], chunks[i]);
    }
    _chunks = [];
  }
}

void main() {
  test('STFT stream then run flushes existing data', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2], v);
    v.verify([]);
    stft.run([3, 4], v);
    v.verify([
      [1, 2, 0, 0],
      [3, 4, 0, 0],
    ]);
  });

  test('STFT stream then run no flush if no existing data', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2, 3, 4], v);
    v.verify([
      [1, 2, 3, 4],
    ]);
    stft.run([5, 6, 7, 8], v);
    v.verify([
      [5, 6, 7, 8],
    ]);
  });

  test('STFT stream then run empty input empty output', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2], v);
    v.verify([]);
    stft.run([], v);
    v.verify([
      [1, 2, 0, 0],
      [0, 0, 0, 0],
    ]);
  });

  test('STFT stream does nothing if no input', () {
    final stft = STFT(4);
    final v = Verifier();
    stft
      ..stream([], v)
      ..stream([], v)
      ..stream([], v)
      ..stream([], v)
      ..stream([], v);
    v.verify([]);
    stft.run([], v);
    v.verify([
      [0, 0, 0, 0],
    ]);
  });

  test('STFT stream then flush flushes existing data', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2], v);
    v.verify([]);
    stft.flush(v);
    v.verify([
      [1, 2, 0, 0],
    ]);
  });

  test('STFT stream then flush does nothing if no existing data', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([], v);
    v.verify([]);
    stft.flush(v);
    v.verify([]);
  });

  test('STFT run then flush does nothing', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.run([1, 2, 3], v);
    v.verify([
      [1, 2, 3, 0],
    ]);
    stft.flush(v);
    v.verify([]);
  });

  test('STFT lone flush does nothing', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.flush(v);
    v.verify([]);
  });

  test('STFT second flush does nothing', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2], v);
    v.verify([]);
    stft.stream([3], v);
    v.verify([]);
    stft.flush(v);
    v.verify([
      [1, 2, 3, 0],
    ]);
    stft.flush(v);
    v.verify([]);
  });

  test('STFT stream flush run', () {
    final stft = STFT(4);
    final v = Verifier();
    stft
      ..stream([1], v)
      ..stream([2], v);
    v.verify([]);
    stft.flush(v);
    v.verify([
      [1, 2, 0, 0],
    ]);
    stft.run([3, 4], v);
    v.verify([
      [3, 4, 0, 0],
    ]);
  });

  test('STFT stream run flush', () {
    final stft = STFT(4);
    final v = Verifier();
    stft
      ..stream([1], v)
      ..stream([2], v);
    v.verify([]);
    stft.run([3, 4], v);
    v.verify([
      [1, 2, 0, 0],
      [3, 4, 0, 0],
    ]);
    stft.flush(v);
    v.verify([]);
  });

  test('STFT flush stream run', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.flush(v);
    v.verify([]);
    stft
      ..stream([1], v)
      ..stream([2], v);
    v.verify([]);
    stft.run([3, 4], v);
    v.verify([
      [1, 2, 0, 0],
      [3, 4, 0, 0],
    ]);
  });

  test('STFT flush run stream', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.flush(v);
    v.verify([]);
    stft.run([3, 4], v);
    v.verify([
      [3, 4, 0, 0],
    ]);
    stft
      ..stream([1], v)
      ..stream([2], v);
    v.verify([]);
    stft.flush(v);
    v.verify([
      [1, 2, 0, 0],
    ]);
  });

  test('STFT run stream flush', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.run([3, 4], v);
    v.verify([
      [3, 4, 0, 0],
    ]);
    stft
      ..stream([1], v)
      ..stream([2], v);
    v.verify([]);
    stft.flush(v);
    v.verify([
      [1, 2, 0, 0],
    ]);
  });

  test('STFT run flush stream', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.run([3, 4], v);
    v.verify([
      [3, 4, 0, 0],
    ]);
    stft.flush(v);
    v.verify([]);
    stft
      ..stream([1], v)
      ..stream([2], v);
    v.verify([]);
    stft.flush(v);
    v.verify([
      [1, 2, 0, 0],
    ]);
  });

  test('STFT run giant chunk stride is n', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.run([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], v, 999);
    v.verify([
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 0],
    ]);
  });

  test('STFT run default chunk stride is n', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.run([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], v);
    v.verify([
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 16],
      [17, 0, 0, 0],
    ]);
  });

  test('STFT stream default chunk stride is n', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], v);
    v.verify([
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 16],
    ]);
    stft.flush(v);
    v.verify([
      [17, 0, 0, 0],
    ]);
  });

  test('STFT stream default chunk stride is n, no flush needed', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], v);
    v.verify([
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 16],
    ]);
    stft.flush(v);
    v.verify([]);
  });

  test('STFT run small overlap', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.run([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], v, 3);
    v.verify([
      [1, 2, 3, 4],
      [4, 5, 6, 7],
      [7, 8, 9, 10],
      [10, 11, 12, 13],
      [13, 14, 15, 16],
      [16, 17, 0, 0],
    ]);
  });

  test('STFT stream small overlap', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], v, 3);
    v.verify([
      [1, 2, 3, 4],
      [4, 5, 6, 7],
      [7, 8, 9, 10],
      [10, 11, 12, 13],
    ]);
    stft.flush(v);
    v.verify([
      [13, 14, 0, 0],
    ]);
  });

  test('STFT stream small overlap, no flush needed', () {
    final stft = STFT(4);
    final v = Verifier();
    stft.stream([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], v, 3);
    v.verify([
      [1, 2, 3, 4],
      [4, 5, 6, 7],
      [7, 8, 9, 10],
      [10, 11, 12, 13],
    ]);
    stft.flush(v);
    v.verify([]);
  });

  test('STFT run large overlap', () {
    final stft = STFT(6);
    final v = Verifier();
    stft.run([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], v, 2);
    v.verify([
      [1, 2, 3, 4, 5, 6],
      [3, 4, 5, 6, 7, 8],
      [5, 6, 7, 8, 9, 10],
      [7, 8, 9, 10, 11, 12],
      [9, 10, 11, 12, 13, 14],
      [11, 12, 13, 14, 15, 0],
    ]);
  });

  test('STFT stream large overlap', () {
    final stft = STFT(6);
    final v = Verifier();
    stft.stream([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], v, 2);
    v.verify([
      [1, 2, 3, 4, 5, 6],
      [3, 4, 5, 6, 7, 8],
      [5, 6, 7, 8, 9, 10],
      [7, 8, 9, 10, 11, 12],
      [9, 10, 11, 12, 13, 14],
    ]);
    stft.flush(v);
    v.verify([
      [11, 12, 13, 14, 15, 0],
    ]);
  });

  test('STFT stream many tiny inputs', () {
    final stft = STFT(6);
    final v = Verifier();
    for (int i = 1; i <= 20; ++i) {
      stft.stream([i.toDouble()], v);
    }
    v.verify([
      [1, 2, 3, 4, 5, 6],
      [7, 8, 9, 10, 11, 12],
      [13, 14, 15, 16, 17, 18],
    ]);
    stft.flush(v);
    v.verify([
      [19, 20, 0, 0, 0, 0],
    ]);
  });

  test('STFT stream many tiny inputs, small overlap', () {
    final stft = STFT(6);
    final v = Verifier();
    for (int i = 1; i <= 20; ++i) {
      stft.stream([i.toDouble()], v, 4);
    }
    v.verify([
      [1, 2, 3, 4, 5, 6],
      [5, 6, 7, 8, 9, 10],
      [9, 10, 11, 12, 13, 14],
      [13, 14, 15, 16, 17, 18],
    ]);
    stft.flush(v);
    v.verify([
      [17, 18, 19, 20, 0, 0],
    ]);
  });

  test('STFT stream many tiny inputs, large overlap', () {
    final stft = STFT(6);
    final v = Verifier();
    for (int i = 1; i <= 19; ++i) {
      stft.stream([i.toDouble()], v, 2);
    }
    v.verify([
      [1, 2, 3, 4, 5, 6],
      [3, 4, 5, 6, 7, 8],
      [5, 6, 7, 8, 9, 10],
      [7, 8, 9, 10, 11, 12],
      [9, 10, 11, 12, 13, 14],
      [11, 12, 13, 14, 15, 16],
      [13, 14, 15, 16, 17, 18],
    ]);
    stft.flush(v);
    v.verify([
      [15, 16, 17, 18, 19, 0],
    ]);
  });

  test('STFT variable chunk stride', () {
    final stft = STFT(6);
    final v = Verifier();
    stft.stream([1, 2, 3], v, 5);
    v.verify([]);
    stft.stream([4, 5], v, 4);
    v.verify([]);
    stft.stream([6], v, 1);
    v.verify([
      [1, 2, 3, 4, 5, 6],
    ]);
    stft.stream([7, 8, 9, 10, 11], v, 2);
    v.verify([
      [3, 4, 5, 6, 7, 8],
      [5, 6, 7, 8, 9, 10],
    ]);
    stft.stream([12, 13], v, 3);
    v.verify([
      [7, 8, 9, 10, 11, 12],
    ]);
    stft.stream([14, 15], v, 4);
    v.verify([
      [10, 11, 12, 13, 14, 15],
    ]);
    stft.stream([16, 17, 18], v, 1);
    v.verify([
      [11, 12, 13, 14, 15, 16],
      [12, 13, 14, 15, 16, 17],
      [13, 14, 15, 16, 17, 18],
    ]);
    stft.flush(v);
    v.verify([]);
  });
}
