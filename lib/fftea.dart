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

bool isPowerOf2(int x) => (x > 0) && ((x & (x - 1)) == 0);

/// A thin wrapper around a Float64List, representing a flat list of complex
/// numbers.
///
/// The values in the array alternate between real and complex components:
/// `[real0, imag0, real1, imag1, ...]`
///
/// This wrapper exists mainly for documentation and type safety purposes.
class ComplexArray {
  Float64List _a;

  ComplexArray(this._a);

  int get length => _a.length ~/ 2;
  Float64List get array => _a;

  static ComplexArray fromRealArray(List<double> reals) {
    final a = Float64List(reals.length << 1);
    for (int i = 0; i < reals.length; ++i) {
      a[i << 1] = reals[i];
    }
    return ComplexArray(a);
  }
}

/// Performs FFTs of a particular power-of-2 size.
class FFT {
  final Float64List _twiddles;

  FFT(int powerOf2Size) : _twiddles = _calculateTwiddles(powerOf2Size);

  /// The size of the FFTs that this class can do.
  ///
  /// Real valued input arrays should have this many elements. Complex numbered
  /// input arrays should have twice as many elements.
  int get size => _twiddles.length;

  static Float64List _calculateTwiddles(int powerOf2Size) {
    if (!isPowerOf2(powerOf2Size)) {
      throw ArgumentError('FFT size must be a power of 2.', 'powerOf2Size');
    }
    if (powerOf2Size <= 1) return Float64List.fromList([1]);
    if (powerOf2Size == 2) return Float64List.fromList([1, 0]);
    if (powerOf2Size == 4) return Float64List.fromList([1, 0, 0, -1]);
    final twiddles = Float64List(powerOf2Size);
    twiddles[0] = 1;
    final step = -math.pi / powerOf2Size;
    final half = powerOf2Size >> 1;
    final quat = half >> 1;
    for (int i = 2; i < quat; i += 2) {
      final theta = step * i;
      twiddles[i] = math.cos(theta);
      twiddles[i + 1] = math.sin(theta);
    }
    twiddles[quat] = math.sqrt1_2;
    final quat_ = quat + 1;
    twiddles[quat_] = -math.sqrt1_2;
    for (int i = 2; i < quat; i += 2) {
      twiddles[quat + i] = -twiddles[quat_ - i];
      twiddles[quat_ + i] = -twiddles[quat - i];
    }
    final half_ = half + 1;
    twiddles[half_] = -1;
    for (int i = 2; i < half; i += 2) {
      twiddles[half + i] = -twiddles[half - i];
      twiddles[half_ + i] = twiddles[half_ - i];
    }
    return twiddles;
  }

  /// In-place FFT.
  ///
  /// Performs an in-place FFT on [complexArray]. The result is stored back in
  /// [complexArray]. No new arrays are allocated by this method.
  ///
  /// This is the most efficient FFT method, if your data is already in the
  /// correct format. Otherwise, you can use one of the other methods to handle
  /// the conversion for you.
  void inPlaceFft(ComplexArray complexArray) {
    final a = complexArray._a;
    final n = _twiddles.length;
    final n2 = n << 1;
    if (a.length != n2) {
      throw ArgumentError('Input data is the wrong length.', 'complexArray');
    }
    for (int i = 0; i < n; ++i) {
      int j = 0;
      for (int nn = n >> 1, ii = i; nn > 0; nn >>= 1, ii >>= 1) {
        j = (j << 1) | (ii & 1);
      }
      if (j < i) {
        final ir = i << 1;
        final jr = j << 1;
        final tr = a[ir];
        a[ir] = a[jr];
        a[jr] = tr;
        final ii = ir + 1;
        final ji = jr + 1;
        final ti = a[ii];
        a[ii] = a[ji];
        a[ji] = ti;
      }
    }
    for (int m = 1; m < n;) {
      final m2 = m << 1;
      final n_m = n ~/ m;
      for (int k = 0, t = 0; k < n2;) {
        final km = k + m2;
        final pr = a[k];
        final pi = a[k + 1];
        final or = a[km];
        final oi = a[km + 1];
        final wr = _twiddles[t];
        final wi = _twiddles[t + 1];
        final qr = or * wr - oi * wi;
        final qi = oi * wr + or * wi;
        a[k] = pr + qr;
        a[k + 1] = pi + qi;
        a[km] = pr - qr;
        a[km + 1] = pi - qi;
        k += 2;
        t += n_m;
        if (t >= n) {
          k += m2;
          t = 0;
        }
      }
      m = m2;
    }
  }

  /// Real-valued FFT.
  ///
  /// Performs an FFT on real-valued inputs. Returns the result as a
  /// [ComplexArray], and doesn't modify the input array.
  ComplexArray realFft(List<double> a) {
    final o = ComplexArray.fromRealArray(a);
    inPlaceFft(o);
    return o;
  }
}
