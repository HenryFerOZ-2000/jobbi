# ⚡ Comandos Rápidos - Sistema de Notificaciones

## 🚀 Deploy Completo (Primero ejecutar esto)

```bash
# 1. Compilar y desplegar Cloud Functions
cd worknow/functions
npm install
npm run build
firebase deploy --only functions
cd ..

# 2. Ejecutar la app
flutter pub get
flutter run
```

---

## 🔧 Cloud Functions

```bash
# Compilar TypeScript
cd worknow/functions
npm run build

# Desplegar a Firebase
firebase deploy --only functions

# Ver logs en tiempo real
firebase functions:log

# Ver logs filtrados
firebase functions:log --only onJobCreated

# Listar funciones deployadas
firebase functions:list

# Eliminar función
firebase functions:delete onJobCreated
```

---

## 📱 Flutter App

```bash
# Instalar dependencias
flutter pub get

# Limpiar build
flutter clean

# Ejecutar en debug
flutter run

# Ejecutar en release (más rápido)
flutter run --release

# Ver logs
flutter logs

# Build APK
flutter build apk --release

# Build AAB (para Play Store)
flutter build appbundle --release
```

---

## 🔍 Debugging

```bash
# Ver todos los dispositivos
flutter devices

# Ejecutar en dispositivo específico
flutter run -d android
flutter run -d chrome

# Ver logs filtrados
flutter logs | grep "FCM"
flutter logs | grep "Notification"

# Limpiar y reinstalar
flutter clean
flutter pub get
flutter run --release
```

---

## 🧪 Testing Rápido

```bash
# 1. Terminal 1: Ver logs de Functions
firebase functions:log

# 2. Terminal 2: Ver logs de Flutter
flutter logs

# 3. En la app: Crear un trabajo y observar los logs
```

---

## 🔥 Firestore

### Ver datos en Firestore Console
```
https://console.firebase.google.com/project/TU_PROJECT_ID/firestore/data
```

### Verificar notificaciones de un usuario
```
Navegar a: users/{uid}/notifications
```

### Verificar token FCM
```
Navegar a: users/{uid}
Campo: notificationToken
```

---

## 📊 Monitoreo

### Firebase Console
```
https://console.firebase.google.com/project/TU_PROJECT_ID/functions
```

### Ver métricas
- Invocations
- Execution time
- Memory usage
- Errors

---

## ⚠️ Troubleshooting Rápido

### No recibo notificaciones
```bash
# 1. Verificar permisos en el dispositivo
# Settings → Apps → WorkNow → Permissions → Notifications

# 2. Verificar token en Firestore
# Firestore → users/{uid} → notificationToken

# 3. Forzar actualización de token
# En la app, ir a HomeScreen y el token se actualiza automáticamente

# 4. Ver logs
firebase functions:log --only onJobCreated
```

### Badge no se actualiza
```bash
# Hot restart (no hot reload)
# En la app, presionar R en la terminal de flutter
# O cerrar y reabrir la app
```

### Cloud Function no se ejecuta
```bash
# Verificar que está desplegada
firebase functions:list

# Ver logs de error
firebase functions:log --only onJobCreated

# Re-desplegar
cd worknow/functions
npm run build
firebase deploy --only functions
```

---

## 🎯 Test Manual Completo (5 minutos)

```bash
# Terminal 1
cd worknow/functions
firebase functions:log

# Terminal 2
cd worknow
flutter run

# En la app:
# 1. Login con usuario A
# 2. Ir a perfil, verificar skills y ciudad
# 3. Logout
# 4. Login con usuario B
# 5. Crear trabajo que coincida con usuario A
# 6. Observar logs en Terminal 1
# 7. Logout
# 8. Login con usuario A
# 9. Verificar badge en campana
# 10. Tocar campana, ver notificación
# 11. Tocar notificación, ir a trabajo
```

---

## 🔄 Reset Completo

```bash
# Si algo sale mal, resetear todo:

# 1. Limpiar Flutter
flutter clean
rm -rf build/

# 2. Reinstalar dependencias
flutter pub get

# 3. Recompilar Functions
cd functions
rm -rf lib/
npm run build
cd ..

# 4. Re-desplegar Functions
cd functions
firebase deploy --only functions
cd ..

# 5. Ejecutar app
flutter run --release
```

---

## 📦 Producción

```bash
# 1. Build release
flutter build apk --release

# 2. Desplegar Functions a producción
firebase use production
firebase deploy --only functions

# 3. Verificar
firebase functions:list --project production
```

---

## 💾 Backup de Firestore

```bash
# Exportar datos
firebase firestore:export gs://your-bucket/backups/$(date +%Y%m%d)

# Importar datos
firebase firestore:import gs://your-bucket/backups/20251128
```

---

## 🎨 UI Testing

```bash
# Si necesitas probar solo la UI sin backend:

# 1. Crear notificación de prueba manualmente en Firestore
# users/{uid}/notifications/{random_id}
# {
#   "title": "Test",
#   "body": "Notificación de prueba",
#   "jobId": "test123",
#   "createdAt": Timestamp.now(),
#   "read": false,
#   "type": "new_job"
# }

# 2. Hot reload
# Presionar r en la terminal de flutter

# 3. Verificar badge y lista
```

---

## 📝 Logs Útiles

### Flutter
```bash
# Ver solo FCM
flutter logs | grep "FCM"

# Ver solo notificaciones
flutter logs | grep "Notification"

# Ver errores
flutter logs | grep "Error"
```

### Firebase Functions
```bash
# Ver solo éxitos
firebase functions:log | grep "✅"

# Ver solo errores
firebase functions:log | grep "❌"

# Ver matching
firebase functions:log | grep "Found"
```

---

## 🔧 Configuración Rápida

### Android
```bash
# Verificar google-services.json
ls -la worknow/android/app/google-services.json

# Si falta, descargar de:
# Firebase Console → Project Settings → Your apps → Download
```

### iOS (si aplica)
```bash
# Verificar GoogleService-Info.plist
ls -la worknow/ios/Runner/GoogleService-Info.plist

# Instalar pods
cd worknow/ios
pod install
cd ..
```

---

## 🎯 Verificación Rápida

### ¿Está todo funcionando?

```bash
# 1. Cloud Functions
firebase functions:list
# Debe mostrar: onJobCreated (ACTIVE)

# 2. App corriendo
flutter devices
# Debe mostrar tu dispositivo

# 3. Firestore
# Ir a Firebase Console y verificar colecciones:
# - users
# - jobs
```

---

## 🚀 Comando Todo-en-Uno

```bash
# Desplegar y ejecutar todo
cd worknow/functions && npm run build && firebase deploy --only functions && cd .. && flutter pub get && flutter run --release
```

---

**Documento creado:** 28 de Noviembre, 2025  
**Versión:** 1.0  
**Para:** WorkNow Notifications System


