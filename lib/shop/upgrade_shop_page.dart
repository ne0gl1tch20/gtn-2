import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_engine.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
import 'upgrade_catalog.dart';

typedef UpgradePurchase = Future<ProgressionState> Function(
  UpgradeDefinition definition, {
  required int levels,
});

class UpgradeShopPage extends StatefulWidget {
  const UpgradeShopPage({
    super.key,
    required this.progression,
    required this.onPurchase,
  });

  final ProgressionState progression;
  final UpgradePurchase onPurchase;

  @override
  State<UpgradeShopPage> createState() => _UpgradeShopPageState();
}

class _UpgradeShopPageState extends State<UpgradeShopPage> {
  late ProgressionState _progression = widget.progression;
  String? _buyingId;
  String _buyMultiplier = '1';

  int _levelsToBuy(GameUpgrade upgrade) {
    final current = _progression.upgrades[upgrade.definition.id] ?? 0;
    final maxLevel = upgrade.definition.maxLevel ?? 999999;
    final remaining = maxLevel - current;
    if (remaining <= 0) return 0;
    if (_buyMultiplier == 'MAX') {
      var levels = 0;
      var total = BigNumber.fromInt(0);
      while (levels < remaining) {
        final nextCost = upgrade.definition.costAtLevel(current + levels);
        if (_progression.money.compareTo(total + nextCost) < 0) break;
        total += nextCost;
        levels++;
      }
      return levels == 0 ? 1 : levels;
    }
    return int.parse(_buyMultiplier).clamp(1, remaining);
  }

  BigNumber _costForLevels(GameUpgrade upgrade, int levels) {
    final current = _progression.upgrades[upgrade.definition.id] ?? 0;
    var total = BigNumber.fromInt(0);
    for (var i = 0; i < levels; i++) {
      total += upgrade.definition.costAtLevel(current + i);
    }
    return total;
  }

  Future<void> _buy(GameUpgrade upgrade, int levels) async {
    if (_buyingId != null) return;
    setState(() => _buyingId = upgrade.definition.id);
    try {
      final updated = await widget.onPurchase(upgrade.definition, levels: levels);
      if (mounted) setState(() => _progression = updated);
    } finally {
      if (mounted) setState(() => _buyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('Upgrade Shop')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
        children: [
          GtnPageHeader(
            eyebrow: 'Build your run',
            title: 'Upgrades',
            description: 'Make every correct guess count. Upgrade levels are saved automatically.',
            icon: Icons.upgrade_rounded,
            accent: GtnUiTokens.purple,
            trailing: _BalanceChip(value: _progression.money.toString()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Buy multiplier', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '1', label: Text('1×')),
                  ButtonSegment(value: '10', label: Text('10×')),
                  ButtonSegment(value: '100', label: Text('100×')),
                  ButtonSegment(value: 'MAX', label: Text('MAX')),
                ],
                selected: {_buyMultiplier},
                onSelectionChanged: _buyingId == null
                    ? (selection) => setState(() => _buyMultiplier = selection.first)
                    : null,
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 0,
                children: [
                  for (final upgrade in UpgradeCatalog.availableForGameplay)
                    SizedBox(
                      width: width,
                      child: _UpgradeCard(
                        upgrade: upgrade,
                        level:
                            _progression.upgrades[upgrade.definition.id] ?? 0,
                        money: _progression.money,
                        busy: _buyingId != null,
                        levelsToBuy: _levelsToBuy(upgrade),
                        totalCost: _costForLevels(
                          upgrade,
                          _levelsToBuy(upgrade),
                        ),
                        multiplier: _buyMultiplier,
                        onBuy: (levels) => _buy(upgrade, levels),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 112),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: GtnUiTokens.gold.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GtnUiTokens.gold.withValues(alpha: .24)),
    ),
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: GtnUiTokens.gold, fontWeight: FontWeight.w900),
    ),
  );
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.level,
    required this.money,
    required this.busy,
    required this.levelsToBuy,
    required this.totalCost,
    required this.multiplier,
    required this.onBuy,
  });

  final GameUpgrade upgrade;
  final int level;
  final BigNumber money;
  final bool busy;
  final int levelsToBuy;
  final BigNumber totalCost;
  final String multiplier;
  final ValueChanged<int> onBuy;

  @override
  Widget build(BuildContext context) {
    final maxLevel = upgrade.definition.maxLevel;
    final isMaxed = maxLevel != null && level >= maxLevel;
    final cost = totalCost;
    final canAfford = levelsToBuy > 0 && money.compareTo(cost) >= 0;
    final theme = Theme.of(context);

    return GtnExpressiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(upgrade.name, style: theme.textTheme.titleMedium),
                ),
                Text(
                  maxLevel == null ? 'Lv. $level' : 'Lv. $level / $maxLevel',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(upgrade.description),
            const SizedBox(height: 8),
            Text(
              upgrade.effectDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            M3EButton.filled(
              onPressed: busy || isMaxed || !canAfford
                  ? null
                  : () => onBuy(levelsToBuy),
              child: Text(
                isMaxed
                    ? 'Max level reached'
                    : 'Upgrade · $cost Money${levelsToBuy > 1 ? ' ($levelsToBuy levels)' : ''}',
              ),
            ),
            if (!isMaxed && multiplier != 'MAX' && !canAfford)
              Text(
                'Need ${cost - money} more Money',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
