// lib/widgets/ar/ar_dialogs.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diálogos reutilizables para la experiencia AR
class ARDialogs {
  /// Muestra un diálogo cuando AR no está disponible
  static Future<void> showARNotAvailableDialog(
    BuildContext context, {
    VoidCallback? onInstallARCore,
  }) async {
    String title = 'AR no disponible';
    String message =
        'La realidad aumentada no está disponible en este dispositivo.';
    bool showInstallButton = false;

    if (Platform.isAndroid) {
      title = 'ARCore no disponible';
      message =
          'Tu dispositivo no tiene ARCore instalado o no es compatible.\n\n'
          'ARCore (Google Play Services for AR) es necesario para la experiencia de realidad aumentada.\n\n'
          '¿Deseas instalar ARCore desde Google Play Store?';
      showInstallButton = true;
    } else if (Platform.isIOS) {
      title = 'ARCore no disponible';
      message =
          'Tu dispositivo no es compatible con ARCore o requiere una versión más reciente de iOS (11.0+).\n\n'
          'Puedes continuar usando el modo de vista previa 3D.';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              LucideIcons.info,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (showInstallButton)
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Instalar ARCore'),
              onPressed: () {
                Navigator.pop(context);
                onInstallARCore?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
        ],
      ),
    );
  }

  /// Abre Google Play Store para instalar ARCore
  static Future<void> openARCoreInPlayStore(BuildContext context) async {
    try {
      const String arCorePackageId = 'com.google.ar.core';
      final Uri playStoreUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=$arCorePackageId',
      );

      if (await canLaunchUrl(playStoreUrl)) {
        final launched = await launchUrl(
          playStoreUrl,
          mode: LaunchMode.externalApplication,
        );

        if (launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Después de instalar ARCore, reinicia la aplicación para usar AR',
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        throw Exception('No se puede abrir la URL de Play Store');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error al abrir Play Store. Busca "Google Play Services for AR" manualmente.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Muestra un diálogo de permisos de cámara denegados
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso de Cámara Requerido'),
        content: const Text(
          'Para usar la función de Realidad Aumentada, necesitamos acceso a la cámara. '
          'Por favor, habilita el permiso en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // El servicio de permisos manejará la apertura de configuración
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación genérico
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de error genérico
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de éxito genérico
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
