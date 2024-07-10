// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/gestures/drag.dart';
import '../utils/frame_util.dart';
import '../utils/log_util.dart';
import '../utils/logs/log_config.dart';
import 'scoll_coordinator.dart';
import '../exts/double_ext.dart';

import '../refresh/drives_indicator/drive_indicator.dart';
import 'scroll_infinite_controller.dart';

class MTScrollPositionWithSingleContext extends ScrollPositionWithSingleContext {
  MTScrollPositionWithSingleContext({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
    required this.controller,
  }) : super();
  final InfiniteScorllController controller;
  ScrollCoordinator get coordinator => controller.coordinator;

  static int id = 0;
  int addBetweenLayoutAndPaintTask(void Function() value) {
    betweenTasks.add(value);
    return id++;
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    int oldSetPixels = 0;
    void before(MTDriveIndicator indicator) {
      assert(() {
        bool isOk = true;
        if (!indicator.activityHasInit) {
          isOk = activity == null;
        } else {
          isOk = newActivity != null;
        }
        indicator.activityHasInit = true;
        return isOk;
      }());
    }

    final oldActivity = activity;
    mtLog(
        "beginActivity - OLD: ${oldActivity?.runtimeType} hash:${oldActivity?.hashCode} 速度:${oldActivity?.velocity} \n \t --- NEW:${newActivity?.runtimeType} ${newActivity?.hashCode}  速度:${newActivity?.velocity} ${FrameUtil.debugFrameCount}",
        tag: TagsConfig.tagActivity);
    oldSetPixels = _debugSetPixels;

    final headerIndicator = coordinator.headerIndicator;
    if (headerIndicator != null) {
      before(headerIndicator);
    }
    final footerIndicator = coordinator.footerIndicator;
    if (footerIndicator != null) {
      before(footerIndicator);
    }

    super.beginActivity(newActivity);
    void after(MTDriveIndicator indicator) {
      assert(oldSetPixels == _debugSetPixels,
          "说明在beginActivity中修改了pixels，要重新考虑逻辑！调查这个非常重要，表明即使是惯性滚动，也是下一帧才会执行的，这样依赖我们将MTIndicator.currentActivity放在真正改变activity调用之前或者之后，效果是一样的，不会出现副作用，因为这个方法执行过程中不会对pixel进行任何修改。同时也会有潜在的因素，比如已经强制修改过pixels了，但是下一帧还是会修改pixels。造成跳动");

      /// 必须放在activity改变之后，因为实际是否更改还是需要确认的，放在super之前则可能造成不一致
      /// 放前放后都不行，都无法处理好拖拽时候goIdle的问题
      /// 如果我只给idle和动画阶段才通知更改acticity呢？
      // if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle || WidgetsBinding.instance.schedulerPhase == SchedulerPhase.transientCallbacks) {
      // indicator.changeCurrentActivity(activity);
      // }
    }

    if (headerIndicator != null) {
      after(headerIndicator);
    }
    if (footerIndicator != null) {
      after(footerIndicator);
    }
  }

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);

    /// 这是不行的，我们必须要加惯性，但是惯性的特性要符合我们自己的定义
    // if (controller.coordinator.shouldRejectBallstic) {
    //   goIdle();
    //   return;
    // }
    final Simulation? simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(BallisticScrollActivity(
        this,
        simulation,
        context.vsync,
        activity?.shouldIgnorePointer ?? true,
      ));
    } else {
      goIdle();
    }
  }

  Queue<void Function()> betweenTasks = Queue();
  @override
  ScrollActivity? get activity => super.activity;
  void justSetPixel(double value) {
    /// 如果是取消掉注释的话，那么会导致拖拽的过程中，如果变动了偏移值（比如：添加新内容，触发该方法），那么拖拽手势将会失效
    // goIdle();
    if (pixels != value) {
      correctPixels(value);
    }
  }

  bool shouldAddClear = true;

  int _debugSetPixels = 0;
  @override
  double setPixels(double newPixels) {
    _debugSetPixels++;
    final _oldPixel = pixels;
    final pixelChange = newPixels - _oldPixel;
    mtLog(
        "<<< begin --- setPixels ： ${newPixels.short} 之前的pixel：$pixels 阶段: ${WidgetsBinding.instance.schedulerPhase} ${InfiniteScorllController.debugFrameCount} avitivity:${activity.runtimeType} ${activity.hashCode} 【速度：${activity?.velocity.short}】",
        tag: TagsConfig.tagPixel);
    final result = super.setPixels(newPixels);
    controller.notifyScrollDelta(pixelChange);
    mtLog(">>>--- end - 实际pixels: ${pixels.short}", tag: TagsConfig.tagPixel);

    controller.accumuateOffset.accumulatedOffset += pixels - _oldPixel;
    if (_oldPixel != pixels) {
      coordinator.changePixels(_oldPixel, pixels);
    }
    if (shouldAddClear) {
      shouldAddClear = false;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        controller.accumuateOffset.accumulatedOffset = 0;
        shouldAddClear = true;
      });
    }

    return result;
  }

  @override
  void correctPixels(double value) {
    super.correctPixels(value);
    mtLog(
        "强制改变pixels : correctPixels : $value activity : ${activity.runtimeType} ${activity.hashCode} 【速度：${activity?.velocity.short}】 ${InfiniteScorllController.debugFrameCount}",
        tag: TagsConfig.tagPixel);
  }

  void stopAndSetPixel(double value) {
    goIdle();
    if (pixels != value) {
      correctPixels(value);
    }
    goBallistic(0);
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final res = super.applyViewportDimension(viewportDimension);
    return res;
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // TODO: implement applyContentDimensions
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  void applyNewDimensions() {
    // TODO: implement applyNewDimensions
    super.applyNewDimensions();
  }

  @override
  bool correctForNewDimensions(ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    mtLog(
        "触发更改尺寸，${InfiniteScorllController.debugFrameCount} (阶段:${WidgetsBinding.instance.schedulerPhase}) \n 【old:pixels-> ${oldPosition.pixels} maxScrollExtent-${oldPosition.maxScrollExtent}】,\n 【new:pixels-> ${newPosition.pixels} maxScrollExtent-${newPosition.maxScrollExtent}】",
        tag: TagsConfig.tagChangeDimension);

    return super.correctForNewDimensions(oldPosition, newPosition);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    // var newPixels = pixels;
    var newPixels = pixels - physics.applyPhysicsToUserOffset(this, delta);
    // final phase =  WidgetsBinding.instance.schedulerPhase;
    setPixels(newPixels);
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    return super.hold(holdCancelCallback);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return super.drag(details, dragCancelCallback);
  }
}
