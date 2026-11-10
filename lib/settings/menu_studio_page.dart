import 'dart:convert';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../design/expressive_widgets.dart';
import 'game_settings.dart';

typedef MenuStudioChanged = Future<void> Function(GameSettings settings);

class MenuStudioPage extends StatefulWidget {
  const MenuStudioPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });
  final GameSettings settings;
  final MenuStudioChanged onChanged;

  @override
  State<MenuStudioPage> createState() => _MenuStudioPageState();
}

class _MenuStudioPageState extends State<MenuStudioPage> {
  late List<String> _order;
  late Map<String, String> _colors;
  bool _saving = false;

  static const _labels = <String, String>{
    'world_map': 'World map',
    'achievements': 'Achievements',
    'live_ops': 'Live events',
    'lua_hub': 'Lua hub',
    'mutators': 'Mutators',
    'talent': 'Talents',
    'relics': 'Relics',
    'home_base': 'Home Base',
    'codex': 'Codex',
    'endgame': 'Endgame',
    'arcade': 'Arcade',
    'stats': 'Statistics',
    'changelog': 'Changelog',
    'settings': 'Settings',
    'about': 'About',
    'staking': 'Lucky Stake',
    'ultra': 'Ultra',
    'prestige': 'Prestige',
    'save_slots': 'Save slots',
    'music': 'Music',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MenuStudioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _load();
  }

  void _load() {
    _order = [...widget.settings.moreScreenOrder];
    _colors = Map.of(widget.settings.moreScreenButtonColors);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final layout = jsonEncode({
      'areas': {for (final id in _order) id: 'more'},
      'orders': {'more': _order},
      'colors': _colors,
    });
    await widget.onChanged(
      widget.settings.copyWith(
        moreScreenOrder: List.unmodifiable(_order),
        moreScreenButtonColors: Map.unmodifiable(_colors),
        webMenuStudioLayout: layout,
      ),
    );
    if (mounted) setState(() => _saving = false);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GtnExpressiveAppBar(titleText: 'Menu Studio'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERSONALIZE',
                  style: TextStyle(
                    color: GtnUiTokens.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Customize buttons',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Reorder the More destinations and assign a color to each entry. The main Play, Worlds, Shop and Arcade tabs remain pinned in this Flutter layout.',
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final id = _order[index];
                final color = _colors[id] ?? '';
                return GtnExpressiveCard(
                  key: ValueKey(id),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: GtnUiTokens.muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _labels[id] ?? id,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        width: 112,
                        child: TextFormField(
                          key: ValueKey('$id-$color'),
                          initialValue: color,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Color',
                            hintText: '#9B7CFF',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final normalized = value.trim().toUpperCase();
                            setState(() {
                              if (normalized.isEmpty) {
                                _colors.remove(id);
                              } else if (RegExp(r'^#[0-9A-F]{6}$')
                                  .hasMatch(normalized)) {
                                _colors[id] = normalized;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: M3EButton.tonal(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _order = [...GameSettings.initial.moreScreenOrder];
                            _colors.clear();
                          }),
                    child: const Text('Reset layout'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: M3EButton.filled(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
