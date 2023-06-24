import 'package:flutter/material.dart';

const musicSheetWidth = 700.0;

class CoverInteractiveViewer extends StatelessWidget {
  const CoverInteractiveViewer({
    this.child,
    Key key,
  }):super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext _) {
    final controller = TransformationController();
    return LayoutBuilder(
      builder: (__, constraint) {
        return InteractiveViewer(
          transformationController: controller..value = Matrix4.identity() * (constraint.biggest.width / musicSheetWidth),
          minScale: 0.1,
          constrained: false,
          child: child,
          boundaryMargin: EdgeInsets.fromLTRB(0, 0, 0, 500),
        );
      },
    );
  }
}