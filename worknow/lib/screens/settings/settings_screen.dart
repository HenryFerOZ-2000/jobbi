import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../verification/verification_status_screen.dart';
import '../verification/privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _language = 'Español';
  String _theme = 'Claro';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final userName = userData?['name'] ?? userData?['fullName'] ?? 'Usuario';
          final userEmail = currentUser?.email ?? '';
          final verificationStatus = userData?['verificationStatus'] ?? 'unverified';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: AppTextStyles.h2.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(userName, style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Account Section
                _buildSectionHeader('Cuenta'),
                _buildListTile(
                  icon: Icons.person_outline,
                  title: 'Editar Perfil',
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: 'Cambiar Contraseña',
                  onTap: () {
                    _showChangePasswordDialog();
                  },
                ),
                _buildListTile(
                  icon: Icons.email_outlined,
                  title: 'Correo Electrónico',
                  subtitle: userEmail,
                  trailing: const SizedBox.shrink(),
                ),

                const Divider(height: 32),

                // Notifications Section
                _buildSectionHeader('Notificaciones'),
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Recibir notificaciones de la app',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Notificaciones por Email',
                  subtitle: 'Recibir emails sobre trabajos',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.mobile_friendly,
                  title: 'Notificaciones Push',
                  subtitle: 'Alertas en tiempo real',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),

                const Divider(height: 32),

                // Preferences Section
                _buildSectionHeader('Preferencias'),
                _buildListTile(
                  icon: Icons.language_outlined,
                  title: 'Idioma',
                  subtitle: _language,
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                _buildListTile(
                  icon: Icons.palette_outlined,
                  title: 'Tema',
                  subtitle: _theme,
                  onTap: () {
                    _showThemeDialog();
                  },
                ),

                const Divider(height: 32),

                // Privacy Section
                _buildSectionHeader('Privacidad y Seguridad'),
                _buildVerificationTile(verificationStatus),
                _buildListTile(
                  icon: Icons.visibility_outlined,
                  title: 'Privacidad del Perfil',
                  subtitle: 'Público',
                  onTap: () {
                    _showPrivacyDialog();
                  },
                ),
                _buildListTile(
                  icon: Icons.block_outlined,
                  title: 'Usuarios Bloqueados',
                  onTap: () {
                    // TODO: Navigate to blocked users
                  },
                ),
                _buildListTile(
                  icon: Icons.security_outlined,
                  title: 'Verificación en Dos Pasos',
                  onTap: () {
                    // TODO: 2FA setup
                  },
                ),

                const Divider(height: 32),

                // Support Section
                _buildSectionHeader('Ayuda y Soporte'),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'Centro de Ayuda',
                  onTap: () {
                    // TODO: Open help center
                  },
                ),
                _buildListTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Reportar un Problema',
                  onTap: () {
                    _showReportDialog();
                  },
                ),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: 'Acerca de',
                  subtitle: 'Versión 1.0.0',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),

                const Divider(height: 32),

                // Legal Section
                _buildSectionHeader('Legal'),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: 'Términos de Servicio',
                  onTap: () {
                    // TODO: Show terms
                  },
                ),
                _buildListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 32),

                // Danger Zone
                _buildSectionHeader('Zona de Peligro'),
                _buildListTile(
                  icon: Icons.delete_outline,
                  title: 'Eliminar Cuenta',
                  titleColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  titleColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () {
                    _handleLogout();
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationTile(String verificationStatus) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (verificationStatus) {
      case 'verified':
        statusText = '✓ Verificado';
        statusColor = AppColors.success;
        statusIcon = Icons.verified_user_rounded;
        break;
      case 'pending':
        statusText = 'En Revisión';
        statusColor = Colors.orange;
        statusIcon = Icons.schedule_rounded;
        break;
      case 'rejected':
        statusText = 'Rechazado';
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default: // unverified
        statusText = 'No Verificado';
        statusColor = Colors.grey;
        statusIcon = Icons.shield_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Verificación de Identidad',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          statusText,
          style: AppTextStyles.bodySmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (verificationStatus == 'unverified') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Verificar',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: statusColor,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationStatusScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: AppTextStyles.h5.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmall)
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmall)
          : null,
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text(
          'Se enviará un enlace de restablecimiento a tu correo electrónico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Send password reset email
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace enviado a tu correo'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'Español',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Claro'),
              value: 'Claro',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Oscuro'),
              value: 'Oscuro',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Automático'),
              value: 'Automático',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidad del Perfil'),
        content: const Text(
          'Controla quién puede ver tu perfil profesional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar un Problema'),
        content: TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe el problema...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte enviado. Gracias!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'WorkNow',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 WorkNow. Todos los derechos reservados.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'WorkNow es una plataforma que conecta profesionales con oportunidades de trabajo.',
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Cuenta',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Esta acción es permanente y no se puede deshacer. '
          'Todos tus datos serán eliminados.\n\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar Cuenta'),
          ),
        ],
      ),
    );
  }
}

