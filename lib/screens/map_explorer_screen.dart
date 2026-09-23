import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';

class MapCityPin {
  final String name;
  final String countryCode;
  final String flag;
  final double xRatio; // 0.0 to 1.0 on world map canvas
  final double yRatio;

  const MapCityPin({
    required this.name,
    required this.countryCode,
    required this.flag,
    required this.xRatio,
    required this.yRatio,
  });
}

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  static const List<MapCityPin> _pins = [
    MapCityPin(name: 'القاهرة', countryCode: 'EG', flag: '🇪🇬', xRatio: 0.58, yRatio: 0.42),
    MapCityPin(name: 'مكة المكرمة / الرياض', countryCode: 'SA', flag: '🇸🇦', xRatio: 0.63, yRatio: 0.45),
    MapCityPin(name: 'دبي', countryCode: 'AE', flag: '🇦🇪', xRatio: 0.67, yRatio: 0.44),
    MapCityPin(name: 'الدار البيضاء', countryCode: 'MA', flag: '🇲🇦', xRatio: 0.46, yRatio: 0.41),
    MapCityPin(name: 'الجزائر', countryCode: 'DZ', flag: '🇩🇿', xRatio: 0.51, yRatio: 0.38),
    MapCityPin(name: 'تونس', countryCode: 'TN', flag: '🇹🇳', xRatio: 0.53, yRatio: 0.37),
    MapCityPin(name: 'بغداد', countryCode: 'IQ', flag: '🇮🇶', xRatio: 0.62, yRatio: 0.39),
    MapCityPin(name: 'إسطنبول', countryCode: 'TR', flag: '🇹🇷', xRatio: 0.59, yRatio: 0.35),
    MapCityPin(name: 'لندن', countryCode: 'GB', flag: '🇬🇧', xRatio: 0.49, yRatio: 0.28),
    MapCityPin(name: 'باريس', countryCode: 'FR', flag: '🇫🇷', xRatio: 0.50, yRatio: 0.31),
    MapCityPin(name: 'برلين', countryCode: 'DE', flag: '🇩🇪', xRatio: 0.53, yRatio: 0.29),
    MapCityPin(name: 'نيويورك', countryCode: 'US', flag: '🇺🇸', xRatio: 0.28, yRatio: 0.36),
    MapCityPin(name: 'طوكيو', countryCode: 'JP', flag: '🇯🇵', xRatio: 0.88, yRatio: 0.38),
    MapCityPin(name: 'ريو دي جانيرو', countryCode: 'BR', flag: '🇧🇷', xRatio: 0.36, yRatio: 0.72),
    MapCityPin(name: 'سيدني', countryCode: 'AU', flag: '🇦🇺', xRatio: 0.89, yRatio: 0.78),
  ];

  MapCityPin? _selectedPin;

  void _onPinTapped(MapCityPin pin) {
    setState(() => _selectedPin = pin);
    final radio = context.read<RadioProvider>();
    radio.filterByCountry(pin.countryCode, pin.name);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer<RadioProvider>(
        builder: (ctx, r, _) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
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
          // Interactive Pan & Zoom World Globe Canvas
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return Stack(
                  children: [
                    // World Map Grid Background
                    CustomPaint(
                      size: Size(width, height),
                      painter: _WorldGridPainter(),
                    ),

                    // City Pins
                    for (final pin in _pins)
                      Positioned(
                        left: pin.xRatio * width - 24,
                        top: pin.yRatio * height - 24,
                        child: GestureDetector(
                          onTap: () => _onPinTapped(pin),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _selectedPin?.countryCode == pin.countryCode
                                      ? AppColors.accent
                                      : AppColors.surface.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedPin?.countryCode == pin.countryCode
                                        ? Colors.white
                                        : AppColors.accent,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(pin.flag, style: const TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pin.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Bottom Instruction Banner
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
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
                      'قرّب واسحب الخريطة وانقر على أي علم للاستماع المباشر من تلك العاصمة.',
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

class _WorldGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw latitude and longitude grid lines
    for (double x = 0; x <= size.width; x += size.width / 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw Equator Line with accent
    final equatorPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.2)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), equatorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
