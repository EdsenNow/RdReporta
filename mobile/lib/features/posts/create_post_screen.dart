import 'package:flutter/material.dart';
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

  final List<String> _provinces = [
    'Distrito Nacional', 'Santo Domingo', 'Santiago', 'La Vega', 
    'San Cristóbal', 'Puerto Plata', 'La Altagracia', 'San Pedro de Macorís', 
    'Duarte', 'La Romana'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _apiClient.getCategories();
    setState(() {
      _categories = list;
      if (list.isNotEmpty) _selectedCategory = list.first;
      _fetchingCategories = false;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _loading = true);

    try {
      // Simulate API call to /posts
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte publicado con éxito! Gracias por tu colaboración.'),
            backgroundColor: AppTheme.confirmationGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el reporte.')),
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
                    const Text(
                      'Categoría de la Incidencia',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
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

                    // Location Card
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
                            children: const [
                              Icon(Icons.location_on, color: AppTheme.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                'Ubicación en República Dominicana',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedProvince,
                            decoration: InputDecoration(
                              labelText: 'Provincia',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) => setState(() => _selectedProvince = val!),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _referenceController,
                            decoration: InputDecoration(
                              labelText: 'Punto de referencia o calle',
                              hintText: 'Ej. Frente a la estación del metro...',
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
                            : const Text('Publicar Incidencia', style: TextStyle(fontSize: 16, fontWeight: 'bold')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
