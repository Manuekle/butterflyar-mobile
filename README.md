# 🦋 ButterflyAR

[![Flutter](https://img.shields.io/badge/Flutter-3.19.0-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.3.0-blue.svg)](https://dart.dev/)
[![Platforms](https://img.shields.io/badge/platforms-Android%20|%20iOS%20|%20Web%20|%20Windows%20|%20macOS%20|%20Linux-lightgrey.svg)](https://flutter.dev/multi-platform/desktop)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

Una aplicación educativa multiplataforma que permite explorar mariposas en Realidad Aumentada. Con un diseño minimalista, soporte para modo oscuro y una experiencia inmersiva, ButterflyAR es perfecta para amantes de la naturaleza y la tecnología.

![ButterflyAR Showcase](./assets/icon/favicon-light.png)

## 📋 Tabla de Contenidos

- [✨ Características](#-características)
- [🚀 Demo Rápida](#-demo-rápida)
- [📱 Requisitos](#-requisitos)
- [⚙️ Instalación](#️-instalación)
- [🛠️ Configuración](#️-configuración)
- [🏗️ Estructura del Proyecto](#️-estructura-del-proyecto)
- [🦋 Gestión de Especies](#-gestión-de-especies)
- [🔍 Integración QR](#-integración-qr)
- [👥 Contribución](#-contribución)
- [📄 Licencia](#-licencia)
- [📧 Contacto](#-contacto)
- [🙏 Agradecimientos](#-agradecimientos)

## ✨ Características

### 🦋 Realidad Aumentada Avanzada

- Visualización de modelos 3D de alta calidad en tiempo real
- Interacción intuitiva con gestos táctiles (escala, rotación, traslación)
- Integración perfecta con el entorno físico del usuario

### 🌐 Multiplataforma

- Soporte nativo para móviles (Android/iOS)
- Versión web accesible desde cualquier navegador
- Compatibilidad con dispositivos de escritorio (Windows, macOS, Linux)

### 🎨 Experiencia de Usuario

- Interfaz minimalista y accesible
- Tema claro/oscuro que se adapta a la configuración del sistema
- Transiciones fluidas y animaciones naturales

### 📚 Base de Datos de Especies

- Información científica detallada de cada mariposa
- Galería de imágenes de alta resolución
- Datos de conservación y distribución geográfica

### 🔍 Sistema de Descubrimiento

- Escaneo de códigos QR para desbloquear contenido exclusivo
- Mapa interactivo de avistamientos
- Sistema de logros y coleccionables

## 🚀 Requisitos

### Para Usuarios

- **Android**: 8.0 (API 26) o superior
- **iOS**: 13.0 o superior
- **Web**: Chrome 90+, Firefox 88+, Safari 14.1+, Edge 90+
- **Escritorio**: Windows 10/11, macOS 10.14+, Linux (con soporte de escritorio)

### Para Desarrolladores

- **Flutter SDK**: 3.19.0 o superior
- **Dart SDK**: 3.3.0 o superior
- **Android Studio** / **VS Code** con extensiones de Flutter
- **Xcode** 14.0+ (para desarrollo iOS/macOS)
- **Git** para control de versiones

## ⚙️ Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/Manuekle/butterflyar.git
cd butterflyar
```

### 2. Obtener Dependencias

```bash
flutter pub get
```

### 3. Configurar Plataforma Objetivo

#### Android

```bash
flutter create --platforms=android .
```

#### iOS

```bash
flutter create --platforms=ios .
cd ios
pod install
cd ..
```

#### Web

```bash
flutter create --platforms=web .
```

### 4. Ejecutar la Aplicación

```bash
# Para Android
flutter run -d <device_id>

# Para iOS
flutter run -d <device_id>

# Para web
flutter run -d chrome --web-renderer html
```

## 🚀 Cómo Usar

### Dispositivos Móviles (Android/iOS)

1. **Prepara tu dispositivo**

   - **Android**:
     - Activa la opción "Opciones de desarrollador" y "Depuración USB"
     - Asegúrate de que el dispositivo soporte ARCore
   - **iOS**:
     - Conecta tu dispositivo y confía en el certificado de desarrollador
     - Asegúrate de que el dispositivo soporte ARKit (iPhone 6s o superior)

2. **Configura los modelos 3D**

   - **Para Android**:

     1. Coloca los archivos `.glb` en `assets/models/`
     2. Asegúrate de que estén referenciados en `pubspec.yaml`

   - **Para iOS**:
     1. Crea la carpeta `models.scnassets` en `ios/Runner/` si no existe
     2. Importa los archivos `.scn` usando Xcode
     3. Asegúrate de que "Target Membership" esté marcado para el target principal

3. **Ejecuta la aplicación**

   ```bash
   # Para Android
   flutter run -d <device_id> --release

   # Para iOS
   flutter run -d <device_id> --release
   ```

4. **Prueba la funcionalidad AR**
   - Abre la cámara y apunta a un código QR
   - La aplicación cargará el modelo 3D correspondiente en realidad aumentada

## 🛠️ Dependencias Principales

La aplicación utiliza las siguientes dependencias principales:

| Paquete                | Versión | Propósito                          |
| ---------------------- | ------- | ---------------------------------- |
| `flutter`              | ^3.19.0 | SDK principal de Flutter           |
| `provider`             | ^6.1.1  | Gestión de estado                  |
| `arkit_plugin`         | ^1.1.2  | Integración con ARKit para iOS     |
| `model_viewer_plus`    | ^1.9.3  | Visualización de modelos 3D        |
| `mobile_scanner`       | ^7.0.0  | Escaneo de códigos QR              |
| `permission_handler`   | ^12.0.1 | Manejo de permisos del dispositivo |
| `shared_preferences`   | ^2.2.2  | Almacenamiento local               |
| `cached_network_image` | ^3.3.1  | Caché de imágenes                  |
| `url_launcher`         | ^6.2.2  | Apertura de enlaces                |
| `google_fonts`         | ^6.1.0  | Fuentes personalizadas             |
| `flutter_svg`          | ^2.0.10 | Renderizado de SVG                 |
| `http`                 | ^1.1.0  | Peticiones HTTP                    |

### Instalación de Dependencias

```bash
flutter pub get
```

### Configuración de Entorno

Copia el archivo de configuración de ejemplo y ajusta los valores según sea necesario:

```bash
cp lib/config/example_config.dart lib/config/app_config.dart
```

## 🏗️ Estructura del Proyecto

```text
butterflyar/
├── android/           # Configuración específica de Android
├── ios/               # Configuración específica de iOS
├── lib/               # Código fuente de la aplicación
│   ├── models/        # Modelos de datos
│   ├── screens/       # Pantallas de la aplicación
│   ├── services/      # Servicios y lógica de negocio
│   ├── utils/         # Utilidades y helpers
│   ├── widgets/       # Widgets reutilizables
│   └── main.dart      # Punto de entrada de la aplicación
├── assets/            # Recursos estáticos
│   ├── species/       # Modelos 3D y metadatos de especies
│   └── images/        # Imágenes de la interfaz de usuario
├── test/              # Pruebas unitarias y de widget
└── pubspec.yaml       # Configuración de dependencias
```

## 🦋 Gestión de Especies

La aplicación utiliza una estructura modular para gestionar las diferentes especies de mariposas. Cada especie se define en el directorio `assets/species/` con sus respectivos recursos.

### Estructura de Directorios

```text
assets/
└── species/
    ├── common_name_1/          # Nombre común en minúsculas y guiones
    │   ├── metadata.json       # Metadatos de la especie
    │   ├── model.glb           # Modelo 3D (formato GLB)
    │   ├── preview.png         # Vista previa (512x512px)
    │   ├── gallery/            # Galería de imágenes
    │   │   ├── image1.jpg
    │   │   └── image2.jpg
    │   └── sounds/             # Sonidos opcionales
    │       └── wing_flap.mp3
    └── common_name_2/
        └── ...
```

### metadata.json

Cada especie debe tener un archivo `metadata.json` con la siguiente estructura:

```json
{
      "id": "monarca",
      "name": "Monarca",
      "scientificName": "Danaus plexippus",
      "description": "La mariposa monarca es famosa por su increíble migración de miles de kilómetros. Sus alas naranjas con venes negras y bordes negros con puntos blancos la hacen inconfundible. Es una de las migraciones más espectaculares del reino animal.",
      "imageAsset": "assets/images/monarca.jpg",
      "modelAssetAndroid": "assets/models/monarca.glb",
      "modelAssetIOS": "models.scnassets/monarca.scn",
      "ambientSound": "assets/sounds/forest_ambient.mp3",
      "characteristics": [
        "Migración épica de hasta 4,000 km",
        "Alas naranjas distintivas con venas negras",
        "Resistente a toxinas de algodoncillo",
        "Cuatro generaciones por año",
        "Navegación usando el sol y campo magnético"
      ],
      "habitat": "Campos abiertos, jardines, praderas, bordes de bosque",
      "distribution": "Norteamérica, con migraciones estacionales a México y California"
    }
```

## 🔍 Integración QR

La aplicación soporta la asociación de códigos QR con especies específicas para una experiencia interactiva en exteriores.

### Formato del Código QR

```json
{
  "type": "butterfly_species",
  "id": "monarca",
  "location": {
    "lat": 19.4326,
    "lng": -99.1332,
    "name": "Jardín Botánico"
  }
}
```

### Implementación en la Aplicación

1. **Escaneo de Códigos QR**

   - Usa la cámara del dispositivo para leer códigos QR
   - Valida la estructura del JSON
   - Carga automáticamente la especie correspondiente

2. **Generación de Códigos**

   ```dart
   import 'package:qr_flutter/qr_flutter.dart';

   QrImageView(
     data: '{"type":"butterfly_species","id":"monarca"}',
     version: QrVersions.auto,
     size: 200.0,
   );
   ```

3. **Manejo de Eventos**

   - Registra cada escaneo en el historial
   - Muestra información adicional basada en la ubicación
   - Desbloquea logros y recompensas

## 👥 Contribución

¡Agradecemos tu interés en contribuir a ButterflyAR! Sigue estos pasos para contribuir:

1. **Reportar Problemas**

   - Revisa los [issues existentes](https://github.com/Manuekle/butterflyar/issues) antes de crear uno nuevo
   - Usa plantillas de issue para errores y solicitudes de características
   - Incluye pasos para reproducir, comportamiento esperado vs real, y capturas de pantalla cuando sea posible

2. **Enviar Cambios**

   ```bash
   # 1. Haz fork del repositorio
   git clone https://github.com/tu-usuario/butterflyar.git
   cd butterflyar

   # 2. Crea una rama para tu característica
   git checkout -b feature/nueva-caracteristica

   # 3. Haz commit de tus cambios
   git commit -m "feat: añadir nueva característica"

   # 4. Haz push a tu fork
   git push origin feature/nueva-caracteristica
   ```

3. **Directrices de Código**

   - Sigue el [estilo de código de Flutter](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
   - Escribe pruebas unitarias para nuevas funcionalidades
   - Documenta los cambios en la API cuando sea necesario
   - Mantén los commits atómicos y con mensajes descriptivos

4. **Revisión de Código**
   - Todo el código debe pasar las pruebas y el análisis estático
   - Los PRs deben ser revisados por al menos un mantenedor
   - Se pueden solicitar cambios antes de hacer merge

### 🐛 Reportar Errores

Por favor, reporta los errores [creando un nuevo issue](https://github.com/Manuekle/butterflyar/issues) con la siguiente información:

- **Descripción clara** del problema
- Pasos para **reproducir** el error
- Comportamiento **esperado** vs **real**
- Capturas de pantalla o grabaciones
- Información del entorno (dispositivo, SO, versión de Flutter)
- Código de ejemplo si es relevante

## 📧 Contacto

- **Manuel** - [@Manuekle](https://github.com/Manuekle)
- **Correo electrónico**: <contacto@butterflyar.app>
- **Sitio web**: [https://butterflyar.app](https://butterflyar.app)
- **Twitter**: [@ButterflyARApp](https://twitter.com/ButterflyARApp)
- **Instagram**: [@butterflyar.app](https://instagram.com/butterflyar.app)

## 🙏 Agradecimientos

Un especial agradecimiento a:

- **Smurfit Kappa Cartón Colombia** - Por hacer posible este proyecto
- **Biólogos de la Universidad del Cauca** - Por su valiosa contribución científica y por compartir su conocimiento sobre las mariposas
- **Comunidad Flutter** - Por crear un ecosistema increíble
- **Creadores de paquetes** - Por su trabajo en las dependencias utilizadas
- **Usuarios** - Por probar la aplicación y proporcionar retroalimentación

---

## ❓ Preguntas Frecuentes y Soporte

### Problemas Técnicos

- **No se visualiza el modelo en Realidad Aumentada**
  - Verifica que la cámara tenga los permisos necesarios
  - Asegúrate de tener buena iluminación
  - Intenta reiniciar la aplicación

### Sobre el Proyecto

- **¿Quiénes están detrás de este proyecto?**
  Este proyecto es una colaboración entre Smurfit Kappa Cartón Colombia y la Universidad del Cauca, con el objetivo de promover la educación ambiental y la conservación de las mariposas nativas de la región del Cauca.

### Contacto

Para soporte técnico o más información, por favor contacta a:

- **Smurfit Kappa Cartón Colombia**: [correo@skcc.com](mailto:correo@skcc.com)
- **Universidad del Cauca - Departamento de Biología**: [biologia@unicauca.edu.co](mailto:biologia@unicauca.edu.co)
  - Verifica permisos de cámara.
  - El modelo `.glb` debe estar bien exportado y referenciado.
  - Usa dispositivos compatibles con ARCore (Android) o ARKit (iOS).
- Para agregar más mariposas, repite el flujo de assets y modelo en el código.
- Mantén los modelos optimizados para evitar caídas de rendimiento.

---
