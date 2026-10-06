import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/app_theme.dart';

class AvatarCropScreen extends StatefulWidget {
  final File imageFile;

  const AvatarCropScreen({super.key, required this.imageFile});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final GlobalKey _cropKey = GlobalKey();

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Offset _focalPoint = Offset.zero;
  int _rotationQuarterTurns = 0;
  bool _showGrid = true;
  bool _saving = false;

  void _reset() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _rotationQuarterTurns = 0;
    });
  }

  void _rotate() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _offset = Offset.zero;
    });
  }

  Future<void> _applyCrop(double cropDiameter) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('No se pudo capturar el área de recorte.');
      }

      final pixelRatio = (720.0 / cropDiameter).clamp(2.0, 3.5);
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Error al codificar la imagen recortada.');
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File(
          '${tempDir.path}/avatar_crop_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cropDiameter = min(screenSize.width * 0.82, 320.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close_rounded),
          onPressed: _saving ? null : () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Ajustar foto',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: _showGrid ? 'Ocultar malla' : 'Mostrar malla',
            icon: Icon(
              _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
              color: _showGrid ? context.loveColor : Colors.white60,
            ),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _applyCrop(cropDiameter),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: context.loveColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Listo',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Interactive Crop Area
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _baseScale = _scale;
                  _baseOffset = _offset;
                  _focalPoint = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _scale = (_baseScale * details.scale).clamp(0.6, 4.5);
                    _offset = _baseOffset + (details.focalPoint - _focalPoint);
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cropped Image Area
                    SizedBox(
                      width: cropDiameter,
                      height: cropDiameter,
                      child: RepaintBoundary(
                        key: _cropKey,
                        child: ClipOval(
                          child: ColoredBox(
                            color: Colors.black,
                            child: Transform.translate(
                              offset: _offset,
                              child: Transform.scale(
                                scale: _scale,
                                alignment: Alignment.center,
                                child: RotatedBox(
                                  quarterTurns: _rotationQuarterTurns,
                                  child: Image.file(
                                    widget.imageFile,
                                    fit: BoxFit.cover,
                                    width: cropDiameter,
                                    height: cropDiameter,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Mask & Grid Overlay (not captured by RepaintBoundary)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CropOverlayPainter(
                            cropDiameter: cropDiameter,
                            showGrid: _showGrid,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              color: const Color(0xFF141417),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Helper text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pinch_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'Arrastra o pellizca para ajustar la imagen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Zoom Slider
                  Row(
                    children: [
                      IconButton(
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.white70),
                        onPressed: () => setState(() =>
                            _scale = (_scale - 0.2).clamp(0.6, 4.5)),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: context.loveColor,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: context.loveColor,
                            overlayColor: context.loveColor
                                .withValues(alpha: 0.2),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: _scale.clamp(0.6, 4.5),
                            min: 0.6,
                            max: 4.5,
                            onChanged: (val) =>
                                setState(() => _scale = val),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white70),
                        onPressed: () => setState(() =>
                            _scale = (_scale + 0.2).clamp(0.6, 4.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Action Buttons: Rotate & Reset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onPressed: _rotate,
                        icon: const Icon(Icons.rotate_right_rounded,
                            size: 18),
                        label: const Text('Rotar 90°',
                            style: TextStyle(fontSize: 13)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt_rounded,
                            size: 18),
                        label: const Text('Centrar',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final double cropDiameter;
  final bool showGrid;

  _CropOverlayPainter({required this.cropDiameter, required this.showGrid});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = cropDiameter / 2;

    // Dark background with circular cutout
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPath = Path()..addRect(screenRect);
    final circlePath = Path()..addOval(circleRect);
    final cutPath =
        Path.combine(PathOperation.difference, backgroundPath, circlePath);

    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cutPath, maskPaint);

    // Circular white border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Grid (Malla) 3x3 inside circle
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.save();
      canvas.clipPath(circlePath);

      final left = center.dx - radius;
      final top = center.dy - radius;
      final step = cropDiameter / 3;

      // Vertical lines
      canvas.drawLine(
        Offset(left + step, top),
        Offset(left + step, top + cropDiameter),
        gridPaint,
      );
      canvas.drawLine(
        Offset(left + step * 2, top),
        Offset(left + step * 2, top + cropDiameter),
        gridPaint,
      );

      // Horizontal lines
      canvas.drawLine(
        Offset(left, top + step),
        Offset(left + cropDiameter, top + step),
        gridPaint,
      );
      canvas.drawLine(
        Offset(left, top + step * 2),
        Offset(left + cropDiameter, top + step * 2),
        gridPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropDiameter != cropDiameter ||
        oldDelegate.showGrid != showGrid;
  }
}
