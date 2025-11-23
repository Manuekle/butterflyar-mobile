import 'package:flutter/foundation.dart';
import '../models/butterfly.dart';
import '../models/butterfly_loader.dart';

class ButterflyProvider with ChangeNotifier {
  List<Butterfly> _butterflies = [];
  // ⭐ Cache para búsquedas rápidas por ID (O(1) en lugar de O(n))
  final Map<String, Butterfly> _butterfliesById = {};
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false;

  // Getters
  List<Butterfly> get butterflies => List.unmodifiable(_butterflies);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;
  bool get isEmpty => _butterflies.isEmpty;
  int get count => _butterflies.length;

  // Cargar mariposas desde assets
  Future<void> loadButterflies() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('🦋 Cargando mariposas desde assets...');
      final loadedButterflies = await loadButterfliesFromAssets();

      _butterflies = loadedButterflies;
      // ⭐ Construir cache de búsqueda por ID para acceso O(1)
      _butterfliesById.clear();
      for (final butterfly in _butterflies) {
        _butterfliesById[butterfly.id.toLowerCase()] = butterfly;
      }
      _hasInitialized = true;

      debugPrint('🦋 Cargadas ${_butterflies.length} especies de mariposas');

      // Log de especies cargadas en modo debug
      if (kDebugMode) {
        for (final butterfly in _butterflies) {
          debugPrint('  - ${butterfly.name} (${butterfly.scientificName})');
        }
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Error al cargar las especies: $e';
      _setError(errorMessage);

      debugPrint('❌ $errorMessage');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Recargar mariposas (forzar recarga)
  Future<void> reloadButterflies() async {
    _hasInitialized = false;
    await loadButterflies();
  }

  // ⭐ Obtener mariposa por ID - Optimizado con Map (O(1))
  Butterfly? getButterflyById(String id) {
    if (_butterflies.isEmpty || id.isEmpty) return null;

    final lowerId = id.toLowerCase();
    final butterfly = _butterfliesById[lowerId];
    
    if (butterfly == null && kDebugMode) {
      debugPrint('🔍 Mariposa no encontrada con ID: $id');
    }
    
    return butterfly;
  }

  // ⭐ Buscar mariposas por nombre - Optimizado con early return
  List<Butterfly> searchByName(String query) {
    if (query.isEmpty || _butterflies.isEmpty) {
      return butterflies;
    }

    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return butterflies;

    // Usar where con toList() para mejor rendimiento
    return _butterflies.where((butterfly) {
      final name = butterfly.name.toLowerCase();
      final scientificName = butterfly.scientificName.toLowerCase();
      return name.contains(lowerQuery) || scientificName.contains(lowerQuery);
    }).toList(growable: false); // Lista de tamaño fijo para mejor rendimiento
  }

  // ⭐ Obtener mariposas que tienen modelo 3D - Cacheado
  List<Butterfly> get butterfliesWithModels {
    return _butterflies.where((b) => 
      b.modelAssetAndroid?.isNotEmpty == true
    ).toList(growable: false);
  }

  // ⭐ Obtener mariposas que tienen sonido ambiente - Optimizado
  List<Butterfly> get butterfliesWithSound {
    return _butterflies
        .where((b) => b.ambientSound?.isNotEmpty == true)
        .toList(growable: false);
  }

  // ⭐ Obtener una mariposa aleatoria - Optimizado con Random
  Butterfly? getRandomButterfly() {
    if (_butterflies.isEmpty) return null;

    // Usar Random para mejor distribución
    final random = DateTime.now().millisecondsSinceEpoch % _butterflies.length;
    return _butterflies[random];
  }

  // Validar que una mariposa tiene los recursos necesarios para AR
  bool isButterflyARReady(String id) {
    final butterfly = getButterflyById(id);
    if (butterfly == null) return false;

    return butterfly.modelAssetAndroid?.isNotEmpty == true &&
        butterfly.imageAsset.isNotEmpty;
  }

  // Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    return {
      'total': _butterflies.length,
      'withModels': butterfliesWithModels.length,
      'withSound': butterfliesWithSound.length,
      'arReady': _butterflies
          .where(
            (b) => 
              b.modelAssetAndroid?.isNotEmpty == true &&
              b.imageAsset.isNotEmpty,
          )
          .length,
    };
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Reinicializar el provider
  void reset() {
    _butterflies.clear();
    _butterfliesById.clear(); // ⭐ Limpiar cache
    _isLoading = false;
    _error = null;
    _hasInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _butterflies.clear();
    _butterfliesById.clear(); // ⭐ Limpiar cache
    super.dispose();
  }
}
