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
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

class Wav {
  final int sampleRate;
  final List<Float64List> channels;
  Wav._(this.sampleRate, this.channels);

  static Wav read(Uint8List bytes) {
    int p = 0;
    ByteData read(int n) {
      final b = ByteData.sublistView(bytes, p, p + n);
      p += n;
      return b;
    }

    int readU8() => (read(1)).getUint8(0);
    int readU16() => (read(2)).getUint16(0, Endian.little);
    int readU32() => (read(4)).getUint32(0, Endian.little);
    int readU24() => readU8() + 0x100 * readU16();
    void checkString(String str) {
      final s = String.fromCharCodes(Uint8List.sublistView(read(str.length)));
      if (s != str) {
        throw FormatException('WAV is corrupted, or not a WAV file.');
      }
    }

    checkString('RIFF');
    readU32(); // File size.
    checkString('WAVE');
    checkString('fmt ');
    readU32(); // Format block size.
    final format = readU16();
    if (format != 1 /* PCM */) {
      throw FormatException('WAV is not using PCM format.');
    }
    final numChannels = readU16();
    if (numChannels < 1) {
      throw FormatException('WAV has no channels.');
    }
    final sampleRate = readU32();
    readU32(); // Bytes per second.
    final bytesPerSample = readU16();
    final bitsPerSamplePerChannel = readU16();
    checkString('data');
    final dataSize = readU32();
    final numSamples = dataSize ~/ bytesPerSample;
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(numSamples));
    }
    int Function()? readSample = (bitsPerSamplePerChannel == 8)
        ? readU8
        : (bitsPerSamplePerChannel == 16)
            ? readU16
            : (bitsPerSamplePerChannel == 24)
                ? readU24
                : (bitsPerSamplePerChannel == 32)
                    ? readU32
                    : null;
    if (readSample == null) {
      throw FormatException(
        'WAV has unsupported bits per sample. Must be 8, 16, 24, or 32.',
      );
    }
    final div = (1 << (bitsPerSamplePerChannel - 1)) * 1.0;
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        channels[j][i] = readSample() / div;
      }
    }
    if (p != bytes.length) {
      throw FormatException('WAV has leftover bytes');
    }
    return Wav._(sampleRate, channels);
  }

  Float64List toMono() {
    final mono = Float64List(channels[0].length);
    for (int i = 0; i < mono.length; ++i) {
      for (int j = 0; j < channels.length; ++j) {
        mono[i] += channels[j][i];
      }
      mono[i] /= channels.length;
    }
    return mono;
  }
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
  const maxPower = 20.0;
  const levels = [' ', '░', '▒', '▓', '█'];
  int index = (power * levels.length) ~/ maxPower;
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
  final wav = Wav.read(await File(argv[0]).readAsBytes());
  final audio = wav.toMono();
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
