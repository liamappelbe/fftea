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

import 'package:fftea/fftea.dart';
import 'package:test/test.dart';

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

  test('FFT.frequency', () {
    final fft = FFT(16);
    expect(fft.frequency(0, 32), 0);
    expect(fft.frequency(1, 32), 2);
    expect(fft.frequency(2, 32), 4);
    expect(fft.frequency(8, 32), 16);
    expect(fft.frequency(2, 4), 0.5);
  });
}
