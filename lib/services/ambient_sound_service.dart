import 'package:just_audio/just_audio.dart';

class AmbientSoundService {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  AmbientSoundService._internal();

  final AudioPlayer _ambientPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _activeSound;
  double _volume = 0.5;

  bool get isPlaying => _isPlaying;
  String? get activeSound => _activeSound;
  double get volume => _volume;

  // Curated high quality looping stream URLs for ambient nature sounds
  static const Map<String, String> ambientSounds = {
    'مطر هادئ 🌧️': 'https://stream.zeno.fm/f3wvbbqmdg8uv', // Relaxing rain stream
    'أمواج البحر 🌊': 'https://stream.zeno.fm/0r0xa792kwzuv', // Ocean waves stream
    'عصافير وطبيعة 🕊️': 'https://stream.zeno.fm/s492v4d71tzuv', // Forest birds stream
    'موقد نار دافئ 🔥': 'https://stream.zeno.fm/99mkg0q71tzuv', // Fireplace crackle stream
  };

  Future<void> playSound(String soundName) async {
    final url = ambientSounds[soundName];
    if (url == null) return;

    if (_activeSound == soundName && _isPlaying) {
      await stop();
      return;
    }

    try {
      await _ambientPlayer.stop();
      _activeSound = soundName;
      await _ambientPlayer.setUrl(url);
      await _ambientPlayer.setVolume(_volume);
      await _ambientPlayer.play();
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _ambientPlayer.setVolume(_volume);
  }

  Future<void> stop() async {
    await _ambientPlayer.stop();
    _isPlaying = false;
    _activeSound = null;
  }
}
