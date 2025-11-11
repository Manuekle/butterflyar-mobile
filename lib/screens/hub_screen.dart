import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700; // ⭐ Detectar pantallas pequeñas

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: isSmallScreen ? 16 : 24, // ⭐ Padding adaptativo
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // ⭐ Evitar overflow
                        children: [
                          // Header
                          _buildHeader(context, theme),

                          SizedBox(
                            height: isSmallScreen
                                ? 16
                                : size.height * 0.04, // ⭐ Espaciado adaptativo
                          ),

                          // Welcome Section
                          _buildWelcomeSection(theme, isSmallScreen),

                          SizedBox(
                            height: isSmallScreen
                                ? 20
                                : size.height * 0.06, // ⭐ Espaciado adaptativo
                          ),

                          // Main Actions
                          _buildMainActions(context, theme),

                          // ⭐ Espaciado flexible en lugar de Spacer
                          SizedBox(
                            height: isSmallScreen ? 20 : 40,
                          ),

                          // Institution Logos
                          _buildInstitutionLogos(theme, isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// ⭐ Widget para logos de instituciones - Responsive
  Widget _buildInstitutionLogos(ThemeData theme, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isSmallScreen ? 16 : 24, // ⭐ Padding adaptativo
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logos row - Responsive
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Smurfit Logo
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                  ),
                  child: Container(
                    width: isSmallScreen ? 80 : 100,
                    height: isSmallScreen ? 40 : 50,
                    child: SvgPicture.asset(
                      'assets/icon/smurtfit/smurtfit.svg',
                      colorFilter: ColorFilter.mode(
                        theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // FUP Logo
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                  ),
                  child: Container(
                    width: isSmallScreen ? 80 : 100,
                    height: isSmallScreen ? 40 : 50,
                    child: SvgPicture.asset(
                      'assets/icon/universidad/fup.svg',
                      colorFilter: ColorFilter.mode(
                        theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Deveniac Logo
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                  ),
                  child: Container(
                    width: isSmallScreen ? 32 : 40,
                    height: isSmallScreen ? 32 : 40,
                    child: Image.asset(
                      'assets/icon/semillero/deveniac.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          size: isSmallScreen ? 32 : 40,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          // Version and year
          Text(
            'Versión 1.0.0 • 2025',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              fontSize: isSmallScreen ? 11 : null, // ⭐ Tamaño de fuente adaptativo
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ButterflyAR',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            Text(
              'Smurfit Kappa cartón Colombia',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                LucideIcons.settings,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(ThemeData theme, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Explora el mundo\nde las mariposas',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.5,
            fontSize: isSmallScreen
                ? 28
                : null, // ⭐ Tamaño de fuente adaptativo para pantallas pequeñas
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        Text(
          'Descubre especies únicas con realidad aumentada y aprende sobre su fascinante mundo natural.',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
            letterSpacing: -0.5,
            fontSize: isSmallScreen ? 13 : 14, // ⭐ Tamaño de fuente adaptativo
          ),
        ),
      ],
    );
  }

  Widget _buildMainActions(BuildContext context, ThemeData theme) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Escanear QR - Acción principal
        SizedBox(
          width: double.infinity,
          child: _buildPrimaryActionCard(
            context: context,
            theme: theme,
            icon: LucideIcons.qrCode,
            title: 'Escanear QR',
            subtitle: 'Escanea un código QR para ver una mariposa en RA',
            onTap: () => Navigator.pushNamed(context, '/qr'),
            isSmallScreen: isSmallScreen,
          ),
        ),

        SizedBox(height: isSmallScreen ? 16 : 20),

        // Ver especies - Acción secundaria
        SizedBox(
          width: double.infinity,
          child: _buildSecondaryActionCard(
            context: context,
            theme: theme,
            icon: LucideIcons.compass,
            title: 'Ver especies',
            subtitle: 'Explora nuestra colección de mariposas',
            onTap: () => Navigator.pushNamed(context, '/species'),
            isSmallScreen: isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(1.0),
        transformAlignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 28), // ⭐ Padding adaptativo
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                width: isSmallScreen ? 56 : 64, // ⭐ Tamaño adaptativo
                height: isSmallScreen ? 56 : 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 28 : 32,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Título
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 20 : null, // ⭐ Tamaño adaptativo
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 6 : 8),

              // Subtítulo
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                  fontSize: isSmallScreen ? 11 : 12, // ⭐ Tamaño adaptativo
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(1.0),
        transformAlignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 28), // ⭐ Padding adaptativo
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: isSmallScreen ? 48 : 56, // ⭐ Tamaño adaptativo
                height: isSmallScreen ? 48 : 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 24 : 28,
                  color: theme.colorScheme.primary,
                ),
              ),

              SizedBox(width: isSmallScreen ? 16 : 20),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 18 : null, // ⭐ Tamaño adaptativo
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        fontSize: isSmallScreen ? 11 : 12, // ⭐ Tamaño adaptativo
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                LucideIcons.chevronRight,
                size: isSmallScreen ? 16 : 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
