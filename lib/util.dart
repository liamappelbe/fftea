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
  static Float64x2List fromRealArray(List<double> reals) {
    final a = Float64x2List(reals.length);
    for (int i = 0; i < reals.length; ++i) {
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
    return Float64x2List.sublistView(this, 0, (length >>> 1) + 1);
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

  /// Returns whether [n] is a prime number.
  bool isPrime(int n) {
    if (n <= 1) return false;
    if (n == 2) return true;
    if (n.isEven) return false;
    return internalIsPrime(n);
  }
}

/// Static [Primes] object used to cache prime numbers between all the functions
/// that need prime numbers.
final primes = Primes();

/// Returns whether [n] is a prime number.
bool isPrime(int n) => primes.isPrime(n);

const _smallPrimes = [
  2,   3,   5,   7,   11,  13,  17,  19,  23,  29,  31,  37,  41,  43,  //
  47,  53,  59,  61,  67,  71,  73,  79,  83,  89,  97,  101, 103, 107, //
  109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, //
  191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, //
  269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, //
  353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, //
  439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, //
  523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607, 613, //
  617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701, //
  709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, //
  811, 821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, //
  907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997, //
];
const _isPrimeNaiveThreshold = 1009 * 1009;  // Square of next prime after ^

bool isPrimeMrBase2(int n) {
  final neg1 = n - 1;
  for (int m = neg1; ; ) {
    final y = expMod(2, m, n);
    if (y != 1) return y == neg1;
    if (m % 2 != 0) return true;
    m >>>= 1;
  }
}

/// Returns whether [n] is a prime number.
bool isPrimeBpsw(int n) {
  return false;
}

bool _isPrimeMrTest(int a, int n, int n_1, int d) {
  if (expMod(a, d, n) == 1) return true;
  while (d <= n_1) {
    if (expMod(a, d, n) == n_1) return true;
    d <<= 1;
  }
  return false;
}

/// Returns whether [n] is a prime number.
bool isPrimeMr(int n) {
  // https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
  // https://oeis.org/A014233
  if (n <= 1) return false;
  if (n == 2) return true;
  if (n.isEven) return false;

  final n_1 = n - 1;
  final d = n_1 >>> trailingZeros(n_1);

  if (!_isPrimeMrTest(2, n, n_1, d)) return false;
  if (n < 2047) return true;
  if (!_isPrimeMrTest(3, n, n_1, d)) return false;
  if (n < 1373653) return true;
  if (!_isPrimeMrTest(5, n, n_1, d)) return false;
  if (n < 25326001) return true;
  if (!_isPrimeMrTest(7, n, n_1, d)) return false;
  if (n < 3215031751) return true;
  if (!_isPrimeMrTest(11, n, n_1, d)) return false;
  if (n < 2152302898747) return true;
  if (!_isPrimeMrTest(13, n, n_1, d)) return false;
  if (n < 3474749660383) return true;
  if (!_isPrimeMrTest(17, n, n_1, d)) return false;
  if (!_isPrimeMrTest(19, n, n_1, d)) return false;
  if (n < 341550071728321) return true;
  if (!_isPrimeMrTest(23, n, n_1, d)) return false;
  if (!_isPrimeMrTest(29, n, n_1, d)) return false;
  if (!_isPrimeMrTest(31, n, n_1, d)) return false;
  if (n < 3825123056546413051) return true;
  return _isPrimeMrTest(37, n, n_1, d);
}

const _isPrimeMr2SmallPrimesAndSquares = [
    9,        3,    25,       5,    49,       7,    121,      11,  //
    169,      13,   289,      17,   361,      19,   529,      23,  //
    841,      29,   961,      31,   1369,     37,   1681,     41,  //
    1849,     43,   2209,     47,   2809,     53,   3481,     59,  //
    3721,     61,   4489,     67,   5041,     71,   5329,     73,  //
    6241,     79,   6889,     83,   7921,     89,   9409,     97,  //
    10201,    101,  10609,    103,  11449,    107,  11881,    109,  //
    12769,    113,  16129,    127,  17161,    131,  18769,    137,  //
    19321,    139,  22201,    149,  22801,    151,  24649,    157,  //
    26569,    163,  27889,    167,  29929,    173,  32041,    179,  //
    32761,    181,  36481,    191,  37249,    193,  38809,    197,  //
    39601,    199,  44521,    211,  49729,    223,  51529,    227,  //
    52441,    229,  54289,    233,  57121,    239,  58081,    241,  //
    63001,    251,  66049,    257,  69169,    263,  72361,    269,  //
    73441,    271,  76729,    277,  78961,    281,  80089,    283,  //
    85849,    293,  94249,    307,  96721,    311,  97969,    313,  //
    100489,   317,  109561,   331,  113569,   337,  120409,   347,  //
    121801,   349,  124609,   353,  128881,   359,  134689,   367,  //
    139129,   373,  143641,   379,  146689,   383,  151321,   389,  //
    157609,   397,  160801,   401,  167281,   409,  175561,   419,  //
    177241,   421,  185761,   431,  187489,   433,  192721,   439,  //
    196249,   443,  201601,   449,  208849,   457,  212521,   461,  //
    214369,   463,  218089,   467,  229441,   479,  237169,   487,  //
    241081,   491,  249001,   499,  253009,   503,  259081,   509,  //
    271441,   521,  273529,   523,  292681,   541,  299209,   547,  //
    310249,   557,  316969,   563,  323761,   569,  326041,   571,  //
    332929,   577,  344569,   587,  351649,   593,  358801,   599,  //
    361201,   601,  368449,   607,  375769,   613,  380689,   617,  //
    383161,   619,  398161,   631,  410881,   641,  413449,   643,  //
    418609,   647,  426409,   653,  434281,   659,  436921,   661,  //
    452929,   673,  458329,   677,  466489,   683,  477481,   691,  //
    491401,   701,  502681,   709,  516961,   719,  528529,   727,  //
    537289,   733,  546121,   739,  552049,   743,  564001,   751,  //
    573049,   757,  579121,   761,  591361,   769,  597529,   773,  //
    619369,   787,  635209,   797,  654481,   809,  657721,   811,  //
    674041,   821,  677329,   823,  683929,   827,  687241,   829,  //
    703921,   839,  727609,   853,  734449,   857,  737881,   859,  //
    744769,   863,  769129,   877,  776161,   881,  779689,   883,  //
    786769,   887,  822649,   907,  829921,   911,  844561,   919,  //
    863041,   929,  877969,   937,  885481,   941,  896809,   947,  //
    908209,   953,  935089,   967,  942841,   971,  954529,   977,  //
    966289,   983,  982081,   991,  994009,   997,  1018081,  1009,  //
    1026169,  1013, 1038361,  1019, 1042441,  1021, 1062961,  1031,  //
    1067089,  1033, 1079521,  1039, 1100401,  1049, 1104601,  1051,  //
    1125721,  1061, 1129969,  1063, 1142761,  1069, 1181569,  1087,  //
    1190281,  1091, 1194649,  1093, 1203409,  1097, 1216609,  1103,  //
    1229881,  1109, 1247689,  1117, 1261129,  1123, 1274641,  1129,  //
    1324801,  1151, 1329409,  1153, 1352569,  1163, 1371241,  1171,  //
    1394761,  1181, 1408969,  1187, 1423249,  1193, 1442401,  1201,  //
    1471369,  1213, 1481089,  1217, 1495729,  1223, 1510441,  1229,  //
    1515361,  1231, 1530169,  1237, 1560001,  1249, 1585081,  1259,  //
    1630729,  1277, 1635841,  1279, 1646089,  1283, 1661521,  1289,  //
    1666681,  1291, 1682209,  1297, 1692601,  1301, 1697809,  1303,  //
    1708249,  1307, 1739761,  1319, 1745041,  1321, 1760929,  1327,  //
    1852321,  1361, 1868689,  1367, 1885129,  1373, 1907161,  1381,  //
    1957201,  1399, 1985281,  1409, 2024929,  1423, 2036329,  1427,  //
    2042041,  1429, 2053489,  1433, 2070721,  1439, 2093809,  1447,  //
    2105401,  1451, 2111209,  1453, 2128681,  1459, 2163841,  1471,  //
    2193361,  1481, 2199289,  1483, 2211169,  1487, 2217121,  1489,  //
    2229049,  1493, 2247001,  1499, 2283121,  1511, 2319529,  1523,  //
    2343961,  1531, 2380849,  1543, 2399401,  1549, 2411809,  1553,  //
    2430481,  1559, 2455489,  1567, 2468041,  1571, 2493241,  1579,  //
    2505889,  1583, 2550409,  1597, 2563201,  1601, 2582449,  1607,  //
    2588881,  1609, 2601769,  1613, 2621161,  1619, 2627641,  1621,  //
    2647129,  1627, 2679769,  1637, 2745649,  1657, 2765569,  1663,  //
    2778889,  1667, 2785561,  1669, 2866249,  1693, 2879809,  1697,  //
    2886601,  1699, 2920681,  1709, 2961841,  1721, 2968729,  1723,  //
    3003289,  1733, 3031081,  1741, 3052009,  1747, 3073009,  1753,  //
    3094081,  1759, 3157729,  1777, 3179089,  1783, 3193369,  1787,  //
    3200521,  1789, 3243601,  1801, 3279721,  1811, 3323329,  1823,  //
    3352561,  1831, 3411409,  1847, 3463321,  1861, 3485689,  1867,  //
    3500641,  1871, 3508129,  1873, 3523129,  1877, 3530641,  1879,  //
    3568321,  1889, 3613801,  1901, 3636649,  1907, 3659569,  1913,  //
    3728761,  1931, 3736489,  1933, 3798601,  1949, 3806401,  1951,  //
    3892729,  1973, 3916441,  1979, 3948169,  1987, 3972049,  1993,  //
    3988009,  1997, 3996001,  1999, 4012009,  2003, 4044121,  2011,  //
    4068289,  2017, 4108729,  2027, 4116841,  2029, 4157521,  2039,  //
    4214809,  2053, 4255969,  2063, 4280761,  2069, 4330561,  2081,  //
    4338889,  2083, 4355569,  2087, 4363921,  2089, 4405801,  2099,  //
    4456321,  2111, 4464769,  2113, 4532641,  2129, 4541161,  2131,  //
    4566769,  2137, 4583881,  2141, 4592449,  2143, 4635409,  2153,  //
    4669921,  2161, 4748041,  2179, 4853209,  2203, 4870849,  2207,  //
    4897369,  2213, 4932841,  2221, 5004169,  2237, 5013121,  2239,  //
    5031049,  2243, 5067001,  2251, 5139289,  2267, 5148361,  2269,  //
    5166529,  2273, 5202961,  2281, 5230369,  2287, 5257849,  2293,  //
    5276209,  2297, 5331481,  2309, 5340721,  2311, 5442889,  2333,  //
    5470921,  2339, 5480281,  2341, 5508409,  2347, 5527201,  2351,  //
    5555449,  2357, 5621641,  2371, 5650129,  2377, 5669161,  2381,  //
    5678689,  2383, 5707321,  2389, 5726449,  2393, 5755201,  2399,  //
    5812921,  2411, 5841889,  2417, 5870929,  2423, 5938969,  2437,  //
    5958481,  2441, 5987809,  2447, 6046681,  2459, 6086089,  2467,  //
    6115729,  2473, 6135529,  2477, 6265009,  2503, 6355441,  2521,  //
    6405961,  2531, 6446521,  2539, 6466849,  2543, 6497401,  2549,  //
    6507601,  2551, 6538249,  2557, 6651241,  2579, 6713281,  2591,  //
    6723649,  2593, 6806881,  2609, 6848689,  2617, 6869641,  2621,  //
    6932689,  2633, 7006609,  2647, 7059649,  2657, 7070281,  2659,  //
    7091569,  2663, 7134241,  2671, 7166329,  2677, 7198489,  2683,  //
    7219969,  2687, 7230721,  2689, 7252249,  2693, 7284601,  2699,  //
    7327849,  2707, 7349521,  2711, 7360369,  2713, 7392961,  2719,  //
    7447441,  2729, 7458361,  2731, 7513081,  2741, 7557001,  2749,  //
    7579009,  2753, 7656289,  2767, 7711729,  2777, 7778521,  2789,  //
    7789681,  2791, 7823209,  2797, 7845601,  2801, 7856809,  2803,  //
    7946761,  2819, 8025889,  2833, 8048569,  2837, 8082649,  2843,  //
    8128201,  2851, 8162449,  2857, 8185321,  2861, 8288641,  2879,  //
    8334769,  2887, 8392609,  2897, 8427409,  2903, 8462281,  2909,  //
    8508889,  2917, 8567329,  2927, 8637721,  2939, 8720209,  2953,  //
    8743849,  2957, 8779369,  2963, 8814961,  2969, 8826841,  2971,  //
    8994001,  2999, 9006001,  3001, 9066121,  3011, 9114361,  3019,  //
    9138529,  3023, 9223369,  3037, 9247681,  3041, 9296401,  3049,  //
    9369721,  3061, 9406489,  3067, 9480241,  3079, 9504889,  3083,  //
    9541921,  3089, 9665881,  3109, 9728161,  3119, 9740641,  3121,  //
    9840769,  3137, 10004569, 3163, 10029889, 3167, 10042561, 3169,  //
    10118761, 3181, 10156969, 3187, 10182481, 3191, 10259209, 3203,  //
    10297681, 3209, 10349089, 3217, 10374841, 3221, 10426441, 3229,  //
    10569001, 3251, 10582009, 3253, 10608049, 3257, 10621081, 3259,  //
    10699441, 3271, 10883401, 3299, 10896601, 3301, 10936249, 3307,  //
    10975969, 3313, 11015761, 3319, 11042329, 3323, 11082241, 3329,  //
    11095561, 3331, 11175649, 3343, 11202409, 3347, 11282881, 3359,  //
    11296321, 3361, 11363641, 3371, 11377129, 3373, 11485321, 3389,  //
    11498881, 3391, 11607649, 3407, 11648569, 3413, 11785489, 3433,  //
    11895601, 3449, 11950849, 3457, 11978521, 3461, 11992369, 3463,  //
    12020089, 3467, 12033961, 3469, 12187081, 3491, 12243001, 3499,  //
    12327121, 3511, 12369289, 3517, 12439729, 3527, 12453841, 3529,  //
    12482089, 3533, 12524521, 3539, 12538681, 3541, 12581209, 3547,  //
    12652249, 3557, 12666481, 3559, 12752041, 3571, 12823561, 3581,  //
    12837889, 3583, 12909649, 3593, 13010449, 3607, 13053769, 3613,  //
    13082689, 3617, 13126129, 3623, 13184161, 3631, 13227769, 3637,  //
    13271449, 3643, 13388281, 3659, 13476241, 3671, 13490929, 3673,  //
    13520329, 3677, 13623481, 3691, 13667809, 3697, 13697401, 3701,  //
    13756681, 3709, 13830961, 3719, 13890529, 3727, 13935289, 3733,  //
    13980121, 3739, 14145121, 3761, 14190289, 3767, 14205361, 3769,  //
    14280841, 3779, 14386849, 3793, 14417209, 3797, 14462809, 3803,  //
    14600041, 3821, 14615329, 3823, 14691889, 3833, 14799409, 3847,  //
    14830201, 3851, 14845609, 3853, 14922769, 3863, 15031129, 3877,  //
    15062161, 3881, 15124321, 3889, 15264649, 3907, 15295921, 3911,  //
    15342889, 3917, 15358561, 3919, 15389929, 3923, 15437041, 3929,  //
    15452761, 3931, 15547249, 3943, 15578809, 3947, 15737089, 3967,  //
    15912121, 3989, 16008001, 4001, 16024009, 4003, 16056049, 4007,  //
    16104169, 4013, 16152361, 4019, 16168441, 4021, 16216729, 4027,  //
    16394401, 4049, 16410601, 4051, 16459249, 4057, 16589329, 4073,  //
    16638241, 4079, 16736281, 4091, 16752649, 4093, 16801801, 4099,  //
    16900321, 4111, 17032129, 4127, 17048641, 4129, 17081689, 4133,  //
    17131321, 4139, 17247409, 4153, 17280649, 4157, 17297281, 4159,  //
    17447329, 4177, 17648401, 4201, 17732521, 4211, 17783089, 4217,  //
    17799961, 4219, 17884441, 4229, 17901361, 4231, 17986081, 4241,  //
    18003049, 4243, 18088009, 4253, 18139081, 4259, 18156121, 4261,  //
    18241441, 4271, 18258529, 4273, 18344089, 4283, 18395521, 4289,  //
    18464209, 4297, 18722929, 4327, 18809569, 4337, 18826921, 4339,  //
    18913801, 4349, 18983449, 4357, 19035769, 4363, 19123129, 4373,  //
    19280881, 4391, 19333609, 4397, 19439281, 4409, 19545241, 4421,  //
    19562929, 4423, 19722481, 4441, 19775809, 4447, 19811401, 4451,  //
    19864849, 4457, 19918369, 4463, 20079361, 4481, 20097289, 4483,  //
    20187049, 4493, 20313049, 4507, 20367169, 4513, 20403289, 4517,  //
    20421361, 4519, 20457529, 4523, 20675209, 4547, 20693401, 4549,  //
    20802721, 4561, 20857489, 4567, 21003889, 4583, 21077281, 4591,  //
    21132409, 4597, 21187609, 4603, 21353641, 4621, 21501769, 4637,  //
    21520321, 4639, 21557449, 4643, 21613201, 4649, 21631801, 4651,  //
    21687649, 4657, 21743569, 4663, 21836929, 4673, 21893041, 4679,  //
    22005481, 4691, 22118209, 4703, 22287841, 4721, 22306729, 4723,  //
    22363441, 4729, 22401289, 4733, 22572001, 4751, 22648081, 4759,  //
    22877089, 4783, 22915369, 4787, 22934521, 4789, 22972849, 4793,  //
    23030401, 4799, 23049601, 4801, 23164969, 4813, 23203489, 4817,  //
    23338561, 4831, 23629321, 4861, 23726641, 4871, 23785129, 4877,  //
    23902321, 4889, 24039409, 4903, 24098281, 4909, 24196561, 4919,  //
    24314761, 4931, 24334489, 4933, 24373969, 4937, 24433249, 4943,  //
    24512401, 4951, 24571849, 4957, 24671089, 4967, 24690961, 4969,  //
    24730729, 4973, 24870169, 4987, 24930049, 4993, 24990001, 4999,  //
    25030009, 5003, 25090081, 5009, 25110121, 5011, 25210441, 5021,  //
    25230529, 5023,  //
];

bool isPrimeMr2(int n) {
  // https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
  // https://oeis.org/A014233
  if (n <= 1) return false;
  if (n == 2) return true;
  if (n.isEven) return false;

  if (n < 25326001) {
    for (int i = 0; i < _isPrimeMr2SmallPrimesAndSquares.length; ++i) {
      if (n < _isPrimeMr2SmallPrimesAndSquares[i]) return true;
      ++i;
      if (n % _isPrimeMr2SmallPrimesAndSquares[i] == 0) return false;
    }
    return true;
  }

  final n_1 = n - 1;
  final d = n_1 >>> trailingZeros(n_1);
  if (!_isPrimeMrTest(2, n, n_1, d)) return false;
  if (!_isPrimeMrTest(3, n, n_1, d)) return false;
  if (!_isPrimeMrTest(5, n, n_1, d)) return false;
  if (!_isPrimeMrTest(7, n, n_1, d)) return false;
  if (n < 3215031751) return true;
  if (!_isPrimeMrTest(11, n, n_1, d)) return false;
  if (n < 2152302898747) return true;
  if (!_isPrimeMrTest(13, n, n_1, d)) return false;
  if (n < 3474749660383) return true;
  if (!_isPrimeMrTest(17, n, n_1, d)) return false;
  if (!_isPrimeMrTest(19, n, n_1, d)) return false;
  if (n < 341550071728321) return true;
  if (!_isPrimeMrTest(23, n, n_1, d)) return false;
  if (!_isPrimeMrTest(29, n, n_1, d)) return false;
  if (!_isPrimeMrTest(31, n, n_1, d)) return false;
  if (n < 3825123056546413051) return true;
  return _isPrimeMrTest(37, n, n_1, d);
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

/// Returns whether padding the PrimeFFT to a power of two size is likely to be
/// faster than not padding it.
///
/// Experimentally, padding is usually a win when the largest prime factor of
/// `n - 1` is greater than 5. We also special case a few small sizes where this
/// simple heuristic is wrong.
bool primePaddingHeuristic(int n) {
  if (n == 31 || n == 61 || n == 101 || n == 241 || n == 251) return true;
  return largestPrimeFactor(n - 1) > 5;
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

/// Returns the number of trailing zeros of [x], where [x] is positive.
///
/// TODO: Only supports [x] below 2^48, for compatibility with JS.
int trailingZeros(int x) {
  x &= -x;
  return 63 - (((x & 0x5555555555555555) != 0 ? 1 : 0) |
      ((x & 0x3333333333333333) != 0 ? 2 : 0) |
      ((x & 0x0F0F0F0F0F0F0F0F) != 0 ? 4 : 0) |
      ((x & 0x00FF00FF00FF00FF) != 0 ? 8 : 0) |
      ((x & 0x0000FFFF0000FFFF) != 0 ? 16 : 0) |
      ((x & 0x00000000FFFFFFFF) != 0 ? 32 : 0));
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

/// Returns [g]^[k] mod [n].
int expMod(int g, int k, int n) {
  if (n < 3037000000) {  // sqrt(1 << 63) minus a bit for safety.
    int y = 1;
    while (k > 0) {
      if (k.isOdd) {
        y = (y * g) % n;
      }
      k >>>= 1;
      g = (g * g) % n;
    }
    return y;
  } else {
    // Fall back to slower BigInt version.
    final n_ = BigInt.from(n);
    BigInt g_ = BigInt.from(g);
    BigInt k_ = BigInt.from(k);
    BigInt y = BigInt.one;
    while (k_ > BigInt.zero) {
      if (k_.isOdd) {
        y = (y * g_) % n_;
      }
      k_ >>= 1;
      g_ = (g_ * g_) % n_;
    }
    return y.toInt();
  }
}

/// Returns the multiplicative inverse of [x] mod [n], where [n] is a prime.
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
