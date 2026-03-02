import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../screens/ratings/user_reviews_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingsWidget extends StatelessWidget {
  final String userId;

  const RatingsWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: RatingService.instance.getUserRatingStats(userId),
      builder: (context, statsSnapshot) {
        if (statsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final stats = statsSnapshot.data ?? {
          'averageRating': 0.0,
          'totalRatings': 0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          'categoryAverages': {},
        };

        final averageRating = (stats['averageRating'] ?? 0.0) is int 
            ? (stats['averageRating'] as int).toDouble() 
            : (stats['averageRating'] ?? 0.0) as double;
        final totalRatings = stats['totalRatings'] as int;
        
        // Parse distribution safely
        final Map<int, int> distribution = {};
        final rawDistribution = stats['ratingDistribution'] as Map<dynamic, dynamic>;
        rawDistribution.forEach((key, value) {
          distribution[int.parse(key.toString())] = int.parse(value.toString());
        });
        
        // Parse category averages safely
        final Map<String, double> categoryAverages = {};
        final rawCategories = stats['categoryAverages'] as Map<dynamic, dynamic>;
        rawCategories.forEach((key, value) {
          final doubleValue = value is int ? value.toDouble() : value as double;
          categoryAverages[key.toString()] = doubleValue;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Calificaciones y Reseñas',
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Content
                  totalRatings == 0
                      ? Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.star_outline_rounded,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin calificaciones aún',
                                style: AppTextStyles.h6.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sé el primero en calificar a este usuario',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Average Rating
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < averageRating.round()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$totalRatings ${totalRatings == 1 ? "reseña" : "reseñas"}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Distribution
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: List.generate(5, (index) {
                              final stars = 5 - index;
                              final count = distribution[stars] ?? 0;
                              final percentage = totalRatings > 0
                                  ? (count / totalRatings) * 100
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      '$stars',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: percentage / 100,
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 20,
                                      child: Text(
                                        '$count',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  
                  // Category Averages within same card
                  if (categoryAverages.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[200], height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Por Categoría',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...categoryAverages.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(entry.key),
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getCategoryLabel(entry.key),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  entry.value.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // View All Reviews Button
            if (totalRatings > 0) ...[
              const SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  final userName = userSnapshot.data?.get('name') ?? userSnapshot.data?.get('fullName') ?? 'Usuario';
                  return OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserReviewsScreen(
                            userId: userId,
                            userName: userName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Ver todas las reseñas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              ),
            ],

            // Reviews List Preview
            if (totalRatings > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Reseñas Recientes',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<RatingModel>>(
                stream: RatingService.instance.getUserRatings(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  final ratings = snapshot.data ?? [];

                  if (ratings.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Show only first 3 reviews as preview
                  final previewRatings = ratings.take(3).toList();
                  
                  return Column(
                    children: previewRatings.map((rating) {
                      return _buildReviewCard(rating);
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(RatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rating.fromUserName.isNotEmpty
                        ? rating.fromUserName[0].toUpperCase()
                        : 'U',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.fromUserName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(rating.createdAt.toDate()),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.rating.toStringAsFixed(1),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Comment
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryLabel(String key) {
    switch (key) {
      case 'profesionalismo':
        return 'Profesionalismo';
      case 'comunicacion':
        return 'Comunicación';
      case 'calidad':
        return 'Calidad del Trabajo';
      default:
        return key;
    }
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'profesionalismo':
        return Icons.business_center_outlined;
      case 'comunicacion':
        return Icons.chat_bubble_outline_rounded;
      case 'calidad':
        return Icons.verified_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }
}

