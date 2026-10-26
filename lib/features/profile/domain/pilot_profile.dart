/// Pilot profile domain entity.
///
/// 100% pure Dart, zero external dependencies.
class PilotProfile {
  final String pilotName;
  final String licenceNumber;
  final String regulatorId;
  final String defaultPicName;

  const PilotProfile({
    this.pilotName = '',
    this.licenceNumber = '',
    this.regulatorId = 'sacaa',
    this.defaultPicName = 'SELF',
  });

  static const PilotProfile defaultProfile = PilotProfile();

  /// Placeholders that earlier builds stored as defaults; they are not a
  /// real pilot's details and are read back as empty.
  static const legacyPlaceholderName = 'PILOT IN COMMAND';
  static const legacyPlaceholderLicence = 'ZA-123456';

  /// Name and licence appear on every logbook page and summary slip.
  bool get isComplete =>
      pilotName.trim().isNotEmpty && licenceNumber.trim().isNotEmpty;

  PilotProfile copyWith({
    String? pilotName,
    String? licenceNumber,
    String? regulatorId,
    String? defaultPicName,
  }) {
    return PilotProfile(
      pilotName: pilotName ?? this.pilotName,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      regulatorId: regulatorId ?? this.regulatorId,
      defaultPicName: defaultPicName ?? this.defaultPicName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pilotName': pilotName,
      'licenceNumber': licenceNumber,
      'regulatorId': regulatorId,
      'defaultPicName': defaultPicName,
    };
  }

  factory PilotProfile.fromJson(Map<String, dynamic> json) {
    return PilotProfile(
      pilotName: json['pilotName'] as String? ?? '',
      licenceNumber: json['licenceNumber'] as String? ?? '',
      regulatorId: json['regulatorId'] as String? ?? 'sacaa',
      defaultPicName: json['defaultPicName'] as String? ?? 'SELF',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PilotProfile &&
          runtimeType == other.runtimeType &&
          pilotName == other.pilotName &&
          licenceNumber == other.licenceNumber &&
          regulatorId == other.regulatorId &&
          defaultPicName == other.defaultPicName;

  @override
  int get hashCode =>
      Object.hash(pilotName, licenceNumber, regulatorId, defaultPicName);

  @override
  String toString() =>
      'PilotProfile(name: $pilotName, licence: $licenceNumber, regulator: $regulatorId)';
}

