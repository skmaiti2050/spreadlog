import 'aircraft_model.dart';
import 'model_endorsement.dart';

abstract class AircraftRepository {
  Stream<List<AircraftModel>> watchAllModels();
  Future<List<AircraftModel>> getAllModels();
  Future<AircraftModel?> getModelById(String id);
  Future<void> saveModel(AircraftModel model);
  Future<void> deleteModel(String id);

  Stream<List<ModelEndorsement>> watchAllEndorsements();
  Future<List<ModelEndorsement>> getAllEndorsements();
  Future<ModelEndorsement?> getEndorsementByModelId(String modelId);
  Future<void> saveEndorsement(ModelEndorsement endorsement);
  Future<void> deleteEndorsement(String id);
}

