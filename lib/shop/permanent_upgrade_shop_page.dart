import 'package:flutter/material.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';
import 'permanent_shop_catalog.dart';
import 'upgrade_catalog.dart';

typedef PermanentUpgradePurchase = Future<ProgressionState> Function(
  GameUpgrade upgrade,
);
typedef PermanentShopPurchase = Future<ProgressionState> Function(
  PermanentShopItem item,
);

class PermanentUpgradeShopPage extends StatefulWidget {
  const PermanentUpgradeShopPage({
    super.key,
    required this.progression,
    required this.ultra,
    required this.onPurchase,
    required this.onPurchaseShopItem,
  });

  final ProgressionState progression;
  final bool ultra;
  final PermanentUpgradePurchase onPurchase;
  final PermanentShopPurchase onPurchaseShopItem;

  @override
  State<PermanentUpgradeShopPage> createState() =>
      _PermanentUpgradeShopPageState();
}

class _PermanentUpgradeShopPageState extends State<PermanentUpgradeShopPage> {
  late ProgressionState _state = widget.progression;
  String? _buyingId;
  late final Future<void> _catalogFuture = _loadCatalogs();

  Future<void> _loadCatalogs() async {
    await UpgradeCatalog.load();
    await PermanentShopCatalog.load();
  }

  List<GameUpgrade> get _catalog =>
      widget.ultra ? UpgradeCatalog.availableUltra : UpgradeCatalog.availablePrestige;

  BigNumber get _balance => widget.ultra ? _state.ultra : _state.prestige;

  int _level(String id) => (widget.ultra
      ? _state.ultraUpgrades[id]
      : _state.prestigeUpgrades[id]) ?? 0;

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

  Future<void> _buyShopItem(PermanentShopItem item) async {
    if (_buyingId != null) return;
    setState(() => _buyingId = item.id);
    try {
      final updated = await widget.onPurchaseShopItem(item);
      if (mounted) setState(() => _state = updated);
    } finally {
      if (mounted) setState(() => _buyingId = null);
    }
  }

  Set<String> get _ownedShopItems =>
      widget.ultra ? _state.ultraShopPurchases : _state.prestigeShopPurchases;

  @override
  Widget build(BuildContext context) {
    final currency = widget.ultra ? 'Ultra' : 'Prestige';
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_state),
        ),
        title: Text('$currency Upgrades'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_state),
            child: const Text('Done'),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load the $currency shop: ${snapshot.error}'),
              ),
            );
          }
          final shopItems = widget.ultra
              ? PermanentShopCatalog.ultra
              : PermanentShopCatalog.prestige;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(widget.ultra ? Icons.auto_awesome : Icons.stars),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$currency balance',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _balance.toString(),
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('$currency Upgrades', style: theme.textTheme.titleLarge),
              for (final upgrade in _catalog)
                _PermanentUpgradeCard(
                  upgrade: upgrade,
                  level: _level(upgrade.definition.id),
                  balance: _balance,
                  currency: currency,
                  busy: _buyingId != null,
                  onBuy: () => _buy(upgrade),
                ),
              const SizedBox(height: 12),
              Text('$currency Shop', style: theme.textTheme.titleLarge),
              for (final item in shopItems)
                _PermanentShopItemCard(
                  item: item,
                  currency: currency,
                  balance: _balance,
                  owned: _ownedShopItems.contains(item.id),
                  busy: _buyingId != null,
                  onBuy: () => _buyShopItem(item),
                ),
            ],
          );
        },
      ),
    );
  }
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
            FilledButton(
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

class _PermanentShopItemCard extends StatelessWidget {
  const _PermanentShopItemCard({
    required this.item,
    required this.currency,
    required this.balance,
    required this.owned,
    required this.busy,
    required this.onBuy,
  });

  final PermanentShopItem item;
  final String currency;
  final BigNumber balance;
  final bool owned;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final cost = BigNumber.fromInt(item.cost);
    final affordable = balance.compareTo(cost) >= 0;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(item.description),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy || owned || !affordable ? null : onBuy,
              child: Text(owned ? 'Owned' : 'Buy · $cost $currency'),
            ),
            if (!owned && !affordable)
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
