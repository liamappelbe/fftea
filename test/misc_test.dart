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
import 'package:fftea/impl.dart';
import 'package:test/test.dart';

void main() {
  test('FFT implementation selector', () {
    expect(FFT(1).toString(), 'NaiveFFT(1)');
    expect(FFT(2).toString(), 'Fixed2FFT()');
    expect(FFT(3).toString(), 'Fixed3FFT()');
    expect(FFT(4).toString(), 'NaiveFFT(4)');
    expect(FFT(5).toString(), 'NaiveFFT(5)');
    expect(FFT(6).toString(), 'NaiveFFT(6)');
    expect(FFT(7).toString(), 'NaiveFFT(7)');
    expect(FFT(8).toString(), 'NaiveFFT(8)');
    expect(FFT(9).toString(), 'NaiveFFT(9)');
    expect(FFT(10).toString(), 'NaiveFFT(10)');
    expect(FFT(11).toString(), 'NaiveFFT(11)');
    expect(FFT(12).toString(), 'NaiveFFT(12)');
    expect(FFT(13).toString(), 'NaiveFFT(13)');
    expect(FFT(14).toString(), 'NaiveFFT(14)');
    expect(FFT(15).toString(), 'NaiveFFT(15)');
    expect(FFT(16).toString(), 'Radix2FFT(16)');
    expect(FFT(17).toString(), 'NaiveFFT(17)');
    expect(FFT(18).toString(), 'NaiveFFT(18)');
    expect(FFT(19).toString(), 'NaiveFFT(19)');
    expect(FFT(20).toString(), 'NaiveFFT(20)');
    expect(FFT(21).toString(), 'NaiveFFT(21)');
    expect(FFT(22).toString(), 'NaiveFFT(22)');
    expect(FFT(23).toString(), 'NaiveFFT(23)');
    expect(FFT(24).toString(), 'CompositeFFT(24)');
    expect(FFT(25).toString(), 'CompositeFFT(25)');
    expect(FFT(25).toString(), 'CompositeFFT(25)');
    expect(FFT(26).toString(), 'CompositeFFT(26)');
    expect(FFT(27).toString(), 'CompositeFFT(27)');
    expect(FFT(28).toString(), 'CompositeFFT(28)');
    expect(FFT(29).toString(), 'PrimeFFT(29, true)');
    expect(FFT(30).toString(), 'CompositeFFT(30)');
    expect(FFT(31).toString(), 'PrimeFFT(31, true)');
    expect(FFT(32).toString(), 'Radix2FFT(32)');
    expect(FFT(33).toString(), 'CompositeFFT(33)');
    expect(FFT(34).toString(), 'CompositeFFT(34)');
    expect(FFT(35).toString(), 'CompositeFFT(35)');
    expect(FFT(36).toString(), 'CompositeFFT(36)');
    expect(FFT(37).toString(), 'PrimeFFT(37, false)');
    expect(FFT(38).toString(), 'CompositeFFT(38)');
    expect(FFT(39).toString(), 'CompositeFFT(39)');
    expect(FFT(40).toString(), 'CompositeFFT(40)');
    expect(FFT(41).toString(), 'PrimeFFT(41, false)');
    expect(FFT(42).toString(), 'CompositeFFT(42)');
    expect(FFT(43).toString(), 'PrimeFFT(43, true)');
    expect(FFT(44).toString(), 'CompositeFFT(44)');
    expect(FFT(45).toString(), 'CompositeFFT(45)');
    expect(FFT(46).toString(), 'CompositeFFT(46)');
    expect(FFT(47).toString(), 'PrimeFFT(47, true)');
    expect(FFT(48).toString(), 'CompositeFFT(48)');
    expect(FFT(49).toString(), 'CompositeFFT(49)');
    expect(FFT(50).toString(), 'CompositeFFT(50)');
  });

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

  test('FFT bad size', () {
    expect(
      () => FFT(0),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size must be greater than 0.',
        ),
      ),
    );
    expect(
      () => FFT(-123),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size must be greater than 0.',
        ),
      ),
    );
    expect(
      () => FFT(0x100000001),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size is limited to 2^32.',
        ),
      ),
    );
    expect(
      () => Radix2FFT(0),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size must be a power of 2.',
        ),
      ),
    );
    expect(
      () => Radix2FFT(-123),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size must be a power of 2.',
        ),
      ),
    );
    expect(
      () => Radix2FFT(3),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size must be a power of 2.',
        ),
      ),
    );
    expect(
      () => Radix2FFT(257),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError &&
              e.message == 'FFT size must be a power of 2.',
        ),
      ),
    );
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
