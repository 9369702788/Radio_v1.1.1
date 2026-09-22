import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../services/radio_api_service.dart';
import '../services/audio_service.dart';

class RadioProvider extends ChangeNotifier {
  final RadioApiService _api = RadioApiService();
  final AudioService _audio = AudioService();

  List<RadioStation> _topStations = [];
  List<RadioStation> _searchResults = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _history = [];

  RadioStation? _currentStation;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  double _volume = 1.0;
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;

  List<RadioStation> get topStations => _topStations;
  List<RadioStation> get searchResults => _searchResults;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get history => _history;
  RadioStation? get currentStation => _currentStation;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  double get volume => _volume;
  int? get sleepTimerMinutes => _sleepTimerMinutes;

  PlayerState? _playerState;
  PlayerState? get playerState => _playerState;

  bool get isPlaying => _playerState?.playing ?? false;
  bool get isBuffering =>
      _playerState?.processingState == ProcessingState.buffering ||
      _playerState?.processingState == ProcessingState.loading;

  RadioProvider() {
    _initAudioListener();
    loadFavorites();
    loadTopStations();
  }

  void _initAudioListener() {
    _audio.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });
  }

  Future<void> loadTopStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.getTopStations(limit: 60);
      _topStations = list;
      _syncFavorites(_topStations);
    } catch (e) {
      _errorMessage = 'تعذر تحميل الإذاعات، تحقق من الاتصال';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.searchStations(query);
      _searchResults = list;
      _syncFavorites(_searchResults);
    } catch (e) {
      _errorMessage = 'تعذر إتمام البحث';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> fetchByCountry(String countryCode) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.getStationsByCountry(countryCode);
      _searchResults = list;
      _syncFavorites(_searchResults);
    } catch (e) {
      _errorMessage = 'تعذر تحميل إذاعات هذه الدولة';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> fetchByTag(String tag) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.getStationsByTag(tag);
      _searchResults = list;
      _syncFavorites(_searchResults);
    } catch (e) {
      _errorMessage = 'تعذر تحميل إذاعات هذا التصنيف';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> playStation(RadioStation station) async {
    _currentStation = station;
    _errorMessage = null;
    notifyListeners();

    _addToHistory(station);

    try {
      await _audio.play(station.url);
    } catch (e) {
      _errorMessage = 'تعذر تشغيل هذا الرابط الصوتي';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentStation == null) return;
    if (isPlaying) {
      await _audio.pause();
    } else {
      await _audio.resume();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _audio.stop();
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val;
    await _audio.setVolume(val);
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      _sleepTimerMinutes = null;
      notifyListeners();
      return;
    }

    _sleepTimerMinutes = minutes;
    notifyListeners();

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      stop();
      _sleepTimerMinutes = null;
      notifyListeners();
    });
  }

  void _addToHistory(RadioStation station) {
    _history.removeWhere((s) => s.uuid == station.uuid);
    _history.insert(0, station);
    if (_history.length > 30) {
      _history.removeLast();
    }
  }

  Future<void> toggleFavorite(RadioStation station) async {
    final exists = _favorites.any((s) => s.uuid == station.uuid);
    if (exists) {
      _favorites.removeWhere((s) => s.uuid == station.uuid);
      station.isFavorite = false;
    } else {
      station.isFavorite = true;
      _favorites.insert(0, station);
    }

    _syncFavorites(_topStations);
    _syncFavorites(_searchResults);
    if (_currentStation?.uuid == station.uuid) {
      _currentStation!.isFavorite = station.isFavorite;
    }

    notifyListeners();
    await _saveFavoritesToPrefs();
  }

  void _syncFavorites(List<RadioStation> list) {
    for (var s in list) {
      s.isFavorite = _favorites.any((f) => f.uuid == s.uuid);
    }
  }

  Future<void> _saveFavoritesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _favorites.map((e) => e.toJson()).toList();
    await prefs.setString('world_radio_favorites', json.encode(jsonList));
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('world_radio_favorites');
    if (data != null) {
      try {
        final List<dynamic> decoded = json.decode(data);
        _favorites = decoded.map((e) => RadioStation.fromJson(e)).toList();
        for (var f in _favorites) {
          f.isFavorite = true;
        }
        notifyListeners();
      } catch (_) {}
    }
  }
}
