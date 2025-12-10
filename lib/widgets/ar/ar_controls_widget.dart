// lib/widgets/ar/ar_controls_widget.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget para controles AR
/// 
/// Proporciona botones para:
/// - Captura de pantalla
/// - Cambio de modo AR/Vista previa
/// - Cambio de fondo día/noche
/// - Navegación
class ARControlsWidget extends StatelessWidget {
  final VoidCallback? onCapture;
  final VoidCallback? onToggleARMode;
  final VoidCallback? onToggleBackground;
  final VoidCallback? onBack;
  final bool isARMode;
  final bool isDayBackground;
  final bool isModelLoaded;
  final bool canUseAR;

  const ARControlsWidget({
    super.key,
    this.onCapture,
    this.onToggleARMode,
    this.onToggleBackground,
    this.onBack,
    this.isARMode = false,
    this.isDayBackground = true,
    this.isModelLoaded = false,
    this.canUseAR = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _buildFloatingButton(
                  icon: LucideIcons.arrowLeft,
                  onPressed: onBack,
                  tooltip: 'Volver',
                ),
                
                // AR mode toggle
                if (canUseAR)
                  _buildFloatingButton(
                    icon: isARMode ? LucideIcons.eye : LucideIcons.scan,
                    onPressed: onToggleARMode,
                    tooltip: isARMode ? 'Vista Previa' : 'Modo AR',
                    isActive: isARMode,
                  ),
              ],
            ),
            
            const Spacer(),
            
            // Bottom controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Background toggle (only in preview mode)
                if (!isARMode)
                  _buildFloatingButton(
                    icon: isDayBackground ? LucideIcons.sun : LucideIcons.moon,
                    onPressed: onToggleBackground,
                    tooltip: isDayBackground ? 'Modo Noche' : 'Modo Día',
                  )
                else
                  const SizedBox(width: 56),
                
                // Capture button
                _buildFloatingButton(
                  icon: LucideIcons.camera,
                  onPressed: isModelLoaded ? onCapture : null,
                  tooltip: 'Capturar',
                  isPrimary: true,
                ),
                
                const SizedBox(width: 56), // Spacer for symmetry
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    VoidCallback? onPressed,
    required String tooltip,
    bool isActive = false,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.blue
              : isActive
                  ? Colors.blue.withOpacity(0.9)
                  : Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
