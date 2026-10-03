import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Корти шаффоф (шишагӣ). `blur: true` танҳо барои унсурҳои ками муҳим
/// (сарлавҳа, меню) — дар рӯйхатҳои дароз садои иловагӣ намедиҳад.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool blur;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 18,
    this.blur = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.glassFill : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    final content = blur
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: box),
          )
        : box;
    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}
