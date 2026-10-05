import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/location_service.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla modal interactiva para seleccionar una ubicación en el mapa de República Dominicana.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Coordenadas centrales por defecto (Santo Domingo / RD)
  static const LatLng _defaultCenter = LatLng(18.4861, -69.9312);

  // Límites geográficos de República Dominicana
  static const double _minLat = 17.3;
  static const double _maxLat = 20.2;
  static const double _minLng = -72.1;
  static const double _maxLng = -68.2;

  GoogleMapController? _mapController;
  late LatLng _selectedLocation;
  bool _locatingGps = false;

  bool _isWithinDR(LatLng loc) =>
      loc.latitude >= _minLat &&
      loc.latitude <= _maxLat &&
      loc.longitude >= _minLng &&
      loc.longitude <= _maxLng;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null &&
        widget.initialLongitude != null &&
        _isWithinDR(LatLng(widget.initialLatitude!, widget.initialLongitude!))) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedLocation = _defaultCenter;
    }
  }

  Future<void> _goToMyLocation() async {
    if (_locatingGps) return;
    setState(() => _locatingGps = true);
    try {
      final pos = await requestCurrentLocation();
      final target = LatLng(pos.latitude, pos.longitude);
      if (!_isWithinDR(target)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tu GPS indica una ubicación fuera de República Dominicana.'),
          ),
        );
        return;
      }
      setState(() => _selectedLocation = target);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible obtener tu ubicación GPS actual.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  void _confirmSelection() {
    if (!_isWithinDR(_selectedLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Selecciona un punto dentro del territorio de República Dominicana.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final inDR = _isWithinDR(_selectedLocation);

    return Scaffold(
      backgroundColor: context.baseColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: Text(
          'Seleccionar ubicación',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: inDR ? _confirmSelection : null,
            child: Text(
              'Confirmar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: inDR ? context.loveColor : context.mutedColor,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mapa interactivo de Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: widget.initialLatitude != null ? 16.0 : 13.5,
            ),
            cameraTargetBounds: CameraTargetBounds(
              LatLngBounds(
                southwest: const LatLng(_minLat, _minLng),
                northeast: const LatLng(_maxLat, _maxLng),
              ),
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(7.0, 20.0),
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (ctrl) => _mapController = ctrl,
            onCameraMove: (pos) {
              setState(() => _selectedLocation = pos.target);
            },
            onTap: (pos) {
              setState(() => _selectedLocation = pos);
              _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
            },
          ),

          // 2. Pin central flotante con animación/sombra
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: inDR ? context.loveColor : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      inDR
                          ? 'Mueve el mapa para ubicar'
                          : 'Punto fuera de RD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: inDR
                            ? context.textPrimaryColor
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.location_pin,
                    size: 46,
                    color: inDR ? context.loveColor : Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // 3. Botón flotante para centrar en Mi GPS
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'picker_my_location',
              onPressed: _goToMyLocation,
              backgroundColor: context.surfaceColor,
              foregroundColor: context.loveColor,
              elevation: 4,
              child: _locatingGps
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.loveColor,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // 4. Panel inferior de información y confirmación
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.loveColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.place_rounded,
                            size: 20, color: context.loveColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coordenadas seleccionadas',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.subtleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: inDR ? _confirmSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.loveColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Usar esta ubicación',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
