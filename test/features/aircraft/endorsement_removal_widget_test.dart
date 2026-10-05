import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/aircraft/data/drift_aircraft_repository.dart';
import 'package:aviation_logbook/features/aircraft/domain/model_endorsement.dart';
import 'package:aviation_logbook/features/aircraft/presentation/providers/aircraft_providers.dart';
import 'package:aviation_logbook/features/aircraft/presentation/widgets/endorse_aircraft_dialog.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'switch off, confirm and save removes active endorsement and keeps aircraft',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftAircraftRepository(db.aircraftDao);
      await repo.getAllModels();
      final model = (await repo.getModelById('C172'))!;
      final endorsement = ModelEndorsement(
        id: 'e1',
        aircraftModelId: model.id,
        pilotDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      await repo.saveEndorsement(endorsement);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aircraftRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => EndorseAircraftDialog(
                      initialModel: model,
                      initialEndorsement: endorsement,
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Aircraft'));
      await tester.pumpAndSettle();
      expect(find.text('Remove recorded endorsement?'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Wrong model');
      await tester.tap(find.text('Remove endorsement'));
      await tester.pumpAndSettle();
      expect(await repo.getEndorsementByModelId('C172'), isNull);
      expect(await repo.getModelById('C172'), isNotNull);
      expect(
        await db.customSelect('SELECT * FROM endorsement_corrections').get(),
        hasLength(1),
      );
    },
  );
}
