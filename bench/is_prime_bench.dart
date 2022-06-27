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

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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

bool naiveIsPrime(int n) {
  if (n <= 1) return false;
  if (n == 2) return true;
  if (n.isEven) return false;
  for (int i = 3; i * i <= n; i += 2) {
    if (n % i == 0) return false;
  }
  return true;
}

void implBench(int n) {
  final naiveTimer = TestTimer();
  final uncachedTimer = TestTimer();
  final cacheTimer = TestTimer();
  final mrTimer = TestTimer();
  final mr2Timer = TestTimer();
  final bpswTimer = TestTimer();
  bool result = false;
  for (var i = 0; i < kTestRuns; ++i) {
    mrTimer.start();
    result = util.isPrimeMr(n);
    mrTimer.stop();

    mr2Timer.start();
    final mr2Result = util.isPrimeMr2(n);
    mr2Timer.stop();

    if (mr2Result != result) {
      print('MR2 <-> MR mismatch at ${n}: ${mr2Result} != ${result}');
      exit(1);
    }

    if (n < 1e9) {
      naiveTimer.start();
      final naiveResult = naiveIsPrime(n);
      naiveTimer.stop();

      if (naiveResult != result) {
        print('Naive <-> MR mismatch at ${n}: ${naiveResult} != ${result}');
        exit(1);
      }

      uncachedTimer.start();
      util.Primes().isPrime(n);
      uncachedTimer.stop();
    }

    if (n < 1e12) {
      cacheTimer.start();
      final cachedResult = util.isPrime(n);
      cacheTimer.stop();

      if (cachedResult != result) {
        print('Cached <-> MR mismatch at ${n}: ${cachedResult} != ${result}');
        exit(1);
      }
    }

    bpswTimer.start();
    //final bpswResult = util.isPrimeBpsw(n);
    bpswTimer.stop();

    //if (bpswResult != result) {
    //  print('BPSW <-> MR mismatch at ${n}: ${bpswResult} != ${result}');
    //  exit(1);
    //}
  }
  print('$n, $result, $naiveTimer, $uncachedTimer, $cacheTimer, $mrTimer, $mr2Timer');  // , $bpswTimer
}

List<int> generateBenchSizes() {
  final a = <int>[];
  // All odd numbers up to 1000.
  for (int i = 3; i < 1000; i += 2) {
    a.add(i);
  }
  // 30000 logarithmically distributed odd numbers between 1e3 and 1e18.
  for (double x = 1000; x < 1e18;) {
    x *= 1.00115195554;  // (1e18 / 1e3) ^ (1 / 30000)
    int i = (x / 2).toInt() * 2 + 1;
    if (i != a.last) {
      a.add(i);
    }
  }
  return a.where(util.isPrimeMr).toList();
}

void main() {
  print('n, is_prime, t_naive, t_uncached, t_cache, t_mr, t_mr2, t_bpsw');
  for (final i in generateBenchSizes()) {
    implBench(i);
  }
}
