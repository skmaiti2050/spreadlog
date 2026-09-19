import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aviation_logbook/core/hints/hints_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HintsService Tests', () {
    test('Defaults to hintsEnabled = true with empty dismissed hints', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(hintsProvider);
      expect(state.hintsEnabled, isTrue);
      expect(state.dismissedHints, isEmpty);
      expect(state.isVisible('test_hint'), isTrue);
    });

    test('Dismissing a hint makes it invisible and persists in state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(hintsProvider.notifier);
      await notifier.dismiss('zoom_hint');

      final state = container.read(hintsProvider);
      expect(state.dismissedHints.contains('zoom_hint'), isTrue);
      expect(state.isVisible('zoom_hint'), isFalse);
      expect(state.isVisible('other_hint'), isTrue);
    });

    test('Disabling hints makes all hints invisible', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(hintsProvider.notifier);
      await notifier.setHintsEnabled(false);

      final state = container.read(hintsProvider);
      expect(state.hintsEnabled, isFalse);
      expect(state.isVisible('any_hint'), isFalse);
    });

    test('resetAllHints clears dismissed set', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(hintsProvider.notifier);
      await notifier.dismiss('hint_1');
      await notifier.dismiss('hint_2');

      expect(container.read(hintsProvider).dismissedHints.length, 2);

      await notifier.resetAllHints();
      expect(container.read(hintsProvider).dismissedHints, isEmpty);
      expect(container.read(hintsProvider).isVisible('hint_1'), isTrue);
    });
  });
}

