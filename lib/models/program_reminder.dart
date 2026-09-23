class ProgramReminder {
  final String id;
  final String title;
  final String stationUuid;
  final String stationName;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1=Mon, ..., 5=Fri, 7=Sun (empty = daily)
  bool isEnabled;

  ProgramReminder({
    required this.id,
    required this.title,
    required this.stationUuid,
    required this.stationName,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  factory ProgramReminder.fromJson(Map<String, dynamic> json) {
    return ProgramReminder(
      id: json['id'] ?? '',
      title: json['title'] ?? 'برنامج إذاعي',
      stationUuid: json['stationUuid'] ?? '',
      stationName: json['stationName'] ?? 'إذاعة',
      hour: json['hour'] ?? 12,
      minute: json['minute'] ?? 0,
      daysOfWeek: json['daysOfWeek'] is List ? List<int>.from(json['daysOfWeek']) : [],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'stationUuid': stationUuid,
      'stationName': stationName,
      'hour': hour,
      'minute': minute,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get daysLabel {
    if (daysOfWeek.isEmpty) return 'يومياً';
    const dayNames = {1: 'الإثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد'};
    return daysOfWeek.map((d) => dayNames[d] ?? '').join('، ');
  }
}
