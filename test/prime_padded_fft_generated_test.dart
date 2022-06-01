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
//   python3 test/generate_test.py

import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:test/test.dart';
import 'util.dart';

void main() {
  test('PrimePaddedFFT 3', () async {
    await testFft('test/data/fft_3.mat', PrimePaddedFFT(3));
  });

  test('PrimePaddedFFT 5', () async {
    await testFft('test/data/fft_5.mat', PrimePaddedFFT(5));
  });

  test('PrimePaddedFFT 7', () async {
    await testFft('test/data/fft_7.mat', PrimePaddedFFT(7));
  });

  test('PrimePaddedFFT 11', () async {
    await testFft('test/data/fft_11.mat', PrimePaddedFFT(11));
  });

  test('PrimePaddedFFT 13', () async {
    await testFft('test/data/fft_13.mat', PrimePaddedFFT(13));
  });

  test('PrimePaddedFFT 17', () async {
    await testFft('test/data/fft_17.mat', PrimePaddedFFT(17));
  });

  test('PrimePaddedFFT 19', () async {
    await testFft('test/data/fft_19.mat', PrimePaddedFFT(19));
  });

  test('PrimePaddedFFT 23', () async {
    await testFft('test/data/fft_23.mat', PrimePaddedFFT(23));
  });

  test('PrimePaddedFFT 29', () async {
    await testFft('test/data/fft_29.mat', PrimePaddedFFT(29));
  });

  test('PrimePaddedFFT 31', () async {
    await testFft('test/data/fft_31.mat', PrimePaddedFFT(31));
  });

  test('PrimePaddedFFT 1009', () async {
    await testFft('test/data/fft_1009.mat', PrimePaddedFFT(1009));
  });

  test('PrimePaddedFFT 7919', () async {
    await testFft('test/data/fft_7919.mat', PrimePaddedFFT(7919));
  });

  test('PrimePaddedFFT 28657', () async {
    await testFft('test/data/fft_28657.mat', PrimePaddedFFT(28657));
  });

  test('Real PrimePaddedFFT 3', () async {
    await testRealFft('test/data/real_fft_3.mat', PrimePaddedFFT(3));
  });

  test('Real PrimePaddedFFT 5', () async {
    await testRealFft('test/data/real_fft_5.mat', PrimePaddedFFT(5));
  });

  test('Real PrimePaddedFFT 7', () async {
    await testRealFft('test/data/real_fft_7.mat', PrimePaddedFFT(7));
  });

  test('Real PrimePaddedFFT 11', () async {
    await testRealFft('test/data/real_fft_11.mat', PrimePaddedFFT(11));
  });

  test('Real PrimePaddedFFT 13', () async {
    await testRealFft('test/data/real_fft_13.mat', PrimePaddedFFT(13));
  });

  test('Real PrimePaddedFFT 17', () async {
    await testRealFft('test/data/real_fft_17.mat', PrimePaddedFFT(17));
  });

  test('Real PrimePaddedFFT 19', () async {
    await testRealFft('test/data/real_fft_19.mat', PrimePaddedFFT(19));
  });

  test('Real PrimePaddedFFT 23', () async {
    await testRealFft('test/data/real_fft_23.mat', PrimePaddedFFT(23));
  });

  test('Real PrimePaddedFFT 29', () async {
    await testRealFft('test/data/real_fft_29.mat', PrimePaddedFFT(29));
  });

  test('Real PrimePaddedFFT 31', () async {
    await testRealFft('test/data/real_fft_31.mat', PrimePaddedFFT(31));
  });

  test('Real PrimePaddedFFT 1009', () async {
    await testRealFft('test/data/real_fft_1009.mat', PrimePaddedFFT(1009));
  });

  test('Real PrimePaddedFFT 7919', () async {
    await testRealFft('test/data/real_fft_7919.mat', PrimePaddedFFT(7919));
  });

  test('Real PrimePaddedFFT 28657', () async {
    await testRealFft('test/data/real_fft_28657.mat', PrimePaddedFFT(28657));
  });

}

