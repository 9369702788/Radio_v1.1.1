import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';

class GlobeCityPin {
  final String name;
  final String countryCode;
  final String flag;
  final double lat;
  final double lon;

  const GlobeCityPin({
    required this.name,
    required this.countryCode,
    required this.flag,
    required double latDeg,
    required double lonDeg,
  })  : lat = latDeg * math.pi / 180.0,
        lon = lonDeg * math.pi / 180.0;
}

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  double _rotationX = 0.45;
  double _rotationY = 0.55;
  Offset _lastFocalPoint = Offset.zero;

  static const List<GlobeCityPin> _cities = [
    GlobeCityPin(name: 'القاهرة', countryCode: 'EG', flag: '🇪🇬', latDeg: 30.0, lonDeg: 31.2),
    GlobeCityPin(name: 'مكة المكرمة', countryCode: 'SA', flag: '🇸🇦', latDeg: 21.4, lonDeg: 39.8),
    GlobeCityPin(name: 'الرياض', countryCode: 'SA', flag: '🇸🇦', latDeg: 24.7, lonDeg: 46.7),
    GlobeCityPin(name: 'دبي', countryCode: 'AE', flag: '🇦🇪', latDeg: 25.2, lonDeg: 55.3),
    GlobeCityPin(name: 'بغداد', countryCode: 'IQ', flag: '🇮🇶', latDeg: 33.3, lonDeg: 44.4),
    GlobeCityPin(name: 'القدس / عمّان', countryCode: 'PS', flag: '🇵🇸', latDeg: 31.9, lonDeg: 35.5),
    GlobeCityPin(name: 'تونس', countryCode: 'TN', flag: '🇹🇳', latDeg: 36.8, lonDeg: 10.2),
    GlobeCityPin(name: 'الجزائر', countryCode: 'DZ', flag: '🇩🇿', latDeg: 36.7, lonDeg: 3.1),
    GlobeCityPin(name: 'الدار البيضاء', countryCode: 'MA', flag: '🇲🇦', latDeg: 33.6, lonDeg: -7.6),
    GlobeCityPin(name: 'إسطنبول', countryCode: 'TR', flag: '🇹🇷', latDeg: 41.0, lonDeg: 28.9),
    GlobeCityPin(name: 'روما', countryCode: 'IT', flag: '🇮🇹', latDeg: 41.9, lonDeg: 12.5),
    GlobeCityPin(name: 'مدريد', countryCode: 'ES', flag: '🇪🇸', latDeg: 40.4, lonDeg: -3.7),
    GlobeCityPin(name: 'باريس', countryCode: 'FR', flag: '🇫🇷', latDeg: 48.8, lonDeg: 2.3),
    GlobeCityPin(name: 'لندن', countryCode: 'GB', flag: '🇬🇧', latDeg: 51.5, lonDeg: -0.1),
    GlobeCityPin(name: 'برلين', countryCode: 'DE', flag: '🇩🇪', latDeg: 52.5, lonDeg: 13.4),
    GlobeCityPin(name: 'موسكو', countryCode: 'RU', flag: '🇷🇺', latDeg: 55.7, lonDeg: 37.6),
    GlobeCityPin(name: 'نيويورك', countryCode: 'US', flag: '🇺🇸', latDeg: 40.7, lonDeg: -74.0),
    GlobeCityPin(name: 'طوكيو', countryCode: 'JP', flag: '🇯🇵', latDeg: 35.7, lonDeg: 139.7),
    GlobeCityPin(name: 'سيدني', countryCode: 'AU', flag: '🇦🇺', latDeg: -33.8, lonDeg: 151.2),
    GlobeCityPin(name: 'ريو دي جانيرو', countryCode: 'BR', flag: '🇧🇷', latDeg: -22.9, lonDeg: -43.2),
  ];

  GlobeCityPin? _selectedPin;

  void _onCityTapped(GlobeCityPin pin) {
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
    final size = MediaQuery.of(context).size;
    final globeRadius = (math.min(size.width, size.height) * 0.42).clamp(140.0, 220.0);

    return Scaffold(
      backgroundColor: const Color(0xFF060910),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الكرة الأرضية التفاعلية 3D 🌍',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.swipe, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'حرّك الكرة الأرضية بإصبعك في أي اتجاه ثلاثي الأبعاد والمس أي إذاعة للاستماع المباشر.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onScaleStart: (details) => _lastFocalPoint = details.focalPoint,
                  onScaleUpdate: (details) {
                    final delta = details.focalPoint - _lastFocalPoint;
                    _lastFocalPoint = details.focalPoint;
                    setState(() {
                      _rotationY += delta.dx * 0.008;
                      _rotationX = (_rotationX - delta.dy * 0.008).clamp(-0.8, 0.8);
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(globeRadius * 2, globeRadius * 2),
                        painter: _Globe3DPainter(
                          radius: globeRadius,
                          rotationX: _rotationX,
                          rotationY: _rotationY,
                        ),
                      ),
                      for (final pin in _cities)
                        _buildProjectedPin(pin, globeRadius),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectedPin(GlobeCityPin pin, double R) {
    final cosLat = math.cos(pin.lat);
    final sinLat = math.sin(pin.lat);
    final deltaLon = pin.lon - _rotationY;

    final x3d = R * cosLat * math.sin(deltaLon);
    final y3d = -R * (sinLat * math.cos(_rotationX) - cosLat * math.sin(_rotationX) * math.cos(deltaLon));
    final z3d = R * (sinLat * math.sin(_rotationX) + cosLat * math.cos(_rotationX) * math.cos(deltaLon));

    if (z3d <= 0) return const SizedBox.shrink();

    final isSelected = _selectedPin?.countryCode == pin.countryCode;

    return Transform.translate(
      offset: Offset(x3d, y3d),
      child: GestureDetector(
        onTap: () => _onCityTapped(pin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : const Color(0xFF182232).withOpacity(0.95),
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.white : AppColors.accent, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(pin.flag, style: const TextStyle(fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pin.name,
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Globe3DPainter extends CustomPainter {
  final double radius;
  final double rotationX;
  final double rotationY;

  _Globe3DPainter({required this.radius, required this.rotationX, required this.rotationY});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00CEC9).withOpacity(0.3),
          const Color(0xFF00CEC9).withOpacity(0.0),
        ],
        stops: const [0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.25));
    canvas.drawCircle(center, radius * 1.25, glowPaint);

    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [
          const Color(0xFF1E293B),
          const Color(0xFF0F172A),
          const Color(0xFF050811),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, spherePaint);

    final linePaint = Paint()
      ..color = const Color(0xFF00CEC9).withOpacity(0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final lonAngle = (i * math.pi / 6) - rotationY;
      final ellipseWidth = (radius * math.cos(lonAngle)).abs();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-rotationX * 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: ellipseWidth * 2, height: radius * 2),
        linePaint,
      );
      canvas.restore();
    }

    for (int i = -3; i <= 3; i++) {
      final latAngle = i * (math.pi / 8);
      final rLat = radius * math.cos(latAngle);
      final yLat = -radius * math.sin(latAngle) * math.cos(rotationX);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, center.dy + yLat), width: rLat * 2, height: (rLat * 0.35 * math.sin(rotationX)).abs() + 2),
        linePaint,
      );
    }

    final borderPaint = Paint()
      ..color = const Color(0xFF00CEC9).withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _Globe3DPainter oldDelegate) =>
      oldDelegate.rotationX != rotationX || oldDelegate.rotationY != rotationY;
}
