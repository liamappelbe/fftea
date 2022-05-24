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

import 'util.dart';

/// Extension methods for [Float64x2List], representing a list of complex
/// numbers.
extension ComplexArray on Float64x2List {
  /// Converts a real array to a [Float64x2List] of complex numbers.
  static Float64x2List fromRealArray(List<double> reals) {
    final a = Float64x2List(reals.length);
    for (int i = 0; i < reals.length; ++i) {
      a[i] = Float64x2(reals[i], 0);
    }
    return a;
  }

  /// Returns the real components of the [Float64x2List].
  ///
  /// This method just discards the imaginary components. It doesn't check
  /// whether the imaginary components are actually close to zero.
  Float64List toRealArray() {
    final r = Float64List(length);
    for (int i = 0; i < r.length; ++i) {
      r[i] = this[i].x;
    }
    return r;
  }

  /// Returns the square magnitudes of the elements of the [Float64x2List].
  ///
  /// If you need the squares of the magnitudes, this method is much more
  /// efficient than calling [magnitudes] then squaring those values.
  Float64List squareMagnitudes() {
    final m = Float64List(length);
    for (int i = 0; i < m.length; ++i) {
      final z = this[i];
      m[i] = z.x * z.x + z.y * z.y;
    }
    return m;
  }

  /// Returns the magnitudes of the elements of the [Float64x2List].
  Float64List magnitudes() {
    final m = squareMagnitudes();
    for (int i = 0; i < m.length; ++i) {
      m[i] = math.sqrt(m[i]);
    }
    return m;
  }

  /// Discards redundant conjugate terms, assuming this is the result of a real
  /// valued FFT. This method does not check whether those terms are actualy
  /// redundant conjugate values.
  ///
  /// The result of a real valued FFT is about half redundant data, so the list
  /// returned by this function omits that data:
  ///
  /// (sum term, ...terms..., nyquist term, ...conjugate terms...)
  ///
  /// The sum term, main terms, and nyquitst term, are kept. The conjugate terms
  /// are discarded.
  ///
  /// This method returns a new array (which is a view into the same data). It
  /// does not modify this array, or make a copy of the data.
  Float64x2List discardConjugates() {
    return Float64x2List.sublistView(this, 0, (length >>> 1) + 1);
  }
}

abstract class FFT {
  static final _ffts = <int, FFT>{};
  final int _size;
  FFT._(this._size);

  static FFT _makeFFT(int size) {
    if (isPowerOf2(size)) {
      return Radix2FFT(size);
    }
    return CompositeFFT(size);
  }

  /// Constructs an FFT object with the given size.
  factory FFT(int size) => _ffts[size] ??= _makeFFT(size);

  /// The size of the FFTs that this object can do.
  int get size => _size;

  /// In-place FFT.
  ///
  /// Performs an in-place FFT on [complexArray]. The result is stored back in
  /// [complexArray]. No new arrays are allocated by this method.
  ///
  /// This is the most efficient FFT method, if your data is already in the
  /// correct format. Otherwise, you can use [realFft] to handle the conversion
  /// for you.
  ///
  /// [ComplexArray] also has some useful methods for managing [Float64x2List]s
  /// of complex numbers.
  void inPlaceFft(Float64x2List complexArray);

  /// Real-valued FFT.
  ///
  /// Performs an FFT on real-valued inputs. Returns the result as a
  /// [Float64x2List], and doesn't modify the input array.
  ///
  /// The complex numbers in the [Float64x2List] contain both the amplitude and
  /// phase information for each frequency. If you only care about the
  /// amplitudes, use [ComplexArray.magnitudes].
  ///
  /// The result of a real valued FFT has a lot of redundant information in it.
  /// See [ComplexArray.discardConjugates] for more info.
  Float64x2List realFft(List<double> reals) {
    final o = ComplexArray.fromRealArray(reals);
    inPlaceFft(o);
    return o;
  }

  /// In-place inverse FFT.
  ///
  /// Performs an in-place inverse FFT on [complexArray]. The result is stored
  /// back in [complexArray]. No new arrays are allocated by this method.
  void inPlaceInverseFft(Float64x2List complexArray) {
    inPlaceFft(complexArray);
    final len = complexArray.length;
    final half = len >>> 1;
    final scale = Float64x2.splat(len.toDouble());
    complexArray[0] /= scale;
    if (len <= 1) return;
    for (int i = 1; i < half; ++i) {
      final j = len - i;
      final temp = complexArray[j];
      complexArray[j] = complexArray[i] / scale;
      complexArray[i] = temp / scale;
    }
    complexArray[half] /= scale;
  }

  /// Real-valued inverse FFT.
  ///
  /// Performs an inverse FFT and discards the imaginary components of the
  /// result.
  ///
  /// This method expects the full result of [realFft], so don't use
  /// [ComplexArray.discardConjugates] if you need to call [realInverseFft].
  ///
  /// WARINING: For efficiency reasons, this modifies [complexArray]. If you
  /// need the original values in [complexArray] to remain unmodified, make a
  /// copy of it first: `realInverseFft(complexArray.sublist(0))`
  Float64List realInverseFft(Float64x2List complexArray) {
    inPlaceFft(complexArray);
    final len = complexArray.length;
    final scale = len.toDouble();
    final r = Float64List(len);
    r[0] = complexArray[0].x / scale;
    if (len <= 1) return r;
    for (int i = 1; i < len; ++i) {
      r[i] = complexArray[len - i].x / scale;
    }
    return r;
  }

  /// Returns the frequency that the given index of FFT output represents.
  ///
  /// [samplesPerSecond] is the sampling rate of the input signal in Hz. The
  /// result is also in Hz.
  double frequency(int index, double samplesPerSecond) {
    return index * samplesPerSecond / size;
  }
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
///
/// The size must be a power of two, eg 1, 2, 4, 8, 16 etc.
class Radix2FFT extends FFT {
  final Float64x2List _twiddles;
  final int _bits;

  /// Constructs an FFT object with the given size.
  ///
  /// The size must be a power of two, eg 1, 2, 4, 8, 16 etc.
  Radix2FFT(int powerOf2Size)
      : _twiddles = _calculateTwiddles(powerOf2Size),
        _bits = highestBit(powerOf2Size),super._(powerOf2Size);

  static Float64x2List _calculateTwiddles(int powerOf2Size) {
    if (!isPowerOf2(powerOf2Size)) {
      throw ArgumentError('FFT size must be a power of 2.', 'powerOf2Size');
    }
    if (powerOf2Size <= 1) return Float64x2List.fromList([]);
    if (powerOf2Size == 2) return Float64x2List.fromList([Float64x2(1, 0)]);
    if (powerOf2Size == 4) {
      return Float64x2List.fromList([Float64x2(1, 0), Float64x2(0, 1)]);
    }
    final half = powerOf2Size >>> 1;
    final twiddles = Float64x2List(half);
    twiddles[0] = Float64x2(1, 0);
    final step = 2 * math.pi / powerOf2Size;
    final quarter = half >>> 1;
    final eighth = quarter >>> 1;
    for (int i = 1; i < eighth; ++i) {
      final theta = step * i;
      twiddles[i] = Float64x2(math.cos(theta), math.sin(theta));
    }
    twiddles[eighth] = Float64x2(math.sqrt1_2, math.sqrt1_2);
    for (int i = 1; i < eighth; ++i) {
      final z = -twiddles[eighth - i];
      twiddles[eighth + i] = Float64x2(-z.y, -z.x);
    }
    twiddles[quarter] = Float64x2(0, 1);
    for (int i = 1; i < quarter; ++i) {
      final z = twiddles[quarter - i];
      twiddles[quarter + i] = Float64x2(-z.x, z.y);
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
  ///
  /// [ComplexArray] also has some useful methods for managing [Float64x2List]s
  /// of complex numbers.
  void inPlaceFft(Float64x2List complexArray) {
    final n = _size;
    if (complexArray.length != n) {
      throw ArgumentError('Input data is the wrong length.', 'complexArray');
    }
    // Bit reverse permutation.
    final n2 = n >>> 1;
    final shift = 64 - _bits;
    for (int i = 0; i < n; ++i) {
      // Calculate bit reversal.
      int j = i;
      j = ((j >>> 32) & 0x00000000FFFFFFFF) | (j << 32);
      j = ((j >>> 16) & 0x0000FFFF0000FFFF) | ((j & 0x0000FFFF0000FFFF) << 16);
      j = ((j >>> 8) & 0x00FF00FF00FF00FF) | ((j & 0x00FF00FF00FF00FF) << 8);
      j = ((j >>> 4) & 0x0F0F0F0F0F0F0F0F) | ((j & 0x0F0F0F0F0F0F0F0F) << 4);
      j = ((j >>> 2) & 0x3333333333333333) | ((j & 0x3333333333333333) << 2);
      j = ((j >>> 1) & 0x5555555555555555) | ((j & 0x5555555555555555) << 1);
      j >>>= shift;
      // Permute.
      if (j < i) {
        final temp = complexArray[i];
        complexArray[i] = complexArray[j];
        complexArray[j] = temp;
      }
    }
    // FFT main loop.
    for (int m = 1; m < n;) {
      final nm = n2 ~/ m;
      for (int k = 0, t = 0; k < n;) {
        final km = k + m;
        final p = complexArray[k];
        final o = complexArray[km];
        final w = _twiddles[t];
        final q = o.scale(w.x) + Float64x2(o.y, -o.x).scale(w.y);
        complexArray[k] = p + q;
        complexArray[km] = p - q;
        ++k;
        t += nm;
        if (t >= n2) {
          k += m;
          t = 0;
        }
      }
      m <<= 1;
    }
  }
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
class CompositeFFT extends FFT {
  /// Constructs an FFT object with the given size.
  ///
  /// The size must be a power of two, eg 1, 2, 4, 8, 16 etc.
  CompositeFFT(int size)
      : super._(size);

  /// In-place FFT.
  ///
  /// Performs an in-place FFT on [complexArray]. The result is stored back in
  /// [complexArray]. No new arrays are allocated by this method.
  ///
  /// This is the most efficient FFT method, if your data is already in the
  /// correct format. Otherwise, you can use [realFft] to handle the conversion
  /// for you.
  ///
  /// [ComplexArray] also has some useful methods for managing [Float64x2List]s
  /// of complex numbers.
  void inPlaceFft(Float64x2List complexArray) {}
}

// TODO: Get rid of this function.
Float64x2List select(Float64x2List input, int stride, int offset) {
  final out = Float64x2List(input.length ~/ stride);
  for (int i = offset, j = 0; i < input.length; i += stride, ++j) {
    out[j] = input[i];
  }
  return out;
}

// TODO: Get rid of this function.
Float64x2 compMul(Float64x2 a, Float64x2 b) {
  return Float64x2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

// TODO: Get rid of this function.
Float64x2 rotor(double t) => Float64x2(math.cos(t), math.sin(t));
Float64x2 twiddle(int n, int k) => rotor(-2 * math.pi * k / n);

/*Float64x2List dumbRad3Fft(Float64x2List input) {
  if (input.length == 1) return input;
  final out = Float64x2List(input.length);
  final sub0 = dumbRad3Fft(select(input, 3, 0));
  final sub1 = dumbRad3Fft(select(input, 3, 1));
  final sub2 = dumbRad3Fft(select(input, 3, 2));
  final nn = input.length ~/ 3;
  final ww = twiddle(3, 1);
  final www = compMul(ww, ww);
  for (int k = 0; k < nn; ++k) {
    final p = sub0[k];
    final q = compMul(sub1[k], twiddle(input.length, k));
    final r = compMul(sub2[k], twiddle(input.length, 2 * k));
    out[k] = p + q + r;
    out[k + nn] = p + compMul(q, twiddle(input.length, nn)) + compMul(r, twiddle(input.length, 2 * nn));
    out[k + 2 * nn] = p + compMul(q, twiddle(input.length, 2 * nn)) + compMul(r, twiddle(input.length, 4 * nn));
  }
  return out;
}*/

/*Float64x2List compositeFft(Float64x2List input) {
  return compositeFftImpl(input, 1, 0, primeDecomp(input.length), 0);
}

Float64x2List compositeFftImpl(Float64x2List input, int stride, int offset, List<int> decomp, int di) {
  // TODO: Rewrite as a loop rather than a recursion.
  // TODO: Do all allocations once.
  // TODO: Calculate twiddle factors once.
  // TODO: Can we make this inline?
  // TODO: Handle large prime factors.
  if (di >= decomp.length) return Float64x2List.fromList([input[offset]]);
  final s = decomp[di];
  final ss = s * stride;
  final sub = <Float64x2List>[];
  for (int i = 0; i < s; ++i) {
    sub.add(compositeFftImpl(input, ss, i * stride + offset, decomp, di + 1));
  }
  final n = input.length ~/ stride;
  final out = Float64x2List(n);
  final nn = n ~/ s;
  final w = [for (int i = 0; i < n; ++i) twiddle(n, i),];
  for (int i = 0; i < nn; ++i) {
    for (int j = 0; j < s; ++j) {
      out[i + j * nn] = sub[0][i];
    }
    for (int j = 1; j < s; ++j) {
      final p = compMul(sub[j][i], w[i * j]);
      out[i] += p;
      for (int k = 1; k < s; ++k) {
        out[i + k * nn] += compMul(p, w[(j * k * nn) % n]);
      }
    }
  }
  return out;
}*/

/*Float64x2List compositeFft(Float64x2List input) {
  final n = input.length;
  Float64x2List out = Float64x2List(n);
  Float64x2List buf = Float64x2List(n);
  Float64x2List w = Float64x2List(n);
  for (int i = 0; i < n; ++i) w[i] = twiddle(n, i);
  compositeFftImpl(input, buf, out, w, n, 1, 0, 0, primeDecomp(n), 0);
  return out;
}

void compositeFftImpl(Float64x2List input, Float64x2List buf, Float64x2List out, Float64x2List w, int n, int stride, int off, int boff, List<int> decomp, int di) {
  // TODO: Rewrite as a loop rather than a recursion.
  // TODO: Can we make this inline?
  // TODO: Handle large prime factors.
  // TODO: Reduce index multiplications.
  if (di >= decomp.length) {
    out[boff] = input[off];
    return;
  }
  final s = decomp[di];
  final ss = s * stride;
  final nn = n ~/ s;
  for (int i = 0; i < s; ++i) {
    compositeFftImpl(input, out, buf, w, nn, ss, i * stride + off, boff + i * nn, decomp, di + 1);
  }
  for (int i = 0; i < nn; ++i) {
    final bi = boff + i;
    for (int j = 0; j < s; ++j) {
      out[bi + j * nn] = buf[bi];
    }
    for (int j = 1; j < s; ++j) {
      final p = buf[bi + j * nn];
      for (int k = 0; k < s; ++k) {
        out[bi + k * nn] += compMul(p, w[stride * ((j * (k * nn + i)) % n)]);
      }
    }
  }
}*/

/*int digitReverse(int x, List<int> decomp) {
  int y = 0;
  for (final r in decomp) {
    y *= r;
    y += x % r;
    x ~/= r;
  }
  return y;
}*/

Float64x2List compositeFft(Float64x2List input) {
  final n = input.length;
  Float64x2List out = Float64x2List(n);
  Float64x2List buf = Float64x2List(n);
  Float64x2List w = Float64x2List(n);
  for (int i = 0; i < n; ++i) w[i] = twiddle(n, i);
  compositeFftImpl(input, buf, out, w, n, 1, 0, 0, primeDecomp(n), 0);
  return out;
}

void compositeFftImpl(Float64x2List input, Float64x2List buf, Float64x2List out, Float64x2List w, int n, int stride, int off, int boff, List<int> decomp, int di) {
  // https://doi.org/10.1090/S0025-5718-1965-0178586-1
  // TODO: Rewrite as a loop rather than a recursion.
  // TODO: Can we make this inline?
  // TODO: Handle large prime factors.
  // TODO: Reduce index multiplications.
  if (di >= decomp.length) {
    out[boff] = input[off];
    return;
  }
  final s = decomp[di];
  final ss = s * stride;
  final nn = n ~/ s;
  for (int i = 0; i < s; ++i) {
    compositeFftImpl(input, out, buf, w, nn, ss, i * stride + off, boff + i * nn, decomp, di + 1);
  }
  for (int i = 0; i < nn; ++i) {
    final bi = boff + i;
    for (int j = 0; j < s; ++j) {
      out[bi + j * nn] = buf[bi];
    }
    for (int j = 1; j < s; ++j) {
      final p = buf[bi + j * nn];
      for (int k = 0; k < s; ++k) {
        out[bi + k * nn] += compMul(p, w[stride * ((j * (k * nn + i)) % n)]);
      }
    }
  }
}

/*Float64List circConv(List<double> a, List<double> b) {
  final n = a.length;
  final o = Float64List(n);
  for (int i = 0; i < n; ++i) {
    for (int j = 0; j < n; ++j) {
      o[i] += a[j] * b[(i - j + n) % n];
    }
  }
  return o;
}

Float64List fftConv(List<double> a, List<double> b) {
  final fft = FFT(a.length);
  final aa = fft.realFft(a);
  final bb = fft.realFft(b);
  for (int i = 0; i < a.length; ++i) {
    aa[i] = compMul(aa[i], bb[i]);
  }
  return fft.realInverseFft(aa);
}*/

void primeFft(Float64x2List input) {
  // https://doi.org/10.1109/PROC.1968.6477
  final n = input.length;

  // Primitive root permutation.
  final g = primitiveRootOfPrime(n);
  final n_ = n - 1;
  // TODO: Don't zero pad if n_ is highly composite.
  final pn = nextPowerOf2(2 * n_);
  final a = Float64x2List(pn);
  final b = Float64x2List(pn);
  for (int q = 0; q < n_; ++q) {
    final i = expMod(g, q, n);
    a[q] = input[i];
    final j = multiplicativeInverseOfPrime(i, n);
    b[q] = twiddle(n, j);
  }

  // Cyclic convolution.
  final fft = FFT(pn);  // TODO: Radix2FFT
  fft.inPlaceFft(a);
  fft.inPlaceFft(b);  // TODO: This can also be done at construction time.
  for (int i = 0; i < pn; ++i) {
    a[i] = compMul(a[i], b[i]);
  }
  fft.inPlaceInverseFft(a);

  final x0 = input[0];
  for (int q = 0; q < n_; ++q) {
    final i = multiplicativeInverseOfPrime(expMod(g, q, n), n);

    // First output is just the sum of all the inputs.
    input[0] += input[i];

    // Rest of the outputs are made by wrapping and summing the unpermuted
    // convolution with the first element of the input.
    input[i] = x0;
    for (int j = q; j < pn; j += n_) {
      input[i] += a[j];
    }
  }
}

/*Float64x2List compositeFft(Float64x2List input) {
  final _n = input.length;
  Float64x2List out = input.sublist(0);
  Float64x2List buf = input.sublist(0);
  Float64x2List w = Float64x2List(_n);
  for (int i = 0; i < _n; ++i) w[i] = twiddle(_n, i);
  int stride = 1;
  int off = 0;
  int boff = 0;
  final decomp = primeDecomp(_n);

  int stride = _n;
  int n = 1;
  for (int di = decomp.length - 1; di >= 0; --di) {
    final s = decomp[di];
    stride ~/= s;
    final nn = n;
    n *= s;

    final temp = out;
    out = buf;
    buf = temp;
  }
  return out;
}

void compositeFftImpl(Float64x2List input, Float64x2List buf, Float64x2List out, Float64x2List w, int n, int stride, int off, int boff, List<int> decomp, int di) {
  // TODO: Rewrite as a loop rather than a recursion.
  // TODO: Can we make this inline?
  // TODO: Handle large prime factors.
  // TODO: Reduce index multiplications.
  if (di >= decomp.length) {
    out[boff] = input[off];
    return;
  }
  final s = decomp[di];
  final ss = s * stride;
  final nn = n ~/ s;
  for (int i = 0; i < s; ++i) {
    compositeFftImpl(input, out, buf, w, nn, ss, i * stride + off, boff + i * nn, decomp, di + 1);
  }
  for (int j = 0; j < nn; ++j) {
    final bi = boff + j;
    for (int k = 0; k < s; ++k) {
      out[bi + k * nn] = buf[bi];
    }
    for (int k = 1; k < s; ++k) {
      final p = buf[bi + k * nn];
      for (int l = 0; l < s; ++l) {
        out[bi + l * nn] += compMul(p, w[stride * ((k * (l * nn + j)) % n)]);
      }
    }
  }
}*/

/// Extension methods for [Float64List], representing a windowing function.
extension Window on Float64List {
  /// Applies the window to the [complexArray].
  ///
  /// This method modifies the input array, rather than allocating a new array.
  void inPlaceApplyWindow(Float64x2List complexArray) {
    if (complexArray.length != length) {
      throw ArgumentError('Input data is the wrong length.', 'complexArray');
    }
    for (int i = 0; i < complexArray.length; ++i) {
      complexArray[i] = complexArray[i].scale(this[i]);
    }
  }

  /// Applies the window to the [complexArray].
  ///
  /// Does not modify the input array. Allocates and returns a new array.
  Float64x2List applyWindow(Float64x2List complexArray) {
    final c = complexArray.sublist(0);
    inPlaceApplyWindow(c);
    return c;
  }

  /// Applies the window to the [realArray].
  ///
  /// This method modifies the input array, rather than allocating a new array.
  void inPlaceApplyWindowReal(List<double> realArray) {
    final a = realArray;
    if (a.length != length) {
      throw ArgumentError('Input data is the wrong length.', 'realArray');
    }
    for (int i = 0; i < a.length; ++i) {
      a[i] *= this[i];
    }
  }

  /// Applies the window to the [realArray].
  ///
  /// Does not modify the input array. Allocates and returns a new array.
  Float64List applyWindowReal(List<double> realArray) {
    final c = Float64List.fromList(realArray);
    inPlaceApplyWindowReal(c);
    return c;
  }

  static Float64List _fillSecondHalf(Float64List a) {
    final half = a.length >>> 1;
    final n = a.length - 1;
    for (int i = 0; i < half; ++i) {
      a[n - i] = a[i];
    }
    return a;
  }

  /// Returns a cosine window, such as Hanning or Hamming.
  ///
  /// `w[i] = 1 - amp - amp * cos(2πi / (size - 1))`
  static Float64List cosine(int size, double amplitude) {
    final a = Float64List(size);
    final half = size >>> 1;
    final offset = 1 - amplitude;
    final scale = 2 * math.pi / (size - 1);
    for (int i = 0; i <= half; ++i) {
      a[i] = offset - amplitude * math.cos(scale * i);
    }
    return _fillSecondHalf(a);
  }

  /// Returns a Hanning window.
  ///
  /// This is a kind of cosine window.
  /// `w[i] = 0.5 - 0.5 * cos(2πi / (size - 1))`
  static Float64List hanning(int size) => cosine(size, 0.5);

  /// Returns a Hamming window.
  ///
  /// This is a kind of cosine window.
  /// `w[i] = 0.54 - 0.46 * cos(2πi / (size - 1))`
  static Float64List hamming(int size) => cosine(size, 0.46);

  /// Returns a Bartlett window.
  ///
  /// This is essentially just a triangular window.
  /// `w[i] = 1 - |2i / (size - 1) - 1|`
  static Float64List bartlett(int size) {
    final a = Float64List(size);
    final half = size >>> 1;
    final offset = (size - 1) / 2;
    for (int i = 0; i <= half; ++i) {
      a[i] = 1 - (i / offset - 1).abs();
    }
    return _fillSecondHalf(a);
  }

  /// Returns a Blackman window.
  ///
  /// This is a more elaborate kind of cosine window.
  /// `w[i] = 0.42 - 0.5 * cos(2πi / (size - 1)) + 0.08 * cos(4πi / (size - 1))`
  static Float64List blackman(int size) {
    final a = Float64List(size);
    final half = size >>> 1;
    final scale = 2 * math.pi / (size - 1);
    for (int i = 0; i <= half; ++i) {
      final t = i * scale;
      a[i] = 0.42 - 0.5 * math.cos(t) + 0.08 * math.cos(2 * t);
    }
    return _fillSecondHalf(a);
  }
}

/// Performs STFTs (Short-time Fourier Transforms).
///
/// STFT breaks up the input into overlapping chunks, applies an optional
/// window, and runs an FFT. This is also known as a spectrogram.
///
/// The chunk size must be a power of two, eg 1, 2, 4, 8, 16 etc.
class STFT {
  final FFT _fft;
  final Float64List? _win;
  final Float64x2List _chunk;

  /// Constructs an STFT object of the given size, with an optional windowing
  /// function.
  ///
  /// The chunk size must be a power of two, eg 1, 2, 4, 8, 16 etc.
  STFT(int powerOf2ChunkSize, [this._win])
      : _fft = FFT(powerOf2ChunkSize),
        _chunk = Float64x2List(powerOf2ChunkSize) {
    if (_win != null && _win!.length != powerOf2ChunkSize) {
      throw ArgumentError(
        'Window must have the same length as the chunk size.',
        '_win',
      );
    }
  }

  /// Returns the frequency that the given index of FFT output represents.
  ///
  /// [samplesPerSecond] is the sampling rate of the input signal in Hz. The
  /// result is also in Hz.
  double frequency(int index, double samplesPerSecond) {
    return _fft.frequency(index, samplesPerSecond);
  }

  /// Runs STFT on [input].
  ///
  /// The input is broken up into chunks, windowed, FFT'd, and then passed to
  /// [reportChunk]. If there isn't enough data in the input to fill the final
  /// chunk, it is padded with zeros.
  ///
  /// When using a windowing function, it is recommended that you overlap the
  /// chunks by setting [chunkStride] to less than the chunk size. Once one
  /// chunk has been processed, the window advances by the stride. If no stride
  /// is given, it defaults to the chunk size.
  ///
  /// WARNING: For efficiency reasons, the same [Float64x2List] is reused for
  /// every chunk, always overwriting the FFT of the previous chunk. So if
  /// [reportChunk] needs to keep the data, it should make a copy (eg using
  /// `result.sublist(0)`).
  void run(
    List<double> input,
    Function(Float64x2List) reportChunk, [
    int chunkStride = 0,
  ]) {
    final chunkSize = _fft.size;
    if (chunkStride <= 0) chunkStride = chunkSize;
    for (int i = 0;; i += chunkStride) {
      final i2 = i + chunkSize;
      if (i2 > input.length) {
        int j = 0;
        final stop = input.length - i;
        for (; j < stop; ++j) {
          _chunk[j] = Float64x2(input[i + j], 0);
        }
        for (; j < chunkSize; ++j) {
          _chunk[j] = Float64x2.zero();
        }
      } else {
        for (int j = 0; j < chunkSize; ++j) {
          _chunk[j] = Float64x2(input[i + j], 0);
        }
      }
      _win?.inPlaceApplyWindow(_chunk);
      _fft.inPlaceFft(_chunk);
      reportChunk(_chunk);
      if (i2 >= input.length) {
        break;
      }
    }
  }

  /// Runs STFT on [input].
  ///
  /// This method is the same as [run], except that it copies all the results to
  /// a [List<Float64x2List>] and returns it. It's a convenience method, but
  /// isn't as efficient as run. See [run] for more details.
  List<Float64x2List> runAndCopy(List<double> input, [int chunkStride = 0]) {
    final o = <Float64x2List>[];
    run(input, (Float64x2List f) => o.add(f.sublist(0)), chunkStride);
    return o;
  }
}
