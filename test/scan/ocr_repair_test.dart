import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quantity misreads are repaired', () {
    expect(repairOcrDigits('l cup sugar'), '1 cup sugar');
    expect(repairOcrDigits('I tsp salt'), '1 tsp salt');
    expect(repairOcrDigits('| lb butter'), '1 lb butter');
    expect(repairOcrDigits('1/Z tsp soda'), '1/2 tsp soda');
    expect(repairOcrDigits('l/Z c. oleo'), '1/2 c. oleo');
    expect(repairOcrDigits('2 l/4 cups flour'), '2 1/4 cups flour');
    expect(repairOcrDigits('O.5 cup milk'), '0.5 cup milk');
    expect(repairOcrDigits('1O oz can'), '10 oz can');
    expect(repairOcrDigits('1 /2 cup'), '1/2 cup');
    expect(repairOcrDigits('1/ 2 cup'), '1/2 cup');
    expect(
      repairOcrDigits('Par 4  l2'),
      'Par 4  l2',
    ); // not a quantity position
  });
  test('words are left alone', () {
    for (final w in [
      'lemon zest',
      'Ice cream',
      'Oil for frying',
      '1 lb. lamb',
      'Oats',
    ]) {
      expect(repairOcrDigits(w), w);
    }
  });
}
