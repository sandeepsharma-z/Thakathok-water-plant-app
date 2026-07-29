import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DottedLoader extends StatefulWidget {
  const DottedLoader({super.key, this.size = 34});
  final double size;

  @override
  State<DottedLoader> createState() => _DottedLoaderState();
}

class _DottedLoaderState extends State<DottedLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _controller,
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(painter: const _DotsPainter()),
        ),
      );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const count = 12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 3;
    for (var i = 0; i < count; i++) {
      final angle = (math.pi * 2 * i / count) - math.pi / 2;
      final opacity = 0.18 + (0.82 * (i + 1) / count);
      final dotRadius = 1.25 + (0.75 * (i + 1) / count);
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius),
        dotRadius,
        Paint()..color = AppColors.liveBrand.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
