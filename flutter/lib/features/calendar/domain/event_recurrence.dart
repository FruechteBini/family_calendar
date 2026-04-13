/// JSON shape matches backend [RecurrenceRule] (frequency, interval, optional by_weekday, until, count).
class EventRecurrenceRule {
  final String frequency; // daily | weekly | monthly | yearly
  final int interval;
  final List<int>? byWeekday; // ISO 1=Mo … 7=Su
  final DateTime? until;
  final int? count;

  const EventRecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.byWeekday,
    this.until,
    this.count,
  });

  factory EventRecurrenceRule.fromJson(Map<String, dynamic> json) {
    final bw = json['by_weekday'] as List<dynamic>?;
    return EventRecurrenceRule(
      frequency: json['frequency'] as String? ?? 'weekly',
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      byWeekday: bw?.map((e) => (e as num).toInt()).toList(),
      until: json['until'] != null ? DateTime.tryParse(json['until'] as String) : null,
      count: (json['count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'interval': interval,
      if (byWeekday != null && byWeekday!.isNotEmpty) 'by_weekday': byWeekday,
      if (until != null) 'until': until!.toIso8601String(),
      if (count != null) 'count': count,
    };
  }

  EventRecurrenceRule copyWith({
    String? frequency,
    int? interval,
    List<int>? byWeekday,
    DateTime? until,
    int? count,
    bool clearUntil = false,
    bool clearCount = false,
    bool clearByWeekday = false,
  }) {
    return EventRecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      byWeekday: clearByWeekday ? null : (byWeekday ?? this.byWeekday),
      until: clearUntil ? null : (until ?? this.until),
      count: clearCount ? null : (count ?? this.count),
    );
  }
}
