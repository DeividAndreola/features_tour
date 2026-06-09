import 'dart:math' as math;

import 'package:features_tour/features_tour.dart';
import 'package:features_tour/src/extensions/get_widget_position.dart';
import 'package:flutter/material.dart';

/// An internal widget that displays all the necessary widgets in a Stack.
class FeaturesChild extends StatefulWidget {
  /// An internal widget that displays all the necessary widgets in a Stack.
  const FeaturesChild({
    required this.globalKey,
    required this.child,
    required this.childConfig,
    required this.skip,
    required this.skipConfig,
    required this.next,
    required this.nextConfig,
    required this.done,
    required this.doneConfig,
    required this.isLastState,
    required this.introduce,
    required this.featureIndex,
    required this.totalFeatures,
    required this.introduceConfig,
    required this.padding,
    super.key,
    this.alignment,
    this.quadrantAlignment,
  });

  /// A `GlobalKey()` to control this widget.
  final GlobalKey globalKey;

  /// The child widget.
  final Widget child;

  /// The child's configuration.
  final ChildConfig childConfig;

  /// The skip button widget.
  final Widget skip;

  /// Skips all the steps.
  final SkipConfig skipConfig;

  /// The next button widget.
  final Widget next;

  /// Moves to the next step.
  final NextConfig nextConfig;

  /// The done button.
  final Widget done;

  /// The done button's configuration.
  final DoneConfig doneConfig;

  /// Indicates if this is the final step.
  final bool isLastState;

  /// Builder for the feature introduction widget.
  final Widget Function(BuildContext context, int index, int total) introduce;

  /// The index of the current feature step.
  final int featureIndex;

  /// The total number of features registered with this controller.
  final int totalFeatures;

  /// The introduction widget's configuration.
  final IntroduceConfig introduceConfig;

  /// The padding of the `introduce` widget.
  final EdgeInsetsGeometry padding;

  /// The alignment of the `introduce` widget inside the `quadrantAlignment`.
  ///
  /// This value automatically aligns depending on the `quadrantAlignment`.
  /// It is positioned as close as possible to other elements.
  final Alignment? alignment;

  /// The quadrant rectangle for the `introduce` widget.
  ///
  /// If this value is `null`, the `top` and `bottom` will be automatically
  /// calculated to get the larger side.
  final QuadrantAlignment? quadrantAlignment;

  @override
  State<FeaturesChild> createState() => _FeaturesChildState();
}

class _FeaturesChildState extends State<FeaturesChild>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Rect? rect;
  late Rect introduceRect;

  /// A key attached to the actual introduce card so its real painted bounds can
  /// be measured. The connector must end at the card itself, not at the full
  /// [introduceRect] quadrant (which can be much larger than the card when the
  /// card is aligned to one side of the quadrant).
  final GlobalKey _introduceKey = GlobalKey();
  Rect? introduceCardRect;

  late Alignment alignment;
  QuadrantAlignment? _quadrantAlignment;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  /// Continuously updates the rect while the widget is mounted.
  /// It stops automatically when disposed.
  void _autoUpdate() {
    var times = 0;
    void frameCallback(Duration _) {
      if (!mounted) return;

      final updated = _updateState();
      if (!updated && times >= 10) return;
      times++;

      // Keeps listening for every frame while mounted.
      WidgetsBinding.instance.addPostFrameCallback(frameCallback);
    }

    // Starts listening.
    WidgetsBinding.instance.addPostFrameCallback(frameCallback);
  }

  /// Updates the current state.
  bool _updateState() {
    if (!mounted || widget.globalKey.currentContext?.mounted != true) {
      return false;
    }

    final tempRect = widget.globalKey.globalPaintBounds;
    final tempCardRect = _introduceKey.globalPaintBounds;

    final rectChanged = tempRect != null && tempRect != rect;
    final cardChanged = tempCardRect != null && tempCardRect != introduceCardRect;

    // Keep ticking until both the child and the introduce card have settled,
    // otherwise the connector would be painted against a stale card position.
    if (!rectChanged && !cardChanged) {
      return false;
    }

    if (tempRect != null) rect = tempRect;
    if (tempCardRect != null) introduceCardRect = tempCardRect;

    if (rect == null) return false;

    _autoSetQuadrantAlignment(rect!);

    final size =
        MediaQuery.maybeOf(context)?.size ??
        MediaQueryData.fromView(View.of(context)).size;

    switch (_quadrantAlignment!) {
      case QuadrantAlignment.top:
        introduceRect = Rect.fromLTRB(0, 0, size.width, rect!.top);
        if (widget.alignment != null) {
          alignment = widget.alignment!;
        } else {
          final dialogWidth = size.width.clamp(280, 400).toDouble();
          var left = rect!.topCenter.dx - dialogWidth / 2;
          if (left < 0) {
            alignment = Alignment.bottomLeft;
            left = 0;
          } else if (left + dialogWidth > size.width) {
            alignment = Alignment.bottomRight;
            left = size.width - dialogWidth;
          } else {
            alignment = Alignment.bottomCenter;
          }
          introduceRect = Rect.fromLTWH(
            left,
            0,
            dialogWidth,
            introduceRect.height,
          );
        }
      case QuadrantAlignment.left:
        introduceRect = Rect.fromLTRB(0, 0, rect!.left, size.height);
        if (widget.alignment != null) {
          alignment = widget.alignment!;
        } else {
          alignment = switch (_calculateAlignmentVertical(rect!, size)) {
            Alignment.topCenter => Alignment.topRight,
            Alignment.bottomCenter => Alignment.bottomRight,
            _ => Alignment.centerRight,
          };
        }
      case QuadrantAlignment.right:
        introduceRect = Rect.fromLTRB(rect!.right, 0, size.width, size.height);
        if (widget.alignment != null) {
          alignment = widget.alignment!;
        } else {
          alignment = switch (_calculateAlignmentVertical(rect!, size)) {
            Alignment.topCenter => Alignment.topLeft,
            Alignment.bottomCenter => Alignment.bottomLeft,
            _ => Alignment.centerLeft,
          };
        }
      case QuadrantAlignment.bottom:
        introduceRect = Rect.fromLTRB(0, rect!.bottom, size.width, size.height);
        if (widget.alignment != null) {
          alignment = widget.alignment!;
        } else {
          final dialogWidth = size.width.clamp(280, 400).toDouble();
          var left = rect!.topCenter.dx - dialogWidth / 2;
          if (left < 0) {
            alignment = Alignment.topLeft;
            left = 0;
          } else if (left + dialogWidth > size.width) {
            alignment = Alignment.topRight;
            left = size.width - dialogWidth;
          } else {
            alignment = Alignment.topCenter;
          }
          introduceRect = Rect.fromLTWH(
            left,
            introduceRect.top,
            dialogWidth,
            introduceRect.height,
          );
        }
      case QuadrantAlignment.inside:
        introduceRect = rect!;
        alignment = widget.alignment ?? Alignment.center;
    }

    setState(() {});
    return true;
  }

  /// Finds the larger height between the top and bottom rectangles to set the
  /// quadrantAlignment.
  void _autoSetQuadrantAlignment(Rect rect) {
    if (_quadrantAlignment != null) return;

    if (widget.quadrantAlignment != null) {
      _quadrantAlignment = widget.quadrantAlignment;
    } else {
      final size = MediaQuery.of(context).size;
      final topRect = Rect.fromLTRB(0, 0, size.width, rect.top);
      final bottomRect = Rect.fromLTRB(0, rect.bottom, size.width, size.height);
      if (topRect.height > bottomRect.height) {
        _quadrantAlignment = QuadrantAlignment.top;
      } else {
        _quadrantAlignment = QuadrantAlignment.bottom;
      }
    }
  }

  /// Calculates the preferred alignment for the `introduce` widget.
  ///
  /// This is for the `left` and `right` quadrant alignments.
  Alignment _calculateAlignmentVertical(Rect rect, Size size) {
    if (rect.top > size.height / 2) {
      return Alignment.bottomCenter;
    } else if (rect.bottom < size.height / 2) {
      return Alignment.topCenter;
    }

    return Alignment.center;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scaleController = AnimationController(
      vsync: this,
      duration: widget.childConfig.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.childConfig.zoomScale,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: widget.childConfig.curve,
      ),
    );

    if (widget.childConfig.enableAnimation) {
      _scaleController.repeat(reverse: true).ignore();
    } else {
      _scaleController.value = 1;
      _scaleController.stop();
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _autoUpdate();
    });
  }

  @override
  void didChangeDependencies() {
    _updateState();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateState();
    super.didChangeMetrics();
  }

  /// The highlight border rect, inflated around the child. [ChildConfig.borderInsetsInflate]
  /// (per-side) takes precedence over the symmetric [ChildConfig.borderSizeInflate].
  Rect _borderRect(Rect childRect) {
    final insets = widget.childConfig.borderInsetsInflate;
    if (insets != null) {
      return Rect.fromLTRB(
        childRect.left - insets.left,
        childRect.top - insets.top,
        childRect.right + insets.right,
        childRect.bottom + insets.bottom,
      );
    }
    return childRect.inflate(widget.childConfig.borderSizeInflate);
  }

  @override
  Widget build(BuildContext context) {
    return rect == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            // Border widget
            Positioned.fromRect(
              rect: _borderRect(rect!),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Material(
                      color: widget.childConfig.backgroundColor,
                      shape: widget.childConfig.shapeBorder,
                    ),
                  );
                },
              ),
            ),

            // Child widget.
            if (widget.childConfig.enableAnimation &&
                widget.childConfig.isAnimateChild)
              Positioned.fromRect(
                rect: rect!,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: widget.child,
                    );
                  },
                ),
              )
            else
              Positioned.fromRect(rect: rect!, child: widget.child),

            // Connector line between child and introduce.
            Builder(
              builder: (context) {
                final config =
                    widget.introduceConfig.connectorConfig ??
                    ConnectorConfig.global;
                if (!config.enabled) return const SizedBox.shrink();
                final color =
                    config.color ?? Theme.of(context).colorScheme.primary;
                // Resolve the introduce padding so the connector ends at the
                // actual card boundary, not the outer introduceRect.
                final introPadding = widget.padding.resolve(
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
                );
                return Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ConnectorPainter(
                        childRect: rect!,
                        introduceRect: introduceRect,
                        introPadding: introPadding,
                        color: color,
                        strokeWidth: config.strokeWidth,
                        dotRadius: config.dotRadius,
                        childAnchor: config.childAnchor,
                        startOffset: config.startOffset,
                        introAnchor: config.introAnchor,
                        endOffset: config.endOffset,
                        cornerRadius: config.cornerRadius,
                        arrowSize: config.arrowSize,
                        minDistance: config.minDistance,
                        introduceCardRect: introduceCardRect,
                      ),
                    ),
                  ),
                );
              },
            ),

            Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Skip text widget.
                  if (!(widget.isLastState && widget.doneConfig.enabled) &&
                      widget.skipConfig.enabled)
                    Positioned.fill(
                      child: Align(
                        alignment: widget.skipConfig.alignment,
                        child: widget.skip,
                      ),
                    ),

                  // Next text widget.
                  if (!(widget.isLastState && widget.doneConfig.enabled) &&
                      widget.nextConfig.enabled)
                    Positioned.fill(
                      child: Align(
                        alignment: widget.nextConfig.alignment,
                        child: widget.next,
                      ),
                    ),

                  // Done text widget.
                  if (widget.isLastState && widget.doneConfig.enabled)
                    Positioned.fill(
                      child: Align(
                        alignment: widget.doneConfig.alignment,
                        child: widget.done,
                      ),
                    ),
                ],
              ),
            ),

            // Introduction widget — must be last in the stack so it is drawn
            // and hit-tested on top of the Scaffold, allowing interactive
            // elements inside the introduce widget to receive pointer events.
            Positioned.fromRect(
              rect: introduceRect,
              child: Padding(
                padding: widget.padding,
                child: Align(
                  alignment: alignment,
                  child: KeyedSubtree(
                    key: _introduceKey,
                    child: widget.introduceConfig.builder(
                      context,
                      rect!,
                      widget.introduce(context, widget.featureIndex, widget.totalFeatures),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
  }
}

/// Paints an orthogonal connector between the child widget and the
/// introduction card, routing automatically:
///
/// - **Child below intro** → L-shape (horizontal → vertical UP, arrives at
///   bottom-center of intro).
/// - **Child above intro** → Z-shape (vertical DOWN → horizontal → vertical
///   DOWN, arrives at top-center of intro).
///
/// Draws a dot at the start and an open arrowhead at the end.
class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({
    required this.childRect,
    required this.introduceRect,
    required this.introPadding,
    required this.color,
    required this.strokeWidth,
    required this.dotRadius,
    required this.childAnchor,
    required this.startOffset,
    required this.introAnchor,
    required this.endOffset,
    required this.cornerRadius,
    required this.arrowSize,
    required this.minDistance,
    required this.introduceCardRect,
  });

  final Rect childRect;
  final Rect introduceRect;

  /// The real painted bounds of the introduce card, when known. The connector
  /// ends here so the line reaches the card itself rather than the outer
  /// [introduceRect] quadrant (which is larger when the card is aligned to one
  /// side). Falls back to [introduceRect] minus padding when unavailable.
  final Rect? introduceCardRect;

  /// Resolved padding of the introduce widget inside [introduceRect].
  /// Used to find the actual card boundary for the end-point anchor.
  final EdgeInsets introPadding;

  final Color color;
  final double strokeWidth;
  final double dotRadius;
  final Alignment childAnchor;
  final Offset startOffset;
  final Alignment? introAnchor;
  final Offset endOffset;
  final double cornerRadius;
  final double arrowSize;
  final double minDistance;

  // The actual bounding rect of the intro card. Prefers the measured card
  // bounds; falls back to introduceRect minus padding before the card has been
  // laid out and measured.
  Rect get _introCardRect =>
      introduceCardRect ??
      Rect.fromLTRB(
        introduceRect.left + introPadding.left,
        introduceRect.top + introPadding.top,
        introduceRect.right - introPadding.right,
        introduceRect.bottom - introPadding.bottom,
      );

  @override
  void paint(Canvas canvas, Size size) {
    // Hide the connector when the child and the intro card are too close.
    // Use _introCardRect (padding already subtracted) so the gap reflects the
    // actual visual space between the child and the visible card edge.
    if (minDistance > 0) {
      final cardRect = _introCardRect;
      final gap = childRect.center.dy < cardRect.center.dy
          ? cardRect.top - childRect.bottom
          : childRect.top - cardRect.bottom;
      if (gap < minDistance) return;
    }

    final childAboveIntro = childRect.center.dy < _introCardRect.center.dy;
    final start = childAnchor.withinRect(childRect) + startOffset;

    final cardRect = _introCardRect;

    // Determine end point and arrival direction.
    final Offset end;
    final double arrivalAngle; // radians: angle the line is traveling AT end

    if (introAnchor != null) {
      // User-specified anchor: snap to the card edge on the dominant axis so
      // the line arrives at the boundary, not inside.
      final anchorPt = introAnchor!.withinRect(cardRect);
      // The arrowhead must follow the direction the line is actually traveling
      // when it reaches the card, which depends on whether the child sits above
      // or below the card — not on which edge was chosen.
      final vAngle = childAboveIntro ? math.pi / 2 : -math.pi / 2;
      if (introAnchor!.y <= -0.5) {
        end = Offset(anchorPt.dx, cardRect.top) + endOffset;
        arrivalAngle = vAngle;
      } else if (introAnchor!.y >= 0.5) {
        end = Offset(anchorPt.dx, cardRect.bottom) + endOffset;
        arrivalAngle = vAngle;
      } else if (introAnchor!.x <= -0.5) {
        end = Offset(cardRect.left, anchorPt.dy) + endOffset;
        arrivalAngle = math.pi;      // going LEFT
      } else {
        end = Offset(cardRect.right, anchorPt.dy) + endOffset;
        arrivalAngle = 0;            // going RIGHT
      }
    } else {
      // Auto: snap to the top or bottom edge center based on relative position.
      if (childAboveIntro) {
        // Child is above intro → arrive at top edge going DOWN.
        end = Offset(cardRect.center.dx, cardRect.top) + endOffset;
        arrivalAngle = math.pi / 2;
      } else {
        // Child is below intro → arrive at bottom edge going UP.
        end = Offset(cardRect.center.dx, cardRect.bottom) + endOffset;
        arrivalAngle = -math.pi / 2;
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_buildPath(start, end), linePaint);

    // Arrowhead.
    if (arrowSize > 0) {
      _drawArrow(canvas, linePaint, end, arrivalAngle);
    }

    // Dot at start.
    if (dotRadius > 0) {
      canvas.drawCircle(
        start,
        dotRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  Path _buildPath(Offset start, Offset end) {
    final path = Path()..moveTo(start.dx, start.dy);

    // If start is inside the child rect, draw a straight segment to the exit
    // edge first so routing (and curves) only begin outside the child domain.
    // If start is already outside, skip this — no extra line needed.
    final Offset routeStart;
    if (childRect.contains(start)) {
      if (childRect.center.dy < _introCardRect.center.dy) {
        // Z-shape: exit through the bottom edge.
        routeStart = Offset(start.dx, childRect.bottom);
      } else {
        // L-shape: exit through the left or right edge.
        final toRight = end.dx > start.dx;
        routeStart = Offset(
          toRight ? childRect.right : childRect.left,
          start.dy,
        );
      }
      path.lineTo(routeStart.dx, routeStart.dy);
    } else {
      routeStart = start;
    }

    final hDist = (end.dx - routeStart.dx).abs();
    final vDist = (end.dy - routeStart.dy).abs();

    if (hDist < 1.0 || vDist < 1.0) {
      path.lineTo(end.dx, end.dy);
      return path;
    }

    if (childRect.center.dy > _introCardRect.center.dy) {
      // ── L-shape ──────────────────────────────────────────────────────────
      final elbow = Offset(end.dx, routeStart.dy);
      final r = cornerRadius.clamp(0.0, math.min(hDist / 2, vDist / 2));
      final hSign = (end.dx - routeStart.dx).sign;
      final vSign = (end.dy - elbow.dy).sign;

      path
        ..lineTo(elbow.dx - hSign * r, elbow.dy)
        ..quadraticBezierTo(
          elbow.dx, elbow.dy,
          elbow.dx, elbow.dy + vSign * r,
        )
        ..lineTo(end.dx, end.dy);
    } else {
      // ── Z-shape ──────────────────────────────────────────────────────────
      final midY = (routeStart.dy + end.dy) / 2;

      final elbow1 = Offset(routeStart.dx, midY);
      final elbow2 = Offset(end.dx, midY);

      final seg1 = (routeStart - elbow1).distance;
      final seg2 = (elbow1 - elbow2).distance;
      final seg3 = (elbow2 - end).distance;

      final r1 = cornerRadius.clamp(0.0, math.min(seg1 / 2, seg2 / 2));
      final r2 = cornerRadius.clamp(0.0, math.min(seg2 / 2, seg3 / 2));

      final vSign1 = (midY - routeStart.dy).sign;
      final hSign  = (end.dx - routeStart.dx).sign;
      final vSign2 = (end.dy - midY).sign;

      path
        ..lineTo(elbow1.dx, elbow1.dy - vSign1 * r1)
        ..quadraticBezierTo(
          elbow1.dx, elbow1.dy,
          elbow1.dx + hSign * r1, elbow1.dy,
        )
        ..lineTo(elbow2.dx - hSign * r2, elbow2.dy)
        ..quadraticBezierTo(
          elbow2.dx, elbow2.dy,
          elbow2.dx, elbow2.dy + vSign2 * r2,
        )
        ..lineTo(end.dx, end.dy);
    }

    return path;
  }

  /// Draws an open V arrowhead at [tip] pointing in [angle] (radians).
  void _drawArrow(Canvas canvas, Paint paint, Offset tip, double angle) {
    const halfAngle = 35.0 * math.pi / 180; // 35° per wing
    final wing1 = tip + Offset(
      math.cos(angle + math.pi - halfAngle) * arrowSize,
      math.sin(angle + math.pi - halfAngle) * arrowSize,
    );
    final wing2 = tip + Offset(
      math.cos(angle + math.pi + halfAngle) * arrowSize,
      math.sin(angle + math.pi + halfAngle) * arrowSize,
    );
    canvas
      ..drawLine(tip, wing1, paint)
      ..drawLine(tip, wing2, paint);
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.childRect != childRect ||
      old.introduceRect != introduceRect ||
      old.introPadding != introPadding ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dotRadius != dotRadius ||
      old.childAnchor != childAnchor ||
      old.startOffset != startOffset ||
      old.introAnchor != introAnchor ||
      old.endOffset != endOffset ||
      old.cornerRadius != cornerRadius ||
      old.arrowSize != arrowSize ||
      old.minDistance != minDistance ||
      old.introduceCardRect != introduceCardRect;
}
