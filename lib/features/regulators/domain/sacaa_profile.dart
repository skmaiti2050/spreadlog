import '../../flights/domain/flight.dart';
import '../../flights/domain/ledger_calculator.dart';
import '../../flights/domain/ledger_page.dart';
import '../../flights/domain/ledger_totals.dart';
import '../../reports/domain/sacaa_pdf_generator.dart';
import 'regulator_profile.dart';

/// SACAA (South African Civil Aviation Authority) CAR Part 61 Appendix A profile.
class SacaaProfile implements RegulatorProfile {
  const SacaaProfile();

  @override
  String get regulatorId => 'sacaa';

  @override
  String get name => 'SACAA Part 61 Appendix A';

  @override
  String get country => 'South Africa';

  @override
  int get entriesPerPage => 14;

  @override
  List<LedgerColumnDefinition> getColumns() {
    return const [
      // Left Page (1-13)
      LedgerColumnDefinition(columnNumber: 1, title: 'Date', width: 85),
      LedgerColumnDefinition(columnNumber: 2, title: 'Type', width: 90),
      LedgerColumnDefinition(columnNumber: 3, title: 'Registration', width: 85),
      LedgerColumnDefinition(columnNumber: 4, title: 'PIC / Commander', width: 120),
      LedgerColumnDefinition(columnNumber: 5, title: 'Dep Place', width: 75),
      LedgerColumnDefinition(columnNumber: 6, title: 'Dep Time', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 7, title: 'Arr Place', width: 75),
      LedgerColumnDefinition(columnNumber: 8, title: 'Arr Time', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 9, title: 'SE Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 10, title: 'SE Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 11, title: 'ME Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 12, title: 'ME Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 13, title: 'FSTD Actual', width: 75, isNumeric: true),

      // Right Page (14-32)
      LedgerColumnDefinition(columnNumber: 14, title: 'SE Dual Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 15, title: 'SE Dual Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 16, title: 'SE PIC Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 17, title: 'SE PIC Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 18, title: 'SE PICUS Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 19, title: 'SE PICUS Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 20, title: 'SE Copilot Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 21, title: 'SE Copilot Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 22, title: 'ME Dual Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 23, title: 'ME Dual Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 24, title: 'ME PIC Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 25, title: 'ME PIC Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 26, title: 'ME PICUS Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 27, title: 'ME PICUS Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 28, title: 'ME Copilot Day', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 29, title: 'ME Copilot Night', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 30, title: 'Inst Actual', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 31, title: 'Inst FSTD', width: 65, isNumeric: true),
      LedgerColumnDefinition(columnNumber: 32, title: 'Landings', width: 70),
      LedgerColumnDefinition(columnNumber: 33, title: 'Remarks', width: 160),
    ];
  }

  static const _calculator = LedgerCalculator();

  @override
  LedgerTotals calculateTotals(List<Flight> flights, {DateTime? cutoffDate}) {
    return _calculator.calculateTotals(flights, cutoffDate: cutoffDate);
  }

  @override
  List<LedgerPage> paginate(
    List<Flight> flights, {
    LedgerTotals? initialBroughtForward,
  }) {
    return _calculator.paginateLedger(
      flights,
      entriesPerPage: entriesPerPage,
      initialBroughtForward: initialBroughtForward ?? LedgerTotals.zero,
    );
  }

  @override
  Future<List<int>> generatePdf({
    required List<LedgerPage> pages,
    required String pilotName,
    required String licenceNumber,
  }) {
    return SacaaPdfGenerator.generateDocument(
      pages: pages,
      pilotName: pilotName,
      licenceNumber: licenceNumber,
    );
  }
}

