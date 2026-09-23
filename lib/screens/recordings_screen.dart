import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/radio_provider.dart';
import '../services/recording_service.dart';
import '../constants/app_colors.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final AudioPlayer _localAudioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  bool _isPlayingLocal = false;

  @override
  void initState() {
    super.initState();
    _localAudioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingLocal = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _currentlyPlayingPath = null;
            _isPlayingLocal = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _localAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playLocalRecording(String path) async {
    if (_currentlyPlayingPath == path && _isPlayingLocal) {
      await _localAudioPlayer.pause();
    } else {
      context.read<RadioProvider>().stop();
      _currentlyPlayingPath = path;
      await _localAudioPlayer.setFilePath(path);
      await _localAudioPlayer.play();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final recordings = radio.recordingsList;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'التسجيلات المحفوظة 🎙️',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => radio.refreshRecordings(),
          ),
        ],
      ),
      body: recordings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.mic_none, size: 72, color: AppColors.surfaceLight),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد تسجيلات بعد',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'أثناء الاستماع لأي إذاعة، اضغط على زر التسجيل 🔴 في مشغل الراديو لحفظ مقاطعك المفضلة هنا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final rec = recordings[index];
                final isPlayingThis = _currentlyPlayingPath == rec.path && _isPlayingLocal;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isPlayingThis ? AppColors.surfaceLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPlayingThis ? AppColors.accent : AppColors.cardBorder,
                      width: isPlayingThis ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: GestureDetector(
                      onTap: () => _playLocalRecording(rec.path),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isPlayingThis ? AppColors.accent : AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlayingThis ? Icons.pause : Icons.play_arrow,
                          color: isPlayingThis ? Colors.black87 : AppColors.accent,
                          size: 28,
                        ),
                      ),
                    ),
                    title: Text(
                      rec.stationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(rec.date),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        Text(
                          _formatBytes(rec.sizeBytes),
                          style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Share Recording
                        IconButton(
                          icon: const Icon(Icons.share, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            Share.shareXFiles(
                              [XFile(rec.path)],
                              text: 'تسجيل من إذاعة ${rec.stationName} عبر World Radio 📻',
                            );
                          },
                        ),
                        // Delete Recording
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () async {
                            if (_currentlyPlayingPath == rec.path) {
                              await _localAudioPlayer.stop();
                              _currentlyPlayingPath = null;
                            }
                            radio.deleteRecording(rec.path);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
