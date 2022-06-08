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

// Benchmarks PrimeFFT at different sizes, with and without padding, to tune
// primePaddingHeuristic.

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

  int get micros => _watch.elapsedMicroseconds;

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

  final primePaddedFFT =
      util.isPrime(size) && size > 2 ? fftea_impl.PrimeFFT(size, true) : null;
  final primeUnpaddedFFT =
      util.isPrime(size) && size > 2 ? fftea_impl.PrimeFFT(size, false) : null;

  int padWins = 0;
  int pad = 0;
  int unpad = 0;
  for (var i = 0; i < kTestRuns; ++i) {
    final primePaddedTimer = TestTimer();
    if (primePaddedFFT != null) {
      final input = inp.sublist(0);
      primePaddedTimer.start();
      primePaddedFFT.inPlaceFft(input);
      primePaddedTimer.stop();
    }
    final primeUnpaddedTimer = TestTimer();
    if (primeUnpaddedFFT != null) {
      final input = inp.sublist(0);
      primeUnpaddedTimer.start();
      primeUnpaddedFFT.inPlaceFft(input);
      primeUnpaddedTimer.stop();
    }
    unpad += primeUnpaddedTimer.micros;
    pad += primePaddedTimer.micros;
    if (primeUnpaddedTimer.micros > primePaddedTimer.micros) {
      ++padWins;
    }
  }
  final lpf = util.largestPrimeFactor(size - 1);
  final padWinRate = padWins / kTestRuns;
  final guessThatPaddingIsFaster = util.primePaddingHeuristic(size);
  final paddingIsFaster = padWinRate > 0.9;
  final paddingIsSlower = padWinRate < 0.1;
  if (guessThatPaddingIsFaster) {
    if (paddingIsSlower) {
      print('FALSE_POSITIVE, $size, $lpf, $pad, $unpad, $padWinRate');
    }
  } else if (paddingIsFaster) {
    print('FALSE_NEGATIVE, $size, $lpf, $pad, $unpad, $padWinRate');
  }
}

List<int> generateBenchSizes() {
  final a = <int>[];
  for (int i = 1; i < 1000; ++i) {
    a.add(util.primes.getPrime(i));
  }
  return a;
}

void main() {
  print('Result, Size, LPF, PrimePaddedFFT, PrimeUnpaddedFFT, Pad Win Rate');
  for (final i in generateBenchSizes()) {
    implBench(i);
  }
}
