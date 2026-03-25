import 'package:flutter/material.dart';

/// Configuration for the connector line drawn between the highlighted child
/// widget and the introduction card.
///
/// The routing is automatic:
/// - **Child below intro** → L-shape: exits horizontally, turns, arrives at
///   the bottom center of the intro card going upward.
/// - **Child above intro** → Z-shape: exits vertically downward, goes
///   horizontal, then arrives at the top center of the intro card going
///   downward.
class ConnectorConfig {
  factory ConnectorConfig({
    bool? enabled,
    Color? color,
    double? strokeWidth,
    double? dotRadius,
    Alignment? childAnchor,
    Offset? startOffset,
    Alignment? introAnchor,
    Offset? endOffset,
    double? cornerRadius,
    double? arrowSize,
    double? minDistance,
  }) {
    return global.copyWith(
      enabled: enabled,
      color: color,
      strokeWidth: strokeWidth,
      dotRadius: dotRadius,
      childAnchor: childAnchor,
      startOffset: startOffset,
      introAnchor: introAnchor,
      endOffset: endOffset,
      cornerRadius: cornerRadius,
      arrowSize: arrowSize,
      minDistance: minDistance,
    );
  }

  const ConnectorConfig._({
    required this.enabled,
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
  });

  /// Global configuration.
  static ConnectorConfig global = const ConnectorConfig._(
    enabled: false,
    color: null,
    strokeWidth: 2.0,
    dotRadius: 5.0,
    childAnchor: Alignment.center,
    startOffset: Offset.zero,
    introAnchor: null,
    endOffset: Offset.zero,
    cornerRadius: 35.0,
    arrowSize: 8.0,
    minDistance: 40.0,
  );

  /// Whether the connector is shown. Default is `false`.
  final bool enabled;

  /// The color of the connector line, dot, and arrow.
  ///
  /// If `null`, defaults to the current theme's primary color.
  final Color? color;

  /// The stroke width of the connector line. Default is `2.0`.
  final double strokeWidth;

  /// The radius of the dot drawn at the child widget end. Default is `5.0`.
  ///
  /// Set to `0` to hide the dot.
  final double dotRadius;

  /// Where on the child widget the connector line starts.
  ///
  /// Defaults to [Alignment.center].
  final Alignment childAnchor;

  /// Pixel offset applied to the start point after [childAnchor] is resolved.
  ///
  /// Useful for nudging the line away from the widget border.
  final Offset startOffset;

  /// Where on the introduction card the connector line ends.
  ///
  /// If `null`, automatically uses the center of the top or bottom edge based
  /// on whether the child is above or below the introduction card.
  final Alignment? introAnchor;

  /// Pixel offset applied to the end point after [introAnchor] is resolved.
  ///
  /// Useful for nudging the line away from the card border.
  final Offset endOffset;

  /// The radius of the rounded 90° corners. Default is `20.0`.
  final double cornerRadius;

  /// The size (wing length) of the arrowhead drawn at the end of the line.
  ///
  /// Set to `0` to hide the arrowhead. Default is `8.0`.
  final double arrowSize;

  /// Minimum gap (in pixels) between the child widget and the introduction
  /// card required for the connector to be drawn.
  ///
  /// When the two are closer than this value the connector is hidden
  /// automatically, avoiding a cramped or overlapping line.
  /// Default is `40.0`. Set to `0` to always draw the connector.
  final double minDistance;

  /// Creates a copy with the given fields replaced.
  ConnectorConfig copyWith({
    bool? enabled,
    Color? color,
    double? strokeWidth,
    double? dotRadius,
    Alignment? childAnchor,
    Offset? startOffset,
    Alignment? introAnchor,
    Offset? endOffset,
    double? cornerRadius,
    double? arrowSize,
    double? minDistance,
  }) {
    return ConnectorConfig._(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dotRadius: dotRadius ?? this.dotRadius,
      childAnchor: childAnchor ?? this.childAnchor,
      startOffset: startOffset ?? this.startOffset,
      introAnchor: introAnchor ?? this.introAnchor,
      endOffset: endOffset ?? this.endOffset,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      arrowSize: arrowSize ?? this.arrowSize,
      minDistance: minDistance ?? this.minDistance,
    );
  }
}
