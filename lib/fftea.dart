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

/// Returns whether x is a power of two: 1, 2, 4, 8, ...
bool isPowerOf2(int x) => (x > 0) && ((x & (x - 1)) == 0);

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
    return Float64x2List.sublistView(this, 0, (length >> 1) + 1);
  }
}

/// Performs FFTs (Fast Fourier Transforms) of a particular size.
///
/// The size must be a power of two, eg 1, 2, 4, 8, 16 etc.
class FFT {
  final Float64x2List _twiddles;
  final int _size;

  /// Constructs an FFT object with the given size.
  ///
  /// The size must be a power of two, eg 1, 2, 4, 8, 16 etc.
  FFT(int powerOf2Size)
      : _twiddles = _calculateTwiddles(powerOf2Size),
        _size = powerOf2Size;

  /// The size of the FFTs that this object can do.
  int get size => _size;

  static Float64x2List _calculateTwiddles(int powerOf2Size) {
    if (!isPowerOf2(powerOf2Size)) {
      throw ArgumentError('FFT size must be a power of 2.', 'powerOf2Size');
    }
    if (powerOf2Size <= 1) return Float64x2List.fromList([]);
    if (powerOf2Size == 2) return Float64x2List.fromList([Float64x2(1, 0)]);
    if (powerOf2Size == 4) {
      return Float64x2List.fromList([Float64x2(1, 0), Float64x2(0, 1)]);
    }
    final half = powerOf2Size >> 1;
    final twiddles = Float64x2List(half);
    twiddles[0] = Float64x2(1, 0);
    final step = 2 * math.pi / powerOf2Size;
    final quarter = half >> 1;
    final eighth = quarter >> 1;
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
    final n2 = n >> 1;
    for (int i = 0; i < n; ++i) {
      // Calculate bit reversal.
      int j = 0;
      for (int nn = n2, ii = i; nn > 0; nn >>= 1, ii >>= 1) {
        j = (j << 1) | (ii & 1);
      }
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
    final half = len >> 1;
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
    final half = a.length >> 1;
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
    final half = size >> 1;
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
    final half = size >> 1;
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
    final half = size >> 1;
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
