import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';
import '../../core/networking/api_client.dart';

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

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    Color categoryColor;
    try {
      categoryColor = Color(int.parse(post.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      categoryColor = AppTheme.primaryBlue;
    }

    return Card(
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
                    borderRadius: BorderRadius.circular(6),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Description
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            // Photos
            if (post.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: post.images.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            if (post.images.isNotEmpty) const SizedBox(height: 12),

            // Location pill
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${post.municipality}, ${post.province}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${post.viewsCount} vistas',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const Divider(height: 24),

            // Bottom Actions: "Confirmo" button + reactions
            Row(
              children: [
                // Highlighted Confirmation Button
                InkWell(
                  onTap: _onConfirmPressed,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _confirmed ? AppTheme.confirmationGreen : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _confirmed ? AppTheme.confirmationGreen : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: _confirmed ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Confirmo ($_confirmationsCount)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _confirmed ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // Reaction icons (No comments, no DMs!)
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded, size: 20),
                  tooltip: 'Importante',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Compartir',
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
