import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const List<Map<String, String>> _quickCountries = [
    {'name': 'مصر', 'code': 'EG', 'flag': '🇪🇬'},
    {'name': 'السعودية', 'code': 'SA', 'flag': '🇸🇦'},
    {'name': 'الإمارات', 'code': 'AE', 'flag': '🇦🇪'},
    {'name': 'المغرب', 'code': 'MA', 'flag': '🇲🇦'},
    {'name': 'بريطانيا', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'أمريكا', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'فرنسا', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'ألمانيا', 'code': 'DE', 'flag': '🇩🇪'},
  ];

  static const List<Map<String, String>> _categories = [
    {'name': 'قرآن كريم', 'tag': 'quran', 'icon': '📖'},
    {'name': 'أخبار', 'tag': 'news', 'icon': '📰'},
    {'name': 'موسيقى كلاسيكية', 'tag': 'classical', 'icon': '🎻'},
    {'name': 'بوب', 'tag': 'pop', 'icon': '🎸'},
    {'name': 'جاز', 'tag': 'jazz', 'icon': '🎷'},
    {'name': 'رياضة', 'tag': 'sports', 'icon': '⚽'},
  ];

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.radio, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => radio.loadTopStations(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => radio.loadTopStations(),
        color: AppColors.accent,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4834D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'أهلاً بك في راديو العالم 🌍',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'استمع مباشرة لأكثر من 40,000 محطة إذاعية من كافة أنحاء العالم بأعلى جودة وبدون انقطاع.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppStrings.countries,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickCountries.length,
                itemBuilder: (context, index) {
                  final c = _quickCountries[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.cardBorder),
                      label: Text('${c['flag']}  ${c['name']}'),
                      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      onPressed: () => radio.fetchByCountry(c['code']!),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppStrings.categories,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.cardBorder),
                      label: Text('${cat['icon']}  ${cat['name']}'),
                      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      onPressed: () => radio.fetchByTag(cat['tag']!),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppStrings.topStations,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (radio.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (radio.errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(radio.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => radio.loadTopStations(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...radio.topStations.map(
                (station) => StationCard(
                  station: station,
                  isCurrent: radio.currentStation?.uuid == station.uuid,
                  isPlaying: radio.isPlaying,
                  onTap: () => radio.playStation(station),
                  onFavoriteToggle: () => radio.toggleFavorite(station),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
