// lib/models/butterfly.dart - Versión híbrida optimizada
class Butterfly {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String imageAsset;
  final String? modelAssetAndroid; // GLB para ARCore/Model Viewer
  final String? modelAssetIOS; // SCN para ARKit
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
    this.modelAssetAndroid, // GLB
    this.modelAssetIOS, // SCN
    this.ambientSound,
    this.characteristics = const [],
    this.habitat = '',
    this.distribution = '',
  });

  // ⭐ GETTERS ESPECÍFICOS POR PLATAFORMA

  /// Para ARKit (iOS) - usa SCN
  String? get modelAssetForARKit => modelAssetIOS;

  /// Para ARCore (Android) - usa GLB
  String? get modelAssetForARCore => modelAssetAndroid;

  /// Para Model Viewer (fallback) - usa GLB
  String? get modelAssetForModelViewer => modelAssetAndroid;

  /// Getter genérico que decide según la plataforma
  String? get modelAsset {
    // En tiempo de ejecución, Platform.isIOS decidirá
    // Pero para JSON serialization, retornamos el GLB por defecto
    return modelAssetAndroid ?? modelAssetIOS;
  }

  // ⭐ VALIDACIONES
  bool get hasIOSModel => modelAssetIOS?.isNotEmpty == true;
  bool get hasAndroidModel => modelAssetAndroid?.isNotEmpty == true;
  bool get hasAnyModel => hasIOSModel || hasAndroidModel;

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

  // Create from JSON map
  factory Butterfly.fromJson(Map<String, dynamic> json) {
    return Butterfly(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      scientificName: json['scientificName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageAsset: json['imageAsset'] as String? ?? '',
      modelAssetAndroid: json['modelAssetAndroid'] as String?,
      modelAssetIOS: json['modelAssetIOS'] as String?,
      ambientSound: json['ambientSound'] as String?,
      characteristics: List<String>.from(json['characteristics'] ?? []),
      habitat: json['habitat'] as String? ?? '',
      distribution: json['distribution'] as String? ?? '',
    );
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
