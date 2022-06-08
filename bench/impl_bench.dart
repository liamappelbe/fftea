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

// Benchmarks fftea's various implementations of FFT.

import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart' as fftea;
import 'package:fftea/impl.dart' as fftea_impl;
import 'package:fftea/util.dart' as util;

class TestTimer {
  final _watch = Stopwatch();
  int _runs = 0;

  void start() {
    ++_runs;
    _watch.start();
  }

  void stop() {
    _watch.stop();
  }

  @override
  String toString() {
    if (_runs == 0) return '';
    return '${_watch.elapsedMicroseconds / _runs}';
  }
}

const kTestRuns = 30;

void implBench(int size) {
  final inp = Float64x2List(size);
  final rand = Random();
  for (var i = 0; i < size; ++i) {
    inp[i] = Float64x2(2 * rand.nextDouble() - 1, 2 * rand.nextDouble() - 1);
  }

  final naiveFFT = size <= 300 ? fftea_impl.NaiveFFT(size) : null;
  final primePaddedFFT =
      util.isPrime(size) && size > 2 ? fftea_impl.PrimeFFT(size, true) : null;
  final primeUnpaddedFFT =
      util.isPrime(size) && size > 2 ? fftea_impl.PrimeFFT(size, false) : null;
  final compositeFFT = fftea_impl.CompositeFFT(size);
  final radix2FFT = util.isPowerOf2(size) ? fftea_impl.Radix2FFT(size) : null;
  final fft = fftea.FFT(size);
  final naiveTimer = TestTimer();
  final primePaddedTimer = TestTimer();
  final primeUnpaddedTimer = TestTimer();
  final compositeTimer = TestTimer();
  final radix2Timer = TestTimer();
  final fftTimer = TestTimer();

  for (var i = 0; i < kTestRuns; ++i) {
    if (naiveFFT != null) {
      final input = inp.sublist(0);
      naiveTimer.start();
      naiveFFT.inPlaceFft(input);
      naiveTimer.stop();
    }
    if (primePaddedFFT != null) {
      final input = inp.sublist(0);
      primePaddedTimer.start();
      primePaddedFFT.inPlaceFft(input);
      primePaddedTimer.stop();
    }
    if (primeUnpaddedFFT != null) {
      final input = inp.sublist(0);
      primeUnpaddedTimer.start();
      primeUnpaddedFFT.inPlaceFft(input);
      primeUnpaddedTimer.stop();
    }
    {
      final input = inp.sublist(0);
      compositeTimer.start();
      compositeFFT.inPlaceFft(input);
      compositeTimer.stop();
    }
    if (radix2FFT != null) {
      final input = inp.sublist(0);
      radix2Timer.start();
      radix2FFT.inPlaceFft(input);
      radix2Timer.stop();
    }
    {
      final input = inp.sublist(0);
      fftTimer.start();
      fft.inPlaceFft(input);
      fftTimer.stop();
    }
  }

  print(
    '$size, $fftTimer, $naiveTimer, $primePaddedTimer, $primeUnpaddedTimer, '
    '$compositeTimer, $radix2Timer',
  );
}

List<int> generateBenchSizes() {
  // All sizes from the unit tests.
  final sizes = {1980, 2310, 2442, 3410, 4913, 7429, 7919, 28657};

  // All sizes below 1024.
  for (int i = 1; i < 1024; ++i) {
    sizes.add(i);
  }

  // All powers of 2 up to 32k.
  for (int i = 1024; i <= 32768; i *= 2) {
    sizes.add(i);
  }

  // 1000 logarithmically distributed numbers between 1024 and 32768.
  for (double i = 1024; i < 32768;) {
    i *= 1.00347174851;
    sizes.add(i.toInt());
  }
  return sizes.toList()..sort();
}

void main() {
  print(
    'Size, FFT, NaiveFFT, PrimePaddedFFT, PrimeUnpaddedFFT, CompositeFFT, '
    'Radix2FFT',
  );
  for (final i in generateBenchSizes()) {
    implBench(i);
  }
}
