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
  test('Radix2FFT 1', () async {
    await testFft('test/data/fft_1.mat', Radix2FFT(1));
  });

  test('Radix2FFT 2', () async {
    await testFft('test/data/fft_2.mat', Radix2FFT(2));
  });

  test('Radix2FFT 4', () async {
    await testFft('test/data/fft_4.mat', Radix2FFT(4));
  });

  test('Radix2FFT 8', () async {
    await testFft('test/data/fft_8.mat', Radix2FFT(8));
  });

  test('Radix2FFT 16', () async {
    await testFft('test/data/fft_16.mat', Radix2FFT(16));
  });

  test('Radix2FFT 32', () async {
    await testFft('test/data/fft_32.mat', Radix2FFT(32));
  });

  test('Radix2FFT 64', () async {
    await testFft('test/data/fft_64.mat', Radix2FFT(64));
  });

  test('Radix2FFT 128', () async {
    await testFft('test/data/fft_128.mat', Radix2FFT(128));
  });

  test('Radix2FFT 256', () async {
    await testFft('test/data/fft_256.mat', Radix2FFT(256));
  });

  test('Radix2FFT 512', () async {
    await testFft('test/data/fft_512.mat', Radix2FFT(512));
  });

  test('Radix2FFT 1024', () async {
    await testFft('test/data/fft_1024.mat', Radix2FFT(1024));
  });

  test('Real Radix2FFT 1', () async {
    await testRealFft('test/data/real_fft_1.mat', Radix2FFT(1));
  });

  test('Real Radix2FFT 2', () async {
    await testRealFft('test/data/real_fft_2.mat', Radix2FFT(2));
  });

  test('Real Radix2FFT 4', () async {
    await testRealFft('test/data/real_fft_4.mat', Radix2FFT(4));
  });

  test('Real Radix2FFT 8', () async {
    await testRealFft('test/data/real_fft_8.mat', Radix2FFT(8));
  });

  test('Real Radix2FFT 16', () async {
    await testRealFft('test/data/real_fft_16.mat', Radix2FFT(16));
  });

  test('Real Radix2FFT 32', () async {
    await testRealFft('test/data/real_fft_32.mat', Radix2FFT(32));
  });

  test('Real Radix2FFT 64', () async {
    await testRealFft('test/data/real_fft_64.mat', Radix2FFT(64));
  });

  test('Real Radix2FFT 128', () async {
    await testRealFft('test/data/real_fft_128.mat', Radix2FFT(128));
  });

  test('Real Radix2FFT 256', () async {
    await testRealFft('test/data/real_fft_256.mat', Radix2FFT(256));
  });

  test('Real Radix2FFT 512', () async {
    await testRealFft('test/data/real_fft_512.mat', Radix2FFT(512));
  });

  test('Real Radix2FFT 1024', () async {
    await testRealFft('test/data/real_fft_1024.mat', Radix2FFT(1024));
  });

}

