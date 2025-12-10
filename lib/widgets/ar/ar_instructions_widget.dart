// lib/widgets/ar/ar_instructions_widget.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget para mostrar instrucciones AR
class ARInstructionsWidget extends StatelessWidget {
  final bool isModelLoaded;
  final bool planeDetected;

  const ARInstructionsWidget({
    super.key,
    this.isModelLoaded = false,
    this.planeDetected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isModelLoaded) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                planeDetected ? LucideIcons.check : LucideIcons.scan,
                color: planeDetected ? Colors.green : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                planeDetected
                    ? 'Toca la superficie para colocar la mariposa'
                    : 'Mueve el dispositivo para detectar una superficie',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
