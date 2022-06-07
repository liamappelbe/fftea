# fftea

[![pub package](https://img.shields.io/pub/v/fftea.svg)](https://pub.dev/packages/fftea)
[![Build Status](https://github.com/liamappelbe/fftea/workflows/CI/badge.svg)](https://github.com/liamappelbe/fftea/actions?query=workflow%3ACI+branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/liamappelbe/fftea/badge.svg?branch=main)](https://coveralls.io/github/liamappelbe/fftea?branch=main)

A simple and efficient Fast Fourier Transform (FFT) implementation.

FFT converts a time domain signal to the frequency domain, and back again. This
is useful for all sorts of applications:

- Filtering or synthesizing audio
- Compression algorithms such as JPEG and MP3
- Computing a spectrogram (most AI applications that analyze audio use
  spectrograms)
- Convolutions, such as reverb filters for audio, or blurring filters for images

This library supports FFT of real or complex arrays of any size. It also
includes some related utilities, such as windowing functions, STFT, and inverse
FFT.

## Usage

Running a basic real-valued FFT:

```dart
// myData.length must be a power of two. Eg 2, 4, 8, 16, ...
List<double> myData = ...;

final fft = FFT(myData.length);
final freq = fft.realFft(myData);
```

`freq` is a `Float64x2List` representing a list of complex numbers. See
`ComplexArray` for helpful extension methods on `Float64x2List`.

For efficiency, avoid recreating the `FFT` object each time. Instead, create one
`FFT` object of whatever size you need, and reuse it.

Running an STFT to calculate a spectrogram:

```dart
// audio.length *doesn't* need to be a power of two. It can be any legnth.
List<double> audio = ...;

final chunkSize = 1024;  // Must be a power of two.
final stft = STFT(chunkSize, Window.hanning(chunkSize));

final spectrogram = <Float64List>[];
stft.run(audio, (Float64x2List freq) {
  spectrogram.add(freq.discardConjugates().magnitudes());
});

```

The result of a real valued FFT is about half redundant data, so
`discardConjugates` removes that data from the result (a common practice for
spectrograms):

```
[sum term, ...terms..., nyquist term, ...conjugate terms...]
 ^----- These terms are kept ------^     ^- Discarded -^
```

Then `magnitudes` discards the phase data of the complex numbers and just keeps
the amplitudes, which is usually what you want for a spectrogram.

If you want to know the frequency of one of the elements of the spectrogram, use
`stft.frequency(index, samplingFrequency)`, where `samplingFrequency` is the
frequency that `audio` was recorded at, eg 44100. The maximum frequency (aka
nyquist frequency) of the spectrogram will be
`stft.frequency(chunkSize / 2, samplingFrequency)`.

See the example for more detailed usage.

## Technical Details

Fast Fourier Transform isn't really a single algorithm. It's a family of
algorithms that all try to perform the Discreet Fourier Transform (DFT) in
O(n\*log(n)) time (a naive implementation of DFT is O(n^2)), where n is the size
of the input array. These algorithms differ mainly by what kind of array sizes
they can handle. For example, some FFT algorithms can only handle power of two
sized arrays, while others can only handle prime number sized arrays.

Many FFT libraries only support power of two arrays. The reason for this is that
it's relatively easy to implement an efficient FFT algorithm for power of two
sizes arrays, using the Cooley-Tukey algorithm.

In general, Cooley-Tukey algorithm actually works for any non-prime array size,
by breaking it down into its prime factors. Powers of two just happen to be
particularly fast and easy to implement.

This library handles arbitrary sizes by using Cooley-Tukey to break the size
into its prime factors, and then using Rader's algorithm to handle large prime
factors, or a naive O(n^2) implementation which is faster for small factors.

There's also a special Radix2FFT implementation for power of two FFTs that is
much faster than the other implementations.

Check out the various implementations of FFT in lib/impl.dart for more details.

## Benchmarks

This package was built because package:fft is not actively maintained anymore,
isn't veey efficient, and only supports power of two FFTs. This package aims to
support FFTs of any size efficiently, and to make power of two FFTs particularly
fast. There are a few improvements that make this Radix2FFT implementation
efficient:

- The main FFT class is constructed with a given size, so that the twiddle
  factors only have to be calculated once. This is particularly handy for STFT.
- Doesn't use a wrapper class for complex numbers, just uses a Float64x2List.
  Every little wrapper class is a seperate allocation and dereference. For inner
  loop code, like FFT's complex number math, this makes a big difference.
  Float64x2 can also take advantage of SIMD optimisations.
- The FFT algorithm is in-place, so no additional arrays are allocated.
- Loop based FFT, rather than recursive.
- Using trigonometric tricks to only calculate a quarter of the twiddle factors.
- Bithacks

I found some other promising Dart FFT implementations, so I decided to benchmark
them too: scidart, and smart_signal_processing. package:fft and
smart_signal_processing only support power of two arrays. Scidart supports
arrays of any size, but for other sizes they use naive DFT, which is much slower.
So for this first set of benchmarks I'm just testing power of two sizes.

To run the benchmarks:

1. Go to the bench directory and pub get, `cd bench && dart pub get`
2. Run `dart run bench.dart`

fftea gains some of its speed by caching the twiddle factors between runs, and
by doing the FFT in-place. So the benchmarks are broken out into cached and
in-place variants. Caching and running in-place is also applied to some of the
other libraries, where appropriate.

In the table below, "cached" means the construction of the FFT object is not
included in the benchmark time. And "in-place" means using the in-place FFT, and
the conversion and copying of the input data into whatever format the FFT wants
is not included in the benchmark. Run in Ubuntu on a Dell XPS 13.

| Size | package:fft | smart | smart, in-place | scidart | scidart, in-place* | fftea | fftea, cached | fftea, in-place, cached |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | 455.9 us | 32.5 us | 10.6 us | 400.8 us | 157.0 us | 86.6 us | 42.1 us | 42.9 us |
| 64 | 538.8 us | 5.3 us | 2.7 us | 274.5 us | 252.6 us | 136.4 us | 119.0 us | 102.5 us |
| 256 | 493.1 us | 12.8 us | 10.4 us | 899.1 us | 808.6 us | 96.4 us | 68.3 us | 58.0 us |
| 2^10 | 1.65 ms | 44.4 us | 43.5 us | 8.71 ms | 8.66 ms | 39.8 us | 28.6 us | 24.6 us |
| 2^12 | 7.61 ms | 188.9 us | 183.9 us | 134.41 ms | 125.13 ms | 135.2 us | 118.1 us | 108.2 us |
| 2^14 | 41.08 ms | 885.4 us | 840.5 us | 2.08 s | 2.07 s | 654.9 us | 592.3 us | 489.3 us |
| 2^16 | 242.88 ms | 5.60 ms | 5.30 ms | 45.40 s | 51.85 s | 3.65 ms | 6.77 ms | 2.57 ms |
| 2^18 | 1.21 s | 24.99 ms | 24.25 ms | Skipped | Skipped | 15.28 ms | 13.94 ms | 10.65 ms |
| 2^20 | 7.03 s | 162.97 ms | 146.55 ms | Skipped | Skipped | 95.38 ms | 101.17 ms | 73.54 ms |

In practice, you usually know how big your FFT is ahead of time, so it's pretty
easy to construct your FFT object once, to take advantage of the caching. It's
sometimes possible to take advantage of the in-place speed up too, for example
if you have to copy your data from another source anyway you may as well
construct the flat complex array yourself. Since this isn't always possible,
the "fftea, cached" times are probably the most representative. In that case,
fftea is about 60-80x faster than package:fft, and about 30% faster than
smart_signal_processing. Not sure what's going on with scidart, but it seems to
be O(n^2).

\* Scidart's FFT doesn't have an in-place mode, but they do use a custom format,
so in-place means that the time to convert to that format is not included in the
benchmark.
