
import 'dart:math' as math;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
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
    final scale = math
        .min(
          constraints.maxWidth / _mapWidth,
          constraints.maxHeight / _mapHeight,
        )
        .clamp(0.35, 0.9)
        .toDouble();
    final verticalOffset = (constraints.maxHeight - _mapHeight * scale) / 2;
    final horizontalOffset = (constraints.maxWidth - _mapWidth * scale) / 2;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(horizontalOffset, verticalOffset, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _zoom(double factor) {
    final current = _transformController.value;
    final next = Matrix4.copy(current)
      ..scaleByDouble(factor, factor, factor, 1);
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
    final selectedDefeated =
        WorldBossCatalog.isDefeated(_state, selected) &&
        !_state.legacySystems.endlessRiftActive;
    final selectedActive =
        _state.legacySystems.activeBossBattleWorldId == selected.id;
    final selectedCanUnlock = WorldBossCatalog.canUnlock(_state, selected);
    final selectedCanFight = WorldBossCatalog.canFight(_state, selected);
    final riftTier = _state.legacySystems.endlessRiftTier < 1
        ? 1
        : _state.legacySystems.endlessRiftTier;
    final hp =
        selected.hits +
        (_state.legacySystems.endlessRiftActive ? (riftTier - 1) * 2 : 0);
    final damage = WorldBossCatalog.damage(_state, selected).clamp(0, hp);
    final phase = ((damage * 3) ~/ hp + 1).clamp(1, 3);
    final misses =
        _state.legacySystems.bossBattleMistakes[selected.bossId] ?? 0;
    final mastery = _state.legacySystems.worldMasteryLevels[selected.id] ?? 1;
    const bossRelics = <String>{
      'verdant_guardian',
      'crystal_golem',
      'ember_dragon',
      'nebula_titan',
    };
    final secretDiscount =
        _state.legacySystems.discoveredSecrets.contains(selected.secretId)
        ? 0.20
        : 0.0;
    final sanctuaryDiscount = (_state.legacySystems.homeBaseLevel * 0.01).clamp(
      0.0,
      0.20,
    );
    final relicDiscount =
        _state.legacySystems.equippedRelics.containsAll(bossRelics)
        ? 0.10
        : 0.0;
    final masteryDiscount = (secretDiscount + sanctuaryDiscount + relicDiscount)
        .clamp(0.0, 0.40);
    final masteryCost =
        BigNumber.fromInt(10 * (mastery + 1)) *
        BigNumber.parse((1 - masteryDiscount).toStringAsFixed(2));
    final canUpgradeMastery =
        mastery < 10 && _state.nebula.compareTo(masteryCost) >= 0;

    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: Text(AppLocalizations.text('world_map_title', 'World Map')),
        actions: [
          IconButton(
            tooltip: AppLocalizations.text(
              'map_fit_screen',
              'Fit map to screen',
            ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressionSummary(context),
            const SizedBox(height: 12),
            _buildWorldList(context),
            const SizedBox(height: 16),
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
                                if (WorldBossCatalog.isUnlocked(
                                      _state,
                                      world,
                                    ) &&
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
              mastery: mastery,
              masteryCost: masteryCost,
              canUpgradeMastery: canUpgradeMastery,
            ),
          ],
        ),
      ),
    );
  }

  bool _fitRequested = false;
  bool _hasInitializedTransform = false;

  Widget _buildProgressionSummary(BuildContext context) {
    final activeWorld = WorldBossCatalog.worlds.firstWhere(
      (world) => world.id == _state.legacySystems.activeWorldId,
      orElse: () => WorldBossCatalog.worlds.first,
    );
    final defeatedCount = WorldBossCatalog.worlds
        .where((world) => WorldBossCatalog.isDefeated(_state, world))
        .length;
    final riftBest = _state.legacySystems.endlessRiftBestTier;
    return GtnExpressiveCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GtnPageHeader(
            eyebrow: 'Beyond the Numbers',
            title: AppLocalizations.text(
              'web_ui_your_universe',
              'Your universe',
            ),
            description: 'Explore worlds, discover secrets and challenge their guardians.',
            icon: Icons.explore_rounded,
            accent: GtnUiTokens.cyan,
            trailing: _StatusChip(
              label: '${WorldBossCatalog.worlds.length} WORLDS',
              color: GtnUiTokens.purple,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProgressionCurrencyTile(
                  label: 'PRESTIGE',
                  value: _state.prestige.toString(),
                  detail: '${_state.prestigeResets} ascensions',
                  color: GtnUiTokens.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressionCurrencyTile(
                  label: 'ULTRA',
                  value: _state.ultra.toString(),
                  detail: '${_state.ultraResets} resets',
                  color: GtnUiTokens.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressionCurrencyTile(
                  label: 'NEBULA',
                  value: _state.nebula.toString(),
                  detail: 'Cosmic currency',
                  color: GtnUiTokens.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GtnUiTokens.green.withValues(alpha: .10),
                  GtnUiTokens.cyan.withValues(alpha: .04),
                ],
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: GtnUiTokens.green.withValues(alpha: .14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C584E), Color(0xFF143047)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFA7FFDA),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT REALM',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: GtnUiTokens.muted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .9,
                        ),
                      ),
                      Text(
                        AppLocalizations.text(
                          activeWorld.worldNameKey,
                          activeWorld.worldName,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Your adventure is taking shape.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: GtnUiTokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$defeatedCount',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: GtnUiTokens.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'BOSSES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: GtnUiTokens.muted,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ProgressionMiniTile(
                  icon: Icons.home_rounded,
                  value: 'Lv. ${_state.legacySystems.homeBaseLevel}',
                  label: 'Home base',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressionMiniTile(
                  icon: Icons.all_inclusive_rounded,
                  value: 'Tier ${riftBest < 1 ? 0 : riftBest}',
                  label: 'Endless Rift best',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressionMiniTile(
                  icon: Icons.shield_rounded,
                  value: '$defeatedCount',
                  label: 'Bosses defeated',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorldList(BuildContext context) {
    final theme = Theme.of(context);
    return GtnExpressiveCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: GtnUiTokens.purple),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORLD EXPEDITION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: GtnUiTokens.cyan,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Worlds & bosses',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: 'READY', color: GtnUiTokens.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock new realms and challenge their guardians. Boss rules and rewards are handled by the game engine.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: GtnUiTokens.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          for (final world in WorldBossCatalog.worlds)
            _buildWorldEntry(context, world),
        ],
      ),
    );
  }

  Widget _buildWorldEntry(BuildContext context, WorldBossDefinition world) {
    final theme = Theme.of(context);
    final unlocked = WorldBossCatalog.isUnlocked(_state, world);
    final defeated =
        WorldBossCatalog.isDefeated(_state, world) &&
        !_state.legacySystems.endlessRiftActive;
    final active = _state.legacySystems.activeBossBattleWorldId == world.id;
    final canUnlock = WorldBossCatalog.canUnlock(_state, world);
    final canFight = WorldBossCatalog.canFight(_state, world);
    final selected = _selectedWorldId == world.id;
    final riftTier = _state.legacySystems.endlessRiftTier < 1
        ? 1
        : _state.legacySystems.endlessRiftTier;
    final hp =
        world.hits +
        (_state.legacySystems.endlessRiftActive ? (riftTier - 1) * 2 : 0);
    final damage = WorldBossCatalog.damage(_state, world).clamp(0, hp);
    final remaining = (hp - damage).clamp(0, hp);
    final busy = _busyAction != null;
    final status = defeated
        ? 'CLEARED'
        : active
        ? 'BATTLE LIVE'
        : unlocked
        ? 'UNLOCKED'
        : 'LOCKED';
    final statusColor = defeated
        ? GtnUiTokens.green
        : unlocked
        ? GtnUiTokens.purple
        : GtnUiTokens.muted;
    final name = AppLocalizations.text(world.worldNameKey, world.worldName);
    final bossName = AppLocalizations.text(world.bossNameKey, world.name);
    final requirement = !unlocked
        ? AppLocalizations.text(
            world.worldRequirementKey,
            'World unlock requirements are not met.',
          )
        : !canFight && !active && !defeated
        ? AppLocalizations.text(
            world.bossRequirementKey,
            'Boss battle requirements are not met.',
          )
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0B1020)
            : const Color(0xFFF1F3FA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected
              ? GtnUiTokens.purple.withValues(alpha: .5)
              : theme.colorScheme.outlineVariant.withValues(alpha: .45),
        ),
        gradient: selected
            ? LinearGradient(
                colors: [
                  GtnUiTokens.purple.withValues(alpha: .10),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bossName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GtnUiTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'BOSS HEALTH',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: GtnUiTokens.muted,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
              Text(
                '$remaining / $hp HP',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              children: [
                Container(
                  height: 5,
                  color: theme.colorScheme.onSurface.withValues(alpha: .08),
                ),
                FractionallySizedBox(
                  widthFactor: hp == 0 ? 0 : remaining / hp,
                  child: Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [GtnUiTokens.danger, Color(0xFFFFB16D)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (requirement != null) ...[
            const SizedBox(height: 10),
            Text(
              requirement,
              style: theme.textTheme.bodySmall?.copyWith(
                color: GtnUiTokens.muted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!unlocked)
                M3EButton.tonal(
                  onPressed: canUnlock && !busy
                      ? () => _runAction(world.id, 'unlock')
                      : null,
                  child: Text(
                    canUnlock ? 'Unlock world' : 'Requirements pending',
                  ),
                ),
              M3EButton.filled(
                onPressed: (active || canFight) && !busy && !defeated
                    ? () => _runAction(world.id, 'boss')
                    : null,
                child: Text(
                  active
                      ? 'Leave battle'
                      : defeated && !_state.legacySystems.endlessRiftActive
                      ? 'Boss defeated'
                      : 'Start battle',
                ),
              ),
              if (unlocked)
                M3EButton.icon(
                  style: M3EButtonStyle.text,
                  onPressed: busy
                      ? null
                      : () => _runAction(world.id, 'select_world'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _state.legacySystems.activeWorldId == world.id
                        ? 'Selected world'
                        : 'Select world',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

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
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: unlocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    defeated
                        ? '★'
                        : active
                        ? '⚔'
                        : unlocked
                        ? '●'
                        : '🔒',
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
    final found = _state.legacySystems.discoveredSecrets.contains(
      world.secretId,
    );
    final theme = Theme.of(context);
    return Positioned(
      left: world.x * _mapWidth - 17,
      top: world.y * _mapHeight + 45,
      child: Tooltip(
        message: found
            ? AppLocalizations.text(
                'secret_discovered',
                'Secret area discovered',
              )
            : AppLocalizations.text(
                'secret_available',
                'Hidden route discovered',
              ),
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
                child: Icon(
                  Icons.key,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
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
    required int mastery,
    required BigNumber masteryCost,
    required bool canUpgradeMastery,
  }) {
    final theme = Theme.of(context);
    final worldName = AppLocalizations.text(
      world.worldNameKey,
      world.worldName,
    );
    final bossName = AppLocalizations.text(world.bossNameKey, world.name);
    final discovered = _state.legacySystems.discoveredSecrets.contains(
      world.secretId,
    );
    final busy = _busyAction != null;
    return GtnExpressiveCard(
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
              Text(
                AppLocalizations.text(
                  world.worldRequirementKey,
                  'World unlock requirements are not met.',
                ),
              )
            else
              Text(
                AppLocalizations.text(
                  world.bossRequirementKey,
                  'Boss battle requirements',
                ),
              ),
            const SizedBox(height: 8),
            if (unlocked && !defeated) ...[
              Text('Boss HP: ${(hp - damage).clamp(0, hp)} / $hp'),
              M3EProgressIndicator.linearWavy(
                value: (damage / hp).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                'Phase $phase / 3 · Misses this phase: $misses',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                AppLocalizations.text(
                  'boss_battle_tip',
                  'Phase 1: every 4 misses pushes back your progress. '
                      'Phase 2: every 3 misses. Phase 3: every 2 misses.',
                ),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                active
                    ? AppLocalizations.text(
                        'boss_battle_active',
                        'Battle active! Return to Play and guess the number '
                            'to damage this boss.',
                      )
                    : 'Start the battle to make correct guesses damage this boss.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: active ? theme.colorScheme.tertiary : null,
                ),
              ),
              if (_state.legacySystems.endlessRiftActive)
                Text(
                  'Endless Rift · Tier $riftTierLabel',
                  style: theme.textTheme.labelMedium,
                ),
              const SizedBox(height: 8),
            ],
            if (unlocked && !defeated)
              Text(
                AppLocalizations.text(world.bossRewardKey, 'Victory rewards'),
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
              M3EButton.tonal(
                onPressed: canUnlock && !busy
                    ? () => _runAction(world.id, 'unlock')
                    : null,
                child: const Text('Unlock world'),
              )
            else if (!defeated)
              M3EButton.filled(
                onPressed: (active || canFight) && !busy
                    ? () => _runAction(world.id, 'boss')
                    : null,
                child: Text(active ? 'Leave boss battle' : 'Start boss battle'),
              )
            else ...[
              Text(
                AppLocalizations.text('boss_defeated', 'Boss defeated'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.text(
                  'world_mastery_label',
                  'World mastery: $mastery / 10',
                ),
                style: theme.textTheme.titleSmall,
              ),
              Text(
                AppLocalizations.text(
                  'world_mastery_bonus',
                  '+${mastery * 2}% Money per correct guess in this world.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
              M3EButton.tonal(
                onPressed: canUpgradeMastery && !busy
                    ? () => _runAction(world.id, 'mastery')
                    : null,
                child: Text(
                  mastery >= 10
                      ? AppLocalizations.text(
                          'world_mastery_max',
                          'Mastery maxed',
                        )
                      : AppLocalizations.text(
                          'world_mastery_upgrade',
                          'Increase mastery · $masteryCost Nebula',
                        ),
                ),
              ),
            ],
            if (unlocked)
              M3EButton.icon(
                style: M3EButtonStyle.text,
                onPressed: busy
                    ? null
                    : () => _runAction(world.id, 'select_world'),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _state.legacySystems.activeWorldId == world.id
                      ? 'Selected world'
                      : 'Select world',
                ),
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

class _ProgressionCurrencyTile extends StatelessWidget {
  const _ProgressionCurrencyTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: GtnUiTokens.muted,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: GtnUiTokens.muted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressionMiniTile extends StatelessWidget {
  const _ProgressionMiniTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: GtnUiTokens.purple),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: GtnUiTokens.muted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
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
      final bothUnlocked =
          unlockedIds.contains(worlds[from].id) &&
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
      if (correctGuesses >= world.secretAt && unlockedIds.contains(world.id)) {
        final secretPaint = Paint()
          ..color = colorScheme.tertiary.withValues(
            alpha: discoveredSecrets.contains(world.secretId) ? 0.9 : 0.45,
          )
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final start = points[i];
        final end = points[i] + const Offset(38, 52);
        canvas.drawLine(start, end, secretPaint);
        canvas.drawCircle(end, 5, Paint()..color = colorScheme.tertiary);
      }
    }

    for (var i = 0; i < worlds.length; i++) {
      final selected = worlds[i].id == selectedWorldId;
      canvas.drawCircle(
        points[i],
        selected ? 54 : 48,
        Paint()
          ..color =
              (unlockedIds.contains(worlds[i].id)
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
