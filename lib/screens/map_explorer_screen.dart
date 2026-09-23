import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';

class MapCityPin {
  final String name;
  final String countryCode;
  final String flag;
  final double x; // Pixel coordinates on a 1200 x 700 virtual canvas
  final double y;
  final String region; // عربي, أوروبا, آسيا, أمريكا, أوقيانوسيا

  const MapCityPin({
    required this.name,
    required this.countryCode,
    required this.flag,
    required this.x,
    required this.y,
    required this.region,
  });
}

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final TransformationController _transController = TransformationController();
  static const double _canvasWidth = 1300.0;
  static const double _canvasHeight = 750.0;

  // Well-spaced coordinates with minimum 80px distance between adjacent pins!
  static const List<MapCityPin> _pins = [
    // الوطن العربي والشرق الأوسط (موزعة بمسافات مريحة وواضحة جداً)
    MapCityPin(name: 'القاهرة', countryCode: 'EG', flag: '🇪🇬', x: 670, y: 310, region: 'عربي'),
    MapCityPin(name: 'مكة / الرياض', countryCode: 'SA', flag: '🇸🇦', x: 740, y: 370, region: 'عربي'),
    MapCityPin(name: 'دبي', countryCode: 'AE', flag: '🇦🇪', x: 810, y: 360, region: 'عربي'),
    MapCityPin(name: 'بغداد', countryCode: 'IQ', flag: '🇮🇶', x: 720, y: 280, region: 'عربي'),
    MapCityPin(name: 'القدس / عمّان', countryCode: 'PS', flag: '🇵🇸', x: 690, y: 290, region: 'عربي'),
    MapCityPin(name: 'تونس', countryCode: 'TN', flag: '🇹🇳', x: 600, y: 260, region: 'عربي'),
    MapCityPin(name: 'الجزائر', countryCode: 'DZ', flag: '🇩🇿', x: 550, y: 275, region: 'عربي'),
    MapCityPin(name: 'الدار البيضاء', countryCode: 'MA', flag: '🇲🇦', x: 480, y: 290, region: 'عربي'),

    // أوروبا (متباعدة تماماً)
    MapCityPin(name: 'إسطنبول', countryCode: 'TR', flag: '🇹🇷', x: 680, y: 240, region: 'أوروبا'),
    MapCityPin(name: 'روما', countryCode: 'IT', flag: '🇮🇹', x: 610, y: 220, region: 'أوروبا'),
    MapCityPin(name: 'مدريد', countryCode: 'ES', flag: '🇪🇸', x: 510, y: 240, region: 'أوروبا'),
    MapCityPin(name: 'باريس', countryCode: 'FR', flag: '🇫🇷', x: 550, y: 190, region: 'أوروبا'),
    MapCityPin(name: 'لندن', countryCode: 'GB', flag: '🇬🇧', x: 520, y: 160, region: 'أوروبا'),
    MapCityPin(name: 'برلين', countryCode: 'DE', flag: '🇩🇪', x: 600, y: 160, region: 'أوروبا'),
    MapCityPin(name: 'موسكو', countryCode: 'RU', flag: '🇷🇺', x: 730, y: 140, region: 'أوروبا'),

    // آسيا وأوقيانوسيا
    MapCityPin(name: 'طوكيو', countryCode: 'JP', flag: '🇯🇵', x: 1080, y: 290, region: 'آسيا'),
    MapCityPin(name: 'سيدني', countryCode: 'AU', flag: '🇦🇺', x: 1120, y: 580, region: 'أوقيانوسيا'),

    // الأمريكتين
    MapCityPin(name: 'نيويورك', countryCode: 'US', flag: '🇺🇸', x: 300, y: 240, region: 'أمريكا'),
    MapCityPin(name: 'ريو دي جانيرو', countryCode: 'BR', flag: '🇧🇷', x: 410, y: 530, region: 'أمريكا'),
  ];

  MapCityPin? _selectedPin;
  String _selectedRegion = 'الكل';

  @override
  void initState() {
    super.initState();
    // Center initially on Middle East / Cairo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final dx = -(670 - size.width / 2);
      final dy = -(310 - size.height / 2);
      _transController.value = Matrix4.identity()..translate(dx, dy);
    });
  }

  void _flyToRegion(String region) {
    setState(() => _selectedRegion = region);
    final size = MediaQuery.of(context).size;
    double targetX = 670;
    double targetY = 310;

    if (region == 'عربي') {
      targetX = 670; targetY = 310;
    } else if (region == 'أوروبا') {
      targetX = 580; targetY = 200;
    } else if (region == 'أمريكا') {
      targetX = 350; targetY = 350;
    } else if (region == 'آسيا') {
      targetX = 1000; targetY = 320;
    }

    final dx = -(targetX - size.width / 2);
    final dy = -(targetY - size.height / 2);
    _transController.value = Matrix4.identity()..translate(dx, dy);
  }

  void _onPinTapped(MapCityPin pin) {
    setState(() => _selectedPin = pin);
    final radio = context.read<RadioProvider>();
    radio.filterByCountry(pin.countryCode, pin.name);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Consumer<RadioProvider>(
          builder: (ctx, r, _) => Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '${pin.flag}  إذاعات ${pin.name}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${r.homeStations.length} إذاعة',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: r.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : ListView.builder(
                          itemCount: r.homeStations.length,
                          itemBuilder: (ctx, index) {
                            final station = r.homeStations[index];
                            return StationCard(
                              station: station,
                              isCurrent: r.currentStation?.uuid == station.uuid,
                              isPlaying: r.isPlaying,
                              onTap: () {
                                r.playStation(station);
                                Navigator.pop(ctx);
                              },
                              onFavoriteToggle: () => r.toggleFavorite(station),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'خريطة العالم التفاعلية 🗺️',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Spacious Panoramic Interactive Viewer (Constrained false = full smooth space!)
          InteractiveViewer(
            transformationController: _transController,
            minScale: 0.7,
            maxScale: 3.5,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            child: Container(
              width: _canvasWidth,
              height: _canvasHeight,
              color: const Color(0xFF0A0F1A),
              child: Stack(
                children: [
                  // Stylized Globe Grid & Continents
                  CustomPaint(
                    size: const Size(_canvasWidth, _canvasHeight),
                    painter: _SpaciousGlobePainter(),
                  ),

                  // Pins with plenty of breathing space
                  for (final pin in _pins)
                    Positioned(
                      left: pin.x - 30,
                      top: pin.y - 25,
                      child: GestureDetector(
                        onTap: () => _onPinTapped(pin),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedPin?.countryCode == pin.countryCode
                                    ? AppColors.accent
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedPin?.countryCode == pin.countryCode
                                      ? Colors.white
                                      : AppColors.accent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Text(pin.flag, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder, width: 0.8),
                              ),
                              child: Text(
                                pin.name,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Region Quick Navigation Tabs at Top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final r in ['الكل', 'عربي', 'أوروبا', 'أمريكا', 'آسيا'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        backgroundColor: _selectedRegion == r ? AppColors.accent : AppColors.surface.withOpacity(0.9),
                        label: Text(
                          r == 'عربي' ? '🕌 الوطن العربي' : r == 'أوروبا' ? '🏰 أوروبا' : r == 'أمريكا' ? '🗽 أمريكا' : r == 'آسيا' ? '⛩️ آسيا' : '🌍 الكل',
                          style: TextStyle(
                            color: _selectedRegion == r ? Colors.black87 : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        onPressed: () => _flyToRegion(r),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Instruction Banner
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: const [
                  Icon(Icons.touch_app, color: AppColors.accent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'اسحب وحرّك الخريطة وانقر على أي علم للاستماع المباشر من تلك المدينة.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaciousGlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw Longitude and Latitude grid
    for (double x = 0; x <= size.width; x += size.width / 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Equator Line
    final equatorPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.3)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), equatorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
