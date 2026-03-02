# 🚀 Instrucciones de Deployment y Testing - Sistema de Notificaciones

## Fecha: 28 de Noviembre, 2025

---

## 📋 Pre-requisitos

✅ Firebase proyecto configurado  
✅ Firebase CLI instalado (`npm install -g firebase-tools`)  
✅ Flutter SDK instalado  
✅ Dispositivo Android/iOS o emulador  
✅ Node.js 18+ instalado  

---

## 🔧 1. Compilar y Desplegar Cloud Functions

### Paso 1: Navegar a la carpeta de funciones
```bash
cd worknow/functions
```

### Paso 2: Instalar dependencias (si es necesario)
```bash
npm install
```

### Paso 3: Compilar TypeScript
```bash
npm run build
```

**Verificar:** Debe crear archivos `.js` en la carpeta `lib/`

### Paso 4: Desplegar a Firebase
```bash
firebase deploy --only functions
```

**Salida esperada:**
```
✔ functions[onJobCreated(us-central1)] Successful create operation.
Function URL: https://...
```

### Paso 5: Verificar deployment
```bash
firebase functions:list
```

Debes ver:
```
onJobCreated (1st gen)
  Status: ACTIVE
  Trigger: firestore.document.onCreate
```

---

## 📱 2. Ejecutar la App Flutter

### Paso 1: Instalar dependencias
```bash
cd ..  # Volver a worknow/
flutter pub get
```

### Paso 2: Verificar dispositivos disponibles
```bash
flutter devices
```

### Paso 3: Ejecutar en dispositivo/emulador
```bash
flutter run
```

**Para Android específicamente:**
```bash
flutter run -d android
```

**Para release mode (más rápido):**
```bash
flutter run --release
```

---

## 🧪 3. Testing del Sistema de Notificaciones

### Test 1: Verificar Token FCM

1. **Abrir app y hacer login**
2. **Ir a Firebase Console → Firestore Database**
3. **Navegar a:** `users/{uid}`
4. **Verificar campo:** `notificationToken` debe existir y tener un valor

**Ejemplo:**
```
notificationToken: "eX1a2b3c4d5e6f7g8h9i0..."
```

Si el token NO existe:
- Verificar permisos de notificación en el dispositivo
- Revisar logs: `flutter logs` o Android Studio logcat

---

### Test 2: Ícono de Campana con Badge

1. **Abrir app**
2. **Navegar a tab "Explorar"** (primera pestaña)
3. **Verificar:** Ícono de campana en la esquina superior derecha
4. **Si hay notificaciones no leídas:** Badge rojo con número

**Estados posibles:**
- 🔔 Sin badge → No hay notificaciones no leídas
- 🔔 `1` → 1 notificación no leída
- 🔔 `9+` → 9 o más notificaciones no leídas

---

### Test 3: Crear Trabajo y Recibir Notificación

#### Setup: Crear dos usuarios
1. **Usuario A (Trabajador):**
   - Email: `trabajador@test.com`
   - Category: `Desarrollo de Software`
   - Skills: `["Flutter", "Dart", "Firebase"]`
   - City: `Quito`
   - Province: `Pichincha`

2. **Usuario B (Empleador):**
   - Email: `empleador@test.com`
   - Cualquier perfil

#### Ejecución del Test:

**Desde Usuario B:**
1. Abrir app
2. Ir a tab "Explorar"
3. Tocar botón flotante "Publicar"
4. Llenar formulario:
   - Título: `Desarrollador Flutter Senior`
   - Categoría: `Desarrollo y Tecnología`
   - Ciudad: `Quito`
   - Provincia: `Pichincha` (opcional pero recomendado)
   - Budget: `1000`
   - Descripción: `Proyecto urgente...`
5. Tocar "Publicar Trabajo"

**Verificar en Firebase Console:**
1. Ir a Functions → Logs
2. Buscar: `New job created`
3. Verificar: `Found X matching users`

**Desde Usuario A:**
1. **Esperar 5-10 segundos**
2. **Debería recibir:**
   - ✅ Notificación push en el dispositivo
   - ✅ Badge en campana (número 1)
3. **Tocar la campana**
4. **Ver notificación:**
   - Título: "Nuevo trabajo en Quito"
   - Descripción: "Hay un nuevo empleo de Desarrollo y Tecnología..."
   - Fondo azul claro (no leída)
5. **Tocar la notificación**
6. **Navegar automáticamente** al detalle del trabajo

---

### Test 4: Pantalla de Notificaciones

**Con Usuario A (que recibió notificación):**

1. **Tocar ícono de campana**
2. **Verificar:**
   - Lista de notificaciones ordenadas por fecha
   - Notificación no leída con fondo azul
   - Notificaciones leídas con fondo blanco
   - Tiempo relativo: "Hace 5h", "Hace 2d", etc.

3. **Tocar notificación:**
   - Marca como leída automáticamente
   - Navega al detalle del trabajo
   - Badge disminuye en 1

4. **Volver a notificaciones:**
   - Notificación ahora tiene fondo blanco (leída)
   - Ya no contribuye al badge

5. **Deslizar notificación a la izquierda:**
   - Aparece fondo rojo
   - Se elimina al soltar

6. **Tocar "Marcar todas":**
   - Todas las notificaciones se marcan como leídas
   - Badge desaparece

---

### Test 5: Notificaciones en Background

1. **Usuario A tiene la app cerrada**
2. **Usuario B crea otro trabajo que coincida**
3. **Usuario A recibe notificación push**
4. **Tocar la notificación:**
   - App se abre
   - Navega automáticamente al detalle del trabajo

---

### Test 6: Matching por Ubicación

**Setup:**
- Usuario C: City "Guayaquil", Province "Guayas"
- Usuario D crea trabajo: City "Guayaquil"

**Resultado esperado:**
- Usuario C recibe notificación (coincide por city)
- Usuario A NO recibe notificación (diferente city)

---

### Test 7: Matching por Intereses

**Setup:**
- Usuario E: Skills ["Diseño Gráfico", "Photoshop"]
- Usuario F crea trabajo: Category "Diseño y Creatividad"

**Resultado esperado:**
- Usuario E recibe notificación (skills relacionados)
- Usuario A NO recibe notificación (diferente área)

---

## 🔍 4. Debugging

### Ver Logs de Flutter
```bash
flutter logs
```

Buscar:
- `✅ FCM Token saved`
- `📩 Foreground message received`
- `🔔 Background message received`
- `📬 Message opened app`

### Ver Logs de Cloud Functions
```bash
firebase functions:log
```

Buscar:
- `📢 New job created: {jobId}`
- `✅ Found X matching users`
- `✅ Notification sent to user`
- `❌ Error sending notification` (si hay problemas)

### Ver Logs en Firebase Console
1. Ir a Firebase Console
2. Functions → Logs
3. Filtrar por: `onJobCreated`

### Verificar Firestore

**Notificaciones creadas:**
```
users/{uid}/notifications/{notifId}
```

Debe tener:
```json
{
  "title": "...",
  "body": "...",
  "jobId": "...",
  "createdAt": Timestamp,
  "read": false,
  "type": "new_job"
}
```

**Token FCM guardado:**
```
users/{uid}
  └─ notificationToken: "..."
```

---

## ⚠️ Troubleshooting

### Problema: No recibo notificaciones push

**Posibles causas:**
1. **Permisos no otorgados**
   - Ir a Settings → Apps → WorkNow → Permissions → Notifications → Allow

2. **Token no guardado**
   - Verificar en Firestore que existe `notificationToken`
   - Si no existe, forzar update:
     ```dart
     await FCMService.instance.updateFcmToken();
     ```

3. **Cloud Function no desplegada**
   - Verificar: `firebase functions:list`
   - Re-desplegar: `firebase deploy --only functions`

4. **Matching no funciona**
   - Verificar datos del usuario en Firestore
   - Verificar que skills/category coincidan
   - Verificar que city/province coincidan

5. **Token inválido**
   - Eliminar app y reinstalar
   - Limpiar datos: `flutter clean && flutter pub get`

---

### Problema: Badge no se actualiza

**Solución:**
1. Verificar que `NotificationService.getUnreadCountStream()` esté funcionando
2. Hot restart la app (no hot reload)
3. Verificar que `read: false` esté en Firestore

---

### Problema: Cloud Function falla

**Ver logs:**
```bash
firebase functions:log --only onJobCreated
```

**Errores comunes:**
- `messaging/invalid-registration-token` → Token FCM inválido (se elimina auto)
- `Permission denied` → Reglas de Firestore incorrectas
- `Timeout` → Function tarda más de 60s (optimizar query)

---

## 📊 5. Monitoreo en Producción

### Metrics en Firebase Console

1. **Ir a:** Functions → Dashboard
2. **Monitorear:**
   - Invocations (ejecuciones)
   - Execution time (tiempo)
   - Memory usage (memoria)
   - Errors (errores)

### Alertas recomendadas

1. **Error rate > 5%**
2. **Execution time > 10s**
3. **Memory usage > 256MB**

---

## 🎯 6. Validación Final

### Checklist de Funcionalidad

- [ ] Token FCM se guarda al hacer login
- [ ] Ícono de campana aparece en "Explorar"
- [ ] Badge muestra contador correcto
- [ ] Al crear trabajo, Cloud Function se ejecuta
- [ ] Usuarios coincidentes reciben notificación en Firestore
- [ ] Usuarios coincidentes reciben notificación push
- [ ] Al tocar campana, navega a NotificationsScreen
- [ ] Lista de notificaciones se muestra correctamente
- [ ] Al tocar notificación, marca como leída
- [ ] Al tocar notificación, navega al trabajo
- [ ] Swipe to delete funciona
- [ ] "Marcar todas" funciona
- [ ] Badge se actualiza en tiempo real
- [ ] Notificaciones background funcionan
- [ ] Matching por ubicación funciona
- [ ] Matching por intereses funciona
- [ ] Owner del trabajo NO recibe notificación

### Performance

- [ ] App inicia en < 3 segundos
- [ ] Cloud Function ejecuta en < 5 segundos
- [ ] Badge se actualiza instantáneamente
- [ ] Push notifications llegan en < 10 segundos

---

## 🚀 7. Deployment a Producción

### Paso 1: Build Release de Flutter
```bash
flutter build apk --release
```

o para iOS:
```bash
flutter build ios --release
```

### Paso 2: Desplegar Cloud Functions a Producción
```bash
firebase use production  # Cambiar a proyecto production
firebase deploy --only functions
```

### Paso 3: Verificar en Producción
```bash
firebase functions:log --project production
```

---

## 📝 Notas Importantes

1. **Tokens FCM expiran:** El sistema ya maneja renovación automática
2. **Límites de FCM:** 500 mensajes/dispositivo/día (gratis)
3. **Firestore reads:** Cada notificación = 1 read (optimizar si hay muchos usuarios)
4. **Cloud Function cold start:** Primera ejecución puede tardar 5-10s
5. **Permisos Android:** Desde Android 13+, permisos más estrictos

---

## ✅ Testing Completado

Si todos los tests pasan, el sistema está listo para producción! 🎉

**Siguiente paso:** Agregar analytics para monitorear engagement de notificaciones.

---

**Documento creado:** 28 de Noviembre, 2025  
**Versión:** 1.0  
**Sistema:** WorkNow Notifications


