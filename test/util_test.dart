
import 'dart:typed_data';
import 'package:fftea/util.dart';
import 'package:test/test.dart';
import 'util.dart';

void main() {
  test('isPowerOf2', () {
    expect(isPowerOf2(0), isFalse);
    expect(isPowerOf2(1), isTrue);
    expect(isPowerOf2(2), isTrue);
    expect(isPowerOf2(3), isFalse);
    expect(isPowerOf2(4), isTrue);
    expect(isPowerOf2(5), isFalse);
    expect(isPowerOf2(6), isFalse);
    expect(isPowerOf2(7), isFalse);
    expect(isPowerOf2(8), isTrue);
    expect(isPowerOf2(47), isFalse);
    expect(isPowerOf2(16384), isTrue);
    expect(isPowerOf2(-123), isFalse);
    expect(isPowerOf2(-4), isFalse);
  });

  test('Primes', () {
    final exp = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
        71, 73, 79, 83, 89, 97, 101];
    for (int i = 0; i < exp.length; ++i) {
      expect(primes.getPrime(i), exp[i]);
    }
  });

  test('Prime decomposition', () {
    expect(primeDecomp(453974598), [2, 3, 3, 3, 7, 11, 23, 47, 101]);
  });

  test("Euler's totient", () {
    // Expected values of Euler's totient, starting at exp[0] = phi(2).
    final exp = [
        1, 2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12, 6, 8, 8, 16, 6, 18, 8, 12, 10,
        22, 8, 20, 12, 18, 12, 28, 8, 30, 16, 20, 16, 24, 12, 36, 18, 24, 16,
        40, 12, 42, 20, 24, 22, 46, 16, 42, 20, 32, 24, 52, 18, 40, 24, 36, 28,
        58, 16, 60, 30, 36, 32, 48, 20, 66, 32, 44];
    for (int i = 0; i < exp.length; ++i) {
      expect(eulersTotient(i + 2), exp[i]);
    }
  });

  test('Modular exponentiation', () {
    final exp = [
      [37, 0, 456, 1], [18, 0, 222, 1], [71, 4, 283, 262], [74, 4, 48, 16],
      [100, 4, 583, 342], [77, 3, 227, 36], [69, 2, 519, 90], [30, 4, 603, 171],
      [3, 9, 691, 335], [46, 4, 289, 268], [99, 4, 105, 36], [70, 7, 903, 343],
      [16, 5, 944, 736], [21, 6, 607, 56], [58, 1, 756, 58], [71, 5, 647, 622],
      [43, 5, 817, 731], [12, 1, 883, 12], [4, 6, 105, 1], [62, 1, 367, 62],
      [98, 3, 92, 32],
    ];
    for (final gkny in exp) {
      expect(expMod(gkny[0], gkny[1], gkny[2]), gkny[3]);
    }
  });

  test('Primitive root of prime', () {
    // Expected primitive roots of primes > 2: https://oeis.org/A001918
    final exp = [
        2, 2, 3, 2, 2, 3, 2, 5, 2, 3, 2, 6, 3, 5, 2, 2, 2, 2, 7, 5, 3, 2, 3, 5,
        2, 5, 2, 6, 3, 3, 2, 3, 2, 2, 6, 5, 2, 5, 2, 2, 2, 19, 5, 2, 3, 2, 3, 2,
        6, 3, 7, 7, 6, 3, 5, 2, 6, 5, 3, 3, 2, 5, 17, 10, 2, 3, 10, 2, 2, 3, 7,
        6, 2, 2, 5, 2, 5, 3, 21, 2, 2, 7, 5, 15, 2, 3, 13, 2, 3, 2, 13, 3, 2, 7,
        5, 2, 3, 2, 2, 2, 2, 2, 3];
    for (int i = 0; i < exp.length; ++i) {
      expect(primitiveRootOfPrime(primes.getPrime(i + 1)), exp[i]);
    }
  });

  test('Multiplicative inverse', () {
    final n = 47;
    for (int i = 1; i < n; ++i) {
      final j = multiplicativeInverseOfPrime(i, n);
      expect((i * j) % n, 1);
    }
  });
}
