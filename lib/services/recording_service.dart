import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class RecordingService {
  bool _isRecording = false;
  String? _currentFilePath;
  http.Client? _client;

  bool get isRecording => _isRecording;

  Future<void> start(String stationName, String url) async {
    if (_isRecording) return;
    _isRecording = true;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${dir.path}/recordings');
      if (!recordingsDir.existsSync()) recordingsDir.createSync();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${recordingsDir.path}/$stationName-$timestamp.mp3';
      
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await _client!.send(request);
      
      final file = File(_currentFilePath!);
      final sink = file.openWrite();
      
      response.stream.listen((data) {
        if (_isRecording) sink.add(data);
      }, onDone: () {
        sink.close();
        _isRecording = false;
      });
    } catch (e) {
      print("Recording Error: $e");
      _isRecording = false;
    }
  }

  void stop() {
    _isRecording = false;
    _client?.close();
  }

  Future<List<FileSystemEntity>> getRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!recordingsDir.existsSync()) return [];
    return recordingsDir.listSync();
  }

  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}
