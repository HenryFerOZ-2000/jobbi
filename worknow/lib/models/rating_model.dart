import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String jobId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final double rating; // 1-5 estrellas
  final String comment;
  final Map<String, double> categories; // profesionalismo, comunicación, calidad
  final Timestamp createdAt;

  RatingModel({
    required this.id,
    required this.jobId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.rating,
    required this.comment,
    required this.categories,
    required this.createdAt,
  });

  // Create from Firestore document
  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse categories safely
    Map<String, double> categoriesMap = {};
    if (map['categories'] != null && map['categories'] is Map) {
      final cats = map['categories'] as Map<dynamic, dynamic>;
      cats.forEach((key, value) {
        categoriesMap[key.toString()] = (value as num).toDouble();
      });
    }

    return RatingModel(
      id: id,
      jobId: map['jobId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? 'Usuario',
      toUserId: map['toUserId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      categories: categoriesMap,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'rating': rating,
      'comment': comment,
      'categories': categories,
      'createdAt': createdAt,
    };
  }

  // Calculate average category rating
  double get averageCategoryRating {
    if (categories.isEmpty) return rating;
    final sum = categories.values.reduce((a, b) => a + b);
    return sum / categories.length;
  }
}


