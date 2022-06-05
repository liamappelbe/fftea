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
import 'package:fftea/impl.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  test('FFT 1', () async {
    await testFft('test/data/fft_1.mat', FFT(1));
  });

  test('FFT 2', () async {
    await testFft('test/data/fft_2.mat', FFT(2));
  });

  test('FFT 3', () async {
    await testFft('test/data/fft_3.mat', FFT(3));
  });

  test('FFT 4', () async {
    await testFft('test/data/fft_4.mat', FFT(4));
  });

  test('FFT 5', () async {
    await testFft('test/data/fft_5.mat', FFT(5));
  });

  test('FFT 6', () async {
    await testFft('test/data/fft_6.mat', FFT(6));
  });

  test('FFT 7', () async {
    await testFft('test/data/fft_7.mat', FFT(7));
  });

  test('FFT 8', () async {
    await testFft('test/data/fft_8.mat', FFT(8));
  });

  test('FFT 9', () async {
    await testFft('test/data/fft_9.mat', FFT(9));
  });

  test('FFT 10', () async {
    await testFft('test/data/fft_10.mat', FFT(10));
  });

  test('FFT 11', () async {
    await testFft('test/data/fft_11.mat', FFT(11));
  });

  test('FFT 12', () async {
    await testFft('test/data/fft_12.mat', FFT(12));
  });

  test('FFT 461', () async {
    await testFft('test/data/fft_461.mat', FFT(461));
  });

  test('FFT 752', () async {
    await testFft('test/data/fft_752.mat', FFT(752));
  });

  test('FFT 1980', () async {
    await testFft('test/data/fft_1980.mat', FFT(1980));
  });

  test('FFT 2310', () async {
    await testFft('test/data/fft_2310.mat', FFT(2310));
  });

  test('FFT 2442', () async {
    await testFft('test/data/fft_2442.mat', FFT(2442));
  });

  test('FFT 3410', () async {
    await testFft('test/data/fft_3410.mat', FFT(3410));
  });

  test('FFT 4913', () async {
    await testFft('test/data/fft_4913.mat', FFT(4913));
  });

  test('FFT 7429', () async {
    await testFft('test/data/fft_7429.mat', FFT(7429));
  });

  test('Real FFT 1', () async {
    await testRealFft('test/data/real_fft_1.mat', FFT(1));
  });

  test('Real FFT 2', () async {
    await testRealFft('test/data/real_fft_2.mat', FFT(2));
  });

  test('Real FFT 3', () async {
    await testRealFft('test/data/real_fft_3.mat', FFT(3));
  });

  test('Real FFT 4', () async {
    await testRealFft('test/data/real_fft_4.mat', FFT(4));
  });

  test('Real FFT 5', () async {
    await testRealFft('test/data/real_fft_5.mat', FFT(5));
  });

  test('Real FFT 6', () async {
    await testRealFft('test/data/real_fft_6.mat', FFT(6));
  });

  test('Real FFT 7', () async {
    await testRealFft('test/data/real_fft_7.mat', FFT(7));
  });

  test('Real FFT 8', () async {
    await testRealFft('test/data/real_fft_8.mat', FFT(8));
  });

  test('Real FFT 9', () async {
    await testRealFft('test/data/real_fft_9.mat', FFT(9));
  });

  test('Real FFT 10', () async {
    await testRealFft('test/data/real_fft_10.mat', FFT(10));
  });

  test('Real FFT 11', () async {
    await testRealFft('test/data/real_fft_11.mat', FFT(11));
  });

  test('Real FFT 12', () async {
    await testRealFft('test/data/real_fft_12.mat', FFT(12));
  });

  test('Real FFT 461', () async {
    await testRealFft('test/data/real_fft_461.mat', FFT(461));
  });

  test('Real FFT 752', () async {
    await testRealFft('test/data/real_fft_752.mat', FFT(752));
  });

  test('Real FFT 1980', () async {
    await testRealFft('test/data/real_fft_1980.mat', FFT(1980));
  });

  test('Real FFT 2310', () async {
    await testRealFft('test/data/real_fft_2310.mat', FFT(2310));
  });

  test('Real FFT 2442', () async {
    await testRealFft('test/data/real_fft_2442.mat', FFT(2442));
  });

  test('Real FFT 3410', () async {
    await testRealFft('test/data/real_fft_3410.mat', FFT(3410));
  });

  test('Real FFT 4913', () async {
    await testRealFft('test/data/real_fft_4913.mat', FFT(4913));
  });

  test('Real FFT 7429', () async {
    await testRealFft('test/data/real_fft_7429.mat', FFT(7429));
  });

}

