import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});
  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _scale = 1.0;

  final List<Map<String, dynamic>> _cities = [
    {'name': 'القاهرة', 'code': 'EG', 'lat': 30.0, 'lng': 31.2, 'flag': '🇪🇬'},
    {'name': 'مكة المكرمة', 'code': 'SA', 'lat': 21.4, 'lng': 39.8, 'flag': '🇸🇦'},
    {'name': 'الرياض', 'code': 'SA', 'lat': 24.7, 'lng': 46.6, 'flag': '🇸🇦'},
    {'name': 'دبي', 'code': 'AE', 'lat': 25.2, 'lng': 55.2, 'flag': '🇦🇪'},
    {'name': 'الدار البيضاء', 'code': 'MA', 'lat': 33.5, 'lng': -7.5, 'flag': '🇲🇦'},
    {'name': 'لندن', 'code': 'GB', 'lat': 51.5, 'lng': -0.1, 'flag': '🇬🇧'},
    {'name': 'باريس', 'code': 'FR', 'lat': 48.8, 'lng': 2.3, 'flag': '🇫🇷'},
    {'name': 'نيويورك', 'code': 'US', 'lat': 40.7, 'lng': -74.0, 'flag': '🇺🇸'},
    {'name': 'طوكيو', 'code': 'JP', 'lat': 35.6, 'lng': 139.6, 'flag': '🇯🇵'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("مكتشف العالم 3D"), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX -= details.delta.dy * 0.01;
              });
            },
            child: Center(
              child: GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    _scale = (_scale * details.scale).clamp(0.5, 5.0);
                  });
                },
                minScale: 0.5,
                maxScale: 4.0,
                onInteractionUpdate: (details) {
                  setState(() => _scale = details.scale);
                },
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_rotationX)
                    ..rotateY(_rotationY)
                    ..scale(_scale),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The Globe Sphere
                      Container(
                        width: 300, height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Colors.blue.shade900, Colors.black],
                            center: const Alignment(-0.3, -0.3),
                          ),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 50, spreadRadius: 10)],
                        ),
                      ),
                      // City Pins
                      ..._cities.map((city) => _buildCityPin(city)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildCityPin(Map<String, dynamic> city) {
    double latRad = city['lat'] * math.pi / 180;
    double lngRad = city['lng'] * math.pi / 180;
    double x = 150 * math.cos(latRad) * math.sin(lngRad);
    double y = -150 * math.sin(latRad);
    double z = 150 * math.cos(latRad) * math.cos(lngRad);

    // Only show if facing the camera
    if (z < 0) return const SizedBox.shrink();

    return Positioned(
      left: 150 + x - 20,
      top: 150 + y - 20,
      child: GestureDetector(
        onTap: () {
          context.read<RadioProvider>().fetchHomeStations(countryCode: city['code']);
          Navigator.pop(context);
        },
        child: Column(
          children: [
            Text(city['flag'], style: const TextStyle(fontSize: 24)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: Colors.black54,
              child: Text(city['name'], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 40, right: 20,
      child: Column(
        children: [
          FloatingActionButton.small(onPressed: () => setState(() => _scale += 0.2), child: const Icon(Icons.add)),
          const SizedBox(height: 10),
          FloatingActionButton.small(onPressed: () => setState(() => _scale -= 0.2), child: const Icon(Icons.remove)),
          const SizedBox(height: 10),
          FloatingActionButton.small(onPressed: () => setState(() { _scale = 1.0; _rotationX = 0; _rotationY = 0; }), child: const Icon(Icons.restart_alt)),
        ],
      ),
    );
  }
}
