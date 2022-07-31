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

import 'dart:math' as math;
import 'dart:typed_data';

import 'impl.dart' show FFT;
import 'util.dart' show ComplexArray;

/// Returns the circular convolution of real arrays [a] and [b].
///
/// [a] and [b] will be zero padded or truncated to [length], which defaults to
/// the length of the larger array.
///
/// Returns the result as a newly allocated [Float64List], and doesn't modify
/// the input arrays. Also allocates 2 [Float64x2List]s along the way.
///
/// If your input arrays are very different lengths, a naive convolution may be
/// faster than this FFT based algorithm.
Float64List circularConvolution(
  List<double> a,
  List<double> b, [
  int length = 0,
]) {
  if (length <= 0) {
    length = math.max(a.length, b.length);
  }
  final fft = FFT(length);
  final aa = ComplexArray.fromRealArray(a, length);
  final bb = ComplexArray.fromRealArray(b, length);
  fft
    ..inPlaceFft(aa)
    ..inPlaceFft(bb);
  aa.complexMultiply(bb);
  return fft.realInverseFft(aa);
}

/// Returns the linear convolution of real arrays [a] and [b].
///
/// [a] and [b] will be zero padded until they're the same length, and the
/// resulting array will also be this length.
///
/// Returns the result as a newly allocated [Float64List], and doesn't modify
/// the input arrays. Also allocates 2 [Float64x2List]s along the way.
///
/// If your input arrays are very different lengths, a naive convolution may be
/// faster than this FFT based algorithm.
Float64List convolution(List<double> a, List<double> b) {
  final n = math.max(a.length, b.length);
  return Float64List.sublistView(circularConvolution(a, b, n << 1), 0, n);
}
