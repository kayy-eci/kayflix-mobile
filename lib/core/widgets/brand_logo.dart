import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.fontSize = 28});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'KAYFLIX',
      style: TextStyle(
        color: AppColors.red,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.4,
        height: 1,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
