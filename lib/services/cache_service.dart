// lib/services/cache_service.dart
import 'package:flutter/foundation.dart';

/// Servicio de caché para optimizar acceso a datos
class CacheService<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration _ttl;
  final int _maxSize;

  CacheService({
    Duration ttl = const Duration(minutes: 5),
    int maxSize = 100,
  })  : _ttl = ttl,
        _maxSize = maxSize;

  /// Obtiene un valor del caché
  V? get(K key) {
    final entry = _cache[key];
    
    if (entry == null) {
      return null;
    }

    // Verificar si expiró
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(key);
      return null;
    }

    entry.accessCount++;
    entry.lastAccess = DateTime.now();
    return entry.value;
  }

  /// Guarda un valor en el caché
  void set(K key, V value) {
    // Si el caché está lleno, eliminar el menos usado
    if (_cache.length >= _maxSize) {
      _evictLeastUsed();
    }

    _cache[key] = _CacheEntry(
      value: value,
      timestamp: DateTime.now(),
      lastAccess: DateTime.now(),
    );
  }

  /// Verifica si una clave existe en el caché
  bool has(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    // Verificar si expiró
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Elimina una entrada del caché
  void remove(K key) {
    _cache.remove(key);
  }

  /// Limpia todo el caché
  void clear() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('🧹 Cache cleared');
    }
  }

  /// Elimina entradas expiradas
  void cleanExpired() {
    final now = DateTime.now();
    final expiredKeys = <K>[];

    _cache.forEach((key, entry) {
      if (now.difference(entry.timestamp) > _ttl) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('🧹 Removed ${expiredKeys.length} expired cache entries');
    }
  }

  /// Elimina la entrada menos usada
  void _evictLeastUsed() {
    if (_cache.isEmpty) return;

    K? leastUsedKey;
    int minAccessCount = double.maxFinite.toInt();

    _cache.forEach((key, entry) {
      if (entry.accessCount < minAccessCount) {
        minAccessCount = entry.accessCount;
        leastUsedKey = key;
      }
    });

    if (leastUsedKey != null) {
      _cache.remove(leastUsedKey);
      if (kDebugMode) {
        debugPrint('🧹 Evicted least used cache entry');
      }
    }
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getStats() {
    int totalAccesses = 0;
    DateTime? oldestEntry;
    DateTime? newestEntry;

    _cache.forEach((_, entry) {
      totalAccesses += entry.accessCount;
      
      if (oldestEntry == null || entry.timestamp.isBefore(oldestEntry!)) {
        oldestEntry = entry.timestamp;
      }
      
      if (newestEntry == null || entry.timestamp.isAfter(newestEntry!)) {
        newestEntry = entry.timestamp;
      }
    });

    return {
      'size': _cache.length,
      'maxSize': _maxSize,
      'totalAccesses': totalAccesses,
      'averageAccesses': _cache.isEmpty ? 0 : totalAccesses / _cache.length,
      'oldestEntry': oldestEntry?.toIso8601String(),
      'newestEntry': newestEntry?.toIso8601String(),
    };
  }
}

/// Entrada de caché con metadata
class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;
  DateTime lastAccess;
  int accessCount;

  _CacheEntry({
    required this.value,
    required this.timestamp,
    required this.lastAccess,
    this.accessCount = 0,
  });
}
