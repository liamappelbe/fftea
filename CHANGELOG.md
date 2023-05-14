## 1.4.0-dev

- Added ComplexArray.createConjugates.

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
