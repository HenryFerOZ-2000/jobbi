import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
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
  final _professionController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  String _selectedCategory = 'Desarrollo de Software';
  bool _hasDegree = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isProfessional = false;
  File? _profileImage;
  String _photoUrl = '';
  final _imagePicker = ImagePicker();

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
  void initState() {
    super.initState();
    _loadUserData();
  }

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
    _professionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return null;
    
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Error al subir imagen: ${e.toString()}';
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Usuario no autenticado';
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw 'Perfil no encontrado';
      }

      final appUser = AppUser.fromMap(doc.data()!, user.uid);

      if (mounted) {
        _fullNameController.text = appUser.fullName;
        _phoneController.text = appUser.phone;
        _countryController.text = appUser.country;
        _cityController.text = appUser.city;
        _selectedCategory = appUser.category;
        _skillsController.text = appUser.skills.join(', ');
        _experienceController.text = appUser.experience;
        _hasDegree = appUser.hasDegree;
        _professionalTitleController.text = appUser.professionalTitle ?? '';
        _educationController.text = appUser.education ?? '';
        _portfolioController.text = appUser.portfolioLinks?.join(', ') ?? '';
        
        // Load photo and professional data if available
        final data = doc.data()!;
        _photoUrl = data['photoUrl'] ?? '';
        _isProfessional = data['isProfessional'] ?? false;
        _professionController.text = data['profession'] ?? '';
        _hourlyRateController.text = (data['hourlyRate'] ?? 0.0).toString();

        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Upload profile image if selected
      String? newPhotoUrl;
      if (_profileImage != null) {
        newPhotoUrl = await _uploadProfileImage(user.uid);
      }

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

      // Prepare update data
      Map<String, dynamic> updateData = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'hasDegree': _hasDegree,
        'professionalTitle': _hasDegree ? _professionalTitleController.text.trim() : null,
        'education': _educationController.text.trim().isNotEmpty
            ? _educationController.text.trim()
            : null,
        'category': _selectedCategory,
        'skills': skills,
        'experience': _experienceController.text.trim(),
        'portfolioLinks': portfolioLinks,
        'isProfessional': _isProfessional,
      };

      // Add photo URL if uploaded
      if (newPhotoUrl != null) {
        updateData['photoUrl'] = newPhotoUrl;
      }

      // Add professional data if user is a professional
      if (_isProfessional) {
        updateData['profession'] = _professionController.text.trim();
        updateData['hourlyRate'] = double.tryParse(_hourlyRateController.text.trim()) ?? 0.0;
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Photo Selector
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: _profileImage != null 
                            ? FileImage(_profileImage!) 
                            : (_photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null) as ImageProvider?,
                        child: _profileImage == null && _photoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary.withOpacity(0.5),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profileImage == null && _photoUrl.isEmpty
                      ? 'Agregar foto de perfil'
                      : 'Toca el ícono para cambiar la foto',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

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
                    hintText: 'Separadas por comas',
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
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                // Professional Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Eres profesional?',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Ofrece tus servicios y recibe trabajos',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isProfessional,
                        onChanged: (value) {
                          setState(() {
                            _isProfessional = value;
                          });
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Professional Fields (conditional)
                if (_isProfessional) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _professionController,
                    decoration: const InputDecoration(
                      labelText: 'Profesión',
                      prefixIcon: Icon(Icons.business_center_outlined),
                      hintText: 'Ej: Desarrollador, Diseñador, Electricista',
                    ),
                    validator: _isProfessional 
                        ? (v) => v == null || v.isEmpty ? 'Requerido' : null
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hourlyRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarifa por hora (USD)',
                      prefixIcon: Icon(Icons.attach_money_outlined),
                      hintText: '25.00',
                    ),
                    validator: _isProfessional 
                        ? (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (double.tryParse(v) == null) return 'Ingresa un número válido';
                            return null;
                          }
                        : null,
                  ),
                ],
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
                    hintText: 'Separados por comas',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

