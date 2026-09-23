import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _initialized = true;
    } catch (_) {}
  }

  Future<void> play(String url) async {
    await initialize();
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<IcyMetadata?> get icyMetadataStream => _player.icyMetadataStream;
}
