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
  test('isPrimeMrBase2', () {
    final pseudoPrimes = {
      2047, 3277, 4033, 4681, 8321, 15841, 29341, 42799, 49141, 52633,  //
      65281, 74665, 80581, 85489, 88357, 90751,  //
    };
    for (int n = 3; n < 10000; n += 2) {
      expect(isPrimeMrBase2(n), isPrime(n) || pseudoPrimes.contains(n));
    }
  });
}
