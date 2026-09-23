import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../constants/app_colors.dart';

class VintageDialScreen extends StatefulWidget {
  const VintageDialScreen({super.key});

  @override
  State<VintageDialScreen> createState() => _VintageDialScreenState();
}

class _VintageDialScreenState extends State<VintageDialScreen> {
  double _currentFrequency = 98.2; // 87.5 MHz to 108.0 MHz
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final freq = 87.5 + (offset / 40.0) * 0.5;
      if (freq >= 87.5 && freq <= 108.0) {
        setState(() => _currentFrequency = double.parse(freq.toStringAsFixed(1)));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _tuneToStation(int index) {
    final radio = context.read<RadioProvider>();
    if (radio.homeStations.isNotEmpty) {
      final target = radio.homeStations[index % radio.homeStations.length];
      radio.playStation(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final station = radio.currentStation;

    return Scaffold(
      backgroundColor: const Color(0xFF15100B), // Vintage warm dark wood
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'راديو كلاسيكي تناظري 📻',
          style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Retro Vintage Wood & Brass Radio Chassis
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C1F16), Color(0xFF1B130E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF8C6D46), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Vintage Speaker Grill Texture
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF100B07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5A452D)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int i = 0; i < 20; i++)
                            Container(width: 3, height: 32, color: const Color(0xFF3B2D1E)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Illuminated Frequency Scale Dial Window
                    Container(
                      height: 110,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1308),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC59B5F), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5C07B).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Scrollable Frequency Ticks
                          ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: 80,
                            itemBuilder: (ctx, index) {
                              final f = 87.5 + (index * 0.25);
                              final isMajor = index % 4 == 0;
                              return Container(
                                width: 20,
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isMajor)
                                      Text(
                                        f.toStringAsFixed(0),
                                        style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: isMajor ? 2.5 : 1.2,
                                      height: isMajor ? 36 : 18,
                                      color: isMajor ? const Color(0xFFE5C07B) : const Color(0xFF8C6D46),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Red Center Tuning Needle
                          Container(
                            width: 3,
                            height: 75,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 6, spreadRadius: 1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Tuning frequency indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('FM 88 - 108 MHz', style: TextStyle(color: Color(0xFF8C6D46), fontSize: 12, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0B06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC59B5F)),
                          ),
                          child: Text(
                            '$_currentFrequency MHz',
                            style: const TextStyle(
                              color: Color(0xFFE5C07B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: radio.isPlaying ? Colors.greenAccent : Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: (radio.isPlaying ? Colors.greenAccent : Colors.redAccent).withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('STEREO', style: TextStyle(color: Color(0xFF8C6D46), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Currently tuned station display
              Column(
                children: [
                  Text(
                    station?.name ?? 'اسحب المؤشر لضبط الإذاعة',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    station?.country ?? 'البحث التناظري اليدوي',
                    style: const TextStyle(color: Color(0xFF8C6D46), fontSize: 14),
                  ),
                ],
              ),

              // Brass Tuning Wheels Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tune down
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C1F16),
                      foregroundColor: const Color(0xFFE5C07B),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      side: const BorderSide(color: Color(0xFF8C6D46), width: 2),
                    ),
                    onPressed: () {
                      _scrollController.animateTo(
                        _scrollController.offset - 60,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      _tuneToStation((_currentFrequency * 10).toInt() - 1);
                    },
                    child: const Icon(Icons.arrow_back_ios_new, size: 24),
                  ),

                  // Big Center Vintage Power Knob
                  GestureDetector(
                    onTap: () => radio.togglePlayPause(),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFE5C07B), Color(0xFF8C6D46), Color(0xFF3B2D1E)],
                        ),
                        border: Border.all(color: const Color(0xFFFFE0A0), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFE5C07B).withOpacity(0.3), blurRadius: 16),
                        ],
                      ),
                      child: Icon(
                        radio.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black87,
                        size: 48,
                      ),
                    ),
                  ),

                  // Tune up
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C1F16),
                      foregroundColor: const Color(0xFFE5C07B),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      side: const BorderSide(color: Color(0xFF8C6D46), width: 2),
                    ),
                    onPressed: () {
                      _scrollController.animateTo(
                        _scrollController.offset + 60,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      _tuneToStation((_currentFrequency * 10).toInt() + 1);
                    },
                    child: const Icon(Icons.arrow_forward_ios, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
