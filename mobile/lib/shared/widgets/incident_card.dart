import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/constants/api_constants.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';
import '../../features/feed/post_detail_screen.dart';
import '../../features/profile/public_profile_screen.dart';
import 'post_reaction_bar.dart';
import 'post_media_carousel.dart';

class IncidentCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onDelete;
  final bool deleting;
  final bool showViewsInsteadOfShare;

  const IncidentCard({
    super.key,
    required this.post,
    this.onDelete,
    this.deleting = false,
    this.showViewsInsteadOfShare = true,
  });

  @override
  State<IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<IncidentCard>
    with WidgetsBindingObserver {
  final ApiClient _apiClient = ApiClient();
  Timer? _impressionTimer;
  bool _visible = false;
  bool _foreground = true;
  bool _currentRoute = false;
  late ValueNotifier<int> _views;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _watchViews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    _updateImpressionTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateImpressionTimer();
  }

  void _watchViews() {
    _views = _apiClient.postViews.watch(widget.post.id, widget.post.viewsCount);
    _views.addListener(_viewsChanged);
    widget.post.viewsCount = _views.value;
  }

  void _viewsChanged() {
    if (mounted) setState(() => widget.post.viewsCount = _views.value);
  }

  @override
  void didUpdateWidget(covariant IncidentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _impressionTimer?.cancel();
      _impressionTimer = null;
      _views.removeListener(_viewsChanged);
      _apiClient.postViews.unwatch(oldWidget.post.id);
      _watchViews();
      _updateImpressionTimer();
    } else {
      final count = widget.post.viewsCount;
      final id = widget.post.id;
      scheduleMicrotask(() => _apiClient.postViews.update(id, count));
      widget.post.viewsCount = _views.value;
    }
  }

  void _visibilityChanged(VisibilityInfo info) {
    _visible = info.visibleFraction >= 0.5;
    _updateImpressionTimer();
  }

  void _updateImpressionTimer() {
    if (!_visible || !_foreground || !_currentRoute) {
      _impressionTimer?.cancel();
      _impressionTimer = null;
      return;
    }
    if (_impressionTimer != null) return;
    _impressionTimer = Timer(const Duration(seconds: 5), () async {
      final count = await _apiClient.recordPostView(widget.post.id);
      if (count != null && mounted) {
        setState(() => widget.post.viewsCount = _views.value);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _impressionTimer?.cancel();
    _views.removeListener(_viewsChanged);
    _apiClient.postViews.unwatch(widget.post.id);
    super.dispose();
  }

  String _formatTwitterTime(DateTime createdAt) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.isNegative || difference.inSeconds < 60) {
      final secs = difference.inSeconds.clamp(1, 59);
      return '${secs}s';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }
    final local = createdAt.toLocal();
    final month = months[local.month - 1];
    if (local.year == now.year) {
      return '${local.day} $month';
    }
    return '${local.day} $month ${local.year}';
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
      categoryColor =
          Color(int.parse(post.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      categoryColor = Theme.of(context).colorScheme.secondary;
    }

    return VisibilityDetector(
      key: Key('post-impression-${post.id}-${identityHashCode(this)}'),
      onVisibilityChanged: _visibilityChanged,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.isDarkMode
                ? const Color(0x1AFFFFFF)
                : context.borderColor,
            width: context.isDarkMode ? 1.2 : 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final updatedPost = await Navigator.push<PostModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(
                    postId: widget.post.id,
                    initialPost: widget.post,
                  ),
                ),
              );
              if (updatedPost != null && mounted) {
                setState(() {
                  widget.post.viewsCount = _views.value;
                  widget.post.reactionsCount = updatedPost.reactionsCount;
                  widget.post.userReaction = updatedPost.userReaction;
                  widget.post.reactionCounts =
                      Map<String, int>.from(updatedPost.reactionCounts);
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Twitter/X style header: circular avatar, author name, handle (with ellipsis) and relative time underneath, and category badge on right.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicProfileScreen(userId: post.userId),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: context.overlayColor,
                          child: ClipOval(
                            child: post.authorAvatarUrl == null ||
                                    post.authorAvatarUrl!.isEmpty
                                ? Text(
                                    post.authorDisplayName.isNotEmpty
                                        ? post.authorDisplayName[0]
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: context.loveColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl:
                                        _formatImageUrl(post.authorAvatarUrl!),
                                    width: 38,
                                    height: 38,
                                    memCacheWidth: 150,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Center(
                                      child: Text(
                                        post.authorDisplayName.isNotEmpty
                                            ? post.authorDisplayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: context.loveColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PublicProfileScreen(userId: post.userId),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.authorDisplayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  if (post.authorIsVerified) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.verified_rounded,
                                        size: 15, color: context.pineColor),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '@${post.authorUsername}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: context.subtleColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' · ${_formatTwitterTime(post.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: context.subtleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.28),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            post.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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

                  if (post.images.isNotEmpty ||
                      (post.videoUrl?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostMediaCarousel(
                          key: ValueKey(post.id),
                          postId: post.id,
                          images: post.images,
                          videoUrl: post.videoUrl),
                    ),

                  // Location pill
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: context.mutedColor),
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
                      if (!widget.showViewsInsteadOfShare)
                        Text(
                          '${post.viewsCount} vistas',
                          style: TextStyle(
                              fontSize: 12, color: context.mutedColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reactions and actions (views or share).
                  Row(
                    children: [
                      Expanded(child: PostReactionBar(post: post)),
                      if (widget.showViewsInsteadOfShare)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 19,
                                color: context.subtleColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${post.viewsCount}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.subtleColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.share_outlined,
                              size: 20, color: context.subtleColor),
                          tooltip: 'Copiar reporte',
                          onPressed: () async {
                            final coordinates = post.latitude != null &&
                                    post.longitude != null
                                ? '\nUbicaciÃ³n: ${post.latitude}, ${post.longitude}'
                                : '';
                            await Clipboard.setData(ClipboardData(
                                text:
                                    '${post.title}\n${post.description}\n${post.municipality}, ${post.province}$coordinates\nRDReporta Â· ${post.id}'));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Reporte copiado. Puedes compartirlo donde prefieras.')));
                            }
                          },
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          tooltip: 'Eliminar reporte',
                          onPressed: widget.deleting ? null : widget.onDelete,
                          icon: widget.deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.delete_outline_rounded,
                                  size: 20, color: context.loveColor),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
