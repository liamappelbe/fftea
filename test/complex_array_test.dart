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
