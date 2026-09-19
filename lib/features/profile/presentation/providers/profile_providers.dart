import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pilot_profile_repository.dart';
import '../../domain/pilot_profile.dart';

final pilotProfileRepositoryProvider = Provider<PilotProfileRepository>((ref) {
  return const PilotProfileRepository();
});

class PilotProfileNotifier extends Notifier<PilotProfile> {
  @override
  PilotProfile build() {
    _loadProfile();
    return PilotProfile.defaultProfile;
  }

  Future<void> _loadProfile() async {
    final repo = ref.read(pilotProfileRepositoryProvider);
    final loaded = await repo.getProfile();
    state = loaded;
  }

  Future<void> updateProfile({
    required String pilotName,
    required String licenceNumber,
    String? regulatorId,
    String? defaultPicName,
  }) async {
    final repo = ref.read(pilotProfileRepositoryProvider);
    final updated = state.copyWith(
      pilotName: pilotName.trim().isNotEmpty ? pilotName.trim() : 'PILOT IN COMMAND',
      licenceNumber: licenceNumber.trim().isNotEmpty ? licenceNumber.trim() : 'ZA-123456',
      regulatorId: regulatorId ?? state.regulatorId,
      defaultPicName: defaultPicName ?? state.defaultPicName,
    );
    state = updated;
    await repo.saveProfile(updated);
  }
}

final pilotProfileProvider =
    NotifierProvider<PilotProfileNotifier, PilotProfile>(
  PilotProfileNotifier.new,
);

