import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fondo sólido adaptativo con botón de cambio de tema.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final bool showThemeToggle;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.showThemeToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? RosePineDark.base : const Color(0xFFFAF4ED),
      body: SafeArea(
        child: child,
      ),
    );
  }
}
