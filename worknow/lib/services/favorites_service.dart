import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite_job_model.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static FavoritesService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache de IDs de favoritos para acceso rápido
  final Set<String> _favoriteJobIds = {};

  Set<String> get favoriteJobIds => _favoriteJobIds;

  // Inicializar y cargar favoritos del usuario
  Future<void> loadUserFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      _favoriteJobIds.clear();
      for (var doc in snapshot.docs) {
        final jobId = doc.data()['jobId'];
        if (jobId != null) {
          _favoriteJobIds.add(jobId);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  // Verificar si un trabajo está en favoritos
  bool isFavorite(String jobId) {
    return _favoriteJobIds.contains(jobId);
  }

  // Agregar un trabajo a favoritos
  Future<void> addFavorite({
    required String jobId,
    required Map<String, dynamic> jobData,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('User not authenticated');
      return;
    }

    try {
      final favoriteRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(jobId);

      final favorite = FavoriteJob(
        id: jobId,
        jobId: jobId,
        userId: userId,
        title: jobData['title'] ?? 'Sin título',
        imageUrl: jobData['imageUrl'],
        city: jobData['city'] ?? 'Ciudad',
        country: jobData['country'] ?? 'País',
        rating: (jobData['rating'] as num?)?.toDouble(),
        budget: jobData['budget'] ?? 0,
        category: jobData['category'] ?? 'General',
        createdAt: Timestamp.now(),
      );

      await favoriteRef.set(favorite.toMap());

      _favoriteJobIds.add(jobId);
      notifyListeners();

      debugPrint('✅ Added to favorites: $jobId');
    } catch (e) {
      debugPrint('❌ Error adding favorite: $e');
      rethrow;
    }
  }

  // Eliminar un trabajo de favoritos
  Future<void> removeFavorite(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('User not authenticated');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(jobId)
          .delete();

      _favoriteJobIds.remove(jobId);
      notifyListeners();

      debugPrint('✅ Removed from favorites: $jobId');
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
      rethrow;
    }
  }

  // Toggle favorito (agregar o eliminar)
  Future<void> toggleFavorite({
    required String jobId,
    required Map<String, dynamic> jobData,
  }) async {
    if (isFavorite(jobId)) {
      await removeFavorite(jobId);
    } else {
      await addFavorite(jobId: jobId, jobData: jobData);
    }
  }

  // Obtener stream de favoritos del usuario
  Stream<List<FavoriteJob>> getFavoritesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FavoriteJob.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener lista de favoritos (future)
  Future<List<FavoriteJob>> getFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FavoriteJob.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  // Limpiar cache al cerrar sesión
  void clearCache() {
    _favoriteJobIds.clear();
    notifyListeners();
  }
}

