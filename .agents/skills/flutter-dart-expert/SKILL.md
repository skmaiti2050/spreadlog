---
name: flutter-dart-expert
description: >-
  Expert engineering standards and guidelines for developing high-reliability,
  local-first Flutter and pure Dart applications. Use whenever writing Dart code,
  designing state management with Riverpod, building Drift SQLite persistence,
  or implementing domain calculation engines.
---

# Flutter & Dart Expert Engineering Guidelines

This project is a mission-critical, offline-first, multi-regulator aviation logbook where calculation accuracy, zero-drift arithmetic, and local data integrity are paramount.

## 1. Core Architectural Separation

```
lib/
├── core/
│   ├── database/       # Drift persistence, DAOs, cross-platform connection
│   └── utils/          # Pure helper utilities (e.g. TimeUtils)
└── features/
    └── <feature>/
        ├── domain/     # PURE DART: Entities, calculators, invariants (NO Flutter, NO Drift)
        ├── data/       # Repositories and adapters mapping DB rows <-> Domain entities
        └── presentation/
            ├── providers/  # Riverpod state notifiers and stream providers
            ├── screens/    # Screen widgets
            └── widgets/    # Reusable UI components
```

### The Pure Domain Rule
- **Zero Framework Leakage**: The domain layer (`lib/features/*/domain/`) must **never** import Flutter (`package:flutter/*`), Riverpod, Drift, or platform channels.
- **Pure Functions & Determinism**: All business logic (e.g., `LedgerCalculator`, `LedgerTotals`) must be deterministic pure Dart classes testable in standard CLI test runners without mocking the UI framework.

## 2. Arithmetic & Aviation Precision Invariants

- **Always Integer Minutes**: Never store or calculate durations in floating-point decimal hours. All time accumulation must happen in deterministic integer minutes (`int`).
- **Formatting at the Boundary**: Only convert integer minutes to decimal format (`TimeUtils.formatMinutesToDecimal(mins)`) or HH:MM (`formatMinutesToHhMm(mins)`) at presentation time.
- **Carry-Forward Invariant**:
  $$\text{Carried Forward} = \text{Brought Forward} + \text{Page Totals}$$
  Every physical ledger page must strictly preserve this invariant.

## 3. Drift & Local-First Persistence

- **Atomic Transactions**: Multi-table insertions (e.g., flight record + associated flight times + landings + instrument times) must always be wrapped in `transaction(() async { ... })`.
- **Cross-Platform Connection**: Use conditional imports for database connections (`native.dart` via `dart:ffi` on mobile/desktop, `web.dart` via `WasmDatabase` on web).
- **Generated Code**: Never commit `*.g.dart` files. Rebuild with `dart run build_runner build --delete-conflicting-outputs`.
- **Static Assets**: Web runtime assets (`drift_worker.js`, `sqlite3.wasm`) are kept out of git and managed via `tool/update_web_assets.dart`.

## 4. Riverpod State Management

- **Provider Specialization**:
  - Keep root stream providers focused (`flightsStreamProvider`).
  - Use functional derivation for computed state (`grandTotalsProvider`, `ledgerPagesProvider`).
- **Testing Guard**: When writing `testWidgets`, always override stream providers with synchronous/finite streams (`Stream.value([])`) to prevent open Dart isolate ports from hanging the test runner.

## 5. Performance & Linting Standards

- **Strict Mode**: Maintain `strict-casts: true`, `strict-inference: true`, and `strict-raw-types: true` in `analysis_options.yaml`.
- **Widget Consting**: Mark all immutable widgets and constructors with `const` to minimize widget tree rebuilds.
- **Async Safety**:
  - Always `await` futures or explicitly mark with `unawaited(...)`.
  - Check `if (!mounted) return;` or `if (!context.mounted) return;` before using `BuildContext` across async gaps.
  - Close all `Sink`s and cancel `StreamSubscription`s in `dispose()`.

