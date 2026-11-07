import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/legacy/builtin_trait_catalog.dart';
import '../core/legacy/legacy_systems_engine.dart';
import '../core/legacy/legacy_systems_state.dart';
import '../core/numbers/big_number.dart';
import '../core/progression/progression_state.dart';
import '../data/updates/update_checker.dart';

typedef LegacyProgressionChanged = Future<void> Function(ProgressionState progression);

class LegacySystemsPage extends StatefulWidget {
  const LegacySystemsPage({
    super.key,
    required this.progression,
    required this.onChanged,
  });

  final ProgressionState progression;
  final LegacyProgressionChanged onChanged;

  @override
  State<LegacySystemsPage> createState() => _LegacySystemsPageState();
}

class _LegacySystemsPageState extends State<LegacySystemsPage> {
  final LegacySystemsEngine _engine = const LegacySystemsEngine();
  final TextEditingController _stakeController = TextEditingController();
  late ProgressionState _progression = widget.progression;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _trackCompleteSubscription;
  bool _isPlaying = false;
  bool _checkingUpdate = false;
  String? _updateMessage;
  String? _updateDetails;
  UpdateRelease? _availableUpdate;
  WindowsUpdateRelease? _availableWindowsUpdate;
  List<Map<String, dynamic>> _talentCatalog = [];
  List<Map<String, dynamic>> _mutatorCatalog = [];
  List<Map<String, dynamic>> _relicCatalog = [];

  LegacySystemsState get _systems => _progression.legacySystems;

  @override
  void initState() {
    super.initState();
    _loadSystemCatalogs();
    _trackCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _playNextTrack();
    });
  }

  @override
  void didUpdateWidget(covariant LegacySystemsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progression != widget.progression) {
      _progression = widget.progression;
    }
  }

  Future<void> _apply(LegacyActionResult result) async {
    if (!result.accepted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message.isEmpty ? 'Action rejected.' : result.message)),
        );
      }
      return;
    }
    final next = result.progression.copyWith(legacySystems: result.systems);
    setState(() => _progression = next);
    await widget.onChanged(next);
  }

  Future<void> _saveSystems(LegacySystemsState systems) async {
    final next = _progression.copyWith(legacySystems: systems);
    setState(() => _progression = next);
    await widget.onChanged(next);
  }

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  @override
  void dispose() {
    _stakeController.dispose();
    _trackCompleteSubscription?.cancel();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traitState = _engine.evaluateTraits(
      progression: _progression,
      systems: _systems,
      playerLevel: 1,
      activeSeasonId: _seasonId(DateTime.now()),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('GTN 1 Systems')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legacy systems', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text('Persistent gameplay systems ported from the original Kotlin game. Purchases and rewards are validated by the Dart engine.'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip('Traits', '${traitState.activeTraitIds.length}/320'),
                      _statChip('Talents', '${_systems.talents.length}/6'),
                      _statChip('Relics', '${_systems.equippedRelics.length}/4'),
                      _statChip('Sanctuary', 'Lv ${_systems.homeBaseLevel}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _traitsSection(traitState),
          _talentsSection(),
          _mutatorsSection(),
          _relicsSection(),
          _homeBaseSection(),
          _stakeSection(),
          _dailySection(),
          _lootSection(),
          _musicSection(),
          _aboutSection(),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) => Chip(
    label: Text('$label · $value'),
    visualDensity: VisualDensity.compact,
  );

  Widget _traitsSection(TraitEffectSummary traits) {
    final sorted = [...builtInTraitCatalog]
      ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.auto_awesome_rounded),
        title: const Text('Traits'),
        subtitle: Text('${traits.activeTraitIds.length} active · ${_systems.discoveredTraits.length} discovered'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Trait activation is automatic. Hidden traits are discovered through their requirements. Effects are bounded by the original trait runtime.'),
          ),
          SizedBox(
            height: 360,
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final item = sorted[index];
                final id = item['id']! as String;
                final hidden = item['visibility'] == 'HIDDEN';
                final discovered = _systems.discoveredTraits.contains(id);
                final active = traits.activeTraitIds.contains(id);
                final visible = !hidden || discovered;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    active ? Icons.check_circle_rounded : hidden && !discovered ? Icons.lock_outline_rounded : Icons.circle_outlined,
                    color: active ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(visible ? _pretty(id) : 'Undiscovered trait'),
                  subtitle: Text('${item['category']} · ${item['effect']}'),
                  trailing: active ? const Text('ACTIVE') : null,
                );
              },
            ),
          ),
          for (final entry in LegacySystemsEngine.gameplayArms.entries)
            if (traits.activeTraitIds.contains(entry.key))
              ListTile(
                title: Text('${_pretty(entry.key)} strategy'),
                subtitle: const Text('Choose how this gameplay trait behaves.'),
                trailing: DropdownButton<String>(
                  value: _systems.selectedTraitArms[entry.key] ?? entry.value.first,
                  items: [
                    for (final arm in entry.value)
                      DropdownMenuItem<String>(
                        value: arm,
                        child: Text(_pretty(arm)),
                      ),
                  ],
                  onChanged: (arm) {
                    if (arm != null) {
                      _apply(_engine.selectTraitArm(
                        progression: _progression,
                        systems: _systems,
                        traitId: entry.key,
                        armId: arm,
                        playerLevel: 1,
                        activeSeasonId: _seasonId(DateTime.now()),
                      ));
                    }
                  },
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _loadSystemCatalogs() async {
    try {
      final talents = jsonDecode(await rootBundle.loadString('assets/game/talents.json')) as Map<String, dynamic>;
      final mutators = jsonDecode(await rootBundle.loadString('assets/game/mutators.json')) as Map<String, dynamic>;
      final relics = jsonDecode(await rootBundle.loadString('assets/game/relics.json')) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _talentCatalog = (talents['talents'] as List).cast<Map<String, dynamic>>();
        _mutatorCatalog = (mutators['mutators'] as List).cast<Map<String, dynamic>>();
        _relicCatalog = (relics['relics'] as List).cast<Map<String, dynamic>>();
      });
    } on Exception {
      // Keep the deterministic built-in fallback catalogs available offline.
    }
  }

  Widget _talentsSection() {
    final talents = _talentCatalog.isNotEmpty
        ? _talentCatalog
        : LegacySystemsEngine.talents.entries.map((entry) => <String, dynamic>{
            'id': entry.key,
            'name': _pretty(entry.key),
            'description': 'Unlock this permanent talent.',
            'cost': entry.value.cost,
            'requiredParentId': entry.value.parent,
          }).toList();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.account_tree_rounded),
        title: const Text('Talent tree'),
        subtitle: Text('${_systems.talents.length} / 6 unlocked · ${_progression.prestige} Prestige'),
        children: [
          for (final talent in talents)
            Builder(builder: (context) {
              final id = talent['id'] as String;
              final name = talent['name'] as String? ?? _pretty(id);
              final description = talent['description'] as String? ?? '';
              final cost = talent['cost'] as int;
              final parent = talent['requiredParentId'] as String?;
              final owned = _systems.talents.contains(id);
              final parentReady = parent == null || _systems.talents.contains(parent);
              return ListTile(
                title: Text(name),
                subtitle: Text('$description\\nCost: $cost Prestige${parent == null ? '' : ' · Requires ${_pretty(parent)}'}'),
                isThreeLine: true,
                trailing: owned
                    ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                    : FilledButton(
                        onPressed: parentReady ? () => _apply(_engine.buyTalent(_progression, _systems, id)) : null,
                        child: const Text('Unlock'),
                      ),
              );
            }),
        ],
      ),
    );
  }

  Widget _mutatorsSection() {
    final mutators = _mutatorCatalog.isNotEmpty
        ? _mutatorCatalog
        : const [
            {'id': 'mut_hardcore', 'name': 'Hardcore Range', 'description': 'Double the guessing range. Rewards ×2.'},
            {'id': 'mut_speed', 'name': 'Hyper Speed', 'description': 'Auto-clicker speed ×3, but earnings halved.'},
            {'id': 'mut_blind', 'name': 'Blindfolded Oracle', 'description': 'Hide higher/lower feedback. Rewards ×5.'},
            {'id': 'mut_tax', 'name': 'Heavy Taxation', 'description': 'Wrong guesses cost 5% of current Money. Rewards ×10.'},
          ];
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune_rounded),
        title: const Text('Mutators & challenge builder'),
        subtitle: Text('Reward multiplier ×${_engine.mutatorRewardMultiplier(_systems)}'),
        children: [
          for (final mutator in mutators)
            SwitchListTile(
              title: Text(mutator['name'] as String),
              subtitle: Text(mutator['description'] as String),
              value: _systems.activeMutators.contains(mutator['id']),
              onChanged: (value) => _apply(_engine.setMutator(_progression, _systems, mutator['id'] as String, value)),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Custom and weekly challenge rewards are claim-once transactions. Challenge objective tracking is connected to the save model.'),
          ),
        ],
      ),
    );
  }

  Widget _relicsSection() {
    final relics = _relicCatalog.isNotEmpty
        ? _relicCatalog
        : const [
            {'id': 'verdant_guardian', 'name': 'Heartwood Sigil', 'description': 'Verdant Guardian relic.', 'unlockBossName': 'Verdant Guardian'},
            {'id': 'crystal_golem', 'name': 'Prism Core', 'description': 'Crystal Golem relic.', 'unlockBossName': 'Crystal Golem'},
            {'id': 'ember_dragon', 'name': 'Ember Scale', 'description': 'Ember Dragon relic.', 'unlockBossName': 'Ember Dragon'},
            {'id': 'nebula_titan', 'name': 'Starbound Fragment', 'description': 'Nebula Titan relic.', 'unlockBossName': 'Nebula Titan'},
          ];
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.diamond_rounded),
        title: const Text('Relic collection'),
        subtitle: Text('${_systems.relicInventory.length}/4 discovered · ${_systems.equippedRelics.length}/4 equipped'),
        children: [
          for (final relic in relics)
            Builder(builder: (context) {
              final id = relic['id'] as String;
              final owned = _systems.relicInventory.contains(id);
              final equipped = _systems.equippedRelics.contains(id);
              return ListTile(
                leading: Icon(owned ? Icons.diamond_rounded : Icons.lock_outline_rounded),
                title: Text(relic['name'] as String),
                subtitle: Text('${relic['description']}\\nEarned from ${relic['unlockBossName']}'),
                isThreeLine: true,
                trailing: FilledButton.tonal(
                  onPressed: owned ? () => _apply(_engine.equipRelic(_progression, _systems, id)) : null,
                  child: Text(equipped ? 'Unequip' : 'Equip'),
                ),
              );
            }),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Set bonus: 2 relics +10%, 3 relics +20%, 4 relics +35% Money. Individual relic bonuses are applied by the backend.'),
          ),
        ],
      ),
    );
  }
  Widget _homeBaseSection() {
    final level = _systems.homeBaseLevel;
    final cost = BigNumber.fromInt(50000 * (level + 1));
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.home_work_rounded),
        title: const Text('Home Base'),
        subtitle: Text('Sanctuary level $level / 20 · +${level * 2}% Money'),
        children: [
          for (final milestone in const [(1, 'Portal Chamber'), (3, 'Relic Forge'), (5, 'Star Archive'), (10, 'Cosmic Observatory')])
            ListTile(
              leading: Icon(level >= milestone.$1 ? Icons.check_circle_rounded : Icons.lock_outline_rounded),
              title: Text(milestone.$2),
              subtitle: Text('Unlocks at level ${milestone.$1}'),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: level < 20 && _progression.money.compareTo(cost) >= 0
                  ? () => _apply(_engine.upgradeHomeBase(_progression, _systems))
                  : null,
              child: Text(level >= 20 ? 'Fully restored' : 'Restore next level · $cost Money'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stakeSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.casino_rounded),
        title: const Text('Lucky Stake'),
        subtitle: Text('Wins: ${_systems.stakesWon} · Losses: ${_systems.stakesLost}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _stakeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stake amount', prefixText: 'Money '),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: () {
                BigNumber stake;
                try {
                  stake = BigNumber.parse(_stakeController.text.trim());
                } on FormatException {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid stake.')));
                  return;
                }
                final result = _engine.settleLuckyStake(
                  progression: _progression,
                  systems: _systems,
                  stake: stake,
                  won: Random.secure().nextBool(),
                  currentStreak: _progression.currentStreak,
                );
                _apply(result);
                _stakeController.clear();
              },
              child: const Text('Flip 50/50'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailySection() {
    final daily = _systems.dailyQuestDate == _today ? _systems : _systems.copyWith(
      dailyQuestDate: _today,
      dailyQuestGuesses: 0,
      dailyQuestCorrectGuesses: 0,
      dailyQuestBestStreak: 0,
      dailyQuestUpgradePurchases: 0,
      claimedDailyQuests: const {},
    );
    const quests = <(String, String, int)>[
      ('daily_guesses_10', 'Make 10 guesses', 10),
      ('daily_correct_5', 'Get 5 correct guesses', 5),
      ('daily_streak_5', 'Reach a streak of 5', 5),
      ('daily_upgrades_3', 'Buy 3 upgrades', 3),
    ];
    final progress = <String, int>{
      'daily_guesses_10': daily.dailyQuestGuesses,
      'daily_correct_5': daily.dailyQuestCorrectGuesses,
      'daily_streak_5': daily.dailyQuestBestStreak,
      'daily_upgrades_3': daily.dailyQuestUpgradePurchases,
    };
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_month_rounded),
        title: const Text('Daily rewards & quests'),
        subtitle: Text('Reward streak: ${_systems.dailyRewardStreak} days'),
        children: [
          ListTile(
            title: const Text('Daily login reward'),
            subtitle: Text(_systems.lastDailyRewardDate == _today ? 'Claimed today' : 'Claim your daily Nebula'),
            trailing: FilledButton(
              onPressed: _systems.lastDailyRewardDate == _today
                  ? null
                  : () => _apply(_engine.claimDailyReward(
                        progression: _progression,
                        systems: _systems,
                        today: _today,
                        traitNebulaBonus: _engine.evaluateTraits(
                          progression: _progression,
                          systems: _systems,
                          playerLevel: 1,
                          activeSeasonId: _seasonId(DateTime.now()),
                        ).nebulaBonusPerClaim,
                        nebulaBoostOwned: (_progression.nebulaItems['nebula_boost'] ?? 0) > 0,
                      )),
              child: const Text('Claim'),
            ),
          ),
          for (final quest in quests)
            ListTile(
              title: Text(quest.$2),
              subtitle: Text('${progress[quest.$1]} / ${quest.$3}'),
              trailing: FilledButton.tonal(
                onPressed: progress[quest.$1]! >= quest.$3 && !daily.claimedDailyQuests.contains(quest.$1)
                    ? () => _apply(_engine.claimDailyQuest(
                          progression: _progression,
                          systems: daily,
                          questId: quest.$1,
                          today: _today,
                          nebulaBoostOwned: (_progression.nebulaItems['nebula_boost'] ?? 0) > 0,
                        ))
                    : null,
                child: Text(daily.claimedDailyQuests.contains(quest.$1) ? 'Claimed' : 'Claim'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _lootSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.inventory_2_rounded),
        title: const Text('Loot chests'),
        subtitle: Text('Opened: ${_systems.lootChestsOpened}'),
        children: [
          for (final tier in const ['common', 'rare', 'epic'])
            ListTile(
              title: Text('${_pretty(tier)} chest'),
              subtitle: Text('Owned: ${_systems.lootChests[tier] ?? 0}'),
              trailing: FilledButton.tonal(
                onPressed: (_systems.lootChests[tier] ?? 0) > 0
                    ? () => _apply(_engine.openLootChest(
                          progression: _progression,
                          systems: _systems,
                          tier: tier,
                          rewardNebula: Random.secure().nextBool(),
                        ))
                    : null,
                child: const Text('Open'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _importMusicTracks() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final directory = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory('${directory.path}/music');
    await musicDirectory.create(recursive: true);
    final imported = <String>[];
    for (final track in picked.files) {
      final bytes = track.bytes;
      if (bytes == null || bytes.isEmpty || bytes.length > 100 * 1024 * 1024) {
        continue;
      }
      final extension = track.extension?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') ?? 'audio';
      final safeName = 'track_${DateTime.now().microsecondsSinceEpoch}_${imported.length}.$extension';
      final destination = File('${musicDirectory.path}/$safeName');
      await destination.writeAsBytes(bytes, flush: true);
      imported.add(destination.path);
    }
    if (imported.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No supported audio files could be imported.')),
        );
      }
      return;
    }
    await _saveSystems(_systems.copyWith(
      musicLibrary: List.unmodifiable({..._systems.musicLibrary, ...imported}),
      musicQueue: List.unmodifiable({..._systems.musicQueue, ...imported}),
      currentTrackId: _systems.currentTrackId ?? imported.first,
    ));
    await _playTrack(imported.first);
  }

  Future<void> _playTrack(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
      if (!mounted) return;
      setState(() => _isPlaying = true);
      await _saveSystems(_systems.copyWith(currentTrackId: path));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play this track: $error')),
        );
      }
    }
  }

  Future<void> _playNextTrack() async {
    if (!mounted || _systems.musicQueue.isEmpty) {
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    final queue = _systems.musicQueue;
    final currentIndex = queue.indexOf(_systems.currentTrackId ?? '');
    if (_systems.musicRepeatMode == 'one' && currentIndex >= 0) {
      await _playTrack(queue[currentIndex]);
      return;
    }
    var nextIndex = currentIndex + 1;
    if (_systems.musicShuffle && queue.length > 1) {
      final choices = List<int>.generate(queue.length, (index) => index)
        ..remove(currentIndex);
      nextIndex = choices[Random.secure().nextInt(choices.length)];
    }
    if (nextIndex >= queue.length) {
      if (_systems.musicRepeatMode != 'all') {
        setState(() => _isPlaying = false);
        return;
      }
      nextIndex = 0;
    }
    await _playTrack(queue[nextIndex]);
  }

  Future<void> _toggleMusicPlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    final current = _systems.currentTrackId;
    if (current != null && File(current).existsSync()) {
      await _audioPlayer.resume();
      if (mounted) setState(() => _isPlaying = true);
    } else if (_systems.musicQueue.isNotEmpty) {
      await _playTrack(_systems.musicQueue.first);
    } else {
      await _importMusicTracks();
    }
  }

  Future<void> _createPlaylist() async {
    if (_systems.musicLibrary.isEmpty) {
      await _importMusicTracks();
      if (_systems.musicLibrary.isEmpty) return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || _systems.musicPlaylists.containsKey(name)) return;
    final playlists = Map<String, List<String>>.of(_systems.musicPlaylists)
      ..[name] = List<String>.unmodifiable(_systems.musicLibrary);
    await _saveSystems(_systems.copyWith(musicPlaylists: Map.unmodifiable(playlists)));
  }

  Future<void> _playPlaylist(List<String> tracks) async {
    final valid = tracks.where((track) => _systems.musicLibrary.contains(track) && File(track).existsSync()).toList();
    if (valid.isEmpty) return;
    await _saveSystems(_systems.copyWith(
      musicQueue: List<String>.unmodifiable(valid),
      currentTrackId: valid.first,
    ));
    await _playTrack(valid.first);
  }

  Future<void> _deletePlaylist(String name) async {
    final playlists = Map<String, List<String>>.of(_systems.musicPlaylists)..remove(name);
    await _saveSystems(_systems.copyWith(musicPlaylists: Map.unmodifiable(playlists)));
  }
  Widget _musicSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.library_music_rounded),
        title: const Text('Offline music player'),
        subtitle: Text('${_systems.musicLibrary.length} tracks · ${_systems.musicPlaylists.length} playlists'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _systems.currentTrackId == null
                        ? 'No track selected'
                        : _systems.currentTrackId!.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Previous track',
                  onPressed: _systems.musicQueue.isEmpty ? null : () async {
                    final index = _systems.musicQueue.indexOf(_systems.currentTrackId ?? '');
                    final previous = (index - 1 + _systems.musicQueue.length) % _systems.musicQueue.length;
                    await _playTrack(_systems.musicQueue[previous]);
                  },
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton(
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                  onPressed: _toggleMusicPlayback,
                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                IconButton(
                  tooltip: 'Next track',
                  onPressed: _systems.musicQueue.isEmpty ? null : _playNextTrack,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: FilledButton.tonalIcon(
              onPressed: _importMusicTracks,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Import audio files'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: FilledButton.tonalIcon(
              onPressed: _createPlaylist,
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('Create playlist from library'),
            ),
          ),
          for (final playlist in _systems.musicPlaylists.entries)
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(playlist.key),
              subtitle: Text('${playlist.value.length} tracks'),
              onTap: () => _playPlaylist(playlist.value),
              trailing: IconButton(
                tooltip: 'Delete playlist',
                onPressed: () => _deletePlaylist(playlist.key),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          SwitchListTile(
            title: const Text('Shuffle'),
            value: _systems.musicShuffle,
            onChanged: (value) => _saveSystems(_systems.copyWith(musicShuffle: value)),
          ),
          ListTile(
            title: const Text('Repeat mode'),
            subtitle: Text(_systems.musicRepeatMode.toUpperCase()),
            trailing: DropdownButton<String>(
              value: _systems.musicRepeatMode,
              items: const [
                DropdownMenuItem(value: 'off', child: Text('Off')),
                DropdownMenuItem(value: 'one', child: Text('One')),
                DropdownMenuItem(value: 'all', child: Text('All')),
              ],
              onChanged: (value) {
                if (value != null) _saveSystems(_systems.copyWith(musicRepeatMode: value));
              },
            ),
          ),
          for (final track in _systems.musicLibrary)
            ListTile(
              dense: true,
              leading: const Icon(Icons.music_note_rounded),
              title: Text(track.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: 'Play track',
                onPressed: () => _playTrack(track),
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline_rounded),
        title: const Text('About & updater'),
        subtitle: Text('Version ${UpdateChecker.currentVersionName} · Flutter / Dart'),
        children: [
          const ListTile(
            title: Text('Guess The Number 2'),
            subtitle: Text('Flutter continuation of the original Kotlin game. Offline-first local saves.'),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded),
            title: const Text('Check for updates'),
            subtitle: Text(_updateMessage ?? 'Check the GitHub release feed for a newer build.'),
            trailing: _checkingUpdate
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            onTap: _checkingUpdate ? null : _checkForUpdate,
          ),
          if (_updateDetails != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_updateDetails!),
            ),
          if (_availableUpdate != null || _availableWindowsUpdate != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SelectableText('SHA-256: ${_availableUpdate?.sha256 ?? _availableWindowsUpdate!.sha256}'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FilledButton.icon(
                onPressed: _checkingUpdate ? null : _downloadAndInstallUpdate,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download and install update'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextButton(
                onPressed: () => _openGithubUrl(_availableUpdate?.releaseUrl ?? _availableWindowsUpdate!.releaseUrl),
                child: const Text('View release notes'),
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Open-source licenses'),
            subtitle: const Text('View notices for Flutter and bundled packages.'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Guess The Number 2',
              applicationVersion: UpdateChecker.currentVersionName,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Source repository'),
            onTap: () => _openGithubUrl('https://github.com/ne0gl1tch20/gtn-2'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text('Debug updates are published to the GitHub debug-latest release after both Android and Windows builds succeed. Android APK downloads are SHA-256 verified before opening the package installer. Windows packages are available from the same release.'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateMessage = 'Checking debug-latest…';
      _updateDetails = null;
      _availableUpdate = null;
      _availableWindowsUpdate = null;
    });
    try {
      if (Platform.isWindows) {
        final update = await UpdateChecker().checkForWindowsUpdate();
        if (!mounted) return;
        setState(() {
          _availableWindowsUpdate = update;
          _availableUpdate = null;
          _updateDetails = update == null
              ? 'This Windows build is up to date.'
              : 'Windows ${update.versionName} · debug-latest #${update.runNumber}\\nCommit: ${update.commitSha}';
          _updateMessage = update == null
              ? 'You are up to date.'
              : 'A verified Windows update is available.';
        });
      } else if (Platform.isAndroid) {
        final update = await UpdateChecker().checkForUpdate();
        if (!mounted) return;
        setState(() {
          _availableUpdate = update;
          _availableWindowsUpdate = null;
          _updateDetails = update == null
              ? 'This Android build is up to date.'
              : 'Android ${update.versionName} (${update.versionCode}) · debug-latest #${update.runNumber}\\nCommit: ${update.commitSha}';
          _updateMessage = update == null
              ? 'You are up to date.'
              : 'A verified Android update is available.';
        });
      } else {
        throw UnsupportedError('In-app updates are available on Android and Windows builds.');
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _updateMessage = message.contains('404')
            ? 'No debug-latest release has been published yet.'
            : 'Update check failed: $error';
      });
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _downloadAndInstallUpdate() async {
    final update = _availableUpdate;
    final windowsUpdate = _availableWindowsUpdate;
    if (update == null && windowsUpdate == null) return;
    setState(() {
      _checkingUpdate = true;
      _updateMessage = 'Downloading and verifying update…';
    });
    try {
      if (Platform.isWindows && windowsUpdate != null) {
        await UpdateChecker().downloadAndInstallWindowsUpdate(windowsUpdate);
      } else if (Platform.isAndroid && update != null) {
        await UpdateChecker().downloadAndInstall(update);
        if (mounted) {
          setState(() => _updateMessage =
              'APK verified. Android package installer opened; follow its prompts to finish.');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _updateMessage = 'Update installation could not start: $error');
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  bool _isGithubUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' &&
        {'github.com', 'api.github.com', 'raw.githubusercontent.com'}.contains(uri.host);
  }

  Future<void> _openGithubUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !_isGithubUrl(value)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _seasonId(DateTime date) => switch (date.month) {
    12 || 1 || 2 => 'winter',
    3 || 4 || 5 => 'spring',
    6 || 7 || 8 => 'summer',
    _ => 'autumn',
  };

  String _pretty(String id) => id
      .replaceAll('mut_', '')
      .replaceAll('talent_', '')
      .split(RegExp(r'[_-]'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
