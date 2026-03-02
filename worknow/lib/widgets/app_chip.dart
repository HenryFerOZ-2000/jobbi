import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppChipType { category, location, price, status, info }

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppChipType type;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.type = AppChipType.info,
    this.onTap,
  });

  Color get _backgroundColor {
    switch (type) {
      case AppChipType.category:
        return AppColors.chipGreen;
      case AppChipType.location:
        return AppColors.chipBlue;
      case AppChipType.price:
        return AppColors.primaryLight;
      case AppChipType.status:
        return AppColors.chipPurple;
      case AppChipType.info:
        return Colors.grey[100]!;
    }
  }

  Color get _textColor {
    switch (type) {
      case AppChipType.category:
        return AppColors.chipGreenText;
      case AppChipType.location:
        return AppColors.chipBlueText;
      case AppChipType.price:
        return AppColors.primary;
      case AppChipType.status:
        return AppColors.chipPurpleText;
      case AppChipType.info:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: chipContent,
      );
    }

    return chipContent;
  }
}

