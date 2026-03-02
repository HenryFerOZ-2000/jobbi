import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../screens/verification/verification_status_screen.dart';

class VerificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user is verified and show dialog if not
  /// Returns true if verified, false otherwise
  static Future<bool> checkVerificationAndShowDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final status = userDoc.data()?['verificationStatus'] ?? 'unverified';

      if (status == 'verified') {
        return true;
      }

      // Show dialog based on status
      if (context.mounted) {
        await _showVerificationDialog(context, status);
      }

      return false;
    } catch (e) {
      debugPrint('Error checking verification: $e');
      return false;
    }
  }

  static Future<void> _showVerificationDialog(BuildContext context, String status) async {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    switch (status) {
      case 'pending':
        title = 'Verificación en Proceso';
        message = 'Tu verificación está siendo revisada. Te notificaremos cuando esté lista.';
        icon = Icons.schedule_rounded;
        iconColor = Colors.orange.shade700;
        break;
      case 'rejected':
        title = 'Verificación Rechazada';
        message = 'Tu verificación fue rechazada. Por favor, revisa los detalles y vuelve a enviarla.';
        icon = Icons.cancel_rounded;
        iconColor = Colors.red.shade700;
        break;
      default: // unverified
        title = 'Verifica tu Identidad';
        message = 'Debes verificar tu identidad para acceder a esta función. Es rápido y seguro.';
        icon = Icons.verified_user_rounded;
        iconColor = AppColors.primary;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerificationStatusScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        status == 'rejected' ? 'Ver Detalles' : 'Verificar',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get verification status for a user
  static Future<String> getVerificationStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['verificationStatus'] ?? 'unverified';
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      return 'unverified';
    }
  }

  /// Check if user is verified (without showing dialog)
  static Future<bool> isUserVerified(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final status = userDoc.data()?['verificationStatus'] ?? 'unverified';
      return status == 'verified';
    } catch (e) {
      debugPrint('Error checking if user is verified: $e');
      return false;
    }
  }
}

