import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Auto-navigate to hub after 5 seconds
    Future.delayed(const Duration(seconds: 5), _navigateToHub);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToHub() {
    Navigator.of(context).pushReplacementNamed('/hub');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Espaciado superior
                SizedBox(height: size.height * 0.1),

                // Logo/Ilustración
                Expanded(
                  flex: 3,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icon/favicon.png',
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenido principal
                Expanded(
                  flex: 2,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título principal
                        Column(
                          children: [
                            Text(
                              'ButterflyAR',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fundación Universitaria de Popayán',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                letterSpacing: -0.5,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        // Subtítulo
                        Text(
                          'Smurfit Kappa cartón Colombia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Descripción
                        Text(
                          'Descubre el fascinante mundo de las mariposas\ncon realidad aumentada',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.9,
                            ),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer with logos and information
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      // Logos row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Smurfit Logo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 100,
                              height: 50,
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

                          // FUP Logo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 100,
                              height: 50,
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

                          // Deveniac Logo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 40,
                              height: 40,
                              child: Image.asset(
                                'assets/icon/semillero/deveniac.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Version and year
                      Text(
                        'Versión 1.0.0 • 2025',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
