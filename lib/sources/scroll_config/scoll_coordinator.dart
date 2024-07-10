import 'package:flutter/material.dart';

import '../refresh/auto_indicator/auto_indicator.dart';
import '../refresh/drives_indicator/drive_indicator.dart';
import '../task/load_trigger.dart';
import '../utils/frame_util.dart';
import '../utils/logs/log_config.dart';

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

  bool _currentFrameNeedCorrectPixels = false;

  /// 需要修正pixels
  void needCorrectPixels() {
    mtLog("needCorrectPixels ${FrameUtil.debugFrameCount}", tag: TagsConfig.tagShouldRejectBallistic);
    _currentFrameNeedCorrectPixels = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _currentFrameNeedCorrectPixels = false;
    });
  }

  /// TODO:当出现滑动到顶部（或底部），但是底部（或顶部）恰好加载完毕的时候，会导致惯性被终止而可能引发Bug，后续修改
  /// 是否应该拒绝惯性
  bool get shouldRejectBallstic => _currentFrameNeedCorrectPixels;

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
