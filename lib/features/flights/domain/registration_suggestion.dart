import '../../aircraft/domain/aircraft_model.dart';
import 'flight.dart';
import 'hobbs_reading.dart';

/// Aircraft details only. Date, duration and operating role are never inferred.
class RegistrationSuggestion {
  final String modelId;
  final AircraftCategory category;
  final AircraftClass aircraftClass;
  const RegistrationSuggestion(this.modelId, this.category, this.aircraftClass);

  static RegistrationSuggestion? find({
    required String registration,
    required Iterable<Flight> flights,
    required Iterable<AircraftModel> fleet,
    String? excludingId,
  }) {
    final normalized = HobbsReading.normalizeRegistration(registration);
    if (normalized.isEmpty || registration.trim().endsWith('-')) return null;
    final matching =
        flights
            .where(
              (flight) =>
                  flight.id != excludingId &&
                  HobbsReading.normalizeRegistration(flight.registration) ==
                      normalized &&
                  flight.aircraftModelId != null &&
                  flight.aircraftModelId!.isNotEmpty,
            )
            .toList()
          ..sort((a, b) {
            final date = b.date.compareTo(a.date);
            return date != 0 ? date : b.createdAt.compareTo(a.createdAt);
          });
    if (matching.isEmpty) return null;
    final flight = matching.first;
    final model = fleet
        .where((model) => model.id == flight.aircraftModelId)
        .firstOrNull;
    return RegistrationSuggestion(
      flight.aircraftModelId!,
      model?.category ?? flight.aircraftCategory,
      model?.aircraftClass ??
          (flight.flightTimes.firstOrNull?.aircraftClass ??
              AircraftClass.singleEngine),
    );
  }
}
