import 'package:flutter/material.dart';

/// Логотипи Green Home Taj (assets/logo.png) бо гӯшаҳои мудаввар.
/// Агар файл ёфт нашавад, иконаи оддӣ нишон дода мешавад.
class AppLogo extends StatelessWidget {
  final double size;
  final double? radius;
  final bool border;

  const AppLogo({super.key, this.size = 64, this.radius, this.border = true});

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: border ? Border.all(color: Colors.white.withOpacity(0.85), width: size > 60 ? 2 : 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: size * 0.2, offset: Offset(0, size * 0.07))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(border ? r - 1.5 : r),
        child: Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF0B3D91),
            child: Icon(Icons.apartment_rounded, color: Colors.white, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}
