# Aviation Logbook Agent Guidelines

## Architecture & Code Standards
- **Pure Domain Integrity**: Files inside `lib/features/*/domain/` must be 100% pure Dart. Never import `package:flutter/*`, `package:drift/*`, or `package:flutter_riverpod/*` into domain layers.
- **Deterministic Units**: All durations must be stored and calculated as integer minutes (`int`). Never accumulate floating-point numbers.
- **Multi-Regulator Modularity**: Keep regulator rules (SACAA, FAA, EASA, DGCA) isolated behind the `RegulatorProfile` abstraction.
- **Zero Committed Generated Files**: Never commit `*.g.dart` or web binary files (`web/drift_worker.js`, `web/sqlite3.wasm`).
- **Memory & Async Safety**: Enforce `unawaited_futures`, `avoid_void_async`, `cancel_subscriptions`, and `use_build_context_synchronously`.
- **Testing**: Every calculation invariant, pagination rule, and regulatory requirement must be covered by pure Dart unit tests in `test/`.

