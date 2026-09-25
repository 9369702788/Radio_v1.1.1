class ProgramReminder {
  final String id;
  final String stationUuid;
  final String stationName;
  final String programName;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  bool isActive;

  ProgramReminder({
    required this.id,
    required this.stationUuid,
    required this.stationName,
    required this.programName,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'stationUuid': stationUuid,
    'stationName': stationName,
    'programName': programName,
    'hour': hour,
    'minute': minute,
    'daysOfWeek': daysOfWeek,
    'isActive': isActive,
  };

  factory ProgramReminder.fromJson(Map<String, dynamic> json) => ProgramReminder(
    id: json['id'],
    stationUuid: json['stationUuid'],
    stationName: json['stationName'],
    programName: json['programName'],
    hour: json['hour'],
    minute: json['minute'],
    daysOfWeek: List<int>.from(json['daysOfWeek']),
    isActive: json['isActive'],
  );
}
