import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/progression/progression_state.dart';
import '../i18n/app_localizations.dart';
import 'world_boss_catalog.dart';

typedef WorldBossAction = Future<ProgressionState> Function(
  String worldId,
  String action,
);

class WorldMapPage extends StatefulWidget {
  const WorldMapPage({
    super.key,
    required this.progression,
    required this.onAction,
  });

  final ProgressionState progression;
  final WorldBossAction onAction;

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  static const double _mapWidth = 920;
  static const double _mapHeight = 590;
  static const List<(int, int)> _routes = [(0, 1), (1, 2), (1, 3), (2, 3)];

  late ProgressionState _state = widget.progression;
  late String _selectedWorldId = widget.progression.legacySystems.activeWorldId;
  late final TransformationController _transformController =
      TransformationController();
  String? _busyAction;

  @override
  void didUpdateWidget(covariant WorldMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progression != widget.progression) {
      _state = widget.progression;
      final activeId = widget.progression.legacySystems.activeWorldId;
      if (WorldBossCatalog.worlds.any((world) => world.id == activeId)) {
        _selectedWorldId = activeId;
      }
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  WorldBossDefinition get _selectedWorld => WorldBossCatalog.worlds.firstWhere(
        (world) => world.id == _selectedWorldId,
        orElse: () => WorldBossCatalog.worlds.first,
      );

  Future<void> _selectWorld(WorldBossDefinition world) async {
    if (_state.legacySystems.endlessRiftActive &&
        world.id != _state.legacySystems.activeWorldId) {
      return;
    }
    setState(() => _selectedWorldId = world.id);
    if (WorldBossCatalog.isUnlocked(_state, world)) {
      await _runAction(world.id, 'select_world');
    }
  }

  Future<void> _runAction(String worldId, String action) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = '$worldId:$action');
    try {
      final updated = await widget.onAction(worldId, action);
      if (mounted) {
        setState(() {
          _state = updated;
          if (action == 'select_world' &&
              WorldBossCatalog.worlds.any((world) => world.id == worldId)) {
            _selectedWorldId = worldId;
          } else {
            final activeId = updated.legacySystems.activeWorldId;
            if (WorldBossCatalog.worlds.any((world) => world.id == activeId)) {
              _selectedWorldId = activeId;
            }
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  void _resetMap(BoxConstraints constraints) {
    final scale = math.min(
      constraints.maxWidth / _mapWidth,
      constraints.maxHeight / _mapHeight,
    ).clamp(0.35, 0.9).toDouble();
    final verticalOffset =
        (constraints.maxHeight - _mapHeight * scale) / 2;
    final horizontalOffset =
        (constraints.maxWidth - _mapWidth * scale) / 2;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(horizontalOffset, verticalOffset, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _zoom(double factor) {
    final current = _transformController.value;
    final next = Matrix4.copy(current)..scaleByDouble(factor, factor, factor, 1);
    final scale = next.getMaxScaleOnAxis();
    if (scale >= 0.35 && scale <= 3.0) {
      _transformController.value = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selectedWorld;
    final selectedUnlocked = WorldBossCatalog.isUnlocked(_state, selected);
    final selectedDefeated = WorldBossCatalog.isDefeated(_state, selected) &&
        !_state.legacySystems.endlessRiftActive;
    final selectedActive =
        _state.legacySystems.activeBossBattleWorldId == selected.id;
    final selectedCanUnlock = WorldBossCatalog.canUnlock(_state, selected);
    final selectedCanFight = WorldBossCatalog.canFight(_state, selected);
    final riftTier = _state.legacySystems.endlessRiftTier < 1
        ? 1
        : _state.legacySystems.endlessRiftTier;
    final hp = selected.hits +
        (_state.legacySystems.endlessRiftActive ? (riftTier - 1) * 2 : 0);
    final damage = WorldBossCatalog.damage(_state, selected).clamp(0, hp);
    final phase = ((damage * 3) ~/ hp + 1).clamp(1, 3);
    final misses =
        _state.legacySystems.bossBattleMistakes[selected.bossId] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.text('world_map_title', 'World Map')),
        actions: [
          IconButton(
            tooltip: AppLocalizations.text('map_fit_screen', 'Fit map to screen'),
            onPressed: () {
              // The viewport callback installs a correctly sized fit transform.
              setState(() {});
              _fitRequested = true;
            },
            icon: const Icon(Icons.fit_screen),
          ),
          IconButton(
            tooltip: AppLocalizations.text('map_reset_view', 'Reset map view'),
            onPressed: () => _transformController.value = Matrix4.identity(),
            icon: const Icon(Icons.center_focus_strong),
          ),
          IconButton(
            tooltip: AppLocalizations.text('zoom_out', 'Zoom out'),
            onPressed: () => _zoom(1 / 1.25),
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: AppLocalizations.text('zoom_in', 'Zoom in'),
            onPressed: () => _zoom(1.25),
            icon: const Icon(Icons.zoom_in),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          children: [
            Text(
              AppLocalizations.text(
                'world_map_hint',
                'Drag to explore, pinch to zoom, and tap a world to inspect it.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 350,
              child: LayoutBuilder(
                builder: (context, viewport) {
                  if (_fitRequested) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _resetMap(viewport);
                      _fitRequested = false;
                    });
                  } else if (!_hasInitializedTransform) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _hasInitializedTransform) return;
                      _resetMap(viewport);
                      _hasInitializedTransform = true;
                    });
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        constrained: false,
                        panEnabled: true,
                        scaleEnabled: true,
                        minScale: 0.35,
                        maxScale: 3,
                        boundaryMargin: const EdgeInsets.all(220),
                        child: SizedBox(
                          width: _mapWidth,
                          height: _mapHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _WorldRoutesPainter(
                                    worlds: WorldBossCatalog.worlds,
                                    routes: _routes,
                                    unlockedIds:
                                        _state.legacySystems.unlockedWorldIds,
                                    correctGuesses: _state.correctGuesses,
                                    discoveredSecrets:
                                        _state.legacySystems.discoveredSecrets,
                                    selectedWorldId: _selectedWorldId,
                                    colorScheme: theme.colorScheme,
                                  ),
                                ),
                              ),
                              for (final world in WorldBossCatalog.worlds)
                                _buildWorldNode(context, world),
                              for (final world in WorldBossCatalog.worlds)
                                if (WorldBossCatalog.isUnlocked(_state, world) &&
                                    _state.correctGuesses >= world.secretAt)
                                  _buildSecretNode(context, world),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildWorldDetails(
              context,
              selected,
              unlocked: selectedUnlocked,
              defeated: selectedDefeated,
              active: selectedActive,
              canUnlock: selectedCanUnlock,
              canFight: selectedCanFight,
              hp: hp,
              damage: damage,
              phase: phase,
              misses: misses,
            ),
          ],
        ),
      ),
    );
  }

  bool _fitRequested = false;
  bool _hasInitializedTransform = false;

  Widget _buildWorldNode(BuildContext context, WorldBossDefinition world) {
    final theme = Theme.of(context);
    final unlocked = WorldBossCatalog.isUnlocked(_state, world);
    final defeated = WorldBossCatalog.isDefeated(_state, world);
    final selected = _selectedWorldId == world.id;
    final active = _state.legacySystems.activeBossBattleWorldId == world.id;
    final name = AppLocalizations.text(world.worldNameKey, world.worldName);
    final status = defeated
        ? AppLocalizations.text('boss_defeated', 'Defeated')
        : active
            ? AppLocalizations.text('boss_battle_active', 'Battle active')
            : unlocked
                ? AppLocalizations.text('world_status_unlocked', 'Unlocked')
                : AppLocalizations.text('world_status_locked', 'Locked');
    final icon = switch (world.id) {
      'verdant_grove' => Icons.forest,
      'crystal_caverns' => Icons.diamond,
      'ember_summit' => Icons.local_fire_department,
      _ => Icons.auto_awesome,
    };
    return Positioned(
      left: world.x * _mapWidth - 76,
      top: world.y * _mapHeight - 48,
      width: 152,
      child: Semantics(
        button: true,
        selected: selected,
        label: '$name, $status',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('world-node-${world.id}'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => _selectWorld(world),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : unlocked
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: unlocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 3),
                  Text(name, textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    defeated ? '★' : active ? '⚔' : unlocked ? '●' : '🔒',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecretNode(BuildContext context, WorldBossDefinition world) {
    final found = _state.legacySystems.discoveredSecrets.contains(world.secretId);
    final theme = Theme.of(context);
    return Positioned(
      left: world.x * _mapWidth - 17,
      top: world.y * _mapHeight + 45,
      child: Tooltip(
        message: found
            ? AppLocalizations.text('secret_discovered', 'Secret area discovered')
            : AppLocalizations.text('secret_available', 'Hidden route discovered'),
        child: Semantics(
          button: true,
          label: 'Secret area: ${world.secretId}',
          child: Material(
            color: found
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            child: InkWell(
              key: ValueKey('secret-node-${world.secretId}'),
              customBorder: const CircleBorder(),
              onTap: found || _busyAction != null
                  ? null
                  : () => _runAction(world.secretId, 'secret'),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.key, size: 18,
                    color: theme.colorScheme.tertiary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldDetails(
    BuildContext context,
    WorldBossDefinition world, {
    required bool unlocked,
    required bool defeated,
    required bool active,
    required bool canUnlock,
    required bool canFight,
    required int hp,
    required int damage,
    required int phase,
    required int misses,
  }) {
    final theme = Theme.of(context);
    final worldName = AppLocalizations.text(world.worldNameKey, world.worldName);
    final bossName = AppLocalizations.text(world.bossNameKey, world.name);
    final discovered =
        _state.legacySystems.discoveredSecrets.contains(world.secretId);
    final busy = _busyAction != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(worldName, style: theme.textTheme.titleLarge),
                ),
                _StatusChip(
                  label: defeated
                      ? 'Defeated'
                      : active
                          ? 'Battle active'
                          : unlocked
                              ? 'Unlocked'
                              : 'Locked',
                  color: defeated
                      ? theme.colorScheme.tertiary
                      : unlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(bossName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!unlocked)
              Text(AppLocalizations.text(
                world.worldRequirementKey,
                'World unlock requirements are not met.',
              ))
            else
              Text(AppLocalizations.text(
                world.bossRequirementKey,
                'Boss battle requirements',
              )),
            const SizedBox(height: 8),
            if (unlocked && !defeated) ...[
              Text('Boss HP: ${(hp - damage).clamp(0, hp)} / $hp'),
              LinearProgressIndicator(
                value: (damage / hp).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                active ? 'Phase $phase / 3 · Misses this phase: $misses'
                    : 'Correct guesses damage the active boss.',
                style: theme.textTheme.bodySmall,
              ),
              if (_state.legacySystems.endlessRiftActive)
                Text('Endless Rift · Tier $riftTierLabel',
                    style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
            ],
            if (unlocked && !defeated)
              Text(
                AppLocalizations.text(
                  world.bossRewardKey,
                  'Victory rewards',
                ),
                style: theme.textTheme.bodySmall,
              ),
            if (unlocked && _state.correctGuesses >= world.secretAt)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  discovered
                      ? 'Secret area discovered'
                      : 'A hidden route has appeared on the map.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (!unlocked)
              FilledButton.tonal(
                onPressed: canUnlock && !busy
                    ? () => _runAction(world.id, 'unlock')
                    : null,
                child: const Text('Unlock world'),
              )
            else if (!defeated)
              FilledButton(
                onPressed: (active || canFight) && !busy
                    ? () => _runAction(world.id, 'boss')
                    : null,
                child: Text(active ? 'Leave boss battle' : 'Start boss battle'),
              )
            else
              Text(
                AppLocalizations.text('boss_defeated', 'Boss defeated'),
                style: theme.textTheme.labelLarge,
              ),
            if (unlocked)
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () => _runAction(world.id, 'select_world'),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_state.legacySystems.activeWorldId == world.id
                    ? 'Selected world'
                    : 'Select world'),
              ),
          ],
        ),
      ),
    );
  }

  String get riftTierLabel {
    final tier = _state.legacySystems.endlessRiftTier;
    return tier < 1 ? '1' : '$tier';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      );
}

class _WorldRoutesPainter extends CustomPainter {
  const _WorldRoutesPainter({
    required this.worlds,
    required this.routes,
    required this.unlockedIds,
    required this.correctGuesses,
    required this.discoveredSecrets,
    required this.selectedWorldId,
    required this.colorScheme,
  });

  final List<WorldBossDefinition> worlds;
  final List<(int, int)> routes;
  final Set<String> unlockedIds;
  final int correctGuesses;
  final Set<String> discoveredSecrets;
  final String selectedWorldId;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final points = worlds
        .map((world) => Offset(world.x * size.width, world.y * size.height))
        .toList(growable: false);
    for (final (from, to) in routes) {
      final bothUnlocked = unlockedIds.contains(worlds[from].id) &&
          unlockedIds.contains(worlds[to].id);
      final paint = Paint()
        ..color = bothUnlocked
            ? colorScheme.primary.withValues(alpha: 0.75)
            : colorScheme.outlineVariant.withValues(alpha: 0.75)
        ..strokeWidth = bothUnlocked ? 7 : 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(points[from], points[to], paint);
    }

    for (var i = 0; i < worlds.length; i++) {
      final world = worlds[i];
      if (correctGuesses >= world.secretAt &&
          unlockedIds.contains(world.id)) {
        final secretPaint = Paint()
          ..color = colorScheme.tertiary.withValues(
            alpha: discoveredSecrets.contains(world.secretId) ? 0.9 : 0.45,
          )
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final start = points[i] + const Offset(0, 28);
        final end = points[i] + const Offset(0, 83);
        canvas.drawLine(start, end, secretPaint);
        canvas.drawCircle(
          end,
          5,
          Paint()..color = colorScheme.tertiary,
        );
      }
    }

    for (var i = 0; i < worlds.length; i++) {
      final selected = worlds[i].id == selectedWorldId;
      canvas.drawCircle(
        points[i],
        selected ? 54 : 48,
        Paint()
          ..color = (unlockedIds.contains(worlds[i].id)
                  ? colorScheme.primary
                  : colorScheme.outline)
              .withValues(alpha: selected ? 0.16 : 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldRoutesPainter oldDelegate) =>
      oldDelegate.worlds != worlds ||
      oldDelegate.unlockedIds != unlockedIds ||
      oldDelegate.correctGuesses != correctGuesses ||
      oldDelegate.discoveredSecrets != discoveredSecrets ||
      oldDelegate.selectedWorldId != selectedWorldId ||
      oldDelegate.colorScheme != colorScheme;
}
