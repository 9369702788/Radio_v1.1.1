import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/radio_provider.dart';
import '../models/radio_station.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';
import '../services/ambient_sound_service.dart';
import 'battery_saver_screen.dart';
import 'car_mode_screen.dart';

// Standalone Live Animated Audio Spectrum Visualizer Widget (Top Level)
class LiveSpectrumVisualizer extends StatefulWidget {
  final bool isPlaying;
  const LiveSpectrumVisualizer({super.key, required this.isPlaying});

  @override
  State<LiveSpectrumVisualizer> createState() => _LiveSpectrumVisualizerState();
}

class _LiveSpectrumVisualizerState extends State<LiveSpectrumVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final heights = [
          widget.isPlaying ? (10.0 + 26.0 * (0.5 + 0.5 * (t * 1.8).remainder(1.0))) : 4.0,
          widget.isPlaying ? (14.0 + 30.0 * (0.5 + 0.5 * ((t + 0.2) * 1.5).remainder(1.0))) : 5.0,
          widget.isPlaying ? (8.0 + 24.0 * (0.5 + 0.5 * ((t + 0.4) * 2.1).remainder(1.0))) : 4.0,
          widget.isPlaying ? (18.0 + 28.0 * (0.5 + 0.5 * ((t + 0.6) * 1.4).remainder(1.0))) : 6.0,
          widget.isPlaying ? (12.0 + 34.0 * (0.5 + 0.5 * ((t + 0.1) * 2.3).remainder(1.0))) : 4.0,
          widget.isPlaying ? (20.0 + 26.0 * (0.5 + 0.5 * ((t + 0.8) * 1.7).remainder(1.0))) : 6.0,
          widget.isPlaying ? (16.0 + 32.0 * (0.5 + 0.5 * ((t + 0.3) * 1.9).remainder(1.0))) : 5.0,
          widget.isPlaying ? (22.0 + 24.0 * (0.5 + 0.5 * ((t + 0.5) * 2.2).remainder(1.0))) : 7.0,
          widget.isPlaying ? (14.0 + 30.0 * (0.5 + 0.5 * ((t + 0.7) * 1.6).remainder(1.0))) : 5.0,
          widget.isPlaying ? (10.0 + 26.0 * (0.5 + 0.5 * ((t + 0.2) * 2.0).remainder(1.0))) : 4.0,
          widget.isPlaying ? (16.0 + 28.0 * (0.5 + 0.5 * ((t + 0.9) * 1.3).remainder(1.0))) : 5.0,
          widget.isPlaying ? (8.0 + 22.0 * (0.5 + 0.5 * ((t + 0.4) * 2.4).remainder(1.0))) : 4.0,
        ];

        return SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in heights)
                Container(
                  width: 5,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent,
                        widget.isPlaying ? AppColors.accentPink : AppColors.cardBorder,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: widget.isPlaying
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, -2),
                            ),
                          ]
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  void _showSleepTimerDialog(BuildContext context, RadioProvider radio) {
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
              'مؤقت النوم الهادئ (مع الخفوت التدريجي) ⏳',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            for (final m in [15, 30, 45, 60, 90])
              ListTile(
                title: Text('$m دقيقة', style: const TextStyle(color: AppColors.textPrimary)),
                trailing: radio.sleepTimerMinutes == m ? const Icon(Icons.check, color: AppColors.accent) : null,
                onTap: () {
                  radio.setSmartFadeSleepTimer(m);
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

  void _showEqualizerSheet(BuildContext context, RadioProvider radio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
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

                // 3 Frequency Sliders (Bass, Mid, Treble)
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
          height: 100,
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
            // Floating Picture-in-Picture (PiP) 🎈
            IconButton(
              tooltip: 'مشغل عائم على الشاشة (PiP)',
              icon: const Icon(Icons.picture_in_picture_alt, color: AppColors.accent, size: 20),
              onPressed: () => radio.enterPictureInPicture(),
            ),
            // Ultra Battery Saver 🔋
            IconButton(
              tooltip: 'وضع توفير البطارية الأقصى',
              icon: const Icon(Icons.battery_saver, color: Colors.greenAccent, size: 20),
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
            // Equalizer Button 🎛️
            IconButton(
              tooltip: 'معادل الصوت و Bass Boost',
              icon: const Icon(Icons.tune, color: AppColors.accent, size: 20),
              onPressed: () => _showEqualizerSheet(context, radio),
            ),
            // Car Mode Button 🚗
            IconButton(
              tooltip: 'وضع القيادة في السيارة',
              icon: const Icon(Icons.directions_car, color: AppColors.accent, size: 20),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CarModeScreen()));
              },
            ),
            // Share Button
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
              onPressed: () => _shareStation(station),
            ),
            // Favorite Button
            IconButton(
              icon: Icon(
                station.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: station.isFavorite ? AppColors.accentPink : AppColors.textSecondary,
                size: 22,
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
              top: radio.oneHandedMode ? 120 : 0,
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
                        const SizedBox(width: 6),
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
                    width: 190,
                    height: 190,
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
                        padding: const EdgeInsets.all(24),
                        child: station.favicon.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: station.favicon,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => const Icon(Icons.radio, size: 70, color: AppColors.accent),
                              )
                            : const Icon(Icons.radio, size: 70, color: AppColors.accent),
                      ),
                    ),
                  ),
                ),

                // Live Audio Spectrum Visualizer (Animated) 📊
                LiveSpectrumVisualizer(isPlaying: radio.isPlaying),

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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${station.country}  ${station.countryCode.isNotEmpty ? "• " + station.countryCode : ""}',
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

                // Playback Controls Row
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Live Subtitles (CC) Toggle 🔤
                        IconButton(
                          tooltip: 'الترجمة النصية والمكتوبة للبث (CC)',
                          icon: Icon(
                            radio.subtitlesEnabled ? Icons.closed_caption : Icons.closed_caption_disabled,
                            color: radio.subtitlesEnabled ? AppColors.accent : AppColors.textSecondary,
                            size: 26,
                          ),
                          onPressed: () => radio.toggleSubtitles(),
                        ),

                        // Rewind 30s ⏪
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

                        // Big Play / Pause Button
                        GestureDetector(
                          onTap: () => radio.togglePlayPause(),
                          child: Container(
                            width: 68,
                            height: 68,
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
                                    size: 38,
                                  ),
                          ),
                        ),

                        // Sleep Timer ⏳
                        IconButton(
                          tooltip: 'مؤقت النوم',
                          icon: Icon(
                            Icons.timer_outlined,
                            color: radio.sleepTimerMinutes != null ? AppColors.accent : AppColors.textSecondary,
                            size: 26,
                          ),
                          onPressed: () => _showSleepTimerDialog(context, radio),
                        ),

                        // Live Recording Button 🔴
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
                              size: 26,
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
                          icon: const Icon(Icons.stop, color: AppColors.textSecondary, size: 26),
                          onPressed: () => radio.stop(),
                        ),
                      ],
                    ),

                    // Recording timer indicator
                    if (radio.isRecording) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'جاري التسجيل: ${radio.recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${radio.recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Volume Slider (with boost up to 150%)
                    Row(
                      children: [
                        const Icon(Icons.volume_down, color: AppColors.textSecondary, size: 20),
                        Expanded(
                          child: Slider(
                            value: radio.volume.clamp(0.0, 1.5),
                            max: 1.5,
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
