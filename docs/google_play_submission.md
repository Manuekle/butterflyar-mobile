# 🎉 App Bundle (AAB) para Google Play - LISTO

## ✅ AAB Generado Exitosamente

**Archivo**: `build/app/outputs/bundle/release/app-release.aab`  
**Tamaño**: 75.6 MB  
**Estado**: ✅ Firmado y listo para subir a Google Play

---

## 🔐 Información de Firma

### Keystore Creado
- **Ubicación**: `/home/manudev/upload-keystore.jks`
- **Alias**: `upload`
- **Contraseña**: `butterflyar2024`
- **Validez**: 10,000 días (~27 años)

### ⚠️ IMPORTANTE - Guardar Keystore

**CRÍTICO**: Guarda el archivo `upload-keystore.jks` en un lugar seguro:

```bash
# Hacer backup del keystore
cp ~/upload-keystore.jks ~/Documentos/ButterflyAR-Keystore-BACKUP.jks

# O subirlo a un lugar seguro (Google Drive, etc.)
```

**Si pierdes este keystore, NO PODRÁS actualizar la app en Google Play.**

---

## 📤 Subir a Google Play Console

### Paso 1: Acceder a Google Play Console
1. Ve a https://play.google.com/console
2. Inicia sesión con tu cuenta de desarrollador
3. Si no tienes cuenta, créala ($25 USD único pago)

### Paso 2: Crear Nueva Aplicación
1. Click en "Crear aplicación"
2. Nombre: **ButterflyAR**
3. Idioma predeterminado: Español
4. Tipo: Aplicación o juego
5. Categoría: Educación

### Paso 3: Subir el AAB
1. Ve a **Producción** → **Crear nueva versión**
2. Click en "Subir" y selecciona:
   ```
   /home/manudev/develop/butterflyar-mobile/build/app/outputs/bundle/release/app-release.aab
   ```
3. Espera a que se procese (puede tardar unos minutos)

### Paso 4: Completar Información Requerida

#### Información de la App
- **Nombre**: ButterflyAR
- **Descripción corta**: Explora mariposas en Realidad Aumentada
- **Descripción completa**: 
  ```
  ButterflyAR es una aplicación educativa que te permite explorar mariposas 
  colombianas en Realidad Aumentada usando ARCore. Visualiza modelos 3D 
  detallados, aprende sobre diferentes especies y experimenta con AR.
  
  Características:
  • Visualización AR de mariposas en 3D
  • Información detallada de cada especie
  • Modelos 3D interactivos
  • Sonidos ambientales
  • Interfaz intuitiva
  ```

#### Capturas de Pantalla (Requerido)
- Mínimo 2 capturas de pantalla
- Tamaño recomendado: 1080x1920 px
- Tomar desde la app en funcionamiento

#### Ícono de la Aplicación
- Tamaño: 512x512 px
- Formato: PNG
- Sin transparencia

#### Clasificación de Contenido
1. Completa el cuestionario
2. Para app educativa: "Todos" (E)

#### Privacidad
- URL de política de privacidad (si aplica)
- Permisos explicados:
  - **Cámara**: Para experiencia AR
  - **Almacenamiento**: Para guardar capturas

### Paso 5: Enviar para Revisión
1. Revisa toda la información
2. Click en "Enviar para revisión"
3. Espera aprobación (1-7 días típicamente)

---

## 📋 Checklist Pre-Publicación

- [ ] AAB generado y firmado ✅
- [ ] Keystore guardado en lugar seguro
- [ ] Capturas de pantalla preparadas
- [ ] Ícono 512x512 listo
- [ ] Descripción escrita
- [ ] Política de privacidad (opcional)
- [ ] Cuenta de Google Play Developer activa
- [ ] Información de contacto actualizada

---

## 🔄 Actualizaciones Futuras

Para actualizar la app en Google Play:

### 1. Actualizar Versión

Edita `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Incrementar número después del +
```

### 2. Generar Nuevo AAB
```bash
flutter build appbundle --release
```

### 3. Subir a Google Play
- Ve a **Producción** → **Crear nueva versión**
- Sube el nuevo AAB
- Describe los cambios
- Enviar para revisión

**IMPORTANTE**: Usa siempre el mismo keystore (`upload-keystore.jks`)

---

## 📊 Información Técnica del AAB

### Contenido
- ✅ Código optimizado para producción
- ✅ Firmado con keystore de release
- ✅ Soporte para múltiples arquitecturas (ARM64, ARM32, x86_64)
- ✅ Recursos optimizados
- ✅ Librerías ARCore incluidas

### Ventajas del AAB vs APK
- ✅ Google Play genera APKs optimizados por dispositivo
- ✅ Menor tamaño de descarga para usuarios
- ✅ Actualizaciones más eficientes
- ✅ Requerido por Google Play (desde 2021)

---

## 🛡️ Seguridad

### Archivos Sensibles (NO compartir)
- `~/upload-keystore.jks` - Keystore de firma
- `android/key.properties` - Credenciales (ya en .gitignore)

### Archivos Seguros para Compartir
- `app-release.aab` - Solo para Google Play
- Código fuente (sin key.properties)

---

## ✅ Resumen

**Estado**: ✅ AAB firmado y listo para Google Play  
**Ubicación**: `build/app/outputs/bundle/release/app-release.aab`  
**Tamaño**: 75.6 MB  
**Próximo paso**: Subir a Google Play Console

¡Tu app está lista para publicarse en Google Play! 🚀
