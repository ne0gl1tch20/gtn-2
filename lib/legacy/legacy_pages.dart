import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/progression/progression_state.dart';
import '../creative/creative_mode_page.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';
import '../worlds/world_boss_catalog.dart';
import 'legacy_systems_page.dart';

enum LegacySection {
  journey('Journey', Icons.route_rounded),
  rewards('Rewards', Icons.card_giftcard_rounded),
  statistics('Statistics', Icons.query_stats_rounded),
  codex('Codex', Icons.menu_book_rounded),
  changelog('Changelog', Icons.article_outlined),
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
          Text(
            'Your GTN journey',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Progress, lifetime rewards, records and the world codex.',
          ),
          const SizedBox(height: 16),
          GtnExpressiveCard(
            child: ListTile(
              leading: const Icon(Icons.palette_rounded),
              title: const Text('Creative Mode'),
              subtitle: const Text(
                'Build a separate sandbox with custom ranges and rules.',
              ),
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
              subtitle: const Text(
                'Traits, talents, mutators, relics, sanctuary, stakes, rewards, loot, music and updates.',
              ),
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
          for (final destination in const [
            (
              LegacySystemsView.music,
              'Music',
              Icons.library_music_rounded,
              'Offline player, library, playlists and playback controls.',
            ),
            (
              LegacySystemsView.luckyStake,
              'Lucky Stake',
              Icons.casino_rounded,
              'Place a stake and settle a validated 50/50 round.',
            ),
          ])
            GtnExpressiveCard(
              child: ListTile(
                leading: Icon(destination.$3),
                title: Text(destination.$2),
                subtitle: Text(destination.$4),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => LegacySystemsPage(
                      progression: progression,
                      onChanged: onSystemsChanged,
                      view: destination.$1,
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
  const _LegacyDetailPage({required this.section, required this.progression});

  final LegacySection section;
  final ProgressionState progression;

  @override
  Widget build(BuildContext context) {
    final content = switch (section) {
      LegacySection.journey => _journey(context),
      LegacySection.rewards => _rewards(context),
      LegacySection.statistics => _statistics(context),
      LegacySection.codex => _codex(context),
      LegacySection.changelog => _changelog(context),
      LegacySection.about => _about(context),
    };
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: Text(section.label)),
      body: ListView(padding: const EdgeInsets.all(16), children: content),
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
      Text(
        '${progression.correctGuesses} correct guesses · ${progression.defeatedBosses.length}/4 guardians defeated',
      ),
      const SizedBox(height: 16),
      for (final milestone in milestones)
        GtnExpressiveCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.$1,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${milestone.$2.clamp(0, milestone.$3)} / ${milestone.$3}',
                    ),
                  ],
                ),
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
    _valueCard(
      'Money earned',
      progression.moneyEarned.toString(),
      Icons.payments_rounded,
    ),
    _valueCard(
      'Nebula earned',
      progression.nebulaEarned.toString(),
      Icons.diamond_rounded,
    ),
    _valueCard(
      'Current Money',
      progression.money.toString(),
      Icons.account_balance_wallet_rounded,
    ),
    _valueCard(
      'Current Prestige',
      progression.prestige.toString(),
      Icons.auto_awesome_rounded,
    ),
    _valueCard(
      'Current Ultra',
      progression.ultra.toString(),
      Icons.bolt_rounded,
    ),
    _valueCard(
      'Current Nebula',
      progression.nebula.toString(),
      Icons.diamond_outlined,
    ),
    const SizedBox(height: 8),
    const Text(
      'Boss rewards are paid once when each guardian is defeated. Arcade rewards are granted when a minigame run is claimed.',
    ),
  ];

  List<Widget> _statistics(BuildContext context) => [
    Text('Your records', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 12),
    _valueCard(
      'Total guesses',
      '${progression.totalGuesses}',
      Icons.bolt_rounded,
    ),
    _valueCard(
      'Correct guesses',
      '${progression.correctGuesses}',
      Icons.check_circle_rounded,
    ),
    _valueCard(
      'Current streak',
      '${progression.currentStreak}',
      Icons.local_fire_department_rounded,
    ),
    _valueCard(
      'Best streak',
      '${progression.bestStreak}',
      Icons.military_tech_rounded,
    ),
    _valueCard(
      'Prestige resets',
      '${progression.prestigeResets}',
      Icons.auto_awesome_rounded,
    ),
    _valueCard(
      'Ultra resets',
      '${progression.ultraResets}',
      Icons.bolt_rounded,
    ),
    _valueCard(
      'Upgrade levels',
      '${progression.upgrades.values.fold<int>(0, (sum, level) => sum + level)}',
      Icons.upgrade_rounded,
    ),
    _valueCard(
      'Bosses defeated',
      '${progression.defeatedBosses.length} / 4',
      Icons.public_rounded,
    ),
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

  List<Widget> _changelog(BuildContext context) => [const _ChangelogContent()];

  List<Widget> _about(BuildContext context) => [
    Text(
      'Guess The Number 2',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 8),
    const Text(
      'A Flutter-based continuation of Guess The Number. Game progress is stored locally on this device.',
    ),
    const SizedBox(height: 16),
    GtnExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: Icon(Icons.link_rounded),
            title: Text('Socials & source code'),
            subtitle: Text('These links open in your external browser.'),
          ),
          for (final link in const [
            (
              'YouTube · @theg0ldne0_01',
              'https://www.youtube.com/@theg0ldne0_01',
            ),
            (
              'Instagram · theg0ldne0_01',
              'https://www.instagram.com/theg0ldne0_01/',
            ),
            (
              'NameMC · PearlSteve15',
              'https://namemc.com/profile/PearlSteve15',
            ),
            ('GitHub · Source code', 'https://github.com/ne0gl1tch20'),
            (
              'Official website',
              'https://ne0gl1tch20.github.io/GuessTheNumber',
            ),
          ])
            ListTile(
              dense: true,
              title: Text(link.$1),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => launchUrl(
                Uri.parse(link.$2),
                mode: LaunchMode.externalApplication,
              ),
            ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    GtnExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Open-source libraries'),
            subtitle: Text(
              'Credits and licenses listed in the original GTN1 About screen.',
            ),
          ),
          for (final item in const [
            (
              'Jetpack Compose',
              'Apache 2.0 · Google / Android Open Source Project',
            ),
            ('Material 3', 'Apache 2.0 · Google'),
            ('Kotlinx Serialization', 'Apache 2.0 · JetBrains'),
            ('Kotlinx Coroutines', 'Apache 2.0 · JetBrains'),
            ('DataStore Preferences', 'Apache 2.0 · Google'),
            ('Navigation Compose', 'Apache 2.0 · Google'),
            ('LuaJ', 'MIT · LuaJ project; James Roseborough and Ian Farmer'),
            ('Jarrlyy UI SDK', 'Project component · Jarrlyy'),
          ])
            ListTile(
              dense: true,
              title: Text(item.$1),
              subtitle: Text(item.$2),
            ),
        ],
      ),
    ),
  ];

  Widget _valueCard(String label, String value, IconData icon) =>
      GtnExpressiveCard(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
}

class _ChangelogContent extends StatelessWidget {
  const _ChangelogContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/changelogs.md'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: M3EProgressIndicator.circular(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return GtnExpressiveCard(
            child: const Text(
              'The bundled GTN1 changelog could not be loaded.',
            ),
          );
        }
        final rows = <Widget>[];
        for (final raw in snapshot.data!.split('\n')) {
          final line = raw.trim();
          if (line.isEmpty || line == '---') continue;
          if (line.startsWith('# ')) continue;
          if (line.startsWith('### ')) {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Text(
                  line.substring(4).replaceAll('**', ''),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: GtnUiTokens.cyan,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          } else if (line.startsWith('## ')) {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 5),
                child: Text(
                  line.substring(3).replaceAll('**', ''),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: GtnUiTokens.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          } else if (line.startsWith('- ')) {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 9),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: GtnUiTokens.cyan,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line
                            .substring(2)
                            .replaceAll('**', '')
                            .replaceAll('`', ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  line.replaceAll('**', '').replaceAll('`', ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ),
            );
          }
        }
        return GtnExpressiveCard(
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: GtnUiTokens.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROJECT HISTORY',
                style: TextStyle(
                  color: GtnUiTokens.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Changelog',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Release notes and development history from the original GTN1 source.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...rows,
            ],
          ),
        );
      },
    );
  }
}
