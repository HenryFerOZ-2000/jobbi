import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  static RatingService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new rating
  Future<void> createRating({
    required String jobId,
    required String toUserId,
    required double rating,
    required String comment,
    required Map<String, double> categories,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Usuario no autenticado';

      // Get current user name
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userName = userDoc.data()?['fullName'] ?? 'Usuario';

      // Create rating document
      final ratingData = RatingModel(
        id: '',
        jobId: jobId,
        fromUserId: currentUser.uid,
        fromUserName: userName,
        toUserId: toUserId,
        rating: rating,
        comment: comment,
        categories: categories,
        createdAt: Timestamp.now(),
      );

      // Add to ratings collection
      await _firestore.collection('ratings').add(ratingData.toMap());

      // Update user's average rating
      await _updateUserRating(toUserId);

      print('✅ Rating created successfully');
    } catch (e) {
      print('❌ Error creating rating: $e');
      rethrow;
    }
  }

  // Update user's average rating
  Future<void> _updateUserRating(String userId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'rating': 0.0,
          'totalRatings': 0,
        });
        return;
      }

      double totalRating = 0;
      int count = 0;

      for (var doc in ratingsSnapshot.docs) {
        final rating = RatingModel.fromMap(doc.data(), doc.id);
        totalRating += rating.rating;
        count++;
      }

      final averageRating = totalRating / count;

      await _firestore.collection('users').doc(userId).update({
        'rating': averageRating,
        'totalRatings': count,
      });

      print('✅ User rating updated: $averageRating ($count reviews)');
    } catch (e) {
      print('❌ Error updating user rating: $e');
    }
  }

  // Get ratings for a user
  Stream<List<RatingModel>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Check if user can rate (already rated this job)
  Future<bool> canRate(String jobId, String toUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final existingRating = await _firestore
          .collection('ratings')
          .where('jobId', isEqualTo: jobId)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: toUserId)
          .limit(1)
          .get();

      return existingRating.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking if can rate: $e');
      return false;
    }
  }

  // Get rating statistics for a user
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          'categoryAverages': {},
        };
      }

      final ratings = ratingsSnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate average
      double totalRating = 0;
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      Map<String, List<double>> categoryScores = {};

      for (var rating in ratings) {
        totalRating += rating.rating;
        distribution[rating.rating.round()] = (distribution[rating.rating.round()] ?? 0) + 1;

        // Category scores
        rating.categories.forEach((category, score) {
          if (!categoryScores.containsKey(category)) {
            categoryScores[category] = [];
          }
          categoryScores[category]!.add(score);
        });
      }

      // Calculate category averages
      Map<String, double> categoryAverages = {};
      categoryScores.forEach((category, scores) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        categoryAverages[category] = avg;
      });

      return {
        'averageRating': totalRating / ratings.length,
        'totalRatings': ratings.length,
        'ratingDistribution': distribution,
        'categoryAverages': categoryAverages,
      };
    } catch (e) {
      print('❌ Error getting rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        'categoryAverages': {},
      };
    }
  }
}


