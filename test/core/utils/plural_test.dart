import 'package:aviation_logbook/core/utils/plural.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the singular only for exactly one', () {
    expect(plural(1, 'landing'), '1 landing');
    expect(plural(0, 'landing'), '0 landings');
    expect(plural(2, 'landing'), '2 landings');
  });

  test('accepts an irregular plural form', () {
    expect(plural(1, 'entry', 'entries'), '1 entry');
    expect(plural(3, 'entry', 'entries'), '3 entries');
  });
}
