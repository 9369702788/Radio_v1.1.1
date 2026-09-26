import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/radio_station.dart';
import 'dart:async';

class AudioService {
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  String? _currentMetadata;

  AudioService() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.icyMetadataStream.listen((meta) {
      _currentMetadata = meta?.info?.title;
    });
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _isInitialized = true;
    } catch (e) {
      print("Audio Init Error: $e");
    }
  }

  Future<void> playStation(RadioStation station) async {
    try {
      await _audioPlayer.setUrl(station.url);
      await _audioPlayer.play();
    } catch (e) {
      print("Play Error: $e");
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> resume() async => await _audioPlayer.play();

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  // Getters
  bool get isPlaying => _audioPlayer.playing;
  bool get isBuffering => _audioPlayer.processingState == ProcessingState.buffering;
  String? get currentMetadata => _currentMetadata;
  Stream<IcyMetadata?> get metadataStream => _audioPlayer.icyMetadataStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
