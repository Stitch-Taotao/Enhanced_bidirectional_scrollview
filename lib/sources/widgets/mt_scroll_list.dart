// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;

import 'package:bidirectional_load_scrollview/sources/utils/frame_util.dart';
import 'package:flutter/material.dart';

import '../scroll_config/scoll_physics.dart';
import '../scroll_config/scroll_behavior.dart';
import '../scroll_config/scroll_infinite_controller.dart';
import '../task/load_trigger.dart';
import '../utils/log_util.dart';
import '../utils/logs/log_config.dart';
import 'scroll_container.dart';
import 'scroll_view.dart';

typedef InfiteLayoutBuilder = Widget Function({Widget? header, Widget? footer, required Widget scrollView});

class InfiniteScrollList<T extends Object> extends StatefulWidget {
  const InfiniteScrollList({super.key, required this.infiniteScorllController, this.infiteLayoutBuilder});

  final InfiniteScorllController<T> infiniteScorllController;
  final InfiteLayoutBuilder? infiteLayoutBuilder;

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T extends Object> extends State<InfiniteScrollList<T>> {
  InfiniteScorllController<T> get infiniteScorllController => widget.infiniteScorllController;
  GlobalKey scrollKey = GlobalKey();
  int subIndex = 0;

  LoadTrigger get loadTrigger => infiniteScorllController.loadTrigger;

  @override
  void initState() {
    FrameUtil.init();
    super.initState();
  }

  Widget buildHeaderView(BuildContext context) {
    return loadTrigger.builderHeaderIndicatorWidget(context);
  }

  Widget buildFooterView(BuildContext context) {
    return loadTrigger.builderFooterIndicatorWidget(context);
  }

  @override
  Widget build(BuildContext context) {
    return _defalutLayoutBuilder();
  }

  Widget _defalutLayoutBuilder() {
    bool hasHeaderIndicator = loadTrigger.headerIndicator != null;
    bool hasFooterIndicator = loadTrigger.footerIndicator != null;
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        infiniteScorllController.notifyScroll(notification);
        return false;
      },
      child: () {
        final layoutBuilder = widget.infiteLayoutBuilder ?? defaultLayoutBuilder;
        var scrollView = buildScrollView();
        Widget? header;
        if (hasHeaderIndicator) {
          header = buildHeaderView(context);
        }
        Widget? footer;
        if (hasFooterIndicator) {
          footer = buildFooterView(context);
        }
        Widget sc = layoutBuilder(header: header, footer: footer, scrollView: scrollView);
        return sc;
      }(),
    );
  }

  Widget defaultLayoutBuilder({footer, header, scrollView}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            scrollView,
            if (header != null) _defaultHeaderView(header),
            if (footer != null) _defaultFooterView(footer, constraints.maxHeight),
          ],
        );
      },
    );
  }

  /// 滚动组件
  Widget buildScrollView() {
    Widget sc = MTSingleChildScrollView(
      // physics:
      //     MTScrollPhysics(infiniteScorllController: infiniteScorllController),
      controller: infiniteScorllController.scrollController,
      child: Builder(builder: (context) {
        infiniteScorllController.bind(context);
        return ScrollContainer(controller: infiniteScorllController);
      }),
    );

    sc = ScrollConfiguration(
        behavior: MTScrollBehavior(physics: MTScrollPhysics(infiniteScorllController: infiniteScorllController)), child: sc);

    final coorinator = infiniteScorllController.coordinator;
    sc = Listener(
      onPointerDown: (event) {
        mtLog("onPointerDown $event", tag: TagsConfig.tagOnPointerEvent);
        coorinator.changeTouch(true);
      },
      onPointerMove: (event) {
        mtLog("onPointerMove $event", tag: TagsConfig.tagOnPointerEvent);
        coorinator.changeTouch(true);
      },
      onPointerCancel: (event) {
        mtLog("onPointerCancel $event", tag: TagsConfig.tagOnPointerEvent);
        coorinator.changeTouch(false);
      },
      onPointerUp: (event) {
        mtLog("onPointerUp $event", tag: TagsConfig.tagOnPointerEvent);
        coorinator.changeTouch(false);
      },
      child: sc,
    );
    return sc;
  }

  Widget _defaultHeaderView(Widget header) {
    final lloadTrigger = loadTrigger;
    Widget? res;
    if (lloadTrigger is IndicatorLoadTrigger) {
      res = ValueListenableBuilder(
        valueListenable: lloadTrigger.headerIndicator!.indicatorNotifer,
        builder: (context, value, child) {
          final indicatorW = header;
          mtLog("此时的状态: $value", tag: TagsConfig.tagBuildPhaseStatus);
          if (value.indicator.isOverScroll && !value.hiddenByTask) {
            // if (value.indicator.isOverScroll&& value.status!=IndicatorStatusEnum.idle) {
            var indicator = value.indicator;
            final absOverOffset = indicator.absOverscrollOffset;
            return Positioned(
                top: math.min(0, -indicator.triggerOffset + absOverOffset),
                left: 0,
                right: 0,
                child:
                    Container(alignment: Alignment.center, height: math.max(indicator.indicatorHeight, absOverOffset), child: indicatorW));
          } else {
            // return Container(height: 40,color: Color.fromARGB(255, 73, 197, 156),);
            return const SizedBox();
          }
        },
      );
    } else if (lloadTrigger is AutoLoadTrigger) {
      res = header;
    } else {}
    return res ?? const SizedBox();
  }

  Widget _defaultFooterView(Widget footer, double maxHeight) {
    final lloadTrigger = loadTrigger;
    Widget? res;
    if (lloadTrigger is IndicatorLoadTrigger) {
      res = ValueListenableBuilder(
        valueListenable: lloadTrigger.footerIndicator!.indicatorNotifer,
        builder: (context, value, child) {
          final indicatorW = footer;
          var indicator = value.indicator;
          final minEdge = maxHeight - indicator.triggerOffset;
          mtLog("此时的状态: $value", tag: TagsConfig.tagBuildPhaseStatus);
          if (value.indicator.isOverScroll) {
            // if (value.indicator.isOverScroll && value.status!=IndicatorStatusEnum.idle) {
            final absOverOffset = indicator.absOverscrollOffset;

            return Positioned(
                top: math.min(maxHeight, maxHeight - absOverOffset),
                left: 0,
                right: 0,
                // bottom: math.max(minEdge, absOverOffset),
                child:
                    Container(alignment: Alignment.center, height: math.max(indicator.indicatorHeight, absOverOffset), child: indicatorW));
          } else {
            // return Container(height: 40,color: Color.fromARGB(255, 73, 197, 156),);
            return const SizedBox();
          }
        },
      );
    } else if (lloadTrigger is AutoLoadTrigger) {
      res = footer;
    } else {}

    return res ?? const SizedBox();
  }
}
