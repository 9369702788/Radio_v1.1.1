import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RadialGradientBackground extends StatelessWidget {
  final Widget child;

  const RadialGradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.4, -0.7),
          radius: 1.4,
          colors: [
            Color(0xFF1E293B),
            AppColors.background,
            Color(0xFF080B10),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: child,
    );
  }
}
