import 'package:material_ui/material_ui.dart';

import '../core/liveops/live_ops_repository.dart';
import '../core/progression/progression_state.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';

typedef LiveOpsClaim = Future<void> Function(LiveOpsEvent event);

class LiveOpsPage extends StatefulWidget {
  const LiveOpsPage({
    super.key,
    required this.progression,
    required this.onClaim,
    this.repository,
  });

  final ProgressionState progression;
  final LiveOpsClaim onClaim;
  final LiveOpsRepository? repository;

  @override
  State<LiveOpsPage> createState() => _LiveOpsPageState();
}

class _LiveOpsPageState extends State<LiveOpsPage> {
  late final LiveOpsRepository _repository =
      widget.repository ?? LiveOpsRepository();
  late Future<LiveOpsSnapshot> _snapshot = _repository.load();
  String? _claimingEventId;

  Future<void> _reload() async {
    setState(() => _snapshot = _repository.load());
    await _snapshot;
  }

  Future<void> _claim(LiveOpsEvent event) async {
    if (_claimingEventId != null) return;
    setState(() => _claimingEventId = event.id);
    try {
      await widget.onClaim(event);
    } finally {
      if (mounted) setState(() => _claimingEventId = null);
    }
  }

  String _dateLabel(String value) {
    final date = DateTime.parse(value).toLocal();
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: Text(AppLocalizations.text('live_ops_title', 'Seasonal Events')),
      ),
      body: FutureBuilder<LiveOpsSnapshot>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ??
              const LiveOpsSnapshot(enabled: false, events: []);
          final systems = widget.progression.legacySystems;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
              children: [
                GtnPageHeader(
                  eyebrow: AppLocalizations.text(
                    'live_ops_eyebrow',
                    'Limited-time rewards',
                  ),
                  title: AppLocalizations.text(
                    'live_ops_heading',
                    'Seasonal Events',
                  ),
                  description: AppLocalizations.text(
                    'live_ops_intro',
                    'Claim event rewards and build permanent bonuses for this save slot.',
                  ),
                  icon: Icons.event_available_rounded,
                  accent: GtnUiTokens.cyan,
                  trailing: _BonusLevelChip(level: systems.permanentEventBoosts),
                ),
                const SizedBox(height: 14),
                GtnExpressiveCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.text(
                            'live_ops_bonus_title',
                            'Event Perks & Permanent Bonuses',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.text(
                            'live_ops_bonus_description',
                            '+2% Money per level and +1 Nebula per correct guess every 5 levels, up to level 25. Applies to this save slot.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (data.error != null) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: AppLocalizations.text(
                      'live_ops_unavailable',
                      'LiveOps unavailable',
                    ),
                    message: data.error!,
                  ),
                ],
                if (!data.enabled) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: AppLocalizations.text(
                      'live_ops_disabled',
                      'Seasonal events are disabled',
                    ),
                    message: AppLocalizations.text(
                      'live_ops_disabled_description',
                      'Enable live_ops and seasonal_rewards in the bundled feature flags to show event offers.',
                    ),
                  ),
                ] else if (data.events.isEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: AppLocalizations.text(
                      'live_ops_no_events',
                      'No seasonal events available',
                    ),
                    message: AppLocalizations.text(
                      'live_ops_no_events_description',
                      'Check again later for the next event.',
                    ),
                  ),
                ] else ...[
                  for (final event in data.events) ...[
                    const SizedBox(height: 12),
                    _EventCard(
                      event: event,
                      claims: systems.liveOpsClaims[event.id] ?? 0,
                      progression: widget.progression,
                      busy: _claimingEventId == event.id,
                      anyClaimBusy: _claimingEventId != null,
                      onClaim: () => _claim(event),
                      dateLabel: _dateLabel,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BonusLevelChip extends StatelessWidget {
  const _BonusLevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: GtnUiTokens.gold.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+$level',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: GtnUiTokens.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          AppLocalizations.text('live_ops_bonus_level', 'BONUS LEVEL'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => GtnExpressiveCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.claims,
    required this.progression,
    required this.busy,
    required this.anyClaimBusy,
    required this.onClaim,
    required this.dateLabel,
  });

  final LiveOpsEvent event;
  final int claims;
  final ProgressionState progression;
  final bool busy;
  final bool anyClaimBusy;
  final VoidCallback onClaim;
  final String Function(String value) dateLabel;

  @override
  Widget build(BuildContext context) {
    final eligible =
        progression.correctGuesses >= event.minCorrectGuesses &&
        progression.prestigeResets >= event.minPrestigeCount &&
        progression.ultraResets >= event.minUltraCount;
    final maxed = claims >= event.maxClaims;
    final canClaim =
        event.status == 'ACTIVE' && !maxed && eligible && !anyClaimBusy;
    final theme = Theme.of(context);
    final statusColor = switch (event.status) {
      'ACTIVE' => GtnUiTokens.green,
      'UPCOMING' => GtnUiTokens.cyan,
      'ENDING' => GtnUiTokens.gold,
      _ => GtnUiTokens.muted,
    };

    return GtnExpressiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(event.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              '${dateLabel(event.startDate)} → ${dateLabel(event.endDate)}',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Reward: +${event.rewardNebula} ${event.currencyName}',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              'Eligibility: ${event.minCorrectGuesses} correct guesses, '
              '${event.minPrestigeCount} Prestige, ${event.minUltraCount} Ultra',
              style: theme.textTheme.bodySmall,
            ),
            if (!eligible) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.text(
                  'live_ops_not_eligible',
                  'You do not meet this event’s requirements yet.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Claims: $claims / ${event.maxClaims}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                M3EButton.filled(
                  onPressed: canClaim ? onClaim : null,
                  child: Text(
                    busy
                        ? AppLocalizations.text('claiming', 'Claiming…')
                        : maxed
                        ? AppLocalizations.text('max_claimed', 'Max Claimed')
                        : 'Claim Reward (+${event.rewardNebula} ${event.currencyName})',
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
