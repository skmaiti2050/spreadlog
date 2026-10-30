import 'package:aviation_logbook/core/utils/email_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts ordinary addresses', () {
    expect(isEmailAddress('pilot@example.com'), isTrue);
    expect(isEmailAddress('first.last+logbook@mail.co.za'), isTrue);
  });

  test('rejects usernames, blanks and partial addresses', () {
    expect(isEmailAddress(null), isFalse);
    expect(isEmailAddress(''), isFalse);
    expect(isEmailAddress('b49817f6ef49a5'), isFalse);
    expect(isEmailAddress('pilot@localhost'), isFalse);
    expect(isEmailAddress('pilot @example.com'), isFalse);
  });
}
