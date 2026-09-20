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

  AircraftModel copyWith({
    String? id,
    String? manufacturer,
    String? model,
    AircraftClass? aircraftClass,
    AircraftCategory? category,
  }) {
    return AircraftModel(
      id: id ?? this.id,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer': manufacturer,
      'model': model,
      'aircraftClass': aircraftClass.name,
      'category': category.name,
    };
  }

  factory AircraftModel.fromJson(Map<String, dynamic> json) {
    return AircraftModel(
      id: json['id'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      aircraftClass: AircraftClass.values.firstWhere(
        (e) => e.name == json['aircraftClass'],
        orElse: () => AircraftClass.singleEngine,
      ),
      category: AircraftCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AircraftCategory.aeroplane,
      ),
    );
  }

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
