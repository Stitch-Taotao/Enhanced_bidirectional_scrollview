import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FrameUtil {
  int _frameCount = 0;
  FrameUtil._() {
    WidgetsFlutterBinding.ensureInitialized();
    scheduleNextFrame();
  }
  Completer<void>? completer;
  // scheduleNextFrame() {
  //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  //     _frameCount++;
  //     scheduleNextFrame();
  //   });
  // }
  scheduleNextFrame() {
    completer = Completer<void>();
    completer!.future.then((value) {
      _frameCount++;
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer!.complete();
      completer = null;
      // _frameCount++;
      scheduleNextFrame();
    });
  }

  static void init() {
    _instance ??= FrameUtil._();
  }

  static FrameUtil? _instance;
  static FrameUtil get single => _instance ??= FrameUtil._();

  ///
  static int get frameCount => FrameUtil.single._frameCount;
  static String get debugFrameCount => '（帧:${FrameUtil.single._frameCount})';
  static SchedulerPhase get phase => WidgetsBinding.instance.schedulerPhase;
  static String get debugPhase => '[阶段:$phase]';
}
