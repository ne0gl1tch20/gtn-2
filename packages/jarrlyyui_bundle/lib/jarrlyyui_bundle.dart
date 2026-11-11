import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:jarrlyyui_language/jarrlyyui_language.dart';

const int juiBundleSchemaVersion = 1;
const int juiHostApiVersion = 1;
const int juiMaximumBundleBytes = 16 * 1024 * 1024;
const int juiMaximumFileBytes = 4 * 1024 * 1024;

class JuiBundleException implements Exception {
  const JuiBundleException(this.message);

  final String message;

  @override
  String toString() => 'JuiBundleException: $message';
}

class JuiBundleFile {
  const JuiBundleFile({required this.path, required this.sha256});

  final String path;
  final String sha256;

  factory JuiBundleFile.fromJson(Object? value) {
    if (value is! Map) {
      throw const JuiBundleException('Invalid bundle file entry.');
    }
    final path = value['path'];
    final digest = value['sha256'];
    if (path is! String ||
        !_isSafeBundlePath(path) ||
        digest is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(digest)) {
      throw const JuiBundleException('Invalid bundle file path or SHA-256.');
    }
    return JuiBundleFile(path: path, sha256: digest.toLowerCase());
  }
}

class JuiBundleManifest {
  JuiBundleManifest({
    required this.bundleVersion,
    required this.minimumHostApiVersion,
    required this.entryScreen,
    required List<JuiBundleFile> files,
  }) : files = List.unmodifiable(files);

  final String bundleVersion;
  final int minimumHostApiVersion;
  final String entryScreen;
  final List<JuiBundleFile> files;

  factory JuiBundleManifest.fromJson(Object? value) {
    if (value is! Map) {
      throw const JuiBundleException('Bundle manifest must be an object.');
    }
    final schema = value['schemaVersion'];
    final version = value['bundleVersion'];
    final minimumHost = value['minimumHostApiVersion'];
    final entryScreen = value['entryScreen'];
    final rawFiles = value['files'];
    if (schema != juiBundleSchemaVersion ||
        version is! String ||
        !RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?$')
            .hasMatch(version) ||
        minimumHost is! int ||
        minimumHost < 1 ||
        entryScreen is! String ||
        !_isSafeBundlePath(entryScreen) ||
        !entryScreen.endsWith('.jui') ||
        rawFiles is! List ||
        rawFiles.isEmpty) {
      throw const JuiBundleException('Unsupported or malformed bundle manifest.');
    }
    final files = rawFiles.map(JuiBundleFile.fromJson).toList();
    final paths = files.map((file) => file.path).toSet();
    if (paths.length != files.length || !paths.contains(entryScreen)) {
      throw const JuiBundleException(
        'Bundle file paths must be unique and include the entry screen.',
      );
    }
    return JuiBundleManifest(
      bundleVersion: version,
      minimumHostApiVersion: minimumHost,
      entryScreen: entryScreen,
      files: files,
    );
  }
}

class JuiBundlePackage {
  JuiBundlePackage({
    required this.manifestJson,
    required Map<String, Uint8List> files,
  }) : files = Map.unmodifiable({
         for (final entry in files.entries)
           entry.key: Uint8List.fromList(entry.value),
       });

  final Object? manifestJson;
  final Map<String, Uint8List> files;
}

class JuiValidatedBundle {
  JuiValidatedBundle({
    required this.manifest,
    required Map<String, Uint8List> files,
    required Map<String, JuiDocument> screens,
  }) : files = Map.unmodifiable(files),
       screens = Map.unmodifiable(screens);

  final JuiBundleManifest manifest;
  final Map<String, Uint8List> files;
  final Map<String, JuiDocument> screens;

  JuiDocument get entryDocument => screens[manifest.entryScreen]!;
}

class JuiBundleValidator {
  JuiBundleValidator({this.hostApiVersion = juiHostApiVersion, JuiParser? parser})
    : parser = parser ?? JuiParser();

  final int hostApiVersion;
  final JuiParser parser;

  JuiValidatedBundle validate(JuiBundlePackage bundle) {
    final manifest = JuiBundleManifest.fromJson(bundle.manifestJson);
    if (manifest.minimumHostApiVersion > hostApiVersion) {
      throw JuiBundleException(
        'Bundle requires host API ${manifest.minimumHostApiVersion}; '
        'this app supports $hostApiVersion.',
      );
    }
    final expectedPaths = manifest.files.map((file) => file.path).toSet();
    final actualPaths = bundle.files.keys.toSet();
    if (actualPaths.difference(expectedPaths).isNotEmpty ||
        expectedPaths.difference(actualPaths).isNotEmpty) {
      throw const JuiBundleException(
        'Bundle contents do not match the manifest file list.',
      );
    }

    var totalBytes = 0;
    final validatedFiles = <String, Uint8List>{};
    final screens = <String, JuiDocument>{};
    for (final entry in manifest.files) {
      final bytes = bundle.files[entry.path]!;
      if (bytes.isEmpty || bytes.length > juiMaximumFileBytes) {
        throw JuiBundleException('Invalid file size: ${entry.path}.');
      }
      totalBytes += bytes.length;
      if (totalBytes > juiMaximumBundleBytes) {
        throw const JuiBundleException('Bundle exceeds the 16 MiB size limit.');
      }
      if (sha256.convert(bytes).toString() != entry.sha256) {
        throw JuiBundleException('SHA-256 mismatch: ${entry.path}.');
      }
      _validateFileType(entry.path);
      final copy = Uint8List.fromList(bytes);
      validatedFiles[entry.path] = copy;
      if (entry.path.endsWith('.jui')) {
        final source = utf8.decode(copy, allowMalformed: false);
        final parsed = parser.parse(source);
        if (!parsed.isSuccess) {
          final diagnostic = parsed.diagnostics.isEmpty
              ? 'unknown parser error'
              : parsed.diagnostics.first.toString();
          throw JuiBundleException(
            'Invalid screen ${entry.path}: $diagnostic',
          );
        }
        screens[entry.path] = parsed.document!;
      }
    }
    if (!screens.containsKey(manifest.entryScreen)) {
      throw const JuiBundleException('Entry screen was not parsed.');
    }
    final ids = screens.values.map((screen) => screen.id).toSet();
    if (ids.length != screens.length) {
      throw const JuiBundleException('Screen IDs must be unique in a bundle.');
    }
    return JuiValidatedBundle(
      manifest: manifest,
      files: validatedFiles,
      screens: screens,
    );
  }

  void _validateFileType(String path) {
    final allowed = path.endsWith('.jui') ||
        const {
          '.png', '.jpg', '.jpeg', '.webp', '.svg', '.json', '.ttf', '.otf',
        }.any(path.endsWith);
    if (!allowed) {
      throw JuiBundleException('Unsupported bundle file type: $path.');
    }
  }
}

abstract interface class JuiBundleSource {
  Future<JuiBundlePackage?> fetchLatest({String? currentVersion});
}

/// Implementations must stage files separately and atomically switch the
/// active bundle only after activateStaged succeeds. A failed activation must
/// leave the previous active bundle readable.
abstract interface class JuiBundleStore {
  Future<JuiValidatedBundle?> readActive();
  Future<void> stage(JuiValidatedBundle bundle);
  Future<void> activateStaged({required String expectedCurrentVersion});
  Future<void> discardStaged();
}

enum JuiBundleUpdateStatus { upToDate, updated, unavailable, rejected }

class JuiBundleUpdateResult {
  const JuiBundleUpdateResult({
    required this.status,
    this.activeVersion,
    this.message,
  });

  final JuiBundleUpdateStatus status;
  final String? activeVersion;
  final String? message;
}

class JuiBundleUpdateManager {
  const JuiBundleUpdateManager({
    required this.source,
    required this.store,
    required this.validator,
  });

  final JuiBundleSource source;
  final JuiBundleStore store;
  final JuiBundleValidator validator;

  Future<JuiBundleUpdateResult> checkForUpdates() async {
    final active = await store.readActive();
    final currentVersion = active?.manifest.bundleVersion;
    try {
      final package = await source.fetchLatest(currentVersion: currentVersion);
      if (package == null) {
        return JuiBundleUpdateResult(
          status: JuiBundleUpdateStatus.unavailable,
          activeVersion: currentVersion,
          message: 'No bundle is currently available.',
        );
      }
      final candidate = validator.validate(package);
      if (currentVersion != null &&
          _compareVersions(candidate.manifest.bundleVersion, currentVersion) <=
              0) {
        return JuiBundleUpdateResult(
          status: JuiBundleUpdateStatus.upToDate,
          activeVersion: currentVersion,
        );
      }
      await store.stage(candidate);
      try {
        await store.activateStaged(
          expectedCurrentVersion: currentVersion ?? '',
        );
      } catch (_) {
        await store.discardStaged();
        rethrow;
      }
      return JuiBundleUpdateResult(
        status: JuiBundleUpdateStatus.updated,
        activeVersion: candidate.manifest.bundleVersion,
      );
    } on Object catch (error) {
      return JuiBundleUpdateResult(
        status: JuiBundleUpdateStatus.rejected,
        activeVersion: currentVersion,
        message: error.toString(),
      );
    }
  }
}

bool _isSafeBundlePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.startsWith(String.fromCharCode(92)) ||
      path.contains(String.fromCharCode(92)) ||
      path.contains(':') ||
      path.split('/').any((part) => part.isEmpty || part == '.' || part == '..')) {
    return false;
  }
  return true;
}

int _compareVersions(String left, String right) {
  List<int> parts(String value) => value
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map(int.parse)
      .toList(growable: false);
  final a = parts(left);
  final b = parts(right);
  for (var i = 0; i < 3; i++) {
    final comparison = a[i].compareTo(b[i]);
    if (comparison != 0) return comparison;
  }
  return 0;
}
