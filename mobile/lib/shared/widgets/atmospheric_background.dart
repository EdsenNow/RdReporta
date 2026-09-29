import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fondo atmosférico adaptativo (Modo Oscuro / Modo Claro) con orbes de luz
/// desenfocados y botón de cambio de tema superior.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final bool showThemeToggle;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13111C) : const Color(0xFFFAF4ED),
      body: Stack(
        children: [
          // 1. Degradado base adaptativo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF110F1A), // Darker
                          Color(0xFF191724), // Base
                        ]
                      : const [Color(0xFFFAF4ED), Color(0xFFFAF4ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. Orbes luminosos adaptativos (Rosé Pine: Love, Pine, Iris, Gold)
          if (isDark) Positioned.fill(
            child: CustomPaint(
              painter: _OrbsBackgroundPainter(isDark: isDark),
            ),
          ),

          // 3. Contenido interactivo
          SafeArea(
            child: child,
          ),

          // 4. Botón flotante para alternar tema (Claro / Oscuro)
          if (showThemeToggle)
            Positioned(
              top: 14,
              right: 18,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1D2E) : const Color(0xFFFFFAF3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0x44EB6F92) : const Color(0xFFF2E9E1),
                      width: isDark ? 1.5 : 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? const Color(0xFFEB6F92) : const Color(0xFFB4637A),
                      size: 20,
                    ),
                    tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
                    onPressed: () {
                      AppTheme.toggleTheme();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrbsBackgroundPainter extends CustomPainter {
  final bool isDark;

  _OrbsBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final alpha1 = isDark ? 0.28 : 0.12;
    final alpha2 = isDark ? 0.08 : 0.03;

    // Orbe 1: Rosa / Love (#EB6F92) - Superior Derecho
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEB6F92).withValues(alpha: alpha1),
          const Color(0xFFEB6F92).withValues(alpha: alpha2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.95, height * 0.12),
        radius: width * 0.65,
      ));
    canvas.drawCircle(Offset(width * 0.95, height * 0.12), width * 0.65, paint1);

    // Orbe 2: Azul / Pine (#31748F) - Inferior Izquierdo
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF31748F).withValues(alpha: isDark ? 0.26 : 0.10),
          const Color(0xFF31748F).withValues(alpha: isDark ? 0.07 : 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.05, height * 0.88),
        radius: width * 0.7,
      ));
    canvas.drawCircle(Offset(width * 0.05, height * 0.88), width * 0.7, paint2);

    // Orbe 3: Púrpura / Iris (#C4A7E7) - Centro Izquierdo
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC4A7E7).withValues(alpha: isDark ? 0.18 : 0.08),
          const Color(0xFFC4A7E7).withValues(alpha: isDark ? 0.05 : 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.70],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.18, height * 0.42),
        radius: width * 0.5,
      ));
    canvas.drawCircle(Offset(width * 0.18, height * 0.42), width * 0.5, paint3);

    // Orbe 4: Dorado / Gold (#F6C177) - Centro / Inferior Derecho
    final paint4 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF6C177).withValues(alpha: isDark ? 0.16 : 0.08),
          const Color(0xFFF6C177).withValues(alpha: isDark ? 0.04 : 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.70],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.85, height * 0.70),
        radius: width * 0.45,
      ));
    canvas.drawCircle(Offset(width * 0.85, height * 0.70), width * 0.45, paint4);
  }

  @override
  bool shouldRepaint(covariant _OrbsBackgroundPainter oldDelegate) => oldDelegate.isDark != isDark;
}
