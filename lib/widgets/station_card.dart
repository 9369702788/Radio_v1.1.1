import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/radio_station.dart';
import '../providers/radio_provider.dart';
import '../constants/app_colors.dart';

class StationCard extends StatelessWidget {
  final RadioStation station;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const StationCard({
    super.key,
    required this.station,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  void _showRatingAndNoteDialog(BuildContext context, RadioProvider radio) {
    int currentRating = radio.getStationRating(station.uuid);
    final noteCtrl = TextEditingController(text: radio.getStationNote(station.uuid) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تقييم المحطة بالنجوم ⭐:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int star = 1; star <= 5; star++)
                      IconButton(
                        icon: Icon(
                          star <= currentRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => currentRating = star);
                          radio.setStationRating(station.uuid, star);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('ملاحظة خاصة على الإذاعة 📝:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'مثال: موعد برنامجي المفضل الساعة 5 مساءً',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  radio.setStationNote(station.uuid, noteCtrl.text);
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ الملاحظة', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final rating = radio.getStationRating(station.uuid);
    final note = radio.getStationNote(station.uuid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.accent : AppColors.cardBorder,
          width: isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent ? AppColors.accent.withOpacity(0.15) : Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: () => _showRatingAndNoteDialog(context, radio),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceLight,
                        child: station.favicon.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: station.favicon,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.radio, color: AppColors.accent, size: 28),
                              )
                            : const Icon(Icons.radio, color: AppColors.accent, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  station.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrent ? AppColors.accent : AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Star rating if any
                              if (rating > 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    Text('$rating', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (station.countryCode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    station.countryCode,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  station.country.isNotEmpty ? station.country : 'عالمي',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              // Stream Health & Ping Indicator 📶
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.success.withOpacity(0.3), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle, color: AppColors.success, size: 6),
                                    const SizedBox(width: 3),
                                    Text(
                                      station.bitrate > 0 ? '${station.bitrate}k' : 'مستقر',
                                      style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent && isPlaying)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.graphic_eq, color: AppColors.accent, size: 20),
                      ),
                    IconButton(
                      icon: Icon(
                        station.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: station.isFavorite ? AppColors.accentPink : AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                  ],
                ),
                // Personal Note Tag if exists
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_note, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.amber, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
