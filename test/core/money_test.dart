import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/core/utils/money.dart';
import 'package:lifemate/core/utils/validators.dart';

void main() {
  group('Money.parseToMinor', () {
    test('parses whole and decimal USD amounts exactly', () {
      expect(Money.parseToMinor('5', 'USD'), 500);
      expect(Money.parseToMinor('4.5', 'USD'), 450);
      expect(Money.parseToMinor('0.10', 'USD'), 10);
      expect(Money.parseToMinor('1,234.56', 'USD'), 123456);
      expect(Money.parseToMinor(' 12. ', 'USD'), 1200);
    });

    test('avoids floating-point errors (0.1 + 0.2 case)', () {
      final a = Money.parseToMinor('0.1', 'USD')!;
      final b = Money.parseToMinor('0.2', 'USD')!;
      expect(a + b, Money.parseToMinor('0.3', 'USD'));
    });

    test('rejects invalid input', () {
      expect(Money.parseToMinor('', 'USD'), isNull);
      expect(Money.parseToMinor('abc', 'USD'), isNull);
      expect(Money.parseToMinor('-5', 'USD'), isNull);
      expect(Money.parseToMinor('1.234', 'USD'), isNull); // too many decimals
      expect(Money.parseToMinor('1.2.3', 'USD'), isNull);
      expect(Money.parseToMinor('9999999999', 'USD'), isNull); // too large
    });

    test('KHR has no decimals', () {
      expect(Money.parseToMinor('12000', 'KHR'), 12000);
      expect(Money.parseToMinor('12000.5', 'KHR'), isNull);
    });
  });

  group('Money.format', () {
    test('formats with symbol, grouping and sign', () {
      expect(Money.format(123456, 'USD'), r'$1,234.56');
      expect(Money.format(5, 'USD'), r'$0.05');
      expect(Money.format(-100, 'USD'), r'-$1.00');
      expect(Money.format(100, 'USD', signed: true), r'+$1.00');
      expect(Money.format(0, 'USD', signed: true), r'$0.00');
      expect(Money.format(12000, 'KHR'), '12,000៛');
    });

    test('toInputText round-trips through parseToMinor', () {
      for (final minor in [1, 50, 450, 123456]) {
        final text = Money.toInputText(minor, 'USD');
        expect(Money.parseToMinor(text, 'USD'), minor);
      }
      expect(Money.toInputText(12000, 'KHR'), '12000');
    });
  });

  group('AppValidators.amount', () {
    final usd = AppValidators.amount('USD');
    test('accepts valid amounts', () {
      expect(usd('4.50'), isNull);
      expect(usd('1'), isNull);
    });
    test('rejects empty, zero and malformed amounts', () {
      expect(usd(''), isNotNull);
      expect(usd('0'), isNotNull);
      expect(usd('0.00'), isNotNull);
      expect(usd('1.999'), isNotNull);
      expect(AppValidators.amount('KHR')('10.5'), contains('whole number'));
    });
  });
}
