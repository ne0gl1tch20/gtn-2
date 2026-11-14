import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/game/game_engine.dart';
import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';
import '../legacy/legacy_pages.dart';
import '../legacy/legacy_systems_page.dart';
import '../profile/player_profile_page.dart';
import '../settings/game_settings.dart';
import '../settings/menu_studio_layout.dart';

const _purple = GtnUiTokens.purple;
const _cyan = GtnUiTokens.cyan;
const _gold = GtnUiTokens.gold;
const _green = GtnUiTokens.green;
const _bg = GtnUiTokens.background;
const _panel = GtnUiTokens.panel;
const _raised = GtnUiTokens.raisedPanel;
const _line = GtnUiTokens.line;
const _white = GtnUiTokens.foreground;
const _muted = GtnUiTokens.muted;

class GameDashboardPage extends StatelessWidget {
  const GameDashboardPage({
    super.key,
    required this.game,
    required this.progression,
    required this.settings,
    this.settingsListenable,
    required this.activeSlot,
    required this.loading,
    required this.message,
    required this.controller,
    required this.onGuess,
    required this.onNewGame,
    required this.onUpgradeShop,
    required this.onPrestige,
    required this.onArcade,
    required this.onNebulaShop,
    required this.onWorldMap,
    required this.onLiveOps,
    required this.onLegacyPages,
    required this.onSaveSlots,
    required this.onSettings,
    required this.onDeveloperSettings,
    required this.onMusic,
    required this.onLuckyStake,
    required this.onSystems,
    this.showDeveloperSettings = false,
    this.randomEventMessage,
    this.incomePerSecond,
    required this.shellNavigatorKey,
    required this.selectedIndex,
    required this.onPrimarySelected,
    required this.onSystemsView,
    required this.onLegacySection,
    this.playerProfile = const PlayerProfile(),
    this.onPlayerProfile,
  });

  final GameState game;
  final ProgressionState progression;
  final GameSettings settings;
  final ValueListenable<GameSettings>? settingsListenable;
  final int activeSlot;
  final bool loading;
  final String message;
  final TextEditingController controller;
  final VoidCallback onGuess;
  final VoidCallback onNewGame;
  final VoidCallback onUpgradeShop;
  final VoidCallback onPrestige;
  final VoidCallback onArcade;
  final VoidCallback onNebulaShop;
  final VoidCallback onWorldMap;
  final VoidCallback onLiveOps;
  final VoidCallback onLegacyPages;
  final VoidCallback onSaveSlots;
  final VoidCallback onSettings;
  final VoidCallback onDeveloperSettings;
  final VoidCallback onMusic;
  final VoidCallback onLuckyStake;
  final VoidCallback onSystems;
  final bool showDeveloperSettings;
  final String? randomEventMessage;
  final BigNumber? incomePerSecond;
  final GlobalKey<NavigatorState> shellNavigatorKey;
  final int selectedIndex;
  final ValueChanged<int> onPrimarySelected;
  final ValueChanged<LegacySystemsView> onSystemsView;
  final ValueChanged<LegacySection> onLegacySection;
  final PlayerProfile playerProfile;
  final VoidCallback? onPlayerProfile;

  void _openMoreMenu(BuildContext context, Color panel, int playIndex) {
    shellNavigatorKey.currentState!
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => _MoreMenuPage(
              settings: settings,
              settingsListenable: settingsListenable ?? ValueNotifier(settings),
              showDeveloperSettings: showDeveloperSettings,
              onSaveSlots: onSaveSlots,
              playerProfile: playerProfile,
              onPlayerProfile: onPlayerProfile ?? () {},
              onDestination: _openMenuDestination,
            ),
          ),
        )
        .then((_) => onPrimarySelected(playIndex));
  }

  void _openMenuDestination(String id) {
    switch (id) {
      case 'worlds':
        onWorldMap();
        return;
      case 'arcade':
        onArcade();
        return;
      case 'upgrades':
        onUpgradeShop();
        return;
      case 'rewards':
        onLegacySection(LegacySection.rewards);
        return;
      case 'journey':
        onLegacySection(LegacySection.journey);
        return;
      case 'shop':
        onNebulaShop();
        return;
      case 'homebase':
        onSystemsView(LegacySystemsView.homeBase);
        return;
      case 'relics':
        onSystemsView(LegacySystemsView.relics);
        return;
      case 'codex':
        onLegacySection(LegacySection.codex);
        return;
      case 'changelog':
        onLegacySection(LegacySection.changelog);
        return;
      case 'about':
        onLegacySection(LegacySection.about);
        return;
      case 'music':
        onMusic();
        return;
      case 'settings':
        onSettings();
        return;
      case 'prestige':
      case 'ultra':
        onPrestige();
        return;
      case 'talent':
        onSystemsView(LegacySystemsView.talents);
        return;
      case 'traits':
        onSystemsView(LegacySystemsView.traits);
        return;
      case 'mutators':
        onSystemsView(LegacySystemsView.mutators);
        return;
      case 'stats':
        onLegacySection(LegacySection.statistics);
        return;
      case 'dev_settings':
        onDeveloperSettings();
        return;
      case 'stake':
        onLuckyStake();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width <= 430;
    final horizontalPadding = compact ? 12.0 : 24.0;
    final foreground = dark ? _white : const Color(0xFF172039);
    final muted = dark ? _muted : const Color(0xFF65708C);
    final panel = dark ? _panel : Colors.white;
    final raised = dark ? _raised : const Color(0xFFF0F1FA);
    final line = dark ? _line : const Color(0x180D1530);
    final menuLayout = MenuStudioLayout.fromSettings(settings);
    final navigationIds = menuLayout.primaryNavigationIds
        .where((id) => id != 'dev_settings' || showDeveloperSettings)
        .toList();
    final playIndex = navigationIds.indexOf('play');

    return Scaffold(
      backgroundColor: dark ? _bg : const Color(0xFFF5F6FC),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          IconData iconFor(String id) => switch (id) {
            'worlds' => Icons.public_rounded,
            'arcade' => Icons.sports_esports_rounded,
            'play' => Icons.play_arrow_rounded,
            'upgrades' => Icons.upgrade_rounded,
            'more' => Icons.menu_rounded,
            'rewards' => Icons.card_giftcard_rounded,
            'journey' => Icons.timeline_rounded,
            'shop' => Icons.storefront_rounded,
            'homebase' => Icons.home_work_rounded,
            'relics' => Icons.auto_awesome_rounded,
            'codex' => Icons.menu_book_rounded,
            'changelog' => Icons.history_rounded,
            'about' => Icons.info_outline_rounded,
            'music' => Icons.library_music_rounded,
            'settings' => Icons.settings_rounded,
            'prestige' => Icons.auto_awesome_rounded,
            'ultra' => Icons.bolt_rounded,
            'talent' => Icons.psychology_alt_rounded,
            'traits' => Icons.auto_awesome_rounded,
            'mutators' => Icons.tune_rounded,
            'stats' => Icons.query_stats_rounded,
            'dev_settings' => Icons.build_rounded,
            'stake' => Icons.casino_rounded,
            _ => Icons.circle_outlined,
          };

          Color colorFor(String id) {
            final hex = menuLayout.colors[id];
            if (hex == null) return _purple;
            final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
            return value == null ? _purple : Color(0xFF000000 | value);
          }

          String labelFor(String id) => switch (id) {
            'worlds' => AppLocalizations.text(
              'nav_worlds',
              'Beyond the Numbers',
            ),
            'arcade' => AppLocalizations.text('nav_arcade', 'Arcade'),
            'play' => AppLocalizations.text('nav_play', 'Play'),
            'upgrades' => AppLocalizations.text('nav_upgrades', 'Upgrades'),
            'more' => AppLocalizations.text('nav_more', 'More'),
            'rewards' => 'Rewards',
            'journey' => 'Journey',
            'shop' => 'Shop',
            'homebase' => 'Home Base',
            'relics' => 'Relics',
            'codex' => 'Codex',
            'changelog' => 'Changelog',
            'about' => 'About',
            'music' => 'Music',
            'settings' => 'Settings',
            'prestige' => 'Prestige',
            'ultra' => 'Ultra',
            'talent' => 'Talents',
            'traits' => 'Traits',
            'mutators' => 'Mutators',
            'stats' => 'Stats',
            'dev_settings' => 'Dev Settings',
            'stake' => 'Lucky Stake',
            _ => id,
          };

          void selectDestination(int index) {
            if (index < 0 || index >= navigationIds.length) return;
            final id = navigationIds[index];
            shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            onPrimarySelected(index);
            if (id == 'more') {
              _openMoreMenu(context, panel, playIndex);
            } else if (id != 'play') {
              _openMenuDestination(id);
            }
          }

          final selected = selectedIndex
              .clamp(0, navigationIds.length - 1)
              .toInt();
          final wide = constraints.maxWidth > 600;
          final minimumItemWidth = wide ? 124.0 : 76.0;
          final minimumBarWidth = navigationIds.length * minimumItemWidth;
          final barWidth = constraints.maxWidth > minimumBarWidth
              ? constraints.maxWidth
              : minimumBarWidth;

          if (wide) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: barWidth,
                child: NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: selectDestination,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  height: 76,
                  backgroundColor: panel,
                  indicatorColor: colorFor(navigationIds[selected])
                      .withValues(alpha: .18),
                  destinations: [
                    for (final id in navigationIds)
                      NavigationDestination(
                        icon: Icon(iconFor(id), color: colorFor(id)),
                        label: labelFor(id),
                      ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: barWidth,
              child: M3ENavigationBar(
                destinations: [
                  for (final id in navigationIds)
                    M3ENavigationBarDestination(
                      icon: Icon(iconFor(id), color: colorFor(id)),
                      label: labelFor(id),
                    ),
                ],
                selectedIndex: selected,
                onDestinationSelected: selectDestination,
              ),
            ),
          );
        },
      ),
      body: Navigator(
        key: shellNavigatorKey,
        onGenerateRoute: (routeSettings) => MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: dark
                        ? const [Color(0xFF182142), _bg, _bg]
                        : const [Color(0xFFEAE8FF), Color(0xFFF5F6FC)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          28,
                        ),
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final fullWidth = constraints.maxWidth;
                              return Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  SizedBox(
                                    width: fullWidth,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                _purple,
                                                Color(0xFF6651D9),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _purple.withValues(
                                                  alpha: .25,
                                                ),
                                                blurRadius: 18,
                                                offset: const Offset(0, 7),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.asset(
                                              'assets/gtn1/gtn-app-logo.png',
                                              width: 42,
                                              height: 42,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Guess The Number',
                                                style: TextStyle(
                                                  color: foreground,
                                                  fontFamily: 'SpaceGrotesk',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: foreground.withValues(
                                              alpha: .06,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            border: Border.all(
                                              color: foreground.withValues(
                                                alpha: .08,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.cloud_off_rounded,
                                                color: _green,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'OFFLINE',
                                                style: TextStyle(
                                                  color: muted,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    key: const Key('dashboard-hero-section'),
                                    width: fullWidth,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        MediaQuery.sizeOf(context).width >= 1100
                                            ? 32
                                            : compact
                                            ? 21
                                            : 25,
                                      ),
                                      constraints: BoxConstraints(
                                        minHeight:
                                            MediaQuery.sizeOf(context).width >=
                                                1100
                                            ? 250
                                            : MediaQuery.sizeOf(context)
                                                      .width >=
                                                  720
                                            ? 220
                                            : compact
                                            ? 190
                                            : 205,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(32),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF292750),
                                            Color(0xFF171B35),
                                            Color(0xFF10172B),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: .1,
                                          ),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 28,
                                            offset: Offset(0, 14),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(32),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: -80,
                                              top: -95,
                                              child: Container(
                                                width: 220,
                                                height: 220,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      _cyan.withValues(
                                                        alpha: .24,
                                                      ),
                                                      _cyan.withValues(
                                                        alpha: 0,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Positioned(
                                              right: 24,
                                              top: 28,
                                              child: _HeroSparkle(
                                                size: 5,
                                                opacity: .8,
                                              ),
                                            ),
                                            const Positioned(
                                              right: 12,
                                              top: 88,
                                              child: _HeroSparkle(
                                                size: 4,
                                                opacity: .55,
                                              ),
                                            ),
                                            const Positioned(
                                              right: 78,
                                              bottom: 26,
                                              child: _HeroSparkle(
                                                size: 5,
                                                opacity: .7,
                                              ),
                                            ),
                                            const Positioned(
                                              right: 132,
                                              top: 44,
                                              child: _HeroSparkle(
                                                size: 3,
                                                opacity: .45,
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.circle,
                                                      color: _green,
                                                      size: 8,
                                                    ),
                                                    SizedBox(width: 7),
                                                    Text(
                                                      'CURRENT RUN',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF9BA5C4,
                                                        ),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 1.7,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Find your secret number',
                                                  style: TextStyle(
                                                    color: Color(0xFF9BA5C4),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      const LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          _cyan,
                                                        ],
                                                      ).createShader(bounds),
                                                  child: Text(
                                                    '${game.minimum} — ${game.maximum}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: compact
                                                          ? 35
                                                          : MediaQuery.sizeOf(
                                                                  context,
                                                                ).width >=
                                                                1100
                                                          ? (MediaQuery.sizeOf(
                                                                      context,
                                                                    ).width *
                                                                    .04)
                                                                .clamp(
                                                                  42.0,
                                                                  58.0,
                                                                )
                                                                .toDouble()
                                                          : 42,
                                                      height: 1,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: -2.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Text(
                                                  message,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFFD2D9F0),
                                                    fontSize: 13,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (randomEventMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: _gold.withValues(
                                          alpha: dark ? .12 : .16,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _gold.withValues(alpha: .38),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: _gold,
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'RANDOM EVENT',
                                                  style: TextStyle(
                                                    color: muted,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  randomEventMessage!,
                                                  style: TextStyle(
                                                    color: foreground,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(
                                    key: const Key(
                                      'dashboard-bot-arena-section',
                                    ),
                                    width: MediaQuery.sizeOf(context).width >= 720
                                        ? (fullWidth - 14) / 2
                                        : fullWidth,
                                    child: _BotArena(
                                      progression: progression,
                                      onOpenShop: onNebulaShop,
                                      panel: panel,
                                      line: line,
                                      foreground: foreground,
                                      muted: muted,
                                    ),
                                  ),
                                  SizedBox(
                                    key: const Key('dashboard-guess-section'),
                                    width: fullWidth,
                                    child: _GuessInput(
                                      game: game,
                                      controller: controller,
                                      enabled: !loading && !game.isComplete,
                                      completed: game.isComplete,
                                      onGuess: onGuess,
                                      panel: panel,
                                      raised: raised,
                                      line: line,
                                      foreground: foreground,
                                      muted: muted,
                                    ),
                                  ),
                                  SizedBox(
                                    key: const Key('dashboard-stats-section'),
                                    width: fullWidth,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _Stat(
                                            Icons.bolt_rounded,
                                            game.attempts.toString(),
                                            'ATTEMPTS',
                                            _cyan,
                                            panel,
                                            line,
                                            foreground,
                                            muted,
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context)
                                                      .width >=
                                                  1100
                                              ? 12
                                              : 10,
                                        ),
                                        Expanded(
                                          child: _Stat(
                                            Icons.check_circle_rounded,
                                            progression.correctGuesses
                                                .toString(),
                                            'CORRECT',
                                            _gold,
                                            panel,
                                            line,
                                            foreground,
                                            muted,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _Stat(
                                            Icons.local_fire_department_rounded,
                                            progression.currentStreak
                                                .toString(),
                                            'STREAK',
                                            _green,
                                            panel,
                                            line,
                                            foreground,
                                            muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    key: const Key('dashboard-wallet-section'),
                                    width: fullWidth,
                                    child: _Wallet(
                                      progression,
                                      panel,
                                      raised,
                                      line,
                                      foreground,
                                      muted,
                                      incomePerSecond,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fullWidth,
                                    child: MediaQuery.sizeOf(context).width >= 720
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  key: const Key(
                                                    'dashboard-action-beyond',
                                                  ),
                                                  child: _Action(
                                                    'Beyond the Numbers',
                                                    'Explore your progression',
                                                    Icons.public_rounded,
                                                    _cyan,
                                                    onWorldMap,
                                                    panel,
                                                    line,
                                                    foreground,
                                                    muted,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 9),
                                              Expanded(
                                                child: SizedBox(
                                                  key: const Key(
                                                    'dashboard-action-daily',
                                                  ),
                                                  child: _Action(
                                                    'Daily Momentum',
                                                    'Keep the streak alive',
                                                    Icons.auto_awesome_rounded,
                                                    _gold,
                                                    () => onLegacySection(
                                                      LegacySection.rewards,
                                                    ),
                                                    panel,
                                                    line,
                                                    foreground,
                                                    muted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              SizedBox(
                                                key: const Key(
                                                  'dashboard-action-beyond',
                                                ),
                                                child: _Action(
                                                  'Beyond the Numbers',
                                                  'Explore your progression',
                                                  Icons.public_rounded,
                                                  _cyan,
                                                  onWorldMap,
                                                  panel,
                                                  line,
                                                  foreground,
                                                  muted,
                                                ),
                                              ),
                                              const SizedBox(height: 9),
                                              SizedBox(
                                                key: const Key(
                                                  'dashboard-action-daily',
                                                ),
                                                child: _Action(
                                                  'Daily Momentum',
                                                  'Keep the streak alive',
                                                  Icons.auto_awesome_rounded,
                                                  _gold,
                                                  () => onLegacySection(
                                                    LegacySection.rewards,
                                                  ),
                                                  panel,
                                                  line,
                                                  foreground,
                                                  muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  if (game.isComplete)
                                    SizedBox(
                                      width: fullWidth,
                                      child: M3EButton.icon(
                                        style: M3EButtonStyle.filled,
                                        onPressed: loading ? null : onNewGame,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text(
                                          'Start another round',
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (loading)
                Positioned.fill(
                  child: Stack(
                    children: [
                      const ModalBarrier(
                        key: Key('dashboard-loading-barrier'),
                        dismissible: false,
                        color: Color(0xB3000618),
                      ),
                      Center(
                        child: Semantics(
                          liveRegion: true,
                          label: 'Loading your game',
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: dark ? _panel : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: line),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 28,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Loading your game',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Restoring save slot $activeSlot and preparing your next round.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSparkle extends StatelessWidget {
  const _HeroSparkle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: opacity * .45),
            blurRadius: size * 2.4,
          ),
        ],
      ),
    ),
  );
}

class _BotArena extends StatelessWidget {
  const _BotArena({
    required this.progression,
    required this.onOpenShop,
    required this.panel,
    required this.line,
    required this.foreground,
    required this.muted,
  });

  final ProgressionState progression;
  final VoidCallback onOpenShop;
  final Color panel;
  final Color line;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    const botIds = ['auto_clicker_basic', 'bot_byte', 'bot_pixel'];
    final systems = progression.legacySystems;
    final ownedBots = botIds
        .where((id) => (progression.nebulaItems[id] ?? 0) > 0)
        .toList(growable: false);
    final active = systems.autoClickerActive && ownedBots.isNotEmpty;
    final countLabel = ownedBots.isEmpty
        ? 'NO BOTS YET'
        : '${ownedBots.length} ${ownedBots.length == 1 ? 'BOT' : 'BOTS'}';
    final status = ownedBots.isEmpty
        ? 'Buy a bot in the Nebula Shop to bring the arena to life.'
        : active
        ? 'Your bots will show their real guesses here.'
        : 'Your bots are owned but automation is paused.';
    final lastGuess = systems.lastBotGuess == null
        ? 'Waiting for your first bot guess…'
        : '${systems.lastBotId ?? 'Bot'} guessed ${systems.lastBotGuess} · '
              '${switch (systems.lastBotFeedback) {
                'TOO_LOW' => 'TOO LOW',
                'TOO_HIGH' => 'TOO HIGH',
                'CORRECT' => 'CORRECT',
                _ => 'WAITING',
              }}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTOMATION LAB',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Guessing Bots',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  countLabel,
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1123),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: Column(
              children: [
                Icon(
                  active ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                  size: 34,
                  color: active ? _cyan : const Color(0xFF687493),
                ),
                const SizedBox(height: 9),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD2D9F0),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastGuess,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 9),
                ),
              ),
              M3EButton.text(
                onPressed: onOpenShop,
                child: const Text('Nebula Shop ↗'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreMenuPage extends StatelessWidget {
  const _MoreMenuPage({
    required this.settings,
    required this.settingsListenable,
    required this.showDeveloperSettings,
    required this.onSaveSlots,
    required this.playerProfile,
    required this.onPlayerProfile,
    required this.onDestination,
  });

  final GameSettings settings;
  final ValueListenable<GameSettings> settingsListenable;
  final bool showDeveloperSettings;
  final VoidCallback onSaveSlots;
  final PlayerProfile playerProfile;
  final VoidCallback onPlayerProfile;
  final ValueChanged<String> onDestination;

  Color _destinationColor(String? hex) {
    if (hex == null || hex.isEmpty) return _purple;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value == null ? _purple : Color(value | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<GameSettings>(
    valueListenable: settingsListenable,
    builder: (context, liveSettings, _) =>
        _buildWithSettings(context, liveSettings),
  );

  Widget _buildWithSettings(BuildContext context, GameSettings settings) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? _white : const Color(0xFF172039);
    final muted = dark ? _muted : const Color(0xFF65708C);
    final panel = dark ? _panel : Colors.white;
    final line = dark ? _line : const Color(0x180D1530);
    final compact = MediaQuery.sizeOf(context).width <= 520;

    Widget entry(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      Color accent, {
      Key? key,
    }) {
      final radius = BorderRadius.circular(18);
      return GtnExpressiveCard(
        key: key,
        color: panel,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: line),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 70 : 78),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 15,
                  vertical: compact ? 12 : 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 40 : 42,
                      height: compact ? 40 : 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: dark ? .16 : .11),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: muted, size: 23),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final destinations =
        <
          String,
          ({IconData icon, String title, String subtitle, VoidCallback onTap})
        >{
          'player_profile': (
            icon: Icons.account_circle_rounded,
            title: playerProfile.username.isEmpty
                ? 'Player profile'
                : playerProfile.username,
            subtitle: playerProfile.bio.isEmpty
                ? 'View your username and bio, then edit your profile'
                : playerProfile.bio,
            onTap: onPlayerProfile,
          ),
          'worlds': (
            icon: Icons.public_rounded,
            title: 'Beyond the Numbers',
            subtitle: 'Explore worlds and guardians',
            onTap: () => onDestination('worlds'),
          ),
          'arcade': (
            icon: Icons.sports_esports_rounded,
            title: 'Arcade',
            subtitle: 'Play arcade challenges',
            onTap: () => onDestination('arcade'),
          ),
          'upgrades': (
            icon: Icons.upgrade_rounded,
            title: 'Upgrades',
            subtitle: 'Improve your game',
            onTap: () => onDestination('upgrades'),
          ),
          'rewards': (
            icon: Icons.card_giftcard_rounded,
            title: 'Rewards',
            subtitle: 'Achievements and daily rewards',
            onTap: () => onDestination('rewards'),
          ),
          'journey': (
            icon: Icons.timeline_rounded,
            title: 'Journey',
            subtitle: 'Your run history and progress',
            onTap: () => onDestination('journey'),
          ),
          'shop': (
            icon: Icons.storefront_rounded,
            title: 'Shop',
            subtitle: 'Browse available items',
            onTap: () => onDestination('shop'),
          ),
          'mutators': (
            icon: Icons.tune_rounded,
            title: 'Mutators',
            subtitle: 'Customize challenge rules',
            onTap: () => onDestination('mutators'),
          ),
          'talent': (
            icon: Icons.psychology_alt_rounded,
            title: 'Talents',
            subtitle: 'Build your talent path',
            onTap: () => onDestination('talent'),
          ),
          'traits': (
            icon: Icons.auto_awesome_rounded,
            title: 'Traits',
            subtitle: 'Choose gameplay traits and variants',
            onTap: () => onDestination('traits'),
          ),
          'relics': (
            icon: Icons.auto_awesome_rounded,
            title: 'Relics',
            subtitle: 'Manage your relic collection',
            onTap: () => onDestination('relics'),
          ),
          'home_base': (
            icon: Icons.home_work_rounded,
            title: 'Home Base',
            subtitle: 'Build up your base',
            onTap: () => onDestination('homebase'),
          ),
          'codex': (
            icon: Icons.menu_book_rounded,
            title: 'Codex',
            subtitle: 'Discoveries and lore entries',
            onTap: () => onDestination('codex'),
          ),
          'stats': (
            icon: Icons.query_stats_rounded,
            title: 'Stats',
            subtitle: 'Review your gameplay records',
            onTap: () => onDestination('stats'),
          ),
          'dev_settings': (
            icon: Icons.build_rounded,
            title: 'Dev Settings',
            subtitle: 'Developer console and diagnostics',
            onTap: () => onDestination('dev_settings'),
          ),
          'changelog': (
            icon: Icons.history_rounded,
            title: 'Changelog',
            subtitle: 'Review version history',
            onTap: () => onDestination('changelog'),
          ),
          'settings': (
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Game preferences and Menu Studio',
            onTap: () => onDestination('settings'),
          ),
          'about': (
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Credits, links and app information',
            onTap: () => onDestination('about'),
          ),
          'staking': (
            icon: Icons.casino_rounded,
            title: 'Lucky Stake',
            subtitle: 'Risk Money for streak-based rewards',
            onTap: () => onDestination('stake'),
          ),
          'ultra': (
            icon: Icons.bolt_rounded,
            title: 'Ultra',
            subtitle: 'Permanent progression upgrades',
            onTap: () => onDestination('ultra'),
          ),
          'prestige': (
            icon: Icons.auto_awesome_rounded,
            title: 'Prestige',
            subtitle: 'Reset and advance your progression',
            onTap: () => onDestination('prestige'),
          ),
          'save_slots': (
            icon: Icons.save_rounded,
            title: 'Save Slots',
            subtitle: 'Manage your saved games',
            onTap: onSaveSlots,
          ),
          'music': (
            icon: Icons.library_music_rounded,
            title: 'Background Music',
            subtitle: 'Offline library, playlists and queue',
            onTap: () => onDestination('music'),
          ),
        };
    final layout = MenuStudioLayout.fromSettings(settings);
    final orderedIds = <String>[];
    for (final sourceId in layout.visibleMoreIds) {
      final id = MenuStudioLayout.settingsIdFor(sourceId);
      if (id == 'music' && !orderedIds.contains('save_slots')) {
        orderedIds.add('save_slots');
      }
      if (destinations.containsKey(id) &&
          (id != 'dev_settings' || showDeveloperSettings)) {
        orderedIds.add(id);
      }
    }
    if (!orderedIds.contains('save_slots')) {
      final aboutIndex = orderedIds.indexOf('about');
      final changelogIndex = orderedIds.indexOf('changelog');
      final insertAt = aboutIndex >= 0
          ? aboutIndex + 1
          : changelogIndex >= 0
          ? changelogIndex + 1
          : orderedIds.length;
      orderedIds.insert(insertAt, 'save_slots');
    }

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = viewportWidth <= 430
        ? 12.0
        : viewportWidth >= 720
        ? (viewportWidth * .03).clamp(20.0, 36.0).toDouble()
        : 16.0;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                28,
              ),
              children: [
                Row(
                  key: const Key('more-global-topbar'),
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [_purple, Color(0xFF6651D9)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withValues(alpha: .25),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/gtn1/gtn-app-logo.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Guess The Number',
                        style: TextStyle(
                          color: foreground,
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: foreground.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: foreground.withValues(alpha: .08),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: _green,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'OFFLINE',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = MediaQuery.sizeOf(context).width > 520 ? 2 : 1;
                    const spacing = 12.0;
                    final itemWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    final profile = destinations['player_profile']!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth,
                          child: entry(
                            profile.icon,
                            profile.title,
                            profile.subtitle,
                            profile.onTap,
                            _destinationColor(
                              settings.moreScreenButtonColors['player_profile'],
                            ),
                            key: const Key('more-profile-card'),
                          ),
                        ),
                        const SizedBox(height: spacing),
                        Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final id in orderedIds)
                              SizedBox(
                                width: itemWidth,
                                child: entry(
                                  destinations[id]!.icon,
                                  destinations[id]!.title,
                                  destinations[id]!.subtitle,
                                  destinations[id]!.onTap,
                                  _destinationColor(
                                    settings.moreScreenButtonColors[id],
                                  ),
                                  key: Key('more-card-$id'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
    this.icon,
    this.value,
    this.label,
    this.color,
    this.panel,
    this.line,
    this.foreground,
    this.muted,
  );
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color panel;
  final Color line;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      vertical: MediaQuery.sizeOf(context).width >= 1100 ? 20 : 15,
      horizontal: MediaQuery.sizeOf(context).width >= 1100 ? 12 : 10,
    ),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line),
    ),
    child: Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: MediaQuery.sizeOf(context).width >= 1100
                ? 26
                : MediaQuery.sizeOf(context).width <= 360
                ? 18
                : 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _Wallet extends StatelessWidget {
  const _Wallet(
    this.state,
    this.panel,
    this.raised,
    this.line,
    this.foreground,
    this.muted,
    this.incomePerSecond,
  );
  final ProgressionState state;
  final Color panel;
  final Color raised;
  final Color line;
  final Color foreground;
  final Color muted;
  final BigNumber? incomePerSecond;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 720 ? 22 : 17),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: _gold,
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              'MONEY',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '＋',
                      style: TextStyle(color: _green, fontSize: 10),
                    ),
                    Text(
                      '${incomePerSecond ?? BigNumber.fromInt(0)}',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      '/s',
                      style: TextStyle(color: _green, fontSize: 10),
                    ),
                  ],
                ),
                Text(
                  '${state.moneyEarned} earned',
                  style: TextStyle(color: muted, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          state.money.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _gold,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: state.bestStreak == 0
                ? 0
                : (state.currentStreak / state.bestStreak).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: raised,
            color: _purple,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'RUN MOMENTUM',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              'BEST ${state.bestStreak}',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _Currency(
                Icons.auto_awesome_rounded,
                'PRESTIGE',
                state.prestige.toString(),
                _purple,
                raised,
                foreground,
                muted,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _Currency(
                Icons.bolt_rounded,
                'ULTRA',
                state.ultra.toString(),
                _cyan,
                raised,
                foreground,
                muted,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _Currency(
                Icons.diamond_rounded,
                'NEBULA',
                state.nebula.toString(),
                const Color(0xFFB7A2FF),
                raised,
                foreground,
                muted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Currency extends StatelessWidget {
  const _Currency(
    this.icon,
    this.label,
    this.value,
    this.color,
    this.background,
    this.foreground,
    this.muted,
  );
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}

class _GuessInput extends StatelessWidget {
  const _GuessInput({
    required this.game,
    required this.controller,
    required this.enabled,
    required this.completed,
    required this.onGuess,
    required this.panel,
    required this.raised,
    required this.line,
    required this.foreground,
    required this.muted,
  });
  final GameState game;
  final TextEditingController controller;
  final bool enabled;
  final bool completed;
  final VoidCallback onGuess;
  final Color panel;
  final Color raised;
  final Color line;
  final Color foreground;
  final Color muted;

  void _setGuess(int value) {
    controller.text = value.toString();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 720 ? 22 : 18),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'YOUR GUESS',
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              'WHOLE NUMBER',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Your guess',
                textField: true,
                child: GtnExpressiveTextField(
                  key: const Key('guess-input'),
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onGuess(),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.text(
                      'play_enter_guess',
                      'Enter your guess',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: MediaQuery.sizeOf(context).width <= 430 ? 100 : 116,
              height: 56,
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Guess',
                button: true,
                enabled: enabled,
                child: M3EButton.filled(
                  onPressed: enabled ? onGuess : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.text('play_guess_button', 'GUESS'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'QUICK PICK',
            style: TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _QuickGuessButton(
              semanticLabel: 'Use lower end of range',
              label: AppLocalizations.text('web_guess_lower_end', 'LOW END'),
              enabled: enabled,
              onPressed: () => _setGuess(game.minimum),
            ),
            _QuickGuessButton(
              semanticLabel: 'Use midpoint of range',
              label: AppLocalizations.text('web_ui_midpoint', 'MIDPOINT'),
              enabled: enabled,
              onPressed: () =>
                  _setGuess(game.minimum + (game.maximum - game.minimum) ~/ 2),
            ),
            _QuickGuessButton(
              semanticLabel: 'Use upper end of range',
              label: AppLocalizations.text('web_guess_upper_end', 'HIGH END'),
              enabled: enabled,
              onPressed: () => _setGuess(game.maximum),
            ),
            _QuickGuessButton(
              semanticLabel: 'Clear guess input',
              label: AppLocalizations.text('clear', 'CLEAR'),
              enabled: enabled,
              onPressed: () {
                controller.clear();
                controller.selection = const TextSelection.collapsed(offset: 0);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            completed
                ? 'You found it! Start another round when you are ready.'
                : 'Every correct guess earns Money. Build your streak for bigger rewards.',
            style: TextStyle(color: muted, fontSize: 10, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _QuickGuessButton extends StatelessWidget {
  const _QuickGuessButton({
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    excludeSemantics: true,
    label: semanticLabel,
    button: true,
    enabled: enabled,
    child: M3EButton.outlined(
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
    this.panel,
    this.line,
    this.foreground,
    this.muted,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color panel;
  final Color line;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) => Material(
    color: panel,
    borderRadius: BorderRadius.circular(21),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 10, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF6F7B9D),
              size: 23,
            ),
          ],
        ),
      ),
    ),
  );
}
