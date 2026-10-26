import 'package:aviation_logbook/core/utils/time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeUtils', () {
    test('formatMinutesToHhMm formats correctly', () {
      expect(TimeUtils.formatMinutesToHhMm(0), '00:00');
      expect(TimeUtils.formatMinutesToHhMm(1), '00:01');
      expect(TimeUtils.formatMinutesToHhMm(59), '00:59');
      expect(TimeUtils.formatMinutesToHhMm(60), '01:00');
      expect(TimeUtils.formatMinutesToHhMm(95), '01:35');
      expect(TimeUtils.formatMinutesToHhMm(1439), '23:59');
    });

    test('formatMinutesToDecimal formats correctly', () {
      expect(TimeUtils.formatMinutesToDecimal(78), '1.3');
      expect(TimeUtils.formatMinutesToDecimal(90), '1.5');
      expect(TimeUtils.formatMinutesToDecimal(0), '0.0');
    });

    test('tryParseHhMmToMinutes parses correctly', () {
      expect(TimeUtils.tryParseHhMmToMinutes('01:35'), 95);
      expect(TimeUtils.tryParseHhMmToMinutes('1:35'), 95);
      expect(TimeUtils.tryParseHhMmToMinutes('00:00'), 0);
      expect(TimeUtils.tryParseHhMmToMinutes('invalid'), isNull);
      expect(TimeUtils.tryParseHhMmToMinutes('01:60'), isNull);
    });

    test('tryParseDecimalToMinutes parses correctly', () {
      expect(TimeUtils.tryParseDecimalToMinutes('1.3'), 78);
      expect(TimeUtils.tryParseDecimalToMinutes('1.5'), 90);
      expect(TimeUtils.tryParseDecimalToMinutes('invalid'), isNull);
    });

    test('formatLogbookDate uses the Appendix A dd/mm/yyyy format', () {
      expect(TimeUtils.formatLogbookDate(DateTime(2026, 9, 5)), '05/09/2026');
      expect(TimeUtils.formatLogbookDate(DateTime(2026, 12, 31)), '31/12/2026');
    });
  });
}

