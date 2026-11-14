import 'dart:convert';

import 'package:flutter/services.dart';

import '../legacy/live_ops_claim_policy.dart';

typedef LiveOpsAssetLoader = Future<String> Function(String path);

class LiveOpsEvent {
  const LiveOpsEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.currencyName,
    required this.maxClaims,
    required this.rewardNebula,
    required this.permanentBoostPerClaim,
    required this.minCorrectGuesses,
    required this.minPrestigeCount,
    required this.minUltraCount,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String startDate;
  final String endDate;
  final String currencyName;
  final int maxClaims;
  final int rewardNebula;
  final int permanentBoostPerClaim;
  final int minCorrectGuesses;
  final int minPrestigeCount;
  final int minUltraCount;

  LiveOpsEvent withStatus(String nextStatus) => LiveOpsEvent(
    id: id,
    title: title,
    description: description,
    status: nextStatus,
    startDate: startDate,
    endDate: endDate,
    currencyName: currencyName,
    maxClaims: maxClaims,
    rewardNebula: rewardNebula,
    permanentBoostPerClaim: permanentBoostPerClaim,
    minCorrectGuesses: minCorrectGuesses,
    minPrestigeCount: minPrestigeCount,
    minUltraCount: minUltraCount,
  );

  LiveOpsClaimDefinition toClaimDefinition() => LiveOpsClaimDefinition(
    id: id,
    maxClaims: maxClaims,
    rewardNebula: rewardNebula,
    permanentBoostPerClaim: permanentBoostPerClaim,
    minCorrectGuesses: minCorrectGuesses,
    minPrestigeCount: minPrestigeCount,
    minUltraCount: minUltraCount,
  );
}

class LiveOpsManifest {
  const LiveOpsManifest({
    required this.manifestVersion,
    required this.events,
    this.schemaVersion = 1,
  });

  final int schemaVersion;
  final int manifestVersion;
  final List<LiveOpsEvent> events;
}

class LiveOpsSnapshot {
  const LiveOpsSnapshot({
    required this.enabled,
    required this.events,
    this.error,
  });

  final bool enabled;
  final List<LiveOpsEvent> events;
  final String? error;
}

class LiveOpsContentValidator {
  static const _statuses = {'UPCOMING', 'ACTIVE', 'ENDING', 'ARCHIVED'};
  static const _maxLong = 0x7fffffffffffffff;

  static void validate(LiveOpsManifest manifest) {
    if (manifest.schemaVersion != 1) {
      throw const FormatException('Unsupported LiveOps schema version.');
    }
    if (manifest.manifestVersion < 1 || manifest.manifestVersion > 2) {
      throw const FormatException('Unsupported LiveOps manifest version.');
    }
    if (manifest.events.length > 32) {
      throw const FormatException('LiveOps manifest contains too many events.');
    }
    final ids = <String>{};
    for (final event in manifest.events) {
      if (!RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(event.id) ||
          !ids.add(event.id)) {
        throw FormatException(
          'LiveOps event ID is invalid or duplicated: ${event.id}',
        );
      }
      if (event.title.trim().isEmpty ||
          event.title.length > 100 ||
          event.description.trim().isEmpty ||
          event.description.length > 500 ||
          event.currencyName.trim().isEmpty ||
          event.currencyName.length > 32) {
        throw FormatException(
          'LiveOps event ${event.id} has invalid display content.',
        );
      }
      if (!_statuses.contains(event.status)) {
        throw FormatException(
          'LiveOps event ${event.id} has an invalid status.',
        );
      }
      final start = _parseInstant(event.startDate, event.id);
      final end = _parseInstant(event.endDate, event.id);
      if (!end.isAfter(start)) {
        throw FormatException(
          'LiveOps event ${event.id} has an invalid date window.',
        );
      }
      if (event.maxClaims < 1 ||
          event.maxClaims > 10000 ||
          event.rewardNebula < 0 ||
          event.rewardNebula > _maxLong ||
          event.permanentBoostPerClaim < 0 ||
          event.minCorrectGuesses < 0 ||
          event.minPrestigeCount < 0 ||
          event.minUltraCount < 0) {
        throw FormatException(
          'LiveOps event ${event.id} has invalid reward or eligibility values.',
        );
      }
    }
  }

  static DateTime _parseInstant(String value, String eventId) {
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw FormatException(
        'LiveOps event $eventId date must include a timezone.',
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('LiveOps event $eventId date is invalid.');
    }
    return parsed.toUtc();
  }
}

class LiveOpsRepository {
  LiveOpsRepository({LiveOpsAssetLoader? loadAsset, DateTime Function()? clock})
    : _loadAsset = loadAsset ?? ((path) => rootBundle.loadString(path)),
      _clock = clock ?? DateTime.now;

  static const _defaultFlags = <String, bool>{
    'live_ops': true,
    'seasonal_rewards': true,
    'world_map': true,
    'challenge_builder': true,
    'dev_console': true,
    'lua_scripting': true,
    'shared_web_play': true,
  };

  final LiveOpsAssetLoader _loadAsset;
  final DateTime Function() _clock;

  Future<LiveOpsSnapshot> load() async {
    try {
      final flags = await _loadFeatureFlags();
      final manifest = _decodeManifest(
        await _loadAsset('assets/game/liveops_manifest.json'),
      );
      LiveOpsContentValidator.validate(manifest);
      final now = _clock().toUtc();
      final events = manifest.events
          .map((event) {
            final start = DateTime.parse(event.startDate).toUtc();
            final end = DateTime.parse(event.endDate).toUtc();
            final status = switch (true) {
              _ when event.status == 'ARCHIVED' => 'ARCHIVED',
              _ when now.isBefore(start) => 'UPCOMING',
              _ when !now.isBefore(end) => 'ARCHIVED',
              _ when event.status == 'ENDING' => 'ENDING',
              _ => 'ACTIVE',
            };
            return event.withStatus(status);
          })
          .toList(growable: false);
      return LiveOpsSnapshot(
        enabled: flags['live_ops'] == true && flags['seasonal_rewards'] == true,
        events: List.unmodifiable(events),
      );
    } on Object catch (error) {
      final message = error.toString();
      return LiveOpsSnapshot(
        enabled: false,
        events: const [],
        error: message.length <= 240 ? message : message.substring(0, 240),
      );
    }
  }

  Future<Map<String, bool>> _loadFeatureFlags() async {
    String source;
    try {
      source = await _loadAsset('assets/game/feature_flags.json');
    } on Object {
      return _defaultFlags;
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['flags'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid feature flag configuration.');
    }
    final rawFlags = decoded['flags'] as Map<String, dynamic>;
    final flags = Map<String, bool>.of(_defaultFlags);
    for (final entry in rawFlags.entries) {
      if (entry.value is! bool) {
        throw FormatException('Feature flag ${entry.key} must be boolean.');
      }
      if (flags.containsKey(entry.key)) {
        flags[entry.key] = entry.value as bool;
      }
    }
    return Map.unmodifiable(flags);
  }

  LiveOpsManifest _decodeManifest(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] is! int ||
        decoded['manifestVersion'] is! int ||
        decoded['events'] is! List) {
      throw const FormatException('Invalid LiveOps manifest structure.');
    }
    final events = <LiveOpsEvent>[];
    for (final raw in decoded['events'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid LiveOps event entry.');
      }
      final requiredStrings = [
        raw['id'],
        raw['title'],
        raw['description'],
        raw['status'],
        raw['startDate'],
        raw['endDate'],
        raw['currencyName'],
      ];
      final requiredInts = [
        raw['maxClaims'],
        raw['rewardNebula'] ?? 10,
        raw['permanentBoostPerClaim'] ?? 1,
        raw['minCorrectGuesses'] ?? 0,
        raw['minPrestigeCount'] ?? 0,
        raw['minUltraCount'] ?? 0,
      ];
      if (requiredStrings.any((value) => value is! String) ||
          requiredInts.any((value) => value is! int)) {
        throw const FormatException('LiveOps event fields have invalid types.');
      }
      events.add(
        LiveOpsEvent(
          id: raw['id'] as String,
          title: raw['title'] as String,
          description: raw['description'] as String,
          status: raw['status'] as String,
          startDate: raw['startDate'] as String,
          endDate: raw['endDate'] as String,
          currencyName: raw['currencyName'] as String,
          maxClaims: raw['maxClaims'] as int,
          rewardNebula: (raw['rewardNebula'] ?? 10) as int,
          permanentBoostPerClaim: (raw['permanentBoostPerClaim'] ?? 1) as int,
          minCorrectGuesses: (raw['minCorrectGuesses'] ?? 0) as int,
          minPrestigeCount: (raw['minPrestigeCount'] ?? 0) as int,
          minUltraCount: (raw['minUltraCount'] ?? 0) as int,
        ),
      );
    }
    return LiveOpsManifest(
      schemaVersion: decoded['schemaVersion'] as int,
      manifestVersion: decoded['manifestVersion'] as int,
      events: List.unmodifiable(events),
    );
  }
}
