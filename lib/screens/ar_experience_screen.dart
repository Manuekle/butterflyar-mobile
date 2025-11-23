// lib/screens/ar_experience_screen.dart - Versión híbrida corregida
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gal/gal.dart';

// ⭐ AR Flutter Plugin para Android e iOS (ARCore)
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:butterflyar/models/butterfly.dart';
import 'package:butterflyar/utils/ar_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Audio y animaciones
  AudioPlayer? _audioPlayer;
  late AnimationController _slideController;
  late Animation<Offset> _slide;

  // ⭐ AR Flutter Plugin managers para Android e iOS
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  ARLocationManager? _arLocationManager;

  ARPlatformSupport _arSupport = ARPlatformSupport.none;
  bool _hasCameraPermission = false;
  bool _isARMode = true;
  bool _isDayBackground = true;
  bool _isModelSelected = false;
  bool _isModelLoaded = false;
  bool _planeDetected = false;

  // Variables para animaciones y control del modelo
  Timer? _idleAnimationTimer;
  double _modelRotationY = 0.0;
  double _idleFloatingOffset = 0.0;
  static const double _fixedScale = 0.003; // Escala fija optimizada

  // Referencias a nodos AR
  ARNode? _butterflyARNode; // ar_flutter_plugin (Android e iOS)
  final List<ARNode> _arNodes = []; // Lista de nodos AR
  late final Butterfly selectedButterfly = widget.butterfly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
    _initAnimations();
    _initializeApp();
  }

  void _initAudio() {
    _audioPlayer ??= AudioPlayer();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );
    _slideController.forward();
  }

  Future<void> _initializeApp() async {
    ARLogger.log('Inicializando aplicación AR...');

    await _detectARSupport();
    await _checkCameraPermission();
    await _playAmbientSound();

    // Siempre iniciar en modo sin AR para evitar redirección automática
    // El usuario puede cambiar manualmente si lo desea
    ARLogger.log('Iniciando en modo vista previa sin AR');
    setState(() => _isARMode = false);
  }

  Future<void> _detectARSupport() async {
    try {
      var support = await SimpleARSupport.detectARSupport();
      
      // ⭐ Verificación adicional: verificar ARCore en tiempo de ejecución
      if (support == ARPlatformSupport.arcore) {
        try {
          // Intentar verificar si ARCore está realmente disponible
          // El plugin ar_flutter_plugin verificará esto al crear la vista AR
          ARLogger.log('ARCore se verificará al crear la vista AR');
        } catch (e) {
          ARLogger.error('Error verificando ARCore', e);
          support = ARPlatformSupport.modelViewer;
        }
      }
      
      setState(() => _arSupport = support);
      ARLogger.log(
        'Soporte AR detectado: ${await SimpleARSupport.getARSupportInfo()}',
      );
    } catch (e) {
      ARLogger.error('Error detectando soporte AR', e);
      setState(() => _arSupport = ARPlatformSupport.modelViewer);
    }
  }

  Future<void> _checkCameraPermission() async {
    try {
      var status = await Permission.camera.status;

      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      final newPermissionState = status.isGranted;
      if (_hasCameraPermission != newPermissionState) {
        setState(() {
          _hasCameraPermission = newPermissionState;
          _shouldRebuildMainView = true; // ⭐ Forzar rebuild si cambió el permiso
        });
      }
      
      ARLogger.log(
        'Estado de permisos de cámara: ${status.toString().split('.').last}',
      );

      if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionSettingsDialog();
        }
      }
    } catch (e) {
      ARLogger.error('Error verificando permisos de cámara', e);
      if (_hasCameraPermission) {
        setState(() {
          _hasCameraPermission = false;
          _shouldRebuildMainView = true;
        });
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso de Cámara Requerido'),
        content: const Text(
          'Para usar la función de RA, necesitamos acceso a la cámara. '
          'Por favor, habilita el permiso en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  void _toggleARMode() {
    // Si está en modo AR, cambiar a vista previa (siempre permitido)
    if (_isARMode) {
      setState(() {
        _isARMode = false;
        _shouldRebuildMainView = true; // ⭐ Forzar rebuild de vista
      });
      HapticFeedback.selectionClick();
      return;
    }

    // Si intenta cambiar a modo AR, verificar disponibilidad
    final isARSupported = _arSupport == ARPlatformSupport.arcore;

    final hasRequiredModel = selectedButterfly.hasAndroidModel;

    // Verificar permisos de cámara
    if (!_hasCameraPermission) {
      _showPermissionSettingsDialog();
      return;
    }

    // Verificar si AR está disponible
    if (!isARSupported) {
      _showARNotAvailableDialog();
      return;
    }

    // Verificar si hay modelo disponible
    if (!hasRequiredModel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modelo 3D no disponible para AR en esta plataforma'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Todo OK, cambiar a modo AR
    setState(() {
      _isARMode = true;
      _shouldRebuildMainView = true; // ⭐ Forzar rebuild de vista
    });
    HapticFeedback.selectionClick();
  }

  /// ⭐ Diálogo mejorado para AR no disponible con opción de instalar ARCore
  void _showARNotAvailableDialog() {
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

    showDialog(
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
                _openARCoreInPlayStore();
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

  /// ⭐ Abre Google Play Store para instalar ARCore
  Future<void> _openARCoreInPlayStore() async {
    try {
      // URL de ARCore en Google Play Store
      const String arCorePackageId = 'com.google.ar.core';
      final Uri playStoreUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=$arCorePackageId',
      );

      ARLogger.log('Abriendo Play Store para instalar ARCore...');

      // Intentar abrir con la app de Play Store
      if (await canLaunchUrl(playStoreUrl)) {
        final launched = await launchUrl(
          playStoreUrl,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          ARLogger.success('Play Store abierta exitosamente');
          if (mounted) {
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
          throw Exception('No se pudo abrir Play Store');
        }
      } else {
        throw Exception('No se puede abrir la URL de Play Store');
      }
    } catch (e) {
      ARLogger.error('Error abriendo Play Store', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
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

  Future<void> _playAmbientSound() async {
    try {
      final soundPath = selectedButterfly.ambientSound;
      if (soundPath?.isNotEmpty ?? false) {
        await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer?.setVolume(0.3);

        final assetPath = soundPath!.startsWith('assets/')
            ? soundPath.substring(7)
            : soundPath;

        await _audioPlayer?.play(AssetSource(assetPath));
        ARLogger.log('Sonido ambiental iniciado');
      }
    } catch (e) {
      ARLogger.error('Error reproduciendo sonido ambiental', e);
    }
  }

  // ==================== AR MODEL LOADING ====================

  /// ⭐ CARGA MODELO GLB EN ARCORE (Android e iOS) usando ar_flutter_plugin
  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (_isModelLoaded || hitTestResults.isEmpty) {
      if (_isModelLoaded) {
        ARLogger.log('Modelo ya cargado, ignorando tap');
      }
      return;
    }

    if (_arObjectManager == null || _arAnchorManager == null) {
      ARLogger.error('Managers AR no inicializados');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: AR no está listo. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final singleHitTestResult = hitTestResults.firstWhere(
      (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    try {
      setState(() => _planeDetected = true);
      ARLogger.log('✅ Plano detectado en ARCore');

      final modelPath = selectedButterfly.modelAssetForARCore;
      if (modelPath == null || modelPath.isEmpty) {
        ARLogger.error('Sin modelo GLB disponible');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modelo 3D no disponible para esta mariposa'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // ⭐ Normalizar ruta del modelo (ar_flutter_plugin espera ruta relativa sin "assets/")
      String normalizedPath = modelPath;
      if (normalizedPath.startsWith('assets/')) {
        normalizedPath = normalizedPath.substring(7); // Remover "assets/"
      }
      ARLogger.log('Cargando modelo desde: $normalizedPath');

      // Crear anchor
      final newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      final didAddAnchor = await _arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        // Crear nodo con el modelo GLB desde assets
        final newNode = ARNode(
          type: NodeType.localGLTF2, // Usar localGLTF2 para archivos en assets
          uri: normalizedPath, // ⭐ Usar ruta normalizada
          scale: vector.Vector3.all(0.2), // Escala ajustada para mariposas
          position: vector.Vector3(0, 0, 0),
          rotation: vector.Vector4(1, 0, 0, 0),
        );

        final didAddNode = await _arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

        if (didAddNode == true) {
          _butterflyARNode = newNode;
          _arNodes.add(newNode);
          setState(() => _isModelLoaded = true);
          ARLogger.success('✅ Modelo GLB cargado exitosamente en ARCore');
          _showSuccessSnackbar();
        } else {
          ARLogger.error('Error al agregar nodo en ARCore - addNode retornó false');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al cargar el modelo. Intenta tocar otro plano.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ARLogger.error('Error al agregar anchor en ARCore - addAnchor retornó false');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear anchor. Intenta de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      ARLogger.error('Error cargando modelo en ARCore', e);
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ==================== USER INTERACTIONS ====================

  void _handleTap() {
    if (!_isARMode || !_isModelLoaded) return;

    setState(() => _isModelSelected = !_isModelSelected);
    HapticFeedback.lightImpact();

    if (_isModelSelected) {
      _stopIdleAnimation();
      _highlightButterfly();
    } else {
      _startIdleAnimation();
      _removeHighlight();
    }
  }

  void _highlightButterfly() {
    if (_butterflyARNode != null) {
      ARLogger.log('Mariposa seleccionada - lista para gestos de rotación');
    }
  }

  void _removeHighlight() {
    if (_butterflyARNode != null) {
      ARLogger.log('Mariposa deseleccionada');
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isModelSelected) return;

    final sensitivity = 0.01;
    final deltaX = details.delta.dx * sensitivity;
    _modelRotationY += deltaX;

    // Rotación con ar_flutter_plugin (Android e iOS)
    // Nota: La rotación puede requerir actualización del nodo AR
    // Por ahora, la rotación se maneja a través de gestos en la vista AR

    if (details.delta.dx.abs() > 2) {
      HapticFeedback.selectionClick();
    }
  }

  // ==================== ANIMATIONS ====================

  void _startIdleAnimation() {
    _stopIdleAnimation();

    // Animación idle con ar_flutter_plugin (Android e iOS)
    // Nota: Las animaciones pueden requerir actualización del nodo AR
    // Por ahora, las animaciones se manejan a través de la vista AR
    if (_butterflyARNode != null) {
      ARLogger.log('Animación idle iniciada');
    }
  }

  // ARCore animation method removed - Android uses Model Viewer only

  void _stopIdleAnimation() {
    _idleAnimationTimer?.cancel();
  }

  // ==================== AR VIEW BUILDERS ====================

  /// ⭐ VISTA AR PARA ANDROID E iOS usando ar_flutter_plugin
  Widget _buildARCoreView() {
    return ARView(
      onARViewCreated: _onARViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
    );
  }

  /// ⭐ Callback cuando se crea la vista AR en Android - Mejorado con manejo de errores
  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    try {
      _arSessionManager = arSessionManager;
      _arObjectManager = arObjectManager;
      _arAnchorManager = arAnchorManager;
      _arLocationManager = arLocationManager;

      // ⭐ Inicializar sesión AR con configuración optimizada
      _arSessionManager?.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handlePans: true,
        handleRotation: true,
      );

      // ⭐ Inicializar object manager
      _arObjectManager?.onInitialize();

      // ⭐ Configurar callback para cuando se toca un plano
      _arSessionManager?.onPlaneOrPointTap = _onPlaneOrPointTapped;

      ARLogger.success('✅ Vista ARCore creada exitosamente con ar_flutter_plugin');
      
      // Mostrar mensaje al usuario
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isModelLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mueve el dispositivo para detectar una superficie plana'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.blue,
              ),
            );
          }
        });
      }
    } catch (e, stackTrace) {
      ARLogger.error('Error inicializando vista ARCore', e);
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      
      // Si hay error, cambiar a Model Viewer
      if (mounted) {
        setState(() {
          _arSupport = ARPlatformSupport.modelViewer;
          _isARMode = false;
          _shouldRebuildMainView = true;
        });
        
        // Mostrar diálogo para instalar ARCore (solo Android)
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showARNotAvailableDialog();
            }
          });
        }
      }
    }
  }

  /// ⭐ VISTA ESTÁTICA MEJORADA CON MODEL VIEWER
  Widget _buildStaticView() {
    // Usar GLB para Model Viewer (mejor compatibilidad)
    final modelPath = selectedButterfly.modelAssetForModelViewer;

    final Widget modelContent = (modelPath?.isNotEmpty == true)
        ? Expanded(
            child: ModelViewer(
              backgroundColor: Colors.transparent,
              src: modelPath!, // GLB para Model Viewer
              alt: "Modelo 3D de ${selectedButterfly.name}",
              ar: false, // ⭐ DESHABILITADO para evitar conflictos
              autoRotate: true,
              cameraControls: true,
              autoPlay: true,
              loading: Loading.eager,
              disableZoom: false,
              // ⭐ CONFIGURACIONES ADICIONALES
              interactionPrompt: InteractionPrompt.none,
              disablePan: false,
            ),
          )
        : _buildNoModelAvailable();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            _isDayBackground
                ? 'assets/backgrounds/day.png'
                : 'assets/backgrounds/night.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [modelContent],
            ),
          ),
          _buildStaticViewControls(),
        ],
      ),
    );
  }

  Widget _buildNoModelAvailable() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.box, size: 64, color: Colors.white.withOpacity(0.7)),
        const SizedBox(height: 16),
        Text(
          'Modelo 3D no disponible',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Necesita archivo GLB para ARCore',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== UI COMPONENTS ====================

  Future<void> _captureScreen() async {
    try {
      // Nota: La captura de pantalla con ar_flutter_plugin puede requerir
      // implementación adicional. Por ahora, se deshabilita.
      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(
          content: Text('Captura de pantalla no disponible en este momento'),
        ));
      }
      return;

      // Código para captura futura con ar_flutter_plugin
      /*
      Uint8List? image;
      // Implementar captura con ar_flutter_plugin

      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo capturar la imagen')),
          );
        }
        return;
      }

      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();

        if (!hasAccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se necesita permiso para guardar la imagen en la galería',
                ),
              ),
            );
          }
          return;
        }
      }

      await Gal.putImageBytes(image, album: 'ButterflyAR');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Foto guardada en la galería!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al guardar la foto';

        if (e is GalException) {
          switch (e.type) {
            case GalExceptionType.accessDenied:
              errorMessage = 'Acceso denegado a la galería';
              break;
            case GalExceptionType.notEnoughSpace:
              errorMessage = 'No hay suficiente espacio en el dispositivo';
              break;
            case GalExceptionType.notSupportedFormat:
              errorMessage = 'Formato de imagen no soportado';
              break;
            case GalExceptionType.unexpected:
            default:
              errorMessage =
                  'Error inesperado: ${e.platformException.message ?? 'Desconocido'}';
              break;
          }
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      ARLogger.error('Error en _captureScreen', e);
      */
    } catch (e) {
      ARLogger.error('Error en _captureScreen', e);
    }
  }

  void _showSuccessSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Mariposa cargada! Toca para interactuar'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStaticViewControls() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingButton(
            icon: LucideIcons.info,
            onPressed: _showInfo,
            tooltip: 'Información',
          ),
          const SizedBox(height: 16),
          _buildFloatingButton(
            icon: _isDayBackground ? LucideIcons.sun : LucideIcons.moon,
            onPressed: () {
              setState(() => _isDayBackground = !_isDayBackground);
              HapticFeedback.lightImpact();
            },
            tooltip: _isDayBackground ? 'Modo noche' : 'Modo día',
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera, size: 48, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Permiso de cámara requerido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Necesitamos acceso a tu cámara para mostrar la experiencia de realidad aumentada.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Conceder Permiso'),
              onPressed: () async {
                final newStatus = await Permission.camera.request();
                if (newStatus.isGranted && mounted) {
                  setState(() => _hasCameraPermission = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  /// ⭐ PANEL DE INFORMACIÓN COMPLETA MEJORADO
  void _showInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(),
    );
  }

  Widget _buildInfoSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.white70 : Colors.black54;
    final sectionTitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2936) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de agarre
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con imagen y nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(selectedButterfly.imageAsset),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedButterfly.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedButterfly.scientificName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Espaciado
                  const SizedBox(height: 24),

                  // Descripción
                  if (selectedButterfly.description.isNotEmpty) ...[
                    Text(
                      'Descripción',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedButterfly.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Características
                  if (selectedButterfly.characteristics.isNotEmpty) ...[
                    Text(
                      'Características',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedButterfly.characteristics.map(
                      (characteristic) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 8),
                              child: Icon(
                                LucideIcons.check,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                characteristic,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: textColor.withOpacity(0.9),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hábitat
                  if (selectedButterfly.habitat.isNotEmpty) ...[
                    Text(
                      'Hábitat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green[900]!.withOpacity(0.2)
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.treePine,
                            color: Colors.green[isDark ? 300 : 700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedButterfly.habitat,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor.withOpacity(0.9),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Distribución
                  if (selectedButterfly.distribution.isNotEmpty) ...[
                    Text(
                      'Distribución',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[900]!.withOpacity(0.2)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.globe,
                            color: Colors.blue[isDark ? 300 : 700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedButterfly.distribution,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor.withOpacity(0.9),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MAIN BUILD ====================

  // ⭐ Memoizar la vista principal para evitar rebuilds innecesarios
  Widget? _cachedMainView;
  bool _shouldRebuildMainView = true;

  Widget _getMainView() {
    if (!_shouldRebuildMainView && _cachedMainView != null) {
      return _cachedMainView!;
    }

    Widget mainView;
    
    if (!_hasCameraPermission) {
      mainView = _buildNoPermissionView();
    } else if (_isARMode) {
      // Solo crear vista AR si realmente está en modo AR
      if (_arSupport == ARPlatformSupport.arcore &&
          selectedButterfly.hasAndroidModel) {
        mainView = _buildARCoreView();
      } else {
        // Fallback a Model Viewer si AR no está disponible
        mainView = _buildStaticView();
      }
    } else {
      mainView = _buildStaticView();
    }

    _cachedMainView = mainView;
    _shouldRebuildMainView = false;
    return mainView;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _getMainView(),

            _buildTopControls(),

            if (_isARMode && _arSupport == ARPlatformSupport.arcore)
              _buildARControls(),

            if (_isARMode &&
                !_isModelLoaded &&
                _arSupport == ARPlatformSupport.arcore)
              _buildARInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Atrás',
          ),
          // ⭐ BOTÓN PARA CAMBIAR ENTRE MODO AR Y VISTA PREVIA
          // Mostrar si AR está disponible (ARCore para Android e iOS)
          if (_arSupport == ARPlatformSupport.arcore &&
              selectedButterfly.hasAndroidModel &&
              _hasCameraPermission)
            _buildFloatingButton(
              icon: _isARMode ? LucideIcons.image : LucideIcons.box,
              onPressed: _toggleARMode,
              tooltip: _isARMode ? 'Vista previa' : 'Vista AR',
            ),
        ],
      ),
    );
  }

  Widget _buildARControls() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingButton(
            icon: LucideIcons.info,
            onPressed: _showInfo,
            tooltip: 'Información',
          ),
          const SizedBox(height: 16),
          _buildFloatingButton(
            icon: LucideIcons.camera,
            onPressed: _captureScreen,
            tooltip: 'Capturar',
          ),
        ],
      ),
    );
  }

  Widget _buildARInstructions() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _planeDetected
                      ? (_isModelLoaded
                            ? (_isModelSelected
                                  ? LucideIcons.rotate3d
                                  : LucideIcons.hand)
                            : LucideIcons.loader)
                      : LucideIcons.search,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _planeDetected
                      ? (_isModelLoaded
                            ? (_isModelSelected
                                  ? 'Arrastra para rotar'
                                  : 'Toca la mariposa para rotarla')
                            : 'Cargando mariposa...')
                      : 'Busca una superficie plana',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _planeDetected
                      ? (_isModelLoaded
                            ? (_isModelSelected
                                  ? 'Rota con el dedo para ver todos los ángulos'
                                  : 'Toca el plano para colocar la mariposa')
                            : 'Preparando experiencia AR...')
                      : 'Mueve tu dispositivo lentamente',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                if (!_isModelLoaded) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LIFECYCLE ====================

  Future<Uint8List?> _imageProviderToUint8List(
    ImageProvider imageProvider,
  ) async {
    try {
      final imageStream = imageProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<ui.Image>();

      final listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      });

      imageStream.addListener(listener);

      try {
        final image = await completer.future;
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        imageStream.removeListener(listener);
      }
    } catch (e) {
      debugPrint('Error converting image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    ARLogger.log('Cerrando experiencia AR');
    _stopIdleAnimation();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _slideController.dispose();
    
    // Limpiar recursos de ar_flutter_plugin
    _arSessionManager?.dispose();
    
    // ⭐ Limpiar cache de vista
    _cachedMainView = null;
    
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ARLogger.log('App resumed - rechecking permissions');
        _checkCameraPermission();
        _playAmbientSound();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        ARLogger.log('App paused/inactive - stopping animations and audio');
        _stopIdleAnimation();
        _audioPlayer?.pause();
        break;
      case AppLifecycleState.detached:
        ARLogger.log('App detached - cleanup');
        _audioPlayer?.stop();
        break;
    }
  }
}
