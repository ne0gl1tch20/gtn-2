import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';

void main() {
  group('BigNumber', () {
    test('parses and normalizes decimals', () {
      expect(BigNumber.parse('0012.3400').toString(), '12.34');
      expect(BigNumber.parse('-0.005').toString(), '-0.005');
      expect(BigNumber.parse('0.000').toString(), '0');
    });

    test('adds and subtracts without floating point loss', () {
      expect(
        (BigNumber.parse('0.1') + BigNumber.parse('0.2')).toString(),
        '0.3',
      );
      expect(
        (BigNumber.parse('100000000000000000000.01') -
                BigNumber.parse('0.01'))
            .toString(),
        '100000000000000000000',
      );
    });

    test('multiplies exact decimals and integers', () {
      expect(
        (BigNumber.parse('12.5') * BigNumber.parse('0.08')).toString(),
        '1',
      );
      expect(BigNumber.parse('999999999999999999').multiplyInt(3).toString(),
          '2999999999999999997');
    });

    test('compares values at different scales', () {
      expect(BigNumber.parse('1.20'), BigNumber.parse('1.2'));
      expect(BigNumber.parse('1.19').compareTo(BigNumber.parse('1.2')), -1);
    });

    test('rejects malformed values', () {
      expect(() => BigNumber.parse('1e6'), throwsFormatException);
      expect(() => BigNumber.parse('1.2.3'), throwsFormatException);
    });
  });
}
