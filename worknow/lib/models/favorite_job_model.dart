import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteJob {
  final String id;
  final String jobId;
  final String userId;
  final String title;
  final String? imageUrl;
  final String city;
  final String country;
  final double? rating;
  final int budget;
  final String category;
  final Timestamp createdAt;

  FavoriteJob({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.title,
    this.imageUrl,
    required this.city,
    required this.country,
    this.rating,
    required this.budget,
    required this.category,
    required this.createdAt,
  });

  factory FavoriteJob.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteJob(
      id: id,
      jobId: map['jobId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'],
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      rating: (map['rating'] as num?)?.toDouble(),
      budget: map['budget'] ?? 0,
      category: map['category'] ?? 'General',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'title': title,
      'imageUrl': imageUrl,
      'city': city,
      'country': country,
      'rating': rating,
      'budget': budget,
      'category': category,
      'createdAt': createdAt,
    };
  }
}

