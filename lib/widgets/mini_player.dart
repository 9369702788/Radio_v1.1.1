import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/radio_provider.dart';
import '../constants/app_colors.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final station = radio.currentStation;

    if (station == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withOpacity(0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: radio.isRecording ? AppColors.error : AppColors.accent.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (radio.isRecording ? AppColors.error : AppColors.accent).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  color: AppColors.surface,
                  child: station.favicon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: station.favicon,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.radio, color: AppColors.accent),
                        )
                      : const Icon(Icons.radio, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      radio.isRecording
                          ? '🔴 جاري التسجيل...'
                          : (radio.liveMetadataTitle != null && radio.liveMetadataTitle!.isNotEmpty)
                              ? radio.liveMetadataTitle!
                              : radio.isBuffering
                                  ? 'جاري التحميل...'
                                  : radio.isPlaying
                                      ? 'بث مباشر الآن'
                                      : 'متوقف مؤقتاً',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: radio.isRecording
                            ? AppColors.error
                            : radio.isPlaying
                                ? AppColors.accent
                                : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: radio.isRecording ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: radio.isBuffering
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      )
                    : Icon(
                        radio.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: AppColors.accent,
                        size: 36,
                      ),
                onPressed: () => radio.togglePlayPause(),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => radio.stop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
