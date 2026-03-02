import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Sign in with email & password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email & password
  Future<UserCredential> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        // Campos antiguos (mantenidos para compatibilidad)
        'profession': '',
        'bio': '',
        'skills': [],
        'city': '',
        'country': '',
        'photoUrl': '',
        'status': 'Disponible',
        'rating': 0.0,
        'profileCompleted': false,
        'isProfessional': false,
        'hourlyRate': 0.0,
        'experience': '',
        'isAvailable': false,
        'completedJobs': 0,
        // Nuevos campos del flujo reestructurado
        'nombre': '',
        'apellido': '',
        'telefono': '',
        'pais': '',
        'provincia': '',
        'ciudad': '',
        'habilidades': [],
        'poseeTituloUniversitario': false,
        'perfilProfesional': null,
        'createdAt': Timestamp.now(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Inicio de sesión cancelado';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          // Campos antiguos (mantenidos para compatibilidad)
          'profession': '',
          'bio': '',
          'skills': [],
          'city': '',
          'country': '',
          'photoUrl': userCredential.user!.photoURL ?? '',
          'status': 'Disponible',
          'rating': 0.0,
          'profileCompleted': false,
          'isProfessional': false,
          'hourlyRate': 0.0,
          'experience': '',
          'isAvailable': false,
          'completedJobs': 0,
          // Nuevos campos del flujo reestructurado
          'nombre': '',
          'apellido': '',
          'telefono': '',
          'pais': '',
          'provincia': '',
          'ciudad': '',
          'habilidades': [],
          'poseeTituloUniversitario': false,
          'perfilProfesional': null,
          'createdAt': Timestamp.now(),
        });
      }

      return userCredential;
    } catch (e) {
      throw 'Error al iniciar sesión con Google: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error: ${e.message}';
    }
  }
}

