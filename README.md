# Aviation Logbook

A local-first, low-cost mobile aviation logbook for pilots, designed
around standard aviation logbook layouts and workflows used by
authorities such as DGCA and SACAA.

The application stores the pilot's logbook data and legally
signed/stamped document scans locally on the device. No hosted database
is required.

## Product Goals

-   Replace repetitive manual logbook calculations with deterministic
    local calculations.
-   Preserve the structure of the physical aviation logbook.
-   Generate career logbook summaries at arbitrary cutoff dates.
-   Store signed/stamped endorsements as immutable scans.
-   Maintain a digital aircraft-model endorsement register.
-   Provide encrypted, portable backups.
-   Avoid recurring cloud database costs.
-   Support Android and iOS from one codebase.
-   Keep the aviation domain logic independent of Flutter UI and
    infrastructure.

> **Compliance note:** The application should reproduce validated
> logbook fields and layouts for supported jurisdictions. Do not claim
> regulatory/legal compliance until the relevant current requirements
> have been independently verified.

------------------------------------------------------------------------

# Tech Stack

## Frontend / Cross-platform

-   **Flutter**
-   **Dart**
-   **Riverpod** --- state management
-   Feature-based Clean Architecture

## Local data

-   **Drift**
-   **SQLite**
-   **flutter_secure_storage**
-   **path_provider**

SQLite is the canonical application database. There is no application
backend in V1.

## Documents / Scanning

-   **cunning_document_scanner**
-   **flutter_image_compress**
-   App-private filesystem

Original document captures are immutable. Processed images and
thumbnails are derivatives.

## PDF

-   **pdf**
-   **printing**
-   **share_plus**

PDFs must be generated using exact physical dimensions for supported
logbook pages/slips.

## Backup

-   **archive**
-   **cryptography** (AES-256-GCM, SHA-256, Argon2id/PBKDF2)
-   **workmanager** (background execution)
-   Pluggable backup transports:
    -   SMTP
    -   REST API provider
    -   OS share/export

The backup format must not depend on an email provider.

## Monetization

-   **in_app_purchase**
-   Local entitlement layer

Initial commercial model:

-   90-day free trial
-   One-time unlock
-   No subscription required for core functionality

------------------------------------------------------------------------

# Architecture

``` text
                         Flutter Application
                                |
                         +------+------+
                         |             |
                       UI          Riverpod
                         |             |
                         +------+------+
                                |
                         Application Layer
                                |
                         +------+------+
                         |             |
                     Domain         Services
                         |             |
             +-----------+-----------+-----------+
             |           |           |           |
          Flights      Ledger     Summaries  Endorsements
             |           |           |           |
             +-----------+-----------+-----------+
                                |
                       Infrastructure Layer
                                |
              +-----------------+-----------------+
              |                 |                 |
            Drift          File Storage         PDF
              |                 |                 |
           SQLite          Documents          Reports
                                |
                             Backup
                                |
                    +-----------+-----------+
                    |           |           |
                   SMTP       REST        Export
```

## Critical architectural rule

The aviation calculation engine must not depend on Flutter widgets,
Riverpod, Drift, or platform APIs.

For example:

``` dart
final result = ledgerCalculator.calculate(
  flights,
  cutoffDate: cutoffDate,
);
```

The same domain calculation must be testable in a pure Dart unit test.

------------------------------------------------------------------------

# Project Structure

Recommended initial structure:

``` text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   ├── daos/
│   │   └── migrations/
│   │
│   ├── crypto/
│   ├── files/
│   ├── pdf/
│   ├── backup/
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── flights/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── aircraft/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── endorsements/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── summaries/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── backups/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── licensing/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/
    ├── widgets/
    └── models/
```

Keep feature-specific code inside its feature. Shared code should remain
genuinely shared.

------------------------------------------------------------------------

# Core Domain Model

The database should model aviation concepts rather than copying the
physical paper grid directly.

Do **not** make the database depend on columns such as:

``` text
se_day_dual
se_day_pic
se_night_dual
se_night_pic
me_day_dual
...
```

Instead, model the concepts and generate the paper layout from them.

## Flight

A flight contains:

``` text
Flight
- id
- date
- aircraftModelId
- registration
- picName
- remarks
- soloCrossCountry
- createdAt
- updatedAt
```

## Flight Time

``` text
FlightTime
- id
- flightId
- aircraftClass: SE | ME
- period: DAY | NIGHT
- role: DUAL | PIC | PICUS | COPILOT
- durationMinutes
```

Store durations as integer minutes, not floating-point hours.

Example:

``` text
01:35 -> 95 minutes
00:45 -> 45 minutes
```

This avoids floating-point accumulation errors.

## Time Entry Format

The canonical representation is always integer minutes. The user-facing entry format is configurable:

```text
TimeEntryFormat
- HH_MM
- DECIMAL_TENTHS
```

Examples:

```text
HH:MM
01:30 -> 90 minutes

Decimal hours
1.3 -> 78 minutes
1.5 -> 90 minutes
```

The decimal format means decimal hours: `1.3` is 1 hour 18 minutes, not 1 hour 30 minutes.

Conversion to and from the selected input format happens at the application/presentation boundary. Regulatory summaries and PDF templates should explicitly define which representation they display.

Formatting to `HH:MM` happens only at the presentation/reporting layer when required.

## Instrument Time

``` text
InstrumentTime
- id
- flightId
- navaids
- place
- actualMinutes
- fstdMinutes
```

## Instruction Time

``` text
InstructionTime
- id
- flightId
- category: SE | ME | FSTD
- durationMinutes
```

## Landings

``` text
Landing
- id
- flightId
- period: DAY | NIGHT
- count
```

------------------------------------------------------------------------

# Ledger Calculation Engine

The physical logbook contains page totals, brought-forward values, and
carried-forward values.

These should be **calculated**, not treated as independent user-entered
data.

Conceptually:

``` text
Flight Entries
      |
      v
Ledger Calculator
      |
      +--> Page Totals
      |
      +--> Brought Forward
      |
      +--> Carried Forward
      |
      +--> Grand Totals
```

The calculator must be deterministic.

Tests should cover:

-   empty page
-   one flight
-   multiple flights
-   exact page boundary
-   carry-forward
-   multi-page ledger
-   day/night splits
-   SE/ME splits
-   dual/PIC/PICUS/copilot
-   instrument actual/FSTD
-   instructor SE/ME/FSTD
-   landings
-   cutoff dates

------------------------------------------------------------------------

# Career Logbook Summaries

The application should expose a generic summary engine with
jurisdiction/layout-specific renderers.

Initial formats:

## Basic SE Summary

``` text
Class / Type
Date Last Flown

Instrument
  Actual
  FSTD

Single Engine Day
  Dual
  PIC

Single Engine Night
  Dual
  PIC

Solo Cross Country

Totals
```

## Composite SE/ME/Instructor Summary

``` text
Type

Single Engine Day
  Dual
  PIC

Single Engine Night
  Dual
  PIC

Multi Engine Day
  Dual
  PIC

Multi Engine Night
  Dual
  PIC

FSTD
  Dual

Instrument
  Actual
  FSTD

Instructor
  SE
  ME
  FSTD

Solo Cross Country
```

Both reports use the same underlying flight data.

The cutoff date is inclusive:

``` text
summary(cutoffDate)
```

Only flights on or before the cutoff date are included.

------------------------------------------------------------------------

# Aircraft Model Register

Model aircraft separately from endorsements.

``` text
AircraftModel
- id
- manufacturer
- model
- aircraftClass: SE | ME
- category
```

Then:

``` text
ModelEndorsement
- id
- aircraftModelId
- pilotDate
- instructorDate
- sourceDocumentId
- createdAt
```

Endorsed aircraft models populate the flight-entry dropdown.

The physical signed register page may optionally be attached as an
immutable document.

------------------------------------------------------------------------

# Endorsement Vault

Signed/stamped pages are treated as immutable documents.

``` text
EndorsementDocument
- id
- category
- endorsementDate
- pageNumber
- originalPath
- processedPath
- thumbnailPath
- sha256
- capturedAt
```

Possible categories initially include:

``` text
GENERAL
VP
RU
T
P
TW
MODEL_REGISTER
OTHER
```

The category list should remain extensible.

## Immutability rules

After an original scan is stored:

-   Do not edit the original.
-   Do not overwrite the original.
-   Do not silently replace it.
-   Do not allow destructive editing.

If a scan is incorrect:

``` text
Original document
       |
       v
Superseded
       |
       v
Replacement document
```

Keep the original and establish the relationship.

------------------------------------------------------------------------

# Document Storage

Use the application documents directory.

Recommended structure:

``` text
documents/
├── database/
│
├── endorsements/
│   └── <document-id>/
│       ├── original.jpg
│       ├── processed.webp
│       └── thumbnail.webp
│
├── backups/
│
└── exports/
```

The Drift database stores metadata and relative file paths.

The original image is never replaced by its compressed derivative.

------------------------------------------------------------------------

# Backup Key & Recovery Model

The backup must remain decryptable after the original device is lost, wiped, or destroyed.

Do **not** make the platform keychain the only location of the backup encryption key.

## User Master Passphrase

The user establishes a master passphrase during backup/security setup.

The backup encryption key is derived from that passphrase using:

- **Argon2id** as the preferred KDF, or
- **PBKDF2-HMAC-SHA256** as a compatibility fallback.

Every backup has a unique cryptographically random salt. The salt is not secret and is stored in the unencrypted archive header/manifest.

The derived key may be cached in `flutter_secure_storage` so scheduled backups do not require the user to enter the passphrase every time.

The master passphrase itself must never be stored.

## New Device Recovery

```text
Install app
    |
Import .logbook backup
    |
Enter master passphrase
    |
Read salt from backup
    |
Derive key
    |
AES-GCM authentication
    |
Verify checksums
    |
Validate schema
    |
Restore
```

If the master passphrase is lost, the encrypted backup is intentionally unrecoverable. The application must communicate this clearly during security setup.

A separately generated recovery key can be added later, but it must not weaken the master-passphrase security model.

------------------------------------------------------------------------

# Backup Format

The backup must be portable and versioned.

Example:

``` text
aviation-logbook-v1.logbook
```

Internally:

``` text
archive/
├── manifest.json
├── database.sqlite
├── endorsements/
│   ├── <id>/
│   │   ├── original.jpg
│   │   └── processed.webp
│   └── ...
└── checksums.json
```

Pipeline:

``` text
SQLite + Documents
        |
        v
Create manifest
        |
        v
Calculate SHA-256
        |
        v
Create archive
        |
        v
Encrypt with AES-256-GCM
        |
        v
.logbook
```

The backup must contain enough metadata to validate itself before
restore.

Example manifest:

``` json
{
  "formatVersion": 1,
  "appVersion": "0.1.0",
  "databaseSchemaVersion": 1,
  "createdAt": "2026-01-01T00:00:00Z",
  "files": [
    {
      "path": "endorsements/abc/original.jpg",
      "sha256": "..."
    }
  ]
}
```

## Restore

Never immediately overwrite the active database.

Use:

``` text
Select backup
    |
Validate archive
    |
Verify encryption
    |
Verify checksums
    |
Validate schema
    |
Show backup metadata
    |
Confirm restore
    |
Create safety snapshot
    |
Restore
```

------------------------------------------------------------------------

# Backup Transport

Backup creation and backup delivery must be separate.

``` dart
abstract interface class BackupTransport {
  Future<void> send(BackupArchive archive);
}
```

Implementations:

``` text
SmtpBackupTransport
RestBackupTransport
ShareBackupTransport
```

The application should work completely without email configuration.

The user must always be able to manually export a backup.

## Dual-email strategy

Configuration:

``` text
Primary Email
Recovery Email
Backup Schedule
```

When automated delivery is enabled, the encrypted archive can be sent to
both destinations.

The application should never send unencrypted flight data or endorsement
images.

------------------------------------------------------------------------

## Background Delivery Constraints

Automated network delivery is best-effort.

Mobile operating systems may suspend or terminate background work, particularly on iOS. Cellular networks or network configurations may also interfere with direct SMTP connections.

Therefore:

```text
Scheduled Backup
      |
      v
Create + Encrypt Backup
      |
      +----> Network transport succeeds ----> Delivered
      |
      +----> Network/background failure
                    |
                    v
             Mark as pending
                    |
                    v
             OS Share Sheet
```

`ShareBackupTransport` is the primary manual fallback when SMTP/API delivery fails or background execution is unavailable.

The application must not treat a backup as successfully delivered merely because it was successfully generated.

Backup state should distinguish at least:

```text
CREATED
QUEUED
SENT
DELIVERY_CONFIRMED
FAILED
EXPORTED
```

---

# Security

Minimum requirements:

-   Encrypt backup archives using authenticated encryption.
-   Store encryption keys in secure platform storage.
-   Never log passwords, encryption keys, tokens, or backup contents.
-   Hash immutable original scans.
-   Verify hashes during backup and restore.
-   Use TLS for network transport.
-   Do not store backup credentials in SQLite.
-   Do not upload documents automatically without explicit user
    configuration.
-   Avoid analytics containing flight or endorsement information.

The encryption key should not simply be hard-coded or derived from a
constant.

------------------------------------------------------------------------

# Monetization

Use an entitlement abstraction:

``` dart
abstract interface class EntitlementService {
  Future<bool> hasWriteAccess();
}
```

Possible states:

``` text
TRIAL
ACTIVE
EXPIRED
LIFETIME_UNLOCKED
```

The rest of the application should not know whether the entitlement came
from:

-   App Store
-   Google Play
-   trial
-   future license mechanism

The trial starts from the application's first-run installation state.

Do not make the application's core flight database dependent on the
store APIs.

------------------------------------------------------------------------

# UI Principles

The primary interaction should feel like a digital aviation logbook, not
a generic CRUD application.

## Flight entry

Use a dense spreadsheet-like layout on tablets and a sectioned form on
phones.

Phone:

``` text
Flight
├── Date / Aircraft
├── PIC / Remarks
├── Instrument
├── Instruction
├── Single Engine
├── Multi Engine
├── Landings
└── Save
```

Tablet:

``` text
+----------------------------------------------------------+
| Date | Type | Registration | PIC | Remarks              |
+----------------------------------------------------------+
| Instrument        | Instructor | SE | ME | FSTD         |
+----------------------------------------------------------+
| SE Day | SE Night | ME Day | ME Night | Landings       |
+----------------------------------------------------------+
```

The underlying data model remains identical.

------------------------------------------------------------------------

# PDF Requirements

PDF generation should use physical units.

Do not design the document in arbitrary screen pixels.

Define templates such as:

``` text
LogbookPageTemplate
CareerSummaryBasicTemplate
CareerSummaryCompositeTemplate
```

Each template should specify:

``` text
physicalWidth
physicalHeight
margins
columnWidths
rowHeights
fontSizes
lineWidths
```

Keep templates separate from calculation logic.

``` text
Domain result
      |
      v
PDF renderer
      |
      v
Physical logbook format
```

------------------------------------------------------------------------

# Development Phases

## Phase 0 --- Foundation

-   [ ] Create Flutter project
-   [ ] Configure analysis/linting
-   [ ] Add Riverpod
-   [ ] Add Drift
-   [ ] Configure SQLite
-   [ ] Configure migrations
-   [ ] Establish feature structure
-   [ ] Establish domain/application/data boundaries
-   [ ] Configure CI

## Phase 1 --- Flight Ledger

-   [ ] Aircraft model
-   [ ] Aircraft registration
-   [ ] Flight entry
-   [ ] SE/ME time
-   [ ] Day/night
-   [ ] Dual/PIC/PICUS/Copilot
-   [ ] Instrument time
-   [ ] Instruction time
-   [ ] Landings
-   [ ] Solo cross-country
-   [ ] Flight list
-   [ ] Edit/delete policy
-   [ ] Totals engine
-   [ ] Unit tests

## Phase 2 --- Physical Logbook

-   [ ] Page layout
-   [ ] Page totals
-   [ ] Brought forward
-   [ ] Carried forward
-   [ ] Grand totals
-   [ ] Multi-page calculations
-   [ ] Exact PDF layout
-   [ ] Print/share

## Phase 3 --- Career Summaries

-   [ ] Basic SE summary
-   [ ] Composite SE/ME/Instructor summary
-   [ ] Cutoff date
-   [ ] Aircraft filtering
-   [ ] PDF slip generation
-   [ ] Physical-size validation

## Phase 4 --- Endorsements

-   [ ] Document scanner
-   [ ] Original capture
-   [ ] Processed image
-   [ ] Thumbnail
-   [ ] SHA-256
-   [ ] Categories
-   [ ] Search
-   [ ] Pagination
-   [ ] Superseded/replacement relationship

## Phase 5 --- Aircraft Endorsements

-   [ ] SE model register
-   [ ] ME model register
-   [ ] Pilot sign-off
-   [ ] Instructor sign-off
-   [ ] Source document attachment
-   [ ] Auto-populate flight aircraft dropdown

## Phase 6 --- Backup

-   [ ] Manifest
-   [ ] Archive format
-   [ ] Checksums
-   [ ] AES-256-GCM encryption
-   [ ] Manual export
-   [ ] Import
-   [ ] Restore validation
-   [ ] SMTP transport
-   [ ] Primary + recovery email
-   [ ] Scheduled backup

## Phase 7 --- Monetization

-   [ ] Trial state
-   [ ] IAP
-   [ ] Entitlement service
-   [ ] Restore purchases
-   [ ] Offline entitlement behavior

------------------------------------------------------------------------

# Testing Strategy

The most important tests are **domain tests**, not widget tests.

## Calculation tests

Every aviation calculation should have explicit tests.

Examples:

``` text
1:30 + 0:45 = 2:15

0:50 SE Dual Day
+ 1:20 SE PIC Day
= 2:10 SE Day
```

Test boundary conditions:

``` text
00:00
00:01
00:59
01:00
23:59
```

Also test large accumulated totals.

## Property/invariant tests

Useful invariants:

``` text
pageTotal == sum(entriesOnPage)

grandTotal == broughtForward + pageTotal

summary(cutoffDate)
    contains no flight after cutoffDate

restore(backup(database))
    produces equivalent logical database

hash(originalFile)
    remains unchanged after processing
```

## PDF tests

PDFs should be tested for:

-   page size
-   number of pages
-   expected labels
-   expected totals
-   cutoff date
-   no clipped columns
-   no overlapping cells

For physical templates, maintain reference PDFs/images for visual
regression testing.

------------------------------------------------------------------------

# Data Integrity Rules

Flight time should be stored as integer minutes.

Never use `double` for aviation duration.

Good:

``` dart
int durationMinutes;
```

Avoid:

``` dart
double hours;
```

because:

``` text
0.1 + 0.2 != exactly 0.3
```

in binary floating-point arithmetic.

Formatting:

``` text
95 minutes -> 01:35
```

Parsing:

``` text
"01:35" -> 95
```

Keep conversion code centralized.

------------------------------------------------------------------------

# Offline-First Requirements

The application must remain useful without:

-   internet
-   user account
-   backend
-   email
-   cloud storage

The following must work offline:

-   add flight
-   edit flight
-   view ledger
-   calculate totals
-   generate summaries
-   scan endorsements
-   view documents
-   generate PDFs
-   export backup
-   restore backup
-   view aircraft endorsements

Internet is optional for:

-   email backup
-   IAP validation where required
-   optional crash reporting
-   future optional services

------------------------------------------------------------------------

# Dependency Rules

Prefer a small dependency surface.

Before adding a package, ask:

1.  Can this be implemented reliably with Dart/Flutter?
2.  Is it required on both Android and iOS?
3.  Is it maintained?
4.  Does it introduce cloud dependency?
5.  Does its license permit the intended distribution?
6.  Can the application replace it behind an interface?

External plugins should normally be hidden behind adapters/interfaces.

Example:

``` text
UI
 |
DocumentScanner interface
 |
CunningDocumentScannerAdapter
```

This prevents third-party APIs from becoming part of the domain model.

------------------------------------------------------------------------

# Initial Scaffold Commands

Create the Flutter project:

```bash
flutter create aviation_logbook
cd aviation_logbook
```

Add production dependencies:

```bash
flutter pub add flutter_riverpod \
  drift \
  sqlite3_flutter_libs \
  path_provider \
  flutter_secure_storage \
  cunning_document_scanner \
  flutter_image_compress \
  pdf \
  printing \
  share_plus \
  archive \
  cryptography \
  workmanager \
  in_app_purchase
```

Add development/code-generation dependencies:

```bash
flutter pub add --dev drift_dev build_runner
```

Then verify:

```bash
flutter analyze
flutter test
flutter run
```

---

# Git Strategy

Recommended branches:

``` text
main
develop
feature/*
fix/*
```

Keep commits small and domain-oriented:

``` text
feat: add flight time domain model
feat: add ledger total calculator
test: add multi-page carry-forward tests
feat: add aircraft endorsement register
feat: add endorsement document vault
```

Do not mix UI redesigns with database migrations and domain changes
unless necessary.

------------------------------------------------------------------------

# Definition of Done for V1

V1 is ready when a pilot can:

1.  Add aircraft models.
2.  Add flights using the relevant logbook fields.
3.  Record SE/ME day/night time.
4.  Record Dual/PIC/PICUS/Copilot time.
5.  Record instrument and instruction time.
6.  Record day/night landings.
7.  Mark solo cross-country.
8.  See correct running totals.
9.  Generate the supported physical logbook representation.
10. Generate a career summary up to a selected date.
11. Scan and store an endorsement locally.
12. Configure a master passphrase for backup encryption.
13. Export an encrypted backup.
14. Restore that backup on another installation using the master passphrase.
15. Detect invalid/corrupted backup archives before restore.
16. Use all core functionality without an internet connection.

------------------------------------------------------------------------

# Guiding Principle

> **The pilot owns the data. The device is the primary datastore. The
> cloud is optional transport, never the source of truth.**

The application should remain useful even if every external service
disappears.