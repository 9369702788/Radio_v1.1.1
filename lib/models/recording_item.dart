import 'dart:io';

class RecordingItem {
  final String path;
  final String stationName;
  final DateTime date;
  final int sizeBytes;

  String get name => stationName;
  File get file => File(path);

  RecordingItem({
    required this.path,
    required this.stationName,
    required this.date,
    required this.sizeBytes,
  });
}
