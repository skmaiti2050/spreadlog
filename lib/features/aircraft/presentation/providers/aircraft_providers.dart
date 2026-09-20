import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/aircraft_dao.dart';
import '../../../flights/presentation/providers/flights_providers.dart';
import '../../data/drift_aircraft_repository.dart';
import '../../domain/aircraft_model.dart';
import '../../domain/aircraft_repository.dart';
import '../../domain/model_endorsement.dart';

final aircraftDaoProvider = Provider<AircraftDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.aircraftDao;
});

final aircraftRepositoryProvider = Provider<AircraftRepository>((ref) {
  final dao = ref.watch(aircraftDaoProvider);
  return DriftAircraftRepository(dao);
});

final allAircraftModelsProvider = StreamProvider<List<AircraftModel>>((ref) {
  final repo = ref.watch(aircraftRepositoryProvider);
  return repo.watchAllModels();
});

final allModelEndorsementsProvider = StreamProvider<List<ModelEndorsement>>((ref) {
  final repo = ref.watch(aircraftRepositoryProvider);
  return repo.watchAllEndorsements();
});

class EndorsedAircraftEntry {
  final AircraftModel model;
  final ModelEndorsement? endorsement;

  const EndorsedAircraftEntry({
    required this.model,
    this.endorsement,
  });

  bool get isEndorsed => endorsement != null;
  AircraftClass get aircraftClass => model.aircraftClass;
}

final endorsedAircraftListProvider = Provider<List<EndorsedAircraftEntry>>((ref) {
  final modelsAsync = ref.watch(allAircraftModelsProvider);
  final endorsementsAsync = ref.watch(allModelEndorsementsProvider);

  final models = modelsAsync.value ?? [];
  final endorsements = endorsementsAsync.value ?? [];

  final endorsementMap = {
    for (final e in endorsements) e.aircraftModelId: e,
  };

  return models.map((m) {
    return EndorsedAircraftEntry(
      model: m,
      endorsement: endorsementMap[m.id],
    );
  }).toList();
});
