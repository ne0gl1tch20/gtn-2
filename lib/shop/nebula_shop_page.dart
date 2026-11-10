import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';

class NebulaShopItem {
  const NebulaShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final String effect;
  final BigNumber price;
}

class NebulaShopCatalog {
  NebulaShopCatalog._();

  static const botIds = {'auto_clicker_basic', 'bot_byte', 'bot_pixel'};
  static const botUpgradeIds = {'bot_speed_upgrade', 'bot_logic_upgrade'};
  static const automationIds = {...botIds, ...botUpgradeIds};

  static final items = List<NebulaShopItem>.unmodifiable([
    NebulaShopItem(
      id: 'nebula_boost',
      name: 'Nebula Crystal',
      description: 'A permanent crystal that amplifies Arcade payouts.',
      effect: '2× Nebula from Arcade rewards',
      price: BigNumber.fromInt(50),
    ),
    NebulaShopItem(
      id: 'golden_guess',
      name: 'Golden Guess Pass',
      description: 'Every tenth guess guarantees a critical hit when the answer is correct.',
      effect: 'Guaranteed 5× critical payout every 10th guess',
      price: BigNumber.fromInt(100),
    ),
    NebulaShopItem(
      id: 'auto_clicker_basic',
      name: 'Auto Clicker',
      description: 'Automatically guesses the target using real high/low feedback.',
      effect: 'Starts the feedback-driven guessing bot',
      price: BigNumber.fromInt(25),
    ),
    NebulaShopItem(
      id: 'bot_byte',
      name: 'Bot Byte',
      description: 'Adds a second bot to the guessing team. Bots take turns.',
      effect: 'Adds an independent feedback-driven bot',
      price: BigNumber.fromInt(60),
    ),
    NebulaShopItem(
      id: 'bot_pixel',
      name: 'Bot Pixel',
      description: 'Adds another bot to the guessing team. It takes turns with the others.',
      effect: 'Adds a third feedback-driven bot',
      price: BigNumber.fromInt(75),
    ),
    NebulaShopItem(
      id: 'bot_speed_upgrade',
      name: 'Bot Speed Upgrade',
      description: 'Makes the automation team guess 50% faster.',
      effect: '1.5× bot speed, up to the original 5× cap',
      price: BigNumber.fromInt(35),
    ),
    NebulaShopItem(
      id: 'bot_logic_upgrade',
      name: 'Shared Memory Upgrade',
      description: 'Lets all owned bots share their learned high/low hints.',
      effect: 'Bots share one feedback interval instead of learning separately',
      price: BigNumber.fromInt(50),
    ),
  ]);
}

typedef NebulaPurchase = Future<ProgressionState> Function(
  NebulaShopItem item,
);

class NebulaShopPage extends StatefulWidget {
  const NebulaShopPage({
    super.key,
    required this.progression,
    required this.onPurchase,
    required this.onAutomationChanged,
  });

  final ProgressionState progression;
  final NebulaPurchase onPurchase;
  final Future<ProgressionState> Function(bool active) onAutomationChanged;

  @override
  State<NebulaShopPage> createState() => _NebulaShopPageState();
}

class _NebulaShopPageState extends State<NebulaShopPage> {
  late ProgressionState _state = widget.progression;
  String? _buyingId;
  bool _togglingAutomation = false;

  Future<void> _toggleAutomation(bool active) async {
    if (_togglingAutomation) return;
    setState(() => _togglingAutomation = true);
    try {
      final updated = await widget.onAutomationChanged(active);
      if (mounted) setState(() => _state = updated);
    } finally {
      if (mounted) setState(() => _togglingAutomation = false);
    }
  }

  Future<void> _buy(NebulaShopItem item) async {
    if (_buyingId != null) return;
    setState(() => _buyingId = item.id);
    try {
      final updated = await widget.onPurchase(item);
      if (mounted) setState(() => _state = updated);
    } finally {
      if (mounted) setState(() => _buyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: const Text('Nebula Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('Nebula: ${_state.nebula}')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Permanent upgrades purchased with Nebula earned in Arcade.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (NebulaShopCatalog.botIds.any(
            (id) => (_state.nebulaItems[id] ?? 0) > 0,
          ))
            GtnExpressiveSwitchTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Clicker'),
              subtitle: Text(
                _state.legacySystems.timeTravelPenaltyUntil > DateTime.now().millisecondsSinceEpoch
                    ? 'Paused by clock rollback protection.'
                    : 'Let your owned bots guess automatically.',
              ),
              value: _state.legacySystems.autoClickerActive,
              onChanged: _togglingAutomation ||
                      _state.legacySystems.timeTravelPenaltyUntil > DateTime.now().millisecondsSinceEpoch
                  ? null
                  : _toggleAutomation,
            ),
          for (final item in NebulaShopCatalog.items)
            GtnExpressiveCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.name, style: theme.textTheme.titleMedium),
                        ),
                        Text('Owned: ${_state.nebulaItems[item.id] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.description),
                    const SizedBox(height: 6),
                    Text(
                      item.effect,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    M3EButton.filled(
                      onPressed: _buyingId != null ||
                              _state.nebula.compareTo(item.price) < 0 ||
                              (NebulaShopCatalog.automationIds.contains(item.id) &&
                                  (_state.nebulaItems[item.id] ?? 0) > 0) ||
                              (NebulaShopCatalog.botUpgradeIds.contains(item.id) &&
                                  !NebulaShopCatalog.botIds.any(
                                    (id) => (_state.nebulaItems[id] ?? 0) > 0,
                                  ))
                          ? null
                          : () => _buy(item),
                      child: Text(
                        NebulaShopCatalog.automationIds.contains(item.id) &&
                                (_state.nebulaItems[item.id] ?? 0) > 0
                            ? 'Purchased'
                            : 'Buy · ${item.price} Nebula',
                      ),
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
