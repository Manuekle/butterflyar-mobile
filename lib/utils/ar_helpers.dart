// lib/utils/ar_helpers.dart - Versión para ARCore (Android e iOS) y Model Viewer (fallback)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Enum para diferentes tipos de soporte AR
enum ARPlatformSupport {
  arcore, // ARCore (Android e iOS usando ar_flutter_plugin)
  modelViewer, // Android/iOS Model Viewer (fallback)
  none, // Sin soporte AR
}

/// Clase para manejar la detección de AR
class SimpleARSupport {
  static ARPlatformSupport _cachedSupport = ARPlatformSupport.none;
  static bool _hasChecked = false;

  /// Detecta qué tipo de AR es compatible en el dispositivo actual
  static Future<ARPlatformSupport> detectARSupport() async {
    if (_hasChecked) return _cachedSupport;

    try {
      // Web: sin soporte AR nativo
      if (kIsWeb) {
        _cachedSupport = ARPlatformSupport.modelViewer;
        return _cachedSupport;
      }

      // iOS: usar ARCore a través de ar_flutter_plugin (iOS 11+)
      if (Platform.isIOS) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          final systemVersion = iosInfo.systemVersion;
          final majorVersion =
              int.tryParse(systemVersion.split('.').first) ?? 0;

          // Verificar versión mínima de iOS (11.0+) para ar_flutter_plugin
          if (majorVersion < 11) {
            debugPrint(
              'ARCore (ar_flutter_plugin) requires iOS 11.0 or later. Current version: $systemVersion',
            );
            _cachedSupport = ARPlatformSupport.modelViewer;
            return _cachedSupport;
          }

          _cachedSupport = ARPlatformSupport.arcore;
          debugPrint(
            'ARCore (ar_flutter_plugin) is supported on this device (iOS $systemVersion)',
          );
        } catch (e) {
          debugPrint('Error checking iOS ARCore support: $e');
          _cachedSupport = ARPlatformSupport.modelViewer;
        }
      }
      // Android: asumir ARCore disponible (se verificará en tiempo de ejecución)
      else if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          final sdkInt = androidInfo.version.sdkInt;
          
          // ARCore requiere Android 7.0 (API 24) o superior
          if (sdkInt >= 24) {
            _cachedSupport = ARPlatformSupport.arcore;
            debugPrint('Android device meets ARCore minimum requirements (API $sdkInt)');
          } else {
            _cachedSupport = ARPlatformSupport.modelViewer;
            debugPrint('Android version too old for ARCore (API $sdkInt < 24)');
          }
        } catch (e) {
          debugPrint('Error checking Android version: $e');
          // Asumir que puede tener ARCore y dejar que falle gracefully
          _cachedSupport = ARPlatformSupport.arcore;
        }
      }
    } catch (e) {
      debugPrint('Error detecting AR support: $e');
      _cachedSupport = ARPlatformSupport.modelViewer;
    }

    _hasChecked = true;
    return _cachedSupport;
  }

  /// Obtiene información legible sobre el soporte AR
  static Future<String> getARSupportInfo() async {
    final support = await detectARSupport();
    switch (support) {
      case ARPlatformSupport.arcore:
        return 'ARCore (Android/iOS)';
      case ARPlatformSupport.modelViewer:
        return '3D Model Viewer';
      case ARPlatformSupport.none:
        return 'No compatible';
    }
  }

  /// ⭐ Resetea el cache para volver a verificar soporte
  static void resetCache() {
    _hasChecked = false;
    _cachedSupport = ARPlatformSupport.none;
  }

  /// ⭐ Verifica si el dispositivo tiene soporte AR nativo (no Model Viewer)
  static bool isNativeARSupported(ARPlatformSupport support) {
    return support == ARPlatformSupport.arcore;
  }
}

/// Configuraciones por defecto para modelos 3D
class ARModelConfig {
  final double scale;
  final List<double> position; // [x, y, z]
  final List<double> rotation; // [x, y, z] en radianes

  const ARModelConfig({
    this.scale = 0.05,
    this.position = const [0, 0, -0.5],
    this.rotation = const [0, 0, 0],
  });

  /// Configuración optimizada para mariposas
  static const ARModelConfig butterfly = ARModelConfig(
    scale: 0.03,
    position: [0, -0.2, -0.8],
    rotation: [0, 0, 0],
  );

  /// Configuración para modelos más grandes
  static const ARModelConfig large = ARModelConfig(
    scale: 0.1,
    position: [0, -0.5, -1.0],
    rotation: [0, 0, 0],
  );
}

/// Utilidad para logs AR
class ARLogger {
  static final bool _debugMode = kDebugMode;

  static void log(String message) {
    if (_debugMode) {
      debugPrint('[AR] $message');
    }
  }

  static void error(String message, [Object? error]) {
    debugPrint('[AR ERROR] $message');
    if (error != null) {
      debugPrint('[AR ERROR] Details: $error');
    }
  }

  static void success(String message) {
    if (_debugMode) {
      debugPrint('[AR SUCCESS] $message');
    }
  }
}

/// Clase helper para trabajar con vectores (deprecated - usar ArCoreVector3Helper)
@Deprecated('Usar ArCoreVector3Helper en su lugar')
class ARKitVector3Helper {
  static dynamic createVector3(double x, double y, double z) {
    return {'x': x, 'y': y, 'z': z};
  }
}

/// Clase helper para trabajar con vectores de ARCore
class ArCoreVector3Helper {
  static dynamic createVector3(double x, double y, double z) {
    // Esto será reemplazado por la importación real de ARCore
    return {'x': x, 'y': y, 'z': z};
  }
}
