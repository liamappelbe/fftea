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
  /// are discarded.
  ///
  /// This method returns a new array (which is a view into the same data). It
  /// does not modify this array, or make a copy of the data.
  Float64x2List discardConjugates() {
    return Float64x2List.sublistView(this, 0, (length >>> 1) + 1);
  }
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
abstract class FFT {
  static final _ffts = <int, FFT>{};
  final int _size;
  FFT._(this._size);

  // TODO: Tune this threshold. When is PrimePaddedFFT faster than NaiveFFT?
  static const _kNaiveThreshold = 16;
  static FFT _makeFFT(int size, bool isPow2, bool isPrime) {
    if (size <= 0) {
      throw ArgumentError('FFT size must be greater than 0.', 'size');
    }
    // TODO: Is NaiveFFT faster than Radix2FFT for small enough sizes?
    // TODO: Is it more efficient to have a specific FFT for 2 and 3?
    if (isPow2) {
      return Radix2FFT(size);
    }
    if (size < _kNaiveThreshold) {
      return NaiveFFT(size);
    }
    if (isPrime) {
      // TODO: Don't zero pad if (size - 1) is highly composite.
      return PrimePaddedFFT(size);
    }
    return CompositeFFT(size);
  }

  static FFT _makeFFTCached(int size, bool isPow2, bool isPrime) =>
      _ffts[size] ??= _makeFFT(size, isPow2, isPrime);

  /// Constructs an FFT object with the given size.
  factory FFT(int size) {
    final isPow2 = isPowerOf2(size);
    return _makeFFTCached(size, isPow2, !isPow2 && isPrime(size));
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
    for (int m = 1; m < n;) {
      final nm = n2 ~/ m;  // TODO: Turn this into a shift.
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

abstract class _StridedFFT extends FFT {
  _StridedFFT._(int size) : super._(size);

  // Note: inp and out may or may not need to be distinct. If you don't know the
  // underlying implementation, assume they need to be distinct.
  void _stridedFft(Float64x2List inp, int istride, int ioff, Float64x2List out, int ostride, int ooff);
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
class NaiveFFT extends _StridedFFT {
  final Float64x2List _twiddles;
  final Float64x2List _buf;

  /// Constructs an FFT object with the given size.
  NaiveFFT(int size, [double woff = 0]) : _twiddles = Float64x2List(size), _buf = Float64x2List(size), super._(size) {
    final dt = -2 * math.pi / size;
    // TODO: Use reflection to halve the number of terms calculated.
    for (int i = 0; i < size; ++i) {
      final t = woff + i * dt;
      _twiddles[i] = Float64x2(math.cos(t), math.sin(t));
    }
  }

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, 1, 0, _buf, 1, 0);
    complexArray.setAll(0, _buf);
  }

  // Note: inp and out must be distinct.
  @override
  void _stridedFft(Float64x2List inp, int istride, int ioff, Float64x2List out, int ostride, int ooff) {
    final x0 = inp[ioff];
    for (int io = ooff, st = 0; st < _size; io += ostride, ++st) {
      out[io] = x0;
    }
    ioff += istride;
    for (int ii = ioff, ji = 1; ji < _size; ii += istride, ++ji) {
      final p = inp[ii];
      for (int io = ooff, jj = 0, k = 0; k < _size; io += ostride, jj += ji, ++k) {
        out[io] += compMul(p, _twiddles[jj % _size]);
      }
    }
  }

  void _stridedFft2(Float64x2List inp, int istride, int ioff, Float64x2List out, int ostride, int ooff, int wn, int wi, int wns) {
    final x0 = inp[ioff];
    for (int io = ooff, st = 0; io < out.length; io += ostride, ++st) {
      out[io] = x0;
    }
    ioff += istride;
    for (int ii = ioff, ji = 1; ji < _size; ii += istride, ++ji) {
      final p = compMul(inp[ii], twiddle(wn, ji * wi));
      for (int io = ooff, jj = 0, k = 0; k < _size; io += ostride, jj += ji, ++k) {
        out[io] += compMul(p, _twiddles[jj % _size]);
      }
    }
  }
}
int _qtotal = 0;

class _CompositeFFTJob {
  final Float64x2List buf;
  final Float64x2List out;
  final int n;
  final int s;
  final int nn;
  final int i;
  final int bi;
  final NaiveFFT fft;
  _CompositeFFTJob(this.buf, this.out, this.n, this.s, this.nn, this.i, this.bi)
      //: fft = FFT._makeFFTCached(s, false, true) as NaiveFFT;
      : fft = NaiveFFT(s, 2 * math.pi * i * 0) {
  }
  void run() {
    fft._stridedFft2(buf, nn, bi, out, nn, bi, n, i, n ~/ fft._size);
    //fft._stridedFft(buf, nn, bi, out, nn, bi);
  }
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
class CompositeFFT extends FFT {
  final Float64x2List _buf;
  final Float64x2List _out;
  late final Float64x2List _innerBuf;
  final Uint64List _perm;
  final _ffts = <List<_CompositeFFTJob>>[];

  /// Constructs an FFT object with the given size.
  CompositeFFT(int size) : _buf = Float64x2List(size), _out = Float64x2List(size), _perm = Uint64List(size), super._(size) {
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
      ffts.add(_CompositeFFTJob(buf, out, n, s, nn, i, bi));
    }
  }

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    //Float64x2List w = Float64x2List(_size);
    //for (int i = 0; i < _size; ++i) w[i] = twiddle(_size, i);
    //_inPlaceFftRecursive(complexArray, _buf, _out, w, _size, 1, 0, 0, 0);

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

  /*void _inPlaceFftRecursive(Float64x2List input, Float64x2List buf, Float64x2List out, Float64x2List w, int n, int stride, int off, int boff, int di) {
    // https://doi.org/10.1090/S0025-5718-1965-0178586-1
    if (di >= _ffts.length) {
      out[boff] = input[off];
      return;
    }
    final fft = _ffts[di];
    final s = fft.size;
    final ss = s * stride;
    final nn = n ~/ s;
    for (int i = 0; i < s; ++i) {
      _inPlaceFftRecursive(input, out, buf, w, nn, ss, i * stride + off, boff + i * nn, di + 1);
    }
    for (int i = 0; i < nn; ++i) {
      final bi = boff + i;
      fft._stridedFft2(buf, nn, bi, out, nn, bi, twiddle(n, i));
    }
  }*/
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
///
/// The size must be a prime number, eg 2, 3, 5, 7, 11 etc.
class PrimePaddedFFT extends _StridedFFT {
  // TODO: Is Bluestein's algorithm faster?
  final int _g;
  final int _pn;
  final Float64x2List _a;
  final Float64x2List _b;
  final Radix2FFT _fft;

  PrimePaddedFFT._(int size, int pn) :
      _g = primitiveRootOfPrime(size),
      _pn = pn,
      _a = Float64x2List(pn),
      _b = Float64x2List(pn),
      _fft = FFT._makeFFTCached(pn, true, false) as Radix2FFT,
      super._(size) {
    final n_ = size - 1;
    for (int q = 0; q < n_; ++q) {
      final j = multiplicativeInverseOfPrime(expMod(_g, q, size), size);
      _b[q] = twiddle(size, j);
    }
    _fft._inPlaceFftImpl(_b);
  }

  /// Constructs an FFT object with the given size.
  ///
  /// The size must be a prime number, eg 2, 3, 5, 7, 11 etc.
  PrimePaddedFFT(int size) : this._(size, nextPowerOf2((size - 1) << 1));

  @override
  void _inPlaceFftImpl(Float64x2List complexArray) {
    _stridedFft(complexArray, 1, 0, complexArray, 1, 0);
  }

  // Note: inp and out don't have to be distinct.
  @override
  void _stridedFft(Float64x2List inp, int istride, int ioff, Float64x2List out, int ostride, int ooff) {
    // https://doi.org/10.1109/PROC.1968.6477
    // Primitive root permutation.
    final n_ = _size - 1;
    for (int q = 0; q < n_; ++q) {
      final i = expMod(_g, q, _size);
      _a[q] = inp[i * istride + ioff];
    }
    _a.fillRange(n_, _a.length, Float64x2.zero());

    // Cyclic convolution.
    _fft._inPlaceFftImpl(_a);
    for (int i = 0; i < _pn; ++i) {
      _a[i] = compMul(_a[i], _b[i]);
    }
    _fft.inPlaceInverseFft(_a);

    // Unpermute and store in out.
    final x0 = inp[ioff];
    out[ooff] = x0;
    for (int q = 0; q < n_; ++q) {
      final i = multiplicativeInverseOfPrime(expMod(_g, q, _size), _size);

      // First output is just the sum of all the inputs.
      out[ooff] += inp[i * istride + ioff];

      // Rest of the outputs are made by wrapping and summing the unpermuted
      // convolution with the first element of the input.
      final oi = i * ostride + ooff;
      out[oi] = x0;
      for (int j = q; j < _pn; j += n_) {
        out[oi] += _a[j];
      }
    }
  }
}

// TODO: Get rid of this function.
Float64x2 compMul(Float64x2 a, Float64x2 b) {
  return Float64x2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

// TODO: Get rid of this function.
Float64x2 rotor(double t) => Float64x2(math.cos(t), math.sin(t));
Float64x2 twiddle(int n, int k) => rotor(-2 * math.pi * k / n);

Float64x2List compositeFft(Float64x2List input) {
  final n = input.length;
  Float64x2List out = Float64x2List(n);
  Float64x2List buf = Float64x2List(n);
  Float64x2List w = Float64x2List(n);
  for (int i = 0; i < n; ++i) w[i] = twiddle(n, i);
  compositeFftImpl(input, buf, out, w, n, 1, 0, 0, primeDecomp(n), 0);
  return out;
}

int _ptotal = 0;
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
  if (_ptotal < 20) print('$n,\t$stride,\t$off,\t$boff,\t$di,\t$s,\t$ss,\t$nn');
  for (int i = 0; i < nn; ++i) {
    final bi = boff + i;
    if (_ptotal < 20) print('$i,\t$bi');
    for (int j = 0; j < s; ++j) {
      out[bi + j * nn] = buf[bi];
    }
    for (int j = 1; j < s; ++j) {
      final p = buf[bi + j * nn];
      for (int k = 0; k < s; ++k) {
        final wi = stride * ((j * (k * nn + i)) % n);
        if (_ptotal < 20) {
          ++_ptotal;
          print('$stride,\t$j,\t$k,\t$nn,\t$i,\t$n,\t$wi');
        }
        out[bi + k * nn] += compMul(p, w[wi]);
      }
    }
  }
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
