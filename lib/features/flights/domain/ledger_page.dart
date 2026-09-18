import 'flight.dart';
import 'ledger_totals.dart';

/// Represents a single physical/digital logbook page with its entries and totals.
class LedgerPage {
  final int pageNumber;
  final List<Flight> entries;
  final LedgerTotals broughtForward;
  final LedgerTotals pageTotals;
  final LedgerTotals carriedForward;

  const LedgerPage({
    required this.pageNumber,
    required this.entries,
    required this.broughtForward,
    required this.pageTotals,
    required this.carriedForward,
  });

  /// Invariant: carriedForward must equal broughtForward + pageTotals
  bool get isValidCarryForward => carriedForward == (broughtForward + pageTotals);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerPage &&
          runtimeType == other.runtimeType &&
          pageNumber == other.pageNumber &&
          broughtForward == other.broughtForward &&
          pageTotals == other.pageTotals &&
          carriedForward == other.carriedForward;

  @override
  int get hashCode => Object.hash(pageNumber, broughtForward, pageTotals, carriedForward);

  @override
  String toString() =>
      'LedgerPage(#$pageNumber, entries: ${entries.length}, PageTotal: ${pageTotals.totalFlightTimeMinutes}m, Carried: ${carriedForward.totalFlightTimeMinutes}m)';
}

