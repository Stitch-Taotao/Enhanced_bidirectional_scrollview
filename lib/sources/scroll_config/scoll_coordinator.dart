import 'package:flutter/material.dart';

import '../refresh/auto_indicator/auto_indicator.dart';
import '../refresh/drives_indicator/drive_indicator.dart';
import '../task/load_trigger.dart';
import '../utils/frame_util.dart';
import '../utils/logs/log_config.dart';

enum CorrectEnum {
  jmmpToItem, // 跳转到某个位置
  keepCurrentVisualWindow, // 顶部追加才会触发这个逻辑
}

class ScrollCoordinator {
  late LoadTrigger loadTrigger;

  ScrollCoordinator.init(this.loadTrigger);

  MTDriveIndicator? get headerIndicator {
    final lLoadTrigger = loadTrigger;
    if (lLoadTrigger is IndicatorLoadTrigger) {
      return lLoadTrigger.headerIndicator;
    }
    return null;
  }

  MTDriveIndicator? get footerIndicator {
    final lLoadTrigger = loadTrigger;
    if (lLoadTrigger is IndicatorLoadTrigger) {
      return lLoadTrigger.footerIndicator;
    }
    return null;
  }

  MTAutoIndicator? get autoHeadIndicator {
    final lLoadTrigger = loadTrigger;
    if (lLoadTrigger is AutoLoadTrigger) {
      return lLoadTrigger.headerIndicator;
    }
    return null;
  }

  MTAutoIndicator? get autoFootIndicator {
    final lLoadTrigger = loadTrigger;
    if (lLoadTrigger is AutoLoadTrigger) {
      return lLoadTrigger.footerIndicator;
    }
    return null;
  }

  CorrectEnum? _correctType;
  CorrectEnum? get correctType => _correctType;

  /// 需要修正pixels
  void needCorrectPixels({required CorrectEnum correctType}) {
    assert(_correctType == null, "同一帧只有一种情况会触发修正");
    _correctType = correctType;
    mtLog("needCorrectPixels ${FrameUtil.debugFrameCount}", tag: TagsConfig.tagShouldRejectBallistic);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _correctType = null;
    });
  }

  /// 是否应该拒绝惯性
  bool get shouldRejectBallstic => _correctType != null;

  void changeTouch(bool beTouch) {
    headerIndicator?.changeTouch(beTouch);
    footerIndicator?.changeTouch(beTouch);
  }

  void changePixels(double oldPixel, double pixels) {
    if (headerIndicator != null) {
      headerIndicator!.changePixel(oldPixel: oldPixel, newPixel: pixels);
    }
    if (footerIndicator != null) {
      footerIndicator!.changePixel(oldPixel: oldPixel, newPixel: pixels);
    }
    if (autoHeadIndicator != null) {
      autoHeadIndicator!.changePixel(oldPixel: oldPixel, newPixel: pixels);
    }
    if (autoFootIndicator != null) {
      autoFootIndicator!.changePixel(oldPixel: oldPixel, newPixel: pixels);
    }
  }
}
