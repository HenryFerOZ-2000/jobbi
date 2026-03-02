import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class PersonalInfoScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onContinue;

  const PersonalInfoScreen({
    super.key,
    required this.initialData,
    required this.onContinue,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  String? _selectedPais;
  String? _selectedProvincia;
  String? _selectedCiudad;
  bool _poseeTituloUniversitario = false;
  bool _isLoadingLocations = true;

  // Datos cargados desde JSON
  Map<String, dynamic> _locationsData = {};
  
  // Mapeo de códigos de país para validación telefónica
  final Map<String, Map<String, dynamic>> _countryPhoneCodes = {
    'Ecuador': {'code': '+593', 'digits': 10, 'example': '0987654321'},
    // Extensible para más países
  };

  @override
  void initState() {
    super.initState();
    _loadLocationsData();
    
    // Cargar datos iniciales si existen
    if (widget.initialData.isNotEmpty) {
      _nombreController.text = widget.initialData['nombre'] ?? '';
      _apellidoController.text = widget.initialData['apellido'] ?? '';
      _telefonoController.text = widget.initialData['telefono'] ?? '';
      _selectedPais = widget.initialData['pais'];
      _selectedProvincia = widget.initialData['provincia'];
      _selectedCiudad = widget.initialData['ciudad'];
      _poseeTituloUniversitario = widget.initialData['poseeTituloUniversitario'] ?? false;
    }
  }

  Future<void> _loadLocationsData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/locations.json');
      final data = json.decode(jsonString);
      setState(() {
        _locationsData = data as Map<String, dynamic>;
        _isLoadingLocations = false;
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  List<String> get _availableCountries {
    return _locationsData.keys.toList()..sort();
  }

  List<String> get _availableProvinces {
    if (_selectedPais == null || !_locationsData.containsKey(_selectedPais)) {
      return [];
    }
    final provinces = _locationsData[_selectedPais] as Map<String, dynamic>;
    return provinces.keys.toList()..sort();
  }

  List<String> get _availableCities {
    if (_selectedPais == null || _selectedProvincia == null) {
      return [];
    }
    final provinces = _locationsData[_selectedPais] as Map<String, dynamic>?;
    if (provinces == null || !provinces.containsKey(_selectedProvincia)) {
      return [];
    }
    final cities = provinces[_selectedProvincia] as List<dynamic>;
    return cities.map((e) => e.toString()).toList()..sort();
  }

  String? _getPhonePrefix() {
    if (_selectedPais != null && _countryPhoneCodes.containsKey(_selectedPais)) {
      return _countryPhoneCodes[_selectedPais]!['code'];
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    
    if (_selectedPais == 'Ecuador') {
      final phoneConfig = _countryPhoneCodes['Ecuador']!;
      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
      
      if (digitsOnly.length != phoneConfig['digits']) {
        return 'Debe tener ${phoneConfig['digits']} dígitos';
      }
      
      if (!digitsOnly.startsWith('0')) {
        return 'Debe comenzar con 0';
      }
    }
    
    return null;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPais == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu país'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedProvincia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu provincia/estado'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCiudad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu ciudad'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Formatear teléfono con código de país
    String formattedPhone = _telefonoController.text.trim();
    final phonePrefix = _getPhonePrefix();
    if (phonePrefix != null) {
      formattedPhone = '$phonePrefix ${_telefonoController.text.trim()}';
    }

    final data = {
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'telefono': formattedPhone,
      'pais': _selectedPais!,
      'provincia': _selectedProvincia!,
      'ciudad': _selectedCiudad!,
      'poseeTituloUniversitario': _poseeTituloUniversitario,
    };

    widget.onContinue(data);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocations) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Datos Personales'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Datos Personales'),
        backgroundColor: AppColors.primary,
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
                          color: Colors.grey[300],
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

                const SizedBox(height: 24),

                Text(
                  'Paso 1 de 3',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuéntanos sobre ti',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tu información personal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 32),

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),

                const SizedBox(height: 16),

                // Apellido
                TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),

                const SizedBox(height: 16),

                // Teléfono con código de país
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Número de Celular *',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: _getPhonePrefix() != null ? '${_getPhonePrefix()} ' : null,
                    prefixStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    hintText: _selectedPais == 'Ecuador' 
                        ? _countryPhoneCodes['Ecuador']!['example']
                        : 'Ej: 0987654321',
                  ),
                  validator: _validatePhone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      _selectedPais == 'Ecuador' ? 10 : 15,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // País
                DropdownButtonFormField<String>(
                  initialValue: _selectedPais,
                  decoration: const InputDecoration(
                    labelText: 'País *',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  items: _availableCountries.map((pais) {
                    return DropdownMenuItem(value: pais, child: Text(pais));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPais = value;
                      _selectedProvincia = null;
                      _selectedCiudad = null;
                      _telefonoController.clear(); // Limpiar teléfono al cambiar país
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Provincia/Estado
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvincia,
                  decoration: const InputDecoration(
                    labelText: 'Provincia / Estado *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: _availableProvinces.map((provincia) {
                    return DropdownMenuItem(value: provincia, child: Text(provincia));
                  }).toList(),
                  onChanged: _selectedPais != null
                      ? (value) {
                          setState(() {
                            _selectedProvincia = value;
                            _selectedCiudad = null;
                          });
                        }
                      : null,
                ),

                const SizedBox(height: 16),

                // Ciudad
                DropdownButtonFormField<String>(
                  initialValue: _selectedCiudad,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _availableCities.map((ciudad) {
                    return DropdownMenuItem(value: ciudad, child: Text(ciudad));
                  }).toList(),
                  onChanged: _selectedPais != null && _selectedProvincia != null
                      ? (value) {
                          setState(() {
                            _selectedCiudad = value;
                          });
                        }
                      : null,
                ),

                const SizedBox(height: 32),

                // ¿Posee título universitario?
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _poseeTituloUniversitario
                          ? AppColors.primary
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: _poseeTituloUniversitario
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Posees título universitario?',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _poseeTituloUniversitario
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Opcional - Puedes agregarlo después',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _poseeTituloUniversitario,
                        onChanged: (value) {
                          setState(() {
                            _poseeTituloUniversitario = value;
                          });
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Botón Continuar Profesional
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) return 0;
                          return 2;
                        },
                      ),
                    ),
                    child: Text(
                      'Continuar',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
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

