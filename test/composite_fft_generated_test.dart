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
  test('FFT CompositeFFT 1', () async {
    await testFft('test/data/fft_1.mat', CompositeFFT(1));
  });

  test('FFT CompositeFFT 2', () async {
    await testFft('test/data/fft_2.mat', CompositeFFT(2));
  });

  test('FFT CompositeFFT 3', () async {
    await testFft('test/data/fft_3.mat', CompositeFFT(3));
  });

  test('FFT CompositeFFT 4', () async {
    await testFft('test/data/fft_4.mat', CompositeFFT(4));
  });

  test('FFT CompositeFFT 5', () async {
    await testFft('test/data/fft_5.mat', CompositeFFT(5));
  });

  test('FFT CompositeFFT 6', () async {
    await testFft('test/data/fft_6.mat', CompositeFFT(6));
  });

  test('FFT CompositeFFT 7', () async {
    await testFft('test/data/fft_7.mat', CompositeFFT(7));
  });

  test('FFT CompositeFFT 8', () async {
    await testFft('test/data/fft_8.mat', CompositeFFT(8));
  });

  test('FFT CompositeFFT 9', () async {
    await testFft('test/data/fft_9.mat', CompositeFFT(9));
  });

  test('FFT CompositeFFT 10', () async {
    await testFft('test/data/fft_10.mat', CompositeFFT(10));
  });

  test('FFT CompositeFFT 11', () async {
    await testFft('test/data/fft_11.mat', CompositeFFT(11));
  });

  test('FFT CompositeFFT 12', () async {
    await testFft('test/data/fft_12.mat', CompositeFFT(12));
  });

  test('FFT CompositeFFT 461', () async {
    await testFft('test/data/fft_461.mat', CompositeFFT(461));
  });

  test('FFT CompositeFFT 752', () async {
    await testFft('test/data/fft_752.mat', CompositeFFT(752));
  });

  test('FFT CompositeFFT 1980', () async {
    await testFft('test/data/fft_1980.mat', CompositeFFT(1980));
  });

  test('FFT CompositeFFT 2310', () async {
    await testFft('test/data/fft_2310.mat', CompositeFFT(2310));
  });

  test('FFT CompositeFFT 2442', () async {
    await testFft('test/data/fft_2442.mat', CompositeFFT(2442));
  });

  test('FFT CompositeFFT 3410', () async {
    await testFft('test/data/fft_3410.mat', CompositeFFT(3410));
  });

  test('FFT CompositeFFT 4913', () async {
    await testFft('test/data/fft_4913.mat', CompositeFFT(4913));
  });

  test('FFT CompositeFFT 7429', () async {
    await testFft('test/data/fft_7429.mat', CompositeFFT(7429));
  });

  test('Real FFT CompositeFFT 1', () async {
    await testRealFft('test/data/real_fft_1.mat', CompositeFFT(1));
  });

  test('Real FFT CompositeFFT 2', () async {
    await testRealFft('test/data/real_fft_2.mat', CompositeFFT(2));
  });

  test('Real FFT CompositeFFT 3', () async {
    await testRealFft('test/data/real_fft_3.mat', CompositeFFT(3));
  });

  test('Real FFT CompositeFFT 4', () async {
    await testRealFft('test/data/real_fft_4.mat', CompositeFFT(4));
  });

  test('Real FFT CompositeFFT 5', () async {
    await testRealFft('test/data/real_fft_5.mat', CompositeFFT(5));
  });

  test('Real FFT CompositeFFT 6', () async {
    await testRealFft('test/data/real_fft_6.mat', CompositeFFT(6));
  });

  test('Real FFT CompositeFFT 7', () async {
    await testRealFft('test/data/real_fft_7.mat', CompositeFFT(7));
  });

  test('Real FFT CompositeFFT 8', () async {
    await testRealFft('test/data/real_fft_8.mat', CompositeFFT(8));
  });

  test('Real FFT CompositeFFT 9', () async {
    await testRealFft('test/data/real_fft_9.mat', CompositeFFT(9));
  });

  test('Real FFT CompositeFFT 10', () async {
    await testRealFft('test/data/real_fft_10.mat', CompositeFFT(10));
  });

  test('Real FFT CompositeFFT 11', () async {
    await testRealFft('test/data/real_fft_11.mat', CompositeFFT(11));
  });

  test('Real FFT CompositeFFT 12', () async {
    await testRealFft('test/data/real_fft_12.mat', CompositeFFT(12));
  });

  test('Real FFT CompositeFFT 461', () async {
    await testRealFft('test/data/real_fft_461.mat', CompositeFFT(461));
  });

  test('Real FFT CompositeFFT 752', () async {
    await testRealFft('test/data/real_fft_752.mat', CompositeFFT(752));
  });

  test('Real FFT CompositeFFT 1980', () async {
    await testRealFft('test/data/real_fft_1980.mat', CompositeFFT(1980));
  });

  test('Real FFT CompositeFFT 2310', () async {
    await testRealFft('test/data/real_fft_2310.mat', CompositeFFT(2310));
  });

  test('Real FFT CompositeFFT 2442', () async {
    await testRealFft('test/data/real_fft_2442.mat', CompositeFFT(2442));
  });

  test('Real FFT CompositeFFT 3410', () async {
    await testRealFft('test/data/real_fft_3410.mat', CompositeFFT(3410));
  });

  test('Real FFT CompositeFFT 4913', () async {
    await testRealFft('test/data/real_fft_4913.mat', CompositeFFT(4913));
  });

  test('Real FFT CompositeFFT 7429', () async {
    await testRealFft('test/data/real_fft_7429.mat', CompositeFFT(7429));
  });

}

