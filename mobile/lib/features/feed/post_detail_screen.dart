import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final PostModel? initialPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  PostModel? _post;
  bool _loading = false;
  late bool _confirmed;
  late int _confirmationsCount;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _confirmed = widget.initialPost?.userHasConfirmed ?? false;
    _confirmationsCount = widget.initialPost?.confirmationsCount ?? 0;
    _loadPost();
  }

  Future<void> _loadPost() async {
    if (_post == null) setState(() => _loading = true);
    final fetched = await _apiClient.getPostById(widget.postId);
    if (mounted && fetched != null) {
      setState(() {
        _post = fetched;
        _confirmed = fetched.userHasConfirmed;
        _confirmationsCount = fetched.confirmationsCount;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _toggleConfirm() async {
    if (_post == null) return;
    setState(() {
      _confirmed = !_confirmed;
      _confirmationsCount += _confirmed ? 1 : -1;
    });

    final success = await _apiClient.confirmPost(_post!.id);
    if (!success && mounted) {
      setState(() {
        _confirmed = !_confirmed;
        _confirmationsCount += _confirmed ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la confirmación')),
      );
    }
  }

  void _showReportDialog() {
    String selectedReason = 'InformacionFalsa';
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reportar Incidencia',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Text(
                    'Ayúdanos a mantener la calidad y veracidad informativa en la comunidad.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Motivo del Reporte',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'InformacionFalsa', child: Text('Información falsa o engañosa')),
                      DropdownMenuItem(value: 'Duplicado', child: Text('Incidencia duplicada o repetida')),
                      DropdownMenuItem(value: 'Spam', child: Text('Publicidad, spam o irrelevante')),
                      DropdownMenuItem(value: 'ContenidoInapropiado', child: Text('Contenido ofensivo o inapropiado')),
                      DropdownMenuItem(value: 'Resuelto', child: Text('Ya fue resuelto en la vía pública')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe brevemente la anomalía (opcional)...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final ok = await _apiClient.reportPost(
                          postId: widget.postId,
                          reason: selectedReason,
                          description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Denuncia enviada a moderación. ¡Gracias!'
                                  : 'Ya has reportado esta publicación anteriormente.'),
                              backgroundColor: ok ? AppTheme.confirmationGreen : AppTheme.accentRed,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
                      child: const Text('Enviar Denuncia'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConstants.hostUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Incidencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Incidencia')),
        body: const Center(child: Text('Incidencia no encontrada o retirada.')),
      );
    }

    final post = _post!;
    Color categoryColor;
    try {
      categoryColor = Color(int.parse(post.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      categoryColor = AppTheme.primaryBlue;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Incidencia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.red),
            tooltip: 'Denunciar reporte',
            onPressed: _showReportDialog,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleConfirm,
                  icon: Icon(_confirmed ? Icons.check_circle : Icons.check_circle_outline),
                  label: Text(
                    _confirmed ? 'Confirmado por ti ($_confirmationsCount)' : 'Confirmar Incidencia ($_confirmationsCount)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _confirmed ? AppTheme.confirmationGreen : AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galería de Imágenes
            if (post.images.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      itemCount: post.images.length,
                      onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: _formatImageUrl(post.images[index]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  if (post.images.length > 1)
                    Positioned(
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(post.images.length, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == i ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i ? Colors.white : Colors.white60,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Categoría y Estado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.categoryName,
                          style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: post.status == 'Active' ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.status == 'Active' ? 'Activa' : post.status,
                          style: TextStyle(
                            color: post.status == 'Active' ? Colors.green[800] : Colors.orange[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    post.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Autor y Nivel
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text(
                          post.authorUsername.isNotEmpty ? post.authorUsername[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${post.authorUsername}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            post.authorReputation,
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${post.viewsCount} visualizaciones',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Descripción Completa
                  const Text(
                    'Detalles del Incidente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta de Ubicación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
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
                              'Ubicación Georreferenciada',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${post.municipality}, ${post.province}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (post.addressReference != null && post.addressReference!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Referencia: ${post.addressReference}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Coordenadas: ${post.latitude.toStringAsFixed(4)}, ${post.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Validación Ciudadana
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppTheme.confirmationGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_confirmationsCount Confirmaciones Ciudadanas',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A1E),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Los ciudadanos avalan la veracidad de este reporte.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
