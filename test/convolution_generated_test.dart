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
  test('Circular convolution 1 1 1', () async {
    await testCircConv('test/data/circ_conv_1_1_1.mat', 1);
  });

  test('Circular convolution 5 47 47', () async {
    await testCircConv('test/data/circ_conv_5_47_47.mat', 47);
  });

  test('Circular convolution 91 12 91', () async {
    await testCircConv('test/data/circ_conv_91_12_91.mat', 91);
  });

  test('Circular convolution 127 129 128', () async {
    await testCircConv('test/data/circ_conv_127_129_128.mat', 128);
  });

  test('Circular convolution 337 321 330', () async {
    await testCircConv('test/data/circ_conv_337_321_330.mat', 330);
  });

  test('Circular convolution 1024 1024 1024', () async {
    await testCircConv('test/data/circ_conv_1024_1024_1024.mat', 1024);
  });

  test('Circular convolution 2000 3000 1400', () async {
    await testCircConv('test/data/circ_conv_2000_3000_1400.mat', 1400);
  });

  test('Circular convolution 123 456 null', () async {
    await testCircConv('test/data/circ_conv_123_456_null.mat', null);
  });

  test('Circular convolution 456 789 null', () async {
    await testCircConv('test/data/circ_conv_456_789_null.mat', null);
  });

  test('Circular convolution 1234 1234 null', () async {
    await testCircConv('test/data/circ_conv_1234_1234_null.mat', null);
  });

  test('Linear convolution 1 1', () async {
    await testLinConv('test/data/lin_conv_1_1.mat');
  });

  test('Linear convolution 4 4', () async {
    await testLinConv('test/data/lin_conv_4_4.mat');
  });

  test('Linear convolution 5 47', () async {
    await testLinConv('test/data/lin_conv_5_47.mat');
  });

  test('Linear convolution 91 12', () async {
    await testLinConv('test/data/lin_conv_91_12.mat');
  });

  test('Linear convolution 127 129', () async {
    await testLinConv('test/data/lin_conv_127_129.mat');
  });

  test('Linear convolution 337 321', () async {
    await testLinConv('test/data/lin_conv_337_321.mat');
  });

  test('Linear convolution 1024 1024', () async {
    await testLinConv('test/data/lin_conv_1024_1024.mat');
  });
}
