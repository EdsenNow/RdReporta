import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../feed/post_detail_screen.dart';
import '../../shared/widgets/request_state.dart';
import '../../shared/widgets/post_media_carousel.dart';
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
  String? _currentUserId;
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
        _apiClient.getCurrentUserId(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          _pins = results[1] as List<PostMapPinModel>;
          _currentUserId = results[2] as String?;
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

  bool _isOwnPin(PostMapPinModel pin) =>
      _currentUserId != null && pin.userId == _currentUserId;

  String _pinAddress(PostMapPinModel pin) {
    final parts = <String>[];
    for (final value in [
      pin.addressReference,
      pin.neighborhood,
      pin.municipality,
      pin.province,
    ]) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty && !parts.contains(text)) parts.add(text);
    }
    return parts.isEmpty ? 'Dirección no especificada' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: context.baseColor,
      body: _error != null
          ? RequestState(message: _error!, onRetry: _loadData)
          : RefreshIndicator(
              color: context.loveColor,
              backgroundColor: context.surfaceColor,
              onRefresh: _loadData,
              edgeOffset: topPadding + 10,
              displacement: 40.0,
              notificationPredicate: (notification) =>
                  _showRadarList && notification.metrics.axis == Axis.vertical,
              child: Stack(
                children: [
                  // 1. Contenido Principal: Mapa Interactivo a Pantalla Completa o Lista Radar
                  Positioned.fill(
                    child: _showRadarList
                        ? _buildRadarListView()
                        : _buildInteractiveMapCanvas(),
                  ),

                  // 2. Cabecera Flotante sobre el Mapa (Píldora + Filtros de Categorías)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Píldora Radar de incidencias flotante
                          Container(
                            height: 64,
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: context.borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.pineColor
                                        .withValues(alpha: 0.12),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Radar de incidencias',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: context.textPrimaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        _showRadarList
                                            ? 'Vista en lista'
                                            : 'Vista en el mapa',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                    _showRadarList
                                        ? Icons.map_rounded
                                        : Icons.view_list_rounded,
                                    color: context.loveColor,
                                  ),
                                  tooltip: _showRadarList
                                      ? 'Ver mapa'
                                      : 'Ver lista geoespacial',
                                  onPressed: () => setState(
                                      () => _showRadarList = !_showRadarList),
                                ),
                              ],
                            ),
                          ),

                          // Chips de Categorías Flotantes
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        ],
                      ),
                    ),
                  ),

                  // 3. Indicador de carga
                  if (_loading)
                    const Positioned(
                      top: 155,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Card(
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text('Cargando incidencias geolocalizadas…',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                    ),

                  // 4. Tarjeta Flotante de Incidencia Seleccionada
                  if (_selectedPin != null && !_showRadarList)
                    Positioned(
                      bottom: 105,
                      left: 16,
                      right: 16,
                      child: _buildPinDetailCard(_selectedPin!),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInteractiveMapCanvas() {
    final markers = _pins
        .map((pin) => Marker(
              markerId: MarkerId(pin.id),
              position: LatLng(pin.latitude, pin.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _isOwnPin(pin)
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueRed,
              ),
              onTap: () => _showPinPreview(pin),
            ))
        .toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(18.7357, -70.1627),
        zoom: 7.4,
      ),
      cameraTargetBounds: CameraTargetBounds(
        LatLngBounds(
          southwest: const LatLng(17.3, -72.1),
          northeast: const LatLng(20.2, -68.2),
        ),
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(7.0, 20.0),
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
    if (_loading && _pins.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox.shrink()],
      );
    }
    if (_pins.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 210, 32, 140),
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
      padding:
          const EdgeInsets.only(top: 165, bottom: 140, left: 16, right: 16),
      itemCount: _pins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pin = _pins[index];
        final pinColor = _parseColor(pin.categoryColor);
        final markerColor =
            _isOwnPin(pin) ? const Color(0xFF2E9B72) : const Color(0xFFE5484D);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: markerColor.withValues(alpha: 0.15),
              child: Icon(Icons.location_on_rounded, color: markerColor),
            ),
            title: Text(pin.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimaryColor)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin.categoryName,
                    style: TextStyle(
                      color: pinColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: context.mutedColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _pinAddress(pin),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.subtleColor,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          border: Border.all(
              color: isSelected ? color : context.borderColor, width: 2),
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
    final hasMedia = pin.images.isNotEmpty ||
        (pin.videoUrl != null && pin.videoUrl!.trim().isNotEmpty);

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
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
            if (hasMedia) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PostMediaCarousel(
                  key: ValueKey('pin-media-${pin.id}'),
                  images: pin.images,
                  videoUrl: pin.videoUrl,
                  aspectRatio: 16 / 9,
                  borderRadius: 12,
                  postId: pin.id,
                ),
              ),
              const SizedBox(height: 10),
            ] else ...[
              const SizedBox(height: 8),
            ],
            Text(
              pin.title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.textPrimaryColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: context.mutedColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _pinAddress(pin),
                    style:
                        TextStyle(fontSize: 11.5, color: context.subtleColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
