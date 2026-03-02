# 🔄 Reestructuración Completa del Flujo de Creación de Perfil

## Fecha: 28 de Noviembre, 2025

---

## 📋 Resumen Ejecutivo

Se ha reestructurado **completamente** el flujo de creación de perfil manteniendo **100% de compatibilidad** con el sistema existente. El nuevo flujo divide la creación de perfil en **3 pantallas separadas** con un diseño moderno y profesional.

---

## ✨ Cambios Principales

### 1. **Pregunta Reemplazada**

❌ **Antes:** "¿Eres profesional?"
✅ **Después:** "¿Posees título universitario?"

**Razón del cambio:**
- Más específico y claro
- Permite filtrar perfiles académicos
- Opcional (no obliga a tener título)
- Mejor UX para todo tipo de trabajadores

---

## 📱 Nuevo Flujo de 3 Pantallas

### **Screen 1: Datos Personales** 👤

**Campos:**
```dart
✓ Nombre *
✓ Apellido *
✓ Número de Celular *
✓ País * (Dropdown)
✓ Provincia/Estado * (Dropdown encadenado)
✓ Ciudad * (Dropdown encadenado)
✓ ¿Posees título universitario? (Switch opcional)
```

**Características:**
- Indicador de progreso (Paso 1 de 3)
- Dropdowns encadenados (país → provincia → ciudad)
- 9 países con provincias/estados
- Ciudades por provincia
- Switch con diseño moderno
- Validación de todos los campos

**Países Incluidos:**
- 🇦🇷 Argentina
- 🇪🇸 España
- 🇲🇽 México
- 🇨🇴 Colombia
- 🇵🇪 Perú
- 🇨🇱 Chile
- 🇪🇨 Ecuador
- 🇻🇪 Venezuela
- 🇺🇸 Estados Unidos

---

### **Screen 2: Selección de Habilidades** 🎯

**Características:**
```dart
✓ Máximo 10 habilidades seleccionables
✓ +50 habilidades categorizadas
✓ Búsqueda en tiempo real
✓ Chips seleccionables con animación
✓ Contador visual (X/10)
✓ Agrupadas por categoría
```

**Categorías de Habilidades:**
1. **Oficios** 🔨
   - Construcción, Carpintería, Electricidad, Plomería, Soldadura, Pintura, Albañilería, Jardinería, Mecánica, Refrigeración, Costura

2. **Servicios** 🏠
   - Cocina, Repostería, Limpieza, Cuidado de Niños, Cuidado de Adultos Mayores, Atención al Cliente

3. **Tecnología** 💻
   - Desarrollo Web, Desarrollo Móvil, Frontend, Backend, Análisis de Datos, Automatización

4. **Diseño** 🎨
   - UI/UX, Diseño Gráfico, Ilustración, Fotografía, Edición de Video

5. **Marketing** 📢
   - Marketing Digital, Redes Sociales, SEO, Redacción, Copywriting

6. **Idiomas** 🌍
   - Traducción, Inglés, Portugués, Francés

7. **Negocios** 💼
   - Ventas, Administración, Contabilidad, RRHH, Gestión de Proyectos

8. **Ofimática** 📊
   - Excel, Word, PowerPoint

9. **Operaciones** 🚚
   - Logística, Transporte, Almacén

10. **Belleza** 💅
    - Peluquería, Maquillaje, Masajes

11. **Deportes** 🏃
    - Entrenamiento Personal, Yoga

12. **Arte** 🎭
    - Música

13. **Educación** 📚
    - Enseñanza

**Diseño de Chips:**
```dart
No seleccionado:
- Fondo blanco
- Borde gris claro
- Texto negro

Seleccionado:
- Fondo turquesa (primary)
- Borde turquesa
- Texto blanco
- Icono de check
- Sombra con glow
```

---

### **Screen 3: Perfil Profesional** 🎓

**Condición:** Solo aparece si `poseeTituloUniversitario = true`

**Campos:**
```dart
✓ Título Universitario * (texto)
✓ Universidad * (texto)
✓ Año de Graduación * (dropdown con últimos 70 años)
```

**Características:**
- Icono decorativo de universidad
- Mensaje informativo
- Validación de todos los campos
- Botón "Finalizar y Guardar"

**Flujo:**
```
Si tiene título  → Muestra Screen 3 → Guarda con perfilProfesional
Si NO tiene título → Salta Screen 3 → Guarda con perfilProfesional = null
```

---

## 🗂️ Estructura de Archivos Creados

```
lib/
├── screens/
│   └── auth/
│       └── profile_setup/
│           ├── profile_setup_flow.dart        (Orquestador principal)
│           ├── personal_info_screen.dart      (Screen 1)
│           ├── skills_selection_screen.dart   (Screen 2)
│           └── professional_profile_screen.dart (Screen 3)
│
└── assets/
    └── skills.json                            (Datos de habilidades)
```

---

## 💾 Estructura de Datos en Firestore

### Campos Nuevos Agregados:

```javascript
{
  // ===== CAMPOS NUEVOS =====
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+54 9 11 1234 5678",
  "pais": "Argentina",
  "provincia": "Buenos Aires",
  "ciudad": "La Plata",
  "habilidades": ["Desarrollo Web", "Diseño UI/UX", "Marketing Digital"],
  "poseeTituloUniversitario": true,
  "perfilProfesional": {
    "titulo": "Ingeniero en Sistemas",
    "universidad": "Universidad Nacional de La Plata",
    "anioGraduacion": 2020
  },
  
  // ===== CAMPOS ANTIGUOS (MANTENIDOS) =====
  "uid": "...",
  "name": "Juan",              // Compatible con nuevo 'nombre'
  "email": "...",
  "profession": "",            // Mantener para compatibilidad
  "bio": "",
  "skills": [],                // Mantener, actualizado desde 'habilidades'
  "city": "",                  // Mantener, actualizado desde 'ciudad'
  "country": "",               // Mantener, actualizado desde 'pais'
  "photoUrl": "",
  "status": "Disponible",
  "rating": 0.0,
  "profileCompleted": true,
  "isProfessional": false,     // Mantener para lógica existente
  "hourlyRate": 0.0,
  "experience": "",
  "isAvailable": false,
  "completedJobs": 0,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Compatibilidad

**IMPORTANTE:** 
- ✅ Todos los campos antiguos se mantienen
- ✅ Queries existentes seguirán funcionando
- ✅ Sistema de postulaciones no se ve afectado
- ✅ Sistema de chats sigue funcionando
- ✅ Búsquedas y filtros mantienen compatibilidad

---

## 🎨 Diseño del Flujo

### Indicador de Progreso

Todas las pantallas incluyen un indicador visual:

```
Screen 1: ████ ░░░░ ░░░░  (1 de 3)
Screen 2: ████ ████ ░░░░  (2 de 3)
Screen 3: ████ ████ ████  (3 de 3)
```

### Navegación

```dart
Register → ProfileSetupFlow
             ↓
         Screen 1 (Personal Info)
             ↓
         Screen 2 (Skills)
             ↓
    ¿Tiene título? ──→ SÍ  → Screen 3 (Professional)
         ↓                        ↓
         NO                    Guardar
         ↓                        ↓
      Guardar ←──────────────────┘
         ↓
      Home Screen
```

### Botones de Navegación

```dart
Screen 1:
- Continuar → Va a Screen 2

Screen 2:
- ← Atrás → Vuelve a Screen 1
- Continuar → Va a Screen 3 (si tiene título) o Guarda (si no)

Screen 3:
- ← Atrás → Vuelve a Screen 2
- Finalizar y Guardar → Guarda y va a Home
```

---

## 🔄 Compatibilidad con Sistema Existente

### ✅ Funcionalidades que Siguen Funcionando

1. **Sistema de Autenticación**
   - ✅ Login con email/password
   - ✅ Login con Google
   - ✅ Registro normal
   - ✅ Reset de contraseña

2. **Sistema de Trabajos**
   - ✅ Crear trabajos
   - ✅ Ver trabajos
   - ✅ Postularse a trabajos
   - ✅ Filtros y búsqueda
   - ✅ Detalles de trabajo

3. **Sistema de Postulaciones**
   - ✅ Postularse
   - ✅ Ver postulantes
   - ✅ Seleccionar candidato
   - ✅ Estado de postulaciones

4. **Sistema de Chats**
   - ✅ Crear conversaciones
   - ✅ Enviar mensajes
   - ✅ Recibir notificaciones
   - ✅ Lista de chats

5. **Perfiles**
   - ✅ Ver perfil propio
   - ✅ Ver perfiles de otros
   - ✅ Editar perfil (usar EditUserProfileScreen antigua)
   - ✅ Foto de perfil

### ⚠️ Notas de Compatibilidad

**Campos Duplicados (intencional):**
- `name` (antiguo) ↔ `nombre` + `apellido` (nuevo)
- `city` (antiguo) ↔ `ciudad` (nuevo)
- `country` (antiguo) ↔ `pais` (nuevo)
- `skills` (antiguo) ↔ `habilidades` (nuevo)

**Razón:**
- Mantiene compatibilidad con código existente
- Evita romper queries y filtros actuales
- Permite migración gradual
- Los nuevos campos se pueden usar para features futuras

---

## 📝 Archivos Modificados

### Nuevos Archivos Creados ✨

1. ✅ `lib/screens/auth/profile_setup/profile_setup_flow.dart`
2. ✅ `lib/screens/auth/profile_setup/personal_info_screen.dart`
3. ✅ `lib/screens/auth/profile_setup/skills_selection_screen.dart`
4. ✅ `lib/screens/auth/profile_setup/professional_profile_screen.dart`
5. ✅ `assets/skills.json`

### Archivos Actualizados 🔄

1. ✅ `lib/screens/auth/register_screen.dart` - Usa ProfileSetupFlow
2. ✅ `lib/screens/home/home_screen.dart` - Usa ProfileSetupFlow
3. ✅ `lib/services/auth_service.dart` - Nuevos campos en registro
4. ✅ `lib/app/router.dart` - Nueva ruta agregada
5. ✅ `pubspec.yaml` - Assets configurados

### Archivos NO Modificados (mantienen funcionalidad) ✅

- ✅ `lib/screens/auth/complete_profile_screen.dart` - Puede seguir usándose
- ✅ `lib/screens/jobs/` - Toda la lógica de trabajos intacta
- ✅ `lib/screens/chat/` - Sistema de chat completo
- ✅ `lib/services/user_service.dart` - Sin cambios
- ✅ `lib/services/chat_service.dart` - Sin cambios
- ✅ `lib/widgets/` - Todos los widgets funcionando

---

## 🎨 Características del Diseño

### PersonalInfoScreen

```dart
Elementos:
✓ Progreso visual (1/3)
✓ Título grande: "Cuéntanos sobre ti"
✓ Subtítulo descriptivo
✓ Campos con iconos
✓ Dropdowns encadenados
✓ Switch de título universitario con diseño card
✓ Botón grande de continuar
```

### SkillsSelectionScreen

```dart
Elementos:
✓ Progreso visual (2/3)
✓ Contador de habilidades seleccionadas (X/10)
✓ Barra de búsqueda integrada
✓ Habilidades agrupadas por categoría
✓ Chips interactivos con animación
✓ Botón flotante en la parte inferior
✓ Header sticky con info importante
```

### ProfessionalProfileScreen

```dart
Elementos:
✓ Progreso visual (3/3)
✓ Icono decorativo grande
✓ 3 campos simples
✓ Dropdown de años (últimos 70)
✓ Card informativo
✓ Botón "Finalizar y Guardar"
```

---

## 🔧 Implementación Técnica

### ProfileSetupFlow (Orquestador)

**Responsabilidades:**
1. Mantener estado global del flujo
2. Gestionar navegación entre screens
3. Acumular datos de todas las pantallas
4. Decidir si mostrar Screen 3 o no
5. Guardar datos en Firestore
6. Navegar al home al completar

**Lógica de Navegación:**
```dart
Step 0 → PersonalInfoScreen
  ↓ onContinue
Step 1 → SkillsSelectionScreen
  ↓ onContinue
  ├─→ Si tiene título: Step 2 → ProfessionalProfileScreen
  └─→ Si NO tiene título: _saveProfile()
       ↓ onComplete (si llegó a Step 2)
    _saveProfile()
       ↓
  Navigator → /home
```

### Gestión de Estado

```dart
class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  int _currentStep = 0;
  Map<String, dynamic> _profileData = {};
  bool _isSaving = false;
  
  // Acumula datos de cada screen
  _profileData = {..._profileData, ...newData};
}
```

### Guardado en Firestore

```dart
// Solo actualiza, no sobrescribe
await FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)
  .update({
    // Nuevos campos
    'nombre': ...,
    'apellido': ...,
    ...
    // Mantiene campos antiguos intactos
  });
```

---

## 📊 Dropdowns Encadenados

### Estructura de Datos

```dart
Map<String, List<String>> _provincias = {
  'Argentina': ['Buenos Aires', 'Córdoba', ...],
  'España': ['Madrid', 'Barcelona', ...],
  ...
};

Map<String, Map<String, List<String>>> _ciudades = {
  'Argentina': {
    'Buenos Aires': ['La Plata', 'Mar del Plata', ...],
    'Córdoba': ['Córdoba Capital', 'Villa María', ...],
  },
  ...
};
```

### Lógica de Cascada

```dart
// Al seleccionar país
onChanged: (pais) {
  setState(() {
    _selectedPais = pais;
    _selectedProvincia = null;  // Reset
    _selectedCiudad = null;     // Reset
  });
}

// Al seleccionar provincia
onChanged: (provincia) {
  setState(() {
    _selectedProvincia = provincia;
    _selectedCiudad = null;     // Reset
  });
}
```

---

## 🎯 Skills Selection System

### Carga de Habilidades

```dart
Future<void> _loadSkills() async {
  final String response = await rootBundle.loadString('assets/skills.json');
  final data = json.decode(response);
  setState(() {
    _allSkills = List<Map<String, dynamic>>.from(data['skills']);
  });
}
```

### Toggle de Selección

```dart
void _toggleSkill(String skillName) {
  if (_selectedSkills.contains(skillName)) {
    _selectedSkills.remove(skillName);
  } else if (_selectedSkills.length < _maxSkills) {
    _selectedSkills.add(skillName);
  } else {
    // Mostrar mensaje de límite alcanzado
  }
}
```

### Búsqueda

```dart
List<Map<String, dynamic>> get _filteredSkills {
  return _allSkills.where((skill) {
    final name = skill['name'].toLowerCase();
    final category = skill['category'].toLowerCase();
    return name.contains(_searchQuery) || category.contains(_searchQuery);
  }).toList();
}
```

### Agrupación

```dart
Map<String, List<Map<String, dynamic>>> get _groupedSkills {
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (var skill in _filteredSkills) {
    final category = skill['category'];
    grouped[category] = grouped[category] ?? [];
    grouped[category]!.add(skill);
  }
  return grouped;
}
```

---

## 🔄 Flujo de Integración

### Registro de Usuario

```
1. Usuario llena RegisterScreen
   ↓
2. AuthService.register() crea cuenta + documento base en Firestore
   ↓
3. Navigator → ProfileSetupFlow
   ↓
4. Usuario completa 3 screens (o 2 si no tiene título)
   ↓
5. ProfileSetupFlow guarda datos con .update()
   ↓
6. Navigator → HomeScreen
```

### Check de Perfil Completo

```dart
// En HomeScreen.initState()
_checkProfileCompletion() {
  final profileCompleted = userDoc.data()?['profileCompleted'] ?? false;
  
  if (!profileCompleted) {
    Navigator → ProfileSetupFlow
  }
}
```

---

## ⚡ Validaciones Implementadas

### Screen 1 (Personal Info)
```dart
✓ Nombre: No vacío
✓ Apellido: No vacío
✓ Teléfono: No vacío
✓ País: Debe seleccionar
✓ Provincia: Debe seleccionar
✓ Ciudad: Debe seleccionar
✓ Título universitario: Opcional (no valida)
```

### Screen 2 (Skills)
```dart
✓ Mínimo: 1 habilidad
✓ Máximo: 10 habilidades
✓ Aviso visual al llegar al límite
```

### Screen 3 (Professional)
```dart
✓ Título universitario: No vacío
✓ Universidad: No vacío
✓ Año graduación: Debe seleccionar
```

---

## 🎉 Beneficios del Nuevo Flujo

### Para el Usuario

1. **Más Organizado** 📋
   - Información dividida en pasos lógicos
   - No abruma con muchos campos a la vez
   - Progreso visual claro

2. **Más Flexible** 🔄
   - Puede volver atrás si se equivoca
   - Salta screens no necesarios automáticamente
   - Título universitario opcional

3. **Más Inclusivo** 🌎
   - Diseñado para TODO tipo de trabajador
   - No solo profesionales con título
   - Habilidades desde oficios hasta tech

4. **Mejor UX** ✨
   - Diseño moderno y limpio
   - Chips visuales para habilidades
   - Feedback inmediato en selecciones

### Para el Desarrollo

1. **Modular** 🧩
   - Cada screen es independiente
   - Fácil de mantener y extender
   - Fácil de testear

2. **Escalable** 📈
   - Fácil agregar más steps
   - Fácil agregar más habilidades
   - Fácil agregar más países

3. **Compatible** ✅
   - No rompe nada existente
   - Migración gradual posible
   - Rollback sencillo si es necesario

---

## 🚀 Próximas Mejoras Sugeridas

### Fase 1: Datos
```dart
[ ] Conectar a API de países/ciudades real
[ ] Agregar más habilidades (100+)
[ ] Permitir agregar habilidades personalizadas
[ ] Multiidioma (inglés/español)
```

### Fase 2: UX
```dart
[ ] Animaciones entre screens (Hero transitions)
[ ] Sugerencias de habilidades según categoría laboral
[ ] Preview de perfil antes de guardar
[ ] Opción de "Saltar por ahora"
```

### Fase 3: Features
```dart
[ ] Importar datos desde LinkedIn
[ ] Verificación de títulos universitarios
[ ] Certificaciones adicionales
[ ] Portfolio/galería de trabajos
```

---

## 📖 Guía de Uso

### Para Desarrolladores

**Agregar una nueva habilidad:**
1. Editar `assets/skills.json`
2. Agregar objeto con id, name, category
3. Hot reload

**Agregar un nuevo país:**
1. Editar `personal_info_screen.dart`
2. Agregar país a `_provincias`
3. Agregar provincias/ciudades a `_ciudades`
4. Compilar

**Agregar un nuevo step:**
1. Crear nuevo screen en `profile_setup/`
2. Agregar case en `profile_setup_flow.dart`
3. Actualizar indicador de progreso
4. Implementar onContinue/onBack

### Para QA/Testing

**Escenarios a probar:**

1. ✅ Usuario SIN título universitario
   - Completa Screen 1 y 2
   - NO ve Screen 3
   - Se guarda correctamente
   - Puede usar la app normalmente

2. ✅ Usuario CON título universitario
   - Completa los 3 screens
   - Ve Screen 3
   - Datos profesionales se guardan
   - Puede usar la app normalmente

3. ✅ Navegación hacia atrás
   - Puede volver en Screen 2 y 3
   - Datos se mantienen
   - No pierde información

4. ✅ Validaciones
   - No puede continuar sin llenar campos obligatorios
   - Límite de 10 habilidades funciona
   - Dropdowns encadenados funcionan correctamente

5. ✅ Compatibilidad
   - Usuarios antiguos pueden seguir usando la app
   - Postulaciones funcionan
   - Chats funcionan
   - Búsquedas funcionan

---

## ✅ Checklist de Implementación

### Creación de Archivos
- [x] skills.json creado con 55 habilidades
- [x] PersonalInfoScreen creado
- [x] SkillsSelectionScreen creado
- [x] ProfessionalProfileScreen creado
- [x] ProfileSetupFlow creado

### Integración
- [x] RegisterScreen actualizado
- [x] HomeScreen actualizado
- [x] AuthService actualizado con nuevos campos
- [x] Router actualizado con nueva ruta
- [x] pubspec.yaml actualizado con assets

### Testing
- [x] Sin errores de linter
- [x] Imports limpios
- [x] Validaciones implementadas
- [x] Navegación funcionando
- [x] Compatibilidad verificada

### Documentación
- [x] Documento completo creado
- [x] Código comentado
- [x] Estructura clara
- [x] Ejemplos incluidos

---

## 🎊 Conclusión

Se ha completado exitosamente la **reestructuración completa del flujo de creación de perfil**. El nuevo sistema es:

✨ **Más Organizado** - 3 screens claramente definidos
🎯 **Más Flexible** - Adaptable a diferentes tipos de usuarios
🌍 **Más Inclusivo** - Para todo tipo de trabajadores
💎 **Más Profesional** - Diseño moderno y pulido
✅ **100% Compatible** - No rompe nada existente

El flujo está **listo para producción** y puede ser usado inmediatamente.

---

**Desarrollado por el equipo de WorkNow**
*Noviembre 2025*

