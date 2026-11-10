import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../design/expressive_widgets.dart';

import '../core/progression/progression_state.dart';
import '../creative/creative_mode_page.dart';
import '../i18n/app_localizations.dart';
import '../worlds/world_boss_catalog.dart';
import 'legacy_systems_page.dart';

enum LegacySection {
  journey('Journey', Icons.route_rounded),
  rewards('Rewards', Icons.card_giftcard_rounded),
  statistics('Statistics', Icons.query_stats_rounded),
  codex('Codex', Icons.menu_book_rounded),
  about('About', Icons.info_outline_rounded);

  const LegacySection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class LegacyHubPage extends StatelessWidget {
  const LegacyHubPage({
    super.key,
    required this.progression,
    required this.activeSlot,
    required this.onSystemsChanged,
  });

  final ProgressionState progression;
  final int activeSlot;
  final LegacyProgressionChanged onSystemsChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your GTN journey', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Progress, lifetime rewards, records and the world codex.'),
          const SizedBox(height: 16),
          GtnExpressiveCard(
            child: ListTile(
              leading: const Icon(Icons.palette_rounded),
              title: const Text('Creative Mode'),
              subtitle: const Text('Build a separate sandbox with custom ranges and rules.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CreativeModePage(slot: activeSlot),
                ),
              ),
            ),
          ),
          GtnExpressiveCard(
            child: ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('All gameplay systems'),
              subtitle: const Text('Traits, talents, mutators, relics, sanctuary, stakes, rewards, loot, music and updates.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => LegacySystemsPage(
                    progression: progression,
                    onChanged: onSystemsChanged,
                  ),
                ),
              ),
            ),
          ),
          for (final section in LegacySection.values)
            GtnExpressiveCard(
              child: ListTile(
                leading: Icon(section.icon),
                title: Text(section.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _LegacyDetailPage(
                      section: section,
                      progression: progression,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegacyDetailPage extends StatelessWidget {
  const _LegacyDetailPage({
    required this.section,
    required this.progression,
  });

  final LegacySection section;
  final ProgressionState progression;

  @override
  Widget build(BuildContext context) {
    final content = switch (section) {
      LegacySection.journey => _journey(context),
      LegacySection.rewards => _rewards(context),
      LegacySection.statistics => _statistics(context),
      LegacySection.codex => _codex(context),
      LegacySection.about => _about(context),
    };
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: Text(section.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: content,
      ),
    );
  }

  List<Widget> _journey(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = <(String, int, int)>[
      ('First steps', progression.correctGuesses, 1),
      ('Getting consistent', progression.correctGuesses, 10),
      ('World explorer', progression.defeatedBosses.length, 1),
      ('Prestige beginner', progression.prestigeResets, 1),
      ('Beyond prestige', progression.ultraResets, 1),
      ('Master of the rift', progression.defeatedBosses.length, 4),
    ];
    return [
      Text('Keep moving forward', style: theme.textTheme.titleLarge),
      const SizedBox(height: 6),
      Text('${progression.correctGuesses} correct guesses · ${progression.defeatedBosses.length}/4 guardians defeated'),
      const SizedBox(height: 16),
      for (final milestone in milestones)
        GtnExpressiveCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(milestone.$1, style: theme.textTheme.titleMedium)),
                  Text('${milestone.$2.clamp(0, milestone.$3)} / ${milestone.$3}'),
                ]),
                const SizedBox(height: 8),
                M3EProgressIndicator.linearWavy(
                  value: (milestone.$2 / milestone.$3).clamp(0.0, 1.0),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _rewards(BuildContext context) => [
        Text('Lifetime earnings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _valueCard('Money earned', progression.moneyEarned.toString(), Icons.payments_rounded),
        _valueCard('Nebula earned', progression.nebulaEarned.toString(), Icons.diamond_rounded),
        _valueCard('Current Money', progression.money.toString(), Icons.account_balance_wallet_rounded),
        _valueCard('Current Prestige', progression.prestige.toString(), Icons.auto_awesome_rounded),
        _valueCard('Current Ultra', progression.ultra.toString(), Icons.bolt_rounded),
        _valueCard('Current Nebula', progression.nebula.toString(), Icons.diamond_outlined),
        const SizedBox(height: 8),
        const Text('Boss rewards are paid once when each guardian is defeated. Arcade rewards are granted when a minigame run is claimed.'),
      ];

  List<Widget> _statistics(BuildContext context) => [
        Text('Your records', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _valueCard('Total guesses', '${progression.totalGuesses}', Icons.bolt_rounded),
        _valueCard('Correct guesses', '${progression.correctGuesses}', Icons.check_circle_rounded),
        _valueCard('Current streak', '${progression.currentStreak}', Icons.local_fire_department_rounded),
        _valueCard('Best streak', '${progression.bestStreak}', Icons.military_tech_rounded),
        _valueCard('Prestige resets', '${progression.prestigeResets}', Icons.auto_awesome_rounded),
        _valueCard('Ultra resets', '${progression.ultraResets}', Icons.bolt_rounded),
        _valueCard('Upgrade levels', '${progression.upgrades.values.fold<int>(0, (sum, level) => sum + level)}', Icons.upgrade_rounded),
        _valueCard('Bosses defeated', '${progression.defeatedBosses.length} / 4', Icons.public_rounded),
      ];

  List<Widget> _codex(BuildContext context) => [
        Text('World codex', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('A field guide to the four known worlds and their guardians.'),
        const SizedBox(height: 12),
        for (final boss in WorldBossCatalog.worlds)
          GtnExpressiveCard(
            child: ListTile(
              leading: Icon(
                progression.defeatedBosses.contains(boss.id)
                    ? Icons.verified_rounded
                    : Icons.public_rounded,
              ),
              title: Text(AppLocalizations.text(boss.worldNameKey, boss.worldName)),
              subtitle: Text(
                '${AppLocalizations.text(boss.bossNameKey, boss.name)}\n'
                '${AppLocalizations.text(boss.worldRequirementKey)}',
              ),
              isThreeLine: true,
              trailing: Text(
                progression.defeatedBosses.contains(boss.id)
                    ? 'Cleared'
                    : 'Undiscovered',
              ),
            ),
          ),
      ];

  List<Widget> _about(BuildContext context) => [
        Text('Guess The Number 2', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'A Flutter-based continuation of Guess The Number. This build includes the core number-guessing loop, progression currencies, upgrades, Arcade minigames, world guardians and local save slots.',
        ),
        const SizedBox(height: 16),
        const Text('Built with Flutter and Dart. Game progress is stored locally on this device.'),
      ];

  Widget _valueCard(String label, String value, IconData icon) => GtnExpressiveCard(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}
