import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../controllers/verification_controller.dart';
import 'verify_identity_screen.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  final VerificationController _controller = VerificationController.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estado de Verificación')),
        body: const Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Estado de Verificación',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _controller.getVerificationStatus(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final data = snapshot.data ?? {'status': 'unverified'};
          final status = data['status'] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(status, data),
                
                if (status == 'unverified') ...[
                  const SizedBox(height: 24),
                  _buildBenefitsSection(),
                  const SizedBox(height: 24),
                  _buildVerifyButton(),
                ] else if (status == 'pending') ...[
                  const SizedBox(height: 24),
                  _buildPendingInfo(data),
                ] else if (status == 'rejected') ...[
                  const SizedBox(height: 24),
                  _buildRejectionInfo(data),
                  const SizedBox(height: 24),
                  _buildVerifyButton(isResubmit: true),
                ] else if (status == 'verified') ...[
                  const SizedBox(height: 24),
                  _buildVerifiedInfo(data),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String status, Map<String, dynamic> data) {
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        icon = Icons.schedule_rounded;
        title = 'Verificación en Proceso';
        subtitle = 'Estamos revisando tu información';
        break;
      case 'verified':
        bgColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        icon = Icons.verified_user_rounded;
        title = '¡Cuenta Verificada!';
        subtitle = 'Tu identidad ha sido confirmada';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        title = 'Verificación Rechazada';
        subtitle = 'Revisa los detalles y vuelve a intentar';
        break;
      default: // unverified
        bgColor = Colors.grey.shade50;
        iconColor = Colors.grey.shade600;
        icon = Icons.shield_outlined;
        title = 'Cuenta No Verificada';
        subtitle = 'Verifica tu identidad para acceder a todas las funciones';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
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
              color: iconColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beneficios de Verificarte',
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.work_rounded,
            'Publica trabajos',
            'Crea ofertas laborales y encuentra trabajadores',
          ),
          _buildBenefitItem(
            Icons.send_rounded,
            'Postula a empleos',
            'Aplica a ofertas de trabajo verificadas',
          ),
          _buildBenefitItem(
            Icons.verified_rounded,
            'Mayor confianza',
            'Los usuarios confiarán más en ti',
          ),
          _buildBenefitItem(
            Icons.security_rounded,
            'Más seguridad',
            'Protege tu cuenta y evita fraudes',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInfo(Map<String, dynamic> data) {
    final submittedAt = data['submittedAt'];
    String dateText = 'Fecha no disponible';
    
    if (submittedAt != null) {
      final date = (submittedAt as dynamic).toDate();
      dateText = DateFormat('dd/MM/yyyy HH:mm').format(date);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu solicitud está siendo revisada',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Enviado el', dateText),
          const Divider(height: 24),
          Text(
            'Nuestro equipo revisará tu información en un plazo de 24-48 horas. Te notificaremos cuando el proceso esté completo.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionInfo(Map<String, dynamic> data) {
    final reason = data['rejectionReason'] ?? 'No se especificó un motivo';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Motivo del Rechazo',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200,
              ),
            ),
            child: Text(
              reason,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Por favor, corrige los problemas mencionados y vuelve a enviar tu verificación.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedInfo(Map<String, dynamic> data) {
    final verifiedAt = data['verifiedAt'];
    String dateText = 'Fecha no disponible';
    
    if (verifiedAt != null) {
      final date = (verifiedAt as dynamic).toDate();
      dateText = DateFormat('dd/MM/yyyy').format(date);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cuenta Verificada',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Verificado el', dateText),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Colors.green.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ahora tienes acceso completo a todas las funciones de la aplicación',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.green.shade900,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton({bool isResubmit = false}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VerifyIdentityScreen(),
            ),
          );
          
          if (result == true && mounted) {
            setState(() {}); // Refresh
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: Icon(isResubmit ? Icons.refresh_rounded : Icons.verified_user_rounded),
        label: Text(
          isResubmit ? 'Reenviar Verificación' : 'Verificar Ahora',
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

