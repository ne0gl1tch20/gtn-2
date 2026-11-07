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
  late final Map<int, Future<SaveData?>> _previews = {
    for (var slot = 1; slot <= 5; slot++)
      slot: SaveStorage.inApplicationDocuments(slot: slot)
          .then((storage) => storage.load()),
  };

  int? _switching;

  Future<void> _select(int slot) async {
    if (_switching != null) return;
    setState(() => _switching = slot);
    try {
      await widget.onSelect(slot);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _switching = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Slots')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your saves stay on this device. Choose a slot to continue or start a fresh run.'),
          const SizedBox(height: 12),
          for (var slot = 1; slot <= 5; slot++)
            FutureBuilder<SaveData?>(
              future: _previews[slot],
              builder: (context, snapshot) {
                final save = snapshot.data;
                final selected = widget.activeSlot == slot;
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
                    trailing: _switching == slot
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : selected
                            ? const Text('Active')
                            : const Icon(Icons.chevron_right),
                    onTap: _switching != null || selected ? null : () => _select(slot),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
