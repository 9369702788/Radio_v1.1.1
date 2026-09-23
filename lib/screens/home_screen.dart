import 'vintage_dial_screen.dart';
import 'insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'map_explorer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, String>> _quickCountries = [
    {'name': 'مصر', 'code': 'EG', 'flag': '🇪🇬'},
    {'name': 'السعودية', 'code': 'SA', 'flag': '🇸🇦'},
    {'name': 'الإمارات', 'code': 'AE', 'flag': '🇦🇪'},
    {'name': 'المغرب', 'code': 'MA', 'flag': '🇲🇦'},
    {'name': 'الجزائر', 'code': 'DZ', 'flag': '🇩🇿'},
    {'name': 'الأردن', 'code': 'JO', 'flag': '🇯🇴'},
    {'name': 'تونس', 'code': 'TN', 'flag': '🇹🇳'},
    {'name': 'العراق', 'code': 'IQ', 'flag': '🇮🇶'},
    {'name': 'الكويت', 'code': 'KW', 'flag': '🇰🇼'},
    {'name': 'قطر', 'code': 'QA', 'flag': '🇶🇦'},
    {'name': 'عُمان', 'code': 'OM', 'flag': '🇴🇲'},
    {'name': 'لبنان', 'code': 'LB', 'flag': '🇱🇧'},
    {'name': 'فلسطين', 'code': 'PS', 'flag': '🇵🇸'},
    {'name': 'بريطانيا', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'أمريكا', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'فرنسا', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'ألمانيا', 'code': 'DE', 'flag': '🇩🇪'},
    {'name': 'تركيا', 'code': 'TR', 'flag': '🇹🇷'},
    {'name': 'إسبانيا', 'code': 'ES', 'flag': '🇪🇸'},
    {'name': 'روسيا', 'code': 'RU', 'flag': '🇷🇺'},
    {'name': 'إيطاليا', 'code': 'IT', 'flag': '🇮🇹'},
    {'name': 'البرازيل', 'code': 'BR', 'flag': '🇧🇷'},
  ];

  static const List<Map<String, String>> _categories = [
    {'name': 'قرآن كريم', 'tag': 'quran', 'icon': '📖'},
    {'name': 'إذاعات إسلامية', 'tag': 'islamic', 'icon': '🕌'},
    {'name': 'أخبار', 'tag': 'news', 'icon': '📰'},
    {'name': 'إذاعات عربية', 'tag': 'arabic', 'icon': '🎙️'},
    {'name': 'رياضة', 'tag': 'sports', 'icon': '⚽'},
    {'name': 'كلاسيك', 'tag': 'classical', 'icon': '🎻'},
    {'name': 'بوب', 'tag': 'pop', 'icon': '🎸'},
    {'name': 'جاز', 'tag': 'jazz', 'icon': '🎷'},
    {'name': 'روك', 'tag': 'rock', 'icon': '🥁'},
    {'name': 'إذاعات دينية', 'tag': 'religious', 'icon': '🤲'},
    {'name': 'أطفال', 'tag': 'kids', 'icon': '🎈'},
    {'name': 'حديث وتوك شو', 'tag': 'talk', 'icon': '💬'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      context.read<RadioProvider>().loadMoreHomeStations();
    }
  }

  void _showThemeDialog(BuildContext context, RadioProvider radio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
              const SizedBox(height: 14),
              const Text(
                'ألوان وثيم التطبيق 🎨',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              for (final th in ['فضاء ليلي 🌌', 'سواد فاحم (OLED) 🖤', 'كلاسيكي ذهبي 📻', 'أزرق نيون ⚡'])
                ListTile(
                  title: Text(th, style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: radio.currentThemeName == th.split(' ')[0] ? const Icon(Icons.check, color: AppColors.accent) : null,
                  onTap: () {
                    radio.setTheme(th.split(' ')[0]);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomStationDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final countryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'إضافة إذاعة خاصة ➕',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'اسم الإذاعة *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'رابط البث المباشر (Stream URL) *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: 'https://...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'الدولة (اختياري)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && urlCtrl.text.trim().isNotEmpty) {
                context.read<RadioProvider>().addCustomStation(
                  name: nameCtrl.text.trim(),
                  url: urlCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت إضافة الإذاعة بنجاح إلى المفضلة والرئيسية! 🎉'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('إضافة الإذاعة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.radio, color: AppColors.accent, size: 24),
            SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // 0. Vintage Dial Button 📻
          IconButton(
            tooltip: 'راديو تناظري كلاسيكي',
            icon: const Icon(Icons.dialpad, color: Color(0xFFE5C07B), size: 22),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VintageDialScreen()));
            },
          ),
          // 1. Interactive Globe / Map Button 🗺️
          IconButton(
            tooltip: 'خريطة العالم التفاعلية',
            icon: const Icon(Icons.public, color: AppColors.accent, size: 22),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapExplorerScreen()));
            },
          ),

          // 2. Surprise Me Dice 🎲
          IconButton(
            tooltip: 'محطة عشوائية حول العالم',
            icon: const Icon(Icons.casino_outlined, color: AppColors.accentPink, size: 22),
            onPressed: () async {
              final st = await radio.playRandomStation();
              if (context.mounted && st != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('إذاعة عشوائية: ${st.name} (${st.country}) 🎲'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
          ),

          // 3. Add Custom Station ➕
          IconButton(
            tooltip: 'إضافة إذاعة خاصة',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent, size: 22),
            onPressed: () => _showAddCustomStationDialog(context),
          ),

          // 4. More Options Popup Menu (Data Saver, Theme, Refresh) ⋮
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'insights') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsScreen()));
              } else if (val == 'theme') {
                _showThemeDialog(context, radio);
              } else if (val == 'datasaver') {
                radio.toggleDataSaverMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      radio.dataSaverMode
                          ? 'تم تفعيل وضع توفير الباقة 📶 (بث خفيف)'
                          : 'تم تعطيل وضع توفير الباقة (جودة فائقة)',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: radio.dataSaverMode ? AppColors.accent : AppColors.surfaceLight,
                  ),
                );
              } else if (val == 'refresh') {
                radio.loadTopStations();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'insights',
                child: Row(
                  children: [
                    Icon(Icons.insights, color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Text('إحصائيات الاستماع 📊', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'datasaver',
                child: Row(
                  children: [
                    Icon(
                      radio.dataSaverMode ? Icons.data_saver_on : Icons.data_saver_off,
                      color: radio.dataSaverMode ? AppColors.accent : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      radio.dataSaverMode ? 'توفير الباقة: مُفعّل 📶' : 'توفير باقة النت',
                      style: TextStyle(color: radio.dataSaverMode ? AppColors.accent : AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: AppColors.accentPink, size: 20),
                    SizedBox(width: 10),
                    Text('ألوان وثيم التطبيق 🎨', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Text('تحديث الإذاعات العالمية 🔄', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => radio.loadTopStations(),
        color: AppColors.accent,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // Hero Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4834D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
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
                    'راديو العالم المباشر 🌍',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'استمع لآلاف المحطات الإذاعية المباشرة. انزل لأسفل لتنزيل المزيد من الإذاعات باستمرار بدون توقف.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            // Countries Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    AppStrings.countries,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (radio.selectedCountryCode != null)
                    TextButton(
                      onPressed: () => radio.loadTopStations(),
                      child: const Text('إلغاء التصفية', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Countries Horizontal List
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Global "All" Chip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: radio.selectedCountryCode == null && radio.selectedTag == null,
                      showCheckmark: false,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: (radio.selectedCountryCode == null && radio.selectedTag == null)
                            ? AppColors.accent
                            : AppColors.cardBorder,
                      ),
                      label: Text(
                        '🌍 كل العالم',
                        style: TextStyle(
                          color: (radio.selectedCountryCode == null && radio.selectedTag == null)
                              ? Colors.black87
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onSelected: (_) => radio.loadTopStations(),
                    ),
                  ),
                  for (final c in _quickCountries)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: radio.selectedCountryCode == c['code'],
                        showCheckmark: false,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: (radio.selectedCountryCode == c['code'])
                              ? AppColors.accent
                              : AppColors.cardBorder,
                          width: (radio.selectedCountryCode == c['code']) ? 1.5 : 1.0,
                        ),
                        label: Text(
                          '${c['flag']}  ${c['name']}',
                          style: TextStyle(
                            color: (radio.selectedCountryCode == c['code']) ? Colors.black87 : AppColors.textPrimary,
                            fontWeight: (radio.selectedCountryCode == c['code']) ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        onSelected: (_) => radio.filterByCountry(c['code']!, c['name']!),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Categories Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    AppStrings.categories,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (radio.selectedTag != null)
                    TextButton(
                      onPressed: () => radio.loadTopStations(),
                      child: const Text('إلغاء التصفية', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Categories Horizontal List
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final cat in _categories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: radio.selectedTag == cat['tag'],
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: (radio.selectedTag == cat['tag']) ? AppColors.primary : AppColors.cardBorder,
                          width: (radio.selectedTag == cat['tag']) ? 1.5 : 1.0,
                        ),
                        label: Text(
                          '${cat['icon']}  ${cat['name']}',
                          style: TextStyle(
                            color: (radio.selectedTag == cat['tag']) ? Colors.white : AppColors.textPrimary,
                            fontWeight: (radio.selectedTag == cat['tag']) ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        onSelected: (_) => radio.filterByTag(cat['tag']!, cat['name']!),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Active Title + Count Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    radio.activeFilterTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!radio.isLoading && radio.homeStations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${radio.homeStations.length} إذاعة مُحمّلة',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Loading / Error / Empty / Stations List
            if (radio.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 12),
                      Text('جاري جلب مئات الإذاعات...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
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
            else if (radio.homeStations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.radio, color: AppColors.surfaceLight, size: 56),
                      const SizedBox(height: 12),
                      const Text('لا توجد إذاعات متاحة في هذا الاختيار حالياً', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => radio.loadTopStations(),
                        child: const Text('العودة للرئيسية', style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              for (final station in (radio.dataSaverMode 
                  ? radio.homeStations.where((s) => s.bitrate <= 128).toList() 
                  : radio.homeStations))
                StationCard(
                  station: station,
                  isCurrent: radio.currentStation?.uuid == station.uuid,
                  isPlaying: radio.isPlaying,
                  onTap: () => radio.playStation(station),
                  onFavoriteToggle: () => radio.toggleFavorite(station),
                ),

              // Bottom Loader for Infinite Scroll
              if (radio.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'جاري تحميل المزيد من المحطات...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
