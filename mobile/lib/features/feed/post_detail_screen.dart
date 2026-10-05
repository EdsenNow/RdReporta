import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/request_state.dart';
import '../../shared/widgets/report_post_sheet.dart';
import '../../shared/widgets/post_reaction_bar.dart';
import '../../shared/widgets/post_media_carousel.dart';

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

  String? _error;
  late ValueNotifier<int> _views;

  @override
  void dispose() {
    _views.removeListener(_viewsChanged);
    _apiClient.postViews.unwatch(widget.postId);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _watchViews();
    _loadPost();
    _recordDetailView();
  }

  void _watchViews() {
    _views = _apiClient.postViews.watch(
        widget.postId, widget.initialPost?.viewsCount ?? 0);
    _views.addListener(_viewsChanged);
  }

  void _viewsChanged() {
    if (mounted && _post != null) {
      setState(() => _post!.viewsCount = _views.value);
    }
  }

  Future<void> _recordDetailView() async {
    final count = await _apiClient.recordPostView(widget.postId);
    if (count != null && mounted && _post != null) {
      setState(() => _post!.viewsCount = count);
    }
  }

  Future<void> _loadPost() async {
    setState(() => _error = null);
    if (_post == null) setState(() => _loading = true);
    try {
      final fetched = await _apiClient.getPostById(widget.postId);
      if (mounted && fetched != null) {
        setState(() {
          _post = fetched;

          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _post = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ApiClient.errorMessage(e);
        });
      }
    }
  }

  void _showReportDialog() async {
    if (!await requireSession(context) || !mounted) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportPostSheet(postId: widget.postId),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(children: [
          Icon(Icons.check_circle_outline_rounded, size: 20),
          SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Denuncia enviada a moderación. Gracias por avisarnos.')),
        ]),
      ));
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return 'hace ${diff.inDays} ${diff.inDays == 1 ? "día" : "días"}';
    }
    if (diff.inHours > 0) {
      return 'hace ${diff.inHours} ${diff.inHours == 1 ? "hora" : "horas"}';
    }
    if (diff.inMinutes > 0) {
      return 'hace ${diff.inMinutes} ${diff.inMinutes == 1 ? "min" : "mins"}';
    }
    return 'hace un momento';
  }

  Widget _buildAuthorHeader(PostModel post, Color categoryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          backgroundImage:
              (post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(
                      _formatImageUrl(post.authorAvatarUrl!))
                  : null,
          child: (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty)
              ? Text(
                  post.authorDisplayName.isNotEmpty
                      ? post.authorDisplayName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.authorDisplayName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.textPrimaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.authorIsVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: context.pineColor, size: 16),
                  ]
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '@${post.authorUsername}',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.subtleColor,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '• ${_getRelativeTime(post.createdAt)}',
                      style: TextStyle(fontSize: 13, color: context.mutedColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  post.categoryName,
                  style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (post.status != 'Active') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf6c177).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.status,
                    style: const TextStyle(
                        color: Color(0xFFf6c177),
                        fontWeight: FontWeight.w600,
                        fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConstants.hostUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Detalle de incidencia')),
          body: RequestState(message: _error!, onRetry: _loadPost));
    }

    if (_loading && _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de incidencia')),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de incidencia')),
        body: Center(
          child: Text(
            'Incidencia no encontrada o retirada.',
            style: TextStyle(color: context.subtleColor),
          ),
        ),
      );
    }

    final post = _post!;
    Color categoryColor;
    try {
      categoryColor =
          Color(int.parse(post.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      categoryColor = theme.colorScheme.secondary;
    }



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_post);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: context.textPrimaryColor),
              onPressed: () => Navigator.of(context).pop(_post),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: IconButton(
                icon: Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                tooltip: 'Denunciar reporte',
                onPressed: _showReportDialog,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(children: [
            Expanded(child: PostReactionBar(post: post)),
            Icon(Icons.visibility_outlined,
                size: 20, color: context.subtleColor),
            const SizedBox(width: 6),
            Text('${post.viewsCount}',
                style: TextStyle(color: context.subtleColor)),
          ]),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: PostMediaCarousel(postId: post.id, images: post.images, videoUrl: post.videoUrl, detail: true),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorHeader(post, categoryColor),
                  const SizedBox(height: 20),
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta de Ubicación
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
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: theme.colorScheme.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                              'Ubicación georreferenciada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.textPrimaryColor,
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${post.municipality}, ${post.province}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        if (post.neighborhood != null &&
                            post.neighborhood!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Barrio o sector: ${post.neighborhood}',
                            style: TextStyle(
                              color: context.subtleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (post.addressReference != null &&
                            post.addressReference!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Referencia: ${post.addressReference}',
                            style: TextStyle(
                                fontSize: 13, color: context.subtleColor),
                          ),
                        ],
                        const SizedBox(height: 6),
                        if (post.latitude != null && post.longitude != null)
                          Text(
                            'Coordenadas: ${post.latitude!.toStringAsFixed(4)}, ${post.longitude!.toStringAsFixed(4)}',
                            style: TextStyle(
                                fontSize: 12, color: context.mutedColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}


