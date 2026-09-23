import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/radio_station.dart';

class RecordingItem {
  final String path;
  final String fileName;
  final String stationName;
  final DateTime date;
  final int sizeBytes;

  RecordingItem({
    required this.path,
    required this.fileName,
    required this.stationName,
    required this.date,
    required this.sizeBytes,
  });
}

class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  http.Client? _client;
  IOSink? _fileSink;
  bool _isRecording = false;
  String? _currentRecordingPath;
  String? _currentStationName;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get currentStationName => _currentStationName;
  DateTime? get recordingStartTime => _recordingStartTime;

  Future<String> _getRecordingsDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${docsDir.path}/world_radio_recordings');
    if (!await recDir.exists()) {
      await recDir.create(recursive: true);
    }
    return recDir.path;
  }

  Future<void> startRecording(RadioStation station) async {
    if (_isRecording) await stopRecording();

    final dirPath = await _getRecordingsDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = station.name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
    final filePath = '$dirPath/Rec_${sanitizedName}_$timestamp.mp3';

    final file = File(filePath);
    _fileSink = file.openWrite();
    _currentRecordingPath = filePath;
    _currentStationName = station.name;
    _recordingStartTime = DateTime.now();
    _isRecording = true;

    _client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(station.url));
      request.headers['User-Agent'] = 'WorldRadioRecorder/2.0';
      final response = await _client!.send(request);

      response.stream.listen(
        (chunk) {
          if (_isRecording && _fileSink != null) {
            _fileSink!.add(chunk);
          }
        },
        onError: (e) {
          stopRecording();
        },
        onDone: () {
          stopRecording();
        },
        cancelOnError: true,
      );
    } catch (e) {
      await stopRecording();
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _isRecording = false;

    try {
      _client?.close();
      await _fileSink?.flush();
      await _fileSink?.close();
    } catch (_) {}

    final savedPath = _currentRecordingPath;
    _client = null;
    _fileSink = null;
    _currentRecordingPath = null;
    _currentStationName = null;
    _recordingStartTime = null;

    return savedPath;
  }

  Future<List<RecordingItem>> getRecordings() async {
    final dirPath = await _getRecordingsDir();
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<RecordingItem> items = [];
    final fileList = dir.listSync();

    for (var entity in fileList) {
      if (entity is File && entity.path.endsWith('.mp3')) {
        final stat = entity.statSync();
        final name = entity.uri.pathSegments.last;
        // Parse station name from Rec_StationName_Timestamp.mp3
        String stationName = 'إذاعة غير معروفة';
        try {
          final parts = name.replaceFirst('Rec_', '').split('_');
          if (parts.length > 1) {
            stationName = parts.sublist(0, parts.length - 1).join(' ');
          }
        } catch (_) {}

        items.add(
          RecordingItem(
            path: entity.path,
            fileName: name,
            stationName: stationName,
            date: stat.modified,
            sizeBytes: stat.size,
          ),
        );
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
