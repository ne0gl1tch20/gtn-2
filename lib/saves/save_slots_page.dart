import 'dart:math';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/game/difficulty_rules.dart';
import '../creative/creative_mode_page.dart';
import '../data/saves/save_data.dart';
import '../data/saves/save_storage.dart';
import '../design/expressive_widgets.dart';
import '../settings/game_settings.dart';

typedef SaveSlotSelection = Future<void> Function(int slot);
typedef SaveSlotPreviewLoader = Future<SaveData?> Function(int slot);

class SaveSlotsPage extends StatefulWidget {
  const SaveSlotsPage({
    super.key,
    required this.activeSlot,
    required this.onSelect,
    this.previewLoader,
  });

  final int activeSlot;
  final SaveSlotSelection onSelect;
  final SaveSlotPreviewLoader? previewLoader;

  @override
  State<SaveSlotsPage> createState() => _SaveSlotsPageState();
}

class _SaveSlotsPageState extends State<SaveSlotsPage> {
  late Map<int, Future<SaveData?>> _previews;
  int? _switching;
  int? _working;

  @override
  void initState() {
    super.initState();
    _refreshPreviews();
  }

  void _refreshPreviews() {
    _previews = {
      for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++)
        slot: widget.previewLoader?.call(slot) ??
            SaveStorage.inApplicationDocuments(slot: slot)
                .then((storage) => storage.load()),
    };
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(_refreshPreviews);
  }

  Future<void> _select(int slot) async {
    if (_switching != null || _working != null) return;
    setState(() => _switching = slot);
    try {
      await widget.onSelect(slot);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _switching = null);
    }
  }

  Future<void> _create(int slot) async {
    final nameController = TextEditingController();
    var difficulty = DifficultyRules.classic;
    var icon = 'default';
    final result =
        await GtnExpressiveDialog.show<
          ({String name, String difficulty, String icon})
        >(
          context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => GtnExpressiveDialog(
              title: Text('Create Slot $slot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GtnExpressiveTextField(
                    controller: nameController,
                    maxLength: 24,
                    decoration: const InputDecoration(
                      labelText: 'Save name (optional)',
                    ),
                  ),
                  GtnExpressiveDropdown<String>(
                    initialValue: difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: [
                      for (final id in DifficultyRules.ids)
                        DropdownMenuItem(
                          value: id,
                          child: Text(DifficultyRules.name(id)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => difficulty = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final id in SaveData.profileIconIds)
                        GtnExpressiveChoiceChip(
                          label: _iconSymbol(id),
                          selected: icon == id,
                          onSelected: (_) => setDialogState(() => icon = id),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                M3EButton.text(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                M3EButton.filled(
                  onPressed: () => Navigator.pop(dialogContext, (
                    name: nameController.text.trim(),
                    difficulty: difficulty,
                    icon: icon,
                  )),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
    nameController.dispose();
    if (result == null || !mounted) return;
    setState(() => _working = slot);
    try {
      final maximum = DifficultyRules.baseRangeMaximum(result.difficulty);
      final save = SaveData(
        secret: Random.secure().nextInt(maximum) + 1,
        attempts: 0,
        gamesWon: 0,
        maximum: maximum,
        settings: GameSettings.initial.copyWith(
          difficultyId: result.difficulty,
        ),
        profileName: result.name,
        profileIconId: result.icon,
      );
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      final created = await storage.createIfEmpty(save);
      if (!created) {
        throw StateError(
          'This slot is no longer empty or contains recoverable data.',
        );
      }
      await _refresh();
      await widget.onSelect(slot);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create this save: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _editProfile(int slot) async {
    final storage = await SaveStorage.inApplicationDocuments(slot: slot);
    final current = await storage.load();
    if (current == null || !mounted) return;
    final nameController = TextEditingController(text: current.profileName);
    var icon = current.profileIconId;
    final result = await GtnExpressiveDialog.show<({String name, String icon})>(
      context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => GtnExpressiveDialog(
          title: Text('Edit Slot $slot Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GtnExpressiveTextField(
                controller: nameController,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Save name'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final id in SaveData.profileIconIds)
                    GtnExpressiveChoiceChip(
                      label: _iconSymbol(id),
                      selected: icon == id,
                      onSelected: (_) => setDialogState(() => icon = id),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            M3EButton.text(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            M3EButton.filled(
              onPressed: () => Navigator.pop(dialogContext, (
                name: nameController.text.trim(),
                icon: icon,
              )),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result == null || !mounted) return;
    setState(() => _working = slot);
    try {
      await storage.update((latest) {
        if (latest == null) {
          throw StateError('The save disappeared while editing its profile.');
        }
        return latest.copyWith(
          profileName: result.name,
          profileIconId: result.icon,
        );
      });
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  String _iconSymbol(String id) => switch (id) {
    'star' => '⭐',
    'bolt' => '⚡',
    'crown' => '👑',
    'planet' => '🪐',
    _ => '🎮',
  };

  Future<void> _openCreativeMode(int slot) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => CreativeModePage(slot: slot)),
    );
    await _refresh();
  }

  Future<void> _duplicate(int sourceSlot) async {
    final emptySlots = <int>[];
    for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      if (slot != sourceSlot &&
          await storage.load() == null &&
          !await storage.hasBackup()) {
        emptySlots.add(slot);
      }
    }
    if (!mounted) return;
    if (emptySlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No empty save slots are available.')),
      );
      return;
    }
    var target = emptySlots.first;
    final selected = await GtnExpressiveDialog.show<int>(
      context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => GtnExpressiveDialog(
          title: Text('Duplicate Slot $sourceSlot'),
          content: GtnExpressiveDropdown<int>(
            initialValue: target,
            decoration: const InputDecoration(labelText: 'Copy into'),
            items: [
              for (final slot in emptySlots)
                DropdownMenuItem(value: slot, child: Text('Slot $slot')),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => target = value);
            },
          ),
          actions: [
            M3EButton.text(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            M3EButton.filled(
              onPressed: () => Navigator.pop(dialogContext, target),
              child: const Text('Duplicate'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _working = sourceSlot);
    try {
      final source = await SaveStorage.inApplicationDocuments(slot: sourceSlot);
      final success = await source.duplicateTo(selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Copied Slot $sourceSlot to Slot $selected.'
                : 'Could not duplicate this save.',
          ),
        ),
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _reset(int slot) async {
    final confirmed = await GtnExpressiveDialog.show<bool>(
      context,
      builder: (dialogContext) => GtnExpressiveDialog(
        title: Text('Reset Slot $slot?'),
        content: const Text(
          'This permanently deletes the save and its restore backup.',
        ),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          M3EButton.filled(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = slot);
    try {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      await storage.reset();
      if (slot == widget.activeSlot) {
        await widget.onSelect(slot);
      }
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _restore(int slot) async {
    final confirmed = await GtnExpressiveDialog.show<bool>(
      context,
      builder: (dialogContext) => GtnExpressiveDialog(
        title: Text('Restore Slot $slot backup?'),
        content: const Text(
          'The current save will become the backup, so you can switch back if needed.',
        ),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          M3EButton.filled(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = slot);
    try {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      final success = await storage.restoreBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Restored Slot $slot backup.'
                : 'No valid backup could be restored.',
          ),
        ),
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('Save Slots')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your saves stay on this device. Choose a slot to continue or manage its backup.',
          ),
          const SizedBox(height: 12),
          for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++)
            FutureBuilder<SaveData?>(
              future: _previews[slot],
              builder: (context, snapshot) {
                final save = snapshot.data;
                final selected = widget.activeSlot == slot;
                final busy = _switching == slot || _working == slot;
                final readFailed = snapshot.hasError;
                final subtitle =
                    snapshot.connectionState != ConnectionState.done
                    ? 'Checking save…'
                    : readFailed
                    ? 'Could not read save. Your data was not changed.'
                    : save == null
                    ? 'Empty slot'
                    : 'Games won: ${save.gamesWon}';
                return GtnExpressiveCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        save == null
                            ? '$slot'
                            : _iconSymbol(save.profileIconId),
                      ),
                    ),
                    title: Text(
                      save?.profileName.isNotEmpty == true
                          ? save!.profileName
                          : 'Slot $slot',
                    ),
                    subtitle: Text(subtitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (busy)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: M3EProgressIndicator.circular(
                              strokeWidth: 2,
                            ),
                          )
                        else if (selected)
                          const Text('Active'),
                        PopupMenuButton<String>(
                          enabled:
                              _switching == null &&
                              _working == null &&
                              snapshot.connectionState == ConnectionState.done &&
                              !readFailed,
                          onSelected: (action) {
                            switch (action) {
                              case 'creative':
                                _openCreativeMode(slot);
                              case 'create':
                                _create(slot);
                              case 'profile':
                                _editProfile(slot);
                              case 'duplicate':
                                _duplicate(slot);
                              case 'restore':
                                _restore(slot);
                              case 'reset':
                                _reset(slot);
                            }
                          },
                          itemBuilder: (context) => [
                            if (save == null)
                              const PopupMenuItem(
                                value: 'create',
                                child: Text('Create save'),
                              ),
                            if (save != null)
                              const PopupMenuItem(
                                value: 'creative',
                                child: Text('Creative Mode'),
                              ),
                            if (save != null)
                              const PopupMenuItem(
                                value: 'profile',
                                child: Text('Edit profile'),
                              ),
                            if (save != null)
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                            const PopupMenuItem(
                              value: 'restore',
                              child: Text('Restore backup'),
                            ),
                            if (save != null)
                              const PopupMenuItem(
                                value: 'reset',
                                child: Text('Reset slot'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap:
                        _switching != null ||
                            _working != null ||
                            selected ||
                            save == null
                        ? null
                        : () => _select(slot),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
