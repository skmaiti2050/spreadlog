import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/flight.dart';
import '../domain/flight_draft.dart';
import 'flights_repository.dart';

class SqliteFlightDraftRepository implements FlightDraftRepository {
  final AppDatabase db;
  SqliteFlightDraftRepository(this.db);

  @override
  Future<FlightDraft?> get(String? flightId) async {
    final row = await db
        .customSelect(
          'SELECT payload FROM flight_drafts WHERE draft_key = ?',
          variables: [Variable(FlightDraft.keyFor(flightId))],
        )
        .getSingleOrNull();
    return row == null
        ? null
        : FlightDraft.fromJson(
            jsonDecode(row.read<String>('payload')) as Map<String, dynamic>,
          );
  }

  @override
  Future<void> save(FlightDraft draft) => db.customStatement(
    'INSERT OR REPLACE INTO flight_drafts (draft_key, payload) VALUES (?, ?)',
    [draft.key, jsonEncode(draft.toJson())],
  );

  @override
  Future<void> discard(String? flightId) => db.customStatement(
    'DELETE FROM flight_drafts WHERE draft_key = ?',
    [FlightDraft.keyFor(flightId)],
  );

  /// Includes child records, so even two edits within one timestamp second
  /// conflict. Canonical keys/rows survive portable schema column ordering.
  Future<String?> revision(String flightId) async {
    final parent = await db
        .customSelect(
          'SELECT * FROM flights_table WHERE id = ?',
          variables: [Variable(flightId)],
        )
        .getSingleOrNull();
    if (parent == null) return null;
    Map<String, Object?> canonical(Map<String, Object?> data) => {
      for (final key in data.keys.toList()..sort()) key: data[key],
    };
    final snapshot = <String, Object?>{'flight': canonical(parent.data)};
    for (final table in [
      'flight_times_table',
      'instrument_times_table',
      'instruction_times_table',
      'landings_table',
    ]) {
      final rows = await db
          .customSelect(
            'SELECT * FROM $table WHERE flight_id = ?',
            variables: [Variable(flightId)],
          )
          .get();
      snapshot[table] =
          rows.map((row) => jsonEncode(canonical(row.data))).toList()..sort();
    }
    return jsonEncode(snapshot);
  }

  /// The check, flight save, and draft removal form one transaction. A failed
  /// save or stale edit leaves the recoverable draft intact.
  Future<void> finalize(Flight flight, {required String? baseRevision}) =>
      db.transaction(() async {
        if (baseRevision != null && await revision(flight.id) != baseRevision) {
          throw const FlightDraftConflict();
        }
        await FlightsRepository(db.flightsDao).saveFlight(flight);
        await discard(baseRevision == null ? null : flight.id);
      });
}
