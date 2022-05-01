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

Float64List normalizeRmsVolume(List<double> a, double target) {
  final b = Float64List.fromList(a);
  double squareSum = 0;
  for (final x in b) {
    squareSum += x * x;
  }
  double factor = target * math.sqrt(b.length / squareSum);
  for (int i = 0; i < b.length; ++i) {
    b[i] *= factor;
  }
  return b;
}

Uint64List linSpace(int end, int steps) {
  final a = Uint64List(steps);
  for (int i = 1; i < steps; ++i) {
    a[i - 1] = (end * i) ~/ steps;
  }
  a[steps - 1] = end;
  return a;
}

String gradient(double power) {
  const scale = 2;
  const levels = [' ', '░', '▒', '▓', '█'];
  int index = math.log((power * levels.length) * scale).floor();
  if (index < 0) index = 0;
  if (index >= levels.length) index = levels.length - 1;
  return levels[index];
}

void main(List<String> argv) async {
  if (argv.length != 1) {
    print('Wrong number of args. Usage:');
    print('  dart run spectrogram.dart test.wav');
    return;
  }
  final wav = await Wav.readFile(argv[0]);
  final audio = normalizeRmsVolume(wav.toMono(), 0.3);
  const chunkSize = 2048;
  const buckets = 120;
  final stft = STFT(chunkSize, Window.hanning(chunkSize));
  Uint64List? logItr;
  stft.run(
    audio,
    (Float64x2List chunk) {
      final amp = chunk.discardConjugates().magnitudes();
      logItr ??= linSpace(amp.length, buckets);
      int i0 = 0;
      for (final i1 in logItr!) {
        double power = 0;
        if (i1 != i0) {
          for (int i = i0; i < i1; ++i) {
            power += amp[i];
          }
          power /= i1 - i0;
        }
        stdout.write(gradient(power));
        i0 = i1;
      }
      stdout.write('\n');
    },
    chunkSize ~/ 2,
  );
}
