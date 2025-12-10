// lib/services/audio_service.dart
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Servicio para gestionar la reproducción de audio en la aplicación
/// 
/// Este servicio encapsula:
/// - Reproducción de sonidos ambientales
/// - Control de volumen
/// - Manejo del ciclo de vida del reproductor
/// - Gestión de múltiples reproductores si es necesario
class AudioService {
  AudioPlayer? _ambientPlayer;
  AudioPlayer? _effectsPlayer;
  
  bool _isAmbientPlaying = false;
  double _ambientVolume = 0.3;
  double _effectsVolume = 0.5;
  
  // Getters
  bool get isAmbientPlaying => _isAmbientPlaying;
  double get ambientVolume => _ambientVolume;
  double get effectsVolume => _effectsVolume;

  /// Inicializa el servicio de audio
  void initialize() {
    _ambientPlayer ??= AudioPlayer();
    _effectsPlayer ??= AudioPlayer();
    
    if (kDebugMode) {
      debugPrint('[AudioService] Initialized');
    }
  }

  /// Reproduce un sonido ambiental en loop
  Future<bool> playAmbientSound(String assetPath, {double? volume}) async {
    try {
      // Asegurar que el reproductor está inicializado
      _ambientPlayer ??= AudioPlayer();
      
      // Normalizar ruta del asset
      final normalizedPath = _normalizeAssetPath(assetPath);
      
      // Configurar volumen
      final playVolume = volume ?? _ambientVolume;
      await _ambientPlayer!.setVolume(playVolume);
      _ambientVolume = playVolume;
      
      // Configurar modo loop
      await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
      
      // Reproducir
      await _ambientPlayer!.play(AssetSource(normalizedPath));
      _isAmbientPlaying = true;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Playing ambient sound: $normalizedPath');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error playing ambient sound: $e');
      }
      return false;
    }
  }

  /// Reproduce un efecto de sonido (una sola vez)
  Future<bool> playEffect(String assetPath, {double? volume}) async {
    try {
      // Asegurar que el reproductor está inicializado
      _effectsPlayer ??= AudioPlayer();
      
      // Normalizar ruta del asset
      final normalizedPath = _normalizeAssetPath(assetPath);
      
      // Configurar volumen
      final playVolume = volume ?? _effectsVolume;
      await _effectsPlayer!.setVolume(playVolume);
      
      // Configurar modo de una sola reproducción
      await _effectsPlayer!.setReleaseMode(ReleaseMode.release);
      
      // Reproducir
      await _effectsPlayer!.play(AssetSource(normalizedPath));
      
      if (kDebugMode) {
        debugPrint('[AudioService] Playing effect: $normalizedPath');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error playing effect: $e');
      }
      return false;
    }
  }

  /// Pausa el sonido ambiental
  Future<void> pauseAmbient() async {
    try {
      await _ambientPlayer?.pause();
      _isAmbientPlaying = false;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Ambient sound paused');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error pausing ambient: $e');
      }
    }
  }

  /// Reanuda el sonido ambiental
  Future<void> resumeAmbient() async {
    try {
      await _ambientPlayer?.resume();
      _isAmbientPlaying = true;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Ambient sound resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error resuming ambient: $e');
      }
    }
  }

  /// Detiene el sonido ambiental
  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer?.stop();
      _isAmbientPlaying = false;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Ambient sound stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error stopping ambient: $e');
      }
    }
  }

  /// Detiene todos los efectos de sonido
  Future<void> stopEffects() async {
    try {
      await _effectsPlayer?.stop();
      
      if (kDebugMode) {
        debugPrint('[AudioService] Effects stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error stopping effects: $e');
      }
    }
  }

  /// Establece el volumen del sonido ambiental
  Future<void> setAmbientVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _ambientPlayer?.setVolume(clampedVolume);
      _ambientVolume = clampedVolume;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Ambient volume set to: $clampedVolume');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error setting ambient volume: $e');
      }
    }
  }

  /// Establece el volumen de los efectos
  Future<void> setEffectsVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _effectsPlayer?.setVolume(clampedVolume);
      _effectsVolume = clampedVolume;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Effects volume set to: $clampedVolume');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error setting effects volume: $e');
      }
    }
  }

  /// Silencia todos los sonidos
  Future<void> muteAll() async {
    await setAmbientVolume(0.0);
    await setEffectsVolume(0.0);
  }

  /// Restaura el volumen por defecto
  Future<void> unmuteAll() async {
    await setAmbientVolume(0.3);
    await setEffectsVolume(0.5);
  }

  /// Normaliza la ruta de un asset (elimina "assets/" si está presente)
  String _normalizeAssetPath(String path) {
    String normalized = path.trim();
    if (normalized.startsWith('assets/')) {
      normalized = normalized.substring(7);
    }
    return normalized;
  }

  /// Limpia y libera recursos
  Future<void> dispose() async {
    try {
      await _ambientPlayer?.stop();
      await _ambientPlayer?.dispose();
      await _effectsPlayer?.stop();
      await _effectsPlayer?.dispose();
      
      _ambientPlayer = null;
      _effectsPlayer = null;
      _isAmbientPlaying = false;
      
      if (kDebugMode) {
        debugPrint('[AudioService] Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioService] Error disposing: $e');
      }
    }
  }
}
