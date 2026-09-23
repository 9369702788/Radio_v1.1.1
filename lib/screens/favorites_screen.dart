import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _showBackupDialog(BuildContext context, RadioProvider radio) {
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
              'النسخ الاحتياطي والمزامنة 💾',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.upload, color: AppColors.accent),
              title: const Text('تصدير نسخة احتياطية (مشاركة/حفظ)', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('حفظ جميع إذاعاتك المفضلة والخاصة في ملف backup', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                final backup = radio.exportBackupJson();
                Share.share(backup, subject: 'World Radio Backup.json');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.accentPink),
              title: const Text('استعادة نسخة احتياطية من نص أو ملف', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('استرجاع قنواتك المفضلة فوراً عند تغيير الهاتف', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showImportDialog(context, radio);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, RadioProvider radio) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('استعادة نسخة احتياطية 📥', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الصق كود النسخة الاحتياطية (JSON) هنا:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{"app": "World Radio"...}',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
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
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final count = await radio.importBackupJson(textCtrl.text.trim());
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count >= 0 ? 'تمت استعادة $count إذاعة بنجاح! 🎉' : 'صيغة النسخة غير صالحة'),
                    backgroundColor: count >= 0 ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('استعادة الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            AppStrings.favorites,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Backup & Restore button
            IconButton(
              tooltip: 'النسخ الاحتياطي والمزامنة',
              icon: const Icon(Icons.backup_outlined, color: AppColors.accent),
              onPressed: () => _showBackupDialog(context, radio),
            ),
            // Share all favorites
            if (radio.favorites.isNotEmpty)
              IconButton(
                tooltip: 'مشاركة قائمة قنواتي المفضلة',
                icon: const Icon(Icons.share, color: AppColors.textSecondary),
                onPressed: () {
                  final listText = radio.favorites
                      .take(15)
                      .map((s) => '• ${s.name} (${s.country})')
                      .join('\n');
                  Share.share(
                    'إذاعاتي المفضلة عبر تطبيق World Radio 📻:\n$listText\n\nحمّل التطبيق واستمع لآلاف المحطات مجاناً!',
                  );
                },
              ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'المفضلة'),
              Tab(icon: Icon(Icons.history), text: 'سجل الاستماع'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Favorites Tab
            Column(
              children: [
                
            // Folders Filter Chips Bar 📁
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final f in ['الكل', 'قرآن', 'أخبار', 'رياضة'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          f == 'قرآن' ? '📖 قرآن وتلاوات' : f == 'أخبار' ? '📰 أخبار' : f == 'رياضة' ? '⚽ رياضة' : '📁 كل المفضلة',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: radio.selectedFavoritesFolder == f ? Colors.black87 : AppColors.textPrimary),
                        ),
                        selected: radio.selectedFavoritesFolder == f,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surface,
                        onSelected: (_) => radio.setFavoritesFolder(f),
                      ),
                    ),
                ],
              ),
            ),

                Expanded(
                  child: radio.filteredFavorites.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.favorite_border, size: 64, color: AppColors.surfaceLight),
                              SizedBox(height: 14),
                              Text('لا توجد إذاعات في هذا المجلد', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90, top: 6),
                          itemCount: radio.filteredFavorites.length,
                          itemBuilder: (context, index) {
                            final station = radio.filteredFavorites[index];
                            return StationCard(
                              station: station,
                              isCurrent: radio.currentStation?.uuid == station.uuid,
                              isPlaying: radio.isPlaying,
                              onTap: () => radio.playStation(station),
                              onFavoriteToggle: () => radio.toggleFavorite(station),
                            );
                          },
                        ),
                ),
              ],
            ),
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.favorite_border, size: 64, color: AppColors.surfaceLight),
                        SizedBox(height: 14),
                        Text(AppStrings.noFavorites, style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )


            // History Tab with Clear button
            radio.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.history, size: 64, color: AppColors.surfaceLight),
                        SizedBox(height: 14),
                        Text('لا يوجد سجل استماع بعد', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'آخر ${radio.history.length} إذاعات استمعت إليها',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_sweep, size: 18, color: AppColors.error),
                              label: const Text('مسح السجل', style: TextStyle(color: AppColors.error, fontSize: 12)),
                              onPressed: () => radio.clearHistory(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: radio.history.length,
                          itemBuilder: (context, index) {
                            final station = radio.history[index];
                            return StationCard(
                              station: station,
                              isCurrent: radio.currentStation?.uuid == station.uuid,
                              isPlaying: radio.isPlaying,
                              onTap: () => radio.playStation(station),
                              onFavoriteToggle: () => radio.toggleFavorite(station),
                            );
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
