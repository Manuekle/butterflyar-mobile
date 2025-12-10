// lib/services/ar/ar_permission_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/ar_helpers.dart';

/// Servicio para gestionar permisos necesarios para AR
/// 
/// Este servicio encapsula:
/// - Verificación de permisos de cámara
/// - Solicitud de permisos
/// - Manejo de permisos denegados permanentemente
/// - Diálogos de configuración
class ARPermissionService {
  bool _hasCameraPermission = false;
  PermissionStatus? _lastCameraStatus;

  // Callbacks
  Function(bool)? _onPermissionChanged;

  // Getters
  bool get hasCameraPermission => _hasCameraPermission;
  PermissionStatus? get lastCameraStatus => _lastCameraStatus;

  /// Configura el callback para cambios de permisos
  void setOnPermissionChanged(Function(bool) callback) {
    _onPermissionChanged = callback;
  }

  /// Verifica el estado actual del permiso de cámara
  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      _lastCameraStatus = status;
      
      final hasPermission = status.isGranted;
      
      if (_hasCameraPermission != hasPermission) {
        _hasCameraPermission = hasPermission;
        _onPermissionChanged?.call(hasPermission);
      }
      
      ARLogger.log('Camera permission status: ${status.toString().split('.').last}');
      return hasPermission;
    } catch (e) {
      ARLogger.error('Error checking camera permission', e);
      return false;
    }
  }

  /// Solicita el permiso de cámara
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      _lastCameraStatus = status;
      
      final hasPermission = status.isGranted;
      
      if (_hasCameraPermission != hasPermission) {
        _hasCameraPermission = hasPermission;
        _onPermissionChanged?.call(hasPermission);
      }
      
      ARLogger.log('Camera permission requested: ${status.toString().split('.').last}');
      return hasPermission;
    } catch (e) {
      ARLogger.error('Error requesting camera permission', e);
      return false;
    }
  }

  /// Verifica y solicita permiso de cámara si es necesario
  Future<bool> ensureCameraPermission() async {
    final hasPermission = await checkCameraPermission();
    
    if (!hasPermission) {
      return await requestCameraPermission();
    }
    
    return true;
  }

  /// Verifica si el permiso fue denegado permanentemente
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.camera.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      ARLogger.error('Error checking if permission is permanently denied', e);
      return false;
    }
  }

  /// Abre la configuración de la aplicación
  Future<bool> openAppSettings() async {
    try {
      final opened = await openAppSettings();
      ARLogger.log('App settings opened: $opened');
      return opened;
    } catch (e) {
      ARLogger.error('Error opening app settings', e);
      return false;
    }
  }

  /// Muestra un diálogo solicitando permisos de cámara
  Future<bool?> showPermissionRequestDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso de Cámara Requerido'),
        content: const Text(
          'Para usar la función de Realidad Aumentada, necesitamos acceso a la cámara. '
          '¿Deseas otorgar este permiso?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await requestCameraPermission();
            },
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo para permisos denegados permanentemente
  Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso de Cámara Requerido'),
        content: const Text(
          'Para usar la función de Realidad Aumentada, necesitamos acceso a la cámara. '
          'Por favor, habilita el permiso en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Maneja el flujo completo de permisos con diálogos
  Future<bool> handlePermissionFlow(BuildContext context) async {
    // Verificar estado actual
    final hasPermission = await checkCameraPermission();
    
    if (hasPermission) {
      return true;
    }

    // Verificar si está permanentemente denegado
    final isPermanentlyDenied = await isPermissionPermanentlyDenied();
    
    if (isPermanentlyDenied) {
      await showPermissionDeniedDialog(context);
      return false;
    }

    // Solicitar permiso
    final granted = await requestCameraPermission();
    
    if (!granted) {
      // Mostrar diálogo explicativo
      await showPermissionRequestDialog(context);
    }
    
    return granted;
  }

  /// Resetea el estado del servicio
  void reset() {
    _hasCameraPermission = false;
    _lastCameraStatus = null;
    ARLogger.log('ARPermissionService reset');
  }
}
