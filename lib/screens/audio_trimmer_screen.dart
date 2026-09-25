import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recording_item.dart';
import '../constants/app_colors.dart';

class AudioTrimmerScreen extends StatefulWidget {
  final RecordingItem recording;
  const AudioTrimmerScreen({Key? key, required this.recording}) : super(key: key);

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  RangeValues _values = const RangeValues(0, 30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('قص وتعديل التسجيل ✂️'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audio_file, color: AppColors.accent, size: 72),
            const SizedBox(height: 16),
            Text(widget.recording.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 32),
            RangeSlider(
              values: _values,
              min: 0,
              max: 120,
              activeColor: AppColors.accent,
              onChanged: (val) => setState(() => _values = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('البداية: ${_values.start.toInt()} ثانية', style: const TextStyle(color: Colors.white70)),
                Text('النهاية: ${_values.end.toInt()} ثانية', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.cut),
              label: const Text('حفظ المقطع المقصوص'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ المقطع بنجاح!')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
