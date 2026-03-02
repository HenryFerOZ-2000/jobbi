import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Política de Privacidad',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔒 POLÍTICA DE PRIVACIDAD',
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'VERIFICACIÓN DE IDENTIDAD',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Actualizado el 30 de noviembre de 2025',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildIntroText(),
              const SizedBox(height: 24),
              
              _buildSection(
                '1. Datos que recopilamos',
                'Para verificar la identidad de los usuarios, solicitamos voluntariamente:',
                [
                  'Fotografía de la cédula de identidad o documento equivalente',
                  'Fotografía tipo selfie del usuario',
                  'Datos básicos del perfil (nombre, correo, teléfono)',
                ],
              ),
              
              _buildSection(
                '2. Finalidad del uso de los datos',
                'La información recopilada se utiliza exclusivamente para:',
                [
                  'Confirmar que el usuario es una persona real',
                  'Reducir riesgos de fraude, duplicación de cuentas y estafas',
                  'Aumentar la seguridad de empleadores y trabajadores',
                  'Garantizar la transparencia en las transacciones dentro de la plataforma',
                ],
                highlight: 'No utilizamos estos datos para ningún otro fin.',
              ),
              
              _buildSection(
                '3. Quién puede acceder a los datos',
                'Los datos de verificación solo podrán ser vistos por:',
                [
                  'El propio usuario (dueño de la cuenta)',
                  'Administradores autorizados de la plataforma',
                ],
                highlight: 'Nadie más tiene acceso a la información',
              ),
              
              _buildSection(
                '4. Almacenamiento y seguridad',
                'Las imágenes son almacenadas en servidores seguros de Firebase Storage con reglas estrictas que impiden accesos no autorizados.\n\nUtilizamos mecanismos de seguridad como:',
                [
                  'Conexiones cifradas (HTTPS)',
                  'Restricciones de acceso por usuario',
                  'Identificadores encriptados',
                  'Accesos registrados y auditados',
                ],
              ),
              
              _buildSection(
                '5. Conservación y eliminación de datos',
                'Los datos serán conservados únicamente mientras:',
                [
                  'Sea necesario validar la identidad',
                  'El usuario mantenga activa su cuenta',
                ],
              ),
              
              _buildContactSection(),
              
              _buildSection(
                '6. Consentimiento del usuario',
                'Al subir las imágenes, el usuario declara que:',
                [
                  'Proporciona la información de forma libre y voluntaria',
                  'Acepta esta política de privacidad',
                  'Autoriza el uso de la información exclusivamente para fines de verificación',
                ],
              ),
              
              _buildSection(
                '7. Derechos de Habeas Data',
                'El usuario puede:',
                [
                  'Acceder a sus datos',
                  'Solicitar corrección',
                  'Solicitar eliminación',
                  'Solicitar explicación sobre el tratamiento',
                ],
                highlight: 'Conforme a la Ley Orgánica de Protección de Datos Personales del Ecuador.',
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'WorkNow se compromete a proteger la privacidad de sus usuarios y cumplir con todas las normativas vigentes sobre protección de datos personales.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroText() {
    return Text(
      'La aplicación WorkNow recopila y procesa ciertos datos personales con el fin de garantizar la seguridad, autenticidad y confianza dentro de la plataforma. Esta política describe cómo se gestionan los datos utilizados en el proceso de verificación de identidad.',
      style: AppTextStyles.bodyMedium.copyWith(
        height: 1.6,
      ),
    );
  }

  Widget _buildSection(String title, String description, List<String> items, {String? highlight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  item,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (highlight != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              highlight,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.email_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'El usuario puede solicitar la eliminación de sus datos en cualquier momento escribiendo a:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.email_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'soporte@worknow.com',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

