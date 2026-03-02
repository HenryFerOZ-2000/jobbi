# 🔄 ARCHIVOS A RESTAURAR - WorkNow

## ❌ ARCHIVOS ELIMINADOS

### Sistema Core
- [x] lib/firebase_options.dart - ✅ RESTAURADO
- [ ] lib/app/app.dart
- [ ] lib/app/router.dart
- [ ] lib/app/auth_gate.dart

### Theme (Viejo - reemplazar con nuevo)
- [ ] lib/theme/colors.dart → USAR app_colors.dart (ya existe)
- [ ] lib/theme/theme.dart → USAR app_theme.dart (ya existe)

### Models
- [ ] lib/models/job.dart
- [ ] lib/models/chat.dart (ya existe)
- [ ] lib/models/message.dart (ya existe)

### Widgets
- [ ] lib/widgets/job_card.dart
- [ ] lib/widgets/primary_button.dart
- [ ] lib/widgets/input_field.dart

### Screens - Auth
- [ ] lib/screens/auth/login_screen.dart
- [ ] lib/screens/auth/register_screen.dart
- [ ] lib/screens/auth/edit_profile_screen.dart
- [ ] lib/screens/auth/complete_profile_screen.dart

### Screens - Home
- [ ] lib/screens/home/home_screen.dart
- [ ] lib/screens/home/tabs/jobs_tab.dart
- [ ] lib/screens/home/tabs/messages_tab.dart
- [ ] lib/screens/home/tabs/profile_tab.dart

### Screens - Jobs
- [ ] lib/screens/jobs/new_job_screen.dart
- [ ] lib/screens/jobs/job_detail_screen.dart
- [ ] lib/screens/jobs/create_job_screen.dart (ya existe)
- [ ] lib/screens/jobs/job_details_screen.dart (ya existe)
- [ ] lib/screens/jobs/my_jobs_screen.dart (ya existe)
- [ ] lib/screens/jobs/applicants_list_screen.dart (ya existe)
- [ ] lib/screens/jobs/jobs_feed_screen.dart (ya existe)

### Services (verificar cuáles existen)
- [ ] lib/services/auth_service.dart (verificar)
- [ ] lib/services/user_service.dart (verificar)
- [ ] lib/services/chat_service.dart (verificar)
- [ ] lib/services/fcm_service.dart (verificar)

## ✅ ARCHIVOS QUE AÚN EXISTEN

- lib/main.dart
- lib/theme/app_colors.dart (nuevo)
- lib/theme/app_text_styles.dart (nuevo)
- lib/theme/app_theme.dart (nuevo)
- lib/models/chat.dart
- lib/models/message.dart
- lib/screens/jobs/create_job_screen.dart
- lib/screens/jobs/job_details_screen.dart
- lib/screens/jobs/my_jobs_screen.dart
- lib/screens/jobs/tabs/my_published_jobs_tab.dart
- lib/screens/jobs/tabs/my_applied_jobs_tab.dart
- lib/screens/jobs/tabs/my_hired_jobs_tab.dart
- lib/screens/jobs/applicants_list_screen.dart
- lib/screens/chat/chat_screen.dart
- lib/screens/chat/chats_list_screen.dart
- lib/screens/profile/profile_screen.dart
- lib/screens/profile/edit_profile_screen.dart
- lib/services/auth_service.dart
- lib/services/chat_service.dart
- lib/services/user_service.dart
- lib/services/fcm_service.dart

## 🎯 PLAN DE RESTAURACIÓN

### Fase 1: CRÍTICO (para que compile)
1. ✅ firebase_options.dart
2. ⏳ lib/app/app.dart
3. ⏳ lib/app/router.dart
4. ⏳ lib/app/auth_gate.dart
5. ⏳ lib/models/job.dart
6. ⏳ lib/screens/auth/login_screen.dart
7. ⏳ lib/screens/auth/register_screen.dart
8. ⏳ lib/screens/home/home_screen.dart

### Fase 2: BÁSICO (funcionalidad core)
9. ⏳ lib/screens/home/tabs/jobs_tab.dart
10. ⏳ lib/screens/home/tabs/messages_tab.dart
11. ⏳ lib/screens/home/tabs/profile_tab.dart
12. ⏳ lib/widgets/input_field.dart
13. ⏳ lib/widgets/primary_button.dart

### Fase 3: SECUNDARIO (features avanzados)
14. ⏳ lib/screens/auth/edit_profile_screen.dart (si no existe)
15. ⏳ lib/screens/auth/complete_profile_screen.dart (si no existe)
16. ⏳ lib/widgets/job_card.dart

## 📝 NOTAS

- Usar el NUEVO sistema de theme (app_colors, app_text_styles, app_theme)
- NO recrear colors.dart y theme.dart viejos
- Verificar que los servicios existen antes de recrearlos
- Priorizar archivos que permitan compilar


