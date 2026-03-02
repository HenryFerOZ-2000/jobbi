import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../services/notification_service.dart';

class RatingController extends ChangeNotifier {
  RatingController._();
  static final RatingController instance = RatingController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RatingService _ratingService = RatingService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  /// Submit a rating for a user
  Future<void> submitRating({
    required String jobId,
    required String targetId,
    required double stars,
    required String comment,
    required Map<String, double> categories,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Usuario no autenticado';

      // Check if already rated
      final hasRated = await hasUserRated(jobId: jobId, targetId: targetId);
      if (hasRated) {
        throw 'Ya has calificado a este usuario en este trabajo';
      }

      // Create the rating
      await _ratingService.createRating(
        jobId: jobId,
        toUserId: targetId,
        rating: stars,
        comment: comment,
        categories: categories,
      );

      // Send notification to the rated user
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userName = userDoc.data()?['fullName'] ?? 'Un usuario';

      await _notificationService.sendNotification(
        targetUserId: targetId,
        title: '⭐ Nueva calificación recibida',
        body: '$userName te ha calificado con ${stars.toStringAsFixed(1)} estrellas',
        type: 'rating_received',
        jobId: jobId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get ratings for a specific user
  Stream<List<RatingModel>> getUserRatings(String targetId) {
    return _ratingService.getUserRatings(targetId);
  }

  /// Check if current user has already rated someone for a specific job
  Future<bool> hasUserRated({
    required String jobId,
    required String targetId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final existingRating = await _firestore
          .collection('ratings')
          .where('jobId', isEqualTo: jobId)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: targetId)
          .limit(1)
          .get();

      return existingRating.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user rated: $e');
      return false;
    }
  }

  /// Calculate and update average rating for a user
  Future<void> calculateAverageRating(String targetId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: targetId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        await _firestore.collection('users').doc(targetId).update({
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

      await _firestore.collection('users').doc(targetId).update({
        'rating': averageRating,
        'totalRatings': count,
      });

      debugPrint('✅ Average rating updated for $targetId: $averageRating ($count ratings)');
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating average rating: $e');
      rethrow;
    }
  }

  /// Get rating statistics for a user
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    return await _ratingService.getUserRatingStats(userId);
  }

  /// Check if user can rate (hasn't rated yet for this job)
  Future<bool> canRate(String jobId, String toUserId) async {
    return await _ratingService.canRate(jobId, toUserId);
  }
}

