import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/flights_dao.dart';
import '../../aircraft/domain/aircraft_model.dart';
import '../domain/flight.dart';
import '../domain/flight_time.dart';
import '../domain/instruction_time.dart';
import '../domain/instrument_time.dart';
import '../domain/landings.dart';

class FlightsRepository {
  final FlightsDao _dao;

  FlightsRepository(this._dao);

  /// Fetches all flights with their associated child records and maps to Domain Flight objects.
  Future<List<Flight>> getAllFlights() async {
    final flightRows = await _dao.getAllFlights();
    final flights = <Flight>[];

    for (final row in flightRows) {
      final flightTimesRows = await _dao.getFlightTimes(row.id);
      final instrumentRow = await _dao.getInstrumentTime(row.id);
      final instructionRows = await _dao.getInstructionTimes(row.id);
      final landingsRow = await _dao.getLandings(row.id);

      flights.add(
        Flight(
          id: row.id,
          date: row.date,
          aircraftModelId: row.aircraftModelId,
          registration: row.registration,
          picName: row.picName,
          remarks: row.remarks,
          soloCrossCountry: row.soloCrossCountry,
          fstdActualMinutes: row.fstdActualMinutes,
          flightTimes: flightTimesRows.map((ft) {
            return FlightTime(
              id: ft.id,
              flightId: ft.flightId,
              aircraftClass: AircraftClass.values[ft.aircraftClass],
              period: TimePeriod.values[ft.period],
              role: PilotRole.values[ft.role],
              durationMinutes: ft.durationMinutes,
            );
          }).toList(),
          instrumentTime: instrumentRow != null
              ? InstrumentTime(
                  id: instrumentRow.id,
                  flightId: instrumentRow.flightId,
                  navaids: instrumentRow.navaids,
                  place: instrumentRow.place,
                  actualMinutes: instrumentRow.actualMinutes,
                  fstdMinutes: instrumentRow.fstdMinutes,
                )
              : null,
          instructionTimes: instructionRows.map((it) {
            return InstructionTime(
              id: it.id,
              flightId: it.flightId,
              category: InstructorCategory.values[it.category],
              durationMinutes: it.durationMinutes,
            );
          }).toList(),
          landings: Landings(
            dayCount: landingsRow?.dayCount ?? 0,
            nightCount: landingsRow?.nightCount ?? 0,
          ),
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      );
    }

    return flights;
  }

  /// Watches all flights reactively.
  Stream<List<Flight>> watchAllFlights() {
    return _dao.watchAllFlights().asyncMap((rows) async {
      final flights = <Flight>[];
      for (final row in rows) {
        final flightTimesRows = await _dao.getFlightTimes(row.id);
        final instrumentRow = await _dao.getInstrumentTime(row.id);
        final instructionRows = await _dao.getInstructionTimes(row.id);
        final landingsRow = await _dao.getLandings(row.id);

        flights.add(
          Flight(
            id: row.id,
            date: row.date,
            aircraftModelId: row.aircraftModelId,
            registration: row.registration,
            picName: row.picName,
            remarks: row.remarks,
            soloCrossCountry: row.soloCrossCountry,
            fstdActualMinutes: row.fstdActualMinutes,
            flightTimes: flightTimesRows.map((ft) {
              return FlightTime(
                id: ft.id,
                flightId: ft.flightId,
                aircraftClass: AircraftClass.values[ft.aircraftClass],
                period: TimePeriod.values[ft.period],
                role: PilotRole.values[ft.role],
                durationMinutes: ft.durationMinutes,
              );
            }).toList(),
            instrumentTime: instrumentRow != null
                ? InstrumentTime(
                    id: instrumentRow.id,
                    flightId: instrumentRow.flightId,
                    navaids: instrumentRow.navaids,
                    place: instrumentRow.place,
                    actualMinutes: instrumentRow.actualMinutes,
                    fstdMinutes: instrumentRow.fstdMinutes,
                  )
                : null,
            instructionTimes: instructionRows.map((it) {
              return InstructionTime(
                id: it.id,
                flightId: it.flightId,
                category: InstructorCategory.values[it.category],
                durationMinutes: it.durationMinutes,
              );
            }).toList(),
            landings: Landings(
              dayCount: landingsRow?.dayCount ?? 0,
              nightCount: landingsRow?.nightCount ?? 0,
            ),
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        );
      }
      return flights;
    });
  }

  /// Persists a new flight and all its child components atomically.
  Future<void> saveFlight(Flight flight) async {
    final flightCompanion = FlightsTableCompanion(
      id: Value(flight.id),
      date: Value(flight.date),
      aircraftModelId: Value(flight.aircraftModelId),
      registration: Value(flight.registration),
      picName: Value(flight.picName),
      remarks: Value(flight.remarks),
      soloCrossCountry: Value(flight.soloCrossCountry),
      fstdActualMinutes: Value(flight.fstdActualMinutes),
      createdAt: Value(flight.createdAt),
      updatedAt: Value(flight.updatedAt),
    );

    final flightTimeCompanions = flight.flightTimes.map((ft) {
      final ftId = ft.id ?? '${flight.id}_ft_${ft.aircraftClass.index}_${ft.period.index}_${ft.role.index}';
      return FlightTimesTableCompanion(
        id: Value(ftId),
        flightId: Value(flight.id),
        aircraftClass: Value(ft.aircraftClass.index),
        period: Value(ft.period.index),
        role: Value(ft.role.index),
        durationMinutes: Value(ft.durationMinutes),
      );
    }).toList();

    InstrumentTimesTableCompanion? instrumentCompanion;
    if (flight.instrumentTime != null && !flight.instrumentTime!.isEmpty) {
      instrumentCompanion = InstrumentTimesTableCompanion(
        id: Value(flight.instrumentTime!.id ?? '${flight.id}_inst'),
        flightId: Value(flight.id),
        navaids: Value(flight.instrumentTime!.navaids),
        place: Value(flight.instrumentTime!.place),
        actualMinutes: Value(flight.instrumentTime!.actualMinutes),
        fstdMinutes: Value(flight.instrumentTime!.fstdMinutes),
      );
    }

    final instructionCompanions = flight.instructionTimes.map((it) {
      final itId = it.id ?? '${flight.id}_instruc_${it.category.index}';
      return InstructionTimesTableCompanion(
        id: Value(itId),
        flightId: Value(flight.id),
        category: Value(it.category.index),
        durationMinutes: Value(it.durationMinutes),
      );
    }).toList();

    LandingsTableCompanion? landingsCompanion;
    if (flight.landings.totalCount > 0) {
      landingsCompanion = LandingsTableCompanion(
        id: Value('${flight.id}_landings'),
        flightId: Value(flight.id),
        dayCount: Value(flight.landings.dayCount),
        nightCount: Value(flight.landings.nightCount),
      );
    }

    await _dao.insertCompleteFlight(
      flight: flightCompanion,
      flightTimes: flightTimeCompanions,
      instrumentTime: instrumentCompanion,
      instructionTimes: instructionCompanions,
      landings: landingsCompanion,
    );
  }

  /// Deletes a flight.
  Future<void> deleteFlight(String flightId) async {
    await _dao.deleteFlight(flightId);
  }

  /// Deletes multiple flights in a single transaction.
  Future<int> deleteFlights(List<String> flightIds) async {
    return _dao.deleteFlights(flightIds);
  }
}

