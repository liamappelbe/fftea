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

// TODO: Test all utils
// TODO: Migrate remaining large array tests to use matrix files
// TODO: Test toString
// TODO: Test FFT type selector
// TODO: Test size 2 and 3 FFT
// TODO: More documentation, especially of the utils.

import 'dart:math' as math;
import 'dart:typed_data';

import 'util.dart';

extension Complex on Float64x2 {
  double get squareMagnitude => x * x + y * y;
  double get magnitude => math.sqrt(squareMagnitude);
}

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
  /// are discarded. For odd length arrays, the nyquist term doesn't exist.
  ///
  /// This method returns a new array (which is a view into the same data). It
  /// does not modify this array, or make a copy of the data.
  Float64x2List discardConjugates() {
    // TODO: What about odd numbered lengths?
    return Float64x2List.sublistView(this, 0, (length >>> 1) + 1);
  }
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
abstract class FFT {
  //                    no flags,     isPow2,     shouldPrimePad,  isOddPrime
  static final _ffts = [<int, FFT>{}, <int, FFT>{}, <int, FFT>{}, <int, FFT>{}];
  static _key(bool isPow2, bool isOddPrime, bool shouldPrimePad) =>
      isPow2 ? 1 : (shouldPrimePad ? 2 : (isOddPrime ? 3 : 0));

  final int _size;
  FFT._(this._size);

  static const _kAlwaysNaiveThreshold = 16;
  static const _kCompositeNaiveThreshold = 24;
  static FFT _makeFFT(int size, bool isPow2, bool isOddPrime, bool shouldPrimePad) {
    if (size <= 0) {
      throw ArgumentError('FFT size must be greater than 0.', 'size');
    }
    if (size == 2) {
      return Fixed2FFT();
    }
    if (size == 3) {
      return Fixed3FFT();
    }
    // TODO: Special case 4, and use it as a base case in CompositeFFT.
    if (size < _kAlwaysNaiveThreshold) {
      return NaiveFFT(size);
    }
    if (isPow2) {
      return Radix2FFT(size);
    }
    if (size < _kCompositeNaiveThreshold) {
      return NaiveFFT(size);
    }
    if (isOddPrime) {
      return PrimeFFT(size, shouldPrimePad);
    }
    return CompositeFFT(size);
  }

  static FFT _makeFFTCached(int size, bool isPow2, bool isOddPrime, bool shouldPrimePad) =>
      _ffts[_key(isPow2, isOddPrime, shouldPrimePad)][size] ??=
          _makeFFT(size, isPow2, isOddPrime, shouldPrimePad);

  /// Constructs an FFT object with the given size.
  factory FFT(int size) {
    final isPow2 = isPowerOf2(size);
    final isOddPrime = !isPow2 && isPrime(size);
    final shouldPrimePad = isOddPrime && primePaddingHeuristic(size);
    return _makeFFTCached(size, isPow2, isOddPrime, shouldPrimePad);
  }

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
  void inPlaceFft(Float64x2List complexArray) {
    if (complexArray.length != _size) {
      throw ArgumentError('Input data is the wrong length.', 'complexArray');
    }
    _inPlaceFftImpl(complexArray);
  }

  void _inPlaceFftImpl(Float64x2List complexArray);

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
    for (int i = 1; i <= half; ++i) {
      final j = len - i;
      final temp = complexArray[j];
      complexArray[j] = complexArray[i] / scale;
      complexArray[i] = temp / scale;
    }
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
        _bits = highestBit(powerOf2Size),
        super._(powerOf2Size);

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

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    // Bit reverse permutation.
    final n = _size;
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
    for (int ms = 0; ms < _bits; ++ms) {
      final m = 1 << ms;
      final nm = n2 >>> ms;
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
    }
  }

  @override
  String toString() => 'Radix2FFT($_size)';
}

abstract class _StridedFFT extends FFT {
  _StridedFFT._(int size) : super._(size);

  // Note: inp and out may or may not need to be distinct. If you don't know the
  // underlying implementation, assume they need to be distinct.
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride);
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
class NaiveFFT extends _StridedFFT {
  final Float64x2List _twiddles;
  final Float64x2List _buf;

  /// Constructs an FFT object with the given size.
  NaiveFFT(int size) : _twiddles = twiddleFactors(size), _buf = Float64x2List(size), super._(size) {}

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, _buf, 1, 0, null, 0);
    complexArray.setAll(0, _buf);
  }

  // Note: inp and out must be distinct.
  @override
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride) {
    final x0 = inp[off];
    for (int io = off, st = 0; st < _size; io += stride, ++st) {
      out[io] = x0;
    }
    final ioff = off + stride;
    if (w != null) {
      for (int ii = ioff, ji = 1; ji < _size; ii += stride, ++ji) {
        final a = inp[ii];
        final b = w[(ji * wstride) % w.length];
        inp[ii] = Float64x2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
      }
    }
    for (int ii = ioff, ji = 1; ji < _size; ii += stride, ++ji) {
      final a = inp[ii];
      for (int io = off, jj = 0, k = 0; k < _size; io += stride, jj += ji, ++k) {
        final b = _twiddles[jj % _size];
        out[io] += Float64x2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
      }
    }
  }

  @override
  String toString() => 'NaiveFFT($_size)';
}

/// Performs FFTs (Fast Fourier Transforms) of size 2.
class Fixed2FFT extends _StridedFFT {
  /// Constructs an FFT object.
  Fixed2FFT() : super._(2) {}

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, complexArray, 1, 0, null, 0);
  }

  // Note: inp and out don't have to be distinct.
  @override
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride) {
    final x0 = inp[off];
    final off1 = off + stride;
    Float64x2 x1 = inp[off1];
    if (w != null) {
      final b = w[wstride];
      x1 = Float64x2(x1.x * b.x - x1.y * b.y, x1.x * b.y + x1.y * b.x);
    }
    out[off] = x0 + x1;
    out[off1] = x0 - x1;
  }

  @override
  String toString() => 'Fixed2FFT()';
}

/// Performs FFTs (Fast Fourier Transforms) of size 3.
class Fixed3FFT extends _StridedFFT {
  /// Constructs an FFT object.
  Fixed3FFT() : super._(3) {}
  static const double _tx = -0.5;
  static const double _ty = -0.8660254037844387;

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, complexArray, 1, 0, null, 0);
  }

  static final _twiddles = twiddleFactors(3);

  // Note: inp and out don't have to be distinct.
  @override
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride) {
    final x0 = inp[off];
    final off1 = off + stride;
    Float64x2 x1 = inp[off1];
    final off2 = off1 + stride;
    Float64x2 x2 = inp[off2];
    if (w != null) {
      final b1 = w[wstride];
      x1 = Float64x2(x1.x * b1.x - x1.y * b1.y, x1.x * b1.y + x1.y * b1.x);
      final b2 = w[wstride + wstride];
      x2 = Float64x2(x2.x * b2.x - x2.y * b2.y, x2.x * b2.y + x2.y * b2.x);
    }
    final x12 = x1 + x2;
    final dz = x1 - x2;
    out[off] = x0 + x12;
    final zx = x0 + x12 * Float64x2(_tx, _tx);
    final zy = Float64x2(-_ty * dz.y, _ty * dz.x);
    out[off1] = zx + zy;
    out[off2] = zx - zy;
  }

  @override
  String toString() => 'Fixed3FFT()';
}

class _CompositeFFTJob {
  final Float64x2List buf;
  final Float64x2List out;
  final int nn;
  final int i;
  final int bi;
  final Float64x2List w;
  final _StridedFFT fft;
  _CompositeFFTJob(this.buf, this.out, int s, this.nn, this.i, this.bi, this.w)
      : fft = FFT._makeFFTCached(s, false, true, primePaddingHeuristic(s)) as _StridedFFT;
  void run() => fft._stridedFft(buf, out, nn, bi, w, i);
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
class CompositeFFT extends FFT {
  final Float64x2List _buf;
  final Float64x2List _out;
  final Float64x2List _twiddles;
  late final Float64x2List _innerBuf;
  final Uint64List _perm;
  final _ffts = <List<_CompositeFFTJob>>[];

  /// Constructs an FFT object with the given size.
  CompositeFFT(int size) : _buf = Float64x2List(size), _out = Float64x2List(size), _twiddles = twiddleFactors(size), _perm = Uint64List(size), super._(size) {
    // TODO: Investigate combining the smaller factors into larger factors that
    // are still smaller than the _kNaiveThreshold. Is this faster?
    final decomp = primeDecomp(size);
    for (int i = 0; i < decomp.length; ++i) {
      _ffts.add(<_CompositeFFTJob>[]);
    }
    _ctorRec(_buf, _out, decomp, size, 1, 0, 0, 0);
    _innerBuf = (decomp.length % 2 != 0) ? _buf : _out;
  }

  void _ctorRec(Float64x2List buf, Float64x2List out, List<int> decomp, int n, int stride, int off, int boff, int di) {
    if (di >= decomp.length) {
      _perm[off] = boff;
      return;
    }

    final s = decomp[di];
    final ss = s * stride;
    final nn = n ~/ s;

    for (int i = 0; i < s; ++i) {
      _ctorRec(out, buf, decomp, nn, ss, i * stride + off, boff + i * nn, di + 1);
    }

    final ffts = _ffts[di];
    for (int i = 0; i < nn; ++i) {
      final bi = boff + i;
      ffts.add(_CompositeFFTJob(buf, out, s, nn, i * stride, bi, _twiddles));
    }
  }

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    for (int i = 0; i < _size; ++i) {
      _innerBuf[_perm[i]] = complexArray[i];
    }
    for (int i = _ffts.length - 1; i >= 0; --i) {
      for (final job in _ffts[i]) {
        job.run();
      }
    }
    complexArray.setAll(0, _out);
  }

  @override
  String toString() => 'CompositeFFT($_size)';
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
///
/// The size must be a prime number greater than 2, eg 3, 5, 7, 11 etc.
class PrimeFFT extends _StridedFFT {
  // TODO: Is Bluestein's algorithm faster?
  final int _g;
  final int _pn;
  final Float64x2List _a;
  final Float64x2List _b;
  final FFT _fft;

  PrimeFFT._(int size, bool padToPow2, int pn) :
      _g = primitiveRootOfPrime(size),
      _pn = pn,
      _a = Float64x2List(pn),
      _b = Float64x2List(pn),
      _fft = FFT._makeFFTCached(pn, padToPow2 || isPowerOf2(pn), false, false),
      super._(size) {
    final n_ = size - 1;
    for (int q = 0; q < n_; ++q) {
      final j = multiplicativeInverseOfPrime(expMod(_g, q, size), size);
      final t = -2 * math.pi * j / size;
      _b[q] = Float64x2(math.cos(t), math.sin(t));
    }
    _fft._inPlaceFftImpl(_b);
  }

  /// Constructs an FFT object with the given size.
  ///
  /// The size must be a prime number greater than 2, eg 3, 5, 7, 11 etc. This
  /// FFT works by delegating to an FFT of either `size - 1`, or padding it up
  /// to a power of two. If `size - 1` is very composite, then not padding is
  /// faster, but if `size - 1` is nearly prime, then padding is faster.
  PrimeFFT(int size, bool padToPow2) :
      this._(size, padToPow2, padToPow2 ? nextPowerOf2((size - 1) << 1) : size - 1);

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, complexArray, 1, 0, null, 0);
  }

  // Note: inp and out don't have to be distinct.
  @override
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride) {
    // https://doi.org/10.1109/PROC.1968.6477
    // Primitive root permutation.
    final n_ = _size - 1;
    if (w != null) {
      for (int ii = off + stride, wi = wstride, ji = 1; ji < _size; ii += stride, wi += wstride, ++ji) {
        final a = inp[ii];
        final b = w[wi % w.length];
        inp[ii] = Float64x2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
      }
    }
    for (int q = 0; q < n_; ++q) {
      final i = expMod(_g, q, _size);
      _a[q] = inp[i * stride + off];
    }
    _a.fillRange(n_, _a.length, Float64x2.zero());

    // Cyclic convolution.
    _fft._inPlaceFftImpl(_a);
    for (int i = 0; i < _pn; ++i) {
      final a = _a[i];
      final b = _b[i];
      _a[i] = Float64x2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
    }
    _fft.inPlaceInverseFft(_a);

    // Unpermute and store in out.
    final x0 = inp[off];
    out[off] = x0;
    for (int q = 0; q < n_; ++q) {
      final i = multiplicativeInverseOfPrime(expMod(_g, q, _size), _size);

      // First output is just the sum of all the inputs.
      final oi = i * stride + off;
      out[off] += inp[oi];

      // Rest of the outputs are made by wrapping and summing the unpermuted
      // convolution with the first element of the input.
      out[oi] = x0;
      for (int j = q; j < _pn; j += n_) {
        out[oi] += _a[j];
      }
    }
  }

  @override
  String toString() => 'PrimeFFT($_size)';
}

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
      _fft._inPlaceFftImpl(_chunk);
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
