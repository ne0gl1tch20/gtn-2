import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
import 'upgrade_catalog.dart';

typedef PermanentUpgradePurchase = Future<ProgressionState> Function(
  GameUpgrade upgrade,
);

class PermanentUpgradeShopPage extends StatefulWidget {
  const PermanentUpgradeShopPage({
    super.key,
    required this.progression,
    required this.ultra,
    required this.onPurchase,
  });

  final ProgressionState progression;
  final bool ultra;
  final PermanentUpgradePurchase onPurchase;

  @override
  State<PermanentUpgradeShopPage> createState() =>
      _PermanentUpgradeShopPageState();
}

class _PermanentUpgradeShopPageState extends State<PermanentUpgradeShopPage> {
  late ProgressionState _state = widget.progression;
  String? _buyingId;

  List<GameUpgrade> get _catalog => widget.ultra
      ? UpgradeCatalog.availableUltra
      : UpgradeCatalog.availablePrestige;

  BigNumber get _balance => widget.ultra ? _state.ultra : _state.prestige;

  int _level(String id) =>
      (widget.ultra ? _state.ultraUpgrades[id] : _state.prestigeUpgrades[id]) ??
      0;

  Future<void> _buy(GameUpgrade upgrade) async {
    if (_buyingId != null) return;
    setState(() => _buyingId = upgrade.definition.id);
    try {
      final updated = await widget.onPurchase(upgrade);
      if (mounted) setState(() => _state = updated);
    } finally {
      if (mounted) setState(() => _buyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.ultra ? 'Ultra' : 'Prestige';
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_state),
        ),
        title: Text('$currency Upgrades'),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.of(context).pop(_state),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
        children: [
          GtnPageHeader(
            eyebrow: widget.ultra ? 'Ultra progression' : 'Prestige progression',
            title: '$currency Upgrades',
            description:
                'Permanent bonuses that stay with your progression after resets.',
            icon: widget.ultra ? Icons.bolt_rounded : Icons.stars_rounded,
            accent: widget.ultra ? GtnUiTokens.cyan : GtnUiTokens.purple,
            trailing: _PermanentBalanceChip(
              label: currency,
              value: _balance.toString(),
            ),
          ),
          const SizedBox(height: 8),
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
                  for (final upgrade in _catalog)
                    SizedBox(
                      width: width,
                      child: _PermanentUpgradeCard(
                        upgrade: upgrade,
                        level: _level(upgrade.definition.id),
                        balance: _balance,
                        currency: currency,
                        busy: _buyingId != null,
                        onBuy: () => _buy(upgrade),
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

class _PermanentBalanceChip extends StatelessWidget {
  const _PermanentBalanceChip({required this.label, required this.value});

  final String label;
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: GtnUiTokens.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: GtnUiTokens.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _PermanentUpgradeCard extends StatelessWidget {
  const _PermanentUpgradeCard({
    required this.upgrade,
    required this.level,
    required this.balance,
    required this.currency,
    required this.busy,
    required this.onBuy,
  });

  final GameUpgrade upgrade;
  final int level;
  final BigNumber balance;
  final String currency;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final definition = upgrade.definition;
    final maxed = definition.maxLevel != null && level >= definition.maxLevel!;
    final cost = definition.costAtLevel(level);
    final affordable = balance.compareTo(cost) >= 0;
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
                Text('Lv. $level / ${definition.maxLevel}'),
              ],
            ),
            const SizedBox(height: 6),
            Text(upgrade.description),
            const SizedBox(height: 6),
            Text(
              upgrade.effectDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            M3EButton.filled(
              onPressed: busy || maxed || !affordable ? null : onBuy,
              child: Text(
                maxed ? 'Max level reached' : 'Upgrade · $cost $currency',
              ),
            ),
            if (!maxed && !affordable)
              Text(
                'Need ${cost - balance} more $currency',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
