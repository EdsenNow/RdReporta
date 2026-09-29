import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../feed/post_detail_screen.dart';
import '../../shared/widgets/request_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiClient _apiClient = ApiClient();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  List<PostMapPinModel> _pins = [];
  bool _loading = true;
  bool _showRadarList = false;
  PostMapPinModel? _selectedPin;
  String? _error;

  // Bounding box para República Dominicana
  static const double minLat = 17.5;
  static const double maxLat = 20.0;
  static const double minLng = -72.0;
  static const double maxLng = -68.3;

  @override
  void initState() {
    super.initState();
    _loadData();
    _apiClient.changes.addListener(_loadData);
  }

  @override
  void dispose() {
    _apiClient.changes.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiClient.getCategories(),
        _apiClient.getMapPins(
          minLat: minLat,
          maxLat: maxLat,
          minLng: minLng,
          maxLng: maxLng,
          categoryId: _selectedCategory?.id,
        ),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _pins = results[1] as List<PostMapPinModel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _filterCategory(CategoryModel? category) async {
    if (_loading) return;
    setState(() {
      _selectedCategory = category;
      _loading = true;
      _selectedPin = null;
      _error = null;
    });
    try {
      final pins = await _apiClient.getMapPins(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        categoryId: category?.id,
      );

      if (mounted) {
        setState(() {
          _pins = pins;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryBlue;
    }
  }

  void _showPinPreview(PostMapPinModel pin) {
    setState(() => _selectedPin = pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 58,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.pineColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: context.pineColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar de incidencias',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _showRadarList ? 'Vista en lista' : 'Vista en el mapa',
                        style: TextStyle(
                          color: context.subtleColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showRadarList ? Icons.map_rounded : Icons.view_list_rounded,
                    color: context.loveColor,
                  ),
                  tooltip: _showRadarList
                      ? 'Ver mapa'
                      : 'Ver lista geoespacial',
                  onPressed: () =>
                      setState(() => _showRadarList = !_showRadarList),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _error != null
          ? RequestState(message: _error!, onRetry: _loadData)
          : Stack(
              children: [
                // 1. Contenido Principal: Mapa Interactivo o Lista Radar
                _showRadarList
                    ? RefreshIndicator(
                        color: context.loveColor,
                        onRefresh: _loadData,
                        child: _buildRadarListView(),
                      )
                    : _buildInteractiveMapCanvas(),
                // 2. Filtros de Categorías Flotantes
                Positioned(
                  top: 14,
                  left: 12,
                  right: 12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: 'Todas (${_pins.length})',
                          isSelected: _selectedCategory == null,
                          color: AppTheme.primaryBlue,
                          onTap: () => _filterCategory(null),
                        ),
                        ..._categories.map((c) {
                          final color = _parseColor(c.colorHex);
                          return _buildCategoryChip(
                            label: c.name,
                            isSelected: _selectedCategory?.id == c.id,
                            color: color,
                            onTap: () => _filterCategory(c),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // 3. Indicador de carga
                if (_loading)
                  const Positioned(
                    top: 70,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Cargando incidencias geolocalizadas…',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ),

                // 4. Tarjeta Flotante de Incidencia Seleccionada
                if (_selectedPin != null && !_showRadarList)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    right: 16,
                    child: _buildPinDetailCard(_selectedPin!),
                  ),
              ],
            ),
    );
  }

  Widget _buildInteractiveMapCanvas() {
    final markers = _pins.map((pin) => Marker(
      markerId: MarkerId(pin.id),
      position: LatLng(pin.latitude, pin.longitude),
      infoWindow: InfoWindow(title: pin.title, snippet: pin.categoryName),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(_parseColor(pin.categoryColor)).hue,
      ),
      onTap: () => _showPinPreview(pin),
    )).toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(18.7357, -70.1627),
        zoom: 7.4,
      ),
      markers: markers,
      mapType: MapType.normal,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      onTap: (_) => setState(() => _selectedPin = null),
    );
  }

  Widget _buildRadarListView() {
    if (_pins.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 160, 32, 100),
        children: [
          Text(
            'No hay incidencias geolocalizadas registradas para este filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.subtleColor),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 70, bottom: 20, left: 16, right: 16),
      itemCount: _pins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pin = _pins[index];
        final pinColor = _parseColor(pin.categoryColor);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: pinColor.withValues(alpha: 0.15),
              child: Icon(Icons.location_on, color: pinColor),
            ),
            title: Text(pin.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimaryColor)),
            subtitle: Text(
              '${pin.categoryName} • ✓ ${pin.confirmationsCount} confirmaciones',
              style: TextStyle(
                  color: pinColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            trailing: Icon(Icons.chevron_right, color: context.subtleColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: pin.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : context.borderColor, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textPrimaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPinDetailCard(PostMapPinModel pin) {
    final pinColor = _parseColor(pin.categoryColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pinColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pin.categoryName,
                    style: TextStyle(
                        color: pinColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: context.subtleColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedPin = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pin.title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.textPrimaryColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Coordenadas: ${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)} • ✓ ${pin.confirmationsCount} confirmaciones',
              style: TextStyle(fontSize: 12, color: context.mutedColor),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: pin.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: const Text('Ver detalles de la incidencia',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DominicanMapPainter extends CustomPainter {
  final bool isDark;
  final Color islandColor;
  final Color borderColor;
  final Color textColor;

  _DominicanMapPainter({
    required this.isDark,
    required this.islandColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0;

    // Cuadrícula geodésica sutil
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paintGrid);
    }

    // Región de RD simulada
    final paintRD = Paint()
      ..color = islandColor
      ..style = PaintingStyle.fill;

    final paintRDBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rectRD = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.25, size.width * 0.8,
          size.height * 0.5),
      const Radius.circular(24),
    );
    canvas.drawRRect(rectRD, paintRD);
    canvas.drawRRect(rectRD, paintRDBorder);

    // Texto de referencia territorial
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'REPÚBLICA DOMINICANA\nRed geoespacial de incidencias',
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height * 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _DominicanMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.islandColor != islandColor ||
        oldDelegate.borderColor != borderColor;
  }
}
