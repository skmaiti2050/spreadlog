import 'dart:io';

/// Updates or verifies web runtime assets (drift_worker.js and sqlite3.wasm).
/// Ensures that local assets in web/ match the required versions without needing
/// to track bulky binary assets in git.
void main(List<String> args) async {
  final force = args.contains('--force');
  final webDir = Directory('web');
  if (!await webDir.exists()) {
    print('Creating web/ directory...');
    await webDir.create(recursive: true);
  }

  // Drift version 2.26.0+ worker
  const driftWorkerUrl =
      'https://github.com/simolus3/drift/releases/download/drift-2.26.0/drift_worker.js';
  // Sqlite3.wasm release
  const sqlite3WasmUrl =
      'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.6/sqlite3.wasm';

  final workerFile = File('web/drift_worker.js');
  final wasmFile = File('web/sqlite3.wasm');

  final client = HttpClient();

  try {
    if (force || !await workerFile.exists() || await workerFile.length() == 0) {
      print('Fetching drift_worker.js...');
      await _downloadFile(client, driftWorkerUrl, workerFile);
      print('✓ Downloaded drift_worker.js (${await workerFile.length()} bytes)');
    } else {
      print('✓ drift_worker.js is up to date (${await workerFile.length()} bytes)');
    }

    if (force || !await wasmFile.exists() || await wasmFile.length() == 0) {
      print('Fetching sqlite3.wasm...');
      await _downloadFile(client, sqlite3WasmUrl, wasmFile);
      print('✓ Downloaded sqlite3.wasm (${await wasmFile.length()} bytes)');
    } else {
      print('✓ sqlite3.wasm is up to date (${await wasmFile.length()} bytes)');
    }
  } finally {
    client.close();
  }

  print('Web assets verified successfully.');
}

Future<void> _downloadFile(HttpClient client, String url, File target) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();

  if (response.isRedirect) {
    final location = response.headers.value(HttpHeaders.locationHeader);
    if (location != null) {
      return _downloadFile(client, location, target);
    }
  }

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      'Failed to download $url (Status code: ${response.statusCode})',
      uri: Uri.parse(url),
    );
  }

  final sink = target.openWrite();
  await response.pipe(sink);
}
