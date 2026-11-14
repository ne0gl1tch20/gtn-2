import 'package:flutter/material.dart';

import '../core/seasonal/seasonal_theme_calendar.dart';
import '../design/expressive_widgets.dart';

class SeasonalThemeSimulatorCard extends StatefulWidget {
  const SeasonalThemeSimulatorCard({super.key});

  @override
  State<SeasonalThemeSimulatorCard> createState() => _SeasonalThemeSimulatorCardState();
}

class _SeasonalThemeSimulatorCardState extends State<SeasonalThemeSimulatorCard> {
  static final List<(String, DateTime)> _presets = [
    ('Christmas', DateTime(2026, 12, 15)),
    ('New Year', DateTime(2027, 1, 2)),
    ("Valentine's", DateTime(2027, 2, 14)),
    ('Lunar New Year', DateTime(2027, 2, 6)),
    ('Easter', DateTime(2027, 3, 26)),
    ('Philippine Summer', DateTime(2027, 4, 15)),
    ('Independence Day', DateTime(2027, 6, 12)),
    ('Back to School', DateTime(2027, 6, 15)),
    ('Halloween', DateTime(2027, 10, 31)),
    ('Winter', DateTime(2027, 1, 15)),
  ];

  static const Map<String, (String, String)> _labels = {
    'christmas': ('🎄', 'Christmas'),
    'new_year': ('🎆', 'New Year'),
    'valentines': ('💗', "Valentine's Day"),
    'lunar_new_year': ('🧧', 'Lunar New Year'),
    'easter': ('🐣', 'Easter'),
    'philippine_summer': ('☀️', 'Philippine Summer'),
    'philippine_independence_day': ('🇵🇭', 'Philippine Independence Day'),
    'back_to_school': ('🎒', 'Back to School'),
    'halloween': ('🎃', 'Halloween'),
    'winter': ('❄️', 'Winter'),
  };

  late DateTime _previewDate = DateTime.now();
  late final TextEditingController _dateController =
      TextEditingController(text: _formatDate(_previewDate));
  bool _dateError = false;
  final SeasonalThemeCalendarConfig _config =
      SeasonalThemeCalendarConfig(winterEnabled: true);

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _applyDate() {
    final value = _dateController.text.trim();
    final parsed = DateTime.tryParse(value);
    if (parsed == null || _formatDate(parsed) != value) {
      setState(() => _dateError = true);
      return;
    }
    setState(() {
      _previewDate = parsed;
      _dateError = false;
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _previewDate = date;
      _dateController.text = _formatDate(date);
      _dateError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = SeasonalThemeCalendar.activeThemes(_previewDate, _config);
    return GtnExpressiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Season Simulator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Preview calendar windows without changing saves, rewards or trait eligibility. Winter is enabled here so it can be tested in any region.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('season-simulator-date'),
              controller: _dateController,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: 'Preview date (YYYY-MM-DD)',
                border: const OutlineInputBorder(),
                errorText: _dateError ? 'Enter a valid date like 2027-02-06.' : null,
              ),
              onChanged: (_) {
                if (_dateError) setState(() => _dateError = false);
              },
              onSubmitted: (_) => _applyDate(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _applyDate, child: const Text('Preview date')),
                OutlinedButton(
                  onPressed: () => _selectDate(DateTime.now()),
                  child: const Text('Today'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Quick presets', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final preset in _presets) ...[
                    OutlinedButton(
                      key: ValueKey('season-preset-${preset.$1.toLowerCase().replaceAll(' ', '-')}'),
                      onPressed: () => _selectDate(preset.$2),
                      child: Text(preset.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const Divider(height: 24),
            Text(
              'Preview: ${_formatDate(_previewDate)}',
              key: const ValueKey('season-simulator-preview-date'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (active.isEmpty)
              Text('No seasonal event is active on this date.')
            else
              for (var index = 0; index < active.length; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_labels[active[index].id]?.$1 ?? '✨'}  ${_labels[active[index].id]?.$2 ?? active[index].id}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(active[index].id, style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                      if (index == 0)
                        Text(
                          'PRIMARY',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
