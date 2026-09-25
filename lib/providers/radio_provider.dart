import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../models/program_reminder.dart';
import '../services/radio_api_service.dart';
import '../services/audio_service.dart';
import '../services/recording_service.dart';

class RadioProvider extends ChangeNotifier {
  final RadioApiService _apiService = RadioApiService();
  final AudioService _audioService = AudioService();
  final RecordingService _recordingService = RecordingService();
  
  List<RadioStation> _stations = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _history = [];
  List<FileSystemEntity> _recordings = [];
  
  RadioStation? _currentStation;
  bool _isLoading = false;
  int _totalListeningMinutes = 0;
  int _dailyStreak = 0;

  RadioProvider() {
    _init();
  }

  Future<void> _init() async {
    await _audioService.initialize();
    await _loadLocalData();
    refreshRecordings();
    
    _audioService.playerStateStream.listen((state) {
      notifyListeners();
    });
  }

  // --- Getters (Aligned with PlayerScreen) ---
  List<RadioStation> get stations => _stations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get history => _history;
  List<FileSystemEntity> get recordingsList => _recordings;
  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _audioService.isPlaying;
  bool get isBuffering => _audioService.isBuffering;
  bool get isLoading => _isLoading;
  bool get isRecording => _recordingService.isRecording;
  
  // The screen expects 'currentMetadata'
  String get currentMetadata => _audioService.currentMetadata ?? "";
  
  int get totalListeningMinutes => _totalListeningMinutes;
  int get dailyStreak => _dailyStreak;
  String get mostListenedStationName => _history.isNotEmpty ? _history.first.name : "N/A";

  // --- Actions (Aligned with PlayerScreen) ---
  
  // The screen expects 'togglePlay'
  void togglePlay() {
    _audioService.togglePlayPause();
    notifyListeners();
  }

  void skipForward() {
    final list = _favorites.isNotEmpty ? _favorites : _stations;
    if (list.isEmpty) return;
    int idx = list.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int next = (idx + 1) % list.length;
    playStation(list[next]);
  }

  void skipBackward() {
    final list = _favorites.isNotEmpty ? _favorites : _stations;
    if (list.isEmpty) return;
    int idx = list.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int prev = (idx - 1 + list.length) % list.length;
    playStation(list[prev]);
  }

  void playStation(RadioStation station) {
    _currentStation = station;
    _audioService.playStation(station);
    _addToHistory(station);
    notifyListeners();
  }

  void stop() {
    _audioService.stop();
    _currentStation = null;
    notifyListeners();
  }

  // --- Recording & Others ---
  void startRecording() {
    if (_currentStation != null) {
      _recordingService.start(_currentStation!.name, _currentStation!.url);
      notifyListeners();
    }
  }

  void stopRecording() {
    _recordingService.stop();
    refreshRecordings();
    notifyListeners();
  }

  Future<void> refreshRecordings() async {
    _recordings = await _recordingService.getRecordings();
    notifyListeners();
  }

  Future<void> deleteRecording(String path) async {
    await _recordingService.deleteRecording(path);
    refreshRecordings();
  }

  // --- Search & Data ---
  Future<void> searchStations(String query) async {
    _isLoading = true;
    notifyListeners();
    _stations = await _apiService.searchStations(query);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    _totalListeningMinutes = prefs.getInt('total_minutes') ?? 0;
    _dailyStreak = prefs.getInt('daily_streak') ?? 0;
  }

  void _addToHistory(RadioStation station) {
    _history.removeWhere((s) => s.uuid == station.uuid);
    _history.insert(0, station);
    if (_history.length > 50) _history.removeLast();
  }
}
