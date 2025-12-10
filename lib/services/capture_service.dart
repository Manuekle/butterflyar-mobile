// lib/services/capture_service.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import 'logger_service.dart';

/// Servicio para gestionar capturas de pantalla
/// 
/// Este servicio encapsula:
/// - Captura de pantalla de la vista AR
/// - Guardado en galería
/// - Manejo de permisos de almacenamiento
/// - Compresión de imágenes
class CaptureService {
  final LoggerService _logger = logger;

  /// Guarda una imagen en la galería
  Future<bool> saveImageToGallery(
    Uint8List imageBytes, {
    String albumName = 'ButterflyAR',
  }) async {
    try {
      // Verificar permisos de galería
      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        _logger.info('Requesting gallery access', category: 'Capture');
        hasAccess = await Gal.requestAccess();

        if (!hasAccess) {
          _logger.warning('Gallery access denied', category: 'Capture');
          return false;
        }
      }

      // Guardar imagen en la galería
      await Gal.putImageBytes(imageBytes, album: albumName);
      
      _logger.success('Image saved to gallery: $albumName', category: 'Capture');
      HapticFeedback.mediumImpact();
      
      return true;
    } on GalException catch (e) {
      _handleGalException(e);
      return false;
    } catch (e) {
      _logger.error('Error saving image to gallery', error: e, category: 'Capture');
      return false;
    }
  }

  /// Maneja excepciones específicas de Gal
  void _handleGalException(GalException e) {
    String errorMessage;
    
    switch (e.type) {
      case GalExceptionType.accessDenied:
        errorMessage = 'Acceso denegado a la galería';
        break;
      case GalExceptionType.notEnoughSpace:
        errorMessage = 'No hay suficiente espacio en el dispositivo';
        break;
      case GalExceptionType.notSupportedFormat:
        errorMessage = 'Formato de imagen no soportado';
        break;
      case GalExceptionType.unexpected:
      default:
        errorMessage = 'Error inesperado al guardar la imagen';
        break;
    }
    
    _logger.error(errorMessage, error: e, category: 'Capture');
  }

  /// Verifica si tiene permisos de galería
  Future<bool> hasGalleryPermission() async {
    try {
      return await Gal.hasAccess();
    } catch (e) {
      _logger.error('Error checking gallery permission', error: e, category: 'Capture');
      return false;
    }
  }

  /// Solicita permisos de galería
  Future<bool> requestGalleryPermission() async {
    try {
      final hasAccess = await Gal.requestAccess();
      
      if (hasAccess) {
        _logger.success('Gallery permission granted', category: 'Capture');
      } else {
        _logger.warning('Gallery permission denied', category: 'Capture');
      }
      
      return hasAccess;
    } catch (e) {
      _logger.error('Error requesting gallery permission', error: e, category: 'Capture');
      return false;
    }
  }

  /// Comprime una imagen (placeholder para futura implementación)
  Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
  }) async {
    // TODO: Implementar compresión de imagen si es necesario
    // Por ahora, retorna la imagen sin comprimir
    return imageBytes;
  }
}
