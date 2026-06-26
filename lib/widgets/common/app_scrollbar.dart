import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps a scrollable in a [Scrollbar] that owns its own [ScrollController],
/// so the scrollbar is anchored to the scrollable's own right edge (which, on
/// the centered web layout, lines up with the content column / app bar edge
/// instead of floating where the text happens to end).
///
/// On web the thumb is always visible (website-like); on mobile it keeps the
/// default fade-in-on-scroll behaviour.
class AppScrollbar extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  const AppScrollbar({Key? key, required this.builder}) : super(key: key);

  @override
  _AppScrollbarState createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: kIsWeb,
      child: widget.builder(context, _controller),
    );
  }
}
