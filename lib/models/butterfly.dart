// lib/models/butterfly.dart - Versión híbrida optimizada
class Butterfly {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String imageAsset;
  final String? modelAssetAndroid; // GLB para ARCore (Android e iOS)
  final String? modelAssetIOS; // Deprecated - usar modelAssetAndroid
  final String? ambientSound;
  final List<String> characteristics;
  final String habitat;
  final String distribution;

  const Butterfly({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.imageAsset,
    this.modelAssetAndroid, // GLB para Android e iOS
    this.modelAssetIOS, // Deprecated
    this.ambientSound,
    this.characteristics = const [],
    this.habitat = '',
    this.distribution = '',
  });

  // ⭐ GETTERS ESPECÍFICOS POR PLATAFORMA

  /// Para ARCore (Android e iOS) - usa GLB
  String? get modelAssetForARCore => modelAssetAndroid;

  /// Para Model Viewer (fallback) - usa GLB
  String? get modelAssetForModelViewer => modelAssetAndroid;

  /// Getter genérico - usa GLB
  String? get modelAsset => modelAssetAndroid;

  // ⭐ VALIDACIONES
  @Deprecated('Usar hasAndroidModel en su lugar')
  bool get hasIOSModel => modelAssetAndroid?.isNotEmpty == true;
  bool get hasAndroidModel => modelAssetAndroid?.isNotEmpty == true;
  bool get hasAnyModel => hasAndroidModel;

  // Helper method to create a copy with some fields overridden
  Butterfly copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? description,
    String? imageAsset,
    String? modelAssetAndroid,
    String? modelAssetIOS,
    String? ambientSound,
    List<String>? characteristics,
    String? habitat,
    String? distribution,
  }) {
    return Butterfly(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      imageAsset: imageAsset ?? this.imageAsset,
      modelAssetAndroid: modelAssetAndroid ?? this.modelAssetAndroid,
      modelAssetIOS: modelAssetIOS ?? this.modelAssetIOS,
      ambientSound: ambientSound ?? this.ambientSound,
      characteristics: characteristics ?? this.characteristics,
      habitat: habitat ?? this.habitat,
      distribution: distribution ?? this.distribution,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'imageAsset': imageAsset,
      'modelAssetAndroid': modelAssetAndroid,
      'modelAssetIOS': modelAssetIOS,
      'ambientSound': ambientSound,
      'characteristics': characteristics,
      'habitat': habitat,
      'distribution': distribution,
    };
  }

  // ⭐ Create from JSON map - Optimizado con validaciones
  factory Butterfly.fromJson(Map<String, dynamic> json) {
    // Validar campos requeridos
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Butterfly ID is required and cannot be empty');
    }

    return Butterfly(
      id: id,
      name: json['name'] as String? ?? 'Unknown',
      scientificName: json['scientificName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageAsset: json['imageAsset'] as String? ?? '',
      modelAssetAndroid: _normalizeAssetPath(json['modelAssetAndroid'] as String?),
      modelAssetIOS: _normalizeAssetPath(json['modelAssetIOS'] as String?),
      ambientSound: _normalizeAssetPath(json['ambientSound'] as String?),
      characteristics: List<String>.from(json['characteristics'] ?? [], growable: false),
      habitat: json['habitat'] as String? ?? '',
      distribution: json['distribution'] as String? ?? '',
    );
  }

  // ⭐ Normalizar rutas de assets (eliminar espacios y validar)
  static String? _normalizeAssetPath(String? path) {
    if (path == null) return null;
    final normalized = path.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  String toString() {
    return 'Butterfly(id: $id, name: $name, iOS: $hasIOSModel, Android: $hasAndroidModel)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Butterfly && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
