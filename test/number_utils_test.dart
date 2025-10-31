import 'package:flutter_test/flutter_test.dart';
import 'package:game_sentry/src/utils/number_utils.dart';

void main() {
  group('NumberUtils', () {
    group('parseInt', () {
      test('should parse valid integer strings', () {
        expect(NumberUtils.parseInt('123'), equals(123));
        expect(NumberUtils.parseInt('-456'), equals(-456));
        expect(NumberUtils.parseInt('0'), equals(0));
      });

      test('should return null for invalid inputs', () {
        expect(NumberUtils.parseInt('abc'), isNull);
        expect(NumberUtils.parseInt('12.34'), isNull);
        expect(NumberUtils.parseInt(''), isNull);
        expect(NumberUtils.parseInt(null), isNull);
        expect(NumberUtils.parseInt('   '), isNull);
      });
    });

    group('parseIntWithDefault', () {
      test('should parse valid integer strings', () {
        expect(NumberUtils.parseIntWithDefault('123'), equals(123));
        expect(NumberUtils.parseIntWithDefault('-456'), equals(-456));
        expect(NumberUtils.parseIntWithDefault('0'), equals(0));
      });

      test('should return default value for invalid inputs', () {
        expect(NumberUtils.parseIntWithDefault('abc'), equals(0));
        expect(NumberUtils.parseIntWithDefault('12.34'), equals(0));
        expect(NumberUtils.parseIntWithDefault(''), equals(0));
        expect(NumberUtils.parseIntWithDefault(null), equals(0));
        expect(NumberUtils.parseIntWithDefault('   '), equals(0));
      });

      test('should return custom default value', () {
        expect(NumberUtils.parseIntWithDefault('abc', defaultValue: -1), equals(-1));
        expect(NumberUtils.parseIntWithDefault('12.34', defaultValue: 42), equals(42));
      });
    });

    group('isValidInt', () {
      test('should return true for valid integer strings', () {
        expect(NumberUtils.isValidInt('123'), isTrue);
        expect(NumberUtils.isValidInt('-456'), isTrue);
        expect(NumberUtils.isValidInt('0'), isTrue);
        expect(NumberUtils.isValidInt('+789'), isTrue);
      });

      test('should return false for invalid inputs', () {
        expect(NumberUtils.isValidInt('abc'), isFalse);
        expect(NumberUtils.isValidInt('12.34'), isFalse);
        expect(NumberUtils.isValidInt(''), isFalse);
        expect(NumberUtils.isValidInt(null), isFalse);
        expect(NumberUtils.isValidInt('   '), isFalse);
        expect(NumberUtils.isValidInt('123abc'), isFalse);
      });
    });
  });
}