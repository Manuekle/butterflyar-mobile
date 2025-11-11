import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/species_selection_screen.dart';
import 'screens/preparation_screen.dart';
import 'screens/ar_experience_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/butterfly_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => ButterflyProvider()..loadButterflies(),
        ),
      ],
      child: const ButterflyARApp(),
    ),
  );
}

class ButterflyARApp extends StatelessWidget {
  const ButterflyARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Configurar colores de sistema según el tema
        _configureSystemUI(themeProvider);

        return MaterialApp(
          title: 'ButterflyAR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/onboarding',
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/hub': (context) => const HubScreen(),
            '/species': (context) => const SpeciesSelectionScreen(),
            '/preparation': (context) => const PreparationScreen(),
            '/ar': (context) => _buildARRoute(context),
            '/settings': (context) => const SettingsScreen(),
            '/qr': (context) => const QRScanScreen(),
          },
        );
      },
    );
  }

  void _configureSystemUI(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  // ⭐ Construir ruta AR con mejor manejo de errores
  Widget _buildARRoute(BuildContext context) {
    final butterflyProvider = Provider.of<ButterflyProvider>(
      context,
      listen: false,
    );

    // Verificar si hay mariposas cargadas
    if (butterflyProvider.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (butterflyProvider.isLoading)
                CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryBlue,
                )
              else
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              const SizedBox(height: 20),
              Text(
                butterflyProvider.isLoading
                    ? 'Cargando experiencia AR...'
                    : butterflyProvider.error ?? 'No hay mariposas disponibles',
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

    // Intentar obtener mariposa desde argumentos
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final butterflyId = args['butterflyId'] as String?;
      if (butterflyId != null && butterflyId.isNotEmpty) {
        final butterfly = butterflyProvider.getButterflyById(butterflyId);
        if (butterfly != null) {
          return ARExperienceScreen(butterfly: butterfly);
        }
        // Si no se encuentra, mostrar error
        return _buildErrorScreen(
          context,
          'Mariposa con ID "$butterflyId" no encontrada',
        );
      }
    }

    // Usar la primera mariposa como fallback
    return ARExperienceScreen(butterfly: butterflyProvider.butterflies.first);
  }

  // ⭐ Widget para mostrar errores
  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

