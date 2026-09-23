import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../constants/app_colors.dart';

class CarModeScreen extends StatelessWidget {
  const CarModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final station = radio.currentStation;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Exit button & Car Mode label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 36),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.directions_car, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'وضع القيادة',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      station?.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                      color: station?.isFavorite == true ? AppColors.accentPink : Colors.white70,
                      size: 36,
                    ),
                    onPressed: station != null ? () => radio.toggleFavorite(station) : null,
                  ),
                ],
              ),

              // Huge Station Title & Metadata
              Column(
                children: [
                  Text(
                    station?.name ?? 'لا توجد إذاعة',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    station != null ? '${station.country} • ${station.language}' : '',
                    style: const TextStyle(color: AppColors.accent, fontSize: 18),
                  ),
                  if (radio.liveMetadataTitle != null && radio.liveMetadataTitle!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        radio.liveMetadataTitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.accentPink, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),

              // Giant Controls: Prev Favorite, Huge Play/Pause, Next Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Favorite
                  IconButton(
                    iconSize: 64,
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => radio.playPreviousFavorite(),
                  ),

                  // Giant Play / Pause button
                  GestureDetector(
                    onTap: () => radio.togglePlayPause(),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        radio.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 72,
                      ),
                    ),
                  ),

                  // Next Favorite
                  IconButton(
                    iconSize: 64,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => radio.playNextFavorite(),
                  ),
                ],
              ),

              // Huge Volume Row with Mute & Boost
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        radio.volume == 0 ? Icons.volume_off : Icons.volume_down,
                        color: Colors.white70,
                        size: 32,
                      ),
                      onPressed: () => radio.setVolume(radio.volume == 0 ? 1.0 : 0.0),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 12,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
                        ),
                        child: Slider(
                          value: radio.volume.clamp(0.0, 1.5),
                          max: 1.5,
                          activeColor: AppColors.accent,
                          inactiveColor: Colors.white24,
                          onChanged: (val) => radio.setVolume(val),
                        ),
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white70, size: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
