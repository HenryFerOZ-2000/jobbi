import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double borderRadius;
  final Widget? placeholder;
  final BoxFit fit;

  const ImageCard({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.borderRadius = 24,
    this.placeholder,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppColors.primary,
                  ),
                );
              },
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        );
  }
}

