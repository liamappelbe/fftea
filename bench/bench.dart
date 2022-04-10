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

import 'dart:math';
import 'dart:typed_data';
import 'package:fft/fft.dart' as fft;
import 'package:fftea/fftea.dart' as fftea;
import 'package:scidart/numdart.dart' as numdart;
import 'package:scidart/scidart.dart' as scidart;
import 'package:smart_signal_processing/src/fft.dart' as smart;

class TestTimer {
  final _watch = Stopwatch();
  int _runs = 0;

  void start() {
    ++_runs;
    _watch.start();
  }

  void stop() {
    _watch.stop();
  }

  @override
  String toString() {
    if (_runs == 0) return 'Skipped';
    final micros = _watch.elapsedMicroseconds / _runs;
    if (micros > 1e6) return '${(micros / 1e6).toStringAsFixed(2)} s';
    if (micros > 1e3) return '${(micros / 1e3).toStringAsFixed(2)} ms';
    return '${micros.toStringAsFixed(1)} us';
  }
}

const kTestRuns = 30;

void bench(int sizeLog2) {
  final size = 1 << sizeLog2;
  final inp = Float64List(size);
  final rand = Random();
  for (var i = 0; i < size; ++i) {
    inp[i] = 2 * rand.nextDouble() - 1;
  }

  final ffteaFFTCached = fftea.FFT(size);
  final fftTimer = TestTimer();
  final smartTimer = TestTimer();
  final smartInPlaceTimer = TestTimer();
  final scidartTimer = TestTimer();
  final scidartInPlaceTimer = TestTimer();
  final ffteaTimer = TestTimer();
  final ffteaCachedTimer = TestTimer();
  final ffteaInPlaceCachedTimer = TestTimer();

  for (var i = 0; i < kTestRuns; ++i) {
    // package:fft
    {
      fftTimer.start();
      fft.FFT().Transform(inp);
      fftTimer.stop();
    }

    // package:smart_signal_processing
    {
      smartTimer.start();
      final imag = Float64List(size);
      smart.FFT.transform(inp, imag);
      smartTimer.stop();
    }

    // package:smart_signal_processing, in-place
    {
      final imag = Float64List(size);
      smartInPlaceTimer.start();
      smart.FFT.transform(inp, imag);
      smartInPlaceTimer.stop();
    }

    // Scidart is too slow, so only do one run on the medium inputs, and don't
    // run it on the larger inputs.
    if (size < 3000 || (i == 0 && size < 100000)) {
      // package:scidart
      {
        scidartTimer.start();
        final cplx = numdart.ArrayComplex(
          List.from(inp.map((x) => numdart.Complex(real: x))),
        );
        scidart.fft(cplx);
        scidartTimer.stop();
      }

      // package:scidart, in-place
      {
        final cplx = numdart.ArrayComplex(
          List.from(inp.map((x) => numdart.Complex(real: x))),
        );
        scidartInPlaceTimer.start();
        scidart.fft(cplx);
        scidartInPlaceTimer.stop();
      }
    }

    // fftea
    {
      ffteaTimer.start();
      fftea.FFT(size).realFft(inp);
      ffteaTimer.stop();
    }

    // fftea, cached
    {
      ffteaCachedTimer.start();
      ffteaFFTCached.realFft(inp);
      ffteaCachedTimer.stop();
    }

    // fftea, in-place, cached
    {
      final cplxInp = fftea.ComplexArray.fromRealArray(inp);
      ffteaInPlaceCachedTimer.start();
      ffteaFFTCached.inPlaceFft(cplxInp);
      ffteaInPlaceCachedTimer.stop();
    }
  }

  final sizeStr = sizeLog2 < 10 ? '$size' : '2^$sizeLog2';
  print(
    '| $sizeStr | $fftTimer | $smartTimer | $smartInPlaceTimer | '
    '$scidartTimer | $scidartInPlaceTimer | $ffteaTimer | '
    '$ffteaCachedTimer | $ffteaInPlaceCachedTimer |',
  );
}

void main() {
  print(
    '| Size | package:fft | smart | smart, in-place | scidart | '
    'scidart, in-place* | fftea | fftea, cached | fftea, in-place, cached |',
  );
  print('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  bench(4);
  bench(6);
  bench(8);
  bench(10);
  bench(12);
  bench(14);
  bench(16);
  bench(18);
  bench(20);
}
