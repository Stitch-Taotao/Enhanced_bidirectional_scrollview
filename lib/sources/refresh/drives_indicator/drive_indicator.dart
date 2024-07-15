// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../exts/double_ext.dart';
import '../../utils/frame_util.dart';
import '../../utils/logs/log_config.dart';
import '../indicator.dart';
import '../indicator_task_manager.dart';

enum DivenIndicatorStatusEnum {
  idle,
  dragForward, // 在临界区拖拽，但是没有达到阈值
  dragbackward, // 在临界区拖拽，但是没有达到阈值
  ready,
  loading, // 触发正在加载
  loaded, // 任务完成，需要处理回弹（）
  // animating, // 动画
  end, // 回弹处理完毕,那么什么时候重返idle状态呢，就在这一帧结束之后
}

abstract class MTDriveIndicator<T extends Object> extends MTIndicator with BuilderMixin, PixelAwareMixin {
  DivenIndicatorStatusEnum get status => _indicatorNotiferStatus.status;

  MTProcessingManager processManager;

  MTDriveIndicator({
    DivenIndicatorStatusEnum status = DivenIndicatorStatusEnum.idle,
    required this.processManager,
  }) {
    assert(maxOverScrollExtent >= 0);
    _indicatorNotiferStatus = IndicatorNotifierStatus<T>(indicator: this);
  }

  /// 当前的偏移值（和滚动相关的偏移值）
  /// TODO:考虑不会因为没有同步correct导致潜在的问题
  // final ValueNotifier<double> _pixelsBySet = ValueNotifier(0.0);
  // ValueNotifier<double> get pixelsNotifier => _pixelsBySet;

  /// 因为我强制更改过Pixel的值，所以这里的old每次只在setPixel记录是不行的，但是我们可以直接通过position去获取
  /// double? oldPixel;
  /// TODO:还有一个可能存在correctPixel的清理，这种情况不需要更改指示器的状态码？

  @override
  void changePixel({required double oldPixel, required double newPixel}) {
    if (oldPixel == newPixel) {
      assert(false, "调用的时候已经做过处理了，不可能相同");
      return;
    }
    final diff = newPixel - oldPixel;
    changeStatusByPixelChange(diff: diff);
    _indicatorNotiferStatus.changePixel(newPixel);
    assert(_indicatorNotiferStatus.pixels == position.pixels);
  }

  /// 是否初始化过activity
  bool activityHasInit = false;

  bool get currentIsDragging => isTouch;

  bool get currentIsTouching => currentIsDragging;

  bool isTouch = false;

  /// 真正的是否是拖拽，不通过对比pre和current
  void changeTouch(bool beTouch) {
    if (isTouch == beTouch) {
      return;
    }
    isTouch = beTouch;
    _changeStatusByChangeDrag(isTouch);
  }

  double triggerOffset = 70.0;

  @override
  double get indicatorHeight => triggerOffset;

  /// 正在处理
  bool get isProcessing => status.index >= DivenIndicatorStatusEnum.loading.index;

  void _checkIsProcessing() {
    /// MARK 只有请求时候才为true只要loaed即为false
    bool onRequest = status.index == DivenIndicatorStatusEnum.loading.index;
    isProcessingNotifier.value = onRequest;
    // mtLog("isProcessing is $isProcessing status is $status ${FrameUtil.debugFrameCount} ${FrameUtil.debugPhase}",
    //     tag: TagsConfig.tagSyncAutoFrame);
  }

  @override
  bool get physicProcessing =>
      (status == DivenIndicatorStatusEnum.ready || status == DivenIndicatorStatusEnum.loading || status == DivenIndicatorStatusEnum.loaded);

  /// 手势变更触发状态更新
  void _changeStatusByChangeDrag(bool beDrag) {
    // ignore: unused_local_variable
    final frameInfo = FrameUtil.debugFrameCount + FrameUtil.debugPhase;

    /// 处理中不管手势怎么样变化，都不会影响状态
    if (isProcessing) {
      return;
    }
    // ignore: unused_local_variable
    final oldStatus = status;
    final isOverScroll = hasOverScroll(isHeader);

    /// TODO：注意drag的时候，可能是在非超出滚动的时候，这个时候不应该将idle变为dragOverscroll状态
    if (beDrag) {
      assert(status != DivenIndicatorStatusEnum.dragForward && status != DivenIndicatorStatusEnum.ready);
      switch (status) {
        case DivenIndicatorStatusEnum.idle: //
          if (isOverScroll) {
            changeStatus(DivenIndicatorStatusEnum.dragForward);
          }
          break;
        case DivenIndicatorStatusEnum.dragForward:
        case DivenIndicatorStatusEnum.dragbackward:
        case DivenIndicatorStatusEnum.ready:
        case DivenIndicatorStatusEnum.loading: //
        case DivenIndicatorStatusEnum.loaded: //
        case DivenIndicatorStatusEnum.end: //
      }
    } else {
      assert(status == DivenIndicatorStatusEnum.idle ||
          status == DivenIndicatorStatusEnum.dragForward ||
          status == DivenIndicatorStatusEnum.dragbackward ||
          status == DivenIndicatorStatusEnum.ready);
      switch (status) {
        case DivenIndicatorStatusEnum.idle:
          break;
        case DivenIndicatorStatusEnum.dragForward:

          /// 这里如果突然修改了尺寸，则不会是isOverScroll的
          // assert(!currentIsDragging && isOverScroll, "其他情况下不可能在这个状态");
          /// 退回空闲状态
          changeStatus(DivenIndicatorStatusEnum.idle);
          break;
        case DivenIndicatorStatusEnum.dragbackward:
          changeStatus(DivenIndicatorStatusEnum.idle);
          break;
        case DivenIndicatorStatusEnum.ready:
          changeStatus(DivenIndicatorStatusEnum.loading);
          break;
        // changeStatus(IndicatorStatus.idle);
        case DivenIndicatorStatusEnum.loading:
        case DivenIndicatorStatusEnum.loaded:
        case DivenIndicatorStatusEnum.end:
      }
    }
  }

  void changeStatus(DivenIndicatorStatusEnum newStatus, {bool isCancel = false}) async {
    final oldStatus = status;
    if (oldStatus == newStatus) {
      return;
    }
    _indicatorNotiferStatus.changeStatus(newStatus);
    _checkIsProcessing();
    if (newStatus == DivenIndicatorStatusEnum.dragbackward) {
      _indicatorNotiferStatus.changeDragDirection(false);
    } else if (newStatus == DivenIndicatorStatusEnum.dragForward) {
      _indicatorNotiferStatus.changeDragDirection(true);
    }

    /// 状态一定是逐步传递的，除非是可以退回到先前的状态
    bool newStatusIndexBiggerOne = newStatus.index - oldStatus.index == 1;
    if (!newStatusIndexBiggerOne) {
      /// end -> idle
      /// ready -> dargOverscroll
      /// dragOverscroll -> idle
      // bool endToIdle = oldStatus == IndicatorStatusEnum.end && newStatus == IndicatorStatusEnum.idle;
      // bool readyToDragOverscroll = oldStatus == IndicatorStatusEnum.ready && (newStatus == IndicatorStatusEnum.dragForward || newStatus == IndicatorStatusEnum.dragbackward);
      // bool dragOverscrollToIdle = (oldStatus == IndicatorStatusEnum.dragForward || oldStatus == IndicatorStatusEnum.dragbackward) && newStatus == IndicatorStatusEnum.idle;
      // bool idleToReady = oldStatus == IndicatorStatusEnum.idle && newStatus == IndicatorStatusEnum.ready;

      // /// 任务取消
      // bool loadingToIdle = oldStatus == IndicatorStatusEnum.loading && newStatus == IndicatorStatusEnum.idle;
      // assert(() {
      //   if (endToIdle || readyToDragOverscroll || dragOverscrollToIdle) {
      //     return true;
      //   } else if (idleToReady) {
      //     /// 手指虽然在拖拽的状态，但是因为任务的完成，在postFrame阶段变为end->idle，
      //     ///并且由于持续向下拖拽过多，所以虽然顶部添加了一些内容，但是整体还是超出滚动范围，甚至当下就超出了触发范围，所以下一帧开始立即由于拖拽直接进入ready状态
      //     return true;
      //   } else if (loadingToIdle) {
      //     return true;
      //   } else {
      //     return false;
      //   }
      // }(), "其他情况下不可能在这个状态");
    }
    final frameInfo = FrameUtil.debugFrameCount + FrameUtil.debugPhase;

    mtLog(" ooo 状态改变 - 旧状态:$oldStatus,新状态:$newStatus 帧：$frameInfo 当前是否在用手拖拽：$currentIsDragging", tag: TagsConfig.tagIndicator);

    if (newStatus == DivenIndicatorStatusEnum.loading) {
      /// 在微任务中，仍然会可能处理beginActivity，所以要注意！目前观测到Drag松手变Idle的时候可能会进入微任务处理...
      var phase = FrameUtil.phase;
      if (phase == SchedulerPhase.midFrameMicrotasks) {
        mtLog("不合理");
      }
      mtLog("状态变为IndicatorStatusEnum.loading的阶段是 ：phase:$phase");

      /// 在layout之后可能主动goIdle，会由ready变为loading的，则为persistentCallbacks，因此我们必须处理手势是否拖拽的节点
      assert(phase == SchedulerPhase.idle, "由于在处理中的时候不会改变loading等处理中的状态，所以只有在触发的那一刻才会进入这里，那么一定是idle的手势触发这一种情况");
      final task = processManager.generateTask();
      task.taskStatus.listenComplete(() {
        /// MARK - 由于我们的task是监听的doneCompleter，并且立即监听doneCompleter，实际doneComplete必须是在midMicro阶段完成
        /// ，因为task只是加入了当前帧微任务队列，所以等doneCompleter完成的时候相当于又追加了一个微任务，所以不管task里面实际的request是同步的还是异步的，到这里的时候一定微任务阶段；
        changeStatus(DivenIndicatorStatusEnum.loaded);
      });
      task.taskStatus.listenCancel(() {
        changeStatus(DivenIndicatorStatusEnum.idle, isCancel: true);

        /// TODO：这里主要是为了保证idle状态一定隐藏indicator，在头部追加内容刚好修改了vp的尺寸后，会correctPixels，
        /// 那一帧结束了滚动，并且导致了leading的位置其实是错误的，最好的方式是在build中检查一下当前pixel值！！！
        /// 其实更好的做法应该是在帧结束去检测一下是否需要显示
        indicatorNotifer.value.changeHiddenByTask(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          indicatorNotifer.value.changeHiddenByTask(false);
        });
      });
    }
    if (newStatus == DivenIndicatorStatusEnum.loaded) {
      assert(FrameUtil.phase == SchedulerPhase.midFrameMicrotasks, "Task的完成一定是在微任务阶段完成的");
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        /// MARK 这里是因为追加append leading 时候一定是在midMicro阶段，并且这一帧必定是会强制触发correctPixel
        /// 导致Idle一定会进入到Ballistic，correct之后，下一帧还是会惯性，必须要阻止惯性的发生
        /// 1.在goBallistic的时候阻止
        /// 2.在这里直接goIdle强制修改状态。
        processManager.loadedCallback?.call();
        changeStatus(DivenIndicatorStatusEnum.end);

        /// 在这之后修正一下惯性问题，这么一套复杂的操作只是相当于把调整尺寸导致的惯性问题移动到了correctPixel之后
        /// 但是要想阻止惯性的发生，还必须将createBallistic的返回设置为null
        /// MARK - JMT - 这里将是否处理惯性移到physic里面了
        // position.goBallistic(0);
      });
    }
    if (newStatus == DivenIndicatorStatusEnum.end) {
      processManager.endCallback?.call();
      changeStatus(DivenIndicatorStatusEnum.idle);
    }
  }

  /// 根据pixel更改状态。
  /// 并且必须是拖拽的情况下才改变状态
  void changeStatusByPixelChange({required double diff}) {
    if (!isProcessing && currentIsDragging) {
      if (isHeader) {
        bool headIsOverScroll = hasOverScroll(isHeader);
        if (headIsOverScroll) {
          if (absOverscrollOffset >= triggerOffset) {
            changeStatus(DivenIndicatorStatusEnum.ready);
          } else {
            // mtLog("diff:$diff");
            if (diff < 0) {
              // 向正向滑动
              changeStatus(DivenIndicatorStatusEnum.dragForward);
            } else {
              changeStatus(DivenIndicatorStatusEnum.dragbackward);
            }
          }
        } else {
          changeStatus(DivenIndicatorStatusEnum.idle);
        }
      } else {
        bool bottomIsOverScroll = hasOverScroll(isHeader);
        if (bottomIsOverScroll) {
          if (absOverscrollOffset >= triggerOffset) {
            changeStatus(DivenIndicatorStatusEnum.ready);
          } else {
            if (diff < 0) {
              // 向正向滑动
              changeStatus(DivenIndicatorStatusEnum.dragForward);
            } else {
              changeStatus(DivenIndicatorStatusEnum.dragbackward);
            }
          }
        } else {
          changeStatus(DivenIndicatorStatusEnum.idle);
        }
      }

      if (diff <= 0) {
        // 向上滚动,加载trailing
      } else {
        // 向下滚动,加载leading
      }
    }
  }

  late final IndicatorNotifierStatus<T> _indicatorNotiferStatus;

  IndicatorNotifier? _indicatorNotifer;

  IndicatorNotifier get indicatorNotifer => _indicatorNotifer ??= IndicatorNotifier(_indicatorNotiferStatus);

  /// 是否需要预留indicotor高度
  @override
  bool get needIndicatorHeight => true;

  /// 是否需要在不完全显示的时候，弹出整个indicator
  @override
  bool get needShowFullIndicator => true;
}

class IndicatorNotifierStatus<T extends Object> extends ChangeNotifier {
  MTDriveIndicator indicator;
  double pixels = 0;
  DivenIndicatorStatusEnum status = DivenIndicatorStatusEnum.idle;

  IndicatorNotifierStatus({required this.indicator});

  ValueNotifier<bool> dragDirectionChange = ValueNotifier(false);

  void changePixel(double value) {
    // final _oldPixels = pixels;
    mtLog("changePixel: $status -> $value ${FrameUtil.phase}", tag: TagsConfig.tagIndicatorNotifer);
    pixels = value;
    // mtLog("changePixel: $_oldPixels -> $pixels");
    uiNotify();
  }

  void changeStatus(DivenIndicatorStatusEnum value) {
    mtLog("changeStatus: $status -> $value ${FrameUtil.phase}", tag: TagsConfig.tagIndicatorNotifer);
    // final oldStatus = status;
    status = value;
    // mtLog("changeStatus: $oldStatus -> $status");
    uiNotify();
  }

  void changeDragDirection(bool down) {
    dragDirectionChange.value = down;
  }

  bool hiddenByTask = false;

  /// 在触发任务取消的时候，强制隐藏指示器
  void changeHiddenByTask(bool value) {
    mtLog("changeHiddenByTask: $status -> $value ${FrameUtil.phase}", tag: TagsConfig.tagIndicatorNotifer);
    // final oldhiddenByTask = hiddenByTask;
    hiddenByTask = value;
    // mtLog("changeHiddenByTask: $oldhiddenByTask -> $hiddenByTask");
    uiNotify();
  }

  void uiNotify() {
    /// 不允许在build阶段触发对UI的setState，否则会造成断言错误
    /// 仅有一种情况会导致此问题，就是当强制更改尺寸后，在布局阶段之前是Drag，直接goIdle、或者goBallistic，
    /// 本质原因是：我们对于手势的触发时机没有处理好，我们是在beginActivity中来推算手势的。
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      return;
    }
    notifyListeners();
  }

  @override
  String toString() {
    return "IndicatorNotifierStatus(pixels:${pixels.short},status:$status hiddenByTask:$hiddenByTask)";
  }
}

class IndicatorNotifier extends ValueNotifier<IndicatorNotifierStatus> {
  IndicatorNotifier(super.value) {
    value.addListener(() {
      notifyListeners();
    });
  }
}
