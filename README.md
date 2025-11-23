# 🦋 ButterflyAR

[![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.0+-blue.svg)](https://dart.dev/)
[![Platforms](https://img.shields.io/badge/platforms-Android%20|%20iOS-lightgrey.svg)](https://flutter.dev/multi-platform/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

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

- **Android**: 8.0 (API 26) o superior con soporte ARCore
- **iOS**: 13.0 o superior con soporte ARKit (iPhone 6s o superior)

### Para Desarrolladores

- **Flutter SDK**: 3.9.0 o superior
- **Dart SDK**: 3.9.0 o superior
- **Android Studio** / **VS Code** con extensiones de Flutter
- **Xcode** 14.0+ (para desarrollo iOS)
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

### 4. Ejecutar la Aplicación

```bash
# Para Android
flutter run -d <device_id>

# Para iOS
flutter run -d <device_id>
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
| `flutter`              | SDK     | SDK principal de Flutter           |
| `provider`             | ^6.1.5  | Gestión de estado                  |
| `arkit_plugin`         | ^1.1.2  | Integración con ARKit para iOS     |
| `ar_flutter_plugin`    | git     | Integración con ARCore para Android|
| `model_viewer_plus`    | ^1.9.3  | Visualización de modelos 3D        |
| `mobile_scanner`       | ^7.0.0  | Escaneo de códigos QR              |
| `permission_handler`   | ^11.3.0 | Manejo de permisos del dispositivo |
| `google_fonts`         | ^6.2.1  | Fuentes personalizadas             |
| `url_launcher`         | ^6.3.2  | Apertura de enlaces                |
| `audioplayers`         | ^6.5.0  | Reproducción de sonidos            |
| `webview_flutter`      | ^4.13.0 | Visualización web                  |
| `flutter_svg`          | ^2.2.1  | Renderizado de SVG                 |
| `lucide_icons_flutter` | ^3.0.3  | Iconos modernos                    |

### Instalación de Dependencias

```bash
flutter pub get
```

## 🏗️ Estructura del Proyecto

```text
butterflyar-mobile/
├── android/              # Configuración específica de Android
├── ios/                  # Configuración específica de iOS
│   └── Runner/
│       └── models.scnassets/  # Modelos 3D para iOS (.scn)
├── lib/                  # Código fuente de la aplicación
│   ├── data/             # Datos JSON de mariposas
│   ├── models/           # Modelos de datos (Butterfly, etc.)
│   ├── providers/        # Providers para gestión de estado
│   ├── screens/          # Pantallas de la aplicación
│   ├── theme/            # Temas y proveedores de tema
│   ├── utils/            # Utilidades y helpers (AR, plataforma)
│   ├── widgets/          # Widgets reutilizables
│   └── main.dart         # Punto de entrada de la aplicación
├── assets/               # Recursos estáticos
│   ├── models/           # Modelos 3D para Android (.glb)
│   ├── images/           # Imágenes de mariposas
│   ├── sounds/           # Sonidos ambientales
│   ├── backgrounds/     # Fondos de pantalla
│   └── icon/             # Iconos de la aplicación
├── test/                 # Pruebas unitarias y de widget
└── pubspec.yaml          # Configuración de dependencias
```

## 🦋 Gestión de Especies

La aplicación utiliza un archivo JSON centralizado (`lib/data/butterflies.json`) para gestionar las diferentes especies de mariposas. Cada especie incluye información científica, referencias a modelos 3D y recursos multimedia.

### Estructura de Datos

Las mariposas se definen en `lib/data/butterflies.json` con la siguiente estructura:

```json
{
  "butterflies": [
    {
      "id": "actinote_osomene",
      "name": "Luminaria Negra",
      "scientificName": "Actinote osomene",
      "description": "Descripción detallada de la especie...",
      "imageAsset": "assets/images/actinote_osomene.jpg",
      "modelAssetAndroid": "assets/models/actinote_osomene.glb",
      "modelAssetIOS": "models.scnassets/actinote_osomene.scn",
      "ambientSound": "assets/sounds/forest_ambient.mp3",
      "characteristics": [
        "Característica 1",
        "Característica 2"
      ],
      "habitat": "Descripción del hábitat",
      "distribution": "Distribución geográfica"
    }
  ]
}
```

### Agregar Nueva Especie

1. Agrega el modelo 3D:
   - **Android**: Coloca el archivo `.glb` en `assets/models/`
   - **iOS**: Coloca el archivo `.scn` en `ios/Runner/models.scnassets/`

2. Agrega la imagen de la mariposa en `assets/images/`

3. Agrega la entrada en `lib/data/butterflies.json` con todos los campos requeridos

4. Asegúrate de que los assets estén referenciados en `pubspec.yaml`

## 🔍 Integración QR

La aplicación incluye un escáner de códigos QR que permite asociar códigos con especies específicas para una experiencia interactiva en exteriores.

### Funcionalidad

- Escaneo de códigos QR usando la cámara del dispositivo
- Validación y procesamiento de códigos
- Carga automática de la especie correspondiente
- Navegación directa a la experiencia AR

### Pantallas Principales

- **Onboarding**: Introducción a la aplicación
- **Hub**: Pantalla principal con opciones de navegación
- **Selección de Especies**: Lista de mariposas disponibles
- **Experiencia AR**: Visualización en realidad aumentada
- **Escáner QR**: Escaneo de códigos para desbloquear contenido
- **Configuración**: Ajustes de la aplicación y tema

## 👥 Contribución

¡Agradecemos tu interés en contribuir a ButterflyAR! 

### Reportar Problemas

Por favor, reporta los errores con la siguiente información:

- **Descripción clara** del problema
- Pasos para **reproducir** el error
- Comportamiento **esperado** vs **real**
- Capturas de pantalla o grabaciones
- Información del entorno (dispositivo, SO, versión de Flutter)

### Directrices de Código

- Sigue el [estilo de código de Flutter](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- Escribe pruebas unitarias para nuevas funcionalidades
- Mantén los commits atómicos y con mensajes descriptivos
- Ejecuta `flutter analyze` antes de enviar cambios

## 📧 Contacto

- **Desarrollador**: [@Manuekle](https://github.com/Manuekle)

## 🙏 Agradecimientos

Un especial agradecimiento a:

- **Smurfit Kappa Cartón Colombia** - Por hacer posible este proyecto
- **Biólogos de la Universidad del Cauca** - Por su valiosa contribución científica y por compartir su conocimiento sobre las mariposas
- **Comunidad Flutter** - Por crear un ecosistema increíble
- **Creadores de paquetes** - Por su trabajo en las dependencias utilizadas
- **Usuarios** - Por probar la aplicación y proporcionar retroalimentación

---

## ❓ Preguntas Frecuentes

### Problemas Técnicos

- **No se visualiza el modelo en Realidad Aumentada**
  - Verifica que la cámara tenga los permisos necesarios
  - Asegúrate de tener buena iluminación
  - Verifica que el dispositivo sea compatible con ARCore (Android) o ARKit (iOS)
  - El modelo `.glb` (Android) o `.scn` (iOS) debe estar bien exportado y referenciado
  - Intenta reiniciar la aplicación

### Sobre el Proyecto

Este proyecto es una colaboración entre **Smurfit Kappa Cartón Colombia** y la **Universidad del Cauca**, con el objetivo de promover la educación ambiental y la conservación de las mariposas nativas de la región del Cauca.

### Optimización

- Mantén los modelos 3D optimizados para evitar caídas de rendimiento
- Los modelos deben tener un tamaño razonable (< 10MB recomendado)
- Usa texturas comprimidas cuando sea posible

---

**Desarrollado con ❤️ usando Flutter**
