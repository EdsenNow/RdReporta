import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/networking/api_client.dart';
import '../../core/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/request_state.dart';
import '../../core/constants/provinces.dart';
import '../../core/constants/municipalities.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'location_picker_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();
  Geocoding get _geocoding => Geocoding(locale: const Locale('es', 'DO'));

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String? _categoryError;
  final Map<String, String> _uploadedImages = {};

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  String _selectedProvince = 'Distrito Nacional';
  Timer? _addressDebounce;
  int _addressRevision = 0;
  bool _resolvingAddress = false;

  bool _loading = false;
  bool _fetchingCategories = true;
  bool _locatingGps = false;
  String? _gpsStatusText;
  String _municipalitySearch = '';
  String _provinceSearch = '';

  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  String? _uploadedVideoUrl;

  final List<String> _provinces = dominicanProvinces;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressRevision++;
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _municipalityController.dispose();
    _neighborhoodController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Color _categoryColor(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.tryParse('FF$value', radix: 16) ?? 0xFFB4637A);
  }

  IconData _categoryIcon(CategoryModel category) {
    return switch (category.slug) {
      'accidentes' => Icons.car_crash_rounded,
      'transito' => Icons.traffic_rounded,
      'calles-vias' => Icons.add_road_rounded,
      'inundaciones' => Icons.water_rounded,
      'basura' => Icons.delete_outline_rounded,
      'servicios-publicos' => Icons.electrical_services_rounded,
      'emergencias' => Icons.emergency_rounded,
      'comunidad' => Icons.groups_rounded,
      'acontecimientos' => Icons.event_rounded,
      _ => Icons.report_problem_outlined,
    };
  }

  Widget _categoryOption(CategoryModel category, {bool selected = false}) {
    final color = _categoryColor(category.colorHex);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
          ),
          child: Icon(_categoryIcon(category), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: context.loveColor, size: 21),
        ],
      ],
    );
  }

  Future<void> _showCategoryPicker() async {
    final selected = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.68,
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: context.borderColor, width: 2),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.mutedColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selecciona una categoría',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 2, thickness: 2, color: context.borderColor),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.paddingOf(sheetContext).bottom,
                  ),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    return InkWell(
                      onTap: () => Navigator.pop(sheetContext, category),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.loveColor.withValues(alpha: 0.08)
                              : context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? context.loveColor
                                : context.borderColor,
                            width: 2,
                          ),
                        ),
                        child: _categoryOption(category, selected: isSelected),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _fetchingCategories = true;
      _categoryError = null;
    });
    try {
      final list = await _apiClient.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        if (list.isNotEmpty) _selectedCategory = list.first;
      });
    } catch (e) {
      if (mounted) setState(() => _categoryError = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _fetchingCategories = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Máximo 4 imágenes por reporte ciudadano.')),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file != null && mounted) {
        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo acceder a la cámara ni a la galería.')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _showVideoSourceDialog() async {
    if (_selectedVideo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya seleccionaste un video. Quítalo si deseas cambiarlo.'),
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.videocam_rounded, color: context.loveColor),
                title: Text('Grabar video con la cámara',
                    style: TextStyle(color: context.textPrimaryColor)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.video_library_rounded, color: context.loveColor),
                title: Text('Elegir video de la galería',
                    style: TextStyle(color: context.textPrimaryColor)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickVideo(source);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (file != null) {
        final controller = VideoPlayerController.file(File(file.path));
        try {
          await controller.initialize();
          if (controller.value.duration > const Duration(minutes: 3)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El video no puede superar los 3 minutos.'),
                ),
              );
            }
            return;
          }
        } finally {
          await controller.dispose();
        }
        final length = await file.length();
        if (length > 150 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El video no puede superar los 150 MB.'),
              ),
            );
          }
          return;
        }
        if (mounted) {
          setState(() {
            _selectedVideo = file;
            _uploadedVideoUrl = null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder al video seleccionado.')),
        );
      }
    }
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _uploadedVideoUrl = null;
    });
  }

  String _normalizedPlace(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('provincia de ', '')
      .replaceAll('province', '')
      .trim();

  String? _matchProvince(String? administrativeArea) {
    if (administrativeArea == null || administrativeArea.trim().isEmpty) {
      return null;
    }
    final normalized = _normalizedPlace(administrativeArea);
    if (normalized == 'national district') return 'Distrito Nacional';
    for (final province in _provinces) {
      final candidate = _normalizedPlace(province);
      if (normalized == candidate ||
          normalized.contains(candidate) ||
          candidate.contains(normalized)) {
        return province;
      }
    }
    return null;
  }

  bool _isLocationInDominicanRepublic(Position position, Placemark? place) {
    final countryCode = place?.isoCountryCode?.trim().toUpperCase();
    if (countryCode != null && countryCode.isNotEmpty && countryCode != 'DO') {
      return false;
    }

    return position.latitude >= 17.3 &&
        position.latitude <= 20.2 &&
        position.longitude >= -72.1 &&
        position.longitude <= -68.2;
  }

  Future<void> _detectLocation() async {
    if (_locatingGps) return;
    _addressDebounce?.cancel();
    final revision = ++_addressRevision;
    setState(() {
      _locatingGps = true;
      _resolvingAddress = false;
    });
    try {
      final position = await requestCurrentLocation();
      if (!mounted || revision != _addressRevision) return;
      if (!_isLocationInDominicanRepublic(position, null)) {
        const message =
            'El GPS detect\u00F3 una ubicaci\u00F3n fuera de Rep\u00FAblica Dominicana. Verifica la se\u00F1al GPS y vuelve a intentarlo.';
        setState(() => _gpsStatusText = message);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(message)),
        );
        return;
      }
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
      await _resolveCoordinateAddress(
        double.parse(_latitudeController.text),
        double.parse(_longitudeController.text),
        revision,
      );
    } catch (error) {
      if (mounted && revision == _addressRevision) {
        final failure = error is LocationRequestException ? error : null;
        final message = failure?.message ??
            'No fue posible obtener coordenadas GPS en este momento. Vuelve a intentarlo.';
        setState(() => _gpsStatusText = message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: failure?.settingsAction == null
                ? null
                : SnackBarAction(
                    label: 'Abrir ajustes',
                    onPressed: () async {
                      if (failure!.settingsAction ==
                          LocationSettingsAction.app) {
                        await Geolocator.openAppSettings();
                      } else {
                        await Geolocator.openLocationSettings();
                      }
                    },
                  ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  String get _detectedAddressSummary {
    final parts = <String>[];
    if (_referenceController.text.trim().isNotEmpty) {
      parts.add(_referenceController.text.trim());
    }
    if (_neighborhoodController.text.trim().isNotEmpty) {
      parts.add(_neighborhoodController.text.trim());
    }
    if (_municipalityController.text.trim().isNotEmpty) {
      parts.add(_municipalityController.text.trim());
    }
    if (_selectedProvince.trim().isNotEmpty &&
        _selectedProvince.trim() != _municipalityController.text.trim()) {
      parts.add(_selectedProvince.trim());
    }
    return parts.join(', ');
  }

  Future<void> _openMapLocationPicker() async {
    if (_loading || _locatingGps) return;
    _addressDebounce?.cancel();

    double? initLat = double.tryParse(_latitudeController.text.trim());
    double? initLng = double.tryParse(_longitudeController.text.trim());

    final selected = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: initLat,
          initialLongitude: initLng,
        ),
      ),
    );

    if (!mounted || selected == null) return;

    final revision = ++_addressRevision;
    setState(() {
      _latitudeController.text = selected.latitude.toStringAsFixed(6);
      _longitudeController.text = selected.longitude.toStringAsFixed(6);
      _resolvingAddress = true;
      _gpsStatusText = 'Buscando la dirección de las coordenadas seleccionadas…';
    });

    await _resolveCoordinateAddress(
      selected.latitude,
      selected.longitude,
      revision,
    );
  }


  Future<void> _submit() async {
    if (_loading || _locatingGps || _resolvingAddress) return;
    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();
    if (latitudeText.isNotEmpty != longitudeText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa ambas coordenadas o déjalas vacías.'),
      ));
      return;
    }
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    if (!await requireSession(context)) return;
    if (!mounted) return;
    if (_loading || _locatingGps || _resolvingAddress) return;

    setState(() => _loading = true);

    try {
      // 1. Subir imágenes seleccionadas
      List<String> uploadedUrls = [];
      for (var img in _selectedImages) {
        final url =
            _uploadedImages[img.path] ?? await _apiClient.uploadImage(img.path);
        if (url == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'No se pudo subir una foto. Tu reporte sigue aquí; vuelve a intentarlo.')));
          }
          return;
        }
        _uploadedImages[img.path] = url;
        uploadedUrls.add(url);
      }

      // 2. Subir video seleccionado si existe
      String? uploadedVideoUrl = _uploadedVideoUrl;
      if (_selectedVideo != null && (uploadedVideoUrl == null || uploadedVideoUrl.isEmpty)) {
        try {
          uploadedVideoUrl = await _apiClient.uploadVideo(_selectedVideo!.path);
          _uploadedVideoUrl = uploadedVideoUrl;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al subir el video: ${ApiClient.errorMessage(e)}'),
            ));
          }
          return;
        }
        if (uploadedVideoUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'No se pudo subir el video. Tu reporte sigue aquí; vuelve a intentarlo.')));
          }
          return;
        }
      }

      // 3. Crear reporte con coordenadas, fotos y video
      final res = await _apiClient.createPost(
        categoryId: _selectedCategory!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        province: _selectedProvince,
        municipality: _municipalityController.text.trim(),
        neighborhood: _neighborhoodController.text.trim().isNotEmpty
            ? _neighborhoodController.text.trim()
            : null,
        latitude: latitudeText.isEmpty ? null : double.parse(latitudeText),
        longitude: longitudeText.isEmpty ? null : double.parse(longitudeText),
        addressReference: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        imageUrls: uploadedUrls,
        videoUrl: uploadedVideoUrl,
      );

      if (mounted) {
        if (res['success'] == true) {
          _apiClient.notifyChanged();
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
            backgroundColor: context.surfaceColor,
            elevation: 8,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.borderColor, width: 2),
            ),
            content: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.successColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_rounded, color: context.successColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reporte publicado',
                        style: TextStyle(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Tu comunidad ya puede verlo.',
                        style: TextStyle(
                            color: context.subtleColor, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ??
                  'Error al publicar el reporte.'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error inesperado al conectar con el servidor.'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleCoordinatePaste(String value) {
    _addressDebounce?.cancel();
    final revision = ++_addressRevision;
    final match = RegExp(
      r'^\s*\(?\s*([+-]?\d+(?:\.\d+)?)\s*[,;]\s*([+-]?\d+(?:\.\d+)?)\s*\)?\s*$',
    ).firstMatch(value);
    if (match != null) {
      final latitude = match.group(1)!;
      final longitude = match.group(2)!;
      _latitudeController.value = TextEditingValue(
        text: latitude,
        selection: TextSelection.collapsed(offset: latitude.length),
      );
      _longitudeController.value = TextEditingValue(
        text: longitude,
        selection: TextSelection.collapsed(offset: longitude.length),
      );
    }
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final valid = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    setState(() {
      _resolvingAddress = valid;
      _gpsStatusText =
          valid ? 'Buscando la dirección de las coordenadas…' : null;
    });
    if (!valid) return;
    _addressDebounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(_resolveCoordinateAddress(latitude, longitude, revision));
    });
  }

  String? _municipalityFromPlace(Placemark place) {
    const aliases = {
      'santo domingo de guzman': 'Santo Domingo',
      'distrito nacional': 'Santo Domingo',
      'bajos de haina': 'Haina',
      'san juan de la maguana': 'San Juan',
      'san gregorio de nigua': 'Nigua',
      'eugenio maria de hostos': 'Hostos',
      'san ignacio de sabaneta': 'Sabaneta',
      'san jose de los llanos': 'Los Llanos',
    };
    for (final candidate in [place.subAdministrativeArea, place.locality]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      final normalized = _normalizedPlace(candidate);
      if (aliases.containsKey(normalized)) return aliases[normalized];
      for (final municipality in dominicanMunicipalities) {
        if (_normalizedPlace(municipality) == normalized) return municipality;
      }
    }
    return null;
  }

  Future<void> _resolveCoordinateAddress(
      double latitude, double longitude, int revision) async {
    if (!mounted || revision != _addressRevision) return;
    setState(() {
      _resolvingAddress = true;
      _gpsStatusText = 'Buscando la dirección de las coordenadas…';
    });
    try {
      final places = await _geocoding
          .placemarkFromCoordinates(latitude, longitude,
              locale: const Locale('es', 'DO'))
          .timeout(const Duration(seconds: 12));
      if (!mounted || revision != _addressRevision) return;
      if (places.isEmpty) {
        setState(() => _gpsStatusText =
            'No se encontró una dirección. Revisa o completa los campos manualmente.');
        return;
      }
      final place = places.first;
      final country = place.isoCountryCode?.trim().toUpperCase();
      if ((country != null && country.isNotEmpty && country != 'DO') ||
          latitude < 17.3 ||
          latitude > 20.2 ||
          longitude < -72.1 ||
          longitude > -68.2) {
        setState(() => _gpsStatusText =
            'Las coordenadas están fuera de República Dominicana. Revisa la ubicación.');
        return;
      }
      final province = _matchProvince(place.administrativeArea);
      final municipality = _municipalityFromPlace(place);
      final neighborhood = place.subLocality?.trim() ?? '';
      // Android may return the full postal address in `street`.
      // Use the separate road and house-number fields instead.
      final street = place.thoroughfare?.trim() ?? '';
      final number = place.subThoroughfare?.trim() ?? '';
      final reference = street.isEmpty
          ? ''
          : [street, if (number.isNotEmpty) number].join(' ');
      setState(() {
        _selectedProvince = province ?? '';
        _municipalityController.text = municipality ?? '';
        _neighborhoodController.text = neighborhood;
        // Replace previous address values so a different street is not retained.
        _referenceController.text = reference;
        _gpsStatusText = province != null &&
                municipality != null &&
                reference.isNotEmpty
            ? 'Dirección completada a partir de las coordenadas. Revisa los datos antes de publicar.'
            : 'Se completaron los datos disponibles. Revisa la dirección y completa los campos vacíos.';
      });
    } catch (_) {
      if (mounted && revision == _addressRevision) {
        setState(() => _gpsStatusText =
            'No se pudo consultar la dirección. Revisa tu conexión y los datos de ubicación antes de publicar.');
      }
    } finally {
      if (mounted && revision == _addressRevision) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  void _clearCoordinates() {
    _addressDebounce?.cancel();
    _addressRevision++;
    setState(() {
      _latitudeController.clear();
      _longitudeController.clear();
      _resolvingAddress = false;
      _gpsStatusText = null;
    });
  }

  Future<void> _showMunicipalityPicker(FormFieldState<String> field) async {
    _municipalitySearch = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = _municipalitySearch.toLowerCase().trim();
          final options = dominicanMunicipalities
              .where((name) => name.toLowerCase().contains(query))
              .toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .72,
              child: Column(children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Selecciona un municipio',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor))),
                const SizedBox(height: 14),
                TextField(
                  autofocus: true,
                  onChanged: (value) =>
                      setSheetState(() => _municipalitySearch = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar municipio',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                    child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final name = options[index];
                    final isSelected = name == _municipalityController.text;
                    return ListTile(
                      title: Text(name),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, name),
                    );
                  },
                )),
              ]),
            ),
          );
        },
      ),
    );
    if (selected != null) {
      _municipalityController.text = selected;
      field.didChange(selected);
    }
  }

  Future<void> _showProvincePicker(FormFieldState<String> field) async {
    _provinceSearch = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = _provinceSearch.toLowerCase().trim();
          final options = _provinces
              .where((name) => name.toLowerCase().contains(query))
              .toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .72,
              child: Column(children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecciona una provincia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  autofocus: true,
                  onChanged: (value) =>
                      setSheetState(() => _provinceSearch = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar provincia',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final name = options[index];
                      final isSelected = name == _selectedProvince;
                      return ListTile(
                        title: Text(name),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, name),
                      );
                    },
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
    if (selected != null) {
      setState(() => _selectedProvince = selected);
      field.didChange(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo reporte ciudadano'),
      ),
      body: _fetchingCategories
          ? Center(
              child: CircularProgressIndicator(
                  color: theme.colorScheme.primary, strokeWidth: 2.5))
          : _categoryError != null || _categories.isEmpty
              ? RequestState(
                  message: _categoryError ??
                      'No hay categorías disponibles todavía.',
                  onRetry: _loadCategories)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categoría
                        Text(
                          'Categoría de la incidencia',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showCategoryPicker,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: context.borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _categoryOption(_selectedCategory!),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    color: context.loveColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Título
                        Text(
                          'Título',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            hintText:
                                'Ej.: semáforo apagado en una intersección crítica',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Ingrese un título'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Descripción
                        Text(
                          'Descripción',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLength: 5000,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Describe lo que ocurre para que otros ciudadanos y autoridades puedan entenderlo…',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Ingrese una descripción'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Fotos y Video / Evidencias
                        Text(
                          'Evidencias (máx. 4 fotos y 1 video)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: Icon(Icons.camera_alt,
                                  color: theme.colorScheme.secondary),
                              label: Text('Cámara',
                                  style: TextStyle(
                                      color: context.textPrimaryColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: context.borderColor, width: 2),
                                backgroundColor: context.surfaceColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                              icon: Icon(Icons.photo_library,
                                  color: theme.colorScheme.secondary),
                              label: Text('Galería',
                                  style: TextStyle(
                                      color: context.textPrimaryColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: context.borderColor, width: 2),
                                backgroundColor: context.surfaceColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : _showVideoSourceDialog,
                              icon: Icon(Icons.videocam_rounded,
                                  color: theme.colorScheme.secondary),
                              label: Text('Video',
                                  style: TextStyle(
                                      color: context.textPrimaryColor)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: context.borderColor, width: 2),
                                backgroundColor: context.surfaceColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Lista de fotos seleccionadas
                        if (_selectedImages.isNotEmpty)
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              separatorBuilder: (_, __) =>
                                   const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(_selectedImages[index].path),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: _loading
                                            ? null
                                            : () => _removeImage(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close,
                                              size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        // Video seleccionado
                        if (_selectedVideo != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: context.loveColor.withValues(alpha: 0.4),
                                  width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.loveColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.videocam_rounded,
                                      color: context.loveColor, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedVideo!.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: context.textPrimaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Video de evidencia adjunto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.subtleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  color: context.subtleColor,
                                  onPressed: _loading ? null : _removeVideo,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Ubicación GPS & Geográfica
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: context.borderColor, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: context.loveColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ubicación en RD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _loading || _locatingGps
                                          ? null
                                          : _detectLocation,
                                      icon: _locatingGps
                                          ? SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: context.loveColor,
                                              ),
                                            )
                                          : Icon(Icons.my_location,
                                              size: 16,
                                              color: context.loveColor),
                                      label: Text(
                                        'Mi GPS',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.loveColor,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.loveColor
                                              .withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        backgroundColor: context.loveColor
                                            .withValues(alpha: 0.08),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _loading || _locatingGps
                                          ? null
                                          : _openMapLocationPicker,
                                      icon: Icon(Icons.map_outlined,
                                          size: 16,
                                          color: context.loveColor),
                                      label: Text(
                                        'Elegir en mapa',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.loveColor,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.loveColor
                                              .withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        backgroundColor: context.loveColor
                                            .withValues(alpha: 0.08),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_detectedAddressSummary.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context.loveColor
                                        .withValues(alpha: 0.07),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: context.loveColor
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.place_rounded,
                                          size: 16,
                                          color: context.loveColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _detectedAddressSummary,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimaryColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_gpsStatusText != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _gpsStatusText!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.subtleColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 12),
                              FormField<String>(
                                initialValue: _selectedProvince,
                                validator: (_) => _selectedProvince.isEmpty
                                    ? 'Selecciona la provincia de la incidencia'
                                    : null,
                                builder: (field) => InkWell(
                                  onTap: _loading
                                      ? null
                                      : () => _showProvincePicker(field),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Provincia',
                                      errorText: field.errorText,
                                      suffixIcon:
                                          const Icon(Icons.expand_more_rounded),
                                    ),
                                    child: Text(
                                      _selectedProvince.isEmpty
                                          ? 'Selecciona una provincia'
                                          : _selectedProvince,
                                      style: TextStyle(
                                          color: context.textPrimaryColor),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FormField<String>(
                                initialValue: _municipalityController.text,
                                validator: (value) =>
                                    _municipalityController.text.trim().isEmpty
                                        ? 'Indica el municipio de la incidencia'
                                        : null,
                                builder: (field) => InkWell(
                                  onTap: _loading
                                      ? null
                                      : () => _showMunicipalityPicker(field),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Municipio',
                                      errorText: field.errorText,
                                      suffixIcon:
                                          const Icon(Icons.expand_more_rounded),
                                    ),
                                    child: Text(
                                      _municipalityController.text.isEmpty
                                          ? 'Selecciona un municipio'
                                          : _municipalityController.text,
                                      style: TextStyle(
                                        color:
                                            _municipalityController.text.isEmpty
                                                ? context.subtleColor
                                                : context.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _neighborhoodController,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                  labelText: 'Barrio o sector',
                                  hintText: 'Ej.: Los Prados',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _referenceController,
                                maxLength: 255,
                                decoration: const InputDecoration(
                                  labelText: 'Calle o punto de referencia',
                                  hintText:
                                      'Ej.: frente a la estación del metro…',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                  'Al pegar coordenadas o usar el GPS, completaremos la dirección disponible. También puedes dejarlas vacías.'),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: TextFormField(
                                        controller: _latitudeController,
                                        readOnly: _loading,
                                        onChanged: _handleCoordinatePaste,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true, signed: true),
                                        decoration: const InputDecoration(
                                            labelText: 'Latitud'),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return null;
                                          }
                                          final n = double.tryParse(v.trim());
                                          return n == null ||
                                                  !n.isFinite ||
                                                  n < -90 ||
                                                  n > 90
                                              ? 'Latitud válida requerida'
                                              : null;
                                        })),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: TextFormField(
                                        controller: _longitudeController,
                                        readOnly: _loading,
                                        onChanged: _handleCoordinatePaste,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true, signed: true),
                                        decoration: const InputDecoration(
                                            labelText: 'Longitud'),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return null;
                                          }
                                          final n = double.tryParse(v.trim());
                                          return n == null ||
                                                  !n.isFinite ||
                                                  n < -180 ||
                                                  n > 180
                                              ? 'Longitud válida requerida'
                                              : null;
                                        })),
                              ]),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _loading ||
                                          (_latitudeController.text.isEmpty &&
                                              _longitudeController.text.isEmpty)
                                      ? null
                                      : _clearCoordinates,
                                  icon: const Icon(Icons.location_off_outlined),
                                  label: const Text('Quitar coordenadas'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                _loading || _locatingGps || _resolvingAddress
                                    ? null
                                    : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Publicar incidencia',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
