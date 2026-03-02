import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employer_review_model.dart';

class EmployerReviewService {
  static final EmployerReviewService _instance = EmployerReviewService._internal();
  factory EmployerReviewService() => _instance;
  EmployerReviewService._internal();

  static EmployerReviewService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a review for an employer
  Future<void> createReview({
    required String employerId,
    required String raterId,
    required String raterName,
    required String jobId,
    required String jobTitle,
    required double rating,
    String? comment,
  }) async {
    try {
      final reviewRef = _firestore
          .collection('users')
          .doc(employerId)
          .collection('reviews')
          .doc();

      final newReview = EmployerReview(
        id: reviewRef.id,
        employerId: employerId,
        raterId: raterId,
        raterName: raterName,
        jobId: jobId,
        jobTitle: jobTitle,
        rating: rating,
        comment: comment,
        createdAt: Timestamp.now(),
      );

      await reviewRef.set(newReview.toMap());

      // Update employer's average rating and count
      await _updateEmployerRating(employerId);

      print('✅ Review created for employer $employerId');
    } catch (e) {
      print('❌ Error creating review: $e');
      rethrow;
    }
  }

  // Get reviews for an employer
  Stream<List<EmployerReview>> getEmployerReviewsStream(String employerId) {
    return _firestore
        .collection('users')
        .doc(employerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmployerReview.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Check if a worker has already reviewed an employer for a specific job
  Future<bool> hasWorkerReviewedEmployer(
      String workerId, String employerId, String jobId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(employerId)
          .collection('reviews')
          .where('raterId', isEqualTo: workerId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking review: $e');
      return false;
    }
  }

  // Update employer's average rating
  Future<void> _updateEmployerRating(String employerId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('users')
          .doc(employerId)
          .collection('reviews')
          .get();

      double totalRating = 0;
      int count = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        final review = EmployerReview.fromMap(doc.data(), doc.id);
        totalRating += review.rating;
      }

      final averageRating = count > 0 ? totalRating / count : 0.0;

      await _firestore.collection('users').doc(employerId).update({
        'employerRatingAverage': averageRating,
        'employerRatingCount': count,
      });

      print('✅ Employer $employerId rating updated to $averageRating ($count reviews)');
    } catch (e) {
      print('❌ Error updating employer rating: $e');
    }
  }

  // Get employer rating stats with distribution
  Future<Map<String, dynamic>> getEmployerRatingStats(String employerId) async {
    try {
      // Get user data for average and count
      final userDoc = await _firestore.collection('users').doc(employerId).get();
      final userData = userDoc.data();

      if (userData == null) {
        return {
          'average': 0.0,
          'count': 0,
          'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      // Get all reviews to calculate distribution
      final reviewsSnapshot = await _firestore
          .collection('users')
          .doc(employerId)
          .collection('reviews')
          .get();

      // Calculate distribution
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var doc in reviewsSnapshot.docs) {
        final review = EmployerReview.fromMap(doc.data(), doc.id);
        final ratingInt = review.rating.round();
        if (ratingInt >= 1 && ratingInt <= 5) {
          distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
        }
      }

      return {
        'average': (userData['employerRatingAverage'] ?? 0.0) is int
            ? (userData['employerRatingAverage'] as int).toDouble()
            : (userData['employerRatingAverage'] ?? 0.0),
        'count': userData['employerRatingCount'] ?? 0,
        'distribution': distribution,
      };
    } catch (e) {
      print('❌ Error getting employer rating stats: $e');
      return {
        'average': 0.0,
        'count': 0,
        'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }
}
