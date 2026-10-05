import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class PostVideoPlayer extends StatefulWidget {
  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.borderRadius = 12,
    this.initiallyMuted = true,
    this.isActive = true,
    this.onTap,
  });

  final String videoUrl;
  final double borderRadius;
  final bool initiallyMuted;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  late bool _isMuted;
  bool _isVisible = false;
  bool _isManuallyPaused = false;
  bool _hasInitialized = false;

  String get _resolvedUrl => widget.videoUrl.startsWith('http')
      ? widget.videoUrl
      : '${ApiConstants.hostUrl}${widget.videoUrl}';

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initiallyMuted;
  }

  @override
  void didUpdateWidget(covariant PostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _updatePlayback();
    }
  }

  void _updatePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (_isVisible && widget.isActive && !_isManuallyPaused) {
      if (!controller.value.isPlaying) controller.play();
    } else {
      if (controller.value.isPlaying) controller.pause();
    }
  }

  Future<void> _initialize() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(_resolvedUrl));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      if (mounted) {
        setState(() {});
        _updatePlayback();
      }
    } catch (e) {
      debugPrint('Error inicializando reproductor de video: $e');
      await controller.dispose();
      if (mounted) setState(() => _error = 'No se pudo reproducir el video.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        _isManuallyPaused = true;
        controller.pause();
      } else {
        _isManuallyPaused = false;
        controller.play();
      }
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _seekRelative(Duration delta) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    
    final newPosition = controller.value.position + delta;
    final maxDuration = controller.value.duration;
    
    if (newPosition < Duration.zero) {
      controller.seekTo(Duration.zero);
    } else if (newPosition > maxDuration) {
      controller.seekTo(maxDuration);
    } else {
      controller.seekTo(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    Widget content;

    if (_error != null) {
      content = Container(
        constraints: const BoxConstraints(minHeight: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.overlayColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: context.mutedColor),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: context.subtleColor)),
          ],
        ),
      );
    } else if (controller == null || !controller.value.isInitialized) {
      content = Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.overlayColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      final videoRatio = controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 16 / 9;
      final clampedRatio = videoRatio.clamp(4 / 5, 16 / 9);

      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: clampedRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width > 0
                      ? controller.value.size.width
                      : 16,
                  height: controller.value.size.height > 0
                      ? controller.value.size.height
                      : 9,
                  child: VideoPlayer(controller),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _togglePlayback,
                    child: Center(
                      child: ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: controller,
                        builder: (context, value, child) {
                          return AnimatedOpacity(
                            opacity: value.isPlaying ? 0 : 1,
                            duration: const Duration(milliseconds: 180),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Double-tap zones for seeking
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () => _seekRelative(const Duration(seconds: -5)),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () => _seekRelative(const Duration(seconds: 5)),
                      ),
                    ),
                  ],
                ),
              ),
              // Always-visible Mute/Unmute button in Twitter/X style
              Positioned(
                right: 10,
                bottom: 10,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleMute,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).colorScheme.primary,
                    bufferedColor: context.mutedColor.withValues(alpha: 0.5),
                    backgroundColor: Colors.black38,
                  ),
                  padding: const EdgeInsets.only(top: 24, bottom: 0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final visible = info.visibleFraction > 0.4;
        if (visible != _isVisible) {
          _isVisible = visible;
          if (visible && !_hasInitialized) {
            _hasInitialized = true;
            _initialize();
          }
          if (!visible) _isManuallyPaused = false;
          _updatePlayback();
        }
      },
      child: content,
    );
  }
}
