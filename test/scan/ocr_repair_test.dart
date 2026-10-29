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
      repairOcrDigits('Va teaspoon baking soda'),
      '¼ teaspoon baking soda',
    );
    expect(repairOcrDigits('V4 cup sugar'), '¼ cup sugar');
    expect(repairOcrDigits('Vz cup butter'), '½ cup butter');
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
      'Va cooking spray',
      'Vanilla cup custard',
    ]) {
      expect(repairOcrDigits(w), w);
    }
  });

  test('"V2 C." before an abbreviated cup, "0Z" after an amount', () {
    expect(repairOcrDigits('V2 C. dry bread crumbs'), '½ C. dry bread crumbs');
    expect(
      repairOcrDigits('1- 16 0Z can whole berry cranberry sauce'),
      '1- 16 oz can whole berry cranberry sauce',
    );
    expect(repairOcrDigits('Ozark ham'), 'Ozark ham');
  });
}
