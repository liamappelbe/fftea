## 1.5.0+1

- Improve example documentation.

## 1.5.0

- Added an audio resampling util.

## 1.4.1

- Special case FFTs of size 4 and 5, which are base cases of composite FFT. This
  speeds up FFTs that hit them by about 10%.
- Small optimisation to primePaddingHeuristic

## 1.4.0

- Added streaming API to STFT: STFT.stream and STFT.flush.
- Added ComplexArray.createConjugates.
- Added STFT.size.

## 1.3.1

- Added FFT.indexOfFrequency and STFT.indexOfFrequency.

## 1.3.0

- Change version constraints to prep for Dart 3.

## 1.2.0

- Add linear and circular convolution functions.
- Add option to ComplexArray.fromRealArray to truncate or zero pad the array.
- Add a complex multiplication function to ComplexArray.

## 1.1.1

- Limit FFT size to 2^32, so that int literals can be small enough for JS
  compatibility.

## 1.1.0

- Add support for FFTs of any size, not just powers of two.

## 1.0.1

- Use a bit hack for bit reversal. Speeds up FFT by about 25%

## 1.0.0+3

- Improve documentation.

## 1.0.0+2

- Switch to using package:wav in example (fixes a bug in the wav reading).

## 1.0.0+1

- Improve documentation and add an example.

## 1.0.0

- Initial version
