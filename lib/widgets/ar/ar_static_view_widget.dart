// lib/widgets/ar/ar_static_view_widget.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/butterfly.dart';

/// Widget para vista estática con Model Viewer
///
/// Muestra el modelo 3D en modo de vista previa sin AR
class ARStaticViewWidget extends StatelessWidget {
  final Butterfly butterfly;
  final bool isDayBackground;

  const ARStaticViewWidget({
    super.key,
    required this.butterfly,
    this.isDayBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final modelPath = butterfly.modelAssetForModelViewer;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDayBackground
                ? 'assets/backgrounds/day.png'
                : 'assets/backgrounds/night.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: (modelPath?.isNotEmpty == true)
            ? ModelViewer(
                backgroundColor: Colors.transparent,
                src: modelPath!,
                alt: "Modelo 3D de ${butterfly.name}",
                ar: false,
                autoRotate: true,
                cameraControls: true,
                autoPlay: true,
                loading: Loading.lazy,
                disableZoom: false,
                interactionPrompt: InteractionPrompt.none,
                disablePan: false,
              )
            : _buildNoModelAvailable(context),
      ),
    );
  }

  Widget _buildNoModelAvailable(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.box, size: 64, color: Colors.white.withOpacity(0.7)),
        const SizedBox(height: 16),
        const Text(
          'Modelo 3D no disponible',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Necesita archivo GLB para visualización',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
