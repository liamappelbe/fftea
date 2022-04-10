# fftea

[![Build Status](https://github.com/liamappelbe/fftea/workflows/CI/badge.svg)](https://github.com/liamappelbe/fftea/actions?query=workflow%3ACI+branch%3Amain)

A simple and efficient FFT implementation.

Supports FFT of power-of-two sized arrays of real or complex numbers, using the
Cooley-Tukey algorithm. Also includes some related utilities, such as windowing
functions, STFT, and inverse FFT.

This package was built because package:fft is not actively maintained anymore,
and wasn't a particularly efficient implementation. There are a few
improvements that make this implementation more efficient:

- The main FFT class is constructed with a given size, so that the twiddle
  factors only have to be calculated once. This is particularly handy for STFT.
- Doesn't use a wrapper class for complex numbers, just uses an array of doubles
  with elements alternating: `[real0, imag0, real1, imag1...]`. Every little
  wrapper class is a seperate allocation and dereference. For inner loop code,
  like FFT's complex number math, this makes a big difference.
- FFT algorithm is in-place, so no additional arrays are allocated.
- Loop based FFT, rather than recursive.
- Using trig tricks to only calculate a quarter of the twiddle factors.

## Usage

```dart
List<double> myData = ...;
// myData.length must be a power of two. Eg 2, 4, 8, 16, ...
final fft = FFT(myData.length);
final freq = fft.realFft(myData);
```

## Benchmarks

I found some other promising FFT implementations, so I decided to benchmark them
too: scidart, and smart_signal_processing.

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
is not included in the benchmark.

| Size | package:fft | smart | smart, in-place | scidart | scidart, in-place* | fftea | fftea, cached | fftea, in-place, cached |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | 497.2 us | 26.8 us | 6.7 us | 445.9 us | 117.5 us | 22.0 us | 3.5 us | 3.0 us |
| 64 | 439.2 us | 2.5 us | 1.9 us | 255.3 us | 174.4 us | 32.4 us | 29.0 us | 20.9 us |
| 256 | 307.2 us | 7.3 us | 6.2 us | 594.3 us | 573.1 us | 10.4 us | 4.3 us | 3.7 us |
| 2^10 | 1.13 ms | 27.9 us | 25.2 us | 6.37 ms | 6.29 ms | 26.1 us | 19.8 us | 17.7 us |
| 2^12 | 5.23 ms | 114.4 us | 107.8 us | 94.11 ms | 92.03 ms | 99.6 us | 89.3 us | 82.0 us |
| 2^14 | 27.98 ms | 635.4 us | 527.7 us | 1.47 s | 1.47 s | 498.5 us | 464.9 us | 391.0 us |
| 2^16 | 151.57 ms | 3.47 ms | 2.98 ms | 29.96 s | 29.84 s | 2.37 ms | 2.15 ms | 1.90 ms |
| 2^18 | 786.77 ms | 17.12 ms | 22.59 ms | Skipped | Skipped | 12.38 ms | 10.78 ms | 9.05 ms |
| 2^20 | 4.39 s | 99.34 ms | 74.18 ms | Skipped | Skipped | 55.19 ms | 51.97 ms | 48.79 ms |

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
