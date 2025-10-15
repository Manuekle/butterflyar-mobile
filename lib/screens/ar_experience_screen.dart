// lib/screens/ar_experience_screen.dart - Versión híbrida corregida
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gal/gal.dart';

import 'package:arkit_plugin/arkit_plugin.dart';
// ARCore deshabilitado en Android - solo usar Model Viewer
// import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:butterflyar/models/butterfly.dart';
import 'package:butterflyar/utils/ar_helpers.dart';

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

  // Controllers AR
  ARKitController? _arkitController; // iOS
  // ArCoreController deshabilitado - Android usa solo Model Viewer

  ARPlatformSupport _arSupport = ARPlatformSupport.none;
  bool _hasCameraPermission = false;
  bool _isARMode = true;
  bool _isDayBackground = true;
  bool _isModelSelected = false;
  bool _showingInfo = false;
  bool _isModelLoaded = false;
  bool _planeDetected = false;

  // Variables para animaciones y control del modelo
  Timer? _idleAnimationTimer;
  double _modelRotationY = 0.0;
  double _idleFloatingOffset = 0.0;
  static const double _fixedScale = 0.003; // Escala fija optimizada

  // Referencias a nodos AR
  String? _currentARNodeName;
  ARKitNode? _butterflyNode; // iOS
  // ArCoreNode deshabilitado - Android usa solo Model Viewer
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

    // Verificar si el dispositivo soporta AR nativo
    final isARSupported =
        (Platform.isIOS && _arSupport == ARPlatformSupport.arkit) ||
        (Platform.isAndroid && _arSupport == ARPlatformSupport.arcore);

    // Verificar si tenemos los modelos necesarios para la plataforma
    final hasRequiredModel =
        (Platform.isIOS && selectedButterfly.hasIOSModel) ||
        (Platform.isAndroid && selectedButterfly.hasAndroidModel);

    // Siempre iniciar en modo sin AR para evitar redirección automática
    // El usuario puede cambiar manualmente si lo desea
    ARLogger.log('Iniciando en modo vista previa sin AR');
    setState(() => _isARMode = false);
  }

  Future<void> _detectARSupport() async {
    try {
      final support = await SimpleARSupport.detectARSupport();
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

      setState(() => _hasCameraPermission = status.isGranted);
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
      setState(() => _hasCameraPermission = false);
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
      setState(() => _isARMode = false);
      HapticFeedback.selectionClick();
      return;
    }

    // Si intenta cambiar a modo AR, verificar disponibilidad
    final isARSupported =
        (Platform.isIOS && _arSupport == ARPlatformSupport.arkit) ||
        (Platform.isAndroid && _arSupport == ARPlatformSupport.arcore);

    final hasRequiredModel =
        (Platform.isIOS && selectedButterfly.hasIOSModel) ||
        (Platform.isAndroid && selectedButterfly.hasAndroidModel);

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
    setState(() => _isARMode = true);
    HapticFeedback.selectionClick();
  }

  void _showARNotAvailableDialog() {
    String title = 'AR no disponible';
    String message =
        'La realidad aumentada no está disponible en este dispositivo.';

    if (Platform.isAndroid) {
      title = 'ARCore no disponible';
      message =
          'Tu dispositivo no tiene ARCore instalado o no es compatible.\n\n'
          'ARCore es necesario para la experiencia de realidad aumentada. '
          'Puedes continuar usando el modo de vista previa 3D.';
    } else if (Platform.isIOS) {
      title = 'ARKit no disponible';
      message =
          'Tu dispositivo no es compatible con ARKit o requiere una versión más reciente de iOS.\n\n'
          'Puedes continuar usando el modo de vista previa 3D.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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

  /// ⭐ CARGA MODELO SCN EN ARKIT (iOS)
  void _onAddAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor && !_isModelLoaded) {
      setState(() => _planeDetected = true);
      ARLogger.log('✅ Plano horizontal detectado en ARKit');

      final modelPath = selectedButterfly.modelAssetForARKit;
      if (modelPath == null || modelPath.isEmpty) {
        ARLogger.error('Sin modelo SCN para iOS');
        return;
      }

      final position = vector.Vector3(0, -0.1, -0.5);
      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      // ⭐ USAR SCN PARA ARKIT
      _butterflyNode = ARKitReferenceNode(
        url: modelPath, // Archivo SCN
        scale: vector.Vector3.all(_fixedScale),
        name: nodeName,
        position: position,
      );

      _arkitController?.add(_butterflyNode!);
      _currentARNodeName = nodeName;
      setState(() => _isModelLoaded = true);
      _startIdleAnimation();
      ARLogger.success('✅ Modelo SCN cargado exitosamente en ARKit');
      _showSuccessSnackbar();
    }
  }

  // ⭐ ARCORE DESHABILITADO EN ANDROID - Solo Model Viewer

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
    if (_butterflyNode != null) {
      ARLogger.log('Mariposa seleccionada - lista para gestos de rotación');
    }
  }

  void _removeHighlight() {
    if (_butterflyNode != null) {
      ARLogger.log('Mariposa deseleccionada');
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isModelSelected) return;

    final sensitivity = 0.01;
    final deltaX = details.delta.dx * sensitivity;
    _modelRotationY += deltaX;

    if (Platform.isIOS && _butterflyNode != null) {
      final rotationMatrix = vector.Matrix3.rotationY(_modelRotationY);
      _butterflyNode?.rotation = rotationMatrix;
    }
    // ARCore rotation disabled - Android uses Model Viewer

    if (details.delta.dx.abs() > 2) {
      HapticFeedback.selectionClick();
    }
  }

  // ==================== ANIMATIONS ====================

  void _startIdleAnimation() {
    _stopIdleAnimation();

    if (Platform.isIOS && _butterflyNode != null) {
      _idleAnimationTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (mounted && !_isModelSelected && _butterflyNode != null) {
          _idleFloatingOffset += 0.03;
          final floatingY = math.sin(_idleFloatingOffset) * 0.02;
          _butterflyNode?.position = vector.Vector3(
            _butterflyNode!.position.x,
            -0.1 + floatingY,
            _butterflyNode!.position.z,
          );
        }
      });
    }
    // ARCore animations disabled
  }

  // ARCore animation method removed - Android uses Model Viewer only

  void _stopIdleAnimation() {
    _idleAnimationTimer?.cancel();
  }

  // ==================== AR VIEW BUILDERS ====================

  Widget _buildARView() {
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: _handlePanUpdate,
      child: ARKitSceneView(
        onARKitViewCreated: (controller) {
          _arkitController = controller;
          ARLogger.success('Vista ARKit creada');
          controller.onAddNodeForAnchor = _onAddAnchor;
        },
        showFeaturePoints: false,
        showWorldOrigin: false,
        planeDetection: ARPlaneDetection.horizontal,
        autoenablesDefaultLighting: true,
        debug: false,
      ),
    );
  }

  // ARCore view removed - Android uses Model Viewer only

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
          Platform.isIOS
              ? 'Necesita archivo SCN para ARKit'
              : 'Necesita archivo GLB para ARCore',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== UI COMPONENTS ====================

  Future<void> _captureScreen() async {
    try {
      if (_arkitController == null) return;

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Capturando pantalla...')));
      }

      Uint8List? image;

      if (Platform.isIOS && _arkitController != null) {
        final imageProvider = await _arkitController?.snapshot();
        if (imageProvider != null) {
          image = await _imageProviderToUint8List(imageProvider);
        }
      }
      // ARCore screenshot disabled

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
    setState(() => _showingInfo = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(),
    ).then((_) => setState(() => _showingInfo = false));
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

  @override
  Widget build(BuildContext context) {
    // Determinar qué vista mostrar
    Widget mainView;
    
    if (!_hasCameraPermission) {
      mainView = _buildNoPermissionView();
    } else if (_isARMode) {
      // Solo crear vista AR si realmente está en modo AR
      if (Platform.isIOS &&
          _arSupport == ARPlatformSupport.arkit &&
          selectedButterfly.hasIOSModel) {
        mainView = _buildARView();
      } else {
        // Android siempre usa Model Viewer
        mainView = _buildStaticView();
      }
    } else {
      mainView = _buildStaticView();
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            mainView,

            _buildTopControls(),

            if (_isARMode &&
                Platform.isIOS &&
                _arSupport == ARPlatformSupport.arkit)
              _buildARControls(),

            if (_isARMode &&
                !_isModelLoaded &&
                Platform.isIOS &&
                _arSupport == ARPlatformSupport.arkit)
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
          // Solo mostrar en iOS donde ARKit está disponible
          if (Platform.isIOS &&
              _arSupport == ARPlatformSupport.arkit &&
              selectedButterfly.hasIOSModel &&
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
                                  : Platform.isIOS
                                  ? 'Toca para activar el modo rotación'
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
    _arkitController?.dispose();
    // _arcoreController deshabilitado
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
