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
  }

  // Getters
  List<RadioStation> get stations => _stations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get history => _history;
  List<FileSystemEntity> get recordingsList => _recordings;
  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _audioService.isPlaying;
  bool get isBuffering => _audioService.isBuffering;
  bool get isLoading => _isLoading;
  bool get isRecording => _recordingService.isRecording;
  String? get liveMetadataTitle => _audioService.currentMetadata;
  int get totalListeningMinutes => _totalListeningMinutes;
  int get dailyStreak => _dailyStreak;
  String get mostListenedStationName => _history.isNotEmpty ? _history.first.name : "N/A";

  // Actions
  void playStation(RadioStation station) {
    _currentStation = station;
    _audioService.playStation(station);
    _addToHistory(station);
    notifyListeners();
  }

  void togglePlayPause() {
    _audioService.togglePlayPause();
    notifyListeners();
  }

  void stop() {
    _audioService.stop();
    notifyListeners();
  }

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

  // Persistence
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    _totalListeningMinutes = prefs.getInt('total_minutes') ?? 0;
    _dailyStreak = prefs.getInt('daily_streak') ?? 0;
    // Load favorites and history...
  }

  void _addToHistory(RadioStation station) {
    _history.removeWhere((s) => s.uuid == station.uuid);
    _history.insert(0, station);
    if (_history.length > 50) _history.removeLast();
  }
  
  // Add missing methods for search, country, etc. (reusing from previous version)
  Future<void> searchStations(String query) async {
    _isLoading = true;
    notifyListeners();
    _stations = await _apiService.searchStations(query);
    _isLoading = false;
    notifyListeners();
  }
}
