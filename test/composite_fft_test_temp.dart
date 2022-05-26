
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:test/test.dart';
import 'util.dart';

void main() {
  /*test('digit reversal', () {
    expect(digitReverse(1234, [10, 10, 10, 10]), 4321);
    expect(digitReverse(47, [2, 2, 2, 2, 2, 2, 2, 2]), 244);
    expect(digitReverse(23, [2, 3, 5]), 28);
  });*/

  test('composite FFT', () {
final inp = [
        6.83109108, -1.09754201, -8.11753967, 9.80973486, //
        -9.56909702, -2.11975544, 6.89938119, -0.67541430, //
        -9.31333260, -5.13379255, -7.69723465, 5.36089786, //
        6.90840982, 8.88303985, -2.11891585, -0.01432752, //
        3.39160403, 8.64406112, -4.54784126, 9.90211104, //
        8.31288006, -4.84342130, 0.02213279, -0.56825329, //
        2.86272805, -9.34921645, 6.30952647, 7.12732962, //
        -7.36867875, 9.11378385, -2.56167207, -1.49541103, //
        9.15850988, 8.18244078, 5.05322594, 3.60502738, //
        -2.77817572, 1.44597350, 3.11518878, -0.97501164, //
        9.96870582, -9.82270552, -3.30194580, 1.79349481, //
        7.53834607, 2.11578167, 6.60501943, 9.06302711, //
        8.59435920, 1.84280418, -0.45390486, 1.28829796, //
        1.21445606, -5.63611552, 0.00914363, -2.28062594, //
        -4.24084959, 5.75056416, -3.65356776, -1.89144165, //
        -0.46875680, 9.44276580, 0.55735809, 0.18237717, //
        9.81957950, -3.18323300, -1.96109676, 6.56759060, //
        9.41362756, -2.18803544, 0.81318010, -1.40398832, //
        -5.95631260, -0.65105925, -7.80582352, 0.89418433, //
        -1.10528484, 2.18461708, 4.03247184, -5.12771067, //
        -1.30763843, 7.35442456, -5.99734448, -2.00021774, //
        -1.08694415, 4.21060244, -1.89120812, 5.16004596, //
        6.15368975, -2.87204401, 9.05939506, 8.88771486, //
        0.74742951, 1.89956421, -8.24782325, 0.96367309, //
        -1.68938384, -0.10633388, -8.96655291, -0.15240901, //
        -5.28730664, -9.94514116, 7.98284397, -8.89476229, //
        -9.30268289, -7.65396839, -8.94496355, 1.94464159, //
        7.93712549, 4.06628124, 9.94854887, 9.81222871, //
        -4.30917306, -9.35282346, 7.07154097, 0.16755252, //
        0.57590676, -2.51186546, 9.24851779, -1.14182654, //
        -8.04905529, -6.82998533, 2.53196745, 5.62948368, //
        -3.73438682, -1.36627646, -4.09159788, -7.87124430, //
        -4.05096064, -7.00821549, -7.94496808, 7.11564270, //
        -5.03647281, -6.72953852, -6.94095078, 7.49418335, //
        3.25848652, -8.80773810, -1.12710340, 1.90584418, //
        4.62687873, -6.49960747, 5.57046015, 4.83698617, //
        1.04215005, 9.96720434, -3.31043410, -0.08020474, //
        0.73727717, -2.75208665, 0.52907466, -9.62408347, //
        -5.82586243, -2.31968585, -4.39928791, 9.06047909, //
        4.36745818, -7.48774058, -0.30159702, 1.49168278, //
        8.49753169, 8.67204624, -7.10001023, 8.57328824, //
        -4.13480541, -6.93826818, 3.42105867, -5.12240763, //
        7.85239938, -3.80123533, 9.35432245, -0.28513645, //
        -6.52552028, 4.81344225, 2.07368544, 5.22609759, //
        -5.48101668, 6.25393683, 7.53864465, 7.16867935, //
        6.06340228, 3.44393510, 2.75192446, 9.51775822, //
        -6.28389528, 3.90665959, 5.10645427, 7.88080592, //
        -0.88138631, 0.11768236, 1.99356736, 5.67618753, //
        8.71985770, 7.44140457, -2.57090893, 4.83422380, //
        -2.80947541, -4.04560515, 1.95336508, 4.49943382, //
        0.75329019, -3.26087022, 8.19607146, 9.12507560, //
        -4.96069179, -1.40634459, -2.94401689, -8.51948501, //
        9.00090957, 7.37917992, -0.97425151, 3.42912077, //
        1.83177623, -9.84259260, 8.10969882, 9.65437465, //
        -6.38493477, -4.92925008, -6.83156336, -5.73327283, //
        5.56335090, 2.13004587, 7.89921530, -2.42514784, //
        -3.49974965, -7.97784152, -2.16105771, 4.55549417, //
        3.96277716, -5.33770948, 0.46576581, 5.91880129, //
        2.07878372, 7.39778296, 7.13100690, 4.46345612, //
        3.67771467, 0.51493855, 9.66342647, -7.38483858, //
        -9.32702656, 8.68158792, 5.09359587, 4.46561394, //
        -9.33729458, -0.69550305, 6.18984166, -2.41827813, //
        -1.84669365, -9.08521795, -1.49159742, -2.38425735, //
        -5.86713134, 1.19706034, 3.03008507, -0.72069608, //
        1.70519373, -1.98444189, -5.55212302, 5.02772530, //
        -8.59953699, 5.88335950, -3.17357235, -4.67050148, //
        -1.96411027, 4.57336169, 6.73386574, 4.49207505, //
        -6.81521686, 5.50857679, 4.37868396, -2.94578410, //
        -0.51292881, -6.99355808, -6.92405189, -8.47755837, //
        2.01928535, 6.89173044, 2.53602439, -7.55030380, //
        0.38699953, -5.40698939, -1.24894573, 3.00632982, //
        -0.91061807, -3.34459786, -5.71831785, 0.64545759, //
        -6.04061283, -8.08522695, -5.46233924, -2.37364537, //
        9.47557392, 7.64292950, 0.82081795, -1.78573254, //
        1.86691331, 0.67481298, 5.19574037, -9.33873873,
      ];
final exp = [
        42.71316770, 80.71671607, -15.80759528, 7.49186811, //
        96.85926663, -124.75899919, -56.68827762, -28.89916793, //
        49.11693733, -37.29345891, 84.38208336, 97.91389768, //
        -43.47635106, 3.31781682, 28.99135596, 13.93350784, //
        66.99464004, 23.20851074, -20.71581341, -53.91672742, //
        -38.49319244, 126.48872805, 4.97129059, -64.72740902, //
        -20.95966361, -16.61430518, 98.98061121, 76.85527746, //
        92.08918882, 10.09135390, -21.13390668, -10.99851192, //
        -83.53818994, -8.26562903, 22.53105982, 95.05721831, //
        -69.98020250, -36.74178778, 25.04912597, 147.55136241, //
        13.60718376, 39.86524718, 8.35393488, 76.85750318, //
        -96.68125535, -2.19941476, 112.01981755, 0.62890641, //
        -22.71380500, -112.13085819, 25.48547099, 49.34686373, //
        34.91939400, 37.55349206, 119.44230280, -41.77040682, //
        59.23020492, 17.85946601, -88.25169547, -113.01766011, //
        130.57926756, 36.70030435, -120.47667325, -15.14119148, //
        10.46513750, -35.68274753, 7.24248805, 18.96042865, //
        165.41793409, 23.37542751, 52.65333971, 111.27136293, //
        97.75170379, 92.82853548, -41.99857043, 92.49410441, //
        120.23423861, -52.92236261, 49.49901163, 20.24849101, //
        -14.31276416, -56.69583619, -13.69750405, -4.44855055, //
        82.29396209, 13.80443201, -60.41195015, 146.26585273, //
        35.65870107, 41.01248754, 82.78646187, -1.39683326, //
        11.88130522, 151.99796652, 108.68539018, -66.71322601, //
        -14.27109431, -125.33569121, 46.67181688, 87.56884121, //
        22.91781107, 48.60954847, -37.68622992, -96.16271078, //
        26.76271677, 35.28545477, 13.25396064, 86.68070478, //
        -92.48404032, -36.60162508, 100.41159091, 10.64903460, //
        68.28658919, 134.37129377, 17.44388583, -118.59263614, //
        97.42081394, -88.74430043, 77.28307608, -11.60747008, //
        32.57810408, -13.24980897, 173.10849928, -84.83966758, //
        14.23148262, -183.90586401, -48.29376100, 29.78404294, //
        -27.65387857, -25.56353691, -53.98527704, 120.41219722, //
        -18.31381099, -60.07907771, -29.91681752, 10.61479264, //
        8.14355017, 7.08212625, 14.96466721, -17.48752820, //
        -82.46133691, -11.07603353, 71.00463704, -40.42686755, //
        86.74970255, -57.93585140, 52.14908026, 50.39370525, //
        51.40916110, 192.98250461, -34.20625132, -143.06631096, //
        28.80272772, 6.98043194, 25.26262763, -96.00792098, //
        -92.63284347, -21.81658831, 111.40172702, 86.48490690, //
        -76.57020131, -13.19183094, 24.87267504, -0.33996024, //
        -18.30838677, -42.65082237, -13.63128112, 22.37558901, //
        35.95725124, 83.17256480, -165.09076542, 47.13523490, //
        -39.39441941, 42.82410793, -47.39291097, 18.80574984, //
        138.46706966, -24.37285699, -67.58663201, 34.73624790, //
        -73.59637852, 59.99947070, -113.77918857, 31.11467560, //
        -31.08812808, -35.85238478, -75.72918673, 4.91333110, //
        20.09114419, 41.23923926, -77.45924155, -18.22227428, //
        10.25065826, -57.97794696, 163.16026842, -17.09854484, //
        74.69415076, 10.97001049, -49.64662605, -15.55868122, //
        73.03432890, -3.13744475, -32.02846500, 137.82586048, //
        -18.18858648, -36.06210345, 43.53404077, -20.27014315, //
        111.40365281, -122.65513661, 0.34365016, 35.15202922, //
        27.47835030, -67.75692891, 16.62426877, -193.65807916, //
        9.95944765, -80.38455651, 33.09704315, -6.18502753, //
        -35.63371028, -66.91489397, 107.63573594, 73.29975749, //
        36.22176028, -101.98451443, -60.27664207, 50.59031758, //
        -71.76457674, 72.84693798, -94.30983223, -66.21405888, //
        -67.74577061, -1.07913094, -4.89003105, 27.37381340, //
        -69.24665231, -3.24607968, 12.97468964, 88.39611624, //
        7.33273936, -39.77424132, -83.84131058, -49.64941959, //
        -34.91170758, -53.89763453, 142.55481602, 107.81196527, //
        -91.94945819, -16.22094990, -84.63591737, 65.19004101, //
        2.97860523, -67.48042260, -53.70748531, -101.21353265, //
        -50.33179120, -4.47573730, -128.63937498, -6.28711453, //
        -22.76716048, 26.99842963, 86.60736539, 58.91697744, //
        111.39432322, -64.77186726, 42.95566025, 16.33759657, //
        -0.83807523, -74.29786639, 12.25124164, -25.06378810, //
        3.71158424, -27.47004090, 129.39465199, -56.20821847, //
        -111.30413176, -197.32419821, 17.26145699, 0.50001957, //
        103.28541401, -36.95357719, 9.49178309, 28.35092921, //
        11.38012436, 48.75629828, -84.47958148, -33.21305090, //
        21.16272763, -44.69575457, -58.21627778, -41.27081723, //
        -99.45576496, -24.49798002, 20.97727179, 28.39457318, //
        -162.83846487, 101.67986414, 13.49637236, -15.52157812,
      ];
    print("GOOD");
    compositeFft(makeArray(inp));
    print('\n\nBAD');
    final out = makeArray(inp);
    CompositeFFT(out.length).inPlaceFft(out);
    //print(out);
    expectClose(toFloats(out), exp);
  });

  test('prime FFT', () {
final inp = [
        -8.62789495, 5.85539056, 3.19853546, 9.71930666, //
        0.21157144, -7.71712852, 8.97832440, -5.71433990, //
        5.02641968, -8.03952519, 7.10462549, -0.23394908, //
        9.80845936, 6.40732978, 9.93739231, 9.42287662, //
        8.85897813, 8.89862082, 8.36320156, -5.09432730, //
        -3.85895797, 9.51769029,
      ];
final exp = [
        49.00065490, 23.02194475, -65.99637102, 17.38862932, //
        3.65969569, 17.62936290, -8.06793523, 9.37884187, //
        -5.77225097, -15.54570881, -8.91067030, -34.04570520, //
        -8.39414156, -17.49272397, 2.28873708, 13.53987583, //
        -7.60969212, 18.32920822, -42.72704181, 30.72595505, //
        -2.37782915, 1.47961620,
      ];
    final out = makeArray(inp);
    PrimePaddedFFT(out.length).inPlaceFft(out);
    expectClose(toFloats(out), exp);
  });

  /*test('prime strided FFT', () {
final inp = [
        -8.62789495, 5.85539056, 0.0, 0.0, 3.19853546, 9.71930666, 0.0, 0.0, //
        0.21157144, -7.71712852, 0.0, 0.0, 8.97832440, -5.71433990, 0.0, 0.0, //
        5.02641968, -8.03952519, 0.0, 0.0, 7.10462549, -0.23394908, 0.0, 0.0, //
        9.80845936, 6.40732978, 0.0, 0.0, 9.93739231, 9.42287662, 0.0, 0.0, //
        8.85897813, 8.89862082, 0.0, 0.0, 8.36320156, -5.09432730, 0.0, 0.0, //
        -3.85895797, 9.51769029, 0.0, 0.0,
      ];
final exp = [
        0.0, 0.0, 0.0, 0.0, 49.00065490, 23.02194475, 0.0, 0.0, 0.0, 0.0, -65.99637102, 17.38862932, //
        0.0, 0.0, 0.0, 0.0, 3.65969569, 17.62936290, 0.0, 0.0, 0.0, 0.0, -8.06793523, 9.37884187, //
        0.0, 0.0, 0.0, 0.0, -5.77225097, -15.54570881, 0.0, 0.0, 0.0, 0.0, -8.91067030, -34.04570520, //
        0.0, 0.0, 0.0, 0.0, -8.39414156, -17.49272397, 0.0, 0.0, 0.0, 0.0, 2.28873708, 13.53987583, //
        0.0, 0.0, 0.0, 0.0, -7.60969212, 18.32920822, 0.0, 0.0, 0.0, 0.0, -42.72704181, 30.72595505, //
        0.0, 0.0, 0.0, 0.0, -2.37782915, 1.47961620,
      ];
    final input = makeArray(inp);
    final out = Float64x2List(exp.length ~/ 2);
    PrimePaddedFFT(input.length ~/ 2).stridedFft(input, 2, 0, out, 3, 2);
    expectClose(toFloats(out), exp);
  });*/

  test('naive FFT', () {
final inp = [
        -8.62789495, 5.85539056, 3.19853546, 9.71930666, //
        0.21157144, -7.71712852, 8.97832440, -5.71433990, //
        5.02641968, -8.03952519, 7.10462549, -0.23394908, //
        9.80845936, 6.40732978, 9.93739231, 9.42287662, //
        8.85897813, 8.89862082, 8.36320156, -5.09432730, //
        -3.85895797, 9.51769029,
      ];
final exp = [
        49.00065490, 23.02194475, -65.99637102, 17.38862932, //
        3.65969569, 17.62936290, -8.06793523, 9.37884187, //
        -5.77225097, -15.54570881, -8.91067030, -34.04570520, //
        -8.39414156, -17.49272397, 2.28873708, 13.53987583, //
        -7.60969212, 18.32920822, -42.72704181, 30.72595505, //
        -2.37782915, 1.47961620,
      ];
    final out = makeArray(inp);
    NaiveFFT(out.length).inPlaceFft(out);
    expectClose(toFloats(out), exp);
  });

  /*test('naive strided FFT', () {
final inp = [
        -8.62789495, 5.85539056, 0.0, 0.0, 3.19853546, 9.71930666, 0.0, 0.0, //
        0.21157144, -7.71712852, 0.0, 0.0, 8.97832440, -5.71433990, 0.0, 0.0, //
        5.02641968, -8.03952519, 0.0, 0.0, 7.10462549, -0.23394908, 0.0, 0.0, //
        9.80845936, 6.40732978, 0.0, 0.0, 9.93739231, 9.42287662, 0.0, 0.0, //
        8.85897813, 8.89862082, 0.0, 0.0, 8.36320156, -5.09432730, 0.0, 0.0, //
        -3.85895797, 9.51769029, 0.0, 0.0,
      ];
final exp = [
        0.0, 0.0, 0.0, 0.0, 49.00065490, 23.02194475, 0.0, 0.0, 0.0, 0.0, -65.99637102, 17.38862932, //
        0.0, 0.0, 0.0, 0.0, 3.65969569, 17.62936290, 0.0, 0.0, 0.0, 0.0, -8.06793523, 9.37884187, //
        0.0, 0.0, 0.0, 0.0, -5.77225097, -15.54570881, 0.0, 0.0, 0.0, 0.0, -8.91067030, -34.04570520, //
        0.0, 0.0, 0.0, 0.0, -8.39414156, -17.49272397, 0.0, 0.0, 0.0, 0.0, 2.28873708, 13.53987583, //
        0.0, 0.0, 0.0, 0.0, -7.60969212, 18.32920822, 0.0, 0.0, 0.0, 0.0, -42.72704181, 30.72595505, //
        0.0, 0.0, 0.0, 0.0, -2.37782915, 1.47961620,
      ];
    final input = makeArray(inp);
    final out = Float64x2List(exp.length ~/ 2);
    NaiveFFT(input.length ~/ 2).stridedFft(input, 2, 0, out, 3, 2);
    expectClose(toFloats(out), exp);
  });*/
}
