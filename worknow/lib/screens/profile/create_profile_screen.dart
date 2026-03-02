import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _professionalTitleController = TextEditingController();
  final _educationController = TextEditingController();
  final _portfolioController = TextEditingController();

  String _selectedCategory = 'Desarrollo de Software';
  bool _hasDegree = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Desarrollo de Software',
    'Diseño Gráfico',
    'Marketing Digital',
    'Redacción y Contenido',
    'Traducción',
    'Fotografía y Video',
    'Arquitectura',
    'Ingeniería',
    'Consultoría',
    'Educación',
    'Salud',
    'Legal',
    'Contabilidad',
    'Recursos Humanos',
    'Ventas',
    'Servicio al Cliente',
    'Limpieza',
    'Construcción',
    'Electricidad',
    'Plomería',
    'Mecánica',
    'Jardinería',
    'Cocina y Chef',
    'Belleza y Estética',
    'Entrenamiento Personal',
    'Otro',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _professionalTitleController.dispose();
    _educationController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar título profesional si tiene degree
    if (_hasDegree && _professionalTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu título profesional'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Parse skills
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Parse portfolio links
      List<String>? portfolioLinks;
      if (_portfolioController.text.trim().isNotEmpty) {
        portfolioLinks = _portfolioController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // Create user model
      final appUser = AppUser(
        uid: user.uid,
        fullName: _fullNameController.text.trim(),
        email: user.email ?? '',
        phone: _phoneController.text.trim(),
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        hasDegree: _hasDegree,
        professionalTitle: _hasDegree ? _professionalTitleController.text.trim() : null,
        education: _educationController.text.trim().isNotEmpty
            ? _educationController.text.trim()
            : null,
        category: _selectedCategory,
        skills: skills,
        experience: _experienceController.text.trim(),
        portfolioLinks: portfolioLinks,
        createdAt: Timestamp.now(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Crear Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Completa tu Perfil Profesional',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta información ayudará a los empleadores a encontrarte',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+1 234 567 8900',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Country
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'País *',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                // Divider
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 24),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría Laboral *',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Skills
                TextFormField(
                  controller: _skillsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Habilidades *',
                    prefixIcon: Icon(Icons.star_outline),
                    hintText: 'Flutter, React, Node.js (separadas por comas)',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  controller: _experienceController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Experiencia Laboral *',
                    prefixIcon: Icon(Icons.work_history_outlined),
                    hintText: 'Describe tu experiencia profesional...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                // Divider
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 24),

                // Has Degree Switch
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _hasDegree
                        ? AppColors.primaryLight
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasDegree
                          ? AppColors.primary
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: _hasDegree
                            ? AppColors.primary
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¿Tienes título o certificación profesional?',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _hasDegree
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: _hasDegree,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _hasDegree = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Professional Title (only if hasDegree)
                if (_hasDegree) ...[
                  TextFormField(
                    controller: _professionalTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Título Profesional *',
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'Ej: Ingeniero de Software',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Education (optional)
                if (_hasDegree) ...[
                  TextFormField(
                    controller: _educationController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Educación (opcional)',
                      prefixIcon: Icon(Icons.school_outlined),
                      hintText: 'Universidad, año, institución...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Portfolio Links (optional)
                TextFormField(
                  controller: _portfolioController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Enlaces de Portfolio (opcional)',
                    prefixIcon: Icon(Icons.link_outlined),
                    hintText: 'github.com/user, behance.net/user (separados por comas)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar Perfil'),
                ),
                const SizedBox(height: 16),

                // Required fields note
                Text(
                  '* Campos obligatorios',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

