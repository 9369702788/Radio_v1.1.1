import 'battery_saver_screen.dart';
import 'vintage_dial_screen.dart';
import '../services/ambient_sound_service.dart';
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

  Widget _buildAudioSpectrumVisualizer(bool isPlaying) {
    const barHeights = [14.0, 26.0, 38.0, 20.0, 32.0, 42.0, 18.0, 28.0, 36.0, 22.0];
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < barHeights.length; i++)
            Container(
              width: 5,
              height: isPlaying ? barHeights[i] : 6.0,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentPink],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }


  void _showRemindersDialog(BuildContext context, RadioProvider radio) {
    final titleCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 13, minute: 0);
    List<int> selectedDays = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_month, color: AppColors.accent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'جدول البرامج والتنبيهات المجدولة 📅',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'إذاعة: ${radio.currentStation?.name ?? ""}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'اسم البرنامج (مثال: خطبة الجمعة، صلاة الفجر، أخبار الرياضة)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pick Time
                  Row(
                    children: [
                      const Text('وقت التنبيه والتشغيل:', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLight),
                        icon: const Icon(Icons.access_time, color: AppColors.accent, size: 18),
                        label: Text(selectedTime.format(context), style: const TextStyle(color: AppColors.textPrimary)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: selectedTime);
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Pick Days
                  const Text('الأيام المحددة:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      {'name': 'الجمعة', 'd': 5},
                      {'name': 'السبت', 'd': 6},
                      {'name': 'الأحد', 'd': 7},
                      {'name': 'الإثنين', 'd': 1},
                      {'name': 'الثلاثاء', 'd': 2},
                      {'name': 'الأربعاء', 'd': 3},
                      {'name': 'الخميس', 'd': 4},
                    ].map((item) {
                      final dayNum = item['d'] as int;
                      final isSel = selectedDays.contains(dayNum);
                      return FilterChip(
                        label: Text(item['name'] as String, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(color: isSel ? Colors.black87 : AppColors.textPrimary),
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedDays.add(dayNum);
                            } else {
                              selectedDays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.alarm_add, color: Colors.white),
                      label: const Text('إضافة إلى جدول التنبيهات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        if (radio.currentStation != null) {
                          radio.addReminder(
                            title: titleCtrl.text,
                            station: radio.currentStation!,
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                            days: selectedDays,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت إضافة البرنامج لجدول التنبيهات بنجاح! 📅'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // Existing Reminders List Preview
                  if (radio.reminders.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.cardBorder),
                    const Text('التنبيهات المجدولة حالياً:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    for (var r in radio.reminders)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_active, color: AppColors.accent, size: 20),
                        title: Text('${r.title} • ${r.formattedTime}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        subtitle: Text('${r.stationName} (${r.daysLabel})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          onPressed: () => radio.deleteReminder(r.id),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showAmbientSoundsDialog(BuildContext context) {
    final ambient = AmbientSoundService();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    const Icon(Icons.nature, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'أصوات الطبيعة والاسترخاء مع الراديو 🌧️',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (ambient.isPlaying)
                      IconButton(
                        icon: const Icon(Icons.stop_circle, color: AppColors.error),
                        onPressed: () async {
                          await ambient.stop();
                          setModalState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AmbientSoundService.ambientSounds.keys.map((sound) {
                    final isActive = ambient.activeSound == sound && ambient.isPlaying;
                    return ActionChip(
                      backgroundColor: isActive ? AppColors.accent : AppColors.surfaceLight,
                      label: Text(
                        sound,
                        style: TextStyle(
                          color: isActive ? Colors.black87 : AppColors.textPrimary,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onPressed: () async {
                        await ambient.playSound(sound);
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('مستوى صوت أصوات الطبيعة:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Slider(
                  value: ambient.volume,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceLight,
                  onChanged: (val) {
                    ambient.setVolume(val);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _searchCurrentTrack(BuildContext context, RadioProvider radio, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البحث عن المحتوى المذاع 🔍',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'المادة الحالية: "$title"',
              style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.translate, color: AppColors.accent),
              title: const Text('الترجمة الفورية للعربية 🌐', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text(radio.translateToText(title), style: const TextStyle(color: AppColors.accent, fontSize: 13)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('الترجمة: ' + radio.translateToText(title)),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.redAccent),
              title: const Text('البحث على YouTube', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('https://www.youtube.com/results?search_query=' + Uri.encodeComponent(title));
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blueAccent),
              title: const Text('البحث على Google', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('https://www.google.com/search?q=' + Uri.encodeComponent(title));
              },
            ),
          ],
        ),
      ),
    );
  }

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
                      for (final p in ['طبيعي', 'قرآن / صوت نقي', 'بيز قوي (Bass Boost)', 'صوت محيطي 3D (قاعة كبرى)', 'كلاسيك', 'بوب', 'جاز'])
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
            // Floating Picture-in-Picture (PiP) 🎈
            IconButton(
              tooltip: 'مشغل عائم على الشاشة (PiP)',
              icon: const Icon(Icons.picture_in_picture_alt, color: AppColors.accent),
              onPressed: () => radio.enterPictureInPicture(),
            ),
            // Live Subtitles (CC) 🔤
            IconButton(
              tooltip: 'الترجمة النصية والمكتوبة للبث (CC)',
              icon: Icon(
                radio.subtitlesEnabled ? Icons.closed_caption : Icons.closed_caption_disabled,
                color: radio.subtitlesEnabled ? AppColors.accent : Colors.white60,
              ),
              onPressed: () => radio.toggleSubtitles(),
            ),
            // One-Handed Reachability Toggle 📱
            IconButton(
              tooltip: 'وضع اليد الواحدة المريح',
              icon: Icon(
                Icons.pan_tool_alt,
                color: radio.oneHandedMode ? AppColors.accent : Colors.white70,
                size: 20,
              ),
              onPressed: () => radio.toggleOneHandedMode(),
            ),
            // Ultra Battery Saver 🔋
            IconButton(
              tooltip: 'وضع توفير البطارية الأقصى',
              icon: const Icon(Icons.battery_saver, color: Colors.greenAccent),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BatterySaverScreen()));
              },
            ),
            // Quick Recall Last Station ⚡
            if (radio.previousStation != null)
              IconButton(
                tooltip: 'التبديل لآخر إذاعة: ${radio.previousStation?.name}',
                icon: const Icon(Icons.history_toggle_off, color: AppColors.accent),
                onPressed: () => radio.quickRecallStation(),
              ),
            // Scheduled Reminder Button 📅
            IconButton(
              tooltip: 'تذكير ببرنامج إذاعي مجدول',
              icon: const Icon(Icons.calendar_month_outlined, color: AppColors.accent),
              onPressed: () => _showRemindersDialog(context, radio),
            ),
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
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: radio.oneHandedMode ? 140 : 0,
            ),
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
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _searchCurrentTrack(context, radio, radio.liveMetadataTitle!),
                          child: const Icon(Icons.search, color: AppColors.accentPink, size: 16),
                        ),
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

                // Live Subtitles Box (CC) 🔤
                if (radio.subtitlesEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.closed_caption, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            radio.liveSubtitleText,
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
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

                // Live Audio Spectrum Visualizer 📊
                _buildAudioSpectrumVisualizer(radio.isPlaying),

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

                // Stream Health & Ping Indicator Badge 📶
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: AppColors.success, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        'بث ممتاز • زمن الاستجابة ${radio.getStreamPing(station)}ms • ${station.bitrate > 0 ? "${station.bitrate} kbps" : "HQ Stereo"}',
                        style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

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
                        // Rewind 30s Button ⏪
                        IconButton(
                          tooltip: 'إرجاع 30 ثانية',
                          icon: const Icon(Icons.replay_30, color: AppColors.textSecondary, size: 26),
                          onPressed: () => radio.rewind30Seconds(),
                        ),
                        // Ambient Sounds Button 🌧️
                        IconButton(
                          tooltip: 'أصوات الطبيعة المرافقة',
                          icon: const Icon(Icons.water_drop_outlined, color: AppColors.accent, size: 26),
                          onPressed: () => _showAmbientSoundsDialog(context),
                        ),
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
