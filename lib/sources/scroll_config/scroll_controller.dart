import 'package:flutter/material.dart';

import 'scroll_infinite_controller.dart';
import 'scroll_position.dart';

class MTScrollController extends ScrollController {
  final InfiniteScorllController infiniteScorllController;
  MTScrollController(this.infiniteScorllController);
  @override
  MTScrollPositionWithSingleContext createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return MTScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
      controller: infiniteScorllController,
    );
  }

  @override
  MTScrollPositionWithSingleContext get position => super.position as MTScrollPositionWithSingleContext;
}
