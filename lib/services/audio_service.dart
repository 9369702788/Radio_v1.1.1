import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  bool _initialized = false;
  String? _lastUrl;
  int _retryCount = 0;
  Timer? _reconnectTimer;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Smart Feature 1: Pause automatically when headphones / Bluetooth disconnect (becoming noisy)
      session.becomingNoisyEventStream.listen((_) {
        pause();
      });

      // Smart Feature 2: Listen for stream errors and auto-reconnect
      _player.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          _handleStreamError();
        },
      );

      _initialized = true;
    } catch (_) {}
  }

  Future<void> play(String url) async {
    await initialize();
    _lastUrl = url;
    _retryCount = 0;
    _reconnectTimer?.cancel();
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _handleStreamError();
      rethrow;
    }
  }

  void _handleStreamError() {
    if (_lastUrl == null || _retryCount >= 3) return;
    _retryCount++;
    final delay = Duration(seconds: _retryCount * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        if (_lastUrl != null) {
          await _player.setUrl(_lastUrl!);
          await _player.play();
          _retryCount = 0;
        }
      } catch (_) {}
    });
  }

  Future<void> pause() async {
    _reconnectTimer?.cancel();
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    _reconnectTimer?.cancel();
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.5));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<IcyMetadata?> get icyMetadataStream => _player.icyMetadataStream;
}
