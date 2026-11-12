import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/game/game_engine.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
import '../legacy/legacy_pages.dart';
import '../legacy/legacy_systems_page.dart';
import '../settings/game_settings.dart';

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
    required this.onSaveSlots,
    required this.onSettings,
    required this.onDeveloperSettings,
    required this.onLegacyPages,
    required this.onMusic,
    required this.onLuckyStake,
    required this.onSystems,
    this.showDeveloperSettings = false,
    required this.shellNavigatorKey,
    required this.selectedIndex,
    required this.onPrimarySelected,
    required this.onSystemsView,
    required this.onLegacySection,
  });

  final GameState game;
  final ProgressionState progression;
  final GameSettings settings;
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
  final VoidCallback onSaveSlots;
  final VoidCallback onSettings;
  final VoidCallback onDeveloperSettings;
  final VoidCallback onLegacyPages;
  final VoidCallback onMusic;
  final VoidCallback onLuckyStake;
  final VoidCallback onSystems;
  final bool showDeveloperSettings;
  final GlobalKey<NavigatorState> shellNavigatorKey;
  final int selectedIndex;
  final ValueChanged<int> onPrimarySelected;
  final ValueChanged<LegacySystemsView> onSystemsView;
  final ValueChanged<LegacySection> onLegacySection;

  void _openMoreMenu(BuildContext context, Color panel) {
    shellNavigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _MoreMenuPage(
          settings: settings,
          showDeveloperSettings: showDeveloperSettings,
          onPrestige: onPrestige,
          onNebulaShop: onNebulaShop,
          onLegacyPages: onLegacyPages,
          onSaveSlots: onSaveSlots,
          onSettings: onSettings,
          onDeveloperSettings: onDeveloperSettings,
          onWorldMap: onWorldMap,
          onArcade: onArcade,
          onMusic: onMusic,
          onLuckyStake: onLuckyStake,
          onSystems: onSystems,
          onSystemsView: onSystemsView,
          onLegacySection: onLegacySection,
          onUpgradeShop: onUpgradeShop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width <= 430;
    final horizontalPadding = compact ? 12.0 : 16.0;
    final foreground = dark ? _white : const Color(0xFF172039);
    final muted = dark ? _muted : const Color(0xFF65708C);
    final panel = dark ? _panel : Colors.white;
    final raised = dark ? _raised : const Color(0xFFF0F1FA);
    final line = dark ? _line : const Color(0x180D1530);

    return Scaffold(
      backgroundColor: dark ? _bg : const Color(0xFFF5F6FC),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          void selectDestination(int index) {
            // Primary tabs replace the active primary destination. Feature
            // pages opened from More use push(), so Back returns to More while
            // the shared navigation shell remains mounted.
            shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            onPrimarySelected(index);
            switch (index) {
              case 0:
                onWorldMap();
                break;
              case 1:
                onArcade();
                break;
              case 2:
                break;
              case 3:
                onUpgradeShop();
                break;
              case 4:
                _openMoreMenu(context, panel);
                break;
            }
          }

          // The M3E bar switches to a wide horizontal-chip layout on larger
          // windows. Keep the GTN1 five-item labels inside the available width
          // with the standard adaptive M3 bar on tablets and desktop windows.
          if (constraints.maxWidth > 600) {
            return NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: selectDestination,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 76,
              backgroundColor: panel,
              indicatorColor: _purple.withValues(alpha: .18),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.public_rounded),
                  label: 'Beyond the Numbers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_rounded),
                  label: 'Arcade',
                ),
                NavigationDestination(
                  icon: Icon(Icons.play_arrow_rounded),
                  label: 'Play',
                ),
                NavigationDestination(
                  icon: Icon(Icons.upgrade_rounded),
                  label: 'Upgrades',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded),
                  label: 'More',
                ),
              ],
            );
          }

          return M3ENavigationBar(
            destinations: const [
              M3ENavigationBarDestination(
                icon: Icon(Icons.public_rounded),
                label: 'Beyond the Numbers',
              ),
              M3ENavigationBarDestination(
                icon: Icon(Icons.sports_esports_rounded),
                label: 'Arcade',
              ),
              M3ENavigationBarDestination(
                icon: Icon(Icons.play_arrow_rounded),
                label: 'Play',
              ),
              M3ENavigationBarDestination(
                icon: Icon(Icons.upgrade_rounded),
                label: 'Upgrades',
              ),
              M3ENavigationBarDestination(
                icon: Icon(Icons.menu_rounded),
                label: 'More',
              ),
            ],
            selectedIndex: selectedIndex,
            onDestinationSelected: selectDestination,
          );
        },
      ),
      body: Navigator(
        key: shellNavigatorKey,
        onGenerateRoute: (routeSettings) => MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => Container(
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
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      28,
                    ),
                    children: [
                      Row(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Container(
                        padding: EdgeInsets.all(compact ? 21 : 25),
                        constraints: BoxConstraints(
                          minHeight: compact ? 190 : 205,
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
                            color: Colors.white.withValues(alpha: .1),
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
                                        _cyan.withValues(alpha: .24),
                                        _cyan.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                right: 24,
                                top: 28,
                                child: _HeroSparkle(size: 5, opacity: .8),
                              ),
                              const Positioned(
                                right: 12,
                                top: 88,
                                child: _HeroSparkle(size: 4, opacity: .55),
                              ),
                              const Positioned(
                                right: 78,
                                bottom: 26,
                                child: _HeroSparkle(size: 5, opacity: .7),
                              ),
                              const Positioned(
                                right: 132,
                                top: 44,
                                child: _HeroSparkle(size: 3, opacity: .45),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: Color(0xFF9BA5C4),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
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
                                          colors: [Colors.white, _cyan],
                                        ).createShader(bounds),
                                    child: Text(
                                      '${game.minimum} — ${game.maximum}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: compact ? 35 : 42,
                                        height: 1,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -2.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 12),
                      _GuessInput(
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
                      const SizedBox(height: 12),
                      Row(
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
                          const SizedBox(width: 6),
                          Expanded(
                            child: _Stat(
                              Icons.check_circle_rounded,
                              progression.correctGuesses.toString(),
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
                              progression.currentStreak.toString(),
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
                      const SizedBox(height: 12),
                      _Wallet(
                        progression,
                        panel,
                        raised,
                        line,
                        foreground,
                        muted,
                      ),
                      const SizedBox(height: 12),
                      _BotArena(
                        progression: progression,
                        onOpenShop: onNebulaShop,
                        panel: panel,
                        line: line,
                        foreground: foreground,
                        muted: muted,
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Action(
                              'Daily Momentum',
                              'Keep the streak alive',
                              Icons.auto_awesome_rounded,
                              _gold,
                              onLegacyPages,
                              panel,
                              line,
                              foreground,
                              muted,
                            ),
                          ),
                        ],
                      ),
                      if (game.isComplete) ...[
                        const SizedBox(height: 12),
                        M3EButton.icon(
                          style: M3EButtonStyle.filled,
                          onPressed: loading ? null : onNewGame,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Start another round'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
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
    required this.showDeveloperSettings,
    required this.onPrestige,
    required this.onNebulaShop,
    required this.onLegacyPages,
    required this.onSaveSlots,
    required this.onSettings,
    required this.onDeveloperSettings,
    required this.onWorldMap,
    required this.onArcade,
    required this.onMusic,
    required this.onLuckyStake,
    required this.onSystems,
    required this.onSystemsView,
    required this.onLegacySection,
    required this.onUpgradeShop,
  });

  final GameSettings settings;
  final bool showDeveloperSettings;
  final VoidCallback onPrestige;
  final VoidCallback onNebulaShop;
  final VoidCallback onLegacyPages;
  final VoidCallback onSaveSlots;
  final VoidCallback onSettings;
  final VoidCallback onDeveloperSettings;
  final VoidCallback onWorldMap;
  final VoidCallback onArcade;
  final VoidCallback onMusic;
  final VoidCallback onLuckyStake;
  final VoidCallback onSystems;
  final ValueChanged<LegacySystemsView> onSystemsView;
  final ValueChanged<LegacySection> onLegacySection;
  final VoidCallback onUpgradeShop;

  Color _destinationColor(String? hex) {
    if (hex == null || hex.isEmpty) return _purple;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value == null ? _purple : Color(value | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? _white : const Color(0xFF172039);
    final muted = dark ? _muted : const Color(0xFF65708C);
    final panel = dark ? _panel : Colors.white;

    Widget entry(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      Color accent,
    ) {
      return GtnExpressiveCard(
        color: panel,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accent.withValues(alpha: .24)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? .16 : .11),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: accent, size: 23),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: accent,
                      size: 17,
                    ),
                  ),
                ],
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
          'world_map': (
            icon: Icons.public_rounded,
            title: 'World map',
            subtitle: 'Explore unlocked worlds and bosses',
            onTap: onWorldMap,
          ),
          'achievements': (
            icon: Icons.emoji_events_rounded,
            title: 'Achievements',
            subtitle: 'Journey progress and rewards',
            onTap: () => onLegacySection(LegacySection.journey),
          ),
          'rewards': (
            icon: Icons.card_giftcard_rounded,
            title: 'Rewards',
            subtitle: 'Achievements and daily rewards',
            onTap: () => onLegacySection(LegacySection.rewards),
          ),
          'journey': (
            icon: Icons.timeline_rounded,
            title: 'Journey',
            subtitle: 'Your run history and progress',
            onTap: () => onLegacySection(LegacySection.journey),
          ),
          'shop': (
            icon: Icons.storefront_rounded,
            title: 'Shop',
            subtitle: 'Browse upgrades',
            onTap: onUpgradeShop,
          ),
          'mutators': (
            icon: Icons.tune_rounded,
            title: 'Mutators',
            subtitle: 'Customize challenge rules',
            onTap: () => onSystemsView(LegacySystemsView.mutators),
          ),
          'talent': (
            icon: Icons.psychology_alt_rounded,
            title: 'Talents',
            subtitle: 'Build your talent path',
            onTap: () => onSystemsView(LegacySystemsView.talents),
          ),
          'traits': (
            icon: Icons.auto_awesome_rounded,
            title: 'Traits',
            subtitle: 'Choose gameplay traits and variants',
            onTap: () => onSystemsView(LegacySystemsView.traits),
          ),
          'relics': (
            icon: Icons.auto_awesome_rounded,
            title: 'Relics',
            subtitle: 'Manage your relic collection',
            onTap: () => onSystemsView(LegacySystemsView.relics),
          ),
          'home_base': (
            icon: Icons.home_work_rounded,
            title: 'Home Base',
            subtitle: 'Build up your base',
            onTap: () => onSystemsView(LegacySystemsView.homeBase),
          ),
          'codex': (
            icon: Icons.menu_book_rounded,
            title: 'Codex',
            subtitle: 'Discoveries and lore entries',
            onTap: () => onLegacySection(LegacySection.codex),
          ),
          'endgame': (
            icon: Icons.flag_rounded,
            title: 'Endgame',
            subtitle: 'Prestige and Ultra progression',
            onTap: onPrestige,
          ),
          'arcade': (
            icon: Icons.sports_esports_rounded,
            title: 'Arcade',
            subtitle: 'Play minigames and earn rewards',
            onTap: onArcade,
          ),
          'stats': (
            icon: Icons.query_stats_rounded,
            title: 'Statistics',
            subtitle: 'Review your gameplay records',
            onTap: () => onLegacySection(LegacySection.statistics),
          ),
          'changelog': (
            icon: Icons.history_rounded,
            title: 'Changelog',
            subtitle: 'Review version history',
            onTap: () => onLegacySection(LegacySection.changelog),
          ),
          'settings': (
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Game preferences and Menu Studio',
            onTap: onSettings,
          ),
          'about': (
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Credits, links and app information',
            onTap: () => onLegacySection(LegacySection.about),
          ),
          'staking': (
            icon: Icons.casino_rounded,
            title: 'Lucky Stake',
            subtitle: 'Risk Money for streak-based rewards',
            onTap: onLuckyStake,
          ),
          'ultra': (
            icon: Icons.bolt_rounded,
            title: 'Ultra',
            subtitle: 'Permanent progression upgrades',
            onTap: onPrestige,
          ),
          'prestige': (
            icon: Icons.auto_awesome_rounded,
            title: 'Prestige',
            subtitle: 'Reset and advance your progression',
            onTap: onPrestige,
          ),
          'save_slots': (
            icon: Icons.save_rounded,
            title: 'Save Slots',
            subtitle: 'Manage your saved games',
            onTap: onSaveSlots,
          ),
          'music': (
            icon: Icons.library_music_rounded,
            title: 'Music',
            subtitle: 'Offline library, playlists and queue',
            onTap: onMusic,
          ),
          'nebula': (
            icon: Icons.diamond_rounded,
            title: 'Nebula Shop',
            subtitle: 'Permanent Nebula upgrades and items',
            onTap: onNebulaShop,
          ),
        };
    final orderedIds = settings.moreScreenOrder
        .where(destinations.containsKey)
        .toSet()
        .toList();
    for (final id in destinations.keys) {
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }

    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('More Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF30295D), Color(0xFF171F36)]
                    : const [Color(0xFFE9E4FF), Color(0xFFF3F0FF)],
              ),
              border: Border.all(
                color: _purple.withValues(alpha: dark ? .28 : .18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: _purple,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPLORE GTN2',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'More Menu',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.7,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your shortcuts, your order.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final id in orderedIds)
            entry(
              destinations[id]!.icon,
              destinations[id]!.title,
              destinations[id]!.subtitle,
              destinations[id]!.onTap,
              _destinationColor(settings.moreScreenButtonColors[id]),
            ),
          if (showDeveloperSettings)
            entry(
              Icons.bug_report_rounded,
              'Dev Settings',
              'Developer tools',
              onDeveloperSettings,
              _destinationColor(null),
            ),
        ],
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
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(22),
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
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: MediaQuery.sizeOf(context).width <= 360 ? 18 : 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
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
  );
  final ProgressionState state;
  final Color panel;
  final Color raised;
  final Color line;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
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
              'YOUR WALLET',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              '${state.moneyEarned} earned',
              style: const TextStyle(color: _green, fontSize: 10),
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
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        Text(
          'MONEY',
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 10),
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
    padding: const EdgeInsets.all(18),
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
                container: true,
                excludeSemantics: true,
                label: 'Your guess',
                textField: true,
                child: GtnExpressiveTextField(
                  key: const Key('guess-input'),
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onGuess(),
                  decoration: const InputDecoration(hintText: 'Enter a number'),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: MediaQuery.sizeOf(context).width <= 360 ? 104 : 120,
              height: 56,
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Guess',
                button: true,
                enabled: enabled,
                child: M3EButton.filled(
                  onPressed: enabled ? onGuess : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GUESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_rounded, size: 18),
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
              label: 'LOW END',
              enabled: enabled,
              onPressed: () => _setGuess(game.minimum),
            ),
            _QuickGuessButton(
              semanticLabel: 'Use midpoint of range',
              label: 'MIDPOINT',
              enabled: enabled,
              onPressed: () =>
                  _setGuess(game.minimum + (game.maximum - game.minimum) ~/ 2),
            ),
            _QuickGuessButton(
              semanticLabel: 'Use upper end of range',
              label: 'HIGH END',
              enabled: enabled,
              onPressed: () => _setGuess(game.maximum),
            ),
            _QuickGuessButton(
              semanticLabel: 'Clear guess input',
              label: 'CLEAR',
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
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 8),
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
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 10, height: 1.2),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted, size: 16),
          ],
        ),
      ),
    ),
  );
}
