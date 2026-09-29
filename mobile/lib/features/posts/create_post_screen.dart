import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/request_state.dart';
import '../../core/constants/provinces.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();
  final Geocoding _geocoding =
      Geocoding(locale: const Locale('es', 'DO'));

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
  double _latitude = 0;
  double _longitude = 0;

  bool _loading = false;
  bool _fetchingCategories = true;
  bool _locatingGps = false;
  String? _gpsStatusText;

  final List<XFile> _selectedImages = [];

  final List<String> _provinces = dominicanProvinces;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                          child:
                              _categoryOption(category, selected: isSelected),
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

  Future<void> _detectLocation() async {
    setState(() => _locatingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Por favor, activa la ubicación GPS en tu dispositivo.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de GPS denegado.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Los permisos de GPS están deshabilitados permanentemente en ajustes.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      Placemark? place;
      try {
        final places = await _geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (places.isNotEmpty) place = places.first;
      } catch (_) {
        // Las coordenadas siguen siendo válidas aunque el dispositivo no
        // pueda resolver la dirección en este momento.
      }
      if (!mounted) return;
      final detectedProvince = _matchProvince(place?.administrativeArea);
      final municipality = (place?.locality?.trim().isNotEmpty ?? false)
          ? place!.locality!.trim()
          : (place?.subAdministrativeArea?.trim() ?? '');
      final neighborhood = place?.subLocality?.trim() ?? '';
      final detectedStreet = place?.street?.trim() ?? '';
      final street = detectedStreet.isNotEmpty
          ? detectedStreet
          : (place?.thoroughfare?.trim() ?? '');
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _latitudeController.text = _latitude.toStringAsFixed(6);
        _longitudeController.text = _longitude.toStringAsFixed(6);
        if (detectedProvince != null) _selectedProvince = detectedProvince;
        if (municipality.isNotEmpty) {
          _municipalityController.text = municipality;
        }
        if (neighborhood.isNotEmpty) {
          _neighborhoodController.text = neighborhood;
        }
        if (street.isNotEmpty) _referenceController.text = street;
        _gpsStatusText =
            place == null
                ? 'Coordenadas obtenidas. Completa los datos de la dirección.'
                : 'Ubicación y dirección completadas con el GPS.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación y dirección obtenidas con el GPS.'),
            backgroundColor: AppTheme.confirmationGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No fue posible obtener coordenadas GPS en este momento.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    if (!await requireSession(context)) return;
    if (!mounted) return;
    if (_loading) return;

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

      // 2. Crear reporte con coordenadas y URLs de fotos
      final res = await _apiClient.createPost(
        categoryId: _selectedCategory!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        province: _selectedProvince,
        municipality: _municipalityController.text.trim(),
        neighborhood: _neighborhoodController.text.trim().isNotEmpty
            ? _neighborhoodController.text.trim()
            : null,
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        addressReference: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        imageUrls: uploadedUrls,
      );

      if (mounted) {
        if (res['success'] == true) {
          _apiClient.notifyChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '¡Reporte publicado con éxito! Gracias por tu colaboración ciudadana.'),
              backgroundColor: AppTheme.confirmationGreen,
            ),
          );
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
                          'Título resumido',
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
                          'Descripción detallada',
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

                        // Fotos / Evidencias
                        Text(
                          'Fotografías de evidencia (máx. 4)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
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
                                side: BorderSide(color: context.borderColor, width: 2),
                                backgroundColor: context.surfaceColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                side: BorderSide(color: context.borderColor, width: 2),
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
                        const SizedBox(height: 20),

                        // Ubicación GPS & Geográfica
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.borderColor, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on,
                                          color: theme.colorScheme.secondary),
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
                                  TextButton.icon(
                                    onPressed:
                                        _locatingGps ? null : _detectLocation,
                                    icon: _locatingGps
                                        ? SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                          )
                                        : Icon(Icons.my_location,
                                            size: 16,
                                            color: theme.colorScheme.secondary),
                                    label: Text(
                                      'Mi GPS',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.secondary),
                                    ),
                                  ),
                                ],
                              ),
                              if (_gpsStatusText != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _gpsStatusText!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: RosePineDark.success,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                key: ValueKey(_selectedProvince),
                                isExpanded: true,
                                initialValue: _selectedProvince,
                                dropdownColor: context.surfaceColor,
                                decoration: const InputDecoration(
                                  labelText: 'Provincia',
                                ),
                                items: _provinces
                                    .map((p) => DropdownMenuItem(
                                        value: p, child: Text(p)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedProvince = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _municipalityController,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                    labelText: 'Municipio'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Indica el municipio de la incidencia'
                                    : null,
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
                                  'Las coordenadas se completan automáticamente con el GPS, pero también puedes introducirlas.'),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: TextFormField(
                                        controller: _latitudeController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true, signed: true),
                                        decoration: const InputDecoration(
                                            labelText: 'Latitud'),
                                        validator: (v) {
                                          final n =
                                              double.tryParse(v?.trim() ?? '');
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
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true, signed: true),
                                        decoration: const InputDecoration(
                                            labelText: 'Longitud'),
                                        validator: (v) {
                                          final n =
                                              double.tryParse(v?.trim() ?? '');
                                          return n == null ||
                                                  !n.isFinite ||
                                                  n < -180 ||
                                                  n > 180
                                              ? 'Longitud válida requerida'
                                              : null;
                                        })),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
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
