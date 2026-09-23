import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';

class BatterySaverScreen extends StatelessWidget {
  const BatterySaverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final station = radio.currentStation;

    return Scaffold(
      backgroundColor: Colors.black, // 100% OLED Pixels OFF
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => radio.togglePlayPause(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.battery_charging_full, color: Colors.white38, size: 18),
                        SizedBox(width: 6),
                        Text('وضع توفير البطارية الأقصى (OLED)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),

                // Pure minimalist OLED text
                Column(
                  children: [
                    Text(
                      station?.name ?? 'World Radio',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      radio.isPlaying ? '● جاري البث (المس الشاشة للإيقاف)' : '○ متوقف (المس الشاشة للتشغيل)',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),

                // Simple exit button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('الخروج من وضع توفير البطارية', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
