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

  static const int _batchSize = 500;

  // Home Screen stations and active filter
  List<RadioStation> _homeStations = [];
  String? _selectedCountryCode;
  String? _selectedCountryName;
  String? _selectedTag;
  String? _selectedTagName;
  String _activeFilterTitle = 'أشهر الإذاعات العالمية';

  // Pagination state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Search Screen stations
  List<RadioStation> _searchResults = [];
  bool _isSearching = false;

  // Favorites & History
  List<RadioStation> _favorites = [];
  final List<RadioStation> _history = [];

  RadioStation? _currentStation;
  String? _errorMessage;
  double _volume = 1.0;
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;

  List<RadioStation> get homeStations => _homeStations;
  String? get selectedCountryCode => _selectedCountryCode;
  String? get selectedTag => _selectedTag;
  String get activeFilterTitle => _activeFilterTitle;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isSearching => _isSearching;

  List<RadioStation> get searchResults => _searchResults;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get history => _history;
  RadioStation? get currentStation => _currentStation;
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

  // Load Top Global Stations
  Future<void> loadTopStations() async {
    _isLoading = true;
    _errorMessage = null;
    _selectedCountryCode = null;
    _selectedCountryName = null;
    _selectedTag = null;
    _selectedTagName = null;
    _activeFilterTitle = 'أشهر الإذاعات العالمية';
    _hasMore = true;
    notifyListeners();

    try {
      final list = await _api.getTopStations(limit: _batchSize, offset: 0);
      _homeStations = list;
      _syncFavorites(_homeStations);
      _hasMore = list.length >= _batchSize;
    } catch (e) {
      _errorMessage = 'تعذر تحميل الإذاعات، تحقق من الاتصال بالإنترنت';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter Home Screen by Country
  Future<void> filterByCountry(String countryCode, String countryName) async {
    if (_selectedCountryCode == countryCode) {
      await loadTopStations();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _selectedCountryCode = countryCode;
    _selectedCountryName = countryName;
    _selectedTag = null;
    _selectedTagName = null;
    _activeFilterTitle = 'إذاعات $countryName';
    _hasMore = true;
    notifyListeners();

    try {
      final list = await _api.getStationsByCountry(countryCode, limit: _batchSize, offset: 0);
      _homeStations = list;
      _syncFavorites(_homeStations);
      _hasMore = list.length >= _batchSize;
    } catch (e) {
      _errorMessage = 'تعذر تحميل إذاعات $countryName';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter Home Screen by Tag/Category
  Future<void> filterByTag(String tag, String tagName) async {
    if (_selectedTag == tag) {
      await loadTopStations();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _selectedTag = tag;
    _selectedTagName = tagName;
    _selectedCountryCode = null;
    _selectedCountryName = null;
    _activeFilterTitle = 'إذاعات $tagName';
    _hasMore = true;
    notifyListeners();

    try {
      final list = await _api.getStationsByTag(tag, limit: _batchSize, offset: 0);
      _homeStations = list;
      _syncFavorites(_homeStations);
      _hasMore = list.length >= _batchSize;
    } catch (e) {
      _errorMessage = 'تعذر تحميل إذاعات $tagName';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Infinite Scroll: Load next batch of 500 stations
  Future<void> loadMoreHomeStations() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextOffset = _homeStations.length;
    List<RadioStation> nextBatch = [];

    try {
      if (_selectedCountryCode != null) {
        nextBatch = await _api.getStationsByCountry(_selectedCountryCode!, limit: _batchSize, offset: nextOffset);
      } else if (_selectedTag != null) {
        nextBatch = await _api.getStationsByTag(_selectedTag!, limit: _batchSize, offset: nextOffset);
      } else {
        nextBatch = await _api.getTopStations(limit: _batchSize, offset: nextOffset);
      }

      if (nextBatch.isEmpty) {
        _hasMore = false;
      } else {
        // Prevent duplicates
        final existingIds = _homeStations.map((s) => s.uuid).toSet();
        final filteredBatch = nextBatch.where((s) => !existingIds.contains(s.uuid)).toList();
        _homeStations.addAll(filteredBatch);
        _syncFavorites(_homeStations);
        _hasMore = nextBatch.length >= _batchSize;
      }
    } catch (_) {
      // Keep existing list on pagination error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Search Screen search
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
      final list = await _api.searchStations(query, limit: _batchSize);
      _searchResults = list;
      _syncFavorites(_searchResults);
    } catch (e) {
      _errorMessage = 'تعذر إتمام البحث';
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
      _errorMessage = 'تعذر تشغيل هذا الرابط الصوتي، جرب إذاعة أخرى';
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
    if (_history.length > 50) {
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

    _syncFavorites(_homeStations);
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
