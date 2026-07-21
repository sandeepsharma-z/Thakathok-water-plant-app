import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The ThakaThok brand mark, used on the splash and home header.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Logo + two-line brand name, used in headers.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.logoSize = 42, this.compact = false});

  final double logoSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: logoSize),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MAHALAKSHMI',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.primaryDark,
                height: 1.05,
              ),
            ),
            Text(
              'WATER PLANT',
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
