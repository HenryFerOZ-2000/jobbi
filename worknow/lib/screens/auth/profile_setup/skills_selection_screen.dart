import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SkillsSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onContinue;
  final VoidCallback onBack;

  const SkillsSelectionScreen({
    super.key,
    required this.initialData,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<SkillsSelectionScreen> createState() => _SkillsSelectionScreenState();
}

class _SkillsSelectionScreenState extends State<SkillsSelectionScreen> {
  List<Map<String, dynamic>> _allSkills = [];
  List<String> _selectedSkills = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final int _maxSkills = 10;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    // Cargar habilidades seleccionadas previamente si existen
    if (widget.initialData['habilidades'] != null) {
      _selectedSkills = List<String>.from(widget.initialData['habilidades']);
    }
  }

  Future<void> _loadSkills() async {
    try {
      final String response = await rootBundle.loadString('assets/skills.json');
      final data = json.decode(response);
      setState(() {
        _allSkills = List<Map<String, dynamic>>.from(data['skills']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar habilidades: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleSkill(String skillName) {
    setState(() {
      if (_selectedSkills.contains(skillName)) {
        _selectedSkills.remove(skillName);
      } else {
        if (_selectedSkills.length < _maxSkills) {
          _selectedSkills.add(skillName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Máximo $_maxSkills habilidades permitidas'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _handleContinue() {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos una habilidad'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final data = {
      ...widget.initialData,
      'habilidades': _selectedSkills,
    };

    widget.onContinue(data);
  }

  List<Map<String, dynamic>> get _filteredSkills {
    if (_searchQuery.isEmpty) {
      return _allSkills;
    }
    return _allSkills.where((skill) {
      final name = skill['name'].toString().toLowerCase();
      final category = skill['category'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  // Agrupar habilidades por categoría
  Map<String, List<Map<String, dynamic>>> get _groupedSkills {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var skill in _filteredSkills) {
      final category = skill['category'] as String;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(skill);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Selecciona tus Habilidades'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Header con progreso
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
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
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Paso 2 de 3',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '¿En qué eres bueno?',
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedSkills.length >= _maxSkills
                                    ? AppColors.warning.withValues(alpha: 0.2)
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedSkills.length}/$_maxSkills',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: _selectedSkills.length >= _maxSkills
                                      ? AppColors.warning
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona hasta $_maxSkills habilidades',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Barra de búsqueda
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar habilidades...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                            ),
                            filled: true,
                            fillColor: AppColors.scaffoldBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Lista de habilidades agrupadas por categoría
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _groupedSkills.length,
                      itemBuilder: (context, index) {
                        final category = _groupedSkills.keys.elementAt(index);
                        final skills = _groupedSkills[category]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre de categoría
                            Padding(
                              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 16 : 0),
                              child: Text(
                                category,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Chips de habilidades
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: skills.map((skill) {
                                final skillName = skill['name'] as String;
                                final isSelected = _selectedSkills.contains(skillName);

                                return GestureDetector(
                                  onTap: () => _toggleSkill(skillName),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        Text(
                                          skillName,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Botón continuar
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: _selectedSkills.isNotEmpty ? _handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(
                          _selectedSkills.isEmpty
                              ? 'Selecciona al menos una habilidad'
                              : 'Continuar',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

