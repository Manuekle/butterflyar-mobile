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
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2936) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de agarre
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con imagen y nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: AssetImage(widget.butterfly.imageAsset),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.butterfly.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.butterfly.scientificName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: secondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  if (widget.butterfly.description.isNotEmpty) ...[
                    Text(
                      'Descripción',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.butterfly.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.9),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Características
                  if (widget.butterfly.characteristics.isNotEmpty) ...[
                    Text(
                      'Características',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.butterfly.characteristics.map(
                      (characteristic) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3, right: 6),
                              child: Icon(
                                LucideIcons.check,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                characteristic,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textColor.withOpacity(0.9),
                                  height: 1.3,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Hábitat
                  if (widget.butterfly.habitat.isNotEmpty) ...[
                    Text(
                      'Hábitat',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green[900]!.withOpacity(0.2)
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
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
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.butterfly.habitat,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor.withOpacity(0.9),
                                height: 1.3,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Distribución
                  if (widget.butterfly.distribution.isNotEmpty) ...[
                    Text(
                      'Distribución',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[900]!.withOpacity(0.2)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
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
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.butterfly.distribution,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor.withOpacity(0.9),
                                height: 1.3,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          // Botón atrás (con fondo blanco e ícono blanco)
          _buildBackButton(),

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
          // Botón Info (siempre visible)
          _buildFloatingButton(
            icon: LucideIcons.info,
            onPressed: _showInfo,
            tooltip: 'Información',
          ),
          const SizedBox(height: 16),

          // En modo AR: Captura
          if (_isARMode) ...[
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

  /// Botón flotante con fondo blanco semi-transparente (borderRadius 8)
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

  /// Botón de atrás - solo ícono blanco, SIN fondo
  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 22),
      onPressed: () => Navigator.pop(context),
      tooltip: 'Atrás',
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
