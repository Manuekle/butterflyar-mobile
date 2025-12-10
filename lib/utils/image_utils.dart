// lib/utils/image_utils.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Utilidades para optimización de imágenes
class ImageUtils {
  /// Precarga imágenes para evitar lag
  static Future<void> precacheImages(
    BuildContext context,
    List<String> assetPaths,
  ) async {
    for (final path in assetPaths) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (e) {
        debugPrint('⚠️ Error precaching image $path: $e');
      }
    }
  }

  /// Comprime una imagen
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Decodificar imagen
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Redimensionar si es necesario
      img.Image resized = image;
      if (maxWidth != null || maxHeight != null) {
        resized = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
        );
      }

      // Comprimir
      final compressed = img.encodeJpg(resized, quality: quality);
      
      debugPrint(
        '📸 Image compressed: ${imageBytes.length} → ${compressed.length} bytes '
        '(${((1 - compressed.length / imageBytes.length) * 100).toStringAsFixed(1)}% reduction)',
      );

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return null;
    }
  }

  /// Obtiene el tamaño de una imagen asset
  static Future<int?> getAssetSize(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.lengthInBytes;
    } catch (e) {
      debugPrint('❌ Error getting asset size for $assetPath: $e');
      return null;
    }
  }

  /// Verifica si una imagen es muy grande
  static Future<bool> isImageTooLarge(
    String assetPath, {
    int maxSizeBytes = 5 * 1024 * 1024, // 5MB por defecto
  }) async {
    final size = await getAssetSize(assetPath);
    if (size == null) return false;
    return size > maxSizeBytes;
  }

  /// Obtiene información de una imagen
  static Future<Map<String, dynamic>?> getImageInfo(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      return {
        'width': image.width,
        'height': image.height,
        'size': bytes.length,
        'format': _getImageFormat(assetPath),
      };
    } catch (e) {
      debugPrint('❌ Error getting image info for $assetPath: $e');
      return null;
    }
  }

  static String _getImageFormat(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'JPEG';
    if (path.endsWith('.png')) return 'PNG';
    if (path.endsWith('.webp')) return 'WebP';
    if (path.endsWith('.gif')) return 'GIF';
    return 'Unknown';
  }
}

/// Widget para carga lazy de imágenes
class LazyImage extends StatefulWidget {
  final String assetPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      await precacheImage(AssetImage(widget.assetPath), context);
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      debugPrint('❌ Error loading image ${widget.assetPath}: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline),
          );
    }

    if (!_isLoaded) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    return Image.asset(
      widget.assetPath,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
  }
}
