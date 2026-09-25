import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../models/program_reminder.dart';
import '../services/radio_api_service.dart';
import '../services/audio_service.dart';
import '../services/recording_service.dart';
import '../services/widget_service.dart';

class RadioProvider extends ChangeNotifier {
  final RadioApiService _apiService = RadioApiService();
  final AudioService _audioService = AudioService();
  final RecordingService _recordingService = RecordingService();
  
  List<RadioStation> _homeStations = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _history = [];
  List<ProgramReminder> _reminders = [];
  
  RadioStation? _currentStation;
  RadioStation? _lastStation;
  bool _isLoading = false;
  bool _isDataSaver = false;
  String _activeFilterTitle = "أشهر الإذاعات العالمية";
  
  // Equalizer & Audio States
  double _bassGain = 1.0;
  double _midGain = 1.0;
  double _trebleGain = 1.0;
  double _bassBoost = 0.0;
  String _currentTheme = 'Deep Space';

  RadioProvider() {
    _init();
  }

  Future<void> _init() async {
    await _audioService.initialize();
    await _loadLocalData();
    fetchHomeStations();
    
    // Listen to metadata
    _audioService.metadataStream.listen((meta) {
      if (meta != null) notifyListeners();
    });
    
    // Auto-reconnect listener
    _audioService.playerStateStream.listen((state) {
      WidgetService.updateWidget(
        title: _currentStation?.name ?? "World Radio",
        subtitle: _audioService.currentMetadata ?? "Live",
        isPlaying: _audioService.isPlaying,
      );
      notifyListeners();
    });
  }

  // Getters
  List<RadioStation> get homeStations => _homeStations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get history => _history;
  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _audioService.isPlaying;
  bool get isLoading => _isLoading;
  String get activeFilterTitle => _activeFilterTitle;
  String get currentMetadata => _audioService.currentMetadata ?? "";
  String get currentTheme => _currentTheme;

  // Actions
  Future<void> fetchHomeStations({String? countryCode, String? tag}) async {
    _isLoading = true;
    notifyListeners();
    _homeStations = await _apiService.getStations(
      countryCode: countryCode, 
      tag: tag, 
      limit: 500,
      isDataSaver: _isDataSaver
    );
    _isLoading = false;
    notifyListeners();
  }

  void playStation(RadioStation station) {
    if (_currentStation != null) _lastStation = _currentStation;
    _currentStation = station;
    _audioService.play(station.url);
    _addToHistory(station);
    notifyListeners();
  }

  void togglePlay() {
    _audioService.togglePlay();
    notifyListeners();
  }

  void skipForward() {
    final list = _favorites.isNotEmpty ? _favorites : _homeStations;
    if (list.isEmpty) return;
    int idx = list.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int next = (idx + 1) % list.length;
    playStation(list[next]);
  }

  void skipBackward() {
    final list = _favorites.isNotEmpty ? _favorites : _homeStations;
    if (list.isEmpty) return;
    int idx = list.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int prev = (idx - 1 + list.length) % list.length;
    playStation(list[prev]);
  }

  void toggleFavorite(RadioStation station) {
    if (_favorites.any((s) => s.uuid == station.uuid)) {
      _favorites.removeWhere((s) => s.uuid == station.uuid);
    } else {
      _favorites.add(station);
    }
    _saveFavorites();
    notifyListeners();
  }

  void setRating(String uuid, int rating, String note) {
    // Logic to save rating and note locally
    notifyListeners();
  }

  void setTheme(String theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  // Recording
  void startRecording() => _recordingService.start(_currentStation?.name ?? "Radio");
  void stopRecording() => _recordingService.stop();
  bool get isRecording => _recordingService.isRecording;

  // Local Storage Helpers
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final favJson = prefs.getString('favorites') ?? '[]';
    _favorites = (json.decode(favJson) as List).map((j) => RadioStation.fromJson(j)).toList();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('favorites', json.encode(_favorites.map((s) => s.toJson()).toList()));
  }

  void _addToHistory(RadioStation station) {
    _history.removeWhere((s) => s.uuid == station.uuid);
    _history.insert(0, station);
    if (_history.length > 50) _history.removeLast();
  }
}
