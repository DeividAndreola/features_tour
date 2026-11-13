import 'package:features_tour/features_tour.dart';
import 'package:flutter/widgets.dart';

/// Tells the `introduce` widget which side of the child it ended up on.
///
/// The side can differ from `IntroduceConfig.quadrantAlignment`: a card that does not fit on the
/// requested side moves to the opposite one when that side is taller. Read it to point an arrow
/// or a tail at the child.
class FeaturesTourPlacement extends InheritedWidget {
  /// Provides [quadrantAlignment] to the `introduce` widget.
  const FeaturesTourPlacement({
    required this.quadrantAlignment,
    required super.child,
    super.key,
  });

  /// The side of the child the `introduce` widget is placed on.
  final QuadrantAlignment quadrantAlignment;

  /// The side of the child the enclosing `introduce` widget is placed on, or `null` outside a tour.
  static QuadrantAlignment? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FeaturesTourPlacement>()
        ?.quadrantAlignment;
  }

  @override
  bool updateShouldNotify(FeaturesTourPlacement oldWidget) =>
      quadrantAlignment != oldWidget.quadrantAlignment;
}
