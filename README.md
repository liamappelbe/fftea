# fftea

A simple and efficient FFT implementation.

Supports FFT of power-of-two sized arrays of real or complex numbers, using the
Cooley-Tukey algorithm. Also includes some related utilities, such as windowing
functions, STFT, and inverse FFT.

This package was built because package:fft is not actively maintained anymore,
and wasn't a particularly efficient implementation. There are a few
improvements that make this implementation more effienct:

- The main FFT class is constructed with a given size, so that the twiddle
  factors only have to be calculated once. This is particularly handy for STFT.
- Doesn't use a wrapper class for complex numbers, just uses an array of doubles
  with elements alternating: `[real0, imag0, real1, imag1...]`. Every little
  wrapper class is a seperate allocation and dereference. For inner loop code,
  like FFT's complex number math, this makes a big difference.
- FFT algorithm is in-place, so no additional arrays are allocated.
- Loop based FFT, rather than recursive.

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

| Size | package:fft | package:fft, cached | smart | smart, in-place | scidart | scidart, in-place* | fftea | fftea, cached | fftea, in-place | fftea, in-place, cached |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | 1.77 ms | 359.5 us | 143.0 us | 28.2 us | 1.73 ms | 444.8 us | 148.7 us | 18.8 us | 21.1 us | 16.5 us |
| 64 | 1.65 ms | 1.39 ms | 49.5 us | 55.2 us | 1.15 ms | 1.05 ms | 131.9 us | 184.5 us | 125.6 us | 112.6 us |
| 256 | 1.89 ms | 1.79 ms | 26.6 us | 20.0 us | 2.38 ms | 2.05 ms | 44.0 us | 21.3 us | 30.7 us | 15.1 us |
| 1024 | 3.35 ms | 3.10 ms | 78.5 us | 71.2 us | 16.79 ms | 16.73 ms | 99.2 us | 78.7 us | 87.0 us | 70.1 us |
| 4096 | 11.33 ms | 11.45 ms | 294.0 us | 271.5 us | 213.92 ms | 215.16 ms | 346.8 us | 283.8 us | 320.8 us | 257.1 us |
| 16384 | 59.59 ms | 61.38 ms | 1.48 ms | 1.25 ms | 3.23 s | 3.22 s | 1.78 ms | 1.27 ms | 1.49 ms | 1.12 ms |
| 65536 | 332.65 ms | 349.81 ms | 8.26 ms | 7.58 ms | 67.70 s | 67.75 s | 7.05 ms | 5.87 ms | 6.37 ms | 5.28 ms |

* Scidart's FFT doesn't have an in-place mode, but they do use a custom format,
so in-place means that the time to convert to that format is not included in the
benchmark.

In practice, you usually know how big your FFT is ahead of time, so it's pretty
easy to construct your FFT object once, to take advantage of the caching. It's
sometimes possible to take advantage of the in-place speed up too, for example
if you have to copy your data from another source anyway you may as well
construct the flat complex array yourself. Since this isn't always possible,
the "fftea, cached" times are probably the most representative. In that case,
fftea is about 30-40x faster than package:fft, and about 30% faster than
smart_signal_processing. Not sure what's going on with scidart, but it seems to
be O(n^2).
