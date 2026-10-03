import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings_service.dart';
import '../theme/app_colors.dart';

/// Фони умумии барнома: градиенти обӣ + пуфакҳои шаффофи оҳиста ҳаракаткунанда.
/// Дар `MaterialApp.builder` гузошта мешавад, бинобар ин ҳамаи саҳифаҳо онро мебинанд.
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 28));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsService>();
    if (s.animationsEnabled) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
    final glass = s.backgroundStyle == BackgroundStyle.glass;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _BackgroundPainter(t: _controller.value, glass: glass),
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  final bool glass;
  _BackgroundPainter({required this.t, required this.glass});

  static const _bubbles = <List<double>>[
    // x, y, радиус (нисбат ба паҳнӣ), фаза, суръат
    [0.15, 0.20, 0.34, 0.0, 1],
    [0.85, 0.12, 0.26, 1.7, 1],
    [0.70, 0.55, 0.40, 3.1, 1],
    [0.10, 0.75, 0.30, 4.4, 1],
    [0.90, 0.88, 0.24, 5.6, 1],
    [0.45, 0.95, 0.20, 2.2, 1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = (glass
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7FBFF), Color(0xFFEAF4FD), Color(0xFFF4F9FE)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.skyTop, AppColors.skyMid, AppColors.skyBottom],
                ))
          .createShader(rect);
    canvas.drawRect(rect, paint);

    final angle = t * 2 * math.pi;
    for (final b in _bubbles) {
      final dx = math.sin(angle + b[3]) * size.width * 0.04;
      final dy = math.cos(angle * 1.0 + b[3]) * size.height * 0.025;
      final center = Offset(size.width * b[0] + dx, size.height * b[1] + dy);
      final r = size.width * b[2];
      final bubblePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            (glass ? const Color(0xFF9CC9F5) : Colors.white).withOpacity(glass ? 0.28 : 0.55),
            (glass ? const Color(0xFF9CC9F5) : const Color(0xFF8CC8FF)).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.t != t || old.glass != glass;
}
