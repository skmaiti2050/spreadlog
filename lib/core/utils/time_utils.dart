enum TimeEntryFormat {
  hhMm,
  decimalTenths,
}

/// Aviation time format and conversion utilities.
///
/// Canonical representation is always integer minutes to avoid floating-point
/// accumulation errors.
class TimeUtils {
  const TimeUtils._();

  /// Converts duration in integer minutes to "HH:MM" formatted string.
  ///
  /// Example: 95 minutes -> "01:35", 0 minutes -> "00:00"
  static String formatMinutesToHhMm(int minutes) {
    if (minutes < 0) {
      final positiveFormatted = formatMinutesToHhMm(-minutes);
      return '-$positiveFormatted';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final hoursStr = hours.toString().padLeft(2, '0');
    final minsStr = mins.toString().padLeft(2, '0');
    return '$hoursStr:$minsStr';
  }

  /// Converts duration in integer minutes to decimal hours string formatted with 1 decimal place.
  ///
  /// In aviation, 1.3 means 1 hour 18 minutes (1.3 hours), not 1h 30m.
  /// Example: 78 minutes -> "1.3", 90 minutes -> "1.5"
  static String formatMinutesToDecimal(int minutes) {
    if (minutes < 0) {
      final positiveFormatted = formatMinutesToDecimal(-minutes);
      return '-$positiveFormatted';
    }
    final hours = minutes / 60.0;
    return hours.toStringAsFixed(1);
  }

  /// Parses an "HH:MM" or "H:MM" string into integer minutes.
  ///
  /// Returns null if format is invalid.
  static int? tryParseHhMmToMinutes(String input) {
    final trimmed = input.trim();
    final parts = trimmed.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) {
      return null;
    }
    if (hours < 0 || minutes < 0 || minutes >= 60) {
      return null;
    }
    return hours * 60 + minutes;
  }

  /// Parses decimal hours (e.g. "1.3" or "1.5") into integer minutes.
  ///
  /// Rounds to nearest integer minute: 1.3 hours = 78 minutes.
  /// Returns null if format is invalid.
  static int? tryParseDecimalToMinutes(String input) {
    final trimmed = input.trim();
    final value = double.tryParse(trimmed);
    if (value == null || value < 0) {
      return null;
    }
    return (value * 60).round();
  }

  /// Parses duration string according to the given [format].
  static int? tryParseToMinutes(String input, TimeEntryFormat format) {
    switch (format) {
      case TimeEntryFormat.hhMm:
        return tryParseHhMmToMinutes(input);
      case TimeEntryFormat.decimalTenths:
        return tryParseDecimalToMinutes(input);
    }
  }

  /// Formats minutes according to the given [format].
  static String formatMinutes(int minutes, TimeEntryFormat format) {
    switch (format) {
      case TimeEntryFormat.hhMm:
        return formatMinutesToHhMm(minutes);
      case TimeEntryFormat.decimalTenths:
        return formatMinutesToDecimal(minutes);
    }
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _monthNamesFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Formats [dt] into "dd MMM yyyy" (e.g. "15 Aug 2026").
  static String formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthNames[dt.month - 1];
    return '$day $month ${dt.year}';
  }

  /// Formats [dt] into "dd MMMM yyyy" (e.g. "15 August 2026").
  static String formatDateFull(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthNamesFull[dt.month - 1];
    return '$day $month ${dt.year}';
  }
}


