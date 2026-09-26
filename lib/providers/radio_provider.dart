import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../services/radio_api_service.dart';
import '../services/audio_service.dart';

class RadioProvider extends ChangeNotifier {
  final RadioApiService _apiService = RadioApiService();
  final AudioService _audioService = AudioService();
  final SharedPreferences _prefs;

  List<RadioStation> _stations = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _recentlyPlayed = [];
  List<RadioStation> _searchResults = [];
  RadioStation? _currentStation;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _dataSaverMode = false;
  String? _errorMessage;
  String _selectedFavoritesFolder = 'All';
  String _currentMetadata = '';
  bool _isBuffering = false;
  bool _isRecording = false;
  List<dynamic> _recordingsList = [];
  int _totalListeningMinutes = 0;
  int _dailyStreak = 0;
  String _mostListenedStationName = 'لا توجد';
  Map<String, double> _ratings = {};
  Map<String, String> _notes = {};

  RadioProvider(this._prefs) {
    _initialize();
  }

  // ===== GETTERS =====
  List<RadioStation> get stations => _stations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get recentlyPlayed => _recentlyPlayed;
  List<RadioStation> get searchResults => _searchResults;
  List<RadioStation> get filteredFavorites => _favorites;
  RadioStation? get currentStation => _currentStation;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get dataSaverMode => _dataSaverMode;
  String? get errorMessage => _errorMessage;
  String get selectedFavoritesFolder => _selectedFavoritesFolder;
  String get currentMetadata => _currentMetadata.isEmpty ? 'بث مباشر...' : _currentMetadata;
  bool get isBuffering => _isBuffering;
  bool get isRecording => _isRecording;
  List<dynamic> get recordingsList => _recordingsList;
  int get totalListeningMinutes => _totalListeningMinutes;
  int get dailyStreak => _dailyStreak;
  String get mostListenedStationName => _mostListenedStationName;
  AudioService get audioService => _audioService;
  List<RadioStation> get homeStations => _stations;

  Future<void> _initialize() async {
    await _audioService.initialize();
    await _loadFavorites();
    await _loadRecentlyPlayed();
    await _loadSettings();
  }

  // ===== SEARCH =====
  Future<void> searchStations(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchStations(query);
      for (var station in _searchResults) {
        station.isFavorite = _favorites.any((fav) => fav.uuid == station.uuid);
      }
    } catch (e) {
      _errorMessage = 'خطأ في البحث';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // ===== STATIONS BY CATEGORY =====
  Future<void> getStationsByCountry(String countryCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stations = await _apiService.getStationsByCountry(countryCode);
      for (var station in _stations) {
        station.isFavorite = _favorites.any((fav) => fav.uuid == station.uuid);
      }
    } catch (e) {
      _errorMessage = 'خطأ في جلب المحطات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTopStations() async {
    _isLoading = true;
    _errorMessage = null;
    _stations = [];
    notifyListeners();

    try {
      _stations = await _apiService.getTopStations();
      for (var station in _stations) {
        station.isFavorite = _favorites.any((fav) => fav.uuid == station.uuid);
      }
    } catch (e) {
      _errorMessage = 'فشل تحميل أفضل المحطات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHomeStations({String? countryCode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (countryCode != null) {
        _stations = await _apiService.getStationsByCountry(countryCode);
      } else {
        _stations = await _apiService.getTopStations();
      }
      for (var station in _stations) {
        station.isFavorite = _favorites.any((fav) => fav.uuid == station.uuid);
      }
    } catch (e) {
      _errorMessage = 'خطأ في تحميل المحطات';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== PLAYBACK CONTROL =====
  Future<void> playStation(RadioStation station) async {
    try {
      await _audioService.playStation(station);
      _currentStation = station;
      _isPlaying = true;
      _addToRecentlyPlayed(station);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'خطأ في التشغيل';
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _audioService.pause();
      _isPlaying = false;
    } else {
      await _audioService.resume();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    await togglePlay();
  }

  Future<void> stop() async {
    await _audioService.stop();
    _currentStation = null;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> skipForward() async {
    if (_stations.isNotEmpty && _currentStation != null) {
      final index = _stations.indexWhere((s) => s.uuid == _currentStation!.uuid);
      if (index >= 0 && index < _stations.length - 1) {
        await playStation(_stations[index + 1]);
      }
    }
  }

  Future<void> skipBackward() async {
    if (_stations.isNotEmpty && _currentStation != null) {
      final index = _stations.indexWhere((s) => s.uuid == _currentStation!.uuid);
      if (index > 0) {
        await playStation(_stations[index - 1]);
      }
    }
  }

  // ===== FAVORITES =====
  Future<void> toggleFavorite(RadioStation station) async {
    station.isFavorite = !station.isFavorite;
    if (station.isFavorite) {
      _favorites.add(station);
    } else {
      _favorites.removeWhere((fav) => fav.uuid == station.uuid);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    try {
      final json = _favorites.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList('favorites', json);
    } catch (e) {
      print('خطأ في حفظ المفضلة');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final json = _prefs.getStringList('favorites') ?? [];
      _favorites = json.map((j) => RadioStation.fromJson(jsonDecode(j))).toList();
      notifyListeners();
    } catch (e) {
      print('خطأ في تحميل المفضلة');
    }
  }

  // ===== RECENTLY PLAYED =====
  void _addToRecentlyPlayed(RadioStation station) async {
    _recentlyPlayed.removeWhere((s) => s.uuid == station.uuid);
    _recentlyPlayed.insert(0, station);
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 50);
    }
    await _saveRecentlyPlayed();
  }

  Future<void> _saveRecentlyPlayed() async {
    try {
      final json = _recentlyPlayed.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList('recently_played', json);
    } catch (e) {
      print('خطأ في حفظ المستمع إليها مؤخراً');
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final json = _prefs.getStringList('recently_played') ?? [];
      _recentlyPlayed = json.map((j) => RadioStation.fromJson(jsonDecode(j))).toList();
      notifyListeners();
    } catch (e) {
      print('خطأ في تحميل المستمع إليها مؤخراً');
    }
  }

  // ===== DATA SAVER MODE =====
  void toggleDataSaverMode() {
    _dataSaverMode = !_dataSaverMode;
    _prefs.setBool('data_saver_mode', _dataSaverMode);
    notifyListeners();
  }

  // ===== RATINGS & NOTES =====
  void setStationRating(String uuid, double rating) {
    _ratings[uuid] = rating;
    notifyListeners();
  }

  double getStationRating(String uuid) => _ratings[uuid] ?? 0.0;

  void setStationNote(String uuid, String note) {
    _notes[uuid] = note;
    notifyListeners();
  }

  String getStationNote(String uuid) => _notes[uuid] ?? '';

  // ===== BACKUP/RESTORE =====
  String exportBackupJson() {
    return jsonEncode({
      'favorites': _favorites.map((s) => s.toJson()).toList(),
      'recently_played': _recentlyPlayed.map((s) => s.toJson()).toList(),
      'ratings': _ratings,
      'notes': _notes,
    });
  }

  Future<int> importBackupJson(String json) async {
    try {
      final data = jsonDecode(json);
      _favorites = (data['favorites'] as List).map((j) => RadioStation.fromJson(j)).toList();
      _recentlyPlayed = (data['recently_played'] as List).map((j) => RadioStation.fromJson(j)).toList();
      _ratings = Map<String, double>.from(data['ratings'] ?? {});
      _notes = Map<String, String>.from(data['notes'] ?? {});
      await _saveFavorites();
      await _saveRecentlyPlayed();
      notifyListeners();
      return _favorites.length;
    } catch (e) {
      _errorMessage = 'خطأ في استيراد النسخة الاحتياطية';
      return 0;
    }
  }

  // ===== FAVORITES FOLDERS =====
  void setFavoritesFolder(String folder) {
    _selectedFavoritesFolder = folder;
    _prefs.setString('selected_folder', folder);
    notifyListeners();
  }

  // ===== SETTINGS =====
  Future<void> _loadSettings() async {
    _dataSaverMode = _prefs.getBool('data_saver_mode') ?? false;
    _selectedFavoritesFolder = _prefs.getString('selected_folder') ?? 'All';
    notifyListeners();
  }

  // ===== RECORDING =====
  Future<void> refreshRecordings() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _recordingsList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecording(String path) async {
    _recordingsList.removeWhere((r) => r.path == path);
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _audioService.dispose();
    super.dispose();
  }
}
