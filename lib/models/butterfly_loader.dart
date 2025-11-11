import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'butterfly.dart';

/// ⭐ Carga todas las mariposas desde el archivo JSON centralizado - Optimizado
Future<List<Butterfly>> loadButterfliesFromAssets() async {
  try {
    debugPrint('🦋 Cargando mariposas desde el archivo JSON...');
    final String jsonString = await rootBundle.loadString(
      'lib/data/butterflies.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString) as Map<String, dynamic>;

    final butterfliesData = jsonData['butterflies'];
    if (butterfliesData == null) {
      debugPrint('❌ No se encontró la clave "butterflies" en el JSON');
      return [];
    }

    if (butterfliesData is! List) {
      debugPrint('❌ "butterflies" debe ser una lista');
      return [];
    }

    final List<dynamic> butterfliesJson = butterfliesData;
    final List<Butterfly> butterflies = [];
    
    // ⭐ Usar for loop para mejor manejo de errores individuales
    for (var i = 0; i < butterfliesJson.length; i++) {
      try {
        final json = butterfliesJson[i] as Map<String, dynamic>;
        butterflies.add(Butterfly.fromJson(json));
      } catch (e, stackTrace) {
        debugPrint('⚠️ Error cargando mariposa en índice $i: $e');
        if (kDebugMode) {
          debugPrint('Stack trace: $stackTrace');
        }
        // Continuar con las demás mariposas
      }
    }

    debugPrint('✅ Se cargaron ${butterflies.length} de ${butterfliesJson.length} especies de mariposas');
    return butterflies;
  } catch (e, stackTrace) {
    debugPrint('❌ Error al cargar las mariposas: $e');
    if (kDebugMode) {
      debugPrint('Stack trace: $stackTrace');
    }
    rethrow;
  }
}

/// Función de compatibilidad para código existente
@Deprecated('Use loadButterfliesFromAssets instead')
Future<List<Butterfly>> loadButterflies() async {
  return loadButterfliesFromAssets();
}
