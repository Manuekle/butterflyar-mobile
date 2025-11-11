/// ⭐ Constantes de la aplicación para mejor mantenibilidad
class AppConstants {
  AppConstants._(); // Constructor privado para evitar instanciación

  // ⭐ Rutas de assets
  static const String butterfliesDataPath = 'lib/data/butterflies.json';
  static const String dayBackgroundPath = 'assets/backgrounds/day.png';
  static const String nightBackgroundPath = 'assets/backgrounds/night.png';

  // ⭐ Configuración de animaciones
  static const Duration slideAnimationDuration = Duration(milliseconds: 800);
  static const Duration idleAnimationInterval = Duration(milliseconds: 100);
  static const Duration snackbarDuration = Duration(seconds: 2);

  // ⭐ Configuración AR
  static const double fixedModelScale = 0.003;
  static const double idleFloatingAmplitude = 0.02;
  static const double idleFloatingSpeed = 0.03;
  static const double modelRotationSensitivity = 0.01;

  // ⭐ Configuración de audio
  static const double ambientSoundVolume = 0.3;

  // ⭐ Configuración de UI
  static const double cardBorderRadius = 12.0;
  static const double floatingButtonSize = 44.0;
  static const double imageCacheWidth = 120.0;

  // ⭐ Mensajes de error
  static const String errorButterflyNotFound = 'Mariposa no encontrada';
  static const String errorLoadingButterflies = 'Error al cargar las especies';
  static const String errorNoButterfliesAvailable = 'No hay mariposas disponibles';
  static const String errorModelNotAvailable = 'Modelo 3D no disponible para AR en esta plataforma';
  static const String errorCameraPermission = 'Permiso de cámara requerido';
  static const String errorARNotAvailable = 'AR no disponible';

  // ⭐ Mensajes de éxito
  static const String successButterflyLoaded = '¡Mariposa cargada! Toca para interactuar';
  static const String successPhotoSaved = '¡Foto guardada en la galería!';
  static const String successCapturing = 'Capturando pantalla...';

  // ⭐ Versión mínima de iOS para ARKit
  static const int minIOSVersionForARKit = 11;

  // ⭐ Versión mínima de Android para ARCore (API level)
  static const int minAndroidAPIForARCore = 24;
}

