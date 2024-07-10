import 'dart:math';

import 'package:flutter/material.dart';

abstract class IndicatorPhysics {
  /// 正在处理
  bool get physicProcessing;
  double get indicatorHeight;
  double get maxOverScrollExtent => 120.0;

  ScrollPositionWithSingleContext get position;
  /// 是否需要预留indicotor高度
  bool get needIndicatorHeight;
  /// 是否需要在不完全显示的时候，弹出整个indicator
  bool get needShowFullIndicator;
}

abstract class MTIndicator implements IndicatorPhysics {
  @override
  double get maxOverScrollExtent => 120.0;
  bool get isHeader;
  bool get isOverScroll => hasOverScroll(isHeader);

  bool hasOverScroll(bool isHeader) {
    /// 刚初始化的时候是没有contentDimensions的，build中会用到，所以需要判断一下，给个固定的false即可
    if (!position.hasContentDimensions) {
      return false;
    }
    bool isOverScroll = false;
    if (isHeader) {
      isOverScroll = position.pixels < position.minScrollExtent;
    } else {
      isOverScroll = position.pixels > position.minScrollExtent;
    }
    return isOverScroll;
  }

  double get absOverscrollOffset {
    if (isHeader) {
      return (min((position.pixels - position.minScrollExtent), 0.0)).abs();
    } else {
      return (max((position.pixels - position.maxScrollExtent), 0.0)).abs();
    }
  }
}

mixin BuilderMixin on MTIndicator {
  Widget? build(BuildContext context);
}

mixin PixelAwareMixin on MTIndicator {
  void changePixel({required double oldPixel, required double newPixel});
}
