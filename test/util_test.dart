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

import 'dart:math' as math;

import 'package:fftea/util.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  test('isPowerOf2', () {
    expect(isPowerOf2(0), isFalse);
    expect(isPowerOf2(1), isTrue);
    expect(isPowerOf2(2), isTrue);
    expect(isPowerOf2(3), isFalse);
    expect(isPowerOf2(4), isTrue);
    expect(isPowerOf2(5), isFalse);
    expect(isPowerOf2(6), isFalse);
    expect(isPowerOf2(7), isFalse);
    expect(isPowerOf2(8), isTrue);
    expect(isPowerOf2(47), isFalse);
    expect(isPowerOf2(16384), isTrue);
    expect(isPowerOf2(-123), isFalse);
    expect(isPowerOf2(-4), isFalse);
  });

  test('Primes', () {
    final exp = [
      2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, //
      61, 67, 71, 73, 79, 83, 89, 97, 101, //
    ];
    for (int i = 0; i < exp.length; ++i) {
      expect(primes.getPrime(i), exp[i]);
    }
  });

  test('Primes stores O(sqrt(n))', () {
    expect(primes.internalIsPrime(2097593), isTrue);
    expect(primes.numPrimes, 230);
    expect(primes.getPrime(229), 1451);
  });

  test('isPrime', () {
    final p = {
      2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, //
      61, 67, 71, 73, 79, 83, 89, 97, 101, //
    };
    for (int i = 0; i <= 102; ++i) {
      expect(isPrime(i), p.contains(i));
    }
  });

  test('Prime decomposition', () {
    expect(primeDecomp(1), []);
    expect(primeDecomp(2), [2]);
    expect(primeDecomp(3), [3]);
    expect(primeDecomp(4), [2, 2]);
    expect(primeDecomp(5), [5]);
    expect(primeDecomp(6), [2, 3]);
    expect(primeDecomp(7), [7]);
    expect(primeDecomp(8), [2, 2, 2]);
    expect(primeDecomp(9), [3, 3]);
    expect(primeDecomp(10), [2, 5]);
    expect(primeDecomp(453974598), [2, 3, 3, 3, 7, 11, 23, 47, 101]);
  });

  test('More prime decomposition', () {
    for (int i = 1; i < 10000; ++i) {
      final decomp = primeDecomp(i);
      int j = 1;
      for (final x in decomp) {
        expect(isPrime(x), isTrue);
        j *= x;
      }
      expect(j, i);
    }
  });

  test('Merge twos into fours', () {
    expect(mergeTwosIntoFours([3, 5, 7]), [3, 5, 7]);
    expect(mergeTwosIntoFours([2, 3, 5, 7]), [2, 3, 5, 7]);
    expect(mergeTwosIntoFours([2, 2, 3, 5, 7]), [4, 3, 5, 7]);
    expect(mergeTwosIntoFours([2, 2, 2, 3, 5, 7]), [2, 4, 3, 5, 7]);
    expect(mergeTwosIntoFours([2, 2, 2, 2, 3, 5, 7]), [4, 4, 3, 5, 7]);
    expect(mergeTwosIntoFours([2, 2, 2, 2, 2, 3, 5, 7]), [2, 4, 4, 3, 5, 7]);
    expect(mergeTwosIntoFours([2, 2, 2, 2, 2, 2, 3, 5, 7]), [4, 4, 4, 3, 5, 7]);
  });

  test('Prime factors', () {
    expect(primeFactors(1), []);
    expect(primeFactors(2), [2]);
    expect(primeFactors(3), [3]);
    expect(primeFactors(4), [2]);
    expect(primeFactors(5), [5]);
    expect(primeFactors(6), [2, 3]);
    expect(primeFactors(7), [7]);
    expect(primeFactors(8), [2]);
    expect(primeFactors(9), [3]);
    expect(primeFactors(10), [2, 5]);
    expect(primeFactors(453974598), [2, 3, 7, 11, 23, 47, 101]);
  });

  test('Largest prime factor', () {
    expect(largestPrimeFactor(1), 1);
    expect(largestPrimeFactor(2), 2);
    expect(largestPrimeFactor(3), 3);
    expect(largestPrimeFactor(4), 2);
    expect(largestPrimeFactor(5), 5);
    expect(largestPrimeFactor(6), 3);
    expect(largestPrimeFactor(7), 7);
    expect(largestPrimeFactor(8), 2);
    expect(largestPrimeFactor(9), 3);
    expect(largestPrimeFactor(10), 5);
    expect(largestPrimeFactor(453974598), 101);
  });

  test('Prime padding heuristic', () {
    final unpadded = {
      2, 3, 5, 7, 11, 13, 17, 19, 37, 41, 73, 97, 109, 151, 163, 181, //
      193, 257, //
    };
    for (int i = 0;; ++i) {
      final p = primes.getPrime(i);
      if (p > 257) break;
      expect(primePaddingHeuristic(p), !unpadded.contains(p));
    }
  });

  test('highestBit', () {
    for (int i = 0; i < 48; ++i) {
      expect(highestBit(1 << i), i);
    }
  });

  test('nextPowerOf2', () {
    expect(nextPowerOf2(1), 1);
    expect(nextPowerOf2(2), 2);
    expect(nextPowerOf2(3), 4);
    expect(nextPowerOf2(4), 4);
    expect(nextPowerOf2(120), 128);
    expect(nextPowerOf2(1023), 1024);
    expect(nextPowerOf2(1024), 1024);
    expect(nextPowerOf2(1025), 2048);
  });

  test('Primitive root of prime', () {
    // Expected primitive roots of primes > 2: https://oeis.org/A001918
    final exp = [
      2, 2, 3, 2, 2, 3, 2, 5, 2, 3, 2, 6, 3, 5, 2, 2, 2, 2, 7, 5, 3, 2, //
      3, 5, 2, 5, 2, 6, 3, 3, 2, 3, 2, 2, 6, 5, 2, 5, 2, 2, 2, 19, 5, 2, //
      3, 2, 3, 2, 6, 3, 7, 7, 6, 3, 5, 2, 6, 5, 3, 3, 2, 5, 17, 10, 2, //
      3, 10, 2, 2, 3, 7, 6, 2, 2, 5, 2, 5, 3, 21, 2, 2, 7, 5, 15, 2, 3, //
      13, 2, 3, 2, 13, 3, 2, 7, 5, 2, 3, 2, 2, 2, 2, 2, 3, //
    ];
    for (int i = 0; i < exp.length; ++i) {
      expect(primitiveRootOfPrime(primes.getPrime(i + 1)), exp[i]);
    }
  });

  test('Modular exponentiation', () {
    final exp = [
      [37, 0, 456, 1],
      [18, 0, 222, 1],
      [71, 4, 283, 262],
      [74, 4, 48, 16],
      [100, 4, 583, 342],
      [77, 3, 227, 36],
      [69, 2, 519, 90],
      [30, 4, 603, 171],
      [3, 9, 691, 335],
      [46, 4, 289, 268],
      [99, 4, 105, 36],
      [70, 7, 903, 343],
      [16, 5, 944, 736],
      [21, 6, 607, 56],
      [58, 1, 756, 58],
      [71, 5, 647, 622],
      [43, 5, 817, 731],
      [12, 1, 883, 12],
      [4, 6, 105, 1],
      [62, 1, 367, 62],
      [98, 3, 92, 32],
    ];
    for (final gkny in exp) {
      expect(expMod(gkny[0], gkny[1], gkny[2]), gkny[3]);
    }
  });

  test('Multiplicative inverse', () {
    final n = 47;
    for (int i = 1; i < n; ++i) {
      final j = multiplicativeInverseOfPrime(i, n);
      expect((i * j) % n, 1);
    }
  });

  test('twiddleFactors', () {
    final z = math.sqrt1_2;
    expectClose2(
      twiddleFactors(8),
      makeArray2(
        [1, z, 0, -z, -1, -z, 0, z],
        [0, -z, -1, -z, 0, z, 1, z],
      ),
    );
  });
}
