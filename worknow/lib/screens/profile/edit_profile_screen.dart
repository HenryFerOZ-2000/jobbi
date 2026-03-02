import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _userService = UserService();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  String _photoUrl = '';
  String _selectedStatus = 'Disponible';

  // Experience
  final List<Map<String, TextEditingController>> _experienceControllers = [];

  // Education
  final List<Map<String, TextEditingController>> _educationControllers = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    
    for (var exp in _experienceControllers) {
      exp['title']?.dispose();
      exp['description']?.dispose();
      exp['years']?.dispose();
    }
    
    for (var edu in _educationControllers) {
      edu['degree']?.dispose();
      edu['institution']?.dispose();
      edu['year']?.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userData = await _userService.getUserProfile(user.uid);
      if (userData != null && mounted) {
        _nameController.text = userData['name'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _cityController.text = userData['city'] ?? '';
        _countryController.text = userData['country'] ?? '';
        _photoUrl = userData['photoUrl'] ?? '';
        _selectedStatus = userData['status'] ?? 'Disponible';

        var skillsList = userData['skills'];
        if (skillsList is List) {
          _skillsController.text = skillsList.join(', ');
        } else if (skillsList is String) {
          _skillsController.text = skillsList;
        }

        // Load experience
        final experienceData = userData['experience'];
        if (experienceData is List) {
          for (var exp in experienceData) {
            final expMap = Map<String, dynamic>.from(exp as Map);
            _experienceControllers.add({
              'title': TextEditingController(text: expMap['title'] ?? ''),
              'description': TextEditingController(text: expMap['description'] ?? ''),
              'years': TextEditingController(text: expMap['years'] ?? ''),
            });
          }
        }

        // Load education
        final educationData = userData['education'];
        if (educationData is List) {
          for (var edu in educationData) {
            final eduMap = Map<String, dynamic>.from(edu as Map);
            _educationControllers.add({
              'degree': TextEditingController(text: eduMap['degree'] ?? ''),
              'institution': TextEditingController(text: eduMap['institution'] ?? ''),
              'year': TextEditingController(text: eduMap['year'] ?? ''),
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addExperience() {
    setState(() {
      _experienceControllers.add({
        'title': TextEditingController(),
        'description': TextEditingController(),
        'years': TextEditingController(),
      });
    });
  }

  void _removeExperience(int index) {
    setState(() {
      _experienceControllers[index]['title']?.dispose();
      _experienceControllers[index]['description']?.dispose();
      _experienceControllers[index]['years']?.dispose();
      _experienceControllers.removeAt(index);
    });
  }

  void _addEducation() {
    setState(() {
      _educationControllers.add({
        'degree': TextEditingController(),
        'institution': TextEditingController(),
        'year': TextEditingController(),
      });
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _educationControllers[index]['degree']?.dispose();
      _educationControllers[index]['institution']?.dispose();
      _educationControllers[index]['year']?.dispose();
      _educationControllers.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Upload image if selected
      if (_imageFile != null) {
        await _userService.uploadProfileImage(user.uid, _imageFile!);
      }

      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Build experience list
      final experience = _experienceControllers.map((exp) {
        return {
          'title': exp['title']!.text.trim(),
          'description': exp['description']!.text.trim(),
          'years': exp['years']!.text.trim(),
        };
      }).where((exp) => exp['title']!.isNotEmpty).toList();

      // Build education list
      final education = _educationControllers.map((edu) {
        return {
          'degree': edu['degree']!.text.trim(),
          'institution': edu['institution']!.text.trim(),
          'year': edu['year']!.text.trim(),
        };
      }).where((edu) => edu['degree']!.isNotEmpty).toList();

      await _userService.updateUserProfile(user.uid, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': skills,
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'status': _selectedStatus,
        'experience': experience,
        'education': education,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo Section
                _buildCard(
                  'Foto de Perfil',
                  Icons.camera_alt_outlined,
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (_photoUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: _imageFile == null && _photoUrl.isEmpty
                              ? Icon(
                                  Icons.add_a_photo,
                                  color: AppColors.primary,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text('Cambiar Foto'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Basic Info
                _buildCard(
                  'Información Básica',
                  Icons.person_outline,
                  Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: Icon(Icons.circle_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Disponible', child: Text('Disponible')),
                          DropdownMenuItem(value: 'Ocupado', child: Text('Ocupado')),
                          DropdownMenuItem(value: 'No disponible', child: Text('No disponible')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bio
                _buildCard(
                  'Biografía',
                  Icons.info_outline,
                  TextFormField(
                    controller: _bioController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Cuéntanos sobre ti...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Location
                _buildCard(
                  'Ubicación',
                  Icons.location_on_outlined,
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'País',
                            prefixIcon: Icon(Icons.public),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Skills
                _buildCard(
                  'Habilidades',
                  Icons.star_outline,
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      hintText: 'Flutter, Design, Marketing (separadas por comas)',
                      prefixIcon: Icon(Icons.lightbulb_outline),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Experience
                _buildCard(
                  'Experiencia Laboral',
                  Icons.work_history_outlined,
                  Column(
                    children: [
                      ..._experienceControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exp = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Experiencia ${index + 1}',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _removeExperience(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: exp['title'],
                                decoration: const InputDecoration(
                                  labelText: 'Título del Puesto',
                                  prefixIcon: Icon(Icons.business_center),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: exp['description'],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción',
                                  prefixIcon: Icon(Icons.description),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: exp['years'],
                                decoration: const InputDecoration(
                                  labelText: 'Duración (ej: 2020-2023)',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _addExperience,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir Experiencia'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Education
                _buildCard(
                  'Educación',
                  Icons.school_outlined,
                  Column(
                    children: [
                      ..._educationControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final edu = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Educación ${index + 1}',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _removeEducation(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: edu['degree'],
                                decoration: const InputDecoration(
                                  labelText: 'Título/Grado',
                                  prefixIcon: Icon(Icons.school),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: edu['institution'],
                                decoration: const InputDecoration(
                                  labelText: 'Institución',
                                  prefixIcon: Icon(Icons.apartment),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: edu['year'],
                                decoration: const InputDecoration(
                                  labelText: 'Año',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _addEducation,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir Educación'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget content) {
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
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
