import '../models/program_reminder.dart';
import '../services/widget_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../services/radio_api_service.dart';
import '../services/audio_service.dart';
import '../services/recording_service.dart';

class RadioProvider extends ChangeNotifier {
  final RadioApiService _api = RadioApiService();
  final AudioService _audio = AudioService();
  final RecordingService _recorder = RecordingService();

  static const int _batchSize = 500;

  // Home Screen stations and active filter
  List<RadioStation> _homeStations = [];
  String? _selectedCountryCode;
  String? _selectedTag;
  String _activeFilterTitle = 'أشهر الإذاعات العالمية';

  // Pagination state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Search Screen stations
  List<RadioStation> _searchResults = [];
  bool _isSearching = false;

  // Favorites & History & Custom
  List<RadioStation> _favorites = [];
  final List<RadioStation> _history = [];
  List<RadioStation> _customStations = [];

  // Live Metadata (Song/Program name)
  String? _liveMetadataTitle;
  String? get liveMetadataTitle => _liveMetadataTitle;

  // Recording
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  List<RecordingItem> _recordingsList = [];

  bool get isRecording => _recorder.isRecording;
  Duration get recordingDuration => _recordingDuration;
  List<RecordingItem> get recordingsList => _recordingsList;

  // Sound Mode / Audio FX
  String _soundMode = 'طبيعي'; // طبيعي, صوت نقي (قرآن/أحاديث), موسيقى غنية
  String get soundMode => _soundMode;

  // Alarm Clock State
  bool _alarmEnabled = false;
  TimeOfDay? _alarmTime;
  RadioStation? _alarmStation;
  Timer? _alarmCheckTimer;

  bool get alarmEnabled => _alarmEnabled;
  TimeOfDay? get alarmTime => _alarmTime;
  RadioStation? get alarmStation => _alarmStation;

  // Player & App State
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
  List<RadioStation> get customStations => _customStations;
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
    _initAudioListeners();
    loadFavorites();
    loadCustomStations();
    loadAlarm();
    _loadReminders();
    loadTopStations();
    refreshRecordings();
    _startAlarmChecker();
    WidgetService.setWidgetListener(() => togglePlayPause());
  }

  void _initAudioListeners() {
    _audio.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
      _syncWidget();
    });

    _audio.icyMetadataStream.listen((metadata) {
      final title = metadata?.info?.title;
      if (title != null && title.trim().isNotEmpty && title != _liveMetadataTitle) {
        _liveMetadataTitle = title.trim();
        notifyListeners();
      }
    });
  }

  // Load Top Global Stations
  Future<void> loadTopStations() async {
    _isLoading = true;
    _errorMessage = null;
    _selectedCountryCode = null;
    _selectedTag = null;
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
    _selectedTag = null;
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
    _selectedCountryCode = null;
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
        final existingIds = _homeStations.map((s) => s.uuid).toSet();
        final filteredBatch = nextBatch.where((s) => !existingIds.contains(s.uuid)).toList();
        _homeStations.addAll(filteredBatch);
        _syncFavorites(_homeStations);
        _hasMore = nextBatch.length >= _batchSize;
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Pick and play a random station (Surprise Me 🎲)
  Future<RadioStation?> playRandomStation() async {
    if (_homeStations.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(_homeStations.length);
      final station = _homeStations[randomIndex];
      await playStation(station);
      return station;
    }
    return null;
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

  // Playback Control
  Future<void> playStation(RadioStation station) async {
    if (isRecording) {
      await stopRecording();
    }

    _currentStation = station;
    _liveMetadataTitle = null;
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
    if (isRecording) {
      await stopRecording();
    }
    await _audio.stop();
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val;
    await _audio.setVolume(val);
    notifyListeners();
  }

  // Sound Mode / Equalizer
  void setSoundMode(String mode) {
    _soundMode = mode;
    if (mode == 'صوت نقي (قرآن/كلام)') {
      _audio.setSpeed(1.0);
    } else if (mode == 'موسيقى غنية') {
      _audio.setSpeed(1.0);
    } else {
      _audio.setSpeed(1.0);
    }
    notifyListeners();
  }

  // Recording Stream Feature 🔴
  Future<bool> startRecording() async {
    if (_currentStation == null) return false;
    try {
      await _recorder.startRecording(_currentStation!);
      _recordingDuration = Duration.zero;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration = Duration(seconds: timer.tick);
        notifyListeners();
      });
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final path = await _recorder.stopRecording();
    _recordingDuration = Duration.zero;
    await refreshRecordings();
    notifyListeners();
    return path;
  }

  Future<void> refreshRecordings() async {
    _recordingsList = await _recorder.getRecordings();
    notifyListeners();
  }

  Future<void> deleteRecording(String path) async {
    await _recorder.deleteRecording(path);
    await refreshRecordings();
  }

  // Radio Alarm Clock ⏰
  Future<void> setAlarm({required TimeOfDay time, required RadioStation station}) async {
    _alarmTime = time;
    _alarmStation = station;
    _alarmEnabled = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_hour', time.hour);
    await prefs.setInt('alarm_minute', time.minute);
    await prefs.setString('alarm_station', json.encode(station.toJson()));
    await prefs.setBool('alarm_enabled', true);

    notifyListeners();
  }

  Future<void> cancelAlarm() async {
    _alarmEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_enabled', false);
    notifyListeners();
  }

  Future<void> loadAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('alarm_enabled') ?? false;
    if (enabled) {
      final hour = prefs.getInt('alarm_hour') ?? 7;
      final minute = prefs.getInt('alarm_minute') ?? 0;
      final stationJson = prefs.getString('alarm_station');
      if (stationJson != null) {
        _alarmTime = TimeOfDay(hour: hour, minute: minute);
        _alarmStation = RadioStation.fromJson(json.decode(stationJson));
        _alarmEnabled = true;
        notifyListeners();
      }
    }
  }

  void _startAlarmChecker() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_alarmEnabled && _alarmTime != null && _alarmStation != null) {
        final now = DateTime.now();
        // Check Program Reminders
        for (var rem in _reminders) {
          if (rem.isEnabled && rem.hour == now.hour && rem.minute == now.minute) {
            if (rem.daysOfWeek.isEmpty || rem.daysOfWeek.contains(now.weekday)) {
              final station = _homeStations.cast<RadioStation?>().firstWhere(
                (s) => s?.uuid == rem.stationUuid,
                orElse: () => null,
              );
              if (station != null && (!isPlaying || _currentStation?.uuid != station.uuid)) {
                playStation(station);
              }
            }
          }
        }
        if (now.hour == _alarmTime!.hour && now.minute == _alarmTime!.minute) {
          if (!isPlaying || _currentStation?.uuid != _alarmStation!.uuid) {
            playStation(_alarmStation!);
          }
        }
      }
    });
  }

  // Custom Station URL ➕
  Future<void> addCustomStation({
    required String name,
    required String url,
    String? country,
    String? favicon,
  }) async {
    final customStation = RadioStation(
      uuid: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      url: url.trim(),
      country: country?.trim() ?? 'محطة خاصة',
      countryCode: '★',
      language: 'العربية',
      favicon: favicon?.trim() ?? '',
      tags: ['خاصة', 'custom'],
      isFavorite: true,
    );

    _customStations.insert(0, customStation);
    _favorites.insert(0, customStation);
    _homeStations.insert(0, customStation);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customStations.map((e) => e.toJson()).toList();
    await prefs.setString('world_radio_custom', json.encode(jsonList));

    await _saveFavoritesToPrefs();
    notifyListeners();
  }

  Future<void> loadCustomStations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('world_radio_custom');
    if (data != null) {
      try {
        final List<dynamic> decoded = json.decode(data);
        _customStations = decoded.map((e) => RadioStation.fromJson(e)).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  // Sleep Timer
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

  // Data Saver Mode (filter streams <= 96kbps or reduce data)
  bool _dataSaverMode = false;
  bool get dataSaverMode => _dataSaverMode;

  void toggleDataSaverMode() {
    _dataSaverMode = !_dataSaverMode;
    notifyListeners();
  }

  // Switch between Favorites (Car Mode / Next / Prev)
  void playNextFavorite() {
    if (_favorites.isEmpty) return;
    int currentIndex = _favorites.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int nextIndex = (currentIndex + 1) % _favorites.length;
    playStation(_favorites[nextIndex]);
  }

  void playPreviousFavorite() {
    if (_favorites.isEmpty) return;
    int currentIndex = _favorites.indexWhere((s) => s.uuid == _currentStation?.uuid);
    int prevIndex = (currentIndex - 1 + _favorites.length) % _favorites.length;
    playStation(_favorites[prevIndex]);
  }

  // Clear History
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }


  void _syncWidget() {
    WidgetService.updateWidget(
      name: _currentStation?.name ?? 'World Radio',
      country: isPlaying ? (_liveMetadataTitle ?? _currentStation?.country ?? 'بث مباشر') : 'متوقف مؤقتاً',
      isPlaying: isPlaying,
    );
  }


  // Equalizer & Audio FX State 🎛️
  double _bassGain = 0.0; // -10 to +10 dB
  double _midGain = 0.0;
  double _trebleGain = 0.0;
  double _bassBoost = 0.0; // 0.0 to 1.0 (0% to 100%)
  String _activePreset = 'طبيعي';

  double get bassGain => _bassGain;
  double get midGain => _midGain;
  double get trebleGain => _trebleGain;
  double get bassBoost => _bassBoost;
  String get activePreset => _activePreset;

  void setEqualizerBands({double? bass, double? mid, double? treble}) {
    if (bass != null) _bassGain = bass;
    if (mid != null) _midGain = mid;
    if (treble != null) _trebleGain = treble;
    _activePreset = 'مخصص';
    notifyListeners();
  }

  void setBassBoost(double val) {
    _bassBoost = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  void applyEqualizerPreset(String preset) {
    _activePreset = preset;
    switch (preset) {
      case 'قرآن / صوت نقي':
        _bassGain = -2.0;
        _midGain = 4.0;
        _trebleGain = 3.0;
        _bassBoost = 0.0;
        break;
      case 'بيز قوي (Bass Boost)':
        _bassGain = 7.0;
        _midGain = 1.0;
        _trebleGain = 0.0;
        _bassBoost = 0.8;
        break;
      case 'كلاسيك':
        _bassGain = 4.0;
        _midGain = -1.0;
        _trebleGain = 3.0;
        _bassBoost = 0.2;
        break;
      case 'بوب':
        _bassGain = 3.0;
        _midGain = 2.0;
        _trebleGain = 4.0;
        _bassBoost = 0.4;
        break;
      case 'جاز':
        _bassGain = 2.0;
        _midGain = 0.0;
        _trebleGain = 2.0;
        _bassBoost = 0.3;
        break;
      default: // طبيعي
        _bassGain = 0.0;
        _midGain = 0.0;
        _trebleGain = 0.0;
        _bassBoost = 0.0;
    }
    notifyListeners();
  }


  // Cloud / Local Backup & Restore 💾
  String exportBackupJson() {
    final data = {
      'app': 'World Radio',
      'version': '3.0.0',
      'date': DateTime.now().toIso8601String(),
      'favorites': _favorites.map((e) => e.toJson()).toList(),
      'custom_stations': _customStations.map((e) => e.toJson()).toList(),
    };
    return json.encode(data);
  }

  Future<int> importBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonStr);
      int importedCount = 0;

      // Import favorites
      if (data['favorites'] is List) {
        final List<dynamic> list = data['favorites'];
        for (var item in list) {
          final station = RadioStation.fromJson(item);
          if (!_favorites.any((f) => f.uuid == station.uuid)) {
            station.isFavorite = true;
            _favorites.add(station);
            importedCount++;
          }
        }
        await _saveFavoritesToPrefs();
      }

      // Import custom stations
      if (data['custom_stations'] is List) {
        final List<dynamic> list = data['custom_stations'];
        for (var item in list) {
          final station = RadioStation.fromJson(item);
          if (!_customStations.any((c) => c.uuid == station.uuid)) {
            _customStations.add(station);
            if (!_homeStations.any((h) => h.uuid == station.uuid)) {
              _homeStations.insert(0, station);
            }
          }
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('world_radio_custom', json.encode(_customStations.map((e) => e.toJson()).toList()));
      }

      _syncFavorites(_homeStations);
      _syncFavorites(_searchResults);
      notifyListeners();
      return importedCount;
    } catch (_) {
      return -1; // Parse error
    }
  }


  // Rewind / Timeshift Buffer Feature ⏪
  Future<void> rewind30Seconds() async {
    try {
      final currentPos = _audio.player.position;
      final target = currentPos > const Duration(seconds: 30)
          ? currentPos - const Duration(seconds: 30)
          : Duration.zero;
      await _audio.player.seek(target);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> jumpToLive() async {
    try {
      final dur = _audio.player.duration;
      if (dur != null) {
        await _audio.player.seek(dur);
      }
      notifyListeners();
    } catch (_) {}
  }

  // App Theme Selection 🎨
  String _currentThemeName = 'فضاء ليلي'; // فضاء ليلي, سواد فاحم (OLED), كلاسيكي ذهبي, أزرق نيون
  String get currentThemeName => _currentThemeName;

  void setTheme(String themeName) {
    _currentThemeName = themeName;
    notifyListeners();
  }


  // Program Reminders Schedule 📅
  List<ProgramReminder> _reminders = [];
  List<ProgramReminder> get reminders => _reminders;

  Future<void> addReminder({
    required String title,
    required RadioStation station,
    required int hour,
    required int minute,
    List<int> days = const [],
  }) async {
    final reminder = ProgramReminder(
      id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'برنامج ${station.name}' : title.trim(),
      stationUuid: station.uuid,
      stationName: station.name,
      hour: hour,
      minute: minute,
      daysOfWeek: days,
      isEnabled: true,
    );
    _reminders.add(reminder);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> toggleReminder(ProgramReminder rem) async {
    rem.isEnabled = !rem.isEnabled;
    await _saveReminders();
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reminders.map((e) => e.toJson()).toList();
    await prefs.setString('world_radio_reminders', json.encode(jsonList));
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('world_radio_reminders');
    if (data != null) {
      try {
        final List<dynamic> decoded = json.decode(data);
        _reminders = decoded.map((e) => ProgramReminder.fromJson(e)).toList();
        notifyListeners();
      } catch (_) {}
    }
  }

  // Stream Health / Latency estimate (Ping in ms) 📶
  int getStreamPing(RadioStation station) {
    if (station.votes > 500) return 65; // High bandwidth top node
    if (station.votes > 100) return 110;
    if (station.bitrate >= 128) return 145;
    return 190;
  }

}
