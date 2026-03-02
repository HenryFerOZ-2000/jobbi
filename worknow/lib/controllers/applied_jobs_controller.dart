import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppliedJobsController extends ChangeNotifier {
  AppliedJobsController._();
  static final AppliedJobsController instance = AppliedJobsController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stream of jobs the current user has applied to
  Stream<List<Map<String, dynamic>>> getJobsIHaveAppliedTo() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((applicationsSnapshot) async {
      List<Map<String, dynamic>> results = [];

      for (var appDoc in applicationsSnapshot.docs) {
        final appData = appDoc.data();
        final jobId = appData['jobId'];

        // Get job details
        final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
        
        if (jobDoc.exists) {
          final jobData = jobDoc.data() as Map<String, dynamic>;
          
          results.add({
            'applicationId': appDoc.id,
            'jobId': jobId,
            'jobTitle': jobData['title'] ?? 'Sin título',
            'jobDescription': jobData['description'] ?? '',
            'jobCategory': jobData['category'] ?? '',
            'jobBudget': jobData['budget'] ?? 0.0,
            'jobCity': jobData['city'] ?? '',
            'jobCountry': jobData['country'] ?? '',
            'jobStatus': jobData['status'] ?? 'open',
            'applicationStatus': appData['status'] ?? 'pending',
            'appliedAt': appData['appliedAt'],
            'message': appData['message'] ?? '',
            'ownerId': jobData['ownerId'] ?? '',
          });
        }
      }

      return results;
    });
  }

  /// Get application status for a specific job
  Future<String> getApplicationStatus(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return 'not_applied';
    }

    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'not_applied';
      }

      return snapshot.docs.first.data()['status'] ?? 'pending';
    } catch (e) {
      debugPrint('Error getting application status: $e');
      return 'error';
    }
  }

  /// Withdraw an application
  Future<void> withdrawApplication(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw 'Usuario no autenticado';
    }

    try {
      // Find the application
      final snapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw 'Aplicación no encontrada';
      }

      // Delete the application
      await snapshot.docs.first.reference.delete();

      // Also remove from job's applicantsIds array
      await _firestore.collection('jobs').doc(jobId).update({
        'applicantsIds': FieldValue.arrayRemove([userId]),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error withdrawing application: $e');
      rethrow;
    }
  }

  /// Get application statistics
  Future<Map<String, int>> getApplicationStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {'total': 0, 'pending': 0, 'accepted': 0, 'rejected': 0};
    }

    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .get();

      int total = snapshot.docs.length;
      int pending = 0;
      int accepted = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (status == 'pending') {
          pending++;
        } else if (status == 'accepted') {
          accepted++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
      };
    } catch (e) {
      debugPrint('Error getting application stats: $e');
      return {'total': 0, 'pending': 0, 'accepted': 0, 'rejected': 0};
    }
  }

  /// Get list of applied jobs (one-time fetch)
  Future<List<Map<String, dynamic>>> getAppliedJobsList() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final applicationsSnapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();

      List<Map<String, dynamic>> results = [];

      for (var appDoc in applicationsSnapshot.docs) {
        final appData = appDoc.data();
        final jobId = appData['jobId'];

        // Get job details
        final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
        
        if (jobDoc.exists) {
          final jobData = jobDoc.data() as Map<String, dynamic>;
          
          results.add({
            'applicationId': appDoc.id,
            'jobId': jobId,
            'jobTitle': jobData['title'] ?? 'Sin título',
            'jobDescription': jobData['description'] ?? '',
            'jobCategory': jobData['category'] ?? '',
            'jobBudget': jobData['budget'] ?? 0.0,
            'jobCity': jobData['city'] ?? '',
            'jobCountry': jobData['country'] ?? '',
            'jobStatus': jobData['status'] ?? 'open',
            'applicationStatus': appData['status'] ?? 'pending',
            'appliedAt': appData['appliedAt'],
            'message': appData['message'] ?? '',
            'ownerId': jobData['ownerId'] ?? '',
          });
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error fetching applied jobs: $e');
      return [];
    }
  }
}

