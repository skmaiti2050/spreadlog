import 'package:flutter/widgets.dart';

/// Material 3 window size classes used to adapt navigation and layout.
enum WindowSize {
  /// Phones in portrait: bottom navigation bar, full-width content.
  compact,

  /// Tablets and small windows: navigation rail.
  medium,

  /// Desktop and large tablets in landscape: labelled navigation rail.
  expanded;

  static const double mediumMin = 600;
  static const double expandedMin = 1024;

  static WindowSize forWidth(double width) {
    if (width >= expandedMin) return WindowSize.expanded;
    if (width >= mediumMin) return WindowSize.medium;
    return WindowSize.compact;
  }

  static WindowSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}

/// Centres [child] and caps its width so lists and forms stay readable on
/// tablets and desktops instead of stretching edge to edge.
class ContentWidth extends StatelessWidget {
  static const double readableMax = 840;

  final Widget child;
  final double maxWidth;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = readableMax,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
