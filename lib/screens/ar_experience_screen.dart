// lib/screens/ar_experience_screen.dart - Versión con ARCore Flutter Plugin
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:butterflyar/models/butterfly.dart';
import 'package:butterflyar/services/ar/ar_permission_service.dart';
import 'package:butterflyar/services/audio_service.dart';
import 'package:butterflyar/services/logger_service.dart';
import 'package:butterflyar/widgets/ar/ar_dialogs.dart';
import 'package:butterflyar/widgets/ar/ar_static_view_widget.dart';

/// Pantalla de experiencia AR con ARCore Flutter Plugin
class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;

  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ==================== SERVICIOS ====================
  final _permissionService = ARPermissionService();
  final _audioService = AudioService();
  final _logger = logger;

  // ==================== AR CORE ====================
  ArCoreController? _arCoreController;

  // ==================== ESTADO ====================
  bool _isARMode = false;
  bool _isDayBackground = true;
  bool _isModelLoaded = false;
  bool _isARSupported = true;
  bool _planeDetected = false;

  // ==================== ANIMACIONES ====================
  late AnimationController _slideController;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initializeApp();
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

  /// Inicializa la aplicación
  Future<void> _initializeApp() async {
    try {
      _logger.arInfo(
        'Inicializando experiencia AR para ${widget.butterfly.name}',
      );

      // Verificar soporte ARCore
      _isARSupported =
          await ArCoreController.checkArCoreAvailability() &&
          await ArCoreController.checkIsArCoreInstalled();

      _logger.arInfo('ARCore disponible: $_isARSupported');

      // Verificar permisos de cámara
      _permissionService.setOnPermissionChanged((hasPermission) {
        _logger.arInfo('Permiso de cámara: $hasPermission');
      });
      await _permissionService.checkCameraPermission();

      // Inicializar audio
      _audioService.initialize();
      if (widget.butterfly.ambientSound != null) {
        await _audioService.playAmbientSound(
          widget.butterfly.ambientSound!,
          volume: 0.3,
        );
        _logger.audioInfo('Sonido ambiental iniciado');
      }

      // Iniciar sin loading screen
      setState(() {
        _isARMode = false;
      });

      _logger.arSuccess('Inicialización completada');
    } catch (e) {
      _logger.arError('Error en inicialización', error: e);
      setState(() {
        _isARSupported = false;
      });
    }
  }

  /// Callback cuando se crea la vista ARCore
  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    _logger.arInfo('Vista ARCore creada');

    // Configurar listener para taps en planos
    _arCoreController!.onPlaneTap = _handlePlaneTap;

    // Listener para detección de planos
    _arCoreController!.onPlaneDetected = (ArCorePlane plane) {
      if (!_planeDetected) {
        setState(() => _planeDetected = true);
        _logger.arInfo('Plano detectado');
      }
    };

    _logger.arSuccess('ARCore listo');
  }

  /// Maneja el tap en un plano
  void _handlePlaneTap(List<ArCoreHitTestResult> hits) {
    if (_isModelLoaded || hits.isEmpty) {
      return;
    }

    final hit = hits.first;
    _addModelToScene(hit);
  }

  /// Agrega el modelo 3D a la escena
  Future<void> _addModelToScene(ArCoreHitTestResult hit) async {
    try {
      _logger.arInfo('Agregando modelo a la escena...');

      final modelPath = widget.butterfly.modelAssetForARCore;
      if (modelPath == null || modelPath.isEmpty) {
        _showErrorSnackbar('Modelo 3D no disponible');
        return;
      }

      // Normalizar ruta (quitar "assets/" si existe)
      String normalizedPath = modelPath;
      if (normalizedPath.startsWith('assets/')) {
        normalizedPath = normalizedPath.substring(7);
      }

      // Crear nodo con el modelo GLB
      final node = ArCoreReferenceNode(
        name: 'butterfly_${widget.butterfly.id}',
        objectUrl: normalizedPath,
        position: hit.pose.translation,
        rotation: hit.pose.rotation,
        scale: vector.Vector3.all(0.2),
      );

      // Agregar nodo a la escena
      await _arCoreController?.addArCoreNodeWithAnchor(node);

      setState(() => _isModelLoaded = true);
      _logger.arSuccess('Modelo cargado exitosamente');
      _showSuccessSnackbar();
      HapticFeedback.mediumImpact();
    } catch (e) {
      _logger.arError('Error agregando modelo', error: e);
      _showErrorSnackbar('Error al cargar el modelo');
    }
  }

  /// Alterna entre modo AR y vista previa
  Future<void> _toggleARMode() async {
    if (_isARMode) {
      setState(() {
        _isARMode = false;
        _planeDetected = false;
      });
      HapticFeedback.selectionClick();
      return;
    }

    if (!_permissionService.hasCameraPermission) {
      final granted = await _permissionService.handlePermissionFlow(context);
      if (!granted) return;
    }

    if (!_isARSupported) {
      await ARDialogs.showARNotAvailableDialog(
        context,
        onInstallARCore: () {
          ARDialogs.openARCoreInPlayStore(context);
        },
      );
      return;
    }

    if (!widget.butterfly.hasAndroidModel) {
      _showErrorSnackbar('Modelo 3D no disponible para AR');
      return;
    }

    setState(() {
      _isARMode = true;
      _isModelLoaded = false;
      _planeDetected = false;
    });
    HapticFeedback.selectionClick();
    _logger.arInfo('Cambiado a modo AR');
  }

  void _toggleBackground() {
    setState(() => _isDayBackground = !_isDayBackground);
    HapticFeedback.selectionClick();
  }

  Future<void> _captureScreen() async {
    HapticFeedback.mediumImpact();
    _showInfoSnackbar('Captura de pantalla no disponible en este momento');
  }

  void _showInfo() {
    // TODO: Implementar panel de información
    _showInfoSnackbar('Panel de información próximamente');
  }

  void _showSuccessSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Modelo cargado exitosamente!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInfoSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Vista principal
          _buildMainView(),

          // Controles superiores
          _buildTopControls(),

          // Controles AR (solo en modo AR)
          _buildARControls(),

          // Instrucciones AR
          if (_isARMode && !_isModelLoaded) _buildARInstructions(),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    if (_isARMode) {
      return ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableTapRecognizer: true,
      );
    } else {
      return ARStaticViewWidget(
        butterfly: widget.butterfly,
        isDayBackground: _isDayBackground,
      );
    }
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón atrás
          _buildFloatingButton(
            icon: LucideIcons.chevronLeft,
            onPressed: () => Navigator.pop(context),
            tooltip: 'Atrás',
          ),

          // Botón cambiar modo AR/Vista (solo si AR está soportado)
          if (_isARSupported && widget.butterfly.hasAndroidModel)
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
          // En modo AR: Info y Captura
          if (_isARMode) ...[
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

          // En modo NO AR: Día/Noche
          if (!_isARMode) ...[
            _buildFloatingButton(
              icon: _isDayBackground ? LucideIcons.sun : LucideIcons.moon,
              onPressed: _toggleBackground,
              tooltip: _isDayBackground ? 'Modo noche' : 'Modo día',
            ),
          ],
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
                  _planeDetected ? LucideIcons.loader : LucideIcons.search,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _planeDetected
                      ? 'Cargando mariposa...'
                      : 'Busca una superficie plana',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _planeDetected
                      ? 'Preparando experiencia AR...'
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

  /// Botón flotante sin fondo, solo icono negro
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
          color: Colors.transparent,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  // ==================== LIFECYCLE ====================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _logger.arInfo('App pausada');
        _audioService.pauseAmbient();
        break;
      case AppLifecycleState.resumed:
        _logger.arInfo('App reanudada');
        _audioService.resumeAmbient();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _logger.arInfo('Limpiando recursos AR');

    WidgetsBinding.instance.removeObserver(this);
    _slideController.dispose();
    _arCoreController?.dispose();
    _audioService.dispose();

    super.dispose();
  }
}
