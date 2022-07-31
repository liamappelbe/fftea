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
import 'package:test/test.dart';
import 'test_util.dart';

void main() {
  test('ComplexArray copying', () {
    // There used to be a dedicated copy() method, but now we just use the built
    // in `sublist(0)`. So we need to make sure this actually copies the array.
    final a = makeArray([1, 2, 3, 4]);
    expect(a.length, 2);
    expect(a[0].x, 1);
    expect(a[0].y, 2);
    expect(a[1].x, 3);
    expect(a[1].y, 4);

    final b = a.sublist(0);
    expect(b.length, 2);
    expect(b[0].x, 1);
    expect(b[0].y, 2);
    expect(b[1].x, 3);
    expect(b[1].y, 4);

    b[1] = Float64x2(123, 456);
    expect(b[0].x, 1);
    expect(b[0].y, 2);
    expect(b[1].x, 123);
    expect(b[1].y, 456);

    expect(a[0].x, 1);
    expect(a[0].y, 2);
    expect(a[1].x, 3);
    expect(a[1].y, 4);
  });

  test('ComplexArray to and from reals', () {
    final a = ComplexArray.fromRealArray([123, 456]);
    expect(a.length, 2);
    expect(a[0].x, 123);
    expect(a[0].y, 0);
    expect(a[1].x, 456);
    expect(a[1].y, 0);

    final b = a.toRealArray();
    expect(b.length, 2);
    expect(b[0], 123);
    expect(b[1], 456);
  });

  test('ComplexArray from reals, zero padding', () {
    final a = ComplexArray.fromRealArray([123, 456], 5);
    expect(a.length, 5);
    expect(a[0].x, 123);
    expect(a[0].y, 0);
    expect(a[1].x, 456);
    expect(a[1].y, 0);
    expect(a[2].x, 0);
    expect(a[2].y, 0);
    expect(a[3].x, 0);
    expect(a[3].y, 0);
    expect(a[4].x, 0);
    expect(a[4].y, 0);
  });

  test('ComplexArray from reals, truncation', () {
    final a = ComplexArray.fromRealArray([123, 456, 789], 1);
    expect(a.length, 1);
    expect(a[0].x, 123);
    expect(a[0].y, 0);
  });

  test('ComplexArray magnitudes', () {
    final a = makeArray([3, 4, -5, 12]);
    expect(a.length, 2);

    final sqmag = a.squareMagnitudes();
    expect(sqmag.length, 2);
    expect(sqmag[0], 25);
    expect(sqmag[1], 169);

    final mag = a.magnitudes();
    expect(mag.length, 2);
    expect(mag[0], 5);
    expect(mag[1], 13);
  });

  test('ComplexArray complexMultiply', () {
    final a = makeArray([
      -1.2, 3.4, 2.4, -6.8, -3.6, -10.2, 4.8, 13.6, -6, 17, 7.2, -20.4, //
      -8.4, -23.8, 9.6, 27.2, -10.8, 30.6, 12, -34, -13.2, -37.4, 14.4, //
      40.8, -15.6, 44.2, 16.8, -47.6, -18, -51, 19.2, 54.4,
    ]);
    final b = makeArray([
      54.4, 19.2, 51, 18, 47.6, 16.8, -44.2, 15.6, -40.8, 14.4, -37.4, 13.2, //
      -34, 12, 30.6, -10.8, 27.2, -9.6, 23.8, -8.4, 20.4, -7.2, -17, -6, //
      -13.6, -4.8, -10.2, -3.6, -6.8, -2.4, 3.4, 1.2,
    ]);
    final c = makeArray([
      -130.56, 161.92, 244.80, -303.60, 0, -546, -424.32, -526.24, 0, -780, //
      0, 858, 571.20, 708.40, 587.52, 728.64, 0, 936, 0, -910, -538.56, //
      -667.92, 0, -780, 424.32, -526.24, -342.72, 425.04, 0, 390, 0, 208,
    ]);
    a.complexMultiply(b);
    expectClose2(a, c);

    expect(
      () => a.complexMultiply(makeArray([1, 2, 3, 4])),
      throwsA(
        predicate(
          (e) =>
              e is ArgumentError && e.message == 'Input is the wrong length.',
        ),
      ),
    );
  });

  test('ComplexArray discardConjugates', () {
    expect(
      toFloats(makeArray([1, 2]).discardConjugates()),
      [1, 2],
    );
    expect(
      toFloats(makeArray([1, 2, 3, 4]).discardConjugates()),
      [1, 2, 3, 4],
    );
    expect(
      toFloats(makeArray([1, 2, 3, 4, 5, 6]).discardConjugates()),
      [1, 2, 3, 4],
    );
    expect(
      toFloats(makeArray([1, 2, 3, 4, 5, 6, 7, 8]).discardConjugates()),
      [1, 2, 3, 4, 5, 6],
    );
    expect(
      toFloats(makeArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).discardConjugates()),
      [1, 2, 3, 4, 5, 6],
    );
    expect(
      toFloats(
        makeArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
            .discardConjugates(),
      ),
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    );
  });
}
