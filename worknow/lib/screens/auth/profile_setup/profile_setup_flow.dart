import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import 'personal_info_screen.dart';
import 'skills_selection_screen.dart';
import 'professional_profile_screen.dart';

class ProfileSetupFlow extends StatefulWidget {
  const ProfileSetupFlow({super.key});

  @override
  State<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  int _currentStep = 0;
  Map<String, dynamic> _profileData = {};
  bool _isSaving = false;

  void _handlePersonalInfoComplete(Map<String, dynamic> data) {
    setState(() {
      _profileData = {..._profileData, ...data};
      _currentStep = 1; // Ir a selección de habilidades
    });
  }

  void _handleSkillsComplete(Map<String, dynamic> data) {
    setState(() {
      _profileData = {..._profileData, ...data};
      
      // Si tiene título universitario, ir a screen de perfil profesional
      if (_profileData['poseeTituloUniversitario'] == true) {
        _currentStep = 2;
      } else {
        // Si no tiene título, finalizar directamente
        _saveProfile();
      }
    });
  }

  void _handleProfessionalProfileComplete(Map<String, dynamic> data) {
    setState(() {
      _profileData = {..._profileData, ...data};
    });
    _saveProfile();
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Preparar datos para Firestore
      final firestoreData = {
        'nombre': _profileData['nombre'],
        'apellido': _profileData['apellido'],
        'telefono': _profileData['telefono'],
        'pais': _profileData['pais'],
        'provincia': _profileData['provincia'],
        'ciudad': _profileData['ciudad'],
        'habilidades': _profileData['habilidades'],
        'poseeTituloUniversitario': _profileData['poseeTituloUniversitario'] ?? false,
        'profileCompleted': true,
        'updatedAt': Timestamp.now(),
      };

      // Agregar perfil profesional solo si existe
      if (_profileData['poseeTituloUniversitario'] == true && 
          _profileData['perfilProfesional'] != null) {
        firestoreData['perfilProfesional'] = _profileData['perfilProfesional'];
      } else {
        firestoreData['perfilProfesional'] = null;
      }

      // Mantener datos existentes que no deben ser sobrescritos
      // Esto asegura compatibilidad con el sistema anterior
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(firestoreData);

      if (mounted) {
        // Navegar al home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar perfil: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Guardando tu perfil...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Renderizar la pantalla correspondiente según el paso actual
    switch (_currentStep) {
      case 0:
        return PersonalInfoScreen(
          initialData: _profileData,
          onContinue: _handlePersonalInfoComplete,
        );
      
      case 1:
        return SkillsSelectionScreen(
          initialData: _profileData,
          onContinue: _handleSkillsComplete,
          onBack: _handleBack,
        );
      
      case 2:
        return ProfessionalProfileScreen(
          initialData: _profileData,
          onComplete: _handleProfessionalProfileComplete,
          onBack: _handleBack,
        );
      
      default:
        return PersonalInfoScreen(
          initialData: _profileData,
          onContinue: _handlePersonalInfoComplete,
        );
    }
  }
}

