import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/radio_station.dart';
import '../models/recording_item.dart';
import '../services/radio_api_service.dart';
import '../services/audio_service.dart';
import '../services/recording_service.dart';
import '../services/ambient_sound_service.dart';

class RadioProvider extends ChangeNotifier {
  final RadioApiService _api = RadioApiService();
  final AudioService _audio = AudioService();
  final RecordingService _recorder = RecordingService();
  final AmbientSoundService _ambient = AmbientSoundService();

  List<RadioStation> _homeStations = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _history = [];
  List<RecordingItem> _recordingsList = [];

  RadioStation? _currentStation;
  RadioStation? _lastStation;
  bool _isLoading = false;
  String _activeFilterTitle = '🌍 كل المحطات';
  String? _selectedCountryCode;
  String? _selectedTag;
  int _offset = 0;
  bool _hasMore = true;
  bool _dataSaver = false;

  final Map<String, int> _ratings = {};
  final Map<String, String> _notes = {};
  int _totalListeningMinutes = 75;
  int _dailyStreak = 4;
  String _mostListenedStationName = 'إذاعة القرآن الكريم';

  // Getters
  List<RadioStation> get stations => _homeStations;
  List<RadioStation> get homeStations => _homeStations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get filteredFavorites => _favorites; // Solves filteredFavorites
  List<RadioStation> get history => _history;
  List<RecordingItem> get recordingsList => _recordingsList; // List<RecordingItem>
  RadioStation? get currentStation => _currentStation;
  bool get isLoading => _isLoading;
  bool get isPlaying => _audio.isPlaying;
  bool get isBuffering => _audio.isBuffering;
  bool get isRecording => _recorder.isRecording;
  bool get hasMore => _hasMore;
  bool get dataSaver => _dataSaver;
  String get activeFilterTitle => _activeFilterTitle;
  String? get selectedCountryCode => _selectedCountryCode;
  String? get selectedTag => _selectedTag;
  String get currentMetadata => _audio.currentMetadata.isNotEmpty ? _audio.currentMetadata : (_currentStation?.name ?? 'World Radio');
  String? get liveMetadataTitle => currentMetadata;
  int get totalListeningMinutes => _totalListeningMinutes;
  int get dailyStreak => _dailyStreak;
  String get mostListenedStationName => _mostListenedStationName;
  AmbientSoundService get ambient => _ambient;

  RadioProvider() {
    _init();
  }

  Future<void> _init() async {
    await _audio.initialize();
    await _loadLocalData();
    await loadInitialStations();
    await refreshRecordings();
  }

  Future<void> fetchHomeStations({String? countryCode, String? tag}) async {
    _selectedCountryCode = countryCode;
    _selectedTag = tag;
    await loadInitialStations();
  }

  Future<void> loadInitialStations() async {
    _isLoading = true;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    _homeStations = await _api.getStations(
      countryCode: _selectedCountryCode,
      tag: _selectedTag,
      offset: 0,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreHomeStations() async {
    if (_isLoading || !_hasMore) return;
    _offset += 500;
    final more = await _api.getStations(
      countryCode: _selectedCountryCode,
      tag: _selectedTag,
      offset: _offset,
    );
    if (more.isEmpty) {
      _hasMore = false;
    } else {
      _homeStations.addAll(more);
    }
    notifyListeners();
  }

  Future<void> filterByCountry(String code, String name) async {
    _selectedCountryCode = code;
    _selectedTag = null;
    _activeFilterTitle = name;
    await loadInitialStations();
  }

  Future<void> filterByTag(String tag, String name) async {
    _selectedTag = tag;
    _selectedCountryCode = null;
    _activeFilterTitle = name;
    await loadInitialStations();
  }

  Future<void> resetFilter() async {
    _selectedCountryCode = null;
    _selectedTag = null;
    _activeFilterTitle = '🌍 كل المحطات';
    await loadInitialStations();
  }

  void toggleDataSaver() {
    _dataSaver = !_dataSaver;
    notifyListeners();
  }

  Future<void> playStation(RadioStation station) async {
    try {
      if (_currentStation != null && _currentStation!.uuid != station.uuid) {
        _lastStation = _currentStation;
      }
      _currentStation = station;
      notifyListeners();
      await _audio.play(station);
      _addToHistory(station);
      _updateWidget();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> togglePlay() async {
    if (_audio.isPlaying) {
      await _audio.pause();
    } else {
      if (_currentStation != null) {
        await _audio.resume();
      }
    }
    _updateWidget();
    notifyListeners();
  }

  Future<void> togglePlayPause() => togglePlay();

  Future<void> stop() async {
    await _audio.stop();
    notifyListeners();
  }

  void skipForward() {
    final list = _favorites.isNotEmpty ? _favorites : _homeStations;
    if (list.isEmpty) return;
    int idx = list.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int nextIdx = (idx + 1) % list.length;
    playStation(list[nextIdx]);
  }

  void skipBackward() {
    final list = _favorites.isNotEmpty ? _favorites : _homeStations;
    if (list.isEmpty) return;
    int idx = list.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int prevIdx = (idx - 1 + list.length) % list.length;
    playStation(list[prevIdx]);
  }

  void quickRecall() {
    if (_lastStation != null) playStation(_lastStation!);
  }

  void playRandomStation() {
    if (_homeStations.isNotEmpty) {
      _homeStations.shuffle();
      playStation(_homeStations.first);
    }
  }

  Future<void> startRecording() async {
    if (_currentStation == null) return;
    await _recorder.startRecording(_currentStation!.url, _currentStation!.name);
    notifyListeners();
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecording();
    await refreshRecordings();
    notifyListeners();
  }

  Future<void> refreshRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recDir = Directory('${dir.path}/recordings');
      if (await recDir.exists()) {
        final files = recDir.listSync().whereType<File>().where((f) => f.path.endsWith('.mp3')).toList();
        _recordingsList = files.map((f) {
          final filename = f.path.split('/').last.replaceAll('.mp3', '');
          final parts = filename.split('_');
          final station = parts.isNotEmpty ? parts.first : 'تسجيل إذاعي';
          final stat = f.statSync();
          return RecordingItem(
            path: f.path,
            stationName: station,
            date: stat.modified,
            sizeBytes: stat.size,
          );
        }).toList();
      } else {
        _recordingsList = [];
      }
    } catch (_) {
      _recordingsList = [];
    }
    notifyListeners();
  }

  Future<void> deleteRecording(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
      await refreshRecordings();
    } catch (_) {}
  }

  void toggleFavorite(RadioStation station) {
    station.isFavorite = !station.isFavorite;
    if (station.isFavorite) {
      _favorites.add(station);
    } else {
      _favorites.removeWhere((s) => s.uuid == station.uuid);
    }
    _saveFavorites();
    notifyListeners();
  }

  void _addToHistory(RadioStation s) {
    _history.removeWhere((item) => item.uuid == s.uuid);
    _history.insert(0, s);
    if (_history.length > 50) _history.removeLast();
    _saveHistory();
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    notifyListeners();
  }

  void setStationRating(String uuid, int stars) {
    _ratings[uuid] = stars;
    _saveLocalMap('ratings', _ratings);
    notifyListeners();
  }

  int getStationRating(String uuid) => _ratings[uuid] ?? 0;

  void setStationNote(String uuid, String note) {
    _notes[uuid] = note;
    _saveLocalMap('notes', _notes);
    notifyListeners();
  }

  String getStationNote(String uuid) => _notes[uuid] ?? '';

  void _updateWidget() {
    try {
      const MethodChannel('com.worldradio.app/widget').invokeMethod('updateWidget', {
        'title': _currentStation?.name ?? 'World Radio',
        'desc': currentMetadata,
        'isPlaying': _audio.isPlaying,
      });
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favs', _favorites.map((s) => jsonEncode(s.toJson())).toList());
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('hist', _history.map((s) => jsonEncode(s.toJson())).toList());
  }

  Future<void> _saveLocalMap(String key, Map map) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(map));
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getStringList('favs') ?? [];
    _favorites = f.map((s) => RadioStation.fromJson(jsonDecode(s))).toList();
    final h = prefs.getStringList('hist') ?? [];
    _history = h.map((s) => RadioStation.fromJson(jsonDecode(s))).toList();
  }
}
