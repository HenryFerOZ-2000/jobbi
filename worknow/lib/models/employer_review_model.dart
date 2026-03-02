import 'package:cloud_firestore/cloud_firestore.dart';

class EmployerReview {
  final String id;
  final String employerId;
  final String raterId; // Worker who rates the employer
  final String raterName;
  final String jobId;
  final String jobTitle;
  final double rating; // 1-5
  final String? comment;
  final Timestamp createdAt;

  EmployerReview({
    required this.id,
    required this.employerId,
    required this.raterId,
    required this.raterName,
    required this.jobId,
    required this.jobTitle,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory EmployerReview.fromMap(Map<String, dynamic> map, String id) {
    return EmployerReview(
      id: id,
      employerId: map['employerId'] ?? '',
      raterId: map['raterId'] ?? '',
      raterName: map['raterName'] ?? 'Usuario',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'raterId': raterId,
      'raterName': raterName,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
