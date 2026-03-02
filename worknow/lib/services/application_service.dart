import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';

class ApplicationService extends ChangeNotifier {
  ApplicationService._();
  static final ApplicationService instance = ApplicationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService.instance;

  /// Apply to a job and create a chat automatically
  Future<void> applyToJob({
    required String jobId,
    required String employerId,
    required String jobTitle,
    String? message,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw 'Usuario no autenticado';
    }

    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      if (userData == null) throw 'Perfil no encontrado';

      final applicantName = userData['fullName'] ?? userData['name'] ?? 'Usuario';

      // Create application document
      final applicationRef = _firestore.collection('applications').doc();
      await applicationRef.set({
        'userId': currentUser.uid,
        'userName': applicantName,
        'employerId': employerId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'status': 'pending', // pending, accepted, rejected, assigned, completed
        'message': message ?? '',
        'appliedAt': Timestamp.now(),
      });

      // Update job document
      await _firestore.collection('jobs').doc(jobId).update({
        'applicantsIds': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Create chat automatically
      await _chatService.createChat(
        otherUserId: employerId,
        jobId: jobId,
        jobTitle: jobTitle,
      );

      // Send notification to employer
      await _sendApplicationNotification(
        employerId: employerId,
        applicantName: applicantName,
        jobTitle: jobTitle,
        jobId: jobId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error applying to job: $e');
      rethrow;
    }
  }

  /// Send notification to employer about new application
  Future<void> _sendApplicationNotification({
    required String employerId,
    required String applicantName,
    required String jobTitle,
    required String jobId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(employerId)
          .collection('notifications')
          .add({
        'title': 'Nueva postulación',
        'body': '$applicantName se postuló para "$jobTitle"',
        'type': 'application',
        'jobId': jobId,
        'read': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Update application status
  Future<void> updateApplicationStatus({
    required String jobId,
    required String userId,
    required String status,
  }) async {
    try {
      // Find the application
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      // Update status
      await snapshot.docs.first.reference.update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // Send notification to applicant
      final applicationData = snapshot.docs.first.data();
      await _sendStatusUpdateNotification(
        userId: userId,
        jobTitle: applicationData['jobTitle'] ?? 'Trabajo',
        status: status,
        jobId: jobId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating application status: $e');
      rethrow;
    }
  }

  /// Send notification about status update
  Future<void> _sendStatusUpdateNotification({
    required String userId,
    required String jobTitle,
    required String status,
    required String jobId,
  }) async {
    try {
      String title = '';
      String body = '';

      switch (status) {
        case 'accepted':
          title = '¡Postulación aceptada!';
          body = 'Tu postulación para "$jobTitle" ha sido aceptada';
          break;
        case 'rejected':
          title = 'Postulación rechazada';
          body = 'Tu postulación para "$jobTitle" ha sido rechazada';
          break;
        case 'assigned':
          title = '¡Trabajo asignado!';
          body = 'Te han asignado el trabajo "$jobTitle"';
          break;
        case 'completed':
          title = 'Trabajo completado';
          body = 'El trabajo "$jobTitle" ha sido marcado como completado';
          break;
        default:
          return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': 'application_status',
        'jobId': jobId,
        'status': status,
        'read': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error sending status notification: $e');
    }
  }

  /// Get applicants for a job
  Stream<List<Map<String, dynamic>>> getApplicants(String jobId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> applicants = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'];

        // Get user details
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();

        if (userData != null) {
          applicants.add({
            'applicationId': doc.id,
            'userId': userId,
            'userName': data['userName'] ?? userData['fullName'] ?? 'Usuario',
            'userEmail': userData['email'] ?? '',
            'userPhoto': userData['photoUrl'],
            'userCategory': userData['category'] ?? '',
            'userRating': userData['rating'] ?? 0.0,
            'userVerified': userData['verificationStatus'] == 'verified',
            'status': data['status'] ?? 'pending',
            'message': data['message'] ?? '',
            'appliedAt': data['appliedAt'],
          });
        }
      }

      return applicants;
    });
  }

  /// Check if user has applied to a job
  Future<bool> hasApplied(String jobId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking application: $e');
      return false;
    }
  }

  /// Get application status
  Future<String?> getApplicationStatus(String jobId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first.data()['status'] as String?;
    } catch (e) {
      debugPrint('Error getting application status: $e');
      return null;
    }
  }
}

