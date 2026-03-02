# 🔐 Sistema de Verificación de Identidad - WorkNow

## 📋 Índice
- [Firebase Rules - Configuración](#firebase-rules---configuración)
- [Configurar Administradores](#configurar-administradores)
- [Desplegar las Reglas](#desplegar-las-reglas)
- [Flujo de Verificación](#flujo-de-verificación)
- [Seguridad y Privacidad](#seguridad-y-privacidad)

---

## 🔥 Firebase Rules - Configuración

### 1. Firebase Storage Rules

Las reglas de **Storage** protegen las fotos de cédula y selfie.

**Archivo:** `firebase_storage.rules`

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Carpeta de verificación de usuarios
    match /user_verification/{userId}/{fileName} {

      // Solo el propietario puede ver/subir sus fotos
      allow read, write: if request.auth != null
                        && request.auth.uid == userId;

      // Los administradores pueden ver todas las fotos
      allow read: if request.auth != null
                && request.auth.token.isAdmin == true;
    }

    // Bloquear cualquier acceso por defecto
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 2. Firebase Firestore Rules

Las reglas de **Firestore** protegen los datos sensibles de los usuarios.

**Archivo:** `firebase_firestore.rules`

Ver el archivo completo en el repositorio.

---

## 👤 Configurar Administradores

Para que un usuario pueda revisar verificaciones, debe tener el claim `isAdmin`.

### Opción 1: Usar Firebase Admin SDK (Node.js)

```javascript
const admin = require('firebase-admin');

// Inicializar Firebase Admin
admin.initializeApp();

// Función para marcar usuario como admin
async function setAdminClaim(uid) {
  try {
    await admin.auth().setCustomUserClaims(uid, { isAdmin: true });
    console.log(`✅ Usuario ${uid} es ahora administrador`);
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Usar con el UID del usuario
setAdminClaim('UID_DEL_USUARIO_AQUI');
```

### Opción 2: Usar Firebase CLI

```bash
# Instalar Firebase Functions (si no lo has hecho)
npm install -g firebase-tools
firebase login

# Crear una función temporal para setear admin
cd functions
```

Crear archivo `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.makeAdmin = functions.https.onCall(async (data, context) => {
  // Solo permitir desde tu cuenta de admin inicial
  if (context.auth.uid !== 'TU_UID_INICIAL') {
    throw new functions.https.HttpsError('permission-denied', 'No autorizado');
  }

  const { uid } = data;
  
  await admin.auth().setCustomUserClaims(uid, { isAdmin: true });
  
  return { success: true, message: `Usuario ${uid} es admin` };
});
```

### Opción 3: Script directo (más rápido)

Crear archivo `scripts/set_admin.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const UID = 'PONER_UID_AQUI'; // ⬅️ Cambiar por tu UID

admin.auth().setCustomUserClaims(UID, { isAdmin: true })
  .then(() => {
    console.log('✅ Admin claim set successfully!');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
```

Ejecutar:
```bash
node scripts/set_admin.js
```

---

## 🚀 Desplegar las Reglas

### Opción 1: Desde Firebase Console (Web)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **WorkNow**
3. **Storage:**
   - Ve a **Storage** → **Rules**
   - Copia el contenido de `firebase_storage.rules`
   - Pega y presiona **Publish**
4. **Firestore:**
   - Ve a **Firestore Database** → **Rules**
   - Copia el contenido de `firebase_firestore.rules`
   - Pega y presiona **Publish**

### Opción 2: Usando Firebase CLI

```bash
# Desplegar Storage Rules
firebase deploy --only storage

# Desplegar Firestore Rules
firebase deploy --only firestore:rules

# Desplegar ambas a la vez
firebase deploy --only storage,firestore:rules
```

---

## 📱 Flujo de Verificación

### Para el Usuario (Worker/Employer)

1. **Solicitar Verificación:**
   - Ir a Perfil → Banner naranja "Verifica tu Identidad"
   - Subir foto de cédula (frente)
   - Subir selfie
   - Aceptar términos y política de privacidad
   - Enviar

2. **Estados posibles:**
   - `unverified`: No ha enviado verificación
   - `pending`: Verificación enviada, esperando revisión
   - `verified`: ✅ Verificado
   - `rejected`: ❌ Rechazado (con motivo)

3. **Beneficios de estar verificado:**
   - Puede publicar trabajos
   - Puede postular a empleos
   - Badge de verificado visible en perfil
   - Mayor confianza de otros usuarios

### Para el Administrador

1. **Acceder a verificaciones:**
   - Crear una ruta/pantalla especial para admins
   - Mostrar `AdminVerificationReviewScreen`

2. **Revisar solicitudes:**
   - Ver lista de pendientes
   - Ampliar foto de cédula y selfie
   - Aprobar ✅ o Rechazar ❌

3. **Aprobar:**
   - Cambia status a `verified`
   - Envía notificación al usuario
   - Usuario recibe badge

4. **Rechazar:**
   - Especificar motivo (obligatorio)
   - Cambia status a `rejected`
   - Usuario puede reenviar

---

## 🛡️ Seguridad y Privacidad

### ¿Dónde se almacenan las fotos?

**Ruta en Storage:**
```
user_verification/
  ├── {userId}/
      ├── id_card.jpg
      └── selfie.jpg
```

### ¿Quién puede ver las fotos?

1. **El propio usuario:** Siempre puede ver sus propias fotos
2. **Administradores:** Solo aquellos con `isAdmin: true`
3. **Nadie más:** Las reglas bloquean cualquier otro acceso

### Datos en Firestore

Cada usuario tiene estos campos en `/users/{uid}`:

```javascript
{
  verificationStatus: 'unverified' | 'pending' | 'verified' | 'rejected',
  idCardUrl: 'https://...',  // Solo visible para admin
  selfieUrl: 'https://...',   // Solo visible para admin
  verificationSubmittedAt: Timestamp,
  verificationUpdatedAt: Timestamp,
  verificationRejectionReason: 'Motivo...' // Si fue rechazado
}
```

### Política de Privacidad

El texto completo está en:
- **Pantalla:** `PrivacyPolicyScreen` (lib/screens/verification/privacy_policy_screen.dart)
- **HTML:** `assets/privacy_policy.html` (para web/email)

**Cumple con:**
- ✅ Ley Orgánica de Protección de Datos Personales del Ecuador
- ✅ Derechos de Habeas Data
- ✅ Consentimiento explícito del usuario

---

## ✅ Checklist de Implementación

- [ ] Desplegar Firebase Storage Rules
- [ ] Desplegar Firebase Firestore Rules
- [ ] Configurar al menos un usuario como administrador
- [ ] Probar flujo completo:
  - [ ] Usuario no verificado intenta publicar trabajo → bloqueado
  - [ ] Usuario envía verificación → status `pending`
  - [ ] Admin revisa → aprueba o rechaza
  - [ ] Usuario verificado → puede publicar/aplicar

---

## 📞 Soporte

Para dudas sobre la implementación:
- **Email:** soporte@worknow.com
- **Documentación Firebase:** https://firebase.google.com/docs

---

## 🔄 Actualizaciones Futuras

Posibles mejoras:
- [ ] OCR automático para validar datos de cédula
- [ ] Machine Learning para detectar fotos falsas
- [ ] Sistema de re-verificación periódica
- [ ] Dashboard de administración más completo
- [ ] Notificaciones push en tiempo real
- [ ] Historial de cambios de verificación

---

**Última actualización:** 30 de noviembre de 2025  
**Versión:** 1.0.0

