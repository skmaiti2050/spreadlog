import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/backups/data/backup_workmanager_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Needed before any backup can be scheduled; not awaited so it can't
  // delay the first frame.
  unawaited(BackupWorkmanagerService.initialize());
  runApp(const ProviderScope(child: AviationLogbookApp()));
}
