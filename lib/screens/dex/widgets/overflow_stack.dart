import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class OverflowStack extends Stack {
  final double overflowLeft;

  const OverflowStack({
    super.key,
    this.overflowLeft = 0.0,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderOverflowStack(
      overflowLeft: overflowLeft,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderOverflowStack renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.overflowLeft = overflowLeft;
  }
}

class RenderOverflowStack extends RenderStack {
  double overflowLeft;

  RenderOverflowStack({
    required this.overflowLeft,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final hitRect = Rect.fromLTRB(-overflowLeft, 0, size.width, size.height);
    if (hitRect.contains(position)) {
      if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}
