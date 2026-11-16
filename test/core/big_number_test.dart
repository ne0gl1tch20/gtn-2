import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';

void main() {
  group('BigNumber', () {
    test('parses and normalizes decimals', () {
      expect(BigNumber.parse('0012.3400').toString(), '12.34');
      expect(BigNumber.parse('-0.005').toString(), '-0.005');
      expect(BigNumber.parse('0.000').toString(), '0');
    });

    test('parses GTN1 scientific notation and magnitude suffixes', () {
      expect(BigNumber.parse('1e6').toString(), '1000000');
      expect(BigNumber.parse('1.25e3').toString(), '1250');
      expect(BigNumber.parse('1.5K').toString(), '1500');
      expect(BigNumber.parse('2Qa').toString(), '2000000000000000');
      expect(
        BigNumber.parse('1Vgn').toString(),
        '1${List.filled(63, '0').join()}',
      );
    });

    test('adds and subtracts without floating point loss', () {
      expect(
        (BigNumber.parse('0.1') + BigNumber.parse('0.2')).toString(),
        '0.3',
      );
      expect(
        (BigNumber.parse('100000000000000000000.01') - BigNumber.parse('0.01'))
            .toString(),
        '100000000000000000000',
      );
    });

    test('multiplies exact decimals and integers', () {
      expect(
        (BigNumber.parse('12.5') * BigNumber.parse('0.08')).toString(),
        '1',
      );
      expect(
        BigNumber.parse('999999999999999999').multiplyInt(3).toString(),
        '2999999999999999997',
      );
    });

    test('compares values at different scales', () {
      expect(BigNumber.parse('1.20'), BigNumber.parse('1.2'));
      expect(BigNumber.parse('1.19').compareTo(BigNumber.parse('1.2')), -1);
    });

    test('matches GTN1 DECIMAL128 precision and HALF_EVEN ties', () {
      expect(
        (BigNumber.parse('9999999999999999999999999999999999') +
                BigNumber.fromInt(1))
            .toString(),
        '10000000000000000000000000000000000',
      );
      expect(
        (BigNumber.parse('12345678901234567890123456789012345') +
                BigNumber.fromInt(0))
            .toString(),
        '12345678901234567890123456789012340',
      );
    });

    test('matches GTN1 subtraction floor and division scale/rounding', () {
      expect(
        (BigNumber.parse('1.00') - BigNumber.parse('1.01')).toString(),
        '0',
      );
      expect(
        (BigNumber.parse('1') / BigNumber.parse('6')).toString(),
        '0.1666666666666667',
      );
      expect((BigNumber.parse('1') / BigNumber.parse('8')).toString(), '0.125');
      expect((BigNumber.parse('12') / BigNumber.fromInt(0)).toString(), '0');
    });

    test('rounds integer multiplication to GTN1 DECIMAL128 precision', () {
      expect(
        BigNumber.parse('9999999999999999999999999999999999')
            .multiplyInt(3)
            .toString(),
        '30000000000000000000000000000000000',
      );
    });

    test('rounds integer powers to GTN1 DECIMAL128 precision', () {
      expect(
        BigNumber.parse('2').powInt(120).toString(),
        '1329227995784915872903807060280345000',
      );
    });

    test('formats GTN1 Standard suffix notation', () {
      expect(BigNumber.fromInt(0).format(), '0');
      expect(BigNumber.parse('0.009').format(), '0.01');
      expect(BigNumber.parse('0.5').format(), '0.5');
      expect(BigNumber.parse('999.5').format(), '1000');
      expect(BigNumber.fromInt(1234).format(), '1.23K');
      expect(BigNumber.fromInt(12345).format(), '12.35K');
      expect(BigNumber.parse('1e100').format(), '1.00e+100');
    });

    test('formats GTN1 Scientific and Engineering notation', () {
      expect(BigNumber.fromInt(1234).format('Scientific'), '1.23e+03');
      expect(BigNumber.parse('999.9').format('Scientific'), '1.00e+03');
      expect(BigNumber.fromInt(12345).format('Engineering'), '12.35e3');
      expect(BigNumber.parse('1e100').format('Engineering'), '10e99');
      expect(BigNumber.fromInt(1).format('Scientific'), '1.00e+00');
    });

    test('formatting does not change plain decimal serialization', () {
      final value = BigNumber.parse('12345.6789');
      expect(value.format(), '12.35K');
      expect(value.toString(), '12345.6789');
    });

    test('rejects malformed values', () {
      expect(() => BigNumber.parse('1x'), throwsFormatException);
      expect(() => BigNumber.parse('1.2.3'), throwsFormatException);
    });
  });
}
