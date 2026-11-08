import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/live_ops/live_ops.dart';

typedef LiveOpsAssetLoader = Future<String> Function(String path);

class LiveOpsRepository {
  LiveOpsRepository({
    LiveOpsAssetLoader? loadAsset,
    DateTime Function()? clock,
  })  : _loadAsset = loadAsset ?? rootBundle.loadString,
        _clock = clock ?? DateTime.now;

  final LiveOpsAssetLoader _loadAsset;
  final DateTime Function() _clock;

  Future<LiveOpsCatalog> load() async {
    final flagsJson = _decodeObject(
      await _loadAsset('assets/game/feature_flags.json'),
      'feature flags',
    );
    if (flagsJson['schemaVersion'] != 1 ||
        flagsJson['flags'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid GTN1 feature flags.');
    }
    final flags = flagsJson['flags'] as Map<String, dynamic>;
    final enabled = flags['live_ops'] == true &&
        flags['seasonal_rewards'] == true;

    final manifest = _decodeObject(
      await _loadAsset('assets/game/liveops_manifest.json'),
      'LiveOps manifest',
    );
    final schemaVersion = manifest['schemaVersion'] ?? 1;
    final manifestVersion = manifest['manifestVersion'];
    final rawEvents = manifest['events'];
    if (schemaVersion != 1 ||
        manifestVersion is! int ||
        manifestVersion < 1 ||
        manifestVersion > 2 ||
        rawEvents is! List ||
        rawEvents.length > 32) {
      throw const FormatException('Unsupported GTN1 LiveOps manifest.');
    }
    final events = <LiveOpsEvent>[];
    final ids = <String>{};
    for (final raw in rawEvents) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid GTN1 LiveOps event entry.');
      }
      final event = LiveOpsEvent.fromJson(raw);
      if (!ids.add(event.id)) {
        throw FormatException('Duplicate GTN1 LiveOps event ID: ${event.id}');
      }
      events.add(event.resolveStatus(_clock()));
    }
    return LiveOpsCatalog(
      manifestVersion: manifestVersion,
      enabled: enabled,
      events: List.unmodifiable(events),
    );
  }

  static Map<String, dynamic> _decodeObject(String raw, String label) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid $label root.');
    }
    return decoded;
  }
}
