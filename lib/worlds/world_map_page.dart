import 'package:flutter/material.dart';

import '../core/progression/progression_state.dart';
import 'world_boss_catalog.dart';

typedef BossAttack = Future<ProgressionState> Function(
  WorldBossDefinition boss,
);

class WorldMapPage extends StatefulWidget {
  const WorldMapPage({
    super.key,
    required this.progression,
    required this.onAttack,
  });

  final ProgressionState progression;
  final BossAttack onAttack;

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  late ProgressionState _state = widget.progression;
  String? _attacking;

  Future<void> _attack(WorldBossDefinition boss) async {
    if (_attacking != null) return;
    setState(() => _attacking = boss.id);
    try {
      final updated = await widget.onAttack(boss);
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
              final defeated = WorldBossCatalog.isDefeated(_state, boss);
              final damage = WorldBossCatalog.damage(_state, boss);
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
                          Text(defeated ? 'Defeated' : unlocked ? 'Unlocked' : 'Locked'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(boss.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(boss.description),
                      const SizedBox(height: 10),
                      Text('Boss health: ${boss.hits - damage} / ${boss.hits}'),
                      LinearProgressIndicator(value: damage / boss.hits),
                      const SizedBox(height: 8),
                      Text(
                        'Requires ${boss.correctRequirement} correct guesses, '
                        '${boss.upgradeRequirement} upgrade levels, '
                        '${boss.prestigeRequirement} Prestige resets and '
                        '${boss.ultraRequirement} Ultra resets.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Reward: ${boss.moneyReward} Money + ${boss.nebulaReward} Nebula'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: !unlocked || defeated || _attacking != null
                            ? null
                            : () => _attack(boss),
                        child: Text(
                          defeated
                              ? 'Victory claimed'
                              : unlocked
                                  ? 'Attack boss'
                                  : 'World locked',
                        ),
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
