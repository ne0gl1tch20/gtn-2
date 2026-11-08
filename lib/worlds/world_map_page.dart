import 'package:flutter/material.dart';

import '../core/progression/progression_state.dart';
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
  late ProgressionState _state = widget.progression;
  String? _attacking;

  Future<void> _runAction(WorldBossDefinition boss, String action) async {
    if (_attacking != null) return;
    setState(() => _attacking = boss.id);
    try {
      final updated = await widget.onAction(boss.id, action);
      if (mounted) setState(() => _state = updated);
    } finally {
      if (mounted) setState(() => _attacking = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('World Map')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Unlock each world, challenge its guardian and claim its one-time reward.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final boss in WorldBossCatalog.worlds)
            Builder(builder: (context) {
              final unlocked = WorldBossCatalog.isUnlocked(_state, boss);
              final canUnlock = WorldBossCatalog.canUnlock(_state, boss);
              final defeated = WorldBossCatalog.isDefeated(_state, boss);
              final canFight = WorldBossCatalog.canFight(_state, boss);
              final active = _state.legacySystems.activeBossBattleWorldId == boss.id;
              final riftTier = _state.legacySystems.endlessRiftTier.clamp(1, 1000000).toInt();
              final bossHp = boss.hits + (_state.legacySystems.endlessRiftActive ? (riftTier - 1) * 2 : 0);
              final damage = WorldBossCatalog.damage(_state, boss);
              final phase = ((damage * 3) ~/ bossHp + 1).clamp(1, 3);
              final misses = _state.legacySystems.bossBattleMistakes[boss.bossId] ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(boss.worldName, style: theme.textTheme.titleLarge),
                          ),
                          Text(defeated ? 'Defeated' : active ? 'Battle active' : canFight ? 'Ready to fight' : unlocked ? 'Unlocked' : canUnlock ? 'Ready to unlock' : 'Locked'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(boss.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(boss.description),
                      const SizedBox(height: 10),
                      Text('Boss health: ${bossHp - damage} / $bossHp'),
                      LinearProgressIndicator(value: damage / bossHp),
                      if (active) Text('Phase $phase · Misses this phase: $misses'),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock: ${boss.unlockCorrectGuesses} correct guesses, '
                        '${boss.unlockUpgradeCount} upgrades, '
                        '${boss.unlockPrestigeCount} Prestige and '
                        '${boss.unlockUltraCount} Ultra.\n'
                        'Fight: ${boss.fightCorrectGuesses} correct guesses, '
                        '${boss.fightUpgradeCount} upgrades, '
                        '${boss.fightPrestigeCount} Prestige and '
                        '${boss.fightUltraCount} Ultra.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Reward: ${boss.moneyReward} Money + ${boss.nebulaReward} Nebula'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: defeated || _attacking != null || (!canFight && !active)
                            ? null
                            : () => _runAction(boss, 'boss'),
                        child: Text(
                          defeated
                              ? 'Victory claimed'
                              : active
                                  ? 'Leave boss battle'
                                  : canFight
                                      ? 'Start boss battle'
                                      : unlocked
                                          ? 'Fight requirements not met'
                                          : 'World locked',
                        ),
                      ),
                      if (canUnlock)
                        FilledButton.tonal(
                          onPressed: _attacking != null
                              ? null
                              : () => _runAction(boss, 'unlock'),
                          child: const Text('Unlock world'),
                        ),
                      if (unlocked)
                        OutlinedButton(
                          onPressed: _attacking != null
                              ? null
                              : () => _runAction(boss, 'select_world'),
                          child: Text(_state.legacySystems.activeWorldId == boss.id
                              ? 'Selected world'
                              : 'Select world'),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
