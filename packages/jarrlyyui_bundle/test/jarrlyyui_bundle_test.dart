import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jarrlyyui_bundle/jarrlyyui_bundle.dart';
import 'package:test/test.dart';

const source = '''
screen "home" version 1 {
  column {
    text key "home.title"
  }
}
''';

JuiBundlePackage package({
  String version = '1.0.0',
  String screenSource = source,
  int minimumHostApiVersion = 1,
}) {
  final bytes = Uint8List.fromList(utf8.encode(screenSource));
  return JuiBundlePackage(
    manifestJson: {
      'schemaVersion': 1,
      'bundleVersion': version,
      'minimumHostApiVersion': minimumHostApiVersion,
      'entryScreen': 'screens/home.jui',
      'files': [
        {
          'path': 'screens/home.jui',
          'sha256': sha256.convert(bytes).toString(),
        },
      ],
    },
    files: {'screens/home.jui': bytes},
  );
}

class MemorySource implements JuiBundleSource {
  MemorySource(this.next);

  final JuiBundlePackage? next;
  String? requestedVersion;

  @override
  Future<JuiBundlePackage?> fetchLatest({String? currentVersion}) async {
    requestedVersion = currentVersion;
    return next;
  }
}

class MemoryStore implements JuiBundleStore {
  JuiValidatedBundle? active;
  JuiValidatedBundle? staged;
  bool failActivation = false;
  int discardCount = 0;

  @override
  Future<JuiValidatedBundle?> readActive() async => active;

  @override
  Future<void> stage(JuiValidatedBundle bundle) async {
    staged = bundle;
  }

  @override
  Future<void> activateStaged({required String expectedCurrentVersion}) async {
    if (failActivation) throw StateError('activation failed');
    expect(active?.manifest.bundleVersion ?? '', expectedCurrentVersion);
    active = staged;
    staged = null;
  }

  @override
  Future<void> discardStaged() async {
    discardCount++;
    staged = null;
  }
}

void main() {
  group('JuiBundleValidator', () {
    test('validates hash and parses entry screen', () {
      final result = JuiBundleValidator().validate(package());
      expect(result.entryDocument.id, 'home');
      expect(result.screens.keys, contains('screens/home.jui'));
    });

    test('rejects tampered file bytes', () {
      final original = package();
      final tampered = JuiBundlePackage(
        manifestJson: original.manifestJson,
        files: {'screens/home.jui': Uint8List.fromList([1, 2, 3])},
      );
      expect(
        () => JuiBundleValidator().validate(tampered),
        throwsA(isA<JuiBundleException>()),
      );
    });

    test('rejects a screen that references an asset absent from the bundle', () {
      const screen = '''
screen "home" version 1 {
  image asset "images/missing.png"
}
''';
      final bytes = Uint8List.fromList(utf8.encode(screen));
      final invalid = JuiBundlePackage(
        manifestJson: {
          'schemaVersion': 1,
          'bundleVersion': '1.0.0',
          'minimumHostApiVersion': 1,
          'entryScreen': 'screens/home.jui',
          'files': [
            {
              'path': 'screens/home.jui',
              'sha256': sha256.convert(bytes).toString(),
            },
          ],
        },
        files: {'screens/home.jui': bytes},
      );
      expect(
        () => JuiBundleValidator().validate(invalid),
        throwsA(isA<JuiBundleException>()),
      );
    });

    test('rejects reserved manifest and Windows device paths', () {
      final digest = sha256.convert(utf8.encode('asset')).toString();
      expect(
        () => JuiBundleManifest.fromJson({
          'schemaVersion': 1,
          'bundleVersion': '1.0.0',
          'minimumHostApiVersion': 1,
          'entryScreen': 'screens/home.jui',
          'files': [
            {'path': 'screens/home.jui', 'sha256': digest},
            {'path': 'manifest.json', 'sha256': digest},
          ],
        }),
        throwsA(isA<JuiBundleException>()),
      );
      expect(
        () => JuiBundleFile.fromJson({
          'path': 'images/CON.png',
          'sha256': digest,
        }),
        throwsA(isA<JuiBundleException>()),
      );
    });

    test('rejects unsupported host API version', () {
      expect(
        () => JuiBundleValidator().validate(
          package(minimumHostApiVersion: 2),
        ),
        throwsA(isA<JuiBundleException>()),
      );
    });

    test('rejects path traversal and executable file extensions', () {
      final bytes = Uint8List.fromList(utf8.encode('no'));
      final traversal = JuiBundlePackage(
        manifestJson: {
          'schemaVersion': 1,
          'bundleVersion': '1.0.0',
          'minimumHostApiVersion': 1,
          'entryScreen': '../home.jui',
          'files': [
            {'path': '../home.jui', 'sha256': sha256.convert(bytes).toString()},
          ],
        },
        files: {'../home.jui': bytes},
      );
      expect(
        () => JuiBundleValidator().validate(traversal),
        throwsA(isA<JuiBundleException>()),
      );
    });
  });

  group('JuiGitHubBundleSource', () {
    test('downloads manifest and exact listed files over HTTPS', () async {
      final bytes = Uint8List.fromList(utf8.encode(source));
      final manifest = {
        'schemaVersion': 1,
        'bundleVersion': '1.0.0',
        'minimumHostApiVersion': 1,
        'entryScreen': 'screens/home.jui',
        'files': [
          {
            'path': 'screens/home.jui',
            'sha256': sha256.convert(bytes).toString(),
          },
        ],
      };
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/manifest.json')) {
          return http.Response(jsonEncode(manifest), 200);
        }
        if (request.url.path.endsWith('/screens/home.jui')) {
          return http.Response.bytes(bytes, 200);
        }
        return http.Response('', 404);
      });
      final sourceAdapter = JuiGitHubBundleSource(
        owner: 'example',
        repository: 'gtn-ui',
        ref: 'main',
        directory: 'bundles/stable',
        client: client,
      );

      final downloaded = await sourceAdapter.fetchLatest();
      final validated = JuiBundleValidator().validate(downloaded!);

      expect(validated.entryDocument.id, 'home');
      expect(validated.manifest.bundleVersion, '1.0.0');
      expect(
        validated.files['screens/home.jui'],
        orderedEquals(bytes),
      );
      client.close();
    });

    test('returns no bundle when the GitHub manifest is missing', () async {
      final client = MockClient((_) async => http.Response('', 404));
      final sourceAdapter = JuiGitHubBundleSource(
        owner: 'example',
        repository: 'gtn-ui',
        ref: 'main',
        directory: 'bundles/stable',
        client: client,
      );

      expect(await sourceAdapter.fetchLatest(), isNull);
      client.close();
    });
  });

  group('JuiFileBundleStore', () {
    test('persists and restores the active bundle across store instances', () async {
      final directory = await Directory.systemTemp.createTemp('jui_bundle_store_');
      addTearDown(() => directory.delete(recursive: true));
      final validator = JuiBundleValidator();
      final store = JuiFileBundleStore(root: directory, validator: validator);
      final bundle = validator.validate(package(version: '1.2.0'));

      expect(await store.readActive(), isNull);
      await store.stage(bundle);
      await store.activateStaged(expectedCurrentVersion: '');

      final reopened = JuiFileBundleStore(
        root: directory,
        validator: validator,
      );
      final active = await reopened.readActive();

      expect(active?.manifest.bundleVersion, '1.2.0');
      expect(active?.entryDocument.id, 'home');
      expect(
        utf8.decode(active!.files['screens/home.jui']!),
        source,
      );
    });

    test('replaces the active pointer only after a newer bundle is staged', () async {
      final directory = await Directory.systemTemp.createTemp('jui_bundle_store_');
      addTearDown(() => directory.delete(recursive: true));
      final validator = JuiBundleValidator();
      final store = JuiFileBundleStore(root: directory, validator: validator);

      await store.stage(validator.validate(package(version: '1.0.0')));
      await store.activateStaged(expectedCurrentVersion: '');
      await store.stage(validator.validate(package(version: '1.1.0')));
      await store.activateStaged(expectedCurrentVersion: '1.0.0');

      expect(
        (await store.readActive())?.manifest.bundleVersion,
        '1.1.0',
      );
      expect(
        await Directory(
          '${directory.path}${Platform.pathSeparator}bundles'
          '${Platform.pathSeparator}1.0.0',
        ).exists(),
        isTrue,
      );
    });

    test('rejects stale activation and keeps the previous active bundle', () async {
      final directory = await Directory.systemTemp.createTemp('jui_bundle_store_');
      addTearDown(() => directory.delete(recursive: true));
      final store = JuiFileBundleStore(root: directory);
      final validator = JuiBundleValidator();
      await store.stage(validator.validate(package(version: '1.0.0')));
      await store.activateStaged(expectedCurrentVersion: '');
      await store.stage(validator.validate(package(version: '1.1.0')));

      await expectLater(
        store.activateStaged(expectedCurrentVersion: '0.9.0'),
        throwsA(isA<StateError>()),
      );
      await store.discardStaged();

      expect(
        (await store.readActive())?.manifest.bundleVersion,
        '1.0.0',
      );
    });
  });

  group('JuiBundleUpdateManager', () {
    test('validates, stages and activates a newer bundle', () async {
      final store = MemoryStore()
        ..active = JuiBundleValidator().validate(package(version: '1.0.0'));
      final source = MemorySource(package(version: '1.1.0'));
      final manager = JuiBundleUpdateManager(
        source: source,
        store: store,
        validator: JuiBundleValidator(),
      );

      final result = await manager.checkForUpdates();

      expect(result.status, JuiBundleUpdateStatus.updated);
      expect(result.activeVersion, '1.1.0');
      expect(source.requestedVersion, '1.0.0');
      expect(store.staged, isNull);
    });

    test('does not downgrade the active bundle', () async {
      final store = MemoryStore()
        ..active = JuiBundleValidator().validate(package(version: '2.0.0'));
      final manager = JuiBundleUpdateManager(
        source: MemorySource(package(version: '1.9.0')),
        store: store,
        validator: JuiBundleValidator(),
      );

      final result = await manager.checkForUpdates();

      expect(result.status, JuiBundleUpdateStatus.upToDate);
      expect(store.active?.manifest.bundleVersion, '2.0.0');
    });

    test('preserves the previous bundle when activation fails', () async {
      final current = JuiBundleValidator().validate(package(version: '1.0.0'));
      final store = MemoryStore()
        ..active = current
        ..failActivation = true;
      final manager = JuiBundleUpdateManager(
        source: MemorySource(package(version: '1.1.0')),
        store: store,
        validator: JuiBundleValidator(),
      );

      final result = await manager.checkForUpdates();

      expect(result.status, JuiBundleUpdateStatus.rejected);
      expect(store.active, same(current));
      expect(store.staged, isNull);
      expect(store.discardCount, 1);
    });
  });
}
