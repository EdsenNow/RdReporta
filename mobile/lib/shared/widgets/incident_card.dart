import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';
import '../../core/networking/api_client.dart';
import '../../features/feed/post_detail_screen.dart';

class IncidentCard extends StatefulWidget {
  final PostModel post;

  const IncidentCard({super.key, required this.post});

  @override
  State<IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<IncidentCard> {
  final ApiClient _apiClient = ApiClient();
  late bool _confirmed;
  late int _confirmationsCount;

  @override
  void initState() {
    super.initState();
    _confirmed = widget.post.userHasConfirmed;
    _confirmationsCount = widget.post.confirmationsCount;
  }

  void _onConfirmPressed() async {
    setState(() {
      _confirmed = !_confirmed;
      _confirmationsCount += _confirmed ? 1 : -1;
    });

    final success = await _apiClient.confirmPost(widget.post.id);
    if (!success && mounted) {
      // Revert if request failed
      setState(() {
        _confirmed = !_confirmed;
        _confirmationsCount += _confirmed ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la confirmación')),
      );
    }
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConstants.hostUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    Color categoryColor;
    try {
      categoryColor = Color(int.parse(post.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      categoryColor = Theme.of(context).colorScheme.secondary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode ? const Color(0x1AFFFFFF) : context.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  postId: post.id,
                  initialPost: post,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header: Category badge & Author
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      post.categoryName,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '@${post.authorUsername}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.subtleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Description
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: context.subtleColor,
                ),
              ),
              const SizedBox(height: 12),

              // Photos
              if (post.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _formatImageUrl(post.images.first),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: context.overlayColor,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              if (post.images.isNotEmpty) const SizedBox(height: 12),

              // Location pill
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: context.mutedColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${post.municipality}, ${post.province}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.subtleColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${post.viewsCount} vistas',
                    style: TextStyle(fontSize: 12, color: context.mutedColor),
                  ),
                ],
              ),
              Divider(height: 24, color: context.borderColor),

              // Bottom Actions: "Confirmo" button + reactions
              Row(
                children: [
                  // Highlighted Confirmation Button
                  InkWell(
                    onTap: _onConfirmPressed,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _confirmed
                            ? RosePineDark.success
                            : context.overlayColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _confirmed
                              ? RosePineDark.success
                              : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: _confirmed ? Colors.white : context.subtleColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Confirmo ($_confirmationsCount)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _confirmed ? Colors.white : context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Reaction icons (No comments, no DMs!)
                  IconButton(
                    icon: Icon(Icons.warning_amber_rounded, size: 20, color: context.subtleColor),
                    tooltip: 'Importante',
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.share_outlined, size: 20, color: context.subtleColor),
                    tooltip: 'Compartir',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
