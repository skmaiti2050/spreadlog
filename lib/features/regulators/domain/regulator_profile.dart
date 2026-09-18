import '../../flights/domain/flight.dart';
import '../../flights/domain/ledger_page.dart';
import '../../flights/domain/ledger_totals.dart';

/// Column definition for a regulator ledger view.
class LedgerColumnDefinition {
  final int columnNumber;
  final String title;
  final String subtitle;
  final double width;
  final bool isNumeric;

  const LedgerColumnDefinition({
    required this.columnNumber,
    required this.title,
    this.subtitle = '',
    this.width = 70.0,
    this.isNumeric = false,
  });
}

/// Abstract contract for civil aviation authorities (SACAA, FAA, EASA, DGCA).
/// Keeps regulator-specific rules, column layouts, and PDF templates 100% modular.
abstract class RegulatorProfile {
  String get regulatorId;
  String get name;
  String get country;
  int get entriesPerPage;

  List<LedgerColumnDefinition> getColumns();

  LedgerTotals calculateTotals(List<Flight> flights, {DateTime? cutoffDate});

  List<LedgerPage> paginate(
    List<Flight> flights, {
    LedgerTotals? initialBroughtForward,
  });

  Future<List<int>> generatePdf({
    required List<LedgerPage> pages,
    required String pilotName,
    required String licenceNumber,
  });
}

