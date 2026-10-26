/// Formats a count with the matching noun form: `plural(1, 'flight')` gives
/// "1 flight", `plural(3, 'flight')` gives "3 flights".
///
/// Pass [pluralForm] for irregular nouns (`plural(2, 'entry', 'entries')`).
String plural(int count, String singular, [String? pluralForm]) =>
    '$count ${count == 1 ? singular : (pluralForm ?? '${singular}s')}';
