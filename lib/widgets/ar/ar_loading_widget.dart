// lib/widgets/ar/ar_loading_widget.dart
import 'package:flutter/material.dart';

/// Widget para mostrar estado de carga en AR
class ARLoadingWidget extends StatelessWidget {
  final String message;

  const ARLoadingWidget({
    super.key,
    this.message = 'Cargando experiencia AR...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
