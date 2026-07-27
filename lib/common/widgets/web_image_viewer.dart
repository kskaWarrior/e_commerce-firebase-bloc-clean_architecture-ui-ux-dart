import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens the fullscreen, zoomable image viewer as a black overlay route.
/// [imagePaths] are the raw stored image references (URLs or legacy
/// filenames); they are resolved through [ImageDisplayHelper]. [initialIndex]
/// is the image to show first. Shared by the shopper storefront and the admin
/// console so product/category images can be inspected up close.
Future<void> showWebImageViewer(
  BuildContext context, {
  required List<String> imagePaths,
  int initialIndex = 0,
}) {
  if (imagePaths.isEmpty) return Future<void>.value();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => WebImageViewer(
        imagePaths: imagePaths,
        initialIndex: initialIndex.clamp(0, imagePaths.length - 1),
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Fullscreen lightbox: a single large image the user can pan and zoom
/// (buttons, double-click, drag), navigate with arrows/thumbnails/keyboard,
/// and dismiss with Esc or the close button. Built on [InteractiveViewer] so
/// it needs no extra package and mirrors the mobile fullscreen gallery.
class WebImageViewer extends StatefulWidget {
  const WebImageViewer({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
  });

  final List<String> imagePaths;
  final int initialIndex;

  @override
  State<WebImageViewer> createState() => _WebImageViewerState();
}

class _WebImageViewerState extends State<WebImageViewer> {
  static const double _minScale = 1;
  static const double _maxScale = 5;
  static const double _step = 0.75;

  final TransformationController _controller = TransformationController();
  final FocusNode _focusNode = FocusNode();
  late int _index;
  Size _viewport = Size.zero;
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  bool get _hasMultiple => widget.imagePaths.length > 1;

  void _resetZoom() => _controller.value = Matrix4.identity();

  /// Applies an absolute [target] scale centred on the viewport (used by the
  /// +/- buttons). Panning is reset so the image stays framed.
  void _applyScale(double target) {
    if (_viewport == Size.zero) return;
    final clamped = target.clamp(_minScale, _maxScale);
    final cx = _viewport.width / 2;
    final cy = _viewport.height / 2;
    setState(() {
      if (clamped <= _minScale) {
        _controller.value = Matrix4.identity();
      } else {
        _controller.value = Matrix4.identity()
          ..translate(cx, cy)
          ..scale(clamped)
          ..translate(-cx, -cy);
      }
    });
  }

  void _zoomIn() => _applyScale(_scale + _step);

  void _zoomOut() => _applyScale(_scale - _step);

  /// Double-click toggles between fit and 2.5× centred on the click point.
  void _toggleDoubleTapZoom() {
    if (_scale > _minScale + 0.01) {
      setState(_resetZoom);
      return;
    }
    final focal = _doubleTapPosition ??
        Offset(_viewport.width / 2, _viewport.height / 2);
    setState(() {
      _controller.value = Matrix4.identity()
        ..translate(focal.dx, focal.dy)
        ..scale(2.5)
        ..translate(-focal.dx, -focal.dy);
    });
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.imagePaths.length) return;
    setState(() {
      _index = next;
      _resetZoom();
    });
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _resetZoom();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        Navigator.of(context).maybePop();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _go(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _go(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        _zoomIn();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.minus:
        _zoomOut();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final url = ImageDisplayHelper.generateProductImagePath(
      widget.imagePaths[_index],
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Tapping the backdrop (outside the image) closes the viewer.
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewport = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
                    onDoubleTap: _toggleDoubleTapZoom,
                    child: InteractiveViewer(
                      transformationController: _controller,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Previous / next arrows.
            if (_hasMultiple) ...[
              _EdgeArrow(
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left,
                tooltip: s.previousImage,
                onTap: _index > 0 ? () => _go(-1) : null,
              ),
              _EdgeArrow(
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right,
                tooltip: s.nextImage,
                onTap: _index < widget.imagePaths.length - 1
                    ? () => _go(1)
                    : null,
              ),
            ],

            // Top bar: image counter + close.
            Positioned(
              top: 16,
              left: 20,
              right: 12,
              child: Row(
                children: [
                  if (_hasMultiple)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.imagePaths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const Spacer(),
                  _CircleButton(
                    icon: Icons.close,
                    tooltip: s.closeViewer,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),

            // Bottom controls: zoom cluster + thumbnail strip.
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleButton(
                          icon: Icons.remove,
                          tooltip: s.zoomOut,
                          filled: false,
                          onTap: _scale > _minScale + 0.01 ? _zoomOut : null,
                        ),
                        _CircleButton(
                          icon: Icons.refresh,
                          tooltip: s.resetZoom,
                          filled: false,
                          onTap:
                              _scale > _minScale + 0.01 ? () => setState(_resetZoom) : null,
                        ),
                        _CircleButton(
                          icon: Icons.add,
                          tooltip: s.zoomIn,
                          filled: false,
                          onTap: _scale < _maxScale - 0.01 ? _zoomIn : null,
                        ),
                      ],
                    ),
                  ),
                  if (_hasMultiple) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: widget.imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final selected = index == _index;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _select(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                width: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? brand.primary
                                        : Colors.white.withOpacity(0.35),
                                    width: selected ? 2.4 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: ImageDisplayHelper
                                      .generateProductImagePath(
                                          widget.imagePaths[index]),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.white.withOpacity(0.08),
                                    child: Icon(Icons.broken_image_outlined,
                                        size: 20,
                                        color: Colors.white.withOpacity(0.6)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round translucent control button used across the viewer chrome.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: filled ? Colors.black.withOpacity(0.45) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white.withOpacity(enabled ? 1 : 0.35),
            ),
          ),
        ),
      ),
    );
    return Tooltip(message: tooltip, child: button);
  }
}

/// A large left/right navigation arrow pinned to a screen edge.
class _EdgeArrow extends StatelessWidget {
  const _EdgeArrow({
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _CircleButton(icon: icon, tooltip: tooltip, onTap: onTap),
      ),
    );
  }
}
