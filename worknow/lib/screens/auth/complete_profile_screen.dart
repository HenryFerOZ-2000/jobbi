import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _professionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  
  bool _isLoading = false;
  bool _isProfessional = false;
  File? _profileImage;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _professionController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Upload profile image if selected
      String? photoUrl;
      if (_profileImage != null) {
        photoUrl = await _uploadProfileImage(user.uid);
      }

      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Prepare base profile data
      Map<String, dynamic> profileData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': skills,
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'profileCompleted': true,
        'isProfessional': _isProfessional,
      };

      // Add photo URL if uploaded
      if (photoUrl != null) {
        profileData['photoUrl'] = photoUrl;
      }

      // Add professional data if user is a professional
      if (_isProfessional) {
        profileData['profession'] = _professionController.text.trim();
        profileData['hourlyRate'] = double.tryParse(_hourlyRateController.text.trim()) ?? 0.0;
        profileData['experience'] = _experienceController.text.trim();
        profileData['isAvailable'] = true;
        profileData['rating'] = 0.0;
        profileData['completedJobs'] = 0;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(profileData);

      if (mounted) {
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
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
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
                Text(
                  'Cuéntanos sobre ti',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tu perfil profesional',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Profile Photo Selector
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: _profileImage != null 
                            ? FileImage(_profileImage!) 
                            : null,
                        child: _profileImage == null
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
                  _profileImage == null 
                      ? 'Agregar foto de perfil (opcional)'
                      : 'Toca el ícono para cambiar la foto',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Biografía',
                    prefixIcon: Icon(Icons.info_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Habilidades (separadas por comas)',
                    prefixIcon: Icon(Icons.star_outlined),
                    hintText: 'Flutter, Design, Marketing',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'País',
                    prefixIcon: Icon(Icons.public_outlined),
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
                              style: AppTextStyles.bodyLarge.copyWith(
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
                  const SizedBox(height: 24),
                  Text(
                    'Información Profesional',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
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
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _experienceController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Experiencia',
                      prefixIcon: Icon(Icons.history_edu_outlined),
                      hintText: 'Describe tu experiencia profesional',
                    ),
                    validator: _isProfessional 
                        ? (v) => v == null || v.isEmpty ? 'Requerido' : null
                        : null,
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar y Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

