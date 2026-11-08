import 'package:flutter/material.dart';

import '../core/game/game_engine.dart';
import '../core/progression/progression_state.dart';

const _purple = Color(0xFF9B7CFF);
const _cyan = Color(0xFF62E8FF);
const _gold = Color(0xFFFFD66B);
const _green = Color(0xFF63F5A4);
const _bg = Color(0xFF080B16);
const _panel = Color(0xFF11172A);
const _raised = Color(0xFF171F36);
const _line = Color(0x20FFFFFF);
const _white = Color(0xFFF7F8FF);
const _muted = Color(0xFF9BA5C4);

class GameDashboardPage extends StatelessWidget {
  const GameDashboardPage({
    super.key,
    required this.game,
    required this.progression,
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
    this.showDeveloperSettings = false,
  });

  final GameState game;
  final ProgressionState progression;
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
  final bool showDeveloperSettings;

  void _openMoreMenu(BuildContext context, Color panel) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _MoreMenuPage(
          showDeveloperSettings: showDeveloperSettings,
          onPrestige: onPrestige,
          onNebulaShop: onNebulaShop,
          onLegacyPages: onLegacyPages,
          onSaveSlots: onSaveSlots,
          onSettings: onSettings,
          onDeveloperSettings: onDeveloperSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? _white : const Color(0xFF172039);
    final muted = dark ? _muted : const Color(0xFF65708C);
    final panel = dark ? _panel : Colors.white;
    final raised = dark ? _raised : const Color(0xFFF0F1FA);
    final line = dark ? _line : const Color(0x180D1530);

    return Scaffold(
      backgroundColor: dark ? _bg : const Color(0xFFF5F6FC),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 8, 7, 7),
          decoration: BoxDecoration(
            color: dark ? const Color(0xF20A0E1C) : Colors.white,
            border: Border(
              top: BorderSide(color: foreground.withValues(alpha: .10)),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: _BottomNavItem(Icons.public_rounded, 'Beyond the Numbers', false, onWorldMap)),
              Expanded(child: _BottomNavItem(Icons.sports_esports_rounded, 'Arcade', false, onArcade)),
              Expanded(child: _BottomNavItem(Icons.play_arrow_rounded, 'Play', true, () {})),
              Expanded(child: _BottomNavItem(Icons.upgrade_rounded, 'Upgrades', false, onUpgradeShop)),
              Expanded(child: _BottomNavItem(Icons.menu_rounded, 'More', false, () => _openMoreMenu(context, panel))),
            ],
          ),
        ),
      ),
      body: Container(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
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
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/gtn1/gtn-app-logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GUESS THE NUMBER',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.7,
                                )),
                            Text('Guess The Number',
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                )),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: foreground.withValues(alpha: .08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, color: _green, size: 7),
                            const SizedBox(width: 6),
                            Text('ONLINE', style: TextStyle(
                              color: muted, fontSize: 8,
                              fontWeight: FontWeight.w900, letterSpacing: 1,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(23),
                    constraints: const BoxConstraints(minHeight: 188),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF292750),
                          Color(0xFF171B35),
                          Color(0xFF10172B),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: .1)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -55,
                          child: Container(
                            width: 190,
                            height: 190,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.circle, color: _green, size: 8),
                                SizedBox(width: 7),
                                Text(
                                  'CURRENT RUN',
                                  style: TextStyle(
                                    color: Color(0xFF9BA5C4),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Find your secret number',
                                style: TextStyle(
                                  color: Color(0xFF9BA5C4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                )),
                            const SizedBox(height: 9),
                            Text('${game.minimum} — ${game.maximum}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 43,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                )),
                            const SizedBox(height: 7),
                            const Text('Make your move.',
                                style: TextStyle(
                                  color: _cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                )),
                            const SizedBox(height: 12),
                            Text(message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD2D9F0),
                                  fontSize: 12,
                                  height: 1.4,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Stat(Icons.bolt_rounded,
                          game.attempts.toString(), 'ATTEMPTS', _cyan,
                          panel, line, foreground, muted)),
                      const SizedBox(width: 6),
                      Expanded(child: _Stat(Icons.check_circle_rounded,
                          progression.correctGuesses.toString(), 'CORRECT', _gold,
                          panel, line, foreground, muted)),
                      const SizedBox(width: 6),
                      Expanded(child: _Stat(Icons.local_fire_department_rounded,
                          progression.currentStreak.toString(), 'STREAK', _green,
                          panel, line, foreground, muted)),
                      const SizedBox(width: 6),
                      Expanded(child: _Stat(Icons.military_tech_rounded,
                          progression.bestStreak.toString(), 'BEST', _purple,
                          panel, line, foreground, muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Wallet(progression, panel, raised, line, foreground, muted),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text('MORE TO EXPLORE',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            )),
                      ),
                      Text('Open a section',
                          style: TextStyle(color: muted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.05,
                    children: [
                      _Action('Upgrade Shop', 'Power up every guess',
                          Icons.upgrade_rounded, _purple, onUpgradeShop,
                          panel, line, foreground, muted),
                      _Action('Prestige & Ultra', 'Reset. Rise. Repeat.',
                          Icons.auto_awesome_rounded, _gold, onPrestige,
                          panel, line, foreground, muted),
                      _Action('Arcade', 'Play for bonus rewards',
                          Icons.sports_esports_rounded, _cyan, onArcade,
                          panel, line, foreground, muted),
                      _Action('World Map', 'Challenge the guardians',
                          Icons.public_rounded, _green, onWorldMap,
                          panel, line, foreground, muted),
                      _Action('Nebula Shop', 'Spend your Nebula',
                          Icons.diamond_rounded, const Color(0xFFB7A2FF),
                          onNebulaShop, panel, line, foreground, muted),
                      _Action('Settings', 'Make the game yours',
                          Icons.settings_rounded, muted, onSettings,
                          panel, line, foreground, muted),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _WorldProgress(progression, panel, line, foreground, muted),
                  if (game.isComplete) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loading ? null : onNewGame,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Start another round'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'SAVE SLOT $activeSlot',
                      style: TextStyle(
                        color: muted.withValues(alpha: .7),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreMenuPage extends StatelessWidget {
  const _MoreMenuPage({
    required this.showDeveloperSettings,
    required this.onPrestige,
    required this.onNebulaShop,
    required this.onLegacyPages,
    required this.onSaveSlots,
    required this.onSettings,
    required this.onDeveloperSettings,
  });

  final bool showDeveloperSettings;
  final VoidCallback onPrestige;
  final VoidCallback onNebulaShop;
  final VoidCallback onLegacyPages;
  final VoidCallback onSaveSlots;
  final VoidCallback onSettings;
  final VoidCallback onDeveloperSettings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? _white : const Color(0xFF172039);
    final muted = dark ? _muted : const Color(0xFF65708C);
    final panel = dark ? _panel : Colors.white;

    Widget entry(IconData icon, String title, String subtitle, VoidCallback onTap) {
      return Card(
        color: panel,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: foreground.withValues(alpha: .08)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: Icon(icon, color: _purple),
          title: Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle, style: TextStyle(color: muted, fontSize: 11)),
          trailing: Icon(Icons.chevron_right_rounded, color: muted),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('More Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('More Menu', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text('Your shortcuts, your order.', style: TextStyle(color: muted)),
          const SizedBox(height: 18),
          entry(Icons.auto_awesome_rounded, 'Prestige & Ultra', 'Prestige and Ultra progression', onPrestige),
          entry(Icons.diamond_rounded, 'Nebula Shop', 'Nebula upgrades and items', onNebulaShop),
          entry(Icons.auto_stories_rounded, 'Journey, Rewards & Codex', 'Achievements, rewards and discoveries', onLegacyPages),
          entry(Icons.save_rounded, 'Save Slots', 'Manage your saved games', onSaveSlots),
          entry(Icons.settings_rounded, 'Settings', 'Game preferences', onSettings),
          if (showDeveloperSettings)
            entry(Icons.bug_report_rounded, 'Dev Settings', 'Developer tools', onDeveloperSettings),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem(this.icon, this.label, this.selected, this.onTap);

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? _purple.withValues(alpha: .15) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: selected ? _purple : _muted),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? _white : _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, this.color, this.panel,
      this.line, this.foreground, this.muted);
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 7),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                )),
          ],
        ),
      );
}

class _Wallet extends StatelessWidget {
  const _Wallet(this.state, this.panel, this.raised, this.line,
      this.foreground, this.muted);
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: _gold, size: 17),
                const SizedBox(width: 8),
                Text('YOUR WALLET',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    )),
                const Spacer(),
                Text('${state.moneyEarned} earned',
                    style: const TextStyle(color: _green, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 12),
            Text(state.money.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                )),
            Text('MONEY',
                style: TextStyle(
                  color: muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                )),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(child: _Currency(Icons.auto_awesome_rounded,
                    'PRESTIGE', state.prestige.toString(), _purple,
                    raised, foreground, muted)),
                const SizedBox(width: 7),
                Expanded(child: _Currency(Icons.bolt_rounded,
                    'ULTRA', state.ultra.toString(), _cyan,
                    raised, foreground, muted)),
                const SizedBox(width: 7),
                Expanded(child: _Currency(Icons.diamond_rounded,
                    'NEBULA', state.nebula.toString(),
                    const Color(0xFFB7A2FF), raised, foreground, muted)),
              ],
            ),
          ],
        ),
      );
}

class _Currency extends StatelessWidget {
  const _Currency(this.icon, this.label, this.value, this.color,
      this.background, this.foreground, this.muted);
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
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                )),
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

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('YOUR GUESS',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    )),
                const Spacer(),
                Text('WHOLE NUMBER',
                    style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onGuess(),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter a number',
                      hintStyle: TextStyle(color: muted.withValues(alpha: .75)),
                      filled: true,
                      fillColor: raised,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _purple, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: enabled ? onGuess : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '->',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              completed
                  ? 'You found it! Start another round when you are ready.'
                  : 'Every correct guess earns Money. Build your streak for bigger rewards.',
              style: TextStyle(color: muted, fontSize: 10, height: 1.4),
            ),
          ],
        ),
      );
}

class _Action extends StatelessWidget {
  const _Action(this.title, this.subtitle, this.icon, this.color, this.onTap,
      this.panel, this.line, this.foreground, this.muted);
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
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: line),
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 8,
                            height: 1.2,
                          )),
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

class _WorldProgress extends StatelessWidget {
  const _WorldProgress(this.state, this.panel, this.line,
      this.foreground, this.muted);
  final ProgressionState state;
  final Color panel;
  final Color line;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final count = state.defeatedBosses.length.clamp(0, 4);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: _cyan, size: 18),
              const SizedBox(width: 8),
              Text('WORLD EXPLORATION',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  )),
              const Spacer(),
              Text('$count / 4 bosses',
                  style: TextStyle(color: muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: count / 4,
              minHeight: 7,
              backgroundColor: foreground.withValues(alpha: .08),
              valueColor: const AlwaysStoppedAnimation<Color>(_cyan),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Defeat guardians to unlock new worlds and earn permanent rewards.',
            style: TextStyle(color: muted, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }
}
