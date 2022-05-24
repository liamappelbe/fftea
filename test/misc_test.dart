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

import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:test/test.dart';

void main() {
  test('FFT.frequency', () {
    final fft = FFT(16);
    expect(fft.frequency(0, 32), 0);
    expect(fft.frequency(1, 32), 2);
    expect(fft.frequency(2, 32), 4);
    expect(fft.frequency(8, 32), 16);
    expect(fft.frequency(2, 4), 0.5);
  });

  test('STFT.frequency', () {
    final stft = STFT(64);
    expect(stft.frequency(0, 32), 0);
    expect(stft.frequency(1, 32), 0.5);
    expect(stft.frequency(2, 32), 1);
    expect(stft.frequency(8, 32), 4);
    expect(stft.frequency(32, 1024), 512);
  });

  test('FFT input data wrong length', () {
    final fft = FFT(16);
    expect(() => fft.inPlaceFft(Float64x2List(16)), returnsNormally);
    expect(
      () => fft.inPlaceFft(Float64x2List(8)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'Input data is the wrong length.',
        ),
      ),
    );
    expect(
      () => fft.inPlaceFft(Float64x2List(64)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'Input data is the wrong length.',
        ),
      ),
    );
  });

  test('Window input data wrong length', () {
    final window = Window.hanning(47);
    expect(() => window.inPlaceApplyWindow(Float64x2List(47)), returnsNormally);
    expect(
      () => window.inPlaceApplyWindow(Float64x2List(32)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'Input data is the wrong length.',
        ),
      ),
    );
    expect(
      () => window.inPlaceApplyWindow(Float64x2List(1024)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'Input data is the wrong length.',
        ),
      ),
    );
  });

  test('Window real input data wrong length', () {
    final window = Window.hanning(47);
    expect(
      () => window.inPlaceApplyWindowReal(Float64List(47)),
      returnsNormally,
    );
    expect(
      () => window.inPlaceApplyWindowReal(Float64List(32)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'Input data is the wrong length.',
        ),
      ),
    );
    expect(
      () => window.inPlaceApplyWindowReal(Float64List(1024)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'Input data is the wrong length.',
        ),
      ),
    );
  });

  test('STFT window wrong length', () {
    expect(() => STFT(64), returnsNormally);
    expect(() => STFT(64, Window.blackman(64)), returnsNormally);
    expect(
      () => STFT(64, Window.blackman(32)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message ==
                  'Window must have the same length as the chunk size.',
        ),
      ),
    );
    expect(
      () => STFT(64, Window.blackman(128)),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message ==
                  'Window must have the same length as the chunk size.',
        ),
      ),
    );
  });
}
