import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_settings_service.dart';
import '../theme/app_colors.dart';

/// Фони умумии барнома: градиенти обии ҷоришаванда, доираҳои калони шаффоф
/// ва пуфакҳое, ки аз поён ба боло мебароянд. Дар `MaterialApp.builder`
/// гузошта шудааст, бинобар ин ҳамаи саҳифаҳо онро мебинанд.
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 20));

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

class _Rising {
  final double x, radius, phase;
  final int speed; // 1..3 — ҳар қадар бузургтар, ҳамон қадар тезтар
  const _Rising(this.x, this.radius, this.phase, this.speed);
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  final bool glass;
  _BackgroundPainter({required this.t, required this.glass});

  // x, y, радиус (нисбат ба паҳнӣ), фаза
  static const _blobs = <List<double>>[
    [0.15, 0.20, 0.38, 0.0],
    [0.85, 0.12, 0.30, 1.7],
    [0.70, 0.55, 0.44, 3.1],
    [0.10, 0.78, 0.34, 4.4],
    [0.90, 0.90, 0.28, 5.6],
  ];

  static final List<_Rising> _rising = () {
    final r = math.Random(11);
    return List.generate(
      16,
      (i) => _Rising(r.nextDouble(), 6 + r.nextDouble() * 18, r.nextDouble(), 1 + r.nextInt(3)),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final angle = t * 2 * math.pi;

    // 1) Градиенти ҷоришаванда
    final shift = math.sin(angle);
    final gradient = glass
        ? LinearGradient(
            begin: Alignment(0, -1 + 0.15 * shift),
            end: Alignment(0, 1),
            colors: const [Color(0xFFF7FBFF), Color(0xFFE6F2FE), Color(0xFFF4F9FE)],
          )
        : LinearGradient(
            begin: Alignment(-1 + 0.5 * shift, -1),
            end: Alignment(1 - 0.5 * shift, 1 + 0.3 * math.cos(angle)),
            colors: const [AppColors.skyTop, Color(0xFF9FD3FF), AppColors.skyBottom],
          );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // 2) Доираҳои калон — оҳиста мегарданд
    final blobColor = glass ? const Color(0xFF9CC9F5) : const Color(0xFF7CC0FF);
    for (final b in _blobs) {
      final dx = math.sin(angle + b[3]) * size.width * 0.10;
      final dy = math.cos(angle * 2 + b[3]) * size.height * 0.05;
      final center = Offset(size.width * b[0] + dx, size.height * b[1] + dy);
      final r = size.width * b[2];
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (glass ? blobColor : Colors.white).withOpacity(glass ? 0.30 : 0.60),
              blobColor.withOpacity(0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // 3) Пуфакҳо — аз поён ба боло мебароянд
    final fill = glass ? const Color(0xFF7FB8F0) : Colors.white;
    final edge = glass ? const Color(0xFF7FB8F0) : Colors.white;
    for (final b in _rising) {
      final p = (t * b.speed + b.phase) % 1.0;
      final y = size.height * (1.08 - 1.16 * p);
      final x = size.width * b.x + math.sin(2 * math.pi * (t * 2 + b.phase)) * 14;
      final fade = math.sin(math.pi * p); // дар поён ва боло нарм ғайб мешавад
      final c = Offset(x, y);
      canvas.drawCircle(c, b.radius, Paint()..color = fill.withOpacity((glass ? 0.14 : 0.30) * fade));
      canvas.drawCircle(
        c,
        b.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = edge.withOpacity((glass ? 0.45 : 0.85) * fade),
      );
      canvas.drawCircle(
        c.translate(-b.radius * 0.3, -b.radius * 0.3),
        b.radius * 0.18,
        Paint()..color = Colors.white.withOpacity(0.9 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.t != t || old.glass != glass;
}
