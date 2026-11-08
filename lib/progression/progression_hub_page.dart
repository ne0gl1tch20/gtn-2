import 'package:flutter/material.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_calculator.dart';
import '../core/progression/progression_state.dart';
import '../shop/permanent_upgrade_shop_page.dart';
import '../shop/permanent_shop_catalog.dart';
import '../shop/upgrade_catalog.dart';

typedef ResetAction = Future<ProgressionState> Function();

class ProgressionHubPage extends StatefulWidget {
  const ProgressionHubPage({
    super.key,
    required this.progression,
    required this.onPrestige,
    required this.onUltra,
    required this.onPurchasePermanentUpgrade,
    required this.onPurchasePermanentShopItem,
  });

  final ProgressionState progression;
  final ResetAction onPrestige;
  final ResetAction onUltra;
  final Future<ProgressionState> Function(GameUpgrade upgrade, bool ultra)
      onPurchasePermanentUpgrade;
  final Future<ProgressionState> Function(PermanentShopItem item, bool ultra)
      onPurchasePermanentShopItem;

  @override
  State<ProgressionHubPage> createState() => _ProgressionHubPageState();
}

class _ProgressionHubPageState extends State<ProgressionHubPage> {
  late ProgressionState _state = widget.progression;
  bool _busy = false;

  Future<void> _run(ResetAction action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (mounted) setState(() => _state = updated);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPermanentShop(bool ultra) async {
    final updated = await Navigator.of(context).push<ProgressionState>(
      MaterialPageRoute<ProgressionState>(
        builder: (_) => PermanentUpgradeShopPage(
          progression: _state,
          ultra: ultra,
          onPurchase: (upgrade) =>
              widget.onPurchasePermanentUpgrade(upgrade, ultra),
          onPurchaseShopItem: (item) =>
              widget.onPurchasePermanentShopItem(item, ultra),
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _state = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prestigeRequirement =
        ProgressionCalculator.prestigeRequirement(_state.prestigeResets);
    final prestigeReward = ProgressionCalculator.prestigeRules(_state)
        .rewardForMoney(_state.money);
    final ultraRequirement =
        ProgressionCalculator.ultraRequirement(_state.ultraResets);
    final ultraReward = ProgressionCalculator.ultraRules(_state)
        .rewardForMoney(_state.money);
    final hasPrestigeForUltra =
        _state.prestige.compareTo(BigNumber.fromInt(1000)) >= 0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Prestige & Ultra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Prestige', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Current Prestige: ${_state.prestige}'),
                  Text('Money: ${_state.money}'),
                  Text('Required: $prestigeRequirement Money'),
                  Text('Next reward: $prestigeReward Prestige'),
                  const SizedBox(height: 12),
                  const Text(
                    'Prestige resets Money and normal upgrades while keeping permanent Prestige upgrades.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ||
                            _state.money.compareTo(prestigeRequirement) < 0 ||
                            prestigeReward.compareTo(BigNumber.fromInt(0)) <= 0
                        ? null
                        : () => _run(widget.onPrestige),
                    child: const Text('Prestige reset'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _openPermanentShop(false),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Prestige upgrades'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ultra', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Current Ultra: ${_state.ultra}'),
                  Text('Prestige balance: ${_state.prestige} / 1000'),
                  Text('Money: ${_state.money}'),
                  Text('Required: $ultraRequirement Money'),
                  Text('Next reward: $ultraReward Ultra (max 2,000)'),
                  const SizedBox(height: 12),
                  const Text(
                    'Ultra is a stronger reset. It clears Money, Prestige and the related progression upgrades.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ||
                            !hasPrestigeForUltra ||
                            _state.money.compareTo(ultraRequirement) < 0 ||
                            ultraReward <= 0
                        ? null
                        : () => _run(widget.onUltra),
                    child: const Text('Ultra reset'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _openPermanentShop(true),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Ultra upgrades'),
                  ),
                  if (!hasPrestigeForUltra)
                    Text(
                      'You need 1,000 Prestige before Ultra is available.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
