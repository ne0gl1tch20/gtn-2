import 'package:flutter/material.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/gtn1_systems_engine.dart';
import '../core/progression/gtn1_systems_state.dart';
import '../core/progression/progression_state.dart';
import '../traits/gtn1_trait_catalog.dart';

typedef Gtn1SystemAction = Future<ProgressionState> Function(String, Map<String, Object?>);
typedef Gtn1StakeAction = Future<StakeResult> Function(BigNumber);

class Gtn1SystemsHubPage extends StatefulWidget {
  const Gtn1SystemsHubPage({
    super.key, required this.progression, required this.onAction,
    required this.onStake, required this.onOpenMusic,
    required this.onOpenAbout, required this.onOpenChangelog,
  });
  final ProgressionState progression;
  final Gtn1SystemAction onAction;
  final Gtn1StakeAction onStake;
  final VoidCallback onOpenMusic, onOpenAbout, onOpenChangelog;

  @override
  State<Gtn1SystemsHubPage> createState() => _Gtn1SystemsHubPageState();
}

class _Gtn1SystemsHubPageState extends State<Gtn1SystemsHubPage> {
  late ProgressionState state = widget.progression;
  final stakeInput = TextEditingController();
  final engine = const Gtn1SystemsEngine();
  bool busy = false;
  String? stakeMessage;

  @override
  void didUpdateWidget(covariant Gtn1SystemsHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progression != widget.progression) state = widget.progression;
  }

  @override
  void dispose() { stakeInput.dispose(); super.dispose(); }

  Future<void> act(String action, [Map<String, Object?> args = const {}]) async {
    if (busy) return;
    setState(() => busy = true);
    try { final next = await widget.onAction(action, args); if (mounted) setState(() => state = next); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> flipStake() async {
    final amount = int.tryParse(stakeInput.text.trim());
    if (amount == null || amount <= 0) { setState(() => stakeMessage = 'Enter a positive whole-number stake.'); return; }
    if (state.money.compareTo(BigNumber.fromInt(amount)) < 0) { setState(() => stakeMessage = 'Not enough Money.'); return; }
    setState(() => busy = true);
    try {
      final result = await widget.onStake(BigNumber.fromInt(amount));
      if (!mounted) return;
      setState(() {
        state = result.state;
        stakeMessage = result.won ? '🎉 Won! Payout: ${result.payout}' : '💥 Lost! ${result.stake} Money forfeited.';
        stakeInput.clear();
      });
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final s = state.systems;
    final activeTraits = engine.activeTraits(state);
    final relics = Gtn1SystemsEngine.relicCatalog;
    final talents = Gtn1SystemsEngine.talentCatalog;
    final multiplier = Gtn1SystemsEngine.mutatorRewardMultiplier(s.activeMutators);
    return Scaffold(
      appBar: AppBar(title: const Text('GTN 1 Systems'), actions: [
        IconButton(onPressed: widget.onOpenMusic, icon: const Icon(Icons.music_note)),
        IconButton(onPressed: widget.onOpenAbout, icon: const Icon(Icons.info_outline)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        summary('Beyond the Number', 'Your saved systems and progression.', [
          ('Traits', '${s.discoveredTraits.length}/${gtn1TraitCatalog.length}'),
          ('Talents', '${s.unlockedTalents.length}/${talents.length}'),
          ('Relics', '${s.relicInventory.length}/4'),
          ('Sanctuary', 'Lv. ${s.homeBaseLevel}/20'),
        ]),
        heading('Traits', '320 built-in definitions with dependencies, conflicts, seasonal rules and hidden discoveries.'),
        summary('Trait Registry', '${activeTraits.length} active · ${s.discoveredTraits.length} discovered.', [
          ('Progression', '${gtn1TraitCatalog.where((t) => t.category == 'progression').length}'),
          ('Gameplay', '${gtn1TraitCatalog.where((t) => t.category == 'gameplay').length}'),
          ('Collection', '${gtn1TraitCatalog.where((t) => t.category == 'collection').length}'),
          ('Seasonal', '${gtn1TraitCatalog.where((t) => t.category == 'seasonal').length}'),
        ]),
        for (final trait in activeTraits.take(24))
          Card(child: ListTile(
            leading: Icon(trait.hidden ? Icons.visibility_off : Icons.auto_awesome),
            title: Text(pretty(trait.id)),
            subtitle: Text('${trait.category} · ${trait.effect.replaceAll('_', ' ')}'),
            trailing: armPicker(trait.id, s),
          )),
        heading('Prestige Talent Web', 'Six parent-gated permanent talents.'),
        for (final talent in talents)
          Card(child: ListTile(
            leading: Icon(s.unlockedTalents.contains(talent.id) ? Icons.check_circle : Icons.account_tree),
            title: Text(talent.name),
            subtitle: Text('${talent.description}${talent.parentId == null ? '' : '\nRequires ${pretty(talent.parentId!)}'}'),
            isThreeLine: talent.parentId != null,
            trailing: s.unlockedTalents.contains(talent.id)
              ? const Chip(label: Text('Owned'))
              : FilledButton.tonal(
                  onPressed: busy ? null : () => act('buy_talent', {'id': talent.id}),
                  child: Text('${talent.cost} P'),
                ),
          )),
        heading('Mutators & Challenges', 'Mutators affect the actual guessing engine and rewards.'),
        summary('Active reward multiplier', '×${multiplier}', [
          ('Range', s.activeMutators.contains('mut_hardcore') ? '1–200' : '1–100'),
          ('Automation', s.activeMutators.contains('mut_speed') ? '3×' : 'Normal'),
          ('Blindfold', s.activeMutators.contains('mut_blind') ? 'On' : 'Off'),
          ('Tax', s.activeMutators.contains('mut_tax') ? '5% miss tax' : 'Off'),
        ]),
        for (final item in const [
          ('mut_hardcore', 'Hardcore Range', 'Doubles range and rewards ×2.'),
          ('mut_speed', 'Hyper Speed', 'Automation speed ×3 and rewards ×3.'),
          ('mut_blind', 'Blindfolded Oracle', 'Hides high/low feedback and rewards ×5.'),
          ('mut_tax', 'Heavy Taxation', 'Wrong guesses cost 5% of current Money. Rewards ×10.'),
        ])
          SwitchListTile(
            value: s.activeMutators.contains(item.$1),
            onChanged: busy ? null : (v) => act('set_mutator', {'id': item.$1, 'active': v}),
            title: Text(item.$2), subtitle: Text(item.$3),
          ),
        heading('Relic Collection', 'Boss relics. Equip up to four for set bonuses.'),
        Text('${s.equippedRelics.length}/4 equipped · 2 relics +10%, 3 +20%, 4 +35% Money and +1 Nebula per correct guess.'),
        for (final relic in relics)
          Card(child: ListTile(
            leading: Icon(s.relicInventory.contains(relic.id) ? Icons.diamond : Icons.lock_outline),
            title: Text(relic.name), subtitle: Text('${relic.rarity} · ${relic.description}'),
            trailing: s.relicInventory.contains(relic.id)
              ? OutlinedButton(
                  onPressed: busy ? null : () => act('equip_relic', {'id': relic.id}),
                  child: Text(s.equippedRelics.contains(relic.id) ? 'Unequip' : 'Equip'),
                )
              : const Text('Boss locked'),
          )),
        heading('Home Base', 'Each level adds 2% Money to correct-guess rewards, capped at 40%.'),
        summary('Cosmic Sanctuary · Level ${s.homeBaseLevel}/20', 'Next restoration: ${50000 * (s.homeBaseLevel + 1)} Money', [
          ('Portal', s.homeBaseLevel >= 1 ? 'Restored' : 'Locked'),
          ('Forge', s.homeBaseLevel >= 3 ? 'Restored' : 'Locked'),
          ('Archive', s.homeBaseLevel >= 5 ? 'Restored' : 'Locked'),
          ('Observatory', s.homeBaseLevel >= 10 ? 'Restored' : 'Locked'),
        ], action: s.homeBaseLevel < 20 ? FilledButton.tonal(
          onPressed: busy ? null : () => act('upgrade_home_base'),
          child: const Text('Restore next level'),
        ) : null),
        heading('Lucky Stake', '50/50 coin flip. Wins pay the stake back plus a streak-based multiplier.'),
        summary('Money: ${state.money}', 'Win multiplier: ${(2 + state.currentStreak * 0.1).toStringAsFixed(1)}×', [
          ('Wins', '${s.stakeWins}'), ('Losses', '${s.stakeLosses}'),
          ('Wagered', '${s.stakeMoneyWagered ?? BigNumber.fromInt(0)}'),
          ('Won', '${s.stakeMoneyWon ?? BigNumber.fromInt(0)}'),
        ]),
        TextField(controller: stakeInput, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stake amount', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: busy ? null : flipStake, icon: const Icon(Icons.casino), label: const Text('Stake & Flip (50/50)')),
        if (stakeMessage != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(stakeMessage!)),
        heading('Daily Rewards & Quests', 'Offline-friendly daily claims.'),
        summary('Daily reward streak: ${s.dailyRewardStreak}/7', 'Last claim: ${s.lastDailyRewardDate.isEmpty ? 'Never' : s.lastDailyRewardDate}', [
          ('Guesses', '${s.dailyQuestGuesses}/10'),
          ('Correct', '${s.dailyQuestCorrectGuesses}/5'),
          ('Best streak', '${s.dailyQuestBestStreak}/5'),
          ('Upgrades', '${s.dailyQuestUpgradePurchases}/3'),
        ], action: FilledButton.tonal(onPressed: busy ? null : () => act('claim_daily_reward'), child: const Text('Claim daily reward'))),
        for (final quest in Gtn1SystemsEngine.dailyQuests)
          Card(child: ListTile(
            title: Text(quest.title),
            subtitle: Text('Reward: ${quest.rewardMoney > 0 ? '${quest.rewardMoney} Money' : '${quest.rewardNebula} Nebula'}'),
            trailing: FilledButton.tonal(
              onPressed: busy || s.claimedDailyQuests.contains(quest.id) ? null : () => act('claim_daily_quest', {'id': quest.id}),
              child: Text(s.claimedDailyQuests.contains(quest.id) ? 'Claimed' : 'Claim'),
            ),
          )),
        heading('Treasure Drops', 'Correct guesses can drop Common, Rare or Epic chests.'),
        summary('${s.lootDropsFound} found · ${s.lootChestsOpened} opened', 'Drop chance per correct guess: Common 18%, Rare 5%, Epic 1%.', [
          ('Common', '${s.lootCommonChests}'), ('Rare', '${s.lootRareChests}'),
          ('Epic', '${s.lootEpicChests}'), ('Latest', s.lastLootDropTier ?? 'None'),
        ]),
        for (final tier in const ['common', 'rare', 'epic'])
          Card(child: ListTile(
            title: Text('${pretty(tier)} Chest'),
            trailing: FilledButton.tonal(
              onPressed: busy || chestCount(tier, s) == 0 ? null : () => act('open_loot_chest', {'tier': tier}),
              child: Text('Open (${chestCount(tier, s)})'),
            ),
          )),
        heading('Achievements & Records', 'Permanent milestones with one-time Nebula rewards.'),
        summary('${s.achievements.length} achievements unlocked', '${state.totalGuesses} guesses · ${state.correctGuesses} correct · best streak ${state.bestStreak}', [
          ('Money earned', '${state.moneyEarned}'), ('Nebula earned', '${state.nebulaEarned}'),
          ('Prestige', '${state.prestigeResets}'), ('Ultra', '${state.ultraResets}'),
        ]),
        heading('World Mastery, Codex & Endgame', 'Secrets, mastery and late-game goals.'),
        summary('World: ${pretty(s.activeWorldId)}', '${s.discoveredSecrets.length}/4 secrets · ${s.codexEntries.length} Codex entries', [
          ('Mastery', '${s.worldMasteryLevels[s.activeWorldId] ?? 0}/10'),
          ('Rift', 'Tier ${s.endlessRiftTier}'), ('Best Rift', 'Tier ${s.endlessRiftBestTier}'),
          ('Endgame claims', '${s.endgameRewardsClaimed.length}/6'),
        ]),
        heading('Other GTN 1 features', 'Music, changelog, About and updater.'),
        Card(child: ListTile(leading: const Icon(Icons.music_note), title: const Text('Background Music'),
          subtitle: const Text('Offline library, queue, playlists, shuffle and repeat.'),
          onTap: widget.onOpenMusic, trailing: const Icon(Icons.chevron_right))),
        Card(child: ListTile(leading: const Icon(Icons.history), title: const Text('Changelog'),
          subtitle: const Text('Release history and feature notes.'),
          onTap: widget.onOpenChangelog, trailing: const Icon(Icons.chevron_right))),
        Card(child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('About & Updates'),
          subtitle: const Text('Version, update checks, download verification and licenses.'),
          onTap: widget.onOpenAbout, trailing: const Icon(Icons.chevron_right))),
      ]),
    );
  }

  Widget? armPicker(String id, Gtn1SystemsState systems) {
    final arms = switch (id) {
      'combo_momentum' => const {'steady': 'Steady', 'burst': 'Burst'},
      'mistake_insurance' => const {'half_refund': 'Half refund', 'careful': 'Careful'},
      'risk_reward' => const {'balanced': 'Balanced', 'high_risk': 'High risk'},
      _ => const <String, String>{},
    };
    if (arms.isEmpty) return null;
    final selected = systems.selectedTraitArms[id] ?? arms.keys.first;
    return PopupMenuButton<String>(
      tooltip: 'Select trait arm',
      onSelected: (value) => act('select_trait_arm', {'traitId': id, 'armId': value}),
      itemBuilder: (_) => arms.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))).toList(),
      child: Chip(label: Text(arms[selected] ?? 'Choose arm')),
    );
  }

  int chestCount(String tier, Gtn1SystemsState s) => switch (tier) {
    'common' => s.lootCommonChests, 'rare' => s.lootRareChests, 'epic' => s.lootEpicChests, _ => 0,
  };

  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );

  Widget summary(String title, String subtitle, List<(String, String)> values, {Widget? action}) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: values.map((v) => Chip(label: Text('${v.$1}: ${v.$2}'))).toList()),
      if (action != null) ...[const SizedBox(height: 8), action],
    ])),
  );

  String pretty(String value) => value.split(RegExp(r'[_-]')).where((x) => x.isNotEmpty)
      .map((x) => x[0].toUpperCase() + x.substring(1)).join(' ');
}
