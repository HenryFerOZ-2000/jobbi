import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job.dart';

class PostedJobsController extends ChangeNotifier {
  PostedJobsController._();
  static final PostedJobsController instance = PostedJobsController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stream of jobs posted by the current user
  Stream<List<Job>> getMyPostedJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('jobs')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get list of jobs posted by the current user (one-time fetch)
  Future<List<Job>> getMyPostedJobsList() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Job.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching posted jobs: $e');
      return [];
    }
  }

  /// Delete a job
  Future<bool> deleteJob(String jobId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw 'Usuario no autenticado';
      }

      // Verify the user is the owner
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) {
        throw 'Trabajo no encontrado';
      }

      final jobData = jobDoc.data() as Map<String, dynamic>;
      if (jobData['ownerId'] != userId) {
        throw 'No tienes permiso para eliminar este trabajo';
      }

      // Delete the job
      await _firestore.collection('jobs').doc(jobId).delete();
      
      // Also delete related applications
      final applicationsSnapshot = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .get();

      for (var doc in applicationsSnapshot.docs) {
        await doc.reference.delete();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting job: $e');
      return false;
    }
  }

  /// Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating job status: $e');
      rethrow;
    }
  }

  /// Get count of applicants for a job
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

  /// Get job statistics
  Future<Map<String, int>> getJobStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {'total': 0, 'open': 0, 'closed': 0};
    }

    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('ownerId', isEqualTo: userId)
          .get();

      int total = snapshot.docs.length;
      int open = 0;
      int closed = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'open';
        if (status == 'open') {
          open++;
        } else if (status == 'closed') {
          closed++;
        }
      }

      return {
        'total': total,
        'open': open,
        'closed': closed,
      };
    } catch (e) {
      debugPrint('Error getting job stats: $e');
      return {'total': 0, 'open': 0, 'closed': 0};
    }
  }
}

