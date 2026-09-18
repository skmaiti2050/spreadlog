// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Dynamically resolves and downloads the appropriate web runtime assets
/// (`drift_worker.js` and `sqlite3.wasm`) directly from GitHub releases.
///
/// Logic:
/// 1. Reads the resolved drift version from `pubspec.lock`.
/// 2. Queries GitHub releases for the matching tag `drift-<version>` (or `/latest` if not tagged).
/// 3. Parses the release JSON to locate `drift_worker.js` and `sqlite3.wasm` asset URLs.
/// 4. Compares local file size/checksum, downloading only if missing or changed.
void main(List<String> args) async {
  final force = args.contains('--force');
  final webDir = Directory('web');
  if (!await webDir.exists()) {
    await webDir.create(recursive: true);
  }

  final client = HttpClient();
  client.userAgent = 'spreadlog-asset-updater';

  try {
    final driftVersion = await _getDriftVersionFromLock();
    print('Resolved drift version in pubspec.lock: $driftVersion');

    final releaseUrl = driftVersion != null
        ? 'https://api.github.com/repos/simolus3/drift/releases/tags/drift-$driftVersion'
        : 'https://api.github.com/repos/simolus3/drift/releases/latest';

    print('Fetching release manifest from GitHub: $releaseUrl');
    Map<String, dynamic>? releaseData = await _fetchJson(client, releaseUrl);

    // Fall back to latest if the specific tag is not found
    if (releaseData == null && driftVersion != null) {
      print('Specific tag not found, falling back to latest release...');
      releaseData = await _fetchJson(
        client,
        'https://api.github.com/repos/simolus3/drift/releases/latest',
      );
    }

    if (releaseData == null) {
      throw Exception('Unable to fetch release JSON from GitHub.');
    }

    final assets = releaseData['assets'] as List<dynamic>? ?? [];
    String? workerUrl;
    int? workerSize;
    String? wasmUrl;
    int? wasmSize;

    for (final asset in assets) {
      final name = asset['name'] as String?;
      if (name == 'drift_worker.js') {
        workerUrl = asset['browser_download_url'] as String?;
        workerSize = asset['size'] as int?;
      } else if (name == 'sqlite3.wasm') {
        wasmUrl = asset['browser_download_url'] as String?;
        wasmSize = asset['size'] as int?;
      }
    }

    if (workerUrl == null || wasmUrl == null) {
      throw Exception('Release does not contain required drift_worker.js or sqlite3.wasm assets.');
    }

    final workerFile = File('web/drift_worker.js');
    final wasmFile = File('web/sqlite3.wasm');

    if (force || !await workerFile.exists() || (workerSize != null && await workerFile.length() != workerSize)) {
      print('Downloading drift_worker.js from: $workerUrl');
      await _downloadFile(client, workerUrl, workerFile);
      print('✓ Updated drift_worker.js (${await workerFile.length()} bytes)');
    } else {
      print('✓ drift_worker.js is current (${await workerFile.length()} bytes)');
    }

    if (force || !await wasmFile.exists() || (wasmSize != null && await wasmFile.length() != wasmSize)) {
      print('Downloading sqlite3.wasm from: $wasmUrl');
      await _downloadFile(client, wasmUrl, wasmFile);
      print('✓ Updated sqlite3.wasm (${await wasmFile.length()} bytes)');
    } else {
      print('✓ sqlite3.wasm is current (${await wasmFile.length()} bytes)');
    }

    print('Web assets are completely synchronized.');
  } finally {
    client.close();
  }
}

Future<String?> _getDriftVersionFromLock() async {
  final lockFile = File('pubspec.lock');
  if (!await lockFile.exists()) return null;

  final lines = await lockFile.readAsLines();
  bool inDriftSection = false;

  for (final line in lines) {
    if (line.trim() == 'drift:') {
      inDriftSection = true;
      continue;
    }
    if (inDriftSection) {
      if (line.startsWith('  ') && !line.startsWith('    ')) {
        // another package
        if (!line.startsWith('  drift:')) break;
      }
      final trimmed = line.trim();
      if (trimmed.startsWith('version:')) {
        return trimmed.replaceFirst('version:', '').replaceAll('"', '').trim();
      }
    }
  }
  return null;
}

Future<Map<String, dynamic>?> _fetchJson(HttpClient client, String url) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode} while querying $url');
    }

    final content = await response.transform(utf8.decoder).join();
    return jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    print('Warning: Failed to fetch JSON from $url: $e');
    return null;
  }
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
      'Failed to download $url (Status: ${response.statusCode})',
      uri: Uri.parse(url),
    );
  }

  final sink = target.openWrite();
  await response.pipe(sink);
}
