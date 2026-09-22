import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/radio_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

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
            ...[15, 30, 45, 60].map(
              (m) => ListTile(
                title: Text('$m دقيقة', style: const TextStyle(color: AppColors.textPrimary)),
                trailing: radio.sleepTimerMinutes == m ? const Icon(Icons.check, color: AppColors.accent) : null,
                onTap: () {
                  radio.setSleepTimer(m);
                  Navigator.pop(ctx);
                },
              ),
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
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.accent.withOpacity(0.6), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
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
                    const SizedBox(height: 8),
                    Text(
                      '${station.country}  ${station.countryCode.isNotEmpty ? "• " + station.countryCode : ""}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    if (station.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: station.tags.take(3).map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text('#$t', style: const TextStyle(color: AppColors.accent, fontSize: 11)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.timer_outlined,
                            color: radio.sleepTimerMinutes != null ? AppColors.accent : AppColors.textSecondary,
                            size: 26,
                          ),
                          onPressed: () => _showSleepTimerDialog(context, radio),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => radio.togglePlayPause(),
                          child: Container(
                            width: 76,
                            height: 76,
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
                                    size: 42,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.stop, color: AppColors.textSecondary, size: 30),
                          onPressed: () => radio.stop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
