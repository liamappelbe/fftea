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

import 'impl.dart';

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

  static Float64List _makeWindow(int size, double Function(int) fn) {
    final a = Float64List(size);
    if (size == 1) {
      a[0] = 1;
      return a;
    }
    final half = size >>> 1;
    final n = size - 1;
    for (int i = 0; i <= half; ++i) {
      a[i] = fn(i);
    }
    for (int i = 0; i < half; ++i) {
      a[n - i] = a[i];
    }
    return a;
  }

  /// Returns a cosine window, such as Hanning or Hamming.
  ///
  /// `w[i] = 1 - amp - amp * cos(2πi / (size - 1))`
  static Float64List cosine(int size, double amplitude) {
    final offset = 1 - amplitude;
    final scale = 2 * math.pi / (size - 1);
    return _makeWindow(size, (i) => offset - amplitude * math.cos(scale * i));
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
    final offset = (size - 1) / 2;
    return _makeWindow(size, (i) => 1 - (i / offset - 1).abs());
  }

  /// Returns a Blackman window.
  ///
  /// This is a more elaborate kind of cosine window.
  /// `w[i] = 0.42 - 0.5 * cos(2πi / (size - 1)) + 0.08 * cos(4πi / (size - 1))`
  static Float64List blackman(int size) {
    final scale = 2 * math.pi / (size - 1);
    return _makeWindow(size, (i) {
      final t = i * scale;
      return 0.42 - 0.5 * math.cos(t) + 0.08 * math.cos(2 * t);
    });
  }
}

/// Performs STFTs (Short-time Fourier Transforms).
///
/// STFT breaks up the input into overlapping chunks, applies an optional
/// window, and runs an FFT. This is also known as a spectrogram.
class STFT {
  final FFT _fft;
  final Float64List? _win;
  final Float64x2List _chunk;
  Float64x2List? _scratch;
  int _chunkIndex = 0;

  /// Constructs an STFT object of the given size, with an optional windowing
  /// function.
  STFT(int chunkSize, [this._win])
      : _fft = FFT(chunkSize),
        _chunk = Float64x2List(chunkSize) {
    if (_win != null && _win!.length != chunkSize) {
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
  double frequency(int index, double samplesPerSecond) =>
      _fft.frequency(index, samplesPerSecond);

  /// Returns the index in the FFT output that corresponds to the given
  /// frequency. This is the inverse of [frequency].
  ///
  /// [samplesPerSecond] is the sampling rate of the input signal in Hz. [freq]
  /// is also in Hz. The result is a double because the target [freq] might not
  /// exactly land on an FFT index. Decide whether to round, floor, or ceil the
  /// result based on your use case.
  double indexOfFrequency(double freq, double samplesPerSecond) =>
      _fft.indexOfFrequency(freq, samplesPerSecond);

  /// Runs STFT on [input].
  ///
  /// The input is broken up into chunks, windowed, FFT'd, and then passed to
  /// [reportChunk]. If there isn't enough data in the input to fill the final
  /// chunk, it is padded with zeros. Does not allocate any arrays.
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
  ]) =>
      _run(input, reportChunk, chunkStride, false);

  /// Runs STFT on [input]. This method is the same as [run], but instead of
  /// zero padding the input to fill the final chunk, it holds on to the excess
  /// data until the next time it is called.
  void stream(
    List<double> input,
    Function(Float64x2List) reportChunk, [
    int chunkStride = 0,
  ]) =>
      _run(input, reportChunk, chunkStride, true);

  /// Runs STFT on any remaining input in the buffer. Use after a series of
  /// calls to [stream] to zero pad and clear the buffer.
  void flush(Function(Float64x2List) reportChunk) =>
      _run([], reportChunk, 0, false);

  void _run(
    List<double> input,
    Function(Float64x2List) reportChunk,
    int chunkStride,
    bool streamed,
  ) {
    // If there's no input, do nothing, unless we're trying to flush and there's
    // data to be flushed.
    if (input.length == 0 && (streamed || _chunkIndex == 0)) return;

    final chunkSize = _fft.size;
    if (chunkStride <= 0) chunkStride = chunkSize;
    final chunkOverlap = chunkSize - chunkStride;

    // i indexes into input, _chunkIndex indexes into _chunk.
    for (int i = 0;;) {
      final i2 = i + chunkSize - _chunkIndex;
      if (i2 > input.length) {
        int j = 0;
        final stop = input.length - i;
        for (; j < stop; ++j) {
          _chunk[_chunkIndex] = Float64x2(input[i + j], 0);
          _chunkIndex = (_chunkIndex + 1) % chunkSize;
        }
        if (streamed) return;
        for (; j < chunkSize; ++j) {
          _chunk[_chunkIndex] = Float64x2.zero();
          _chunkIndex = (_chunkIndex + 1) % chunkSize;
        }
      } else {
        for (int j = 0; j < chunkSize; ++j) {
          _chunk[_chunkIndex] = Float64x2(input[i + j], 0);
          _chunkIndex = (_chunkIndex + 1) % chunkSize;
        }
      }
      i = i2 - chunkOverlap;
      // TODO: Handle the case where i is now negative.
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
  /// isn't as efficient as run (this method allocated a lot of arrays). See
  /// [run] for more details.
  List<Float64x2List> runAndCopy(List<double> input, [int chunkStride = 0]) {
    final o = <Float64x2List>[];
    run(input, (Float64x2List f) => o.add(f.sublist(0)), chunkStride);
    return o;
  }
}
