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

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
///
/// This is the base class of a bunch of different implementations. Use the
/// [FFT.FFT] constructor to automatically select the correct implementation for
/// your buffer size.
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
/// The size must be a power of two, eg 1, 2, 4, 8, 16 etc. This is the fastest
/// implementation, using a highly optimised version of the Cooley–Tukey
/// algorithm.
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

// Special base class for FFTs that can do striding, which is necessary for any
// base cases of [CompositeFFT].
abstract class _StridedFFT extends FFT {
  _StridedFFT._(int size) : super._(size);

  // Note: inp and out may or may not need to be distinct. If you don't know the
  // underlying implementation, assume they need to be distinct.
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride);
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
///
/// This implementation can do any size, but is O(n^2), so for large sizes it is
/// much slower. But due to it's simplicity, it's the fastest implementation for
/// small sizes.
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
///
/// This is mainly useful as a base case of [CompositeFFT].
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
///
/// This is mainly useful as a base case of [CompositeFFT].
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

// Represents a single stage of execution of [CompositeFFT].
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
///
/// This implementation handles arbitrary sizes, by decomposing the FFT into
/// smaller sized FFTs, using the Cooley–Tukey algorithm.
class CompositeFFT extends FFT {
  final Float64x2List _buf;
  final Float64x2List _out;
  final Float64x2List _twiddles;
  late final Float64x2List _innerBuf;
  final Uint64List _perm;
  final _ffts = <List<_CompositeFFTJob>>[];

  /// Constructs an FFT object with the given size.
  CompositeFFT(int size) : _buf = Float64x2List(size), _out = Float64x2List(size), _twiddles = twiddleFactors(size), _perm = Uint64List(size), super._(size) {
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
/// The size must be a prime number greater than 2, eg 3, 5, 7, 11 etc. This
/// implementation works by delegating to an FFT of either `size - 1` (which is
/// composite, so can be handled by [CompositeFFT]), or by padding it up to a
/// power of two (which can be handled by [Radix2FFT]), using Rader's algorithm.
/// If `size - 1` only has small prime factors, then not padding is faster, but
/// if `size - 1` has large prime factors, then padding is faster. This decision
/// is made by [primePaddingHeuristic].
class PrimeFFT extends _StridedFFT {
  final bool _padToPow2;
  final int _g;
  final int _pn;
  final Float64x2List _a;
  final Float64x2List _b;
  final FFT _fft;

  PrimeFFT._(int size, bool padToPow2, int pn) :
      _padToPow2 = padToPow2,
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
  /// The size must be a prime number greater than 2, eg 3, 5, 7, 11 etc.
  PrimeFFT(int size, bool padToPow2) :
      this._(size, padToPow2, padToPow2 ? nextPowerOf2((size - 1) << 1) : size - 1);

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, complexArray, 1, 0, null, 0);
  }

  // Note: inp and out don't have to be distinct.
  @override
  void _stridedFft(Float64x2List inp, Float64x2List out, int stride, int off, Float64x2List? w, int wstride) {
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
  String toString() => 'PrimeFFT($_size, $_padToPow2)';
}
