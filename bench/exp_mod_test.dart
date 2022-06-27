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
import 'package:fftea/util.dart' as util;

BigInt expModBigInt(BigInt g, BigInt k, BigInt n) {
  BigInt y = BigInt.from(1);
  while (k > BigInt.from(0)) {
    if (k.isOdd) {
      y = (y * g) % n;
    }
    k >>= 1;
    g = (g * g) % n;
  }
  return y;
}

int findFirstFail(bool Function(int) test) {
  // test is assumed to be a function that returns true for small numbers, and
  // false for large numbers. However, unlike regular binary search, test is
  // allowed to have a range in the middle where it returns a mix of true and
  // false, possibly non-deterministically.
  if (!test(0)) return 0;
  int probablyPassing = 0;
  int definitelyFailing = 1;
  bool anyFail = false;

  // Double range any failure is found.
  while (true) {
    if (!test(definitelyFailing)) {
      anyFail = true;
      break;
    }
    if (definitelyFailing == 1 << 62) {
      break;
    }
    definitelyFailing *= 2;
  }

  while (true) {
    // Halve range until probable first failure is found.
    while (true) {
      final mid = probablyPassing + (definitelyFailing - probablyPassing) >> 1;
      if (mid == probablyPassing) {
        break;
      }
      if (test(mid)) {
        probablyPassing = mid;
      } else {
        anyFail = true;
        definitelyFailing = mid;
      }
    }

    // Confirm by checking some smaller values.
    int search = 1;
    final oldDefinitelyFailing = definitelyFailing;
    while (true) {
      if (search == 1 << 62 || search > oldDefinitelyFailing) {
        break;
      }
      int check = oldDefinitelyFailing - search;
      if (!test(check)) {
        anyFail = true;
        definitelyFailing = check;
      }
      search *= 2;
    }
    if (oldDefinitelyFailing == definitelyFailing) {
      break;
    }

    // If we found something we missed, repeat the binary search.
    probablyPassing = definitelyFailing >> 1;
  }
  return anyFail ? definitelyFailing : -1;
}

void main() {
  final r = Random();
  print(findFirstFail((n) {
    for (int i = 0; i < 100; ++i) {
      int g = (n.toDouble() * r.nextDouble()).toInt();
      int k = (n.toDouble() * r.nextDouble()).toInt();
      int y1 = util.expMod(g, k, n);
      int y2 = expModBigInt(BigInt.from(g), BigInt.from(k), BigInt.from(n)).toInt();
      if (y1 != y2) {
        print('$n, $g, $k, $n, $y1, $y2');
        return false;
      }
    }
    return true;
  }));

  //print(util.expMod(431665002, 2349572900, 3037036544));
  //print('\n');
  //print(expModBigInt(BigInt.from(431665002), BigInt.from(2349572900), BigInt.from(3037036544)));

}
