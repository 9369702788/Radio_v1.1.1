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
  
  // Maps for Ratings and Notes
  Map<String, int> _ratings = {};
  Map<String, String> _notes = {};
  
  RadioStation? _currentStation;
  bool _isLoading = false;
  bool _isDataSaver = false;
  String _currentTheme = 'Deep Space';

  RadioProvider() {
    _init();
  }

  Future<void> _init() async {
    await _audioService.initialize();
    await _loadLocalData();
    fetchHomeStations();
  }

  // Getters
  List<RadioStation> get homeStations => _homeStations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get history => _history;
  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _audioService.isPlaying;
  bool get isLoading => _isLoading;
  String get currentMetadata => _audioService.currentMetadata ?? "";

  // --- Rating & Note Methods (Fixed for station_card.dart) ---
  
  int getStationRating(String uuid) => _ratings[uuid] ?? 0;
  
  String getStationNote(String uuid) => _notes[uuid] ?? "";

  void setStationRating(String uuid, int rating) {
    _ratings[uuid] = rating;
    _saveRatingsAndNotes();
    notifyListeners();
  }

  void setStationNote(String uuid, String note) {
    _notes[uuid] = note;
    _saveRatingsAndNotes();
    notifyListeners();
  }

  // --- Core Actions ---

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
    _currentStation = station;
    _audioService.play(station.url);
    _addToHistory(station);
    notifyListeners();
  }

  void togglePlay() {
    _audioService.togglePlay();
    notifyListeners();
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

  // --- Persistence ---

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Favorites
    final favJson = prefs.getString('favorites') ?? '[]';
    _favorites = (json.decode(favJson) as List).map((j) => RadioStation.fromJson(j)).toList();
    
    // Load Ratings
    final ratingsJson = prefs.getString('station_ratings') ?? '{}';
    _ratings = Map<String, int>.from(json.decode(ratingsJson));
    
    // Load Notes
    final notesJson = prefs.getString('station_notes') ?? '{}';
    _notes = Map<String, String>.from(json.decode(notesJson));
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('favorites', json.encode(_favorites.map((s) => s.toJson()).toList()));
  }

  Future<void> _saveRatingsAndNotes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('station_ratings', json.encode(_ratings));
    prefs.setString('station_notes', json.encode(_notes));
  }

  void _addToHistory(RadioStation station) {
    _history.removeWhere((s) => s.uuid == station.uuid);
    _history.insert(0, station);
    if (_history.length > 50) _history.removeLast();
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
}
