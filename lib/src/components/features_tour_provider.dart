import 'package:features_tour/features_tour.dart';
import 'package:flutter/widgets.dart';

/// Provides a [FeaturesTourController] to descendant widgets.
///
/// Wrap any part of your widget tree with this widget and retrieve the
/// controller anywhere below it using [FeaturesTourProvider.of] or
/// [FeaturesTourProvider.maybeOf].
///
/// Example:
/// ```dart
/// FeaturesTourProvider(
///   controller: tourController,
///   child: MyPage(),
/// )
///
/// // In a descendant:
/// final controller = FeaturesTourProvider.of(context);
/// ```
class FeaturesTourProvider extends InheritedWidget {
  const FeaturesTourProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The [FeaturesTourController] available to descendants.
  final FeaturesTourController controller;

  /// Returns the nearest [FeaturesTourController] from the widget tree.
  ///
  /// Throws a [FlutterError] if no [FeaturesTourProvider] is found in the
  /// ancestor tree.
  static FeaturesTourController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FeaturesTourProvider>();
    if (provider == null) {
      throw FlutterError(
        'FeaturesTourProvider.of() called with a context that does not contain '
        'a FeaturesTourProvider.\n'
        'Make sure there is a FeaturesTourProvider ancestor in the widget tree.',
      );
    }
    return provider.controller;
  }

  /// Returns the nearest [FeaturesTourController], or `null` if none is found.
  static FeaturesTourController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FeaturesTourProvider>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(FeaturesTourProvider oldWidget) =>
      oldWidget.controller != controller;
}
