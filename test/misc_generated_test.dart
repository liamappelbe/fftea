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

import 'test_util.dart';

void main() {
  test('Window hamming 1', () async {
    await testWindow('test/data/window_hamming_1.mat', Window.hamming(1));
  });

  test('Window hanning 1', () async {
    await testWindow('test/data/window_hanning_1.mat', Window.hanning(1));
  });

  test('Window bartlett 1', () async {
    await testWindow('test/data/window_bartlett_1.mat', Window.bartlett(1));
  });

  test('Window blackman 1', () async {
    await testWindow('test/data/window_blackman_1.mat', Window.blackman(1));
  });

  test('Window apply real hamming 1', () async {
    await testWindowApplyReal('test/data/window_apply_real_hamming_1.mat', Window.hamming(1));
  });

  test('Window apply complex hamming 1', () async {
    await testWindowApplyComplex('test/data/window_apply_complex_hamming_1.mat', Window.hamming(1));
  });

  test('Window hamming 2', () async {
    await testWindow('test/data/window_hamming_2.mat', Window.hamming(2));
  });

  test('Window hanning 2', () async {
    await testWindow('test/data/window_hanning_2.mat', Window.hanning(2));
  });

  test('Window bartlett 2', () async {
    await testWindow('test/data/window_bartlett_2.mat', Window.bartlett(2));
  });

  test('Window blackman 2', () async {
    await testWindow('test/data/window_blackman_2.mat', Window.blackman(2));
  });

  test('Window apply real hamming 2', () async {
    await testWindowApplyReal('test/data/window_apply_real_hamming_2.mat', Window.hamming(2));
  });

  test('Window apply complex hamming 2', () async {
    await testWindowApplyComplex('test/data/window_apply_complex_hamming_2.mat', Window.hamming(2));
  });

  test('Window hamming 3', () async {
    await testWindow('test/data/window_hamming_3.mat', Window.hamming(3));
  });

  test('Window hanning 3', () async {
    await testWindow('test/data/window_hanning_3.mat', Window.hanning(3));
  });

  test('Window bartlett 3', () async {
    await testWindow('test/data/window_bartlett_3.mat', Window.bartlett(3));
  });

  test('Window blackman 3', () async {
    await testWindow('test/data/window_blackman_3.mat', Window.blackman(3));
  });

  test('Window apply real hamming 3', () async {
    await testWindowApplyReal('test/data/window_apply_real_hamming_3.mat', Window.hamming(3));
  });

  test('Window apply complex hamming 3', () async {
    await testWindowApplyComplex('test/data/window_apply_complex_hamming_3.mat', Window.hamming(3));
  });

  test('Window hamming 16', () async {
    await testWindow('test/data/window_hamming_16.mat', Window.hamming(16));
  });

  test('Window hanning 16', () async {
    await testWindow('test/data/window_hanning_16.mat', Window.hanning(16));
  });

  test('Window bartlett 16', () async {
    await testWindow('test/data/window_bartlett_16.mat', Window.bartlett(16));
  });

  test('Window blackman 16', () async {
    await testWindow('test/data/window_blackman_16.mat', Window.blackman(16));
  });

  test('Window apply real hamming 16', () async {
    await testWindowApplyReal('test/data/window_apply_real_hamming_16.mat', Window.hamming(16));
  });

  test('Window apply complex hamming 16', () async {
    await testWindowApplyComplex('test/data/window_apply_complex_hamming_16.mat', Window.hamming(16));
  });

  test('Window hamming 47', () async {
    await testWindow('test/data/window_hamming_47.mat', Window.hamming(47));
  });

  test('Window hanning 47', () async {
    await testWindow('test/data/window_hanning_47.mat', Window.hanning(47));
  });

  test('Window bartlett 47', () async {
    await testWindow('test/data/window_bartlett_47.mat', Window.bartlett(47));
  });

  test('Window blackman 47', () async {
    await testWindow('test/data/window_blackman_47.mat', Window.blackman(47));
  });

  test('Window apply real hamming 47', () async {
    await testWindowApplyReal('test/data/window_apply_real_hamming_47.mat', Window.hamming(47));
  });

  test('Window apply complex hamming 47', () async {
    await testWindowApplyComplex('test/data/window_apply_complex_hamming_47.mat', Window.hamming(47));
  });

  test('STFT null 47 16 5', () async {
    await testStft('test/data/stft_null_47_16_5.mat', STFT(16), 5);
  });

  test('STFT hamming 47 16 5', () async {
    await testStft('test/data/stft_hamming_47_16_5.mat', STFT(16, Window.hamming(16)), 5);
  });

  test('STFT null 47 16 16', () async {
    await testStft('test/data/stft_null_47_16_16.mat', STFT(16), 16);
  });

  test('STFT hamming 47 16 16', () async {
    await testStft('test/data/stft_hamming_47_16_16.mat', STFT(16, Window.hamming(16)), 16);
  });

  test('STFT null 47 23 5', () async {
    await testStft('test/data/stft_null_47_23_5.mat', STFT(23), 5);
  });

  test('STFT hamming 47 23 5', () async {
    await testStft('test/data/stft_hamming_47_23_5.mat', STFT(23, Window.hamming(23)), 5);
  });

  test('STFT null 47 23 23', () async {
    await testStft('test/data/stft_null_47_23_23.mat', STFT(23), 23);
  });

  test('STFT hamming 47 23 23', () async {
    await testStft('test/data/stft_hamming_47_23_23.mat', STFT(23, Window.hamming(23)), 23);
  });

  test('STFT null 128 16 5', () async {
    await testStft('test/data/stft_null_128_16_5.mat', STFT(16), 5);
  });

  test('STFT hamming 128 16 5', () async {
    await testStft('test/data/stft_hamming_128_16_5.mat', STFT(16, Window.hamming(16)), 5);
  });

  test('STFT null 128 16 16', () async {
    await testStft('test/data/stft_null_128_16_16.mat', STFT(16), 16);
  });

  test('STFT hamming 128 16 16', () async {
    await testStft('test/data/stft_hamming_128_16_16.mat', STFT(16, Window.hamming(16)), 16);
  });

  test('STFT null 128 23 5', () async {
    await testStft('test/data/stft_null_128_23_5.mat', STFT(23), 5);
  });

  test('STFT hamming 128 23 5', () async {
    await testStft('test/data/stft_hamming_128_23_5.mat', STFT(23, Window.hamming(23)), 5);
  });

  test('STFT null 128 23 23', () async {
    await testStft('test/data/stft_null_128_23_23.mat', STFT(23), 23);
  });

  test('STFT hamming 128 23 23', () async {
    await testStft('test/data/stft_hamming_128_23_23.mat', STFT(23, Window.hamming(23)), 23);
  });

  test('STFT null 1234 16 5', () async {
    await testStft('test/data/stft_null_1234_16_5.mat', STFT(16), 5);
  });

  test('STFT hamming 1234 16 5', () async {
    await testStft('test/data/stft_hamming_1234_16_5.mat', STFT(16, Window.hamming(16)), 5);
  });

  test('STFT null 1234 16 16', () async {
    await testStft('test/data/stft_null_1234_16_16.mat', STFT(16), 16);
  });

  test('STFT hamming 1234 16 16', () async {
    await testStft('test/data/stft_hamming_1234_16_16.mat', STFT(16, Window.hamming(16)), 16);
  });

  test('STFT null 1234 23 5', () async {
    await testStft('test/data/stft_null_1234_23_5.mat', STFT(23), 5);
  });

  test('STFT hamming 1234 23 5', () async {
    await testStft('test/data/stft_hamming_1234_23_5.mat', STFT(23, Window.hamming(23)), 5);
  });

  test('STFT null 1234 23 23', () async {
    await testStft('test/data/stft_null_1234_23_23.mat', STFT(23), 23);
  });

  test('STFT hamming 1234 23 23', () async {
    await testStft('test/data/stft_hamming_1234_23_23.mat', STFT(23, Window.hamming(23)), 23);
  });

}

