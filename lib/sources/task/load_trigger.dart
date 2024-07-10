// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../refresh/auto_indicator/auto_indicator.dart';
import '../refresh/drives_indicator/builder_indicator.dart';
import '../refresh/drives_indicator/drive_indicator.dart';
import '../refresh/drives_indicator/footer_indicator.dart';
import '../refresh/drives_indicator/header_indicator.dart';
import '../refresh/indicator.dart';
import '../refresh/indicator_task_manager.dart';
import '../scroll_config/scroll_infinite_controller.dart';

typedef TriggerTypeAppendCallback<T extends Object> = Future<List<T>> Function(InfiniteScorllController<T> infiniteScorllController);

abstract class LoadTrigger<T extends Object> {
  /// 滚动到一定位置自动触发
  ///   触发的时候可以添加指示器，一个head指示器，一个tail指示器
  /// 下拉加载、上拉加载触发
  ///   两个指示器，封装，并且要处理两个指示器单个存在、同时存在的情况
  TriggerTypeAppendCallback<T>? appendHeadTask;
  TriggerTypeAppendCallback<T>? appendFootTask;
  LoadTrigger({
    this.appendHeadTask,
    this.appendFootTask,
  });
  MTIndicator? _headerIndicator;
  MTIndicator? get headerIndicator => _headerIndicator;

  MTIndicator? _footerIndicator;
  MTIndicator? get footerIndicator => _footerIndicator;
  MTIndicator? buildHeaderIndicator(MTProcessingManager manager, InfiniteScorllController<T> controller);
  MTIndicator? buildFooterIndicator(MTProcessingManager manager, InfiniteScorllController<T> controller);

  late InfiniteScorllController<T> infiniteScorllController;
  void assemble(InfiniteScorllController<T> controller) {
    infiniteScorllController = controller;
    final indicotorTrigger = this;
    final headerRequest = indicotorTrigger.appendHeadTask;
    final footerRequest = indicotorTrigger.appendFootTask;
    final lThis = this;
    if (lThis is IndicatorLoadTrigger) {
      if (headerRequest != null) {
        MTProcessingManager headProcessManager = MTProcessingManager(
          generateTask: () {
            final task = controller.trickAppendData(
                appendLeading: true,
                request: () {
                  return headerRequest(controller);
                });
            return task;
          },
        );
        _headerIndicator = (lThis as IndicatorLoadTrigger).buildHeaderIndicator(headProcessManager, controller);
      }
      if (footerRequest != null) {
        MTProcessingManager footProcessManager = MTProcessingManager(
          generateTask: () {
            final task = controller.trickAppendData(
                appendLeading: false,
                request: () {
                  return footerRequest(controller);
                });
            return task;
          },
        );

        _footerIndicator = (lThis as IndicatorLoadTrigger).buildFooterIndicator(footProcessManager, controller);
      }
    } else if (this is AutoLoadTrigger) {
      if (headerRequest != null) {
        MTProcessingManager headProcessManager = MTProcessingManager(
          generateTask: () {
            final task = controller.trickAppendData(
                appendLeading: true,
                request: () {
                  return headerRequest(controller);
                });
            return task;
          },
        );
        _headerIndicator = buildHeaderIndicator(headProcessManager, controller);
      }
      if (footerRequest != null) {
        MTProcessingManager headProcessManager = MTProcessingManager(
          generateTask: () {
            final task = controller.trickAppendData(
                appendLeading: false,
                request: () {
                  return footerRequest(controller);
                });
            return task;
          },
        );
        _footerIndicator = buildFooterIndicator(headProcessManager, controller);
      }
    }
  }

  Widget builderHeaderIndicatorWidget(BuildContext context) {
    final lLoad = this;
    Widget? res;
    if (lLoad is AutoLoadTrigger) {
      res = (lLoad as AutoLoadTrigger).headerIndicator?.build(context);
    } else if (lLoad is IndicatorLoadTrigger) {
      res = (lLoad as IndicatorLoadTrigger).headerIndicator?.build(context);
    } else {
      return const SizedBox();
    }
    return res ?? const SizedBox();
  }

  Widget builderFooterIndicatorWidget(BuildContext context) {
    final lLoad = this;
    Widget? res;
    if (lLoad is AutoLoadTrigger) {
      res = (lLoad as AutoLoadTrigger).footerIndicator?.build(context);
    } else if (lLoad is IndicatorLoadTrigger) {
      res = (lLoad as IndicatorLoadTrigger).footerIndicator?.build(context);
    } else {
      return const SizedBox();
    }
    return res ?? const SizedBox();
  }
}

class AutoLoadTrigger<T extends Object> extends LoadTrigger<T> {
  /// 根据本次滚动的偏移量和滚动后的pixels来判断是否需要加载
  bool Function(ScrollController scrollController, double scrollDelta)? needTriggerHeader;
  bool Function(ScrollController scrollController, double scrollDelta)? needTriggerFooter;
  AutoLoadTrigger({
    this.needTriggerHeader,
    this.needTriggerFooter,
    super.appendHeadTask,
    super.appendFootTask,
  }) {
    /// appendHeadTask不为空，则needTriggerHeader也不为空
    // assert((needTriggerHeader == null) == (appendHeadTask == null), "请保证appendHeadTask不为空，则needTriggerHeader也不为空");
    // assert((needTriggerFooter == null) == (appendFootTask == null), "请保证appendFootTask不为空，则needTriggerFooter也不为空");
  }
  @override
  MTAutoIndicator<T>? get headerIndicator => _headerIndicator as MTAutoIndicator<T>?;
  @override
  MTAutoIndicator<T>? get footerIndicator => _footerIndicator as MTAutoIndicator<T>?;

  @override
  MTAutoIndicator<T>? buildHeaderIndicator(MTProcessingManager manager, InfiniteScorllController<T> controller) {
    return MTAutoIndicator<T>(loadTrigger: this, processManager: manager, isHeader: true);
    // return null;
  }

  @override
  MTAutoIndicator<T>? buildFooterIndicator(MTProcessingManager manager, InfiniteScorllController<T> controller) {
    return MTAutoIndicator<T>(loadTrigger: this, processManager: manager, isHeader: false);
  }
}

class IndicatorLoadTrigger<T extends Object> extends LoadTrigger<T> {
  IndicatorLoadTrigger({
    super.appendHeadTask,
    super.appendFootTask,
    this.headerIndicatorBuilder,
    this.footerIndicatorBuilder,
  });
  @override
  MTDriveIndicator<T>? get headerIndicator => _headerIndicator as MTDriveIndicator<T>?;
  @override
  MTDriveIndicator<T>? get footerIndicator => _footerIndicator as MTDriveIndicator<T>?;
  IndicatorBuilder? headerIndicatorBuilder;
  IndicatorBuilder? footerIndicatorBuilder;

  @override
  HeaderIndicator<T>? buildHeaderIndicator(MTProcessingManager manager, InfiniteScorllController<T> controller) {
    return HeaderIndicator(loadTrigger: this, processManager: manager, builder: headerIndicatorBuilder);
  }

  @override
  FooterIndicator<T>? buildFooterIndicator(MTProcessingManager manager, InfiniteScorllController<T> controller) {
    return FooterIndicator(loadTrigger: this, processManager: manager, builder: footerIndicatorBuilder);
  }
}
