# fftea

[![pub package](https://img.shields.io/pub/v/fftea.svg)](https://pub.dev/packages/fftea)
[![Build Status](https://github.com/liamappelbe/fftea/workflows/CI/badge.svg)](https://github.com/liamappelbe/fftea/actions?query=workflow%3ACI+branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/liamappelbe/fftea/badge.svg?branch=main)](https://coveralls.io/github/liamappelbe/fftea?branch=main)

A simple and efficient Fast Fourier Transform (FFT) library.

FFT converts a time domain signal to the frequency domain, and back again. This
is useful for all sorts of applications:

- Filtering or synthesizing audio
- Compression algorithms such as JPEG and MP3
- Computing a spectrogram (most AI applications that analyze audio actually do
  visual analysis of the spectrogram)
- Convolutions, such as reverb filters for audio, or blurring filters for images

This library supports FFT of real or complex arrays of any size. It also
includes some related utilities, such as windowing functions, STFT, and inverse
FFT.

## Usage

Running a basic real-valued FFT:

```dart
import 'package:fftea/fftea.dart';

List<double> myData = ...;

final fft = FFT(myData.length);
final freq = fft.realFft(myData);
```

`freq` is a `Float64x2List` representing a list of complex numbers. See
`ComplexArray` for helpful extension methods on `Float64x2List`.

Running an STFT to calculate a spectrogram:

```dart
import 'package:fftea/fftea.dart';

List<double> audio = ...;

final chunkSize = 1234;
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

Most FFT libraries only support power of two arrays. The reason for this is that
it's relatively easy to implement an efficient FFT algorithm for power of two
sizes arrays, using the Cooley-Tukey algorithm. To handle all array sizes, you
need a patchwork of different implementations for different kinds of sizes.

In general, Cooley-Tukey algorithm actually works for any non-prime array size,
by breaking it down into its prime factors. Powers of two just happen to be
particularly fast and easy to implement.

This library handles arbitrary sizes by using Cooley-Tukey to break the size
into its prime factors, and then using Rader's algorithm to handle large prime
factors, or a naive O(n^2) implementation which is faster for small factors.

There's also a special Radix2FFT implementation for power of two FFTs that is
much faster than the other implementations.

Rader's algorithm handles a prime numbered size, n, by transforming it into an
FFT of size n - 1, which is non-prime, so can be handled by Cooley-Tukey.
Alternatively, the n - 1 FFT can be zero padded up to a power two, which is
usually faster because the special Radix2FFT can be used. See the
`primePaddingHeuristic` function.

There are also a few special implementations for handling fixed sized FFTs of
very small sizes. There's never really a practical use case for an FFT of size
2 or 3, but these form the base cases of Cooley-Tukey, and make larger FFTs
much faster.

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
- Using trigonometric tricks to calculate fewer twiddle factors.
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
| 16 | 424.4 us | 33.5 us | 23.3 us | 359.8 us | 133.6 us | 71.0 us | 48.2 us | 38.7 us |
| 64 | 657.7 us | 7.6 us | 2.9 us | 310.2 us | 271.8 us | 136.8 us | 134.6 us | 103.5 us |
| 256 | 614.1 us | 15.5 us | 11.1 us | 984.9 us | 1.02 ms | 100.3 us | 51.9 us | 38.3 us |
| 2^10 | 1.74 ms | 50.0 us | 46.2 us | 9.14 ms | 9.17 ms | 39.5 us | 25.7 us | 23.5 us |
| 2^12 | 8.01 ms | 219.7 us | 203.1 us | 133.10 ms | 138.19 ms | 119.8 us | 109.9 us | 104.8 us |
| 2^14 | 39.69 ms | 903.5 us | 860.3 us | 2.15 s | 2.03 s | 677.9 us | 536.0 us | 436.2 us |
| 2^16 | 225.97 ms | 5.36 ms | 4.76 ms | 42.53 s | 42.71 s | 3.43 ms | 3.14 ms | 2.21 ms |
| 2^18 | 1.21 s | 27.89 ms | 25.84 ms | Skipped | Skipped | 12.95 ms | 12.53 ms | 10.99 ms |
| 2^20 | 7.25 s | 164.35 ms | 149.33 ms | Skipped | Skipped | 89.84 ms | 85.69 ms | 74.99 ms |

In practice, you usually know how big your FFT is ahead of time, so it's pretty
easy to construct your FFT object once, to take advantage of the caching. It's
sometimes possible to take advantage of the in-place speed up too, for example
if you have to copy your data from another source anyway you may as well
construct the flat complex array yourself. Since this isn't always possible,
the "fftea, cached" times are probably the most representative. In that case,
fftea is about 60-80x faster than package:fft, and about 70% faster than
smart_signal_processing. Not sure what's going on with scidart, but it seems to
be O(n^2) even for power of two sizes.

\* Scidart's FFT doesn't have an in-place mode, but they do use a custom format,
so in-place means that the time to convert to that format is not included in the
benchmark.

I also benchmarked fftea's various implementations of FFT at different sizes,
using bench/impl_bench.dart.

![Performance of different fftea implementations](/bench/impl_bench_1.png)

This graph shows how the different implementations perform at different sizes.

![Performance of FFT.FFT constructor](/bench/impl_bench_2.png)

This graph shows the performance of the implementation selected by the `FFT.FFT`
constructor, which attempts to automatically pick the right implementation for
the given size. Although the overall O(n\*log(n)) worst case slope is
maintained, there is a lot of variation between specific sizes.

Looking at the first graph, you can see that Radix2FFT is consistently the
fastest, the PrimeFFT variants are the slowest, and CompositeFFT is in between.
Generally, the more composite the size is, the faster the FFT will be. So if you
have some flexibility in the FFT size you can choose, try to choose a highly
composite size (ie, one where the prime factors are small), or ideally choose a
power of two.
