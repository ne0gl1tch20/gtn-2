import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../design/expressive_widgets.dart';
import '../design/gtn_color_picker_dialog.dart';
import 'game_settings.dart';
import 'menu_studio_layout.dart';

typedef MenuStudioChanged = Future<void> Function(GameSettings settings);

class MenuStudioPage extends StatefulWidget {
  const MenuStudioPage({
    super.key,
    required this.settings,
    required this.onChanged,
    this.onPreview,
    this.onCancel,
  });

  final GameSettings settings;
  final MenuStudioChanged onChanged;
  final ValueChanged<GameSettings>? onPreview;
  final VoidCallback? onCancel;

  @override
  State<MenuStudioPage> createState() => _MenuStudioPageState();
}

class _MenuStudioPageState extends State<MenuStudioPage> {
  late MenuStudioLayout _layout;
  bool _saving = false;
  bool _allowPop = false;

  static const _labels = <String, String>{
    'worlds': 'Worlds',
    'arcade': 'Arcade',
    'upgrades': 'Upgrades',
    'rewards': 'Rewards',
    'journey': 'Journey',
    'shop': 'Shop',
    'homebase': 'Home Base',
    'relics': 'Relics',
    'codex': 'Codex',
    'changelog': 'Changelog',
    'about': 'About',
    'music': 'Background Music',
    'settings': 'Settings',
    'prestige': 'Prestige',
    'ultra': 'Ultra',
    'talent': 'Talents',
    'traits': 'Traits',
    'mutators': 'Mutators',
    'stats': 'Stats',
    'dev_settings': 'Dev Settings',
    'stake': 'Lucky Stake',
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
    _layout = MenuStudioLayout.fromSettings(widget.settings);
  }

  GameSettings _settingsForLayout() => widget.settings.copyWith(
    moreScreenOrder: List.unmodifiable(_layout.settingsMoreOrder),
    moreScreenButtonColors: Map.unmodifiable(_layout.settingsColors),
    webMenuStudioLayout: _layout.encode(),
  );

  void _preview() => widget.onPreview?.call(_settingsForLayout());

  void _cancel() {
    if (_saving || _allowPop) return;
    widget.onCancel?.call();
    setState(() => _allowPop = true);
    if (!Navigator.of(context).canPop()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _move(String id, String targetArea) {
    final currentArea = _layout.areas[id] ?? 'more';
    if (currentArea == targetArea) return;

    final areas = Map<String, String>.of(_layout.areas)..[id] = targetArea;
    final navOrder = List<String>.of(_layout.navOrder)..remove(id);
    final moreOrder = List<String>.of(_layout.moreOrder)..remove(id);
    if (targetArea == 'nav') {
      navOrder.add(id);
    } else {
      moreOrder.add(id);
    }

    setState(() {
      _layout = _layout.copyWith(
        areas: areas,
        navOrder: navOrder,
        moreOrder: moreOrder,
      );
    });
    _preview();
  }

  void _reorder(String area, int oldIndex, int newIndex) {
    final order = List<String>.of(
      area == 'nav' ? _layout.visibleNavigationIds : _layout.visibleMoreIds,
    );
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    final hidden = area == 'nav'
        ? _layout.navOrder.where((id) => _layout.areas[id] != 'nav')
        : _layout.moreOrder.where((id) => _layout.areas[id] != 'more');
    final updatedOrder = [...order, ...hidden];
    setState(() {
      _layout = _layout.copyWith(
        navOrder: area == 'nav' ? updatedOrder : null,
        moreOrder: area == 'more' ? updatedOrder : null,
      );
    });
    _preview();
  }

  Color _colorFor(String id, BuildContext context) {
    final hex = _layout.colors[id];
    if (hex == null) return Theme.of(context).colorScheme.primary;
    final parsed = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return parsed == null
        ? Theme.of(context).colorScheme.primary
        : Color(0xFF000000 | parsed);
  }

  Future<void> _chooseColor(String id) async {
    final result = await showGtnColorPickerDialog(
      context,
      initialHex: _layout.colors[id] ?? '#9B7CFF',
      title: 'Choose ${_labels[id] ?? id} color',
      allowReset: true,
    );
    if (!mounted || result == null) return;

    final colors = Map<String, String>.of(_layout.colors);
    if (result.reset) {
      colors.remove(id);
    } else if (result.hex != null) {
      colors[id] = result.hex!;
    }
    setState(() => _layout = _layout.copyWith(colors: colors));
    _preview();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onChanged(_settingsForLayout());
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the menu layout.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _menuSection(String area, String title, String description) {
    final order = area == 'nav'
        ? _layout.visibleNavigationIds
        : _layout.visibleMoreIds;
    return GtnExpressiveCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (order.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No buttons here yet. Move a button into this section.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: order.length,
              onReorderItem: (oldIndex, newIndex) =>
                  _reorder(area, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final id = order[index];
                final color = _colorFor(id, context);
                final targetArea = area == 'nav' ? 'more' : 'nav';
                return GtnExpressiveCard(
                  key: ValueKey('$area-$id'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  color: color.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: GtnUiTokens.muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labels[id] ?? id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              id,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Choose color for ${_labels[id] ?? id}',
                        onPressed: _saving ? null : () => _chooseColor(id),
                        icon: Icon(Icons.colorize_rounded, color: color),
                      ),
                      TextButton(
                        onPressed: _saving ? null : () => _move(id, targetArea),
                        child: Text(
                          area == 'nav' ? 'Move to More' : 'Move to top bar',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewIds = [
      ..._layout.visibleNavigationIds,
      ..._layout.visibleMoreIds,
    ].take(8);

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customize buttons'),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
            Text(
              'Reorder your navigation, move destinations into More and choose each button color with GTN’s built-in color picker.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _menuSection(
              'nav',
              'Top bar',
              'Drag to reorder buttons. Play and More remain pinned.',
            ),
            _menuSection(
              'more',
              'More menu',
              'Move extra destinations here to keep your main navigation tidy.',
            ),
            GtnExpressiveCard(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live preview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview the first buttons in your navigation layout.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in previewIds)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _colorFor(
                              id,
                              context,
                            ).withValues(alpha: 0.16),
                            border: Border.all(
                              color: _colorFor(
                                id,
                                context,
                              ).withValues(alpha: 0.55),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Text(
                              _labels[id] ?? id,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: M3EButton.tonal(
                    onPressed: _saving
                        ? null
                        : () => setState(
                            () => _layout = MenuStudioLayout.defaults(),
                          ),
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
          ],
        ),
      ),
    );
  }
}
