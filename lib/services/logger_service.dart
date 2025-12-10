// lib/services/logger_service.dart
import 'package:flutter/foundation.dart';

/// Niveles de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
}

/// Servicio de logging estructurado para la aplicación
/// 
/// Proporciona logging consistente con:
/// - Niveles de log (debug, info, warning, error, success)
/// - Formateo consistente con timestamps
/// - Control de visibilidad según modo debug
/// - Prefijos por categoría
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Configuración
  bool _enableDebugLogs = kDebugMode;
  bool _enableTimestamps = true;
  bool _enableEmojis = true;

  // Getters y setters
  bool get enableDebugLogs => _enableDebugLogs;
  set enableDebugLogs(bool value) => _enableDebugLogs = value;
  
  bool get enableTimestamps => _enableTimestamps;
  set enableTimestamps(bool value) => _enableTimestamps = value;
  
  bool get enableEmojis => _enableEmojis;
  set enableEmojis(bool value) => _enableEmojis = value;

  /// Log de debug (solo en modo debug)
  void debug(String message, {String? category}) {
    if (!_enableDebugLogs) return;
    _log(LogLevel.debug, message, category: category);
  }

  /// Log de información
  void info(String message, {String? category}) {
    _log(LogLevel.info, message, category: category);
  }

  /// Log de advertencia
  void warning(String message, {String? category}) {
    _log(LogLevel.warning, message, category: category);
  }

  /// Log de error
  void error(String message, {Object? error, StackTrace? stackTrace, String? category}) {
    _log(LogLevel.error, message, category: category);
    
    if (error != null) {
      debugPrint('  └─ Error details: $error');
    }
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('  └─ Stack trace:\n$stackTrace');
    }
  }

  /// Log de éxito
  void success(String message, {String? category}) {
    _log(LogLevel.success, message, category: category);
  }

  /// Método interno para logging
  void _log(LogLevel level, String message, {String? category}) {
    final buffer = StringBuffer();

    // Emoji según nivel
    if (_enableEmojis) {
      buffer.write(_getEmoji(level));
      buffer.write(' ');
    }

    // Timestamp
    if (_enableTimestamps) {
      final now = DateTime.now();
      buffer.write('[${_formatTime(now)}] ');
    }

    // Nivel
    buffer.write('[${_getLevelName(level)}]');

    // Categoría
    if (category != null) {
      buffer.write(' [$category]');
    }

    // Mensaje
    buffer.write(' $message');

    // Imprimir
    debugPrint(buffer.toString());
  }

  /// Obtiene el emoji para un nivel de log
  String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.success:
        return '✅';
    }
  }

  /// Obtiene el nombre del nivel de log
  String _getLevelName(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.success:
        return 'SUCCESS';
    }
  }

  /// Formatea el tiempo
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  /// Logs específicos por categoría

  // AR Logs
  void ar(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, category: 'AR');
  }

  void arDebug(String message) => ar(message, level: LogLevel.debug);
  void arInfo(String message) => ar(message, level: LogLevel.info);
  void arWarning(String message) => ar(message, level: LogLevel.warning);
  void arError(String message, {Object? error}) {
    ar(message, level: LogLevel.error);
    if (error != null) {
      debugPrint('  └─ Error details: $error');
    }
  }
  void arSuccess(String message) => ar(message, level: LogLevel.success);

  // Audio Logs
  void audio(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, category: 'Audio');
  }

  void audioDebug(String message) => audio(message, level: LogLevel.debug);
  void audioInfo(String message) => audio(message, level: LogLevel.info);
  void audioError(String message, {Object? error}) {
    audio(message, level: LogLevel.error);
    if (error != null) {
      debugPrint('  └─ Error details: $error');
    }
  }

  // Network Logs
  void network(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, category: 'Network');
  }

  void networkDebug(String message) => network(message, level: LogLevel.debug);
  void networkInfo(String message) => network(message, level: LogLevel.info);
  void networkError(String message, {Object? error}) {
    network(message, level: LogLevel.error);
    if (error != null) {
      debugPrint('  └─ Error details: $error');
    }
  }

  // UI Logs
  void ui(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, category: 'UI');
  }

  void uiDebug(String message) => ui(message, level: LogLevel.debug);
  void uiInfo(String message) => ui(message, level: LogLevel.info);
  void uiWarning(String message) => ui(message, level: LogLevel.warning);

  // Data Logs
  void data(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, category: 'Data');
  }

  void dataDebug(String message) => data(message, level: LogLevel.debug);
  void dataInfo(String message) => data(message, level: LogLevel.info);
  void dataError(String message, {Object? error}) {
    data(message, level: LogLevel.error);
    if (error != null) {
      debugPrint('  └─ Error details: $error');
    }
  }

  /// Limpia la configuración
  void reset() {
    _enableDebugLogs = kDebugMode;
    _enableTimestamps = true;
    _enableEmojis = true;
  }
}

// Instancia global para fácil acceso
final logger = LoggerService();
