import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showTooltip;

  const VerifiedBadge({
    super.key,
    this.size = 20,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.verified_rounded,
        size: size,
        color: AppColors.primary,
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: 'Usuario Verificado',
      child: badge,
    );
  }
}

