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

  static const Map<String, String> ambientSounds = {
    'مطر واسترخاء 🌧️': 'https://ice2.somafm.com/dronezone-128-mp3',
    'أمواج بحر وهدوء 🌊': 'https://ice4.somafm.com/deepspaceone-128-mp3',
    'مقهى وموسيقى هادئة ☕': 'https://ice1.somafm.com/groovesalad-128-mp3',
    'طبيعة وغابات 🕊️': 'https://ice2.somafm.com/secretagent-128-mp3',
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
    try {
      await _ambientPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
    _activeSound = null;
  }
}
