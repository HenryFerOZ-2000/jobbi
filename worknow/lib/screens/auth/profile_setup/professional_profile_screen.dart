import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onComplete;
  final VoidCallback onBack;

  const ProfessionalProfileScreen({
    super.key,
    required this.initialData,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _universidadController = TextEditingController();
  
  int? _selectedYear;
  
  // Generar lista de años (últimos 70 años)
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List.generate(70, (index) => currentYear - index);

    // Cargar datos previos si existen
    if (widget.initialData['perfilProfesional'] != null) {
      final perfil = widget.initialData['perfilProfesional'] as Map<String, dynamic>;
      _tituloController.text = perfil['titulo'] ?? '';
      _universidadController.text = perfil['universidad'] ?? '';
      _selectedYear = perfil['anioGraduacion'];
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _universidadController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el año de graduación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final data = {
      ...widget.initialData,
      'perfilProfesional': {
        'titulo': _tituloController.text.trim(),
        'universidad': _universidadController.text.trim(),
        'anioGraduacion': _selectedYear,
      },
    };

    widget.onComplete(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Perfil Profesional'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Paso 3 de 3',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu formación académica',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuéntanos sobre tu título universitario',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 32),

                // Icono decorativo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Título universitario
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título Universitario *',
                    prefixIcon: Icon(Icons.workspace_premium_outlined),
                    hintText: 'Ej: Ingeniero en Sistemas',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                // Universidad
                TextFormField(
                  controller: _universidadController,
                  decoration: const InputDecoration(
                    labelText: 'Universidad *',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                    hintText: 'Ej: Universidad Nacional',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                // Año de graduación
                DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Año de Graduación *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: _years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                  validator: (v) => v == null ? 'Requerido' : null,
                ),

                const SizedBox(height: 32),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Esta información te ayudará a destacar en trabajos profesionales',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Botón Finalizar
                ElevatedButton(
                  onPressed: _handleComplete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Finalizar y Guardar'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

