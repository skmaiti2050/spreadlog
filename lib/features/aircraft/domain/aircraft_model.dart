enum AircraftClass {
  singleEngine,
  multiEngine,
}

enum AircraftCategory {
  aeroplane,
  helicopter,
  fstd,
  other,
}

class AircraftModel {
  final String id;
  final String manufacturer;
  final String model;
  final AircraftClass aircraftClass;
  final AircraftCategory category;

  const AircraftModel({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.aircraftClass,
    required this.category,
  });

  String get displayName => '$manufacturer $model';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AircraftModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AircraftModel(id: $id, name: $displayName, class: $aircraftClass)';
}

