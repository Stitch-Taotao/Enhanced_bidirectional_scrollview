import 'package:flutter/material.dart';

import '../refresh/drives_indicator/drive_indicator.dart';
import '../task/load_trigger.dart';
import '../utils/frame_util.dart';
import '../utils/logs/log_config.dart';
import '../utils/square_simulation.dart';
import 'scoll_coordinator.dart';
import 'scroll_infinite_controller.dart';
import 'scroll_position.dart';

/// [ClampingScrollPhysics]
class MTScrollPhysics extends BouncingScrollPhysics {
  final InfiniteScorllController infiniteScorllController;

  const MTScrollPhysics({super.parent, required this.infiniteScorllController});

  ScrollCoordinator get coordinator => infiniteScorllController.coordinator;

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MTScrollPhysics(parent: buildParent(ancestor), infiniteScorllController: infiniteScorllController);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);
    final loadTrigger = coordinator.loadTrigger;

    if (!position.outOfRange) {
      return offset;
    }
    var oldPixels = position.pixels;
    var assumeApplyPixels = oldPixels - offset;
    if (loadTrigger is IndicatorLoadTrigger) {
      final MTDriveIndicator? headerIndicator = loadTrigger.headerIndicator;
      if (headerIndicator != null) {
        assert(headerIndicator.currentIsTouching, "一定是在Drag才会触发这个方法");
        final maxOverScroll = headerIndicator.maxOverScrollExtent;

        /// todo:这里有个问题是不能回到精确的100这个位置了
        /// 判断是上边界还是下边界
        var leadingEdge = position.minScrollExtent - maxOverScroll;

        /// 保证offset>0 向下拉动
        if (assumeApplyPixels <= leadingEdge && offset > 0) {
          /// 给出临界返回值
          return oldPixels - leadingEdge;
          // return 0;
        }
      }
      final MTDriveIndicator? footerIndicator = loadTrigger.footerIndicator;
      if (footerIndicator != null) {
        assert(footerIndicator.currentIsTouching, "一定是在Drag才会触发这个方法");
        final maxOverScroll = footerIndicator.maxOverScrollExtent;

        /// todo:这里有个问题是不能回到精确的100这个位置了
        /// 判断是上边界还是下边界
        var trailingEdge = position.maxScrollExtent + maxOverScroll;
        if (assumeApplyPixels >= trailingEdge && offset < 0) {
          return oldPixels - trailingEdge;
          // return 0;
        }
      }
    }

    /// 保留父类处理
    return super.applyPhysicsToUserOffset(position, offset);
  }

  // @override
  // double applyBoundaryConditions(ScrollMetrics position, double value) {
  //   /// 超出部分，在这里不能返回，
  //   /// 返回会导致立即停掉Ballstic，进而直接goIdle而停止，无法触发回弹效果
  //   /// 而ClampPhysic之所以没事，是因为，恰好它停止的位置就是边界，不需要回弹
  //   double overScroll = 0;
  //   final maxOverScroll = indicator.maxOverScrollExtent;
  //   var minScrollExtent = position.minScrollExtent;
  //   var maxScrollExtent = position.maxScrollExtent;
  //   if (value < position.pixels && position.pixels <= minScrollExtent) {
  //     // final t = Tween(begin: 0, end: -maxOverScroll);
  //     // underscroll
  //     // final cDiff = value - position.pixels;
  //     // if (cDiff.abs() >= maxOverScroll) {
  //     //   return cDiff;
  //     // }
  //     // return 0;
  //     // if ((position.pixels - minScrollExtent).abs() >= maxOverScroll) {
  //     //   return value - position.pixels;
  //     // }
  //   }

  //   if (maxScrollExtent <= position.pixels && position.pixels < value) {
  //     // final t = Tween(begin: maxScrollExtent, end: maxScrollExtent + maxOverScroll);
  //     // overscroll
  //     return value - position.pixels;
  //   }
  //   return super.applyBoundaryConditions(position, value);
  // }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = toleranceFor(position);
    const decelerationRate = ScrollDecelerationRate.normal;
    final loadTrigger = coordinator.loadTrigger;

    final headerIndicator = loadTrigger.headerIndicator;
    final footerIndicator = loadTrigger.footerIndicator;
    /// 最终决定在强制更新pixels的地方标记一下，不能再调用goBallstic了。
    if (coordinator.shouldRejectBallstic) {
      /// 恰好是触发惯性这时候
      if (coordinator.correctType == CorrectEnum.jmmpToItem) {
        return null;
      } else {
        /// 这种情况下一定是追加顶部内容，导致的，此刻一定是顶部loaded的时候
        /// TODO:这里可能是autoindicator或者下拉indicator
        if (footerIndicator != null) {
          WidgetsBinding.instance.addPostFrameCallback((d){
            // (position as MTScrollPositionWithSingleContext).activity?.resetActivity();
            (position as MTScrollPositionWithSingleContext).goBallistic(velocity);
          });
        }
      }
      mtLog("shouldRejectBallstic：${infiniteScorllController.coordinator.shouldRejectBallstic} ${FrameUtil.debugFrameCount}",
          tag: TagsConfig.tagShouldRejectBallistic);
      return null;
    }
    // if (parent != null) {
    //   return parent?.createBallisticSimulation(position, velocity);
    // }

    /// 如果当前是loading、loaded、状态,并且满足边界状态
    final pixels = position.pixels;
    double headProcessingExtent = 0.0;
    double footProcessingExtent = 0.0;

    bool headerNeedGoBallstic = false;
    bool footerNeedGoBallstic = false;
    double v = 330;
    if (headerIndicator != null) {
      headProcessingExtent = headerIndicator.needIndicatorHeight ? headerIndicator.indicatorHeight : 0;
      // if (headerIndicator.status == IndicatorStatusEnum.loaded) {
      /// MARK - 这里一定是由于新添加了内容导致尺寸发生变化，所以重新进入goBallstic，
      /// 我们保证loaded的时候一定是在这一帧的midMicro、build、直到postFrameCallback，
      /// 所以这里返回null，避免触发goBallstic,导致已经修正了pixel下一帧又被修改回去
      ///
      /// 为了避免出现拉动距离非常非常大，加载完新的内容，保持滚动后偏移仍然很大，出现空白的情况，
      /// 我们在状态改变为end之后进行惯性滚动，详细见[[MTIndicator.changeStatus]]
      //   return null;
      // }
      bool isProcessing = headerIndicator.physicProcessing;

      /// TODO:假设允许多个同时触发的话，那么这里就需要更多调整了！
      /// 需要考虑两个同时出现，单独出现一个的情况
      /// 必须在想等的时候返回null
      final minEdge = position.minScrollExtent - headProcessingExtent;
      if (isProcessing) {
        if (pixels < minEdge) {
          headerNeedGoBallstic = true;
        } else if (pixels == minEdge) {
          return null;
        } else if (pixels > minEdge && pixels < position.minScrollExtent) {
          if (headerIndicator.needShowFullIndicator) {
            double acceleration = 0;
            double distance = pixels;
            double endDistance = minEdge;
            double lvelocity = -v;
            final simu = ClampGravitySimulation(acceleration, distance, endDistance, lvelocity);
            return simu;
          } else {
            return null;
          }
        }
      }
      // overTriggerHeight = pixels < minEdge;
      // bool equalTriggerHeight = pixels == position.minScrollExtent - processingExtent;
      // if (isProcessing) {
      //   if (overTriggerHeight) {
      //     headerNeedGoBallstic = true;
      //   } else if (equalTriggerHeight) {
      //     return null;
      //   } else {
      //     ///TODO: 这里如果其他情况设置为false，则正在下拉加载的时候，划走，再快速划回来，很不容易置顶loading，更多的是回到正常边界位置
      //     ///并且设置成false也会出现同样得问题
      //     /// 如果设置成true，则会造成Ballistic无限进入Ballistic，
      //     /// 另外同样有问题，就是快速滑动超过边界，确实更容易整体将loading置顶，但是不超出边界的情况，并不会置顶loading或者回到正常边界，而是保持原位
      //     /// 设置成true，还有一个问题，就是滑动到idle状态下，超出的一部分
      //     // headerNeedGoBallstic = false;
      //     // headerNeedGoBallstic = true;
      //     double acceleration = 0.001;
      //     double distance = pixels;
      //     double endDistance = position.minScrollExtent - processingExtent;
      //     double lvelocity = velocity;
      //     final simu = ClampGravitySimulation(acceleration, distance, endDistance, lvelocity);
      //     return simu;
      //   }
      // }
    }

    if (footerIndicator != null) {
      footProcessingExtent = footerIndicator.needIndicatorHeight ? footerIndicator.indicatorHeight : 0;

      // if (footerIndicator.status == IndicatorStatusEnum.loaded) {
      //   /// MARK - 这里一定是由于新添加了内容导致尺寸发生变化，所以重新进入goBallstic，
      //   /// 我们保证loaded的时候一定是在这一帧的midMicro、build、直到postFrameCallback，
      //   /// 所以这里返回null，避免触发goBallstic,导致已经修正了pixel下一帧又被修改回去
      //   ///
      //   /// 为了避免出现拉动距离非常非常大，加载完新的内容，保持滚动后偏移仍然很大，出现空白的情况，
      //   /// 我们在状态改变为end之后进行惯性滚动，详细见[[MTIndicator.changeStatus]]
      //   return null;
      // }
      /// TODO:因为这里我们的status是在beginActivty之后修改的，所以松手的时候还可能是ready
      bool isProcessing = footerIndicator.physicProcessing;
      if (isProcessing) {
        final maxEdge = position.maxScrollExtent + footProcessingExtent;
        if (pixels > maxEdge) {
          headerNeedGoBallstic = true;
        } else if (pixels == maxEdge) {
          return null;
        } else if (pixels < maxEdge && pixels > position.maxScrollExtent) {
          if (footerIndicator.needShowFullIndicator) {
            double acceleration = 0;
            double distance = pixels;
            double endDistance = maxEdge;
            double lvelocity = v;
            final simu = ClampGravitySimulation(acceleration, distance, endDistance, lvelocity);
            return simu;
          } else {
            return null;
          }
        }
      }
    }

    /// TODO
    if (headerNeedGoBallstic || footerNeedGoBallstic) {
      double leadingExtent = position.minScrollExtent - headProcessingExtent;
      double trailingExtent = position.maxScrollExtent + footProcessingExtent;
      double constantDeceleration;
      switch (decelerationRate) {
        case ScrollDecelerationRate.fast:
          constantDeceleration = 1400;
        case ScrollDecelerationRate.normal:
          constantDeceleration = 0;
      }
      return BouncingScrollSimulation(
          spring: spring,
          position: position.pixels,
          velocity: velocity,
          leadingExtent: leadingExtent,
          trailingExtent: trailingExtent,
          tolerance: tolerance,
          constantDeceleration: constantDeceleration);
    }

    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      double constantDeceleration;
      switch (decelerationRate) {
        case ScrollDecelerationRate.fast:
          constantDeceleration = 1400;
        case ScrollDecelerationRate.normal:
          constantDeceleration = 0;
      }
      return BouncingScrollSimulation(
          spring: spring,
          position: position.pixels,
          velocity: velocity,
          leadingExtent: position.minScrollExtent,
          trailingExtent: position.maxScrollExtent,
          tolerance: tolerance,
          constantDeceleration: constantDeceleration);
    }
    return null;
  }
}
