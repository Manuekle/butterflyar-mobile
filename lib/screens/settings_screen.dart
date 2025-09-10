import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:butterflyar/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 22),
          tooltip: 'Atrás',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildThemeSection(context),
              const SizedBox(height: 32),
              _buildAboutSection(context),
              const SizedBox(height: 32),
              _buildSupportSection(context),
              const SizedBox(height: 32),
              _buildLegalSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildSection(
          title: 'Apariencia',
          children: [
            _buildThemeOption(
              context: context,
              title: 'Tema del sistema',
              subtitle: 'Usar configuración del dispositivo',
              isSelected: themeProvider.themeMode == ThemeMode.system,
              onTap: () => themeProvider.setSystemTheme(),
            ),
            _buildDivider(),
            _buildThemeOption(
              context: context,
              title: 'Tema claro',
              subtitle: 'Fondo claro con texto oscuro',
              isSelected: themeProvider.themeMode == ThemeMode.light,
              onTap: () => themeProvider.setLightTheme(),
            ),
            _buildDivider(),
            _buildThemeOption(
              context: context,
              title: 'Tema oscuro',
              subtitle: 'Fondo oscuro con texto claro',
              isSelected: themeProvider.themeMode == ThemeMode.dark,
              onTap: () => themeProvider.setDarkTheme(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      title: 'Información',
      children: [
        _buildListTile(
          context: context,
          icon: LucideIcons.info,
          title: 'Versión',
          subtitle: '1.0.0',
          onTap: () => _showVersionDialog(context),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.shield,
          title: 'Política de privacidad',
          subtitle: 'Cómo manejamos tus datos',
          onTap: () => _showInfoDialog(
            context,
            'Política de Privacidad',
            'En ButterflyAR, respetamos y protegemos tu privacidad.\n\nDatos que recopilamos:\n- Información de uso de la aplicación\n- Datos de diagnóstico en caso de errores\n\nNo recopilamos información personal identificable sin tu consentimiento explícito.\n\nPara más información, contacta a: privacidad@fup.edu.co',
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildSection(
      title: 'Soporte',
      children: [
        _buildListTile(
          context: context,
          icon: LucideIcons.info,
          title: 'Centro de ayuda',
          subtitle: 'Preguntas frecuentes y guías',
          onTap: () => _showInfoDialog(
            context,
            'Centro de ayuda',
            'Si necesitas ayuda con la aplicación, por favor contacta a nuestro equipo de soporte.\n\nCorreo: soporte@fup.edu.co\nHorario: Lunes a Viernes 8:00 AM - 6:00 PM',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.bug,
          title: 'Reportar problema',
          subtitle: 'Ayúdanos a mejorar la aplicación',
          onTap: () => _showInfoDialog(
            context,
            'Reportar problema',
            'Por favor describe el problema que has encontrado.\n\nIncluye:\n- Qué estabas haciendo cuando ocurrió el problema\n- Pasos para reproducirlo\n- Capturas de pantalla si es posible\n\nCorreo: soporte@fup.edu.co',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.star,
          title: 'Calificar aplicación',
          subtitle: 'Comparte tu experiencia con otros',
          onTap: () => _showInfoDialog(
            context,
            'Calificar aplicación',
            '¡Tu opinión es muy importante para nosotros!\n\nPor favor califica nuestra aplicación en la tienda de aplicaciones.\n\nSi tienes sugerencias de mejora, no dudes en compartirlas con nosotros.',
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return _buildSection(
      title: 'Acerca de',
      children: [
        _buildListTile(
          context: context,
          icon: LucideIcons.user,
          title: 'Autor',
          subtitle: 'Est. Ing Sistemas Manuel Erazo',
          onTap: () => _showInfoDialog(
            context,
            'Manuel Esteban Erazo Medina',
            'Estudiante de Ingeniería de Sistemas\nUniversidad: Fundación Universitaria de Popayán\nCorreo: manuel.erazo@fup.edu.co',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.graduationCap,
          title: 'Universidad',
          subtitle: 'Fundación Universitaria de Popayán',
          onTap: () => _showInfoDialog(
            context,
            'Fundación Universitaria de Popayán',
            'Institución de Educación Superior\n\nSede Principal:\nCalle 5 # 8-58, Popayán - Cauca\n\nContacto:\nTeléfono: (602) 838 1005\nSitio web: www.fup.edu.co',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.sprout,
          title: 'Semillero de investigación',
          subtitle: 'Deveniac',
          onTap: () => _showInfoDialog(
            context,
            'Semillero de Investigación Deveniac',
            'Grupo de investigación en desarrollo de software y nuevas tecnologías\n\nLíder: Mag. Luis Vejarano\nCorreo: luis.vejarano@docente.fup.edu.co\nPagina web: www.deveniac.com',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.briefcase,
          title: 'Empresa',
          subtitle: 'Smurfit Kappa',
          onTap: () => _showInfoDialog(
            context,
            'Smurfit Kappa',
            'Compañía líder en empaques de papel con presencia global.\n\nSede en Colombia:\nPlanta Yumbo, Valle del Cauca\n\nSitio web: www.smurfitkappa.com',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.user,
          title: 'Coordinadora del proyecto',
          subtitle: 'Mag. Daniela Gutiérrez',
          onTap: () => _showInfoDialog(
            context,
            'Mag. Daniela Gutiérrez',
            'Coordinadora del Proyecto\n\nTítulo: Magíster en Ingeniería de Sistemas\nUniversidad: Fundación Universitaria de Popayán\nCorreo: daniela.gutierrez@docente.edu.co',
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context: context,
          icon: LucideIcons.user,
          title: 'Director del proyecto',
          subtitle: 'Mag. Luis Vejarano',
          onTap: () => _showInfoDialog(
            context,
            'Mag. Luis Vejarano',
            'Director del Proyecto\nLíder del Semillero Deveniac\n\nTítulo: Magíster en Ingeniería de Sistemas\nUniversidad: Fundación Universitaria de Popayán\nCorreo: luis.vejarano@docente.fup.edu.co',
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Radio button personalizado
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),

            const SizedBox(width: 16),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Flecha
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.onSurface.withOpacity(0.1),
      indent: 20,
      endIndent: 20,
    );
  }

  void _showVersionDialog(BuildContext context) {
    _showMaterialVersionDialog(context);
  }

  void _showMaterialVersionDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ButterflyAR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Una aplicación de realidad aumentada para explorar el mundo de las mariposas.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Versión'),
                Text(
                  '1.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Año'),
                Text(
                  '2025',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.8)),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
