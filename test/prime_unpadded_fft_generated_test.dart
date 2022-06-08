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

// GENERATED FILE. DO NOT EDIT.

// Test cases generated with numpy as a reference implementation, using:
//   python3 test/generate_test.py && dart format .

// ignore_for_file: unused_import
// ignore_for_file: require_trailing_commas

import 'package:fftea/fftea.dart';
import 'package:fftea/impl.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  test('PrimeFFT 3', () async {
    await testFft('test/data/fft_3.mat', PrimeFFT(3, false));
  });

  test('PrimeFFT 5', () async {
    await testFft('test/data/fft_5.mat', PrimeFFT(5, false));
  });

  test('PrimeFFT 7', () async {
    await testFft('test/data/fft_7.mat', PrimeFFT(7, false));
  });

  test('PrimeFFT 11', () async {
    await testFft('test/data/fft_11.mat', PrimeFFT(11, false));
  });

  test('PrimeFFT 13', () async {
    await testFft('test/data/fft_13.mat', PrimeFFT(13, false));
  });

  test('PrimeFFT 17', () async {
    await testFft('test/data/fft_17.mat', PrimeFFT(17, false));
  });

  test('PrimeFFT 19', () async {
    await testFft('test/data/fft_19.mat', PrimeFFT(19, false));
  });

  test('PrimeFFT 23', () async {
    await testFft('test/data/fft_23.mat', PrimeFFT(23, false));
  });

  test('PrimeFFT 29', () async {
    await testFft('test/data/fft_29.mat', PrimeFFT(29, false));
  });

  test('PrimeFFT 31', () async {
    await testFft('test/data/fft_31.mat', PrimeFFT(31, false));
  });

  test('PrimeFFT 1009', () async {
    await testFft('test/data/fft_1009.mat', PrimeFFT(1009, false));
  });

  test('PrimeFFT 7919', () async {
    await testFft('test/data/fft_7919.mat', PrimeFFT(7919, false));
  });

  test('PrimeFFT 28657', () async {
    await testFft('test/data/fft_28657.mat', PrimeFFT(28657, false));
  });

  test('Real PrimeFFT 3', () async {
    await testRealFft('test/data/real_fft_3.mat', PrimeFFT(3, false));
  });

  test('Real PrimeFFT 5', () async {
    await testRealFft('test/data/real_fft_5.mat', PrimeFFT(5, false));
  });

  test('Real PrimeFFT 7', () async {
    await testRealFft('test/data/real_fft_7.mat', PrimeFFT(7, false));
  });

  test('Real PrimeFFT 11', () async {
    await testRealFft('test/data/real_fft_11.mat', PrimeFFT(11, false));
  });

  test('Real PrimeFFT 13', () async {
    await testRealFft('test/data/real_fft_13.mat', PrimeFFT(13, false));
  });

  test('Real PrimeFFT 17', () async {
    await testRealFft('test/data/real_fft_17.mat', PrimeFFT(17, false));
  });

  test('Real PrimeFFT 19', () async {
    await testRealFft('test/data/real_fft_19.mat', PrimeFFT(19, false));
  });

  test('Real PrimeFFT 23', () async {
    await testRealFft('test/data/real_fft_23.mat', PrimeFFT(23, false));
  });

  test('Real PrimeFFT 29', () async {
    await testRealFft('test/data/real_fft_29.mat', PrimeFFT(29, false));
  });

  test('Real PrimeFFT 31', () async {
    await testRealFft('test/data/real_fft_31.mat', PrimeFFT(31, false));
  });

  test('Real PrimeFFT 1009', () async {
    await testRealFft('test/data/real_fft_1009.mat', PrimeFFT(1009, false));
  });

  test('Real PrimeFFT 7919', () async {
    await testRealFft('test/data/real_fft_7919.mat', PrimeFFT(7919, false));
  });

  test('Real PrimeFFT 28657', () async {
    await testRealFft('test/data/real_fft_28657.mat', PrimeFFT(28657, false));
  });
}
