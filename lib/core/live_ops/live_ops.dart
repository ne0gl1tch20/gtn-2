class LiveOpsEvent {
  const LiveOpsEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.currencyName,
    required this.maxClaims,
    required this.rewardNebula,
    required this.permanentBoostPerClaim,
    required this.minCorrectGuesses,
    required this.minPrestigeCount,
    required this.minUltraCount,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyName;
  final int maxClaims;
  final int rewardNebula;
  final int permanentBoostPerClaim;
  final int minCorrectGuesses;
  final int minPrestigeCount;
  final int minUltraCount;

  LiveOpsEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? currencyName,
    int? maxClaims,
    int? rewardNebula,
    int? permanentBoostPerClaim,
    int? minCorrectGuesses,
    int? minPrestigeCount,
    int? minUltraCount,
  }) =>
      LiveOpsEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        currencyName: currencyName ?? this.currencyName,
        maxClaims: maxClaims ?? this.maxClaims,
        rewardNebula: rewardNebula ?? this.rewardNebula,
        permanentBoostPerClaim:
            permanentBoostPerClaim ?? this.permanentBoostPerClaim,
        minCorrectGuesses: minCorrectGuesses ?? this.minCorrectGuesses,
        minPrestigeCount: minPrestigeCount ?? this.minPrestigeCount,
        minUltraCount: minUltraCount ?? this.minUltraCount,
      );

  factory LiveOpsEvent.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final description = json['description'];
    final status = json['status'];
    final start = json['startDate'];
    final end = json['endDate'];
    final currency = json['currencyName'];
    final maxClaims = json['maxClaims'];
    final reward = json['rewardNebula'] ?? 10;
    final boost = json['permanentBoostPerClaim'] ?? 1;
    final correct = json['minCorrectGuesses'] ?? 0;
    final prestige = json['minPrestigeCount'] ?? 0;
    final ultra = json['minUltraCount'] ?? 0;
    if (id is! String ||
        !RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(id) ||
        title is! String ||
        title.trim().isEmpty ||
        title.length > 100 ||
        description is! String ||
        description.trim().isEmpty ||
        description.length > 500 ||
        status is! String ||
        !const {'UPCOMING', 'ACTIVE', 'ENDING', 'ARCHIVED'}.contains(status) ||
        start is! String ||
        end is! String ||
        currency is! String ||
        currency.trim().isEmpty ||
        currency.length > 32 ||
        maxClaims is! int ||
        reward is! int ||
        boost is! int ||
        correct is! int ||
        prestige is! int ||
        ultra is! int ||
        maxClaims <= 0 ||
        reward < 0 ||
        boost < 0 ||
        correct < 0 ||
        prestige < 0 ||
        ultra < 0) {
      throw const FormatException('Invalid LiveOps event definition.');
    }
    final hasStartOffset = RegExp(r'(?:Z|[+-]\\d{2}:\\d{2})
    if (startDate == null ||
        endDate == null ||
        !endDate.isAfter(startDate)) {
      throw const FormatException('Invalid LiveOps event date window.');
    }
    return LiveOpsEvent(
      id: id,
      title: title,
      description: description,
      status: status,
      startDate: startDate,
      endDate: endDate,
      currencyName: currency,
      maxClaims: maxClaims,
      rewardNebula: reward,
      permanentBoostPerClaim: boost,
      minCorrectGuesses: correct,
      minPrestigeCount: prestige,
      minUltraCount: ultra,
    );
  }

  LiveOpsEvent resolveStatus(DateTime now) {
    final utcNow = now.toUtc();
    final nextStatus = status == 'ARCHIVED'
        ? 'ARCHIVED'
        : utcNow.isBefore(startDate)
            ? 'UPCOMING'
            : !utcNow.isBefore(endDate)
                ? 'ARCHIVED'
                : status == 'ENDING'
                    ? 'ENDING'
                    : 'ACTIVE';
    return LiveOpsEvent(
      id: id,
      title: title,
      description: description,
      status: nextStatus,
      startDate: startDate,
      endDate: endDate,
      currencyName: currencyName,
      maxClaims: maxClaims,
      rewardNebula: rewardNebula,
      permanentBoostPerClaim: permanentBoostPerClaim,
      minCorrectGuesses: minCorrectGuesses,
      minPrestigeCount: minPrestigeCount,
      minUltraCount: minUltraCount,
    );
  }

  bool isWithinClaimWindow(DateTime now) {
    final utcNow = now.toUtc();
    return !utcNow.isBefore(startDate) && utcNow.isBefore(endDate);
  }
}

class LiveOpsCatalog {
  const LiveOpsCatalog({
    required this.manifestVersion,
    required this.enabled,
    required this.events,
  });

  final int manifestVersion;
  final bool enabled;
  final List<LiveOpsEvent> events;
}
).hasMatch(start);
    final hasEndOffset = RegExp(r'(?:Z|[+-]\\d{2}:\\d{2})
    if (startDate == null ||
        endDate == null ||
        !endDate.isAfter(startDate)) {
      throw const FormatException('Invalid LiveOps event date window.');
    }
    return LiveOpsEvent(
      id: id,
      title: title,
      description: description,
      status: status,
      startDate: startDate,
      endDate: endDate,
      currencyName: currency,
      maxClaims: maxClaims,
      rewardNebula: reward,
      permanentBoostPerClaim: boost,
      minCorrectGuesses: correct,
      minPrestigeCount: prestige,
      minUltraCount: ultra,
    );
  }

  LiveOpsEvent resolveStatus(DateTime now) {
    final utcNow = now.toUtc();
    final nextStatus = status == 'ARCHIVED'
        ? 'ARCHIVED'
        : utcNow.isBefore(startDate)
            ? 'UPCOMING'
            : !utcNow.isBefore(endDate)
                ? 'ARCHIVED'
                : status == 'ENDING'
                    ? 'ENDING'
                    : 'ACTIVE';
    return LiveOpsEvent(
      id: id,
      title: title,
      description: description,
      status: nextStatus,
      startDate: startDate,
      endDate: endDate,
      currencyName: currencyName,
      maxClaims: maxClaims,
      rewardNebula: rewardNebula,
      permanentBoostPerClaim: permanentBoostPerClaim,
      minCorrectGuesses: minCorrectGuesses,
      minPrestigeCount: minPrestigeCount,
      minUltraCount: minUltraCount,
    );
  }

  bool isWithinClaimWindow(DateTime now) {
    final utcNow = now.toUtc();
    return !utcNow.isBefore(startDate) && utcNow.isBefore(endDate);
  }
}

class LiveOpsCatalog {
  const LiveOpsCatalog({
    required this.manifestVersion,
    required this.enabled,
    required this.events,
  });

  final int manifestVersion;
  final bool enabled;
  final List<LiveOpsEvent> events;
}
).hasMatch(end);
    if (!hasStartOffset || !hasEndOffset) {
      throw const FormatException('LiveOps dates must include an explicit UTC offset.');
    }
    final startDate = DateTime.tryParse(start)?.toUtc();
    final endDate = DateTime.tryParse(end)?.toUtc();
    if (startDate == null ||
        endDate == null ||
        !endDate.isAfter(startDate)) {
      throw const FormatException('Invalid LiveOps event date window.');
    }
    return LiveOpsEvent(
      id: id,
      title: title,
      description: description,
      status: status,
      startDate: startDate,
      endDate: endDate,
      currencyName: currency,
      maxClaims: maxClaims,
      rewardNebula: reward,
      permanentBoostPerClaim: boost,
      minCorrectGuesses: correct,
      minPrestigeCount: prestige,
      minUltraCount: ultra,
    );
  }

  LiveOpsEvent resolveStatus(DateTime now) {
    final utcNow = now.toUtc();
    final nextStatus = status == 'ARCHIVED'
        ? 'ARCHIVED'
        : utcNow.isBefore(startDate)
            ? 'UPCOMING'
            : !utcNow.isBefore(endDate)
                ? 'ARCHIVED'
                : status == 'ENDING'
                    ? 'ENDING'
                    : 'ACTIVE';
    return LiveOpsEvent(
      id: id,
      title: title,
      description: description,
      status: nextStatus,
      startDate: startDate,
      endDate: endDate,
      currencyName: currencyName,
      maxClaims: maxClaims,
      rewardNebula: rewardNebula,
      permanentBoostPerClaim: permanentBoostPerClaim,
      minCorrectGuesses: minCorrectGuesses,
      minPrestigeCount: minPrestigeCount,
      minUltraCount: minUltraCount,
    );
  }

  bool isWithinClaimWindow(DateTime now) {
    final utcNow = now.toUtc();
    return !utcNow.isBefore(startDate) && utcNow.isBefore(endDate);
  }
}

class LiveOpsCatalog {
  const LiveOpsCatalog({
    required this.manifestVersion,
    required this.enabled,
    required this.events,
  });

  final int manifestVersion;
  final bool enabled;
  final List<LiveOpsEvent> events;
}
