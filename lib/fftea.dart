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

  /// Constructs a ComplexArray from a Float64List.
  ///
  /// The given Float64List must be in the correct format. The values must
  /// alternate between real and complex components:
  /// `[real0, imag0, real1, imag1, ...]`
  ComplexArray(this._a);

  /// Length of the ComplexArray.
  ///
  /// That is, the number of (real, imag) pairs in the array.
  int get length => _a.length ~/ 2;

  /// Returns the underlying array.
  ///
  /// The values in the array alternate between real and complex components:
  /// `[real0, imag0, real1, imag1, ...]`
  Float64List get array => _a;

  /// Returns a copy of this ComplexArray.
  ///
  /// The underlying array is copied, so modifications to the returned
  /// ComplexArray will not affect this one.
  ComplexArray copy() => ComplexArray(Float64List.fromList(_a));

  /// Converts a real array to a ComplexArray.
  static ComplexArray fromRealArray(List<double> reals) {
    final a = Float64List(reals.length << 1);
    for (int i = 0; i < reals.length; ++i) {
      a[i << 1] = reals[i];
    }
    return ComplexArray(a);
  }

  /// Returns the real components of the ComplexArray.
  ///
  /// This method just discards the imaginary components.
  Float64List toRealArray() {
    final r = Float64List(length);
    for (int i = 0; i < r.length; ++i) {
      r[i] = _a[i << 1];
    }
    return r;
  }

  /// Returns the square magnitudes of the elements of the ComplexArray.
  ///
  /// If you need the squares of the magnitudes, this method is much more
  /// efficient than calling `magnitudes()` then squaring those values.
  Float64List squareMagnitudes() {
    final m = Float64List(length);
    for (int i = 0; i < m.length; ++i) {
      final j = i << 1;
      final x = _a[j];
      final y = _a[j + 1];
      m[i] = x * x + y * y;
    }
    return m;
  }

  /// Returns the magnitudes of the elements of the ComplexArray.
  Float64List magnitudes() {
    final m = squareMagnitudes();
    for (int i = 0; i < m.length; ++i) {
      m[i] = math.sqrt(m[i]);
    }
    return m;
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
  /// correct format. Otherwise, you can use [realFft] to handle the conversion
  /// for you.
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

  /// In-place inverse FFT.
  ///
  /// Performs an in-place inverse FFT on [complexArray]. The result is stored
  /// back in [complexArray]. No new arrays are allocated by this method.
  void inPlaceInverseFft(ComplexArray complexArray) {
    inPlaceFft(complexArray);
    final a = complexArray.array;
    final len = a.length;
    final half = len >> 1;
    final scale = half.toDouble();
    a[0] /= scale;
    a[1] /= scale;
    if (len <= 2) return;
    for (int i = 2; i < half; i += 2) {
      final ii = i + 1;
      final jr = len - i;
      final ji = jr + 1;
      final tr = a[jr] / scale;
      final ti = a[ji] / scale;
      a[jr] = a[i] / scale;
      a[ji] = a[ii] / scale;
      a[i] = tr;
      a[ii] = ti;
    }
    a[half] /= scale;
    a[half + 1] /= scale;
  }

  /// Real-valued inverse FFT.
  ///
  /// Performs an inverse FFT and discards the imaginary components of the
  /// result.
  ///
  /// WARINING: For efficiency reasons, this modifies [complexArray]. If you
  /// need the original values in [complexArray] to remain unmodified, make a
  /// copy of it first: `realInverseFft(complexArray.copy())`
  Float64List realInverseFft(ComplexArray complexArray) {
    inPlaceFft(complexArray);
    final a = complexArray.array;
    final len = a.length;
    final half = len >> 1;
    final scale = half.toDouble();
    final r = Float64List(half);
    r[0] = a[0] / scale;
    if (len <= 2) return r;
    for (int i = 1; i < half; ++i) {
      r[i] = a[len - (i << 1)] / scale;
    }
    return r;
  }
}
