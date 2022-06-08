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
  test('NaiveFFT 1', () async {
    await testFft('test/data/fft_1.mat', NaiveFFT(1));
  });

  test('NaiveFFT 2', () async {
    await testFft('test/data/fft_2.mat', NaiveFFT(2));
  });

  test('NaiveFFT 3', () async {
    await testFft('test/data/fft_3.mat', NaiveFFT(3));
  });

  test('NaiveFFT 4', () async {
    await testFft('test/data/fft_4.mat', NaiveFFT(4));
  });

  test('NaiveFFT 5', () async {
    await testFft('test/data/fft_5.mat', NaiveFFT(5));
  });

  test('NaiveFFT 6', () async {
    await testFft('test/data/fft_6.mat', NaiveFFT(6));
  });

  test('NaiveFFT 7', () async {
    await testFft('test/data/fft_7.mat', NaiveFFT(7));
  });

  test('NaiveFFT 8', () async {
    await testFft('test/data/fft_8.mat', NaiveFFT(8));
  });

  test('NaiveFFT 9', () async {
    await testFft('test/data/fft_9.mat', NaiveFFT(9));
  });

  test('NaiveFFT 10', () async {
    await testFft('test/data/fft_10.mat', NaiveFFT(10));
  });

  test('NaiveFFT 11', () async {
    await testFft('test/data/fft_11.mat', NaiveFFT(11));
  });

  test('NaiveFFT 12', () async {
    await testFft('test/data/fft_12.mat', NaiveFFT(12));
  });

  test('NaiveFFT 13', () async {
    await testFft('test/data/fft_13.mat', NaiveFFT(13));
  });

  test('NaiveFFT 14', () async {
    await testFft('test/data/fft_14.mat', NaiveFFT(14));
  });

  test('NaiveFFT 15', () async {
    await testFft('test/data/fft_15.mat', NaiveFFT(15));
  });

  test('NaiveFFT 16', () async {
    await testFft('test/data/fft_16.mat', NaiveFFT(16));
  });

  test('Real NaiveFFT 1', () async {
    await testRealFft('test/data/real_fft_1.mat', NaiveFFT(1));
  });

  test('Real NaiveFFT 2', () async {
    await testRealFft('test/data/real_fft_2.mat', NaiveFFT(2));
  });

  test('Real NaiveFFT 3', () async {
    await testRealFft('test/data/real_fft_3.mat', NaiveFFT(3));
  });

  test('Real NaiveFFT 4', () async {
    await testRealFft('test/data/real_fft_4.mat', NaiveFFT(4));
  });

  test('Real NaiveFFT 5', () async {
    await testRealFft('test/data/real_fft_5.mat', NaiveFFT(5));
  });

  test('Real NaiveFFT 6', () async {
    await testRealFft('test/data/real_fft_6.mat', NaiveFFT(6));
  });

  test('Real NaiveFFT 7', () async {
    await testRealFft('test/data/real_fft_7.mat', NaiveFFT(7));
  });

  test('Real NaiveFFT 8', () async {
    await testRealFft('test/data/real_fft_8.mat', NaiveFFT(8));
  });

  test('Real NaiveFFT 9', () async {
    await testRealFft('test/data/real_fft_9.mat', NaiveFFT(9));
  });

  test('Real NaiveFFT 10', () async {
    await testRealFft('test/data/real_fft_10.mat', NaiveFFT(10));
  });

  test('Real NaiveFFT 11', () async {
    await testRealFft('test/data/real_fft_11.mat', NaiveFFT(11));
  });

  test('Real NaiveFFT 12', () async {
    await testRealFft('test/data/real_fft_12.mat', NaiveFFT(12));
  });

  test('Real NaiveFFT 13', () async {
    await testRealFft('test/data/real_fft_13.mat', NaiveFFT(13));
  });

  test('Real NaiveFFT 14', () async {
    await testRealFft('test/data/real_fft_14.mat', NaiveFFT(14));
  });

  test('Real NaiveFFT 15', () async {
    await testRealFft('test/data/real_fft_15.mat', NaiveFFT(15));
  });

  test('Real NaiveFFT 16', () async {
    await testRealFft('test/data/real_fft_16.mat', NaiveFFT(16));
  });
}
