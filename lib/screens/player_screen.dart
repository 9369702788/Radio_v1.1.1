import 'dart:math' as math;
import '../services/widget_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/radio_provider.dart';
import '../constants/app_colors.dart';

class LiveSpectrumVisualizer extends StatefulWidget {
  final bool isPlaying;
  const LiveSpectrumVisualizer({super.key, required this.isPlaying});
  @override
  State<LiveSpectrumVisualizer> createState() => _LiveSpectrumVisualizerState();
}

class _LiveSpectrumVisualizerState extends State<LiveSpectrumVisualizer> with TickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(12, (index) {
            double h = widget.isPlaying ? (20 + 30 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + index))) : 5;
            return Container(
              width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(2)),
            );
          }),
        );
      },
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isOneHanded = false;
  bool _showCC = true;

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();
    final station = radio.currentStation;
    if (station == null) return const Scaffold(body: Center(child: Text("لا توجد إذاعة")));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.picture_in_picture_alt), onPressed: () => WidgetService.enterPip()),
          IconButton(icon: Icon(_isOneHanded ? Icons.pan_tool : Icons.pan_tool_alt), onPressed: () => setState(() => _isOneHanded = !_isOneHanded)),
        ],
      ),
      body: Column(
        children: [
          if (!_isOneHanded) const Spacer(),
          // Artwork
          Center(
            child: Hero(
              tag: station.uuid,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 30)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(imageUrl: station.favicon, fit: BoxFit.cover, errorWidget: (c,u,e) => const Icon(Icons.radio, size: 100)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // CC Subtitles
          if (_showCC) Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Text(radio.currentMetadata.isEmpty ? "بث مباشر..." : radio.currentMetadata, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 20),
          LiveSpectrumVisualizer(isPlaying: radio.isPlaying),
          const Spacer(),
          // Controls
          _buildControls(radio),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildControls(RadioProvider radio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white), onPressed: () => radio.skipBackward()),
        FloatingActionButton.large(
          onPressed: () => radio.togglePlay(),
          backgroundColor: Colors.cyanAccent,
          child: Icon(radio.isPlaying ? Icons.pause : Icons.play_arrow, size: 50, color: Colors.black),
        ),
        IconButton(icon: const Icon(Icons.skip_next, size: 40, color: Colors.white), onPressed: () => radio.skipForward()),
      ],
    );
  }
}

