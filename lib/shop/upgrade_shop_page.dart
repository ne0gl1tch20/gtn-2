import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_engine.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
import 'upgrade_catalog.dart';

typedef UpgradePurchase = Future<ProgressionState> Function(
  UpgradeDefinition definition,
);

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

  Future<void> _buy(GameUpgrade upgrade) async {
    if (_buyingId != null) return;
    setState(() => _buyingId = upgrade.definition.id);
    try {
      final updated = await widget.onPurchase(upgrade.definition);
      if (mounted) setState(() => _progression = updated);
    } finally {
      if (mounted) setState(() => _buyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: const Text('Upgrade Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Money: ${_progression.money}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Make every correct guess count.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Upgrade levels are saved automatically. Prices use the '
            'base cost × growth rate^level formula.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final upgrade in UpgradeCatalog.availableForGameplay)
            _UpgradeCard(
              upgrade: upgrade,
              level: _progression.upgrades[upgrade.definition.id] ?? 0,
              money: _progression.money,
              busy: _buyingId != null,
              onBuy: () => _buy(upgrade),
            ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.level,
    required this.money,
    required this.busy,
    required this.onBuy,
  });

  final GameUpgrade upgrade;
  final int level;
  final BigNumber money;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final maxLevel = upgrade.definition.maxLevel;
    final isMaxed = maxLevel != null && level >= maxLevel;
    final cost = upgrade.definition.costAtLevel(level);
    final canAfford = money.compareTo(cost) >= 0;
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
                  child: Text(
                    upgrade.name,
                    style: theme.textTheme.titleMedium,
                  ),
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
              onPressed: busy || isMaxed || !canAfford ? null : onBuy,
              child: Text(
                isMaxed
                    ? 'Max level reached'
                    : 'Upgrade · $cost Money',
              ),
            ),
            if (!isMaxed && !canAfford)
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
