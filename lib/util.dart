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

import 'dart:math' as math;
import 'dart:typed_data';

/// Extension methods for [Float64x2List], representing a list of complex
/// numbers.
extension ComplexArray on Float64x2List {
  /// Converts a real array to a [Float64x2List] of complex numbers.
  static Float64x2List fromRealArray(
    List<double> reals, [
    int outputLength = -1,
  ]) {
    if (outputLength < 0) outputLength = reals.length;
    final a = Float64x2List(outputLength);
    final copyLength = math.min(reals.length, outputLength);
    for (int i = 0; i < copyLength; ++i) {
      a[i] = Float64x2(reals[i], 0);
    }
    return a;
  }

  /// Returns the real components of the [Float64x2List].
  ///
  /// This method just discards the imaginary components. It doesn't check
  /// whether the imaginary components are actually close to zero.
  Float64List toRealArray() {
    final r = Float64List(length);
    for (int i = 0; i < r.length; ++i) {
      r[i] = this[i].x;
    }
    return r;
  }

  /// Returns the square magnitudes of the elements of the [Float64x2List].
  ///
  /// If you need the squares of the magnitudes, this method is much more
  /// efficient than calling [magnitudes] then squaring those values.
  Float64List squareMagnitudes() {
    final m = Float64List(length);
    for (int i = 0; i < m.length; ++i) {
      final z = this[i];
      m[i] = z.x * z.x + z.y * z.y;
    }
    return m;
  }

  /// Returns the magnitudes of the elements of the [Float64x2List].
  Float64List magnitudes() {
    final m = squareMagnitudes();
    for (int i = 0; i < m.length; ++i) {
      m[i] = math.sqrt(m[i]);
    }
    return m;
  }

  /// Complex multiplies each element of [other] onto each element of this list.
  ///
  /// This method modifies this array, rather than allocating a new array. The
  /// other array must have the same length as this one.
  void complexMultiply(Float64x2List other) {
    if (other.length != length) {
      throw ArgumentError('Input is the wrong length.', 'other');
    }
    for (int i = 0; i < length; ++i) {
      final a = this[i];
      final b = other[i];
      this[i] = a.scale(b.x) + Float64x2(-a.y, a.x).scale(b.y);
    }
  }

  static int _discConjLen(int length) {
    return (length == 0) ? 0 : ((length >>> 1) + 1);
  }

  /// Discards redundant conjugate terms, assuming this is the result of a real
  /// valued FFT. This method does not check whether those terms are actualy
  /// redundant conjugate values.
  ///
  /// The result of a real valued FFT is about half redundant data, so the list
  /// returned by this function omits that data:
  ///
  /// (sum term, ...terms..., nyquist term, ...conjugate terms...)
  ///
  /// The sum term, main terms, and nyquitst term, are kept. The conjugate terms
  /// are discarded. For odd length arrays, the nyquist term doesn't exist.
  ///
  /// This method returns a new array (which is a view into the same data). It
  /// does not modify this array, or make a copy of the data.
  Float64x2List discardConjugates() {
    return Float64x2List.sublistView(this, 0, _discConjLen(length));
  }

  /// Creates redundant conjugate terms. This is the inverse of
  /// [discardConjugates], and it only really makes sense to recreate conjugates
  /// after they have been discarded using that method.
  ///
  /// When discarding the conjugates, an array of e.g. 10 elements or 11
  /// elements will both end up with 6 elements left. So when recreating them,
  /// the [outputLength] needs to be specified. It should be the same as the
  /// length of the array before [discardConjugates] was called.
  ///
  /// The intended use case for this function is as part of a signal processing
  /// pipeline like this:
  ///
  /// 1. Take in a real valued time domain input
  /// 2. Perform an FFT to get the frequency domain signal
  /// 3. Discard the redundant conjugates using [discardConjugates]
  /// 4. Perform some manipulations on the complex frequency domain signal
  /// 5. Recreate the conjugates using [createConjugates]
  /// 6. Inverse FFT to get a real valued time domain output
  ///
  /// You could get the same output by skipping steps 3 and 5, but in that case,
  /// care must be taken to ensure that step 4 preserves the conjugate symmetry,
  /// which can be fiddly. If that symmetry is lost, then the final time domain
  /// output will contain complex values, not just real values. So it's usually
  /// easier to discard the conjugates and then recreate them later.
  ///
  /// This method returns a totally new array containing a copy of this array,
  /// with the extra values appended at the end.
  Float64x2List createConjugates(int outputLength) {
    if (_discConjLen(outputLength) != length) {
      throw ArgumentError(
        'Output length must be either (2 * length - 2) or (2 * length - 1).',
        'outputLength',
      );
    }
    final out = Float64x2List(outputLength);
    for (int i = 0; i < length; ++i) {
      out[i] = this[i];
    }
    for (int i = length; i < outputLength; ++i) {
      final a = this[outputLength - i];
      out[i] = Float64x2(a.x, -a.y);
    }
    return out;
  }
}

/// Returns whether [x] is a power of two: 1, 2, 4, 8, ...
bool isPowerOf2(int x) => (x > 0) && ((x & (x - 1)) == 0);

/// Prime number generator.
///
/// Maintains an internal list of prime numbers, which it uses to generate new
/// prime numbers.
class Primes {
  final _p = <int>[2, 3, 5, 7];
  int _n = 9;

  /// Returns whether [oddN] is prime, assuming it's an odd number. This is only
  /// public for testing. Use the public [isPrime] function instead.
  bool internalIsPrime(int oddN) {
    for (int i = 1;; ++i) {
      final p = i < _p.length ? _p[i] : addPrime();
      if (p * p > oddN) return true;
      if (oddN % p == 0) return false;
    }
  }

  /// Adds the next prime and returns it.
  int addPrime() {
    while (true) {
      _n += 2;
      if (internalIsPrime(_n)) {
        _p.add(_n);
        return _n;
      }
    }
  }

  /// Returns the [i]th prime number.
  ///
  /// WARNING: This will generate and store every prime number below the [i]th.
  /// That can be very expensive. That's why the [isPrime], [primeDecomp] etc
  /// are carefully implemented to only request primes up to `sqrt(n)`.
  int getPrime(int i) {
    while (_p.length <= i) {
      addPrime();
    }
    return _p[i];
  }

  /// Returns the number of primes that are currently cached.
  int get numPrimes => _p.length;
}

/// Static [Primes] object used to cache prime numbers between all the functions
/// that need prime numbers.
final primes = Primes();

/// Returns whether [n] is a prime number.
bool isPrime(int n) {
  if (n <= 1) return false;
  if (n == 2) return true;
  if (n.isEven) return false;
  return primes.internalIsPrime(n);
}

/// Returns the prime decomposition of [n].
///
/// For example, 120 returns `[2, 2, 2, 3, 5]`.
List<int> primeDecomp(int n) {
  final a = <int>[];
  for (int i = 0, p = 2;;) {
    if (p * p > n) break;
    if (n % p != 0) {
      i += 1;
      p = primes.getPrime(i);
    } else {
      a.add(p);
      n ~/= p;
    }
  }
  if (n != 1) a.add(n);
  return a;
}

/// Returns the unique prime factors of [n].
///
/// For example, 120 returns `[2, 3, 5]`.
List<int> primeFactors(int n) {
  bool newp = true;
  final a = <int>[];
  for (int i = 0, p = 2;;) {
    if (p * p > n) break;
    if (n % p != 0) {
      i += 1;
      p = primes.getPrime(i);
      newp = true;
    } else {
      if (newp) {
        a.add(p);
        newp = false;
      }
      n ~/= p;
    }
  }
  if (n != 1 && (a.isEmpty || a.last != n)) a.add(n);
  return a;
}

/// Returns the largest prime factor of [n].
///
/// For example, 120 returns 5.
int largestPrimeFactor(int n) {
  int maxp = 1;
  for (int i = 0, p = 2;;) {
    if (p * p > n) break;
    if (n % p != 0) {
      i += 1;
      p = primes.getPrime(i);
    } else {
      if (p > maxp) maxp = p;
      n ~/= p;
    }
  }
  if (n > maxp) maxp = n;
  return maxp;
}

/// Returns whether `largestPrimeFactor(n) > k`.
///
/// This function is significantly more efficient than doing that check
/// explicitly.
bool largestPrimeFactorIsAbove(int n, int k) {
  for (int i = 0, p = 2;;) {
    if (p * p > n || p > k) break;
    if (n % p != 0) {
      i += 1;
      p = primes.getPrime(i);
    } else {
      n ~/= p;
    }
  }
  return n > k;
}

/// Returns whether padding the PrimeFFT to a power of two size is likely to be
/// faster than not padding it.
///
/// Experimentally, padding is usually a win when the largest prime factor of
/// `n - 1` is greater than 5. We also special case a few small sizes where this
/// simple heuristic is wrong.
bool primePaddingHeuristic(int n) {
  if (n == 31 || n == 61 || n == 101 || n == 241 || n == 251) return true;
  return largestPrimeFactorIsAbove(n - 1, 5);
}

/// Returns the highest set bit of [x], where [x] is a power of 2.
///
/// Only supports [x] below 2^48, for compatibility with JS.
int highestBit(int x) {
  return ((x & 0xAAAAAAAAAAAA) != 0 ? 1 : 0) |
      ((x & 0xCCCCCCCCCCCC) != 0 ? 2 : 0) |
      ((x & 0xF0F0F0F0F0F0) != 0 ? 4 : 0) |
      ((x & 0xFF00FF00FF00) != 0 ? 8 : 0) |
      ((x & 0x0000FFFF0000) != 0 ? 16 : 0) |
      ((x & 0xFFFF00000000) != 0 ? 32 : 0);
}

/// Returns the smallest power of two equal or greater than [x].
int nextPowerOf2(int x) {
  --x;
  x |= x >> 1;
  x |= x >> 2;
  x |= x >> 4;
  x |= x >> 8;
  x |= x >> 16;
  x |= x >> 32;
  ++x;
  return x;
}

/// Returns the primitive root of [n], where [n] is a prime > 2.
int primitiveRootOfPrime(int n) {
  int e = n - 1;
  final d = primeFactors(e);
  for (int i = 0; i < d.length; ++i) {
    d[i] = e ~/ d[i];
  }
  for (int g = 2;; ++g) {
    bool allNot1 = true;
    for (final k in d) {
      if (expMod(g, k, n) == 1) {
        allNot1 = false;
        break;
      }
    }
    if (allNot1) return g;
  }
}

/// Returns g^k mod n.
int expMod(int g, int k, int n) {
  int y = 1;
  while (k > 0) {
    if (k & 0x1 != 0) {
      y = (y * g) % n;
    }
    k >>>= 1;
    g = (g * g) % n;
  }
  return y;
}

/// Returns the multiplicative inverse of x mod n, where n is a prime.
int multiplicativeInverseOfPrime(int x, int n) {
  return expMod(x, n - 2, n);
}

/// Returns the twiddle factors for an FFT of size [n]. Aka the complex n-th
/// roots of 1.
Float64x2List twiddleFactors(int n) {
  final twiddles = Float64x2List(n);
  final dt = -2 * math.pi / n;
  final half = n ~/ 2;
  for (int i = 0; i <= half; ++i) {
    final t = i * dt;
    twiddles[i] = Float64x2(math.cos(t), math.sin(t));
  }
  for (int i = (n + 1) ~/ 2; i < n; ++i) {
    final a = twiddles[n - i];
    twiddles[i] = Float64x2(a.x, -a.y);
  }
  return twiddles;
}
