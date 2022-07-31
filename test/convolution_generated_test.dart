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
  test('Convolve 1 1', () async {
    await testConv('test/data/conv_1_1_1.mat', 1);
  });

  test('Convolve 5 47', () async {
    await testConv('test/data/conv_5_47_47.mat', 47);
  });

  test('Convolve 91 12', () async {
    await testConv('test/data/conv_91_12_91.mat', 91);
  });

  test('Convolve 127 129', () async {
    await testConv('test/data/conv_127_129_128.mat', 128);
  });

  test('Convolve 337 321', () async {
    await testConv('test/data/conv_337_321_330.mat', 330);
  });

  test('Convolve 1024 1024', () async {
    await testConv('test/data/conv_1024_1024_1024.mat', 1024);
  });

  test('Convolve 2000 3000', () async {
    await testConv('test/data/conv_2000_3000_1400.mat', 1400);
  });
}
