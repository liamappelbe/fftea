// Copyright 2023 The fftea authors
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

import 'dart:typed_data';

import 'impl.dart' show FFT;
import 'util.dart' show ComplexArray;

/// Resamples the [input] audio to the given [outputLength].
///
/// Returns a new array of length [outputLength] containing the resampled
/// [input]. Doesn't modify the input array.
///
/// This function FFTs the input, truncates or zero pads the frequencies to the
/// output length, then IFFTs to get the output. This isn't the best way of
/// resampling audio. It's intended to be simple and good enough for most
/// purposes. A more typical approach is convolution with a windowed sinc
/// function, which will often be more efficient and produce better results, but
/// requires a bit more design work to match the parameters to the use case. If
/// you just want something that works well enough, this function is a good
/// starting point.
Float64List resample(List<double> input, int outputLength) {
  if (input.length == outputLength) {
    return Float64List.fromList(input);
  }
  final inf = FFT(input.length).realFft(input).discardConjugates();
  final outflen = ComplexArray.discardConjugatesLength(outputLength);
  late Float64x2List outf;
  if (outflen < inf.length) {
    // Truncate.
    outf = Float64x2List.sublistView(inf, 0, outflen);
  } else {
    // Zero pad.
    outf = Float64x2List(outflen);
    for (int i = 0; i < inf.length; ++i) {
      outf[i] = inf[i];
    }
  }
  final out =
      FFT(outputLength).realInverseFft(outf.createConjugates(outputLength));
  // Resampling like this changes the amplitude, so we need to fix that.
  final ratio = outputLength.toDouble() / input.length;
  for (int i = 0; i < out.length; ++i) {
    out[i] *= ratio;
  }
  return out;
}

/// Resamples the [input] audio by the given sampling [ratio]. If [ratio] > 1
/// the result will have more samples.
///
/// See [resample] for more information.
Float64List resampleByRatio(List<double> input, double ratio) =>
    resample(input, (input.length * ratio).round());

/// Resamples the [input] audio from [inputSampleRate] to [outputSampleRate].
///
/// See [resample] for more information.
Float64List resampleByRate(
  List<double> input,
  double inputSampleRate,
  double outputSampleRate,
) =>
    resampleByRatio(input, outputSampleRate / inputSampleRate);
