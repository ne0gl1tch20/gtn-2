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
    required this.gamesWon,
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
    this.showDeveloperSettings = false,
  });

  final GameState game;
  final ProgressionState progression;
  final int gamesWon;
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
  final bool showDeveloperSettings;

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
                        child: const Icon(Icons.casino_rounded,
                            color: Colors.white, size: 25),
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
                            Text('Game Center',
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                )),
                          ],
                        ),
                      ),
                      _TopButton(Icons.save_rounded, 'Save slots', onSaveSlots,
                          foreground),
                      const SizedBox(width: 5),
                      _TopButton(Icons.tune_rounded, 'Settings', onSettings,
                          foreground),
                      if (showDeveloperSettings) ...[
                        const SizedBox(width: 5),
                        _TopButton(Icons.bug_report_rounded,
                            'Developer settings', onDeveloperSettings,
                            foreground),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
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
                                  'YOUR NEXT NUMBER IS WAITING',
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
                            Text('Find your\nsecret number',
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 28,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                )),
                            const SizedBox(height: 9),
                            const Text('RANGE  1 — 100',
                                style: TextStyle(
                                  color: _cyan,
                                  fontSize: 13,
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
                      const SizedBox(width: 9),
                      Expanded(child: _Stat(Icons.emoji_events_rounded,
                          gamesWon.toString(), 'GAMES WON', _gold,
                          panel, line, foreground, muted)),
                      const SizedBox(width: 9),
                      Expanded(child: _Stat(Icons.local_fire_department_rounded,
                          progression.currentStreak.toString(), 'STREAK', _green,
                          panel, line, foreground, muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Wallet(progression, panel, raised, line, foreground, muted),
                  const SizedBox(height: 12),
                  _GuessInput(
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
                        child: Text('YOUR JOURNEY',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            )),
                      ),
                      Text('Explore the game',
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
                      'SAVE SLOT $activeSlot,
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

class _TopButton extends StatelessWidget {
  const _TopButton(this.icon, this.tooltip, this.onTap, this.foreground);
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color foreground;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: foreground.withValues(alpha: .07),
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: foreground.withValues(alpha: .08)),
          ),
        ),
        icon: Icon(icon, size: 19),
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
                Text('MAKE YOUR GUESS',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    )),
                const Spacer(),
                Text('1 TO 100',
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
                    child: const Row(
                      children: [
                        Text('GUESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            )),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 17),
                      ],
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
