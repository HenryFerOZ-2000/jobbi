import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class SavedProfilesController extends ChangeNotifier {
  SavedProfilesController._();
  static final SavedProfilesController instance = SavedProfilesController._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Set<String> _savedProfileIds = {};

  /// Initialize saved profiles
  Future<void> init() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedProfiles')
          .get();

      _savedProfileIds.clear();
      for (var doc in snapshot.docs) {
        _savedProfileIds.add(doc.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing saved profiles: $e');
    }
  }

  /// Toggle saved profile
  Future<void> toggleSavedProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw 'Usuario no autenticado';
    }

    try {
      final savedProfileRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedProfiles')
          .doc(userId);

      if (_savedProfileIds.contains(userId)) {
        // Remove from saved
        await savedProfileRef.delete();
        _savedProfileIds.remove(userId);
      } else {
        // Add to saved
        await savedProfileRef.set({
          'userId': userId,
          'fullName': userData['fullName'] ?? userData['name'] ?? 'Usuario',
          'category': userData['category'] ?? 'Sin categoría',
          'city': userData['city'] ?? userData['ciudad'] ?? '',
          'country': userData['country'] ?? userData['pais'] ?? '',
          'rating': userData['rating'] ?? 0.0,
          'totalRatings': userData['totalRatings'] ?? 0,
          'savedAt': Timestamp.now(),
        });
        _savedProfileIds.add(userId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling saved profile: $e');
      rethrow;
    }
  }

  /// Check if a profile is saved
  bool isProfileSaved(String userId) {
    return _savedProfileIds.contains(userId);
  }

  /// Get stream of saved profiles
  Stream<List<AppUser>> getSavedProfilesStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('savedProfiles')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<AppUser> savedUsers = [];

      for (var doc in snapshot.docs) {
        final savedData = doc.data();
        final userId = savedData['userId'];

        // Get full user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          savedUsers.add(AppUser.fromMap(userDoc.data()!, userId));
        }
      }

      return savedUsers;
    });
  }

  /// Get list of saved profiles (one-time fetch)
  Future<List<AppUser>> getSavedProfilesList() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savedProfiles')
          .orderBy('savedAt', descending: true)
          .get();

      List<AppUser> savedUsers = [];

      for (var doc in snapshot.docs) {
        final savedData = doc.data();
        final userId = savedData['userId'];

        // Get full user data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          savedUsers.add(AppUser.fromMap(userDoc.data()!, userId));
        }
      }

      return savedUsers;
    } catch (e) {
      debugPrint('Error fetching saved profiles: $e');
      return [];
    }
  }
}

