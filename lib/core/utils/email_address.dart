/// Loose check that [value] looks like `name@domain.tld`. Enough to catch a
/// username or a typo before a mail server rejects it; not RFC 5322.
bool isEmailAddress(String? value) =>
    value != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
