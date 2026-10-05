import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';
import 'auth_guard.dart';

class PostReactionBar extends StatefulWidget {
  final PostModel post;

  const PostReactionBar({super.key, required this.post});

  @override
  State<PostReactionBar> createState() => _PostReactionBarState();
}

class _PostReactionBarState extends State<PostReactionBar> {
  final _api = ApiClient();
  final _anchor = LayerLink();
  Timer? _holdTimer;
  OverlayEntry? _picker;
  bool _busy = false;
  bool _pickerOpenedForThisTouch = false;

  static const _options = <_ReactionOption>[
    _ReactionOption('MeGusta', 'assets/emojis/like_3d.png', 'Like'),
    _ReactionOption('Corazon', 'assets/emojis/heart_3d.png', 'Corazón'),
    _ReactionOption('Risa', 'assets/emojis/laugh_3d.png', 'Risa'),
    _ReactionOption('Sorpresa', 'assets/emojis/surprise_3d.png', 'Sorpresa'),
    _ReactionOption('ConLagrima', 'assets/emojis/sad_3d.png', 'Triste'),
    _ReactionOption('Enojo', 'assets/emojis/angry_3d.png', 'Enojo'),
  ];

  Future<void> _react(String type) async {
    if (_busy || widget.post.status != 'Active') return;
    if (!await requireSession(context) || !mounted || _busy) return;

    final previousReaction = widget.post.userReaction;
    final previousCount = widget.post.reactionsCount;
    final previousCounts = Map<String, int>.from(widget.post.reactionCounts);

    final nextReaction = previousReaction == type ? null : type;
    final countDelta = previousReaction == null
        ? 1
        : nextReaction == null
            ? -1
            : 0;

    final nextCounts = Map<String, int>.from(previousCounts);
    if (previousReaction != null) {
      final current = nextCounts[previousReaction] ?? 0;
      if (current <= 1) {
        nextCounts.remove(previousReaction);
      } else {
        nextCounts[previousReaction] = current - 1;
      }
    }
    if (nextReaction != null) {
      nextCounts[nextReaction] = (nextCounts[nextReaction] ?? 0) + 1;
    }

    setState(() {
      _busy = true;
      widget.post.userReaction = nextReaction;
      widget.post.reactionsCount =
          (previousCount + countDelta).clamp(0, 1 << 31).toInt();
      widget.post.reactionCounts = nextCounts;
    });

    final error = await _api.toggleReaction(widget.post.id, type);
    if (error != null) {
      widget.post.userReaction = previousReaction;
      widget.post.reactionsCount = previousCount;
      widget.post.reactionCounts = previousCounts;
    } else {
      _api.recordPostView(widget.post.id);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _startHold() {
    if (_busy || widget.post.status != 'Active') return;
    _pickerOpenedForThisTouch = false;
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _pickerOpenedForThisTouch = true;
      _openPicker();
    });
  }

  void _openPicker() {
    _closePicker();
    _picker = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePicker,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _anchor,
            showWhenUnlinked: false,
            offset: const Offset(0, -68),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: context.isDarkMode ? .45 : .18),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in _options)
                      _buildPickerItem(option),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_picker!);
  }

  Widget _buildPickerItem(_ReactionOption option) {
    final isSelected = widget.post.userReaction == option.type;
    final count = widget.post.reactionCounts[option.type] ?? 0;

    return Semantics(
      button: true,
      label: option.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _closePicker();
          _react(option.type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: isSelected
              ? BoxDecoration(
                  color: context.loveColor
                      .withValues(alpha: context.isDarkMode ? 0.25 : 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.loveColor
                        .withValues(alpha: context.isDarkMode ? 0.55 : 0.40),
                    width: 1.4,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                option.assetPath,
                width: 36,
                height: 36,
                cacheWidth: 114,
                cacheHeight: 114,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.sentiment_satisfied_alt_rounded,
                  size: 32,
                  color: context.loveColor,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? context.loveColor : context.subtleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _closePicker() {
    _picker?.remove();
    _picker?.dispose();
    _picker = null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !_busy && widget.post.status == 'Active';
    final userReaction = widget.post.userReaction;
    final matching = _options.where((o) => o.type == userReaction);
    final selectedOption = matching.isNotEmpty ? matching.first : null;
    final defaultOption = _options.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _anchor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => _startHold() : null,
            onTapCancel: () => _holdTimer?.cancel(),
            onTapUp: enabled
                ? (_) {
                    _holdTimer?.cancel();
                    if (!_pickerOpenedForThisTouch) {
                      _react(selectedOption?.type ?? defaultOption.type);
                    }
                  }
                : null,
            child: Semantics(
              button: true,
              selected: userReaction != null,
              label: selectedOption?.label ?? 'Reaccionar',
              hint: 'Mantén presionado para ver más reacciones',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: selectedOption != null
                    ? BoxDecoration(
                        color: context.loveColor
                            .withValues(alpha: context.isDarkMode ? 0.22 : 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.loveColor
                              .withValues(alpha: context.isDarkMode ? 0.55 : 0.40),
                          width: 1.4,
                        ),
                      )
                    : null,
                child: Center(
                  child: selectedOption != null
                      ? Image.asset(
                          selectedOption.assetPath,
                          width: 25,
                          height: 25,
                          cacheWidth: 75,
                          cacheHeight: 75,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.thumb_up_alt_rounded,
                            size: 22,
                            color: context.loveColor,
                          ),
                        )
                      : Image.asset(
                          defaultOption.assetPath,
                          width: 25,
                          height: 25,
                          cacheWidth: 75,
                          cacheHeight: 75,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.thumb_up_alt_rounded,
                            size: 22,
                            color: context.subtleColor,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (widget.post.reactionsCount > 0)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                widget.post.reactionsCount.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: userReaction != null
                      ? context.loveColor
                      : context.subtleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _closePicker();
    super.dispose();
  }
}

class _ReactionOption {
  final String type;
  final String assetPath;
  final String label;

  const _ReactionOption(this.type, this.assetPath, this.label);
}
