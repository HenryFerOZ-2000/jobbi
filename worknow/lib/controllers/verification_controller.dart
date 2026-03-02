import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/notification_service.dart';

class VerificationController extends ChangeNotifier {
  VerificationController._();
  static final VerificationController instance = VerificationController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService.instance;

  /// Submit verification with ID card and selfie
  Future<void> submitVerification({
    required String userId,
    required File idCardFile,
    required File selfieFile,
  }) async {
    try {
      // Upload ID card image (ruta según Firebase Rules)
      final idCardRef = _storage.ref().child('user_verification/$userId/id_card.jpg');
      await idCardRef.putFile(idCardFile);
      final idCardUrl = await idCardRef.getDownloadURL();

      // Upload selfie image (ruta según Firebase Rules)
      final selfieRef = _storage.ref().child('user_verification/$userId/selfie.jpg');
      await selfieRef.putFile(selfieFile);
      final selfieUrl = await selfieRef.getDownloadURL();

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'pending',
        'idCardUrl': idCardUrl,
        'selfieUrl': selfieUrl,
        'submittedAt': Timestamp.now(),
        'rejectionReason': null, // Clear any previous rejection reason
      });

      debugPrint('✅ Verification submitted successfully for user $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error submitting verification: $e');
      rethrow;
    }
  }

  /// Approve verification (Admin function)
  Future<void> approveVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'verified',
        'verifiedAt': Timestamp.now(),
        'rejectionReason': null,
      });

      // Send notification to user
      await _notificationService.sendNotification(
        targetUserId: userId,
        title: '✓ Verificación aprobada',
        body: 'Tu identidad ha sido verificada exitosamente. Ya puedes acceder a todas las funciones.',
        type: 'verification_approved',
      );

      debugPrint('✅ Verification approved for user $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error approving verification: $e');
      rethrow;
    }
  }

  /// Reject verification (Admin function)
  Future<void> rejectVerification({
    required String userId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'rejected',
        'rejectionReason': reason,
      });

      // Send notification to user
      await _notificationService.sendNotification(
        targetUserId: userId,
        title: '✗ Verificación rechazada',
        body: 'Tu verificación fue rechazada. Motivo: $reason',
        type: 'verification_rejected',
      );

      debugPrint('✅ Verification rejected for user $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error rejecting verification: $e');
      rethrow;
    }
  }

  /// Get pending verifications (Admin function)
  Stream<List<Map<String, dynamic>>> getPendingVerifications() {
    return _firestore
        .collection('users')
        .where('verificationStatus', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'userId': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get user verification status
  Future<Map<String, dynamic>> getVerificationStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();

      if (data == null) {
        return {
          'status': 'unverified',
          'idCardUrl': null,
          'selfieUrl': null,
          'submittedAt': null,
          'verifiedAt': null,
          'rejectionReason': null,
        };
      }

      return {
        'status': data['verificationStatus'] ?? 'unverified',
        'idCardUrl': data['idCardUrl'],
        'selfieUrl': data['selfieUrl'],
        'submittedAt': data['submittedAt'],
        'verifiedAt': data['verifiedAt'],
        'rejectionReason': data['rejectionReason'],
      };
    } catch (e) {
      debugPrint('❌ Error getting verification status: $e');
      return {
        'status': 'unverified',
        'idCardUrl': null,
        'selfieUrl': null,
        'submittedAt': null,
        'verifiedAt': null,
        'rejectionReason': null,
      };
    }
  }

  /// Check if current user is verified
  Future<bool> isCurrentUserVerified() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final status = userDoc.data()?['verificationStatus'] ?? 'unverified';

      return status == 'verified';
    } catch (e) {
      debugPrint('❌ Error checking if user is verified: $e');
      return false;
    }
  }

  /// Check if user can perform action (is verified)
  Future<bool> canPerformAction(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final status = userDoc.data()?['verificationStatus'] ?? 'unverified';

      return status == 'verified';
    } catch (e) {
      debugPrint('❌ Error checking if user can perform action: $e');
      return false;
    }
  }
}

