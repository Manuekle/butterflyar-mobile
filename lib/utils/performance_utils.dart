// lib/utils/performance_utils.dart
import 'package:flutter/foundation.dart';

/// Utilidades para optimización de rendimiento
class PerformanceUtils {
  /// Debounce para búsquedas y operaciones frecuentes
  static Future<void> debounce({
    required Duration duration,
    required Future<void> Function() action,
  }) async {
    await Future.delayed(duration);
    await action();
  }

  /// Throttle para limitar ejecuciones
  static DateTime? _lastExecution;
  
  static Future<T?> throttle<T>({
    required Duration duration,
    required Future<T> Function() action,
  }) async {
    final now = DateTime.now();
    
    if (_lastExecution == null || 
        now.difference(_lastExecution!) > duration) {
      _lastExecution = now;
      return await action();
    }
    
    return null;
  }

  /// Mide el tiempo de ejecución de una función
  static Future<T> measurePerformance<T>({
    required String label,
    required Future<T> Function() action,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await action();
      stopwatch.stop();
      
      if (kDebugMode) {
        debugPrint('⏱️ [$label] took ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('❌ [$label] failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      rethrow;
    }
  }

  /// Limpia recursos no utilizados
  static void clearMemory() {
    if (kDebugMode) {
      debugPrint('🧹 Clearing memory cache');
    }
    // Implementar limpieza específica según necesidad
  }
}

/// Mixin para widgets con optimización de rebuild
mixin OptimizedRebuildMixin {
  bool _shouldRebuild = true;
  
  void markNeedsRebuild() {
    _shouldRebuild = true;
  }
  
  void markRebuildComplete() {
    _shouldRebuild = false;
  }
  
  bool get shouldRebuild => _shouldRebuild;
}
