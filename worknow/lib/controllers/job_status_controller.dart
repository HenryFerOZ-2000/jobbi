import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class JobStatusController extends ChangeNotifier {
  JobStatusController._();
  static final JobStatusController instance = JobStatusController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService.instance;

  /// Accept an applicant
  /// Changes status to "accepted"
  /// Increments filledSlots++ 
  /// If filledSlots == totalSlots, marks isClosed = true
  Future<void> acceptApplicant({
    required String jobId,
    required String userId,
    bool autoAssign = false, // Optional: auto assign after accepting
  }) async {
    try {
      // Get job data
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      
      if (jobData == null) {
        throw 'Trabajo no encontrado';
      }

      final totalSlots = jobData['totalSlots'] ?? 1;
      final filledSlots = jobData['filledSlots'] ?? 0;

      // Check if there are available slots
      if (filledSlots >= totalSlots) {
        throw 'No hay cupos disponibles';
      }

      // Find the application
      final appSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (appSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final appDoc = appSnapshot.docs.first;
      final appData = appDoc.data();

      // Update application status
      await appDoc.reference.update({
        'status': autoAssign ? 'assigned' : 'accepted',
        'updatedAt': Timestamp.now(),
      });

      // Increment filled slots
      final newFilledSlots = filledSlots + 1;
      final isFull = newFilledSlots >= totalSlots;

      // Update job
      await _firestore.collection('jobs').doc(jobId).update({
        'filledSlots': newFilledSlots,
        'isClosed': isFull,
      });

      // If job is now full, reject pending applicants
      if (isFull) {
        await _rejectPendingApplicants(jobId, userId, appData['jobTitle'] ?? 'Trabajo');
      }

      // Send notification to applicant
      await _notificationService.sendNotification(
        targetUserId: userId,
        title: autoAssign ? '¡Trabajo asignado!' : '¡Postulación aceptada!',
        body: autoAssign
            ? 'Te han asignado el trabajo "${appData['jobTitle']}"'
            : 'Tu postulación para "${appData['jobTitle']}" ha sido aceptada',
        type: 'application_status',
        jobId: jobId,
        status: autoAssign ? 'assigned' : 'accepted',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error accepting applicant: $e');
      rethrow;
    }
  }

  /// Assign work to an applicant
  /// Changes status from "accepted" to "assigned"
  Future<void> assignApplicant({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Find the application
      final appSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (appSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final appDoc = appSnapshot.docs.first;
      final appData = appDoc.data();

      // Verify current status is accepted
      if (appData['status'] != 'accepted') {
        throw 'Solo se pueden asignar postulaciones aceptadas';
      }

      // Update application status
      await appDoc.reference.update({
        'status': 'assigned',
        'updatedAt': Timestamp.now(),
      });

      // Send notification to applicant
      await _notificationService.sendNotification(
        targetUserId: userId,
        title: '¡Trabajo asignado!',
        body: 'Te han asignado el trabajo "${appData['jobTitle']}"',
        type: 'application_status',
        jobId: jobId,
        status: 'assigned',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning applicant: $e');
      rethrow;
    }
  }

  /// Start working on a job
  /// Changes status from "assigned" to "in_progress"
  Future<void> startWork({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Find the application
      final appSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (appSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final appDoc = appSnapshot.docs.first;
      final appData = appDoc.data();

      // Update application status
      await appDoc.reference.update({
        'status': 'in_progress',
        'updatedAt': Timestamp.now(),
      });

      // Send notification to employer
      await _notificationService.sendNotification(
        targetUserId: appData['employerId'],
        title: 'Trabajo iniciado',
        body: '${appData['userName']} ha comenzado a trabajar en "${appData['jobTitle']}"',
        type: 'application_status',
        jobId: jobId,
        status: 'in_progress',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting work: $e');
      rethrow;
    }
  }

  /// Request completion from worker
  /// Changes status to "waiting_confirmation"
  /// Worker requests that employer confirms job is done
  Future<void> requestCompletion({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Find the application
      final appSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (appSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final appDoc = appSnapshot.docs.first;
      final appData = appDoc.data();

      // Update application status
      await appDoc.reference.update({
        'status': 'waiting_confirmation',
        'completionRequestedBy': userId,
        'updatedAt': Timestamp.now(),
      });

      // Send notification to employer
      await _notificationService.sendNotification(
        targetUserId: appData['employerId'],
        title: 'Solicitud de finalización',
        body: '${appData['userName']} solicita confirmar la finalización de "${appData['jobTitle']}"',
        type: 'completion_request',
        jobId: jobId,
        status: 'waiting_confirmation',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error requesting completion: $e');
      rethrow;
    }
  }

  /// Confirm completion (by employer)
  /// Changes status to "completed"
  /// Records completedAt timestamp
  Future<void> confirmCompletion({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Find the application
      final appSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (appSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final appDoc = appSnapshot.docs.first;
      final appData = appDoc.data();

      // Update application status
      await appDoc.reference.update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Optionally: Decrement filled slots if slots are reusable
      // For now, we'll keep the slot filled
      
      // Check if all accepted/assigned applicants are completed
      final activeApplicants = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', whereIn: ['accepted', 'assigned', 'in_progress', 'waiting_confirmation'])
          .get();

      // If no more active applicants, mark job as fully closed
      if (activeApplicants.docs.isEmpty) {
        await _firestore.collection('jobs').doc(jobId).update({
          'status': 'closed',
          'isClosed': true,
        });
      }

      // Send notification to worker
      await _notificationService.sendNotification(
        targetUserId: userId,
        title: '¡Trabajo completado!',
        body: 'El trabajo "${appData['jobTitle']}" ha sido marcado como completado',
        type: 'application_status',
        jobId: jobId,
        status: 'completed',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error confirming completion: $e');
      rethrow;
    }
  }

  /// Reject an applicant
  /// Changes status to "rejected"
  /// If applicant was accepted/assigned, decrements filledSlots
  Future<void> rejectApplicant({
    required String jobId,
    required String userId,
    String? reason,
  }) async {
    try {
      // Get job data
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      
      if (jobData == null) {
        throw 'Trabajo no encontrado';
      }

      // Find the application
      final appSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (appSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final appDoc = appSnapshot.docs.first;
      final appData = appDoc.data();
      final currentStatus = appData['status'];

      // Update application status
      await appDoc.reference.update({
        'status': 'rejected',
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // If applicant was accepted/assigned/in_progress, decrement filled slots
      if (currentStatus == 'accepted' || 
          currentStatus == 'assigned' || 
          currentStatus == 'in_progress' ||
          currentStatus == 'waiting_confirmation') {
        final filledSlots = jobData['filledSlots'] ?? 0;
        final newFilledSlots = filledSlots > 0 ? filledSlots - 1 : 0;
        final totalSlots = jobData['totalSlots'] ?? 1;
        final isClosed = newFilledSlots >= totalSlots;

        await _firestore.collection('jobs').doc(jobId).update({
          'filledSlots': newFilledSlots,
          'isClosed': isClosed,
        });
      }

      // Send notification to applicant
      await _notificationService.sendNotification(
        targetUserId: userId,
        title: 'Postulación rechazada',
        body: reason ?? 'Tu postulación para "${appData['jobTitle']}" ha sido rechazada',
        type: 'application_status',
        jobId: jobId,
        status: 'rejected',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting applicant: $e');
      rethrow;
    }
  }

  /// Reject all pending applicants (when job is full)
  Future<void> _rejectPendingApplicants(String jobId, String acceptedUserId, String jobTitle) async {
    try {
      final pendingSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (var doc in pendingSnapshot.docs) {
        final data = doc.data();
        if (data['userId'] != acceptedUserId) {
          batch.update(doc.reference, {
            'status': 'rejected',
            'autoRejected': true,
            'rejectionReason': 'Cupos completos',
            'updatedAt': Timestamp.now(),
          });

          // Send notification
          _notificationService.sendNotification(
            targetUserId: data['userId'],
            title: 'Cupos completos',
            body: 'El trabajo "$jobTitle" ha cerrado sus cupos',
            type: 'application_status',
            jobId: jobId,
            status: 'rejected',
          );
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error rejecting pending applicants: $e');
    }
  }

  /// Get application for a user and job
  Future<Map<String, dynamic>?> getApplication({
    required String jobId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return {
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      };
    } catch (e) {
      debugPrint('Error getting application: $e');
      return null;
    }
  }

  /// Get current user's applications
  Stream<List<Map<String, dynamic>>> getMyApplications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> applications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Get job details
        final jobDoc = await _firestore.collection('jobs').doc(data['jobId']).get();
        final jobData = jobDoc.data();

        if (jobData != null) {
          applications.add({
            'applicationId': doc.id,
            ...data,
            'jobData': jobData,
          });
        }
      }

      return applications;
    });
  }

  /// Get applications by status
  Stream<List<Map<String, dynamic>>> getApplicationsByStatus(String status) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: status)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> applications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Get job details
        final jobDoc = await _firestore.collection('jobs').doc(data['jobId']).get();
        final jobData = jobDoc.data();

        if (jobData != null) {
          applications.add({
            'applicationId': doc.id,
            ...data,
            'jobData': jobData,
          });
        }
      }

      return applications;
    });
  }
}

