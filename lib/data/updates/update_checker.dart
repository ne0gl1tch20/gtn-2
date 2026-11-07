import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateRelease {
  const UpdateRelease({
    required this.versionName,
    required this.versionCode,
    required this.runNumber,
    required this.commitSha,
    required this.sha256,
    required this.apkUrl,
    required this.releaseUrl,
  });

  final String versionName;
  final int versionCode;
  final int runNumber;
  final String commitSha;
  final String sha256;
  final String apkUrl;
  final String releaseUrl;
}

class UpdateChecker {
  static const repository = 'ne0gl1tch20/gtn-2';
  static const releaseTag = 'debug-latest';
  static const packageName = 'com.jarrlyyy.gtn_2';
  static const apkAssetName = 'GuessTheNumber-debug.apk';
  static const manifestAssetName = 'update-manifest.json';
  static const currentVersionName = String.fromEnvironment('APP_VERSION', defaultValue: '2.0.0');
  static const currentVersionCode = int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 1);
  static const maxMetadataBytes = 1024 * 1024;
  static const maxApkBytes = 250 * 1024 * 1024;

  Future<UpdateRelease?> checkForUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final release = await _getJson(
        client,
        Uri.parse('https://api.github.com/repos/$repository/releases/tags/$releaseTag'),
      );
      if (release['tag_name'] != releaseTag) {
        throw const FormatException('Unexpected Stable Debug release tag.');
      }
      final releaseUrl = release['html_url'];
      final assets = release['assets'];
      if (releaseUrl is! String || !_isReleaseUrl(Uri.tryParse(releaseUrl)) || assets is! List) {
        throw const FormatException('Stable Debug release metadata is invalid.');
      }
      String? assetUrl(String name) {
        for (final item in assets) {
          if (item is! Map<String, dynamic> || item['name'] != name) continue;
          final value = item['browser_download_url'];
          if (value is String && _isReleaseAssetUrl(Uri.tryParse(value), name)) return value;
        }
        return null;
      }
      final manifestUrl = assetUrl(manifestAssetName);
      final apkUrl = assetUrl(apkAssetName);
      if (manifestUrl == null || apkUrl == null) {
        throw const FormatException('Stable Debug release is missing its APK or update manifest.');
      }
      final manifest = await _getJson(client, Uri.parse(manifestUrl));
      final versionName = manifest['versionName'];
      final versionCode = manifest['versionCode'];
      final runNumber = manifest['runNumber'];
      final commitSha = manifest['commit'];
      final checksum = manifest['sha256'];
      if (manifest['channel'] != 'android-debug' ||
          manifest['packageName'] != packageName ||
          manifest['assetName'] != apkAssetName ||
          versionName is! String || versionName.isEmpty ||
          versionCode is! int || versionCode <= 0 ||
          runNumber is! int || runNumber <= 0 ||
          commitSha is! String || !RegExp(r'^[a-fA-F0-9]{40}$').hasMatch(commitSha) ||
          checksum is! String || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(checksum)) {
        throw const FormatException('Stable Debug update manifest is invalid.');
      }
      if (isCurrent(
        remoteVersionName: versionName,
        remoteVersionCode: versionCode,
        remoteRunNumber: runNumber,
        installedVersionName: currentVersionName,
        installedVersionCode: currentVersionCode,
        installedRunNumber: currentVersionCode,
      )) return null;
      return UpdateRelease(
        versionName: versionName,
        versionCode: versionCode,
        runNumber: runNumber,
        commitSha: commitSha,
        sha256: checksum.toLowerCase(),
        apkUrl: apkUrl,
        releaseUrl: releaseUrl,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> downloadAndInstall(UpdateRelease update) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('In-app APK installation is only supported on Android.');
    }
    if (!_isReleaseAssetUrl(Uri.tryParse(update.apkUrl), apkAssetName) ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(update.sha256)) {
      throw const FormatException('Update download metadata is not trusted.');
    }
    final directory = await getTemporaryDirectory();
    final apk = File('${directory.path}/gtn2-update.apk');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(update.apkUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'GTN2-Updater');
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('APK download returned HTTP ${response.statusCode}.');
      }
      if (response.contentLength > maxApkBytes) {
        throw const FormatException('Update APK exceeds the size limit.');
      }
      final sink = apk.openWrite();
      var total = 0;
      try {
        await for (final chunk in response.timeout(const Duration(seconds: 60))) {
          total += chunk.length;
          if (total > maxApkBytes) throw const FormatException('Update APK exceeds the size limit.');
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final actual = await sha256.bind(apk.openRead()).first;
      if (actual.toString().toLowerCase() != update.sha256.toLowerCase()) {
        throw const FormatException('Downloaded APK failed SHA-256 verification.');
      }
      final result = await OpenFilex.open(
        apk.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) throw StateError(result.message);
    } catch (_) {
      if (await apk.exists()) await apk.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static bool isCurrent({
    required String remoteVersionName,
    required int remoteVersionCode,
    required int remoteRunNumber,
    required String installedVersionName,
    required int installedVersionCode,
    required int installedRunNumber,
  }) {
    if (remoteVersionCode < installedVersionCode) return true;
    if (remoteVersionCode > installedVersionCode) return false;
    final order = compareVersions(remoteVersionName, installedVersionName);
    if (order < 0) return true;
    if (order > 0) return false;
    return remoteRunNumber <= installedRunNumber;
  }

  static int compareVersions(String left, String right) {
    List<int> parts(String value) => RegExp(r'\d+')
        .allMatches(value).take(4).map((match) => int.parse(match.group(0)!)).toList();
    final a = parts(left);
    final b = parts(right);
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final comparison = (i < a.length ? a[i] : 0).compareTo(i < b.length ? b[i] : 0);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  Future<Map<String, dynamic>> _getJson(HttpClient client, Uri uri) async {
    if (!_isTrustedMetadataUrl(uri)) throw const FormatException('Update metadata URL is not trusted.');
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    request.headers.set(HttpHeaders.userAgentHeader, 'GTN2-Updater');
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub returned HTTP ${response.statusCode}.');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      bytes.addAll(chunk);
      if (bytes.length > maxMetadataBytes) throw const FormatException('Update metadata is too large.');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) throw const FormatException('Update metadata JSON is invalid.');
    return decoded;
  }

  bool _isTrustedMetadataUrl(Uri uri) =>
      uri.scheme == 'https' &&
      (uri.host == 'api.github.com' || _isReleaseAssetUrl(uri, manifestAssetName));

  bool _isReleaseUrl(Uri? uri) =>
      uri != null && uri.scheme == 'https' && uri.host == 'github.com' &&
      uri.path == '/$repository/releases/tag/$releaseTag';

  bool _isReleaseAssetUrl(Uri? uri, String assetName) =>
      uri != null && uri.scheme == 'https' && uri.host == 'github.com' &&
      uri.path == '/$repository/releases/download/$releaseTag/$assetName';
}
