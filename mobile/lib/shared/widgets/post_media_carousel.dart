import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'post_video_player.dart';

class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({
    super.key,
    required this.images,
    this.videoUrl,
    this.initialIndex = 0,
    this.fullScreen = false,
    this.detail = false,
    this.postId,
    this.aspectRatio,
    this.borderRadius = 16,
  });

  final List<String> images;
  final String? videoUrl;
  final int initialIndex;
  final bool fullScreen;
  final bool detail;
  final String? postId;
  final double? aspectRatio;
  final double borderRadius;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  late final PageController _controller;
  late int _index;
  bool get _hasVideo => widget.videoUrl?.isNotEmpty ?? false;
  int get _count => widget.images.length + (_hasVideo ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, (_count - 1).clamp(0, _count));
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreen() {
    if (widget.postId != null) {
      ApiClient().recordPostView(widget.postId!);
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Scaffold(
                  extendBodyBehindAppBar: true,
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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  body: PostMediaCarousel(
                    images: widget.images,
                    videoUrl: widget.videoUrl,
                    initialIndex: _index,
                    fullScreen: true,
                  ),
                )));
  }

  Widget _media(int index) {
    if (index >= widget.images.length) {
      return Center(
          child: PostVideoPlayer(
        key: ValueKey(widget.videoUrl),
        videoUrl: widget.videoUrl!,
        borderRadius: widget.fullScreen ? 0 : 16,
        isActive: index == _index,
        onTap: (!widget.fullScreen) ? _openFullScreen : null,
      ));
    }
    final url = widget.images[index];
    final image = CachedNetworkImage(
      imageUrl: url.startsWith('http') ? url : '${ApiConstants.hostUrl}$url',
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: widget.fullScreen ? null : 450,
      placeholder: (_, url) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, url, error) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined,
              color: context.mutedColor, size: 32),
          const SizedBox(height: 8),
          Text('No se pudo cargar la imagen.',
              style: TextStyle(color: context.subtleColor)),
        ],
      )),
    );
    if (widget.fullScreen) {
      return InteractiveViewer(minScale: 1, maxScale: 4, child: image);
    }
    return GestureDetector(onTap: _openFullScreen, child: image);
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    
    final content = _count == 1
        ? _media(0)
        : PageView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: _count,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (_, index) => _media(index),
          );

    final pages = ClipRRect(
      borderRadius:
          BorderRadius.circular(widget.fullScreen ? 0 : widget.borderRadius),
      child: ColoredBox(
        color: context.overlayColor,
        child: content,
      ),
    );
    return Column(
      mainAxisSize: widget.fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.fullScreen)
          Expanded(child: pages)
        else
          AspectRatio(
            aspectRatio: widget.aspectRatio ??
                (widget.detail ? (_count == 1 ? 1 : 11 / 10) : 4 / 3),
            child: pages,
          ),
        if (_count > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _count; i++)
                Semantics(
                  label: 'Medio ${i + 1} de $_count',
                  selected: i == _index,
                  button: true,
                  child: GestureDetector(
                    onTap: () => _controller.animateToPage(i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == _index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? Theme.of(context).colorScheme.primary
                              : context.mutedColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text('${_index + 1}/$_count',
                  style: TextStyle(color: context.subtleColor, fontSize: 12)),
            ]),
          ),
      ],
    );
  }
}
