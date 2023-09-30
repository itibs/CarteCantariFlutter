import 'package:flutter/material.dart';

const defaultMusicSheetWidth = 700.0;

class CoverInteractiveViewer extends StatelessWidget {
  final musicSheetWidth;

  const CoverInteractiveViewer({
    Key? key,
    required this.child,
    this.musicSheetWidth,
  }):super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext _) {
    final controller = TransformationController();
    return LayoutBuilder(
      builder: (__, constraint) {
        return InteractiveViewer(
          transformationController: controller..value = Matrix4.identity() * (constraint.biggest.width / (musicSheetWidth ?? defaultMusicSheetWidth)),
          minScale: 0.1,
          constrained: false,
          child: child,
          boundaryMargin: EdgeInsets.fromLTRB(0, 0, 0, 500),
        );
      },
    );
  }
}