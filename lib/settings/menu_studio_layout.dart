import 'dart:convert';

import 'game_settings.dart';

class MenuStudioLayout {
  const MenuStudioLayout({
    required this.areas,
    required this.navOrder,
    required this.moreOrder,
    required this.colors,
  });

  static const navigationIds = <String>['worlds', 'arcade', 'upgrades'];

  static const moreIds = <String>[
    'rewards',
    'journey',
    'shop',
    'homebase',
    'relics',
    'codex',
    'changelog',
    'about',
    'music',
    'settings',
    'prestige',
    'ultra',
    'talent',
    'traits',
    'mutators',
    'stats',
    'dev_settings',
    'stake',
  ];

  static const sourceIds = <String>[...navigationIds, ...moreIds];

  static const _sourceToSettings = <String, String>{
    'homebase': 'home_base',
    'stake': 'staking',
  };

  static const _settingsToSource = <String, String>{
    'home_base': 'homebase',
    'staking': 'stake',
  };

  final Map<String, String> areas;
  final List<String> navOrder;
  final List<String> moreOrder;
  final Map<String, String> colors;

  factory MenuStudioLayout.defaults() {
    return MenuStudioLayout(
      areas: {
        for (final id in navigationIds) id: 'nav',
        for (final id in moreIds) id: 'more',
      },
      navOrder: [...navigationIds],
      moreOrder: [...moreIds],
      colors: const {},
    );
  }

  factory MenuStudioLayout.fromSettings(GameSettings settings) {
    final stored = tryParse(settings.webMenuStudioLayout);
    if (stored != null) return stored;

    final defaults = MenuStudioLayout.defaults();
    final moreOrder = <String>[];
    for (final id in settings.moreScreenOrder
        .map((id) => _settingsToSource[id] ?? id)
        .where(moreIds.contains)) {
      if (!moreOrder.contains(id)) moreOrder.add(id);
    }
    for (final id in moreIds) {
      if (!moreOrder.contains(id)) moreOrder.add(id);
    }

    final colors = <String, String>{};
    for (final entry in settings.moreScreenButtonColors.entries) {
      final id = _settingsToSource[entry.key] ?? entry.key;
      if (sourceIds.contains(id) &&
          RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(entry.value)) {
        colors[id] = entry.value.toUpperCase();
      }
    }

    return MenuStudioLayout(
      areas: defaults.areas,
      navOrder: defaults.navOrder,
      moreOrder: moreOrder,
      colors: colors,
    );
  }

  static MenuStudioLayout? tryParse(String? raw) {
    if (raw == null || raw.isEmpty || raw.length > 1600) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded.keys.any(
        (key) => !const ['areas', 'orders', 'colors'].contains(key),
      )) {
        return null;
      }

      final rawAreas = decoded['areas'];
      final rawOrders = decoded['orders'];
      final rawColors = decoded['colors'] ?? <String, dynamic>{};
      if (rawAreas is! Map || rawOrders is! Map || rawColors is! Map) {
        return null;
      }
      if (rawAreas.length > 100 ||
          rawColors.length > 100 ||
          rawOrders.keys.any((key) => key != 'nav' && key != 'more') ||
          !rawOrders.containsKey('nav') ||
          !rawOrders.containsKey('more')) {
        return null;
      }

      final areas = <String, String>{
        for (final id in navigationIds) id: 'nav',
        for (final id in moreIds) id: 'more',
      };
      for (final entry in rawAreas.entries) {
        if (entry.key is! String ||
            !sourceIds.contains(entry.key) ||
            (entry.value != 'nav' && entry.value != 'more')) {
          return null;
        }
        areas[entry.key as String] = entry.value as String;
      }

      List<String>? readOrder(Object? value) {
        if (value is! List ||
            value.length > 100 ||
            value.any((item) => item is! String)) {
          return null;
        }
        final ids = value.cast<String>();
        if (ids.toSet().length != ids.length ||
            ids.any((id) => !sourceIds.contains(id))) {
          return null;
        }
        return List<String>.of(ids);
      }

      final rawNavOrder = readOrder(rawOrders['nav']);
      final rawMoreOrder = readOrder(rawOrders['more']);
      if (rawNavOrder == null || rawMoreOrder == null) return null;

      final navOrder = <String>[
        ...navigationIds,
        ...rawNavOrder.where((id) => !navigationIds.contains(id)),
      ];
      for (final id in sourceIds) {
        if (areas[id] == 'nav' && !navOrder.contains(id)) {
          navOrder.add(id);
        }
      }

      final moreOrder = List<String>.of(rawMoreOrder);
      for (final id in sourceIds) {
        if (areas[id] == 'more' && !moreOrder.contains(id)) {
          moreOrder.add(id);
        }
      }

      final colors = <String, String>{};
      for (final entry in rawColors.entries) {
        if (entry.key is! String ||
            !sourceIds.contains(entry.key) ||
            entry.value is! String ||
            !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(entry.value as String)) {
          return null;
        }
        colors[entry.key as String] = (entry.value as String).toUpperCase();
      }

      return MenuStudioLayout(
        areas: Map.unmodifiable(areas),
        navOrder: List.unmodifiable(navOrder),
        moreOrder: List.unmodifiable(moreOrder),
        colors: Map.unmodifiable(colors),
      );
    } on Object {
      return null;
    }
  }

  List<String> get visibleNavigationIds => navOrder
      .where((id) => sourceIds.contains(id) && areas[id] == 'nav')
      .toList();

  List<String> get visibleMoreIds =>
      moreOrder.where((id) => areas[id] == 'more').toList();

  List<String> get primaryNavigationIds {
    final beforePlay = visibleNavigationIds.where(
      (id) => id == 'worlds' || id == 'arcade',
    );
    final afterPlay = visibleNavigationIds.where(
      (id) => id != 'worlds' && id != 'arcade',
    );
    return [...beforePlay, 'play', ...afterPlay, 'more'];
  }

  int get playIndex => primaryNavigationIds.indexOf('play');

  static String settingsIdFor(String sourceId) =>
      _sourceToSettings[sourceId] ?? sourceId;

  static String sourceIdForSettings(String settingsId) =>
      _settingsToSource[settingsId] ?? settingsId;

  List<String> get settingsMoreOrder => visibleMoreIds
      .map((id) => _sourceToSettings[id] ?? id)
      .toList();

  Map<String, String> get settingsColors => {
    for (final entry in colors.entries)
      (_sourceToSettings[entry.key] ?? entry.key): entry.value,
  };

  String encode() => jsonEncode({
    'areas': areas,
    'orders': {'nav': navOrder, 'more': moreOrder},
    'colors': colors,
  });

  MenuStudioLayout copyWith({
    Map<String, String>? areas,
    List<String>? navOrder,
    List<String>? moreOrder,
    Map<String, String>? colors,
  }) {
    return MenuStudioLayout(
      areas: areas ?? this.areas,
      navOrder: navOrder ?? this.navOrder,
      moreOrder: moreOrder ?? this.moreOrder,
      colors: colors ?? this.colors,
    );
  }
}
