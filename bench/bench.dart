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
import 'package:scidart/scidart.dart' as scidart;
import 'package:scidart/numdart.dart' as numdart;
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
    final micros = _watch.elapsedMicroseconds / _runs;
    if (micros > 1e6) return '${(micros / 1e6).toStringAsFixed(2)} s';
    if (micros > 1e3) return '${(micros / 1e3).toStringAsFixed(2)} ms';
    return '${micros.toStringAsFixed(1)} us';
  }
}

const kTestRuns = 10;

bench(int size) {
  final inp = Float64List(size);
  final rand = Random();
  for (var i = 0; i < size; ++i) {
    inp[i] = 2 * rand.nextDouble() - 1;
  }

  final fftFFTCached = fft.FFT();
  final ffteaFFTCached = fftea.FFT(size);
  final fftTimer = TestTimer();
  final fftCachedTimer = TestTimer();
  final smartTimer = TestTimer();
  final smartInPlaceTimer = TestTimer();
  final scidartTimer = TestTimer();
  final scidartInPlaceTimer = TestTimer();
  final ffteaTimer = TestTimer();
  final ffteaCachedTimer = TestTimer();
  final ffteaInPlaceTimer = TestTimer();
  final ffteaInPlaceCachedTimer = TestTimer();

  for (var i = 0; i < kTestRuns; ++i) {
    // package:fft
    {
      fftTimer.start();
      final o = fft.FFT().Transform(inp);
      fftTimer.stop();
    }

    // package:fft, cached
    {
      fftCachedTimer.start();
      final o = fftFFTCached.Transform(inp);
      fftCachedTimer.stop();
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

    // package:scidart
    {
      scidartTimer.start();
      final cplx = numdart.ArrayComplex(List.from(inp.map(
          (x) => numdart.Complex(real: x))));
      final o = scidart.fft(cplx);
      scidartTimer.stop();
    }

    // package:scidart, in-place
    {
      final cplx = numdart.ArrayComplex(List.from(inp.map(
          (x) => numdart.Complex(real: x))));
      scidartInPlaceTimer.start();
      final o = scidart.fft(cplx);
      scidartInPlaceTimer.stop();
    }

    // fftea
    {
      ffteaTimer.start();
      final o = fftea.FFT(size).realFft(inp);
      ffteaTimer.stop();
    }

    // fftea, cached
    {
      ffteaCachedTimer.start();
      final o = ffteaFFTCached.realFft(inp);
      ffteaCachedTimer.stop();
    }

    // fftea, in-place
    {
      final cplxInp = fftea.ComplexArray.fromRealArray(inp);
      ffteaInPlaceTimer.start();
      fftea.FFT(size).inPlaceFft(cplxInp);
      ffteaInPlaceTimer.stop();
    }

    // fftea, in-place, cached
    {
      final cplxInp = fftea.ComplexArray.fromRealArray(inp);
      ffteaInPlaceCachedTimer.start();
      ffteaFFTCached.inPlaceFft(cplxInp);
      ffteaInPlaceCachedTimer.stop();
    }
  }

  print('| $size | $fftTimer | $fftCachedTimer | '
      '$smartTimer | $smartInPlaceTimer | '
      '$scidartTimer | $scidartInPlaceTimer | '
      '$ffteaTimer | $ffteaCachedTimer | '
      '$ffteaInPlaceTimer | $ffteaInPlaceCachedTimer |');
}

main() {
  print(
    '| Size | package:fft | package:fft, cached | smart | smart, in-place | '
    'scidart | scidart, in-place* | fftea | fftea, cached | '
     'fftea, in-place | fftea, in-place, cached |');
  print('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  bench(16);
  bench(64);
  bench(256);
  bench(1024);
  bench(4096);
  bench(16384);
  bench(65536);
}
