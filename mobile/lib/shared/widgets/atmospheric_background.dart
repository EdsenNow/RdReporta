import 'package:flutter/material.dart';

/// Fondo atmosférico con orbes de luz desenfocados idéntico a FinanzApp.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;

  const AtmosphericBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13111C),
      body: Stack(
        children: [
          // 1. Degradado base oscuro
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF110F1A), // darker
                    Color(0xFF191724), // dark
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. Orbes luminosos y etéreos (Rosé Pine: Love, Pine, Iris, Gold)
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbsBackgroundPainter(),
            ),
          ),

          // 3. Contenido interactivo
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _OrbsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Orbe 1: Rosa / Love (#EB6F92) - Superior Derecho
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEB6F92).withValues(alpha: 0.28),
          const Color(0xFFEB6F92).withValues(alpha: 0.08),
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
          const Color(0xFF31748F).withValues(alpha: 0.26),
          const Color(0xFF31748F).withValues(alpha: 0.07),
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
          const Color(0xFFC4A7E7).withValues(alpha: 0.18),
          const Color(0xFFC4A7E7).withValues(alpha: 0.05),
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
          const Color(0xFFF6C177).withValues(alpha: 0.16),
          const Color(0xFFF6C177).withValues(alpha: 0.04),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
