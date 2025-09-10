// lib/screens/ar_experience_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
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
  ArCoreController? _arcoreController; // Android

  ARPlatformSupport _arSupport = ARPlatformSupport.none;
  bool _hasCameraPermission = false;
  bool _isARMode = true;
  bool _isDayBackground = true;
  bool _isModelSelected = false;
  bool _showingInfo = false;
  bool _isModelLoaded = false;
  bool _planeDetected = false;

  // Variables para animaciones y control del modelo
  Timer? _rotationTimer;
  Timer? _floatingTimer;
  double _modelRotation = 0.0;
  double _floatingOffset = 0.0;

  double _currentScale = 0.02; // Variable para la escala actual

  // Variables para animaciones y control del modelo
  Timer? _idleAnimationTimer; // Solo animación idle
  double _modelRotationY = 0.0; // Rotación controlada por usuario
  double _idleFloatingOffset = 0.0; // Solo para animación de flotación idle
  static const double _fixedScale =
      0.003; // ⭐ ESCALA FIJA BASADA EN TUS PRUEBAS

  // Referencias a nodos AR
  String? _currentARNodeName;
  ARKitNode? _butterflyNode; // iOS
  ArCoreNode? _butterflyARCoreNode; // Android
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

    if ((Platform.isIOS && _arSupport == ARPlatformSupport.arkit) ||
        (Platform.isAndroid && _arSupport == ARPlatformSupport.arcore)) {
      if (_hasCameraPermission) {
        ARLogger.success('Dispositivo listo para AR nativa');
      } else {
        ARLogger.log('Sin permisos de cámara, usando modo vista previa');
        setState(() => _isARMode = false);
      }
    } else {
      ARLogger.log('AR nativa no disponible, usando Model Viewer');
      setState(() => _isARMode = false);
    }
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

  // Esta función ahora solo es llamada para reintentar la carga.
  // La carga inicial se hará cuando se detecte un plano.
  Future<void> _loadButterflyModel() async {
    // La lógica de carga inicial se movió a _onAddAnchor y _onARCorePlaneTap
  }

  // ==================== ANIMATIONS ====================

  void _startButterflyAnimations() {
    _stopAutoAnimations();

    // Simplemente giramos el modelo lentamente
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted &&
          !_isModelSelected &&
          (_butterflyNode != null || _butterflyARCoreNode != null)) {
        _modelRotation += 0.005; // Rotación más lenta
        if (Platform.isIOS && _butterflyNode != null) {
          _butterflyNode?.rotation = vector.Matrix3.rotationY(_modelRotation);
        }
        // Para ARCore se maneja diferente la rotación en _startIdleAnimationARCore
      }
    });

    // La animación de flotación se puede simplificar
    _floatingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted &&
          !_isModelSelected &&
          (_butterflyNode != null || _butterflyARCoreNode != null)) {
        _floatingOffset += 0.05;
        final floatingY =
            math.sin(_floatingOffset) * 0.03; // Flotación más sutil
        if (Platform.isIOS && _butterflyNode != null) {
          _butterflyNode?.position.y = floatingY;
        }
        // Para ARCore se maneja diferente la flotación en _startIdleAnimationARCore
      }
    });
  }

  void _stopAutoAnimations() {
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();
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
    if (_butterflyNode != null || _butterflyARCoreNode != null) {
      // Solo cambiar el brillo/material, NO la escala
      // Para ARKit/ARCore podríamos añadir un efecto de brillo aquí si fuera necesario
      ARLogger.log('Mariposa seleccionada - lista para gestos de rotación');
    }
  }

  void _removeHighlight() {
    if (_butterflyNode != null || _butterflyARCoreNode != null) {
      // Restaurar material original si fuera necesario
      ARLogger.log('Mariposa deseleccionada');
    }
  }

  Future<void> _captureScreen() async {
    try {
      if (_arkitController == null && _arcoreController == null) return;

      // Mostrar retroalimentación táctil
      HapticFeedback.mediumImpact();

      // Mostrar mensaje de carga
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Capturando pantalla...')));
      }

      Uint8List? image;

      // Tomar la captura de pantalla según la plataforma
      if (Platform.isIOS && _arkitController != null) {
        final imageProvider = await _arkitController?.snapshot();
        if (imageProvider != null) {
          image = await _imageProviderToUint8List(imageProvider);
        }
      } else if (Platform.isAndroid && _arcoreController != null) {
        // ARCore plugin might have different snapshot method
        // This is a placeholder - check the actual ARCore plugin documentation
        try {
          // Placeholder for ARCore screenshot
          ARLogger.log('Captura de pantalla ARCore no implementada aún');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Captura en ARCore próximamente')),
            );
          }
          return;
        } catch (e) {
          ARLogger.error('Error en captura ARCore', e);
        }
      }

      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo capturar la imagen')),
          );
        }
        return;
      }

      // Solicitar permiso de almacenamiento si es necesario
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se necesita permiso para guardar la imagen'),
              ),
            );
          }
          return;
        }
      }

      // Guardar la imagen en la galería
      final result = await ImageGallerySaver.saveImage(
        image,
        quality: 100,
        name: 'butterfly_ar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (result['isSuccess'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Foto guardada en la galería!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar la foto')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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

  // ==================== GESTURE HANDLING ====================

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isModelSelected) return;

    // Convertir el movimiento del dedo a rotación
    final sensitivity = 0.01;
    final deltaX = details.delta.dx * sensitivity;

    // Solo rotar en Y (horizontal)
    _modelRotationY += deltaX;

    // Aplicar la rotación al modelo manteniendo la escala fija
    if (Platform.isIOS && _butterflyNode != null) {
      final rotationMatrix = vector.Matrix3.rotationY(_modelRotationY);
      _butterflyNode?.rotation = rotationMatrix;
    } else if (Platform.isAndroid && _butterflyARCoreNode != null) {
      // Para ARCore, la rotación se maneja diferente
      // Esto es un placeholder - verificar documentación de ARCore plugin
      // _butterflyARCoreNode?.rotation = vector.Vector4(0, _modelRotationY, 0, 1);
    }

    // Opcional: Feedback háptico suave durante la rotación
    if (details.delta.dx.abs() > 2) {
      HapticFeedback.selectionClick();
    }
  }

  // ==================== AR VIEW BUILDERS ====================

  Widget _buildARView() {
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: _handlePanUpdate, // ⭐ AÑADIR GESTOS DE ARRASTRE
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

  Widget _buildARCoreView() {
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: _handlePanUpdate,
      child: ArCoreView(
        onArCoreViewCreated: (controller) {
          _arcoreController = controller;
          ARLogger.success('Vista ARCore creada');
          controller.onPlaneDetected = _onARCorePlaneDetected;
          controller.onPlaneTap = _onARCorePlaneTap;
        },
        enableTapRecognizer: true,
      ),
    );
  }

  // ==================== AR VIEW BUILDERS END ====================

  // ==================== AR LOGIC iOS ====================

  // ALTERNATIVA: COLOCAR EN EL PLANO DETECTADO
  void _onAddAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor && !_isModelLoaded) {
      setState(() => _planeDetected = true);
      ARLogger.log('✅ Plano horizontal detectado en ARKit');

      final position = vector.Vector3(0, -0.1, -0.5); // Posición más cercana
      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      _butterflyNode = ARKitReferenceNode(
        url: selectedButterfly.modelAssetIOS!,
        scale: vector.Vector3.all(_fixedScale), // ⭐ ESCALA FIJA
        name: nodeName,
        position: position,
      );

      _arkitController?.add(_butterflyNode!);
      _currentARNodeName = nodeName;
      setState(() => _isModelLoaded = true);
      _startIdleAnimation(); // Solo animación idle
      ARLogger.success('✅ Mariposa cargada y colocada exitosamente en ARKit');
      _showSuccessSnackbar();
    }
  }

  // ==================== AR LOGIC Android ====================

  void _onARCorePlaneDetected(ArCorePlane plane) {
    setState(() => _planeDetected = true);
    ARLogger.log('✅ Plano detectado en ARCore');
  }

  void _onARCorePlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isNotEmpty && !_isModelLoaded) {
      final hit = hits.first;
      _loadARCoreModel(hit);
    }
  }

  Future<void> _loadARCoreModel(ArCoreHitTestResult hit) async {
    try {
      final position = hit.pose.translation;
      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      _butterflyARCoreNode = ArCoreReferenceNode(
        name: nodeName,
        objectUrl: selectedButterfly.modelAssetAndroid!,
        position: vector.Vector3(position.x, position.y, position.z),
        scale: vector.Vector3.all(_fixedScale),
      );

      await _arcoreController?.addArCoreNode(_butterflyARCoreNode!);
      _currentARNodeName = nodeName;
      setState(() => _isModelLoaded = true);
      _startIdleAnimationARCore();
      ARLogger.success('✅ Mariposa cargada en ARCore');
      _showSuccessSnackbar();
    } catch (e) {
      ARLogger.error('Error cargando modelo en ARCore', e);
    }
  }

  void _startIdleAnimationARCore() {
    _stopIdleAnimation();

    _idleAnimationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted || _isModelSelected || _butterflyARCoreNode == null) {
        return;
      }

      _idleFloatingOffset += 0.03;
      final floatingY = math.sin(_idleFloatingOffset) * 0.02;

      // Get current position and create new position with floating offset
      final currentPos = _butterflyARCoreNode!.position;
      if (currentPos != null) {
        final newPosition = vector.Vector3(
          currentPos.value.x,
          currentPos.value.y + floatingY,
          currentPos.value.z,
        );

        // Create a new node at the updated position
        final newNode = ArCoreReferenceNode(
          name: _butterflyARCoreNode!.name,
          objectUrl: selectedButterfly.modelAssetAndroid!,
          position: newPosition,
          scale: _butterflyARCoreNode!.scale?.value ?? vector.Vector3.all(1.0),
          rotation:
              _butterflyARCoreNode!.rotation?.value ??
              vector.Vector4(0, 0, 0, 1),
        );

        // Remove the old node and add the new one
        _arcoreController?.removeNode(nodeName: _butterflyARCoreNode!.name);
        _arcoreController?.addArCoreNode(newNode);
        _butterflyARCoreNode = newNode;
      }
    });
  }

  // ==================== AR LOGIC END ====================

  // ==================== ANIMATIONS ====================

  void _startIdleAnimation() {
    _stopIdleAnimation();

    if (Platform.isIOS && _butterflyNode != null) {
      // Solo flotación suave cuando NO está seleccionada para ARKit
      _idleAnimationTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (mounted && !_isModelSelected && _butterflyNode != null) {
          _idleFloatingOffset += 0.03;
          final floatingY =
              math.sin(_idleFloatingOffset) * 0.02; // Flotación muy sutil
          _butterflyNode?.position = vector.Vector3(
            _butterflyNode!.position.x,
            -0.1 + floatingY, // Mantener posición base + flotación
            _butterflyNode!.position.z,
          );
        }
      });
    } else if (Platform.isAndroid && _butterflyARCoreNode != null) {
      // Para ARCore usar el método específico
      _startIdleAnimationARCore();
    }
  }

  void _stopIdleAnimation() {
    _idleAnimationTimer?.cancel();
  }

  // ==================== USER INTERACTIONS ====================

  Widget _buildStaticView() {
    final modelPath = selectedButterfly.modelAssetAndroid;

    final Widget modelContent = modelPath != null && modelPath.isNotEmpty
        ? Expanded(
            child: ModelViewer(
              backgroundColor: Colors.transparent,
              src: modelPath,
              alt: "Modelo 3D de ${selectedButterfly.name}",
              ar: false,
              autoRotate: true,
              cameraControls: true,
              autoPlay: true,
              loading: Loading.eager,
              disableZoom: false,
            ),
          )
        : Column(
            children: [
              Icon(
                _arSupport == ARPlatformSupport.none
                    ? Icons.phone_android
                    : LucideIcons.box,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _arSupport == ARPlatformSupport.none
                    ? 'Vista previa 3D'
                    : 'Modelo 3D',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _arSupport == ARPlatformSupport.arkit
                    ? 'Toca el botón AR para realidad aumentada'
                    : _arSupport == ARPlatformSupport.arcore
                    ? 'Toca el botón AR para realidad aumentada'
                    : 'AR no soportado en este dispositivo',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          );

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

  // ==================== UI COMPONENTS ====================

  // ==================== DEBUG CONTROLS ====================

  void _adjustScale(bool increase) {
    if (_butterflyNode == null) return;

    if (increase) {
      _currentScale = (_currentScale * 1.2).clamp(0.001, 1.0); // Aumentar 20%
    } else {
      _currentScale = (_currentScale * 0.8).clamp(0.001, 1.0); // Reducir 20%
    }

    // Create a new node with the updated scale
    final rotation = _butterflyNode!.eulerAngles;
    final rotationVector = vector.Vector4(
      rotation.x,
      rotation.y,
      rotation.z,
      1.0,
    );

    final newNode = ARKitNode(
      geometry: _butterflyNode!.geometry,
      position: _butterflyNode!.position,
      rotation: rotationVector,
      scale: vector.Vector3.all(_currentScale),
      name: _butterflyNode!.name,
    );

    // Remove the old node by name and add the new one
    if (_butterflyNode?.name != null) {
      _arkitController?.remove(_butterflyNode!.name!);
    }

    _arkitController?.add(newNode);
    _butterflyNode = newNode;

    ARLogger.log('Nueva escala: $_currentScale');

    // Show current scale
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Escala: ${_currentScale.toStringAsFixed(3)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(selectedButterfly.imageAsset),
                            fit: BoxFit.cover,
                          ),
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedButterfly.scientificName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descripción',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedButterfly.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
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
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (!_hasCameraPermission)
              _buildNoPermissionView()
            else
              Platform.isIOS &&
                      _isARMode &&
                      _arSupport == ARPlatformSupport.arkit
                  ? _buildARView()
                  : Platform.isAndroid &&
                        _isARMode &&
                        _arSupport == ARPlatformSupport.arcore
                  ? _buildARCoreView()
                  : _buildStaticView(),

            _buildTopControls(),

            if ((Platform.isIOS &&
                    _isARMode &&
                    _arSupport == ARPlatformSupport.arkit) ||
                (Platform.isAndroid &&
                    _isARMode &&
                    _arSupport == ARPlatformSupport.arcore))
              _buildARControls(),

            if ((Platform.isIOS &&
                    _isARMode &&
                    _arSupport == ARPlatformSupport.arkit &&
                    !_isModelLoaded) ||
                (Platform.isAndroid &&
                    _isARMode &&
                    _arSupport == ARPlatformSupport.arcore &&
                    !_isModelLoaded))
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
          if ((_arSupport == ARPlatformSupport.arkit && Platform.isIOS) ||
              (_arSupport == ARPlatformSupport.arcore && Platform.isAndroid))
            _buildFloatingButton(
              icon: _isARMode ? LucideIcons.image : LucideIcons.box,
              onPressed: () {
                setState(() => _isARMode = !_isARMode);
                HapticFeedback.selectionClick();
              },
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
          // ⭐ BOTONES DE DEBUG REMOVIDOS
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

  // Convertir ImageProvider a Uint8List
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
    _stopIdleAnimation(); // ⭐ ACTUALIZADO NOMBRE
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _slideController.dispose();
    _arkitController?.dispose();
    _arcoreController?.dispose(); // Agregar disposal de ARCore
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ARLogger.log('App resumed - rechecking permissions');
        _checkCameraPermission();
        if ((_arkitController != null || _arcoreController != null) &&
            !_isModelLoaded) {
          // No llamar _loadButterflyModel ya que usamos auto-detección de planos
        }
        _playAmbientSound();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        ARLogger.log('App paused/inactive - stopping animations and audio');
        _stopIdleAnimation(); // ⭐ ACTUALIZADO NOMBRE
        _audioPlayer?.pause();
        break;
      case AppLifecycleState.detached:
        ARLogger.log('App detached - cleanup');
        _audioPlayer?.stop();
        break;
    }
  }
}
