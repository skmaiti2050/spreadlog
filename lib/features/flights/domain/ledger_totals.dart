/// Comprehensive aviation ledger totals value object.
///
/// Stores all accumulated values as deterministic integer minutes and counts.
class LedgerTotals {
  // Single Engine Day
  final int seDayDual;
  final int seDayPic;
  final int seDayPicus;
  final int seDayCopilot;

  // Single Engine Night
  final int seNightDual;
  final int seNightPic;
  final int seNightPicus;
  final int seNightCopilot;

  // Multi Engine Day
  final int meDayDual;
  final int meDayPic;
  final int meDayPicus;
  final int meDayCopilot;

  // Multi Engine Night
  final int meNightDual;
  final int meNightPic;
  final int meNightPicus;
  final int meNightCopilot;

  // Instrument Time
  final int instrumentActual;
  final int instrumentFstd;

  // Instructor Time
  final int instructorSe;
  final int instructorMe;
  final int instructorFstd;

  // FSTD Actual Flight Device Time (SACAA Column 13)
  final int fstdActual;

  // Landings
  final int landingsDay;
  final int landingsNight;

  // Solo Cross-Country
  final int soloCrossCountryMinutes;
  final int soloCrossCountryCount;

  const LedgerTotals({
    this.seDayDual = 0,
    this.seDayPic = 0,
    this.seDayPicus = 0,
    this.seDayCopilot = 0,
    this.seNightDual = 0,
    this.seNightPic = 0,
    this.seNightPicus = 0,
    this.seNightCopilot = 0,
    this.meDayDual = 0,
    this.meDayPic = 0,
    this.meDayPicus = 0,
    this.meDayCopilot = 0,
    this.meNightDual = 0,
    this.meNightPic = 0,
    this.meNightPicus = 0,
    this.meNightCopilot = 0,
    this.instrumentActual = 0,
    this.instrumentFstd = 0,
    this.instructorSe = 0,
    this.instructorMe = 0,
    this.instructorFstd = 0,
    this.fstdActual = 0,
    this.landingsDay = 0,
    this.landingsNight = 0,
    this.soloCrossCountryMinutes = 0,
    this.soloCrossCountryCount = 0,
  });

  static const LedgerTotals zero = LedgerTotals();

  // Derived calculations
  int get totalSingleEngineDay =>
      seDayDual + seDayPic + seDayPicus + seDayCopilot;

  int get totalSingleEngineNight =>
      seNightDual + seNightPic + seNightPicus + seNightCopilot;

  int get totalSingleEngine => totalSingleEngineDay + totalSingleEngineNight;

  int get totalMultiEngineDay =>
      meDayDual + meDayPic + meDayPicus + meDayCopilot;

  int get totalMultiEngineNight =>
      meNightDual + meNightPic + meNightPicus + meNightCopilot;

  int get totalMultiEngine => totalMultiEngineDay + totalMultiEngineNight;

  int get totalDay => totalSingleEngineDay + totalMultiEngineDay;
  int get totalNight => totalSingleEngineNight + totalMultiEngineNight;

  int get totalDual => seDayDual + seNightDual + meDayDual + meNightDual;
  int get totalPic => seDayPic + seNightPic + meDayPic + meNightPic;
  int get totalPicus => seDayPicus + seNightPicus + meDayPicus + meNightPicus;
  int get totalCopilot =>
      seDayCopilot + seNightCopilot + meDayCopilot + meNightCopilot;

  int get totalInstructor => instructorSe + instructorMe + instructorFstd;
  int get totalInstrument => instrumentActual + instrumentFstd;
  int get totalLandings => landingsDay + landingsNight;

  /// Deterministic Total Flight Time in integer minutes: Columns 14 to 29.
  ///
  /// FSTD time (Col 13) is not flight time. The printed SACAA logbook footer
  /// reads "Grand total flight time (columns 14 to 29)", and the worked
  /// logbook summaries in SA-CATS 61 exclude FSTD hours from their totals.
  /// (Appendix A's "sum of columns 13 to 29" contradicts both.)
  int get totalFlightTimeMinutes => totalSingleEngine + totalMultiEngine;

  LedgerTotals operator +(LedgerTotals other) {
    return LedgerTotals(
      seDayDual: seDayDual + other.seDayDual,
      seDayPic: seDayPic + other.seDayPic,
      seDayPicus: seDayPicus + other.seDayPicus,
      seDayCopilot: seDayCopilot + other.seDayCopilot,
      seNightDual: seNightDual + other.seNightDual,
      seNightPic: seNightPic + other.seNightPic,
      seNightPicus: seNightPicus + other.seNightPicus,
      seNightCopilot: seNightCopilot + other.seNightCopilot,
      meDayDual: meDayDual + other.meDayDual,
      meDayPic: meDayPic + other.meDayPic,
      meDayPicus: meDayPicus + other.meDayPicus,
      meDayCopilot: meDayCopilot + other.meDayCopilot,
      meNightDual: meNightDual + other.meNightDual,
      meNightPic: meNightPic + other.meNightPic,
      meNightPicus: meNightPicus + other.meNightPicus,
      meNightCopilot: meNightCopilot + other.meNightCopilot,
      instrumentActual: instrumentActual + other.instrumentActual,
      instrumentFstd: instrumentFstd + other.instrumentFstd,
      instructorSe: instructorSe + other.instructorSe,
      instructorMe: instructorMe + other.instructorMe,
      instructorFstd: instructorFstd + other.instructorFstd,
      fstdActual: fstdActual + other.fstdActual,
      landingsDay: landingsDay + other.landingsDay,
      landingsNight: landingsNight + other.landingsNight,
      soloCrossCountryMinutes:
          soloCrossCountryMinutes + other.soloCrossCountryMinutes,
      soloCrossCountryCount:
          soloCrossCountryCount + other.soloCrossCountryCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerTotals &&
          runtimeType == other.runtimeType &&
          seDayDual == other.seDayDual &&
          seDayPic == other.seDayPic &&
          seDayPicus == other.seDayPicus &&
          seDayCopilot == other.seDayCopilot &&
          seNightDual == other.seNightDual &&
          seNightPic == other.seNightPic &&
          seNightPicus == other.seNightPicus &&
          seNightCopilot == other.seNightCopilot &&
          meDayDual == other.meDayDual &&
          meDayPic == other.meDayPic &&
          meDayPicus == other.meDayPicus &&
          meDayCopilot == other.meDayCopilot &&
          meNightDual == other.meNightDual &&
          meNightPic == other.meNightPic &&
          meNightPicus == other.meNightPicus &&
          meNightCopilot == other.meNightCopilot &&
          instrumentActual == other.instrumentActual &&
          instrumentFstd == other.instrumentFstd &&
          instructorSe == other.instructorSe &&
          instructorMe == other.instructorMe &&
          instructorFstd == other.instructorFstd &&
          fstdActual == other.fstdActual &&
          landingsDay == other.landingsDay &&
          landingsNight == other.landingsNight &&
          soloCrossCountryMinutes == other.soloCrossCountryMinutes &&
          soloCrossCountryCount == other.soloCrossCountryCount;

  @override
  int get hashCode => Object.hashAll([
        seDayDual,
        seDayPic,
        seDayPicus,
        seDayCopilot,
        seNightDual,
        seNightPic,
        seNightPicus,
        seNightCopilot,
        meDayDual,
        meDayPic,
        meDayPicus,
        meDayCopilot,
        meNightDual,
        meNightPic,
        meNightPicus,
        meNightCopilot,
        instrumentActual,
        instrumentFstd,
        instructorSe,
        instructorMe,
        instructorFstd,
        fstdActual,
        landingsDay,
        landingsNight,
        soloCrossCountryMinutes,
        soloCrossCountryCount,
      ]);

  @override
  String toString() =>
      'LedgerTotals(Total: ${totalFlightTimeMinutes}m, SE: ${totalSingleEngine}m, ME: ${totalMultiEngine}m, Landings: $totalLandings)';
}

