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

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:wav/wav.dart';

// Displays a spectrogram of the input audio, using STFT.
//
// To generate the spectrogram, we break the audio into small chunks, FFT the
// chunk to get frequency, divide the frequencies into buckets, and print a
// character indicating the power of that frequency bucket. A darker shading
// means that group of frequencies is louder at that time. Time goes from top
// top bottom, with low frequencies on the left and high on the right.
//
// https://en.wikipedia.org/wiki/Spectrogram
void main(List<String> argv) async {
  if (argv.length != 1) {
    print('Wrong number of args. Usage:');
    print('  dart run spectrogram.dart test.wav');
    return;
  }

  // Load the user's WAV file and normalize its volume.
  final wav = await Wav.readFile(argv[0]);
  final audio = normalizeRmsVolume(wav.toMono(), 0.3);

  // Set up the STFT. The chunk size is the number of audio samples in each
  // chunk to be FFT'd. The buckets is the number of frequency buckets to
  // split the resulting FFT into when printing.
  const chunkSize = 2048;
  final stft = STFT(chunkSize, Window.hanning(chunkSize));
  const buckets = 120;

  // STFT divides the input into chunks, and runs an FFT on all the chunks.
  stft.run(
    audio,
    // This callback is called for each FFT'd chunk.
    (Float64x2List chunk) {
      // FFTs of real valued data contain a lot of redundant frequency data that
      // we don't want to see in our spectrogram, so discard it. See
      // [ComplexArray.discardConjugates] for more info. We also don't care
      // about the phase of the frequencies, just the amplitude, so calculate
      // magnitudes.
      final amp = chunk.discardConjugates().magnitudes();

      for (int bucket = 0; bucket < buckets; ++bucket) {
        // Calculate the bucket endpoints.
        int start = (amp.length * bucket) ~/ buckets;
        int end = (amp.length * (bucket + 1)) ~/ buckets;

        // RMS works in the frequency domain too. This is essentially
        // calculating what the perceived volume would be if we were only
        // listening to this frequency bucket. Technically there are some
        // scaling factors I'm ignoring.
        // https://en.wikipedia.org/wiki/Root_mean_square#In_frequency_domain
        double power = rms(Float64List.sublistView(amp, start, end));

        stdout.write(gradient(power));
      }
      stdout.write('\n');
    },
    // Stride by half the chunk size, so that the chunks overlap.
    chunkSize ~/ 2,
  );
}

// Calculates the RMS volume of the audio. This is a decent approxiation of
// human perception of loudness.
// https://en.wikipedia.org/wiki/Root_mean_square
double rms(List<double> audio) {
  if (audio.isEmpty) {
    return 0;
  }
  double squareSum = 0;
  for (final x in audio) {
    squareSum += x * x;
  }
  return math.sqrt(squareSum / audio.length);
}

// Returns a copy of the input audio, with the amplitude adjusted so that the
// RMS volume of the result is set to the target.
Float64List normalizeRmsVolume(List<double> audio, double target) {
  double factor = target / rms(audio);
  final output = Float64List.fromList(audio);
  for (int i = 0; i < audio.length; ++i) {
    output[i] *= factor;
  }
  return output;
}

// Converts audio power into a unicode gradient for printing.
String gradient(double power) {
  const scale = 2;
  const levels = [' ', '░', '▒', '▓', '█'];
  int index = math.log((power * levels.length) * scale).floor();
  if (index < 0) index = 0;
  if (index >= levels.length) index = levels.length - 1;
  return levels[index];
}
