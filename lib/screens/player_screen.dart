import 'car_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/radio_provider.dart';
import '../models/radio_station.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});


  void _showEqualizerSheet(BuildContext context, RadioProvider radio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'معادل الصوت و Bass Boost 🎛️',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        radio.activePreset,
                        style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Presets Horizontal List
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in ['طبيعي', 'قرآن / صوت نقي', 'بيز قوي (Bass Boost)', 'كلاسيك', 'بوب', 'جاز'])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(p, style: const TextStyle(fontSize: 11)),
                            selected: radio.activePreset == p,
                            selectedColor: AppColors.accent,
                            backgroundColor: AppColors.surfaceLight,
                            labelStyle: TextStyle(
                              color: radio.activePreset == p ? Colors.black87 : AppColors.textPrimary,
                              fontWeight: radio.activePreset == p ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              radio.applyEqualizerPreset(p);
                              setSheetState(() {});
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3 Interactive Frequency Sliders (Bass, Mid, Treble)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFrequencySlider(
                      label: 'Bass\n(منخفض)',
                      value: radio.bassGain,
                      color: AppColors.accentPink,
                      onChanged: (val) {
                        radio.setEqualizerBands(bass: val);
                        setSheetState(() {});
                      },
                    ),
                    _buildFrequencySlider(
                      label: 'Vocal\n(متوسط)',
                      value: radio.midGain,
                      color: AppColors.accent,
                      onChanged: (val) {
                        radio.setEqualizerBands(mid: val);
                        setSheetState(() {});
                      },
                    ),
                    _buildFrequencySlider(
                      label: 'Treble\n(مرتفع)',
                      value: radio.trebleGain,
                      color: AppColors.primary,
                      onChanged: (val) {
                        radio.setEqualizerBands(treble: val);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Bass Boost Slider
                Row(
                  children: [
                    const Icon(Icons.speaker_group, color: AppColors.accentPink, size: 20),
                    const SizedBox(width: 10),
                    const Text('مضخم الترددات (Bass Boost):', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    const Spacer(),
                    Text('${(radio.bassBoost * 100).toInt()}%', style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: radio.bassBoost,
                  activeColor: AppColors.accentPink,
                  inactiveColor: AppColors.surfaceLight,
                  onChanged: (val) {
                    radio.setBassBoost(val);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildFrequencySlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(
          '${value > 0 ? "+" : ""}${value.toInt()} dB',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 110,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value.clamp(-10.0, 10.0),
              min: -10.0,
              max: 10.0,
              activeColor: color,
              inactiveColor: AppColors.surfaceLight,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  void _showSleepTimerDialog(BuildContext context, RadioProvider radio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مؤقت النوم ⏳',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            for (final m in [15, 30, 45, 60, 90])
              ListTile(
                title: Text('$m دقيقة', style: const TextStyle(color: AppColors.textPrimary)),
                trailing: radio.sleepTimerMinutes == m ? const Icon(Icons.check, color: AppColors.accent) : null,
                onTap: () {
                  radio.setSleepTimer(m);
                  Navigator.pop(ctx);
                },
              ),
            if (radio.sleepTimerMinutes != null)
              ListTile(
                title: const Text('إلغاء المؤقت', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  radio.setSleepTimer(0);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAlarmDialog(BuildContext context, RadioProvider radio) {
    TimeOfDay selectedTime = radio.alarmTime ?? const TimeOfDay(hour: 7, minute: 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'منبه الراديو ⏰',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (radio.alarmEnabled)
                      Switch(
                        value: radio.alarmEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (val) {
                          if (!val) {
                            radio.cancelAlarm();
                            setModalState(() {});
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'استيقظ يومياً على إذاعة: ${radio.currentStation?.name ?? "المحطة الحالية"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.access_time, color: AppColors.accent),
                    label: Text(
                      selectedTime.format(context),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (radio.currentStation != null) {
                        radio.setAlarm(time: selectedTime, station: radio.currentStation!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم ضبط منبه الراديو على الساعة ${selectedTime.format(context)} ⏰'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: const Text('حفظ وتفعيل المنبه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareStation(RadioStation station) {
    Share.share(
      'استمع معي إلى إذاعة "${station.name}" (${station.country}) مباشرة عبر تطبيق World Radio! 🌍📻\nرابط البث: ${station.url}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final station = radio.currentStation;

    if (station == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('لا توجد إذاعة مشغلة الآن', style: TextStyle(color: Colors.white))),
      );
    }

    return RadialGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'مشغل الراديو',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            // Equalizer Button 🎛️
            IconButton(
              tooltip: 'معادل الصوت و Bass Boost',
              icon: const Icon(Icons.tune, color: AppColors.accent),
              onPressed: () => _showEqualizerSheet(context, radio),
            ),
            // Car Mode Button 🚗
            IconButton(
              tooltip: 'وضع القيادة في السيارة',
              icon: const Icon(Icons.directions_car, color: AppColors.accent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarModeScreen()),
                );
              },
            ),
            // Share Button
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
              onPressed: () => _shareStation(station),
            ),
            // Favorite Button
            IconButton(
              icon: Icon(
                station.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: station.isFavorite ? AppColors.accentPink : AppColors.textSecondary,
              ),
              onPressed: () => radio.toggleFavorite(station),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Live Stream Title (ICY Metadata)
                if (radio.liveMetadataTitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.graphic_eq, color: AppColors.accent, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            radio.liveMetadataTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Station Vinyl Artwork
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: radio.isRecording ? AppColors.error : AppColors.accent.withOpacity(0.6),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (radio.isRecording ? AppColors.error : AppColors.accent).withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: station.favicon.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: station.favicon,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => const Icon(Icons.radio, size: 80, color: AppColors.accent),
                              )
                            : const Icon(Icons.radio, size: 80, color: AppColors.accent),
                      ),
                    ),
                  ),
                ),

                // Station Info
                Column(
                  children: [
                    Text(
                      station.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${station.country}  ${station.countryCode.isNotEmpty ? "• ${station.countryCode}" : ""}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),

                // Sound Modes Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final mode in ['طبيعي', 'صوت نقي (قرآن/كلام)', 'موسيقى غنية'])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(mode, style: const TextStyle(fontSize: 10)),
                          selected: radio.soundMode == mode,
                          selectedColor: AppColors.accent.withOpacity(0.25),
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: radio.soundMode == mode ? AppColors.accent : AppColors.textSecondary,
                            fontWeight: radio.soundMode == mode ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => radio.setSoundMode(mode),
                        ),
                      ),
                  ],
                ),

                // Controls Row: Timer, Play/Pause, Stop, Record 🔴, Alarm ⏰
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Sleep Timer
                        IconButton(
                          tooltip: 'مؤقت النوم',
                          icon: Icon(
                            Icons.timer_outlined,
                            color: radio.sleepTimerMinutes != null ? AppColors.accent : AppColors.textSecondary,
                            size: 26,
                          ),
                          onPressed: () => _showSleepTimerDialog(context, radio),
                        ),

                        // Alarm Clock
                        IconButton(
                          tooltip: 'منبه الراديو',
                          icon: Icon(
                            Icons.alarm,
                            color: radio.alarmEnabled ? AppColors.accent : AppColors.textSecondary,
                            size: 26,
                          ),
                          onPressed: () => _showAlarmDialog(context, radio),
                        ),

                        // Big Play/Pause
                        GestureDetector(
                          onTap: () => radio.togglePlayPause(),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: radio.isBuffering
                                ? const Center(
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Icon(
                                    radio.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                          ),
                        ),

                        // Live Audio Recording Button 🔴
                        IconButton(
                          tooltip: radio.isRecording ? 'إيقاف التسجيل' : 'تسجيل البث المباشر',
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: radio.isRecording ? AppColors.error.withOpacity(0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              radio.isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                              color: radio.isRecording ? AppColors.error : AppColors.textSecondary,
                              size: 28,
                            ),
                          ),
                          onPressed: () async {
                            if (radio.isRecording) {
                              final path = await radio.stopRecording();
                              if (context.mounted && path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم حفظ التسجيل بنجاح في قسم التسجيلات 🎙️'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else {
                              final ok = await radio.startRecording();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'بدأ تسجيل البث المباشر الآن 🔴' : 'تعذر بدء التسجيل'),
                                    backgroundColor: ok ? AppColors.error : AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),

                        // Stop
                        IconButton(
                          tooltip: 'إيقاف كامل',
                          icon: const Icon(Icons.stop, color: AppColors.textSecondary, size: 28),
                          onPressed: () => radio.stop(),
                        ),
                      ],
                    ),

                    // Recording timer indicator
                    if (radio.isRecording) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'جاري التسجيل: ${radio.recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${radio.recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Volume Slider
                    Row(
                      children: [
                        const Icon(Icons.volume_down, color: AppColors.textSecondary, size: 20),
                        Expanded(
                          child: Slider(
                            value: radio.volume,
                            activeColor: AppColors.accent,
                            inactiveColor: AppColors.surfaceLight,
                            onChanged: (val) => radio.setVolume(val),
                          ),
                        ),
                        const Icon(Icons.volume_up, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
