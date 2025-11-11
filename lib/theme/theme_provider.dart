import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider();

  ThemeMode get themeMode => _themeMode;

  // ⭐ Cache del estado de modo oscuro para evitar cálculos repetidos
  bool? _cachedIsDarkMode;
  Brightness? _lastSystemBrightness;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Obtener el brillo del sistema
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      
      // ⭐ Usar cache si el brillo del sistema no ha cambiado
      if (_lastSystemBrightness == brightness && _cachedIsDarkMode != null) {
        return _cachedIsDarkMode!;
      }
      
      _lastSystemBrightness = brightness;
      _cachedIsDarkMode = brightness == Brightness.dark;
      return _cachedIsDarkMode!;
    }
    
    // ⭐ Cache para modos fijos
    final isDark = _themeMode == ThemeMode.dark;
    if (_cachedIsDarkMode != isDark) {
      _cachedIsDarkMode = isDark;
    }
    return isDark;
  }

  String get currentThemeText {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      _cachedIsDarkMode = null; // ⭐ Limpiar cache al cambiar modo
      _lastSystemBrightness = null;
      notifyListeners();
    }
  }

  // Método de compatibilidad para código existente
  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  // Métodos de conveniencia
  Future<void> setLightTheme() async => await setThemeMode(ThemeMode.light);
  Future<void> setDarkTheme() async => await setThemeMode(ThemeMode.dark);
  Future<void> setSystemTheme() async => await setThemeMode(ThemeMode.system);

  // Alternar entre los tres modos
  Future<void> cycleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }
}
