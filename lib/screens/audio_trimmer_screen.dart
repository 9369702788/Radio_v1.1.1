import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../services/recording_service.dart';
import '../constants/app_colors.dart';

class AudioTrimmerScreen extends StatefulWidget {
  final RecordingItem recording;

  const AudioTrimmerScreen({super.key, required this.recording});

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  final AudioPlayer _player = AudioPlayer();
  Duration _totalDuration = Duration.zero;
  RangeValues _currentRange = const RangeValues(0, 30);
  bool _isPlaying = false;
  bool _isTrimming = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final dur = await _player.setFilePath(widget.recording.path);
      if (dur != null && mounted) {
        setState(() {
          _totalDuration = dur;
          _currentRange = RangeValues(0, dur.inSeconds > 30 ? 30 : dur.inSeconds.toDouble());
        });
      }
    } catch (_) {}

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.seek(Duration(seconds: _currentRange.start.toInt()));
      await _player.play();
    }
  }

  Future<void> _saveTrimmedAudio() async {
    setState(() => _isTrimming = true);
    try {
      final originalFile = File(widget.recording.path);
      final bytes = await originalFile.readAsBytes();

      // Estimate byte offsets based on duration
      if (_totalDuration.inSeconds > 0) {
        final totalSec = _totalDuration.inSeconds;
        final startRatio = (_currentRange.start / totalSec).clamp(0.0, 1.0);
        final endRatio = (_currentRange.end / totalSec).clamp(0.0, 1.0);

        final startByte = (bytes.length * startRatio).toInt();
        final endByte = (bytes.length * endRatio).toInt();
        final trimmedBytes = bytes.sublist(startByte, endByte);

        final dir = originalFile.parent.path;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final trimmedPath = '$dir/Trim_${widget.recording.fileName.replaceAll('.mp3', '')}_$timestamp.mp3';

        final trimmedFile = File(trimmedPath);
        await trimmedFile.writeAsBytes(trimmedBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ المقطع المقصوص بنجاح في قسم التسجيلات! ✂️🎉'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء قص المقطع'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isTrimming = false);
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final maxSec = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds.toDouble() : 60.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'محرر وقص التسجيلات ✂️',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Station and File Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.music_note, color: AppColors.accent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    widget.recording.stationName,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'المدة الإجمالية: ${_formatTime(maxSec)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Visual Range Slider
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('البداية: ${_formatTime(_currentRange.start)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    Text(
                      'مدة المقطع: ${_formatTime(_currentRange.end - _currentRange.start)}',
                      style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold),
                    ),
                    Text('النهاية: ${_formatTime(_currentRange.end)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                RangeSlider(
                  values: _currentRange,
                  min: 0,
                  max: maxSec,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceLight,
                  onChanged: (values) {
                    if (values.end - values.start >= 3) {
                      setState(() => _currentRange = values);
                    }
                  },
                ),
              ],
            ),

            // Play Preview Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.accent),
                  label: Text(_isPlaying ? 'إيقاف المعاينة' : 'معاينة المقطع المقصوص', style: const TextStyle(color: Colors.white)),
                  onPressed: _togglePreview,
                ),
              ],
            ),

            // Action Buttons: Save & Share
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isTrimming
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.content_cut, color: Colors.white),
                    label: const Text('حفظ المقطع المقصوص 💾', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _isTrimming ? null : _saveTrimmedAudio,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share, color: AppColors.accent),
                    label: const Text('مشاركة المقطع فوراً 📤', style: TextStyle(color: AppColors.accent, fontSize: 15)),
                    onPressed: () {
                      Share.shareXFiles([XFile(widget.recording.path)], text: 'مقطع من إذاعة ${widget.recording.stationName}');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
