import 'package:flutter/material.dart';

import '../data/saves/save_data.dart';
import '../data/saves/save_storage.dart';

typedef SaveSlotSelection = Future<void> Function(int slot);

class SaveSlotsPage extends StatefulWidget {
  const SaveSlotsPage({
    super.key,
    required this.activeSlot,
    required this.onSelect,
  });

  final int activeSlot;
  final SaveSlotSelection onSelect;

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
        slot: SaveStorage.inApplicationDocuments(slot: slot)
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

  Future<void> _duplicate(int sourceSlot) async {
    final emptySlots = <int>[];
    for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      if (slot != sourceSlot && await storage.load() == null && !await storage.hasBackup()) {
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
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Duplicate Slot $sourceSlot'),
          content: DropdownButtonFormField<int>(
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, target), child: const Text('Duplicate')),
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
        SnackBar(content: Text(success ? 'Copied Slot $sourceSlot to Slot $selected.' : 'Could not duplicate this save.')),
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _reset(int slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset Slot $slot?'),
        content: const Text('This permanently deletes the save and its restore backup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = slot);
    try {
      final storage = await SaveStorage.inApplicationDocuments(slot: slot);
      await storage.reset();
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _restore(int slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Restore Slot $slot backup?'),
        content: const Text('The current save will become the backup, so you can switch back if needed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
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
        SnackBar(content: Text(success ? 'Restored Slot $slot backup.' : 'No valid backup could be restored.')),
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Slots')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your saves stay on this device. Choose a slot to continue or manage its backup.'),
          const SizedBox(height: 12),
          for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++)
            FutureBuilder<SaveData?>(
              future: _previews[slot],
              builder: (context, snapshot) {
                final save = snapshot.data;
                final selected = widget.activeSlot == slot;
                final busy = _switching == slot || _working == slot;
                final subtitle = snapshot.connectionState != ConnectionState.done
                    ? 'Checking save…'
                    : save == null
                        ? 'Empty slot'
                        : 'Games won: ${save.gamesWon}';
                return Card(
                  child: ListTile(
                    leading: Icon(selected ? Icons.check_circle : Icons.save_outlined),
                    title: Text('Slot $slot'),
                    subtitle: Text(subtitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (busy)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        else if (selected)
                          const Text('Active'),
                        PopupMenuButton<String>(
                          enabled: _switching == null && _working == null && snapshot.connectionState == ConnectionState.done,
                          onSelected: (action) {
                            switch (action) {
                              case 'duplicate': _duplicate(slot);
                              case 'restore': _restore(slot);
                              case 'reset': _reset(slot);
                            }
                          },
                          itemBuilder: (context) => [
                            if (save != null) const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                            const PopupMenuItem(value: 'restore', child: Text('Restore backup')),
                            if (save != null) const PopupMenuItem(value: 'reset', child: Text('Reset slot')),
                          ],
                        ),
                      ],
                    ),
                    onTap: _switching != null || _working != null || selected || save == null
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
