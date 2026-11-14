import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/progression/achievement_catalog.dart';
import '../core/progression/progression_state.dart';
import '../creative/creative_mode_page.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';
import '../worlds/world_boss_catalog.dart';
import 'legacy_systems_page.dart';

enum LegacySection {
  journey('Achievements & Perks', Icons.emoji_events_rounded),
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
    this.onOpenProfile,
    this.onOpenSaveSlots,
    this.onOpenSettings,
    this.onOpenDeveloperSettings,
    this.onOpenShop,
    this.onOpenProgression,
  });

  final ProgressionState progression;
  final int activeSlot;
  final LegacyProgressionChanged onSystemsChanged;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSaveSlots;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenDeveloperSettings;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenProgression;

  void _openSystems(
    BuildContext context, {
    LegacySystemsView view = LegacySystemsView.all,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegacySystemsPage(
          progression: progression,
          onChanged: onSystemsChanged,
          view: view,
        ),
      ),
    );
  }

  void _openSection(BuildContext context, LegacySection section) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            LegacyDetailPage(section: section, progression: progression),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _MoreDestination(
        title: 'Rewards',
        description: 'Achievements and daily rewards',
        icon: Icons.emoji_events_rounded,
        accent: GtnUiTokens.gold,
        onTap: () => _openSection(context, LegacySection.rewards),
      ),
      _MoreDestination(
        title: 'Journey',
        description: 'Your run history and progress',
        icon: Icons.schedule_rounded,
        accent: GtnUiTokens.cyan,
        onTap: () => _openSection(context, LegacySection.journey),
      ),
      if (onOpenShop != null)
        _MoreDestination(
          title: 'Shop',
          description: 'Browse available items',
          icon: Icons.shopping_bag_rounded,
          accent: GtnUiTokens.purple,
          onTap: onOpenShop!,
        ),
      _MoreDestination(
        title: 'Home Base',
        description: 'Build up your base',
        icon: Icons.home_rounded,
        accent: GtnUiTokens.green,
        onTap: () => _openSystems(context, view: LegacySystemsView.homeBase),
      ),
      _MoreDestination(
        title: 'Relics',
        description: 'Manage your relic collection',
        icon: Icons.auto_awesome_rounded,
        accent: GtnUiTokens.purple,
        onTap: () => _openSystems(context, view: LegacySystemsView.relics),
      ),
      _MoreDestination(
        title: 'Codex',
        description: 'Explore discoveries',
        icon: Icons.menu_book_rounded,
        accent: GtnUiTokens.cyan,
        onTap: () => _openSection(context, LegacySection.codex),
      ),
      _MoreDestination(
        title: 'Changelog',
        description: 'See what changed in recent updates',
        icon: Icons.article_outlined,
        accent: GtnUiTokens.cyan,
        onTap: () => _openSection(context, LegacySection.changelog),
      ),
      _MoreDestination(
        title: 'About',
        description: 'About & Licenses',
        icon: Icons.info_outline_rounded,
        accent: GtnUiTokens.muted,
        onTap: () => _openSection(context, LegacySection.about),
      ),
      if (onOpenSaveSlots != null)
        _MoreDestination(
          title: 'Save Slots',
          description: 'Switch or manage saved games',
          icon: Icons.save_outlined,
          accent: GtnUiTokens.gold,
          onTap: onOpenSaveSlots!,
        ),
      _MoreDestination(
        title: 'Background Music',
        description: 'Control your background music',
        icon: Icons.library_music_rounded,
        accent: GtnUiTokens.purple,
        onTap: () => _openSystems(context, view: LegacySystemsView.music),
      ),
      if (onOpenSettings != null)
        _MoreDestination(
          title: 'Settings',
          description: 'Customize your experience',
          icon: Icons.settings_rounded,
          accent: GtnUiTokens.cyan,
          onTap: onOpenSettings!,
        ),
      if (onOpenProgression != null) ...[
        _MoreDestination(
          title: 'Prestige',
          description: 'Prestige upgrades and resets',
          icon: Icons.workspace_premium_rounded,
          accent: GtnUiTokens.gold,
          onTap: onOpenProgression!,
        ),
        _MoreDestination(
          title: 'Ultra',
          description: 'Ultra progression',
          icon: Icons.auto_awesome_rounded,
          accent: GtnUiTokens.purple,
          onTap: onOpenProgression!,
        ),
      ],
      _MoreDestination(
        title: 'Talents',
        description: 'Build your talent path',
        icon: Icons.layers_rounded,
        accent: GtnUiTokens.purple,
        onTap: () => _openSystems(context, view: LegacySystemsView.talents),
      ),
      _MoreDestination(
        title: 'Traits',
        description: 'Gameplay modules and selectable variants',
        icon: Icons.layers_rounded,
        accent: GtnUiTokens.cyan,
        onTap: () => _openSystems(context, view: LegacySystemsView.traits),
      ),
      _MoreDestination(
        title: 'Mutators',
        description: 'Customize challenge rules',
        icon: Icons.explore_rounded,
        accent: GtnUiTokens.gold,
        onTap: () => _openSystems(context, view: LegacySystemsView.mutators),
      ),
      _MoreDestination(
        title: 'Stats',
        description: 'Review your game statistics',
        icon: Icons.query_stats_rounded,
        accent: GtnUiTokens.cyan,
        onTap: () => _openSection(context, LegacySection.statistics),
      ),
      if (onOpenDeveloperSettings != null)
        _MoreDestination(
          title: 'Dev Settings',
          description: 'Developer console and diagnostics',
          icon: Icons.build_rounded,
          accent: GtnUiTokens.muted,
          onTap: onOpenDeveloperSettings!,
        ),
      _MoreDestination(
        title: 'Lucky Stake',
        description: 'Try your luck with a stake',
        icon: Icons.star_rounded,
        accent: GtnUiTokens.gold,
        onTap: () => _openSystems(context, view: LegacySystemsView.luckyStake),
      ),
    ];

    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
        children: [
          if (onOpenProfile != null) ...[
            _MoreDestinationCard(
              destination: _MoreDestination(
                title: 'Player profile',
                description:
                    'View your username and bio, then edit your profile.',
                icon: Icons.account_circle_rounded,
                accent: GtnUiTokens.cyan,
                onTap: onOpenProfile!,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _MoreDestinationGrid(destinations: destinations),
        ],
      ),
    );
  }
}

class _MoreDestination {
  const _MoreDestination({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}

class _MoreSectionHeading extends StatelessWidget {
  const _MoreSectionHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreDestinationGrid extends StatelessWidget {
  const _MoreDestinationGrid({required this.destinations});

  final List<_MoreDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 1;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final destination in destinations)
              SizedBox(
                width: width,
                child: _MoreDestinationCard(destination: destination),
              ),
          ],
        );
      },
    );
  }
}

class _MoreDestinationCard extends StatelessWidget {
  const _MoreDestinationCard({required this.destination});

  final _MoreDestination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(
        color: destination.accent.withValues(alpha: dark ? .28 : .20),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: destination.onTap,
        borderRadius: BorderRadius.circular(22),
        child: GtnExpressiveCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(14),
          shape: shape,
          color: dark ? GtnUiTokens.raisedPanel : const Color(0xFFF0F1FA),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: destination.accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  destination.icon,
                  color: destination.accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dark
                            ? GtnUiTokens.muted
                            : const Color(0xFF65708C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegacyDetailPage extends StatelessWidget {
  const LegacyDetailPage({
    super.key,
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
      LegacySection.changelog => _changelog(context),
      LegacySection.about => _about(context),
    };
    final description = switch (section) {
      LegacySection.journey =>
        'Track achievements, milestones and the rewards earned along the way.',
      LegacySection.rewards =>
        'Review lifetime earnings and the currencies in your current run.',
      LegacySection.statistics =>
        'Inspect your records, streaks and long-term progression.',
      LegacySection.codex =>
        'A field guide to the known worlds, guardians and discoveries.',
      LegacySection.changelog =>
        'See what changed across Guess The Number updates.',
      LegacySection.about =>
        'Game information, source links and open-source acknowledgements.',
    };
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: Text(section.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
        children: [
          GtnPageHeader(
            eyebrow: 'More · GTN reference',
            title: section.label,
            description: description,
            icon: section.icon,
            accent: GtnUiTokens.purple,
          ),
          const SizedBox(height: 8),
          ...content,
        ],
      ),
    );
  }

  List<Widget> _journey(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = AchievementCatalog.all
        .where((item) => progression.achievements.contains(item.id))
        .length;
    return [
      Text('Achievement Progress', style: theme.textTheme.titleLarge),
      const SizedBox(height: 6),
      Text('Unlocked: $unlockedCount / ${AchievementCatalog.all.length}'),
      const SizedBox(height: 8),
      M3EProgressIndicator.linearWavy(
        value: unlockedCount / AchievementCatalog.all.length,
      ),
      const SizedBox(height: 16),
      for (final achievement in AchievementCatalog.all)
        Builder(
          builder: (context) {
            final unlocked = progression.achievements.contains(achievement.id);
            final target = AchievementCatalog.target(achievement.id);
            final current = AchievementCatalog.progress(
              progression,
              achievement.id,
            );
            final isCounterMilestone = target > 0;
            return GtnExpressiveCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          unlocked
                              ? Icons.check_circle_rounded
                              : Icons.lock_rounded,
                          color: unlocked
                              ? const Color(0xFFFFD166)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                achievement.description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          achievement.tier.toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unlocked
                                ? 'Unlocked'
                                : AchievementCatalog.progressLabel(
                                    progression,
                                    achievement,
                                  ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '+${achievement.rewardNebula} Nebula',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    if (!unlocked && isCounterMilestone) ...[
                      const SizedBox(height: 8),
                      M3EProgressIndicator.linearWavy(
                        value: (current / target).clamp(0.0, 1.0),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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

  List<Widget> _statistics(BuildContext context) {
    final theme = Theme.of(context);
    final total = progression.totalGuesses;
    final correct = progression.correctGuesses;
    final failed = total - correct;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final hours = progression.playtimeSeconds ~/ 3600;
    final minutes = (progression.playtimeSeconds % 3600) ~/ 60;
    final seconds = progression.playtimeSeconds % 60;
    final playtime = hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : minutes > 0
        ? '${minutes}m ${seconds}s'
        : '${seconds}s';
    final totalUpgradeLevels = progression.upgrades.values.fold<int>(
      0,
      (sum, level) => sum + level,
    );

    return [
      GtnExpressiveCard(
        color: theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Guessing Precision',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.analytics_rounded, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(accuracy * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: accuracy,
                minHeight: 9,
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: .45,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('Correct: $correct'),
                Text('Failed: $failed'),
                Text('Total: $total'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Performance & Economy',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      _valueCard(
        'Money earned',
        progression.moneyEarned.toString(),
        Icons.trending_up_rounded,
      ),
      _valueCard(
        'Money spent',
        progression.moneySpent.toString(),
        Icons.shopping_cart_rounded,
      ),
      _valueCard('Play time', playtime, Icons.timer_rounded),
      const SizedBox(height: 8),
      Text(
        'Progression Records',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
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
        '$totalUpgradeLevels',
        Icons.upgrade_rounded,
      ),
      _valueCard(
        'Bosses defeated',
        '${progression.defeatedBosses.length} / ${WorldBossCatalog.worlds.length}',
        Icons.public_rounded,
      ),
      _valueCard(
        'Random events',
        '${progression.randomEventsTriggered}',
        Icons.casino_rounded,
      ),
    ];
  }

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
            ('GitHub · Source code', 'https://github.com/ne0gl1tch20/gtn-2'),
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
