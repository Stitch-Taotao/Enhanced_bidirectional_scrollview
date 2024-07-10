import 'package:flutter/material.dart';

class MTScrollBehavior extends ScrollBehavior {
  final ScrollPhysics? physics;
  const MTScrollBehavior({
    this.physics,
  });
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (physics != null) {
      return physics!;
    }
    return super.getScrollPhysics(context);
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
