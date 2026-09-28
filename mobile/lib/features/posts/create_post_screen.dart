import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  String _selectedProvince = 'Distrito Nacional';
  String _selectedMunicipality = 'Santo Domingo';
  double _latitude = 18.4861;
  double _longitude = -69.9312;
  
  bool _loading = false;
  bool _fetchingCategories = true;
  bool _locatingGps = false;
  String? _gpsStatusText;

  final List<XFile> _selectedImages = [];

  final List<String> _provinces = [
    'Distrito Nacional', 'Santo Domingo', 'Santiago', 'La Vega', 
    'San Cristóbal', 'Puerto Plata', 'La Altagracia', 'San Pedro de Macorís', 
    'Duarte', 'La Romana', 'Espaillat', 'Azua', 'Peravia', 'Barahona'
  ];

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
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = await _apiClient.getCategories();
    setState(() {
      _categories = list;
      if (list.isNotEmpty) _selectedCategory = list.first;
      _fetchingCategories = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 4 imágenes por reporte ciudadano.')),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file != null) {
        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder a la cámara o galería.')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _locatingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor activa la localización GPS en tu dispositivo.')),
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
            const SnackBar(content: Text('Los permisos de GPS están deshabilitados permanentemente en ajustes.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _gpsStatusText = 'GPS: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Ubicación GPS obtenida con éxito.'),
            backgroundColor: AppTheme.confirmationGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fue posible obtener coordenadas GPS en este momento.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _loading = true);

    try {
      // 1. Subir imágenes seleccionadas
      List<String> uploadedUrls = [];
      for (var img in _selectedImages) {
        final url = await _apiClient.uploadImage(img.path);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      // 2. Crear reporte con coordenadas y URLs de fotos
      final res = await _apiClient.createPost(
        categoryId: _selectedCategory!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        province: _selectedProvince,
        municipality: _selectedMunicipality,
        latitude: _latitude,
        longitude: _longitude,
        addressReference: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
        imageUrls: uploadedUrls,
      );

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Reporte publicado con éxito! Gracias por tu colaboración ciudadana.'),
              backgroundColor: AppTheme.confirmationGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Error al publicar el reporte.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte Ciudadano'),
      ),
      body: _fetchingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    const Text(
                      'Categoría de la Incidencia',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CategoryModel>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 20),

                    // Título
                    const Text(
                      'Título Resumido',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Semáforo apagado en intersección crítica',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese un título' : null,
                    ),
                    const SizedBox(height: 20),

                    // Descripción
                    const Text(
                      'Descripción Detallada',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe lo que ocurre para que otros ciudadanos y autoridades puedan entenderlo...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese una descripción' : null,
                    ),
                    const SizedBox(height: 20),

                    // Fotos / Evidencias
                    const Text(
                      'Fotografías de Evidencia (Máx. 4)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: AppTheme.primaryBlue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ubicación en RD',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _locatingGps ? null : _detectLocation,
                                icon: _locatingGps
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location, size: 16),
                                label: const Text('Mi GPS', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                          if (_gpsStatusText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _gpsStatusText!,
                              style: const TextStyle(fontSize: 12, color: AppTheme.confirmationGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedProvince,
                            decoration: InputDecoration(
                              labelText: 'Provincia',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedProvince = val;
                                  _selectedMunicipality = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _referenceController,
                            decoration: InputDecoration(
                              labelText: 'Punto de referencia o calle',
                              hintText: 'Ej. Frente a la estación del metro o esquina...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Publicar Incidencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
