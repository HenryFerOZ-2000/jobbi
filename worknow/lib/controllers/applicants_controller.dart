import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/application_service.dart';
import '../services/chat_service.dart';

class ApplicantsController extends ChangeNotifier {
  ApplicantsController._();
  static final ApplicantsController instance = ApplicantsController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance; // Reserved for future use
  final ApplicationService _applicationService = ApplicationService.instance;
  final ChatService _chatService = ChatService.instance;

  /// Get applicants for a job
  Stream<List<Map<String, dynamic>>> getApplicants(String jobId) {
    return _applicationService.getApplicants(jobId);
  }

  /// Accept an applicant
  Future<void> acceptApplicant({
    required String jobId,
    required String userId,
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

      // Update application status
      await _applicationService.updateApplicationStatus(
        jobId: jobId,
        userId: userId,
        status: 'accepted',
      );

      // Increment filled slots
      final newFilledSlots = filledSlots + 1;
      final isFull = newFilledSlots >= totalSlots;

      // Update job
      await _firestore.collection('jobs').doc(jobId).update({
        'filledSlots': newFilledSlots,
        'isClosed': isFull,
      });

      // If job is now full, optionally reject pending applicants
      if (isFull) {
        await _rejectPendingApplicants(jobId, userId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error accepting applicant: $e');
      rethrow;
    }
  }

  /// Reject pending applicants when job is full
  Future<void> _rejectPendingApplicants(String jobId, String acceptedUserId) async {
    try {
      final pendingSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in pendingSnapshot.docs) {
        if (doc.data()['userId'] != acceptedUserId) {
          await doc.reference.update({
            'status': 'rejected',
            'autoRejected': true,
            'rejectionReason': 'Cupos completos',
            'updatedAt': Timestamp.now(),
          });

          // Send notification
          final userData = doc.data();
          await _firestore
              .collection('users')
              .doc(userData['userId'])
              .collection('notifications')
              .add({
            'title': 'Cupos completos',
            'body': 'El trabajo "${userData['jobTitle']}" ha cerrado sus cupos',
            'type': 'application_status',
            'jobId': jobId,
            'status': 'rejected',
            'read': false,
            'createdAt': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error rejecting pending applicants: $e');
    }
  }

  /// Reject an applicant
  Future<void> rejectApplicant({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Get current application status
      final applicationSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (applicationSnapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      final currentStatus = applicationSnapshot.docs.first.data()['status'];

      // If was accepted, decrement filled slots
      if (currentStatus == 'accepted') {
        final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
        final jobData = jobDoc.data();
        
        if (jobData != null) {
          final filledSlots = jobData['filledSlots'] ?? 0;
          final newFilledSlots = filledSlots > 0 ? filledSlots - 1 : 0;
          final totalSlots = jobData['totalSlots'] ?? 1;

          await _firestore.collection('jobs').doc(jobId).update({
            'filledSlots': newFilledSlots,
            'isClosed': newFilledSlots >= totalSlots ? true : false,
          });
        }
      }

      // Update application status
      await _applicationService.updateApplicationStatus(
        jobId: jobId,
        userId: userId,
        status: 'rejected',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting applicant: $e');
      rethrow;
    }
  }

  /// Assign job to an applicant
  Future<void> assignJob({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Update application status to assigned
      await _applicationService.updateApplicationStatus(
        jobId: jobId,
        userId: userId,
        status: 'assigned',
      );

      // Update job status to assigned
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'assigned',
        'assignedTo': userId,
        'assignedAt': Timestamp.now(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning job: $e');
      rethrow;
    }
  }

  /// Open or create chat with an applicant
  Future<String> openChat({
    required String jobId,
    required String userId,
  }) async {
    try {
      // Get job data
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      
      if (jobData == null) {
        throw 'Trabajo no encontrado';
      }

      final jobTitle = jobData['title'] ?? 'Trabajo';

      // Create or get existing chat
      final chatId = await _chatService.createChat(
        otherUserId: userId,
        jobId: jobId,
        jobTitle: jobTitle,
      );

      return chatId;
    } catch (e) {
      debugPrint('Error opening chat: $e');
      rethrow;
    }
  }

  /// Get applicants count for a job
  Future<int> getApplicantsCount(String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting applicants count: $e');
      return 0;
    }
  }

  /// Get applicants count by status
  Future<Map<String, int>> getApplicantsStats(String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .get();

      int total = snapshot.docs.length;
      int pending = 0;
      int accepted = 0;
      int rejected = 0;
      int assigned = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'accepted':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'assigned':
            assigned++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'assigned': assigned,
      };
    } catch (e) {
      debugPrint('Error getting applicants stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'assigned': 0,
      };
    }
  }
}

