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

/// Returns whether x is a power of two: 1, 2, 4, 8, ...
bool isPowerOf2(int x) => (x > 0) && ((x & (x - 1)) == 0);

class Primes {
  final _p = <int>[2, 3, 5, 7];
  int _n = 9;
  bool _isPrime(int n) {
    for (final p in _p) {
      if (p * p > n) return true;
      if (n % p == 0) return false;
    }
    return true;
  }
  void _addPrime() {
    while (true) {
      _n += 2;
      if (_isPrime(_n)) {
        _p.add(_n);
        break;
      }
    }
  }
  int getPrime(int i) {
    while (_p.length <= i) _addPrime();
    return _p[i];
  }
}
final primes = Primes();

bool isPrime(int n) {
  // TODO: Maybe implement Baillie–PSW?
  for (int i = 0, p = 2;;) {
    if (p * p > n) return true;
    if (n % p == 0) return false;
    i += 1;
    p = primes.getPrime(i);
  }
}

List<int> primeDecomp(int n) {
  // TODO: Fix edge case where n is a large prime, and this function will store
  // all the prime numbers up to that prime in primes. Instead, explicitly check
  // if n is prime each time we divide it (or only do this once i>100 or
  // something). This will mean we only store primes up to sqrt(n).
  final a = <int>[];
  for (int i = 0, p = 2;;) {
    if (n % p != 0) {
      i += 1;
      p = primes.getPrime(i);
    } else {
      a.add(p);
      n ~/= p;
      if (n == 1) break;
    }
  }
  return a;
}

List<int> primeFactors(int n) {
  bool newp = true;
  final a = <int>[];
  for (int i = 0, p = 2;;) {
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
      if (n == 1) break;
    }
  }
  return a;
}

int highestBit(int x) {
  return ((x & 0xAAAAAAAAAAAAAAAA) != 0 ? 1 : 0) |
      ((x & 0xCCCCCCCCCCCCCCCC) != 0 ? 2 : 0) |
      ((x & 0xF0F0F0F0F0F0F0F0) != 0 ? 4 : 0) |
      ((x & 0xFF00FF00FF00FF00) != 0 ? 8 : 0) |
      ((x & 0xFFFF0000FFFF0000) != 0 ? 16 : 0) |
      ((x & 0xFFFFFFFF00000000) != 0 ? 32 : 0);
}

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

// Returns the primitive root of n. WARNING: Assumes n is a prime > 2.
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

// Returns g^k mod n.
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

// TODO: Probably don't need this function.
int eulersTotient(int n) {
  bool newp = true;
  int e = 1;
  for (int i = 0, p = 2;;) {
    if (n % p != 0) {
      i += 1;
      p = primes.getPrime(i);
      newp = true;
    } else {
      if (newp) {
        e *= p - 1;
        newp = false;
      } else {
        e *= p;
      }
      n ~/= p;
      if (n == 1) break;
    }
  }
  return e;
}

// Returns the multiplicative inverse of x mod n, where n is a prime.
int multiplicativeInverseOfPrime(int x, int n) {
  return expMod(x, n - 2, n);
}

Float64x2List twiddleFactors(int size) {
  final twiddles = Float64x2List(size);
  final dt = -2 * math.pi / size;
  // TODO: Use reflection to halve the number of terms calculated.
  for (int i = 0; i < size; ++i) {
    final t = i * dt;
    twiddles[i] = Float64x2(math.cos(t), math.sin(t));
  }
  return twiddles;
}
